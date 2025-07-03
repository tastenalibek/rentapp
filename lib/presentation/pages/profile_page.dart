import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentapp/services/auth_service.dart';
import 'package:rentapp/presentation/pages/login_screen.dart';
import 'package:rentapp/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  User? _currentUser;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploading = false;
  File? _selectedImage;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    _fetchUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = FirebaseAuth.instance.currentUser;

      if (_currentUser != null) {
        // Get additional user data from Firestore if it exists
        final docSnapshot = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (docSnapshot.exists) {
          setState(() {
            _userData = docSnapshot.data() ?? {};
            _nameController.text = _userData['displayName'] ?? _currentUser!.displayName ?? '';
            _phoneController.text = _userData['phone'] ?? '';
            _addressController.text = _userData['address'] ?? '';
          });
        } else {
          // If no data in Firestore yet, use data from Auth if available
          _nameController.text = _currentUser!.displayName ?? '';

          // Create initial user document in Firestore
          await _firestore.collection('users').doc(_currentUser!.uid).set({
            'displayName': _currentUser!.displayName ?? '',
            'email': _currentUser!.email ?? '',
            'photoURL': _currentUser!.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Fetch the newly created document
          final newDocSnapshot = await _firestore
              .collection('users')
              .doc(_currentUser!.uid)
              .get();

          setState(() {
            _userData = newDocSnapshot.data() ?? {};
          });
        }
      }
    } catch (e) {
      _showErrorDialog(AppLocalizations.of(context)!.errorLoadingProfile(e.toString()));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show image source selection dialog
      final localizations = AppLocalizations.of(context)!;
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
          title: Text(localizations.selectImageSource),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: Text(localizations.camera),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Text(localizations.gallery),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (source == null) return;

      // Use try-catch with PlatformException handling
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } on PlatformException catch (e) {
      final localizations = AppLocalizations.of(context)!;
      if (e.code == 'channel-error' || e.message?.contains('Unable to establish connection') == true) {
        _showErrorDialog(localizations.imagePickerPermissionError);
      } else {
        _showErrorDialog(localizations.errorSelectingImage(e.message ?? ''));
      }
    } catch (e) {
      _showErrorDialog(AppLocalizations.of(context)!.errorSelectingImage(e.toString()));
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      // Create a unique filename
      final String fileName = '${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_selectedImage!.path)}';
      final Reference storageRef = _storage.ref().child('profile_images/$fileName');

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);

      // Wait for the upload to complete and get the download URL
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorDialog(AppLocalizations.of(context)!.errorUploadingImage(e.toString()));
      return null;
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Upload image if a new one was selected
      String? photoURL;
      if (_selectedImage != null) {
        photoURL = await _uploadImage();
      }

      // Update Firestore data
      final updatedData = {
        'displayName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add photoURL to updatedData only if a new image was uploaded
      if (photoURL != null) {
        updatedData['photoURL'] = photoURL;

        // Also update photoURL in Firebase Auth
        await _currentUser!.updatePhotoURL(photoURL);
      }

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updatedData);

      // Also update displayName in Firebase Auth
      await _currentUser!.updateDisplayName(_nameController.text.trim());

      // Refresh user data
      await _fetchUserData();

      setState(() {
        _isEditing = false;
        _selectedImage = null;
      });

      _showSuccessMessage(AppLocalizations.of(context)!.profileUpdatedSuccess);
    } catch (e) {
      _showErrorDialog(AppLocalizations.of(context)!.errorUpdatingProfile(e.toString()));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();

      // Reset onboarding flag as in your CarListScreen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_onboarding', false);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const OnboardingPage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      _showErrorDialog(AppLocalizations.of(context)!.errorSigningOut(e.toString()));
    }
  }

  void _showErrorDialog(String message) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.ok),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green.shade700
            : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.deepPurple.shade300 : Colors.deepPurple;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDarkMode ? const Color(0xFF242424) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;

    return Theme(
        data: Theme.of(context).copyWith(
          // Set dialog background color based on dark/light mode
          dialogBackgroundColor: isDarkMode ? const Color(0xFF303030) : Colors.white,
          // Customize dialog text color
          dialogTheme: DialogTheme(
            titleTextStyle: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            contentTextStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              localizations.profile,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (!_isEditing)
                IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: Icon(Icons.edit, color: primaryColor),
                  tooltip: localizations.editProfile,
                )
              else
                IconButton(
                  onPressed: () => setState(() {
                    _isEditing = false;
                    _selectedImage = null;

                    // Reset controllers to original values
                    _nameController.text = _userData['displayName'] ?? _currentUser?.displayName ?? '';
                    _phoneController.text = _userData['phone'] ?? '';
                    _addressController.text = _userData['address'] ?? '';
                  }),
                  icon: Icon(Icons.close, color: primaryColor),
                  tooltip: localizations.cancelEditing,
                ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : Stack(
            children: [
              // Background decoration elements - adjusted for dark mode
              Positioned(
                bottom: -100,
                right: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.deepPurple.withOpacity(0.2)
                        : const Color(0x307C4DFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.deepPurple.shade200.withOpacity(0.2)
                        : const Color(0x30BB86FC),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Main content
              FadeTransition(
                opacity: _fadeInAnimation,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Profile Image with upload option
                            Stack(
                              children: [
                                // Profile image
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!) as ImageProvider
                                      : (_userData['photoURL'] != null &&
                                      _userData['photoURL'].toString().isNotEmpty
                                      ? NetworkImage(_userData['photoURL'])
                                      : _currentUser?.photoURL != null &&
                                      _currentUser!.photoURL!.isNotEmpty
                                      ? NetworkImage(_currentUser!.photoURL!)
                                      : null) as ImageProvider?,
                                  child: (_selectedImage == null &&
                                      _userData['photoURL'] == null &&
                                      (_currentUser?.photoURL == null ||
                                          _currentUser!.photoURL!.isEmpty))
                                      ? Icon(Icons.person, size: 60, color: isDarkMode ? Colors.white70 : Colors.black54)
                                      : null,
                                ),
                                // Edit image button (shown only in edit mode)
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _isUploading ? null : _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: backgroundColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: _isUploading
                                            ? SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                            : const Icon(
                                          Icons.camera_alt,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // User email (non-editable)
                            Text(
                              _currentUser?.email ?? localizations.noEmail,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Profile information fields
                            TextFormField(
                              controller: _nameController,
                              enabled: _isEditing,
                              style: TextStyle(color: textColor),
                              decoration: _inputDecoration(localizations.fullName, Icons.person, isDarkMode),
                              validator: (value) =>
                              value == null || value.isEmpty ? localizations.nameRequired : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              enabled: _isEditing,
                              style: TextStyle(color: textColor),
                              decoration: _inputDecoration(localizations.phoneNumber, Icons.phone, isDarkMode),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              enabled: _isEditing,
                              style: TextStyle(color: textColor),
                              decoration: _inputDecoration(localizations.address, Icons.home, isDarkMode),
                              keyboardType: TextInputType.streetAddress,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 32),
                            // Save button (when editing)
                            if (_isEditing)
                              ElevatedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                  if (_formKey.currentState!.validate()) {
                                    _updateProfile();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  disabledBackgroundColor: primaryColor.withOpacity(0.5),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                                    : Text(
                                  localizations.saveProfile,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            // Stats cards
                            if (!_isEditing) ...[
                              Row(
                                children: [
                                  Text(
                                    localizations.accountInformation,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoCards(isDarkMode, cardColor, textColor, subtextColor, primaryColor),
                              const SizedBox(height: 32),
                            ],
                            // Sign out button
                            OutlinedButton.icon(
                              onPressed: _signOut,
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: Text(
                                localizations.signOut,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  Widget _buildInfoCards(bool isDarkMode, Color cardColor, Color textColor, Color subtextColor, Color primaryColor) {
    final localizations = AppLocalizations.of(context)!;
    final accountCreationDate = _userData['createdAt'] != null
        ? (_userData['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final formattedDate = "${accountCreationDate.day}/${accountCreationDate.month}/${accountCreationDate.year}";

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: localizations.memberSince,
                value: formattedDate,
                icon: Icons.calendar_today,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                title: localizations.rentals,
                value: _userData['rentalCount']?.toString() ?? "0",
                icon: Icons.car_rental,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: localizations.status,
                value: localizations.active,
                icon: Icons.verified_user,
                valueColor: isDarkMode ? Colors.green.shade300 : Colors.green,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                title: localizations.reviews,
                value: _userData['reviewCount']?.toString() ?? "0",
                icon: Icons.star,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
    required bool isDarkMode,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: isDarkMode ? 0 : 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? textColor,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDarkMode) {
    final Color borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final Color fillColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final Color iconColor = _isEditing
        ? (isDarkMode ? Colors.deepPurple.shade200 : Colors.deepPurple)
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
      ),
      prefixIcon: Icon(icon, color: iconColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: isDarkMode ? Colors.deepPurple.shade200 : Colors.deepPurple,
            width: 2
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDarkMode ? Colors.red.shade300 : Colors.red, width: 1),
      ),
    );
  }
}