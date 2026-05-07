import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';

/// AI persona options available in hybrid chat.
///
/// The [id] string MUST match what the backend `chatWithGemini` callable
/// expects exactly — changing these breaks the Cloud Function contract.
enum AiPersona {
  companion,
  coach,
  cbtTherapist,
  mindfulnessGuide,
  crisisCompanion,
}

/// Extension providing persona metadata and l10n helpers.
extension AiPersonaX on AiPersona {
  /// Snake_case id sent to the backend. Must match the Cloud Function contract.
  String get id {
    switch (this) {
      case AiPersona.companion:
        return 'companion';
      case AiPersona.coach:
        return 'coach';
      case AiPersona.cbtTherapist:
        return 'cbt_therapist';
      case AiPersona.mindfulnessGuide:
        return 'mindfulness_guide';
      case AiPersona.crisisCompanion:
        return 'crisis_companion';
    }
  }

  /// Material icon representing this persona.
  IconData get icon {
    switch (this) {
      case AiPersona.companion:
        return Icons.favorite_rounded;
      case AiPersona.coach:
        return Icons.emoji_events_rounded;
      case AiPersona.cbtTherapist:
        return Icons.psychology_rounded;
      case AiPersona.mindfulnessGuide:
        return Icons.self_improvement_rounded;
      case AiPersona.crisisCompanion:
        return Icons.health_and_safety_rounded;
    }
  }

  /// Localized short label.
  String localizedLabel(S s) {
    switch (this) {
      case AiPersona.companion:
        return s.personaCompanion;
      case AiPersona.coach:
        return s.personaCoach;
      case AiPersona.cbtTherapist:
        return s.personaCbt;
      case AiPersona.mindfulnessGuide:
        return s.personaMindfulness;
      case AiPersona.crisisCompanion:
        return s.personaCrisis;
    }
  }

  /// Localized one-line description.
  String localizedDescription(S s) {
    switch (this) {
      case AiPersona.companion:
        return s.personaCompanionDesc;
      case AiPersona.coach:
        return s.personaCoachDesc;
      case AiPersona.cbtTherapist:
        return s.personaCbtDesc;
      case AiPersona.mindfulnessGuide:
        return s.personaMindfulnessDesc;
      case AiPersona.crisisCompanion:
        return s.personaCrisisDesc;
    }
  }

  /// Parse a backend id string back into an [AiPersona].
  /// Unknown strings default to [AiPersona.companion].
  static AiPersona fromId(String id) {
    for (final p in AiPersona.values) {
      if (p.id == id) return p;
    }
    return AiPersona.companion;
  }
}

/// Riverpod state provider for the currently selected AI persona.
/// Defaults to [AiPersona.companion].
///
/// Stored separately from the chat doc; persisted to Firestore on change
/// inside the HybridChatScreen.
final aiPersonaProvider = StateProvider<AiPersona>(
  (ref) => AiPersona.companion,
);
