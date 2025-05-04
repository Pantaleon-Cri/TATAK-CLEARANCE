import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_clearance/registration_list.dart'; // Your existing widget

class UpdateStudentInfoPage extends StatefulWidget {
  final String schoolId; // Pass this from the logged-in user's info

  UpdateStudentInfoPage({required this.schoolId});

  @override
  _UpdateStudentInfoPageState createState() => _UpdateStudentInfoPageState();
}

class _UpdateStudentInfoPageState extends State<UpdateStudentInfoPage> {
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedClub;
  String? _selectedCourse;
  String? _selectedYear;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.schoolId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _selectedCollege = data['college'];
        _selectedDepartment = data['department'];
        _selectedClub = data['club'];
        _selectedCourse = data['course'];
        _selectedYear = data['year'];
      });
    }
  }

  Future<void> _updateUserData() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.schoolId)
          .update({
        'college': _selectedCollege,
        'department': _selectedDepartment,
        'club': _selectedClub,
        'course': _selectedCourse,
        'year': _selectedYear,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Information updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Student Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCollege,
                hint: Text('Select College'),
                items: ['CAS', 'CED', 'CEAC', 'CBA'].map((college) {
                  return DropdownMenuItem(
                    value: college,
                    child: Text(college),
                  );
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
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a college'
                    : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                ),
              ),
              SizedBox(height: 10),
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUserData,
                child: Text('Update Info'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
