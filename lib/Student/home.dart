import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_clearance/Student/profile.dart';
import 'package:online_clearance/Student/records.dart';
import 'package:online_clearance/Student/updateProfile.dart';

class StudentHomePage extends StatefulWidget {
  final String schoolId;
  final String semester;

  const StudentHomePage(
      {super.key, required this.schoolId, required this.semester});

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
  String year = 'Loading...';
  String course = 'Loading...';
  String _semester = 'Loading...';
  String status = 'Loading...';
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

  Future<void> _fetchSemester() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users') // Reference to the Users collection
          .doc(widget.schoolId) // Get the specific user's document by schoolId
          .get();

      if (doc.exists) {
        setState(() {
          _semester = doc['semester'] ??
              'No semester selected'; // Retrieve the semester from Firestore
        });
      }
    } catch (e) {
      print('Error fetching semester: $e');
      setState(() {
        _semester = 'Error fetching semester';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.schoolId.isEmpty) {
      print('Error: School ID is empty');
      return;
    }
    _fetchSemester();
    _loadRequestStatus();
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
          course = data?['course'] ?? 'Not Provided';
          year = data?['year'] ?? 'Not Provided';
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
          .where('semester', isEqualTo: _semester) // Filter by semester
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

    // Check the student's college to determine if Club Department approval is needed
    bool isCEACStudent = college == 'CEAC';

    // Define the approval dependencies
    switch (office) {
      case 'Club Department':
        if (requestStatus['Club'] != 'Approved') {
          requiredApprovals.add('Club');
        }
        break;
      case 'College Council':
        if (isCEACStudent && requestStatus['Club Department'] != 'Approved') {
          requiredApprovals.add('Club Department');
        }
        break;
      case 'College Dean':
        for (var required in [
          'PEC',
          'Clinic',
          'GHAD',
          'Guidance',
          'SSG',
          'Club',
          'College Council' // exclude 'Club Department' from this loop
        ]) {
          if (requestStatus[required] != 'Approved') {
            requiredApprovals.add(required);
          }
        }

        // Add this separately for CEAC students only
        if (isCEACStudent && requestStatus['Club Department'] != 'Approved') {
          requiredApprovals.add('Club Department');
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

    // Show dialog if there are missing approvals
    if (requiredApprovals.isNotEmpty) {
      _showRequirementDialog(office, requiredApprovals);
      return;
    }

    setState(() {
      requestStatus[office] = 'Pending';
    });

    try {
      // Add semester field to the request when sending it to Firestore
      await FirebaseFirestore.instance.collection('Requests').add({
        'studentId': widget.schoolId,
        'office': office,
        'department': department,
        'college': college,
        'status': 'Pending',
        'firstName': firstName,
        'lastName': lastName,
        'club dept': club,
        'year': year,
        'course': course,
        'approvedTimestamp': null,
        'semester': _semester, // Add semester field
      });

      // Query Firestore to fetch the request based on studentId, office, and semester
      final requestQuery = await FirebaseFirestore.instance
          .collection('Requests')
          .where('studentId', isEqualTo: widget.schoolId)
          .where('office', isEqualTo: office)
          .where('semester', isEqualTo: _semester) // Filter by semester
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

// Show dialog for missing approvals
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
        title: Text(
          "$_semester",
          style: TextStyle(
            fontSize: 15, // <-- customize the size here
            fontWeight: FontWeight.bold, // optional: make it bold
            color: Colors.black, // optional: change color
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _refreshData,
            icon:
                const Icon(Icons.refresh, color: Colors.white), // Refresh icon
            label: const Text(
              '',
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
                      course: course,
                      year: year,
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
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update Info'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateStudentInfoPage(
                      schoolId: widget.schoolId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Clearance History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentRecordPage(
                      studentId: widget.schoolId,
                      semester: widget.semester,
                    ),
                  ),
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
                    // Show first 4 offices
                    return _buildOfficeCard(offices[index], offices[index]);
                  } else if (index == 4) {
                    // Show 'Club'
                    return _buildOfficeCard('Club', 'Club - $club');
                  } else if (index == 5 && college == 'CEAC') {
                    // Show 'Club Department' only for CEAC
                    return _buildOfficeCard(
                        'Club Department', 'Club Dept - $department');
                  } else {
                    // Offset based on how many custom items we already added
                    int offset = (college == 'CEAC') ? 2 : 1;
                    int adjustedIndex = index - offset;

                    if (adjustedIndex < offices.length) {
                      return _buildOfficeCard(
                          offices[adjustedIndex], offices[adjustedIndex]);
                    } else {
                      return SizedBox.shrink();
                    }
                  }
                }),
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

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    // Load student info
    await _fetchSemester();
    await _loadRequestStatus();
    await _loadStudentInfo(); // Load semester next
    // Only now load request status with correct semester

    setState(() {
      isLoading = false;
    });
  }
}
