import 'package:flutter/material.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Modern Green Color Palette
    const Color primaryGreen = Color(0xFF2E7D32);     // Deep Green
    const Color accentGreen = Color(0xFF4CAF50);      // Vibrant Green
    const Color lightGreen = Color(0xFF81C784);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5), // Very light warm green tint
      appBar: AppBar(
        title: const Text(
          "FoodLink",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo + Header
              Center(
                child: Column(
                  children: [
                    Image.network(
                      'https://via.placeholder.com/220x220/2E7D32/FFFFFF?text=🍃+FoodLink', // ← Replace with your real logo URL
                      height: 160,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.volunteer_activism,
                        size: 140,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Welcome to FoodLink",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Together we can reduce food waste\nand fight hunger",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                "Select Your Role",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 30),

              // Role Cards
              _buildRoleCard(
                context,
                icon: Icons.restaurant_outlined,
                title: "Food Donor",
                subtitle: "Donate surplus food",
                roleKey: "donor",
                roleName: "Food Donor",
                color: primaryGreen,
              ),
              const SizedBox(height: 16),

              _buildRoleCard(
                context,
                icon: Icons.volunteer_activism,
                title: "Charity / NGO",
                subtitle: "Receive donations",
                roleKey: "charity",
                roleName: "Charity",
                color: const Color(0xFFFB8C00), // Warm orange accent
              ),
              const SizedBox(height: 16),

              _buildRoleCard(
                context,
                icon: Icons.attach_money,
                title: "Financial Sponsor",
                subtitle: "Support with funds",
                roleKey: "sponsor",
                roleName: "Financial Sponsor",
                color: const Color(0xFF1565C0), // Deep blue
              ),
              const SizedBox(height: 16),

              _buildRoleCard(
                context,
                icon: Icons.delivery_dining,
                title: "Delivery Rider",
                subtitle: "Help deliver food",
                roleKey: "rider",
                roleName: "Delivery Rider",
                color: const Color(0xFF6A1B9A), // Purple
              ),

              const SizedBox(height: 50),

              // Guest Option
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Guest mode - Limited view (coming soon)"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(
                  "Continue as Guest",
                  style: TextStyle(
                    fontSize: 17,
                    color: primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String roleKey,
    required String roleName,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LoginPage(
                  selectedRole: roleKey,
                  roleName: roleName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}