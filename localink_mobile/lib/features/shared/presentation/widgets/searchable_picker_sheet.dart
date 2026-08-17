import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class SearchablePickerItem<T> {
  const SearchablePickerItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    String? searchText,
  }) : searchText = searchText ?? label;

  final T value;
  final String label;
  final String? subtitle;
  final String? leading;
  final String searchText;
}

/// Searchable bottom sheet with client-side filtering and lazy list rendering.
Future<SearchablePickerItem<T>?> showSearchablePickerSheet<T>({
  required BuildContext context,
  required String title,
  required String searchHint,
  required List<SearchablePickerItem<T>> items,
  T? selected,
  String emptyMessage = 'No results found',
  int pageSize = 40,
}) {
  return showModalBottomSheet<SearchablePickerItem<T>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _SearchablePickerSheet<T>(
        title: title,
        searchHint: searchHint,
        items: items,
        selected: selected,
        emptyMessage: emptyMessage,
        pageSize: pageSize,
      );
    },
  );
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  const _SearchablePickerSheet({
    required this.title,
    required this.searchHint,
    required this.items,
    required this.selected,
    required this.emptyMessage,
    required this.pageSize,
  });

  final String title;
  final String searchHint;
  final List<SearchablePickerItem<T>> items;
  final T? selected;
  final String emptyMessage;
  final int pageSize;

  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;
  String _query = '';
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _visibleCount = widget.pageSize;
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<SearchablePickerItem<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((item) => item.searchText.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<SearchablePickerItem<T>> get _visible {
    final filtered = _filtered;
    if (_visibleCount >= filtered.length) return filtered;
    return filtered.take(_visibleCount).toList(growable: false);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _visibleCount = widget.pageSize;
      });
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0);
      }
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 160) {
      final filteredLen = _filtered.length;
      if (_visibleCount < filteredLen) {
        setState(() {
          _visibleCount = (_visibleCount + widget.pageSize).clamp(0, filteredLen);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final maxHeight = mq.size.height * 0.82;
    final visible = _visible;
    final filteredLen = _filtered.length;
    final selected = widget.selected;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            minHeight: mq.size.height * 0.45,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(() {});
                        _onQueryChanged(value);
                      },
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onQueryChanged('');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filteredLen == 0
                          ? Center(
                              child: Text(
                                widget.emptyMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AppTheme.mutedTextColor,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollCtrl,
                              itemCount: visible.length +
                                  (visible.length < filteredLen ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= visible.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.accentColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final item = visible[index];
                                final isSelected = selected != null &&
                                    selected == item.value;
                                return ListTile(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(context).pop(item);
                                  },
                                  leading: item.leading == null
                                      ? null
                                      : SizedBox(
                                          width: 32,
                                          child: Text(
                                            item.leading!,
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                  title: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.accentColor
                                          : AppTheme.textColor,
                                    ),
                                  ),
                                  subtitle: item.subtitle == null
                                      ? null
                                      : Text(
                                          item.subtitle!,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AppTheme.mutedTextColor,
                                          ),
                                        ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: AppTheme.accentColor,
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
