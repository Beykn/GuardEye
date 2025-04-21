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

late List<CameraDescription> cameras;

// Use the existing Violation model for the queue
class PendingViolation {
  final Violation violation;
  final CameraImage image;

  PendingViolation({
    required this.violation,
    required this.image,
  });
}

class LiveCam extends StatefulWidget {
  final String uid;
  const LiveCam({Key? key, required this.uid}) : super(key: key);

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
  
  // Queue to store detected violations
  final Queue<PendingViolation> _violationsQueue = Queue<PendingViolation>();
  bool _isProcessingViolations = false;

  // Map to track last detection time for each type
  final Map<String, DateTime> _lastDetectionTimes = {};
  // Duration to wait before allowing another detection of the same type
  final Duration _detectionCooldown = const Duration(seconds: 3);

  late final UserDatabaseService _userDb;
  late final ViolationHandler _violationHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _violationHandler = ViolationHandler(UserDatabaseService(uid: widget.uid));
    _userDb = UserDatabaseService(uid: widget.uid);
    _initializeCamera();
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

  // Check if a detection should be processed based on type and timing
  bool _shouldProcessDetection(String type) {
    final now = DateTime.now();
    
    // Check if we've seen this type before
    if (_lastDetectionTimes.containsKey(type)) {
      final lastDetection = _lastDetectionTimes[type]!;
      
      // If the cooldown period hasn't elapsed, skip this detection
      if (now.difference(lastDetection) < _detectionCooldown) {
        print('🕒 Skipping $type detection - cooldown period active (${now.difference(lastDetection).inSeconds}s)');
        return false;
      }
    }
    
    // Update the last detection time for this type
    _lastDetectionTimes[type] = now;
    return true;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final recognitions = await _detectionService.predictCameraImage(image);
      final int numDetections = recognitions![2][0].toInt();

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
          print('Detected $label with confidence: ${(confidence * 100).toStringAsFixed(1)}%');

          // Only process this detection if it passes our cooldown filter
          if (_shouldProcessDetection(label)) {
            // Create a Violation object using your model
            final violation = Violation(
              id: 'temp', // Generate a unique ID
              type: label,
              timestamp: DateTime.now(),
              confidence: confidence,
              imageBase64: null, // We'll set this later after processing
            );

            // Add to queue instead of processing immediately
            _violationsQueue.add(PendingViolation(
              violation: violation,
              image: image,
            ));
            
            print('✅ Added $label violation to queue (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
          }
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
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
          if (cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              onPressed: _switchCamera,
            ),
          // Added indicators for queue length and detection status
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
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'FPS: ${(1000 / (DateTime.now().millisecondsSinceEpoch - _lastProcessingTime)).toStringAsFixed(1)}',
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
                _buildCooldownIndicator('phone'),
                _buildCooldownIndicator('cigarette'),
                _buildCooldownIndicator('vape'),
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
  
  // Visual indicator showing cooldown status for each violation type
  Widget _buildCooldownIndicator(String type) {
    bool isInCooldown = false;
    int remainingSeconds = 0;
    
    if (_lastDetectionTimes.containsKey(type)) {
      final elapsed = DateTime.now().difference(_lastDetectionTimes[type]!);
      if (elapsed < _detectionCooldown) {
        isInCooldown = true;
        remainingSeconds = (_detectionCooldown.inSeconds - elapsed.inSeconds);
      }
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
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isInCooldown ? Colors.red : Colors.green,
              ),
            ),
            if (isInCooldown)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  '${remainingSeconds}s',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
