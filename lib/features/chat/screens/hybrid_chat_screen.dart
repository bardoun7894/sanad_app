import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/message.dart';
import '../models/ai_persona.dart';
import '../providers/chat_provider.dart';
import '../providers/hybrid_chat_provider.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_mode_indicator.dart';
import '../widgets/request_therapist_button.dart';
import '../widgets/handoff_transition.dart';
import '../widgets/handoff_system_message.dart';

/// Unified hybrid chat screen that wraps the existing AI chat with handoff
/// capability to a live therapist.
///
/// Layers:
/// 1. [ChatHeader] at the top (mode-aware)
/// 2. [ChatModeIndicator] banner below the header
/// 3. Message list (AI messages from [chatProvider] or therapist view)
/// 4. [RequestTherapistButton] floating above the input when suggested
/// 5. [HandoffTransition] overlay during mode switch
class HybridChatScreen extends ConsumerStatefulWidget {
  const HybridChatScreen({super.key});

  @override
  ConsumerState<HybridChatScreen> createState() => _HybridChatScreenState();
}

class _HybridChatScreenState extends ConsumerState<HybridChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _hydratePersonaFromFirestore();
  }

  /// Load the persisted persona from Firestore on startup so the chip row
  /// reflects the last-used persona after a cold start.
  Future<void> _hydratePersonaFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ai_chats')
          .doc(uid)
          .get();
      if (!mounted) return;
      final savedId = doc.data()?['persona'] as String?;
      if (savedId != null) {
        ref.read(aiPersonaProvider.notifier).state =
            AiPersonaX.fromId(savedId);
      }
    } catch (_) {
      // Non-critical — defaults to companion if load fails.
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Persist the chosen persona to the ai_chats/{uid} doc so the Cloud
  /// Function can also read it server-side if needed.
  Future<void> _persistPersona(AiPersona persona) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('ai_chats')
        .doc(uid)
        .set({'persona': persona.id}, SetOptions(merge: true));
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
    final s = ref.watch(stringsProvider);
    final hybridState = ref.watch(hybridChatProvider);
    final chatState = ref.watch(chatProvider);

    // Auto-scroll on new messages
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if ((previous?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    // Navigate to therapist chat when mode switches
    ref.listen<HybridChatState>(hybridChatProvider, (previous, next) {
      if (previous?.currentMode == 'ai' &&
          next.currentMode == 'therapist' &&
          next.activeHandoff?.therapistChatId != null) {
        context.push('/therapist-chat/${next.activeHandoff!.therapistChatId}');
      }
    });

    final chatMode = hybridState.currentMode == 'therapist'
        ? ChatMode.therapist
        : ChatMode.ai;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Header
              ChatHeader(
                onBack: () => context.pop(),
                onEscalate: () {
                  final notifier = ref.read(hybridChatProvider.notifier);
                  notifier.checkForHandoffSuggestion(
                    latestResponse: chatState.messages.isNotEmpty
                        ? chatState.messages.last.content
                        : '',
                  );
                },
                chatMode: chatMode,
                therapistName: hybridState.activeHandoff?.therapistName,
                isOnline: true,
              ),

              // Mode indicator banner
              const ChatModeIndicator(),

              // Persona selector — only visible in AI mode
              if (hybridState.currentMode == 'ai')
                _PersonaSelector(
                  isDark: isDark,
                  s: s,
                  onPersonaChanged: _persistPersona,
                ),

              // Error banner
              if (hybridState.error != null)
                _ErrorBanner(
                  error: hybridState.error!,
                  onDismiss: () {
                    ref.read(hybridChatProvider.notifier).clearError();
                  },
                ),

              // Message list
              Expanded(
                child: _buildMessageList(
                  context,
                  chatState,
                  hybridState,
                  isDark,
                  s,
                ),
              ),

              // Request therapist button (above input)
              if (hybridState.hasSuggestion && hybridState.currentMode == 'ai')
                const RequestTherapistButton(),

              // Input bar
              if (hybridState.currentMode == 'ai')
                _ChatInputBar(
                  controller: _messageController,
                  isDark: isDark,
                  isTyping: chatState.isTyping,
                  onSend: (text) {
                    if (text.trim().isEmpty) return;
                    ref.read(chatProvider.notifier).sendMessage(text.trim());
                    _messageController.clear();
                    _scrollToBottom();
                  },
                  strings: s,
                  isRtl: ref.watch(languageProvider).isRtl,
                ),
            ],
          ),

          // Handoff transition overlay
          if (hybridState.isTransitioning) const HandoffTransition(),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    ChatState chatState,
    HybridChatState hybridState,
    bool isDark,
    S s,
  ) {
    final messages = chatState.messages;

    if (messages.isEmpty) {
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
                      Icons.forum_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.startTheConversation,
                    textAlign: TextAlign.center,
                    style: AppTypography.headingLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.supportWelcomeMessage,
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (chatState.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator at the end
        if (index == messages.length && chatState.isTyping) {
          return _TypingIndicator(isDark: isDark);
        }

        final message = messages[index];

        // Check if there's a handoff event to show before this message
        if (hybridState.activeHandoff != null && index == messages.length - 1) {
          return Column(
            children: [
              HandoffSystemMessage(handoff: hybridState.activeHandoff!),
              _MessageBubble(message: message, isDark: isDark),
            ],
          );
        }

        return _MessageBubble(message: message, isDark: isDark);
      },
    );
  }
}

// ── Persona Selector ───────────────────────────────────────────────────────

class _PersonaSelector extends ConsumerWidget {
  final bool isDark;
  final S s;
  final Future<void> Function(AiPersona) onPersonaChanged;

  const _PersonaSelector({
    required this.isDark,
    required this.s,
    required this.onPersonaChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(aiPersonaProvider);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: AiPersona.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final persona = AiPersona.values[index];
          final isSelected = persona == selected;
          return _PersonaChip(
            persona: persona,
            isSelected: isSelected,
            isDark: isDark,
            label: persona.localizedLabel(s),
            onTap: () {
              ref.read(aiPersonaProvider.notifier).state = persona;
              onPersonaChanged(persona);
            },
          );
        },
      ),
    );
  }
}

class _PersonaChip extends StatelessWidget {
  final AiPersona persona;
  final bool isSelected;
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  const _PersonaChip({
    required this.persona,
    required this.isSelected,
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.surfaceDark
                  : AppColors.borderLight.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              persona.icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textMuted : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textMuted : AppColors.textSecondary),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input Bar ──────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isTyping;
  final ValueChanged<String> onSend;
  final S strings;
  final bool isRtl;

  const _ChatInputBar({
    required this.controller,
    required this.isDark,
    required this.isTyping,
    required this.onSend,
    required this.strings,
    required this.isRtl,
  });

  Widget build(BuildContext context) {
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
                        controller: controller,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: onSend,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: strings.typeMessage,
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: GestureDetector(
                        onTap: () => onSend(controller.text),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.gradientStart,
                                AppColors.gradientEnd,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Transform.flip(
                            flipX: isRtl,
                            child: const Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: Colors.white,
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

// ── Message Bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            message.content,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
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
          border: isUser
              ? null
              : Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight.withValues(alpha: 0.5),
                ),
        ),
        child: Text(
          message.content,
          style: AppTypography.bodyMedium.copyWith(
            color: isUser
                ? Colors.white
                : (isDark ? Colors.white : AppColors.textPrimary),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ── Typing Indicator ───────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final bool isDark;

  const _TypingIndicator({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
              child: _DotPulse(delay: i * 200),
            );
          }),
        ),
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  final int delay;

  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 16, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
