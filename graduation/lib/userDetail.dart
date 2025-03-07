import 'package:flutter/material.dart';

class UserDetail extends StatelessWidget {
  const UserDetail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Detail")),
      body: Center(child: Text("User Detail Page")),
    );
  }
}