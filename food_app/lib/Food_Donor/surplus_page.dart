import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/firestore_service.dart';

class LogSurplusFoodPage extends StatefulWidget {
  const LogSurplusFoodPage({super.key});

  @override
  State<LogSurplusFoodPage> createState() => _LogSurplusFoodPageState();
}

class _LogSurplusFoodPageState extends State<LogSurplusFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final foodTypeController = TextEditingController();
  final quantityController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void dispose() {
    foodTypeController.dispose();
    quantityController.dispose();
    notesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Position? _currentPosition;
  String _locationStatus = "Tap to capture current location";

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

  TimeOfDay? _pickupFrom;
  TimeOfDay? _pickupTo;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _requiresColdStorage = false;
  double _expiryHours = 4.0;

  final List<String> commonFoodTypes = [
    'Cooked Rice & Curry',
    'Vegetable Biryani',
    'String Hoppers & Kiri Hodi',
    'Bread & Pastries',
    'Fresh Fruits',
    'Cooked Meals',
    'Packaged Snacks',
    'Dairy Products',
    'Other',
  ];

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
        _locationStatus = "✅ Captured: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      });
    } catch (e) {
      setState(() => _locationStatus = "❌ Error capturing location");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location error: $e")));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _submitDonation() async {
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

    if (_pickupFrom == null || _pickupTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select pickup time window")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? imageUrl;

      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('donations/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await _firestoreService.createDonation({
        'foodType': foodTypeController.text.trim(),
        'quantity': '${quantityController.text.trim()} kg',
        'quantityKg': double.tryParse(quantityController.text.trim()) ?? 0,
        'notes': notesController.text.trim(),
        'latitude': finalLatitude,
        'longitude': finalLongitude,
        'locationSource': _useManualLocation ? 'manual' : 'gps',
        'pickupFrom': _pickupFrom!.format(context),
        'pickupTo': _pickupTo!.format(context),
        'imageUrl': imageUrl ?? '',
        'coldRequired': _requiresColdStorage,
        'expiryHours': _expiryHours,
        'status': 'Logged',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Surplus food logged successfully!"), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Surplus Food"), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Food Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text("Select food type"),
                items: commonFoodTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => foodTypeController.text = val ?? '',
              ),
              const SizedBox(height: 24),

              const Text("Quantity (kg)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "e.g. 12"),
                validator: (v) => v?.isEmpty ?? true ? "Quantity required" : null,
              ),
              const SizedBox(height: 24),

              const Text("Location (Required for matching)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              // Location method toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Current GPS"),
                              selected: !_useManualLocation,
                              onSelected: (selected) {
                                if (selected) setState(() => _useManualLocation = false);
                              },
                              selectedColor: Colors.green,
                              labelStyle: TextStyle(
                                color: !_useManualLocation ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Enter Manually"),
                              selected: _useManualLocation,
                              onSelected: (selected) {
                                if (selected) setState(() => _useManualLocation = true);
                              },
                              selectedColor: Colors.green,
                              labelStyle: TextStyle(
                                color: _useManualLocation ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Show GPS capture or manual input based on selection
                      if (!_useManualLocation) ...[
                        ListTile(
                          leading: const Icon(Icons.my_location, color: Colors.green, size: 32),
                          title: Text(
                            _currentPosition != null
                                ? "✅ ${(_currentPosition!.latitude).toStringAsFixed(4)}, ${(_currentPosition!.longitude).toStringAsFixed(4)}"
                                : "Tap capture to get current location",
                            style: TextStyle(
                              fontSize: 14,
                              color: _currentPosition != null ? Colors.green : Colors.grey,
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.location_searching),
                            label: const Text("Capture"),
                          ),
                        ),
                      ] else ...[
                        // Search bar with autocomplete
                        TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: "Search location",
                            hintText: "Start typing... (e.g., Col, Kan, Gal)",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchResults = [];
                                            _showSearchResults = false;
                                          });
                                        },
                                      )
                                    : null,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Type at least 2 letters to see suggestions",
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),

                        // Search results dropdown
                        if (_showSearchResults) ...[
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: _searchResults.isNotEmpty
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      final place = _searchResults[index];
                                      final isCommon = _commonLocations.contains(place);
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _selectSearchResult(place),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              border: index < _searchResults.length - 1
                                                  ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                                                  : null,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  color: isCommon ? Colors.green : Colors.blue,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        place['name'].toString().split(',')[0],
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: isCommon ? Colors.green.shade700 : Colors.black87,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (place['name'].toString().contains(','))
                                                        Text(
                                                          place['name'].toString().split(',').skip(1).take(2).join(', '),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey[600],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      Text(
                                                        '${place['lat'].toStringAsFixed(4)}, ${place['lon'].toStringAsFixed(4)}',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey[500],
                                                          fontFamily: 'monospace',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isCommon)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade100,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'Popular',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: Colors.green.shade700,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : _isSearching
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'No locations found. Try typing more letters or enter coordinates manually below.',
                                          style: TextStyle(color: Colors.grey, fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Or enter coordinates directly
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          "Or enter coordinates directly:",
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latitudeController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: const InputDecoration(
                                  labelText: "Latitude",
                                  hintText: "e.g., 6.9319",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.north),
                                ),
                                validator: (v) {
                                  if (_useManualLocation && (v?.isEmpty ?? true)) {
                                    return "Required";
                                  }
                                  final lat = double.tryParse(v ?? '');
                                  if (_useManualLocation && (lat == null || lat < -90 || lat > 90)) {
                                    return "Invalid latitude (-90 to 90)";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _longitudeController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: const InputDecoration(
                                  labelText: "Longitude",
                                  hintText: "e.g., 79.8478",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.east),
                                ),
                                validator: (v) {
                                  if (_useManualLocation && (v?.isEmpty ?? true)) {
                                    return "Required";
                                  }
                                  final lon = double.tryParse(v ?? '');
                                  if (_useManualLocation && (lon == null || lon < -180 || lon > 180)) {
                                    return "Invalid longitude (-180 to 180)";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text("Pickup Time Window", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setState(() => _pickupFrom = time);
                      },
                      child: Text(_pickupFrom != null ? "From: ${_pickupFrom!.format(context)}" : "Select From"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setState(() => _pickupTo = time);
                      },
                      child: Text(_pickupTo != null ? "To: ${_pickupTo!.format(context)}" : "Select To"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text("Storage Requirements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text("Requires Cold Storage"),
                subtitle: const Text("For perishable items like dairy, cooked meals"),
                value: _requiresColdStorage,
                onChanged: (val) => setState(() => _requiresColdStorage = val),
                activeColor: Colors.green,
              ),
              const SizedBox(height: 16),

              const Text("Expiry Time (Hours)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Slider(
                value: _expiryHours,
                min: 1,
                max: 24,
                divisions: 23,
                label: "${_expiryHours.toStringAsFixed(0)}h",
                onChanged: (val) => setState(() => _expiryHours = val),
              ),
              Center(
                child: Text(
                  "Food will expire in ${_expiryHours.toStringAsFixed(0)} hours",
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),

              const Text("Additional Notes (Optional)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Any special instructions?"),
              ),
              const SizedBox(height: 24),

              const Text("Photo of Food (Optional)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_selectedImage != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text("Camera")),
                  ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text("Gallery")),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDonation,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit & Log Surplus Food", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}