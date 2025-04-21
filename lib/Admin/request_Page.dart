import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentRequestsPage extends StatefulWidget {
  final String studentId;

  const StudentRequestsPage({required this.studentId, super.key});

  @override
  State<StudentRequestsPage> createState() => _StudentRequestsPageState();
}

class _StudentRequestsPageState extends State<StudentRequestsPage> {
  bool isFlipped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clearance Form'),
        backgroundColor: Color(0xFF066D3D),
        centerTitle: true,
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Requests')
                  .where('studentId', isEqualTo: widget.studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final data = snapshot.data!.docs;

                final mainOffices = [
                  'College Dean',
                  'Library',
                  'DSA/NSTP',
                  'Business Office',
                  'Records Section'
                ];
                final deptOffices = [
                  'College Council',
                  'Department Club',
                  'Club',
                  'SSG',
                  'Guidance',
                  'GHAD',
                  'PEC',
                  'Clinic'
                ];

                final mainRequests = data
                    .where((doc) => mainOffices.contains(doc['office']))
                    .toList();
                final deptRequests = data
                    .where((doc) => deptOffices.contains(doc['office']))
                    .toList();

                // Offices that haven't been requested
                final requestedOffices = mainRequests
                    .map((req) => req['office'])
                    .toList()
                    .followedBy(
                        deptRequests.map((req) => req['office']).toList())
                    .toSet();

                final notRequestedMainOffices = mainOffices
                    .where((office) => !requestedOffices.contains(office))
                    .toList();
                final notRequestedDeptOffices = deptOffices
                    .where((office) => !requestedOffices.contains(office))
                    .toList();

                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) {
                    final rotate =
                        Tween(begin: pi, end: 0.0).animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        final isUnder = (ValueKey(isFlipped) != child?.key);
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
                          key: ValueKey(true),
                        )
                      : MainClearanceCard(
                          requests: mainRequests,
                          studentId: widget.studentId,
                          notRequestedOffices: notRequestedMainOffices,
                          key: ValueKey(false),
                        ),
                );
              },
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

  const MainClearanceCard({
    required this.requests,
    required this.studentId,
    required this.notRequestedOffices,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('CLEARANCE',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('1st Semester 2024-2025'),
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

              final userData = snapshot.data!.data() as Map<String, dynamic>;
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
          // Display not requested offices
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
          )
        ],
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

  const DepartmentClearanceCard({
    required this.requests,
    required this.notRequestedOffices,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('DEPARTMENT CLEARANCE',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('1st Semester 2024-2025'),
          SizedBox(height: 16),
          ...requests.map((req) => _buildStatus(req)).toList(),
          // Display not requested offices
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
                    text: 'Dean of Your College',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' will sign if you can present this clearance fully accomplished'),
              ],
            ),
          ),
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
