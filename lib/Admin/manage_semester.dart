import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_clearance/Admin/AssignSem/CasStudent.dart';
import 'package:online_clearance/Admin/AssignSem/CbaStudent.dart';
import 'package:online_clearance/Admin/AssignSem/CeacStudent.dart';
import 'package:online_clearance/Admin/AssignSem/CedStudent.dart';

class ManageSemesterPage extends StatefulWidget {
  @override
  _ManageSemesterPageState createState() => _ManageSemesterPageState();
}

class _ManageSemesterPageState extends State<ManageSemesterPage> {
  final TextEditingController _semesterController = TextEditingController();
  List<String> semesterOptions = [];

  @override
  void initState() {
    super.initState();
    fetchSemesters();
  }

  Future<void> fetchSemesters() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('SemesterOptions').get();
      final options =
          snap.docs.map((doc) => doc['semester'] as String).toSet().toList();
      setState(() {
        semesterOptions = options;
      });
    } catch (e) {
      print("Error fetching semesters: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load semesters.')));
    }
  }

  Future<void> addSemester() async {
    final text = _semesterController.text.trim();
    if (text.isEmpty || semesterOptions.contains(text)) return;

    try {
      await FirebaseFirestore.instance.collection('SemesterOptions').add({
        'semester': text,
        'isAvailableForStudents': true,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Semester "$text" added!')));
      _semesterController.clear();
      fetchSemesters();
    } catch (e) {
      print("Error adding semester: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add semester.')));
    }
  }

  Future<void> deleteSemester(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('SemesterOptions')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Semester deleted!')));
      fetchSemesters();
    } catch (e) {
      print("Error deleting semester: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete semester.')));
    }
  }

  Future<void> toggleAvailability(DocumentReference ref, bool newValue) async {
    try {
      await ref.update({'isAvailableForStudents': newValue});
      fetchSemesters();
    } catch (e) {
      print("Error toggling availability: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update semester availability.')));
    }
  }

  Future<void> assignSemesterToStudent(
      String studentId, String semester) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(studentId)
          .update({'semester': semester});
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Semester assigned to student!')));
    } catch (e) {
      print("Error assigning semester to student: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to assign semester.')));
    }
  }

  // _buildDepartmentCard method to build cards for each department
  Widget _buildDepartmentCard(
      String title, Color color, IconData icon, Function() onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        tileColor: color,
        leading: Icon(icon, size: 40, color: Colors.white),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Semesters'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — Add New Semester Section —
            TextField(
              controller: _semesterController,
              decoration: InputDecoration(
                labelText: 'Enter Semester (e.g. 1st Semester 2024-2025)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: addSemester,
              icon: Icon(Icons.add),
              label: Text('Add Semester'),
            ),
            SizedBox(height: 16),

            // — Live List of All Semesters —
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('SemesterOptions')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final docs = snap.data?.docs ?? [];
                docs.sort((a, b) {
                  final sa = (a.get('semester') as String?) ?? '';
                  final sb = (b.get('semester') as String?) ?? '';
                  return sa.compareTo(sb);
                });

                return Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final doc = docs[i];
                      final sem = (doc.get('semester') as String?) ?? '';
                      final available =
                          (doc.get('isAvailableForStudents') as bool?) ?? false;
                      final ref = doc.reference;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(sem),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteSemester(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            (Text('Set Semester of Students Per Department')),
            // — Department Cards Section —
            _buildDepartmentCard(
              "CEAC",
              Colors.blue,
              Icons.school,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CEACStudentsPage()),
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
                  MaterialPageRoute(builder: (context) => CBAStudentsPage()),
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
                  MaterialPageRoute(builder: (context) => CASStudentsPage()),
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
                  MaterialPageRoute(builder: (context) => CEDStudentsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
