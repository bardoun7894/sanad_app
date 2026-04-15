enum MoodType { happy, calm, anxious, sad, angry, tired }

extension MoodTypeExtension on MoodType {
  static String emoji(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return '\u{1F60A}';
      case MoodType.calm:
        return '\u{1F60C}';
      case MoodType.anxious:
        return '\u{1F630}';
      case MoodType.sad:
        return '\u{1F622}';
      case MoodType.angry:
        return '\u{1F621}';
      case MoodType.tired:
        return '\u{1F634}';
    }
  }

  static String label(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return 'سعيد';
      case MoodType.calm:
        return 'هادئ';
      case MoodType.anxious:
        return 'قلق';
      case MoodType.sad:
        return 'حزين';
      case MoodType.angry:
        return 'غاضب';
      case MoodType.tired:
        return 'متعب';
    }
  }
}
