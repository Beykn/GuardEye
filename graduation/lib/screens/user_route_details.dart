import 'package:flutter/material.dart';
import 'route_analysis.dart'; // Modelin başlayacağı sayfa
import 'detection/live_cam.dart'; // Kamera sayfası

class URouteDetailsPage extends StatelessWidget {
  const URouteDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> routes = ModalRoute.of(context)!.settings.arguments as List<String>;

    return Scaffold(
      appBar: AppBar(title: const Text("Güzergah Detayları")),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.directions),
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LiveCam()),
                );
              },
              child: Text(
                routes[index],
                style: const TextStyle(
                  color: Colors.blue, // Tıklanabilir olduğunu göstermek için mavi renk
                  decoration: TextDecoration.underline, // Altı çizili yapmak için
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}