import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  /// Current live location marker
  Set<Marker> _markers = {};
  
  /// Default / initial camera position.
  /// Will be updated once we get the first GPS position.
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(24.8607, 67.0011),
    zoom: 14,
  );

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// Initialize location tracking
  Future<void> _initializeLocation() async {
    // 1. Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Location services are disabled. Please enable them.';
        _isLoading = false;
      });
      return;
    }

    // 2. Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Location permission denied.';
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Location permissions are permanently denied. Please enable them in settings.';
        _isLoading = false;
      });
      return;
    }

    // 3. Get initial position
    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(initialPosition.latitude, initialPosition.longitude),
          zoom: 16,
        );
        _updateMarker(initialPosition);
        _isLoading = false;
      });

      // Move camera to initial position if controller is ready
      _controller?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(initialPosition.latitude, initialPosition.longitude),
        ),
      );

      // 4. Start live location stream
      _startLocationStream();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  /// Start listening to live location updates
  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 4, // Update every 4 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _updateMarker(position);
        // Optionally auto-center camera on location updates
        // Uncomment if you want camera to follow automatically
        // _controller?.animateCamera(
        //   CameraUpdate.newLatLng(
        //     LatLng(position.latitude, position.longitude),
        //   ),
        // );
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  /// Update marker with new position
  void _updateMarker(Position position) {
    setState(() {
      // Remove old marker and add new one
      _markers = {
        Marker(
          markerId: const MarkerId('live_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  /// Recenter camera to current location
  void _recenterCamera() {
    if (_markers.isNotEmpty) {
      final marker = _markers.first;
      _controller?.animateCamera(
        CameraUpdate.newLatLng(marker.position),
      );
    }
  }

  @override
  void dispose() {
    // Cancel location stream subscription
    _positionStreamSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeLocation();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          onMapCreated: (c) => _controller = c,
          markers: _markers,
          zoomControlsEnabled: true,
          compassEnabled: false,
          mapToolbarEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          trafficEnabled: false,
          buildingsEnabled: false,
          indoorViewEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
        // Recenter button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _recenterCamera,
            tooltip: 'Recenter to current location',
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
