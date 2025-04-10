import 'dart:convert';
import 'dart:io';
import 'package:graduation/services/database.dart';

class ViolationHandler {
  final UserDatabaseService userDb;

  ViolationHandler(this.userDb);

  Future<void> handleViolation({
    required String type,
    required File imageFile,
    double? confidence,
  }) async {
    try {
      if (imageFile == null || !(await imageFile.exists())) {
        print('❌ Image file does not exist at path: ${imageFile?.path}');
        return;
      }

      print('📤 Converting image to base64: ${imageFile.path}');

      // Convert image to base64
      String? base64Image = await convertImageToBase64(imageFile);

      if (base64Image != null) {
        // Save violation to Firestore with base64 image data
        await userDb.addViolation(
          type: type,
          timestamp: DateTime.now(),
          confidence: confidence,
          imageBase64: base64Image,
        );

        print('✅ Violation saved to database with label: $type');
      } else {
        print("Error converting image to base64");
      }
    } catch (e) {
      print("Error handling violation: $e");
    }
  }

  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      // Read image file as bytes
      List<int> imageBytes = await imageFile.readAsBytes();
      
      // Convert image bytes to base64
      String base64Image = base64Encode(imageBytes);

      return base64Image;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }
}
