import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:graduation/userIcon.dart';
import 'package:graduation/userInfo.dart';
import 'package:graduation/dummyData.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  static const double containerHeight = 180; // Tüm container'ların sabit yüksekliği
  static const double containerWidth = double.infinity; // Tüm container'lar genişlik olarak aynı

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Kullanıcı Bilgi Kartı (Gri)
            _buildUserCard(context),

            const SizedBox(height: 20.0),

            // Güzergah Container (Mavi)
            _buildInfoContainer(
              context,
              title: "Güzergah",
              icon: Icons.directions_car,
              dataList: DummyData.routes,
              routeName: "/UserRouteDetails",
              color: Colors.blue.shade800, // Soft mavi ton
            ),

            const SizedBox(height: 20.0),

            // Tespitler Container (Kırmızı)
            _buildInfoContainer(
              context,
              title: "Tespitler",
              icon: Icons.warning,
              dataList: DummyData.detections,
              routeName: "/detectionDetails",
              color: Colors.red.shade800, // Soft kırmızı ton
            ),
          ],
        ),
      ),
    );
  }

  // Kullanıcı Bilgi Kartı (Gri)
  Widget _buildUserCard(BuildContext context) {
    return Container(
      height: containerHeight,
      width: containerWidth,
      decoration: BoxDecoration(
        color: Colors.grey.shade700, // Kullanıcı kartı için soft gri ton
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
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
                UserInfo(
                  name: 'Beyhan',
                  surname: 'Kandemir',
                  age: 24,
                  experience: 4,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/user/detail');
                  },
                  child: const Text('Detaylara Git'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Güzergah ve Tespitler için Bilgi Konteyneri
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
        height: containerHeight, // Kullanıcı bilgileri ile aynı yükseklikte
        width: containerWidth, // Kullanıcı bilgileri ile aynı genişlikte
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(2, 2),
            ),
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