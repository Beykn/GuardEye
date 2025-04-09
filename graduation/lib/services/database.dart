import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation/models/userInfo.dart';

class UserDatabaseService {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _driverCollection = FirebaseFirestore.instance.collection('drivers');

  UserDatabaseService({required this.uid});

  // Update user data (driver profile)
  Future updateUserData(String firstName, String lastName, String email, String age) async {
    return await _driverCollection.doc(uid).set({
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'age': age,
      'role': 'driver',
    });
  }

  // Add a trip for the user (driver)
  

  // Get trips for the user (driver)
  Future<List<Map<String, dynamic>>> getDriverTrips() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .doc(uid)
          .collection('trips')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching trips: $e');
      return [];
    }
  }

  // Get user data (driver)
  Future<Driver?> getDriverData() async {
    try {
      DocumentSnapshot snapshot = await _driverCollection.doc(uid).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> trips = await _getTripsFromFirestore();

        return Driver(
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          age: int.tryParse(data['age'].toString()) ?? 0,
          role: data['role'] ?? '',
          UID: snapshot.id,
          trips: trips,
        );
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching driver data: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getTripsFromFirestore() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .doc(uid)
          .collection('trips')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'startingPoint': doc['startingPoint'],
        'endingPoint': doc['endingPoint'],
        'date': doc['date'],
        'hours': doc['hours'],
      }).toList();
    } catch (e) {
      print('Error fetching trips: $e');
      return [];
    }
  }
}
