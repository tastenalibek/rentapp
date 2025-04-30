//MapDetailsPage.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class MapsDetailsPage extends StatefulWidget {
  final Car car;

  const MapsDetailsPage({Key? key, required this.car}) : super(key: key);

  @override
  State<MapsDetailsPage> createState() => _MapsDetailsPageState();
}

class _MapsDetailsPageState extends State<MapsDetailsPage> {
  final Completer<GoogleMapController> _controller = Completer();

  // Astana coordinates (default)
  static const LatLng _astanaLocation = LatLng(51.1694, 71.4491);

  // Initial camera position
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: _astanaLocation,
    zoom: 14.0,
  );

  // Set of markers
  Set<Marker> _markers = {};

  // User's current position
  Position? _currentPosition;

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndGetLocation();
    _addCarMarkers();
  }

  // Add predefined car locations as markers
  void _addCarMarkers() {
    // Adding car markers - simulating car locations around Astana
    _markers.add(
      Marker(
        markerId: MarkerId(widget.car.model),
        position: LatLng(51.1694, 71.4491), // Main Astana location
        infoWindow: InfoWindow(
          title: widget.car.model,
          snippet: '₸${widget.car.pricePerHour}/hour',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    // Add more simulated car locations
    _markers.add(
      Marker(
        markerId: MarkerId('${widget.car.model}-1'),
        position: LatLng(51.1794, 71.4591), // Slightly offset
        infoWindow: InfoWindow(
          title: '${widget.car.model}-1',
          snippet: '₸${widget.car.pricePerHour + 10}/hour',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    _markers.add(
      Marker(
        markerId: MarkerId('${widget.car.model}-2'),
        position: LatLng(51.1594, 71.4391), // Another offset
        infoWindow: InfoWindow(
          title: '${widget.car.model}-2',
          snippet: '₸${widget.car.pricePerHour + 20}/hour',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
  }

  // Request location permission and get user's location
  Future<void> _requestPermissionAndGetLocation() async {
    try {
      // Request location permission
      var status = await Permission.location.request();

      if (status.isGranted) {
        setState(() {
          _isLoading = true;
        });

        // Check if location service is enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
          return;
        }

        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
          _isLoading = false;

          // Add current location marker
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(
                title: 'Your Location',
                snippet: 'You are here',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            ),
          );

          // Update camera position to user's location
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.0,
          );
        });

        // Update camera position
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        );

        // Get address from coordinates (reverse geocoding)
        _getAddressFromLatLng(position);
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  // Get address from latitude and longitude
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}, ${place.country}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your location: $address')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting address: $e')),
      );
    }
  }

  // Move camera to user's location
  Future<void> _goToCurrentLocation() async {
    if (_currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16.0,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map - ${widget.car.model}'),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomControlsEnabled: false,
            onTap: (LatLng position) {
              // You can add functionality here when map is tapped
            },
          ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Zoom and location controls
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  child: const Icon(Icons.add),
                  onPressed: () async {
                    final GoogleMapController controller = await _controller.future;
                    controller.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const SizedBox(height: 8.0),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () async {
                    final GoogleMapController controller = await _controller.future;
                    controller.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
                const SizedBox(height: 8.0),
                FloatingActionButton(
                  heroTag: 'location',
                  child: const Icon(Icons.my_location),
                  onPressed: _goToCurrentLocation,
                ),
              ],
            ),
          ),

          // Car information card
          Positioned(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, size: 36.0, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.car.model,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          Text(
                            '₸${widget.car.pricePerHour}/hour • ${widget.car.distance}km away',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Handle rent action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Renting ${widget.car.model}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text('Rent'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}