import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapist_chat/models/therapist_chat.dart';
import '../../therapist_chat/providers/therapist_chat_provider.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../providers/user_support_chat_provider.dart';

class UserChatListScreen extends ConsumerWidget {
  const UserChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine current theme brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Background colors matching the design intent while using app theme
    // HTML uses #F3F6F8 for light bg, #111827 for dark
    final backgroundColor = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF3F6F8);

    final strings = ref.watch(stringsProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid;
    final isGuest = authState.user?.isGuest ?? false;
    final subStatus = ref.watch(subscriptionStatusProvider);
    final tierLevel = subStatus.tierLevel;
    // Hide support/therapist tiles for guests and free (tier 0) users
    final hideSupportAndTherapy = isGuest || tierLevel < 1;

    if (userId == null) {
      return Scaffold(body: Center(child: Text(strings.loginRequired)));
    }

    final chatsAsync = ref.watch(userChatsProvider(userId));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(context, isDark, strings),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: _buildSearchBar(isDark, strings),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  return ref.refresh(userChatsProvider(userId).future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. Sanad AI Assistant
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 8.0,
                        ),
                        child: _AiChatTile(
                          onTap: () => context.push('/chat'),
                          isDark: isDark,
                          strings: strings,
                        ),
                      ),
                    ),

                    // 2. Sanad Support / Sanad Therapy (Admin) — hidden for guests & free users
                    if (!hideSupportAndTherapy)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.0,
                          ),
                          child: _SupportChatTile(
                            userId: userId,
                            isDark: isDark,
                            strings: strings,
                          ),
                        ),
                      ),

                    // 3. Personal Therapist Section (Tiers 3 & 4) — hidden for guests & free users
                    if (!hideSupportAndTherapy && tierLevel >= 3) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: Text(
                            strings.talkToTherapist, // "Personal Therapist" or similar
                            style: AppTypography.headingSmall.copyWith(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      chatsAsync.when(
                        data: (chats) {
                          if (chats.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 30,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 72,
                                        color: isDark
                                            ? AppColors.textMuted
                                            : AppColors.primary.withValues(
                                              alpha: 0.7,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      strings
                                          .noSessionsToday, // "No conversations yet" roughly
                                      style: AppTypography.headingMedium
                                          .copyWith(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            fontWeight: FontWeight.w700,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                      ),
                                      child: Text(
                                        strings.chatsWithTherapistsAppearHere,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                              height: 1.5,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final chat = chats[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _ChatThreadTile(
                                    chat: chat,
                                    strings: strings,
                                    onTap: () {
                                      context.push(
                                        '/chat/therapist/${chat.chatId}',
                                        extra: chat,
                                      );
                                    },
                                  ),
                                );
                              }, childCount: chats.length),
                            ),
                          );
                        },
                        loading: () => const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                strings.unableToLoadMessages,
                                style: TextStyle(color: Colors.red[400]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, dynamic strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.messages,
            style: AppTypography.headingLarge.copyWith(
              color: isDark
                  ? Colors.white
                  : const Color(0xFF0F172A), // Slate-900
              fontSize: 34, // Large iOS style title
              fontWeight: FontWeight.w800,
              fontFamily: 'Tajawal',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.connectWithCareTeam,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B), // Slate-500
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, dynamic strings) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.2 : 0.03,
            ), // Softer shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: strings.searchConversations,
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8), // Slate-400
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8), // Slate-400
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _SupportChatTile extends ConsumerWidget {
  final String userId;
  final bool isDark;
  final dynamic strings;

  const _SupportChatTile({
    required this.userId,
    required this.isDark,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatInfoAsync = ref.watch(supportChatInfoProvider(userId));
    final unreadCountAsync = ref.watch(supportUnreadCountProvider(userId));

    return chatInfoAsync.when(
      data: (info) {
        return GestureDetector(
          onTap: () => context.push('/chat/support'),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Support Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            strings.sanadSupport, // "Sanad Therapy / Support"
                            style: AppTypography.headingSmall.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (info?.status == 'open')
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info?.lastMessage ?? strings.connectWithProfessional,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Unread Badge
                unreadCountAsync.when(
                  data: (count) {
                    if (count == 0) {
                      return Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFF94A3B8),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AiChatTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final dynamic strings;

  const _AiChatTile({
    required this.onTap,
    required this.isDark,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [Colors.white, const Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20), // More rounded
          border: Border.all(
            color: AppColors.primary.withValues(
              alpha: isDark ? 0.3 : 0.1,
            ), // Subtle brand border
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // AI Avatar - Hero style
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sanad AI',
                        style: AppTypography.headingSmall.copyWith(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Verified/Assistant Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.chatSubtitle, // "Assistant is ready to help"
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Call to action arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatThreadTile extends StatelessWidget {
  final TherapistChatThread chat;
  final VoidCallback onTap;
  final S strings;

  const _ChatThreadTile({
    required this.chat,
    required this.onTap,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = chat.unreadCountUser > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF374151) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: chat.therapistPhotoUrl != null
                        ? NetworkImage(chat.therapistPhotoUrl!)
                        : null,
                    child: chat.therapistPhotoUrl == null
                        ? Text(
                            chat.therapistName.isNotEmpty
                                ? chat.therapistName[0].toUpperCase()
                                : 'T',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                ),
                // Typing indicator or Online status would go here
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.therapistName,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Tajawal',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageTime != null)
                        Text(
                          _formatTime(chat.lastMessageTime!),
                          style: TextStyle(
                            // Highlight color if unread
                            color: hasUnread
                                ? AppColors.primary
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                            fontSize: 12,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Message Preview & Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.typing.therapistTyping
                              ? strings.typingIndicator
                              : (chat.lastMessage ?? strings.startConversation),
                          style: TextStyle(
                            color: chat.typing.therapistTyping
                                ? const Color(0xFF22C55E)
                                : (hasUnread
                                      ? (isDark
                                            ? Colors.white
                                            : const Color(
                                                0xFF334155,
                                              )) // Darker if unread
                                      : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(
                                                0xFF64748B,
                                              ))), // Slate-500
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontStyle: chat.typing.therapistTyping
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              chat.unreadCountUser > 9
                                  ? '9+'
                                  : chat.unreadCountUser.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
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
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(time);
    } else if (difference.inDays == 1) {
      return strings.yesterday;
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(time);
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
