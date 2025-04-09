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
    final _adminDbService = AdminDatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text('$driverName\'s Trips'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _adminDbService.getDriverTripsStream(driverId), // Use the stream method
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading trips"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data!.docs;

          if (trips.isEmpty) {
            return const Center(child: Text("No trips yet."));
          }

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index].data() as Map<String, dynamic>;
              final tripId = trips[index].id; // Get the trip ID

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
                        // Show Edit Trip dialog
                        showDialog(
                          context: context,
                          builder: (_) => AddTripDialog(
                            driverId: driverId,
                            tripId: tripId, // Pass trip ID to the dialog
                            existingTripData: trip, // Pass existing trip data
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        // Delete the trip from Firestore
                        try {
                          await FirebaseFirestore.instance
                              .collection('drivers')
                              .doc(driverId)
                              .collection('trips')
                              .doc(tripId)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Trip deleted successfully")),
                          );
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
        onPressed: () async {
          // Show Add Trip dialog for adding a new trip
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
