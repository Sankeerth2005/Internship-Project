import 'dart:async';
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
import '../../../shared/presentation/widgets/app_text_field.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/shake_widget.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/app_dialog.dart';
import '../../../../core/theme/app_theme.dart';

// ─── DESIGN TOKENS (aligned to DESIGN_SYSTEM.md) ─────────────────────────────
class _Tok {
  static const Color primary  = Color(0xFFFF6600);
  static const Color white    = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color medText  = Color(0xFF5F5C58);
  static const Color mutedText = Color(0xFF9F9B96);
  static const Color surface  = Color(0xFFF9F8F6);
  static const Color border   = Color(0xFFEAE8E3);

  // Spacing (4dp grid)
  static const double lg  = 16;

  // Radii
  static const double rMd    = 12;
  static const double rRound = 999;
}

class SignupScreen extends ConsumerStatefulWidget {
  final String? preSelectedRole;

  const SignupScreen({super.key, this.preSelectedRole});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // Wizard Steps: 0 = Profile Details, 1 = Location Details, 2 = Security Details
  int _currentStep = 0;
  final List<GlobalKey<FormState>> _stepFormKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _streetFocus = FocusNode();
  final FocusNode _pincodeFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // Active focus tracker for field glows
  String _activeFocusField = '';

  // Role type
  String _selectedType = 'user'; // 'user' or 'client'

  // Location data lists and selections
  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  Country? _selectedCountry;
  StateModel? _selectedState;
  CityModel? _selectedCity;

  // Phone code details
  String _selectedPhoneCode = '91';
  List<Map<String, String>> _phoneCountries = [
    {'code': '91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '1', 'name': 'United States', 'flag': '🇺🇸'},
  ];

  // Loading indicator controls
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _isSubmitting = false;

  // Pincode validation mismatch error message
  String? _pincodeError;

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
    _passwordController.addListener(_onPasswordChanged);
    _setupFocusListeners();
    _loadCountries();
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(() => _updateFocus('name', _nameFocus.hasFocus));
    _phoneFocus.addListener(() => _updateFocus('phone', _phoneFocus.hasFocus));
    _emailFocus.addListener(() => _updateFocus('email', _emailFocus.hasFocus));
    _streetFocus.addListener(() => _updateFocus('street', _streetFocus.hasFocus));
    _pincodeFocus.addListener(() => _updateFocus('pincode', _pincodeFocus.hasFocus));
    _passwordFocus.addListener(() => _updateFocus('password', _passwordFocus.hasFocus));
    _confirmPasswordFocus.addListener(() => _updateFocus('confirmPassword', _confirmPasswordFocus.hasFocus));
  }

