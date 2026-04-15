<?php

namespace App\Filament\Widgets;

use App\Models\Booking;
use Carbon\Carbon;
use Filament\Widgets\Widget;

class WeeklyAgendaWidget extends Widget
{
    protected static string $view = 'filament.widgets.weekly-agenda-widget';

    protected static ?int $sort = 8;

    protected int|string|array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];

    public function getWeekData(): array
    {
        $startOfWeek = Carbon::now()->startOfWeek();
        $endOfWeek = Carbon::now()->endOfWeek();

        try {
            $bookings = Booking::all(
                wheres: [
                    ['scheduled_time', '>=', $startOfWeek->toDateTimeString()],
                    ['scheduled_time', '<=', $endOfWeek->toDateTimeString()],
                ],
                orderBy: 'scheduled_time',
                direction: 'ASC',
            );
        } catch (\Exception $e) {
            $bookings = [];
        }

        // Group by day of week
        $days = [];
        for ($i = 0; $i < 7; $i++) {
            $date = $startOfWeek->copy()->addDays($i);
            $days[$date->format('Y-m-d')] = [
                'label' => $date->format('D'),
                'date' => $date->format('M d'),
                'isToday' => $date->isToday(),
                'bookings' => [],
            ];
        }

        foreach ($bookings as $booking) {
            $dateKey = Carbon::parse($booking->scheduled_time)->format('Y-m-d');
            if (isset($days[$dateKey])) {
                $days[$dateKey]['bookings'][] = $booking;
            }
        }

        return $days;
    }

    public function getSessionIcon(string $type): string
    {
        return match ($type) {
            'video' => 'heroicon-o-video-camera',
            'audio' => 'heroicon-o-phone',
            'chat' => 'heroicon-o-chat-bubble-left-right',
            'in_person' => 'heroicon-o-building-office',
            default => 'heroicon-o-clock',
        };
    }
}
