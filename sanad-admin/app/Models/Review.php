<?php

namespace App\Models;

class Review extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'reviews';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'therapist_id',
        'user_id',
        'booking_id',
        'rating',
        'comment',
        'created_at',
        'updated_at',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'therapist_id' => 'string',
        'user_id' => 'string',
        'booking_id' => 'string',
        'rating' => 'float',
        'comment' => 'string',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the star rating display string.
     */
    public function getStarRating(): string
    {
        $rating = $this->getAttribute('rating') ?? 0;
        $fullStars = (int) floor($rating);
        $halfStar = ($rating - $fullStars) >= 0.5;
        $emptyStars = 5 - $fullStars - ($halfStar ? 1 : 0);

        return str_repeat('*', $fullStars)
            .($halfStar ? '+' : '')
            .str_repeat('-', $emptyStars);
    }

    /**
     * Get the Filament color associated with the rating value.
     */
    public function getRatingColor(): string
    {
        $rating = $this->getAttribute('rating') ?? 0;

        return match (true) {
            $rating >= 4.0 => 'success',
            $rating >= 3.0 => 'warning',
            $rating >= 2.0 => 'info',
            default => 'danger',
        };
    }

    /**
     * Get a formatted rating string (e.g. "4.5 / 5.0").
     */
    public function getFormattedRating(): string
    {
        $rating = $this->getAttribute('rating') ?? 0;

        return number_format((float) $rating, 1).' / 5.0';
    }
}
