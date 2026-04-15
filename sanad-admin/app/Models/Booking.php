<?php

namespace App\Models;

class Booking extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'bookings';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'therapist_id',
        'client_id',
        'client_name',
        'client_email',
        'client_photo_url',
        'client_age',
        'primary_complaint',
        'scheduled_time',
        'duration_minutes',
        'session_type',
        'status',
        'amount',
        'currency',
        'notes',
        'cancellation_reason',
        'rejection_reason',
        'created_at',
        'confirmed_at',
        'completed_at',
        'cancelled_at',
        'updated_at',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'therapist_id' => 'string',
        'client_id' => 'string',
        'client_name' => 'string',
        'client_email' => 'string',
        'client_photo_url' => 'string',
        'client_age' => 'integer',
        'primary_complaint' => 'string',
        'scheduled_time' => 'datetime',
        'duration_minutes' => 'integer',
        'session_type' => 'string',
        'status' => 'string',
        'amount' => 'float',
        'currency' => 'string',
        'notes' => 'string',
        'cancellation_reason' => 'string',
        'rejection_reason' => 'string',
        'created_at' => 'datetime',
        'confirmed_at' => 'datetime',
        'completed_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ─── Defaults ────────────────────────────────────────────

    public function __construct(array $attributes = [])
    {
        // Apply defaults before parent constructor processes attributes.
        $defaults = [
            'duration_minutes' => 60,
            'currency' => 'SAR',
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Check whether this booking is upcoming (not yet occurred).
     *
     * An upcoming booking has a status of 'pending' or 'confirmed'
     * and its scheduled_time is in the future.
     */
    public function isUpcoming(): bool
    {
        $upcomingStatuses = ['pending', 'confirmed'];

        if (! in_array($this->status, $upcomingStatuses, true)) {
            return false;
        }

        if ($this->scheduled_time === null) {
            return false;
        }

        return strtotime($this->scheduled_time) > time();
    }

    /**
     * Get the Heroicon name corresponding to the session type.
     */
    public function getSessionTypeIcon(): string
    {
        return match ($this->session_type) {
            'video' => 'heroicon-o-video-camera',
            'audio' => 'heroicon-o-phone',
            'chat' => 'heroicon-o-chat-bubble-left-right',
            'in_person' => 'heroicon-o-building-office',
            default => 'heroicon-o-question-mark-circle',
        };
    }

    /**
     * Get the Filament color associated with the booking status.
     */
    public function getStatusColor(): string
    {
        return match ($this->status) {
            'pending' => 'warning',
            'confirmed' => 'info',
            'completed' => 'success',
            'rejected' => 'danger',
            'cancelled' => 'gray',
            'no_show' => 'danger',
            default => 'gray',
        };
    }
}
