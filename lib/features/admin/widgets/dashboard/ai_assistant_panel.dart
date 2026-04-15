import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/services/app_config.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/risk_alerts_provider.dart';

// ── Data model for a single admin chat message ───────────────────────────

class _AdminChatMessage {
  final String id;
  final String content;
  final String role; // 'user' | 'model'
  final DateTime timestamp;

  _AdminChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  bool get isUser => role == 'user';

  Map<String, dynamic> toFirestore() => {
    'content': content,
    'role': role,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  factory _AdminChatMessage.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return _AdminChatMessage(
      id: id,
      content: data['content'] as String? ?? '',
      role: data['role'] as String? ?? 'model',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

// ── Main Panel Widget ────────────────────────────────────────────────────

class AiAssistantPanel extends ConsumerStatefulWidget {
  const AiAssistantPanel({super.key});

  @override
  ConsumerState<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends ConsumerState<AiAssistantPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;

  GeminiService? _aiService;
  String? _lastKnownKey;
  bool _isTyping = false;
  bool _isLoadingHistory = true;
  bool _hasText = false;

  /// In-memory message list (source of truth for UI).
  final List<_AdminChatMessage> _messages = [];

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    // Load history then auto-prompt if empty
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadHistory();
    if (_messages.isEmpty) {
      await _sendDefaultPrompt();
    }
  }

  // ── GeminiService (lazy, key-aware) ────────────────────────────────────

  GeminiService? _getAiService() {
    final key = AppConfig.geminiApiKey;
    if (key.isEmpty) return null;
    if (_aiService == null || _lastKnownKey != key) {
      _aiService = GeminiService(apiKey: key);
      _lastKnownKey = key;
    }
    return _aiService;
  }

  // ── Firestore helpers ──────────────────────────────────────────────────

  String? get _adminId => ref.read(currentUserProvider)?.uid;

  CollectionReference _messagesCol(String adminId) => _firestore
      .collection('admin_ai_chats')
      .doc(adminId)
      .collection('messages');

  Future<void> _loadHistory() async {
    final adminId = _adminId;
    if (adminId == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final snap = await _messagesCol(
        adminId,
      ).orderBy('timestamp', descending: false).limit(100).get();

      final loaded = snap.docs.map((doc) {
        return _AdminChatMessage.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(loaded);
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Admin AI: failed to load history: $e');
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveMessage(_AdminChatMessage msg) async {
    final adminId = _adminId;
    if (adminId == null) return;
    try {
      await _messagesCol(adminId).doc(msg.id).set(msg.toFirestore());
    } catch (e) {
      debugPrint('Admin AI: failed to save message: $e');
    }
  }

  Future<void> _clearHistory() async {
    final adminId = _adminId;
    if (adminId == null) return;
    try {
      final snap = await _messagesCol(adminId).get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Admin AI: failed to clear history: $e');
    }
  }

  // ── Stats context (system prompt for admin) ────────────────────────────

  String _buildStatsContext() {
    final statsAsync = ref.read(dashboardStatsProvider);
    final riskAsync = ref.read(riskAlertsProvider);

    final buffer = StringBuffer();
    buffer.writeln('أنت المساعد الذكي للوحة إدارة تطبيق سند للصحة النفسية.');
    buffer.writeln(
      'You are the AI assistant for the Sanad mental health clinic admin dashboard.',
    );
    buffer.writeln('الإحصائيات الحالية / Current real-time stats:\n');

    statsAsync.whenData((stats) {
      buffer.writeln('- إجمالي المستخدمين / Total users: ${stats.totalUsers}');
      buffer.writeln(
        '- المستخدمون النشطون (آخر 30 يوم) / Active users (30d): ${stats.activeUsers}',
      );
      buffer.writeln(
        '- مستخدمون جدد هذا الشهر / New this month: ${stats.newUsersThisMonth}',
      );
      buffer.writeln(
        '- المشتركون المميزون / Premium subscribers: ${stats.premiumUsers}',
      );
      buffer.writeln(
        '- الجلسات اليوم / Sessions today: ${stats.sessionsToday}',
      );
      buffer.writeln(
        '- جلسات معلقة / Pending sessions: ${stats.pendingSessions}',
      );
      buffer.writeln(
        '- إجمالي الإيرادات / Total revenue: ${stats.formattedRevenue}',
      );
      buffer.writeln('- تنبيهات حرجة / Critical flags: ${stats.criticalFlags}');
    });

    riskAsync.whenData((alerts) {
      if (alerts.isNotEmpty) {
        buffer.writeln(
          '\nتنبيهات المخاطر / Risk Alerts (${alerts.length} total):',
        );
        for (final alert in alerts.take(5)) {
          buffer.writeln(
            '  - ${alert.patientName}: ${alert.level.name} risk (mood declining ${alert.daysCount} days)',
          );
        }
      } else {
        buffer.writeln('\nلا توجد تنبيهات مخاطر نشطة / No active risk alerts.');
      }
    });

    buffer.writeln(
      '\nأجب دائمًا باللغة العربية كلغة افتراضية. إذا كتب المسؤول بلغة أخرى، أجب بنفس اللغة.',
    );
    buffer.writeln(
      'Default response language: Arabic. If the admin writes in another language, respond in that language.',
    );

    return buffer.toString();
  }

  // ── Default auto-prompt (Arabic dashboard briefing) ────────────────────

  static const _defaultPrompt =
      'قدم لي ملخصاً شاملاً عن حالة التطبيق اليوم: '
      'عدد المستخدمين النشطين، الجلسات، تنبيهات المخاطر، '
      'المستخدمين الذين يحتاجون متابعة، والتوصيات العاجلة. '
      'كن مختصراً ومباشراً مثل تقرير صباحي لمدير العيادة.';

  Future<void> _sendDefaultPrompt() async {
    await _sendMessage(_defaultPrompt, isAutoPrompt: true);
  }

  // ── Send message flow ──────────────────────────────────────────────────

  Future<void> _sendMessage(String content, {bool isAutoPrompt = false}) async {
    final aiService = _getAiService();
    final adminId = _adminId;

    if (aiService == null || adminId == null) {
      final s = S(ref.read(languageProvider).language);
      _addBotMessage('${s.aiNotConfigured}\n${s.aiConfigureHint}');
      return;
    }

    // 1. Add user message to UI + Firestore
    final userMsg = _AdminChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: 'user',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();
    _saveMessage(userMsg);

    // 2. Build history for Gemini context
    final geminiHistory = _messages
        .map((m) => GeminiChatMessage(role: m.role, content: m.content))
        .toList();

    // 3. Call Gemini
    try {
      final response = await aiService.sendMessage(
        messages: geminiHistory,
        systemPrompt: _buildStatsContext(),
      );

      if (!mounted) return;

      // 4. Add bot response
      final botMsg = _AdminChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: response.content,
        role: 'model',
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(botMsg);
        _isTyping = false;
      });
      _scrollToBottom();
      _saveMessage(botMsg);
    } catch (e) {
      debugPrint('Admin AI error: $e');
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage(S(ref.read(languageProvider).language).error);
    }
  }

  void _addBotMessage(String content) {
    final msg = _AdminChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      content: content,
      role: 'model',
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(msg));
    _scrollToBottom();
    _saveMessage(msg);
  }

  // ── New chat ───────────────────────────────────────────────────────────

  Future<void> _handleNewChat() async {
    setState(() {
      _messages.clear();
      _isTyping = false;
    });
    await _clearHistory();
    await _sendDefaultPrompt();
  }

  // ── UI helpers ─────────────────────────────────────────────────────────

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

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _sendMessage(text);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = false;
    final s = S(ref.watch(languageProvider).language);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.adminGlass.withValues(alpha: 0.3),
                ]
              : [AppColors.primary.withValues(alpha: 0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
          _buildHeader(isDark, s),

          Divider(
            height: 1,
            color: isDark
                ? AppColors.adminBorder.withValues(alpha: 0.5)
                : AppColors.border,
          ),

          // ── Messages ─────────────────────────────────────────────────
          Expanded(
            child: _isLoadingHistory
                ? _buildLoadingState(isDark, s)
                : _messages.isEmpty && !_isTyping
                ? _buildEmptyState(isDark, s)
                : _buildMessagesList(isDark),
          ),

          // ── Input bar ────────────────────────────────────────────────
          _buildInputBar(isDark, s),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.aiAssistant,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  s.aiAssistantSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // New Chat button
          IconButton(
            icon: Icon(Icons.add_comment_rounded, size: 20),
            color: AppColors.primary,
            tooltip: s.newChat,
            onPressed: _handleNewChat,
          ),
        ],
      ),
    );
  }

