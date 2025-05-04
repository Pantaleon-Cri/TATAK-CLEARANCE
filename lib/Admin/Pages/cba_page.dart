import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_clearance/Admin/request_Page.dart'; // Import the new page

import 'package:excel/excel.dart';
import 'file_downloader_mobile.dart'
    if (dart.library.html) 'file_downloader_web.dart';

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

  Future<void> _generateExcelReport(
      Map<String, Map<String, dynamic>> students, BuildContext context) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['CBA Students'];

    sheet.appendRow([
      'School ID',
      'First Name',
      'Last Name',
      'Department',
      'Club Department',
      'Course',
      'Year',
      'Status',
    ]);

    for (var entry in students.entries) {
      final studentId = entry.key;
      final student = entry.value;

      String status = 'Unknown';
      try {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(studentId)
            .get();

        if (userSnapshot.exists) {
          status = userSnapshot.data()?['status'] ?? 'Unknown';
        }
      } catch (e) {
        status = 'Error';
      }

      sheet.appendRow([
        studentId,
        student['firstName'] ?? '',
        student['lastName'] ?? '',
        student['department'] ?? '',
        student['club dept'] ?? '',
        student['course'] ?? '',
        student['year']?.toString() ?? '',
        status,
      ]);
    }

    final fileBytes = excel.encode();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'CBA_Report_$timestamp.xlsx';

    if (fileBytes != null) {
      await saveFile(Uint8List.fromList(fileBytes), fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb
              ? 'Excel Report downloaded!'
              : 'Excel Report saved and opened!'),
        ),
      );
    }
  }

  Future<String> _getClearanceStatus(String studentId, String semester) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Requests')
          .where('studentId', isEqualTo: studentId)
          .where('semester', isEqualTo: semester)
          .get();

      bool allApproved =
          snapshot.docs.every((doc) => doc['status'] == 'Approved');

      // Determine the new status
      String newStatus = allApproved ? 'Completed' : 'Not Completed';

      // Update the status in the Users collection
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(studentId)
          .update({
        'status': newStatus,
      });

      return newStatus;
    } catch (e) {
      return 'Error';
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
            child: _selectedSemester == null
                ? Center(child: Text('Select a semester first'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Requests')
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

                      final Map<String, Map<String, dynamic>> studentMap = {};
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final studentId = data['studentId'];

                        if (studentId != null &&
                            studentId.toString().contains(_searchQuery)) {
                          studentMap[studentId] = data;
                        }
                      }

                      if (studentMap.isEmpty) {
                        return Center(child: Text('No records found.'));
                      }

                      List<DataRow> rows = studentMap.entries.map((entry) {
                        final student = entry.value;
                        return DataRow(cells: [
                          DataCell(Text('${entry.key}')),
                          DataCell(Text('${student['firstName'] ?? ''}')),
                          DataCell(Text('${student['lastName'] ?? ''}')),
                          DataCell(Text('${student['department'] ?? ''}')),
                          DataCell(Text('${student['club dept'] ?? ''}')),
                          DataCell(Text('${student['course'] ?? ''}')),
                          DataCell(Text('${student['year'] ?? ''}')),
                          DataCell(FutureBuilder<String>(
                            future: _getClearanceStatus(
                                entry.key, _selectedSemester!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text('Loading...');
                              }
                              if (snapshot.hasError) {
                                return Text('Error');
                              }
                              return Text(snapshot.data ?? 'Error');
                            },
                          )),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.arrow_forward),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentRequestsPage(
                                      studentId: entry.key,
                                      semester: _selectedSemester!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ]);
                      }).toList();

                      return Column(
                        children: [
                          SingleChildScrollView(
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
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: rows,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.picture_as_pdf),
                              label: Text("Generate PDF Report"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                final Map<String, Map<String, dynamic>>
                                    dataToExport = Map.from(studentMap);
                                _generateExcelReport(dataToExport, context);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
