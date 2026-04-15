import 'message.dart';
import '../../therapist_chat/models/therapist_message.dart';
import 'chat_handoff.dart';

/// Sender type for hybrid messages spanning both AI and therapist conversations.
enum HybridSender { user, ai, therapist, system }

/// Unified message wrapper that can represent an AI chat [Message], a
/// [TherapistMessage], or a system-level handoff event.
///
/// Used to render a single merged message list in the hybrid chat screen.
class HybridMessage {
  /// Unique identifier for the message.
  final String id;

  /// The text content of the message.
  final String content;

  /// Who sent the message.
  final HybridSender sender;

  /// When the message was sent.
  final DateTime timestamp;

  /// Whether this message originated from the AI chat (as opposed to therapist).
  final bool isFromAi;

  /// The original AI [Message], if this was created from one.
  final Message? originalAiMessage;

  /// The original [TherapistMessage], if this was created from one.
  final TherapistMessage? originalTherapistMessage;

  /// The [ChatHandoff] if this is a handoff event message.
  final ChatHandoff? handoff;

  const HybridMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isFromAi = false,
    this.originalAiMessage,
    this.originalTherapistMessage,
    this.handoff,
  });

  /// Create a [HybridMessage] from an AI chat [Message].
  factory HybridMessage.fromAiMessage(Message message) {
    return HybridMessage(
      id: message.id,
      content: message.content,
      sender: message.type == MessageType.user
          ? HybridSender.user
          : message.type == MessageType.system
          ? HybridSender.system
          : HybridSender.ai,
      timestamp: message.timestamp,
      isFromAi: message.type == MessageType.bot,
      originalAiMessage: message,
    );
  }

  /// Create a [HybridMessage] from a [TherapistMessage].
  factory HybridMessage.fromTherapistMessage(TherapistMessage message) {
    return HybridMessage(
      id: message.id,
      content: message.content,
      sender: message.senderType == SenderType.therapist
          ? HybridSender.therapist
          : message.senderType == SenderType.system
          ? HybridSender.system
          : HybridSender.user,
      timestamp: message.timestamp,
      isFromAi: false,
      originalTherapistMessage: message,
    );
  }

  /// Create a system [HybridMessage] representing a handoff event.
  factory HybridMessage.handoffEvent(ChatHandoff handoff) {
    String content;
    switch (handoff.status) {
      case HandoffStatus.pending:
        content = 'Requesting a therapist...';
      case HandoffStatus.accepted:
        content = handoff.therapistName != null
            ? 'Session transferred to ${handoff.therapistName}'
            : "You've been connected with a therapist";
      case HandoffStatus.inProgress:
        content = handoff.therapistName != null
            ? 'In session with ${handoff.therapistName}'
            : 'Therapist session in progress';
      case HandoffStatus.completed:
        content = 'Therapist session ended';
      case HandoffStatus.expired:
        content = 'Therapist request expired';
      case HandoffStatus.cancelled:
        content = 'Therapist request cancelled';
    }

    return HybridMessage(
      id: 'handoff_${handoff.id}',
      content: content,
      sender: HybridSender.system,
      timestamp: handoff.createdAt,
      isFromAi: false,
      handoff: handoff,
    );
  }

  /// Whether this is a handoff event message.
  bool get isHandoffEvent => handoff != null;

  /// Whether this message is from the current user.
  bool get isFromUser => sender == HybridSender.user;

  /// Whether this is a system message.
  bool get isSystem => sender == HybridSender.system;

  /// String representation of the sender for display.
  String get senderLabel {
    switch (sender) {
      case HybridSender.user:
        return 'user';
      case HybridSender.ai:
        return 'ai';
      case HybridSender.therapist:
        return 'therapist';
      case HybridSender.system:
        return 'system';
    }
  }
}
