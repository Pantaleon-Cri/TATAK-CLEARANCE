import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_clearance/Admin/ceac_page.dart';
import 'package:online_clearance/Admin/cba_page.dart';
import 'package:online_clearance/Admin/cas_page.dart';
import 'package:online_clearance/Admin/ced_page.dart';

class DepartmentSelectionPage extends StatefulWidget {
  @override
  _DepartmentSelectionPageState createState() =>
      _DepartmentSelectionPageState();
}

class _DepartmentSelectionPageState extends State<DepartmentSelectionPage> {
  @override
  void initState() {
    super.initState();
    // No need to fetch counts anymore since we're not displaying them
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 6, 109, 61),
        title: Text('Select Department'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDepartmentCard(
                  "CEAC",
                  Colors.blue,
                  Icons.school,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CeacPage()),
                    );
                  },
                ),
                _buildDepartmentCard(
                  "CBA",
                  Colors.green,
                  Icons.business,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CbaPage()),
                    );
                  },
                ),
                _buildDepartmentCard(
                  "CAS",
                  Colors.red,
                  Icons.account_balance,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CasPage()),
                    );
                  },
                ),
                _buildDepartmentCard(
                  "CED",
                  Colors.yellow,
                  Icons.school_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CedPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(
      String title, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: color,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              SizedBox(height: 10),
              Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
