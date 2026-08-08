import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/providers/user_provider.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_dialog.dart';
import '../../../../core/network/app_error_formatter.dart';

class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _isDeleting = false;
  bool _understandConsequences = false;
  final List<bool> _checklistStates = [false, false, false, false];

  final List<String> _checklistItems = [
    'I understand that my account and all associated data will be permanently deleted',
    'I understand that my business listings (if any) will be removed',
    'I understand that my reviews, favorites, and chat history will be deleted',
    'I understand that this action cannot be undone',
  ];

  Future<void> _deleteAccount() async {
    if (!_understandConsequences) {
      AppFeedback.showError(context, 'Please confirm that you understand the consequences');
      return;
    }

    if (_checklistStates.any((checked) => !checked)) {
      AppFeedback.showError(context, 'Please confirm all checklist items');
      return;
    }

    setState(() => _isDeleting = true);

    try {
      HapticFeedback.heavyImpact();
      final repo = ref.read(userRepositoryProvider);
      await repo.deleteAccount();

      if (mounted) {
        // Clear local storage and logout
        ref.read(authProvider.notifier).logout();
        
        AppDialog.showSuccess(
          context: context,
          title: 'Account Deleted',
          message: 'Your account has been permanently deleted. We\'re sorry to see you go.',
        ).then((_) {
          if (mounted) {
            context.go('/welcome');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        AppFeedback.showError(context, AppErrorFormatter.format(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1918)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF1A1918),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF6600).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6600),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This action is permanent and cannot be undone',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF1A1918),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // What will be deleted
              const Text(
                'What will be deleted:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF1A1918),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeletionItem(Icons.person_rounded, 'Your profile and personal information'),
              _buildDeletionItem(Icons.storefront_rounded, 'Your business listings and catalog'),
              _buildDeletionItem(Icons.star_rounded, 'Your reviews and ratings'),
              _buildDeletionItem(Icons.favorite_rounded, 'Your favorites and saved items'),
              _buildDeletionItem(Icons.chat_rounded, 'Your chat history and messages'),
              _buildDeletionItem(Icons.location_on_rounded, 'Your address and location data'),
              const SizedBox(height: 24),

              // Data retention notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAE8E3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: const Color(0xFF5F5C58),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Data Retention',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF1A1918),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Some data may be retained for legal or security purposes, but will be anonymized. Your account will be permanently deactivated immediately.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF5F5C58),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Checklist
              const Text(
                'Please confirm the following:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF1A1918),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_checklistItems.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _checklistStates[index] = !_checklistStates[index];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _checklistStates[index]
                            ? const Color(0xFFFF6600).withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _checklistStates[index]
                              ? const Color(0xFFFF6600)
                              : const Color(0xFFEAE8E3),
                          width: _checklistStates[index] ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _checklistStates[index]
                                  ? const Color(0xFFFF6600)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _checklistStates[index]
                                    ? const Color(0xFFFF6600)
                                    : const Color(0xFFEAE8E3),
                              ),
                            ),
                            child: _checklistStates[index]
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _checklistItems[index],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: _checklistStates[index]
                                    ? const Color(0xFF1A1918)
                                    : const Color(0xFF5F5C58),
                                fontSize: 12,
                                fontWeight: _checklistStates[index]
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Final confirmation checkbox
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _understandConsequences = !_understandConsequences;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _understandConsequences
                            ? const Color(0xFFFF6600)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _understandConsequences
                              ? const Color(0xFFFF6600)
                              : const Color(0xFFEAE8E3),
                        ),
                      ),
                      child: _understandConsequences
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I understand the consequences and want to permanently delete my account',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF1A1918),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Delete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isDeleting ? null : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1251B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Permanently Delete Account',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFE1251B),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF5F5C58),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
