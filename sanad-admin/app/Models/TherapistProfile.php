<?php

namespace App\Models;

class TherapistProfile extends FirestoreModel
{
    /**
     * The Firestore collection name.
     *
     * Document ID = Firebase Auth UID.
     */
    protected function getCollectionName(): string
    {
        return 'therapists';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'email',
        'name',
        'title',
        'bio',
        'photo_url',
        'specialties',
        'session_types',
        'therapy_types',
        'languages',
        'qualifications',
        'session_price',
        'currency',
        'years_experience',
        'approval_status',
        'is_active',
        'rating',
        'review_count',
        'created_at',
        'approved_at',
        'approved_by',
        'rejection_reason',
        'license_document_url',
        'phone_number',
        'updated_at',
        'status',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'email' => 'string',
        'name' => 'string',
        'title' => 'string',
        'bio' => 'string',
        'photo_url' => 'string',
        'specialties' => 'array',
        'session_types' => 'array',
        'therapy_types' => 'array',
        'languages' => 'array',
        'qualifications' => 'array',
        'session_price' => 'float',
        'currency' => 'string',
        'years_experience' => 'integer',
        'approval_status' => 'string',
        'is_active' => 'boolean',
        'rating' => 'float',
        'review_count' => 'integer',
        'created_at' => 'datetime',
        'approved_at' => 'datetime',
        'approved_by' => 'string',
        'rejection_reason' => 'string',
        'license_document_url' => 'string',
        'phone_number' => 'string',
        'updated_at' => 'datetime',
        'status' => 'string',
    ];

    // ─── Defaults ────────────────────────────────────────────

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'currency' => 'SAR',
            'approval_status' => 'pending',
            'is_active' => false,
            'rating' => 0.0,
            'review_count' => 0,
            'specialties' => [],
            'session_types' => [],
            'therapy_types' => [],
            'languages' => [],
            'qualifications' => [],
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the Filament color associated with the approval status.
     */
    public function getApprovalStatusColor(): string
    {
        return match ($this->approval_status) {
            'pending' => 'warning',
            'approved' => 'success',
            'rejected' => 'danger',
            'suspended' => 'gray',
            default => 'gray',
        };
    }

    /**
     * Get the Heroicon name corresponding to the approval status.
     */
    public function getApprovalStatusIcon(): string
    {
        return match ($this->approval_status) {
            'pending' => 'heroicon-o-clock',
            'approved' => 'heroicon-o-check-circle',
            'rejected' => 'heroicon-o-x-circle',
            'suspended' => 'heroicon-o-no-symbol',
            default => 'heroicon-o-question-mark-circle',
        };
    }

    /**
     * Get the formatted session price string with currency prefix.
     */
    public function getFormattedPrice(): string
    {
        $currency = $this->safeGet('currency', 'SAR');
        $price = $this->getAttribute('session_price');

        return $currency.' '.number_format((float) ($price ?? 0), 2);
    }

    /**
     * Get a comma-separated string of specialties.
     */
    public function getSpecialtiesLabels(): string
    {
        $specialties = $this->getAttribute('specialties');

        if (! is_array($specialties) || empty($specialties)) {
            return 'N/A';
        }

        return implode(', ', $specialties);
    }

    /**
     * Determine whether the therapist is pending approval.
     */
    public function isPending(): bool
    {
        return $this->approval_status === 'pending';
    }

    /**
     * Determine whether the therapist is approved.
     */
    public function isApproved(): bool
    {
        return $this->approval_status === 'approved';
    }

    /**
     * Determine whether the therapist is rejected.
     */
    public function isRejected(): bool
    {
        return $this->approval_status === 'rejected';
    }
}
