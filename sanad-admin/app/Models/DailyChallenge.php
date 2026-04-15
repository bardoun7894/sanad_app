<?php

namespace App\Models;

class DailyChallenge extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'daily_challenges';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'title',
        'title_en',
        'description',
        'description_en',
        'type',
        'duration_minutes',
        'order',
        'publish_date',
        'is_active',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'title' => 'string',
        'title_en' => 'string',
        'description' => 'string',
        'description_en' => 'string',
        'type' => 'string',
        'duration_minutes' => 'integer',
        'order' => 'integer',
        'publish_date' => 'datetime',
        'is_active' => 'boolean',
    ];

    // ─── Defaults ────────────────────────────────────────────

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'type' => 'general',
            'duration_minutes' => 10,
            'order' => 0,
            'is_active' => true,
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the badge color for the challenge type.
     */
    public function getTypeColor(): string
    {
        return match ($this->type) {
            'breathing' => 'info',
            'gratitude' => 'success',
            'mindfulness' => 'primary',
            'exercise' => 'warning',
            'journaling' => 'gray',
            'social' => 'danger',
            'selfCare' => 'success',
            'general' => 'gray',
            default => 'gray',
        };
    }
}
