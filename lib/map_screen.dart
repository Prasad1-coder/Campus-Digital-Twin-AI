import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  final LatLng collegeLocation = const LatLng(
    19.1383,
    77.3210,
  );

  final Set<Marker> markers = {
    const Marker(
      markerId: MarkerId("college"),
      position: LatLng(19.1383, 77.3210),
      infoWindow: InfoWindow(
        title: "My College",
        snippet: "Campus Digital Twin AI",
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Map"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: collegeLocation,
          zoom: 17,
        ),
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
      ),
    );
  }
}