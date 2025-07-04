import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/domain/usecases/get_cars.dart';
import 'package:rentapp/presentation/bloc/car_event.dart';
import 'package:rentapp/presentation/bloc/car_state.dart';
import 'package:rentapp/data/models/car.dart';

class CarBloc extends Bloc<CarEvent, CarState> {
  final GetCars getCars;

  CarBloc({required this.getCars}) : super(CarsLoading()) {
    // Загрузка машин
    on<LoadCars>((event, emit) async {
      emit(CarsLoading());
      try {
        final cars = await getCars.call();
        emit(CarsLoaded(cars));
      } catch (e) {
        emit(CarsError(e.toString()));
      }
    });

    // Переключение избранного
    on<ToggleFavoriteCar>((event, emit) {
      if (state is CarsLoaded) {
        final currentState = state as CarsLoaded;
        final updatedCars = currentState.cars.map((car) {
          if (car.model == event.carModel) {
            return car.copyWith(isFavorite: !car.isFavorite);
          }
          return car;
        }).toList();
        emit(CarsLoaded(updatedCars));
      }
    });
  }
}
