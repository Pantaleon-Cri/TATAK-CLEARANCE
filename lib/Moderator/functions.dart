import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile.dart'; // Ensure this is the correct path for ProfileDialog
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatorFunctions {
  static void fetchUserInfo(
    String userID, // Use userID instead of clubId
    Function(String, String, String, String, String, String, String) onUpdate,
    BuildContext context,
  ) {
    FirebaseFirestore.instance
        .collection('moderators') // Changed to 'users'
        .doc(userID) // Changed to use userID
        .snapshots()
        .listen(
      (userSnapshot) {
        if (userSnapshot.exists && userSnapshot.data() != null) {
          final userData = userSnapshot.data() as Map<String, dynamic>;
          onUpdate(
            userData['userName'] ?? 'N/A',
            userData['department'] ?? 'N/A',
            userData['email'] ?? 'N/A',
            userData['userID'] ?? 'N/A',
            userData['accountType'] ?? 'N/A',
            userData['college'] ?? 'N/A',
            userData['category'] ?? 'N/A',
          );
        } else {
          // Fallback values in case document is not found
          onUpdate('N/A', 'N/A', 'N/A', 'N/A', 'N/A', 'N/A', 'N/A');
        }
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user info: $error')),
        );
        onUpdate('Error', 'Error', 'Error', 'Error', 'Error', 'Error', 'Error');
      },
    );
  }

  static void showProfileDialog(BuildContext context, String userName,
      String college, String department, String email, String userID) {
    showDialog(
      context: context,
      builder: (context) {
        return ProfileDialog(
          // Mapping to ProfileDialog constructor
          department: department, // Mapping to ProfileDialog constructor
          clubEmail: email, // Mapping to ProfileDialog constructor
          userID: userID, // Mapping to ProfileDialog constructor
          college: college, // Mapping to ProfileDialog constructor
          category: '', // Empty or other category data as per your needs
          subCategory: '', // Empty or other sub-category data as per your needs
        );
      },
    );
  }
}

// Method to pick an image from gallery or camera
Future<void> pickImage(
  ImageSource source,
  Function(File) setProfileImage,
  Function(String) setProfileImageURL,
  String userID, // Use userID instead of clubId
) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    setProfileImage(File(pickedFile.path));

    // Upload the image to Firebase Storage and save the reference in Firestore
    await uploadImageToFirebase(pickedFile.path, setProfileImageURL, userID);
  }
}

// Upload the picked image to Firebase Storage
Future<void> uploadImageToFirebase(
  String filePath,
  Function(String) setProfileImageURL,
  String userID, // Use userID instead of clubId
) async {
  try {
    // Create a unique file name for the image based on timestamp
    String fileName =
        'profile_images/${userID}_${DateTime.now().millisecondsSinceEpoch}.png';

    // Reference to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    // Upload the file to Firebase Storage
    final uploadTask = storageRef.putFile(File(filePath));
    final snapshot = await uploadTask.whenComplete(() => null);

    // Get the download URL of the uploaded image
    final downloadURL = await snapshot.ref.getDownloadURL();

    // Save the download URL in Firestore under the user's userID
    await saveImageURLToFirestore(downloadURL, userID);
    setProfileImageURL(downloadURL); // Set the URL to display the image
  } catch (e) {
    print('Error uploading image: $e');
  }
}

// Save the image URL to Firestore under the user's document
Future<void> saveImageURLToFirestore(String downloadURL, String userID) async {
  try {
    // Reference to the 'users' collection in Firestore
    final userDocRef =
        FirebaseFirestore.instance.collection('moderators').doc(userID);

    // Update the document with the image URL
    await userDocRef.set(
      {
        'profileImageURL': downloadURL,
      },
      SetOptions(merge: true), // Merge to avoid overwriting existing data
    );
  } catch (e) {
    print('Error saving image URL to Firestore: $e');
  }
}

// Load the profile image from Firestore
Future<void> loadProfileImage(
  String userID, // Use userID instead of clubId
  Function(String?) setProfileImageURL,
) async {
  try {
    // Get the document from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('moderators')
        .doc(userID)
        .get();

    if (userDoc.exists &&
        userDoc.data() != null &&
        userDoc.data()!.containsKey('profileImageURL')) {
      // Set the profile image URL if it exists in Firestore
      setProfileImageURL(userDoc.data()!['profileImageURL']);
    } else {
      setProfileImageURL(null); // If no image exists, reset the URL
    }
  } catch (e) {
    print('Error loading profile image: $e');
  }
}
