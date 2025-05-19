import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'detection_service.dart';
import 'draw_service.dart' as draw_service;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:graduation/services/database.dart';
import 'package:graduation/inner_services/violation_handler.dart';
import 'package:graduation/models/violation.dart';
import 'package:graduation/models/violations_helper.dart';
import 'package:http/http.dart' as http;

late List<CameraDescription> cameras;

class LiveCam extends StatefulWidget {
  final String uid;
  final String tripId;

  const LiveCam({Key? key, required this.uid, required this.tripId}) : super(key: key);

  @override
  State<LiveCam> createState() => _LiveCamState();
}

class _LiveCamState extends State<LiveCam> with WidgetsBindingObserver {
  CameraController? _controller;
  final DetectionService _detectionService = DetectionService();
  bool _isDetecting = false;
  List<dynamic>? _recognitions;
  Size? previewSize;
  bool _isCameraInitialized = false;
  int _lastProcessingTime = 0;
  int _currentCameraIndex = 0;

  // Frame skipping for performance optimization
  int _frameSkip = 2;  // Process every 3rd frame
  int _frameCounter = 0;

  Timer? _uploadTimer;
  final Duration _recognitionInterval = const Duration(seconds: 30);
  
  // Queue to store detected violations
  final Queue<PendingViolation> _violationsQueue = Queue<PendingViolation>();
  bool _isProcessingViolations = false;
  bool _isCheckingViolations = false;

  // Track detections across consecutive frames
  final Map<String, DetectionTracker> _activeDetections = {};
  
  // A separate list to track violation types that need to be checked
  final Set<String> _detectionsToCheck = {};
  
  // Number of consecutive frames required to confirm a violation
  final int _requiredConsecutiveFrames = 4;
  
  // Time between violation checks (increased for performance)
  final Duration _violationCheckDelay = const Duration(milliseconds: 200);

  late final UserDatabaseService _userDb;
  late final ViolationHandler _violationHandler;

  int _frameCount = 0;
  int _lastFpsTime = DateTime.now().millisecondsSinceEpoch;
  double _inputFps = 0.0;
  
  // Minimal time gap between two violation uploads of the same type
  final Duration _violationCooldown = const Duration(seconds: 7);
  
  // Stores last upload time for each violation type
  final Map<String, DateTime> _lastUploadTimes = {};

  DateTime? _startTime;

