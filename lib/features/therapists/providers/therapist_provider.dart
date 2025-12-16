import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/therapist.dart';

class TherapistState {
  final List<Therapist> therapists;
  final Specialty? selectedSpecialty;
  final SessionType? selectedSessionType;
  final bool isLoading;
  final String searchQuery;

  const TherapistState({
    this.therapists = const [],
    this.selectedSpecialty,
    this.selectedSessionType,
    this.isLoading = false,
    this.searchQuery = '',
  });

  List<Therapist> get filteredTherapists {
    var result = therapists;

    if (searchQuery.isNotEmpty) {
      result = result.where((t) =>
          t.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    if (selectedSpecialty != null) {
      result = result.where((t) => t.specialties.contains(selectedSpecialty)).toList();
    }

    if (selectedSessionType != null) {
      result = result.where((t) => t.sessionTypes.contains(selectedSessionType)).toList();
    }

    return result;
  }

  TherapistState copyWith({
    List<Therapist>? therapists,
    Specialty? selectedSpecialty,
    SessionType? selectedSessionType,
    bool? isLoading,
    String? searchQuery,
    bool clearSpecialty = false,
    bool clearSessionType = false,
  }) {
    return TherapistState(
      therapists: therapists ?? this.therapists,
      selectedSpecialty: clearSpecialty ? null : (selectedSpecialty ?? this.selectedSpecialty),
      selectedSessionType: clearSessionType ? null : (selectedSessionType ?? this.selectedSessionType),
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TherapistNotifier extends StateNotifier<TherapistState> {
  TherapistNotifier() : super(const TherapistState()) {
    _loadSampleTherapists();
  }

  void _loadSampleTherapists() {
    final now = DateTime.now();

    final sampleTherapists = [
      Therapist(
        id: '1',
        name: 'Dr. Sarah Ahmed',
        title: 'Clinical Psychologist',
        bio: 'Dr. Sarah Ahmed is a licensed clinical psychologist with over 10 years of experience helping individuals overcome anxiety, depression, and trauma. She uses evidence-based approaches including CBT and EMDR to provide personalized care.',
        specialties: [Specialty.anxiety, Specialty.depression, Specialty.trauma],
        sessionTypes: [SessionType.video, SessionType.audio],
        rating: 4.9,
        reviewCount: 127,
        yearsExperience: 10,
        sessionPrice: 350,
        languages: ['Arabic', 'English'],
        qualifications: [
          'PhD in Clinical Psychology - King Saud University',
          'Licensed Clinical Psychologist',
          'Certified EMDR Practitioner',
        ],
        reviews: [
          Review(
            id: 'r1',
            authorName: 'Nora M.',
            rating: 5,
            comment: 'Dr. Sarah is incredibly understanding and patient. She helped me work through my anxiety in ways I never thought possible.',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          Review(
            id: 'r2',
            authorName: 'Ahmed K.',
            rating: 5,
            comment: 'Professional, empathetic, and truly helpful. Highly recommended!',
            createdAt: now.subtract(const Duration(days: 12)),
          ),
        ],
        isAvailableToday: true,
        nextAvailable: 'Today, 3:00 PM',
      ),
      Therapist(
        id: '2',
        name: 'Dr. Omar Hassan',
        title: 'Psychiatrist',
        bio: 'Dr. Omar Hassan is a board-certified psychiatrist specializing in mood disorders and stress management. He combines medication management with psychotherapy for comprehensive treatment.',
        specialties: [Specialty.depression, Specialty.stress, Specialty.addiction],
        sessionTypes: [SessionType.video, SessionType.audio, SessionType.chat],
        rating: 4.8,
        reviewCount: 89,
        yearsExperience: 15,
        sessionPrice: 450,
        languages: ['Arabic', 'English', 'French'],
        qualifications: [
          'MD - Cairo University',
          'Board Certified Psychiatrist',
          'Fellowship in Addiction Medicine',
        ],
        reviews: [
          Review(
            id: 'r3',
            authorName: 'Fatima A.',
            rating: 5,
            comment: 'Dr. Omar really listens and takes time to understand your situation. His treatment approach is holistic and effective.',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
        ],
        isAvailableToday: false,
        nextAvailable: 'Tomorrow, 10:00 AM',
      ),
      Therapist(
        id: '3',
        name: 'Dr. Layla Mahmoud',
        title: 'Marriage & Family Therapist',
        bio: 'Dr. Layla specializes in relationship counseling and family therapy. With 8 years of experience, she helps couples and families build stronger connections and resolve conflicts.',
        specialties: [Specialty.relationships, Specialty.selfEsteem, Specialty.stress],
        sessionTypes: [SessionType.video],
        rating: 4.7,
        reviewCount: 64,
        yearsExperience: 8,
        sessionPrice: 300,
        languages: ['Arabic', 'English'],
        qualifications: [
          'MA in Marriage and Family Therapy',
          'Licensed Marriage & Family Therapist',
          'Gottman Method Certified',
        ],
        reviews: [
          Review(
            id: 'r4',
            authorName: 'Yusuf & Mariam',
            rating: 5,
            comment: 'Dr. Layla saved our marriage. Her insights and guidance helped us communicate better and reconnect.',
            createdAt: now.subtract(const Duration(days: 20)),
          ),
        ],
        isAvailableToday: true,
        nextAvailable: 'Today, 5:00 PM',
      ),
      Therapist(
        id: '4',
        name: 'Dr. Khalid Al-Rashid',
        title: 'Trauma Specialist',
        bio: 'Dr. Khalid is a trauma-informed therapist with expertise in PTSD, grief, and loss. He creates a safe space for healing using somatic therapy and mindfulness-based approaches.',
        specialties: [Specialty.trauma, Specialty.grief, Specialty.anxiety],
        sessionTypes: [SessionType.video, SessionType.audio],
        rating: 4.9,
        reviewCount: 103,
        yearsExperience: 12,
        sessionPrice: 400,
        languages: ['Arabic', 'English'],
        qualifications: [
          'PsyD - American University of Beirut',
          'Certified Trauma Professional',
          'Somatic Experiencing Practitioner',
        ],
        reviews: [
          Review(
            id: 'r5',
            authorName: 'Anonymous',
            rating: 5,
            comment: 'Dr. Khalid helped me process trauma I had been carrying for years. His gentle approach made me feel safe throughout.',
            createdAt: now.subtract(const Duration(days: 8)),
          ),
        ],
        isAvailableToday: false,
        nextAvailable: 'Wednesday, 2:00 PM',
      ),
      Therapist(
        id: '5',
        name: 'Dr. Mona El-Sayed',
        title: 'Cognitive Behavioral Therapist',
        bio: 'Dr. Mona is a CBT specialist who helps clients develop practical coping strategies for anxiety, depression, and low self-esteem. She believes in empowering clients with tools for lasting change.',
        specialties: [Specialty.anxiety, Specialty.selfEsteem, Specialty.depression],
        sessionTypes: [SessionType.video, SessionType.chat],
        rating: 4.6,
        reviewCount: 52,
        yearsExperience: 6,
        sessionPrice: 280,
        languages: ['Arabic', 'English'],
        qualifications: [
          'MSc in Clinical Psychology',
          'Certified CBT Therapist',
          'ACT (Acceptance & Commitment Therapy) Trained',
        ],
        reviews: [],
        isAvailableToday: true,
        nextAvailable: 'Today, 6:00 PM',
      ),
    ];

    state = state.copyWith(therapists: sampleTherapists);
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

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = state.copyWith(
      clearSpecialty: true,
      clearSessionType: true,
      searchQuery: '',
    );
  }
}

final therapistProvider = StateNotifierProvider<TherapistNotifier, TherapistState>(
  (ref) => TherapistNotifier(),
);

// Provider for selected therapist details
final selectedTherapistProvider = StateProvider<Therapist?>((ref) => null);
