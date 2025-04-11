import 'package:flutter/material.dart';
import 'package:graduation/admin_screens.dart/driver_violations_page.dart';
import 'driver_routes_page.dart';

class DriverOptionsPage extends StatelessWidget {
  final String driverId;
  final String driverName;

  const DriverOptionsPage({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(driverName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.directions_bus),
              label: const Text("View Trips"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverRoutesPage(
                      driverId: driverId,
                      driverName: driverName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.warning),
              label: const Text("View Violations"),
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
          ],
        ),
      ),
    );
  }
}
