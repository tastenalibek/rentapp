import 'package:rentapp/data/models/car.dart';

abstract class CarState {}

class CarsLoading extends CarState {}

class CarsLoaded extends CarState {
  final List<Car> cars;
  final List<Car> favoriteCars;

  CarsLoaded(this.cars) : favoriteCars = cars.where((car) => car.isFavorite).toList();

  // Helper method to create a new state with updated cars
  CarsLoaded copyWith({List<Car>? cars}) {
    return CarsLoaded(cars ?? this.cars);
  }
}

class CarsError extends CarState {
  final String message;

  CarsError(this.message);
}