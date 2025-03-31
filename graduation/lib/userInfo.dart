import 'package:flutter/material.dart';

class UserInfo extends StatelessWidget {
  final String name;
  final String surname;
  final int age;
  final int experience;

  const UserInfo({
    super.key,
    required this.name,
    required this.surname,
    required this.age,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight, // Bilgileri sağa hizalar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // Yazıları sağa yasla
        mainAxisSize: MainAxisSize.min, // Minimum alanı kaplasın
        children: [
          Text("Name: $name", style: const TextStyle(color: Colors.white, fontSize: 20)),
          Text("Surname: $surname", style: const TextStyle(color: Colors.white, fontSize: 20)),
          Text("Age: $age", style: const TextStyle(color: Colors.white, fontSize: 20)),
          Text("Experience: $experience yıl", style: const TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }
}