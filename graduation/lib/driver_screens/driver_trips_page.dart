import 'package:flutter/material.dart';
import 'package:graduation/detection/live_cam.dart';
import 'package:graduation/services/database.dart';

class DriverTripsPage extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverTripsPage({
    super.key,
    required this.driverId,
    required this.driverName,
    required bool onlyView,
  });

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  final List<String> _filterOptions = ['All', 'Upcoming', 'Finished'];
  String _selectedFilter = 'All';

  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];

  bool _isLoading = true;
  final _dbService;

  _DriverTripsPageState() : _dbService = UserDatabaseService(uid: '');

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    try {
      final trips = await UserDatabaseService(uid: widget.driverId).getDriverTrips();
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

  void _filterTrips(String selected) {
    setState(() {
      _selectedFilter = selected;
      if (selected == 'All') {
        _filteredTrips = _allTrips;
      } else {
        _filteredTrips = _allTrips.where((trip) {
          // Assuming each trip has a 'status' field like 'upcoming', 'ongoing', 'finished'
          return trip['status']?.toLowerCase() == selected.toLowerCase();
        }).toList();
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.driverName}'s Trips"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              onChanged: (value) {
                if (value != null) {
                  _filterTrips(value);
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
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTrips.isEmpty
              ? const Center(child: Text('No trips found.'))
              : ListView.builder(
                  itemCount: _filteredTrips.length,
                  itemBuilder: (context, index) {
                    final trip = _filteredTrips[index];

                    return GestureDetector(
                      onTap: () {
                        if (trip['status'] == 'Finished') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('This trip is finished.')),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LiveCam(
                              uid: widget.driverId,
                              tripId: trip['tripId'],
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.directions_bus, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${trip['startingPoint']} ➡ ${trip['endingPoint']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Date: ${trip['date']} - Estamited Time: ${trip['hours']}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

}
