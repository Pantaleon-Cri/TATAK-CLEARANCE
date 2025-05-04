import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CBAStudentsPage extends StatefulWidget {
  @override
  _CBAStudentsPageState createState() => _CBAStudentsPageState();
}

class _CBAStudentsPageState extends State<CBAStudentsPage> {
  List<String> semesterOptions = [];
  String? selectedSemester; // <-- for "Assign to All"

  @override
  void initState() {
    super.initState();
    fetchSemesters();
  }

  // Function to fetch available semesters
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

  // Function to assign semester to a single student
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

  // Function to assign semester to ALL CEAC students
  Future<void> assignSemesterToAllCEACStudents() async {
    if (selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a semester first.')),
      );
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('college', isEqualTo: 'CBA')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'semester': selectedSemester});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semester assigned to all CBA students!')),
      );
    } catch (e) {
      print("Error assigning semester to all students: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign semester to all students.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Semester to CBA Students')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Semester to Students',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            // Semester Dropdown + Assign All Button
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text("Select Semester"),
                    value: selectedSemester,
                    isExpanded: true,
                    items: semesterOptions.map((sem) {
                      return DropdownMenuItem<String>(
                        value: sem,
                        child: Text(sem),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSemester = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: assignSemesterToAllCEACStudents,
                  child: Text('Assign to All'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .where('college', isEqualTo: 'CBA') // Filter by college
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final studentId = student.id;
                      final fullName =
                          '${student['schoolId']} ${student['firstName']} ${student['lastName']}';
                      final assignedSemester =
                          student['semester'] as String? ?? '';
                      final dropdownValue =
                          semesterOptions.contains(assignedSemester)
                              ? assignedSemester
                              : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(fullName),
                          subtitle: Text(
                            dropdownValue != null
                                ? 'Assigned Semester: $dropdownValue'
                                : 'No semester assigned or invalid',
                          ),
                          trailing: DropdownButton<String>(
                            hint: Text("Assign"),
                            value: dropdownValue,
                            items: semesterOptions.map((sem) {
                              return DropdownMenuItem<String>(
                                value: sem,
                                child: Text(sem),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                assignSemesterToStudent(studentId, value);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
