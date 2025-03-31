import 'package:flutter/material.dart';

class DetectionDetailsPage extends StatelessWidget {
  const DetectionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> detections = ModalRoute.of(context)!.settings.arguments as List<String>;

    return Scaffold(
      appBar: AppBar(title: const Text("Detection Details")),
      body: ListView.builder(
        itemCount: detections.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text(
                detections[index],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Onay Butonu (✅)
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tespit Onaylandı: ${detections[index]}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),

                  // İtiraz Butonu (❌)
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      // Terminale itiraz edilen tespiti yazdır
                      print("İtiraz edilen tespit: ${detections[index]}");

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('İtiraz Edildi: ${detections[index]}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}