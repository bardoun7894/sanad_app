import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../therapist_portal/models/therapist_profile.dart';
import 'global_search_dropdown.dart';

enum SearchResultType { patient, clinician, appointment }

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final String route;
  final Object? extra;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.route,
    this.extra,
  });
}

class GlobalSearchBar extends ConsumerStatefulWidget {
  final double width;
  final bool forceCompact;

  const GlobalSearchBar({
    super.key,
    this.width = 260,
    this.forceCompact = false,
  });

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showOverlay();
    } else if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final s = S(ref.read(languageProvider).language);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 360,
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: isRtl ? Alignment.bottomRight : Alignment.bottomLeft,
          followerAnchor: isRtl ? Alignment.topRight : Alignment.topLeft,
          offset: const Offset(0, 8),
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: SearchResultsDropdown(
              results: _results,
              isSearching: _isSearching,
              isDark: isDark,
              s: s,
              onResultTap: (result) {
                if (result.extra != null) {
                  context.go(result.route, extra: result.extra);
                } else {
                  context.go(result.route);
                }
                _removeOverlay();
                _searchController.clear();
                _focusNode.unfocus();
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);
    _showOverlay();

    _performSearch(query).then((searchResults) {
      if (!mounted) return;
      setState(() {
        _results = searchResults;
        _isSearching = false;
      });
      _showOverlay();
    });
  }

  Future<List<SearchResult>> _performSearch(String query) async {
    final lowerQuery = query.toLowerCase();
    final results = <SearchResult>[];

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .limit(5)
          .get();

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final email = (data['email'] as String? ?? '').toLowerCase();

        if (name.contains(lowerQuery) || email.contains(lowerQuery)) {
          results.add(
            SearchResult(
              id: doc.id,
              title: data['name'] ?? 'Unknown User',
              subtitle: data['email'] ?? 'No email',
              type: SearchResultType.patient,
              route: '/admin/users/${doc.id}',
            ),
          );
        }
      }

      final therapistsSnapshot = await FirebaseFirestore.instance
          .collection('therapists')
          .limit(5)
          .get();

      for (final doc in therapistsSnapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final title = (data['title'] as String? ?? '').toLowerCase();

        if (name.contains(lowerQuery) || title.contains(lowerQuery)) {
          final therapistProfile = TherapistProfile.fromFirestore(doc);
          results.add(
            SearchResult(
              id: doc.id,
              title: data['name'] ?? 'Unknown Therapist',
              subtitle: data['title'] ?? 'Therapist',
              type: SearchResultType.clinician,
              route: '/admin/therapists/detail',
              extra: therapistProfile,
            ),
          );
        }
      }

      return results.take(6).toList();
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AdminResponsive.isMobile(context);

    if (isMobile || widget.forceCompact) {
      return IconButton(
        onPressed: () => _openMobileSearch(context),
        icon: Icon(
          Icons.search_rounded,
          size: 21,
          color: isDark
              ? AppColors.adminTextSecondary
              : AppColors.textSecondary,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: widget.width,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.adminGlass.withValues(alpha: 0.5)
              : const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.adminBorder : const Color(0xFFE2E8F0),
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? AppColors.adminTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: S(
              ref.watch(languageProvider).language,
            ).searchUsersCliniciansDot,
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 19,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _removeOverlay();
                      setState(() {
                        _results = [];
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ),
    );
  }

  void _openMobileSearch(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.read(languageProvider).language);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MobileSearchSheet(
        isDark: isDark,
        s: s,
        onResultTap: (result) {
          Navigator.pop(sheetContext);
          if (result.extra != null) {
            context.go(result.route, extra: result.extra);
          } else {
            context.go(result.route);
          }
        },
      ),
    );
  }
}
