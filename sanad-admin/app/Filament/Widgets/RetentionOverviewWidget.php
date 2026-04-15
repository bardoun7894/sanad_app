<?php

namespace App\Filament\Widgets;

use App\Services\UserInsightsService;
use Filament\Widgets\Widget;

class RetentionOverviewWidget extends Widget
{
    protected static string $view = 'filament.widgets.retention-overview-widget';

    protected static ?int $sort = 12;

    protected int|string|array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];

    public function getData(): array
    {
        try {
            $insights = app(UserInsightsService::class);
            $atRisk = $insights->getAtRiskUsers(10);
            $distribution = $insights->getEngagementDistribution();

            return [
                'at_risk_count' => count($atRisk),
                'critical_count' => collect($atRisk)->where('risk_level', 'critical')->count(),
                'distribution' => $distribution,
                'top_risk' => array_slice($atRisk, 0, 3),
            ];
        } catch (\Exception $e) {
            return [
                'at_risk_count' => 0,
                'critical_count' => 0,
                'distribution' => ['0-20' => 0, '21-40' => 0, '41-60' => 0, '61-80' => 0, '81-100' => 0],
                'top_risk' => [],
            ];
        }
    }
}
