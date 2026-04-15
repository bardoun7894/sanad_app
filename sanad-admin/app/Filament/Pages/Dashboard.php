<?php

namespace App\Filament\Pages;

use App\Filament\Widgets\AiAssistantWidget;
use App\Filament\Widgets\CommunityHealthWidget;
use App\Filament\Widgets\DashboardHeaderWidget;
use App\Filament\Widgets\HabitProgressWidget;
use App\Filament\Widgets\KpiStatsWidget;
use App\Filament\Widgets\QuickActionsWidget;
use App\Filament\Widgets\RecentActivityWidget;
use App\Filament\Widgets\RetentionOverviewWidget;
use App\Filament\Widgets\RevenueChartWidget;
use App\Filament\Widgets\RiskAlertsWidget;
use App\Filament\Widgets\SessionDistributionChartWidget;
use App\Filament\Widgets\SessionsChartWidget;
use App\Filament\Widgets\TopTherapistsWidget;
use App\Filament\Widgets\WeeklyAgendaWidget;
use Filament\Pages\Dashboard as BaseDashboard;

class Dashboard extends BaseDashboard
{
    protected static ?string $navigationIcon = 'heroicon-o-home';

    protected static ?int $navigationSort = 1;

    protected static string $routePath = '/';

    protected static bool $shouldRegisterNavigation = true;

    public function getTitle(): string
    {
        return __('dashboard');
    }

    public static function getNavigationLabel(): string
    {
        return __('dashboard');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('main');
    }

    public function getWidgets(): array
    {
        return [
            DashboardHeaderWidget::class,
            KpiStatsWidget::class,
            QuickActionsWidget::class,
            RevenueChartWidget::class,
            SessionsChartWidget::class,
            SessionDistributionChartWidget::class,
            WeeklyAgendaWidget::class,
            RiskAlertsWidget::class,
            RecentActivityWidget::class,
            TopTherapistsWidget::class,
            RetentionOverviewWidget::class,
            CommunityHealthWidget::class,
            HabitProgressWidget::class,
            AiAssistantWidget::class,
        ];
    }

    public function getColumns(): int|string|array
    {
        return [
            'default' => 1,
            'md' => 2,
            'xl' => 3,
        ];
    }

    public function getHeaderWidgets(): array
    {
        return [];
    }

    public function getFooterWidgets(): array
    {
        return [];
    }
}
