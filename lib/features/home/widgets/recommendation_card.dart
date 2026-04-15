import 'package:flutter/material.dart';
import '../../content/models/content_models.dart';
import 'content_cards/article_content_card.dart';
import 'content_cards/exercise_content_card.dart';
import 'content_cards/podcast_content_card.dart';
import 'content_cards/tip_content_card.dart';

/// Compact card dispatcher for displaying a premium recommendation (Article, Exercise, or Podcast)
class RecommendationCard extends StatelessWidget {
  final ContentItem content;
  final VoidCallback? onTap;

  const RecommendationCard({super.key, required this.content, this.onTap});

  @override
  Widget build(BuildContext context) {
    switch (content.type) {
      case 'exercise':
        return ExerciseContentCard(content: content, onTap: onTap ?? () {});
      case 'podcast':
      case 'video':
        return PodcastContentCard(content: content, onTap: onTap ?? () {});
      case 'tip':
      case 'challenge':
        return TipContentCard(content: content, onTap: onTap ?? () {});
      case 'article':
      default:
        return ArticleContentCard(content: content, onTap: onTap ?? () {});
    }
  }
}
