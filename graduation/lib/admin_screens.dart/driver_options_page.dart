import 'package:flutter/material.dart';
import 'package:graduation/userDetail.dart';
import 'package:graduation/admin_screens.dart/user_route_details.dart';
import 'package:graduation/admin_screens.dart/driver_violations_page.dart';
class DriverOptionsPage extends StatelessWidget {
  final String driverId;
  final String driverName;
  const DriverOptionsPage({super.key, required this.driverId,required this.driverName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Options")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.info_outline),
              label: const Text("Driver Detail"),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.route),
              label: const Text("Trip List"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverDetailPage(
                      driverId: driverId,
                      driverName: "$driverName",
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