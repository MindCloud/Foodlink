import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class LogSurplusFoodPage extends StatefulWidget {
  const LogSurplusFoodPage({super.key});

  @override
  State<LogSurplusFoodPage> createState() => _LogSurplusFoodPageState();
}

class _LogSurplusFoodPageState extends State<LogSurplusFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final foodTypeController = TextEditingController();
  final quantityController = TextEditingController();
  final notesController = TextEditingController();

  Position? _currentPosition;
  String _locationStatus = "Tap to capture current location";

  TimeOfDay? _pickupFrom;
  TimeOfDay? _pickupTo;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  final List<String> commonFoodTypes = [
    'Cooked Rice & Curry',
    'Vegetable Biryani',
    'String Hoppers & Kiri Hodi',
    'Bread & Pastries',
    'Fresh Fruits',
    'Cooked Meals',
    'Packaged Snacks',
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
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please capture GPS location")));
      return;
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

      await FirebaseFirestore.instance.collection('donations').add({
        'donorId': user.uid,
        'donorEmail': user.email,
        'foodType': foodTypeController.text.trim(),
        'quantity': '${quantityController.text.trim()} kg',
        'notes': notesController.text.trim(),
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'pickupFrom': _pickupFrom!.format(context),
        'pickupTo': _pickupTo!.format(context),
        'imageUrl': imageUrl ?? '',
        'status': 'Logged',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Surplus food logged successfully!"), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true); // Return success flag to refresh dashboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
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

              const Text("GPS Location (Required for matching)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green, size: 40),
                  title: Text(_locationStatus),
                  trailing: ElevatedButton(onPressed: _getCurrentLocation, child: const Text("Capture")),
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