// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/routes.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  UserRole _selectedRole = UserRole.unknown; 
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final roleArgument = ModalRoute.of(context)?.settings.arguments;
    if (roleArgument is UserRole) {
      _selectedRole = roleArgument;
    } else {
      print("Warning: No role passed to SignupScreen, defaulting to farmer.");
      _selectedRole = UserRole.farmer; 
    }
  }


  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == UserRole.unknown) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Role not selected. Please go back and select a role.')),
        );
        return;
      }
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _selectedRole,
        );
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup Failed: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: kPrimaryTextColor),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimarySwatch.shade200, kPrimarySwatch.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Join our community as a ${_selectedRole.name[0].toUpperCase()}${_selectedRole.name.substring(1)}!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                     prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!value.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your password';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  Text('Signing up as: ${_selectedRole.name[0].toUpperCase()}${_selectedRole.name.substring(1)}',
                    style: TextStyle(fontSize: 16, color: kPrimarySwatch.shade700, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 25),
                  _isLoading
                      ? CircularProgressIndicator(color: kPrimarySwatch.shade600)
                      : CustomButton(
                          text: 'Sign Up',
                          onPressed: _signup,
                        ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(color: kPrimarySwatch.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
