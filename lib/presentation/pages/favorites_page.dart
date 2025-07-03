import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/presentation/bloc/car_state.dart';
import 'package:rentapp/presentation/bloc/car_event.dart';
import 'package:rentapp/presentation/widgets/car_card.dart';
import 'package:lottie/lottie.dart';
import 'package:rentapp/data/models/car.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _removeFavorite(BuildContext context, Car car) {
    final localizations = AppLocalizations.of(context)!;
    context.read<CarBloc>().add(ToggleFavoriteCar(car.model));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.removedFromFavorites(car.model)),
        action: SnackBarAction(
          label: localizations.undo,
          onPressed: () {
            context.read<CarBloc>().add(ToggleFavoriteCar(car.model));
          },
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSwipeableFavoriteItem(BuildContext context, Car car) {
    final localizations = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key(car.model),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _removeFavorite(context, car);
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(height: 5),
            Text(
              localizations.remove,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: CarCard(car: car),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<CarBloc, CarState>(
      builder: (context, state) {
        if (state is CarsLoading) {
          return Center(
            child: Lottie.asset(
              'assets/Animation - 1747215575376.json',
              width: 200,
              height: 200,
            ),
          );
        } else if (state is CarsLoaded) {
          // Get only favorite cars from the state
          final favoriteCars = state.favoriteCars;

          if (favoriteCars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noFavoriteCars,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.markCarsAsFavorite,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favoriteCars.length,
            itemBuilder: (context, index) {
              return _buildSwipeableFavoriteItem(context, favoriteCars[index]);
            },
          );
        } else if (state is CarsError) {
          return Center(
            child: Text('${localizations.error}: ${state.message}',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}