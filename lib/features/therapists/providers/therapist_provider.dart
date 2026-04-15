import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/therapist.dart';
import '../repositories/therapist_repository.dart';

class TherapistState {
  final List<Therapist> therapists;
  final Specialty? selectedSpecialty;
  final SessionType? selectedSessionType;
  final TherapyType? selectedTherapyType;
  final bool isLoading;
  final String searchQuery;
  final List<String> intakeIssues;
  final String? intakeNote;

  final String? error; // Added error field

  const TherapistState({
    this.therapists = const [],
    this.selectedSpecialty,
    this.selectedSessionType,
    this.selectedTherapyType,
    this.isLoading = false,
    this.searchQuery = '',
    this.error,
    this.intakeIssues = const [],
    this.intakeNote,
  });

  List<Therapist> get filteredTherapists {
    var result = therapists;

    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (t) =>
                t.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                t.title.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (selectedSpecialty != null) {
      result = result
          .where((t) => t.specialties.contains(selectedSpecialty))
          .toList();
    }

    if (selectedSessionType != null) {
      result = result
          .where((t) => t.sessionTypes.contains(selectedSessionType))
          .toList();
    }

    if (selectedTherapyType != null) {
      result = result
          .where((t) => t.therapyTypes.contains(selectedTherapyType))
          .toList();
    }

    // Filter by intake issues if present
    if (intakeIssues.isNotEmpty) {
      final relevantSpecialties = intakeIssues
          .map(_mapIssueToSpecialty)
          .whereType<Specialty>()
          .toList();

      if (relevantSpecialties.isNotEmpty) {
        // If we have matching specialties, filter by them
        result = result
            .where(
              (t) => t.specialties.any((s) => relevantSpecialties.contains(s)),
            )
            .toList();
      }
    }

    return result;
  }

  Specialty? _mapIssueToSpecialty(String issue) {
    switch (issue.toLowerCase()) {
      case 'anxiety':
        return Specialty.anxiety;
      case 'depression':
        return Specialty.depression;
      case 'stress':
      case 'work':
        return Specialty.stress;
      case 'relationships':
      case 'family':
        return Specialty.relationships;
      case 'trauma':
        return Specialty.trauma;
      case 'grief':
        return Specialty.grief;
      case 'self-esteem':
        return Specialty.selfEsteem;
      default:
        return null;
    }
  }

  TherapistState copyWith({
    List<Therapist>? therapists,
    Specialty? selectedSpecialty,
    SessionType? selectedSessionType,
    TherapyType? selectedTherapyType,
    bool? isLoading,
    String? searchQuery,
    String? error,
    List<String>? intakeIssues,
    String? intakeNote,
    bool clearSpecialty = false,
    bool clearSessionType = false,
    bool clearTherapyType = false,
    bool clearError = false,
    bool clearIntakeData = false,
  }) {
    return TherapistState(
      therapists: therapists ?? this.therapists,
      selectedSpecialty: clearSpecialty
          ? null
          : (selectedSpecialty ?? this.selectedSpecialty),
      selectedSessionType: clearSessionType
          ? null
          : (selectedSessionType ?? this.selectedSessionType),
      selectedTherapyType: clearTherapyType
          ? null
          : (selectedTherapyType ?? this.selectedTherapyType),
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      error: clearError ? null : (error ?? this.error),
      intakeIssues: clearIntakeData ? [] : (intakeIssues ?? this.intakeIssues),
      intakeNote: clearIntakeData ? null : (intakeNote ?? this.intakeNote),
    );
  }
}

class TherapistNotifier extends StateNotifier<TherapistState> {
  final TherapistRepository _repository;

  TherapistNotifier(this._repository) : super(const TherapistState()) {
    loadTherapists();
  }

  Future<void> loadTherapists() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profiles = await _repository.getApprovedTherapists();
      final therapists = profiles.map((p) => p.toTherapist()).toList();

      state = state.copyWith(therapists: therapists, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading therapists: $e',
      );
    }
  }

  Future<void> refresh() async {
    await loadTherapists();
  }

  void setSpecialty(Specialty? specialty) {
    if (specialty == state.selectedSpecialty) {
      state = state.copyWith(clearSpecialty: true);
    } else {
      state = state.copyWith(selectedSpecialty: specialty);
    }
  }

  void setSessionType(SessionType? type) {
    if (type == state.selectedSessionType) {
      state = state.copyWith(clearSessionType: true);
    } else {
      state = state.copyWith(selectedSessionType: type);
    }
  }

  void setTherapyType(TherapyType? type) {
    if (type == state.selectedTherapyType) {
      state = state.copyWith(clearTherapyType: true);
    } else {
      state = state.copyWith(selectedTherapyType: type);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setIntakeData(List<String> issues, String note) {
    state = state.copyWith(intakeIssues: issues, intakeNote: note);
  }

  void clearFilters() {
    state = state.copyWith(
      clearSpecialty: true,
      clearSessionType: true,
      clearTherapyType: true,
      clearIntakeData: true,
      searchQuery: '',
    );
  }
}

final therapistProvider =
    StateNotifierProvider<TherapistNotifier, TherapistState>((ref) {
      final repository = ref.watch(therapistRepositoryProvider);
      return TherapistNotifier(repository);
    });

// Provider to trigger tab switching in TherapySelectionScreen
final bookingsTabTriggerProvider = StateProvider<int?>((ref) => null);

// Provider for selected therapist details
final selectedTherapistProvider = StateProvider<Therapist?>((ref) => null);
