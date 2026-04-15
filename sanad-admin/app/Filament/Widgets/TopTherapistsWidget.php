<?php

namespace App\Filament\Widgets;

use App\Services\AnalyticsService;
use Filament\Widgets\Widget;

class TopTherapistsWidget extends Widget
{
    protected static ?int $sort = 3;

    protected int | string | array $columnSpan = 'full';

    protected static string $view = 'filament.widgets.top-therapists-widget';

    public function getTherapists(): array
    {
        $analytics = app(AnalyticsService::class);
        $performance = $analytics->getClinicianPerformance();

        // Return top 5 therapists
        return array_slice($performance, 0, 5);
    }
}
