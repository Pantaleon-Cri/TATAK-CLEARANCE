import 'package:flutter/material.dart';

class RegistrationList extends StatefulWidget {
  final String? selectedCourse;
  final String? selectedYear;
  final String? selectedCollege;
  final String? selectedDepartment;
  final String? selectedClub;
  final ValueChanged<String?> onCollegeChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<String?> onClubChanged;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<String?> onYearChanged;
  final bool showCollege;
  final bool showDepartment;
  final bool showClub;
  final bool showCourse;
  final bool showYear;

  RegistrationList({
    required this.selectedCourse,
    required this.selectedYear,
    required this.selectedCollege,
    required this.selectedDepartment,
    required this.selectedClub,
    required this.onCollegeChanged,
    required this.onDepartmentChanged,
    required this.onClubChanged,
    required this.onCourseChanged,
    required this.onYearChanged,
    this.showCollege = true,
    this.showDepartment = true,
    this.showClub = true,
    this.showCourse = true,
    this.showYear = true,
  });

  @override
  _RegistrationListState createState() => _RegistrationListState();
}

class _RegistrationListState extends State<RegistrationList> {
  final Map<String, Map<String, Map<String, List<String>>>> collegeData = {
    'CED': {
      'No Club Departments for CED': {
        'PEFS': ['BSEd PE (Physical Education)'],
        'YES CLUB': ['BEEd (Bachelor of Elementary Education)'],
        'KAMAFIL': ['BSEd Filipino (Filipino Education)'],
        'MATH CLUB': ['BSEd Math (Mathematics Education)'],
        'JSEG': ['BSEd Science (Science Education)'],
        'ENGLISH CLUB': ['BSEd English (English Education)'],
        'APDM': ['BSEd Social Studies (Social Studies Education)'],
        'RE CLUB': ['BSEd RE (Religious Education)']
      },
    },
    'CEAC': {
      'CSD': {
        'PSITS': ['BS Information Technology', 'BS Computer Science'],
        'BITS': ['Bachelor of Library and Information Science'],
      },
      'SEAS': {
        'PICE': ['BS Civil Engineering'],
        'ARCHI': ['BS Architecture'],
        'EE': ['BS Electrical Engineering'],
        'CompENG': ['BS Computer Engineering'],
        'ECE': ['BS Electronics Engineering'],
      },
    },
    'CBA': {
      'No Club Departments for CBA': {
        'JPIA': ['Accountancy'],
        'JPAMA': ['Management Accounting'],
        'JHAMS': ['Hospitality Management'],
        'JFINEX': ['Financial Management'],
        'JPMAP': ['Human Resource'],
        'JPMA': ['Marketing Management']
      },
    },
    'CAS': {
      "No Club Departments for CAS": {
        "SONS": ["Nursing"],
        "PHISMETS": ["Medical Technology"],
        "PC": ["Bachelor of Arts in Communication"],
        "NASSS": [
          "Bachelor of Science in Chemistry",
          "Bachelor of Science in Biology",
          "Bachelor of Science in Environmental Science"
        ],
        "SDF": ["Philosophy"],
        "JSWAP": ["Social Work"],
        "JPCAP": ["Criminology"],
        "JPAP": ["Psychology"],
        "PSS": ["Political Science"]
      }
    },
  };

  // Build the department dropdown
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
        widget.onClubChanged(null); // Reset club when department changes
        widget.onCourseChanged(null); // Reset course when department changes
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }

  // Build the club dropdown
  Widget _buildClubDropdown() {
    List<String> clubs = widget.selectedCollege != null &&
            widget.selectedDepartment != null
        ? (collegeData[widget.selectedCollege!]![widget.selectedDepartment!]!
                as Map<String, List<String>>)
            .keys
            .toList()
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
        widget.onCourseChanged(null); // Reset course when club changes
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }

  // Build the course dropdown
  Widget _buildCourseDropdown() {
    List<String> courses = widget.selectedCollege != null &&
            widget.selectedDepartment != null &&
            widget.selectedClub != null
        ? collegeData[widget.selectedCollege!]![widget.selectedDepartment!]![
                widget.selectedClub!] ??
            []
        : [];

    return DropdownButtonFormField<String>(
      value: widget.selectedCourse,
      hint: Text('Select Course'),
      items: courses.map((course) {
        return DropdownMenuItem(
          value: course,
          child: Text(course),
        );
      }).toList(),
      onChanged: widget.onCourseChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }

  // Build the year dropdown
  Widget _buildYearDropdown() {
    List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

    return DropdownButtonFormField<String>(
      value: widget.selectedYear,
      hint: Text('Select Year'),
      items: years.map((year) {
        return DropdownMenuItem(
          value: year,
          child: Text(year),
        );
      }).toList(),
      onChanged: widget.onYearChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
      validator: (value) => value == null || value.isEmpty
          ? 'Please select a year'
          : null, // Add validator
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showDepartment && widget.selectedCollege != null)
          _buildDepartmentDropdown(),
        SizedBox(height: 5),
        if (widget.showClub && widget.selectedDepartment != null)
          _buildClubDropdown(),
        SizedBox(height: 5),
        if (widget.showCourse && widget.selectedClub != null)
          _buildCourseDropdown(),
        SizedBox(height: 5),
        if (widget.showYear) _buildYearDropdown(),
      ],
    );
  }
}
