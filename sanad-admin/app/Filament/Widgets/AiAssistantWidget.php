<?php

namespace App\Filament\Widgets;

use Filament\Widgets\Widget;

class AiAssistantWidget extends Widget
{
    protected static string $view = 'filament.widgets.ai-assistant-widget';

    protected static ?int $sort = 11;

    protected int|string|array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];
}
