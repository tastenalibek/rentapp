import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/presentation/bloc/car_state.dart';
import 'package:rentapp/presentation/widgets/car_card.dart';
import 'package:rentapp/presentation/pages/onboarding_page.dart';
import 'package:rentapp/presentation/pages/favorites_page.dart';
import 'package:rentapp/presentation/pages/profile_page.dart';
import 'package:rentapp/presentation/pages/settings_page.dart';
import 'package:rentapp/presentation/pages/home_page.dart';

class CarListScreen extends StatefulWidget {
  const CarListScreen({super.key});

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _animations = [];
  String _searchQuery = '';
  String _sortBy = 'Model';
  int _currentIndex = 2;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
          (route) => false,
    );
  }

  void _prepareAnimations(int count) {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    _animations.clear();

    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      final animation = Tween<Offset>(
        begin: const Offset(1.0, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

      _controllers.add(controller);
      _animations.add(animation);

      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Car> _filterAndSort(List<Car> cars) {
    final filtered = cars
        .where((car) => car.model.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (_sortBy == 'Price') {
      filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    } else {
      filtered.sort((a, b) => a.model.compareTo(b.model));
    }

    return filtered;
  }

  Widget _buildCarListContent() {
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
          final cars = _filterAndSort(state.cars);
          _prepareAnimations(cars.length);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: localizations.searchByModel,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Row(
                  children: [
                    Text('${localizations.sortBy}: '),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _sortBy,
                      items: [
                        DropdownMenuItem(value: 'Model', child: Text(localizations.model)),
                        DropdownMenuItem(value: 'Price', child: Text(localizations.price)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    return SlideTransition(
                      position: _animations[index],
                      child: CarCard(car: cars[index]),
                    );
                  },
                ),
              ),
            ],
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

  Widget _getPageContent(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const FavoritesPage();
      case 2:
        return _buildCarListContent(); // dynamic content
      case 3:
        return const SettingsPage();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.background,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onBackground,
      ),
      body: _getPageContent(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: theme.cardColor,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: localizations.home),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: localizations.favorites),
          BottomNavigationBarItem(icon: const Icon(Icons.directions_car), label: localizations.cars),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: localizations.settings),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: localizations.profile),
        ],
      ),
    );
  }
}