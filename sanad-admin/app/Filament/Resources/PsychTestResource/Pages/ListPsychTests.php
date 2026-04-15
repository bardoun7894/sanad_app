<?php

namespace App\Filament\Resources\PsychTestResource\Pages;

use App\Filament\Resources\PsychTestResource;
use App\Models\PsychologicalTest;
use Filament\Resources\Pages\Page;

class ListPsychTests extends Page
{
    protected static string $resource = PsychTestResource::class;
    protected static string $view = 'filament.resources.psych-test-resource.pages.list-psych-tests';

    public array $records = [];

    public function getTitle(): string
    {
        return __('psychological_tests');
    }

    public function getHeading(): string
    {
        return __('psychological_tests');
    }

    public function mount(): void
    {
        $this->loadRecords();
    }

    public function loadRecords(): void
    {
        $this->records = PsychologicalTest::all();
    }

    public function toggleActive(string $id): void
    {
        $record = PsychologicalTest::find($id);
        if ($record) {
            $record->fill(['is_active' => !$record->getAttribute('is_active')]);
            $record->save();
        }
        $this->loadRecords();
    }

    public function deleteRecord(string $id): void
    {
        $record = PsychologicalTest::find($id);
        if ($record) {
            $record->delete();
        }
        $this->loadRecords();
        $this->dispatch('notify', type: 'success', message: __('record_deleted'));
    }
}
