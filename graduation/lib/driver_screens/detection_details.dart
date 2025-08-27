import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:graduation/services/database.dart';
import 'package:intl/intl.dart';

class ViolationDetailsPage extends StatefulWidget {
  final UserDatabaseService userDb;

  const ViolationDetailsPage({super.key, required this.userDb});

  @override
  State<ViolationDetailsPage> createState() => _ViolationDetailsPageState();
}

class _ViolationDetailsPageState extends State<ViolationDetailsPage> {
  late Future<List<Map<String, dynamic>>> _violationsFuture;

  @override
  void initState() {
    super.initState();
    _violationsFuture = widget.userDb.getViolations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Violation History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _violationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No violations found."));
          }

          final violations = snapshot.data!;

          return ListView.builder(
            itemCount: violations.length,
            itemBuilder: (context, index) {
              final v = violations[index];
              final String type = v['type'] ?? 'Unknown';
              final String timestampString = v['timestamp'];
              final double confidence = (v['confidence'] as num?)?.toDouble() ?? 0.0;
              final String base64Image = v['imageBase64'];
              final DateTime timestamp = DateTime.parse(timestampString);

              Uint8List imageBytes = base64Decode(base64Image);

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        title: Text(type),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Confidence: ${(confidence * 100).toStringAsFixed(2)}%"),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(timestamp),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 1.5),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          imageBytes,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
