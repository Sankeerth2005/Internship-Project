import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/user_prefs_store.dart';
import '../../../../core/validation/app_validators.dart';
import '../../../../core/async/latest_async_guard.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/location_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../../catalog/presentation/providers/currency_provider.dart';
import '../../../profile/widgets/profile_info_tile.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../shared/presentation/widgets/searchable_select_field.dart';
import '../../../shared/presentation/widgets/location_picker_items.dart';
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
  final _profileFormKey = GlobalKey<FormState>();

  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  Country? _selectedCountry;
  StateModel? _selectedState;
  CityModel? _selectedCity;
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  String? _pincodeError;
  bool _pincodeValidating = false;
  final _pincodeGuard = LatestAsyncGuard();
  final _statesGuard = LatestAsyncGuard();
  final _citiesGuard = LatestAsyncGuard();
  Timer? _pincodeDebounce;
  CancelToken? _pincodeCancel;

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
    _pincodeDebounce?.cancel();
    _pincodeCancel?.cancel();
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
    _pincodeDebounce?.cancel();
    _pincodeCancel?.cancel();
    _pincodeGuard.invalidate();
    if (_pincodeError != null || _pincodeValidating) {
      setState(() {
        _pincodeError = null;
        _pincodeValidating = false;
      });
    }
    final pincode = _pincodeCtrl.text.trim();
    final formatError = AppValidators.pincode(
      pincode,
      required: false,
      countryName: _selectedCountry?.name ?? _countryCtrl.text,
      countryIso2: _selectedCountry?.iso2,
      countryCode: _phoneCodeCtrl.text,
    );
    if (pincode.isEmpty || formatError != null) return;
    _pincodeDebounce = Timer(const Duration(milliseconds: 400), () {
      _lookupPincode(pincode);
    });
  }

  String? _validateEmail(String? value) => AppValidators.email(value);

  Future<void> _lookupPincode(String pincode) async {
    final requestId = _pincodeGuard.next();
    _pincodeCancel?.cancel();
    _pincodeCancel = CancelToken();
    if (mounted) setState(() => _pincodeValidating = true);
    try {
      final repo = ref.read(locationRepositoryProvider);
      final res = await repo.validatePincode(
        pincode,
        cancelToken: _pincodeCancel,
      );
      if (!mounted || !_pincodeGuard.isLatest(requestId)) return;
      if (_pincodeCtrl.text.trim() != pincode) return;

      if (!res.isValid) {
        setState(() {
          _pincodeError = 'Invalid or unverified pincode';
          _pincodeValidating = false;
        });
        return;
      }

      String norm(String? s) => (s ?? '').toLowerCase().replaceAll(' ', '');
      final selCountry = norm(_selectedCountry?.name ?? _countryCtrl.text);
      final selState = norm(_selectedState?.name ?? _stateCtrl.text);
      if (res.country != null &&
          selCountry.isNotEmpty &&
          !norm(res.country).contains(selCountry) &&
          !selCountry.contains(norm(res.country))) {
        setState(() {
          _pincodeError = 'Pincode country mismatch (${res.country})';
          _pincodeValidating = false;
        });
        return;
      }
      if (res.state != null &&
          selState.isNotEmpty &&
          !norm(res.state).contains(selState) &&
          !selState.contains(norm(res.state))) {
        setState(() {
          _pincodeError = 'Pincode state mismatch (${res.state})';
          _pincodeValidating = false;
        });
        return;
      }

      setState(() {
        _pincodeError = null;
        _pincodeValidating = false;
        if (res.city != null && res.city!.isNotEmpty && _selectedCity == null) {
          _cityCtrl.text = res.city!;
        }
        if (res.state != null && res.state!.isNotEmpty && _selectedState == null) {
          _stateCtrl.text = res.state!;
        }
        if (res.country != null && res.country!.isNotEmpty && _selectedCountry == null) {
          _countryCtrl.text = res.country!;
        }
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted || !_pincodeGuard.isLatest(requestId)) return;
      setState(() {
        _pincodeValidating = false;
        _pincodeError = 'Could not verify pincode. Try again.';
      });
    } catch (e) {
      if (!mounted || !_pincodeGuard.isLatest(requestId)) return;
      setState(() {
        _pincodeValidating = false;
        _pincodeError = 'Could not verify pincode. Try again.';
      });
    }
  }

  void _populateFields(UserProfileDto profile) {
    _nameCtrl.text = profile.fullName;
    _emailCtrl.text = profile.email;
    final phoneCode = profile.countryCode.replaceAll('+', '').trim();
    _phoneCodeCtrl.text = phoneCode.isEmpty ? '91' : phoneCode;
    _phoneCtrl.text = AppValidators.nationalNumber(profile.phone, phoneCode);
    _streetCtrl.text = profile.address.street ?? '';
    _cityCtrl.text = profile.address.city ?? '';
    _stateCtrl.text = profile.address.state ?? '';
    _pincodeCtrl.text = profile.address.pincode ?? '';
    final country = profile.address.country?.trim() ?? '';
    _countryCtrl.text = country.isEmpty ? 'India' : country;
    _profilePicBase64 = profile.profilePicture;
  }

  Future<void> _ensureLocationData() async {
    if (_countries.isNotEmpty) {
      await _matchLocationFromControllers();
      return;
    }
    setState(() => _loadingCountries = true);
    try {
      final repo = ref.read(locationRepositoryProvider);
      final countries = await repo.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });
      await _matchLocationFromControllers();
    } catch (_) {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  Future<void> _matchLocationFromControllers() async {
    if (_countries.isEmpty) return;
    final countryName = _countryCtrl.text.trim().toLowerCase();
    Country? matched;
    for (final c in _countries) {
      if (c.name.toLowerCase() == countryName) {
        matched = c;
        break;
      }
    }
    matched ??= _countries.cast<Country?>().firstWhere(
          (c) => c!.name.toLowerCase().contains(countryName) ||
              countryName.contains(c.name.toLowerCase()),
          orElse: () => null,
        );
    if (matched == null) return;
    _selectedCountry = matched;
    final code = matched.phoneCode?.replaceAll('+', '').trim();
    if (code != null && code.isNotEmpty && _phoneCodeCtrl.text.trim().isEmpty) {
      _phoneCodeCtrl.text = code;
    }
    await _loadStates(matched.iso2, preserveNames: true);
  }

  Future<void> _loadStates(String countryIso2, {bool preserveNames = false}) async {
    final requestId = _statesGuard.next();
    setState(() {
      _loadingStates = true;
      if (!preserveNames) {
        _states = [];
        _selectedState = null;
        _cities = [];
        _selectedCity = null;
        _stateCtrl.clear();
        _cityCtrl.clear();
        _pincodeError = null;
      }
    });
    try {
      final states = await ref.read(locationRepositoryProvider).getStates(countryIso2);
      if (!mounted || !_statesGuard.isLatest(requestId)) return;
      StateModel? matched;
      if (preserveNames) {
        final name = _stateCtrl.text.trim().toLowerCase();
        for (final s in states) {
          if (s.name.toLowerCase() == name ||
              s.name.toLowerCase().contains(name) ||
              name.contains(s.name.toLowerCase())) {
            matched = s;
            break;
          }
        }
      }
      setState(() {
        _states = states;
        _selectedState = matched;
        _loadingStates = false;
      });
      if (matched != null) {
        await _loadCities(countryIso2, matched.iso2, preserveNames: preserveNames);
      }
    } catch (_) {
      if (!mounted || !_statesGuard.isLatest(requestId)) return;
      setState(() => _loadingStates = false);
    }
  }

  Future<void> _loadCities(
    String countryIso2,
    String stateIso2, {
    bool preserveNames = false,
  }) async {
    final requestId = _citiesGuard.next();
    setState(() {
      _loadingCities = true;
      if (!preserveNames) {
        _cities = [];
        _selectedCity = null;
        _cityCtrl.clear();
        _pincodeError = null;
      }
    });
    try {
      final cities =
          await ref.read(locationRepositoryProvider).getCities(countryIso2, stateIso2);
      if (!mounted || !_citiesGuard.isLatest(requestId)) return;
      CityModel? matched;
      if (preserveNames) {
        final name = _cityCtrl.text.trim().toLowerCase();
        for (final c in cities) {
          if (c.name.toLowerCase() == name) {
            matched = c;
            break;
          }
        }
      }
      setState(() {
        _cities = cities;
        _selectedCity = matched;
        _loadingCities = false;
      });
    } catch (_) {
      if (!mounted || !_citiesGuard.isLatest(requestId)) return;
      setState(() => _loadingCities = false);
    }
  }

  Future<void> _saveProfile() async {
    final nameError = AppValidators.name(_nameCtrl.text, label: 'Full name');
    if (nameError != null) {
      AppFeedback.showError(context, nameError);
      return;
    }

    final country = (_selectedCountry?.name ?? _countryCtrl.text).trim();
    final state = (_selectedState?.name ?? _stateCtrl.text).trim();
    final city = (_selectedCity?.name ?? _cityCtrl.text).trim();
    final pincode = _pincodeCtrl.text.trim();
    final phoneCode = _phoneCodeCtrl.text.trim();
    final phone = AppValidators.nationalNumber(_phoneCtrl.text, phoneCode);

    final codeError = AppValidators.callingCode(phoneCode);
    if (codeError != null) {
      AppFeedback.showError(context, codeError);
      return;
    }
    final phoneError = AppValidators.phone(
      phone,
      countryCode: phoneCode,
      countryName: country,
    );
    if (phoneError != null) {
      AppFeedback.showError(context, phoneError);
      return;
    }

    final emailError = AppValidators.email(_emailCtrl.text);
    if (emailError != null) {
      AppFeedback.showError(context, emailError);
      return;
    }

    if (country.isEmpty || state.isEmpty || city.isEmpty || pincode.isEmpty) {
      AppFeedback.showError(
        context,
        'Country, State, City, and Pincode are all required',
      );
      return;
    }

    final streetError = AppValidators.street(_streetCtrl.text);
    if (streetError != null) {
      AppFeedback.showError(context, streetError);
      return;
    }

    final pincodeError = AppValidators.pincode(
      pincode,
      required: true,
      countryName: country,
      countryIso2: _selectedCountry?.iso2,
      countryCode: phoneCode,
      asyncError: _pincodeError,
    );
    if (pincodeError != null) {
      AppFeedback.showError(context, pincodeError);
      return;
    }

    if (_pincodeValidating) {
      AppFeedback.showError(context, 'Please wait for pincode verification');
      return;
    }

    if (_isSaving) return;
    _profileFormKey.currentState?.validate();
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile(UpdateUserProfileDto(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        phone: phone,
        countryCode: phoneCode.startsWith('+') ? phoneCode : '+$phoneCode',
        profilePicture: _profilePicBase64,
        address: AddressDto(
          street: _streetCtrl.text.trim().isNotEmpty ? _streetCtrl.text.trim() : null,
          city: city,
          state: state,
          pincode: pincode,
          country: country,
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
                            _ensureLocationData();
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
                  Form(
                    key: _profileFormKey,
                    child: Container(
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
                                    validator: (v) => AppValidators.phone(
                                      v,
                                      countryCode: _phoneCodeCtrl.text,
                                      countryName: _selectedCountry?.name ?? _countryCtrl.text,
                                    ),
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
                        if (_isEditMode) ...[
                          SearchableSelectField<Country>(
                            label: 'Country *',
                            hint: 'Select country',
                            prefixIcon: Icons.flag_outlined,
                            items: countryPickerItems(_countries),
                            selected: _selectedCountry,
                            loading: _loadingCountries,
                            searchHint: 'Search countries...',
                            emptyMessage: 'No countries found',
                            validator: (v) => AppValidators.requiredSelection(v, 'Country'),
                            onSelected: (item) {
                              setState(() {
                                _selectedCountry = item.value;
                                _countryCtrl.text = item.value.name;
                                final code = item.value.phoneCode?.replaceAll('+', '').trim();
                                if (code != null && code.isNotEmpty) {
                                  _phoneCodeCtrl.text = code;
                                }
                                _pincodeError = null;
                              });
                              _loadStates(item.value.iso2);
                            },
                          ),
                          const SizedBox(height: 16),
                          SearchableSelectField<StateModel>(
                            label: 'State *',
                            hint: _selectedCountry == null ? 'Select country first' : 'Select state',
                            prefixIcon: Icons.map_outlined,
                            items: statePickerItems(_states),
                            selected: _selectedState,
                            loading: _loadingStates,
                            enabled: _selectedCountry != null && !_loadingStates,
                            searchHint: 'Search states...',
                            emptyMessage: 'No states found',
                            validator: (v) => AppValidators.requiredSelection(v, 'State'),
                            onSelected: (item) {
                              setState(() {
                                _selectedState = item.value;
                                _stateCtrl.text = item.value.name;
                                _pincodeError = null;
                              });
                              _loadCities(_selectedCountry!.iso2, item.value.iso2);
                            },
                          ),
                          const SizedBox(height: 16),
                          SearchableSelectField<CityModel>(
                            label: 'City *',
                            hint: _selectedState == null ? 'Select state first' : 'Select city',
                            prefixIcon: Icons.location_city_outlined,
                            items: cityPickerItems(_cities),
                            selected: _selectedCity,
                            loading: _loadingCities,
                            enabled: _selectedState != null && !_loadingCities,
                            searchHint: 'Search cities...',
                            emptyMessage: 'No cities found',
                            validator: (v) => AppValidators.requiredSelection(v, 'City'),
                            onSelected: (item) {
                              setState(() {
                                _selectedCity = item.value;
                                _cityCtrl.text = item.value.name;
                                _pincodeError = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          ProfileInfoTile(
                            label: 'Pincode',
                            controller: _pincodeCtrl,
                            icon: Icons.pin_drop_outlined,
                            isEditMode: true,
                          ),
                          if (_pincodeValidating)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(
                                color: _ProfileTok.primary,
                                minHeight: 2,
                              ),
                            ),
                          if (_pincodeError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _pincodeError!,
                                style: const TextStyle(
                                  color: _ProfileTok.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ] else ...[
                          ProfileInfoTile(label: 'City', controller: _cityCtrl, icon: Icons.location_city_outlined, isEditMode: false),
                          ProfileInfoTile(label: 'State', controller: _stateCtrl, icon: Icons.map_outlined, isEditMode: false),
                          ProfileInfoTile(label: 'Pincode', controller: _pincodeCtrl, icon: Icons.pin_drop_outlined, isEditMode: false),
                          ProfileInfoTile(label: 'Country', controller: _countryCtrl, icon: Icons.flag_outlined, isEditMode: false),
                        ],
                      ],
                    ),
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
