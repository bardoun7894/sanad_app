import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/therapist_chat.dart';
import '../providers/therapist_chat_provider.dart';

/// Chat filter types
enum ChatFilter { allChats, unread, urgent, scheduled }

/// Chat list screen for therapists to see all their client conversations
class TherapistChatListScreen extends ConsumerStatefulWidget {
  const TherapistChatListScreen({super.key});

  @override
  ConsumerState<TherapistChatListScreen> createState() =>
      _TherapistChatListScreenState();
}

class _TherapistChatListScreenState
    extends ConsumerState<TherapistChatListScreen> {
  ChatFilter _selectedFilter = ChatFilter.allChats;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Background colors matching the design intent while using app theme
    // HTML uses #F8FAFC for light bg, #111827 for dark
    final backgroundColor = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF8FAFC);

    final authState = ref.watch(authProvider);
    final therapistId = authState.user?.uid;
    final s = ref.watch(stringsProvider);

    if (therapistId == null) {
      return Scaffold(body: Center(child: Text(s.pleaseLoginToViewMessages)));
    }

    final chatsAsync = ref.watch(therapistChatsProvider(therapistId));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Profile
            _buildHeader(context, isDark, authState.user, s),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: _buildSearchBar(isDark, s),
            ),

            // Filter Tabs
            _buildFilterTabs(isDark, s),

            // Content
            Expanded(
              child: chatsAsync.when(
                data: (chats) {
                  // Apply filtering and search
                  final filteredChats = _filterChats(chats);

                  if (filteredChats.isEmpty) {
                    return _buildEmptyState(isDark, s);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChatThreadTile(
                          chat: chat,
                          strings: s,
                          onTap: () {
                            context.push(
                              '/therapist/messages/${chat.chatId}',
                              extra: chat,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text('${s.errorLoadingMessages}: $error'),
                      const SizedBox(height: 8),
                      Text(
                        s.ensureFirestoreIndexes,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, dynamic user, S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.myPatients,
                  style: AppTypography.headingMedium.copyWith(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF0F172A), // Slate-900
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.manageOngoingSessions,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B), // Slate-500
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              // Support Chat Button
              GestureDetector(
                onTap: () => context.push('/support-chat'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Notification Bell
              GestureDetector(
                onTap: () => context.pushNamed('notifications'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Profile Image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Filter chats based on selected filter and search query
  List<TherapistChatThread> _filterChats(List<TherapistChatThread> chats) {
    var filtered = chats;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((chat) {
        final query = _searchQuery.toLowerCase();
        return chat.userName.toLowerCase().contains(query) ||
            (chat.lastMessage?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply tab filter
    switch (_selectedFilter) {
      case ChatFilter.allChats:
        // No additional filtering
        break;
      case ChatFilter.unread:
        filtered = filtered
            .where((chat) => chat.unreadCountTherapist > 0)
            .toList();
        break;
      case ChatFilter.urgent:
        filtered = filtered.where((chat) {
          // Urgent: Unread by therapist AND > 10 minutes since last message
          return chat.unreadCountTherapist > 0 &&
              chat.lastMessageTime != null &&
              DateTime.now().difference(chat.lastMessageTime!).inMinutes > 10;
        }).toList();
        break;
      case ChatFilter.scheduled:
        // Show chats with associated bookings
        filtered = filtered
            .where((chat) => chat.bookingIds.isNotEmpty)
            .toList();
        break;
    }

    return filtered;
  }

  Widget _buildSearchBar(bool isDark, S s) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: s.searchPatients,
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8), // Slate-400
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark, S s) {
    final tabs = [
      {'label': s.allChats, 'filter': ChatFilter.allChats},
      {'label': s.unread, 'filter': ChatFilter.unread},
      {'label': s.urgent, 'filter': ChatFilter.urgent},
      {'label': s.scheduled, 'filter': ChatFilter.scheduled},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final filter = tab['filter'] as ChatFilter;
          final isSelected = _selectedFilter == filter;

          // Styling logic (Updated to use app color for selected font)
          final bgLight = isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white;
          final bgDark = isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : const Color(0xFF1F2937);
          final textLight = isSelected
              ? AppColors.primary
              : const Color(0xFF475569);
          final textDark = isSelected
              ? AppColors.primary
              : const Color(0xFFCBD5E1);
          final borderLight = isSelected
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0);
          final borderDark = isSelected
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFF374151);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? bgDark : bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? borderDark : borderLight),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                tab['label'] as String,
                style: TextStyle(
                  color: isDark ? textDark : textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 24),
          Text(
            s.noMessagesYet,
            style: AppTypography.headingSmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.clientsWillAppearHere,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white54 : AppColors.textLightSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    final hasUnread = chat.unreadCountTherapist > 0;

    // Urgent: Unread by therapist AND > 10 minutes since last message
    final bool isUrgent =
        chat.unreadCountTherapist > 0 &&
        chat.lastMessageTime != null &&
        DateTime.now().difference(chat.lastMessageTime!).inMinutes > 10;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24), // rounded-3xl
          border: isUrgent
              ? const Border(
                  left: BorderSide(color: Color(0xFFEF4444), width: 4),
                )
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      16,
                    ), // Rounded square look from design
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFF1F5F9),
                    image: chat.userPhotoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(chat.userPhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: chat.userPhotoUrl == null
                      ? Center(
                          child: Text(
                            chat.userName.isNotEmpty
                                ? chat.userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                // Status Indicator
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E), // Green-500
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.userName,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Tajawal',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.lastMessageTime != null
                            ? _formatTime(chat.lastMessageTime!)
                            : '',
                        style: TextStyle(
                          color: hasUnread
                              ? AppColors.primary
                              : const Color(0xFF94A3B8), // Slate-400
                          fontSize: 11, // Match design small text
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.typing.userTyping
                        ? strings.typingIndicator
                        : (chat.lastMessage ?? strings.noMessagesYet),
                    style: TextStyle(
                      color: chat.typing.userTyping
                          ? const Color(0xFF22C55E)
                          : (hasUnread
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B))
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF475569))),
                      fontSize: 14,
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Tags / Chips Row
                  Row(
                    children: [
                      // Tag: Urgent (based on unread + recent activity)
                      if (isUrgent)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2), // Red-50
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  strings.urgent,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626), // Red-600
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Tag: Default category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFF1F5F9), // Slate-100
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          strings.general,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
