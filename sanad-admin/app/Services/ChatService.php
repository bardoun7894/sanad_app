<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

class ChatService
{
    protected FirestoreService $firestore;

    public function __construct(FirestoreService $firestore)
    {
        $this->firestore = $firestore;
    }

    /**
     * Get all chat threads ordered by last_message_time DESC.
     */
    public function getThreads(?int $limit = 50): array
    {
        try {
            return $this->firestore->queryCollection(
                'support_chats',
                [],
                'last_message_time',
                'DESC',
                $limit,
            );
        } catch (\Exception $e) {
            Log::error("ChatService getThreads failed: {$e->getMessage()}");

            return [];
        }
    }

    /**
     * Get messages for a thread, ordered by timestamp ASC.
     */
    public function getMessages(string $threadId, ?int $limit = 50): array
    {
        try {
            return $this->firestore->getSubcollection(
                'support_chats',
                $threadId,
                'messages',
                [],
                'timestamp',
                'ASC',
                $limit,
            );
        } catch (\Exception $e) {
            Log::error("ChatService getMessages failed: {$e->getMessage()}");

            return [];
        }
    }

    /**
     * Send a message to a thread.
     */
    public function sendMessage(string $threadId, string $content, bool $isBroadcast = false): void
    {
        try {
            $messageData = [
                'sender_id' => 'admin',
                'content' => $content,
                'timestamp' => now()->toDateTimeString(),
                'is_read' => false,
                'is_broadcast' => $isBroadcast,
            ];

            $this->firestore->addToSubcollection('support_chats', $threadId, 'messages', $messageData);

            // Update thread metadata
            $thread = $this->firestore->getDocument('support_chats', $threadId);
            $currentCount = $thread['unread_count_user'] ?? 0;
            $this->firestore->updateDocument('support_chats', $threadId, [
                'last_message' => mb_substr($content, 0, 100),
                'last_message_time' => now()->toDateTimeString(),
                'unread_count_user' => $currentCount + 1,
            ]);
        } catch (\Exception $e) {
            Log::error("ChatService sendMessage failed: {$e->getMessage()}");
            throw $e;
        }
    }

    /**
     * Create a new chat thread for a user.
     */
    public function createThread(string $userId, string $userName, string $userEmail): void
    {
        try {
            $this->firestore->setDocument('support_chats', $userId, [
                'user_id' => $userId,
                'user_name' => $userName,
                'user_email' => $userEmail,
                'last_message' => '',
                'last_message_time' => now()->toDateTimeString(),
                'unread_count_admin' => 0,
                'unread_count_user' => 0,
            ]);
        } catch (\Exception $e) {
            Log::error("ChatService createThread failed: {$e->getMessage()}");
            throw $e;
        }
    }

    /**
     * Broadcast a message to all threads.
     */
    public function broadcastMessage(string $content): int
    {
        try {
            $threads = $this->getThreads(500);
            $count = 0;

            foreach ($threads as $thread) {
                $threadId = $thread['id'];
                $this->sendMessage($threadId, $content, true);
                $count++;
            }

            return $count;
        } catch (\Exception $e) {
            Log::error("ChatService broadcastMessage failed: {$e->getMessage()}");
            throw $e;
        }
    }

    /**
     * Mark all admin messages as read in a thread.
     */
    public function markThreadRead(string $threadId): void
    {
        try {
            $this->firestore->updateDocument('support_chats', $threadId, [
                'unread_count_admin' => 0,
            ]);
        } catch (\Exception $e) {
            Log::error("ChatService markThreadRead failed: {$e->getMessage()}");
        }
    }

    /**
     * Get unread count for admin across all threads.
     */
    public function getTotalUnreadCount(): int
    {
        try {
            $threads = $this->getThreads(500);

            return array_sum(array_map(fn ($t) => (int) ($t['unread_count_admin'] ?? 0), $threads));
        } catch (\Exception $e) {
            return 0;
        }
    }

    /**
     * Get chat stats.
     */
    public function getStats(): array
    {
        try {
            $threads = $this->getThreads(500);
            $totalConversations = count($threads);
            $unreadMessages = array_sum(array_map(fn ($t) => (int) ($t['unread_count_admin'] ?? 0), $threads));

            return [
                'total_conversations' => $totalConversations,
                'unread_messages' => $unreadMessages,
                'urgent_count' => 0,
                'avg_response_time' => __('not_available'),
            ];
        } catch (\Exception $e) {
            return [
                'total_conversations' => 0,
                'unread_messages' => 0,
                'urgent_count' => 0,
                'avg_response_time' => __('not_available'),
            ];
        }
    }
}
