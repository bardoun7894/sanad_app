<?php

namespace App\Models;

class User extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'users';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'email',
        'display_name',
        'name',
        'role',
        'is_premium',
        'subscription_status',
        'subscription_plan',
        'subscription_expiry_date',
        'subscription_product_title',
        'subscription_start_date',
        'subscription_assigned_by',
        'subscription_assigned_at',
        'subscription_revoked_at',
        'subscription_revoked_by',
        'payment_gateway',
        'auto_renew',
        'premium_updated_at',
        'phone_number',
        'date_of_birth',
        'last_login',
        'therapist_status',
        'created_at',
        'updated_at',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'email' => 'string',
        'display_name' => 'string',
        'name' => 'string',
        'role' => 'string',
        'is_premium' => 'boolean',
        'subscription_status' => 'string',
        'subscription_plan' => 'string',
        'subscription_expiry_date' => 'datetime',
        'subscription_product_title' => 'string',
        'subscription_start_date' => 'datetime',
        'subscription_assigned_by' => 'string',
        'subscription_assigned_at' => 'datetime',
        'subscription_revoked_at' => 'datetime',
        'subscription_revoked_by' => 'string',
        'payment_gateway' => 'string',
        'auto_renew' => 'boolean',
        'premium_updated_at' => 'datetime',
        'phone_number' => 'string',
        'date_of_birth' => 'datetime',
        'last_login' => 'datetime',
        'therapist_status' => 'string',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the best available display name for this user.
     */
    public function getDisplayName(): string
    {
        return $this->display_name
            ?? $this->name
            ?? $this->email
            ?? 'Unknown';
    }

    /**
     * Check whether the user has the admin role.
     */
    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * Check whether the user has the therapist role.
     */
    public function isTherapist(): bool
    {
        return $this->role === 'therapist';
    }

    /**
     * Check whether the user currently has premium access.
     */
    public function isPremium(): bool
    {
        return (bool) $this->is_premium;
    }

    /**
     * Check whether the user's subscription is currently active.
     *
     * A subscription is considered active when:
     * - subscription_status is 'active', OR
     * - is_premium is true and the expiry date has not passed.
     */
    public function isSubscriptionActive(): bool
    {
        if ($this->subscription_status === 'active') {
            return true;
        }

        if ($this->isPremium() && $this->subscription_expiry_date !== null) {
            return strtotime($this->subscription_expiry_date) > time();
        }

        return false;
    }
}
