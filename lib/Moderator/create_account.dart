import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_clearance/login_page.dart';

class CreatorCreateAccount extends StatefulWidget {
  @override
  _CreatorCreateAccountState createState() => _CreatorCreateAccountState();
}

class _CreatorCreateAccountState extends State<CreatorCreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clubnameController = TextEditingController();
  final TextEditingController _clubEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _userIDController = TextEditingController();

  String? _selectedCollege;
  String? _selectedDepartment;

  String? _selectedCategory;
  String? _selectedSubCategory;
  bool _isLoading = false;

  Future<void> _saveToFirestore() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading state
      });

      try {
        // Check if the user ID already exists in Firestore
        var doc = await FirebaseFirestore.instance
            .collection('moderators')
            .doc(_userIDController.text)
            .get();

        if (doc.exists) {
          // Show a SnackBar if the user ID already exists
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User ID already exists.',
                style: TextStyle(color: Colors.red),
              ),
              backgroundColor: Colors.white,
            ),
          );
        } else {
          // Save the new moderator data if the user ID doesn't exist
          await FirebaseFirestore.instance
              .collection('moderators')
              .doc(_userIDController.text)
              .set({
            'clubName': _clubnameController.text,
            'clubEmail': _clubEmailController.text,
            'password': _passwordController.text,
            'userID': _userIDController.text,
            'college': _selectedCollege,
            'department': _selectedDepartment,
            'category': _selectedCategory,
            'subCategory': _selectedSubCategory,
            'status': 'pending', // Set status to 'pending'
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Account successfully registered! Wait for the admin approval to continue login')),
          );

          _clearFields();

          // Navigate to login page after registration
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading state
        });
      }
    }
  }

  // Reset all fields
  void _clearFields() {
    _clubnameController.clear();
    _clubEmailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _userIDController.clear();
    setState(() {
      _selectedCollege = null;
      _selectedDepartment = null;
      _selectedCategory = null;
      _selectedSubCategory = null;
    });
  }

  // Function to approve or deny a moderator registration in admin panel

  // Function to handle moderator sign-in

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 236, 241, 239),
        title: Text('Create Account as Moderator'),
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
                        // Category Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          hint: Text('Select Category'),
                          items: [
                            'Business Office',
                            'Library',
                            'PEC',
                            'Clinic',
                            'GHAD',
                            'Guidance',
                            'Club Department',
                            'Club',
                            'College Council',
                            'College Dean',
                            'SSG',
                            'DSA/NSTP',
                            'Records Section'
                          ].map((category) {
                            return DropdownMenuItem(
                                value: category, child: Text(category));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              _selectedCollege = null;
                              _selectedDepartment = null;
                              _selectedSubCategory = null;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),

                        // Additional Dropdowns for College/Department/Subcategory...
                        if (_selectedCategory == 'College Council' ||
                            _selectedCategory == 'College Dean' ||
                            _selectedCategory == 'Guidance') ...[
                          DropdownButtonFormField<String>(
                            value: _selectedCollege,
                            hint: Text('Select College'),
                            items: ['CEAC', 'CBA', 'CAS', 'CED'].map((college) {
                              return DropdownMenuItem(
                                value: college,
                                child: Text(college),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCollege = value;
                                _selectedDepartment = null;
                                _selectedSubCategory = null;
                              });
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                        ],
                        if (_selectedCategory == 'Club Department') ...[
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
                                _selectedSubCategory = null;
                              });
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),

                          if (_selectedCollege == 'CED') ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              hint: Text('Select Department'),
                              items:
                                  ['Natural Science', 'RE'].map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubCategory = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                          if (_selectedCollege == 'CBA') ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              hint: Text('Select Department'),
                              items: ['Business 1', 'Administration 1']
                                  .map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubCategory = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                          if (_selectedCollege == 'CEAC') ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              hint: Text('Select Department'),
                              items: ['CSD', 'SEAS'].map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubCategory = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                          if (_selectedCollege == 'CAS') ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              hint: Text('Select Department'),
                              items: ['Natural Science', 'Medical Courses']
                                  .map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubCategory = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                          // Subcategory Dropdown based on Department selection
                        ],
                        if (_selectedCategory == 'Club') ...[
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
                                _selectedSubCategory = null;
                              });
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),

                          if (_selectedCollege == 'CED') ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              hint: Text('Select Department'),
                              items:
                                  ['Natural Science', 'RE'].map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubCategory = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                          if (_selectedCollege == 'CBA') ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              hint: Text('Select Department'),
                              items: ['Business 1', 'Administration 1']
                                  .map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubCategory = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                          if (_selectedCollege == 'CEAC') ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              hint: Text('Select Department'),
                              items: ['CSD', 'SEAS'].map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubCategory = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                          if (_selectedCollege == 'CAS') ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              hint: Text('Select Department'),
                              items: ['Natural Science', 'Medical Courses']
                                  .map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubCategory = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                          // Subcategory Dropdown based on Department selection
                          if (_selectedDepartment != null) ...[
                            SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: _selectedSubCategory,
                              hint: Text('Select Subcategory'),
                              items:
                                  _getSubCategoryOptions().map((subCategory) {
                                return DropdownMenuItem(
                                  value: subCategory,
                                  child: Text(subCategory),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubCategory = value;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                        SizedBox(height: 5),
                        TextFormField(
                          controller: _userIDController,
                          decoration: InputDecoration(
                            labelText: 'User ID',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a User ID';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: _clubEmailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            // Check if the email is in the correct format using a regex
                            String emailPattern =
                                r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"; // Email regex pattern
                            RegExp regExp = RegExp(emailPattern);

                            if (!regExp.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 5),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 5),

                        // Confirm password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveToFirestore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0B3F33),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ), // Disable button when loading
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Register',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white)),
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

  List<String> _getSubCategoryOptions() {
    if (_selectedCollege == 'CAS') {
      if (_selectedDepartment == 'Natural Science') {
        return ['Science Club', 'Math Club'];
      } else if (_selectedDepartment == 'Medical Courses') {
        return ['Sons', 'Phismets'];
      }
    } else if (_selectedCollege == 'CEAC') {
      if (_selectedDepartment == 'CSD') {
        return ['PSITS', 'BLIS'];
      } else if (_selectedDepartment == 'SEAS') {
        return ['PICE', 'ARCHI', 'EE', 'CompENG', 'ECE'];
      }
    } else if (_selectedCollege == 'CBA') {
      if (_selectedDepartment == 'Business 1') {
        return ['Club E1', 'Club E2'];
      } else if (_selectedDepartment == 'Administration 1') {
        return ['Club F1', 'Club F2'];
      }
    } else if (_selectedCollege == 'CED') {
      if (_selectedDepartment == 'Natural Science') {
        return ['Science', 'Math'];
      } else if (_selectedDepartment == 'RE') {
        return ['Club B1', 'Club B2'];
      }
    }
    return [];
  }
}
