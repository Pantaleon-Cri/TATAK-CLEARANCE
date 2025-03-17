import 'package:flutter/material.dart';
import 'package:online_clearance/Moderator/create_account.dart';
import 'package:online_clearance/Student/create_account.dart';

class CreateAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account As')),
      body: Center(
        // Centers the entire column
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                600, // Prevents stretching like my deadlines stretching my sanity
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Student Box
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 100),
                    backgroundColor: Colors.blue, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Rounded corners
                    ),
                  ),
                  onPressed: () {
                    // Navigate to Student account creation page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentCreateAccount(),
                      ),
                    );
                  },
                  child: Text(
                    'Student',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Moderator Box
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 100),
                    backgroundColor: Colors.green, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Rounded corners
                    ),
                  ),
                  onPressed: () {
                    // Navigate to Moderator account creation page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatorCreateAccount(),
                      ),
                    );
                  },
                  child: Text(
                    'Moderator',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
