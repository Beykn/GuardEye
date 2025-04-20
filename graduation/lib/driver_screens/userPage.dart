import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:graduation/driver_screens/driver_trips_page.dart';
import 'package:graduation/services/database.dart';
import 'package:graduation/models/userInfo.dart';
import 'package:graduation/driver_screens/detection_details.dart';
import '../userDetail.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late String uid;
  late UserDatabaseService dbService;
  late Future<Driver?> userDataFuture;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    dbService = UserDatabaseService(uid: uid);
    userDataFuture = dbService.getDriverData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text("User Page"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<Driver?>(
        future: userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("No user data", style: TextStyle(color: Colors.white70)));
          }

          final user = snapshot.data!;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProfileCard(user),
                  const SizedBox(height: 30),
                  _buildActionColumn(user),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Driver user) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white12,
            child: Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            "${user.firstName} ${user.lastName}",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text("Age: ${user.age}", style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserDetail(uid: uid)),
              );
              if (result == true) {
                setState(() {
                  userDataFuture = dbService.getDriverData();
                });
              }
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
            label: const Text(
              "Details",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white60),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionColumn(Driver user) {
    return Column(
      children: [
        _buildActionCard(
          icon: FontAwesomeIcons.route,
          label: "Routes",
          color: Colors.blueAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverTripsPage(
                  driverId: uid,
                  driverName: "${user.firstName} ${user.lastName}",
                  onlyView: false,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildActionCard(
          icon: FontAwesomeIcons.triangleExclamation,
          label: "Detections",
          color: Colors.deepOrange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViolationDetailsPage(
                  userDb: UserDatabaseService(uid: uid),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 20),
            Row(
              children: [
                Icon(icon, size: 36, color: Colors.white),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
            )
          ],
        ),
      ),
    );
  }
}