// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'injection_container.dart';
import 'presentation/pages/car_list_screen.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_screen.dart';
import 'presentation/pages/onboarding_page.dart';
import 'presentation/pages/not_found_page.dart';
import 'presentation/bloc/car_bloc.dart';
import 'presentation/bloc/car_event.dart';
import 'presentation/bloc/favorite_bloc.dart';
import 'presentation/bloc/favorite_event.dart';
import 'presentation/widgets/language_switcher.dart';
import 'theme/theme_notifier.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final GlobalKey<_RentAppState> rentAppKey = GlobalKey<_RentAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initInjection();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: RentApp(key: rentAppKey),
    ),
  );
}

class RentApp extends StatefulWidget {
  const RentApp({super.key});

  @override
  State<RentApp> createState() => _RentAppState();
}

class _RentAppState extends State<RentApp> {
  Widget? _startScreen;
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    setState(() {
      if (!seenOnboarding) {
        _startScreen = const OnboardingPage();
      } else if (isLoggedIn) {
        _startScreen = const CarListScreen();
      } else {
        _startScreen = const LoginScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeNotifier>(context).theme;

    return MultiBlocProvider(
      providers: [
        BlocProvider<CarBloc>(
          create: (_) => getIt<CarBloc>()..add(LoadCars()),
        ),
        BlocProvider<FavoriteBloc>(
          create: (_) => FavoriteBloc()..add(LoadFavorites()),
        ),
      ],
      child: MaterialApp(
        title: 'RentApp',
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: _locale,
        home: _startScreen ?? const Scaffold(body: Center(child: CircularProgressIndicator())),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
        ),
      ),
    );
  }
}