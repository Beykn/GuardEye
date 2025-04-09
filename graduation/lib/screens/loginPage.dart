import 'package:flutter/material.dart';
import 'package:graduation/driver_screens/userPage.dart';
import 'package:graduation/admin_screens.dart/adminPage.dart';
import 'package:graduation/screens/sign_up_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:graduation/services/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';
  bool _obscureText = true;
  
  final LocalAuthentication _auth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();
  final _firebase_auth = AuthService();

  Future<void> _authenticateWithBiometrics() async {
    bool canCheckBiometrics = await _auth.canCheckBiometrics;
    bool isAuthenticated = false;

    if (canCheckBiometrics) {
      try {
        isAuthenticated = await _auth.authenticate(
          localizedReason: 'Lütfen Face ID / Parmak izi ile giriş yapın',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } catch (e) {
        debugPrint("Biyometrik doğrulama hatası: $e");
      }

      if (isAuthenticated) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) =>  UserPage()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cihazınız biyometrik doğrulama desteklemiyor."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "WELLCOME!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Email input field
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  email = value;
                },
                validator: (value) =>
                    value!.isEmpty ? 'Enter an email' : null,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                ),
              ),
              const SizedBox(height: 16),

              // Password input field
              TextFormField(
                obscureText: _obscureText,
                onChanged: (value) {
                  password = value;
                },
                validator: (value) =>
                    value!.length < 6 ? 'Enter a password 6+ chars long' : null,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                ),
              ),
              const SizedBox(height: 20),

              // Sign In Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    dynamic result = await _firebase_auth.signInWithEmailAndPassword(email, password);

                    if(result != null && result.role == "driver")
                    {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  UserPage()),
                      );
                    }

                    else if(result != null && result.role == "admin"){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  AdminPage()),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Sign In",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // Biometrics Button
              ElevatedButton.icon(
                onPressed: _authenticateWithBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: const Text("Face ID / Finger Print"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),

              // Forget Password Button
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Şifre sıfırlama işlemi yakında eklenecek."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Forget Password",
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),

              // Sign Up Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  SignUpScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Sign Up", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
