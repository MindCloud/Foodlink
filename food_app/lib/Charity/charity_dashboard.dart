import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../role_selection_page.dart';   // Make sure this import path is correct
import '../services/intelligent_matching.dart';

class CharityDashboard extends StatefulWidget {
  const CharityDashboard({super.key});

  @override
  State<CharityDashboard> createState() => _CharityDashboardState();
}

class _CharityDashboardState extends State<CharityDashboard> {
  // Replace your current availableMatches with this:
final List<Map<String, dynamic>> availableMatches = [
  {
    "id": "D001",
    "donorName": "Mr. Rajesh Perera",
    "foodType": "Cooked Rice & Curry (Vegetarian)",
    "quantity": "4 kg",
    "distance": "9.2 km",
    "location": "Colombo 05 (Near Hyde Park Corner)",
    "timeLeft": "25 min",
  },
  {
    "id": "D002",
    "donorName": "Mrs. Anusha Silva",
    "foodType": "String Hoppers & Kiri Hodi",
    "quantity": "2.5 kg",
    "distance": "11.5 km",
    "location": "Colombo 03 (Galle Face area)",
    "timeLeft": "18 min",
  },
];

  bool hasClaimedAny = false;

  void _claimDonation(String donationId) {
    setState(() {
      hasClaimedAny = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Successfully claimed for Free Pickup!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Logout function - Same as Donor Dashboard
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout from Charity Dashboard?"),
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
        title: const Text("Charity Dashboard"),
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
            // Header
            const Text(
              "Available Matches for You",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Geofenced Matching (8–12 km) + Intelligent Matching Algorithm (IMA)",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 32),

            // Matches List
            Expanded(
              child: availableMatches.isEmpty
                  ? const Center(
                      child: Text(
                        "No matches available right now.\nNew matches appear daily around 5:00 PM.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: availableMatches.length,
                      itemBuilder: (context, index) {
                        final match = availableMatches[index];

                        // IMA calculation
                        final int imaScore = IntelligentMatchingAlgorithm.calculateScore(match);
                        final String imaReason = IntelligentMatchingAlgorithm.getReason(imaScore);

                        match['imaScore'] = imaScore;
                        match['imaReason'] = imaReason;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Donor & Distance Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      match["donorName"],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        match["distance"],
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Food Type
                                Text(
                                  match["foodType"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // === INTELLIGENT MATCHING ALGORITHM (IMA) BADGE ===
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.psychology, size: 18, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Intelligent Match • ${match["imaReason"]}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Quantity & Location
                                Row(
                                  children: [
                                    const Icon(Icons.scale, size: 20, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Quantity: ${match["quantity"]}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 20, color: Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        match["location"],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Claim Button (Tier 1 - Free Pickup)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: hasClaimedAny
                                        ? null
                                        : () => _claimDonation(match["id"]),
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text(
                                      "Claim for Free Pickup",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                                Center(
                                  child: Text(
                                    "Pickup before 5:30 PM • ${match["timeLeft"]} left",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Tier 2 Info Banner + IMA Mention
            // Tier 2 Info Banner + Haversine Formula Mention
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.blue[50],
    borderRadius: BorderRadius.circular(10),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "If not claimed by 5:30 PM, the donation will automatically move to Tier 2 (Rider Delivery)",
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.blue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // === HAVERSINE FORMULA MENTION ===
      Row(
        children: [
          const Icon(Icons.calculate, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Matched using Haversine Formula (strict 8–12 km radius)",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),
          ],
        ),
      ),
    );
  }
}