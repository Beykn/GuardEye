import 'dart:convert';
import 'dart:io';
import 'package:graduation/services/database.dart';

// Using your Violation model
class Violation {
  final String id;
  final String type;
  final DateTime timestamp;
  final double? confidence;
  final String? imageBase64;
  
  Violation({
    required this.id,
    required this.type,
    required this.timestamp,
    this.confidence,
    this.imageBase64,
  });
  
  factory Violation.fromMap(String id, Map<String, dynamic> data) {
    return Violation(
      id: id,
      type: data['type'] ?? '',
      timestamp: data['timestamp'],
      confidence: (data['confidence'] != null)
          ? (data['confidence'] as num).toDouble()
          : null,
      imageBase64: data['imageBase64'],
    );
  }
  
  // Add a method to create a copy with the base64 image
  Violation copyWithBase64(String base64Image) {
    return Violation(
      id: id,
      type: type,
      timestamp: timestamp,
      confidence: confidence,
      imageBase64: base64Image,
    );
  }
  
  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'timestamp': timestamp,
      'confidence': confidence,
      'imageBase64': imageBase64,
    };
  }
}

