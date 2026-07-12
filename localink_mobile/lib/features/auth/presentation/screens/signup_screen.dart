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
import '../widgets/animated_background.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
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

  // Location data
  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  Country? _selectedCountry;
  StateModel? _selectedState;
  CityModel? _selectedCity;

  // Phone codes
  String _selectedPhoneCode = '91';
  List<Map<String, String>> _phoneCountries = [
    {'code': '91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '1', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': '44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '61', 'name': 'Australia', 'flag': '🇦🇺'},
  ];

  // Loading states
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _isSubmitting = false;

  // Pincode error
  String? _pincodeError;

  // Success popup
  bool _showSuccessPopup = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
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
    if (pincode.isEmpty) return true; // let form validator handle empty
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

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final pincodeValid = await _validatePincodeAsync();
    if (!pincodeValid) {
      _formKey.currentState!.validate(); // re-validate to show pincode error
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
        setState(() => _showSuccessPopup = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showSuccessPopup = false);
            context.pop();
          }
        });
      }
    }
  }

  // ===================== VALIDATORS =====================

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

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFFFF4D4F),
          ),
        );
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedAuthBackground(
            child: Row(
              children: [
                // Left pane (desktop only)
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
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Discover businesses around you',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Right pane (form)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.4, -0.4),
                        radius: 1.5,
                        colors: [
                          const Color(0xFFC8A97E).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: _buildSignupCard(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Success popup overlay
          if (_showSuccessPopup) _buildSuccessPopup(),
        ],
      ),
    );
  }

  Widget _buildSignupCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF141414).withValues(alpha: 0.6),
        backgroundBlendMode: BlendMode.srcOver,
        border: Border.all(
          color: const Color(0xFFC8A97E).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8A97E).withValues(alpha: 0.12),
            blurRadius: 20,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Heading
            const Text(
              'Create Account',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF8F4F0),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              _selectedType == 'client'
                  ? 'Register your business on Vocal for Sanatan'
                  : 'Join Vocal for Sanatan to discover businesses',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Toggle pill
            _buildTogglePill(),
            const SizedBox(height: 14),

            // ========== BASIC DETAILS ==========
            _buildFieldLabel(
              _selectedType == 'client' ? 'Owner / Business Name *' : 'Name *',
            ),
            const SizedBox(height: 4),
            _buildInputField(
              controller: _nameController,
              validator: _validateName,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z\s]')),
              ],
            ),
            const SizedBox(height: 6),

            // Phone
            _buildFieldLabel('Phone *'),
            const SizedBox(height: 4),
            _buildPhoneRow(),
            const SizedBox(height: 6),

            // Email
            _buildFieldLabel('Email *'),
            const SizedBox(height: 4),
            _buildInputField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),

            // ========== LOCATION ==========
            _buildLocationGrid(),
            const SizedBox(height: 12),

            // ========== SECURITY ==========
            _buildSecurityGrid(),
            const SizedBox(height: 14),

            // Submit button
            _buildGoldButton(
              label: _isSubmitting ? null : 'Create Account',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _onSubmit,
            ),
            const SizedBox(height: 16),

            // Login redirect
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC8A97E),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TOGGLE PILL =====================

  Widget _buildTogglePill() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            alignment: _selectedType == 'user'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC8A97E), Color(0xFFE6C89F)],
                  ),
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = 'user'),
                  child: Center(
                    child: Text(
                      'User',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: _selectedType == 'user'
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedType == 'user'
                            ? Colors.black
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = 'client'),
                  child: Center(
                    child: Text(
                      'Business Owner',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: _selectedType == 'client'
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedType == 'client'
                            ? Colors.black
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== PHONE ROW =====================

  Widget _buildPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone code selector
        SizedBox(
          width: 100,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedPhoneCode,
            decoration: _compactInputDecoration(''),
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Colors.white,
            ),
            items: _phoneCountries
                .map(
                  (pc) => DropdownMenuItem(
                    value: pc['code'],
                    child: Text(
                      '${pc['flag']} +${pc['code']}',
                      style: const TextStyle(fontSize: 11),
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
        // Phone number
        Expanded(
          child: _buildInputField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: _selectedPhoneCode == '91' ? 10 : 15,
          ),
        ),
      ],
    );
  }

  // ===================== LOCATION GRID =====================

  Widget _buildLocationGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCountryDropdown(),
              const SizedBox(height: 6),
              _buildStateDropdown(),
              const SizedBox(height: 6),
              _buildCityDropdown(),
              const SizedBox(height: 6),
              _buildPincodeField(),
              const SizedBox(height: 6),
              _buildFieldLabel('Street *'),
              const SizedBox(height: 4),
              _buildInputField(
                controller: _streetController,
                validator: _validateStreet,
              ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildCountryDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildStateDropdown()),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildCityDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildPincodeField()),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFieldLabel('Street *'),
                const SizedBox(height: 4),
                _buildInputField(
                  controller: _streetController,
                  validator: _validateStreet,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Country *'),
        const SizedBox(height: 4),
        _loadingCountries
            ? _buildLoadingIndicator()
            : DropdownButtonFormField<Country>(
                value: _selectedCountry,
                decoration: _compactInputDecoration('Select Country'),
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Colors.white,
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
                        _selectedPhoneCode = country.phoneCode!.replaceAll(
                          '+',
                          '',
                        );
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
        _buildFieldLabel('State *'),
        const SizedBox(height: 4),
        _loadingStates
            ? _buildLoadingIndicator()
            : DropdownButtonFormField<StateModel>(
                value: _selectedState,
                decoration: _compactInputDecoration('Select State'),
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Colors.white,
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
        _buildFieldLabel('City *'),
        const SizedBox(height: 4),
        _loadingCities
            ? _buildLoadingIndicator()
            : DropdownButtonFormField<CityModel>(
                value: _selectedCity,
                decoration: _compactInputDecoration('Select City'),
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Colors.white,
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

  Widget _buildPincodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Pincode *'),
        const SizedBox(height: 4),
        _buildInputField(
          controller: _pincodeController,
          validator: _validatePincode,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  // ===================== SECURITY GRID =====================

  Widget _buildSecurityGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        final passwordField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Password *'),
            const SizedBox(height: 4),
            _buildPasswordField(
              controller: _passwordController,
              show: _showPassword,
              onToggle: () => setState(() => _showPassword = !_showPassword),
              validator: _validatePassword,
            ),
          ],
        );
        final confirmField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Confirm Password *'),
            const SizedBox(height: 4),
            _buildPasswordField(
              controller: _confirmPasswordController,
              show: _showConfirmPassword,
              onToggle: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
              validator: _validateConfirmPassword,
            ),
          ],
        );
        if (isNarrow) {
          return Column(
            children: [passwordField, const SizedBox(height: 6), confirmField],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: passwordField),
            const SizedBox(width: 12),
            Expanded(child: confirmField),
          ],
        );
      },
    );
  }

  // ===================== SHARED WIDGETS =====================

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: Color(0xFFC8A97E),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: Colors.white,
      ),
      decoration: _compactInputDecoration(''),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: Colors.white,
      ),
      decoration: _compactInputDecoration('').copyWith(
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              show ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFC9A66B),
              size: 14,
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minHeight: 34,
          minWidth: 34,
        ),
      ),
    );
  }

  InputDecoration _compactInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: Colors.white.withValues(alpha: 0.3),
      ),
      counterText: '',
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC8A97E)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF4D4F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF4D4F), width: 2),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: Color(0xFFFF4D4F),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 34,
      child: Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFC8A97E),
          ),
        ),
      ),
    );
  }

  Widget _buildGoldButton({
    String? label,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFC8A97E), Color(0xFFE6C89F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8A97E).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    label ?? '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ===================== SUCCESS POPUP =====================

  Widget _buildSuccessPopup() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC8A97E).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC8A97E).withValues(alpha: 0.2),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFFC8A97E),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Account Created!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8F4F0),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Redirecting to login...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
