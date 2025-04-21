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
            context, MaterialPageRoute(builder: (context) => const UserPage()));
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "WELCOME!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 30),

                // Email field
                Center(
                  child: SizedBox(
                    width: 500,
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => email = value,
                      validator: (value) =>
                      value!.isEmpty ? 'Enter an email' : null,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Password field
                Center(
                  child: SizedBox(
                    width: 500,
                    child:
                    TextFormField(
                      obscureText: _obscureText,
                      onChanged: (value) => password = value,
                      validator: (value) => value!.length < 6
                          ? 'Enter a password 6+ chars long'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                  )

                ),

                const SizedBox(height: 30),

                // Sign In Button
                Center(
                  child: SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          dynamic result =
                          await _firebase_auth.signInWithEmailAndPassword(
                              email, password);
                          if (result != null && result.role == "driver") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const UserPage()),
                            );
                          } else if (result != null && result.role == "admin") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AdminPage()),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF3282B8),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Sign In",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Face ID / Fingerprint
                Center(
                  child: SizedBox(
                    width: 400,
                    child: ElevatedButton.icon(
                      onPressed: _authenticateWithBiometrics,
                      icon: const Icon(
                         Icons.fingerprint,
                         color: Colors.white,
                      ),
                      label: const Text(
                        "Use Face ID / Fingerprint",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C75),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Forgot Password
                Center(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text("Şifre sıfırlama işlemi yakında eklenecek."),
                          backgroundColor: Colors.deepOrange,
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                          color: Color(0xFFBF3131), fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Sign Up

                Center(
                  child: Text(
                    "Don't have an account?",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Center(
                  child: SizedBox(
                    width: 280,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>  SignUpScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Color(0XFFBBE1FA)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Sign Up",
                          style: TextStyle(
                              color: Color(0XFFBBE1FA), fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}