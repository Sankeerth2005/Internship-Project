import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/register_request.dart';
import '../../data/models/location_models.dart';
import '../../data/repositories/location_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../providers/location_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String? preSelectedRole;

  const SignupScreen({super.key, this.preSelectedRole});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Role toggle
  String _selectedType = 'user'; // 'user' or 'client'

  // Password visibility
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Location Data
  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  Country? _selectedCountry;
  StateModel? _selectedState;
  CityModel? _selectedCity;

  // Phone Codes
  String _selectedPhoneCode = '91';
  List<Map<String, String>> _phoneCountries = [
    {'code': '91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '1', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': '44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '61', 'name': 'Australia', 'flag': '🇦🇺'},
  ];

  // Loading States
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _isSubmitting = false;

  // Pincode Error
  String? _pincodeError;

  // Animation & Ember Particles
  late AnimationController _particleController;
  final List<EmberParticle> _particles =
      List.generate(35, (index) => EmberParticle());

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedRole != null) {
      final role = widget.preSelectedRole!.toLowerCase().trim();
      if (role == 'client' || role == 'businessowner') {
        _selectedType = 'client';
      } else if (role == 'user') {
        _selectedType = 'user';
      }
    }

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      });
    _particleController.repeat();

    _loadCountries();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _pincodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  LocationRepository get _locationRepo => ref.read(locationRepositoryProvider);

  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    try {
      final countries = await _locationRepo.getCountries();
      final codes = countries
          .where((c) => c.phoneCode != null && c.phoneCode!.isNotEmpty)
          .map(
            (c) => {
              'code': c.phoneCode!.replaceAll('+', ''),
              'name': c.name,
              'flag': c.emoji ?? '',
            },
          )
          .toList();
      setState(() {
        _countries = countries;
        if (codes.isNotEmpty) _phoneCountries = codes;

        try {
          final india =
              countries.firstWhere((c) => c.name.toLowerCase() == 'india');
          _selectedCountry = india;
          if (india.phoneCode != null) {
            _selectedPhoneCode = india.phoneCode!.replaceAll('+', '');
          }
          _loadStates(india.iso2);
        } catch (_) {}

        _loadingCountries = false;
      });
    } catch (e) {
      setState(() => _loadingCountries = false);
    }
  }

  Future<void> _loadStates(String countryIso2) async {
    setState(() {
      _loadingStates = true;
      _states = [];
      _selectedState = null;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final states = await _locationRepo.getStates(countryIso2);
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (e) {
      setState(() => _loadingStates = false);
    }
  }

  Future<void> _loadCities(String countryIso2, String stateIso2) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final cities = await _locationRepo.getCities(countryIso2, stateIso2);
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (e) {
      setState(() => _loadingCities = false);
    }
  }

  Future<bool> _validatePincodeAsync() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.isEmpty) return true;
    setState(() => _pincodeError = null);
    try {
      final res = await _locationRepo.validatePincode(pincode);
      if (res.country == null || res.state == null || res.city == null) {
        setState(() => _pincodeError = 'Invalid pincode');
        return false;
      }
      String norm(String? s) =>
          (s ?? '').toLowerCase().replaceAll(' ', '').trim();
      if (_selectedCountry != null &&
          norm(res.country) != norm(_selectedCountry?.name)) {
        setState(() => _pincodeError = 'Pincode country mismatch');
        return false;
      }
      if (_selectedState != null &&
          norm(res.state) != norm(_selectedState?.name)) {
        setState(() => _pincodeError = 'Pincode state mismatch');
        return false;
      }
      if (_selectedCity != null && norm(res.city) != norm(_selectedCity?.name)) {
        setState(() => _pincodeError = 'Pincode city mismatch');
        return false;
      }
      return true;
    } catch (_) {
      setState(() => _pincodeError = 'Pincode verification failed');
      return false;
    }
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please resolve the errors in the form before submitting.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    final pincodeValid = await _validatePincodeAsync();
    if (!pincodeValid) {
      _formKey.currentState!.validate();
      setState(() => _isSubmitting = false);
      return;
    }

    final request = RegisterRequest(
      userType: _selectedType == 'client' ? 'BusinessOwner' : 'User',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      countryCode: '+$_selectedPhoneCode',
      password: _passwordController.text,
      country: _selectedCountry?.name ?? '',
      state: _selectedState?.name ?? '',
      city: _selectedCity?.name ?? '',
      street: _streetController.text.trim(),
      pincode: _pincodeController.text.trim(),
    );

    final message = await ref.read(authProvider.notifier).register(request);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.go('/login', extra: _selectedType);
      }
    }
  }

  // ===================== VALIDATORS =====================

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (!RegExp(r'^[A-Za-z][A-Za-z\s]*$').hasMatch(v.trim())) {
      return 'Only letters & spaces (start with letter)';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email address is required';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    if (_selectedPhoneCode == '91') {
      if (!RegExp(r'^[3-9][0-9]{9}$').hasMatch(v.trim())) {
        return 'Enter valid 10-digit number';
      }
    } else {
      if (!RegExp(r'^(?!0+$)[0-9]{6,15}$').hasMatch(v.trim())) {
        return 'Invalid phone (6-15 digits)';
      }
    }
    return null;
  }

  String? _validatePincode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Pincode is required';
    if (!RegExp(r'^[A-Za-z0-9\-\s]{3,10}$').hasMatch(v.trim())) {
      return 'Invalid pincode';
    }
    if (_pincodeError != null) return _pincodeError;
    return null;
  }

  String? _validateStreet(String? v) {
    if (v == null || v.trim().isEmpty) return 'Street is required';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Min 8 characters';
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$')
        .hasMatch(v)) {
      return 'Needs upper, lower, number & special char';
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Confirm password is required';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        final cleanMsg = next.message.replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMsg),
            backgroundColor: const Color(0xFFFF4D4F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (next is AuthAuthenticated) {
        final role = next.userType.toLowerCase().trim();
        if (role == 'admin') {
          context.go('/admin-dashboard');
        } else if (role == 'client' || role == 'businessowner') {
          context.go('/business-dashboard');
        } else {
          context.go('/home');
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF070504),
      body: Stack(
        children: [
          // ─── 1. DYNAMIC TEMPLE & SUNSET BACKGROUND ARTWORK CANVAS ───
          Positioned.fill(
            child: CustomPaint(
              painter: SignupHeroPainter(_particles),
            ),
          ),

          // ─── 2. TOP BACK BUTTON ───
          Positioned(
            top: 40,
            left: 18,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF100B08).withValues(alpha: 0.8),
                    border: Border.all(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFFFF9D00),
                  ),
                ),
              ),
            ),
          ),

          // ─── 3. FIXED NON-SCROLLABLE CONTENT LAYOUT ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Top clearance so header title sits cleanly below the sun disc & temple peak
                  const SizedBox(height: 100),

                  // ─── HEADER BRANDING TYPOGRAPHY BLOCK ───
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Create Your ',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 27,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'Account',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF9D00),
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Lotus Divider: ─── 🪷 ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFF9D00).withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Icon(
                          Icons.filter_vintage_rounded,
                          size: 13,
                          color: Color(0xFFFF9D00),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF9D00).withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Subtitle Text
                  const Text(
                    'Join Vocal For Sanatan and be a part of\npreserving our heritage.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFC4B8AC),
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // ─── 4. MAIN SIGNUP CARD CONTAINER ───
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0A08).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Field 1: Full Name
                              SizedBox(
                                height: 40,
                                child: TextFormField(
                                  controller: _nameController,
                                  validator: _validateName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: 'Full Name',
                                    prefixIcon: Icons.person_outline_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Field 2: Phone Number + Code Selector
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 40,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14110E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFF2E241A)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          color: Color(0xFFFF7A00),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedPhoneCode,
                                            dropdownColor:
                                                const Color(0xFF16110D),
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white54,
                                              size: 16,
                                            ),
                                            items: _phoneCountries.map((c) {
                                              return DropdownMenuItem<String>(
                                                value: c['code'],
                                                child: Text('+${c['code']}'),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() =>
                                                    _selectedPhoneCode = val);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        validator: _validatePhone,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: 'Phone Number',
                                          prefixIcon: null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Field 3: Email Address
                              SizedBox(
                                height: 40,
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: 'Email Address',
                                    prefixIcon: Icons.mail_outline_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Field 4: Country Dropdown
                              SizedBox(
                                height: 40,
                                child: DropdownButtonFormField<Country>(
                                  initialValue: _selectedCountry,
                                  dropdownColor: const Color(0xFF16110D),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: _loadingCountries
                                        ? 'Loading Countries...'
                                        : 'Country',
                                    prefixIcon: Icons.language_rounded,
                                  ),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white54,
                                    size: 18,
                                  ),
                                  items: _countries.map((c) {
                                    return DropdownMenuItem<Country>(
                                      value: c,
                                      child: Text(c.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedCountry = val;
                                        if (val.phoneCode != null &&
                                            val.phoneCode!.isNotEmpty) {
                                          _selectedPhoneCode = val.phoneCode!
                                              .replaceAll('+', '');
                                        }
                                      });
                                      _loadStates(val.iso2);
                                    }
                                  },
                                  validator: (v) =>
                                      v == null ? 'Country is required' : null,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Fields 5 & 6: State & City Dropdowns (Side-by-Side)
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: DropdownButtonFormField<StateModel>(
                                        initialValue: _selectedState,
                                        dropdownColor: const Color(0xFF16110D),
                                        isExpanded: true,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          color: Colors.white,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: _loadingStates
                                              ? 'Loading...'
                                              : 'State',
                                          prefixIcon: Icons
                                              .account_balance_outlined,
                                        ),
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white54,
                                          size: 16,
                                        ),
                                        items: _states.map((s) {
                                          return DropdownMenuItem<StateModel>(
                                            value: s,
                                            child: Text(s.name,
                                                overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null &&
                                              _selectedCountry != null) {
                                            setState(
                                                () => _selectedState = val);
                                            _loadCities(
                                                _selectedCountry!.iso2, val.iso2);
                                          }
                                        },
                                        validator: (v) =>
                                            v == null ? 'Required' : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: DropdownButtonFormField<CityModel>(
                                        initialValue: _selectedCity,
                                        dropdownColor: const Color(0xFF16110D),
                                        isExpanded: true,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          color: Colors.white,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: _loadingCities
                                              ? 'Loading...'
                                              : 'City',
                                          prefixIcon:
                                              Icons.location_city_rounded,
                                        ),
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white54,
                                          size: 16,
                                        ),
                                        items: _cities.map((c) {
                                          return DropdownMenuItem<CityModel>(
                                            value: c,
                                            child: Text(c.name,
                                                overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedCity = val);
                                          }
                                        },
                                        validator: (v) =>
                                            v == null ? 'Required' : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Fields 7 & 8: Pincode & Street Address (Side-by-Side)
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: TextFormField(
                                        controller: _pincodeController,
                                        validator: _validatePincode,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          color: Colors.white,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: 'Pincode',
                                          prefixIcon:
                                              Icons.location_on_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: TextFormField(
                                        controller: _streetController,
                                        validator: _validateStreet,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          color: Colors.white,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: 'Street Address',
                                          prefixIcon: Icons.add_road_rounded,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Field 9: Password
                              SizedBox(
                                height: 40,
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  validator: _validatePassword,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: 'Password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(
                                          () => _showPassword = !_showPassword),
                                      child: Icon(
                                        _showPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white54,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Field 10: Confirm Password
                              SizedBox(
                                height: 40,
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_showConfirmPassword,
                                  validator: _validateConfirmPassword,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: 'Confirm Password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() =>
                                          _showConfirmPassword =
                                              !_showConfirmPassword),
                                      child: Icon(
                                        _showConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white54,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Privacy Info Banner Box
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14100D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFF7A00)
                                        .withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_user_outlined,
                                      color: Color(0xFFFF9D00),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Your privacy is important to us',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFFF9D00),
                                            ),
                                          ),
                                          SizedBox(height: 1),
                                          Text(
                                            'We never share your information with anyone.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 10.5,
                                              color: Color(0xFFA09488),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // ─── ACTION BUTTON ("Create Account") ───
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF8000),
                                        Color(0xFFD63E00),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6A00)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.synagogue_outlined,
                                                color: Colors.white,
                                                size: 19,
                                              ),
                                              const Spacer(),
                                              const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                width: 26,
                                                height: 26,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFFF9E1B),
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Footer Link: "Already have an account? Login"
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFFC0B5A8),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/login', extra: _selectedType);
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF7A00),
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dashed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: Color(0xFF756A60),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: const Color(0xFFFF7A00),
              size: 16,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFF14110E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E241A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E241A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF4D4F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF4D4F), width: 1.4),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        color: Color(0xFFFF4D4F),
        height: 0.8,
      ),
    );
  }
}

