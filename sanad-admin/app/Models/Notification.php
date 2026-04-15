<?php

namespace App\Models;

use App\Filament\Resources\BookingResource;
use App\Filament\Resources\UserResource;
use App\Filament\Resources\TherapistResource;
use App\Filament\Resources\PaymentResource;
use App\Filament\Pages\ChatSupport;
use App\Filament\Pages\CommunityModeration;
use App\Filament\Pages\Dashboard;

class Notification extends FirestoreModel
{
    /**
     * The Firestore collection name.
     */
    protected function getCollectionName(): string
    {
        return 'notifications';
    }

    /**
     * Fillable fields.
     */
    protected array $fillable = [
        'user_id',
        'title',
        'body',
        'type',
        'created_at',
        'is_read',
        'read_at',
        'data',
        'action_route',
    ];

    /**
     * Attribute casts.
     */
    protected array $casts = [
        'user_id' => 'string',
        'title' => 'string',
        'body' => 'string',
        'type' => 'string',
        'created_at' => 'datetime',
        'is_read' => 'boolean',
        'read_at' => 'datetime',
        'data' => 'array',
        'action_route' => 'string',
    ];

    // ─── Defaults ────────────────────────────────────────────

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'is_read' => false,
            'type' => 'system',
            'data' => [],
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    // ─── Helper Methods ──────────────────────────────────────

    /**
     * Get the Heroicon name corresponding to the notification type.
     */
    public function getTypeIcon(): string
    {
        return match ($this->type) {
            'booking' => 'heroicon-o-calendar',
            'message' => 'heroicon-o-chat-bubble-left-right',
            'community' => 'heroicon-o-users',
            'mood' => 'heroicon-o-face-smile',
            'system' => 'heroicon-o-cog-6-tooth',
            'therapist' => 'heroicon-o-academic-cap',
            'payment' => 'heroicon-o-banknotes',
            default => 'heroicon-o-bell',
        };
    }

    /**
     * Get the Tailwind color class corresponding to the notification type.
     */
    public function getTypeColor(): string
    {
        return match ($this->type) {
            'booking' => 'text-blue-400',
            'message' => 'text-cyan-400',
            'community' => 'text-purple-400',
            'mood' => 'text-yellow-400',
            'system' => 'text-gray-400',
            'therapist' => 'text-emerald-400',
            'payment' => 'text-green-400',
            default => 'text-gray-400',
        };
    }

    /**
     * Get the Tailwind background color class corresponding to the notification type.
     */
    public function getTypeBgColor(): string
    {
        return match ($this->type) {
            'booking' => 'bg-blue-500/10',
            'message' => 'bg-cyan-500/10',
            'community' => 'bg-purple-500/10',
            'mood' => 'bg-yellow-500/10',
            'system' => 'bg-gray-500/10',
            'therapist' => 'bg-emerald-500/10',
            'payment' => 'bg-green-500/10',
            default => 'bg-gray-500/10',
        };
    }

    /**
     * Get the admin panel URL for this notification action.
     *
     * Maps the notification type to an admin route using Filament
     * Resource/Page URL helpers instead of hardcoded paths.
     */
    public function getActionUrl(): string
    {
        $actionRoute = trim((string) ($this->getAttribute('action_route') ?? ''));

        if ($actionRoute !== '') {
            if (str_starts_with($actionRoute, 'http://') || str_starts_with($actionRoute, 'https://')) {
                return $actionRoute;
            }

            if (str_starts_with($actionRoute, '/admin')) {
                return url($actionRoute);
            }

            if (str_starts_with($actionRoute, 'admin/')) {
                return url('/'.$actionRoute);
            }

            if (str_starts_with($actionRoute, '/')) {
                return url('/admin'.$actionRoute);
            }

            return url('/admin/'.$actionRoute);
        }

        return match ($this->type) {
            'booking' => BookingResource::getUrl(),
            'message' => ChatSupport::getUrl(),
            'community' => CommunityModeration::getUrl(),
            'mood' => UserResource::getUrl(),
            'system' => Dashboard::getUrl(),
            'therapist' => TherapistResource::getUrl(),
            'payment' => PaymentResource::getUrl(),
            default => Dashboard::getUrl(),
        };
    }

    /**
     * Get a human-readable time-ago string for created_at.
     */
    public function getTimeAgo(): string
    {
        $createdAt = $this->getAttribute('created_at');

        if (! $createdAt) {
            return __('just_now');
        }

        try {
            return \Carbon\Carbon::parse($createdAt)->diffForHumans();
        } catch (\Exception $e) {
            return __('just_now');
        }
    }
}
