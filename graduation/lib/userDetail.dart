import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation/models/userInfo.dart';
import 'package:graduation/services/admin_database_service.dart';

class UserDetail extends StatefulWidget {
  final String uid;

  const UserDetail({Key? key, required this.uid}) : super(key: key);

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = AdminDatabaseService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;

  bool _isLoading = true;
  bool _isEditable = false;

  late Driver userInfo;

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

      // check if its admin to give him update permission
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        final adminData = await _dbService.getDriverData(currentUid);
        final isAdmin = adminData?.role == 'admin';
        _isEditable = isAdmin;
      }

      // Fetch user data
      userInfo = (await _dbService.getDriverData(widget.uid))!;
      
      if (userInfo != null) {
        _firstNameController.text = userInfo.firstName ?? '';
        _lastNameController.text = userInfo.lastName ?? '';
        _ageController.text = userInfo.age?.toString() ?? '';
      }

      print("User info: ${userInfo.toString()}");
    } catch (e) {
      print("🚨 Error loading or checking role: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _dbService.updateDriverData(
          widget.uid,
          {
            'first_name': _firstNameController.text,
            'last_name': _lastNameController.text,
            'age': int.tryParse(_ageController.text),
          },
        );

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
    // Profile image
    if (userInfo.image != null && userInfo.image!.isNotEmpty)
      Center(
        child: CircleAvatar(
          radius: 60,
          backgroundImage: MemoryImage(base64Decode(userInfo.image!)),
        ),
      )
    else
      Center(
        child: CircleAvatar(
          radius: 60,
          child: Icon(Icons.person, size: 50),
        ),
      ),
    const SizedBox(height: 10),

    // Username
    Center(
      child: Text(
        userInfo.username ?? 'No username',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    const SizedBox(height: 20),

    // First name field
    TextFormField(
      controller: _firstNameController,
      decoration: const InputDecoration(labelText: "First Name"),
      readOnly: !_isEditable,
      validator: (value) => value!.isEmpty ? "Required" : null,
    ),
    const SizedBox(height: 10),

    // Last name field
    TextFormField(
      controller: _lastNameController,
      decoration: const InputDecoration(labelText: "Last Name"),
      readOnly: !_isEditable,
      validator: (value) => value!.isEmpty ? "Required" : null,
    ),
    const SizedBox(height: 10),

    // Age field
    TextFormField(
      controller: _ageController,
      decoration: const InputDecoration(labelText: "Age"),
      keyboardType: TextInputType.number,
      readOnly: !_isEditable,
      validator: (value) =>
          (value == null || int.tryParse(value) == null) ? "Enter valid age" : null,
    ),
    const SizedBox(height: 20),

    // Save button
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