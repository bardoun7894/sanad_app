import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../services/admin_chat_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Chat filter state
class ChatFilter {
  final String searchQuery;
  final String priority;
  final bool showUnreadOnly;

  const ChatFilter({
    this.searchQuery = '',
    this.priority = 'all',
    this.showUnreadOnly = false,
  });

  ChatFilter copyWith({
    String? searchQuery,
    String? priority,
    bool? showUnreadOnly,
  }) {
    return ChatFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      priority: priority ?? this.priority,
      showUnreadOnly: showUnreadOnly ?? this.showUnreadOnly,
    );
  }
}

final chatFilterProvider = StateProvider<ChatFilter>(
  (ref) => const ChatFilter(),
);

class AdminChatListScreen extends ConsumerStatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  ConsumerState<AdminChatListScreen> createState() =>
      _AdminChatListScreenState();
}

class _AdminChatListScreenState extends ConsumerState<AdminChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(chatFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          _buildHeader(isDark),

          // Stats Row
          _buildStatsRow(isDark),

          // Search and Filters
          _buildSearchAndFilters(isDark, filter),

          // Tabs
          _buildTabs(isDark),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChatList(filter: filter, type: 'all'),
                _ChatList(filter: filter, type: 'unread'),
                _ChatList(filter: filter, type: 'priority'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final isMobile = AdminResponsive.isMobile(context);

    final titleAndStats = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Support Inbox',
          style: TextStyle(
            fontSize: isMobile ? 22 : 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage patient support conversations',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.campaign_rounded,
          label: 'Broadcast All',
          onPressed: () => _showBroadcastDialog(context),
          isDark: isDark,
        ),
        _ActionButton(
          icon: Icons.add_comment_rounded,
          label: 'New Chat',
          onPressed: () => _showUserSearchDialog(context),
          isDark: isDark,
        ),
        _ActionButton(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: () => setState(() {}),
          isDark: isDark,
          isOutlined: true,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? 12 : 24,
        isMobile ? 12 : 24,
        16,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleAndStats,
                const SizedBox(height: 12),
                actions,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleAndStats),
                actions,
              ],
            ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _BroadcastDialog(),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final isMobile = AdminResponsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: StreamBuilder<List<ChatThread>>(
        stream: AdminChatService().getChatThreads(),
        builder: (context, snapshot) {
          final threads = snapshot.data ?? [];
          final totalUnread = threads.fold<int>(
            0,
            (sum, t) => sum + t.unreadCount,
          );
          final urgentCount = threads.where((t) => t.unreadCount > 3).length;
          // Note: Response time calculation available but requires async future builder
          // For now showing unread count is more valuable than response time
          final avgResponseTime = totalUnread > 0 ? 'Active' : 'All Clear';

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.inbox_rounded,
                  label: 'Total Conversations',
                  value: threads.length.toString(),
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.mark_email_unread_rounded,
                  label: 'Unread Messages',
                  value: totalUnread.toString(),
                  color: AppColors.statusWarning,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.priority_high_rounded,
                  label: 'High Priority',
                  value: urgentCount.toString(),
                  color: AppColors.statusDanger,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.timer_rounded,
                  label: 'Avg Response',
                  value: avgResponseTime,
                  color: AppColors.statusSuccess,
                  isDark: isDark,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark, ChatFilter filter) {
    final isMobile = AdminResponsive.isMobile(context);

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.3)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.adminBorder : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(chatFilterProvider.notifier).state = filter.copyWith(
                    searchQuery: value,
                  );
                },
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by email or message...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FilterToggle(
                    label: 'Unread Only',
                    isActive: filter.showUnreadOnly,
                    onTap: () {
                      ref.read(chatFilterProvider.notifier).state = filter
                          .copyWith(showUnreadOnly: !filter.showUnreadOnly);
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                _FilterDropdown(
                  value: filter.priority,
                  items: const {
                    'all': 'All Priority',
                    'high': 'High',
                    'medium': 'Medium',
                    'low': 'Low',
                  },
                  onChanged: (value) {
                    ref.read(chatFilterProvider.notifier).state = filter
                        .copyWith(priority: value);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.3)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.adminBorder : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(chatFilterProvider.notifier).state = filter.copyWith(
                    searchQuery: value,
                  );
                },
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by email or message...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Unread Only Toggle
          _FilterToggle(
            label: 'Unread Only',
            isActive: filter.showUnreadOnly,
            onTap: () {
              ref.read(chatFilterProvider.notifier).state = filter.copyWith(
                showUnreadOnly: !filter.showUnreadOnly,
              );
            },
            isDark: isDark,
          ),
          const SizedBox(width: 12),

          // Priority Dropdown
          _FilterDropdown(
            value: filter.priority,
            items: const {
              'all': 'All Priority',
              'high': 'High',
              'medium': 'Medium',
              'low': 'Low',
            },
            onChanged: (value) {
              ref.read(chatFilterProvider.notifier).state = filter.copyWith(
                priority: value,
              );
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    final isMobile = AdminResponsive.isMobile(context);
    return StreamBuilder<List<ChatThread>>(
      stream: AdminChatService().getChatThreads(),
      builder: (context, snapshot) {
        final threads = snapshot.data ?? [];
        final unreadCount = threads.where((t) => t.unreadCount > 0).length;
        final priorityCount = threads.where((t) => t.unreadCount > 3).length;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.adminGlass.withValues(alpha: 0.2)
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            dividerColor: Colors.transparent,
            tabs: [
              _TabWithBadge(
                label: 'All Chats',
                count: threads.length,
                isDark: isDark,
              ),
              _TabWithBadge(
                label: 'Unread',
                count: unreadCount,
                isDark: isDark,
                badgeColor: AppColors.statusWarning,
              ),
              _TabWithBadge(
                label: 'Priority',
                count: priorityCount,
                isDark: isDark,
                badgeColor: AppColors.statusDanger,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUserSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _UserSearchDialog(),
    );
  }
}

class _UserSearchDialog extends StatefulWidget {
  const _UserSearchDialog();

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _error = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await AdminChatService().searchUsers(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error searching users: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startChat(Map<String, dynamic> user) {
    final userId = user['uid'] as String;
    final userEmail = user['email'] as String? ?? 'Unknown';
    final userName = user['name'] as String? ?? '';

    // Close dialog
    Navigator.of(context).pop();

    // Navigate to chat detail with a temporary thread object
    // The actual thread will be created/updated when the first message is sent
    final thread = ChatThread(
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
    );

    context.go('/admin/chat/detail/${thread.userId}', extra: thread);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Chat'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, Email or Phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            if (_results.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                width: double.infinity,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final email = user['email'] as String? ?? 'No Email';
                    final name = user['name'] as String? ?? 'No Name';
                    final phone = user['phone'] as String? ?? '';
                    final avatarUrl = user['avatar_url'] as String?;
                    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            hasAvatar ? NetworkImage(avatarUrl) : null,
                        child: !hasAvatar
                            ? Text(
                                email.isNotEmpty ? email[0].toUpperCase() : '?',
                              )
                            : null,
                      ),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email),
                          if (phone.isNotEmpty)
                            Text(phone, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      isThreeLine: phone.isNotEmpty,
                      onTap: () => _startChat(user),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty && !_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No users found'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Dialog for broadcasting a message to all users
class _BroadcastDialog extends StatefulWidget {
  const _BroadcastDialog();

  @override
  State<_BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<_BroadcastDialog> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  String? _result;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _result = 'Please enter a message');
      return;
    }

    setState(() {
      _isSending = true;
      _result = null;
    });

    try {
      final report = await AdminChatService().broadcastMessageWithReport(
        message,
      );
      if (mounted) {
        setState(() {
          _isSending = false;
          _result = report.isSuccess
              ? 'Message sent to ${report.sentCount} users.'
              : 'Sent: ${report.sentCount}, Failed: ${report.failedCount}';
        });
        if (report.isSuccess) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _result = '❌ Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.campaign_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text('Broadcast Message'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This message will be sent to ALL registered users.',
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your broadcast message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.adminSurface
                    : AppColors.background,
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.contains('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(
                    color: _result!.contains('✅') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _sendBroadcast,
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_isSending ? 'Sending...' : 'Send to All'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Chat List Widget
class _ChatList extends StatelessWidget {
  final ChatFilter filter;
  final String type;

  const _ChatList({required this.filter, required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<ChatThread>>(
      stream: AdminChatService().getChatThreads(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error.toString(), isDark: isDark);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        var threads = snapshot.data ?? [];

        // Apply filters
        if (type == 'unread') {
          threads = threads.where((t) => t.unreadCount > 0).toList();
        } else if (type == 'priority') {
          threads = threads.where((t) => t.unreadCount > 3).toList();
        }

        if (filter.showUnreadOnly) {
          threads = threads.where((t) => t.unreadCount > 0).toList();
        }

        if (filter.searchQuery.isNotEmpty) {
          threads = threads.where((t) {
            return t.userEmail.toLowerCase().contains(
                  filter.searchQuery.toLowerCase(),
                ) ||
                t.lastMessage.toLowerCase().contains(
                  filter.searchQuery.toLowerCase(),
                );
          }).toList();
        }

        if (threads.isEmpty) {
          return _EmptyState(type: type, isDark: isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: threads.length,
          itemBuilder: (context, index) {
            final thread = threads[index];
            return _ChatThreadCard(thread: thread, isDark: isDark);
          },
        );
      },
    );
  }
}

class _ChatThreadCard extends StatefulWidget {
  final ChatThread thread;
  final bool isDark;

  const _ChatThreadCard({required this.thread, required this.isDark});

  @override
  State<_ChatThreadCard> createState() => _ChatThreadCardState();
}

class _ChatThreadCardState extends State<_ChatThreadCard> {
  late final Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = AdminChatService().resolveDisplayNameForThread(widget.thread);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  String _getPriority() {
    if (widget.thread.unreadCount > 5) return 'critical';
    if (widget.thread.unreadCount > 3) return 'high';
    if (widget.thread.unreadCount > 0) return 'medium';
    return 'low';
  }

  /// Confirms then permanently deletes this conversation for BOTH sides
  /// (admin inbox + the client's support-chat screen).
  Future<void> _confirmDelete(String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(
          'This permanently deletes the chat with "$displayName" for both '
          'the dashboard and the client. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AdminChatService().deleteChatThread(widget.thread.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final isDark = widget.isDark;
    final hasUnread = thread.unreadCount > 0;
    final priority = _getPriority();

    return FutureBuilder<String>(
      future: _nameFuture,
      initialData: thread.fallbackDisplayName,
      builder: (context, snapshot) {
        final displayName = snapshot.data ?? thread.fallbackDisplayName;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.adminGlass.withValues(alpha: hasUnread ? 0.4 : 0.2)
                : hasUnread
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? AppColors.adminBorder : AppColors.borderLight),
              width: hasUnread ? 1.5 : 1,
            ),
            boxShadow: hasUnread
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              onTap: () => context.go(
                '/admin/chat/detail/${thread.userId}',
                extra: thread,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // Avatar with priority indicator
                    Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: hasUnread
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : (isDark
                                      ? AppColors.adminSurface
                                      : AppColors.background),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasUnread
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              thread.userEmail.isNotEmpty
                                  ? thread.userEmail[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: hasUnread
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.adminTextSecondary
                                          : AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _getPriorityColor(priority),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.adminBackground
                                      : Colors.white,
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
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(thread.lastMessageTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.adminTextSecondary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  thread.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: hasUnread
                                        ? (isDark
                                              ? Colors.white.withValues(alpha: 0.9)
                                              : AppColors.textPrimary)
                                        : (isDark
                                              ? AppColors.adminTextSecondary
                                              : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                              if (hasUnread) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    thread.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (priority == 'high' || priority == 'critical') ...[
                            const SizedBox(height: 8),
                            _PriorityBadge(priority: priority, isDark: isDark),
                          ],
                        ],
                      ),
                    ),

                    // Delete conversation (both sides)
                    IconButton(
                      tooltip: 'Delete conversation',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.statusDanger.withValues(alpha: 0.85),
                      ),
                      onPressed: () => _confirmDelete(displayName),
                    ),

                    // Chevron
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return AppColors.riskCritical;
      case 'high':
        return AppColors.riskHigh;
      case 'medium':
        return AppColors.statusWarning;
      default:
        return AppColors.statusSuccess;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  final bool isDark;

  const _PriorityBadge({required this.priority, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = priority == 'critical'
        ? AppColors.riskCritical
        : AppColors.riskHigh;
    final label = priority == 'critical' ? 'URGENT' : 'HIGH PRIORITY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Supporting Widgets
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isOutlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isDark,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : AppColors.primary,
        foregroundColor: isOutlined
            ? (isDark ? Colors.white : AppColors.textPrimary)
            : Colors.white,
        elevation: isOutlined ? 0 : 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: isOutlined
              ? BorderSide(
                  color: isDark ? AppColors.adminBorder : AppColors.borderLight,
                )
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.adminGlass.withValues(alpha: 0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // Fix unbounded height constraint
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterToggle({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.3)
                    : Colors.white),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.5)
                : (isDark ? AppColors.adminBorder : AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isActive
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final Function(String) onChanged;
  final bool isDark;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
          ),
          dropdownColor: isDark ? AppColors.adminSurface : Colors.white,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: items.entries.map((e) {
            return DropdownMenuItem(value: e.key, child: Text(e.value));
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;
  final bool isDark;
  final Color? badgeColor;

  const _TabWithBadge({
    required this.label,
    required this.count,
    required this.isDark,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor ?? AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;
  final bool isDark;

  const _EmptyState({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final messages = {
      'all': 'No active conversations',
      'unread': 'All messages are read',
      'priority': 'No priority messages',
    };

    final icons = {
      'all': Icons.forum_outlined,
      'unread': Icons.mark_email_read_outlined,
      'priority': Icons.priority_high_outlined,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.adminGlass.withValues(alpha: 0.2)
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icons[type] ?? Icons.forum_outlined,
              size: 48,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            messages[type] ?? 'No conversations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;

  const _ErrorState({required this.error, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.statusDanger,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading chats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