  void _updateFocus(String fieldName, bool hasFocus) {
    if (hasFocus) {
      setState(() => _activeFocusField = fieldName);
    } else if (_activeFocusField == fieldName) {
      setState(() => _activeFocusField = '');
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _pincodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _streetFocus.dispose();
    _pincodeFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {}); // Updates requirement checkmarks dynamically
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
        
        // India pre-selected setup
        try {
          final india = countries.firstWhere((c) => c.name.toLowerCase() == 'india');
          _selectedCountry = india;
          if (india.phoneCode != null) {
            _selectedPhoneCode = india.phoneCode!.replaceAll('+', '');
          }
          _loadStates(india.iso2);
        } catch (_) {}
        
        _loadingCountries = false;
      });
    } catch (e, st) {
      debugPrint('Error loading countries: $e');
      debugPrint('$st');
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
    } catch (e, st) {
      debugPrint('Error loading states: $e');
      debugPrint('$st');
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
    } catch (e, st) {
      debugPrint('Error loading cities: $e');
      debugPrint('$st');
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
      if (norm(res.country) != norm(_selectedCountry?.name)) {
        setState(() => _pincodeError = 'Pincode country mismatch');
        return false;
      }
      if (norm(res.state) != norm(_selectedState?.name)) {
        setState(() => _pincodeError = 'Pincode state mismatch');
        return false;
      }
      if (norm(res.city) != norm(_selectedCity?.name)) {
        setState(() => _pincodeError = 'Pincode city mismatch');
        return false;
      }
      return true;
    } catch (_) {
      setState(() => _pincodeError = 'Pincode verification failed');
      return false;
    }
  }

  void _nextStep() async {
    HapticFeedback.lightImpact();
    if (_currentStep == 0) {
      if (_stepFormKeys[0].currentState!.validate()) {
        setState(() {
          _currentStep = 1;
        });
      } else {
        _shakeKey.currentState?.shake();
      }
    } else if (_currentStep == 1) {
      if (_stepFormKeys[1].currentState!.validate()) {
        setState(() => _loadingCities = true);
        final pincodeValid = await _validatePincodeAsync();
        setState(() => _loadingCities = false);
        if (!pincodeValid) {
          _stepFormKeys[1].currentState!.validate();
          _shakeKey.currentState?.shake();
          return;
        }
        setState(() {
          _currentStep = 2;
        });
      } else {
        _shakeKey.currentState?.shake();
      }
    }
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_stepFormKeys[2].currentState!.validate()) {
      _shakeKey.currentState?.shake();
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _isSubmitting = true);

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
        HapticFeedback.mediumImpact();
        AppDialog.showSuccess(
          context: context,
          title: 'Account Created!',
          message: 'Redirecting to login dashboard...',
        ).then((_) {
          if (mounted) {
            context.pop();
          }
        });
      }
    }
  }

  // ===================== FORM VALIDATORS =====================

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!RegExp(r'^[A-Za-z][A-Za-z\s]*$').hasMatch(v.trim())) {
      return 'Letters and spaces only (start with letter)';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!RegExp(
      r'^[a-zA-Z][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(v.trim())) {
      return 'Invalid email';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (_selectedPhoneCode == '91') {
      if (!RegExp(r'^[3-9][0-9]{9}$').hasMatch(v.trim())) {
        return 'Enter 10-digit number (starts 3-9)';
      }
    } else {
      if (!RegExp(r'^(?!0+$)[0-9]{6,15}$').hasMatch(v.trim())) {
        return 'Invalid phone (6-15 digits)';
      }
    }
    return null;
  }

  String? _validatePincode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!RegExp(r'^[A-Za-z0-9\-\s]{3,10}$').hasMatch(v.trim())) {
      return 'Invalid format';
    }
    if (_pincodeError != null) return _pincodeError;
    return null;
  }

  String? _validateStreet(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 8) return 'Min 8 characters';
    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$',
    ).hasMatch(v)) {
      return 'Needs upper, lower, number & special char';
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        HapticFeedback.heavyImpact();
        _shakeKey.currentState?.shake();
        final cleanMsg = next.message.replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMsg),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } else if (next is AuthAuthenticated) {
        HapticFeedback.mediumImpact();
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _prevStep();
      },
      child: Scaffold(
        backgroundColor: _Tok.white,
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: CustomPaint(
                painter: _SignupBgPainter(),
              ),
            ),

            SafeArea(
              child: Row(
                children: [
                  // Desktop left branding pane
                  if (isWide)
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 80,
                            left: 60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Join Vocal\nfor Sanatan',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: _Tok.charcoal,
                                    height: 1.15,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Register to discover verified local businesses,\nsupport your community, and connect directly.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    color: _Tok.medText,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Form pane
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: ShakeWidget(
                          key: _shakeKey,
                          child: Center(
                            child: AppCard(
                              maxWidth: 500,
                              padding: const EdgeInsets.all(28),
                              child: _buildStepContent(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Premium back navigation button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 12),
                child: _BackButton(
                  onPressed: () {
                    if (_currentStep > 0) {
                      _prevStep();
                    } else {
                      context.pop();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP DISPATCHER ───
  Widget _buildStepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(_currentStep),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step Header
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: _Tok.lg, vertical: 6),
              decoration: BoxDecoration(
                color: _Tok.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(_Tok.rRound),
                border: Border.all(color: _Tok.primary.withValues(alpha: 0.18)),
              ),
              child: Text(
                'Step ${_currentStep + 1} of 3',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _Tok.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Horizontal Segment Progress Bar
          Row(
            children: List.generate(3, (index) {
              final isPassed = index <= _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isPassed ? _Tok.primary : _Tok.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Render Page fields based on active index
          _currentStep == 0
              ? _buildStep0()
              : _currentStep == 1
                  ? _buildStep1()
                  : _buildStep2(),
        ],
      ),
    );
  }

  // ─── STEP 1: Profile Details ───
  Widget _buildStep0() {
    final isClient = _selectedType == 'client';
    return Form(
      key: _stepFormKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _Tok.charcoal,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isClient
                ? 'Register your business on Vocal for Sanatan'
                : 'Join Vocal for Sanatan to discover local stores',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _Tok.medText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          _AnimatedFieldGlow(
            isFocused: _activeFocusField == 'name',
            child: AppTextField(
              controller: _nameController,
              labelText: isClient ? 'Owner / Business Name *' : 'Name *',
              hintText: 'Enter full name',
              prefixIcon: Icons.person_outline_rounded,
              validator: _validateName,
              focusNode: _nameFocus,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 16),

          _buildPhoneFieldLabel(),
          const SizedBox(height: 6),
          _buildPhoneRow(),
          const SizedBox(height: 16),

          _AnimatedFieldGlow(
            isFocused: _activeFocusField == 'email',
            child: AppTextField(
              controller: _emailController,
              labelText: 'Email *',
              hintText: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              validator: _validateEmail,
              focusNode: _emailFocus,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _nextStep(),
            ),
          ),
          const SizedBox(height: 32),

          AppButton(
            label: 'Continue',
            onPressed: _nextStep,
          ),
          const SizedBox(height: 20),

          _buildSignInLink(),
        ],
      ),
    );
  }

  // ─── STEP 2: Address Details ───
  Widget _buildStep1() {
    return Form(
      key: _stepFormKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Location Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _Tok.charcoal,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Provide your location to connect with listings and community events in your area.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _Tok.medText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          _buildCountryDropdown(),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStateDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildCityDropdown()),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _AnimatedFieldGlow(
                  isFocused: _activeFocusField == 'street',
                  child: AppTextField(
                    controller: _streetController,
                    labelText: 'Street *',
                    hintText: 'Street address',
                    prefixIcon: Icons.location_on_outlined,
                    validator: _validateStreet,
                    focusNode: _streetFocus,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _AnimatedFieldGlow(
                  isFocused: _activeFocusField == 'pincode',
                  child: AppTextField(
                    controller: _pincodeController,
                    labelText: 'Pincode *',
                    hintText: 'Pincode',
                    keyboardType: TextInputType.number,
                    validator: _validatePincode,
                    focusNode: _pincodeFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _nextStep(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          AppButton(
            label: 'Continue',
            isLoading: _loadingCities,
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  // ─── STEP 3: Security & Credentials ───
  Widget _buildStep2() {
    return Form(
      key: _stepFormKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Secure Account',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _Tok.charcoal,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ensure your password meets the required security criteria.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _Tok.medText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          _AnimatedFieldGlow(
            isFocused: _activeFocusField == 'password',
            child: AppTextField(
              controller: _passwordController,
              labelText: 'Password *',
              hintText: 'Enter your password',
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: _validatePassword,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 14),

          // Real-time Checklist Feedback
          _buildPasswordChecklist(),
          const SizedBox(height: 16),

          _AnimatedFieldGlow(
            isFocused: _activeFocusField == 'confirmPassword',
            child: AppTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password *',
              hintText: 'Re-enter your password',
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: _validateConfirmPassword,
              focusNode: _confirmPasswordFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onSubmit(),
            ),
          ),
          const SizedBox(height: 32),

          AppButton(
            label: 'Create Account',
            isLoading: _isSubmitting,
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }

  // ===================== HELPER SUB-WIDGETS =====================

  Widget _buildPhoneFieldLabel() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Phone *',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: _Tok.charcoal,
        ),
      ),
    );
  }

  Widget _buildPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone code dropdown selector
        _AnimatedFieldGlow(
          isFocused: _activeFocusField == 'phone_code',
          child: Container(
            width: 108,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Tok.surface,
              borderRadius: BorderRadius.circular(_Tok.rMd),
              border: Border.all(color: _Tok.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedPhoneCode,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                dropdownColor: _Tok.white,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: _Tok.charcoal,
                  fontWeight: FontWeight.bold,
                ),
                items: _phoneCountries
                    .map(
                      (pc) => DropdownMenuItem(
                        value: pc['code'],
                        child: Text(
                          '${pc['flag']} +${pc['code']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPhoneCode = val);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Phone input textfield
        Expanded(
          child: _AnimatedFieldGlow(
            isFocused: _activeFocusField == 'phone',
            child: AppTextField(
              controller: _phoneController,
              labelText: 'Phone Number',
              hintText: 'Number',
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
              focusNode: _phoneFocus,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Country *',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: _Tok.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        _loadingCountries
            ? _buildCompactLoadingIndicator()
            : _AnimatedFieldGlow(
                isFocused: _activeFocusField == 'country',
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _Tok.surface,
                    borderRadius: BorderRadius.circular(_Tok.rMd),
                    border: Border.all(color: _Tok.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<Country>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Select Country',
                      ),
                      dropdownColor: _Tok.white,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: _Tok.charcoal,
                        fontWeight: FontWeight.bold,
                      ),
                      items: _countries
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (country) {
                        if (country != null) {
                          setState(() {
                            _selectedCountry = country;
                            if (country.phoneCode != null) {
                              _selectedPhoneCode = country.phoneCode!.replaceAll('+', '');
                            }
                          });
                          _loadStates(country.iso2);
                        }
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State *',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: _Tok.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        _loadingStates
            ? _buildCompactLoadingIndicator()
            : _AnimatedFieldGlow(
                isFocused: _activeFocusField == 'state',
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _Tok.surface,
                    borderRadius: BorderRadius.circular(_Tok.rMd),
                    border: Border.all(color: _Tok.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<StateModel>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Select State',
                      ),
                      dropdownColor: _Tok.white,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: _Tok.charcoal,
                        fontWeight: FontWeight.bold,
                      ),
                      items: _states
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (state) {
                        if (_selectedCountry != null && state != null) {
                          setState(() => _selectedState = state);
                          _loadCities(_selectedCountry!.iso2, state.iso2);
                        }
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City *',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: _Tok.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        _loadingCities
            ? _buildCompactLoadingIndicator()
            : _AnimatedFieldGlow(
                isFocused: _activeFocusField == 'city',
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _Tok.surface,
                    borderRadius: BorderRadius.circular(_Tok.rMd),
                    border: Border.all(color: _Tok.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<CityModel>(
                      value: _selectedCity,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Select City',
                      ),
                      dropdownColor: _Tok.white,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: _Tok.charcoal,
                        fontWeight: FontWeight.bold,
                      ),
                      items: _cities
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (city) {
                        if (city != null) setState(() => _selectedCity = city);
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildCompactLoadingIndicator() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _Tok.surface,
        borderRadius: BorderRadius.circular(_Tok.rMd),
        border: Border.all(color: _Tok.border),
      ),
      child: const Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _Tok.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordChecklist() {
    final text = _passwordController.text;
    final hasMin8 = text.length >= 8;
    final hasUpper = text.contains(RegExp(r'[A-Z]'));
    final hasLower = text.contains(RegExp(r'[a-z]'));
    final hasDigit = text.contains(RegExp(r'[0-9]'));
    final hasSpecial = text.contains(RegExp(r'[\W_]'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Tok.surface,
        borderRadius: BorderRadius.circular(_Tok.rMd),
        border: Border.all(color: _Tok.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password requirements:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _Tok.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          _buildChecklistItem('Minimum 8 characters', hasMin8),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one uppercase letter (A-Z)', hasUpper),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one lowercase letter (a-z)', hasLower),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one number (0-9)', hasDigit),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one special character', hasSpecial),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isCompleted) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isCompleted ? const Color(0xFF1E824C) : _Tok.mutedText,
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: isCompleted ? _Tok.charcoal : _Tok.medText,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account?  ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: _Tok.medText,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: _Tok.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ANIMATED FIELD GLOW ─────────────────────────────────────────────────────
class _AnimatedFieldGlow extends StatelessWidget {
  final bool isFocused;
  final Widget child;

  const _AnimatedFieldGlow({
    required this.isFocused,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_Tok.rMd),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: _Tok.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}

// ─── BACK BUTTON ──────────────────────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _Tok.surface,
            borderRadius: BorderRadius.circular(_Tok.rMd),
            border: Border.all(color: _Tok.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: _Tok.charcoal,
          ),
        ),
      ),
    );
  }
}

// ─── BACKGROUND PAINTER ───────────────────────────────────────────────────────
class _SignupBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // White base
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));

    // Top-right saffron bloom
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF9E4F).withValues(alpha: 0.055),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width, 0),
            radius: size.width * 0.9,
          ),
        ),
    );

    // Bottom-left orange bloom
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF6600).withValues(alpha: 0.038),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(0, size.height),
            radius: size.width * 0.85,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
