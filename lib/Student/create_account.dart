import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_clearance/login_page.dart';
import 'package:online_clearance/registration_list.dart';

class StudentCreateAccount extends StatefulWidget {
  @override
  _StudentCreateAccountState createState() => _StudentCreateAccountState();
}

class _StudentCreateAccountState extends State<StudentCreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedClub;
  bool isLoading = false; // Added loading state

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true; // Start loading
    });

    final schoolId = _schoolIdController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(schoolId)
          .get();

      if (doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ID already exists.',
                  style: TextStyle(color: Colors.red)),
              backgroundColor: Colors.white),
        );
      } else {
        await FirebaseFirestore.instance.collection('Users').doc(schoolId).set({
          'schoolId': schoolId,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'college': _selectedCollege,
          'department': _selectedDepartment,
          'club': _selectedClub,
          'password': password, // Handle securely in production
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Registration successful!')));

        _clearFields();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }

    setState(() {
      isLoading = false; // Stop loading
    });
  }

  void _clearFields() {
    _schoolIdController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _selectedCollege = null;
      _selectedDepartment = null;
      _selectedClub = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 236, 241, 239),
        title: Text('Create Account as Student'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true, // Prevents bottom overflow
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/color.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Centered content with proper constraints
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600, // Ensures it doesn’t stretch too wide
                  minWidth: 600, // Prevents extreme shrinking
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _schoolIdController,
                          decoration: InputDecoration(
                            labelText: 'School ID',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your Student ID'
                              : null,
                        ),
                        SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: _selectedCollege,
                          hint: Text('Select College'),
                          items: ['CAS', 'CED', 'CEAC', 'CBA'].map((college) {
                            return DropdownMenuItem(
                                value: college, child: Text(college));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCollege = value;
                              _selectedDepartment = null;
                              _selectedClub = null;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 15),
                          ),
                        ),
                        SizedBox(height: 5),
                        RegistrationList(
                          selectedCollege: _selectedCollege,
                          selectedDepartment: _selectedDepartment,
                          selectedClub: _selectedClub,
                          onCollegeChanged: (college) {
                            setState(() {
                              _selectedCollege = college;
                              _selectedDepartment = null;
                              _selectedClub = null;
                            });
                          },
                          onDepartmentChanged: (department) {
                            setState(() {
                              _selectedDepartment = department;
                              _selectedClub = null;
                            });
                          },
                          onClubChanged: (club) {
                            setState(() {
                              _selectedClub = club;
                            });
                          },
                        ),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your first name'
                              : null,
                        ),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your last name'
                              : null,
                        ),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your password'
                              : null,
                        ),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
                          validator: (value) =>
                              value != _passwordController.text.trim()
                                  ? 'Passwords do not match'
                                  : null,
                        ),
                        SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : _register, // Disable button when loading
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0B3F33),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.white) // Show loader
                              : Text(
                                  'SIGN UP',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
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
