import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:rentapp/presentation/widgets/dark_mode_switch.dart';
import 'package:rentapp/presentation/widgets/theme_switcher.dart';
import 'package:rentapp/presentation/widgets/language_switcher.dart';
import 'package:rentapp/presentation/pages/onboarding_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _saveRecentSearches = true;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    // Load saved preferences
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationEnabled = prefs.getBool('location_enabled') ?? true;
      _saveRecentSearches = prefs.getBool('save_recent_searches') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('location_enabled', _locationEnabled);
    await prefs.setBool('save_recent_searches', _saveRecentSearches);
  }

  Future<void> _clearAppData() async {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.clearAppData),
        content: Text(localizations.clearAppDataConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              // Don't clear onboarding flag to prevent showing onboarding again
              await prefs.setBool('seen_onboarding', true);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.appDataCleared)),
                );

                // Reload preferences
                _loadPreferences();
              }
            },
            child: Text(localizations.clear),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.logout),
        content: Text(localizations.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('seen_onboarding', false);

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingPage()),
                      (route) => false,
                );
              }
            },
            child: Text(localizations.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteAccount),
        content: Text(localizations.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingPage()),
                        (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${localizations.error}: ${e.toString()}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.background,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onBackground,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSection(
              title: localizations.appearance,
              icon: Icons.palette_outlined,
              children: [
                _buildSettingItem(
                  title: localizations.darkMode,
                  trailing: const DarkModeSwitch(),
                ),
                _buildSettingItem(
                  title: localizations.appTheme,
                  trailing: const ThemeSwitcher(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: localizations.general,
              icon: Icons.settings_outlined,
              children: [
                _buildSettingItem(
                  title: localizations.language,
                  trailing: const LanguageSwitcher(),
                ),
                SwitchListTile(
                  title: Text(localizations.enableNotifications),
                  subtitle: Text(localizations.notificationsDescription),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                      _savePreferences();
                    });
                  },
                ),
                SwitchListTile(
                  title: Text(localizations.enableLocation),
                  subtitle: Text(localizations.locationDescription),
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                      _savePreferences();
                    });
                  },
                ),
                SwitchListTile(
                  title: Text(localizations.saveRecentSearches),
                  subtitle: Text(localizations.recentSearchesDescription),
                  value: _saveRecentSearches,
                  onChanged: (value) {
                    setState(() {
                      _saveRecentSearches = value;
                      _savePreferences();
                    });
                  },
                ),
                ListTile(
                  title: Text(localizations.clearAppData),
                  subtitle: Text(localizations.clearAppDataDescription),
                  trailing: const Icon(Icons.cleaning_services_outlined),
                  onTap: _clearAppData,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: localizations.account,
              icon: Icons.person_outline,
              children: [
                ListTile(
                  title: Text(
                    FirebaseAuth.instance.currentUser?.email ?? localizations.notSignedIn,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(localizations.emailAddress),
                ),
                ListTile(
                  title: Text(localizations.logout),
                  leading: const Icon(Icons.logout),
                  onTap: () => _logout(context),
                ),
                ListTile(
                  title: Text(localizations.deleteAccount),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  textColor: Colors.red,
                  onTap: _deleteAccount,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: localizations.about,
              icon: Icons.info_outline,
              children: [
                ListTile(
                  title: Text(localizations.appVersion),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  title: Text(localizations.termsOfService),
                  onTap: () {
                    // Navigate to Terms of Service page
                  },
                ),
                ListTile(
                  title: Text(localizations.privacyPolicy),
                  onTap: () {
                    // Navigate to Privacy Policy page
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required Widget trailing,
    String? subtitle,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
    );
  }
}