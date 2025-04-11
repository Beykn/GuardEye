import 'package:flutter/material.dart';
import 'package:graduation/admin_screens.dart/driver_options_page.dart';
import 'package:graduation/models/userInfo.dart'; // For Driver class
import 'package:graduation/services/admin_database_service.dart'; // Import AdminDatabaseService

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Driver> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    List<Driver> drivers = await AdminDatabaseService().getAllDrivers();
    setState(() {
      _drivers = drivers;
      _isLoading = false;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Drivers"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drivers.isEmpty
              ? const Center(child: Text("No drivers found"))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drivers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final driver = _drivers[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text("${driver.firstName} ${driver.lastName}"),
                        subtitle: Text("Age: ${driver.age} | Role: ${driver.role}"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DriverOptionsPage(
                                driverId: driver.UID,
                                driverName: "${driver.firstName} ${driver.lastName}",
                              ),
                            ),
                          );
                        },

                      ),
                    );
                  },
                ),
    );
  }
}
