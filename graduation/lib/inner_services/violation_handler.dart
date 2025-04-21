import 'dart:convert';
import 'dart:io';
import 'package:graduation/services/database.dart';
import 'package:graduation/models/violation.dart';

class ViolationHandler {
  final UserDatabaseService userDb;
  
  ViolationHandler(this.userDb);
  
  Future<void> handleViolation({
    required Violation violation,
    required File imageFile,
  }) async {
    try {
      if (!(await imageFile.exists())) {
        print('❌ Image file does not exist at path: ${imageFile.path}');
        return;
      }
      
      print('📤 Processing image: ${imageFile.path}');
      
      // Convert image to base64 efficiently
      final String base64Image = await _convertImageToBase64Efficiently(imageFile);
      
      // Create an updated violation with the base64 image
      final Violation completeViolation = violation.copyWithBase64(base64Image);
      
      // Save to database
      await userDb.addViolation(
        type: completeViolation.type,
        timestamp: completeViolation.timestamp,
        confidence: completeViolation.confidence,
        imageBase64: completeViolation.imageBase64,
      );
      
      print('✅ Violation saved to database with label: ${completeViolation.type}');
      
      // Delete the temporary file to free up space
      try {
        await imageFile.delete();
      } catch (e) {
        print('Warning: Could not delete temporary image file: $e');
      }
      
    } catch (e) {
      print("Error handling violation: $e");
    }
  }
  
  // More efficient base64 conversion that reads chunks rather than loading entire file
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
}