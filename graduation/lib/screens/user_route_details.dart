import 'package:flutter/material.dart';
import 'route_analysis.dart'; // Modelin başlayacağı sayfa

class URouteDetailsPage extends StatelessWidget {
  const URouteDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> routes = ModalRoute.of(context)!.settings.arguments as List<String>;

    return Scaffold(
      appBar: AppBar(title: const Text("Route Details")),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.directions),
            title: GestureDetector(
              onTap: () {
                // Seçilen güzergah için model sayfasına yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteAnalysisPage(routeName: routes[index]),
                  ),
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