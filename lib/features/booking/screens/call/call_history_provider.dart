import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'call_invite_service.dart';

/// State for paginated call history
class CallHistoryState {
  final List<CallInvite> calls;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot? lastDocument;

  const CallHistoryState({
    this.calls = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastDocument,
  });

  CallHistoryState copyWith({
    List<CallInvite>? calls,
    bool? isLoading,
    bool? hasMore,
    String? error,
    DocumentSnapshot? lastDocument,
  }) {
    return CallHistoryState(
      calls: calls ?? this.calls,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

/// Notifier for paginated call history
class CallHistoryNotifier extends StateNotifier<CallHistoryState> {
  final String userId;
  final FirebaseFirestore _firestore;
  static const int _pageSize = 20;

  CallHistoryNotifier({
    required this.userId,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const CallHistoryState()) {
    loadInitial();
  }

  CollectionReference get _invitesRef => _firestore.collection('call_invites');

  Future<void> loadInitial() async {
    if (userId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Query where user is caller OR callee
      // Firestore doesn't support OR across fields, so we do two queries
      final callerQuery = await _invitesRef
          .where('caller_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(_pageSize)
          .get();

      final calleeQuery = await _invitesRef
          .where('callee_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(_pageSize)
          .get();

      // Merge and deduplicate
      final allDocs = <String, DocumentSnapshot>{};
      for (final doc in callerQuery.docs) {
        allDocs[doc.id] = doc;
      }
      for (final doc in calleeQuery.docs) {
        allDocs[doc.id] = doc;
      }

      final calls = allDocs.values
          .map((doc) => CallInvite.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Take only pageSize items
      final paginated = calls.take(_pageSize).toList();

      state = CallHistoryState(
        calls: paginated,
        isLoading: false,
        hasMore: paginated.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load call history',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || userId.isEmpty) return;
    state = state.copyWith(isLoading: true);

    try {
      final lastCreatedAt = state.calls.isNotEmpty
          ? Timestamp.fromDate(state.calls.last.createdAt)
          : null;

      if (lastCreatedAt == null) {
        state = state.copyWith(isLoading: false, hasMore: false);
        return;
      }

      final callerQuery = await _invitesRef
          .where('caller_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .startAfter([lastCreatedAt])
          .limit(_pageSize)
          .get();

      final calleeQuery = await _invitesRef
          .where('callee_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .startAfter([lastCreatedAt])
          .limit(_pageSize)
          .get();

      final allDocs = <String, DocumentSnapshot>{};
      for (final doc in callerQuery.docs) {
        allDocs[doc.id] = doc;
      }
      for (final doc in calleeQuery.docs) {
        allDocs[doc.id] = doc;
      }

      // Remove already-loaded IDs
      final existingIds = state.calls.map((c) => c.id).toSet();
      allDocs.removeWhere((id, _) => existingIds.contains(id));

      final newCalls = allDocs.values
          .map((doc) => CallInvite.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final paginated = newCalls.take(_pageSize).toList();

      state = state.copyWith(
        calls: [...state.calls, ...paginated],
        isLoading: false,
        hasMore: paginated.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more calls',
      );
    }
  }

  Future<void> refresh() async {
    state = const CallHistoryState();
    await loadInitial();
  }
}

/// Provider for call history, keyed by userId
final callHistoryProvider =
    StateNotifierProvider.family<CallHistoryNotifier, CallHistoryState, String>(
  (ref, userId) => CallHistoryNotifier(userId: userId),
);
