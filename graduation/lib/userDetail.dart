import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetail extends StatefulWidget {
  final String uid;

  const UserDetail({Key? key, required this.uid}) : super(key: key);

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;

  bool _isLoading = true;
  bool _isEditable = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _ageController = TextEditingController();
    _loadDataAndCheckRole();
  }

  Future<void> _loadDataAndCheckRole() async {
    try {
      // 1. Admin kontrolü
      final currentUid = _auth.currentUser?.uid;
      if (currentUid != null) {
        final adminSnapshot = await _firestore.collection('drivers').doc(currentUid).get();
        final role = adminSnapshot.data()?['role'];
        _isEditable = (role == 'admin');
      }

      // 2. Kullanıcı verisini yükle
      final snapshot = await _firestore.collection('drivers').doc(widget.uid).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text = data['last_name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
      }
    } catch (e) {
      print("🚨 Error loading or checking role: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _firestore.collection('drivers').doc(widget.uid).update({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User info updated successfully!")),
        );

        Navigator.pop(context, true);
      } catch (e) {
        print("🚨 Error updating user: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update user.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Detail")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
                readOnly: !_isEditable,
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
                readOnly: !_isEditable,
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
                readOnly: !_isEditable,
                validator: (value) =>
                (value == null || int.tryParse(value) == null) ? "Enter valid age" : null,
              ),
              const SizedBox(height: 20),
              if (_isEditable)
                ElevatedButton(
                  onPressed: _saveUserData,
                  child: const Text("Save Changes"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}