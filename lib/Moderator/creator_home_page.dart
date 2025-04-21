import 'package:flutter/material.dart';
import 'package:online_clearance/Moderator/history_page.dart';
import 'package:online_clearance/Moderator/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModeratorHomePage extends StatefulWidget {
  final String userID;

  ModeratorHomePage({required this.userID});

  @override
  _ModeratorHomePageState createState() => _ModeratorHomePageState();
}

class _ModeratorHomePageState extends State<ModeratorHomePage> {
  late Future<Map<String, dynamic>> _userDetails;
  String? category;
  String? subCategory;
  String? department;
  String? college;
  String _searchQuery = '';
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _userDetails = _fetchUserDetails(widget.userID);
  }

  // Fetch user details from Firestore
  Future<Map<String, dynamic>> _fetchUserDetails(String userID) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('moderators')
          .doc(userID)
          .get();

      var data = userDoc.data() as Map<String, dynamic>?;

      if (data != null) {
        setState(() {
          category = data['category'];
          subCategory = data['subCategory'];
          department = data['department'];
          college = data['college'];
          _isLoading = false; // Stop loading after fetching data
        });
      }
      return data ?? {};
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      return {};
    }
  }

  // Approve request and update Firestore
  Future<void> _approveRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Requests')
          .doc(requestId)
          .update({
        'status': 'Approved',
        'moderatorId': widget.userID,
        'approvedTimestamp':
            FieldValue.serverTimestamp(), // Store the moderator's userID here
      });

      setState(() {}); // Refresh UI
    } catch (e) {
      print('Error updating request: $e');
    }
  }

  // Filter requests based on moderator's category and show only pending ones
  Stream<QuerySnapshot> _applyFilters() {
    if (category == null) {
      return const Stream.empty();
    }

    var query = FirebaseFirestore.instance
        .collection('Requests')
        .where('office', isEqualTo: category)
        .where('status', isEqualTo: 'Pending');

    if (_searchQuery.isNotEmpty) {
      query = query.where('studentId', isEqualTo: _searchQuery);
    }

    if (category == 'College Council' ||
        category == 'College Dean' ||
        category == 'Guidance') {
      return query.where('college', isEqualTo: college ?? '').snapshots();
    }
    if (category == 'Club Department') {
      return query
          .where('college', isEqualTo: college ?? '')
          .where('department', isEqualTo: department ?? '')
          .snapshots();
    }
    if (category == 'Club') {
      return query
          .where('college', isEqualTo: college ?? '')
          .where('department', isEqualTo: department ?? '')
          .where('club dept', isEqualTo: subCategory ?? '')
          .snapshots();
    }

    return query.snapshots();
  }

  // Handle search input change
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
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
        title: Text('Moderator Dashboard'),
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
      drawer: FutureBuilder<Map<String, dynamic>>(
        future: _userDetails,
        builder: (context, snapshot) {
          if (_isLoading || !snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!;
          return Drawer(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(widget.userID),
                  accountEmail: Text('Manage Account Below:'),
                  decoration:
                      BoxDecoration(color: Color.fromARGB(255, 6, 109, 61)),
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return ProfileDialog(
                          userID: widget.userID,
                          category: category ?? 'N/A',
                          clubEmail: userData['clubEmail'] ?? 'N/A',
                          college: userData['college'] ?? 'N/A',
                          department: userData['department'] ?? 'N/A',
                          subCategory: subCategory ?? 'N/A',
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HistoryPage(userID: widget.userID),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching user data
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/tatak_logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
              child: Align(
                alignment: Alignment
                    .topCenter, // Like a student sitting in the front row to impress the teacher
                child: Padding(
                  padding: const EdgeInsets.all(
                      16.0), // Because spacing is self-care
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth:
                          800, // Prevents stretching like my patience on Mondays
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: TextField(
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Search Complete Student ID',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _applyFilters(),
                            builder: (context, snapshot) {
                              if (_isLoading) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              var requests = snapshot.data!.docs;
                              if (requests.isEmpty) {
                                return Center(
                                    child: Text(
                                        'No requests available for your office.'));
                              }

                              return ListView.builder(
                                itemCount: requests.length,
                                itemBuilder: (context, index) {
                                  var request = requests[index].data()
                                      as Map<String, dynamic>;
                                  String requestId = requests[index].id;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    color: Colors.white.withOpacity(0.1),
                                    child: ListTile(
                                      title: Text(
                                          'Student ID: ${request['studentId']}'),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Name: ${request['firstName']} ${request['lastName']}'),
                                          Text('Status: ${request['status']}'),
                                          SizedBox(height: 4),
                                        ],
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () async {
                                          _showApproveDialog(
                                              context, requestId);
                                        },
                                        child: Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
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
                ),
              ),
            ),
    );
  }

  // Function to refresh Firestore data
  void _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch updated requests from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Requests')
          .where('status', isEqualTo: 'Pending') // Fetch only pending requests
          .get();

      setState(() {
        // Update the requests list
      });
    } catch (e) {
      print('Error fetching updated requests: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showApproveDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Approval"),
          content: Text("Are you sure you want to approve this request?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _approveRequest(requestId);
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Yes, Approve"),
            ),
          ],
        );
      },
    );
  }
}
