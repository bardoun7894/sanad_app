<?php

namespace App\Models;

use App\Services\FirestoreService;
use Carbon\Carbon;

class MoodEntry extends FirestoreModel
{
    /**
     * The Firestore collection name.
     *
     * This returns the subcollection name used for collectionGroup queries.
     * The actual Firestore path is: users/{userId}/mood_entries/{docId}
     */
    protected function getCollectionName(): string
    {
        return 'mood_entries';
    }

    /**
     * Mood type labels indexed by their integer value (0-5).
     */
    public const MOOD_TYPES = [
        'happy',
        'calm',
        'anxious',
        'sad',
        'angry',
        'tired',
    ];

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'mood',
        'date',
        'note',
        '_parent_id',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'mood' => 'integer',
        'date' => 'datetime',
        'note' => 'string',
        '_parent_id' => 'string',
    ];

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the human-readable mood label for this entry.
     */
    public function getMoodLabel(): string
    {
        $index = $this->mood;

        if ($index !== null && isset(self::MOOD_TYPES[$index])) {
            return self::MOOD_TYPES[$index];
        }

        return 'unknown';
    }

    /**
     * Get a Filament-compatible color based on the mood index.
     *
     * Lower indices (happy, calm) map to positive colors,
     * higher indices (angry, tired) map to negative/warning colors.
     */
    public function getMoodColor(): string
    {
        return match ($this->mood) {
            0 => 'success',   // happy  - green
            1 => 'info',      // calm   - blue
            2 => 'warning',   // anxious - amber
            3 => 'primary',   // sad    - indigo
            4 => 'danger',    // angry  - red
            5 => 'gray',      // tired  - gray
            default => 'gray',
        };
    }

    /**
     * Query recent mood entries across all users via collectionGroup.
     *
     * @param  int  $days  Number of days to look back (default 7).
     * @return array<static>
     */
    public static function queryRecent(int $days = 7): array
    {
        $service = app(FirestoreService::class);

        $since = Carbon::now()->subDays($days);

        $results = $service->queryCollectionGroup(
            'mood_entries',
            [
                ['date', '>=', $since->toDateTimeString()],
            ],
            'date',
            'DESC',
        );

        return array_map(
            fn (array $data) => static::fromFirestore($data),
            $results,
        );
    }
}
