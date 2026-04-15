<?php

namespace App\Filament\Resources\ChallengeResource\Pages;

use App\Filament\Resources\ChallengeResource;
use App\Models\DailyChallenge;
use Filament\Resources\Pages\Page;

class ListChallenges extends Page
{
    protected static string $resource = ChallengeResource::class;

    protected static string $view = 'filament.resources.challenge-resource.pages.list-challenges';

    public array $records = [];

    public string $search = '';

    public function getTitle(): string
    {
        return __('challenges');
    }

    public function getHeading(): string
    {
        return __('challenges');
    }

    public function mount(): void
    {
        $this->loadRecords();
    }

    public function loadRecords(): void
    {
        $all = DailyChallenge::all([], 'order', 'ASC');

        if ($this->search !== '') {
            $query = mb_strtolower($this->search);
            $all = array_filter($all, function (DailyChallenge $item) use ($query) {
                return str_contains(mb_strtolower($item->safeGet('title', '')), $query)
                    || str_contains(mb_strtolower($item->safeGet('title_en', '')), $query)
                    || str_contains(mb_strtolower($item->safeGet('type', '')), $query);
            });
            $all = array_values($all);
        }

        $this->records = $all;
    }

    public function updatedSearch(): void
    {
        $this->loadRecords();
    }

    public function deleteRecord(string $id): void
    {
        $record = DailyChallenge::find($id);
        if ($record) {
            $record->delete();
        }

        $this->loadRecords();
        $this->dispatch('notify', type: 'success', message: __('challenge_deleted'));
    }
}
