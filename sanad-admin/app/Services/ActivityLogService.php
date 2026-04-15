<?php

namespace App\Services;

use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ActivityLogService
{
    protected FirestoreService $firestore;

    public function __construct(FirestoreService $firestore)
    {
        $this->firestore = $firestore;
    }

    /**
     * Log an admin/system action to the Firestore activity_logs collection.
     *
     * This method is intentionally non-blocking: failures are captured
     * and logged but never re-thrown, so callers are not disrupted.
     *
     * The `actor_uid` field is always included to identify who performed
     * the action. It is derived from the authenticated admin user, or
     * from the metadata if explicitly provided by the caller.
     *
     * @param  string  $type  Activity type (e.g. sessionCompleted, bookingCreated).
     * @param  string  $description  Human-readable description of the action.
     * @param  array  $metadata  Optional additional data to attach to the log entry.
     */
    public function log(string $type, string $description, array $metadata = []): void
    {
        try {
            $user = Auth::user();
            $actorUid = $metadata['actor_uid'] ?? $user?->getKey() ?? 'system';

            $data = [
                'type' => $type,
                'actor_uid' => $actorUid,
                'user_id' => $user?->getKey() ?? 'system',
                'user_name' => $user?->getDisplayName() ?? 'System',
                'description' => $description,
                'timestamp' => now()->toDateTimeString(),
                'metadata' => $metadata,
            ];

            $this->firestore->addDocument('activity_logs', $data);
        } catch (\Throwable $e) {
            Log::error('ActivityLogService::log failed', [
                'type' => $type,
                'description' => $description,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
