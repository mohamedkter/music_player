import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Search bar following the Studio design system.
///
/// - 2px solid border
/// - Purple focus border with 2px purple shadow offset
/// - Calls [onChanged] with debounce handled externally (in BLoC)
///
/// Usage:
/// ```dart
/// AppSearchBar(
///   hintText: 'ابحث عن موسيقى...',
///   onChanged: (q) => context.read<SearchBloc>().add(SearchQueryChanged(q)),
///   onClear: () => context.read<SearchBloc>().add(SearchCleared()),
/// )
/// ```
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.controller,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final TextEditingController? controller;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode()
      ..addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
    _controller.addListener(
      () => setState(() => _hasText = _controller.text.isNotEmpty),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.outline,
          width: 2,
        ),
        boxShadow: _isFocused
            ? [
                const BoxShadow(
                  color: AppColors.primary,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.md),
            child: Icon(Icons.search, size: 20, color: AppColors.outline),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.outline,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm + AppSpacing.xs,
                ),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onClear?.call();
              },
              child: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(Icons.close, size: 18, color: AppColors.outline),
              ),
            ),
        ],
      ),
    );
  }
}
