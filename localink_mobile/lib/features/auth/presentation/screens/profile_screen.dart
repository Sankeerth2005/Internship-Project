import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_provider.dart';
import '../../data/models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../../profile/widgets/profile_info_tile.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../../core/network/app_error_formatter.dart';

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

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pincodeCtrl.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    _pincodeCtrl.removeListener(_onPincodeChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
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
    _phoneCtrl.text = profile.phone ?? '';
    _streetCtrl.text = profile.address.street ?? '';
    _cityCtrl.text = profile.address.city ?? '';
    _stateCtrl.text = profile.address.state ?? '';
    _pincodeCtrl.text = profile.address.pincode ?? '';
    _countryCtrl.text = profile.address.country ?? '';
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppFeedback.showError(context, 'Full name is required');
      return;
    }

    final country = _countryCtrl.text.trim();
    final state = _stateCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final pincode = _pincodeCtrl.text.trim();

    // Validate phone format
    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty) {
      // Remove any non-digit chars
      final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
      if (country.toLowerCase() == 'india') {
        if (digitsOnly.length != 10 || !RegExp(r'^[3-9][0-9]{9}$').hasMatch(digitsOnly)) {
          AppFeedback.showError(
            context,
            'Indian phone numbers must be exactly 10 digits and start with 3-9',
          );
          return;
        }
      } else {
        if (digitsOnly.length < 6 || digitsOnly.length > 15) {
          AppFeedback.showError(
            context,
            'Phone number must be between 6 and 15 digits',
          );
          return;
        }
      }
    }

    // Validate email format
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      AppFeedback.showError(context, 'Email is required');
      return;
    }
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
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
    if (country.length < 2) {
      AppFeedback.showError(context, 'Country name is too short');
      return;
    }

    // Validate state - should be at least 2 characters
    if (state.length < 2) {
      AppFeedback.showError(context, 'State name is too short');
      return;
    }

    // Validate city - should be at least 2 characters
    if (city.length < 2) {
      AppFeedback.showError(context, 'City name is too short');
      return;
    }

    // Validate pincode format based on country
    if (country.toLowerCase() == 'india') {
      if (pincode.length != 6 || int.tryParse(pincode) == null) {
        AppFeedback.showError(context, 'Indian pincodes must be exactly 6 digits');
        return;
      }
    } else {
      // For other countries, pincode should be at least 3 characters and alphanumeric
      if (pincode.length < 3) {
        AppFeedback.showError(context, 'Pincode must be at least 3 characters');
        return;
      }
      // Allow alphanumeric but no special characters except hyphen and space
      final validPincode = RegExp(r'^[a-zA-Z0-9\s\-]+$');
      if (!validPincode.hasMatch(pincode)) {
        AppFeedback.showError(context, 'Pincode contains invalid characters');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile(UpdateUserProfileDto(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        address: AddressDto(
          street: _streetCtrl.text.trim().isNotEmpty ? _streetCtrl.text.trim() : null,
          city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
          state: _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
          pincode: _pincodeCtrl.text.trim().isNotEmpty ? _pincodeCtrl.text.trim() : null,
          country: _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : null,
        ),
      ));

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
                  Container(
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
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _ProfileTok.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        ProfileInfoTile(label: 'Email', controller: _emailCtrl, icon: Icons.email_outlined, isEditMode: _isEditMode),
                        ProfileInfoTile(label: 'Phone', controller: _phoneCtrl, icon: Icons.phone_outlined, isEditMode: _isEditMode),
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
