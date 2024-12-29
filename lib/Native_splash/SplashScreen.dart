import 'package:flutter/material.dart';
import 'dart:async';

import '../Screen/loginscreen.dart';

class CombinedSplashScreen extends StatefulWidget {
  const CombinedSplashScreen({super.key});

  @override
  _CombinedSplashScreenState createState() => _CombinedSplashScreenState();
}

class _CombinedSplashScreenState extends State<CombinedSplashScreen> {
  int _currentScreen = 1;  // Variable to manage which splash screen to show

  @override
  void initState() {
    super.initState();
    // Show SplashScreen1 for 3 seconds, then switch to SplashScreen2
    Timer(Duration(seconds: 3), () {
      setState(() {
        _currentScreen = 2;  // Switch to SplashScreen2
      });
      // After SplashScreen2, navigate to the LoginScreen
      Timer(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentScreen == 1 ? Colors.blue : Colors.green, // Background color changes based on current screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace Image.asset with Icon widgets
            _currentScreen == 1
                ? Icon(
              Icons.monetization_on,  // Icon for the first splash screen
              size: 150,
              color: Colors.white,
            )
                : Icon(
              Icons.calendar_today,  // Icon for the second splash screen
              size: 150,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              _currentScreen == 1
                  ? 'WATCH AND EARN'  // Text for first splash screen
                  : 'DAILY CLAIMS', // Text for second splash screen
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
