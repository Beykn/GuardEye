import 'package:graduation/models/violation.dart';
import 'package:camera/camera.dart';
class PendingViolation {
    final Violation violation;
    final CameraImage image;

    PendingViolation({
      required this.violation,
      required this.image,
    });
  }

class DetectionTracker {
  final String type;
  int consecutiveFrames = 1;
  final double confidence;
  DateTime firstDetected;
  bool violationReported = false;
  CameraImage? imageToUse;
  
  DetectionTracker({
    required this.type,
    required this.confidence,
    this.imageToUse,
    DateTime? detectedAt,
  }) : firstDetected = detectedAt ?? DateTime.now();
  
  void incrementFrameCount(CameraImage image) {
    consecutiveFrames++;
    // Store the 2nd frame instead of the 3rd
    if (consecutiveFrames == 2 && !violationReported) {
      imageToUse = image;
    }
  }
  
  bool isStale(DateTime now) {
    // Consider detection stale if more than 500ms has passed with no updates
    return now.difference(firstDetected).inMilliseconds > 500;
  }
}