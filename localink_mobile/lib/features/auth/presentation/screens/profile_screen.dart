import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/user_prefs_store.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../../catalog/presentation/providers/currency_provider.dart';
import '../../../profile/widgets/profile_info_tile.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../../core/network/app_error_formatter.dart';

/// Resolves a profile picture to an ImageProvider.
/// Supports: base64 data URIs, relative paths, and full URLs.
ImageProvider? _resolveProfilePicture(String? picture) {
  if (picture == null || picture.isEmpty) return null;
  
  // Handle base64 data URIs
  if (picture.startsWith('data:image')) {
    final base64Data = picture.split(',').last;
    try {
      return MemoryImage(base64Decode(base64Data));
    } catch (_) {
      return null;
    }
  }
  
  // Handle relative paths - resolve using DioClient
  final resolved = DioClient.resolveUrl(picture);
  if (resolved != null) {
    return NetworkImage(resolved);
  }
  
  return NetworkImage(picture);
}

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
class _ProfileTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
  static const Color error = Color(0xFFE1251B);
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditMode = false;
  bool _isSaving = false;
  String? _profilePicBase64;
  String _currency = UserPrefsStore.defaultCurrency;
  List<String> _currencies = List<String>.from(UserPrefsStore.fallbackCurrencies);
  bool _loadingCurrencies = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  Future<bool> _ensureGalleryPermission() async {
    // For Android 13+, use READ_MEDIA_IMAGES
    // For older Android versions, use READ_EXTERNAL_STORAGE
    if (Platform.isAndroid) {
      // Try photos permission first (Android 13+)
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }
      
      // Request photos permission
      photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }
      
      // Fallback to storage permission for older Android versions
      if (photosStatus.isPermanentlyDenied) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
          if (storageStatus.isGranted) {
            return true;
          }
        }
      }
      
      if (!mounted) {
        return false;
      }
      
      AppFeedback.showError(
        context,
        photosStatus.isPermanentlyDenied
            ? 'Gallery access is blocked. Please allow photo access in app settings.'
            : 'Gallery access is required to choose a profile picture.',
      );
      return false;
    } else {
      // iOS permission handling
      var status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }
      
      status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
      
      if (!mounted) {
        return false;
      }
      
      AppFeedback.showError(
        context,
        status.isPermanentlyDenied
            ? 'Gallery access is blocked. Please allow photo access in app settings.'
            : 'Gallery access is required to choose a profile picture.',
      );
      return false;
    }
  }

  Future<void> _pickImage() async {
    try {
      final hasPermission = await _ensureGalleryPermission();
      if (!hasPermission) {
        return;
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profilePicBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
      if (mounted) {
        AppFeedback.showError(context, 'Unable to open gallery. Please try again.');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pincodeCtrl.addListener(_onPincodeChanged);
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await UserPrefsStore.getCurrency();
    var currencies = List<String>.from(UserPrefsStore.fallbackCurrencies);

    try {
      final rates = await ref
          .read(currencyRepositoryProvider)
          .getExchangeRates(currency);
      if (rates.success && rates.data != null && rates.data!.rates.isNotEmpty) {
        currencies = rates.data!.rates.keys.toList()..sort();
        if (!currencies.contains(currency)) {
          currencies.insert(0, currency);
        }
      }
    } catch (_) {
      // Keep offline fallback list when rates API is unavailable.
    }

    if (!mounted) return;
    setState(() {
      _currency = currency;
      _currencies = currencies;
      _loadingCurrencies = false;
    });
  }

  @override
  void dispose() {
    _pincodeCtrl.removeListener(_onPincodeChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    if (!_isEditMode) return;
    final pincode = _pincodeCtrl.text.trim();
    if (pincode.length == 6 && int.tryParse(pincode) != null) {
      _lookupPincode(pincode);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final trimmed = value.trim();
    if (trimmed.length > 256) return 'Email cannot exceed 256 characters';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _lookupPincode(String pincode) async {
    try {
      final repo = ref.read(locationRepositoryProvider);
      final res = await repo.validatePincode(pincode);
      if (res.city != null && res.city!.isNotEmpty) {
        setState(() {
          _cityCtrl.text = res.city!;
          if (res.state != null && res.state!.isNotEmpty) {
            _stateCtrl.text = res.state!;
          }
          if (res.country != null && res.country!.isNotEmpty) {
            _countryCtrl.text = res.country!;
          }
        });
      }
    } catch (e) {
      debugPrint('Pincode lookup error: $e');
    }
  }

  void _populateFields(UserProfileDto profile) {
    _nameCtrl.text = profile.fullName;
    _emailCtrl.text = profile.email;
    _phoneCodeCtrl.text = profile.countryCode.replaceAll('+', '').trim();
    _phoneCtrl.text = profile.phone ?? '';
    _streetCtrl.text = profile.address.street ?? '';
    _cityCtrl.text = profile.address.city ?? '';
    _stateCtrl.text = profile.address.state ?? '';
    _pincodeCtrl.text = profile.address.pincode ?? '';
    _countryCtrl.text = profile.address.country ?? '';
    _profilePicBase64 = profile.profilePicture;
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppFeedback.showError(context, 'Full name is required');
      return;
    }
    if (name.length < 2 || name.length > 100) {
      AppFeedback.showError(context, 'Full name must be between 2 and 100 characters');
      return;
    }
    if (!RegExp(r"^[a-zA-Z\s\-\.']+$").hasMatch(name)) {
      AppFeedback.showError(context, 'Name can only contain letters, spaces, hyphens, dots, and apostrophes');
      return;
    }

    final country = _countryCtrl.text.trim();
    final state = _stateCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final pincode = _pincodeCtrl.text.trim();

    // Validate phone code
    final phoneCode = _phoneCodeCtrl.text.trim();
    if (phoneCode.isEmpty) {
      AppFeedback.showError(context, 'Phone code is required');
      return;
    }
    if (!RegExp(r'^\+?[0-9]{1,4}$').hasMatch(phoneCode)) {
      AppFeedback.showError(context, 'Invalid phone code format (e.g. 91 or +91)');
      return;
    }

    // Validate phone format
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      AppFeedback.showError(context, 'Phone number is required');
      return;
    }
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    final isIndia = phoneCode == '91' || phoneCode == '+91' || country.toLowerCase() == 'india';
    if (isIndia) {
      if (digitsOnly.length != 10) {
        AppFeedback.showError(context, 'Indian phone number must be exactly 10 digits');
        return;
      }
    } else {
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        AppFeedback.showError(context, 'Phone number must be between 7 and 15 digits');
        return;
      }
    }

    // Validate email format
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      AppFeedback.showError(context, 'Email is required');
      return;
    }
    if (email.length > 256) {
      AppFeedback.showError(context, 'Email cannot exceed 256 characters');
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      AppFeedback.showError(
        context,
        'Invalid email address format (e.g. name@domain.com)',
      );
      return;
    }

    if (country.isEmpty || state.isEmpty || city.isEmpty || pincode.isEmpty) {
      AppFeedback.showError(
        context,
        'Country, State, City, and Pincode are all required',
      );
      return;
    }

    // Validate country - should be at least 2 characters
    if (country.length < 2 || country.length > 100) {
      AppFeedback.showError(context, 'Country must be between 2 and 100 characters');
      return;
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s\-\.']+$");
    if (!nameRegex.hasMatch(country)) {
      AppFeedback.showError(context, 'Country can only contain letters, spaces, hyphens, dots, and apostrophes');
      return;
    }

    // Validate state - should be at least 2 characters
    if (state.length < 2 || state.length > 100) {
      AppFeedback.showError(context, 'State must be between 2 and 100 characters');
      return;
    }
    if (!nameRegex.hasMatch(state)) {
      AppFeedback.showError(context, 'State can only contain letters, spaces, hyphens, dots, and apostrophes');
      return;
    }

    // Validate city - should be at least 2 characters
    if (city.length < 2 || city.length > 100) {
      AppFeedback.showError(context, 'City must be between 2 and 100 characters');
      return;
    }
    if (!nameRegex.hasMatch(city)) {
      AppFeedback.showError(context, 'City can only contain letters, spaces, hyphens, dots, and apostrophes');
      return;
    }

    // Validate pincode format
    if (country.toLowerCase().contains('india')) {
      if (pincode.length != 6 || int.tryParse(pincode) == null) {
        AppFeedback.showError(context, 'Indian pincode must be exactly 6 digits');
        return;
      }
    } else {
      if (pincode.length < 3 || pincode.length > 15) {
        AppFeedback.showError(context, 'Pincode must be between 3 and 15 characters');
        return;
      }
      if (!RegExp(r'^[A-Za-z0-9\-\s]+$').hasMatch(pincode)) {
        AppFeedback.showError(context, 'Pincode contains invalid characters');
        return;
      }
    }

    // Validate street address length
    final street = _streetCtrl.text.trim();
    if (street.length > 500) {
      AppFeedback.showError(context, 'Street address cannot exceed 500 characters');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile(UpdateUserProfileDto(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        countryCode: phoneCode.startsWith('+') ? phoneCode : '+$phoneCode',
        profilePicture: _profilePicBase64,
        address: AddressDto(
          street: _streetCtrl.text.trim().isNotEmpty ? _streetCtrl.text.trim() : null,
          city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
          state: _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
          pincode: _pincodeCtrl.text.trim().isNotEmpty ? _pincodeCtrl.text.trim() : null,
          country: _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : null,
        ),
      ));

      // Invalidate the profile provider to refresh data everywhere (home screen, etc.)
      ref.invalidate(userProfileProvider);
      setState(() => _isEditMode = false);

      if (mounted) {
        AppFeedback.showSuccess(context, 'Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrorFormatter.format(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: _ProfileTok.bg,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _ProfileTok.primary)),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: _ProfileTok.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load profile\n${err.toString().replaceFirst("Exception: ", "")}',
                      style: const TextStyle(color: _ProfileTok.textMedium), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _ProfileTok.primary, foregroundColor: Colors.white),
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            // Populate fields on first load or when not editing
            if (!_isEditMode) {
               _populateFields(profile);
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Profile',
                          style: TextStyle(color: _ProfileTok.textHigh, fontSize: 22, fontWeight: FontWeight.bold)),
                      if (!_isEditMode)
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: _ProfileTok.primary),
                          onPressed: () {
                            _populateFields(profile);
                            setState(() => _isEditMode = true);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar presentation
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _isEditMode ? _pickImage : null,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9E4F), Color(0xFFFF6600)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _ProfileTok.primary.withValues(alpha: 0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white,
                            backgroundImage: _resolveProfilePicture(_profilePicBase64 ?? profile.profilePicture),
                            child: (_profilePicBase64 == null && (profile.profilePicture == null || profile.profilePicture!.isEmpty))
                                ? Text(
                                    profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _ProfileTok.primary),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (_isEditMode)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: _ProfileTok.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditMode)
                    const Text(
                      'Tap the photo to add or change your profile picture',
                      style: TextStyle(color: _ProfileTok.textMedium, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  if (_isEditMode) const SizedBox(height: 8),
                  Text(
                    profile.fullName,
                    style: const TextStyle(color: _ProfileTok.textHigh, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: const TextStyle(color: _ProfileTok.textMedium, fontSize: 13),
                  ),
                  const SizedBox(height: 32),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _ProfileTok.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _ProfileTok.border),
                    ),
                    child: Column(
                      children: [
                        ProfileInfoTile(label: 'Full Name', controller: _nameCtrl, icon: Icons.person_outline_rounded, isEditMode: _isEditMode),
                        ProfileInfoTile(label: 'Email', controller: _emailCtrl, icon: Icons.email_outlined, isEditMode: _isEditMode, validator: _validateEmail),
                        if (_isEditMode)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _phoneCodeCtrl,
                                    style: const TextStyle(color: Color(0xFF1A1918), fontSize: 14),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Code',
                                      labelStyle: const TextStyle(color: Color(0xFF5F5C58), fontSize: 13),
                                      prefixIcon: const Icon(Icons.add_rounded, color: Color(0xFFFF6600), size: 16),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFEAE8E3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFEAE8E3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFFF6600), width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 7,
                                  child: ProfileInfoTile(
                                    label: 'Phone Number',
                                    controller: _phoneCtrl,
                                    icon: Icons.phone_outlined,
                                    isEditMode: true,
                                    isPhone: true,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ProfileInfoTile(
                            label: 'Phone',
                            controller: TextEditingController(
                              text: '${_phoneCodeCtrl.text.isNotEmpty ? "${_phoneCodeCtrl.text.startsWith('+') ? '' : '+'}${_phoneCodeCtrl.text} " : ""}${_phoneCtrl.text}',
                            ),
                            icon: Icons.phone_outlined,
                            isEditMode: false,
                          ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Address Details',
                            style: TextStyle(color: _ProfileTok.primary, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ProfileInfoTile(label: 'Street', controller: _streetCtrl, icon: Icons.home_outlined, isEditMode: _isEditMode),
                        ProfileInfoTile(label: 'City', controller: _cityCtrl, icon: Icons.location_city_outlined, isEditMode: _isEditMode),
                        ProfileInfoTile(label: 'State', controller: _stateCtrl, icon: Icons.map_outlined, isEditMode: _isEditMode),
                        ProfileInfoTile(label: 'Pincode', controller: _pincodeCtrl, icon: Icons.pin_drop_outlined, isEditMode: _isEditMode),
                        ProfileInfoTile(label: 'Country', controller: _countryCtrl, icon: Icons.flag_outlined, isEditMode: _isEditMode),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_isEditMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _ProfileTok.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ProfileTok.textMedium,
                              side: const BorderSide(color: _ProfileTok.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => setState(() => _isEditMode = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Preferences
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _ProfileTok.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _ProfileTok.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferences',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _ProfileTok.textHigh,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Display currency',
                                style: TextStyle(
                                  color: _ProfileTok.textMedium,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (_loadingCurrencies)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _currencies.contains(_currency)
                                      ? _currency
                                      : (_currencies.isNotEmpty
                                          ? _currencies.first
                                          : UserPrefsStore.defaultCurrency),
                                  isExpanded: false,
                                  menuMaxHeight: 360,
                                  items: _currencies
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    await UserPrefsStore.setCurrency(v);
                                    if (!mounted) return;
                                    setState(() => _currency = v);
                                    if (!context.mounted) return;
                                    AppFeedback.showSuccess(
                                      context,
                                      'Currency set to $v',
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 20),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(
                            Icons.lock_reset_rounded,
                            color: _ProfileTok.primary,
                          ),
                          title: const Text(
                            'Change password',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _ProfileTok.textHigh,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/change-password'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ProfileTok.error,
                        side: const BorderSide(color: _ProfileTok.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout from Account', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legal & Account Links
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => context.push('/privacy-policy'),
                          icon: const Icon(Icons.description_outlined, size: 16, color: _ProfileTok.textMedium),
                          label: const Text('Privacy Policy', style: TextStyle(color: _ProfileTok.textMedium, fontSize: 12)),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => context.push('/delete-account'),
                          icon: const Icon(Icons.delete_outline, size: 16, color: _ProfileTok.error),
                          label: const Text('Delete Account', style: TextStyle(color: _ProfileTok.error, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
