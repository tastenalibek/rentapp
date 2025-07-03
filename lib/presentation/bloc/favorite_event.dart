import '../../../data/models/car.dart';

abstract class FavoriteEvent {}

class LoadFavorites extends FavoriteEvent {}

class AddFavorite extends FavoriteEvent {
  final Car car;

  AddFavorite(this.car);
}

class RemoveFavorite extends FavoriteEvent {
  final Car car;

  RemoveFavorite(this.car);
}
