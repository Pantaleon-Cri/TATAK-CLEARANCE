import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_clearance/Admin/admin_homepage.dart';
import 'package:online_clearance/Student/home.dart';
import 'package:online_clearance/Moderator/creator_home_page.dart'; // Moderator's home page
import 'create_account_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // For toggling password visibility

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Start loading
      });

      try {
        final id = _idController.text.trim();
        final password = _passwordController.text.trim();

        // Check in the Users collection for students
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('Users').doc(id).get();

        if (userDoc.exists) {
          String storedPassword = userDoc['password'];

          if (storedPassword == password) {
            String schoolId = userDoc['schoolId']; // Retrieve the schoolId
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentHomePage(
                  schoolId: schoolId, // Pass the actual schoolId
                ),
              ),
            );
            return; // Exit the function if login is successful
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect password.')),
            );
            return;
          }
        } else {
          // ID not found in Users collection, check for moderators
          DocumentSnapshot moderatorDoc = await FirebaseFirestore.instance
              .collection('moderators')
              .doc(id)
              .get();

          if (moderatorDoc.exists) {
            String storedUserID = moderatorDoc['userID'];
            String storedPassword = moderatorDoc['password'];
            String status = moderatorDoc['status']; // Retrieve the status

            if (storedUserID == id && storedPassword == password) {
              if (status == 'approved') {
                String userID = moderatorDoc['userID'];
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModeratorHomePage(
                      userID: userID,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Your account is pending approval.')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Incorrect userID or password.')),
              );
            }
          } else {
            // Check for admin credentials
            DocumentSnapshot adminDoc = await FirebaseFirestore.instance
                .collection('admin')
                .doc('adminDoc')
                .get();

            if (adminDoc.exists) {
              String storedAdminID = adminDoc['adminId'];
              String storedAdminPassword = adminDoc['password'];

              if (id == storedAdminID && password == storedAdminPassword) {
                await FirebaseFirestore.instance
                    .collection('admin')
                    .doc('adminDoc')
                    .set({
                  'lastLogin': DateTime.now().toIso8601String(),
                }, SetOptions(merge: true));

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPage(),
                  ),
                );
                return;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Incorrect admin ID or password.')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ID not found.')),
              );
            }
          }
        }
      } catch (e) {
        print('Error during login: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Stop loading after login attempt
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Prevents bottom overflow
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/ndmu.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Centered content with proper constraints
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400, // Ensures it doesn’t stretch too wide
                  minWidth: 300, // Prevents extreme shrinking
                ),
                child: Container(
                  width: screenWidth * 0.85, // Responsive width
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Heading
                        Text(
                          'Tatak',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        // Username Field
                        TextFormField(
                          controller: _idController,
                          decoration: InputDecoration(
                            hintText: 'School ID/User ID',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5)),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your Username'
                              : null,
                        ),
                        SizedBox(height: 10),
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your password'
                              : null,
                        ),
                        SizedBox(height: 15),
                        // Sign In Button
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(35)),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 3))
                                : Text('Sign In',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                          ),
                        ),
                        SizedBox(height: 5),
                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Don\'t Have Account?',
                                style: TextStyle(color: Colors.white)),
                            TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          CreateAccountPage())),
                              child: Text('Sign Up',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
