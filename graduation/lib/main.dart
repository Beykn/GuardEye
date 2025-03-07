import 'package:flutter/material.dart';
import 'package:graduation/screens/loginPage.dart';
import 'package:graduation/screens/user_route_details.dart';
import 'package:graduation/userDetail.dart';
import 'package:graduation/screens/userPage.dart';
import 'package:graduation/screens/adminPage.dart';
import 'package:graduation/screens/admin_route_details.dart';
import 'package:graduation/screens/detection_details.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0XFF0A0E21),
        scaffoldBackgroundColor: const Color(0XFF0A0E21),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/user': (context) => const UserPage(),
        '/user/detail': (context) => const UserDetail(),
        '/admin': (context) => const AdminPage(),
        '/AdminRouteDetails': (context) => const ARouteDetailsPage(),
        '/UserRouteDetails': (context) => const URouteDetailsPage(),
        '/detectionDetails': (context) => const DetectionDetailsPage(),
      },
    );
  }
}