  // Cache recent frames to reduce memory allocations
  Uint8List? _cachedImageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _violationHandler = ViolationHandler(UserDatabaseService(uid: widget.uid));
    _userDb = UserDatabaseService(uid: widget.uid);
    _initializeCamera();
    _startTime = DateTime.now();
    _startPeriodicUploads();
  }

  void _startPeriodicUploads() {
    _uploadTimer = Timer.periodic(
      _recognitionInterval,  
      (timer) => _captureAndUploadImage(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitialized) return;
    try {
      await _detectionService.loadModel();
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        print('No camera available');
        return;
      }

      final camera = cameras[_currentCameraIndex];
      _controller = CameraController(
        camera,
        // Use medium resolution for faster processing
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        previewSize = Size(
          _controller!.value.previewSize!.height,
          _controller!.value.previewSize!.width,
        );
        _isCameraInitialized = true;
      });

      _controller!.startImageStream(_processCameraImage);
      
      // Start processing queue in background
      _processViolationsQueue();
      
      // Start checking for violations in background
      _startViolationChecking();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length <= 1) return;

    await _controller!.dispose();

    setState(() {
      _isCameraInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
    });

    await _initializeCamera();
  }

  // Clean up stale detections that haven't been updated recently
  void _cleanStaleDetections() {
    final now = DateTime.now();
    final staleKeys = <String>[];
    
    _activeDetections.forEach((key, tracker) {
      if (tracker.isStale(now)) {
        staleKeys.add(key);
      }
    });
    
    for (final key in staleKeys) {
      _activeDetections.remove(key);
    }
  }

  // Start a background task to periodically check for violations
  void _startViolationChecking() async {
    while (mounted) {
      await Future.delayed(_violationCheckDelay);
      if (_detectionsToCheck.isNotEmpty && !_isCheckingViolations) {
        await _checkForViolations();
      }
    }
  }

  // Check for violations that have reached threshold and queue them (just once)
  Future<void> _checkForViolations() async {
    if (_isCheckingViolations) return;
    _isCheckingViolations = true;
    
    try {
      // Create a copy to avoid concurrent modification
      final detectionTypes = Set<String>.from(_detectionsToCheck);
      _detectionsToCheck.clear();
      
      for (final type in detectionTypes) {
        if (_activeDetections.containsKey(type)) {
          final tracker = _activeDetections[type]!;
          
          // Check if we've reached threshold, haven't reported this yet,
          // and aren't in cooldown period
          if (tracker.consecutiveFrames >= _requiredConsecutiveFrames && 
              !tracker.violationReported &&
              tracker.imageToUse != null) {
            
            final now = DateTime.now();
            
            // Check if we're in the cooldown period
            if (_lastUploadTimes.containsKey(type)) {
              final timeSinceLastUpload = now.difference(_lastUploadTimes[type]!);
              if (timeSinceLastUpload < _violationCooldown) {
                continue;
              }
            }
            
            // Mark as reported
            tracker.violationReported = true;
            
            // Update last upload time
            _lastUploadTimes[type] = now;
            
            // Create a Violation object
            final violation = Violation(
              id: 'temp', // Generate a unique ID
              type: type,
              timestamp: now,
              confidence: tracker.confidence,
              imageBase64: null, // We'll set this later after processing
            );

            // Add to queue for processing
            _violationsQueue.add(PendingViolation(
              violation: violation,
              image: tracker.imageToUse!,
            ));
          }
        }
      }
    } catch (e) {
      print('Error checking for violations: $e');
    } finally {
      _isCheckingViolations = false;
    }
  }

  Future<String> _convertImageToBase64Efficiently(File imageFile) async {
    try {
      // Use direct file reading for better performance
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting image to base64: $e');
      rethrow;
    }
  }

  Future<void> _captureAndUploadImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Capture the current camera frame
      final XFile cameraImage = await _controller!.takePicture();
      
      // Convert to a file
      final File imageFile = File(cameraImage.path);
      final String base64Image = await _convertImageToBase64Efficiently(imageFile);

      // Upload to server using a non-blocking approach
      unawaited(http.post(
        Uri.parse('http://192.168.136.81:3000/check'),
        body: jsonEncode({
          'driverId': widget.uid,
          'testImage': base64Image,
        }),
        headers: {'Content-Type': 'application/json'},
      ).then((_) {
        print('Image uploaded successfully!');
      }).catchError((error) {
        print('Upload failed: $error');
      }));

      // Delete the temporary file
      unawaited(imageFile.delete());
    } catch (e) {
      print('Error capturing/uploading image: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _frameCount++;
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastFpsTime >= 1000) {
      setState(() {
        _inputFps = _frameCount * 1000 / (currentTime - _lastFpsTime);
      });
      _frameCount = 0;
      _lastFpsTime = currentTime;
    }

    // Skip frames for better performance
    _frameCounter = (_frameCounter + 1) % (_frameSkip + 1);
    if (_frameCounter != 0) return;

    if (_isDetecting) return;
    _isDetecting = true;

    try {
      // Clean up stale detections periodically instead of every frame
      if (_frameCounter == 0) {
        _cleanStaleDetections();
      }
      
      final recognitions = await _detectionService.predictCameraImage(image);
      final int numDetections = recognitions![2][0].toInt();
      
      // Track which detection types were found in this frame
      final Set<String> currentFrameDetections = {};

      // Reduce threshold for cleaner processing
      const double confidenceThreshold = 0.5;

      for (int i = 0; i < numDetections; i++) {
        final double confidence = recognitions[0][0][i];

        if (confidence > confidenceThreshold) {
          final int classIndex = recognitions[3][0][i].toInt();
          String label = switch (classIndex) {
            0 => 'vape',
            1 => 'cigarette',
            2 => 'phone',
            _ => 'unknown'
          };
          
          currentFrameDetections.add(label);
          
          // Add this type to the list to check for violations later
          _detectionsToCheck.add(label);
          
          // Update or create tracking for this detection
          if (_activeDetections.containsKey(label)) {
            // We've seen this before, increment frame counter
            _activeDetections[label]!.incrementFrameCount(image);
          } else {
            // First time we've seen this detection in recent frames
            _activeDetections[label] = DetectionTracker(
              type: label, 
              confidence: confidence,
            );
          }
        }
      }
      
      // Only remove detections if they're missing for 2 consecutive processed frames
      // This helps with temporary false negatives
      for (final key in _activeDetections.keys.toList()) {
        final tracker = _activeDetections[key]!;
        if (!currentFrameDetections.contains(key)) {
          tracker.missedFrames++;
          if (tracker.missedFrames > 2) {
            _activeDetections.remove(key);
          }
        } else {
          tracker.missedFrames = 0;
        }
      }

      if (mounted) {
        setState(() {
          _recognitions = recognitions;
          _lastProcessingTime = DateTime.now().millisecondsSinceEpoch;
        });
      }
    } catch (e) {
      print('Error in detection: $e');
    } finally {
      _isDetecting = false;
    }
  }

  // Process violations queue in background with optimized processing
  Future<void> _processViolationsQueue() async {
    if (_isProcessingViolations) return;
    
    _isProcessingViolations = true;
    
    while (true) {
      if (_violationsQueue.isNotEmpty) {
        final pendingViolation = _violationsQueue.removeFirst();
        
        try {
          String filename = 'violation_${pendingViolation.violation.timestamp.millisecondsSinceEpoch}_${pendingViolation.violation.type}';
          File? imageFile = await convertCameraImageToFile(pendingViolation.image, filename);

          if (imageFile != null) {
            // Process in background to avoid blocking main UI
            unawaited(_violationHandler.handleViolation(
              violation: pendingViolation.violation,
              imageFile: imageFile,
            ));
          }
        } catch (e) {
          print('Error processing violation: $e');
        }
      } else {
        // Sleep a bit to avoid high CPU usage when queue is empty
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // If widget is being disposed, break the loop
      if (!mounted) break;
    }
    
    _isProcessingViolations = false;
  }

  Future<File?> convertCameraImageToFile(CameraImage image, String filename) async {
    try {
      // Optimize image conversion for better performance
      final int width = image.width;
      final int height = image.height;
      
      // Create image buffer
      final img.Image imgImage = img.Image(width: width, height: height);
      
      // Use more efficient YUV to RGB conversion
      final Uint8List yPlane = image.planes[0].bytes;
      final Uint8List uPlane = image.planes[1].bytes;
      final Uint8List vPlane = image.planes[2].bytes;
      
      final int yRowStride = image.planes[0].bytesPerRow;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;
      
      // Convert YUV to RGB more efficiently
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yRowStride + x;
          
          // More efficient UV index calculation
          final int uvY = y ~/ 2;
          final int uvX = x ~/ 2;
          final int uvIndex = uvY * uvRowStride + uvX * uvPixelStride;
          
          // Use fixed point math for speed
          final int yValue = yPlane[yIndex];
          final int uValue = uPlane[uvIndex];
          final int vValue = vPlane[uvIndex];
          
          // Faster YUV to RGB conversion using integer math
          // Y = 1.164(Y-16)
          // R = Y + 1.596(V-128)
          // G = Y - 0.813(V-128) - 0.391(U-128)
          // B = Y + 2.018(U-128)
          
          final int y1 = ((yValue * 1192) >> 10) - 16;
          final int u1 = uValue - 128;
          final int v1 = vValue - 128;
          
          int r = y1 + ((v1 * 1634) >> 10);
          int g = y1 - ((v1 * 832) >> 10) - ((u1 * 400) >> 10);
          int b = y1 + ((u1 * 2066) >> 10);
          
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);
          
          imgImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      // Compress with lower quality for faster encoding
      final jpg = img.encodeJpg(imgImage, quality: 80);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$filename.jpg';
      final file = File(path)..writeAsBytesSync(jpg);

      return file;
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  void _confirmEndTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: const Text('Are you sure you want to end this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _userDb.endTrip(widget.tripId, _startTime!);
      Navigator.pop(context); // Go back after ending trip
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _uploadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Object Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            onPressed: _confirmEndTrip,
          ),
          if (cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              onPressed: _switchCamera,
            ),
          // Queue length and detection status
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  'Queue: ${_violationsQueue.length}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                _buildDetectionStatusIndicator(),
              ],
            ),
          ),
        ],
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          if (_recognitions != null)
            // Only draw boxes when not detecting to reduce UI load
            !_isDetecting ? CustomPaint(
              painter: draw_service.BoxPainter(
                _recognitions!,
                previewSize ?? Size.zero,
                MediaQuery.of(context).size,
              ),
            ) : const SizedBox.shrink(),
          Positioned(
            bottom: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'FPS: ${_inputFps.toStringAsFixed(1)} | Skip: $_frameSkip',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          // Status indicators for each violation type
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDetectionProgressIndicator('vape'),
                _buildDetectionProgressIndicator('cigarette'),
                _buildDetectionProgressIndicator('phone'),
              ],
            ),
          ),
          // Add cooldown indicators
          Positioned(
            bottom: 100,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCooldownIndicator('vape'),
                _buildCooldownIndicator('cigarette'),
                _buildCooldownIndicator('phone'),
              ],
            ),
          ),
          // Add frame skip controller
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () {
                    if (_frameSkip > 0) {
                      setState(() {
                        _frameSkip--;
                      });
                    }
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Skip: $_frameSkip',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if (_frameSkip < 5) {
                      setState(() {
                        _frameSkip++;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Visual indicator for detection status
  Widget _buildDetectionStatusIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isDetecting ? Colors.red : Colors.green,
      ),
    );
  }
  
  // Visual indicator showing progress toward consecutive frames
  Widget _buildDetectionProgressIndicator(String type) {
    int currentFrameCount = 0;
    double progress = 0.0;
    bool reported = false;
    
    if (_activeDetections.containsKey(type)) {
      final tracker = _activeDetections[type]!;
      currentFrameCount = tracker.consecutiveFrames;
      progress = currentFrameCount / _requiredConsecutiveFrames;
      reported = tracker.violationReported;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 30,
              height: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade700,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    reported ? Colors.green : (progress >= 1.0 ? Colors.red : Colors.amber),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              reported ? '✓' : '$currentFrameCount/$_requiredConsecutiveFrames',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
  
  // Visual indicator for cooldown status
  Widget _buildCooldownIndicator(String type) {
    bool inCooldown = false;
    int remainingSeconds = 0;
    
    if (_lastUploadTimes.containsKey(type)) {
      final elapsed = DateTime.now().difference(_lastUploadTimes[type]!);
      if (elapsed < _violationCooldown) {
        inCooldown = true;
        remainingSeconds = (_violationCooldown.inSeconds - elapsed.inSeconds);
      }
    }
    
    // Only show if in cooldown
    if (!inCooldown) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$type: cooldown ${remainingSeconds}s',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}

// Add this extension to allow using unawaited without import
extension FutureExtensions<T> on Future<T> {
  void unawaited() {}
}


class DetectionTracker {
  final String type;
  double confidence;
  int consecutiveFrames = 0;
  CameraImage? imageToUse;
  bool violationReported = false;
  final DateTime firstDetected = DateTime.now();
  int missedFrames = 0;  // NEW: Track missed frames
  
  DetectionTracker({required this.type, required this.confidence});
  
  void incrementFrameCount(CameraImage image) {
    consecutiveFrames++;
    confidence = (confidence * 0.8) + (confidence * 0.2); // Smoothed confidence
    
    // Only store image if we don't have one yet or every few frames
    if (imageToUse == null || consecutiveFrames % 2 == 0) {
      imageToUse = image;
    }
  }
  
  bool isStale(DateTime now) {
    // Mark as stale if no updates for 2 seconds
    return now.difference(firstDetected).inSeconds > 2;
  }
}