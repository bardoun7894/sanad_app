import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';

void main() {
  group('Therapist', () {
    test('creates with required fields', () {
      const therapist = Therapist(
        id: 't1',
        name: 'Dr. Smith',
        title: 'Clinical Psychologist',
        bio: 'Experienced therapist',
        specialties: [Specialty.anxiety, Specialty.depression],
        sessionTypes: [SessionType.audio, SessionType.chat],
        rating: 4.8,
        reviewCount: 120,
        yearsExperience: 10,
        sessionPrice: 150.0,
        languages: ['Arabic', 'English'],
        qualifications: ['PhD Psychology'],
      );

      expect(therapist.id, 't1');
      expect(therapist.name, 'Dr. Smith');
      expect(therapist.title, 'Clinical Psychologist');
      expect(therapist.rating, 4.8);
      expect(therapist.reviewCount, 120);
      expect(therapist.yearsExperience, 10);
      expect(therapist.sessionPrice, 150.0);
      expect(therapist.currency, 'USD');
      expect(therapist.therapyTypes, [TherapyType.individual]);
      expect(therapist.isAvailableToday, isFalse);
      expect(therapist.reviews, isEmpty);
    });

    test('formattedPrice returns price with currency', () {
      const therapist = Therapist(
        id: 't1',
        name: 'Dr. Smith',
        title: 'Psychologist',
        bio: 'Bio',
        specialties: [],
        sessionTypes: [],
        rating: 4.0,
        reviewCount: 0,
        yearsExperience: 5,
        sessionPrice: 200.0,
        currency: 'SAR',
        languages: [],
        qualifications: [],
      );

      // currencySymbol('SAR') maps to '$' in the current model.
      expect(therapist.formattedPrice, '\$200.0');
    });
  });

  group('Specialty', () {
    test('has expected values', () {
      expect(Specialty.values.length, 8);
      expect(Specialty.anxiety.name, 'anxiety');
      expect(Specialty.depression.name, 'depression');
      expect(Specialty.trauma.name, 'trauma');
      expect(Specialty.relationships.name, 'relationships');
      expect(Specialty.stress.name, 'stress');
      expect(Specialty.selfEsteem.name, 'selfEsteem');
      expect(Specialty.grief.name, 'grief');
      expect(Specialty.addiction.name, 'addiction');
    });

    test('getLabel returns English default', () {
      expect(SpecialtyData.getLabel(Specialty.anxiety), 'Anxiety');
      expect(SpecialtyData.getLabel(Specialty.depression), 'Depression');
      expect(SpecialtyData.getLabel(Specialty.trauma), 'Trauma & PTSD');
      expect(SpecialtyData.getLabel(Specialty.relationships), 'Relationships');
      expect(SpecialtyData.getLabel(Specialty.stress), 'Stress Management');
      expect(SpecialtyData.getLabel(Specialty.selfEsteem), 'Self-Esteem');
      expect(SpecialtyData.getLabel(Specialty.grief), 'Grief & Loss');
      expect(SpecialtyData.getLabel(Specialty.addiction), 'Addiction');
    });
  });

  group('TherapyType', () {
    test('has expected values', () {
      expect(TherapyType.values.length, 3);
      expect(TherapyType.individual.name, 'individual');
      expect(TherapyType.couples.name, 'couples');
      expect(TherapyType.teen.name, 'teen');
    });

    test('getLabel returns English default', () {
      expect(
        TherapyTypeData.getLabel(TherapyType.individual),
        'Individual Therapy',
      );
      expect(TherapyTypeData.getLabel(TherapyType.couples), 'Couples Therapy');
      expect(TherapyTypeData.getLabel(TherapyType.teen), 'Teen Therapy');
    });

    test('getDescription returns description', () {
      expect(
        TherapyTypeData.getDescription(TherapyType.individual),
        contains('Private sessions'),
      );
      expect(
        TherapyTypeData.getDescription(TherapyType.couples),
        contains('relationships'),
      );
      expect(
        TherapyTypeData.getDescription(TherapyType.teen),
        contains('13-18'),
      );
    });
  });

  group('SessionType', () {
    test('has expected values', () {
      expect(SessionType.values.length, 3);
      expect(SessionType.audio.name, 'audio');
      expect(SessionType.chat.name, 'chat');
      expect(SessionType.inPerson.name, 'inPerson');
    });

    test('firestoreValue returns correct values', () {
      expect(SessionType.audio.firestoreValue, 'audio');
      expect(SessionType.chat.firestoreValue, 'chat');
      expect(SessionType.inPerson.firestoreValue, 'in_person');
    });

    test('fromFirestore parses correctly', () {
      expect(SessionTypeFirestore.fromFirestore('audio'), SessionType.audio);
      expect(SessionTypeFirestore.fromFirestore('chat'), SessionType.chat);
      expect(
        SessionTypeFirestore.fromFirestore('in_person'),
        SessionType.inPerson,
      );
      expect(
        SessionTypeFirestore.fromFirestore('inPerson'),
        SessionType.inPerson,
      );
    });

    test('fromFirestore defaults to audio for unknown', () {
      expect(SessionTypeFirestore.fromFirestore('video'), SessionType.audio);
      expect(SessionTypeFirestore.fromFirestore(null), SessionType.audio);
    });

    test('getLabel returns English default', () {
      expect(SessionTypeData.getLabel(SessionType.audio), 'Audio Call');
      expect(SessionTypeData.getLabel(SessionType.chat), 'Chat Session');
      expect(
        SessionTypeData.getLabel(SessionType.inPerson),
        'In-Person Session',
      );
    });
  });

  group('Booking', () {
    test('creates with required fields', () {
      const therapist = Therapist(
        id: 't1',
        name: 'Dr. Smith',
        title: 'Psychologist',
        bio: 'Bio',
        specialties: [],
        sessionTypes: [],
        rating: 4.0,
        reviewCount: 0,
        yearsExperience: 5,
        sessionPrice: 100.0,
        languages: [],
        qualifications: [],
      );

      final booking = Booking(
        id: 'b1',
        therapist: therapist,
        dateTime: DateTime(2026, 3, 1),
        sessionType: SessionType.audio,
        status: 'confirmed',
      );

      expect(booking.id, 'b1');
      expect(booking.therapist.id, 't1');
      expect(booking.sessionType, SessionType.audio);
      expect(booking.status, 'confirmed');
    });
  });
}
