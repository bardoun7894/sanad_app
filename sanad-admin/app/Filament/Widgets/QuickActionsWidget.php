<?php

namespace App\Filament\Widgets;

use App\Filament\Resources\UserResource;
use App\Filament\Resources\BookingResource;
use App\Filament\Resources\TherapistResource;
use App\Filament\Resources\PaymentResource;
use Filament\Widgets\Widget;

class QuickActionsWidget extends Widget
{
    protected static string $view = 'filament.widgets.quick-actions-widget';

    protected static ?int $sort = 2;

    protected int|string|array $columnSpan = [
        'md' => 2,
        'xl' => 1,
    ];

    public function getActions(): array
    {
        return [
            [
                'label' => __('new_patient'),
                'icon' => 'heroicon-o-user-plus',
                'url' => UserResource::getUrl(),
                'color' => 'primary',
            ],
            [
                'label' => __('schedule_session'),
                'icon' => 'heroicon-o-calendar-days',
                'url' => BookingResource::getUrl(),
                'color' => 'success',
            ],
            [
                'label' => __('add_clinician'),
                'icon' => 'heroicon-o-academic-cap',
                'url' => TherapistResource::getUrl(),
                'color' => 'info',
            ],
            [
                'label' => __('create_invoice'),
                'icon' => 'heroicon-o-document-text',
                'url' => PaymentResource::getUrl(),
                'color' => 'warning',
            ],
        ];
    }
}
