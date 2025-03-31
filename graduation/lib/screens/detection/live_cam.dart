// live_cam.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'detection_service.dart';
import 'draw_service.dart' as draw_service; // Import draw_service.dart with prefix

late List<CameraDescription> cameras;

class LiveCam extends StatefulWidget {
  const LiveCam({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      if (mounted) {
        setState(() {
          _recognitions = recognitions;
          _lastProcessingTime = DateTime.now().millisecondsSinceEpoch;
        });
      }
    } catch (e) {
      print('Error detecting: $e');
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