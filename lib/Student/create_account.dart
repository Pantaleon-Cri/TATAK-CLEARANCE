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
  String? _selectedCourse;
  String? _selectedYear;
  String? _selectedSemester;
  List<String> _semesterList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSemesters(); // Fetch semesters as soon as the widget is initialized
  }

  // Fetch semesters from Firestore
  Future<void> _fetchSemesters() async {
    setState(() {
      isLoading = true; // start loading
    });

    try {
      // 1) Query only the semesters marked available
      final snapshot = await FirebaseFirestore.instance
          .collection('SemesterOptions')
          .where('isAvailableForStudents', isEqualTo: true)
          .get();

      // 2) If you want console logs for debugging
      if (snapshot.docs.isEmpty) {
        print('No available semesters found');
      } else {
        print('Found ${snapshot.docs.length} available semester(s)');
      }

      // 3) Sort locally and extract the 'semester' string safely
      final docs = snapshot.docs;
      docs.sort((a, b) {
        final sa = (a.get('semester') as String?) ?? '';
        final sb = (b.get('semester') as String?) ?? '';
        return sa.compareTo(sb);
      });

      final List<String> semesters = docs
          .map((doc) => (doc.get('semester') as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      setState(() {
        _semesterList = semesters;
      });
    } catch (e) {
      // 4) Show real error in console and clear list on failure
      print('Error fetching semesters: $e');
      setState(() {
        _semesterList = [];
      });
    } finally {
      setState(() {
        isLoading = false; // always stop loading
      });
    }
  }

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
      // Check if the schoolId exists with a different semester
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('schoolId', isEqualTo: schoolId)
          .where('semester', isEqualTo: _selectedSemester)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('You have already registered for this semester.',
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
          'course': _selectedCourse,
          'year': _selectedYear,
          'semester': _selectedSemester,
          'password': password,
          'status': null // Handle securely in production
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
      _selectedCourse = null;
      _selectedYear = null;
      _selectedSemester = null;
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/color.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  minWidth: 600,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 5),
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
                              _selectedCourse = null;
                              _selectedYear = null;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 15),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please select a college'
                              : null, // Add validator for College
                        ),
                        SizedBox(height: 5),
                        RegistrationList(
                          selectedCollege: _selectedCollege,
                          selectedDepartment: _selectedDepartment,
                          selectedClub: _selectedClub,
                          selectedCourse: _selectedCourse,
                          selectedYear: _selectedYear,
                          onCollegeChanged: (college) {
                            setState(() {
                              _selectedCollege = college;
                              _selectedDepartment = null;
                              _selectedClub = null;
                              _selectedCourse = null;
                              _selectedYear = null;
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
                              _selectedCourse = null;
                            });
                          },
                          onCourseChanged: (course) {
                            setState(() {
                              _selectedCourse = course;
                              _selectedYear = null;
                            });
                          },
                          onYearChanged: (year) {
                            setState(() {
                              _selectedYear = year;
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
                                  : null, // Add validator for Confirm Password
                        ),
                        SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    _register();
                                  }
                                },
                          child: isLoading
                              ? CircularProgressIndicator()
                              : Text('Create Account'),
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
