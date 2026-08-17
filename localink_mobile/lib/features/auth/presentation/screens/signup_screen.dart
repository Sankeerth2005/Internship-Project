import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/google_sign_in_helper.dart';
import '../../../../core/auth/role_routes.dart';
import '../../../../core/widgets/brand_icons.dart';
import '../../../../core/validation/app_validators.dart';
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
import '../../../shared/presentation/widgets/app_back_button.dart';
import '../../../shared/presentation/widgets/animated_field_glow.dart';
import '../../../shared/presentation/widgets/app_background.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../shared/presentation/widgets/searchable_select_field.dart';
import '../../../shared/presentation/widgets/location_picker_items.dart';
import '../../../../core/network/app_error_formatter.dart';

class _Tok {
  static const Color primary = Color(0xFFFF6600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color medText = Color(0xFF5F5C58);
  static const Color mutedText = Color(0xFF9F9B96);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const double lg = 16;
  static const double rRound = 999;
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // 0 = profile, 1 = password. Role is chosen after login via Continue As.
  int _currentStep = 0;
  final List<GlobalKey<FormState>> _stepFormKeys =
      List.generate(2, (_) => GlobalKey<FormState>());
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  String _activeFocusField = '';
  List<Country> _countries = [];
  Country? _selectedCountry;
  String _selectedPhoneCode = '91';
  bool _loadingCountries = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _setupFocusListeners();
    _loadCountries();
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(() => _updateFocus('name', _nameFocus.hasFocus));
    _phoneFocus.addListener(() => _updateFocus('phone', _phoneFocus.hasFocus));
    _emailFocus.addListener(() => _updateFocus('email', _emailFocus.hasFocus));
    _passwordFocus
        .addListener(() => _updateFocus('password', _passwordFocus.hasFocus));
    _confirmPasswordFocus.addListener(
      () => _updateFocus('confirmPassword', _confirmPasswordFocus.hasFocus),
    );
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => setState(() {});

  LocationRepository get _locationRepo => ref.read(locationRepositoryProvider);

  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    try {
      final countries = await _locationRepo.getCountries();
      if (!mounted) return;
      Country? india;
      for (final c in countries) {
        if (c.name.toLowerCase() == 'india') {
          india = c;
          break;
        }
      }
      setState(() {
        _countries = countries;
        _selectedCountry = india ?? (countries.isNotEmpty ? countries.first : null);
        final code = _selectedCountry?.phoneCode?.replaceAll('+', '').trim();
        if (code != null && code.isNotEmpty) _selectedPhoneCode = code;
        _loadingCountries = false;
      });
    } catch (e, st) {
      debugPrint('Error loading countries: $e\n$st');
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  void _onCountrySelected(Country country) {
    final newCode = (country.phoneCode ?? '').replaceAll('+', '').trim();
    setState(() {
      _selectedCountry = country;
      if (newCode.isNotEmpty) _selectedPhoneCode = newCode;
    });
    _stepFormKeys[0].currentState?.validate();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep == 0) {
      if (_stepFormKeys[0].currentState?.validate() == true) {
        setState(() => _currentStep = 1);
      } else {
        _shakeKey.currentState?.shake();
      }
    }
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;
    if (_stepFormKeys[1].currentState?.validate() != true) {
      _shakeKey.currentState?.shake();
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final national = AppValidators.nationalNumber(
        _phoneController.text,
        _selectedPhoneCode,
      );
      final request = RegisterRequest(
        userType: 'user',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: national,
        countryCode: '+$_selectedPhoneCode',
        password: _passwordController.text,
        country: _selectedCountry?.name ?? '',
        state: '',
        city: '',
        street: '',
        pincode: '',
      );

      final message = await ref.read(authProvider.notifier).register(request);
      if (!mounted) return;
      if (message != null) {
        HapticFeedback.mediumImpact();
        await AppDialog.showSuccess(
          context: context,
          title: 'Account Created!',
          message: 'Sign in to choose how you want to continue.',
        );
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrorFormatter.format(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (ref.read(authProvider) is AuthLoading) return;
    try {
      HapticFeedback.lightImpact();
      final idToken = await GoogleSignInHelper.getIdToken();
      if (idToken == null) return;
      await ref.read(authProvider.notifier).googleSignIn(idToken);
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        AppFeedback.showError(context, GoogleSignInHelper.friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        HapticFeedback.heavyImpact();
        _shakeKey.currentState?.shake();
        final cleanMsg = next.message.replaceAll('Exception: ', '').trim();
        AppFeedback.showError(context, cleanMsg);
      } else if (next is AuthAuthenticated) {
        HapticFeedback.mediumImpact();
        context.go(RoleRoutes.resolvePostAuthRoute(
          accountType: next.userType,
          activeExperience: next.activeExperience,
          needsExperienceSelection: next.needsExperienceSelection,
        ));
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          _prevStep();
        } else {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: _Tok.white,
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: Stack(
            children: [
              SafeArea(
                child: Row(
                  children: [
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
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
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
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12),
                  child: AppBackButton(
                    onPressed: () {
                      if (_currentStep > 0) {
                        _prevStep();
                      } else {
                        context.go('/login');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Column(
        key: ValueKey(_currentStep),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _Tok.lg,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _Tok.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(_Tok.rRound),
                border: Border.all(color: _Tok.primary.withValues(alpha: 0.18)),
              ),
              child: Text(
                'Step ${_currentStep + 1} of 2',
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
          Row(
            children: List.generate(2, (index) {
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
          if (_currentStep == 0) _buildStep1Profile() else _buildStep2Security(),
        ],
      ),
    );
  }

  Widget _buildStep1Profile() {
    return Form(
      key: _stepFormKeys[0],
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
          const Text(
            'A few details to get you started. You can add your address later.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _Tok.medText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          AnimatedFieldGlow(
            isFocused: _activeFocusField == 'name',
            child: AppTextField(
              controller: _nameController,
              labelText: 'Name *',
              hintText: 'Enter full name',
              prefixIcon: Icons.person_outline_rounded,
              validator: AppValidators.name,
              focusNode: _nameFocus,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              maxLength: 100,
            ),
          ),
          const SizedBox(height: 16),
          SearchableSelectField<Country>(
            label: 'Country *',
            hint: 'Select country',
            prefixIcon: Icons.public_rounded,
            items: countryPickerItems(_countries),
            selected: _selectedCountry,
            loading: _loadingCountries,
            searchHint: 'Search countries...',
            emptyMessage: 'No countries found',
            validator: (v) => AppValidators.requiredSelection(v, 'Country'),
            onSelected: (item) => _onCountrySelected(item.value),
          ),
          const SizedBox(height: 16),
          AnimatedFieldGlow(
            isFocused: _activeFocusField == 'phone',
            child: AppTextField(
              controller: _phoneController,
              labelText: 'Phone *',
              hintText: _selectedPhoneCode.isEmpty
                  ? 'Phone number'
                  : 'Number ($_selectedPhoneCode)',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) => AppValidators.phone(
                v,
                countryCode: _selectedPhoneCode,
                countryName: _selectedCountry?.name,
              ),
              focusNode: _phoneFocus,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              ],
              onChanged: (_) => _stepFormKeys[0].currentState?.validate(),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedFieldGlow(
            isFocused: _activeFocusField == 'email',
            child: AppTextField(
              controller: _emailController,
              labelText: 'Email *',
              hintText: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              validator: AppValidators.email,
              focusNode: _emailFocus,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _nextStep(),
            ),
          ),
          const SizedBox(height: 32),
          AppButton(label: 'Continue', onPressed: _nextStep),
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE8E3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSubmitting ? null : _signInWithGoogle,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BrandIcons.google(size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1918),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSignInLink(),
        ],
      ),
    );
  }

  Widget _buildStep2Security() {
    return Form(
      key: _stepFormKeys[1],
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
            'Choose a strong password to protect your account.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _Tok.medText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          AnimatedFieldGlow(
            isFocused: _activeFocusField == 'password',
            child: AppTextField(
              controller: _passwordController,
              labelText: 'Password *',
              hintText: 'Enter your password',
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: AppValidators.password,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 14),
          _buildPasswordChecklist(),
          const SizedBox(height: 16),
          AnimatedFieldGlow(
            isFocused: _activeFocusField == 'confirmPassword',
            child: AppTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password *',
              hintText: 'Re-enter your password',
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) => AppValidators.confirmPassword(
                v,
                _passwordController.text,
              ),
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

  Widget _buildPasswordChecklist() {
    final text = _passwordController.text;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Tok.surface,
        borderRadius: BorderRadius.circular(12),
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
          _buildChecklistItem('Minimum 8 characters', AppValidators.hasMinLength(text)),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one uppercase letter (A-Z)', AppValidators.hasUpper(text)),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one lowercase letter (a-z)', AppValidators.hasLower(text)),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one number (0-9)', AppValidators.hasDigit(text)),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one special character', AppValidators.hasSpecial(text)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isCompleted) {
    return Row(
      children: [
        Icon(
          isCompleted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
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
          onTap: () => context.go('/login'),
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
