/// XP configuration constants and level calculation utilities
class XpConfig {
  XpConfig._();

  // --- XP Rewards ---
  static const int moodLog = 10;
  static const int completeChapter = 25;
  static const int streak7Day = 50;
  static const int streak30Day = 200;
  static const int leaveReview = 15;
  static const int communityPost = 10;
  static const int completeChallenge = 20;
  static const int bookTherapy = 30;

  // --- Daily Cap ---
  static const int dailyCap = 100;

  // --- Level Thresholds ---
  // XP required to reach each level (index = level number, value = cumulative XP)
  // Level 1 starts at 0 XP, level 50 requires 49000 XP
  static const List<int> levelThresholds = [
    0, // Level 1
    100, // Level 2
    250, // Level 3
    450, // Level 4
    700, // Level 5
    1000, // Level 6
    1350, // Level 7
    1750, // Level 8
    2200, // Level 9
    2700, // Level 10
    3250, // Level 11
    3850, // Level 12
    4500, // Level 13
    5200, // Level 14
    5950, // Level 15
    6750, // Level 16
    7600, // Level 17
    8500, // Level 18
    9450, // Level 19
    10450, // Level 20
    11500, // Level 21
    12600, // Level 22
    13750, // Level 23
    14950, // Level 24
    16200, // Level 25
    17500, // Level 26
    18850, // Level 27
    20250, // Level 28
    21700, // Level 29
    23200, // Level 30
    24750, // Level 31
    26350, // Level 32
    28000, // Level 33
    29700, // Level 34
    31450, // Level 35
    33250, // Level 36
    35100, // Level 37
    37000, // Level 38
    38950, // Level 39
    40950, // Level 40
    43000, // Level 41
    45100, // Level 42
    47250, // Level 43
    49450, // Level 44
    51700, // Level 45
    54000, // Level 46
    56350, // Level 47
    58750, // Level 48
    61200, // Level 49
    63700, // Level 50
  ];

  /// Returns the current level (1-50) based on total XP
  static int levelForXp(int xp) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= levelThresholds[i]) {
        return i + 1; // Levels are 1-indexed
      }
    }
    return 1;
  }

  /// Returns XP needed to reach the next level from current XP.
  /// Returns 0 if already at max level.
  static int xpForNextLevel(int currentXp) {
    final currentLevel = levelForXp(currentXp);
    if (currentLevel >= levelThresholds.length) return 0;
    return levelThresholds[currentLevel] - currentXp;
  }

  /// Returns progress fraction (0.0 - 1.0) toward the next level.
  /// Returns 1.0 if at max level.
  static double progressToNextLevel(int currentXp) {
    final currentLevel = levelForXp(currentXp);
    if (currentLevel >= levelThresholds.length) return 1.0;

    final currentLevelXp = levelThresholds[currentLevel - 1];
    final nextLevelXp = levelThresholds[currentLevel];
    final levelRange = nextLevelXp - currentLevelXp;

    if (levelRange <= 0) return 1.0;

    final progressInLevel = currentXp - currentLevelXp;
    return (progressInLevel / levelRange).clamp(0.0, 1.0);
  }
}
