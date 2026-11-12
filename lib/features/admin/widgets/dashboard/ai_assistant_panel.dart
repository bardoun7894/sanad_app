import '../../../chat/services/ai_privacy_consent_service.dart';
import '../../../chat/widgets/ai_privacy_consent_dialog.dart';
import 'risk_alerts_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/services/app_config.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/risk_alerts_provider.dart';
import '../../providers/usage_insights_provider.dart';

// ── Data model for a single admin chat message ───────────────────────────

class _AdminChatMessage {
  final String id;
  final String content;
  final String role; // 'user' | 'model'
  final DateTime timestamp;
  final Set<String>? subjectUserIds;

  _AdminChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.subjectUserIds,
  });

  bool get isUser => role == 'user';

  Map<String, dynamic> toFirestore() => {
    'content': content,
    'role': role,
    'timestamp': Timestamp.fromDate(timestamp),
    if (subjectUserIds != null) 'ai_subject_user_ids': subjectUserIds!.toList(),
  };

  factory _AdminChatMessage.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return _AdminChatMessage(
      id: id,
      subjectUserIds: data['ai_subject_user_ids'] is List
          ? (data['ai_subject_user_ids'] as List).whereType<String>().toSet()
          : null,
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
  final FirebaseFirestore? firestore;
  final GeminiService? aiService;

  const AiAssistantPanel({super.key, this.firestore, this.aiService});

  @override
  ConsumerState<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends ConsumerState<AiAssistantPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late final _firestore = widget.firestore ?? FirebaseFirestore.instance;

  GeminiService? _aiService;
  String? _lastKnownKey;
  String? _historyAdminId;
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
      try {
        await ref.read(dashboardStatsProvider.future);
      } catch (_) {}
      if (!mounted) return;
      await _sendDefaultPrompt();
    }
  }

  // ── GeminiService (lazy, key-aware) ────────────────────────────────────

  GeminiService? _getAiService() {
    if (widget.aiService != null) return widget.aiService;
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

      if (!mounted || _adminId != adminId) return;
      _historyAdminId = adminId;
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

  String _buildStatsContext(
    List<RiskAlert> alerts, [
    AdminUsageInsights? insights,
  ]) {
    final statsAsync = ref.read(dashboardStatsProvider);

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
        '- المعالجون والأخصائيون / Therapists & clinicians: ${stats.therapistsCount}',
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
      buffer.writeln('\nإحصائيات تبويب المحتوى / Content & CMS stats:');
      buffer.writeln(
        '- إجمالي عناصر المحتوى / Total content items: ${stats.totalContentCount} (منشور / published: ${stats.publishedContentCount}، مسودة / drafts: ${stats.draftContentCount})',
      );
      buffer.writeln(
        '- عدد المقالات في تبويب المحتوى / Articles in Content tab: ${stats.articlesCount}',
      );
      buffer.writeln(
        '- عدد التمارين في تبويب المحتوى / Exercises in Content tab: ${stats.exercisesCount}',
      );
      buffer.writeln(
        '- عدد الفيديوهات في تبويب المحتوى / Videos in Content tab: ${stats.videosCount}',
      );
      buffer.writeln(
        '- الاقتباسات والنصائح اليومية / Daily quotes & tips: ${stats.dailyQuotesCount}',
      );
      buffer.writeln(
        '- التحديات اليومية / Daily challenges: ${stats.dailyChallengesCount}',
      );
      buffer.writeln(
        '- الاختبارات النفسية / Psychological tests: ${stats.psychTestsCount}',
      );
      buffer.writeln('- الأسئلة الشائعة / FAQs: ${stats.faqsCount}');
    });

    {
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
    }

    if (insights != null) {
      buffer.write(insights.toPromptContext());
    } else {
      buffer.writeln(
        '\nإحصائيات استخدام الأقسام غير متاحة الآن؛ إذا سُئلت عنها فاعتذر ولا تخمّن.',
      );
    }

    buffer.writeln(
      '\nأجب دائمًا باللغة العربية كلغة افتراضية وبأسلوب واضح ومباشر. إذا كتب المسؤول بلغة أخرى، أجب بنفس اللغة.',
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

    if (_historyAdminId != adminId) {
      _messages.clear();
      await _loadHistory();
    }
    if (!mounted || _adminId != adminId) return;
    if (!await ensureAiPrivacyConsent(context, ref)) return;
    if (!mounted || _adminId != adminId) return;
    final alerts = ref.read(riskAlertsProvider).valueOrNull ?? <RiskAlert>[];
    AdminUsageInsights? insights;
    try {
      insights = await ref.read(adminUsageInsightsProvider.future);
    } catch (e) {
      // Usage insights are optional context; the chat still works without them.
      debugPrint('Admin AI: usage insights unavailable: $e');
    }
    if (!mounted || _adminId != adminId) return;
    // Legacy history has no reliable patient provenance, so remains visible
    // locally but is excluded from new AI transfers.
    final transferableHistory = _messages
        .where((message) => message.subjectUserIds != null)
        .toList();
    final subjectUserIds = {
      for (final alert in alerts.take(5)) alert.patientId,
      ...?insights?.consentingTopUserIds,
      for (final message in transferableHistory) ...message.subjectUserIds!,
    };

    try {
      await ref
          .read(aiPrivacyConsentServiceProvider)
          .requireConsent(userId: adminId, subjectUserIds: subjectUserIds);
    } catch (_) {
      if (mounted)
        _addBotMessage(
          S(ref.read(languageProvider).language).aiConsentRequired,
        );
      return;
    }
    if (!mounted || _adminId != adminId) return;

    // 1. Add user message to UI + Firestore
    final userMsg = _AdminChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      subjectUserIds: subjectUserIds,
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
    final geminiHistory = [
      ...transferableHistory,
      userMsg,
    ].map((m) => GeminiChatMessage(role: m.role, content: m.content)).toList();

    // 3. Call Gemini
    try {
      final response = await aiService.sendMessage(
        userId: adminId,
        subjectUserIds: subjectUserIds,
        messages: geminiHistory,
        systemPrompt: _buildStatsContext(alerts, insights),
      );

      if (!mounted || _adminId != adminId) return;

      // 4. Add bot response
      final botMsg = _AdminChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: response.content,
        subjectUserIds: subjectUserIds,
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
      if (!mounted || _adminId != adminId) return;
      setState(() => _isTyping = false);
      final strings = S(ref.read(languageProvider).language);
      _addBotMessage(
        isAiConsentRequiredError(e)
            ? strings.aiConsentRequired
            : isAiBillingExhaustedError(e)
                ? strings.aiCreditDepleted
                : strings.error,
      );
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
    ref.invalidate(adminUsageInsightsProvider);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.uid == next?.uid) return;
      setState(() {
        _messages.clear();
        _isTyping = false;
        _isLoadingHistory = true;
        _historyAdminId = null;
      });
      _inputController.clear();
      _loadHistory();
    });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.border,
          width: 0.5,
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
            child: const Icon(
              Icons.psychology_outlined,
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
            icon: const Icon(Icons.add_comment_outlined, size: 20),
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
          const SizedBox(
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
            Icons.psychology_outlined,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  MarkdownStyleSheet _markdownStyleSheet(bool isDark) {
    final textColor = isDark
        ? AppColors.adminTextPrimary
        : AppColors.textPrimary;
    final secondaryColor = isDark
        ? AppColors.adminTextSecondary
        : AppColors.textSecondary;
    final baseStyle = TextStyle(
      fontSize: 13,
      height: 1.55,
      color: textColor,
    );

    return MarkdownStyleSheet(
      p: baseStyle,
      pPadding: const EdgeInsets.only(bottom: 6),
      strong: baseStyle.copyWith(fontWeight: FontWeight.w600),
      em: baseStyle,
      h1: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      h2: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      h3: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      h4: baseStyle.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      h5: baseStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      h6: baseStyle.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
      listBullet: baseStyle.copyWith(color: AppColors.primary),
      listIndent: 16,
      blockSpacing: 8,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.border,
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(_AdminChatMessage msg, bool isDark) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : isDark
                    ? AppColors.adminGlass
                    : AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.adminBorder
                            : AppColors.border,
                        width: 1,
                      ),
              ),
              child: isUser
                  ? SelectableText(
                      msg.content,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    )
                  : MarkdownBody(
                      data: msg.content,
                      selectable: true,
                      styleSheet: _markdownStyleSheet(isDark),
                    ),
            ),
          ),

          // Trailing spacing for bot messages
          if (!isUser) const SizedBox(width: 16),
          // Leading spacing for user messages
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Typing indicator ───────────────────────────────────────────────────

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.adminGlass : AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(
                color: isDark ? AppColors.adminBorder : AppColors.border,
                width: 1,
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
        color: isDark ? AppColors.adminSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.adminGlass : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.adminBorder : AppColors.border,
                ),
              ),
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
                    horizontal: 0,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _hasText
                ? AppColors.primary
                : (isDark ? AppColors.adminGlass : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _hasText ? _handleSend : null,
              child: Padding(
                padding: const EdgeInsets.all(10),
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
