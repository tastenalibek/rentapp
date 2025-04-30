//car.dart

class Car {
  final String model;
  final int distance;
  final int fuelCapacity;
  final int pricePerHour;
  final double? latitude;
  final double? longitude;

  Car({
    required this.model,
    required this.distance,
    required this.fuelCapacity,
    required this.pricePerHour,
    this.latitude,
    this.longitude,
  });

  // Create from Firestore
  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      model: map['model'] ?? '',
      distance: map['distance'] ?? 0,
      fuelCapacity: map['fuelCapacity'] ?? 0,
      pricePerHour: map['pricePerHour'] ?? 0,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'distance': distance,
      'fuelCapacity': fuelCapacity,
      'pricePerHour': pricePerHour,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create a copy with potentially different values
  Car copyWith({
    String? model,
    int? distance,
    int? fuelCapacity,
    int? pricePerHour,
    double? latitude,
    double? longitude,
  }) {
    return Car(
      model: model ?? this.model,
      distance: distance ?? this.distance,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}