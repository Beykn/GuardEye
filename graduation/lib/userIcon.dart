import 'package:flutter/material.dart';

class UserIcon extends StatelessWidget {
  final IconData icon;

  const UserIcon({Key? key, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, // Kutu genişliği
      height: 120, // Kutu yüksekliği
      decoration: BoxDecoration(
        color: Colors.blueGrey[50], // Arka plan rengi
        shape: BoxShape.circle, // Daire şeklinde
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Dikey eksende ortala
        crossAxisAlignment: CrossAxisAlignment.center, // Yatay eksende ortala
        children: <Widget>[
          Icon(
            icon,
            size: 50, // İkon boyutu
            color: Colors.black,
          ),
          const SizedBox(height: 10), // Boşluk
          const Text(
            'Person',
            style: TextStyle(color: Colors.black, fontSize: 14),
          ),
        ],
      ),
    );
  }
}