import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_clearance/Admin/admin_homepage.dart'; // AdminPage to navigate back

class HistoryPage extends StatelessWidget {
  // Function to set the status back to 'Pending'
  Future<void> _setStatusToPending(String moderatorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('moderators')
          .doc(moderatorId)
          .update({'status': 'pending'});
      print('Status updated to Pending');
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF167E55),
        title: Text('Approved History'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminPage(), // Go back to AdminPage
              ),
            );
          },
        ),
      ),
      body: Align(
        alignment:
            Alignment.topCenter, // Ensures it stays at the top but centered
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 800, // Adjust max width to prevent stretching
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('moderators')
                  .where('status',
                      isEqualTo: 'approve') // Show only approved moderators
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var approvedModerators = snapshot.data!.docs;

                if (approvedModerators.isEmpty) {
                  return Center(child: Text('No approved requests yet.'));
                }

                return ListView.builder(
                  shrinkWrap: true, // Prevents unnecessary scrolling issues
                  physics: BouncingScrollPhysics(), // Smooth scrolling effect
                  itemCount: approvedModerators.length,
                  itemBuilder: (context, index) {
                    var moderator = approvedModerators[index].data()
                        as Map<String, dynamic>;
                    String moderatorId = approvedModerators[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: Colors.white
                          .withOpacity(0.1), // Adjust the card opacity
                      child: ListTile(
                        title: Text('Name: ${moderator['userID']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${moderator['clubEmail']}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _showPendingDialog(context, moderatorId);
                          },
                          child: Text('Back to Pending'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor:
                                Colors.white, // Change button color
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showPendingDialog(BuildContext context, String moderatorId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Action"),
          content: Text(
              "Are you sure you want to set this request back to Pending?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog first
                await _setStatusToPending(moderatorId); // Then update status
              },
              child: Text("Yes, Set to Pending"),
            ),
          ],
        );
      },
    );
  }
}
