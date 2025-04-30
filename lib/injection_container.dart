//injection_container.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:rentapp/data/datasources/firebase_car_data_source.dart';
import 'package:rentapp/data/repositories/car_repository_impl.dart';
import 'package:rentapp/domain/repositories/car_repository.dart';
import 'package:rentapp/domain/usecases/get_cars.dart';
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/Service/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

GetIt getIt = GetIt.instance;

void initInjection(){
  try{
    // Firebase and repository dependencies
    getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
    getIt.registerLazySingleton<FirebaseCarDataSource>(
            () => FirebaseCarDataSource(firestore: getIt<FirebaseFirestore>())
    );
    getIt.registerLazySingleton<CarRepository>(
            () => CarRepositoryImpl(getIt<FirebaseCarDataSource>())
    );
    getIt.registerLazySingleton<GetCars>(
            () => GetCars(getIt<CarRepository>())
    );
    getIt.registerFactory(() => CarBloc(getCars: getIt<GetCars>()));

    // Location service
    getIt.registerLazySingleton<LocationService>(() => LocationService());

  } catch (e){
    throw e;
  }
}