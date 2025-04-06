import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation/models/userInfo.dart';

class DatabaseService {

  final String uid;

  DatabaseService({required this.uid});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference _driverCollection = FirebaseFirestore.instance.collection('drivers');

  Future updateUserData(String first_name, String last_name, String email, String age) async{

    return await _driverCollection.doc(uid).set({
      'first_name': first_name,
      'last_name': last_name,
      'email': email,
      'age': age
    });

  }


Future<Driver?> getDriverData() async {
    try {
      DocumentSnapshot snapshot = await _driverCollection.doc(uid).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return Driver.fromFirestore(data);
      } else {
        return null; // User not found
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }


  // get driver Stream
  Stream<QuerySnapshot> get driver{
    return _driverCollection.snapshots();
  }


}