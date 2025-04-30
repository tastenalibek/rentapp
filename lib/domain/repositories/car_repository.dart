//car_repository.dart

import 'package:rentapp/data/models/car.dart';

abstract class CarRepository {
  Future<List<Car>> fetchCars();
}