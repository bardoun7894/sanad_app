import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_handoff.dart';
import '../repositories/chat_handoff_repository.dart';
import '../services/ai_chat_service.dart';
import '../../../core/services/user_context_service.dart';
import '../../therapist_chat/services/therapist_chat_service.dart';
import '../../therapist_chat/models/therapist_chat.dart';
import '../../mood/models/mood_entry.dart';

/// Orchestrator service for AI-to-therapist handoffs.
///
/// Coordinates between [ChatHandoffRepository], [AiChatService],
/// [UserContextService], and [TherapistChatService] to manage the
/// full handoff lifecycle: initiation, acceptance, and completion.
class HandoffService {
  final FirebaseFirestore _firestore;
  final ChatHandoffRepository _handoffRepository;
  final AiChatService _aiChatService;
  final UserContextService _userContextService;
  final TherapistChatService _therapistChatService;

  HandoffService({
    FirebaseFirestore? firestore,
    required ChatHandoffRepository handoffRepository,
    required AiChatService aiChatService,
    required UserContextService userContextService,
    required TherapistChatService therapistChatService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _handoffRepository = handoffRepository,
       _aiChatService = aiChatService,
       _userContextService = userContextService,
       _therapistChatService = therapistChatService;

  // ── Initiate Handoff ────────────────────────────────────────────────────

  /// Creates a new handoff request from AI chat to therapist.
  ///
  /// Builds a [MoodSnapshot] from recent mood entries, fetches a conversation
  /// summary from the AI chat, and writes the handoff to Firestore.
  ///
  /// Returns the handoff document ID.
  Future<String> initiateHandoff({
    required String userId,
    required String userName,
    required HandoffTrigger triggerReason,
    String? triggerDetails,
    String? therapistId,
    String? riskAlertId,
  }) async {
    try {
      // 1. Build mood snapshot from last 7 days
      final moodSnapshot = await buildMoodSnapshot(userId);

      // 2. Get AI conversation summary for context transfer
      String aiSummary;
      try {
        aiSummary = await _aiChatService.getConversationSummary(userId);
      } catch (e) {
        debugPrint('HandoffService: Failed to get AI summary: $e');
        aiSummary = 'Unable to retrieve conversation summary.';
      }

      // 3. Get risk level from user context
      String? riskLevel;
      try {
        final context = await _userContextService.buildContext(userId);
        riskLevel = context['riskLevel'] as String?;
      } catch (e) {
        debugPrint('HandoffService: Failed to get user context: $e');
      }

      // 4. Create handoff document
      final now = DateTime.now();
      final handoff = ChatHandoff(
        id: '', // Will be assigned by Firestore
        userId: userId,
        userName: userName,
        fromMode: 'ai',
        toMode: 'therapist',
        therapistId: therapistId,
        triggerReason: triggerReason,
        triggerDetails: triggerDetails,
        aiSummary: aiSummary,
        moodSnapshot: moodSnapshot,
        chatHistoryRef: 'ai_chats/$userId',
        riskLevel: riskLevel,
        riskAlertId: riskAlertId,
        status: HandoffStatus.pending,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );

      final handoffId = await _handoffRepository.create(handoff);

      // 5. Mark AI chat as escalated
      try {
        await _aiChatService.markAsEscalated(
          userId: userId,
          escalatedTo: 'therapist',
          therapistId: therapistId,
        );
      } catch (e) {
        debugPrint('HandoffService: Failed to mark AI chat escalated: $e');
      }

      debugPrint('HandoffService: Handoff initiated: $handoffId');
      return handoffId;
    } catch (e, st) {
      debugPrint('HandoffService: Error initiating handoff: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  // ── Accept Handoff ──────────────────────────────────────────────────────

  /// Therapist accepts a pending handoff.
  ///
  /// Creates or retrieves a [TherapistChatThread] with the AI context
  /// transferred, then links the therapist chat to the handoff.
  Future<String> acceptHandoff({
    required String handoffId,
    required String therapistId,
    required String therapistName,
  }) async {
    try {
      // 1. Get the handoff details
      final handoff = await _handoffRepository.get(handoffId);
      if (handoff == null) {
        throw Exception('Handoff not found: $handoffId');
      }

      if (!handoff.isPending) {
        throw Exception('Handoff is no longer pending: ${handoff.status.name}');
      }

      // 2. Accept the handoff in Firestore
      await _handoffRepository.accept(handoffId, therapistId, therapistName);

      // 3. Build AI context for the therapist chat
      final aiContext = _buildAiContextForTherapist(handoff);

      // 4. Get or create therapist chat thread with AI context
      final chatThread = await _therapistChatService.getOrCreateChat(
        therapistId: therapistId,
        userId: handoff.userId,
        therapistName: therapistName,
        userName: handoff.userName,
        source: ChatSource.aiEscalation,
        aiContext: aiContext,
      );

      // 5. Link the therapist chat to the handoff
      await _handoffRepository.linkTherapistChat(handoffId, chatThread.chatId);

      debugPrint(
        'HandoffService: Handoff accepted: $handoffId -> ${chatThread.chatId}',
      );
      return chatThread.chatId;
    } catch (e, st) {
      debugPrint('HandoffService: Error accepting handoff: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  // ── Complete Handoff ────────────────────────────────────────────────────

  /// Marks a handoff as completed (therapist has addressed the user's needs).
  Future<void> completeHandoff(String handoffId) async {
    try {
      await _handoffRepository.complete(handoffId);
      debugPrint('HandoffService: Handoff completed: $handoffId');
    } catch (e, st) {
      debugPrint('HandoffService: Error completing handoff: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  // ── Build Mood Snapshot ─────────────────────────────────────────────────

  /// Fetches the last 7 days of mood entries and computes statistics.
  ///
  /// Returns a [MoodSnapshot] with average score, trend, and consecutive
  /// low-mood days count.
  Future<MoodSnapshot> buildMoodSnapshot(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mood_entries')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .orderBy('date', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return const MoodSnapshot();
      }

      final entries = snapshot.docs.map((doc) {
        return MoodEntry.fromMap(doc.data(), doc.id);
      }).toList();

      // Extract dates and mood names
      final dates = entries
          .map(
            (e) =>
                '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
          )
          .toList();
      final moods = entries.map((e) => e.mood.name).toList();

      // Compute scores
      final scores = entries
          .map((e) => MoodMetadata.getMoodScore(e.mood).toDouble())
          .toList();

      // Average score
      final averageScore = scores.reduce((a, b) => a + b) / scores.length;

      // Trend: compare first half vs second half (scores are descending by date)
      String trend = 'stable';
      if (scores.length >= 2) {
        final half = scores.length ~/ 2;
        final recentAvg =
            scores.sublist(0, half).reduce((a, b) => a + b) / half;
        final olderAvg =
            scores.sublist(half).reduce((a, b) => a + b) /
            (scores.length - half);
        final diff = recentAvg - olderAvg;
        if (diff > 0.5) {
          trend = 'improving';
        } else if (diff < -0.5) {
          trend = 'declining';
        }
      }

      // Consecutive low-mood days (most recent first)
      int consecutiveLowDays = 0;
      for (final score in scores) {
        if (score <= 2) {
          consecutiveLowDays++;
        } else {
          break;
        }
      }

      return MoodSnapshot(
        dates: dates,
        moods: moods,
        averageScore: averageScore,
        trend: trend,
        consecutiveLowDays: consecutiveLowDays,
      );
    } catch (e) {
      debugPrint('HandoffService: Error building mood snapshot: $e');
      return const MoodSnapshot();
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Builds a formatted AI context string for the therapist to review.
  String _buildAiContextForTherapist(ChatHandoff handoff) {
    final buffer = StringBuffer();

    buffer.writeln('=== AI Chat Handoff Context ===');
    buffer.writeln('Trigger: ${handoff.triggerReason.name}');
    if (handoff.triggerDetails != null) {
      buffer.writeln('Details: ${handoff.triggerDetails}');
    }
    if (handoff.riskLevel != null) {
      buffer.writeln('Risk Level: ${handoff.riskLevel}');
    }

    // Mood snapshot
    final mood = handoff.moodSnapshot;
    if (mood.dates.isNotEmpty) {
      buffer.writeln(
        '\nMood (last 7 days): avg=${mood.averageScore.toStringAsFixed(1)}/5, '
        'trend=${mood.trend}, '
        'consecutive low days=${mood.consecutiveLowDays}',
      );
      buffer.writeln('Recent moods: ${mood.moods.take(5).join(', ')}');
    }

    // AI summary
    if (handoff.aiSummary.isNotEmpty) {
      buffer.writeln('\n--- Conversation Summary ---');
      buffer.writeln(handoff.aiSummary);
    }

    return buffer.toString();
  }
}
