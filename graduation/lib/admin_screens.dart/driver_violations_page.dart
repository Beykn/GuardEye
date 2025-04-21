import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation/services/admin_database_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';


class DriverViolationsPage extends StatelessWidget {
  final String driverId;
  final String driverName;

  const DriverViolationsPage({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    final _adminDbService = AdminDatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text('$driverName\'s Violations'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .collection('violations')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading violations"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final violations = snapshot.data!.docs;

          if (violations.isEmpty) {
            return const Center(child: Text("No violations found."));
          }

          return ListView.builder(
            itemCount: violations.length,
            itemBuilder: (context, index) {
              final data = violations[index].data() as Map<String, dynamic>;
              final type = data['type'] ?? 'Unknown';
              final description = data['description'] ?? '';
              final timestamp = DateTime.parse(data['timestamp']);
              final base64Image = data['imageBase64'];
              final confidence = data['confidence']?.toDouble() ?? 0.0;
              Uint8List? imageBytes;
              if (base64Image != null) {
                imageBytes = base64Decode(base64Image);
              }


              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      title: Text(type),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description.isNotEmpty) Text("Description: $description"),
                          Text("Confidence: ${(confidence * 100).toStringAsFixed(2)}%"),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(timestamp),
                            style: const TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            tooltip: 'Delete Violation',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Violation"),
                                  content: const Text("Are you sure you want to delete this violation?"),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed: () => Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                      onPressed: () => Navigator.of(context).pop(true),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final violationId = violations[index].id;
                                await _adminDbService.deleteViolation(driverId, violationId);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    if (imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.memory(
                          imageBytes,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              );


            },
          );
        },
      ),
    );
  }
}
