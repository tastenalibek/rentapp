//marker_clusterer.dart

import 'dart:core';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerClusterer {
  // Distance threshold for clustering in meters
  final double clusterRadius;

  MarkerClusterer({this.clusterRadius = 150});

  // Group markers by proximity
  Set<Marker> clusterMarkers(List<Marker> markers) {
    if (markers.isEmpty) return {};

    // Copy to avoid modifying original list
    List<Marker> markersCopy = List.from(markers);
    Set<Marker> resultMarkers = {};

    while (markersCopy.isNotEmpty) {
      Marker baseMarker = markersCopy.removeAt(0);
      List<Marker> clusterGroup = [baseMarker];

      // Find nearby markers
      markersCopy.removeWhere((marker) {
        bool isNearby = _isMarkerNearby(
            baseMarker.position,
            marker.position,
            clusterRadius
        );

        if (isNearby) {
          clusterGroup.add(marker);
        }

        return isNearby;
      });

      // If we have multiple markers in the group, create a cluster
      if (clusterGroup.length > 1) {
        resultMarkers.add(_createClusterMarker(clusterGroup));
      } else {
        // Just add the single marker
        resultMarkers.add(baseMarker);
      }
    }

    return resultMarkers;
  }

  // Check if two markers are within clustering distance
  bool _isMarkerNearby(LatLng position1, LatLng position2, double radius) {
    const double metersPerDegree = 111319.9; // Approximate meters per degree at equator

    double deltaLat = (position1.latitude - position2.latitude).abs();
    double deltaLng = (position1.longitude - position2.longitude).abs();

    double latDistance = deltaLat * metersPerDegree;
    double lngDistance = deltaLng * metersPerDegree *
        math.cos((position1.latitude + position2.latitude) * 0.5 * math.pi / 180.0);

    double distance = math.sqrt(latDistance * latDistance + lngDistance * lngDistance);

    return distance <= radius;
  }

  // Calculate average position for a group of markers
  LatLng _calculateClusterCenter(List<Marker> markers) {
    double latSum = 0;
    double lngSum = 0;

    for (Marker marker in markers) {
      latSum += marker.position.latitude;
      lngSum += marker.position.longitude;
    }

    return LatLng(
      latSum / markers.length,
      lngSum / markers.length,
    );
  }

  // Create a marker representing a cluster
  Marker _createClusterMarker(List<Marker> markers) {
    LatLng center = _calculateClusterCenter(markers);
    String markerId = 'cluster_${center.latitude}_${center.longitude}';

    List<String> titles = [];
    for (Marker marker in markers) {
      if (marker.infoWindow.title != null) {
        titles.add(marker.infoWindow.title!);
      }
    }

    return Marker(
      markerId: MarkerId(markerId),
      position: center,
      infoWindow: InfoWindow(
        title: '${markers.length} cars available',
        snippet: titles.take(3).join(', ') + (titles.length > 3 ? '...' : ''),
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      onTap: () {
        // Handle cluster tap if needed
      },
    );
  }
}
