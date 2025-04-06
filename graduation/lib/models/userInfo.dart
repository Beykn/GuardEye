// user_info.dart
class Driver {
  final String firstName;
  final String lastName;
  final int age;

  Driver({
    required this.firstName,
    required this.lastName,
    required this.age,
  });

  // Map Firestore document to User object
  factory Driver.fromFirestore(Map<String, dynamic> firestoreData) {
    return Driver(
      firstName: firestoreData['first_name'] ?? '',
      lastName: firestoreData['last_name'] ?? '',
      age: int.tryParse(firestoreData['age'].toString()) ?? 0,
    );
  }

  // Optional: to map the User model back to Firestore format (if you need to save data)
  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'age': age,
    };
  }
}
