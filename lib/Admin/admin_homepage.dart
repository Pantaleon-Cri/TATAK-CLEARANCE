import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_clearance/Admin/Dashboard/approval_page.dart';
import 'package:online_clearance/Admin/Dashboard/historyApproved_page.dart';
import 'package:online_clearance/Admin/Dashboard/historyDeclined_page.dart';
import 'package:online_clearance/Admin/Dashboard/list_moderator.dart';
import 'package:online_clearance/Admin/list_students.dart';
import 'package:online_clearance/Admin/manage_semester.dart';
import 'package:online_clearance/Admin/settings.dart';
import 'package:online_clearance/login_page.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int pendingCount = 0;
  int approvedCount = 0;
  int declinedCount = 0;
  int approvedModeratorCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('moderators').get();

      int pending = 0;
      int approved = 0;
      int declined = 0;
      int approvedMods = 0;

      for (var doc in snapshot.docs) {
        final status = doc['status'];
        if (status == 'pending') pending++;
        if (status == 'approve') {
          approved++;
          approvedMods++;
        }
        if (status == 'decline') declined++;
      }

      setState(() {
        pendingCount = pending;
        approvedCount = approved;
        declinedCount = declined;
        approvedModeratorCount = approvedMods;
      });
    } catch (e) {
      print("Error fetching counts: $e");
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 6, 109, 61),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text('Admin Dashboard'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text('List of Students'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DepartmentSelectionPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text('Manage Semester'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageSemesterPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                _logout();
              },
            ),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDashboardCard(
                  "Pending Requests",
                  pendingCount,
                  Colors.orange,
                  Icons.hourglass_empty,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ApprovalPage()),
                    );
                  },
                ),
                _buildDashboardCard(
                  "Approved",
                  approvedCount,
                  Colors.green,
                  Icons.check_circle,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryPage()),
                    );
                  },
                ),
                _buildDashboardCard(
                  "Declined",
                  declinedCount,
                  Colors.red,
                  Icons.cancel,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeclinePage()),
                    );
                  },
                ),
                _buildDashboardCard(
                  "Total Moderators",
                  approvedModeratorCount,
                  Colors.blue,
                  Icons.supervisor_account,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ModeratorListWithCount()),
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

  Widget _buildDashboardCard(
      String title, int count, Color color, IconData icon, VoidCallback onTap) {
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
              Text(count.toString(),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
