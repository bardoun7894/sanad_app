import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/services/zego_call_service.dart';
import '../models/therapist_chat.dart';
import '../models/therapist_message.dart';
import '../providers/therapist_chat_provider.dart';
import '../widgets/quick_reply_sheet.dart';
import '../widgets/session_timer.dart';
import '../../auth/providers/auth_provider.dart';

/// Chat detail screen for therapist-user conversation
class TherapistChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final TherapistChatThread? initialThread;

  const TherapistChatDetailScreen({
    super.key,
    required this.chatId,
    this.initialThread,
  });

  @override
  ConsumerState<TherapistChatDetailScreen> createState() =>
      _TherapistChatDetailScreenState();
}

class _TherapistChatDetailScreenState
    extends ConsumerState<TherapistChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final typingAsync = ref.watch(typingStatusProvider(widget.chatId));
    final sessionParams = ChatSessionParams(
      chatId: widget.chatId,
      senderType: SenderType.therapist,
    );
    final sessionState = ref.watch(chatSessionProvider(sessionParams));
    final thread = widget.initialThread;
    final currentUser = ref.watch(authProvider).user;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: _buildAppBar(isDark, typingAsync, thread, currentUser, s),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final showDate =
                        index == 0 ||
                        !_isSameDay(
                          messages[index - 1].timestamp,
                          message.timestamp,
                        );

                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(message.timestamp),
                        _MessageBubble(
                          message: message,
                          isFromTherapist: message.isFromTherapist,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),

          // Typing indicator
          typingAsync.maybeWhen(
            data: (typing) {
              if (typing.userTyping) {
                return _buildTypingIndicator(isDark);
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Input bar
          _buildInputBar(isDark, sessionState, sessionParams, s),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    bool isDark,
    AsyncValue<TypingStatus> typingAsync,
    TherapistChatThread? thread,
    dynamic currentUser,
    S s,
  ) {
    return AppBar(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: thread?.userPhotoUrl != null
                ? NetworkImage(thread!.userPhotoUrl!)
                : null,
            child: thread?.userPhotoUrl == null
                ? Text(
                    thread?.userName.isNotEmpty == true
                        ? thread!.userName[0].toUpperCase()
                        : 'U',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread?.userName ?? 'Client',
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontFamily: 'Tajawal',
                  ),
                ),
                if (thread?.bookingId != null) ...[
                  const SizedBox(height: 2),
                  SessionTimer(bookingId: thread!.bookingId!),
                ] else
                  typingAsync.maybeWhen(
                    data: (typing) {
                      if (typing.userTyping) {
                        return Text(
                          s.typingIndicator,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return Text(
                        s.onlineStatus,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Audio call button — uses Zego built-in call invitation
        IconButton(
          icon: Icon(
            Icons.phone,
            color: isDark ? Colors.white : AppColors.primary,
          ),
          onPressed: () async {
            if (currentUser == null || thread == null) return;

            final success = await ZegoCallService.instance.sendCallInvitation(
              targetUserId: thread.userId,
              targetUserName: thread.userName,
              callerUserId: currentUser.uid,
              callerName: currentUser.displayName ?? thread.therapistName,
              chatId: widget.chatId,
            );

            if (!success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.failedToInitiateCall),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          tooltip: 'Call',
        ),
        IconButton(
          icon: Icon(
            Icons.notification_important_rounded,
            color: Colors.red[400],
          ),
          onPressed: () => _showEmergencyDialog(s),
          tooltip: s.reportEmergency,
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDark
                ? Colors.white
                : const Color.fromARGB(255, 38, 34, 34),
          ),
          onPressed: () => _showOptionsMenu(s),
        ),
      ],
    );
  }

  void _showEmergencyDialog(S s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(s.reportEmergency),
          ],
        ),
        content: Text(s.emergencyFlagConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger alert logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.emergencyAlertSent),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(s.reportEmergency),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;

    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => _TypingDot(delay: index * 200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(
    bool isDark,
    ChatSessionState sessionState,
    ChatSessionParams sessionParams,
    S s,
  ) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: s.typeAMessage,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? Colors.white
                    : const Color.fromARGB(255, 0, 0, 0),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  ref
                      .read(chatSessionProvider(sessionParams).notifier)
                      .onTyping();
                }
              },
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => QuickReplySheet(
                  onReplySelected: (text) {
                    _messageController.text = text;
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                    FocusScope.of(context).requestFocus(_focusNode);
                    ref
                        .read(chatSessionProvider(sessionParams).notifier)
                        .onTyping();
                  },
                ),
              );
            },
            icon: Icon(
              Icons.flash_on_rounded,
              color: isDark ? Colors.orangeAccent : Colors.orange,
            ),
            tooltip: 'Quick Responses',
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: sessionState.isSending
                  ? null
                  : () {
                      final content = _messageController.text.trim();
                      if (content.isNotEmpty) {
                        ref
                            .read(chatSessionProvider(sessionParams).notifier)
                            .sendMessage(content);
                        _messageController.clear();
                        _scrollToBottom();
                      }
                    },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: sessionState.isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(s.viewProfile),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to client profile
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(s.viewBookings),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to bookings
                },
              ),
              ListTile(
                leading: Icon(Icons.archive_outlined, color: Colors.orange),
                title: Text(s.archiveChat),
                onTap: () {
                  Navigator.pop(context);
                  // Archive chat
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final TherapistMessage message;
  final bool isFromTherapist;

  const _MessageBubble({required this.message, required this.isFromTherapist});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.senderType == SenderType.system) {
      return _buildSystemMessage(isDark);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromTherapist
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isFromTherapist
                  ? AppColors.primary
                  : (isDark ? Colors.white10 : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isFromTherapist ? 20 : 4),
                bottomRight: Radius.circular(isFromTherapist ? 4 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isFromTherapist
                        ? Colors.white
                        : (isDark
                              ? Colors.white
                              : AppColors
                                    .textPrimary), // Fixed: Dark text on light bg
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.timestamp),
                      style: AppTypography.caption.copyWith(
                        color: isFromTherapist
                            ? Colors.white70
                            : (isDark ? Colors.white38 : Colors.grey),
                        fontSize: 10,
                      ),
                    ),
                    if (isFromTherapist) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: message.isRead ? Colors.white : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey[200],
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            message.content,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white54 : Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, _animation.value),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
