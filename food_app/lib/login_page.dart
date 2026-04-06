import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_page.dart';
import 'Food_Donor/donor_dashboard.dart';
import 'Charity/charity_dashboard.dart';
import 'Financial_Sponsor/sponsor_dashboard.dart';
import 'Delivery_Rider/rider_dashboard.dart';

class LoginPage extends StatefulWidget {
  final String selectedRole;
  final String roleName;

  const LoginPage({
    super.key,
    required this.selectedRole,
    required this.roleName,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()!.containsKey('role')) {
          final dbRole = doc['role'] as String;
          _navigateToDashboard(dbRole);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Role not found. Contact admin.")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Error: $e")),
      );
    }
  }

  void _navigateToDashboard(String role) {
    Widget destination;
    switch (role) {
      case 'donor':
        destination = const DonorDashboard();
        break;
      case 'charity':
        destination = const CharityDashboard();
        break;
      case 'sponsor':
        destination = const SponsorDashboard();
        break;
      case 'rider':
        destination = const RiderDashboard();
        break;
      default:
        destination = const DonorDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Colors.green.shade700;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Login as ${widget.roleName}"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Logo
              Image.network(
                'https://via.placeholder.com/180x180/2E7D32/FFFFFF?text=🍃+FoodLink', // Replace with your real logo URL
                height: 140,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.food_bank,
                  size: 120,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Welcome back!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue as ${widget.roleName}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Input Fields
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Login Button
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignupPage(
                        selectedRole: widget.selectedRole,
                        roleName: widget.roleName,
                      ),
                    ),
                  );
                },
                child: Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(color: primaryGreen, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}