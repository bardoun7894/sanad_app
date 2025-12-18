import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/widgets/sanad_button.dart';
import '../subscription/providers/feature_gating_provider.dart';
import '../subscription/widgets/paywall_overlay.dart';
import 'providers/chat_provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/quick_replies.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Check access after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkChatAccess();
    });
  }

  void _checkChatAccess() {
    final canAccess = ref.read(canAccessChatProvider);
    if (!canAccess) {
      final s = ref.read(stringsProvider);
      showPaywallOverlay(
        context,
        featureName: s.unlimitedChat,
        featureDescription: s.chatWithAiAndTherapists,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _showEscalateDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.read(stringsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 32,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.talkToTherapist,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.connectWithProfessional,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to therapist booking
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    s.bookSession,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  s.continueChatting,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canAccess = ref.watch(canAccessChatProvider);
    final s = ref.watch(stringsProvider);

    // Scroll to bottom when messages change
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    if (!canAccess) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(s.unlimitedChat),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                s.subscriptionRequired,
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                s.chatWithAiAndTherapists,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SanadButton(
                text: s.upgradeToPremium,
                onPressed: () => context.push('/subscription'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header
          ChatHeader(
            onBack: () => Navigator.of(context).pop(),
            onEscalate: _showEscalateDialog,
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 16),
              itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (chatState.isTyping && index == chatState.messages.length) {
                  return const TypingIndicator();
                }
                return ChatBubble(message: chatState.messages[index]);
              },
            ),
          ),

          // Quick replies
          if (chatState.quickReplies.isNotEmpty)
            QuickReplies(
              replies: chatState.quickReplies,
              onSelect: (reply) {
                ref.read(chatProvider.notifier).selectQuickReply(reply);
              },
            ),

          // Input bar
          ChatInputBar(
            onSend: (message) {
              ref.read(chatProvider.notifier).sendMessage(message);
            },
            isEnabled: !chatState.isTyping,
          ),
        ],
      ),
    );
  }
}
