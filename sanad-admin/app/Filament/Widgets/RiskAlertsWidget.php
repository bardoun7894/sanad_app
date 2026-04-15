<?php

namespace App\Filament\Widgets;

use App\Services\RiskAlertService;
use Filament\Widgets\Widget;

class RiskAlertsWidget extends Widget
{
    protected static string $view = 'filament.widgets.risk-alerts-widget';

    protected static ?int $sort = 9;

    protected int|string|array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];

    public function getAlerts(): array
    {
        try {
            return app(RiskAlertService::class)->getRiskAlerts();
        } catch (\Exception $e) {
            return [];
        }
    }

    public function getRiskColor(string $level): string
    {
        return match ($level) {
            'critical' => 'text-red-400',
            'high' => 'text-orange-400',
            'moderate' => 'text-blue-400',
            default => 'text-green-400',
        };
    }

    public function getRiskBgColor(string $level): string
    {
        return match ($level) {
            'critical' => 'bg-red-500/10',
            'high' => 'bg-orange-500/10',
            'moderate' => 'bg-blue-500/10',
            default => 'bg-green-500/10',
        };
    }

    public function getRiskBadgeClasses(string $level): string
    {
        return match ($level) {
            'critical' => 'bg-red-500/20 text-red-400 border-red-500/30',
            'high' => 'bg-orange-500/20 text-orange-400 border-orange-500/30',
            'moderate' => 'bg-blue-500/20 text-blue-400 border-blue-500/30',
            default => 'bg-green-500/20 text-green-400 border-green-500/30',
        };
    }
}
