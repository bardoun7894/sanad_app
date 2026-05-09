import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_users_provider.dart';
import '../../therapists/providers/therapist_assignment_provider.dart';
import '../../auth/providers/auth_provider.dart';

// ── Pure-Dart helpers (top-level so they are unit-testable) ─────────────────

/// Returns [unblockLabel] when user is blocked, [blockLabel] otherwise.
String blockButtonLabel({
  required bool isBlocked,
  required String blockLabel,
  required String unblockLabel,
}) =>
    isBlocked ? unblockLabel : blockLabel;

/// Returns the icon for the block/unblock toggle button.
IconData blockButtonIcon({required bool isBlocked}) =>
    isBlocked ? Icons.lock_open_rounded : Icons.block_rounded;

// ────────────────────────────────────────────────────────────────────────────

class ClinicPatientProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  /// True when an admin is viewing (full powers: block, delete, generate
  /// report, delete mood entries, assign therapist). False for the therapist
  /// portal — read-only view of the same screen with admin actions hidden.
  final bool isAdminView;

  const ClinicPatientProfileScreen({
    super.key,
    required this.userId,
    this.isAdminView = true,
  });

  @override
  ConsumerState<ClinicPatientProfileScreen> createState() =>
      _ClinicPatientProfileScreenState();
}

