import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../role_selection_page.dart';
import '../services/ima_api_service.dart';
import '../services/firestore_service.dart';
import '../screens/map_screen.dart';
import '../screens/report_screen.dart';
import 'charity_registration_page.dart';

class CharityDashboard extends StatefulWidget {
  const CharityDashboard({super.key});

  @override
  State<CharityDashboard> createState() => _CharityDashboardState();
}

class _CharityDashboardState extends State<CharityDashboard> {
  final _firestoreService = FirestoreService();
  
  // Charity's own location (Colombo Fort area)
  double charityLat = 6.9319;
  double charityLon = 79.8478;

  bool isLoading = true;
  bool isCheckingRegistration = true;
  String? errorMessage;
  bool isRegistered = false;
  Map<String, dynamic>? charityData;
  List<Map<String, dynamic>> availableMatches = [];
  List<Map<String, dynamic>> charities = [];

  bool hasClaimedAny = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final charityDoc = await _firestoreService.getCharityByUserId();
    
    setState(() {
      isCheckingRegistration = false;
      isRegistered = charityDoc != null;
      if (charityDoc != null) {
        charityData = charityDoc.data() as Map<String, dynamic>;
        charityLat = charityData?['latitude'] ?? 6.9319;
        charityLon = charityData?['longitude'] ?? 79.8478;
        charities = [
          {
            "id": charityDoc.id,
            "name": charityData?['name'] ?? 'My Charity',
            "lat": charityLat,
            "lon": charityLon,
            "received_today": charityData?['receivedToday'] ?? 0,
            "has_cold_storage": charityData?['hasColdStorage'] ?? true,
            "capacity_remaining": charityData?['capacityRemaining'] ?? 50
          },
        ];
      }
    });

    if (isRegistered) {
      _loadMatches();
    }
  }

  Future<void> _loadMatches() async {
    // Check if backend is available
    final isHealthy = await ImaApiService.healthCheck();
    
    if (!isHealthy) {
      setState(() {
        isLoading = false;
        errorMessage = "Backend unavailable - using fallback data";
        availableMatches = _getFallbackMatches();
      });
      return;
    }

    // Load donations from Firestore
    try {
      final donationsSnapshot = await _firestoreService.getAvailableDonations().first;
      
      if (donationsSnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          availableMatches = [];
        });
        return;
      }

      List<Map<String, dynamic>> donations = donationsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "lat": data['latitude'],
          "lon": data['longitude'],
          "food_type": data['foodType'],
          "quantity_kg": data['quantityKg'] ?? 0,
          "expiry_hours": data['expiryHours'] ?? 4.0,
          "cold_required": data['coldRequired'] ?? false,
          "timestamp": data['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
          "donorName": data['donorEmail']?.split('@')[0] ?? 'Anonymous',
          "location": "Location captured via GPS",
          "timeLeft": "Available",
          "quantity": data['quantity'] ?? '0 kg',
          "foodType": data['foodType'],
          "donorLat": data['latitude'],
          "donorLon": data['longitude'],
          "pickupFrom": data['pickupFrom'],
          "pickupTo": data['pickupTo'],
        };
      }).toList();

      // Get batch IMA matches from backend
      final results = await ImaApiService.getBatchImaMatches(donations, charities);
      
      setState(() {
        isLoading = false;
        availableMatches = donations.map((donation) {
          final result = results.firstWhere(
            (r) => r["donation_id"] == donation["id"],
            orElse: () => {"match": null},
          );
          
          final match = result["match"];
          
          return {
            ...donation,
            "distance": match != null ? "${match["distance_km"]} km" : "--",
            "imaScore": match != null ? (match["final_score"] * 100).round() : 75,
            "imaReason": match != null ? match["reason"] : "Standard Match",
            "spoilageRisk": match != null ? match["spoilage_risk"] : 0.0,
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        availableMatches = _getFallbackMatches();
        errorMessage = "Error loading matches: $e";
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackMatches() {
    return [
      {
        "id": "D001",
        "donorName": "Mr. Rajesh Perera",
        "foodType": "Cooked Rice & Curry (Vegetarian)",
        "quantity": "4 kg",
        "distance": "9.2 km",
        "location": "Colombo 05 (Near Hyde Park Corner)",
        "timeLeft": "25 min",
        "donorLat": 6.8500,
        "donorLon": 79.8600,
        "imaScore": 85,
        "imaReason": "High Nutritional Fit",
        "spoilageRisk": 0.2,
      },
      {
        "id": "D002",
        "donorName": "Mrs. Anusha Silva",
        "foodType": "String Hoppers & Kiri Hodi",
        "quantity": "2.5 kg",
        "distance": "11.5 km",
        "location": "Colombo 03 (Galle Face area)",
        "timeLeft": "18 min",
        "donorLat": 6.8300,
        "donorLon": 79.8700,
        "imaScore": 78,
        "imaReason": "Good Match",
        "spoilageRisk": 0.3,
      },
    ];
  }

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
            icon: const Icon(Icons.assessment),
            tooltip: "View IMA Report",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: isCheckingRegistration
          ? const Center(child: CircularProgressIndicator())
          : !isRegistered
              ? _buildRegistrationPrompt()
              : Padding(
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
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : availableMatches.isEmpty
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
                        final int imaScore = match['imaScore'] ?? 75;
                        final String imaReason = match['imaReason'] ?? 'Standard Match';
                        final double spoilageRisk = match['spoilageRisk'] ?? 0.0;

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
                                        "IMA Score: $imaScore • $imaReason",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Spoilage Risk Indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: spoilageRisk > 0.5 ? Colors.red[50] : Colors.green[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: spoilageRisk > 0.5 ? Colors.red.shade200 : Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        spoilageRisk > 0.5 ? Icons.warning : Icons.check_circle,
                                        size: 18,
                                        color: spoilageRisk > 0.5 ? Colors.red : Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Spoilage Risk: ${(spoilageRisk * 100).toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: spoilageRisk > 0.5 ? Colors.red : Colors.green,
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

                                // View on Map Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MapScreen(
                                            donorLat: match["donorLat"],
                                            donorLon: match["donorLon"],
                                            charityLat: charityLat,
                                            charityLon: charityLon,
                                            donorName: match["donorName"],
                                            charityName: "My Charity (Home)",
                                            foodType: match["foodType"],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text(
                                      "View on Map",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green[700],
                                      side: BorderSide(color: Colors.green.shade700),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
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
            if (errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                  // === BACKEND IMA MENTION ===
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Powered by Backend IMA: Haversine + Adaptive MCDM + Spoilage Risk Prediction",
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

  Widget _buildRegistrationPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              "Register Your Charity",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Complete your charity registration to start receiving food donations",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CharityRegistrationPage(),
                  ),
                );
                if (result == true) {
                  _checkRegistration();
                }
              },
              icon: const Icon(Icons.add_business),
              label: const Text(
                "Register Now",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}