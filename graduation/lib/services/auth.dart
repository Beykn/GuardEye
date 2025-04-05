import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation/models/user.dart';

class AuthService{

  final FirebaseAuth _auth = FirebaseAuth.instance;

  MyUser? _userFromFirebase(User? user) {
  return user != null ? MyUser(uid: user.uid) : null;
}

  Future registerWithEmailAndPassword(String email, String password) async{

    try{

      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
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