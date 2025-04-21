import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_clearance/Admin/request_Page.dart';
// Import the new page

class CbaPage extends StatefulWidget {
  @override
  _CbaPageState createState() => _CbaPageState();
}

class _CbaPageState extends State<CbaPage> {
  String? _selectedSemester;
  List<String> _semesterOptions = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSemesterOptions();
  }

  Future<void> _fetchSemesterOptions() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('SemesterOptions').get();
      setState(() {
        _semesterOptions =
            snapshot.docs.map((doc) => doc['semester'] as String).toList();
        if (_semesterOptions.isNotEmpty) {
          _selectedSemester = _semesterOptions.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 6, 109, 61),
        title: Text('CBA Students'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading
                ? CircularProgressIndicator()
                : DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSemester,
                    onChanged: (String? newSemester) {
                      setState(() {
                        _selectedSemester = newSemester!;
                      });
                    },
                    items: _semesterOptions
                        .map<DropdownMenuItem<String>>((String semester) {
                      return DropdownMenuItem<String>(
                        value: semester,
                        child: Text(semester),
                      );
                    }).toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by School ID',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('college', isEqualTo: 'CBA')
                  .where('semester', isEqualTo: _selectedSemester)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final students = snapshot.data!.docs.where((student) {
                  final schoolId = student['schoolId'].toString();
                  return schoolId.contains(_searchQuery);
                }).toList();

                List<DataRow> rows = students.map((student) {
                  return DataRow(cells: [
                    DataCell(Text('${student['schoolId']}')),
                    DataCell(Text('${student['firstName']}')),
                    DataCell(Text('${student['lastName']}')),
                    DataCell(Text('${student['department']}')),
                    DataCell(Text('${student['club']}')),
                    DataCell(Text('${student['course']}')),
                    DataCell(Text('${student['year']}')),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          // Navigate to the new page and pass the student's schoolId
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentRequestsPage(
                                studentId: student['schoolId'],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ]);
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('School ID')),
                      DataColumn(label: Text('First Name')),
                      DataColumn(label: Text('Last Name')),
                      DataColumn(label: Text('Club Department')),
                      DataColumn(label: Text('Club')),
                      DataColumn(label: Text('Course')),
                      DataColumn(label: Text('Year')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: rows,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
