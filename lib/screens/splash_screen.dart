import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 255, 255, 255), // Match your app theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app-logo',
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: 150,
                height: 150,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
