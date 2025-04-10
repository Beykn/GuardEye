// live_cam.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'detection_service.dart';
import 'draw_service.dart' as draw_service; // Import draw_service.dart with prefix
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:graduation/services/database.dart';
import 'package:graduation/screens/detection/violation_handler.dart';

late List<CameraDescription> cameras;

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

      if(cameras.isEmpty) {
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
        previewSize = Size(_controller!.value.previewSize!.height, _controller!.value.previewSize!.width);
        _isCameraInitialized = true;
      });
      _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if(cameras.length <= 1) return;

    await _controller!.dispose();

    setState(() {
      _isCameraInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
    });

    await _initializeCamera();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final recognitions = await _detectionService.predictCameraImage(image);

      final int numDetections = recognitions![2][0].toInt();

      for (int i = 0; i < numDetections; i++) {
        final double confidence = recognitions[0][0][i];

        if (confidence > 0.6) {
          // Get class index and label
          final int classIndex = recognitions![3][0][i].toInt();
          String label = '';

          switch (classIndex) {
            case 0:
              label = 'cigarette';
              break;
            case 1:
              label = 'phone';
              break;
            case 2:
              label = 'vape';
              break;
            default:
              label = 'unknown';
          }

          // Save frame
          String filename = 'violation_${DateTime.now().millisecondsSinceEpoch}_$label';
          File? imageFile = await convertCameraImageToFile(image, filename);

          if (imageFile != null) {
            // Handle violation
            await _violationHandler.handleViolation(
              type: label,
              imageFile: imageFile,
              confidence: confidence,
            );
          } else {
            print('Error saving image file');
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


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller!.dispose();
    super.dispose();
  }

  Future<File?> convertCameraImageToFile(CameraImage image, String filename) async {
    try {
      // Convert YUV to RGB
      final int width = image.width;
      final int height = image.height;
      final img.Image imgImage = img.Image(width: width, height: height);

      // Fill the RGB image with pixel data
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex = (y >> 1) * (image.planes[1].bytesPerRow) + (x >> 1) * 2;
          final int index = y * width + x;

          final yp = image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];

          int r = (yp + vp * 1436 / 1024 - 179).toInt().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).toInt().clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).toInt().clamp(0, 255);

          imgImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      final jpg = img.encodeJpg(imgImage);
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
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Object Detection'),
        actions: [
          // Camera switch button
          if (cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              onPressed: _switchCamera,
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
        ],
      ),
    );
  }
}