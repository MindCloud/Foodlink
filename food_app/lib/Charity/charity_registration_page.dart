// lib/Charity/charity_registration_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class CharityRegistrationPage extends StatefulWidget {
  const CharityRegistrationPage({super.key});

  @override
  State<CharityRegistrationPage> createState() => _CharityRegistrationPageState();
}

class _CharityRegistrationPageState extends State<CharityRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Position? _currentPosition;
  String _locationStatus = "Tap to capture location";
  bool _hasColdStorage = false;
  bool _isLoading = false;

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
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture your location")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.createCharity({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'charityType': _selectedCharityType,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
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
      appBar: AppBar(
        title: const Text("Register Charity"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Charity Name
              _buildSectionTitle("Charity Name"),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration("Enter charity name"),
                validator: (v) => v?.isEmpty ?? true ? "Name required" : null,
              ),
              const SizedBox(height: 24),

              // Charity Type
              _buildSectionTitle("Charity Type"),
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration("Select type"),
                value: _selectedCharityType,
                items: _charityTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCharityType = val),
                validator: (v) => v == null ? "Type required" : null,
              ),
              const SizedBox(height: 24),

              // Address
              _buildSectionTitle("Address"),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: _buildInputDecoration("Enter full address"),
                validator: (v) => v?.isEmpty ?? true ? "Address required" : null,
              ),
              const SizedBox(height: 24),

              // Phone
              _buildSectionTitle("Phone Number"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration("Enter phone number"),
                validator: (v) => v?.isEmpty ?? true ? "Phone required" : null,
              ),
              const SizedBox(height: 24),

              // Location
              _buildSectionTitle("Location (Required for Matching)"),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green, size: 32),
                  title: Text(
                    _locationStatus,
                    style: TextStyle(fontSize: 14, color: _locationStatus.startsWith("✅") ? Colors.green : Colors.grey),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text("Capture"),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Cold Storage
              _buildSectionTitle("Facilities"),
              SwitchListTile(
                title: const Text("Has Cold Storage"),
                subtitle: const Text("For perishable items"),
                value: _hasColdStorage,
                onChanged: (val) => setState(() => _hasColdStorage = val),
                activeColor: Colors.green,
              ),
              const SizedBox(height: 16),

              // Capacity
              _buildSectionTitle("Daily Capacity (kg)"),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration("e.g., 50"),
                validator: (v) => v?.isEmpty ?? true ? "Capacity required" : null,
              ),
              const SizedBox(height: 24),

              // Description
              _buildSectionTitle("Description (Optional)"),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _buildInputDecoration("Tell us about your charity"),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Register Charity",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
