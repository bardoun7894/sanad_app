import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../services/admin_chat_service.dart';
import '../widgets/admin_bento_ui.dart';
import '../widgets/chat/admin_chat_conversation_pane.dart';
import '../widgets/chat/admin_chat_dialogs.dart';

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

class _AdminChatListScreenState extends ConsumerState<AdminChatListScreen> {
  final _searchController = TextEditingController();
  final _chatService = AdminChatService();
  late Stream<List<ChatThread>> _threadsStream;
  String _activeTab = 'all'; // 'all' | 'unread' | 'priority'
  String? _selectedUserId;
  ChatThread? _adHocThread;

  @override
  void initState() {
    super.initState();
    _threadsStream = _chatService.getChatThreads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _threadsStream = _chatService.getChatThreads();
    });
  }

  List<ChatThread> _applyFilters(List<ChatThread> threads, ChatFilter filter) {
    return threads.where((t) {
      if (_activeTab == 'unread' && t.unreadCount <= 0) return false;
      if (_activeTab == 'priority' && t.unreadCount <= 3) return false;
      if (filter.showUnreadOnly && t.unreadCount <= 0) return false;

      if (filter.priority != 'all') {
        final p = _priorityOf(t);
        if (filter.priority == 'high' && p != 'high' && p != 'critical') {
          return false;
        }
        if (filter.priority == 'medium' && p != 'medium') return false;
        if (filter.priority == 'low' && p != 'low') return false;
      }

      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        final match =
            t.userName.toLowerCase().contains(q) ||
            t.userEmail.toLowerCase().contains(q) ||
            t.lastMessage.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  String _priorityOf(ChatThread t) {
    if (t.unreadCount > 5) return 'critical';
    if (t.unreadCount > 3) return 'high';
    if (t.unreadCount > 0) return 'medium';
    return 'low';
  }

  void _openThread(ChatThread thread, bool isSplitView) {
    if (isSplitView) {
      setState(() {
        _selectedUserId = thread.userId;
        _adHocThread = thread;
      });
    } else {
      context.go('/admin/chat/detail/${thread.userId}', extra: thread);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = ref.watch(languageProvider).language == AppLanguage.arabic;
    final filter = ref.watch(chatFilterProvider);
    final isMobile = AdminResponsive.isMobile(context);
    final pad = isMobile ? 14.0 : 22.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(pad),
        child: StreamBuilder<List<ChatThread>>(
          stream: _threadsStream,
          builder: (context, snapshot) {
            final allThreads = snapshot.data ?? const <ChatThread>[];
            final filtered = _applyFilters(allThreads, filter);
            final totalUnread = allThreads.fold<int>(
              0,
              (sum, t) => sum + t.unreadCount,
            );
            final unreadThreads = allThreads
                .where((t) => t.unreadCount > 0)
                .length;
            final priorityThreads = allThreads
                .where((t) => t.unreadCount > 3)
                .length;

            // Resolve active thread for desktop split-pane
            ChatThread? activeThread;
            if (_selectedUserId != null) {
              for (final t in allThreads) {
                if (t.userId == _selectedUserId) {
                  activeThread = t;
                  break;
                }
              }
              activeThread ??= _adHocThread?.userId == _selectedUserId
                  ? _adHocThread
                  : null;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isSplitView = constraints.maxWidth >= 980;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Command Header ──────────────────────────────────
                    AdminPageHeader(
                      title: isAr ? 'صندوق الدعم' : 'Support Inbox',
                      subtitle: isAr
                          ? 'إدارة محادثات الدعم الفني ومتابعة رسائل المرضى'
                          : 'Manage patient support conversations in real time',
                      actions: [
                        AdminBentoButton(
                          icon: Icons.campaign_rounded,
                          label: isAr ? 'رسالة جماعية' : 'Broadcast',
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const AdminBroadcastChatDialog(),
                          ),
                        ),
                        AdminBentoButton(
                          icon: Icons.add_comment_rounded,
                          label: isAr ? 'محادثة جديدة' : 'New Chat',
                          primary: true,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => AdminNewChatDialog(
                              onSelectThread: (thread) =>
                                  _openThread(thread, isSplitView),
                            ),
                          ),
                        ),
                        AdminHeaderIconButton(
                          icon: Icons.refresh_rounded,
                          tooltip: isAr ? 'تحديث' : 'Refresh',
                          onTap: _refresh,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Compact Bento Stats Row ─────────────────────────
                    _ChatStatsStrip(
                      isDark: isDark,
                      isAr: isAr,
                      totalThreads: allThreads.length,
                      totalUnread: totalUnread,
                      priorityCount: priorityThreads,
                    ),
                    const SizedBox(height: 16),

                    // ── Main Bento Inbox Workspace ──────────────────────
                    Expanded(
                      child: isSplitView
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 390,
                                  child: _InboxListPanel(
                                    isDark: isDark,
                                    isAr: isAr,
                                    isLoading:
                                        snapshot.connectionState ==
                                            ConnectionState.waiting &&
                                        allThreads.isEmpty,
                                    error: snapshot.hasError
                                        ? '${snapshot.error}'
                                        : null,
                                    filter: filter,
                                    activeTab: _activeTab,
                                    allCount: allThreads.length,
                                    unreadCount: unreadThreads,
                                    priorityCount: priorityThreads,
                                    threads: filtered,
                                    selectedUserId: activeThread?.userId,
                                    searchController: _searchController,
                                    onSearchChanged: (v) =>
                                        ref
                                            .read(chatFilterProvider.notifier)
                                            .state = filter.copyWith(
                                          searchQuery: v,
                                        ),
                                    onTabChanged: (t) =>
                                        setState(() => _activeTab = t),
                                    onToggleUnreadOnly: () =>
                                        ref
                                            .read(chatFilterProvider.notifier)
                                            .state = filter.copyWith(
                                          showUnreadOnly:
                                              !filter.showUnreadOnly,
                                        ),
                                    onPriorityChanged: (p) =>
                                        ref
                                            .read(chatFilterProvider.notifier)
                                            .state = filter.copyWith(
                                          priority: p,
                                        ),
                                    onSelectThread: (t) =>
                                        _openThread(t, isSplitView),
                                    onDeleted: (uid) {
                                      if (_selectedUserId == uid) {
                                        setState(() {
                                          _selectedUserId = null;
                                          _adHocThread = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: AdminBento.cardDecoration(
                                      isDark,
                                    ),
                                    child: activeThread != null
                                        ? AdminChatConversationPane(
                                            key: ValueKey(activeThread.userId),
                                            thread: activeThread,
                                            embedded: true,
                                            onOpenFullScreen: () => context.go(
                                              '/admin/chat/detail/${activeThread!.userId}',
                                              extra: activeThread,
                                            ),
                                          )
                                        : _EmptySelectionPane(
                                            isDark: isDark,
                                            isAr: isAr,
                                            hasThreads: filtered.isNotEmpty,
                                            onStartFirst: filtered.isNotEmpty
                                                ? () => _openThread(
                                                    filtered.first,
                                                    true,
                                                  )
                                                : null,
                                          ),
                                  ),
                                ),
                              ],
                            )
                          : _InboxListPanel(
                              isDark: isDark,
                              isAr: isAr,
                              isLoading:
                                  snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  allThreads.isEmpty,
                              error: snapshot.hasError
                                  ? '${snapshot.error}'
                                  : null,
                              filter: filter,
                              activeTab: _activeTab,
                              allCount: allThreads.length,
                              unreadCount: unreadThreads,
                              priorityCount: priorityThreads,
                              threads: filtered,
                              selectedUserId: null,
                              searchController: _searchController,
                              onSearchChanged: (v) =>
                                  ref
                                      .read(chatFilterProvider.notifier)
                                      .state = filter.copyWith(
                                    searchQuery: v,
                                  ),
                              onTabChanged: (t) =>
                                  setState(() => _activeTab = t),
                              onToggleUnreadOnly: () =>
                                  ref
                                      .read(chatFilterProvider.notifier)
                                      .state = filter.copyWith(
                                    showUnreadOnly: !filter.showUnreadOnly,
                                  ),
                              onPriorityChanged: (p) =>
                                  ref
                                      .read(chatFilterProvider.notifier)
                                      .state = filter.copyWith(
                                    priority: p,
                                  ),
                              onSelectThread: (t) => _openThread(t, false),
                              onDeleted: (_) {},
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChatStatsStrip extends StatelessWidget {
  final bool isDark;
  final bool isAr;
  final int totalThreads;
  final int totalUnread;
  final int priorityCount;

  const _ChatStatsStrip({
    required this.isDark,
    required this.isAr,
    required this.totalThreads,
    required this.totalUnread,
    required this.priorityCount,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.inbox_rounded,
        label: isAr ? 'إجمالي المحادثات' : 'Total Conversations',
        value: '$totalThreads',
        color: AppColors.primary,
      ),
      (
        icon: Icons.mark_email_unread_rounded,
        label: isAr ? 'رسائل غير مقروءة' : 'Unread Messages',
        value: '$totalUnread',
        color: AppColors.statusWarning,
      ),
      (
        icon: Icons.priority_high_rounded,
        label: isAr ? 'أولوية عالية' : 'High Priority',
        value: '$priorityCount',
        color: AppColors.statusDanger,
      ),
      (
        icon: Icons.check_circle_outline_rounded,
        label: isAr ? 'حالة الصندوق' : 'Queue Status',
        value: totalUnread > 0
            ? (isAr ? 'نشط' : 'Active')
            : (isAr ? 'مكتمل' : 'All Clear'),
        color: AppColors.statusSuccess,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 168),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: AdminBento.cardDecoration(isDark, radius: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: items[i].color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(items[i].icon, size: 17, color: items[i].color),
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        items[i].value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AdminBento.textPrimary(isDark),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AdminBento.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InboxListPanel extends StatelessWidget {
  final bool isDark;
  final bool isAr;
  final bool isLoading;
  final String? error;
  final ChatFilter filter;
  final String activeTab;
  final int allCount;
  final int unreadCount;
  final int priorityCount;
  final List<ChatThread> threads;
  final String? selectedUserId;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTabChanged;
  final VoidCallback onToggleUnreadOnly;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<ChatThread> onSelectThread;
  final ValueChanged<String> onDeleted;

  const _InboxListPanel({
    required this.isDark,
    required this.isAr,
    required this.isLoading,
    required this.error,
    required this.filter,
    required this.activeTab,
    required this.allCount,
    required this.unreadCount,
    required this.priorityCount,
    required this.threads,
    required this.selectedUserId,
    required this.searchController,
    required this.onSearchChanged,
    required this.onTabChanged,
    required this.onToggleUnreadOnly,
    required this.onPriorityChanged,
    required this.onSelectThread,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminBento.cardDecoration(isDark),
      child: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminBento.surfaceMuted(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminBento.borderStrong(isDark)),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AdminBento.textPrimary(isDark),
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      isDense: true,
                      hintText: isAr
                          ? 'ابحث بالاسم أو البريد أو الرسالة...'
                          : 'Search name, email, or message...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: AdminBento.textSecondary(isDark),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AdminBento.textSecondary(isDark),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Segmented Tabs (All / Unread / Priority)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AdminBento.surfaceMuted(isDark),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      _SegmentPill(
                        label: isAr ? 'الكل' : 'All',
                        count: allCount,
                        selected: activeTab == 'all',
                        isDark: isDark,
                        onTap: () => onTabChanged('all'),
                      ),
                      _SegmentPill(
                        label: isAr ? 'غير مقروء' : 'Unread',
                        count: unreadCount,
                        badgeColor: AppColors.statusWarning,
                        selected: activeTab == 'unread',
                        isDark: isDark,
                        onTap: () => onTabChanged('unread'),
                      ),
                      _SegmentPill(
                        label: isAr ? 'عاجل' : 'Priority',
                        count: priorityCount,
                        badgeColor: AppColors.statusDanger,
                        selected: activeTab == 'priority',
                        isDark: isDark,
                        onTap: () => onTabChanged('priority'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AdminBento.border(isDark)),

          // Thread List
          Expanded(
            child: error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  )
                : isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : threads.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 40,
                          color: AdminBento.textSecondary(
                            isDark,
                          ).withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isAr
                              ? 'لا توجد محادثات مطابقة'
                              : 'No matching conversations',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AdminBento.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return _BentoThreadRow(
                        key: ValueKey(thread.userId),
                        thread: thread,
                        isDark: isDark,
                        isAr: isAr,
                        selected: thread.userId == selectedUserId,
                        onTap: () => onSelectThread(thread),
                        onDeleted: () => onDeleted(thread.userId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String label;
  final int count;
  final Color? badgeColor;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.label,
    required this.count,
    this.badgeColor,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = badgeColor ?? AppColors.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AdminBento.surface(isDark) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AdminBento.textPrimary(isDark)
                        : AdminBento.textSecondary(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: selected ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoThreadRow extends StatefulWidget {
  final ChatThread thread;
  final bool isDark;
  final bool isAr;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  const _BentoThreadRow({
    super.key,
    required this.thread,
    required this.isDark,
    required this.isAr,
    required this.selected,
    required this.onTap,
    required this.onDeleted,
  });

  @override
  State<_BentoThreadRow> createState() => _BentoThreadRowState();
}

class _BentoThreadRowState extends State<_BentoThreadRow> {
  late final Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = AdminChatService().resolveDisplayNameForThread(widget.thread);
  }

  String _formatDate(DateTime date, bool isAr) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Now';
    if (diff.inMinutes < 60) {
      return isAr ? '${diff.inMinutes}د' : '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return isAr ? '${diff.inHours}س' : '${diff.inHours}h';
    }
    if (diff.inDays == 1) return isAr ? 'أمس' : '1d';
    if (diff.inDays < 7) {
      return isAr ? '${diff.inDays}ي' : '${diff.inDays}d';
    }
    return DateFormat('d MMM').format(date);
  }

  Future<void> _confirmDelete(String displayName) async {
    final isAr = widget.isAr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف المحادثة؟' : 'Delete conversation?'),
        content: Text(
          isAr
              ? 'سيتم حذف المحادثة مع "$displayName" نهائياً من لوحة التحكم وتطبيق المستخدم.'
              : 'This permanently deletes the chat with "$displayName" for both admin and client.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await AdminChatService().deleteChatThread(widget.thread.userId);
      widget.onDeleted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حذف المحادثة' : 'Conversation deleted'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'فشل الحذف: $e' : 'Failed to delete: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final isDark = widget.isDark;
    final isAr = widget.isAr;
    final hasUnread = thread.unreadCount > 0;
    final isUrgent = thread.unreadCount > 3;

    return FutureBuilder<String>(
      future: _nameFuture,
      initialData: thread.fallbackDisplayName,
      builder: (context, snapshot) {
        final displayName = snapshot.data ?? thread.fallbackDisplayName;
        final initial = displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : '?';

        return Material(
          color: widget.selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.09)
              : (hasUnread
                    ? AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04)
                    : Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.selected
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : (hasUnread
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.transparent),
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: hasUnread || widget.selected
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : AdminBento.surfaceMuted(isDark),
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: hasUnread || widget.selected
                                ? AppColors.primary
                                : AdminBento.textSecondary(isDark),
                          ),
                        ),
                      ),
                      if (hasUnread)
                        PositionedDirectional(
                          end: -1,
                          bottom: -1,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? AppColors.statusDanger
                                  : AppColors.statusWarning,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AdminBento.surface(isDark),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: hasUnread || widget.selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: AdminBento.textPrimary(isDark),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(thread.lastMessageTime, isAr),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? AppColors.primary
                                    : AdminBento.textSecondary(isDark),
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                thread.lastMessage.isEmpty
                                    ? (isAr ? 'محادثة جديدة' : 'New chat')
                                    : thread.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: hasUnread
                                      ? AdminBento.textPrimary(
                                          isDark,
                                        ).withValues(alpha: 0.85)
                                      : AdminBento.textSecondary(isDark),
                                ),
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isUrgent
                                      ? AppColors.statusDanger
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${thread.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: isAr ? 'حذف المحادثة' : 'Delete conversation',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AdminBento.textSecondary(
                        isDark,
                      ).withValues(alpha: 0.7),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    onPressed: () => _confirmDelete(displayName),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptySelectionPane extends StatelessWidget {
  final bool isDark;
  final bool isAr;
  final bool hasThreads;
  final VoidCallback? onStartFirst;

  const _EmptySelectionPane({
    required this.isDark,
    required this.isAr,
    required this.hasThreads,
    this.onStartFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAr ? 'اختر محادثة للبدء' : 'Select a conversation',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AdminBento.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'اضغط على أي محادثة من القائمة الجانبية للرد مباشرة دون مغادرة الصفحة.'
                  : 'Pick any thread from the inbox to reply right here without leaving the page.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AdminBento.textSecondary(isDark),
              ),
            ),
            if (hasThreads && onStartFirst != null) ...[
              const SizedBox(height: 18),
              AdminBentoButton(
                icon: Icons.mark_chat_read_rounded,
                label: isAr ? 'فتح أحدث محادثة' : 'Open latest thread',
                primary: true,
                onPressed: onStartFirst,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
