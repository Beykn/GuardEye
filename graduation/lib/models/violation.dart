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
}
