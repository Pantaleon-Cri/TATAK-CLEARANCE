import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _newPasswordController = TextEditingController();
  final _newAdminIdController = TextEditingController();
  bool _newPasswordVisible = false;
  bool _isLoading = false;
  bool _currentPasswordVisible = false;

  String _currentAdminId = "Loading...";
  String _currentPassword = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  // Function to fetch current admin ID and password from Firestore
  Future<void> _fetchAdminData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('admin')
          .doc('adminDoc') // Replace with the correct admin ID
          .get();

      if (doc.exists) {
        setState(() {
          _currentAdminId = doc['adminId'];
          _currentPassword = doc['password'];
        });
      } else {
        setState(() {
          _currentAdminId = "Not Found";
          _currentPassword = "Not Found";
        });
      }
    } catch (e) {
      setState(() {
        _currentAdminId = "Error loading";
        _currentPassword = "Error loading";
      });
    }
  }

  // Function to update password and admin ID in Firestore
  Future<void> _updateSettings() async {
    String newPassword = _newPasswordController.text;
    String newAdminId = _newAdminIdController.text;

    if (newPassword.isEmpty || newAdminId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    bool? confirmUpdate = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Update"),
        content: Text("Are you sure you want to update the settings?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmUpdate == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('admin')
            .doc('adminDoc') // Replace with the correct admin ID
            .update({
          'password': newPassword,
          'adminId': newAdminId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings updated successfully')),
        );

        Navigator.pop(context); // Navigate back after update
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating settings: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 6, 109, 61),
        title: Text('Settings'),
      ),
      body: Align(
        alignment:
            Alignment.topCenter, // Ensures it stays at the top but centered
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, // Adjust max width to prevent stretching
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator()) // Show loading spinner
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Current Admin ID
                      Text(
                        "Current Admin ID: $_currentAdminId",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),

                      // New Admin ID TextField
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: TextField(
                          controller: _newAdminIdController,
                          decoration: InputDecoration(
                            labelText: "New Admin ID",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Display Current Password with Toggle Visibility
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentPasswordVisible
                                  ? "Current Password: $_currentPassword"
                                  : "Current Password: ••••••••",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _currentPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentPasswordVisible =
                                    !_currentPasswordVisible;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      // New Password TextField with visibility toggle
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: TextField(
                          controller: _newPasswordController,
                          obscureText: !_newPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "New Password",
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _newPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _newPasswordVisible = !_newPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Update Settings Button
                      SizedBox(
                        width: double
                            .infinity, // Makes the button full width like the TextField
                        child: ElevatedButton(
                          onPressed: _updateSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green, // Change button color to green
                            foregroundColor: Colors.white, // Text color
                            padding: EdgeInsets.symmetric(
                                vertical:
                                    12.0), // Adjust padding for better touch area
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Matches TextField border radius
                            ),
                          ),
                          child: Text(
                            'Update Settings',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
