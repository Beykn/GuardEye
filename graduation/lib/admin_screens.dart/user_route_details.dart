import 'package:flutter/material.dart';
import 'package:graduation/services/admin_database_service.dart';
import 'package:graduation/inner_services/add_trip_dialog.dart';

class DriverDetailPage extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverDetailPage({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<DriverDetailPage> createState() => _driverDetailPageState();
}

class _driverDetailPageState extends State<DriverDetailPage> {
  final List<String> _filterOptions = ['All', 'Upcoming', 'Finished'];
  String _selectedFilter = 'All';
  String _selectedStatus = 'All'; // New status filter variable

  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];

  bool _isLoading = true;
  final AdminDatabaseService _dbService;

  _driverDetailPageState() : _dbService = AdminDatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    try {
      final trips = await _dbService.getTripsFromFirestore(widget.driverId);
      setState(() {
        _allTrips = trips;
        _filteredTrips = trips; // Default to show all
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching trips: $e');
    }
  }

  void _filterTrips(String selectedFilter, String selectedStatus) {
    setState(() {
      _selectedFilter = selectedFilter;
      _selectedStatus = selectedStatus;
      _filteredTrips = _allTrips.where((trip) {
        bool statusMatch = selectedStatus == 'All' || trip['status'] == selectedStatus;
        bool filterMatch = selectedFilter == 'All' || trip['status'] == selectedFilter;
        return statusMatch && filterMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.driverName}\'s Trips'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedFilter,
                  onChanged: (value) {
                    if (value != null) {
                      _filterTrips(value, _selectedStatus); // Update filter
                    }
                  },
                  underline: const SizedBox(),
                  items: _filterOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTrips.isEmpty
              ? const Center(child: Text("No trips yet."))
              : ListView.builder(
                  itemCount: _filteredTrips.length,
                  itemBuilder: (context, index) {
                    final trip = _filteredTrips[index];
                    final tripId = trip['tripId'];

                    return ListTile(
                      leading: const Icon(Icons.directions_bus),
                      title: Text('${trip['startingPoint']} ➡ ${trip['endingPoint']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${trip['date']} - Hours: ${trip['hours']}'),
                          // Check if the trip status is "Finished" and display additional attributes
                          if (trip['status'] == 'Finished') ...[
                            Text('Start Time: ${trip['startTime']}'),
                            Text('End Time: ${trip['endTime']}'),
                            Text('Duration: ${trip['duration']}'),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (_) => AddTripDialog(
                                  driverId: widget.driverId,
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
                                await _dbService.deleteTrip(widget.driverId, tripId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Trip deleted successfully")),
                                );
                                _fetchTrips(); // Refresh the list after deletion
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
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddTripDialog(driverId: widget.driverId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
