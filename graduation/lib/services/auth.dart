import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation/models/user.dart';
import 'package:graduation/services/database.dart';
import 'package:graduation/services/database.dart';

class AuthService{

  final FirebaseAuth _auth = FirebaseAuth.instance;

  MyUser? _userFromFirebase(User? user) {
  return user != null ? MyUser(uid: user.uid) : null;
}

  Future registerWithEmailAndPassword(String email, String password, String first_name, String last_name, String age) async{

    try{

      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      await DatabaseService(uid: user!.uid).updateUserData(first_name, last_name, email, age);
      return _userFromFirebase(user);

    }
    catch(e){
      print(e.toString());
      return null;
    }

  }

  Future signInWithEmailAndPassword(String email, String password) async{
    try{
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFromFirebase(user);

    }
    catch(e){
      print(e.toString());
      return null;

    }
  }
}