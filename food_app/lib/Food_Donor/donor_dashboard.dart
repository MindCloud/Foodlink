import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../role_selection_page.dart';
import 'surplus_page.dart';
import '../services/firestore_service.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final _firestoreService = FirestoreService();
  Map<String, dynamic>? _donorStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _firestoreService.getDonorStats();
    setState(() => _donorStats = stats);
  }

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
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _loadStats,
          ),
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
              "Your Impact",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildImpactCard(
                  'KG Rescued',
                  '${_donorStats?['totalKg']?.toStringAsFixed(1) ?? '0.0'}',
                  Icons.recycling,
                  Colors.green,
                ),
                _buildImpactCard(
                  'Donations',
                  '${_donorStats?['totalDonations'] ?? '0'}',
                  Icons.fastfood,
                  Colors.orange,
                ),
                _buildImpactCard(
                  'Completed',
                  '${_donorStats?['completedDonations'] ?? '0'}',
                  Icons.check_circle,
                  Colors.blue,
                ),
              ],
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
              "Your Donations",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getDonorDonations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No donations yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to log your first surplus food',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final donation = doc.data() as Map<String, dynamic>;
                    return _buildDonationCard(doc.id, donation);
                  },
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LogSurplusFoodPage()),
          );
          if (result == true) {
            _loadStats();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Log Surplus Food"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildImpactCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.only(right: 8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(String docId, Map<String, dynamic> donation) {
    final status = donation['status'] ?? 'Logged';
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.fastfood, color: Colors.green),
        ),
        title: Text(
          donation['foodType'] ?? 'Unknown Food',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(donation['quantity'] ?? '0 kg'),
            if (donation['pickupFrom'] != null)
              Text('Pickup: ${donation['pickupFrom']} - ${donation['pickupTo']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(status),
              backgroundColor: statusColor.withOpacity(0.1),
              labelStyle: TextStyle(color: statusColor, fontSize: 12),
            ),
            if (status == 'Logged')
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'edit') {
                    // TODO: Implement edit functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit feature coming soon')),
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(docId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Logged':
        return Colors.blue;
      case 'Claimed':
        return Colors.orange;
      case 'Picked Up':
        return Colors.purple;
      case 'Delivered':
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmDelete(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Donation'),
        content: const Text('Are you sure you want to delete this donation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteDonation(docId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Donation deleted'), backgroundColor: Colors.green),
          );
          _loadStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}