import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../role_selection_page.dart';
import 'surplus_page.dart';

class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for client demo (you can replace with real Firestore data later)
    final todaySurplus = {
      'foodType': 'Cooked Rice & Curry',
      'quantity': '12 kg',
      'pickupTime': 'Today 6:00 PM - 7:00 PM',
      'status': 'Ready for Pickup',
    };

    final impactMetrics = [
      {'label': 'KG Rescued', 'value': '45', 'icon': Icons.recycling},
      {'label': 'People Fed', 'value': '120', 'icon': Icons.people},
      {'label': 'CO₂ Saved', 'value': '85 kg', 'icon': Icons.eco},
    ];

    final badges = [
      {'name': 'First Rescue', 'icon': Icons.emoji_events, 'color': Colors.amber},
      {'name': 'Eco Hero', 'icon': Icons.eco, 'color': Colors.green},
      {'name': 'Top Donor', 'icon': Icons.star, 'color': Colors.orange},
    ];

    final pastDonations = [
      {
        'date': '28 Mar 2026',
        'food': 'Vegetable Biryani - 8kg',
        'status': 'Delivered to Charity',
        'charity': 'Hope Shelter'
      },
      {
        'date': '27 Mar 2026',
        'food': 'Bread & Pastries - 15kg',
        'status': 'Picked up by Rider',
        'charity': 'Community Kitchen'
      },
      {
        'date': '26 Mar 2026',
        'food': 'Fresh Fruits - 10kg',
        'status': 'Claimed by Charity',
        'charity': 'Old Age Home'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Food Donor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                try {
                  await FirebaseAuth.instance.signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out successfully")),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Logout error: $e")),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            const Text(
              "Welcome back, Food Donor!",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Rescue food • Reduce waste • Feed communities",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 1. Today's Surplus Summary
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Surplus",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            todaySurplus['status']!,
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text("Food: ${todaySurplus['foodType']}"),
                    Text("Quantity: ${todaySurplus['quantity']}"),
                    Text("Pickup: ${todaySurplus['pickupTime']}"),
                    const SizedBox(height: 8),
                    const Text(
                      "Post-Nudge: Admin will send notification at 5:00 PM daily",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Impact Metrics
            const Text(
              "Your Impact This Month",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: impactMetrics.map((metric) {
                return Expanded(
                  child: Card(
                    margin: const EdgeInsets.only(right: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Icon(metric['icon'] as IconData, size: 32, color: Colors.green),
                          const SizedBox(height: 8),
                          Text(
                            metric['value'] as String,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            metric['label'] as String,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 3. Earned Badges (Gamification)
            const Text(
              "Earned Badges",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: badge['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(badge['icon'] as IconData, size: 40, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          badge['name'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 4. Past Donations List
            const Text(
              "Past Donations",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pastDonations.length,
              itemBuilder: (context, index) {
                final donation = pastDonations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.fastfood, color: Colors.green),
                    title: Text(donation['food']!),
                    subtitle: Text("${donation['date']} • ${donation['charity']}"),
                    trailing: Chip(
                      label: Text(donation['status']!),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogSurplusFoodPage()),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text("Log Surplus Food"),
      backgroundColor: Colors.green,
    ),
    );
  }
}