<?php

namespace App\Filament\Widgets;

use App\Models\ActivityLog;
use Filament\Widgets\Widget;

class RecentActivityWidget extends Widget
{
    protected static string $view = 'filament.widgets.recent-activity-widget';

    protected static ?int $sort = 10;

    protected int|string|array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];

    public function getActivities(): array
    {
        try {
            return ActivityLog::all(
                orderBy: 'timestamp',
                direction: 'DESC',
                limit: 5,
            );
        } catch (\Exception $e) {
            return [];
        }
    }

    public function getTypeIcon(string $type): string
    {
        return match ($type) {
            'sessionCompleted' => 'heroicon-o-check-circle',
            'bookingCreated' => 'heroicon-o-calendar',
            'moodLogged' => 'heroicon-o-face-smile',
            'postCreated' => 'heroicon-o-chat-bubble-left',
            'userRegistered' => 'heroicon-o-user-plus',
            'therapistApproved' => 'heroicon-o-shield-check',
            'paymentVerified' => 'heroicon-o-banknotes',
            default => 'heroicon-o-information-circle',
        };
    }

    public function getTypeColor(string $type): string
    {
        return match ($type) {
            'sessionCompleted' => 'text-green-400',
            'bookingCreated' => 'text-blue-400',
            'moodLogged' => 'text-purple-400',
            'postCreated' => 'text-cyan-400',
            'userRegistered' => 'text-emerald-400',
            'therapistApproved' => 'text-amber-400',
            'paymentVerified' => 'text-yellow-400',
            default => 'text-gray-400',
        };
    }

    public function getTypeBgColor(string $type): string
    {
        return match ($type) {
            'sessionCompleted' => 'bg-green-500/10',
            'bookingCreated' => 'bg-blue-500/10',
            'moodLogged' => 'bg-purple-500/10',
            'postCreated' => 'bg-cyan-500/10',
            'userRegistered' => 'bg-emerald-500/10',
            'therapistApproved' => 'bg-amber-500/10',
            'paymentVerified' => 'bg-yellow-500/10',
            default => 'bg-gray-500/10',
        };
    }
}