// ─── EMBER PARTICLE ───

class EmberParticle {
  late double x;
  late double y;
  late double speedY;
  late double speedX;
  late double size;
  late double opacity;

  EmberParticle() {
    reset();
  }

  void reset() {
    final rand = math.Random();
    x = rand.nextDouble();
    y = 0.3 + rand.nextDouble() * 0.7;
    speedY = 0.0005 + rand.nextDouble() * 0.0015;
    speedX = (rand.nextDouble() - 0.5) * 0.0004;
    size = 1.0 + rand.nextDouble() * 2.5;
    opacity = 0.2 + rand.nextDouble() * 0.65;
  }

  void update() {
    y -= speedY;
    x += speedX + math.sin(y * 12) * 0.0003;

    if (y < -0.05 || x < -0.05 || x > 1.05) {
      reset();
    }
  }
}

// ─── HIGH-FIDELITY SIGNUP HERO PAINTER ───

class SignupHeroPainter extends CustomPainter {
  final List<EmberParticle> particles;

  SignupHeroPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Deep Background Gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0C0704),
          Color(0xFF070504),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRect(rect, bgPaint);

    // 2. High Sunset Glow Aura (Radial Saffron Light behind top Spire)
    final sunCenter = Offset(size.width * 0.5, size.height * 0.11);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.78),
        radius: 0.65,
        colors: [
          const Color(0xFFFF6A00).withValues(alpha: 0.60),
          const Color(0xFFD64000).withValues(alpha: 0.32),
          const Color(0xFF3D1200).withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.38, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, glowPaint);

    // 3. Glowing Sun Disc in Upper Sky
    final sunPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFFFFF0B3),
          const Color(0xFFFF9D00).withValues(alpha: 0.85),
          const Color(0xFFFF5500).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
          Rect.fromCircle(center: sunCenter, radius: size.width * 0.22));

    canvas.drawCircle(sunCenter, size.width * 0.22, sunPaint);

    // 4. Silhouetted Flying Birds in Sky
    final birdPaint = Paint()
      ..color = const Color(0xFF1E1008).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final birdPositions = [
      Offset(size.width * 0.25, size.height * 0.05),
      Offset(size.width * 0.32, size.height * 0.04),
      Offset(size.width * 0.72, size.height * 0.06),
      Offset(size.width * 0.78, size.height * 0.045),
    ];

    for (var pos in birdPositions) {
      final birdPath = Path()
        ..moveTo(pos.dx - 6, pos.dy + 2)
        ..quadraticBezierTo(pos.dx - 3, pos.dy - 3, pos.dx, pos.dy)
        ..quadraticBezierTo(pos.dx + 3, pos.dy - 3, pos.dx + 6, pos.dy + 2);
      canvas.drawPath(birdPath, birdPaint);
    }

    // 5. Floating Ember Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      particlePaint.color =
          const Color(0xFFFF9D00).withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        particlePaint,
      );
    }

    // 6. Golden Glowing Light Swooshes
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 4; i++) {
      wavePaint.color =
          const Color(0xFFFF8C00).withValues(alpha: 0.16 + i * 0.04);
      final path = Path();
      double yOffset = size.height * (0.08 + i * 0.03);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.28,
        yOffset - 20 + i * 8,
        size.width * 0.72,
        yOffset + 25 - i * 6,
        size.width,
        yOffset - 10,
      );
      canvas.drawPath(path, wavePaint);
    }

    // 7. Sanatan Temple Spires Silhouette Artwork positioned high up in header
    final templeHeight = size.height * 0.22;
    final templePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1E1008),
          const Color(0xFF0F0804),
          const Color(0xFF070504),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, templeHeight));

    final templePath = Path();
    templePath.moveTo(0, templeHeight);

    // Left outer spire
    templePath.lineTo(size.width * 0.05, templeHeight * 0.85);
    templePath.lineTo(size.width * 0.12, templeHeight * 0.55);
    templePath.lineTo(size.width * 0.18, templeHeight * 0.85);

    // Left inner spire
    templePath.lineTo(size.width * 0.25, templeHeight * 0.42);
    templePath.lineTo(size.width * 0.32, templeHeight * 0.75);

    // Central Main Shikhara Spire
    templePath.lineTo(size.width * 0.40, templeHeight * 0.35);
    templePath.lineTo(size.width * 0.47, templeHeight * 0.14);
    templePath.lineTo(size.width * 0.50, templeHeight * 0.08); // Main pinnacle
    templePath.lineTo(size.width * 0.53, templeHeight * 0.14);
    templePath.lineTo(size.width * 0.60, templeHeight * 0.35);

    // Right inner spire
    templePath.lineTo(size.width * 0.68, templeHeight * 0.75);
    templePath.lineTo(size.width * 0.75, templeHeight * 0.42);

    // Right outer spire
    templePath.lineTo(size.width * 0.82, templeHeight * 0.85);
    templePath.lineTo(size.width * 0.88, templeHeight * 0.55);
    templePath.lineTo(size.width * 0.95, templeHeight * 0.85);
    templePath.lineTo(size.width, templeHeight);

    templePath.close();
    canvas.drawPath(templePath, templePaint);

    // Draw Saffron Flying Flag atop Main Temple Spire
    final mainPeakX = size.width * 0.50;
    final mainPeakY = templeHeight * 0.08;

    final polePaint = Paint()
      ..color = const Color(0xFFFF9D00)
      ..strokeWidth = 1.5;

    canvas.drawLine(
        Offset(mainPeakX, mainPeakY), Offset(mainPeakX, mainPeakY - 14), polePaint);

    final flagPath = Path()
      ..moveTo(mainPeakX, mainPeakY - 14)
      ..lineTo(mainPeakX + 13, mainPeakY - 8.5)
      ..lineTo(mainPeakX, mainPeakY - 3)
      ..close();

    final flagPaint = Paint()
      ..color = const Color(0xFFFF7700)
      ..style = PaintingStyle.fill;

    canvas.drawPath(flagPath, flagPaint);

    // Draw small ॐ text on main flag
    const flagOmSpan = TextSpan(
      text: '\u0950',
      style: TextStyle(
        fontSize: 6.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFF0B3),
      ),
    );
    final flagOmPainter = TextPainter(
      text: flagOmSpan,
      textDirection: TextDirection.ltr,
    );
    flagOmPainter.layout();
    flagOmPainter.paint(canvas, Offset(mainPeakX + 2.0, mainPeakY - 11.5));

    // 8. Central Gear Ring Emblem & Om Flag Logo positioned on the upper central spire
    final emblemX = size.width * 0.5;
    final emblemY = templeHeight * 0.48;

    const gearRadius = 22.0;
    final gearPaint = Paint()
      ..color = const Color(0xFFFF9D00)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Gear teeth outer ring
    canvas.drawCircle(Offset(emblemX, emblemY), gearRadius, gearPaint);

    final toothPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final angle = (i * 20) * math.pi / 180;
      final dx = emblemX + (gearRadius + 3.0) * math.cos(angle);
      final dy = emblemY + (gearRadius + 3.0) * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.2, toothPaint);
    }

    // Inner dark circle container
    final innerBgPaint = Paint()
      ..color = const Color(0xFF0F0905)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(emblemX, emblemY), gearRadius - 2, innerBgPaint);

    // Flag + Om inside Central Emblem
    final emblemFlagPath = Path()
      ..moveTo(emblemX - 4, emblemY - 9)
      ..lineTo(emblemX + 8, emblemY - 4)
      ..lineTo(emblemX - 4, emblemY + 1)
      ..close();

    canvas.drawLine(
      Offset(emblemX - 4, emblemY - 11),
      Offset(emblemX - 4, emblemY + 9),
      polePaint,
    );

    canvas.drawPath(emblemFlagPath, flagPaint);

    const omSpan = TextSpan(
      text: '\u0950',
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFD166),
      ),
    );

    final omPainter = TextPainter(
      text: omSpan,
      textDirection: TextDirection.ltr,
    );
    omPainter.layout();
    omPainter.paint(
      canvas,
      Offset(emblemX - omPainter.width / 2 + 1, emblemY + 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
