<?php

namespace App\Filament\Resources\TherapistResource\Pages;

use App\Filament\Resources\TherapistResource;
use App\Models\TherapistProfile;
use Filament\Resources\Pages\Page;

class ViewTherapist extends Page
{
    protected static string $resource = TherapistResource::class;

    protected static string $view = 'filament.resources.therapist-resource.pages.view-therapist';

    public ?TherapistProfile $record = null;

    public function getTitle(): string
    {
        return $this->record?->safeGet('name', __('clinician')) ?? __('clinician');
    }

    public function getHeading(): string
    {
        return $this->record?->safeGet('name', __('clinician')) ?? __('clinician');
    }

    public function getSubheading(): ?string
    {
        return $this->record?->safeGet('title', '');
    }

    public function mount(string|TherapistProfile $record): void
    {
        $this->record = $record instanceof TherapistProfile ? $record : TherapistProfile::find($record);

        if ($this->record === null) {
            abort(404);
        }
    }

    public function getBreadcrumbs(): array
    {
        return [
            route('filament.admin.resources.clinicians.index') => __('clinicians'),
            '#' => $this->record?->safeGet('name', __('clinician')),
        ];
    }
}
