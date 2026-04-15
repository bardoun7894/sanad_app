<?php

namespace App\Filament\Widgets;

use App\Services\UserInsightsService;
use Filament\Widgets\Widget;

class HabitProgressWidget extends Widget
{
    protected static string $view = 'filament.widgets.habit-progress-widget';

    protected static ?int $sort = 14;

    protected int|string|array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];

    public function getData(): array
    {
        try {
            return app(UserInsightsService::class)->getChallengeAnalytics();
        } catch (\Exception $e) {
            return [
                'total_completions' => 0,
                'unique_users' => 0,
                'completion_rate' => 0,
            ];
        }
    }
}
