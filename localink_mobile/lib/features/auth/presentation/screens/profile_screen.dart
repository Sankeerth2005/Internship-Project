import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user_profile.dart';
import '../../providers/auth_provider.dart';

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
  void dispose() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required'), backgroundColor: Color(0xFFFF4D4F)),
      );
      return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF52C41A)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFFF4D4F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFC8A97E))),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load profile\n${err.toString().replaceFirst("Exception: ", "")}',
                      style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8A97E), foregroundColor: Colors.black),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Profile',
                          style: TextStyle(color: Color(0xFFC8A97E), fontSize: 22, fontWeight: FontWeight.bold)),
                      if (!_isEditMode)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFFC8A97E)),
                          onPressed: () {
                            _populateFields(profile);
                            setState(() => _isEditMode = true);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFC8A97E),
                    child: Text(
                      profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(profile.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(profile.email,
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 25),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        _buildField('Full Name', _nameCtrl, Icons.person),
                        _buildField('Email', _emailCtrl, Icons.email),
                        _buildField('Phone', _phoneCtrl, Icons.phone),
                        const SizedBox(height: 15),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Address', style: TextStyle(color: Color(0xFFC8A97E), fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),
                        _buildField('Street', _streetCtrl, Icons.home),
                        _buildField('City', _cityCtrl, Icons.location_city),
                        _buildField('State', _stateCtrl, Icons.map),
                        _buildField('Pincode', _pincodeCtrl, Icons.pin_drop),
                        _buildField('Country', _countryCtrl, Icons.flag),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  if (_isEditMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC8A97E),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
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

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
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

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _isEditMode
          ? TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: Icon(icon, color: const Color(0xFFC8A97E), size: 18),
                filled: true,
                fillColor: Colors.black38,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            )
          : Row(
              children: [
                Icon(icon, color: const Color(0xFFC8A97E), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        ctrl.text.isNotEmpty ? ctrl.text : 'Not set',
                        style: TextStyle(
                          color: ctrl.text.isNotEmpty ? Colors.white : Colors.white24,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
