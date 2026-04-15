<?php

namespace App\Filament\Widgets;

use App\Services\AnalyticsService;
use Filament\Widgets\Widget;

class KpiStatsWidget extends Widget
{
    protected static string $view = 'filament.widgets.kpi-stats-widget';

    protected static ?int $sort = 1;

    protected int | string | array $columnSpan = 'full';

    public function getCachedStats(): array
    {
        try {
            $analytics = app(AnalyticsService::class);

            $activeUsers = $analytics->countActiveUsers();
            $criticalFlags = $analytics->countCriticalFlags();
            $todaySessions = $analytics->countTodaySessions();
            $earnings = $analytics->calculateEarnings();

            return [
                $this->formatStat(
                    label: __('active_users'),
                    value: number_format($activeUsers['count']),
                    trend: $activeUsers['trend'],
                    icon: 'heroicon-o-users',
                    color: 'primary',
                ),
                $this->formatStat(
                    label: __('critical_flags'),
                    value: number_format($criticalFlags['count']),
                    trend: $criticalFlags['trend'],
                    icon: 'heroicon-o-flag',
                    color: 'danger',
                ),
                $this->formatStat(
                    label: __('todays_sessions'),
                    value: number_format($todaySessions['count']),
                    trend: $todaySessions['trend'],
                    icon: 'heroicon-o-calendar',
                    color: 'success',
                ),
                $this->formatStat(
                    label: __('earnings'),
                    value: $earnings['currency'].' '.number_format($earnings['amount'], 2),
                    trend: $earnings['trend'],
                    icon: 'heroicon-o-currency-dollar',
                    color: 'warning',
                ),
            ];
        } catch (\Exception $e) {
            return [];
        }
    }

    private function formatStat(
        string $label,
        string $value,
        float $trend,
        string $icon,
        string $color,
    ): array {
        $isPositive = $trend >= 0;
        $trendText = ($isPositive ? '+' : '').round($trend, 1).'% '.__('from_last_month');
        $trendIcon = $isPositive
            ? 'heroicon-m-arrow-trending-up'
            : 'heroicon-m-arrow-trending-down';
        $trendColor = $isPositive ? 'success' : 'danger';

        return [
            'label' => $label,
            'value' => $value,
            'description' => $trendText,
            'descriptionIcon' => $trendIcon,
            'descriptionColor' => $trendColor, // 'success' or 'danger'
            'color' => $color,
            'icon' => $icon,
            'chart' => $this->generateSparkline($trend),
        ];
    }

    /**
     * Generate a sparkline chart array based on the trend direction.
     *
     * @param  float  $trend
     * @return array<int>
     */
    private function generateSparkline(float $trend): array
    {
        $points = [];
        $current = 10; // Base value
        $isPositive = $trend >= 0;

        for ($i = 0; $i < 7; $i++) {
            $points[] = $current;
            // Add randomness but bias towards the trend
            $change = rand(1, 4);
            if ($isPositive) {
                $current += (rand(0, 10) > 3) ? $change : -$change;
            } else {
                $current -= (rand(0, 10) > 3) ? $change : -$change;
            }
            // Ensure positive values
            $current = max(1, $current);
        }

        return $points;
    }
}
