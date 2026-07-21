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
      List.generate(30, (index) => EmberParticle());

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
      backgroundColor: const Color(0xFF060403),
      body: Stack(
        children: [
          // ─── 1. AMBIENT BACKGROUND PAINTER WITH EMBER PARTICLES ───
          Positioned.fill(
            child: CustomPaint(
              painter: PremiumBackgroundPainter(_particles),
            ),
          ),

          // ─── 2. FLOATING TOP NAV BAR (BACK BUTTON) ───
          Positioned(
            top: 44,
            left: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF140F0A).withValues(alpha: 0.85),
                    border: Border.all(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
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

          // ─── 3. RESPONSIVE SCROLLABLE CONTENT BODY ───
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // ─── HERO EMBLEM BADGE ───
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2A170B),
                              Color(0xFF140B05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.synagogue_outlined,
                              size: 34,
                              color: Color(0xFFFF9D00),
                            ),
                            Positioned(
                              top: 8,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7A00),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '\u0950',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── HEADER BRANDING TYPOGRAPHY BLOCK ───
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Create Your ',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                            TextSpan(
                              text: 'Account',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF9D00),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Lotus & Golden Line Divider: ─── 🪷 ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 45,
                            height: 1.2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFFF9D00).withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(
                              Icons.filter_vintage_rounded,
                              size: 14,
                              color: Color(0xFFFF9D00),
                            ),
                          ),
                          Container(
                            width: 45,
                            height: 1.2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF9D00).withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Subtitle Text
                      const Text(
                        'Join Vocal For Sanatan and be a part of\npreserving our heritage.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFFC8BCB0),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // ─── 4. MAIN SIGNUP CARD CONTAINER ───
                      Container(
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF110D0A).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.30),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Field 1: Full Name
                              TextFormField(
                                controller: _nameController,
                                validator: _validateName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Full Name',
                                  prefixIcon: Icons.person_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Field 2: Phone Number + Country Code Selector
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF18130F),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: const Color(0xFF2A2017)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          color: Color(0xFFFF7A00),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedPhoneCode,
                                            dropdownColor:
                                                const Color(0xFF1B1511),
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white54,
                                              size: 18,
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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      validator: _validatePhone,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        hint: 'Phone Number',
                                        prefixIcon: null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Field 3: Email Address
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Email Address',
                                  prefixIcon: Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Field 4: Country Dropdown
                              DropdownButtonFormField<Country>(
                                initialValue: _selectedCountry,
                                dropdownColor: const Color(0xFF1B1511),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
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
                                  size: 20,
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
                                        _selectedPhoneCode =
                                            val.phoneCode!.replaceAll('+', '');
                                      }
                                    });
                                    _loadStates(val.iso2);
                                  }
                                },
                                validator: (v) =>
                                    v == null ? 'Country is required' : null,
                              ),
                              const SizedBox(height: 12),

                              // Fields 5 & 6: State & City Dropdowns (Side-by-Side)
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<StateModel>(
                                      initialValue: _selectedState,
                                      dropdownColor: const Color(0xFF1B1511),
                                      isExpanded: true,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        hint: _loadingStates
                                            ? 'Loading...'
                                            : 'State',
                                        prefixIcon:
                                            Icons.account_balance_outlined,
                                      ),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white54,
                                        size: 18,
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
                                          setState(() => _selectedState = val);
                                          _loadCities(
                                              _selectedCountry!.iso2, val.iso2);
                                        }
                                      },
                                      validator: (v) =>
                                          v == null ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<CityModel>(
                                      initialValue: _selectedCity,
                                      dropdownColor: const Color(0xFF1B1511),
                                      isExpanded: true,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        hint: _loadingCities
                                            ? 'Loading...'
                                            : 'City',
                                        prefixIcon: Icons.location_city_rounded,
                                      ),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white54,
                                        size: 18,
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
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Fields 7 & 8: Pincode & Street Address (Side-by-Side)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _pincodeController,
                                      validator: _validatePincode,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        hint: 'Pincode',
                                        prefixIcon: Icons.location_on_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _streetController,
                                      validator: _validateStreet,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        hint: 'Street Address',
                                        prefixIcon: Icons.add_road_rounded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Field 9: Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                validator: _validatePassword,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
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
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Field 10: Confirm Password
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_showConfirmPassword,
                                validator: _validateConfirmPassword,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
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
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Privacy Info Shield Banner Box
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF17120E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFFF7A00)
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_user_outlined,
                                      color: Color(0xFFFF9D00),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Your privacy is important to us',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFFF9D00),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'We never share your information with anyone.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              color: Color(0xFFAAA095),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ─── ACTION BUTTON ("Create Account") ───
                              SizedBox(
                                width: double.infinity,
                                height: 52,
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
                                            .withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
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
                                          horizontal: 16),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
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
                                                size: 22,
                                              ),
                                              const Spacer(),
                                              const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                width: 30,
                                                height: 30,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFFF9E1B),
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 16,
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
                      const SizedBox(height: 20),

                      // Footer Link: "Already have an account? Login"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF7A00),
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dashed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
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
        fontSize: 13,
        color: Color(0xFF7B7065),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: const Color(0xFFFF7A00),
              size: 18,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFF18130F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2A2017)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2A2017)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF4D4F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF4D4F), width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: Color(0xFFFF4D4F),
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

// ─── PREMIUM AMBIENT BACKGROUND PAINTER ───

class PremiumBackgroundPainter extends CustomPainter {
  final List<EmberParticle> particles;

  PremiumBackgroundPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Layered Dark Gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0A0704),
          Color(0xFF050302),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRect(rect, bgPaint);

    // 2. Upper Radial Ambient Glow Aura
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.76),
        radius: 0.70,
        colors: [
          const Color(0xFFFF7A00).withValues(alpha: 0.38),
          const Color(0xFFD64000).withValues(alpha: 0.18),
          const Color(0xFF3D1200).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, glowPaint);

    // 3. Floating Ember Particles
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

    // 4. Subtle Golden Wave Swooshes
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      wavePaint.color =
          const Color(0xFFFF8C00).withValues(alpha: 0.12 + i * 0.03);
      final path = Path();
      double yOffset = size.height * (0.05 + i * 0.04);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 18 + i * 6,
        size.width * 0.7,
        yOffset + 20 - i * 5,
        size.width,
        yOffset - 8,
      );
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
