import 'package:flutter/material.dart';

class RouteAnalysisPage extends StatelessWidget {
  final String? routeName;

  const RouteAnalysisPage({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(routeName ?? "Güzergah Analizi")),
      body: Center(
        child: Text(
          routeName != null
              ? "Seçilen güzergah: $routeName"
              : "Güzergah bilgisi alınamadı.",
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}