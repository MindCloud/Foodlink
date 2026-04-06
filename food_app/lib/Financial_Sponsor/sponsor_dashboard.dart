import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../role_selection_page.dart';   // Ensure correct import path

class SponsorDashboard extends StatefulWidget {
  const SponsorDashboard({super.key});

  @override
  State<SponsorDashboard> createState() => _SponsorDashboardState();
}

class _SponsorDashboardState extends State<SponsorDashboard> {
  double walletBalance = 12500.0; // Starting balance in LKR

  // Dummy Recent Transactions
  final List<Map<String, dynamic>> recentTransactions = [
    {
      "amount": -1000,
      "description": "10 km delivery - Restaurant X to Hope Shelter",
      "date": "28 Mar 2026",
      "time": "6:45 PM",
      "type": "spent"
    },
    {
      "amount": 5000,
      "description": "Funds Added via Bank Transfer",
      "date": "27 Mar 2026",
      "time": "11:20 AM",
      "type": "added"
    },
    {
      "amount": -750,
      "description": "8 km delivery - City Kitchen to Old Age Home",
      "date": "26 Mar 2026",
      "time": "7:10 PM",
      "type": "spent"
    },
  ];

  // Add Funds Dialog (Simulated as per SOW)
  void _showAddFundsDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Funds to Wallet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter amount in LKR", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "e.g. 5000",
                border: OutlineInputBorder(),
                prefixText: "LKR ",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amountText = amountController.text.trim();
              if (amountText.isNotEmpty) {
                final amount = double.tryParse(amountText);
                if (amount != null && amount > 0) {
                  setState(() {
                    walletBalance += amount;
                  });

                  // Add to transactions
                  setState(() {
                    recentTransactions.insert(0, {
                      "amount": amount,
                      "description": "Funds Added",
                      "date": "29 Mar 2026",
                      "time": "03:02 PM",
                      "type": "added"
                    });
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✅ LKR ${amount.toStringAsFixed(0)} added successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text("Add Funds"),
          ),
        ],
      ),
    );
  }

  // Logout - Same as Donor & Charity Dashboards
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout from Sponsor Dashboard?"),
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
          const SnackBar(
            content: Text("Logged out successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Sponsor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      "Current Wallet Balance",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "LKR ${walletBalance.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddFundsDialog,
                        icon: const Icon(Icons.add_circle),
                        label: const Text(
                          "Add Funds",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Spending Reports Header
            const Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Transactions List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTransactions.length,
              itemBuilder: (context, index) {
                final tx = recentTransactions[index];
                final isAdded = tx["type"] == "added";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdded ? Colors.green[100] : Colors.red[100],
                      child: Icon(
                        isAdded ? Icons.add : Icons.remove,
                        color: isAdded ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      tx["description"],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text("${tx["date"]} • ${tx["time"]}"),
                    trailing: Text(
                      "${isAdded ? '+' : ''}LKR ${tx["amount"].abs()}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAdded ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Export Report Button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("📄 PDF Report export feature coming in next milestone"),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Export Detailed Spending Report (PDF)"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}