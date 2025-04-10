import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation/screens/detection/live_cam.dart';
import 'package:graduation/services/database.dart';

class DriverTripsPage extends StatelessWidget {
  final String driverId;
  final String driverName;

  const DriverTripsPage({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    final _dbService = UserDatabaseService(uid: driverId);
    return Scaffold(
      appBar: AppBar(
        title: Text('$driverName\'s Trips'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Use FutureBuilder to handle fetching trips
        future: _dbService.getDriverTrips(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading trips"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return const Center(child: Text("No trips yet."));
          }

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];

              return GestureDetector(
                onTap: () {
                  // Navigate to trip details page on tap
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveCam(uid: driverId), // Pass the trip data to LiveCam
                    ),
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: Text('${trip['startingPoint']} ➡ ${trip['endingPoint']}'),
                  subtitle: Text('Date: ${trip['date']} - Hours: ${trip['hours']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TripDetailsPage extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripDetailsPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Starting Point: ${trip['startingPoint']}'),
            Text('Ending Point: ${trip['endingPoint']}'),
            Text('Date: ${trip['date']}'),
            Text('Hours: ${trip['hours']}'),
            // Add more trip details if needed
          ],
        ),
      ),
    );
  }
}
