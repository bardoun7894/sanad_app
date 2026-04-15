<?php

namespace App\Models;

use App\Services\FirestoreService;
use Illuminate\Support\Facades\Log;

class AdminAIChat extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'admin_ai_chats';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'admin_id',
        'last_message',
        'last_message_time',
        'updated_at',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'admin_id' => 'string',
        'last_message' => 'string',
        'last_message_time' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ─── Subcollection: messages ─────────────────────────────

    /**
     * Get all messages from the admin's chat subcollection.
     *
     * Returns an array of message documents sorted by timestamp ASC.
     * Each message has: role (user|assistant), content, timestamp.
     *
     * @return array<int, array{id: string, role: string, content: string, timestamp: string}>
     */
    public static function getMessages(string $adminId): array
    {
        try {
            $firestore = app(FirestoreService::class);

            return $firestore->getSubcollection(
                parentCollection: 'admin_ai_chats',
                parentId: $adminId,
                subcollection: 'messages',
                orderBy: 'timestamp',
                direction: 'ASC',
            );
        } catch (\Exception $e) {
            Log::error("AdminAIChat::getMessages failed: {$e->getMessage()}", [
                'admin_id' => $adminId,
            ]);

            return [];
        }
    }

    /**
     * Add a message to the admin's chat subcollection.
     *
     * @param  string  $adminId  The admin's Firebase Auth UID.
     * @param  string  $role  'user' or 'assistant'.
     * @param  string  $content  The message text.
     * @return string The generated document ID.
     */
    public static function addMessage(string $adminId, string $role, string $content): string
    {
        try {
            $firestore = app(FirestoreService::class);

            $messageData = [
                'role' => $role,
                'content' => $content,
                'timestamp' => now()->toDateTimeString(),
            ];

            $messageId = $firestore->addToSubcollection(
                parentCollection: 'admin_ai_chats',
                parentId: $adminId,
                subcollection: 'messages',
                data: $messageData,
            );

            // Update the parent chat document with the latest message info.
            $firestore->setDocument('admin_ai_chats', $adminId, [
                'admin_id' => $adminId,
                'last_message' => mb_substr($content, 0, 200),
                'last_message_time' => now()->toDateTimeString(),
                'updated_at' => now()->toDateTimeString(),
            ], merge: true);

            return $messageId;
        } catch (\Exception $e) {
            Log::error("AdminAIChat::addMessage failed: {$e->getMessage()}", [
                'admin_id' => $adminId,
                'role' => $role,
            ]);

            return '';
        }
    }

    /**
     * Delete all messages in the admin's chat subcollection.
     */
    public static function clearMessages(string $adminId): void
    {
        try {
            $firestore = app(FirestoreService::class);

            $messages = $firestore->getSubcollection(
                parentCollection: 'admin_ai_chats',
                parentId: $adminId,
                subcollection: 'messages',
            );

            foreach ($messages as $message) {
                if (isset($message['id'])) {
                    $firestore->deleteSubcollectionDocument('admin_ai_chats', $adminId, 'messages', $message['id']);
                }
            }

            // Reset the parent document.
            $firestore->setDocument('admin_ai_chats', $adminId, [
                'admin_id' => $adminId,
                'last_message' => '',
                'last_message_time' => now()->toDateTimeString(),
                'updated_at' => now()->toDateTimeString(),
            ], merge: true);
        } catch (\Exception $e) {
            Log::error("AdminAIChat::clearMessages failed: {$e->getMessage()}", [
                'admin_id' => $adminId,
            ]);
        }
    }
}
