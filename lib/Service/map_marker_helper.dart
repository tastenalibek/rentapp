//map_marker_helper.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerHelper {
  // Cache for marker icons
  static Map<String, BitmapDescriptor> _markerIconCache = {};

  // Get marker icon from asset
  static Future<BitmapDescriptor> getMarkerIconFromAsset(String assetPath, {int width = 80, int height = 80}) async {
    // Check if icon is already cached
    if (_markerIconCache.containsKey(assetPath)) {
      return _markerIconCache[assetPath]!;
    }

    // Load image from asset
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    // Create bitmap descriptor from bytes
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: width,
      targetHeight: height,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    final BitmapDescriptor markerIcon = BitmapDescriptor.fromBytes(resizedBytes);

    // Cache the icon
    _markerIconCache[assetPath] = markerIcon;

    return markerIcon;
  }

  // Create custom marker widget
  static Future<BitmapDescriptor> getCustomMarker({
    required String label,
    required Color backgroundColor,
    Color textColor = Colors.white,
    double fontSize = 14.0,
    double size = 150,
    IconData icon = Icons.directions_car,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = backgroundColor;
    final double radius = size / 2;

    // Draw circle background
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Draw icon
    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: textColor,
        fontSize: size * 0.5,
        fontFamily: icon.fontFamily,
        height: 1,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        radius - iconPainter.width / 2,
        radius - iconPainter.height / 2 - 10,
      ),
    );

    // Draw text
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius + iconPainter.height / 2 - 15,
      ),
    );

    // Convert canvas to image
    final img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}