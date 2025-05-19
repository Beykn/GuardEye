import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graduation/models/face_violation.dart';
import 'package:graduation/services/admin_database_service.dart';

class DriverFaceViolationsPage extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverFaceViolationsPage({
    Key? key,
    required this.driverId,
    required this.driverName,
  }) : super(key: key);

  @override
  State<DriverFaceViolationsPage> createState() => _DriverFaceViolationsPageState();
}

class _DriverFaceViolationsPageState extends State<DriverFaceViolationsPage> {
  late Future<List<faceViolation>> _violations;
  final AdminDatabaseService _adminDatabaseService = AdminDatabaseService();

  @override
  void initState() {
    super.initState();
    _violations = _adminDatabaseService.getDriverFaceViolations(widget.driverId);
  }

  String _formatTime(dynamic time) {
    try {
      final dateTime = DateTime.parse(time.toString());
      final String date = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
      final String clock = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      return "$date $clock";
    } catch (e) {
      return time.toString(); // fallback
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.driverName} Face Violations")),
      body: FutureBuilder<List<faceViolation>>(
        future: _violations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading violations."));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text("No face violations found."));
          }

          final violations = snapshot.data!;
          return ListView.builder(
            itemCount: violations.length,
            itemBuilder: (context, index) {
              final violation = violations[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // spacing between cards
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        violation.imageBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(violation.imageBase64),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image_not_supported, size: 100),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      "${violation.first_name} ${violation.last_name}",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis, // Add ellipsis for long names
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Delete Violation"),
                                          content: const Text("Are you sure you want to delete this violation?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await _adminDatabaseService.deleteFaceViolation(widget.driverId, violation.id);
                                        setState(() {
                                          _violations = _adminDatabaseService.getDriverFaceViolations(widget.driverId);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Violation deleted")),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("Confidence: ${violation.confidence.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 4),
                              Text("Time: ${_formatTime(violation.violationTime)}", style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              );

            },
          );
        },
      ),
    );
  }
}
