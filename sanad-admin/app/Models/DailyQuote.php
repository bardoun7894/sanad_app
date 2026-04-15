<?php

namespace App\Models;

class DailyQuote extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'daily_quotes';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'text',
        'author',
        'category',
        'publish_date',
        'is_active',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'text' => 'string',
        'author' => 'string',
        'category' => 'string',
        'publish_date' => 'datetime',
        'is_active' => 'boolean',
    ];

    // ─── Defaults ────────────────────────────────────────────

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'is_active' => true,
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }
}
