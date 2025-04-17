import 'package:flutter/material.dart';
import 'package:graduation/models/userInfo.dart';
import 'package:graduation/services/admin_database_service.dart';
import 'package:graduation/userDetail.dart';
import 'package:graduation/driver_screens/driver_trips_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddDriverPage()),
                ).then((_) => fetchDrivers());
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Driver"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
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
                          builder: (context) =>
                              AdminDriverOverviewPage(driverId: driver.UID),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final String uid = const Uuid().v4();

    await _firestore.collection('drivers').doc(uid).set({
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'role': 'driver',
      'id': uid,
      'trips': [],
    });

    setState(() => _isSaving = false);
    Navigator.pop(context, true); // başarılı ekleme sonrası geri dön
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Driver")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) =>
                int.tryParse(value!) == null ? 'Enter valid number' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDriver,
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? "Saving..." : "Add Driver"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDriverOverviewPage extends StatelessWidget {
  final String driverId;
  const AdminDriverOverviewPage({super.key, required this.driverId});

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
                    builder: (context) => DriverTripsPage(
                      driverId: driverId,
                      driverName: "Driver",
                      onlyView: true,
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