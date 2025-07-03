import '../../../data/models/car.dart';

abstract class FavoriteState {}

class FavoritesLoading extends FavoriteState {}

class FavoritesLoaded extends FavoriteState {
  final List<Car> favorites;

  FavoritesLoaded(this.favorites);
}

class FavoritesError extends FavoriteState {
  final String message;
  FavoritesError({required this.message});
}
