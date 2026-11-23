import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../therapist_portal/models/therapist_profile.dart';
import 'global_search_bar.dart';

class SearchResultsDropdown extends StatelessWidget {
  final List<SearchResult> results;
  final bool isSearching;
  final bool isDark;
  final S s;
  final ValueChanged<SearchResult> onResultTap;

  const SearchResultsDropdown({
    super.key,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
                color: isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1),
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
                    overflow: TextOverflow.ellipsis,
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
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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

/// Full-screen bottom sheet search for mobile & compact header viewports.
class MobileSearchSheet extends StatefulWidget {
  final bool isDark;
  final S s;
  final ValueChanged<SearchResult> onResultTap;

  const MobileSearchSheet({
    super.key,
    required this.isDark,
    required this.s,
    required this.onResultTap,
  });

  @override
  State<MobileSearchSheet> createState() => _MobileSearchSheetState();
}

class _MobileSearchSheetState extends State<MobileSearchSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.5)
                    : const Color(0xFFF4F7FA),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.adminBorder
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontSize: 15,
                  color: widget.isDark
                      ? AppColors.adminTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.s.searchUsersCliniciansDot,
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: widget.isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
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
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: widget.isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1),
          ),
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
                          ? AppColors.adminBorder
                          : const Color(0xFFE6ECF1),
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
