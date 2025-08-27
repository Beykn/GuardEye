// detection_service.dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';

class DetectionService {
  Interpreter? _interpreter;
  bool _initialized = false;
  
  // Pre-allocated tensors
  late final List<List<List<double>>> _outputLocations;
  late final List<List<double>> _outputClasses;
  late final List<List<double>> _outputScores;
  late final List<double> _numDetections;
  late final Map<int, Object> _outputs;
  late final List<List<List<List<double>>>> _inputArray;
  late final IsolateInterpreter _isolateInterpreter;
  

  Future<void> loadModel() async {
    if (_initialized) return;
    
    try {
      // Configure interpreter options
      final options = InterpreterOptions()
        ..threads = 4;
      
      

      // Load model
      _interpreter = await Interpreter.fromAsset(
        'assets/ssd_all_data.tflite',
        options: options,
      );

        
      _isolateInterpreter = await IsolateInterpreter.create(address: _interpreter!.address);
      

      // Pre-allocate output tensors
      _outputLocations = List.generate(
        1,
        (_) => List.generate(
          10,
          (_) => List.filled(4, 0.0),
        ),
      );
      _outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
      _outputScores = List.generate(1, (_) => List.filled(10, 0.0));
      _numDetections = List.filled(1, 0.0);

      _outputs = {
        0: _outputScores,
        1: _outputLocations,
        2: _numDetections,
        3: _outputClasses,
      };

      // Pre-allocate input tensor
      _inputArray = List.generate(
        1,
        (_) => List.generate(
          640,
          (_) => List.generate(
            640,
            (_) => List.filled(3, 0.0),
          ),
        ),
      );

      _initialized = true;
      print('Model loaded successfully');

    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<List<dynamic>?> predictCameraImage(CameraImage image) async {
    if (_isolateInterpreter == null || !_initialized) {
      throw Exception('Interpreter is not initialized');
    }

    try {
      // Process image
      _processCameraImage(image, _inputArray[0]);
      
      // Run inference
      _isolateInterpreter!.runForMultipleInputs([_inputArray], _outputs);

      return [
        _outputScores,
        _outputLocations,
        _numDetections,
        _outputClasses,
      ];
    } catch (e) {
      print('Error during inference: $e');
      return null;
    }
  }

  void _processCameraImage(CameraImage image, List<List<List<double>>> input) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    
    final bytes = image.planes[0].bytes;
    final uvBytes1 = image.planes[1].bytes;
    final uvBytes2 = image.planes[2].bytes;

    // Calculate scaling factors
    final double scaleX = width / 640;
    final double scaleY = height / 640;

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final int srcX = (x * scaleX).floor();
        final int srcY = (y * scaleY).floor();
        
        final int uvIndex = 
          uvPixelStride * (srcX >> 1) + 
          uvRowStride * (srcY >> 1);
        
        final int index = srcY * width + srcX;

        final yp = bytes[index];
        final up = uvBytes1[uvIndex];
        final vp = uvBytes2[uvIndex];

        // Optimized YUV to RGB conversion
        int r = yp + ((1436 * (vp - 128)) >> 10);
        int g = yp - ((46549 * (up - 128)) >> 17) - ((93604 * (vp - 128)) >> 17);
        int b = yp + ((1814 * (up - 128)) >> 10);

        // Clamp and normalize
        input[y][x][0] = (r < 0 ? 0 : (r > 255 ? 255 : r)) / 255.0;
        input[y][x][1] = (g < 0 ? 0 : (g > 255 ? 255 : g)) / 255.0;
        input[y][x][2] = (b < 0 ? 0 : (b > 255 ? 255 : b)) / 255.0;
      }
    }
  }

  void dispose() {
    _isolateInterpreter?.close();
  }
}