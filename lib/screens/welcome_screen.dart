// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '../utils/routes.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimarySwatch.shade300, kPrimarySwatch.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/welcome.png', 
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.agriculture, size: 100, color: Colors.white70); 
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'AgriWaste Connect', 
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Turning agricultural waste into valuable resources.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),
              CustomButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.roleSelection); 
                },
                backgroundColor: Colors.white,
                textColor: kPrimarySwatch.shade700,
              ),
              const SizedBox(height: 20),
               TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.login);
                },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
