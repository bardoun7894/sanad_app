<?php

namespace App\Models;

class Assessment extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'assessments';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'risk_level',
        'user_id',
        'created_at',
        'updated_at',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'risk_level' => 'string',
        'user_id' => 'string',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the Filament color associated with the risk level.
     */
    public function getRiskLevelColor(): string
    {
        return match ($this->risk_level) {
            'critical' => 'danger',
            'high' => 'warning',
            'moderate' => 'info',
            'low' => 'success',
            default => 'gray',
        };
    }

    /**
     * Determine whether this assessment is considered critical.
     *
     * An assessment is critical if the risk level is 'high' or 'critical'.
     */
    public function isCritical(): bool
    {
        return in_array($this->risk_level, ['high', 'critical'], true);
    }
}
