import 'package:flutter/material.dart';
import 'dart:math' show pi, sin;
import 'package:firebase_auth/firebase_auth.dart';
import '../role_selection_page.dart';
import '../services/ima_api_service.dart';
import '../services/firestore_service.dart';
import '../screens/map_screen.dart';
import '../screens/report_screen.dart';
import 'charity_registration_page.dart';
import 'spoilage_risk_calculator.dart';

// Theme Colors - Modern Teal, Coral, Cream, Charcoal
const Color _primaryTeal = Color(0xFF006D77);
const Color _lightTeal = Color(0xFF83C5BE);
const Color _cream = Color(0xFFEDF6F9);
const Color _coral = Color(0xFFE29578);
const Color _darkCoral = Color(0xFFFF6B6B);
const Color _charcoal = Color(0xFF2D3436);
const Color _white = Color(0xFFFFFFFF);
const Color _softGrey = Color(0xFFF7F9FA);

class CharityDashboard extends StatefulWidget {
  const CharityDashboard({super.key});

  @override
  State<CharityDashboard> createState() => _CharityDashboardState();
}

class _CharityDashboardState extends State<CharityDashboard>
    with TickerProviderStateMixin {
  final _firestoreService = FirestoreService();

  // Animations
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

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
    // Smoother, more subtle animations
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutQuad),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkRegistration();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
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
        final timestamp = data['createdAt']?.toDate() ?? DateTime.now();
        final expiryHours = (data['expiryHours'] ?? 4.0).toDouble();
        final coldRequired = data['coldRequired'] ?? false;
        final foodType = data['foodType']?.toString() ?? '';
        
        // Calculate local spoilage risk
        final spoilageRisk = SpoilageRiskCalculator.calculateRisk(
          expiryHours: expiryHours,
          coldRequired: coldRequired,
          postedTime: timestamp,
          foodType: foodType,
        );
        
        final timeUntilSpoilage = SpoilageRiskCalculator.getTimeUntilSpoilage(
          expiryHours: expiryHours,
          coldRequired: coldRequired,
          postedTime: timestamp,
        );
        
        return {
          "id": doc.id,
          "lat": data['latitude'],
          "lon": data['longitude'],
          "food_type": data['foodType'],
          "quantity_kg": data['quantityKg'] ?? 0,
          "expiry_hours": expiryHours,
          "cold_required": coldRequired,
          "timestamp": timestamp.toIso8601String(),
          "donorName": data['donorEmail']?.split('@')[0] ?? 'Anonymous',
          "location": "Location captured via GPS",
          "timeLeft": timeUntilSpoilage,
          "quantity": data['quantity'] ?? '0 kg',
          "foodType": foodType,
          "donorLat": data['latitude'],
          "donorLon": data['longitude'],
          "pickupFrom": data['pickupFrom'],
          "pickupTo": data['pickupTo'],
          "calculatedSpoilageRisk": spoilageRisk,
          "timeUntilSpoilage": timeUntilSpoilage,
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
          
          // Use backend spoilage risk if available, otherwise use local calculation
          final backendSpoilageRisk = match?["spoilage_risk"] as double?;
          final localSpoilageRisk = donation["calculatedSpoilageRisk"] as double? ?? 0.0;
          final finalSpoilageRisk = backendSpoilageRisk ?? localSpoilageRisk;
          
          return {
            ...donation,
            "distance": match != null ? "${match["distance_km"]} km" : "--",
            "imaScore": match != null ? (match["final_score"] * 100).round() : 75,
            "imaReason": match != null ? match["reason"] : "Standard Match",
            "spoilageRisk": finalSpoilageRisk,
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
      backgroundColor: _softGrey,
      body: Stack(
        children: [
          // Modern Gradient Background
          _buildModernBackground(),

          // Main Content
          SafeArea(
            child: isCheckingRegistration
                ? const Center(child: CircularProgressIndicator(color: _primaryTeal))
                : !isRegistered
                    ? _buildRegistrationPrompt()
                    : Column(
                        children: [
                          // Modern App Bar
                          _buildModernAppBar(),

                          // Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Modern Header
                                  _buildModernHeader(),
                                  const SizedBox(height: 20),

                                  // Matches List
                                  Expanded(child: _buildModernMatchesList()),

                                  // Info Banner
                                  if (errorMessage != null) _buildModernErrorBanner(),
                                  _buildModernInfoBanner(),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ==================== MODERN HELPER WIDGETS ====================

  Widget _buildModernBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _cream,
                _lightTeal.withOpacity(0.3),
                _softGrey,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Organic blob shapes
              Positioned(
                top: -100 + (_floatController.value * 20),
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _lightTeal.withOpacity(0.2),
                  ),
                ),
              ),
              Positioned(
                bottom: 100 + (_floatController.value * 30),
                left: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _coral.withOpacity(0.15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _lightTeal.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_primaryTeal, _lightTeal]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.volunteer_activism, color: _white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Charity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _charcoal,
                      ),
                    ),
                    Text(
                      charityData?['name'] ?? 'My Charity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              _buildModernActionButton(
                icon: Icons.assessment_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                ),
              ),
              const SizedBox(width: 10),
              _buildModernActionButton(
                icon: Icons.logout_outlined,
                onTap: _logout,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300]!,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDestructive ? _darkCoral : _primaryTeal,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_coral, _darkCoral]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _coral.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: _white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available Matches",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _charcoal,
                    ),
                  ),
                  Text(
                    "Smart matching within 8-12 km radius",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lightTeal.withOpacity(0.2), _cream],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _lightTeal.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology, size: 16, color: _primaryTeal),
              const SizedBox(width: 8),
              Text(
                "AI-Powered Matching",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _primaryTeal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernMatchesList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: _primaryTeal,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              "Finding matches...",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (availableMatches.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[200]!,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_lightTeal, _cream]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: _primaryTeal,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                "No matches yet",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "New donations appear daily at 5:00 PM",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: availableMatches.length,
      itemBuilder: (context, index) {
        final match = availableMatches[index];
        return AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, index % 2 == 0 ? _floatAnimation.value : -_floatAnimation.value * 0.5),
              child: _buildModernMatchCard(match),
            );
          },
        );
      },
    );
  }

  Widget _buildModernMatchCard(Map<String, dynamic> match) {
    final int imaScore = match['imaScore'] ?? 75;
    final String imaReason = match['imaReason'] ?? 'Standard Match';
    final double spoilageRisk = match['spoilageRisk'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_primaryTeal, _lightTeal]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline, color: _white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match["donorName"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _charcoal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            match["distance"],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _coral.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: _darkCoral),
                      const SizedBox(width: 4),
                      Text(
                        match["timeLeft"],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _darkCoral,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Food Type
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _softGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, size: 18, color: _primaryTeal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      match["foodType"],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stats Row
            Row(
              children: [
                _buildModernBadge(
                  icon: Icons.scale,
                  label: match["quantity"],
                  color: _primaryTeal,
                ),
                const SizedBox(width: 10),
                _buildModernBadge(
                  icon: Icons.psychology,
                  label: "IMA $imaScore",
                  color: imaScore > 80 ? _primaryTeal : _coral,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Spoilage Risk Indicator with Progress Bar
            _buildSpoilageRiskIndicator(spoilageRisk, match["timeUntilSpoilage"] ?? ""),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildModernClaimButton(match["id"]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildModernMapButton(match),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpoilageRiskIndicator(double risk, String timeLeft) {
    final riskInfo = SpoilageRiskCalculator.getRiskInfo(risk);
    final riskColor = Color(riskInfo.color);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                risk > 0.5 ? Icons.warning_amber_rounded : Icons.thermostat,
                color: riskColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Spoilage Risk: ${(risk * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: riskColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  riskInfo.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: risk,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          
          // Time remaining message
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                timeLeft.isNotEmpty ? timeLeft : "Time remaining unknown",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernClaimButton(String donationId) {
    return GestureDetector(
      onTap: hasClaimedAny ? null : () => _claimDonation(donationId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: hasClaimedAny
              ? null
              : const LinearGradient(colors: [_coral, _darkCoral]),
          color: hasClaimedAny ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: hasClaimedAny
              ? null
              : [
                  BoxShadow(
                    color: _coral.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasClaimedAny ? Icons.check : Icons.favorite,
              color: hasClaimedAny ? Colors.grey[600] : _white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              hasClaimedAny ? "Claimed" : "Claim Pickup",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: hasClaimedAny ? Colors.grey[600] : _white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMapButton(Map<String, dynamic> match) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            donorLat: match["donorLat"],
            donorLon: match["donorLon"],
            charityLat: charityLat,
            charityLon: charityLon,
            donorName: match["donorName"],
            charityName: charityData?['name'] ?? "My Charity",
            foodType: match["foodType"],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _lightTeal, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: _primaryTeal, size: 18),
            const SizedBox(width: 6),
            Text(
              "View Map",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _primaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkCoral.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _darkCoral.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _darkCoral.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: _darkCoral, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: _darkCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_lightTeal.withOpacity(0.2), _cream],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightTeal.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline, color: _primaryTeal, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Unclaimed donations move to Tier 2 (Rider Delivery) after 5:30 PM",
                  style: TextStyle(
                    fontSize: 13,
                    color: _charcoal,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: _primaryTeal),
                SizedBox(width: 8),
                Text(
                  "AI: Haversine + IMA + Spoilage",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_coral, _darkCoral],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _coral.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.volunteer_activism,
                      size: 60,
                      color: _white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              "Register Your Charity",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _charcoal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Complete your charity registration to start receiving food donations",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () async {
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
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryTeal, _lightTeal],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryTeal.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_business, color: _white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          "Register Now",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== WAVE PAINTER ====================

class _WavePainter extends CustomPainter {
  final double animation;
  final Color color;

  _WavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.3);

    for (var i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final y = size.height * 0.3 + sin((x / size.width * 2 * pi) + (animation * 2 * pi)) * 12;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}