  // ── Loading state ──────────────────────────────────────────────────────

  Widget _buildLoadingState(bool isDark, S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.analyzingData,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark, S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_rounded,
            size: 40,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            s.getAiInsights,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Messages list ──────────────────────────────────────────────────────

  Widget _buildMessagesList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator as last item
        if (index == _messages.length) {
          return _buildTypingIndicator(isDark);
        }
        return _buildBubble(_messages[index], isDark);
      },
    );
  }

  // ── Chat bubble ────────────────────────────────────────────────────────

  Widget _buildBubble(_AdminChatMessage msg, bool isDark) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot avatar
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : isDark
                    ? AppColors.adminSurface.withValues(alpha: 0.8)
                    : AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.adminBorder.withValues(alpha: 0.5)
                            : AppColors.border,
                        width: 0.5,
                      ),
              ),
              child: SelectableText(
                msg.content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isUser
                      ? Colors.white
                      : isDark
                      ? AppColors.adminTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Right spacing for bot messages
          if (!isUser) const SizedBox(width: 28),
          // Left spacing for user messages
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Typing indicator ───────────────────────────────────────────────────

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.adminSurface.withValues(alpha: 0.8)
                  : AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.adminBorder.withValues(alpha: 0.5)
                    : AppColors.border,
                width: 0.5,
              ),
            ),
            child: _BouncingDots(),
          ),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.adminBorder.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.adminTextPrimary
                    : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: s.askFollowUpQuestion,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: _hasText ? AppColors.primary : Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _hasText ? _handleSend : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: _hasText
                      ? Colors.white
                      : isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bouncing dots animation ──────────────────────────────────────────────

class _BouncingDots extends StatefulWidget {
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });

    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 0,
        end: -6,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    // Stagger the animations
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: child,
            );
          },
          child: Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

// ── Compact FAB for mobile ───────────────────────────────────────────────

class CompactAiButton extends ConsumerWidget {
  final VoidCallback onTap;

  const CompactAiButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S(ref.watch(languageProvider).language);
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
      label: Text(s.aiInsights),
    );
  }
}
