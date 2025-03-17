import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreatorSettingsPage extends StatefulWidget {
  final String userID;

  const CreatorSettingsPage({super.key, required this.userID});

  @override
  _CreatorSettingsPageState createState() => _CreatorSettingsPageState();
}

class _CreatorSettingsPageState extends State<CreatorSettingsPage> {
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isLoading = false;

  late String _password = '';
  late String _newPassword = '';
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentPassword();
  }

  void _fetchCurrentPassword() async {
    try {
      final moderatorDoc = await FirebaseFirestore.instance
          .collection('moderators')
          .doc(widget.userID)
          .get();

      if (moderatorDoc.exists) {
        setState(() {
          _password = moderatorDoc.data()?['password'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching password: $e')),
      );
    }
  }

  Future<void> _updatePasswordInFirebase() async {
    if (_newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('moderators')
          .doc(widget.userID)
          .update({'password': _newPassword});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );

      Navigator.pop(context); // Navigate back to the main page
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
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
            child: ListView(
              shrinkWrap: true, // Prevents unnecessary scrolling
              children: [
                // Current password field
                TextFormField(
                  controller: TextEditingController(text: _password),
                  obscureText: !_isPasswordVisible,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    hintText: "Your current password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // New password field
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  onChanged: (value) => _newPassword = value,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save password changes button with loading state
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          await _updatePasswordInFirebase();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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
    );
  }
}
