<?php

namespace App\Filament\Resources\BookingResource\Pages;

use App\Filament\Resources\BookingResource;
use App\Models\Booking;
use App\Models\TherapistProfile;
use Filament\Resources\Pages\Page;

class ViewBooking extends Page
{
    protected static string $resource = BookingResource::class;

    protected static string $view = 'filament.resources.booking-resource.pages.view-booking';

    public ?Booking $record = null;

    public ?string $therapistName = null;

    public function getTitle(): string
    {
        $client = $this->record?->safeGet('client_name', __('appointment'));

        return __('appointment').' - '.$client;
    }

    public function getHeading(): string
    {
        return __('appointment_details');
    }

    public function mount(string|Booking $record): void
    {
        $this->record = $record instanceof Booking ? $record : Booking::find($record);

        if ($this->record === null) {
            abort(404);
        }

        // Resolve therapist name
        $therapistId = $this->record->getAttribute('therapist_id');
        if ($therapistId) {
            $therapist = TherapistProfile::find($therapistId);
            $this->therapistName = $therapist?->safeGet('name', __('unknown'));
        }
    }

    public function getBreadcrumbs(): array
    {
        return [
            route('filament.admin.resources.appointments.index') => __('appointments'),
            '#' => $this->record?->safeGet('client_name', __('appointment')),
        ];
    }
}
