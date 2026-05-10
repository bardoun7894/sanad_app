import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';

/// Mobile-first patient detail screen for the therapist portal.
///
/// Intentionally lighter than the admin's ClinicPatientProfileScreen —
/// the therapist needs a fast, compact view of who they are talking to:
/// identity card, contact, last 5 mood entries, last 5 test results, and
/// the bookings between them and this patient. Admin-only surfaces
/// (block, delete, generate report, AI insights, therapist re-assignment)
/// are absent by design.
class TherapistPatientDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const TherapistPatientDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<TherapistPatientDetailScreen> createState() =>
      _TherapistPatientDetailScreenState();
}

class _TherapistPatientDetailScreenState
    extends ConsumerState<TherapistPatientDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

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
    final s = ref.watch(stringsProvider);
    final therapistUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.myPatients),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(s.patientNotFound));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildBody(isDark, data, therapistUid, s);
        },
      ),
    );
  }

  Widget _buildBody(
    bool isDark,
    Map<String, dynamic> userData,
    String? therapistUid,
    dynamic s,
  ) {
    final name = userData['display_name'] ??
        userData['name'] ??
        userData['full_name'] ??
        'User';
    final email = userData['email'] as String? ?? '';
    final phone = userData['phone'] as String? ?? '';
    final photoUrl = userData['photo_url'] ?? userData['avatar_url'];
    final createdAt = userData['created_at'] as Timestamp?;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final joinedDate = createdAt != null
        ? DateFormat('MMM yyyy', localeTag).format(createdAt.toDate())
        : '';
    final isPremium = userData['is_premium'] == true;

    return Column(
      children: [
        _IdentityCard(
          name: name,
          email: email,
          phone: phone,
          photoUrl: photoUrl,
          joinedDate: joinedDate,
          joinedPrefix: s.joinedPrefix,
          isPremium: isPremium,
          isDark: isDark,
          onChat: therapistUid == null
              ? null
              : () => context.push(
                    '/therapist/messages/${therapistUid}_${widget.userId}',
                  ),
        ),
        Container(
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
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? Colors.white60 : AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: s.tabOverview),
              Tab(text: s.tabMood),
              Tab(text: s.tabTests),
              Tab(text: s.tabSessions),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                userId: widget.userId,
                therapistUid: therapistUid,
                isDark: isDark,
                s: s,
              ),
              _MoodTab(userId: widget.userId, isDark: isDark, s: s),
              _TestsTab(userId: widget.userId, isDark: isDark, s: s),
              _SessionsTab(
                userId: widget.userId,
                therapistUid: therapistUid,
                isDark: isDark,
                s: s,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final dynamic photoUrl;
  final String joinedDate;
  final String joinedPrefix;
  final bool isPremium;
  final bool isDark;
  final VoidCallback? onChat;

  const _IdentityCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.joinedDate,
    required this.joinedPrefix,
    required this.isPremium,
    required this.isDark,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage:
                    photoUrl is String && (photoUrl as String).isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                child: photoUrl is String && (photoUrl as String).isNotEmpty
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: AppTypography.headingMedium.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (joinedDate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$joinedPrefix $joinedDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onChat != null)
                IconButton.filled(
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  onPressed: onChat,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 40),
                  ),
                ),
            ],
          ),
          if (email.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (email.isNotEmpty)
                  _ContactChip(
                    icon: Icons.email_outlined,
                    label: email,
                    isDark: isDark,
                  ),
                if (phone.isNotEmpty)
                  _ContactChip(
                    icon: Icons.phone_outlined,
                    label: phone,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _ContactChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String userId;
  final String? therapistUid;
  final bool isDark;
  final dynamic s;
  const _OverviewTab({
    required this.userId,
    required this.therapistUid,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Two count cards side-by-side
        Row(
          children: [
            Expanded(
              child: _CountCard(
                label: s.moodEntriesCount,
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('mood_entries')
                    .orderBy('timestamp', descending: true)
                    .limit(50)
                    .snapshots(),
                isDark: isDark,
                icon: Icons.mood_rounded,
                color: AppColors.statusInfo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CountCard(
                label: s.testResultsCount,
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('test_results')
                    .orderBy('created_at', descending: true)
                    .limit(50)
                    .snapshots(),
                isDark: isDark,
                icon: Icons.fact_check_rounded,
                color: AppColors.statusSuccess,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Latest mood
        _LatestMoodCard(userId: userId, isDark: isDark, s: s, localeTag: localeTag),
        const SizedBox(height: 12),
        // Latest test
        _LatestTestCard(userId: userId, isDark: isDark, s: s, localeTag: localeTag),
        const SizedBox(height: 12),
        // Upcoming session + completed count
        if (therapistUid != null) ...[
          _UpcomingSessionCard(
            userId: userId,
            therapistUid: therapistUid!,
            isDark: isDark,
            s: s,
            localeTag: localeTag,
          ),
          const SizedBox(height: 12),
          _CompletedSessionsCard(
            userId: userId,
            therapistUid: therapistUid!,
            isDark: isDark,
            s: s,
          ),
        ],
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot> stream;
  final bool isDark;
  final IconData icon;
  final Color color;
  const _CountCard({
    required this.label,
    required this.stream,
    required this.isDark,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final count = snap.hasData ? snap.data!.docs.length : 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                '$count',
                style: AppTypography.headingMedium.copyWith(
                  fontSize: 24,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LatestMoodCard extends StatelessWidget {
  final String userId;
  final bool isDark;
  final dynamic s;
  final String localeTag;
  const _LatestMoodCard({
    required this.userId,
    required this.isDark,
    required this.s,
    required this.localeTag,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionTile(
      isDark: isDark,
      label: s.latestMood,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('mood_entries')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Text(
              s.noMoodEntriesYet,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            );
          }
          final d =
              snap.data!.docs.first.data() as Map<String, dynamic>;
          final mood = d['mood']?.toString() ?? '—';
          final ts = d['timestamp'] as Timestamp?;
          final when = ts != null
              ? DateFormat('MMM d • HH:mm', localeTag).format(ts.toDate())
              : '';
          return Row(
            children: [
              Text(_emojiFor(mood), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (when.isNotEmpty)
                      Text(
                        when,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white60
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _emojiFor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'anxious':
        return '😰';
      case 'angry':
        return '😠';
      case 'calm':
        return '😌';
      case 'tired':
        return '😴';
      default:
        return '😐';
    }
  }
}

class _LatestTestCard extends StatelessWidget {
  final String userId;
  final bool isDark;
  final dynamic s;
  final String localeTag;
  const _LatestTestCard({
    required this.userId,
    required this.isDark,
    required this.s,
    required this.localeTag,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionTile(
      isDark: isDark,
      label: s.latestTest,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('test_results')
            .orderBy('created_at', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Text(
              s.noTestResultsYet,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            );
          }
          final d =
              snap.data!.docs.first.data() as Map<String, dynamic>;
          final type = d['test_type']?.toString() ?? 'Test';
          final score = d['total_score']?.toString() ?? '—';
          final ts = d['created_at'] as Timestamp?;
          final when = ts != null
              ? DateFormat('MMM d, yyyy', localeTag).format(ts.toDate())
              : '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$type — $score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (when.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  when,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UpcomingSessionCard extends StatelessWidget {
  final String userId;
  final String therapistUid;
  final bool isDark;
  final dynamic s;
  final String localeTag;
  const _UpcomingSessionCard({
    required this.userId,
    required this.therapistUid,
    required this.isDark,
    required this.s,
    required this.localeTag,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionTile(
      isDark: isDark,
      label: s.upcomingSession,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('client_id', isEqualTo: userId)
            .where('therapist_id', isEqualTo: therapistUid)
            .where('status', whereIn: ['confirmed', 'pending'])
            .orderBy('scheduled_time')
            .limit(1)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Text(
              s.noUpcomingSession,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            );
          }
          final d =
              snap.data!.docs.first.data() as Map<String, dynamic>;
          final ts = d['scheduled_time'] as Timestamp?;
          final when = ts != null
              ? DateFormat('EEE, MMM d • HH:mm', localeTag)
                  .format(ts.toDate())
              : '';
          final status = d['status']?.toString() ?? '';
          return Row(
            children: [
              Icon(Icons.event_available_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompletedSessionsCard extends StatelessWidget {
  final String userId;
  final String therapistUid;
  final bool isDark;
  final dynamic s;
  const _CompletedSessionsCard({
    required this.userId,
    required this.therapistUid,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionTile(
      isDark: isDark,
      label: s.completedSessionsLabel,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('client_id', isEqualTo: userId)
            .where('therapist_id', isEqualTo: therapistUid)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snap) {
          final count = snap.hasData ? snap.data!.docs.length : 0;
          return Text(
            '$count',
            style: AppTypography.headingMedium.copyWith(
              fontSize: 22,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          );
        },
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final bool isDark;
  final String label;
  final Widget child;
  const _SectionTile({
    required this.isDark,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MoodTab extends StatelessWidget {
  final String userId;
  final bool isDark;
  final dynamic s;
  const _MoodTab({
    required this.userId,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mood_entries')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.mood_outlined,
            label: s.noMoodEntriesYet,
            isDark: isDark,
          );
        }
        final localeTag = Localizations.localeOf(context).toLanguageTag();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final mood = d['mood']?.toString() ?? '—';
            final note = d['note']?.toString() ?? '';
            final ts = d['timestamp'] as Timestamp?;
            final when = ts != null
                ? DateFormat('MMM d, HH:mm', localeTag).format(ts.toDate())
                : '';
            return _RowCard(
              isDark: isDark,
              leading: Text(_moodEmoji(mood), style: const TextStyle(fontSize: 22)),
              title: mood,
              subtitle: note.isEmpty ? when : '$when • $note',
            );
          },
        );
      },
    );
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'anxious':
        return '😰';
      case 'angry':
        return '😠';
      case 'calm':
        return '😌';
      case 'tired':
        return '😴';
      default:
        return '😐';
    }
  }
}

class _TestsTab extends StatelessWidget {
  final String userId;
  final bool isDark;
  final dynamic s;
  const _TestsTab({
    required this.userId,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('test_results')
          .orderBy('created_at', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.fact_check_outlined,
            label: s.noTestResultsYet,
            isDark: isDark,
          );
        }
        final localeTag = Localizations.localeOf(context).toLanguageTag();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final type = d['test_type']?.toString() ??
                d['testType']?.toString() ??
                'Test';
            final score = d['total_score']?.toString() ??
                d['totalScore']?.toString() ??
                '—';
            final interp = d['interpretation']?.toString() ?? '';
            final ts = d['created_at'] as Timestamp?;
            final when = ts != null
                ? DateFormat('MMM d, yyyy', localeTag).format(ts.toDate())
                : '';
            return _RowCard(
              isDark: isDark,
              leading: const Icon(Icons.fact_check_outlined,
                  color: AppColors.primary),
              title: '$type — $score',
              subtitle: interp.isEmpty ? when : '$when • $interp',
            );
          },
        );
      },
    );
  }
}

class _SessionsTab extends StatelessWidget {
  final String userId;
  final String? therapistUid;
  final bool isDark;
  final dynamic s;
  const _SessionsTab({
    required this.userId,
    required this.therapistUid,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    if (therapistUid == null) {
      return _EmptyState(
        icon: Icons.event_busy_outlined,
        label: s.signInRequired,
        isDark: isDark,
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('client_id', isEqualTo: userId)
          .where('therapist_id', isEqualTo: therapistUid)
          .orderBy('scheduled_time', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.event_busy_outlined,
            label: s.noSessionsYet,
            isDark: isDark,
          );
        }
        final localeTag = Localizations.localeOf(context).toLanguageTag();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final status = d['status']?.toString() ?? 'unknown';
            final ts = d['scheduled_time'] as Timestamp?;
            final when = ts != null
                ? DateFormat('EEE, MMM d • HH:mm', localeTag).format(ts.toDate())
                : '';
            return _RowCard(
              isDark: isDark,
              leading: Icon(
                _statusIcon(status),
                color: _statusColor(status),
              ),
              title: when,
              subtitle: status,
            );
          },
        );
      },
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.event_available_rounded;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.event_busy_outlined;
      case 'pending':
      case 'awaiting_payment':
        return Icons.schedule_rounded;
      default:
        return Icons.event_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.statusInfo;
      case 'completed':
        return AppColors.statusSuccess;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
      case 'awaiting_payment':
        return AppColors.statusWarning;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _RowCard extends StatelessWidget {
  final bool isDark;
  final Widget leading;
  final String title;
  final String subtitle;
  const _RowCard({
    required this.isDark,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 32, child: Center(child: leading)),
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
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white60
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _EmptyState({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
