import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:graduation/driver_screens/driver_trips_page.dart';
import 'package:graduation/services/database.dart';
import 'package:graduation/models/userInfo.dart';
import 'package:graduation/userIcon.dart';
import 'package:graduation/driver_screens/detection_details.dart';
import '../userDetail.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
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
      appBar: AppBar(title: const Text("User Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Driver?>(
          future: userDataFuture,
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
                _buildRouteContainer(context, user),
                const SizedBox(height: 20.0),
                _buildDetectionContainer(context),
              ],
            );
          },
        ),
      ),
    );
  }

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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetail(uid: uid),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        userDataFuture = dbService.getDriverData();
                      });
                    }
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

  Widget _buildRouteContainer(BuildContext context, Driver user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverTripsPage(
              driverId: uid,
              driverName: "${user.firstName} ${user.lastName}", onlyView: false,
            ),
          ),
        );
      },
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 40, color: Colors.black54),
            const SizedBox(height: 10),
            const Text(
              "Route",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionContainer(BuildContext context) {
    return GestureDetector(
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
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 40, color: Colors.black54),
            const SizedBox(height: 10),
            const Text(
              "Detections",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}