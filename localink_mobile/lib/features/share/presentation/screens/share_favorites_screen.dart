import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../business/data/models/business_models.dart';
import '../../../business/providers/business_provider.dart';
import '../../../shared/presentation/widgets/app_back_button.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../../core/network/app_error_formatter.dart';
import '../../providers/share_provider.dart';
import '../../utils/business_share_helper.dart';
import '../../utils/share_actions.dart';

enum _ShareMode { all, select }

class _Tok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
}

class ShareFavoritesScreen extends ConsumerStatefulWidget {
  const ShareFavoritesScreen({super.key});

  @override
  ConsumerState<ShareFavoritesScreen> createState() =>
      _ShareFavoritesScreenState();
}

class _ShareFavoritesScreenState extends ConsumerState<ShareFavoritesScreen> {
  _ShareMode _mode = _ShareMode.all;
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _selectedIds = <int>[];
  bool _sharing = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(favoriteBusinessesProvider);

    return Scaffold(
      backgroundColor: _Tok.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  AppBackButton(onPressed: () => context.pop()),
                  const Expanded(
                    child: Text(
                      'Share Favorites',
                      style: TextStyle(
                        color: _Tok.textHigh,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: businessesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _Tok.primary),
                ),
                error: (e, _) => Center(
                  child: Text(AppErrorFormatter.format(e)),
                ),
                data: (businesses) {
                  if (businesses.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          "You don't have any favorite businesses yet.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      RadioListTile<_ShareMode>(
                        value: _ShareMode.all,
                        groupValue: _mode,
                        activeColor: _Tok.primary,
                        title: const Text('Share All Favorites'),
                        onChanged: (v) => setState(() => _mode = v!),
                      ),
                      RadioListTile<_ShareMode>(
                        value: _ShareMode.select,
                        groupValue: _mode,
                        activeColor: _Tok.primary,
                        title: const Text('Select Businesses'),
                        onChanged: (v) => setState(() => _mode = v!),
                      ),
                      const SizedBox(height: 8),
                      if (_mode == _ShareMode.select) ...[
                        Text(
                          '${_selectedIds.length} businesses selected',
                          style: const TextStyle(
                            color: _Tok.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...businesses.map((b) => _SelectTile(
                              business: b,
                              selected: _selectedIds.contains(b.businessId),
                              onChanged: (sel) {
                                setState(() {
                                  if (sel) {
                                    if (!_selectedIds.contains(b.businessId)) {
                                      _selectedIds.add(b.businessId);
                                    }
                                  } else {
                                    _selectedIds.remove(b.businessId);
                                  }
                                });
                              },
                            )),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Optional title',
                          hintText: 'Businesses You May Like',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 120,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Optional note',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _sharing
                              ? null
                              : () => _createAndShare(businesses),
                          style: FilledButton.styleFrom(
                            backgroundColor: _Tok.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _mode == _ShareMode.select && _selectedIds.isNotEmpty
                                ? 'Share ${_selectedIds.length} Businesses'
                                : 'Share Favorites',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAndShare(List<BusinessDto> all) async {
    if (_mode == _ShareMode.select && _selectedIds.isEmpty) {
      AppFeedback.showWarning(context, 'Select at least one business.');
      return;
    }

    setState(() => _sharing = true);
    try {
      final repo = ref.read(shareRepositoryProvider);
      final result = await repo.createFavoritesShare(
        shareAllFavorites: _mode == _ShareMode.all,
        businessIds:
            _mode == _ShareMode.select ? List<int>.from(_selectedIds) : null,
        title: _titleCtrl.text,
        note: _noteCtrl.text,
      );

      final link = BusinessShareHelper.linkForCreated(result);
      final message = BusinessShareHelper.buildCollectionMessage(
        shareUrl: link,
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (!mounted) return;
      await showShareActionsSheet(context, message: message, link: link);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrorFormatter.format(e));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

}

class _SelectTile extends StatelessWidget {
  final BusinessDto business;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _SelectTile({
    required this.business,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      activeColor: _Tok.primary,
      title: Text(
        business.businessName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (business.categoryName ?? '').isNotEmpty
          ? Text(business.categoryName!)
          : null,
      onChanged: (v) => onChanged(v ?? false),
    );
  }
}
