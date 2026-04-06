import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'Food_Donor/donor_dashboard.dart';
import 'Charity/charity_dashboard.dart';
import 'Financial_Sponsor/sponsor_dashboard.dart';
import 'Delivery_Rider/rider_dashboard.dart';

class SignupPage extends StatefulWidget {
  final String selectedRole;
  final String roleName;

  const SignupPage({
    super.key,
    required this.selectedRole,
    required this.roleName,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _signup() async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': emailController.text.trim(),
          'role': widget.selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );

        _navigateToDashboard(widget.selectedRole);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Error: $e")),
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
        title: Text("Sign Up as ${widget.roleName}"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Image.network(
                'https://via.placeholder.com/180x180/2E7D32/FFFFFF?text=🍃+FoodLink',
                height: 140,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.food_bank,
                  size: 120,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Join FoodLink",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Create your account as ${widget.roleName}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

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

              ElevatedButton(
                onPressed: _signup,
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
                  "Create Account",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Already have an account? Login",
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