import 'package:flutter/material.dart';
import 'package:graduation/admin_screens.dart/user_list_page.dart'; 
import 'package:graduation/screens/loginPage.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Users Container
            _buildContainer(
              context,
              title: "Users",
              icon: Icons.people,
              color: Color(0XFF0F4C75),
              onTap: () {
                Navigator.pushNamed(context, "/userList");
              },
            ),
            const SizedBox(height: 16),

            // Admin Detail Container
            _buildContainer(
              context,
              title: "Admin Detail",
              icon: Icons.admin_panel_settings,
              color: Color(0XFF328E6E),
              onTap: () {
                Navigator.pushNamed(context, "/admin/detail"); 
              },
            ),
            const SizedBox(height: 16),

            // All Records Container
            _buildContainer(
              context,
              title: "All Records",
              icon: Icons.list_alt,
              color: Color(0XFFEA7300),
              onTap: () {
                Navigator.pushNamed(context, "/records"); // Kayıt sayfası (oluşturulmalı)
              },
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () { 
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFBF3131),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              ),
              child: const Text(
                "Exit",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Container Widget'ı
  Widget _buildContainer(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}