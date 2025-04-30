//map_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/Service/location_service.dart';

// Events
abstract class MapEvent {}

class LoadMapData extends MapEvent {
  final List<Car> cars;
  LoadMapData(this.cars);
}

class UpdateUserLocation extends MapEvent {}

class SelectCar extends MapEvent {
  final Car car;
  SelectCar(this.car);
}

// States
abstract class MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final Set<Marker> markers;
  final LatLng userLocation;
  final LatLng cameraPosition;
  final Car? selectedCar;

  MapLoaded({
    required this.markers,
    required this.userLocation,
    required this.cameraPosition,
    this.selectedCar,
  });

  MapLoaded copyWith({
    Set<Marker>? markers,
    LatLng? userLocation,
    LatLng? cameraPosition,
    Car? selectedCar,
  }) {
    return MapLoaded(
      markers: markers ?? this.markers,
      userLocation: userLocation ?? this.userLocation,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      selectedCar: selectedCar ?? this.selectedCar,
    );
  }
}

class MapError extends MapState {
  final String message;
  MapError(this.message);
}

// BLoC
class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationService locationService;

  // Astana coordinates as default
  static const LatLng defaultLocation = LatLng(51.1694, 71.4491);

  MapBloc({required this.locationService}) : super(MapLoading()) {
    on<LoadMapData>(_onLoadMapData);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<SelectCar>(_onSelectCar);
  }

  Future<void> _onLoadMapData(LoadMapData event, Emitter<MapState> emit) async {
    emit(MapLoading());

    try {
      // Get user's location
      Position? position = await locationService.getCurrentPosition();
      LatLng userLocation = position != null
          ? LatLng(position.latitude, position.longitude)
          : defaultLocation;

      // Create markers from cars
      Set<Marker> markers = _createCarMarkers(event.cars);

      // Add user location marker
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLocation,
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );

      emit(MapLoaded(
        markers: markers,
        userLocation: userLocation,
        cameraPosition: userLocation,
        selectedCar: null,
      ));
    } catch (e) {
      emit(MapError('Failed to load map data: $e'));
    }
  }

  Future<void> _onUpdateUserLocation(UpdateUserLocation event, Emitter<MapState> emit) async {
    try {
      if (state is MapLoaded) {
        final currentState = state as MapLoaded;

        // Get updated user location
        Position? position = await locationService.getCurrentPosition();
        if (position == null) return;

        LatLng userLocation = LatLng(position.latitude, position.longitude);

        // Update user location marker
        Set<Marker> updatedMarkers = Set.from(currentState.markers);
        updatedMarkers.removeWhere((marker) => marker.markerId.value == 'user_location');
        updatedMarkers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: userLocation,
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'You are here',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          ),
        );

        emit(currentState.copyWith(
          markers: updatedMarkers,
          userLocation: userLocation,
        ));
      }
    } catch (e) {
      emit(MapError('Failed to update location: $e'));
    }
  }

  void _onSelectCar(SelectCar event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;

      // Get car coordinates or use default if not available
      LatLng carPosition = LatLng(
        event.car.latitude ?? defaultLocation.latitude,
        event.car.longitude ?? defaultLocation.longitude,
      );

      emit(currentState.copyWith(
        selectedCar: event.car,
        cameraPosition: carPosition,
      ));
    }
  }

  Set<Marker> _createCarMarkers(List<Car> cars) {
    Set<Marker> markers = {};

    for (Car car in cars) {
      // Skip cars without location data
      if (car.latitude == null || car.longitude == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(car.model),
          position: LatLng(car.latitude!, car.longitude!),
          infoWindow: InfoWindow(
            title: car.model,
            snippet: '₸${car.pricePerHour}/hour',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    return markers;
  }
}