class _ClinicPatientProfileScreenState
    extends ConsumerState<ClinicPatientProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Memoised so the FutureBuilder doesn't re-fire on every StreamBuilder rebuild.
  late final Future<Map<String, dynamic>> _insightsFuture;
  String? _selectedTherapistId;
  bool _isAssigningTherapist = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _insightsFuture = _fetchInsights();
  }

  Future<Map<String, dynamic>> _fetchInsights() async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('analyzeUserPatterns');
    final result = await callable.call({'userId': widget.userId});
    final data = result.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<void> _assignTherapist({
    required String userId,
    required String therapistId,
    required String therapistName,
    String? currentTherapistId,
    required String userName,
    String? userPhotoUrl,
    String? therapistPhotoUrl,
  }) async {
    setState(() => _isAssigningTherapist = true);
    try {
      final currentAdmin = ref.read(authProvider).user;
      final result = await ref
          .read(therapistAssignmentProvider.notifier)
          .assignTherapist(
            userId: userId,
            therapistId: therapistId,
            therapistName: therapistName,
            therapistPhotoUrl: therapistPhotoUrl,
            actorUid: currentAdmin?.uid ?? 'admin',
            actorName: currentAdmin?.displayName ?? 'Admin',
            triggeredBy: 'admin',
          );

      if (!mounted) return;
      setState(() {
        _selectedTherapistId = null;
        _isAssigningTherapist = false;
      });
      switch (result) {
        case AssignmentSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${ref.read(stringsProvider).assignedTherapistSuccess}: $therapistName',
              ),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        case AssignmentValidationError(:final reason):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${ref.read(stringsProvider).assignLabel} failed: $reason',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        case AssignmentPartialSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Assigned, but chat creation failed — will recover on first open',
              ),
              backgroundColor: Colors.amber,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigningTherapist = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${ref.read(stringsProvider).assignLabel} failed: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeTherapistAssignment(String userId) async {
    setState(() => _isAssigningTherapist = true);
    try {
      final currentAdmin = ref.read(authProvider).user;
      final result = await ref
          .read(therapistAssignmentProvider.notifier)
          .unassignTherapist(
            userId: userId,
            actorUid: currentAdmin?.uid ?? 'admin',
            actorName: currentAdmin?.displayName ?? 'Admin',
            triggeredBy: 'admin',
          );

      if (!mounted) return;
      setState(() {
        _selectedTherapistId = null;
        _isAssigningTherapist = false;
      });
      switch (result) {
        case AssignmentSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(stringsProvider).removeTherapistSuccess),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        case AssignmentValidationError(:final reason):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Remove failed: $reason'),
              backgroundColor: AppColors.error,
            ),
          );
        case AssignmentPartialSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unassigned, but archiving the chat failed',
              ),
              backgroundColor: Colors.amber,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigningTherapist = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Remove failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading user data...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          final s = ref.read(stringsProvider);
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userName =
              userData['name'] ?? userData['display_name'] ?? 'Unknown User';
          final userEmail = userData['email'] ?? 'No email';
          final isPremium = userData['is_premium'] == true;
          final isBlocked = userData['is_blocked'] == true;
          final createdAt = userData['created_at'] as Timestamp?;
          final joinDate = createdAt != null
              ? DateFormat('MMM yyyy').format(createdAt.toDate())
              : 'Unknown';

          return Column(
            children: [
              // Header with user info
              _buildHeader(
                context,
                isDark,
                userName,
                userEmail,
                isPremium,
                isBlocked,
                joinDate,
              ),

              // Therapist assignment card (admin only — therapists can't
              // reassign their own clients to a different therapist).
              if (widget.isAdminView)
                _buildTherapistAssignmentCard(
                  isDark: isDark,
                  userData: userData,
                  userName: userName,
                  s: s,
                ),

              const SizedBox(height: 8),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.adminBorder
                          : AppColors.borderLight,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  tabs: const [
                    Text('Appointments'),
                    Text('Clinical Notes'),
                    Text('Mood Tracker'),
                    Text('Overview'),
                    Text('AI Insights'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentsTab(isDark),
                    _buildNotesTab(isDark),
                    _buildMoodTab(isDark),
                    _buildOverviewTab(isDark, userData),
                    _buildInsightsTab(isDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    String userName,
    String userEmail,
    bool isPremium,
    bool isBlocked,
    String joinDate,
  ) {
    final initials = userName.isNotEmpty
        ? userName
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.adminSurface : Colors.white,
              foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 24),
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isPremium)
                      _StatusBadge(
                        label: 'Premium',
                        color: AppColors.statusSuccess,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${widget.userId.length > 20 ? '${widget.userId.substring(0, 20)}...' : widget.userId} • Joined $joinDate',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to chat with this user
                  context.go('/admin/chat');
                },
                icon: const Icon(Icons.message_outlined, size: 18),
                label: const Text('Message'),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              if (widget.isAdminView)
                ElevatedButton.icon(
                  onPressed: () => _generateReport(context),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(ref.read(stringsProvider).generateReport),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                ),
              // Block / Unblock button (admin only)
              if (widget.isAdminView)
                ElevatedButton.icon(
                  onPressed: () =>
                      _confirmBlockUser(context, isBlocked, userName),
                  icon: Icon(blockButtonIcon(isBlocked: isBlocked), size: 18),
                  label: Text(
                    blockButtonLabel(
                      isBlocked: isBlocked,
                      blockLabel: ref.read(stringsProvider).blockUser,
                      unblockLabel: ref.read(stringsProvider).unblockUser,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                ),
              // Delete button (admin only)
              if (widget.isAdminView)
                ElevatedButton.icon(
                  onPressed: () => _confirmDeleteUser(context, userName),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: Text(ref.read(stringsProvider).deleteUser),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTherapistAssignmentCard({
    required bool isDark,
    required Map<String, dynamic> userData,
    required String userName,
    required dynamic s,
  }) {
    final currentTherapistId = userData['assigned_therapist_id'] as String?;
    final currentTherapistName =
        userData['assigned_therapist_name'] as String?;
    final userPhotoUrl = userData['photo_url'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 0,
        color: isDark
            ? AppColors.adminSurface
            : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.assignedTherapist,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  if (currentTherapistName != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentTherapistName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              ref.watch(approvedTherapistsProvider).when(
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => Text(
                  s.failedLoadTherapists,
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
                data: (therapists) {
                  if (therapists.isEmpty) {
                    return Text(
                      s.noApprovedTherapists,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 13,
                      ),
                    );
                  }

                  final selectedId = _selectedTherapistId ?? currentTherapistId;

                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('therapist_dropdown_${currentTherapistId ?? "none"}'),
                          initialValue: selectedId != null &&
                                  therapists.any(
                                    (t) => t['id'] == selectedId,
                                  )
                              ? selectedId
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: s.selectTherapist,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade50,
                          ),
                          items: therapists.map((t) {
                            final id = t['id'] as String? ?? '';
                            final name = t['name'] as String? ?? 'Unknown';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedTherapistId = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: (_selectedTherapistId == null ||
                                  _isAssigningTherapist)
                              ? null
                              : () {
                                  final therapist = therapists
                                      .cast<Map<String, dynamic>>()
                                      .firstWhere(
                                        (t) =>
                                            t['id'] == _selectedTherapistId,
                                      );
                                  _assignTherapist(
                                    userId: widget.userId,
                                    therapistId: _selectedTherapistId!,
                                    therapistName:
                                        therapist['name'] as String? ??
                                            'Therapist',
                                    currentTherapistId: currentTherapistId,
                                    userName: userName,
                                    userPhotoUrl: userPhotoUrl,
                                    therapistPhotoUrl:
                                        therapist['photo_url'] as String?,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isAssigningTherapist
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  currentTherapistId != null
                              ? s.changeLabel
                              : s.assignLabel,
                                ),
                        ),
                      ),
                      if (currentTherapistId != null) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: _isAssigningTherapist
                                ? null
                                : () => _removeTherapistAssignment(
                                      widget.userId,
                                    ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(s.removeLabel),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark, Map<String, dynamic> userData) {
    final subscriptionPlan = userData['subscription_plan'] ?? 'Free';
    final subscriptionExpiry =
        userData['subscription_expiry_date'] as Timestamp?;
    final phone = userData['phone'] ?? 'Not provided';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column (Activity)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _SectionCard(
                  title: 'Recent Activity',
                  isDark: isDark,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('user_id', isEqualTo: widget.userId)
                        .orderBy('created_at', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return SizedBox(
                          height: 100,
                          child: Center(
                            child: Text(
                              'No recent activity',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'unknown';
                          final createdAt = data['created_at'] as Timestamp?;
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              _getStatusIcon(status),
                              color: _getStatusColor(status),
                              size: 20,
                            ),
                            title: Text(
                              'Booking - ${status.toString().toUpperCase()}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              createdAt != null
                                  ? DateFormat(
                                      'MMM d, yyyy',
                                    ).format(createdAt.toDate())
                                  : 'Unknown date',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Subscription Details',
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan: $subscriptionPlan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (subscriptionExpiry != null)
                                  Text(
                                    'Expires: ${DateFormat('MMM d, yyyy').format(subscriptionExpiry.toDate())}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.adminTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  )
                                else
                                  Text(
                                    'No active subscription',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.adminTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showSubscriptionDialog(subscriptionPlan),
                            icon: const Icon(
                                Icons.card_membership_rounded,
                                size: 16),
                            label: const Text('Manage'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column (Contact Info)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _SectionCard(
                  title: 'Contact Information',
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            phone,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Account Status',
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 16,
                            color: userData['email_verified'] == true
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userData['email_verified'] == true
                                ? 'Email Verified'
                                : 'Email Not Verified',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.event_available;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Mood entries are stored as a subcollection under each user document:
  // users/{userId}/mood_entries/{entryId}, with fields { mood: int (MoodType
  // index), date: Timestamp, note: String? }. The mobile app writes here; the
  // admin reads + can delete entries (rules already allow it).
  static const _moodLabels = [
    'Happy', // 0
    'Calm', // 1
    'Anxious', // 2
    'Sad', // 3
    'Angry', // 4
    'Tired', // 5
  ];
  static const _moodEmojis = ['😊', '😌', '😰', '😢', '😠', '😴'];

  Widget _buildMoodTab(bool isDark) {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('mood_entries');

    return Column(
      children: [
        // ── "Generate AI Report" convenience button ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _generateReport(context),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Generate AI Report from Mood History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  textStyle: const TextStyle(fontSize: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Mood entries list ────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: col.orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load mood entries: ${snapshot.error}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No mood entries yet',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45),
                  ),
                );
              }
              return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final moodIdx = (data['mood'] as num?)?.toInt() ?? -1;
            final note = (data['note'] as String?)?.trim() ?? '';
            final ts = data['date'] as Timestamp?;
            final emoji = (moodIdx >= 0 && moodIdx < _moodEmojis.length)
                ? _moodEmojis[moodIdx]
                : '😐';
            final label = (moodIdx >= 0 && moodIdx < _moodLabels.length)
                ? _moodLabels[moodIdx]
                : 'Unknown';
            final dateStr = ts != null
                ? DateFormat('MMM d, yyyy — HH:mm').format(ts.toDate())
                : 'Unknown date';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(emoji, style: const TextStyle(fontSize: 28)),
              title: Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: widget.isAdminView
                  ? IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      tooltip: 'Delete entry',
                      onPressed: () =>
                          _confirmDeleteMood(doc.reference, label),
                    )
                  : null,
            );
          },
        );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteMood(
    DocumentReference ref,
    String label,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete mood entry'),
        content: Text('Delete "$label" entry? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood entry deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSubscriptionDialog(String currentPlan) {
    const plans = ['Free', 'Basic', 'Premium'];
    String selectedPlan = plans.contains(currentPlan) ? currentPlan : 'Free';
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Manage Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Plan',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPlan,
                items: plans
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedPlan = v!),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              if (selectedPlan != 'Free') ...[
                const SizedBox(height: 16),
                const Text('Expiry Date',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expiryDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) {
                      setDialogState(() => expiryDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    expiryDate != null
                        ? DateFormat('MMM d, yyyy').format(expiryDate!)
                        : 'Pick expiry date',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              onPressed: () async {
                final Map<String, dynamic> update = {
                  'subscription_plan': selectedPlan,
                  'is_premium': selectedPlan != 'Free',
                };
                if (selectedPlan != 'Free' && expiryDate != null) {
                  update['subscription_expiry_date'] =
                      Timestamp.fromDate(expiryDate!);
                } else if (selectedPlan == 'Free') {
                  update['subscription_expiry_date'] = null;
                }
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .update(update);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Subscription updated to $selectedPlan'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Generate Full Report
  // ---------------------------------------------------------------------------

  Future<void> _generateReport(BuildContext ctx) async {
    final s = ref.read(stringsProvider);
    final languageState = ref.read(languageProvider);
    final locale = languageState.locale.languageCode; // 'ar', 'en', or 'fr'

    if (!ctx.mounted) return;
    showModalBottomSheet<void>(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                s.reportGenerating,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('generateUserReport');
      await callable.call({
        'userId': widget.userId,
        'locale': locale,
      });

      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      ctx.push(
        '${AppRoutes.adminPatientReports}?userId=${widget.userId}',
      );
    } catch (e) {
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Block / Unblock user
  // ---------------------------------------------------------------------------

  Future<void> _confirmBlockUser(
    BuildContext ctx,
    bool isBlocked,
    String userName,
  ) async {
    final s = ref.read(stringsProvider);
    final confirmText =
        isBlocked ? s.unblockUserConfirm : s.blockUserConfirm;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isBlocked ? s.unblockUser : s.blockUser),
        content: Text(confirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: Text(isBlocked ? s.unblockUser : s.blockUser),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('setUserBlocked');
      await callable.call({
        'userId': widget.userId,
        'blocked': !isBlocked,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBlocked ? s.userUnblocked : s.userBlocked),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Delete user
  // ---------------------------------------------------------------------------

  Future<void> _confirmDeleteUser(
    BuildContext ctx,
    String userName,
  ) async {
    final s = ref.read(stringsProvider);
    bool understood = false;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(s.deleteUser),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.deleteUserConfirm),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: understood,
                    activeColor: AppColors.error,
                    onChanged: (v) =>
                        setDialogState(() => understood = v ?? false),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.iUnderstand)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(s.cancel),
            ),
            ElevatedButton(
              onPressed: understood
                  ? () => Navigator.of(dialogCtx).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(s.deleteUser),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    // Capture messenger before the async gap / pop
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show progress dialog
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.error),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                s.deleting,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteUserAccount');
      await callable.call({'userId': widget.userId});

      if (!mounted) return;
      navigator.pop(); // dismiss progress sheet
      navigator.pop(); // pop this profile screen

      messenger.showSnackBar(
        SnackBar(
          content: Text(s.userDeleted),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop(); // dismiss progress sheet
      messenger.showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AI Insights Tab
  // ---------------------------------------------------------------------------

  Widget _buildInsightsTab(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load AI insights. Please try again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return _buildInsightsEmpty(isDark);
        }
        return _buildInsightsData(isDark, data);
      },
    );
  }

  Widget _buildInsightsEmpty(bool isDark) {
    final s = ref.read(stringsProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              s.noPatternsYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsData(bool isDark, Map<String, dynamic> data) {
    final s = ref.read(stringsProvider);
    final trend = data['trend'] as String? ?? 'stable';
    final dominantMood = data['dominantMood'] as String? ?? '';
    final lowStreak = (data['lowStreak'] as num?)?.toInt() ?? 0;
    final weekendDip = data['weekendDip'] as bool? ?? false;
    final noteThemes =
        (data['noteThemes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final anomalies =
        (data['anomalies'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final riskLevel = data['riskLevel'] as String? ?? 'low';

    // Extended pattern fields
    final timeOfDayRaw = data['timeOfDay'] as Map<String, dynamic>?;
    final dayOfWeekRaw = data['dayOfWeek'] as Map<String, dynamic>?;
    final testTrajectoryRaw =
        (data['testTrajectory'] as List?)?.cast<Map<String, dynamic>>();
    final bookingImpactRaw = data['bookingImpact'] as Map<String, dynamic>?;
    final contentEngagementRaw =
        data['contentEngagement'] as Map<String, dynamic>?;
    final loggingGap = (data['loggingGap'] as num?)?.toInt() ?? 0;
    final noteSentimentRaw = data['noteSentiment'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Existing chips (unchanged)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InsightsChip(
                label: _insightTrendLabel(trend, s),
                icon: _insightTrendIcon(trend),
                color: _insightTrendColor(trend),
                isDark: isDark,
              ),
              _InsightsChip(
                label: 'Risk: $riskLevel',
                icon: Icons.shield_outlined,
                color: _insightRiskColor(riskLevel),
                isDark: isDark,
              ),
              if (dominantMood.isNotEmpty)
                _InsightsChip(
                  label:
                      '${s.dominantMood}: ${_insightMoodEmoji(dominantMood)} $dominantMood',
                  icon: Icons.mood_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              if (lowStreak > 0)
                _InsightsChip(
                  label: '${s.lowStreakDays}: $lowStreak',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              if (weekendDip)
                _InsightsChip(
                  label: s.weekendDip,
                  icon: Icons.weekend_rounded,
                  color: AppColors.statusWarning,
                  isDark: isDark,
                ),
              ...noteThemes.map(
                (theme) => _InsightsChip(
                  label: theme,
                  icon: Icons.label_outline_rounded,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  isDark: isDark,
                ),
              ),
              ...anomalies.map(
                (anomaly) => _InsightsChip(
                  label: anomaly,
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          // ── Extended sections (additive) ─────────────────────────────

          // Time of day
          if (timeOfDayRaw != null) ...[
            const SizedBox(height: 24),
            _ClinicSectionHeader(label: s.timeOfDay, isDark: isDark),
            const SizedBox(height: 8),
            _ClinicPatternCard(
              isDark: isDark,
              child: _ClinicTimeOfDayBars(
                data: timeOfDayRaw,
                s: s,
                isDark: isDark,
              ),
            ),
          ],

          // Day of week heatmap
          if (dayOfWeekRaw != null) ...[
            const SizedBox(height: 16),
            _ClinicSectionHeader(label: s.dayOfWeek, isDark: isDark),
            const SizedBox(height: 8),
            _ClinicPatternCard(
              isDark: isDark,
              child: _ClinicDayOfWeekHeatmap(
                data: dayOfWeekRaw,
                isDark: isDark,
              ),
            ),
          ],

          // Test trajectory
          if (testTrajectoryRaw != null && testTrajectoryRaw.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ClinicSectionHeader(label: s.testTrajectory, isDark: isDark),
            const SizedBox(height: 8),
            _ClinicPatternCard(
              isDark: isDark,
              child: Column(
                children: testTrajectoryRaw.map((item) {
                  final testType = item['testType'] as String? ?? '—';
                  final lastScore = item['lastScore'];
                  final direction = item['direction'] as String? ?? 'stable';
                  final slope = item['slope'];

                  final directionIcon = direction == 'up'
                      ? Icons.trending_up_rounded
                      : direction == 'down'
                          ? Icons.trending_down_rounded
                          : Icons.trending_flat_rounded;
                  final directionColor = direction == 'up'
                      ? AppColors.success
                      : direction == 'down'
                          ? AppColors.error
                          : AppColors.warning;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(directionIcon, color: directionColor),
                    title: Text(
                      testType,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Text(
                      lastScore != null
                          ? '${lastScore.toString()} (slope: ${slope ?? "—"})'
                          : '—',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Booking impact
          if (bookingImpactRaw != null) ...[
            const SizedBox(height: 16),
            _ClinicSectionHeader(label: s.bookingImpact, isDark: isDark),
            const SizedBox(height: 8),
            _ClinicPatternCard(
              isDark: isDark,
              child: _ClinicBookingImpactCard(
                data: bookingImpactRaw,
                s: s,
                isDark: isDark,
              ),
            ),
          ],

          // Content engagement
          if (contentEngagementRaw != null) ...[
            const SizedBox(height: 16),
            _ClinicSectionHeader(label: s.contentEngagement, isDark: isDark),
            const SizedBox(height: 8),
            _ClinicPatternCard(
              isDark: isDark,
              child: _ClinicContentEngagementCard(
                data: contentEngagementRaw,
                isDark: isDark,
              ),
            ),
          ],

          // Logging gap
          if (loggingGap > 5) ...[
            const SizedBox(height: 16),
            _ClinicPatternCard(
              isDark: isDark,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$loggingGap ${s.days} — ${s.loggingGap.toLowerCase()}',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Note sentiment
          if (noteSentimentRaw != null) ...[
            const SizedBox(height: 16),
            _ClinicSectionHeader(label: s.noteSentiment, isDark: isDark),
            const SizedBox(height: 8),
            _ClinicPatternCard(
              isDark: isDark,
              child: _ClinicNoteSentimentBars(
                data: noteSentimentRaw,
                isDark: isDark,
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _insightTrendLabel(String trend, dynamic s) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return s.trendImproving as String;
      case 'declining':
        return s.trendDeclining as String;
      default:
        return s.trendStable as String;
    }
  }

  IconData _insightTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up_rounded;
      case 'declining':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color _insightTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return AppColors.success;
      case 'declining':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Color _insightRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  String _insightMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'calm':
        return '😌';
      case 'anxious':
        return '😰';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'tired':
        return '😴';
      default:
        return '😐';
    }
  }

  Widget _buildNotesTab(bool isDark) {
    return Center(
      child: Text(
        'Clinical notes feature coming soon',
        style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
      ),
    );
  }

  Widget _buildAppointmentsTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('user_id', isEqualTo: widget.userId)
          .orderBy('scheduled_time', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No appointments found',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'unknown';
            final scheduledTime = data['scheduled_time'] as Timestamp?;
            final therapistName = data['therapist_name'] ?? 'Unknown therapist';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
              ),
              title: Text(
                therapistName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                scheduledTime != null
                    ? DateFormat(
                        'MMM d, yyyy - h:mm a',
                      ).format(scheduledTime.toDate())
                    : 'Unknown date',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              trailing: _StatusBadge(
                label: status,
                color: _getStatusColor(status),
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InsightsChip — colored chip used in the AI Insights tab
// ---------------------------------------------------------------------------
class _InsightsChip extends StatelessWidget {
  const _InsightsChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clinic extended pattern widgets ─────────────────────────────────────────

const _kClinicMoodEmojis = {
  0: '😊',
  1: '😌',
  2: '😰',
  3: '😢',
  4: '😠',
  5: '😴',
};

Color _clinicMoodColor(int? v) {
  switch (v) {
    case 0:
      return AppColors.success;
    case 1:
      return const Color(0xFF6EC6CA);
    case 2:
      return AppColors.warning;
    case 3:
      return const Color(0xFF90A4AE);
    case 4:
      return AppColors.error;
    case 5:
      return const Color(0xFFB39DDB);
    default:
      return AppColors.borderLight;
  }
}

class _ClinicSectionHeader extends StatelessWidget {
  const _ClinicSectionHeader({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ClinicPatternCard extends StatelessWidget {
  const _ClinicPatternCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.35)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}

class _ClinicTimeOfDayBars extends StatelessWidget {
  const _ClinicTimeOfDayBars({
    required this.data,
    required this.s,
    required this.isDark,
  });

  final Map<String, dynamic> data;
  final dynamic s;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final slots = [
      (s.morning as String, data['morning']),
      (s.afternoon as String, data['afternoon']),
      (s.evening as String, data['evening']),
      (s.night as String, data['night']),
    ];
    final maxVal = slots
        .map((e) => (e.$2 as num?)?.toDouble() ?? 0.0)
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: slots.map((slot) {
        final label = slot.$1;
        final val = (slot.$2 as num?)?.toInt();
        final frac = (maxVal > 0 && val != null) ? val / maxVal : 0.0;
        final emoji = _kClinicMoodEmojis[val] ?? '—';
        final barColor = _clinicMoodColor(val);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: frac.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(val != null ? emoji : '—',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ClinicDayOfWeekHeatmap extends StatelessWidget {
  const _ClinicDayOfWeekHeatmap({required this.data, required this.isDark});

  final Map<String, dynamic> data;
  final bool isDark;

  static const _keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(_keys.length, (i) {
        final val = (data[_keys[i]] as num?)?.toInt();
        final color = _clinicMoodColor(val);
        return Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: val != null
                    ? color.withValues(alpha: 0.8)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                shape: BoxShape.circle,
              ),
              child: val != null
                  ? Center(
                      child: Text(
                        _kClinicMoodEmojis[val] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 3),
            Text(
              _labels[i],
              style: TextStyle(
                color: isDark ? Colors.white38 : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ClinicBookingImpactCard extends StatelessWidget {
  const _ClinicBookingImpactCard({
    required this.data,
    required this.s,
    required this.isDark,
  });

  final Map<String, dynamic> data;
  final dynamic s;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final before = data['before'];
    final after = data['after'];
    final delta = (data['deltaMoodInt'] as num?)?.toInt();
    final sampleSize = (data['sampleSize'] as num?)?.toInt() ?? 0;

    final textStyle = TextStyle(
      color: isDark ? Colors.white : AppColors.textPrimary,
      fontSize: 14,
    );

    return Row(
      children: [
        Icon(Icons.event_available_rounded,
            color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Mood $before → $after'
            '${delta != null ? ' (Δ $delta)' : ''}'
            ', based on $sampleSize sessions',
            style: textStyle,
          ),
        ),
      ],
    );
  }
}

class _ClinicContentEngagementCard extends StatelessWidget {
  const _ClinicContentEngagementCard({
    required this.data,
    required this.isDark,
  });

  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final withEng = data['withEngagement'];
    final withoutEng = data['withoutEngagement'];
    final sampleSize = (data['sampleSize'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'After engagement: $withEng vs without: $withoutEng ($sampleSize samples)',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClinicNoteSentimentBars extends StatelessWidget {
  const _ClinicNoteSentimentBars({required this.data, required this.isDark});

  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final positive = (data['positive'] as num?)?.toInt() ?? 0;
    final negative = (data['negative'] as num?)?.toInt() ?? 0;
    final total = positive + negative;
    final posFrac = total > 0 ? (positive / total).clamp(0.0, 1.0) : 0.0;
    final negFrac = total > 0 ? (negative / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        _ClinicSentimentRow(
          emoji: '😊',
          fraction: posFrac,
          color: AppColors.success,
          count: positive,
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        _ClinicSentimentRow(
          emoji: '😢',
          fraction: negFrac,
          color: AppColors.error,
          count: negative,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ClinicSentimentRow extends StatelessWidget {
  const _ClinicSentimentRow({
    required this.emoji,
    required this.fraction,
    required this.color,
    required this.count,
    required this.isDark,
  });

  final String emoji;
  final double fraction;
  final Color color;
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: TextStyle(
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
