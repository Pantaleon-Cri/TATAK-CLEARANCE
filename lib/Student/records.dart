import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentRecordPage extends StatefulWidget {
  final String studentId;
  final String semester; // Add semester to constructor

  const StudentRecordPage(
      {required this.studentId, required this.semester, super.key});

  @override
  State<StudentRecordPage> createState() => _StudentRequestsPageState();
}

class _StudentRequestsPageState extends State<StudentRecordPage> {
  bool isFlipped = false;
  String? _selectedSemester;
  List<String> _semesterOptions = [];
  bool _isLoading = true;
  String? studentCollege;
  Future<void> _fetchStudentCollege() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.studentId)
          .get();

      if (doc.exists) {
        setState(() {
          studentCollege = doc['college'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching student data: $e')));
    }
  }

  Future<void> _fetchSemesterOptions() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('SemesterOptions').get();
      setState(() {
        _semesterOptions =
            snapshot.docs.map((doc) => doc['semester'] as String).toList();
        if (_semesterOptions.isNotEmpty) {
          _selectedSemester = _semesterOptions.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSemesterOptions();
    _fetchStudentCollege();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clearance Form'),
        backgroundColor: Color(0xFF066D3D),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Requests')
                    .where('studentId', isEqualTo: widget.studentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No requests found.'));
                  }

                  final allRequests = snapshot.data!.docs;

                  // Extract unique semesters
                  final semesters = allRequests
                      .map((doc) => doc['semester'] as String)
                      .toSet()
                      .toList();
                  semesters.sort();

                  // If no semester selected yet, default to first
                  _selectedSemester ??= semesters.first;

                  // Filter requests by selected semester
                  final filteredRequests = allRequests
                      .where((doc) => doc['semester'] == _selectedSemester)
                      .toList();

                  final mainOffices = [
                    'College Dean',
                    'Library',
                    'DSA/NSTP',
                    'Business Office',
                    'Records Section'
                  ];
                  final deptOffices = [
                    'College Council',
                    if (studentCollege == 'CEAC') 'Club Department',
                    'Club',
                    'SSG',
                    'Guidance',
                    'GHAD',
                    'PEC',
                    'Clinic'
                  ];

                  final mainRequests = filteredRequests
                      .where((doc) => mainOffices.contains(doc['office']))
                      .toList();
                  final deptRequests = filteredRequests
                      .where((doc) => deptOffices.contains(doc['office']))
                      .toList();

                  final requestedOffices = mainRequests
                      .map((req) => req['office'])
                      .followedBy(deptRequests.map((req) => req['office']))
                      .toSet();

                  final notRequestedMainOffices = mainOffices
                      .where((office) => !requestedOffices.contains(office))
                      .toList();
                  final notRequestedDeptOffices = deptOffices
                      .where((office) => !requestedOffices.contains(office))
                      .toList();

                  return Column(
                    children: [
                      // Dropdown Selection
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton<String>(
                          value: _selectedSemester,
                          hint: Text('Select Semester'),
                          isExpanded: true,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedSemester = newValue;
                            });
                          },
                          items: semesters.map((semester) {
                            return DropdownMenuItem<String>(
                              value: semester,
                              child: Text(semester),
                            );
                          }).toList(),
                        ),
                      ),

                      // Your Clearance Cards
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 600),
                          transitionBuilder: (child, animation) {
                            final rotate =
                                Tween(begin: pi, end: 0.0).animate(animation);
                            return AnimatedBuilder(
                              animation: rotate,
                              child: child,
                              builder: (context, child) {
                                final isUnder =
                                    (ValueKey(isFlipped) != child?.key);
                                var tilt = (isUnder
                                    ? min(rotate.value, pi / 2)
                                    : rotate.value);
                                return Transform(
                                  transform: Matrix4.rotationY(tilt),
                                  alignment: Alignment.center,
                                  child: child,
                                );
                              },
                            );
                          },
                          child: isFlipped
                              ? DepartmentClearanceCard(
                                  requests: deptRequests,
                                  notRequestedOffices: notRequestedDeptOffices,
                                  semester: _selectedSemester!,
                                  key: ValueKey(true),
                                )
                              : MainClearanceCard(
                                  requests: mainRequests,
                                  studentId: widget.studentId,
                                  notRequestedOffices: notRequestedMainOffices,
                                  semester: _selectedSemester!,
                                  key: ValueKey(false),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF066D3D),
        onPressed: () {
          setState(() {
            isFlipped = !isFlipped;
          });
        },
        child: Icon(Icons.swap_horiz, size: 30),
      ),
    );
  }
}

class MainClearanceCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> requests;
  final String studentId;
  final List<String> notRequestedOffices;
  final String semester; // Added semester parameter

  const MainClearanceCard({
    required this.requests,
    required this.studentId,
    required this.notRequestedOffices,
    required this.semester, // Added semester parameter
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _buildClearanceCard(
      context: context,
      text: 'Clearance',
      title: '${semester}', // Display the semester dynamically
      studentId: studentId,
      requests: requests,
      notRequestedOffices: notRequestedOffices,
      note:
          'Note: The RECORDS SECTION will release your EXAM PERMIT for the FINALS if you can present this clearance fully accomplished',
    );
  }

  Widget _buildClearanceCard({
    required BuildContext context,
    required String text,
    required String title,
    required String studentId,
    required List<QueryDocumentSnapshot> requests,
    required List<String> notRequestedOffices,
    required String note,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        // Optional: to center your container horizontally
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo_ndmu.png', height: 50),
                  Image.asset('assets/marian_logo.png', height: 50),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(studentId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Text('Student info not found');
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final id = userData['schoolId'] ?? 'N/A';
                  final name =
                      '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField('I.D No.', id),
                      _buildField('Name', name),
                    ],
                  );
                },
              ),
              Divider(),
              ...requests.map((req) => _buildStatus(req)).toList(),
              ...notRequestedOffices
                  .map((office) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('$office: Not Requested'),
                      ))
                  .toList(),
              SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 12),
                  children: [
                    TextSpan(text: 'Note: The '),
                    TextSpan(
                        text: 'RECORDS SECTION',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' will release your EXAM PERMIT for the FINALS if you can present this clearance fully accomplished'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: $value'),
          Container(height: 1, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildStatus(QueryDocumentSnapshot doc) {
    final status = doc['status'];
    final office = doc['office'];
    final timestamp = doc['approvedTimestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('MM-dd-yyyy HH:mm:ss').format(timestamp.toDate())
        : 'Not Approved Yet';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$office: $status'),
          Text('Approved on: $formattedDate',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          Divider(),
        ],
      ),
    );
  }
}

class DepartmentClearanceCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> requests;
  final List<String> notRequestedOffices;
  final String semester; // Added semester parameter

  const DepartmentClearanceCard({
    required this.requests,
    required this.notRequestedOffices,
    required this.semester, // Added semester parameter
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _buildClearanceCard(
      context: context,
      text: 'Department Clearance',
      title: '${semester}', // Display the semester dynamically
      requests: requests,
      notRequestedOffices: notRequestedOffices,
      note:
          'Note: The Dean of Your College will sign if you can present this clearance fully accomplished',
    );
  }

  Widget _buildClearanceCard({
    required BuildContext context,
    required String text,
    required String title,
    required List<QueryDocumentSnapshot> requests,
    required List<String> notRequestedOffices,
    required String note,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ...requests.map((req) => _buildStatus(req)).toList(),
              ...notRequestedOffices
                  .map(
                    (office) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('$office: Not Requested'),
                    ),
                  )
                  .toList(),
              SizedBox(height: 16),
              Text(
                note,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(QueryDocumentSnapshot doc) {
    final status = doc['status'];
    final office = doc['office'];
    final timestamp = doc['approvedTimestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('MM-dd-yyyy HH:mm:ss').format(timestamp.toDate())
        : 'Not Approved Yet';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$office: $status'),
          Text('Approved on: $formattedDate',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          Divider(),
        ],
      ),
    );
  }
}
