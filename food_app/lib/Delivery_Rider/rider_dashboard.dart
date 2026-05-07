import 'package:flutter/material.dart';
import 'dart:math' show pi, sin;
import 'package:firebase_auth/firebase_auth.dart';
import '../role_selection_page.dart';
import '../screens/map_screen.dart';

// Rider Theme - Energetic Orange & Deep Indigo
const Color _primaryIndigo = Color(0xFF4F46E5);
const Color _lightIndigo = Color(0xFF818CF8);
const Color _deepOrange = Color(0xFFEA580C);
const Color _amber = Color(0xFFF59E0B);
const Color _cream = Color(0xFFFEF7ED);
const Color _charcoal = Color(0xFF1F2937);
const Color _white = Color(0xFFFFFFFF);
const Color _softGrey = Color(0xFFF9FAFB);

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

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

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

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
      backgroundColor: _softGrey,
      body: Stack(
        children: [
          // Animated Background
          _buildRiderBackground(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Modern App Bar
                _buildRiderAppBar(),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: activeJob == null
                        ? _buildAvailableJobsView()
                        : _buildActiveJobView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MODERN RIDER WIDGETS ====================

  Widget _buildRiderBackground() {
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
                _lightIndigo.withOpacity(0.2),
                _softGrey,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated route/path shapes
              Positioned(
                top: -50 + (_floatController.value * 30),
                right: -30,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _deepOrange.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 150 - (_floatController.value * 20),
                left: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryIndigo.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiderAppBar() {
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
                  color: _deepOrange.withOpacity(0.2),
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
                    gradient: const LinearGradient(colors: [_deepOrange, _amber]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping, color: _white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rider",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _charcoal,
                      ),
                    ),
                    Text(
                      "On Duty",
                      style: TextStyle(
                        fontSize: 12,
                        color: _deepOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logout
          GestureDetector(
            onTap: _logout,
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
              child: const Icon(Icons.logout_outlined, color: _deepOrange, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_deepOrange, _amber]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _deepOrange.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.delivery_dining, color: _white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available Jobs",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _charcoal,
                    ),
                  ),
                  Text(
                    "Tier 2 fallback deliveries",
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
        const SizedBox(height: 20),

        // Jobs List
        Expanded(child: _buildJobsList()),
      ],
    );
  }

  Widget _buildJobsList() {
    if (availableJobs.isEmpty) {
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
                        gradient: const LinearGradient(colors: [_cream, _amber]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        size: 48,
                        color: _deepOrange,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                "No jobs available",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "New Tier 2 jobs appear after 5:30 PM",
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
      itemCount: availableJobs.length,
      itemBuilder: (context, index) {
        final job = availableJobs[index];
        return AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, index % 2 == 0 ? _floatAnimation.value : -_floatAnimation.value * 0.5),
              child: _buildJobCard(job),
            );
          },
        );
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final fare = _calculateFare(job["distance"]);

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
                    gradient: const LinearGradient(colors: [_primaryIndigo, _lightIndigo]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "#${job["id"].toString().substring(3)}",
                    style: const TextStyle(
                      color: _white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    job["foodType"],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _charcoal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.route, size: 12, color: _deepOrange),
                      const SizedBox(width: 4),
                      Text(
                        "${job["distance"]} km",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _softGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildRouteRow(
                    icon: Icons.restaurant,
                    label: "From",
                    value: job["donorName"],
                    address: job["donorLocation"],
                    color: _deepOrange,
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey[300], height: 1),
                  const SizedBox(height: 10),
                  _buildRouteRow(
                    icon: Icons.favorite,
                    label: "To",
                    value: job["charityName"],
                    address: job["charityLocation"],
                    color: _primaryIndigo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats & Fare
            Row(
              children: [
                _buildRiderBadge(
                  icon: Icons.scale,
                  label: job["quantity"],
                  color: _charcoal,
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_deepOrange, _amber]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments, size: 14, color: _white),
                      const SizedBox(width: 6),
                      Text(
                        "LKR ${fare.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildAcceptButton(job),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteRow({
    required IconData icon,
    required String label,
    required String value,
    required String address,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$label: $value",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiderBadge({
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

  Widget _buildAcceptButton(Map<String, dynamic> job) {
    return GestureDetector(
      onTap: () => _acceptJob(job),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_deepOrange, _amber]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _deepOrange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: _white, size: 16),
            SizedBox(width: 6),
            Text(
              "ACCEPT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobView() {
    final fare = _calculateFare(activeJob!["distance"]);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_primaryIndigo, _lightIndigo]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryIndigo.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.delivery_dining, color: _white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Active Delivery",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _charcoal,
                      ),
                    ),
                    Text(
                      "In progress",
                      style: TextStyle(
                        fontSize: 13,
                        color: _primaryIndigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Job Card
          Container(
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job ID & Fare
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _deepOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Job #${activeJob!["id"].toString().substring(3)}",
                          style: TextStyle(
                            color: _deepOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_deepOrange, _amber]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "LKR ${fare.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Food Type
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _softGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.restaurant_menu, color: _primaryIndigo, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            activeJob!["foodType"],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Route
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildRouteRow(
                          icon: Icons.restaurant,
                          label: "Pickup",
                          value: activeJob!["donorName"],
                          address: activeJob!["donorLocation"],
                          color: _deepOrange,
                        ),
                        const SizedBox(height: 12),
                        Divider(color: _amber.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        _buildRouteRow(
                          icon: Icons.favorite,
                          label: "Deliver",
                          value: activeJob!["charityName"],
                          address: activeJob!["charityLocation"],
                          color: _primaryIndigo,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildMapButton(),
                  const SizedBox(height: 12),
                  _buildStatusButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton() {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryIndigo, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: _primaryIndigo, size: 20),
            const SizedBox(width: 10),
            Text(
              "View Route on Map",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _primaryIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton() {
    if (currentJobStatus == "delivered") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _lightIndigo.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryIndigo.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: _primaryIndigo, size: 24),
            const SizedBox(width: 10),
            Text(
              "Delivery Completed",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _primaryIndigo,
              ),
            ),
          ],
        ),
      );
    }

    final isPickup = currentJobStatus == "accepted";
    return GestureDetector(
      onTap: isPickup ? _markAsPickedUp : _markAsDelivered,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPickup
                ? [_deepOrange, _amber]
                : [_primaryIndigo, _lightIndigo],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (isPickup ? _deepOrange : _primaryIndigo).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPickup ? Icons.inventory_2 : Icons.check_circle,
              color: _white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              isPickup ? "MARK AS PICKED UP" : "MARK AS DELIVERED",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}