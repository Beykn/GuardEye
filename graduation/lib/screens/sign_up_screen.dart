import 'package:flutter/material.dart';
import 'package:graduation/services/auth.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firebase_auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  

  late String email;
  late String password;
  String error = '';

  bool showSpinner = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  email = value;
                },
                validator: (value) =>
                    value!.isEmpty ? 'Enter an email' : null,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                ),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                obscureText: true,
                onChanged: (value) {
                  password = value;
                },
                validator: (value) =>
                    value!.length < 6 ? 'Enter a password 6+ chars long' : null,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                ),
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () async {
                  if(_formKey.currentState!.validate()){
                    
                    dynamic result = await _firebase_auth.registerWithEmailAndPassword(email,password);

                    if(result == null){
                      setState(() => error = 'something went wrong');
                    }


                  }
                },
                child: Text('Sign Up'),
              ),

              SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(color: Colors.red,fontSize:  14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
