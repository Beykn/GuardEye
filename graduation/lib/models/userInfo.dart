// user_info.dart
class Driver {
  final String firstName;
  final String lastName;
  final int age;
  final String role;
  final String UID;
  final String image;
  final List<Map<String, dynamic>> trips;
  final String username;

  Driver({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.role,
    required this.UID,
    required this.trips,
    required this.image,
    required this.username,
  });

  // Map Firestore document to User object
  factory Driver.fromFirestore(Map<String, dynamic> firestoreData) {
    return Driver(
      firstName: firestoreData['firstName'] ?? '',
      lastName: firestoreData['lastName'] ?? '',
      age: int.tryParse(firestoreData['age'].toString()) ?? 0,
      role: firestoreData['role'] ?? '',
      UID: firestoreData['id'] ?? '',
      trips: List<Map<String, dynamic>>.from(firestoreData['trips'] ?? []),
      image: firestoreData['imageBase64'] ?? '',
      username: firestoreData['username'] ?? '',
    );
  }
  

 
}
