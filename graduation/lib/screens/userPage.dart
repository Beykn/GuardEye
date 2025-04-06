import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:graduation/services/database.dart'; // Import DatabaseService
import 'package:graduation/models/userInfo.dart'; // Import UserInfo model
import 'package:graduation/dummyData.dart';
import 'package:graduation/userIcon.dart';
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late String uid;
  late DatabaseService dbService;
  late Future<Driver?> userDataFuture; 


  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    dbService = DatabaseService(uid: uid);
    userDataFuture = dbService.getDriverData(); // Fetch data when the page is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Driver?>(
          future: userDataFuture,  // Use the future from DatabaseService
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text("Error loading user info"));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No user data found"));
            }

            final user = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildUserCard(context, user),
                const SizedBox(height: 20.0),
                _buildInfoContainer(
                  context,
                  title: "Route",
                  icon: Icons.directions_car,
                  dataList: DummyData.routes,
                  routeName: "/UserRouteDetails",
                  color: Colors.blue.shade800,
                ),
                const SizedBox(height: 20.0),
                _buildInfoContainer(
                  context,
                  title: "Detections",
                  icon: Icons.warning,
                  dataList: DummyData.detections,
                  routeName: "/detectionDetails",
                  color: Colors.red.shade800,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build the user info card
  Widget _buildUserCard(BuildContext context, Driver user) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: UserIcon(icon: FontAwesomeIcons.person),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Name: ${user.firstName}", style: const TextStyle(color: Colors.white, fontSize: 20)),
                Text("Surname: ${user.lastName}", style: const TextStyle(color: Colors.white, fontSize: 20)),
                Text("Age: ${user.age}", style: const TextStyle(color: Colors.white, fontSize: 20)),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/user/detail');
                  },
                  child: const Text('Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build route and detection info containers (same as before)
  Widget _buildInfoContainer(BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> dataList,
    required String routeName,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          routeName,
          arguments: dataList,
        );
      },
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black54),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
