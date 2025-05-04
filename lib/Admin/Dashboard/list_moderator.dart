import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ModeratorListWithCount extends StatelessWidget {
  const ModeratorListWithCount({super.key});

  Future<List<DocumentSnapshot>> _getApprovedUsers() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('moderators')
        .where('status', isEqualTo: 'approve') // Only approved moderators
        .get();
    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Of Approved Moderators'),
        backgroundColor: Colors.green,
        centerTitle: true,
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
            future: _getApprovedUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No approved moderators.'));
              }

              List<DocumentSnapshot> approvedUsers = snapshot.data!;

              return Align(
                alignment: Alignment.topCenter, // Start at the top
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 600, // Prevents stretching in web mode
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: approvedUsers.map((user) {
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
                              'Email: ${user['clubEmail'] ?? 'No email'}',
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
