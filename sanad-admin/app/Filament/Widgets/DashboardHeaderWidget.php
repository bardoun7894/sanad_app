<?php

namespace App\Filament\Widgets;

use Filament\Widgets\Widget;

class DashboardHeaderWidget extends Widget
{
    protected static string $view = 'filament.widgets.dashboard-header-widget';

    protected static ?int $sort = 0;

    protected int | string | array $columnSpan = 'full';

    public function getViewData(): array
    {
        return [
            'user' => auth()->user(),
        ];
    }
}
