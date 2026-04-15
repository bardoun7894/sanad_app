<?php

namespace App\Models;

use App\Services\FirestoreService;
use Illuminate\Support\Facades\Log;

class SystemSetting extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'system_settings';
    }

    /**
     * The document ID for the single config document.
     */
    protected const CONFIG_DOCUMENT_ID = 'config';

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'maintenance_mode',
        'enable_therapist_application',
        'min_app_version',
        'contact_email',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'maintenance_mode' => 'boolean',
        'enable_therapist_application' => 'boolean',
        'min_app_version' => 'string',
        'contact_email' => 'string',
    ];

    // ─── Static Config Access ────────────────────────────────

    /**
     * Load the singleton config document from Firestore.
     *
     * Returns a SystemSetting instance populated with the current
     * values stored in `system_settings/config`. If the document
     * does not exist, a fresh instance with sensible defaults is returned.
     */
    public static function getConfig(): static
    {
        try {
            $service = app(FirestoreService::class);
            $data = $service->getDocument('system_settings', self::CONFIG_DOCUMENT_ID);

            if ($data !== null) {
                return static::fromFirestore($data);
            }
        } catch (\Exception $e) {
            Log::error("SystemSetting::getConfig failed: {$e->getMessage()}");
        }

        // Return defaults when the document does not exist yet.
        return new static([
            'id' => self::CONFIG_DOCUMENT_ID,
            'maintenance_mode' => false,
            'enable_therapist_application' => true,
            'min_app_version' => '1.0.0',
            'contact_email' => '',
        ]);
    }

    /**
     * Persist the current settings to the `system_settings/config` document.
     *
     * Uses a merge write so only the supplied fields are overwritten.
     */
    public function saveConfig(): void
    {
        $service = app(FirestoreService::class);

        $data = [
            'maintenance_mode' => (bool) $this->getAttribute('maintenance_mode'),
            'enable_therapist_application' => (bool) $this->getAttribute('enable_therapist_application'),
            'min_app_version' => (string) ($this->getAttribute('min_app_version') ?? '1.0.0'),
            'contact_email' => (string) ($this->getAttribute('contact_email') ?? ''),
            'updated_at' => now()->toDateTimeString(),
        ];

        $service->setDocument('system_settings', self::CONFIG_DOCUMENT_ID, $data, merge: true);

        $this->exists = true;
        $this->original = $this->attributes;
    }
}
