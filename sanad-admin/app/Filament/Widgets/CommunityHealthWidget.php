<?php

namespace App\Filament\Widgets;

use App\Services\UserInsightsService;
use Filament\Widgets\Widget;

class CommunityHealthWidget extends Widget
{
    protected static string $view = 'filament.widgets.community-health-widget';

    protected static ?int $sort = 13;

    protected int|string|array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];

    public function getData(): array
    {
        try {
            return app(UserInsightsService::class)->getCommunityAnalytics();
        } catch (\Exception $e) {
            return [
                'total_posts_30d' => 0,
                'posts_per_day' => 0,
                'active_contributors' => 0,
                'total_reactions' => 0,
                'avg_reactions' => 0,
            ];
        }
    }
}
