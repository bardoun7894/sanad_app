import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/therapist_chat.dart';
import '../models/therapist_message.dart';
import '../providers/therapist_chat_provider.dart';
import '../../subscription/providers/feature_gating_provider.dart'; // Import feature gating
import '../../subscription/providers/subscription_provider.dart'; // For refresh
import 'package:go_router/go_router.dart'; // For navigation
import '../../auth/providers/auth_provider.dart'; // For current user
import '../../booking/providers/user_booking_provider.dart';
import '../../therapist_portal/models/therapist_booking.dart';
import '../../reviews/providers/review_provider.dart';

/// Chat screen for users to message their therapist
class UserTherapistChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final TherapistChatThread? initialThread;

  const UserTherapistChatScreen({
    super.key,
    required this.chatId,
    this.initialThread,
  });

  @override
  ConsumerState<UserTherapistChatScreen> createState() =>
      _UserTherapistChatScreenState();
}

class _UserTherapistChatScreenState
    extends ConsumerState<UserTherapistChatScreen> {
  static const Duration _ratingPromptDelay = Duration(minutes: 30);

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _ratingPromptShown = false;
  Timer? _ratingPromptTimer;

  @override
  void initState() {
    super.initState();
    _ratingPromptTimer = Timer(_ratingPromptDelay, _maybeShowTimedPrompt);
  }

  @override
  void dispose() {
    _ratingPromptTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Fires after the user has been in the chat for [_ratingPromptDelay].
  /// Prompts for a rating against the most recent non-cancelled booking
  /// with this therapist (preferring completed sessions).
  Future<void> _maybeShowTimedPrompt() async {
    if (!mounted || _ratingPromptShown) return;
    final booking = await _findRatableBooking();
    if (!mounted || booking == null) return;
    _ratingPromptShown = true;
    await _showRatingSheet(booking);
  }

  /// Resolve the therapist id from the initial thread or by parsing the chatId
  /// (chatId format: `{therapistId}_{userId}`).
  String? get _therapistId {
    if (widget.initialThread != null) return widget.initialThread!.therapistId;
    final parts = widget.chatId.split('_');
    if (parts.length < 2) return null;
    return parts.first;
  }

  /// One Firestore read returns every booking ID this user has already
  /// reviewed, then we filter the cached booking lists locally.
  Future<List<TherapistBooking>> _candidateBookings({
    required bool completedOnly,
  }) async {
    final user = ref.read(authProvider).user;
    final therapistId = _therapistId;
    if (user == null || therapistId == null) return const [];

    final past =
        ref.read(userPastBookingsProvider).valueOrNull ?? const [];
    final upcoming = completedOnly
        ? const <TherapistBooking>[]
        : (ref.read(userUpcomingBookingsProvider).valueOrNull ?? const []);

    final filtered = [...past, ...upcoming].where((b) {
      if (b.therapistId != therapistId) return false;
      if (completedOnly) return b.status == BookingStatus.completed;
      return b.status != BookingStatus.cancelled &&
          b.status != BookingStatus.rejected;
    }).toList()
      ..sort((a, b) {
        final aCompleted = a.status == BookingStatus.completed;
        final bCompleted = b.status == BookingStatus.completed;
        if (aCompleted != bCompleted) return aCompleted ? -1 : 1;
        return b.scheduledTime.compareTo(a.scheduledTime);
      });

    if (filtered.isEmpty) return const [];

    final reviewedIds =
        await ref.read(reviewedBookingIdsProvider(user.uid).future);
    return filtered.where((b) => !reviewedIds.contains(b.id)).toList();
  }

  /// Best booking for the timer / manual button: any non-cancelled,
  /// preferring completed sessions.
  Future<TherapistBooking?> _findRatableBooking() async {
    final candidates = await _candidateBookings(completedOnly: false);
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Best booking for the back-button prompt: only completed sessions.
  Future<TherapistBooking?> _findUnreviewedCompletedBooking() async {
    final candidates = await _candidateBookings(completedOnly: true);
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Pop the screen after (optionally) prompting the user to rate the most
  /// recent unreviewed completed session with this therapist. The prompt is
  /// shown at most once per screen lifetime. Every await is followed by a
  /// fresh mounted check so the final pop is safe.
  Future<void> _exitWithMaybePrompt() async {
    if (!_ratingPromptShown) {
      _ratingPromptShown = true;
      final booking = await _findUnreviewedCompletedBooking();
      if (!mounted) return;
      if (booking != null) {
        await _showRatingSheet(booking);
        if (!mounted) return;
      }
    }
    Navigator.of(context).pop();
  }

  /// Shows the stars-only bottom sheet and, if the user taps a star, opens
  /// the full review screen pre-filled with that rating. The sheet itself
  /// just returns the selected star number — navigation happens in the
  /// caller behind a fresh mounted check.
  Future<void> _showRatingSheet(TherapistBooking booking) async {
    final thread = widget.initialThread;
    final therapistName = thread?.therapistName ?? '';
    final therapistPhoto = thread?.therapistPhotoUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedRating = await showModalBottomSheet<int>(
      context: context,
      backgroundColor:
          isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(sheetContext).pop(starNumber),
                      child: Icon(
                        Icons.star_border_rounded,
                        size: 42,
                        color: isDark ? Colors.white70 : Colors.grey.shade500,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedRating == null) return;
    context.pushNamed(
      'leaveReview',
      extra: {
        'bookingId': booking.id,
        'therapistId': booking.therapistId,
        'therapistName': therapistName,
        'therapistPhoto': therapistPhoto,
        'initialRating': selectedRating,
      },
    );
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
      senderType: SenderType.user,
    );
    final sessionState = ref.watch(chatSessionProvider(sessionParams));
    final canSend = ref.watch(canSendMessagesProvider); // Check permissions
    final thread = widget.initialThread;
    final currentUser = ref.watch(authProvider).user;
    final s = ref.watch(stringsProvider);

    // Listen for errors and show SnackBar
    ref.listen<ChatSessionState>(chatSessionProvider(sessionParams), (
      previous,
      next,
    ) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exitWithMaybePrompt();
      },
      child: Scaffold(
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
                if (messages.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.gradientStart.withValues(
                                        alpha: 0.1,
                                      ),
                                      AppColors.gradientEnd.withValues(
                                        alpha: 0.1,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.psychology_rounded,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                s.startTheConversation,
                                textAlign: TextAlign.center,
                                style: AppTypography.headingLarge.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.therapistWelcomeMessage,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.textMuted
                                      : AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

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
                          isFromUser: message.isFromUser,
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
              if (typing.therapistTyping) {
                return _buildTypingIndicator(isDark, s);
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Input bar or Upgrade Prompt
          canSend
              ? _buildInputBar(isDark, sessionState, sessionParams, s)
              : _buildUpgradePrompt(isDark, context, s),
        ],
      ),
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
        onPressed: _exitWithMaybePrompt,
      ),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: thread?.therapistPhotoUrl != null
                ? ClipOval(
                    child: Image.network(
                      thread!.therapistPhotoUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      thread?.therapistName.isNotEmpty == true
                          ? thread!.therapistName[0].toUpperCase()
                          : 'T',
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread?.therapistName ?? s.yourTherapist,
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                typingAsync.maybeWhen(
                  data: (typing) {
                    if (typing.therapistTyping) {
                      return Text(
                        s.typingIndicator,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return Text(
                      s.licensedTherapist,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? Colors.white54
                            : AppColors.textLightSecondary,
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
        // Manual rate button — lets the user rate at any moment.
        IconButton(
          tooltip: s.leaveReview,
          icon: const Icon(Icons.star_rounded, color: Colors.amber),
          onPressed: () async {
            final booking = await _findRatableBooking();
            if (!mounted) return;
            if (booking == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.howWasYourSession)),
              );
              return;
            }
            _ratingPromptShown = true;
            await _showRatingSheet(booking);
          },
        ),
        // Call button intentionally hidden for patients — only the therapist
        // can initiate a call from their side of the conversation.
      ],
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

  Widget _buildTypingIndicator(bool isDark, S s) {
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
          const SizedBox(width: 8),
          Text(
            s.therapistIsTyping,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white54 : Colors.grey,
              fontStyle: FontStyle.italic,
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.transparent, width: 1.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
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
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            ref
                                .read(
                                  chatSessionProvider(sessionParams).notifier,
                                )
                                .onTyping();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: GestureDetector(
                        onTap: sessionState.isSending
                            ? null
                            : () async {
                                final content = _messageController.text.trim();
                                if (content.isNotEmpty) {
                                  try {
                                    await ref
                                        .read(
                                          chatSessionProvider(
                                            sessionParams,
                                          ).notifier,
                                        )
                                        .sendMessage(content);
                                    _messageController.clear();
                                    _scrollToBottom();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to send message: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                          action: SnackBarAction(
                                            label: 'Retry',
                                            textColor: Colors.white,
                                            onPressed: () {
                                              // Trigger send again with same content
                                              _messageController.text = content;
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sessionState.isSending
                                ? Colors.transparent
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: sessionState.isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Transform.flip(
                                  flipX: ref.watch(languageProvider).isRtl,
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                    textDirection: TextDirection.ltr,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildUpgradePrompt(bool isDark, BuildContext context, S s) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s.unlockChatAccess,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button to re-check subscription
              GestureDetector(
                onTap: () {
                  // Manually refresh subscription status
                  ref.read(subscriptionProvider.notifier).checkSubscription();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.refreshingSubscription)),
                  );
                },
                child: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.upgradeToPremiumToReply,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(s.upgradeNow),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TherapistMessage message;
  final bool isFromUser;

  const _MessageBubble({required this.message, required this.isFromUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.senderType == SenderType.system) {
      return _buildSystemMessage(isDark);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isFromUser
                  ? AppColors.primary
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isFromUser ? 20 : 4),
                bottomRight: Radius.circular(isFromUser ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
              border: isFromUser
                  ? null
                  : Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight.withValues(alpha: 0.5),
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isFromUser
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.timestamp),
                      style: AppTypography.caption.copyWith(
                        color: isFromUser
                            ? Colors.white70
                            : (isDark ? Colors.white38 : Colors.grey),
                        fontSize: 10,
                      ),
                    ),
                    if (isFromUser) ...[
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
