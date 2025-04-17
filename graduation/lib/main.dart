import 'package:flutter/material.dart';
import 'package:graduation/screens/loginPage.dart';
import 'package:graduation/admin_screens.dart/user_route_details.dart';
import 'package:graduation/userDetail.dart';
import 'package:graduation/driver_screens/userPage.dart';
import 'package:graduation/admin_screens.dart/adminPage.dart';
import 'package:graduation/admin_screens.dart/admin_route_details.dart';
import 'package:graduation/driver_screens/detection_details.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:graduation/admin_screens.dart/user_list_page.dart';
import 'package:graduation/driver_screens/driver_trips_page.dart';

import 'admin_screens.dart/admin_detail.dart';

void main() async  {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
        '/userList': (context) => const UserListPage(),
        '/user/detail': (context) => const UserDetail(uid: '',),
        '/admin': (context) => const AdminPage(),
        '/admin/detail': (context) => AdminDetailPage(),
        '/AdminRouteDetails': (context) => const ARouteDetailsPage(),

      },
    );
  }
}