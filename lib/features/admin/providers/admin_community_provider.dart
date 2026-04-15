import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../community/models/post.dart';

class AdminCommunityState {
  final bool isLoading;
  final String? error;
  final List<Post> posts;

  const AdminCommunityState({
    this.isLoading = false,
    this.error,
    this.posts = const [],
  });

  AdminCommunityState copyWith({
    bool? isLoading,
    String? error,
    List<Post>? posts,
  }) {
    return AdminCommunityState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      posts: posts ?? this.posts,
    );
  }
}

class AdminCommunityNotifier extends StateNotifier<AdminCommunityState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminCommunityNotifier() : super(const AdminCommunityState()) {
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Fetch recent 50 posts for moderation for now, as no flag system exists
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      final posts = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              // Manual mapping because Post model might not have fromFirestore or it might be internal to the feature
              // Checking Post model from previous view_file...
              // Post model is simple data class, no fromFirestore factory shown in view_file output?
              // Wait, I checked view_file for Post. It DOES NOT have fromFirestore factory in the snippet I saw?
              // Let me check the view_file output again.
              // The output showed lines 1-156. It's a data class with copyWith.
              // It seems I need to implement the mapping myself here or add it to the model.
              // Adding it to the model is better but I can mapped it here for now to avoid modifying existing logic too much.

              return Post(
                id: doc.id,
                author: Author(
                  id: data['author_id'] ?? '',
                  name: data['author_name'] ?? 'Unknown',
                  avatarUrl: data['author_avatar'],
                  isAnonymous: data['is_anonymous'] ?? false,
                ),
                content: data['content'] ?? '',
                category: PostCategory.values.firstWhere(
                  (e) => e.toString().split('.').last == data['category'],
                  orElse: () => PostCategory.general,
                ),
                createdAt: (data['created_at'] as Timestamp).toDate(),
                reactions: {}, // Not needed for moderation list view really
                comments: [], // Not needed for main list
              );
            } catch (e) {
              debugPrint('Error parsing post ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Post>()
          .toList();

      state = state.copyWith(isLoading: false, posts: posts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _fetchPosts();

  Future<void> deletePost(String postId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _firestore.collection('posts').doc(postId).delete();
      await _fetchPosts();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final adminCommunityProvider =
    StateNotifierProvider<AdminCommunityNotifier, AdminCommunityState>((ref) {
      return AdminCommunityNotifier();
    });
