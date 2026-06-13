import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';
import 'package:sanad_app/core/utils/revenue_split.dart';

// ---------------------------------------------------------------------------
// Pure helper classes
// ---------------------------------------------------------------------------

class InvoiceClassifier {
  /// A booking is a payable invoice if payment_status=='paid' OR status=='completed'.
  static bool qualifies(Map<String, dynamic> data) {
    return data['payment_status'] == 'paid' || data['status'] == 'completed';
  }

  /// Remove duplicates by doc id (a booking qualifying by both rules counts once).
  /// Preserves order of first occurrences.
  static List<T> dedupe<T>(List<T> items, String Function(T) idOf) {
    final seen = <String>{};
    final result = <T>[];
    for (final item in items) {
      final id = idOf(item);
      if (seen.add(id)) {
        result.add(item);
      }
    }
    return result;
  }
}

class InvoiceFilter {
  /// Inclusive range check on the invoice date. Null bounds = open-ended.
  static bool inRange(DateTime date, DateTime? from, DateTime? to) {
    if (from != null && date.isBefore(from)) return false;
    if (to != null && date.isAfter(to)) return false;
    return true;
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class InvoiceRecord {
  final String id;
  final String clientName;
  final String therapistId;
  final String therapistName;
  final String currency;
  final String status;
  final String paymentMethod;
  final double amount;
  final DateTime date;
  final RevenueShares shares;

  const InvoiceRecord({
    required this.id,
    required this.clientName,
    required this.therapistId,
    required this.therapistName,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.amount,
    required this.date,
    required this.shares,
  });
}

class TherapistPayout {
  final String therapistId;
  final String therapistName;
  final int sessions;
  final double gross;
  final double therapistDue;
  final double appCut;
  final double maintenance;

  const TherapistPayout({
    required this.therapistId,
    required this.therapistName,
    required this.sessions,
    required this.gross,
    required this.therapistDue,
    required this.appCut,
    required this.maintenance,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminInvoicesState {
  final List<InvoiceRecord> invoices;
  final List<TherapistPayout> payouts;
  final double totalGross;
  final double totalTherapist;
  final double totalApp;
  final double totalMaintenance;
  final DateTime? from;
  final DateTime? to;

  /// Free-text filters (client-requested): match on client / therapist name.
  final String clientQuery;
  final String therapistQuery;

  final bool isLoading;
  final String? error;

  const AdminInvoicesState({
    this.invoices = const [],
    this.payouts = const [],
    this.totalGross = 0,
    this.totalTherapist = 0,
    this.totalApp = 0,
    this.totalMaintenance = 0,
    this.from,
    this.to,
    this.clientQuery = '',
    this.therapistQuery = '',
    this.isLoading = false,
    this.error,
  });

  AdminInvoicesState copyWith({
    List<InvoiceRecord>? invoices,
    List<TherapistPayout>? payouts,
    double? totalGross,
    double? totalTherapist,
    double? totalApp,
    double? totalMaintenance,
    DateTime? from,
    DateTime? to,
    String? clientQuery,
    String? therapistQuery,
    bool? isLoading,
    String? error,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearError = false,
  }) {
    return AdminInvoicesState(
      invoices: invoices ?? this.invoices,
      payouts: payouts ?? this.payouts,
      totalGross: totalGross ?? this.totalGross,
      totalTherapist: totalTherapist ?? this.totalTherapist,
      totalApp: totalApp ?? this.totalApp,
      totalMaintenance: totalMaintenance ?? this.totalMaintenance,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      clientQuery: clientQuery ?? this.clientQuery,
      therapistQuery: therapistQuery ?? this.therapistQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AdminInvoicesNotifier extends StateNotifier<AdminInvoicesState> {
  final Ref _ref;
  final FirebaseFirestore _firestore;

  /// Optional fixed settings used in tests to avoid Firestore dependency on
  /// systemSettingsProvider. When non-null, overrides the provider read.
  final SystemSettings? _settingsOverride;

  /// Full classified invoice list before range filtering.
  /// Cached so range changes don't require a Firestore round-trip.
  List<InvoiceRecord> _allInvoices = [];

  AdminInvoicesNotifier(
    this._ref, {
    FirebaseFirestore? firestore,
    SystemSettings? settingsOverride,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _settingsOverride = settingsOverride,
        super(const AdminInvoicesState()) {
    // React to admin edits of the revenue split: recompute shares live without
    // a Firestore round-trip. Skipped under a test override (fixed settings).
    if (_settingsOverride == null) {
      _ref.listen<AsyncValue<SystemSettings>>(
        systemSettingsProvider,
        (_, __) {
          if (mounted && _allInvoices.isNotEmpty) _applyRangeAndCommit();
        },
      );
    }
    loadInvoices();
  }

  /// Current split settings: test override → live provider value → defaults.
  /// Falling back to defaults (rather than a stale baked value) means a
  /// cold-start race resolves to correct numbers as soon as settings load,
  /// because the provider listener above re-commits when they arrive.
  SystemSettings _currentSettings() =>
      _settingsOverride ??
      _ref.read(systemSettingsProvider).valueOrNull ??
      const SystemSettings();

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // DO NOT use .orderBy('scheduled_time') — Firestore silently drops docs
      // missing that field. Fetch all, sort client-side.
      final snapshot = await _firestore.collection('bookings').get();

      final settings = _currentSettings();
      final allClassified = <InvoiceRecord>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (!InvoiceClassifier.qualifies(data)) continue;

        // Resolve invoice date: prefer scheduled_time, fall back to created_at.
        final scheduledTs = data['scheduled_time'] as Timestamp?;
        final createdTs = data['created_at'] as Timestamp?;
        final date = scheduledTs?.toDate() ?? createdTs?.toDate() ?? DateTime.now();

        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        allClassified.add(InvoiceRecord(
          id: doc.id,
          clientName: data['client_name'] as String? ?? '',
          therapistId: data['therapist_id'] as String? ?? '',
          therapistName: data['therapist_name'] as String? ?? '',
          currency: data['currency'] as String? ?? 'USD',
          status: data['status'] as String? ?? '',
          paymentMethod: data['payment_method'] as String? ?? '',
          amount: amount,
          date: date,
          shares: RevenueSplit.compute(
            amount: amount,
            therapistPct: settings.revenueTherapistPct,
            appPct: settings.revenueAppPct,
            maintenancePct: settings.revenueMaintenancePct,
          ),
        ));
      }

      // Dedupe (same doc qualifying by both rules still counts once).
      final deduped = InvoiceClassifier.dedupe(allClassified, (r) => r.id);

      // Sort descending by date.
      deduped.sort((a, b) => b.date.compareTo(a.date));

      _allInvoices = deduped;
      _applyRangeAndCommit();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setRange(DateTime? from, DateTime? to) {
    state = state.copyWith(
      from: from,
      to: to,
      clearFrom: from == null,
      clearTo: to == null,
    );
    _applyRangeAndCommit();
  }

  void setThisWeek() {
    final now = DateTime.now();
    // Monday of the current week.
    final weekday = now.weekday; // 1=Mon ... 7=Sun
    final monday = DateTime(now.year, now.month, now.day - (weekday - 1));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    setRange(monday, sunday);
  }

  void setThisMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    setRange(firstDay, lastDay);
  }

  void clearRange() {
    state = state.copyWith(clearFrom: true, clearTo: true);
    _applyRangeAndCommit();
  }

  /// Search by client name (بحث باسم العميل). Empty string clears the filter.
  void setClientQuery(String query) {
    state = state.copyWith(clientQuery: query);
    _applyRangeAndCommit();
  }

  /// Search by therapist name (بحث باسم المعالج). Empty string clears it.
  void setTherapistQuery(String query) {
    state = state.copyWith(therapistQuery: query);
    _applyRangeAndCommit();
  }

  Future<void> refresh() => loadInvoices();

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _applyRangeAndCommit() {
    final from = state.from;
    final to = state.to;
    final settings = _currentSettings();
    final clientQ = state.clientQuery.trim().toLowerCase();
    final therapistQ = state.therapistQuery.trim().toLowerCase();

    // Recompute shares from the CURRENT settings every commit so editing the
    // revenue split updates already-loaded invoices without a Firestore reload.
    final filtered = _allInvoices
        .where((inv) => InvoiceFilter.inRange(inv.date, from, to))
        .where((inv) =>
            clientQ.isEmpty || inv.clientName.toLowerCase().contains(clientQ))
        .where((inv) =>
            therapistQ.isEmpty ||
            inv.therapistName.toLowerCase().contains(therapistQ))
        .map((inv) => InvoiceRecord(
              id: inv.id,
              clientName: inv.clientName,
              therapistId: inv.therapistId,
              therapistName: inv.therapistName,
              currency: inv.currency,
              status: inv.status,
              paymentMethod: inv.paymentMethod,
              amount: inv.amount,
              date: inv.date,
              shares: RevenueSplit.compute(
                amount: inv.amount,
                therapistPct: settings.revenueTherapistPct,
                appPct: settings.revenueAppPct,
                maintenancePct: settings.revenueMaintenancePct,
              ),
            ))
        .toList();

    // Group by therapist_id → TherapistPayout.
    final payoutMap = <String, _PayoutAccumulator>{};
    double totalGross = 0;
    double totalTherapist = 0;
    double totalApp = 0;
    double totalMaintenance = 0;

    for (final inv in filtered) {
      totalGross += inv.amount;
      totalTherapist += inv.shares.therapist;
      totalApp += inv.shares.app;
      totalMaintenance += inv.shares.maintenance;

      final acc = payoutMap.putIfAbsent(
        inv.therapistId,
        () => _PayoutAccumulator(
          therapistId: inv.therapistId,
          therapistName: inv.therapistName,
        ),
      );
      acc.add(inv);
    }

    final payouts = payoutMap.values
        .map((acc) => acc.toTherapistPayout())
        .toList()
      ..sort((a, b) => b.gross.compareTo(a.gross)); // highest earner first

    state = state.copyWith(
      invoices: filtered,
      payouts: payouts,
      totalGross: totalGross,
      totalTherapist: totalTherapist,
      totalApp: totalApp,
      totalMaintenance: totalMaintenance,
      isLoading: false,
      clearError: true,
    );
  }
}

/// Mutable accumulator — private implementation detail.
class _PayoutAccumulator {
  final String therapistId;
  final String therapistName;
  int sessions = 0;
  double gross = 0;
  double therapistDue = 0;
  double appCut = 0;
  double maintenance = 0;

  _PayoutAccumulator({required this.therapistId, required this.therapistName});

  void add(InvoiceRecord inv) {
    sessions++;
    gross += inv.amount;
    therapistDue += inv.shares.therapist;
    appCut += inv.shares.app;
    maintenance += inv.shares.maintenance;
  }

  TherapistPayout toTherapistPayout() => TherapistPayout(
        therapistId: therapistId,
        therapistName: therapistName,
        sessions: sessions,
        gross: gross,
        therapistDue: therapistDue,
        appCut: appCut,
        maintenance: maintenance,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final adminInvoicesProvider =
    StateNotifierProvider<AdminInvoicesNotifier, AdminInvoicesState>(
  (ref) => AdminInvoicesNotifier(ref),
);
