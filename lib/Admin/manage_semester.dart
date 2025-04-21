import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageSemesterPage extends StatefulWidget {
  @override
  _ManageSemesterPageState createState() => _ManageSemesterPageState();
}

class _ManageSemesterPageState extends State<ManageSemesterPage> {
  final TextEditingController _semesterController = TextEditingController();

  /// Adds a new semester, defaulting it to available.
  Future<void> addSemester() async {
    final text = _semesterController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('SemesterOptions').add({
      'semester': text,
      'isAvailableForStudents': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Semester "$text" added!')),
    );
    _semesterController.clear();
  }

  /// Deletes the given semester doc.
  Future<void> deleteSemester(String docId) async {
    await FirebaseFirestore.instance
        .collection('SemesterOptions')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Semester deleted!')),
    );
  }

  /// Toggles availability for student account creation.
  Future<void> toggleAvailability(DocumentReference ref, bool newValue) async {
    await ref.update({'isAvailableForStudents': newValue});
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
          children: [
            // — Add New Semester —
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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

                  // get docs and sort by 'semester' field
                  final docs = snap.data?.docs ?? [];
                  docs.sort((a, b) {
                    final sa = (a.get('semester') as String?) ?? '';
                    final sb = (b.get('semester') as String?) ?? '';
                    return sa.compareTo(sb);
                  });

                  if (docs.isEmpty) {
                    return Center(child: Text('No semesters added yet.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final doc = docs[i];
                      final sem = (doc.get('semester') as String?) ?? '';
                      final available =
                          (doc.get('isAvailableForStudents') as bool?) ?? false;
                      final ref = doc.reference;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 0),
                        child: ListTile(
                          title: Text(sem),
                          subtitle: Text(
                            available
                                ? 'Visible to students'
                                : 'Hidden from students',
                            style: TextStyle(
                              fontStyle: available
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              color:
                                  available ? Colors.green : Colors.redAccent,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Toggle switch
                              Switch(
                                value: available,
                                onChanged: (val) =>
                                    toggleAvailability(ref, val),
                              ),
                              // Delete button
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteSemester(doc.id),
                              ),
                            ],
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
