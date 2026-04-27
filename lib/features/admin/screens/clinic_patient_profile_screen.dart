import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class ClinicPatientProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ClinicPatientProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ClinicPatientProfileScreen> createState() =>
      _ClinicPatientProfileScreenState();
}

class _ClinicPatientProfileScreenState
    extends ConsumerState<ClinicPatientProfileScreen>
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

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userName =
              userData['name'] ?? userData['display_name'] ?? 'Unknown User';
          final userEmail = userData['email'] ?? 'No email';
          final isPremium = userData['is_premium'] == true;
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
                joinDate,
              ),

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
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to chat with this user
                  context.go('/admin/chat');
                },
                icon: const Icon(Icons.message_outlined, size: 18),
                label: const Text('Message'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildMoodTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mood_entries')
          .where('user_id', isEqualTo: widget.userId)
          .orderBy('created_at', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No mood entries yet',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final mood = data['mood'] ?? 'neutral';
            final note = data['note'] ?? '';
            final createdAt = data['created_at'] as Timestamp?;

            return ListTile(
              leading: Text(
                _getMoodEmoji(mood),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                mood.toString().toUpperCase(),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              subtitle: Text(
                note.isNotEmpty
                    ? note
                    : (createdAt != null
                          ? DateFormat('MMM d, yyyy').format(createdAt.toDate())
                          : 'Unknown date'),
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'anxious':
        return '😰';
      case 'calm':
        return '😌';
      case 'angry':
        return '😠';
      default:
        return '😐';
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
