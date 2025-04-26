import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation/models/userInfo.dart';
import 'package:firebase_storage/firebase_storage.dart';


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

  // end trip
  Future<void> endTrip(String tripId, DateTime startTime) async {
    try {
      await _firestore.collection('drivers').doc(uid).collection('trips').doc(tripId).update({
        'status': 'Finished',
        'startTime': startTime,
        'endTime': DateTime.now(),
        'duration': DateTime.now().difference(startTime).inHours.toString() + ':' + DateTime.now().difference(startTime).inMinutes.remainder(60).toString(),
      });
      print('Trip ended successfully');
    } catch (e) {
      print('Error ending trip: $e');
    }
  }

  

  // Get trips for the user (driver)
  Future<List<Map<String, dynamic>>> getDriverTrips() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .doc(uid)
          .collection('trips')
          .orderBy('createdAt', descending: true)
          .get();


    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['tripId'] = doc.id; // 👈 Add the document id into the map
      return data;
    }).toList();
    } catch (e) {
      print('Error fetching trips: $e');
      return [];
    }
  }

  Future<void> addViolation({ required String type, required DateTime timestamp, double? confidence,String? imageBase64, }) async {
    try {
      await _driverCollection.doc(uid).collection('violations').add({
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'confidence': confidence,
        'imageBase64': imageBase64, // Save the base64 string here
      });
      print('Violation added successfully');
    } catch (e) {
      print('Error adding violation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getViolations() async {
    try {
      QuerySnapshot snapshot = await _driverCollection
          .doc(uid)
          .collection('violations')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching violations: $e");
      return [];
    }
  }

  Future<String> getUserRole() async {
    try {
      DocumentSnapshot snapshot = await _driverCollection.doc(uid).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return data['role'] ?? '';
      } else {
        return '';
      }
    } catch (e) {
      print("Error fetching user role: $e");
      return '';
    }
  }


  // Get user data (driver)
  Future<Driver?> getDriverData() async {
    try {
      DocumentSnapshot snapshot = await _driverCollection.doc(uid).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        return Driver(
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          age: int.tryParse(data['age'].toString()) ?? 0,
          role: data['role'] ?? '',
          UID: snapshot.id,
          trips: [],
        );
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching driver data: $e");
      return null;
    }
  }

  
}
