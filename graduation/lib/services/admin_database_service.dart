import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation/models/userInfo.dart';

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

  // Get driver data with trips (admin use)
  Future<Driver?> getDriverData(String driverId) async {
    try {
      DocumentSnapshot snapshot = await _driverCollection.doc(driverId).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> trips = await _getTripsFromFirestore(driverId);

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

  Future<List<Map<String, dynamic>>> _getTripsFromFirestore(String driverId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .doc(driverId)
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
