import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/providers/system_settings_provider.dart';
import '../../admin/services/admin_chat_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../providers/user_support_chat_provider.dart';

/// Screen for users to chat with support team
class UserSupportChatScreen extends ConsumerStatefulWidget {
  final String? aiContext; // Context from AI escalation

  const UserSupportChatScreen({super.key, this.aiContext});

  @override
  ConsumerState<UserSupportChatScreen> createState() =>
      _UserSupportChatScreenState();
}

class _UserSupportChatScreenState extends ConsumerState<UserSupportChatScreen> {
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
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final s = ref.watch(stringsProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.support)),
        body: Center(child: Text(s.pleaseLoginToContactSupport)),
      );
    }

    final params = SupportChatParams(userId: user.uid, userEmail: user.email);

    final sessionState = ref.watch(supportChatNotifierProvider(params));
    final messagesAsync = ref.watch(supportMessagesProvider(user.uid));
    // Listen for errors and show SnackBar
    ref.listen<SupportChatState>(supportChatNotifierProvider(params), (
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

    // ── Trial paywall gate ────────────────────────────────────────────────
    // Fail-open on settings load/error — never block on a transient failure.
    final settingsAsync = ref.watch(systemSettingsProvider);
    final settings = settingsAsync.maybeWhen(
      data: (s2) => s2,
      orElse: () => null,
    );

    // Subscription: fail-open (treat unknown as tier 0) but do NOT gate while
    // loading — the loading state means we can't confirm gating yet.
    final subState = ref.watch(subscriptionProvider);
    final tierLevel = subState.isLoading ? 1 : subState.status.tierLevel;

    // Compute gate: require settings loaded + a configured trial-start date.
    // Grandfather rule — only accounts created ON OR AFTER
    // supportTrialStartDate are subject to the paywall; existing users (and
    // everyone if the date is unset) are never gated.
    bool gated = false;
    final trialStart = settings?.supportTrialStartDate;
    if (settings != null && !settings.supportOpenToAll && trialStart != null) {
      final createdAt = user.createdAt;
      final inProgram = !createdAt.isBefore(trialStart);
      final supportTrialDays = settings.supportTrialDays;
      if (inProgram && supportTrialDays >= 0) {
        final trialEnded = DateTime.now().isAfter(
          createdAt.add(Duration(days: supportTrialDays)),
        );
        gated = trialEnded && tierLevel < 1;
      }
    }
    // ─────────────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B141A) // WhatsApp Dark background
          : const Color(0xFFEFEAE2), // WhatsApp Light background
      appBar: _buildAppBar(isDark, s),
      body: Column(
        children: [
          // Info banner
          _buildInfoBanner(isDark, s),

          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                _scrollToBottom();
                if (messages.isEmpty) {
                  return _buildEmptyState(isDark, s);
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isFromUser =
                        message.senderId != 'admin' &&
                        message.senderId != 'system';
                    return _MessageBubble(
                      message: message,
                      isFromUser: isFromUser,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),

          // Input bar or trial-ended paywall
          if (gated)
            _buildTrialEndedBanner(isDark, s)
          else
            _buildInputBar(isDark, sessionState, params, s),
        ],
      ),
    );
  }

  Widget _buildTrialEndedBanner(bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.supportTrialEnded,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.go('/subscription'),
                child: Text(
                  s.subscribeToContinue,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, S s) {
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF202C33)
                  : const Color(0xFF00A884).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.supportTeam,
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  s.usuallyRespondsInHours,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark, S s) {
    if (widget.aiContext != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.contextSharedWithSupport,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(bool isDark, S s) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight.withValues(alpha: 0.5),
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
                        AppColors.gradientStart.withValues(alpha: 0.1),
                        AppColors.gradientEnd.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.startConversation,
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.sendMessageSupportWillRespond,
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

  Widget _buildInputBar(
    bool isDark,
    SupportChatState sessionState,
    SupportChatParams params,
    S s,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                      ? const Color(0xFF0F172A)
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
                          hintText: s.typeYourMessage,
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
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
                                          supportChatNotifierProvider(
                                            params,
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
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFromUser;

  const _MessageBubble({required this.message, required this.isFromUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // System message
    if (message.senderId == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Admin avatar
          if (!isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.support_agent_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
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
                if (message.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, progress) => progress == null
                          ? child
                          : const SizedBox(
                              width: 180,
                              height: 130,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                      errorBuilder: (c, e, s) => const SizedBox(
                        width: 180,
                        height: 130,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  if (message.content.isNotEmpty && message.content != '📷')
                    const SizedBox(height: 6),
                ],
                if (message.content.isNotEmpty && message.content != '📷')
                  Text(
                    message.content,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isFromUser
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.textPrimary),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
