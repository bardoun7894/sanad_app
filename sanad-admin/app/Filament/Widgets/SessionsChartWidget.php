<?php

namespace App\Filament\Widgets;

use App\Services\AnalyticsService;
use Filament\Widgets\ChartWidget;

class SessionsChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Session Volume';

    protected static ?int $sort = 6;

    protected int | string | array $columnSpan = [
        'md' => 2,
        'xl' => 2,
    ];

    protected function getData(): array
    {
        $analytics = app(AnalyticsService::class);
        $volume = $analytics->getSessionVolume('monthly');

        $labels = array_map(fn($item) => $item['label'], $volume);
        $data = array_map(fn($item) => $item['count'], $volume);

        return [
            'datasets' => [
                [
                    'label' => 'Sessions',
                    'data' => $data,
                    'backgroundColor' => 'rgba(14, 165, 233, 0.8)',
                    'borderColor' => 'rgb(14, 165, 233)',
                    'borderWidth' => 2,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }

    public function getHeading(): ?string
    {
        return __('session_volume');
    }
}
