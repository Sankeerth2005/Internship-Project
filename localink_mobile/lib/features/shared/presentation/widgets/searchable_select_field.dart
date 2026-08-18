import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import 'searchable_picker_sheet.dart';

/// Single-border form field that opens a searchable picker sheet.
class SearchableSelectField<T> extends StatelessWidget {
  const SearchableSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.prefixIcon,
    this.enabled = true,
    this.loading = false,
    this.errorText,
    this.searchHint,
    this.emptyMessage = 'No results found',
    this.validator,
    this.displayBuilder,
  });

  final String label;
  final String hint;
  final List<SearchablePickerItem<T>> items;
  final T? selected;
  final ValueChanged<SearchablePickerItem<T>> onSelected;
  final IconData? prefixIcon;
  final bool enabled;
  final bool loading;
  final String? errorText;
  final String? searchHint;
  final String emptyMessage;
  final String? Function(T?)? validator;
  final String Function(T value)? displayBuilder;

  String get _display {
    if (selected == null) return hint;
    if (displayBuilder != null) return displayBuilder!(selected as T);
    for (final item in items) {
      if (item.value == selected) {
        final lead = item.leading;
        // Keep the closed field compact: subtitle belongs in the picker list.
        if (lead != null && lead.isNotEmpty) {
          return '$lead  ${item.label}';
        }
        return item.label;
      }
    }
    return selected.toString();
  }

  Future<void> _open(BuildContext context) async {
    if (!enabled || loading) return;
    HapticFeedback.selectionClick();
    final picked = await showSearchablePickerSheet<T>(
      context: context,
      title: label.replaceAll('*', '').trim(),
      searchHint: searchHint ?? 'Search ${label.replaceAll('*', '').trim().toLowerCase()}...',
      items: items,
      selected: selected,
      emptyMessage: emptyMessage,
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: ValueKey(selected),
      initialValue: selected,
      validator: (_) => validator?.call(selected),
      builder: (state) {
        final err = errorText ?? state.errorText;
        return InkWell(
          onTap: enabled && !loading ? () => _open(context) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InputDecorator(
            isEmpty: selected == null,
            decoration: InputDecoration(
              labelText: label,
              // Child already renders hint/value. hintText would paint on top
              // of that child and overlap the floating label when empty.
              floatingLabelBehavior: FloatingLabelBehavior.always,
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.fromLTRB(12, 18, 8, 14),
              errorText: err,
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(prefixIcon, color: AppTheme.accentColor, size: 20),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: enabled
                          ? AppTheme.mutedTextColor
                          : AppTheme.softMutedTextColor,
                    ),
              enabled: enabled && !loading,
            ),
            child: Text(
              _display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: selected == null
                    ? AppTheme.softMutedTextColor
                    : (enabled ? AppTheme.textColor : AppTheme.mutedTextColor),
              ),
            ),
          ),
        );
      },
    );
  }
}
