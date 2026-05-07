import 'package:flutter/material.dart';
import 'dart:math' show pi, sin;
import 'login_page.dart';

// Role Selection Theme - Ultra Vibrant Rainbow Palette
const Color _primaryGreen = Color(0xFF10B981);
const Color _lightGreen = Color(0xFF34D399);
const Color _brightGreen = Color(0xFF6EE7B7);
const Color _primaryOrange = Color(0xFFF97316);
const Color _lightOrange = Color(0xFFFB923C);
const Color _brightOrange = Color(0xFFFDBA74);
const Color _primaryBlue = Color(0xFF3B82F6);
const Color _lightBlue = Color(0xFF60A5FA);
const Color _brightBlue = Color(0xFF93C5FD);
const Color _primaryPurple = Color(0xFF8B5CF6);
const Color _lightPurple = Color(0xFFA78BFA);
const Color _brightPurple = Color(0xFFC4B5FD);
const Color _primaryPink = Color(0xFFEC4899);
const Color _lightPink = Color(0xFFF472B6);
const Color _primaryYellow = Color(0xFFEAB308);
const Color _lightYellow = Color(0xFFFDE047);
const Color _primaryRed = Color(0xFFEF4444);
const Color _lightCyan = Color(0xFF22D3EE);
const Color _charcoal = Color(0xFF1F2937);
const Color _white = Color(0xFFFFFFFF);
const Color _softGrey = Color(0xFFF8FAFC);
const Color _warmCream = Color(0xFFFFFBEB);

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _scaleController;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Logo + Header
                    _buildHeader(),

                    const SizedBox(height: 40),

                    // Role Selection Title
                    _buildSectionTitle(),

                    const SizedBox(height: 24),

                    // Role Cards
                    _buildRoleCard(
                      icon: Icons.restaurant_outlined,
                      title: "Food Donor",
                      subtitle: "Share surplus food with those in need",
                      roleKey: "donor",
                      roleName: "Food Donor",
                      gradient: const [_primaryGreen, _lightGreen],
                      delay: 0,
                    ),
                    const SizedBox(height: 16),

                    _buildRoleCard(
                      icon: Icons.volunteer_activism,
                      title: "Charity / NGO",
                      subtitle: "Receive donations for your organization",
                      roleKey: "charity",
                      roleName: "Charity",
                      gradient: const [_primaryOrange, _lightOrange],
                      delay: 100,
                    ),
                    const SizedBox(height: 16),

                    _buildRoleCard(
                      icon: Icons.attach_money,
                      title: "Financial Sponsor",
                      subtitle: "Support food rescue with funds",
                      roleKey: "sponsor",
                      roleName: "Financial Sponsor",
                      gradient: const [_primaryBlue, _lightBlue],
                      delay: 200,
                    ),
                    const SizedBox(height: 16),

                    _buildRoleCard(
                      icon: Icons.delivery_dining,
                      title: "Delivery Rider",
                      subtitle: "Help deliver food to charities",
                      roleKey: "rider",
                      roleName: "Delivery Rider",
                      gradient: const [_primaryPurple, _lightPurple],
                      delay: 300,
                    ),

                    const SizedBox(height: 32),

                    // Guest Option
                    _buildGuestOption(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.topLeft,
              colors: [
                _primaryPink.withOpacity(0.15),
                _primaryPurple.withOpacity(0.12),
                _primaryBlue.withOpacity(0.15),
                _primaryGreen.withOpacity(0.12),
                _primaryYellow.withOpacity(0.15),
                _primaryOrange.withOpacity(0.12),
                _primaryRed.withOpacity(0.15),
                _primaryPink.withOpacity(0.15),
              ],
              stops: const [0.0, 0.14, 0.28, 0.42, 0.56, 0.70, 0.84, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Large colorful floating circles
              Positioned(
                top: 40 + _floatAnimation.value,
                right: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryPink.withOpacity(0.3),
                        _primaryPink.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 180 - _floatAnimation.value * 0.6,
                left: -60,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryOrange.withOpacity(0.25),
                        _primaryOrange.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 200 + _floatAnimation.value * 0.4,
                right: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryBlue.withOpacity(0.25),
                        _primaryBlue.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 350 - _floatAnimation.value * 0.5,
                left: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryGreen.withOpacity(0.25),
                        _primaryGreen.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 350 + _floatAnimation.value * 0.3,
                right: 60,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryPurple.withOpacity(0.3),
                        _primaryPurple.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100 - _floatAnimation.value * 0.4,
                left: 80,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryYellow.withOpacity(0.25),
                        _primaryYellow.withOpacity(0.0),
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

  Widget _buildHeader() {
    return Column(
      children: [
        // Rainbow Logo Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryPink,
                _primaryPurple,
                _primaryBlue,
                _primaryGreen,
                _primaryYellow,
                _primaryOrange,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _primaryPurple.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.food_bank,
            size: 60,
            color: _white,
          ),
        ),
        const SizedBox(height: 24),

        // Welcome Text with Gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_primaryPurple, _primaryBlue, _primaryGreen, _primaryOrange],
          ).createShader(bounds),
          child: const Text(
            "FoodLink",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: _white,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Rainbow Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryPink, _primaryPurple, _primaryBlue],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: _primaryPurple.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, color: _white, size: 16),
              SizedBox(width: 8),
              Text(
                "Connect • Share • Nourish",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _white,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.favorite, color: _white, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Choose your colorful journey to reduce food waste",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_white, _softGrey],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryPurple.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryPink, _primaryPurple, _primaryBlue],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _primaryPurple.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.palette,
              color: _white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_primaryPurple, _primaryBlue, _primaryGreen],
            ).createShader(bounds),
            child: const Text(
              "Select Your Role",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String roleKey,
    required String roleName,
    required List<Color> gradient,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
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
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _white,
                      gradient[1].withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: gradient[0].withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon Container with Rainbow Border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primaryPink,
                              _primaryPurple,
                              _primaryBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradient),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: gradient[0].withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 28, color: _white),
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: gradient[0],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Animated Arrow with Gradient
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: _white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestOption() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Guest mode - Limited view (coming soon)",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _charcoal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryPink,
              _primaryPurple,
              _primaryBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryPurple.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, color: _white, size: 22),
            SizedBox(width: 12),
            Text(
              "Continue as Guest",
              style: TextStyle(
                fontSize: 16,
                color: _white,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: _white, size: 20),
          ],
        ),
      ),
    );
  }
}