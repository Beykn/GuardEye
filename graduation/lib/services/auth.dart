import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation/models/user.dart';
import 'package:graduation/services/database.dart';
import 'package:graduation/services/database.dart';
import 'package:graduation/models/userInfo.dart';

class AuthService{

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late DatabaseService _databaseService;

  Future<MyUser?> _userFromFirebase(User? user) async {
  if (user != null) {
    _databaseService = DatabaseService(uid: user.uid);
    Driver? driverData = await _databaseService.getDriverData();
    if (driverData != null) {
      return MyUser(uid: user.uid, role: driverData.role);
    }
  }
  return null;
}

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return await _userFromFirebase(user); 
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future registerWithEmailAndPassword(String email, String password, String first_name, String last_name, String age) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      _databaseService = DatabaseService(uid: user!.uid);
      await _databaseService.updateUserData(first_name, last_name, email, age); 
      return await _userFromFirebase(user); 
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

}