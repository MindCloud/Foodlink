import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../role_selection_page.dart';

// Sponsor Premium Theme - Navy, Gold & Emerald
const Color _deepNavy = Color(0xFF1E3A5F);
const Color _royalBlue = Color(0xFF2563EB);
const Color _gold = Color(0xFFF59E0B);
const Color _amber = Color(0xFFFBBF24);
const Color _emerald = Color(0xFF10B981);
const Color _emeraldLight = Color(0xFF34D399);
const Color _cream = Color(0xFFFEF9E7);
const Color _charcoal = Color(0xFF1F2937);
const Color _white = Color(0xFFFFFFFF);
const Color _softGrey = Color(0xFFF3F4F6);
const Color _rose = Color(0xFFF43F5E);

class SponsorDashboard extends StatefulWidget {
  const SponsorDashboard({super.key});

  @override
  State<SponsorDashboard> createState() => _SponsorDashboardState();
}

class _SponsorDashboardState extends State<SponsorDashboard>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

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

  // Export Spending Report
  void _exportSpendingReport() {
    final totalSpent = recentTransactions
        .where((tx) => tx["type"] == "spent")
        .fold<double>(0, (sum, tx) => sum + (tx["amount"] as num).abs());
    final totalAdded = recentTransactions
        .where((tx) => tx["type"] == "added")
        .fold<double>(0, (sum, tx) => sum + (tx["amount"] as num));
    final currentDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final reportContent = '''
═══════════════════════════════════════════════════════════════
                    FOODLINK SPONSOR REPORT
═══════════════════════════════════════════════════════════════

Generated: $currentDate
Sponsor: ${FirebaseAuth.instance.currentUser?.email ?? 'Unknown'}

-----------------------------------------------------------------
                           SUMMARY
-----------------------------------------------------------------
Current Balance:    LKR ${walletBalance.toStringAsFixed(2)}
Total Added:        LKR ${totalAdded.toStringAsFixed(2)}
Total Spent:        LKR ${totalSpent.toStringAsFixed(2)}
-----------------------------------------------------------------

TRANSACTION HISTORY:
==================

${recentTransactions.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final tx = entry.value;
      final type = tx["type"] == "added" ? "CREDIT" : "DEBIT";
      final amount = (tx["amount"] as num).abs().toStringAsFixed(2);
      return '''
#$index  [$type] ${tx["date"]} ${tx["time"]}
      Description: ${tx["description"]}
      Amount: LKR $amount
''';
    }).join('\n')}

═══════════════════════════════════════════════════════════════
              Thank you for supporting FoodLink!
═══════════════════════════════════════════════════════════════
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _royalBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf, color: _royalBlue, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Spending Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _softGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  reportContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Report generated successfully! Copy the report above or take a screenshot.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: _charcoal)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Report copied to clipboard!'),
                  backgroundColor: _emerald,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _royalBlue,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
      backgroundColor: _softGrey,
      body: Stack(
        children: [
          // Premium Background
          _buildSponsorBackground(),

          // Main Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Modern App Bar
                SliverToBoxAdapter(child: _buildSponsorAppBar()),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Wallet Card
                      _buildWalletCard(),
                      const SizedBox(height: 28),

                      // Stats Row
                      _buildStatsRow(),
                      const SizedBox(height: 28),

                      // Transactions Header
                      _buildSectionHeader("Recent Transactions", Icons.receipt_long),
                      const SizedBox(height: 16),

                      // Transactions List
                      _buildTransactionsList(),
                      const SizedBox(height: 24),

                      // Export Button
                      _buildExportButton(),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PREMIUM SPONSOR WIDGETS ====================

  Widget _buildSponsorBackground() {
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
                _softGrey,
                _white,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Elegant shapes
              Positioned(
                top: -80 + (_floatController.value * 20),
                right: -40,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _gold.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 200 - (_floatController.value * 15),
                left: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _royalBlue.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSponsorAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  color: _gold.withOpacity(0.2),
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
                    gradient: const LinearGradient(
                      colors: [_deepNavy, _royalBlue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance, color: _white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sponsor",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _charcoal,
                      ),
                    ),
                    Text(
                      "Financial Partner",
                      style: TextStyle(
                        fontSize: 12,
                        color: _gold,
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
              child: const Icon(Icons.logout_outlined, color: _deepNavy, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_deepNavy, _royalBlue],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _royalBlue.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wallet, color: _gold, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Wallet Balance",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: _gold,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Balance
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LKR",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: _white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      walletBalance.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _white,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      ".00",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: _white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Available for delivery sponsorship",
                  style: TextStyle(
                    fontSize: 14,
                    color: _white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 28),

                // Add Funds Button
                GestureDetector(
                  onTap: _showAddFundsDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_gold, _amber],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, color: _deepNavy, size: 22),
                        SizedBox(width: 10),
                        Text(
                          "Add Funds",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    final totalSpent = recentTransactions
        .where((tx) => tx["type"] == "spent")
        .fold<double>(0, (sum, tx) => sum + (tx["amount"] as num).abs());
    final totalAdded = recentTransactions
        .where((tx) => tx["type"] == "added")
        .fold<double>(0, (sum, tx) => sum + (tx["amount"] as num));

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_down,
            label: "Total Spent",
            value: "LKR ${totalSpent.toStringAsFixed(0)}",
            color: _rose,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            label: "Total Added",
            value: "LKR ${totalAdded.toStringAsFixed(0)}",
            color: _emerald,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_deepNavy, _royalBlue],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _royalBlue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: _white, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      children: recentTransactions.asMap().entries.map((entry) {
        final index = entry.key;
        final tx = entry.value;
        final isAdded = tx["type"] == "added";

        return AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, index % 2 == 0 ? _floatAnimation.value : -_floatAnimation.value),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[200]!,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAdded
                                ? [_emerald, _emeraldLight]
                                : [_rose, Colors.red[400]!],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isAdded ? Icons.add : Icons.delivery_dining,
                          color: _white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx["description"],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _charcoal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${tx["date"]} • ${tx["time"]}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Amount
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isAdded
                              ? _emerald.withOpacity(0.1)
                              : _rose.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAdded
                                ? _emerald.withOpacity(0.3)
                                : _rose.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          "${isAdded ? '+' : '-'}LKR ${(tx["amount"] as num).abs().toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isAdded ? _emerald : _rose,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: _exportSpendingReport,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _deepNavy, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: _deepNavy, size: 22),
            const SizedBox(width: 10),
            Text(
              "Export Spending Report (PDF)",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _deepNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}