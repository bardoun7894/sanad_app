import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../therapist_portal/models/therapist_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/utils/responsive.dart';

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
  const GlobalSearchBar({super.key});

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
    final isDark = false;
    final s = S(ref.read(languageProvider).language);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 50),
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: _SearchResultsDropdown(
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

    // Executing search...
    _performSearch(query).then((searchResults) {
      if (!mounted) return;
      setState(() {
        _results = searchResults;
        _isSearching = false;
      });
      _showOverlay(); // Update results
    });
  }

  Future<List<SearchResult>> _performSearch(String query) async {
    final lowerQuery = query.toLowerCase();
    final results = <SearchResult>[];

    try {
      // 1. Search Users (Clients)
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .limit(5)
          .get();

      // Client-side filtering as Firestore doesn't support startsWith well freely
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

      // 2. Search Clinicians (Therapists)
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
    final isDark = false;
    final isMobile = AdminResponsive.isMobile(context);

    // On mobile: show a compact search icon that opens a modal search
    if (isMobile) {
      return IconButton(
        onPressed: () => _openMobileSearch(context),
        icon: Icon(
          Icons.search_rounded,
          size: 22,
          color: isDark
              ? AppColors.adminTextSecondary
              : AppColors.textSecondary,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      );
    }

    // Desktop / Tablet: inline search bar
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: 280,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.adminGlass.withValues(alpha: 0.5)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.border,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.adminTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: S(
              ref.watch(languageProvider).language,
            ).searchUsersCliniciansDot,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
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
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  /// Opens a full-screen modal search on mobile devices.
  void _openMobileSearch(BuildContext context) {
    final isDark = false;
    final s = S(ref.read(languageProvider).language);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MobileSearchSheet(
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

class _SearchResultsDropdown extends StatelessWidget {
  final List<SearchResult> results;
  final bool isSearching;
  final bool isDark;
  final S s;
  final Function(SearchResult) onResultTap;

  const _SearchResultsDropdown({
    required this.results,
    required this.isSearching,
    required this.isDark,
    required this.s,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isSearching
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  s.noResultsFound,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 56,
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
              itemBuilder: (context, index) {
                final result = results[index];
                return _SearchResultItem(
                  result: result,
                  isDark: isDark,
                  s: s,
                  onTap: () => onResultTap(result),
                );
              },
            ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final SearchResult result;
  final bool isDark;
  final S s;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.result,
    required this.isDark,
    required this.s,
    required this.onTap,
  });

  IconData get _icon {
    switch (result.type) {
      case SearchResultType.patient:
        return Icons.person_rounded;
      case SearchResultType.clinician:
        return Icons.medical_services_rounded;
      case SearchResultType.appointment:
        return Icons.calendar_today_rounded;
    }
  }

  Color get _iconColor {
    switch (result.type) {
      case SearchResultType.patient:
        return AppColors.primary;
      case SearchResultType.clinician:
        return AppColors.success;
      case SearchResultType.appointment:
        return AppColors.warning;
    }
  }

  String get _typeLabel {
    switch (result.type) {
      case SearchResultType.patient:
        return s.labelPatient;
      case SearchResultType.clinician:
        return s.labelClinician;
      case SearchResultType.appointment:
        return s.labelAppointment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon, size: 18, color: _iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.adminTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen bottom sheet search for mobile devices.
class _MobileSearchSheet extends StatefulWidget {
  final bool isDark;
  final S s;
  final Function(SearchResult) onResultTap;

  const _MobileSearchSheet({
    required this.isDark,
    required this.s,
    required this.onResultTap,
  });

  @override
  State<_MobileSearchSheet> createState() => _MobileSearchSheetState();
}

class _MobileSearchSheetState extends State<_MobileSearchSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

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
    } catch (e) {
      debugPrint('Mobile search error: $e');
    }

    if (!mounted) return;
    setState(() {
      _results = results.take(6).toList();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.5)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.border,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontSize: 16,
                  color: widget.isDark
                      ? AppColors.adminTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.s.searchUsersCliniciansDot,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: widget.isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: widget.isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: widget.isDark
                                ? AppColors.adminTextSecondary
                                : AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _results = []);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: widget.isDark ? AppColors.borderDark : AppColors.border,
          ),
          // Results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.isEmpty
                          ? widget.s.searchUsersCliniciansDot
                          : widget.s.noResultsFound,
                      style: TextStyle(
                        color: widget.isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 56,
                      color: widget.isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return _SearchResultItem(
                        result: result,
                        isDark: widget.isDark,
                        s: widget.s,
                        onTap: () => widget.onResultTap(result),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
