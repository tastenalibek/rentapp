import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorite_event.dart';
import 'favorite_state.dart';
import '../../../data/models/car.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  FavoriteBloc() : super(FavoritesLoading()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddFavorite>(_onAddFavorite);
    on<RemoveFavorite>(_onRemoveFavorite);
  }

  Future<void> _onLoadFavorites(LoadFavorites event, Emitter<FavoriteState> emit) async {
    emit(FavoritesLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final favJsonList = prefs.getStringList('favorites') ?? [];
      final favorites = favJsonList.map((jsonStr) {
        final map = json.decode(jsonStr);
        return Car.fromMap(map).copyWith(isFavorite: true);
      }).toList();
      emit(FavoritesLoaded(List.unmodifiable(favorites)));
    } catch (e) {
      emit(FavoritesError(message: e.toString()));
    }
  }

  Future<void> _saveFavorites(List<Car> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final favJsonList = favorites.map((car) => json.encode(car.toMap())).toList();
    await prefs.setStringList('favorites', favJsonList);
  }

  Future<void> _onAddFavorite(AddFavorite event, Emitter<FavoriteState> emit) async {
    if (state is FavoritesLoaded) {
      final currentFavorites = List<Car>.from((state as FavoritesLoaded).favorites);
      if (!currentFavorites.any((car) => car.model == event.car.model)) {
        currentFavorites.add(event.car.copyWith(isFavorite: true));
        await _saveFavorites(currentFavorites);
        emit(FavoritesLoaded(List.unmodifiable(currentFavorites)));
      }
    }
  }

  Future<void> _onRemoveFavorite(RemoveFavorite event, Emitter<FavoriteState> emit) async {
    if (state is FavoritesLoaded) {
      final currentFavorites = List<Car>.from((state as FavoritesLoaded).favorites)
        ..removeWhere((car) => car.model == event.car.model);
      await _saveFavorites(currentFavorites);
      emit(FavoritesLoaded(List.unmodifiable(currentFavorites)));
    }
  }
}
