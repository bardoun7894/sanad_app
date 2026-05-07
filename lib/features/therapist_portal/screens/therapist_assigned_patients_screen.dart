import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapist_chat/services/therapist_chat_service.dart';

class TherapistAssignedPatientsScreen extends ConsumerWidget {
  const TherapistAssignedPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final authState = ref.watch(authProvider);
    final therapistId = authState.user?.uid;

    if (therapistId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.myPatients)),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          s.myAssignedPatients,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('assigned_therapist_id', isEqualTo: therapistId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.noAssignedPatients,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.noAssignedPatientsHint,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? data['display_name'] ?? 'User';
              final photoUrl = data['photo_url'] as String?;
              final createdAt = data['created_at'] as Timestamp?;
              final joinedDate = createdAt != null
                  ? DateFormat('MMM yyyy').format(createdAt.toDate())
                  : '';
              final isPremium = data['is_premium'] == true;

              return _PatientCard(
                name: name,
                photoUrl: photoUrl,
                joinedDate: joinedDate,
                joinedPrefix: s.joinedPrefix,
                isPremium: isPremium,
                isDark: isDark,
                onTap: () async {
                  final chatId = '${therapistId}_${users[index].id}';
                  final chatService = TherapistChatService();
                  final exists = await chatService.chatExists(therapistId, users[index].id);
                  if (!exists && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.chatNotCreated),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  if (context.mounted) {
                    context.push('/therapist/messages/$chatId');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String joinedDate;
  final String joinedPrefix;
  final bool isPremium;
  final bool isDark;
  final VoidCallback onTap;

  const _PatientCard({
    required this.name,
    this.photoUrl,
    required this.joinedDate,
    required this.joinedPrefix,
    required this.isPremium,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: AppTypography.headingSmall.copyWith(
                              fontSize: 15,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (joinedDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$joinedPrefix $joinedDate',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
