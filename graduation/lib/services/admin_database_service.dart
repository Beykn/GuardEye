import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation/models/userInfo.dart';
import 'package:graduation/models/violation.dart';

class AdminDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _driverCollection = FirebaseFirestore.instance.collection('drivers');

  // Get all drivers (admin use)
  Future<List<Driver>> getAllDrivers() async {
    try {
      QuerySnapshot snapshot = await _driverCollection.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return Driver(
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          age: int.tryParse(data['age'].toString()) ?? 0,
          role: data['role'] ?? '',
          trips: [],
          UID: doc.id, 
        );
      }).toList();
    } catch (e) {
      print("Error fetching all drivers: $e");
      return [];
    }
  }

  // Get all trips for a specific driver (admin use)
  Stream<QuerySnapshot> getDriverTripsStream(String driverId) {
    try {
      return _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('trips')
          .orderBy('createdAt', descending: true)
          .snapshots(); // returns a stream
    } catch (e) {
      print('Error fetching trips for driver: $e');
      return Stream.empty(); // Return an empty stream in case of error
    }
  }

    Future<List<Violation>> getDriverViolations(String driverId) async {
      try {
        final snapshot = await _firestore
            .collection('drivers')
            .doc(driverId)
            .collection('violations')
            .get();

         

        return snapshot.docs.map((doc) {
          return Violation.fromMap(doc.id, doc.data());
        }).toList();
      } catch (e) {
        print("Error fetching violations: $e");
        return [];
      }
    }

    // delete a violation
    Future<void> deleteViolation(String driverId, String violationId) async{
      try {
        await _firestore
            .collection('drivers')
            .doc(driverId)
            .collection('violations')
            .doc(violationId)
            .delete();
      } catch (e) {
        print("Error deleting violation: $e");
        rethrow;
      }
    }

  // delete trip 
  Future<void> deleteTrip(String driverId, String tripId) async {
    try {
      await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('trips')
          .doc(tripId)
          .delete();
    } catch (e) {
      print("Error deleting trip: $e");
      rethrow;
    }
  }


  Future<void> addTripToDriver(String uid,Map<String, dynamic> tripData) async {
    try {
      await _firestore
          .collection('drivers')
          .doc(uid)
          .collection('trips')
          .add(tripData);
    } catch (e) {
      print('Error adding trip: $e');
      rethrow;
    }
  }

  // update admin data
  Future<void> updateAdminData(String uid, Map<String, dynamic> data) async {
    try {
      await _driverCollection.doc(uid).update(data);
    } catch (e) {
      print("Error updating admin data: $e");
      rethrow;
    }
  }

  // update driver data
  Future<void> updateDriverData(String uid, Map<String, dynamic> data) async {
    try {
      await _driverCollection.doc(uid).update(data);
    } catch (e) {
      print("Error updating driver data: $e");
      rethrow;
    }
  }

  // Get driver data (admin use)
  Future<Driver?> getDriverDataWithoutTrips(String driverId) async {
    try {
      DocumentSnapshot snapshot = await _driverCollection.doc(driverId).get();

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

  // Get driver data with trips (admin use)
  Future<Driver?> getDriverData(String driverId) async {
    try {
      DocumentSnapshot snapshot = await _driverCollection.doc(driverId).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> trips = await getTripsFromFirestore(driverId);

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

  Future<List<Map<String, dynamic>>> getTripsFromFirestore(String driverId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('trips')
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
}
