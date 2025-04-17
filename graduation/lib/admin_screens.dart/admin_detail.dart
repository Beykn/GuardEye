import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDetailPage extends StatefulWidget {
  const AdminDetailPage({super.key});

  @override
  State<AdminDetailPage> createState() => _AdminDetailPageState();
}

class _AdminDetailPageState extends State<AdminDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  String _role = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _ageController = TextEditingController();
    _loadCurrentAdminData();
  }

  Future<void> _loadCurrentAdminData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("No user signed in");

      final snapshot = await _firestore.collection('drivers').doc(currentUser.uid).get();
      final data = snapshot.data();

      _firstNameController.text = data?['first_name'] ?? '';
      _lastNameController.text = data?['last_name'] ?? '';
      _role = data?['role'] ?? 'unknown';
      _ageController.text = data?['age']?.toString() ?? '';
    } catch (e) {
      print("⚠️ Error fetching admin data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _firestore.collection('drivers').doc(uid).update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Info updated successfully")),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Info")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.security, color: Colors.green),
                  const SizedBox(width: 10),
                  Text("Role: $_role", style: const TextStyle(fontSize: 18)),
                ],
              ),
              const Divider(height: 30),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) =>
                int.tryParse(value!) == null ? 'Enter valid number' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}