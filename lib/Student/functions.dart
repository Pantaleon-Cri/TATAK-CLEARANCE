import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:online_clearance/Student/profile.dart';

class StudentFunctions {
  static void fetchStudentInfo(
      String schoolId,
      Function(String, String, String, String, String, String, String, String,
              String)
          onUpdate,
      BuildContext context) {
    // Updated signature
    FirebaseFirestore.instance
        .collection('Users')
        .doc(schoolId)
        .snapshots()
        .listen((studentSnapshot) {
      if (studentSnapshot.exists && studentSnapshot.data() != null) {
        final studentData = studentSnapshot.data() as Map<String, dynamic>;
        onUpdate(
            studentData['firstName'] ?? 'N/A',
            studentData['lastName'] ?? 'N/A',
            studentData['email'] ?? 'N/A',
            studentData['department'] ?? 'N/A', // Fetch department
            studentData['schoolId'] ?? 'N/A',
            studentData['club'] ?? 'N/A',
            studentData['college'] ?? 'N/A',
            studentData['course'] ?? 'N/A',
            studentData['year'] ?? 'N/A');
      } else {
        onUpdate('N/A', 'N/A', 'N/A', 'N/A', 'N/A', 'N/A', 'N/A', 'N/A', 'N/A');
      }
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch student info: $error')),
      );
      onUpdate('Error', 'Error', 'Error', 'Error', 'Error', 'Error', 'Error',
          'Error', 'Error');
    });
  }

  static Future<void> showProfileDialog(
    BuildContext context,
    String course,
    String year,
    String firstName,
    String lastName,
    String email,
    String college,
    String department,
    String club,
    String schoolId,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return StudentProfileDialog(
          year: year,
          course: course,
          firstName: firstName,
          lastName: lastName,
          email: email,
          department: department,
          schoolId: schoolId,
          club: club,
          college: college,
        );
      },
    );
  }
}

Future<void> pickImage(ImageSource source, Function(File) setProfileImage,
    Function(String) setProfileImageURL, String schoolId) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    setProfileImage(File(pickedFile.path));
    await uploadImageToFirebase(pickedFile.path, setProfileImageURL, schoolId);
  }
}

Future<void> uploadImageToFirebase(String filePath,
    Function(String) setProfileImageURL, String schoolId) async {
  try {
    String fileName =
        'profile_images/${schoolId}_${DateTime.now().millisecondsSinceEpoch}.png';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = storageRef.putFile(File(filePath));
    final snapshot = await uploadTask.whenComplete(() => null);
    final downloadURL = await snapshot.ref.getDownloadURL();
    await saveImageURLToFirestore(downloadURL, schoolId);
    setProfileImageURL(downloadURL);
  } catch (e) {
    print('Error uploading image: $e');
  }
}

Future<void> saveImageURLToFirestore(
    String downloadURL, String schoolId) async {
  try {
    final studentDocRef =
        FirebaseFirestore.instance.collection('Users').doc(schoolId);
    await studentDocRef.set({
      'profileImageURL': downloadURL,
    }, SetOptions(merge: true));
  } catch (e) {
    print('Error saving image URL to Firestore: $e');
  }
}

Future<void> loadProfileImage(
    String schoolId, Function(String?) setProfileImageURL) async {
  try {
    final studentDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(schoolId)
        .get();
    if (studentDoc.exists &&
        studentDoc.data() != null &&
        studentDoc.data()!.containsKey('profileImageURL')) {
      setProfileImageURL(studentDoc.data()!['profileImageURL']);
    }
  } catch (e) {
    print('Error loading profile image: $e');
  }
}
