import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../login_page.dart';
import 'functions.dart';
import 'settings.dart';

class StudentProfileDialog extends StatefulWidget {
  final String firstName;
  final String year;
  final String course;
  final String lastName;
  final String email;
  final String college;
  final String department;
  final String club;
  final String schoolId;

  const StudentProfileDialog({
    super.key,
    required this.firstName,
    required this.year,
    required this.course,
    required this.lastName,
    required this.email,
    required this.department,
    required this.schoolId,
    required this.college,
    required this.club,
  });

  @override
  _StudentProfileDialogState createState() => _StudentProfileDialogState();
}

class _StudentProfileDialogState extends State<StudentProfileDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.schoolId.isEmpty) {
      print('Error: School ID is empty');
      return; // Exit early if schoolId is empty
    }
  }

  // Loads the profile image from a URL if it exists

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.white,
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Avoid unnecessary stretching
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileDetail(
                        'Name:', '${widget.firstName} ${widget.lastName}'),
                    _buildProfileDetail('College:', widget.college),
                    _buildProfileDetail(
                        'Course/Year:', '${widget.course} ${widget.year}'),
                    _buildProfileDetail('Department:', widget.department),
                    _buildProfileDetail('Club:', widget.club),
                    _buildProfileDetail('School ID:', widget.schoolId),
                    const SizedBox(height: 20),
                    Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SettingsPage(schoolId: widget.schoolId),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (Route<dynamic> route) => false,
                        );
                      },
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

  // Helper method to create profile detail with bold labels inside a rectangle
  Widget _buildProfileDetail(String label, String value) {
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
