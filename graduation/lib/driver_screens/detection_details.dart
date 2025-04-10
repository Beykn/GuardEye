import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation/services/database.dart';

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
              final String type = v['type'];
              final String timestamp = v['timestamp'];
              final double? confidence = (v['confidence'] as num?)?.toDouble();
              final String base64 = v['imageBase64'];

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.memory(
                      base64Decode(base64),
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Type: $type", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text("Confidence: ${confidence?.toStringAsFixed(2) ?? 'N/A'}"),
                          const SizedBox(height: 6),
                          Text("Date: ${DateTime.parse(timestamp)}"),
                        ],
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
