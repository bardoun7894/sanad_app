<?php

namespace App\Models;

class CommunityPost extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'posts';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'author_id',
        'author_name',
        'author_avatar',
        'is_anonymous',
        'content',
        'category',
        'created_at',
        'report_count',
        'reactions',
        'comments_count',
        'updated_at',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'author_id' => 'string',
        'author_name' => 'string',
        'author_avatar' => 'string',
        'is_anonymous' => 'boolean',
        'content' => 'string',
        'category' => 'string',
        'created_at' => 'datetime',
        'report_count' => 'integer',
        'reactions' => 'array',
        'comments_count' => 'integer',
        'updated_at' => 'datetime',
    ];

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Check whether the post has been reported.
     */
    public function isReported(): bool
    {
        return ($this->report_count ?? 0) > 0;
    }

    /**
     * Get the Filament color corresponding to the post category.
     */
    public function getCategoryColor(): string
    {
        return match ($this->category) {
            'general' => 'primary',
            'anxiety' => 'warning',
            'depression' => 'info',
            'relationships' => 'success',
            'selfCare' => 'secondary',
            'motivation' => 'primary',
            default => 'gray',
        };
    }

    /**
     * Get the display-friendly category label.
     */
    public function getCategoryLabel(): string
    {
        return match ($this->category) {
            'general' => __('category_general'),
            'anxiety' => __('category_anxiety'),
            'depression' => __('category_depression'),
            'relationships' => __('category_relationships'),
            'selfCare' => __('category_self_care'),
            'motivation' => __('category_motivation'),
            default => __('category_unknown'),
        };
    }

    /**
     * Get the display name for the author, respecting anonymity.
     */
    public function getAuthorDisplayName(): string
    {
        if ($this->is_anonymous) {
            return __('anonymous');
        }

        return $this->author_name ?? __('unknown_user');
    }

    /**
     * Get a truncated content preview.
     */
    public function getContentPreview(int $length = 200): string
    {
        $content = $this->content ?? '';

        if (mb_strlen($content) <= $length) {
            return $content;
        }

        return mb_substr($content, 0, $length).'...';
    }

    /**
     * Get a summary of reactions.
     */
    public function getReactionsSummary(): string
    {
        $reactions = $this->reactions;

        if (empty($reactions) || ! is_array($reactions)) {
            return __('no_reactions');
        }

        $parts = [];
        foreach ($reactions as $type => $count) {
            if (is_numeric($count) && (int) $count > 0) {
                $parts[] = "{$type}: {$count}";
            } elseif (is_array($count)) {
                $parts[] = "{$type}: ".count($count);
            }
        }

        return ! empty($parts) ? implode(', ', $parts) : __('no_reactions');
    }
}
