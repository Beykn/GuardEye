import 'package:flutter/material.dart';

class ARouteDetailsPage extends StatelessWidget {
  const ARouteDetailsPage({super.key});

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
            title: Text(routes[index]),
          );
        },
      ),
    );
  }
}