  import 'dart:async';
import 'dart:convert';
import 'dart:io';
  import 'dart:collection';
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
    final int _requiredConsecutiveFrames = 3;
    
    // Time between violation checks
    final Duration _violationCheckDelay = const Duration(milliseconds: 100);

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
      _recognitionInterval,  // Fires every minute
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
          ResolutionPreset.high,
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
      
      if (staleKeys.isNotEmpty) {
        print('🧹 Cleaned up ${staleKeys.length} stale detections');
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
                  print('⏳ Skipping $type upload - in cooldown period (${timeSinceLastUpload.inSeconds}s/${_violationCooldown.inSeconds}s)');
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
              
              print('✅ Added $type violation to queue after ${_requiredConsecutiveFrames} consecutive frames '
                  '(confidence: ${(tracker.confidence * 100).toStringAsFixed(1)}%)');
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

        print('sending image to server...');

        // Upload to server (non-blocking)
        http.post(
          Uri.parse('http://192.168.1.107:3000/check'),
          body: jsonEncode({
            'driverId': widget.uid,
            'testImage': base64Image,
          }),
          headers: {'Content-Type': 'application/json'},
        ).then((response) {
          print('Image uploaded successfully!');
        }).catchError((error) {
          print('Upload failed: $error');
        });

        // Delete the temporary file
        await imageFile.delete();
      } catch (e) {
        print('Error capturing/uploading image: $e');
      }
    }

    Future<void> _processCameraImage(CameraImage image) async {
      if (_isDetecting) return;

      _frameCount++;
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastFpsTime >= 1000) {
        setState(() {
          _inputFps = _frameCount * 1000 / (currentTime - _lastFpsTime);
        });
        _frameCount = 0;
        _lastFpsTime = currentTime;
      }

      _isDetecting = true;

      try {
        // Clean up stale detections before processing new ones
        _cleanStaleDetections();
        
        final recognitions = await _detectionService.predictCameraImage(image);
        final int numDetections = recognitions![2][0].toInt();
        
        // Track which detection types were found in this frame
        final Set<String> currentFrameDetections = {};

        for (int i = 0; i < numDetections; i++) {
          final double confidence = recognitions[0][0][i];

          if (confidence > 0.4) {
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
        
        // Remove detections that weren't found in this frame
        final missingDetections = <String>[];
        _activeDetections.forEach((key, tracker) {
          if (!currentFrameDetections.contains(key)) {
            missingDetections.add(key);
          }
        });
        
        for (final key in missingDetections) {
          _activeDetections.remove(key);
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

    // Process violations queue in background
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
              await _violationHandler.handleViolation(
                violation: pendingViolation.violation,
                imageFile: imageFile,
              );
            } else {
              print('Error saving image file');
            }
          } catch (e) {
            print('Error processing violation: $e');
          }
        } else {
          // Sleep a bit to avoid high CPU usage when queue is empty
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // If widget is being disposed, break the loop
        if (!mounted) break;
      }
      
      _isProcessingViolations = false;
    }

    Future<File?> convertCameraImageToFile(CameraImage image, String filename) async {
      try {
        final int width = image.width;
        final int height = image.height;
        final img.Image imgImage = img.Image(width: width, height: height);

        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final int uvIndex = (y >> 1) * image.planes[1].bytesPerRow + (x >> 1) * 2;

            final yp = image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
            final up = image.planes[1].bytes[uvIndex];
            final vp = image.planes[2].bytes[uvIndex];

            int r = (yp + vp * 1436 / 1024 - 179).toInt().clamp(0, 255);
            int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).toInt().clamp(0, 255);
            int b = (yp + up * 1814 / 1024 - 227).toInt().clamp(0, 255);

            imgImage.setPixelRgba(x, y, r, g, b, 255);
          }
        }

        final jpg = img.encodeJpg(imgImage, quality: 85); // Add compression for faster processing
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
              CustomPaint(
                painter: draw_service.BoxPainter(
                  _recognitions!,
                  previewSize ?? Size.zero,
                  MediaQuery.of(context).size,
                ),
              ),
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
                  'Input FPS: ${_inputFps.toStringAsFixed(1)}',
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