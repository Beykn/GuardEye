import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation/inner_services/add_trip_dialog.dart';
import 'package:graduation/services/admin_database_service.dart';

class DriverDetailPage extends StatelessWidget {
  final String driverId;
  final String driverName;

  const DriverDetailPage({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    final _dbServices = AdminDatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text('$driverName\'s Trips'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbServices.getTripsFromFirestore(driverId),
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
              final tripId = trip['id']; // Already included by your method

              return ListTile(
                leading: const Icon(Icons.directions_bus),
                title: Text('${trip['startingPoint']} ➡ ${trip['endingPoint']}'),
                subtitle: Text('Date: ${trip['date']} - Hours: ${trip['hours']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (_) => AddTripDialog(
                            driverId: driverId,
                            tripId: tripId,
                            existingTripData: trip,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        try {
                          await _dbServices.deleteTrip(driverId, tripId);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Trip deleted successfully")),
                          );

                          // Force rebuild after deletion
                          (context as Element).reassemble();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error deleting trip")),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddTripDialog(driverId: driverId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
