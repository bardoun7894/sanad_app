import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/admin_users_provider.dart';
import 'package:intl/intl.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final isDark = false;

    // Find the patient
    final patient = state.users.cast<AdminUser?>().firstWhere(
      (u) => u?.id == widget.patientId,
      orElse: () => null,
    );

    if (patient == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'Patient not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header with patient info
          _buildHeader(patient, isDark),

          // Tabs
          _buildTabs(isDark),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(patient: patient, isDark: isDark),
                _SessionsTab(patient: patient, isDark: isDark),
                _AssessmentsTab(patient: patient, isDark: isDark),
                _BillingTab(patient: patient, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AdminUser patient, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),

          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              (patient.displayName != null && patient.displayName!.isNotEmpty)
                  ? patient.displayName![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patient.displayName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RiskBadge(
                      level: _calculateRiskLevel(patient),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  patient.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              _ActionButton(
                icon: Icons.message_outlined,
                label: 'Message',
                isDark: isDark,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.calendar_today_outlined,
                label: 'Schedule',
                isDark: isDark,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? AppColors.adminSurface : Colors.white,
                onSelected: (value) {
                  // Handle action
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Row(
                      children: [
                        Icon(Icons.block_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Suspend Account'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
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
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Sessions'),
          Tab(text: 'Assessments'),
          Tab(text: 'Billing'),
        ],
      ),
    );
  }

  String _calculateRiskLevel(AdminUser patient) {
    // Simulated risk calculation
    if (patient.isPremium) return 'low';
    final daysSinceCreation = patient.createdAt != null
        ? DateTime.now().difference(patient.createdAt!).inDays
        : 0;
    if (daysSinceCreation < 7) return 'moderate';
    return 'low';
  }
}

// Overview Tab - Real Firestore Data
class _OverviewTab extends StatelessWidget {
  final AdminUser patient;
  final bool isDark;

  const _OverviewTab({required this.patient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row - Real Data
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserStats(),
            builder: (context, snapshot) {
              final stats =
                  snapshot.data ??
                  {'total': 0, 'completed': 0, 'cancelled': 0, 'balance': 0.0};

              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Sessions',
                      value: '${stats['total']}',
                      icon: Icons.video_camera_front_outlined,
                      color: AppColors.statusInfo,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Completed',
                      value: '${stats['completed']}',
                      icon: Icons.check_circle_outline,
                      color: AppColors.statusSuccess,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Cancelled',
                      value: '${stats['cancelled']}',
                      icon: Icons.cancel_outlined,
                      color: AppColors.statusDanger,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Balance',
                      value:
                          'SAR ${(stats['balance'] as double).toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.statusWarning,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Patient Info and Mood History Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info Card
              Expanded(
                flex: 2,
                child: _InfoCard(
                  title: 'Patient Information',
                  isDark: isDark,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Full Name',
                        value: patient.displayName ?? 'Unknown',
                        isDark: isDark,
                      ),
                      _InfoRow(
                        label: 'Email',
                        value: patient.email,
                        isDark: isDark,
                      ),
                      _InfoRow(
                        label: 'Phone',
                        value: patient.phoneNumber ?? 'Not provided',
                        isDark: isDark,
                      ),
                      _InfoRow(
                        label: 'Date of Birth',
                        value: patient.dateOfBirth != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(patient.dateOfBirth!)
                            : 'Not provided',
                        isDark: isDark,
                      ),
                      _InfoRow(
                        label: 'Joined',
                        value: patient.createdAt != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(patient.createdAt!)
                            : 'Unknown',
                        isDark: isDark,
                      ),
                      _InfoRow(
                        label: 'Subscription',
                        value: patient.isPremium ? 'Premium' : 'Free',
                        valueColor: patient.isPremium
                            ? AppColors.statusSuccess
                            : AppColors.textSecondary,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Mood History Card
              Expanded(
                flex: 3,
                child: _InfoCard(
                  title: 'Recent Mood History',
                  isDark: isDark,
                  child: _MoodHistoryChart(isDark: isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          _InfoCard(
            title: 'Recent Activity',
            isDark: isDark,
            child: _RecentActivityList(patient: patient, isDark: isDark),
          ),
        ],
      ),
    );
  }

  /// Fetches real stats from Firestore
  Future<Map<String, dynamic>> _fetchUserStats() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Get all bookings for this user
      final bookingsSnapshot = await firestore
          .collection('bookings')
          .where('user_id', isEqualTo: patient.id)
          .get();

      int total = bookingsSnapshot.docs.length;
      int completed = 0;
      int cancelled = 0;

      for (final doc in bookingsSnapshot.docs) {
        final status = doc.data()['status'] as String?;
        if (status == 'completed') completed++;
        if (status == 'cancelled' || status == 'canceled') cancelled++;
      }

      // Get payments balance (completed payments sum)
      final paymentsSnapshot = await firestore
          .collection('payments')
          .where('user_id', isEqualTo: patient.id)
          .where('status', isEqualTo: 'completed')
          .get();

      double balance = 0;
      for (final doc in paymentsSnapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount is num) balance += amount.toDouble();
      }

      return {
        'total': total,
        'completed': completed,
        'cancelled': cancelled,
        'balance': balance,
      };
    } catch (e) {
      return {'total': 0, 'completed': 0, 'cancelled': 0, 'balance': 0.0};
    }
  }
}

// Sessions Tab - Real Firestore Data
class _SessionsTab extends StatelessWidget {
  final AdminUser patient;
  final bool isDark;

  const _SessionsTab({required this.patient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upcoming Sessions
          _InfoCard(
            title: 'Upcoming Sessions',
            isDark: isDark,
            child: _RealSessionList(
              userId: patient.id,
              isDark: isDark,
              isUpcoming: true,
              emptyMessage: 'No upcoming sessions',
            ),
          ),
          const SizedBox(height: 24),

          // Session History
          _InfoCard(
            title: 'Session History',
            isDark: isDark,
            child: _RealSessionList(
              userId: patient.id,
              isDark: isDark,
              isUpcoming: false,
              emptyMessage: 'No session history',
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that fetches real booking data from Firestore
class _RealSessionList extends StatelessWidget {
  final String userId;
  final bool isDark;
  final bool isUpcoming;
  final String emptyMessage;

  const _RealSessionList({
    required this.userId,
    required this.isDark,
    required this.isUpcoming,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                emptyMessage,
                style: TextStyle(
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final sessions = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'date':
                (data['scheduled_time'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            'type': data['session_type'] ?? 'video',
            'therapist': data['therapist_name'] ?? 'Unknown Therapist',
            'status': data['status'] ?? 'pending',
            'duration': data['duration'] as int?,
          };
        }).toList();

        return _SessionList(
          sessions: sessions,
          isDark: isDark,
          emptyMessage: emptyMessage,
        );
      },
    );
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    if (isUpcoming) {
      return firestore
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .where(
            'scheduled_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          )
          .orderBy('scheduled_time')
          .limit(10)
          .snapshots();
    } else {
      return firestore
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .where('scheduled_time', isLessThan: Timestamp.fromDate(now))
          .orderBy('scheduled_time', descending: true)
          .limit(20)
          .snapshots();
    }
  }
}

// Assessments Tab
class _AssessmentsTab extends StatelessWidget {
  final AdminUser patient;
  final bool isDark;

  const _AssessmentsTab({required this.patient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assessment Scores
          _InfoCard(
            title: 'Assessment Scores',
            isDark: isDark,
            child: _AssessmentScoresList(isDark: isDark),
          ),
          const SizedBox(height: 24),

          // Assessment History
          _InfoCard(
            title: 'Assessment History',
            isDark: isDark,
            child: _AssessmentHistoryList(isDark: isDark),
          ),
        ],
      ),
    );
  }
}

// Billing Tab
class _BillingTab extends ConsumerWidget {
  final AdminUser patient;
  final bool isDark;

  const _BillingTab({required this.patient, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subscription Status
          _InfoCard(
            title: 'Subscription',
            isDark: isDark,
            child: _SubscriptionCard(
              patient: patient,
              isDark: isDark,
              onTogglePremium: () => _showPremiumConfirmDialog(context, ref),
            ),
          ),
          const SizedBox(height: 24),

          // Payment History
          _InfoCard(
            title: 'Payment History',
            isDark: isDark,
            child: _PaymentHistoryList(isDark: isDark, patientId: patient.id),
          ),
        ],
      ),
    );
  }

  void _showPremiumConfirmDialog(BuildContext context, WidgetRef ref) {
    final willBePremium = !patient.isPremium;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.adminSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              willBePremium
                  ? Icons.workspace_premium_rounded
                  : Icons.star_outline,
              color: willBePremium
                  ? AppColors.statusSuccess
                  : AppColors.statusWarning,
            ),
            const SizedBox(width: 8),
            Text(
              willBePremium ? 'Grant Premium' : 'Revoke Premium',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          willBePremium
              ? 'Are you sure you want to grant premium access to ${patient.displayName ?? patient.email}?\n\nThey will have access to all premium features.'
              : 'Are you sure you want to revoke premium access from ${patient.displayName ?? patient.email}?\n\nThey will lose access to premium features.',
          style: TextStyle(
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willBePremium
                  ? AppColors.statusSuccess
                  : AppColors.statusWarning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(adminUsersProvider.notifier)
                  .updateUserPremium(patient.id, willBePremium);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (willBePremium
                                ? 'Premium access granted'
                                : 'Premium access revoked')
                          : 'Failed to update premium status',
                    ),
                    backgroundColor: success
                        ? AppColors.statusSuccess
                        : AppColors.statusDanger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(willBePremium ? 'Grant' : 'Revoke'),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  valueColor ?? (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String level;
  final bool isDark;

  const _RiskBadge({required this.level, required this.isDark});

  Color get _color {
    switch (level) {
      case 'critical':
        return AppColors.riskCritical;
      case 'high':
        return AppColors.riskHigh;
      case 'moderate':
        return AppColors.riskModerate;
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '${level.toUpperCase()} RISK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? AppColors.adminGlass.withValues(alpha: 0.5)
          : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.adminTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodHistoryChart extends StatelessWidget {
  final bool isDark;

  const _MoodHistoryChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Placeholder for actual chart
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Mood History Chart',
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Install fl_chart to enable',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.adminTextSecondary.withValues(alpha: 0.7)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real activity list from Firestore
class _RecentActivityList extends StatelessWidget {
  final AdminUser patient;
  final bool isDark;

  const _RecentActivityList({required this.patient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('user_id', isEqualTo: patient.id)
          .orderBy('scheduled_time', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No recent activity',
                style: TextStyle(
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'pending';
            final sessionType = data['session_type'] as String? ?? 'video';
            final therapistName =
                data['therapist_name'] as String? ?? 'Unknown';
            final scheduledTime = (data['scheduled_time'] as Timestamp?)
                ?.toDate();

            IconData icon;
            Color color;
            String title;

            if (status == 'completed') {
              icon = Icons.check_circle_outline;
              color = AppColors.statusSuccess;
              title = '${sessionType.capitalize()} session completed';
            } else if (status == 'cancelled' || status == 'canceled') {
              icon = Icons.cancel_outlined;
              color = AppColors.statusDanger;
              title = '${sessionType.capitalize()} session cancelled';
            } else {
              icon = Icons.schedule_outlined;
              color = AppColors.statusInfo;
              title = '${sessionType.capitalize()} session scheduled';
            }

            return _ActivityRow(
              icon: icon,
              title: title,
              subtitle: 'With $therapistName',
              time: scheduledTime != null ? _formatTimeAgo(scheduledTime) : '',
              color: color,
              isDark: isDark,
            );
          }).toList(),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) {
      // Future date
      final futureDiff = date.difference(now);
      if (futureDiff.inDays > 0) return 'in ${futureDiff.inDays} days';
      if (futureDiff.inHours > 0) return 'in ${futureDiff.inHours} hours';
      return 'soon';
    }

    if (diff.inDays > 7) return DateFormat('MMM d').format(date);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  }
}

/// Activity row widget
class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final bool isDark;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
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
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class _SessionList extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final bool isDark;
  final String emptyMessage;

  const _SessionList({
    required this.sessions,
    required this.isDark,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage,
            style: TextStyle(
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      children: sessions.map((session) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(
                    session['type'] as String,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(session['type'] as String),
                  size: 18,
                  color: _getTypeColor(session['type'] as String),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(session['type'] as String).toUpperCase()} Session',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      session['therapist'] as String,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat(
                      'MMM dd, yyyy',
                    ).format(session['date'] as DateTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _StatusChip(status: session['status'] as String),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'video':
        return AppColors.statusInfo;
      case 'chat':
        return AppColors.primary;
      default:
        return AppColors.statusSuccess;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'confirmed':
        return AppColors.statusSuccess;
      case 'completed':
        return AppColors.statusInfo;
      case 'cancelled':
        return AppColors.statusDanger;
      default:
        return AppColors.statusWarning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _AssessmentScoresList extends StatelessWidget {
  final bool isDark;

  const _AssessmentScoresList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final assessments = [
      {'name': 'PHQ-9', 'score': 8, 'maxScore': 27, 'level': 'Mild'},
      {'name': 'GAD-7', 'score': 5, 'maxScore': 21, 'level': 'Mild'},
      {'name': 'PSS-10', 'score': 14, 'maxScore': 40, 'level': 'Low'},
    ];

    return Column(
      children: assessments.map((assessment) {
        final percentage =
            (assessment['score'] as int) / (assessment['maxScore'] as int);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    assessment['name'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${assessment['score']}/${assessment['maxScore']} (${assessment['level']})',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.adminSurface
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getScoreColor(percentage),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage < 0.3) return AppColors.statusSuccess;
    if (percentage < 0.6) return AppColors.statusWarning;
    return AppColors.statusDanger;
  }
}

class _AssessmentHistoryList extends StatelessWidget {
  final bool isDark;

  const _AssessmentHistoryList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final history = [
      {
        'name': 'PHQ-9',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'score': 8,
      },
      {
        'name': 'GAD-7',
        'date': DateTime.now().subtract(const Duration(days: 14)),
        'score': 5,
      },
      {
        'name': 'PHQ-9',
        'date': DateTime.now().subtract(const Duration(days: 30)),
        'score': 12,
      },
    ];

    return Column(
      children: history.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(item['date'] as DateTime),
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
              Text(
                'Score: ${item['score']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final AdminUser patient;
  final bool isDark;
  final VoidCallback onTogglePremium;

  const _SubscriptionCard({
    required this.patient,
    required this.isDark,
    required this.onTogglePremium,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: patient.isPremium
                ? AppColors.statusSuccess.withValues(alpha: 0.1)
                : AppColors.textMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            patient.isPremium
                ? Icons.workspace_premium_rounded
                : Icons.person_outline_rounded,
            size: 32,
            color: patient.isPremium
                ? AppColors.statusSuccess
                : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.isPremium ? 'Premium Plan' : 'Free Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                patient.isPremium ? 'Active subscription' : 'Limited features',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onTogglePremium,
          icon: Icon(
            patient.isPremium
                ? Icons.star_outline
                : Icons.workspace_premium_rounded,
            size: 18,
          ),
          label: Text(patient.isPremium ? 'Revoke' : 'Upgrade'),
          style: ElevatedButton.styleFrom(
            backgroundColor: patient.isPremium
                ? AppColors.statusWarning
                : AppColors.statusSuccess,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PaymentHistoryList extends StatelessWidget {
  final bool isDark;
  final String patientId;

  const _PaymentHistoryList({required this.isDark, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('user_id', isEqualTo: patientId)
          .orderBy('created_at', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data?.docs ?? [];

        if (payments.isEmpty) {
          return Center(
            child: Text(
              'No payment history',
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          );
        }

        return Column(
          children: payments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date =
                (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            final amount = data['amount'] ?? 0;
            final currency = data['currency'] ?? 'SAR';
            final description = data['product_title'] ?? 'Payment';
            final status = data['status'] ?? 'completed';

            final payment = {
              'date': date,
              'amount': '$currency $amount',
              'description': description,
              'status': status == 'completed' ? 'paid' : status,
            };

            return _buildPaymentRow(payment);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment) {
    return Column(
      children: [payment].map((payment) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: payment['status'] == 'paid'
                      ? AppColors.statusSuccess.withValues(alpha: 0.1)
                      : AppColors.statusWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  payment['status'] == 'paid'
                      ? Icons.check_circle_outline
                      : Icons.replay_rounded,
                  size: 18,
                  color: payment['status'] == 'paid'
                      ? AppColors.statusSuccess
                      : AppColors.statusWarning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(payment['date'] as DateTime),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    payment['amount'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    (payment['status'] as String).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: payment['status'] == 'paid'
                          ? AppColors.statusSuccess
                          : AppColors.statusWarning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
