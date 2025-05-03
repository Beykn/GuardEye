class faceViolation{

  final String id;
  final String driverId;
  final String first_name;
  final String last_name;
  final double confidence;
  final String imageBase64;
  final String tripId;
  final String violationTime;

  faceViolation({
    required this.id,
    required this.driverId,
    required this.first_name,
    required this.last_name,
    required this.confidence,
    required this.imageBase64,
    required this.tripId,
    required this.violationTime
  });

  
}