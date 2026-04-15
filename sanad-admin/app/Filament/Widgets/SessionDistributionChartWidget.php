<?php

namespace App\Filament\Widgets;

use App\Services\AnalyticsService;
use Filament\Widgets\ChartWidget;

class SessionDistributionChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Session Type Distribution';

    protected static ?int $sort = 7;

    protected int | string | array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];

    protected function getData(): array
    {
        $analytics = app(AnalyticsService::class);
        $distribution = $analytics->getSessionTypeDistribution();

        $labels = array_map(fn($item) => ucfirst($item['type']), $distribution);
        $data = array_map(fn($item) => $item['count'], $distribution);

        return [
            'datasets' => [
                [
                    'label' => 'Sessions',
                    'data' => $data,
                    'backgroundColor' => [
                        'rgba(14, 165, 233, 0.8)',
                        'rgba(56, 189, 248, 0.8)',
                        'rgba(125, 211, 252, 0.8)',
                        'rgba(186, 230, 253, 0.8)',
                    ],
                    'borderColor' => [
                        'rgb(14, 165, 233)',
                        'rgb(56, 189, 248)',
                        'rgb(125, 211, 252)',
                        'rgb(186, 230, 253)',
                    ],
                    'borderWidth' => 2,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }

    public function getHeading(): ?string
    {
        return __('session_distribution');
    }
}
