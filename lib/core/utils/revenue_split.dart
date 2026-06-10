/// Pure revenue-split helpers — no Flutter or Firestore imports.
class RevenueShares {
  final double therapist;
  final double app;
  final double maintenance;

  const RevenueShares({
    required this.therapist,
    required this.app,
    required this.maintenance,
  });
}

class RevenueSplit {
  /// Splits [amount] by the three percentages. Percentages are 0-100.
  static RevenueShares compute({
    required double amount,
    required double therapistPct,
    required double appPct,
    required double maintenancePct,
  }) {
    return RevenueShares(
      therapist: amount * therapistPct / 100,
      app: amount * appPct / 100,
      maintenance: amount * maintenancePct / 100,
    );
  }

  /// True if the three percentages sum to 100 (allow a 0.01 tolerance for floats).
  static bool sumsTo100(
    double therapistPct,
    double appPct,
    double maintenancePct,
  ) {
    final sum = therapistPct + appPct + maintenancePct;
    return (sum - 100.0).abs() <= 0.01;
  }
}
