import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String schoolId;

  const SettingsPage({super.key, required this.schoolId});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _newPasswordController = TextEditingController();

  late String _password = '';
  late String _newPassword = '';

  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isLoading = false; // Loading state for button

  @override
  void initState() {
    super.initState();
    _fetchCurrentPassword();
  }

  void _fetchCurrentPassword() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.schoolId)
          .get();

      if (studentDoc.exists) {
        setState(() {
          _password = studentDoc.data()?['password'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student record not found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching password: $e')),
      );
    }
  }

  Future<void> _updatePasswordInFirebase() async {
    _newPassword = _newPasswordController.text.trim(); // Trim spaces

    if (_newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading state
    });

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.schoolId)
          .update({'password': _newPassword});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );

      _newPasswordController.clear(); // Clear input field

      // Navigate back to main page after success
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                shrinkWrap: true, // Prevents unnecessary expansion
                children: [
                  TextFormField(
                    controller: TextEditingController(text: _password),
                    obscureText: !_isPasswordVisible,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_isNewPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _updatePasswordInFirebase();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save Password Changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
