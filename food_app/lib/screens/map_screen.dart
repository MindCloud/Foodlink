// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/haversine.dart';

class MapScreen extends StatefulWidget {
  final double donorLat;
  final double donorLon;
  final double charityLat;
  final double charityLon;
  final String donorName;
  final String charityName;
  final String foodType;

  const MapScreen({
    super.key,
    required this.donorLat,
    required this.donorLon,
    required this.charityLat,
    required this.charityLon,
    required this.donorName,
    required this.charityName,
    required this.foodType,
    this.isRider = false,
  });

  final bool isRider;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;

  @override
  Widget build(BuildContext context) {
    final LatLng donorPos = LatLng(widget.donorLat, widget.donorLon);
    final LatLng charityPos = LatLng(widget.charityLat, widget.charityLon);

    final double distanceKm = Haversine.calculateDistance(
      lat1: widget.charityLat,
      lon1: widget.charityLon,
      lat2: widget.donorLat,
      lon2: widget.donorLon,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Route Map"),
        backgroundColor: Colors.green,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: donorPos,
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: {
          Marker(
            markerId: const MarkerId("donor"),
            position: donorPos,
            infoWindow: InfoWindow(title: "Pickup", snippet: widget.donorName),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
          Marker(
            markerId: const MarkerId("charity"),
            position: charityPos,
            infoWindow: InfoWindow(title: "Drop-off", snippet: widget.charityName),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId("route"),
            points: [donorPos, charityPos],
            color: Colors.blue,
            width: 5,
          ),
        },
        onMapCreated: (controller) {
          mapController = controller;
          // Zoom to fit both points
          controller.animateCamera(CameraUpdate.newLatLngBounds(
            LatLngBounds(southwest: donorPos, northeast: charityPos),
            80,
          ));
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.foodType,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("From: ${widget.donorName}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${distanceKm.toStringAsFixed(1)} km",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const Text(
                        "Distance",
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (widget.isRider) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Estimated Fare",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        "LKR ${(distanceKm * 100).toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = 'https://www.google.com/maps/dir/?api=1&origin=${widget.donorLat},${widget.donorLon}&destination=${widget.charityLat},${widget.charityLon}&travelmode=driving';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Could not launch Google Maps")),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text("Start Navigation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              Row(
                children: [
                   const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "8–12 km – Eligible for Free Pickup",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              "Straight-line distance calculated via Haversine Formula",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}