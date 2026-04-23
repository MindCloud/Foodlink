import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../role_selection_page.dart';
import '../screens/map_screen.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  // Dummy Available Tier 2 Jobs
  List<Map<String, dynamic>> availableJobs = [
    {
      "id": "J001",
      "donorName": "Mr. Rajesh Perera",
      "foodType": "Cooked Rice & Curry (Vegetarian)",
      "quantity": "4 kg",
      "donorLocation": "Colombo 05 (Hyde Park Corner)",
      "charityName": "Hope Shelter",
      "charityLocation": "Colombo 10 (Maradana)",
      "distance": 10.8,
      "status": "Available",
      "donorLat": 6.8400,
      "donorLon": 79.8700,
      "charityLat": 6.9319,
      "charityLon": 79.8478,
    },
    {
      "id": "J002",
      "donorName": "Mrs. Anusha Silva",
      "foodType": "String Hoppers & Kiri Hodi",
      "quantity": "2.5 kg",
      "donorLocation": "Colombo 03 (Galle Face)",
      "charityName": "Community Kitchen",
      "charityLocation": "Colombo 07 (Cinnamon Gardens)",
      "distance": 9.5,
      "status": "Available",
      "donorLat": 6.8300,
      "donorLon": 79.8700,
      "charityLat": 6.9044,
      "charityLon": 79.8600,
    },
  ];

  // Rider's Current Active Job (null if no active job)
  Map<String, dynamic>? activeJob;
  String currentJobStatus = ""; // "picked_up" or "delivered"

  // Calculate Fare: 100 LKR per km
  double _calculateFare(double distance) {
    return (distance * 100).roundToDouble();
  }

  void _acceptJob(Map<String, dynamic> job) {
    setState(() {
      activeJob = job;
      availableJobs.removeWhere((j) => j["id"] == job["id"]);
      currentJobStatus = "accepted";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Job #${job["id"]} Accepted"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _markAsPickedUp() {
    setState(() {
      currentJobStatus = "picked_up";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📦 Food Picked Up from Donor"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _markAsDelivered() {
    if (activeJob == null) return;

    final fare = _calculateFare(activeJob!["distance"]);

    setState(() {
      currentJobStatus = "delivered";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎉 Delivery Completed! LKR ${fare.toStringAsFixed(0)} will be deducted from Sponsor Wallet"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );

    // Simulate system actions
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          activeJob = null;
          currentJobStatus = "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Job completed. Impact updated for Donor & Sponsor."),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  // Logout - Same as other dashboards
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout from Rider Dashboard?"),
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
          const SnackBar(content: Text("Logged out successfully"), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Rider Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Available Delivery Jobs",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Tier 2 Fallback Jobs (Unclaimed after 5:30 PM)",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 32),

            // Available Jobs List
            if (activeJob == null) ...[
              Expanded(
                child: availableJobs.isEmpty
                    ? const Center(
                        child: Text(
                          "No delivery jobs available at the moment.\nNew Tier 2 jobs appear after 5:30 PM.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: availableJobs.length,
                        itemBuilder: (context, index) {
                          final job = availableJobs[index];
                          final fare = _calculateFare(job["distance"]);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Job #${job["id"]}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        "${job["distance"]} km",
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    job["foodType"],
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                                  ),
                                  Text("Qty: ${job["quantity"]}"),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text("From: ${job["donorLocation"]}")),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text("To: ${job["charityName"]} (${job["charityLocation"]})")),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Fare: LKR ${fare.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _acceptJob(job),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text("Accept Job"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ] 
            // Active Job Section
            else ...[
              const Text(
                "Current Active Job",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Job #${activeJob!["id"]} - ${activeJob!["foodType"]}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text("From: ${activeJob!["donorName"]} • ${activeJob!["donorLocation"]}"),
                      Text("To: ${activeJob!["charityName"]} • ${activeJob!["charityLocation"]}"),
                      const SizedBox(height: 20),

                      // View on Map Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapScreen(
                                  donorLat: activeJob!["donorLat"],
                                  donorLon: activeJob!["donorLon"],
                                  charityLat: activeJob!["charityLat"],
                                  charityLon: activeJob!["charityLon"],
                                  donorName: activeJob!["donorName"],
                                  charityName: activeJob!["charityName"],
                                  foodType: activeJob!["foodType"],
                                  isRider: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text("View on Map"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (currentJobStatus == "accepted")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _markAsPickedUp,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            child: const Text("Mark as Picked Up"),
                          ),
                        )
                      else if (currentJobStatus == "picked_up")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _markAsDelivered,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text("Mark as Delivered"),
                          ),
                        )
                      else if (currentJobStatus == "delivered")
                        const Center(
                          child: Text(
                            "✅ Delivery Completed Successfully!",
                            style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}