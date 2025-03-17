import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../login_page.dart';
import 'functions.dart';
import 'settings.dart';

class ProfileDialog extends StatefulWidget {
  final String department;
  final String clubEmail;
  final String userID;
  final String college;
  final String category;
  final String subCategory;

  const ProfileDialog({
    super.key,
    required this.department,
    required this.clubEmail,
    required this.userID,
    required this.college,
    required this.category,
    required this.subCategory,
  });

  @override
  _ProfileDialogState createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  @override
  void initState() {
    super.initState();
    loadProfileImage(widget.userID, (url) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.grey[200],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500, // Limit the width of the dialog
              maxHeight:
                  constraints.maxHeight * 0.9, // Prevent excessive height
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Image (Avatar)

                    const SizedBox(height: 20),

                    // Profile details with bold labels inside a rectangle
                    _buildProfileDetail('User ID:', widget.userID,
                        isBold: true),
                    _buildProfileDetail('Office:', widget.category,
                        isBold: true),
                    _buildProfileDetail('Email:', widget.clubEmail,
                        isBold: true),
                    _buildProfileDetail('College:', widget.college,
                        isBold: true),
                    _buildProfileDetail('Department:', widget.department,
                        isBold: true),
                    _buildProfileDetail('Club:', widget.subCategory,
                        isBold: true),

                    const SizedBox(height: 20),

                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          _modernButton(
                            context,
                            label: 'Settings',
                            icon: Icons.settings,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatorSettingsPage(
                                    userID: widget.userID,
                                  ),
                                ),
                              );
                            },
                          ),
                          _modernButton(
                            context,
                            label: 'Logout',
                            icon: Icons.exit_to_app,
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                                (Route<dynamic> route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Function to build profile detail with bold label inside a rectangle
  Widget _buildProfileDetail(String label, String value,
      {bool isBold = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernButton(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
