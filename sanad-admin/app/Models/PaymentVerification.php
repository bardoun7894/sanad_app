<?php

namespace App\Models;

class PaymentVerification extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'payment_verifications';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'user_id',
        'user_name',
        'user_email',
        'product_id',
        'product_title',
        'amount',
        'currency',
        'reference_code',
        'receipt_url',
        'status',
        'created_at',
        'reviewed_at',
        'reviewed_by',
        'rejection_reason',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'user_id' => 'string',
        'user_name' => 'string',
        'user_email' => 'string',
        'product_id' => 'string',
        'product_title' => 'string',
        'amount' => 'float',
        'currency' => 'string',
        'reference_code' => 'string',
        'receipt_url' => 'string',
        'status' => 'string',
        'created_at' => 'datetime',
        'reviewed_at' => 'datetime',
        'reviewed_by' => 'string',
        'rejection_reason' => 'string',
    ];

    // ─── Defaults ────────────────────────────────────────────

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'currency' => 'USD',
            'status' => 'pending',
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the Filament color associated with the verification status.
     */
    public function getStatusColor(): string
    {
        return match ($this->status) {
            'approved' => 'success',
            'pending' => 'warning',
            'rejected' => 'danger',
            default => 'gray',
        };
    }

    /**
     * Check whether the verification is still pending.
     */
    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    /**
     * Check whether the verification has been approved.
     */
    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }
}
