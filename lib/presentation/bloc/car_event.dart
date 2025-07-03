//car_event.dart

abstract class CarEvent {}

class LoadCars extends CarEvent {}

class ToggleFavoriteCar extends CarEvent {
  final String carModel;

  ToggleFavoriteCar(this.carModel);
}


