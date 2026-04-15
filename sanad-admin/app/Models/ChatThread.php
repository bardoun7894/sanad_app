<?php

namespace App\Models;

class ChatThread extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'support_chats';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'user_id',
        'user_name',
        'user_email',
        'last_message',
        'last_message_time',
        'unread_count_admin',
        'unread_count_user',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'user_id' => 'string',
        'user_name' => 'string',
        'user_email' => 'string',
        'last_message' => 'string',
        'last_message_time' => 'datetime',
        'unread_count_admin' => 'integer',
        'unread_count_user' => 'integer',
    ];

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Check if this thread has unread messages for admin.
     */
    public function hasUnreadAdmin(): bool
    {
        return ($this->unread_count_admin ?? 0) > 0;
    }

    /**
     * Get a truncated preview of the last message.
     */
    public function getLastMessagePreview(int $length = 60): string
    {
        $message = $this->last_message ?? '';

        if (mb_strlen($message) <= $length) {
            return $message;
        }

        return mb_substr($message, 0, $length).'...';
    }

    /**
     * Get a human-readable time-ago string for the last message.
     */
    public function getTimeAgo(): string
    {
        $time = $this->last_message_time;

        if ($time === null) {
            return __('never');
        }

        try {
            return \Carbon\Carbon::parse($time)->diffForHumans();
        } catch (\Exception $e) {
            return $time;
        }
    }

    /**
     * Get the display name, falling back to email or ID.
     */
    public function getDisplayName(): string
    {
        return $this->user_name
            ?? $this->user_email
            ?? $this->user_id
            ?? __('unknown_user');
    }
}
