import 'package:flutter/material.dart';

class RegistrationList extends StatefulWidget {
  final String? selectedCollege;
  final String? selectedDepartment;
  final String? selectedClub;
  final ValueChanged<String?> onCollegeChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<String?> onClubChanged;
  final bool showCollege; // To control whether to show the college dropdown
  final bool
      showDepartment; // To control whether to show the department dropdown
  final bool showClub; // To control whether to show the club dropdown

  RegistrationList({
    required this.selectedCollege,
    required this.selectedDepartment,
    required this.selectedClub,
    required this.onCollegeChanged,
    required this.onDepartmentChanged,
    required this.onClubChanged,
    this.showCollege =
        true, // Default to true, so the college dropdown is shown by default
    this.showDepartment =
        true, // Default to true, so the department dropdown is shown by default
    this.showClub =
        true, // Default to true, so the club dropdown is shown by default
  });

  @override
  _RegistrationListState createState() => _RegistrationListState();
}

class _RegistrationListState extends State<RegistrationList> {
  final Map<String, Map<String, List<String>>> collegeData = {
    'CED': {
      'Natural Science': ['science', 'math'],
      'RE': ['Club B1', 'Club B2'],
    },
    'CEAC': {
      'CSD': ['PSITS', 'BLIS'],
      'SEAS': ['PICE', 'ARCHI', 'EE', 'CompENG', 'ECE'],
    },
    'CBA': {
      'Business 1': ['Club E1', 'Club E2'],
      'Administration 1': ['Club F1', 'Club F2'],
    },
    'CAS': {
      'Natural Science': ['science', 'math'],
      'Medical Courses': ['Sons', 'Phismets'],
    },
  };

  // Method to build the department dropdown
  Widget _buildDepartmentDropdown() {
    List<String> departments = widget.selectedCollege != null
        ? collegeData[widget.selectedCollege!]!.keys.toList()
        : [];

    return DropdownButtonFormField<String>(
      value: widget.selectedDepartment,
      hint: Text('Select Department'),
      items: departments.map((department) {
        return DropdownMenuItem(
          value: department,
          child: Text(department),
        );
      }).toList(),
      onChanged: (value) {
        widget.onDepartmentChanged(value);
      },
      decoration: InputDecoration(
        // No border for the dropdown

        border: OutlineInputBorder(),
        filled: true, // Enable filling
        fillColor: Colors.white,

        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }

  // Method to build the club dropdown
  Widget _buildClubDropdown() {
    List<String> clubs =
        widget.selectedCollege != null && widget.selectedDepartment != null
            ? collegeData[widget.selectedCollege!]![widget.selectedDepartment!]!
            : [];

    return DropdownButtonFormField<String>(
      value: widget.selectedClub,
      hint: Text('Select Club'),
      items: clubs.map((club) {
        return DropdownMenuItem(
          value: club,
          child: Text(club),
        );
      }).toList(),
      onChanged: (value) {
        widget.onClubChanged(value);
      },
      decoration: InputDecoration(
        // No border for the dropdown
        border: OutlineInputBorder(),
        filled: true, // Enable filling
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show department dropdown if club type is "Non-Departmental" and a college is selected
        if (widget.showDepartment && widget.selectedCollege != null)
          _buildDepartmentDropdown(),
        SizedBox(height: 5),

        // Show club dropdown if club type is "Non-Departmental" and both department and college are selected
        if (widget.showClub && widget.selectedDepartment != null)
          _buildClubDropdown(),
      ],
    );
  }
}
