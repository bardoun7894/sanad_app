<?php

namespace App\Filament\Widgets;

use App\Services\AnalyticsService;
use Filament\Widgets\ChartWidget;

class RevenueChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Revenue Trends';

    protected static ?int $sort = 5;

    protected int | string | array $columnSpan = [
        'md' => 2,
        'xl' => 2,
    ];

    protected function getData(): array
    {
        $analytics = app(AnalyticsService::class);
        $trends = $analytics->getRevenueTrends('monthly');

        $labels = array_map(fn($item) => $item['label'], $trends);
        $data = array_map(fn($item) => $item['amount'], $trends);

        return [
            'datasets' => [
                [
                    'label' => 'Revenue (SAR)',
                    'data' => $data,
                    'borderColor' => 'rgb(14, 165, 233)',
                    'backgroundColor' => 'rgba(14, 165, 233, 0.1)',
                    'fill' => true,
                    'tension' => 0.4,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }

    public function getHeading(): ?string
    {
        return __('revenue_trends');
    }
}
