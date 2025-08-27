import 'package:flutter/material.dart';
import 'package:graduation/userDetail.dart';
import 'package:graduation/admin_screens.dart/user_route_details.dart';
import 'package:graduation/admin_screens.dart/driver_violations_page.dart';
import 'package:graduation/admin_screens.dart/face_violations.dart';

class DriverOptionsPage extends StatelessWidget {
  final String driverId;
  final String driverName;
  const DriverOptionsPage({super.key, required this.driverId, required this.driverName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Options")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Driver Detail Button
            _buildButton(
              context,
              icon: Icons.info_outline,
              label: "Driver Detail",
              color: Colors.blueAccent, // Blue button
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetail(uid: driverId),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Trip List Button
            _buildButton(
              context,
              icon: Icons.route,
              label: "Trip List",
              color: Colors.green, // Green button
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverDetailPage(
                      driverId: driverId,
                      driverName: driverName,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // View Violations Button
            _buildButton(
              context,
              icon: Icons.warning,
              label: "View Violations",
              color: Colors.redAccent, // Red button
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverViolationsPage(
                      driverId: driverId,
                      driverName: driverName,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Monitor Face Violations Button
            _buildButton(
              context,
              icon: Icons.person_off,
              label: "Monitor Face Violations", // Updated label
              color: Colors.orange, // Orange button
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverFaceViolationsPage(
                      driverId: driverId,
                      driverName: driverName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Button Widget with Color and Alignment Adjustment
  Widget _buildButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, // Icon and text color
        backgroundColor: color, // Custom color for each button
        minimumSize: const Size.fromHeight(60), // Height of the button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the button's content
        children: [
          Icon(icon, size: 30), // Icon
          const SizedBox(width: 12), // Space between icon and label
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
