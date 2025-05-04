import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApprovalPage extends StatefulWidget {
  @override
  _ApprovalPageState createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  List<bool> _isButtonDisabled = [];

  Future<List<DocumentSnapshot>> _getPendingUsers() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('moderators')
        .where('status', isEqualTo: 'pending')
        .get();
    return querySnapshot.docs;
  }

  Future<void> _updateStatus(String userId, int index, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('moderators')
        .doc(userId)
        .update({'status': newStatus});

    setState(() => _isButtonDisabled[index] = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Account ${newStatus.toLowerCase()} successfully')));
  }

  void _showConfirmDialog(
      BuildContext context, String userId, int index, String actionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("$actionType Account"),
          content: Text("Are you sure you want to $actionType this account?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateStatus(userId, index, actionType.toLowerCase());
              },
              child: Text(actionType,
                  style: TextStyle(
                      color: actionType == "Approved"
                          ? Colors.green
                          : Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Approval Requests"),
        backgroundColor: Color.fromARGB(255, 6, 109, 61),
      ),
      body: Stack(
        children: [
          // Background logo
          Positioned.fill(
            child: Opacity(
              opacity: 0.1, // Adjust visibility
              child: Center(
                child:
                    Image.asset('assets/tatak_logo.png', fit: BoxFit.contain),
              ),
            ),
          ),
          FutureBuilder<List<DocumentSnapshot>>(
            future: _getPendingUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No pending requests.'));
              }

              List<DocumentSnapshot> pendingUsers = snapshot.data!;
              _isButtonDisabled =
                  List.generate(pendingUsers.length, (_) => false);

              return Align(
                alignment: Alignment.topCenter, // Start at the top
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 600, // Prevents stretching in web mode
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: pendingUsers.map((user) {
                        int index = pendingUsers.indexOf(user);
                        return Card(
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          color: Colors.white
                              .withOpacity(0.1), // Light transparency
                          child: ListTile(
                            title: Text(
                              'User ID: ${user['userID'] ?? 'Unknown'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                'Email: ${user['clubEmail'] ?? 'No email'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: _isButtonDisabled[index]
                                      ? null
                                      : () => _showConfirmDialog(
                                          context, user.id, index, "approve"),
                                  child: Text("Approve"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: _isButtonDisabled[index]
                                      ? null
                                      : () => _showConfirmDialog(
                                          context, user.id, index, "Decline"),
                                  child: Text("Decline"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
