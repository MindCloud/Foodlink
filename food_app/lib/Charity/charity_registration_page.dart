// lib/Charity/charity_registration_page.dart
import 'package:flutter/material.dart';
import 'dart:math' show pi, sin;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/firestore_service.dart';

// Theme Colors - Green, Yellow, White, Black
const Color _primaryGreen = Color(0xFF1B5E20);
const Color _lightGreen = Color(0xFF4CAF50);
const Color _accentYellow = Color(0xFFFFD700);
const Color _brightYellow = Color(0xFFFFEB3B);
const Color _black = Color(0xFF0D0D0D);
const Color _white = Color(0xFFFFFFFF);

class CharityRegistrationPage extends StatefulWidget {
  const CharityRegistrationPage({super.key});

  @override
  State<CharityRegistrationPage> createState() => _CharityRegistrationPageState();
}

class _CharityRegistrationPageState extends State<CharityRegistrationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  // Animations
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Position? _currentPosition;
  String _locationStatus = "Tap to capture location";
  bool _hasColdStorage = false;
  bool _isLoading = false;
  
  // Manual location input
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  bool _useManualLocation = false;
  
  // Location search with autocomplete
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounceTimer;
  
  // Common Sri Lanka locations for quick selection
  final List<Map<String, dynamic>> _commonLocations = [
    {'name': 'Colombo Fort', 'lat': 6.9319, 'lon': 79.8478, 'type': 'city'},
    {'name': 'Dehiwala-Mount Lavinia', 'lat': 6.8569, 'lon': 79.8652, 'type': 'city'},
    {'name': 'Kandy', 'lat': 7.2906, 'lon': 80.6337, 'type': 'city'},
    {'name': 'Galle', 'lat': 6.0329, 'lon': 80.2168, 'type': 'city'},
    {'name': 'Jaffna', 'lat': 9.6615, 'lon': 80.0255, 'type': 'city'},
    {'name': 'Negombo', 'lat': 7.2090, 'lon': 79.8350, 'type': 'city'},
    {'name': 'Nuwara Eliya', 'lat': 6.9696, 'lon': 80.7892, 'type': 'city'},
    {'name': 'Anuradhapura', 'lat': 8.3114, 'lon': 80.4037, 'type': 'city'},
    {'name': 'Trincomalee', 'lat': 8.5874, 'lon': 81.2152, 'type': 'city'},
    {'name': 'Batticaloa', 'lat': 7.9965, 'lon': 81.6783, 'type': 'city'},
    {'name': 'Matara', 'lat': 5.9496, 'lon': 80.5353, 'type': 'city'},
    {'name': 'Kurunegala', 'lat': 7.4863, 'lon': 80.3623, 'type': 'city'},
    {'name': 'Ratnapura', 'lat': 6.6828, 'lon': 80.3990, 'type': 'city'},
    {'name': 'Badulla', 'lat': 6.9895, 'lon': 81.0557, 'type': 'city'},
    {'name': 'Polonnaruwa', 'lat': 7.9403, 'lon': 81.0188, 'type': 'city'},
    {'name': 'Gampaha', 'lat': 7.0917, 'lon': 79.9986, 'type': 'city'},
    {'name': 'Kalutara', 'lat': 6.5833, 'lon': 79.9614, 'type': 'city'},
    {'name': 'Moratuwa', 'lat': 6.7881, 'lon': 79.8912, 'type': 'city'},
    {'name': 'Maharagama', 'lat': 6.8483, 'lon': 79.9259, 'type': 'city'},
    {'name': 'Pettah', 'lat': 6.9350, 'lon': 79.8500, 'type': 'suburb'},
    {'name': 'Bambalapitiya', 'lat': 6.8880, 'lon': 79.8580, 'type': 'suburb'},
    {'name': 'Wellawatte', 'lat': 6.8700, 'lon': 79.8600, 'type': 'suburb'},
    {'name': 'Borella', 'lat': 6.9100, 'lon': 79.8800, 'type': 'suburb'},
    {'name': 'Nugegoda', 'lat': 6.8640, 'lon': 79.8930, 'type': 'suburb'},
    {'name': 'Rajagiriya', 'lat': 6.9100, 'lon': 79.8950, 'type': 'suburb'},
    {'name': 'Kotte', 'lat': 6.9000, 'lon': 79.9200, 'type': 'suburb'},
    {'name': 'Malabe', 'lat': 6.9060, 'lon': 79.9500, 'type': 'suburb'},
    {'name': 'Kelaniya', 'lat': 6.9500, 'lon': 79.9200, 'type': 'suburb'},
    {'name': 'Wattala', 'lat': 6.9800, 'lon': 79.8900, 'type': 'suburb'},
    {'name': 'Ja-Ela', 'lat': 7.0200, 'lon': 79.8900, 'type': 'suburb'},
    {'name': 'Ragama', 'lat': 7.0300, 'lon': 79.9200, 'type': 'suburb'},
  ];

  final List<String> _charityTypes = [
    'Old Age Home',
    'Orphanage',
    'Community Kitchen',
    'Homeless Shelter',
    'Disaster Relief',
    'School Feeding Program',
    'Other',
  ];
  String? _selectedCharityType;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Search location using OpenStreetMap Nominatim (free, no API key needed)
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    // First filter common locations
    final filteredCommon = _commonLocations.where((loc) => 
      loc['name'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();

    setState(() {
      _isSearching = true;
      _searchResults = filteredCommon;
      _showSearchResults = true;
    });

    // Debounce API call - wait 500ms after user stops typing
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Using OpenStreetMap Nominatim API (free, no API key required)
        final encodedQuery = Uri.encodeComponent(query + ', Sri Lanka'); // Focus on Sri Lanka
        final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&countrycodes=lk';
        
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'FoodLinkApp/1.0'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final apiResults = data.map((place) => {
            'name': place['display_name'],
            'lat': double.parse(place['lat']),
            'lon': double.parse(place['lon']),
            'type': place['type'],
          }).toList();
          
          // Combine common + API results, remove duplicates
          final allResults = [...filteredCommon];
          for (var apiResult in apiResults) {
            final isDuplicate = allResults.any((r) => 
              (r['lat'] as double).toStringAsFixed(3) == (apiResult['lat'] as double).toStringAsFixed(3) &&
              (r['lon'] as double).toStringAsFixed(3) == (apiResult['lon'] as double).toStringAsFixed(3)
            );
            if (!isDuplicate) {
              allResults.add(apiResult);
            }
          }
          
          setState(() {
            _searchResults = allResults.take(8).toList(); // Limit to 8 results
            _showSearchResults = true;
            _isSearching = false;
          });
        }
      } catch (e) {
        print('Search error: $e');
        setState(() => _isSearching = false);
        // Still show common results even if API fails
      }
    });
  }

  void _onSearchChanged(String value) {
    if (value.length >= 2) {
      _searchLocation(value);
    } else if (value.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> place) {
    setState(() {
      _latitudeController.text = place['lat'].toString();
      _longitudeController.text = place['lon'].toString();
      _searchController.text = place['name'].toString().split(',')[0]; // Short name
      _showSearchResults = false;
      _searchResults = [];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Location set: ${place['name'].toString().split(',')[0]}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locationStatus = "Getting GPS...");

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services disabled");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus = "✅ ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      });
    } catch (e) {
      setState(() => _locationStatus = "❌ Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location error: $e")),
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate location is provided (either GPS or manual)
    double? finalLatitude;
    double? finalLongitude;
    
    if (!_useManualLocation) {
      // Use GPS location
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please capture current GPS location or switch to manual entry")),
        );
        return;
      }
      finalLatitude = _currentPosition!.latitude;
      finalLongitude = _currentPosition!.longitude;
    } else {
      // Use manual location
      final lat = double.tryParse(_latitudeController.text.trim());
      final lon = double.tryParse(_longitudeController.text.trim());
      if (lat == null || lon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid latitude and longitude")),
        );
        return;
      }
      finalLatitude = lat;
      finalLongitude = lon;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.createCharity({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'charityType': _selectedCharityType,
        'latitude': finalLatitude,
        'longitude': finalLongitude,
        'locationSource': _useManualLocation ? 'manual' : 'gps',
        'hasColdStorage': _hasColdStorage,
        'capacityRemaining': int.tryParse(_capacityController.text) ?? 50,
        'description': _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Charity registered successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Animated Header
          _buildAnimatedHeader(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Charity Name
                          _buildSectionHeader(Icons.business, "Charity Name"),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _nameController,
                            hint: "Enter charity name",
                            icon: Icons.business,
                            validator: (v) => v?.isEmpty ?? true ? "Name required" : null,
                          ),
                          const SizedBox(height: 24),

                          // Charity Type
                          _buildSectionHeader(Icons.category, "Charity Type"),
                          const SizedBox(height: 12),
                          _buildCharityTypeDropdown(),
                          const SizedBox(height: 24),

                          // Address
                          _buildSectionHeader(Icons.location_on, "Address"),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _addressController,
                            hint: "Enter full address",
                            icon: Icons.home,
                            maxLines: 2,
                            validator: (v) => v?.isEmpty ?? true ? "Address required" : null,
                          ),
                          const SizedBox(height: 24),

                          // Phone
                          _buildSectionHeader(Icons.phone, "Phone Number"),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _phoneController,
                            hint: "Enter phone number",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v?.isEmpty ?? true ? "Phone required" : null,
                          ),
                          const SizedBox(height: 24),

                          // Location
                          _buildSectionHeader(Icons.my_location, "Location (Required)"),
                          const SizedBox(height: 12),
                          _buildLocationCard(),
                          const SizedBox(height: 24),

                          // Cold Storage
                          _buildStorageSection(),
                          const SizedBox(height: 24),

                          // Capacity
                          _buildSectionHeader(Icons.scale, "Daily Capacity (kg)"),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _capacityController,
                            hint: "e.g., 50",
                            icon: Icons.scale,
                            keyboardType: TextInputType.number,
                            validator: (v) => v?.isEmpty ?? true ? "Capacity required" : null,
                          ),
                          const SizedBox(height: 24),

                          // Description
                          _buildSectionHeader(Icons.description, "Description (Optional)"),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _descriptionController,
                            hint: "Tell us about your charity",
                            icon: Icons.edit_note,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animated Submit Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isLoading ? 1.0 : _pulseAnimation.value,
                  child: _buildSubmitButton(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryGreen, _lightGreen, _accentYellow],
              stops: [0.3, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              // Floating Charity Icons
              ..._buildFloatingIcons(),
              // Wave
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(double.infinity, 50),
                  painter: _WavePainter(
                    animation: _floatController.value,
                    color: Colors.grey[50]!,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingIcons() {
    final icons = [Icons.volunteer_activism, Icons.favorite, Icons.food_bank, Icons.local_dining];
    return List.generate(4, (index) {
      return AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final offset = sin((_floatController.value * 2 * pi) + (index * 0.8)) * 12;
          return Positioned(
            top: 30 + (index * 35) + offset,
            left: index.isEven ? 25 + (index * 30) : null,
            right: !index.isEven ? 25 + ((3 - index) * 30) : null,
            child: Opacity(
              opacity: 0.12,
              child: Icon(icons[index], size: 28 + (index * 3), color: _white),
            ),
          );
        },
      );
    });
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.arrow_back_ios, color: _white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Register Charity",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(color: _black, blurRadius: 10, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Join our food rescue network",
                  style: TextStyle(
                    fontSize: 13,
                    color: _white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accentYellow, _brightYellow]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _accentYellow.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _primaryGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _black,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accentYellow, _brightYellow]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryGreen, size: 20),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightGreen, width: 2),
        ),
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildCharityTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          hintText: "Select charity type",
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accentYellow, _brightYellow]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.category, color: _primaryGreen, size: 20),
          ),
        ),
        value: _selectedCharityType,
        items: _charityTypes.map((type) => DropdownMenuItem(
          value: type,
          child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
        )).toList(),
        onChanged: (val) => setState(() => _selectedCharityType = val),
        validator: (v) => v == null ? "Type required" : null,
        icon: const Icon(Icons.arrow_drop_down, color: _primaryGreen),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toggle Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    label: "GPS Location",
                    icon: Icons.my_location,
                    isSelected: !_useManualLocation,
                    onTap: () => setState(() => _useManualLocation = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildToggleButton(
                    label: "Manual Entry",
                    icon: Icons.edit_location,
                    isSelected: _useManualLocation,
                    onTap: () => setState(() => _useManualLocation = true),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: !_useManualLocation ? _buildGPSContent() : _buildManualLocationContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_lightGreen, _primaryGreen])
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? _white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? _white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSContent() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentPosition != null
                          ? [_lightGreen.withOpacity(0.2), _lightGreen.withOpacity(0.1)]
                          : [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: _currentPosition != null ? _lightGreen : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPosition != null ? "Location Captured" : "Capture Location",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _currentPosition != null ? _lightGreen : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentPosition != null
                            ? "${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}"
                            : "Tap button to get GPS coordinates",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildAnimatedButton(
              onPressed: _getCurrentLocation,
              icon: Icons.location_searching,
              label: _currentPosition != null ? "Update Location" : "Capture GPS",
              gradient: const [_lightGreen, _primaryGreen],
            ),
          ],
        );
      },
    );
  }

  Widget _buildManualLocationContent() {
    return Column(
      children: [
        _buildSearchField(),
        if (_showSearchResults) _buildSearchResults(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCoordField(_latitudeController, "Latitude", Icons.north),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCoordField(_longitudeController, "Longitude", Icons.east),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search location...",
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accentYellow, _brightYellow]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.search, color: _primaryGreen, size: 18),
        ),
        suffixIcon: _isSearching
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen),
                ),
              )
            : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _showSearchResults = false;
                      });
                    },
                  )
                : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _lightGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: _lightGreen.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
        color: _white,
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: _searchResults.isNotEmpty
          ? ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                final isCommon = _commonLocations.contains(place);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_on,
                    color: isCommon ? _lightGreen : Colors.blue,
                    size: 20,
                  ),
                  title: Text(
                    place['name'].toString().split(',')[0],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCommon ? _primaryGreen : _black,
                    ),
                  ),
                  subtitle: Text(
                    '${place['lat'].toStringAsFixed(4)}, ${place['lon'].toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  trailing: isCommon
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentYellow.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(fontSize: 8, color: _primaryGreen, fontWeight: FontWeight.w800),
                          ),
                        )
                      : null,
                  onTap: () => _selectSearchResult(place),
                );
              },
            )
          : _isSearching
              ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
              : const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No results found', style: TextStyle(color: Colors.grey)),
                ),
    );
  }

  Widget _buildCoordField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildStorageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasColdStorage ? _lightGreen.withOpacity(0.1) : _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasColdStorage ? _lightGreen : Colors.grey[200]!,
          width: _hasColdStorage ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: _hasColdStorage
                  ? const LinearGradient(colors: [_lightGreen, _primaryGreen])
                  : const LinearGradient(colors: [Colors.grey, Colors.grey]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _hasColdStorage ? Icons.ac_unit : Icons.thermostat,
              color: _white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cold Storage",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _hasColdStorage ? _primaryGreen : _black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "For perishable food items",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _hasColdStorage,
            onChanged: (val) => setState(() => _hasColdStorage = val),
            activeColor: _lightGreen,
            activeTrackColor: _lightGreen.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient[1].withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submitRegistration,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
                  colors: [_accentYellow, _brightYellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isLoading ? Colors.grey[400] : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _isLoading ? Colors.grey : _accentYellow.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: _white, strokeWidth: 3),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Registering...",
                    style: TextStyle(
                      color: _white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism, color: _primaryGreen, size: 26),
                  SizedBox(width: 12),
                  Text(
                    "REGISTER CHARITY",
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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
