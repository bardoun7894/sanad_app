<?php

namespace App\Models;

class Payment extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'payments';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'user_id',
        'user_email',
        'amount',
        'currency',
        'status',
        'payment_method',
        'reference_code',
        'gateway_transaction_id',
        'product_id',
        'product_title',
        'start_date',
        'end_date',
        'notes',
        'created_at',
        'updated_at',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'user_id' => 'string',
        'user_email' => 'string',
        'amount' => 'float',
        'currency' => 'string',
        'status' => 'string',
        'payment_method' => 'string',
        'reference_code' => 'string',
        'gateway_transaction_id' => 'string',
        'product_id' => 'string',
        'product_title' => 'string',
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'notes' => 'string',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ─── Defaults ────────────────────────────────────────────

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'currency' => 'SAR',
            'status' => 'pending',
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the Filament color associated with the payment status.
     */
    public function getStatusColor(): string
    {
        return match ($this->status) {
            'completed' => 'success',
            'pending' => 'warning',
            'failed' => 'danger',
            'refunded' => 'info',
            default => 'gray',
        };
    }

    /**
     * Get the Heroicon name corresponding to the payment status.
     */
    public function getStatusIcon(): string
    {
        return match ($this->status) {
            'completed' => 'heroicon-o-check-circle',
            'pending' => 'heroicon-o-clock',
            'failed' => 'heroicon-o-x-circle',
            'refunded' => 'heroicon-o-arrow-uturn-left',
            default => 'heroicon-o-question-mark-circle',
        };
    }

    /**
     * Get the formatted amount string with currency prefix.
     */
    public function getFormattedAmount(): string
    {
        $currency = $this->safeGet('currency', 'SAR');
        $amount = $this->getAttribute('amount');

        return $currency.' '.number_format((float) ($amount ?? 0), 2);
    }
}
