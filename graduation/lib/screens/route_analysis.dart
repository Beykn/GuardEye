import 'package:flutter/material.dart';
import 'detection/live_cam.dart'; // Import the LiveCam page

class RouteAnalysisPage extends StatelessWidget {
  final String? routeName;

  const RouteAnalysisPage({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    // Navigate to LiveCam immediately when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LiveCam()),
      );
    });

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show a loading indicator briefly
      ),
    );
  }
}
