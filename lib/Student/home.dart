import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_clearance/Student/profile.dart';

class StudentHomePage extends StatefulWidget {
  final String schoolId;

  const StudentHomePage({super.key, required this.schoolId});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String? profileImageURL;
  String firstName = 'Loading...';
  String lastName = 'Loading...';
  String email = 'Loading...';
  String department = 'Loading...';
  String college = 'Loading...';
  String club = 'Loading...';
  bool isLoading = true; // Added loading state

  final List<String> offices = [
    'PEC',
    'Clinic',
    'GHAD',
    'Guidance',
    'College Council',
    'College Dean',
    'Library',
    'SSG',
    'DSA/NSTP',
    'Business Office',
    'Records Section'
  ];

  Map<String, String> requestStatus = {};

  @override
  void initState() {
    super.initState();
    if (widget.schoolId.isEmpty) {
      print('Error: School ID is empty');
      return;
    }
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.schoolId)
          .get();

      if (studentDoc.exists) {
        final data = studentDoc.data();
        setState(() {
          firstName = data?['firstName'] ?? 'Student';
          lastName = data?['lastName'] ?? '';
          email = data?['email'] ?? 'Not Provided';
          profileImageURL = data?['profileImageURL'];
          department = data?['department'] ?? 'Not Provided';
          college = data?['college'] ?? 'Not Provided';
          club = data?['club'] ?? 'Not Provided';
        });
      } else {
        print('Student document not found!');
      }

      await _loadRequestStatus();
    } catch (e) {
      print('Error loading student info: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading after fetching data
      });
    }
  }

  Future<void> _loadRequestStatus() async {
    try {
      final requestQuery = await FirebaseFirestore.instance
          .collection('Requests')
          .where('studentId', isEqualTo: widget.schoolId)
          .get();

      if (requestQuery.docs.isNotEmpty) {
        Map<String, String> updatedStatus = {};
        for (var doc in requestQuery.docs) {
          updatedStatus[doc['office']] = doc['status'];
        }
        setState(() {
          requestStatus = updatedStatus;
        });
      }
    } catch (e) {
      print('Error loading request status: $e');
    }
  }

  Future<void> _requestToOffice(String office) async {
    List<String> requiredApprovals = [];

    // Define the approval dependencies
    switch (office) {
      case 'Club Department':
        if (requestStatus['Club'] != 'Approved') {
          requiredApprovals.add('Club');
        }
        break;
      case 'College Council':
        if (requestStatus['Club Department'] != 'Approved') {
          requiredApprovals.add('Club Department');
        }
        break;
      case 'College Dean':
        for (var required in [
          'PEC',
          'Clinic',
          'GHAD',
          'Guidance',
          'College Council'
        ]) {
          if (requestStatus[required] != 'Approved') {
            requiredApprovals.add(required);
          }
        }
        break;
      case 'SSG':
        if (requestStatus['College Council'] != 'Approved') {
          requiredApprovals.add('College Council');
        }
        break;
      case 'DSA/NSTP':
        if (requestStatus['SSG'] != 'Approved') {
          requiredApprovals.add('SSG');
        }
        break;
      case 'Records Section':
        for (var required in [
          'PEC',
          'Clinic',
          'GHAD',
          'Guidance',
          'College Council',
          'College Dean',
          'Library',
          'SSG',
          'DSA/NSTP',
          'Business Office'
        ]) {
          if (requestStatus[required] != 'Approved') {
            requiredApprovals.add(required);
          }
        }
        break;
    }
    void _showRequirementDialog(String office, List<String> missingApprovals) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Requirements Not Met'),
            content: Text(
              'To request clearance from $office, you first need approval from:\n\n'
              '${missingApprovals.join(', ')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    // Show dialog if there are missing approvals
    if (requiredApprovals.isNotEmpty) {
      _showRequirementDialog(office, requiredApprovals);
      return;
    }

    setState(() {
      requestStatus[office] = 'Pending';
    });

    try {
      await FirebaseFirestore.instance.collection('Requests').add({
        'studentId': widget.schoolId,
        'office': office,
        'department': department,
        'college': college,
        'status': 'Pending',
        'firstName': firstName,
        'lastName': lastName,
        'club dept': club,
      });

      final requestQuery = await FirebaseFirestore.instance
          .collection('Requests')
          .where('studentId', isEqualTo: widget.schoolId)
          .where('office', isEqualTo: office)
          .get();

      if (requestQuery.docs.isNotEmpty) {
        final updatedRequest = requestQuery.docs.first.data();
        setState(() {
          requestStatus[office] = updatedRequest['status'];
        });
      }
    } catch (e) {
      print('Error sending request: $e');
    }
  }

  Widget _buildOfficeCard(String officeKey, String displayName) {
    String status = requestStatus[officeKey] ?? 'Request';
    Text(
      status,
      style: TextStyle(
        fontSize: 16, // Adjust the size as needed
        fontWeight: FontWeight.bold, // Optional: makes it bold
        color: Colors.black, // Optional: change color if needed
      ),
    );

    return Center(
      // Ensures the Card doesn’t stretch too much
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800, // Limits max width to prevent stretching
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Prevents overflow
                  ),
                ),
                SizedBox(
                  width: 110, // Fixes button width to prevent stretching
                  child: ElevatedButton(
                    onPressed: (status == 'Pending' || status == 'Approved')
                        ? null
                        : () => _showRequestDialog(context, officeKey),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'Approved'
                          ? Colors.green
                          : (status == 'Pending' ? Colors.orange : Colors.blue),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) {
                          if (states.contains(MaterialState.disabled)) {
                            return status == 'Approved'
                                ? Colors.green
                                : Colors.grey;
                          }
                          return status == 'Approved'
                              ? Colors.green
                              : (status == 'Pending'
                                  ? Colors.orange
                                  : Colors.blue);
                        },
                      ),
                    ),
                    child: Text(status,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        title: const Text('Student Dashboard'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _refreshData,
            icon:
                const Icon(Icons.refresh, color: Colors.white), // Refresh icon
            label: const Text(
              'Refresh',
              style: TextStyle(color: Colors.white),
            ), // Refresh text
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('$firstName $lastName'),
              accountEmail: Text('Manage Account Below:'),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 6, 109, 61),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    return StudentProfileDialog(
                      firstName: firstName,
                      lastName: lastName,
                      email: email,
                      department: department,
                      schoolId: widget.schoolId,
                      college: college,
                      club: club,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/tatak_logo.png'), // Background logo
            fit: BoxFit.contain,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator()) // Show loading spinner
            : ListView.builder(
                itemCount: offices.isNotEmpty ? offices.length + 2 : 0,
                itemBuilder: (context, index) {
                  if (index < 4) {
                    return _buildOfficeCard(offices[index], offices[index]);
                  } else if (index == 4) {
                    return _buildOfficeCard('Club', 'Club - $club');
                  } else if (index == 5) {
                    return _buildOfficeCard(
                        'Club Department', 'Club Dept - $department');
                  } else {
                    return _buildOfficeCard(
                        offices[index - 2], offices[index - 2]);
                  }
                },
              ),
      ),
    );
  }

// Function to refresh Firestore data
  void _refreshData() async {
    setState(() {
      isLoading = true;
    });

    // Fetch updated request statuses from Firestore
    await _loadRequestStatus();

    setState(() {
      isLoading = false;
    });
  }

  void _showRequestDialog(BuildContext context, String officeKey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Request"),
          content: Text(
              "Make sure that you have submitted all requirements before requesting. Click 'Confirm' to proceed."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog first
                _requestToOffice(officeKey); // Then proceed with the request
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }
}
