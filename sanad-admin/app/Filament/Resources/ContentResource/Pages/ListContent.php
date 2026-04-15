<?php

namespace App\Filament\Resources\ContentResource\Pages;

use App\Filament\Resources\ContentResource;
use App\Models\AppContent;
use Filament\Resources\Pages\Page;

class ListContent extends Page
{
    protected static string $resource = ContentResource::class;

    protected static string $view = 'filament.resources.content-resource.pages.list-content';

    public array $records = [];

    public string $search = '';

    public function getTitle(): string
    {
        return __('content');
    }

    public function getHeading(): string
    {
        return __('content');
    }

    public function mount(): void
    {
        $this->loadRecords();
    }

    public function loadRecords(): void
    {
        $all = AppContent::all([], 'created_at', 'DESC');

        if ($this->search !== '') {
            $query = mb_strtolower($this->search);
            $all = array_filter($all, function (AppContent $item) use ($query) {
                return str_contains(mb_strtolower($item->safeGet('title', '')), $query)
                    || str_contains(mb_strtolower($item->safeGet('category', '')), $query);
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
        $record = AppContent::find($id);
        if ($record) {
            $record->delete();
        }

        $this->loadRecords();
        $this->dispatch('notify', type: 'success', message: __('content_deleted'));
    }
}
