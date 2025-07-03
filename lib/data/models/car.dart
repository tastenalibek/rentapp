// ✅ Updated car.dart with full theme-aware UI support via context
class Car {
  final String model;
  final int distance;
  final int fuelCapacity;
  final int pricePerHour;
  final double? latitude;
  final double? longitude;
  final String image;
  bool isFavorite;

  Car({
    required this.model,
    required this.distance,
    required this.fuelCapacity,
    required this.pricePerHour,
    this.latitude,
    this.longitude,
    required this.image,
    this.isFavorite = false,
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
      image: map['image'] ?? 'assets/default_car.png',
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
      'image': image,
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
    String? image,
    bool? isFavorite,
  }) {
    return Car(
      model: model ?? this.model,
      distance: distance ?? this.distance,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      image: image ?? this.image,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
