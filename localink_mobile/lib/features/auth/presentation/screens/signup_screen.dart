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
import '../../../shared/presentation/widgets/animated_checkmark.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/app_dialog.dart';
import '../../../../core/theme/app_theme.dart';

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

  // Role type
  String _selectedType = 'user'; // 'user' or 'client'

  // Password visibility
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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
    _loadCountries();
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
      HapticFeedback.warningImpact();
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
      return 'Only letters and spaces (start with letter)';
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
        return 'Enter valid 10-digit number (starts 3-9)';
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
        HapticFeedback.errorImpact();
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
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Ambient Radial Background Glows
            Positioned.fill(
              child: CustomPaint(
                painter: _SignupGlowPainter(),
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
                                  'Welcome to\nVocal for Sanatan',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1918),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Join the community and support local stores.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    color: const Color(0xFF1A1918).withOpacity(0.6),
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
                              padding: const EdgeInsets.all(24),
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
              begin: const Offset(0.05, 0.0),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppTheme.accentColor,
                )
              else
                const SizedBox(width: 48),
              
              Text(
                'Step ${_currentStep + 1} of 3',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Segment Progress Bar
          Row(
            children: List.generate(3, (index) {
              final isPassed = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isPassed ? AppTheme.accentColor : const Color(0xFFEAE8E3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

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
    return Form(
      key: _stepFormKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1918),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _selectedType == 'client'
                ? 'Register your business on Vocal for Sanatan'
                : 'Join Vocal for Sanatan to discover local stores',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Color(0xFF5F5C58),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          AppTextField(
            controller: _nameController,
            labelText: _selectedType == 'client' ? 'Owner / Business Name *' : 'Name *',
            hintText: 'Enter full name',
            prefixIcon: Icons.person_outline_rounded,
            validator: _validateName,
            focusNode: _nameFocus,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          _buildPhoneFieldLabel(),
          const SizedBox(height: 6),
          _buildPhoneRow(),
          const SizedBox(height: 16),

          AppTextField(
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1918),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Select your location to connect with local community events.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Color(0xFF5F5C58),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          _buildCountryDropdown(),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStateDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildCityDropdown()),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
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
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1918),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Ensure your password meets core security guidelines.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Color(0xFF5F5C58),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          AppTextField(
            controller: _passwordController,
            labelText: 'Password *',
            hintText: 'Enter your password',
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: _validatePassword,
            focusNode: _passwordFocus,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          // Real-time Checklist Feedback
          _buildPasswordChecklist(),
          const SizedBox(height: 16),

          AppTextField(
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
          color: Color(0xFF1A1918),
        ),
      ),
    );
  }

  Widget _buildPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone code dropdown selector
        Container(
          width: 104,
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 8.0),
          child: DropdownButtonFormField<String>(
            value: _selectedPhoneCode,
            decoration: _compactInputDecoration(''),
            dropdownColor: Colors.white,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF1A1918),
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
        const SizedBox(width: 8),
        // Phone input textfield
        Expanded(
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
            color: Color(0xFF1A1918),
          ),
        ),
        const SizedBox(height: 6),
        _loadingCountries
            ? _buildCompactLoadingIndicator()
            : DropdownButtonFormField<Country>(
                value: _selectedCountry,
                decoration: _compactInputDecoration('Select Country'),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF1A1918),
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
            color: Color(0xFF1A1918),
          ),
        ),
        const SizedBox(height: 6),
        _loadingStates
            ? _buildCompactLoadingIndicator()
            : DropdownButtonFormField<StateModel>(
                value: _selectedState,
                decoration: _compactInputDecoration('Select State'),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF1A1918),
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
            color: Color(0xFF1A1918),
          ),
        ),
        const SizedBox(height: 6),
        _loadingCities
            ? _buildCompactLoadingIndicator()
            : DropdownButtonFormField<CityModel>(
                value: _selectedCity,
                decoration: _compactInputDecoration('Select City'),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF1A1918),
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
      ],
    );
  }

  Widget _buildCompactLoadingIndicator() {
    return const SizedBox(
      height: 48,
      child: Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accentColor,
          ),
        ),
      ),
    );
  }

  InputDecoration _compactInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password requirements:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1918),
            ),
          ),
          const SizedBox(height: 8),
          _buildChecklistItem('Minimum 8 characters', hasMin8),
          const SizedBox(height: 4),
          _buildChecklistItem('At least one uppercase letter (A-Z)', hasUpper),
          const SizedBox(height: 4),
          _buildChecklistItem('At least one lowercase letter (a-z)', hasLower),
          const SizedBox(height: 4),
          _buildChecklistItem('At least one number (0-9)', hasDigit),
          const SizedBox(height: 4),
          _buildChecklistItem('At least one special character (@, #, \$, %)', hasSpecial),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isCompleted) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isCompleted ? AppTheme.tricolorGreen : AppTheme.mutedTextColor,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isCompleted ? const Color(0xFF1A1918) : const Color(0xFF5F5C58),
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
          'Already have an account? ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: Color(0xFF5F5C58),
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
              color: AppTheme.accentColor,
            ),
          ),
        ),
      ],
    );
  }


}



// Visual Ambient Gradient Glows Painter
class _SignupGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E4F).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.9));
    canvas.drawRect(rect, p1);

    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6600).withOpacity(0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.9));
    canvas.drawRect(rect, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
