<?php

namespace App\Models;

class SubscriptionProduct extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'subscription_products';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'title',
        'description',
        'price',
        'currency_code',
        'billing_period',
        'billing_period_days',
        'localized_price',
        'is_featured',
        'features',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'title' => 'string',
        'description' => 'string',
        'price' => 'float',
        'currency_code' => 'string',
        'billing_period' => 'string',
        'billing_period_days' => 'integer',
        'localized_price' => 'string',
        'is_featured' => 'boolean',
        'features' => 'array',
    ];

    // ─── Defaults ────────────────────────────────────────────

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'currency_code' => 'SAR',
            'is_featured' => false,
            'features' => [],
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the formatted price string with currency prefix.
     */
    public function getFormattedPrice(): string
    {
        $currency = $this->safeGet('currency_code', 'SAR');
        $price = $this->getAttribute('price');

        return $currency.' '.number_format((float) ($price ?? 0), 2);
    }

    /**
     * Get a display label combining title, price, and billing period.
     *
     * Example: "Premium Plan - SAR 199.00/monthly"
     */
    public function getDisplayLabel(): string
    {
        $title = $this->safeGet('title', 'Untitled');
        $formattedPrice = $this->getFormattedPrice();
        $billingPeriod = $this->safeGet('billing_period', 'monthly');

        return $title.' - '.$formattedPrice.'/'.$billingPeriod;
    }
}
