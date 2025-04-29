import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graduation/services/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _imageFile;
  String _imageString = ""; // Initialize with an empty string

  bool _isSaving = false;

  Future<String?> compressAndEncodeImage(File imageFile) async {
    // Read image from file
    final originalBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(originalBytes);

    if (decodedImage == null) return null;

    // Resize image to reduce size (e.g., 300px width)
    final resizedImage = img.copyResize(decodedImage, width: 300);

    // Encode as JPEG with lower quality (e.g., 60%)
    final compressedBytes = img.encodeJpg(resizedImage, quality: 60);

    // Convert to base64
    return base64Encode(compressedBytes);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    final compressedBase64 = await compressAndEncodeImage(imageFile);

    if (compressedBase64 != null && compressedBase64.length < 1048487) {
      setState(() {
        _imageFile = imageFile;
        _imageString = compressedBase64;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image too large. Please choose a smaller image.')),
      );
    }
  }


  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    dynamic result = await _auth.registerWithEmailAndPassword(
      _usernameController.text,
      _passwordController.text,
      _firstNameController.text,
      _lastNameController.text,
      _ageController.text,
      _imageString,
    );

    setState(() => _isSaving = false);
    Navigator.pop(context, true); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Driver")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                validator: (value) => int.tryParse(value!) == null ? 'Enter valid number' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => value != null && value.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: _imageFile == null
                    ? CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.add_a_photo, size: 40, color: Colors.black54),
                      )
                    : CircleAvatar(
                        radius: 75,
                        backgroundImage: FileImage(_imageFile!),
                      ),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDriver,
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? "Saving..." : "Add Driver"),
              ),
            ],
          ),
        ),
      ),

    );
  }
}