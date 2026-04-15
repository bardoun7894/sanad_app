<?php

namespace App\Models;

class AppContent extends FirestoreModel
{
    protected function getCollectionName(): string
    {
        return 'content';
    }

    protected array $fillable = [
        'title',
        'category',
        'type',
        'content_text',
        'media_url',
        'link_url',
        'thumbnail_url',
        'is_premium',
        'mood_tags',
        'is_published',
        'created_at',
    ];

    protected array $casts = [
        'title' => 'string',
        'category' => 'string',
        'type' => 'string',
        'content_text' => 'string',
        'media_url' => 'string',
        'link_url' => 'string',
        'thumbnail_url' => 'string',
        'is_premium' => 'boolean',
        'mood_tags' => 'array',
        'is_published' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'type' => 'article',
            'is_published' => false,
            'is_premium' => false,
            'mood_tags' => [],
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    public function getTypeColor(): string
    {
        return match ($this->type) {
            'article' => 'primary',
            'exercise' => 'success',
            'video' => 'warning',
            'podcast' => 'info',
            default => 'gray',
        };
    }
}
