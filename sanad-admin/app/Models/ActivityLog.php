<?php

namespace App\Models;

class ActivityLog extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'activity_logs';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'type',
        'user_id',
        'user_name',
        'description',
        'timestamp',
        'metadata',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'type' => 'string',
        'user_id' => 'string',
        'user_name' => 'string',
        'description' => 'string',
        'timestamp' => 'datetime',
        'metadata' => 'array',
    ];

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the Heroicon name corresponding to the activity type.
     */
    public function getTypeIcon(): string
    {
        return match ($this->type) {
            'sessionCompleted' => 'heroicon-o-check-circle',
            'bookingCreated' => 'heroicon-o-calendar',
            'moodLogged' => 'heroicon-o-face-smile',
            'postCreated' => 'heroicon-o-document-text',
            'userRegistered' => 'heroicon-o-user-plus',
            'therapistApproved' => 'heroicon-o-shield-check',
            'paymentVerified' => 'heroicon-o-credit-card',
            default => 'heroicon-o-information-circle',
        };
    }

    /**
     * Get the Filament color associated with the activity type.
     */
    public function getTypeColor(): string
    {
        return match ($this->type) {
            'sessionCompleted' => 'success',
            'bookingCreated' => 'info',
            'moodLogged' => 'primary',
            'postCreated' => 'warning',
            'userRegistered' => 'success',
            'therapistApproved' => 'info',
            'paymentVerified' => 'success',
            default => 'gray',
        };
    }
}
