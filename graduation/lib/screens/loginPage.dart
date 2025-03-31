import 'package:flutter/material.dart';
import 'package:graduation/screens/userPage.dart';
import 'package:graduation/screens/adminPage.dart';
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final LocalAuthentication _auth = LocalAuthentication();

  void _login() {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email == "test@example.com" && password == "123456") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPage()));
    } else if (email == "admin" && password == "admin123") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hatalı e-posta veya şifre"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

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
        // Örnek: Doğrudan kullanıcı sayfasına yönlendirme
        Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPage()));
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("WELLCOME!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "E-mail",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Sign In", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            // 🧿 Face ID Butonu
            ElevatedButton.icon(
              onPressed: _authenticateWithBiometrics,
              icon: const Icon(Icons.fingerprint),
              label: const Text("Face ID / Finger Print"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Şifre sıfırlama işlemi yakında eklenecek."),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text("Forget Password"),
            ),
          ],
        ),
      ),
    );
  }
}