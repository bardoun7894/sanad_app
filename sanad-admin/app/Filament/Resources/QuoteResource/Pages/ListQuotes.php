<?php

namespace App\Filament\Resources\QuoteResource\Pages;

use App\Filament\Resources\QuoteResource;
use App\Models\DailyQuote;
use Filament\Resources\Pages\Page;

class ListQuotes extends Page
{
    protected static string $resource = QuoteResource::class;

    protected static string $view = 'filament.resources.quote-resource.pages.list-quotes';

    public array $records = [];

    public string $search = '';

    public function getTitle(): string
    {
        return __('quotes');
    }

    public function getHeading(): string
    {
        return __('quotes');
    }

    public function mount(): void
    {
        $this->loadRecords();
    }

    public function loadRecords(): void
    {
        $all = DailyQuote::all([], 'publish_date', 'DESC');

        if ($this->search !== '') {
            $query = mb_strtolower($this->search);
            $all = array_filter($all, function (DailyQuote $item) use ($query) {
                return str_contains(mb_strtolower($item->safeGet('text', '')), $query)
                    || str_contains(mb_strtolower($item->safeGet('author', '')), $query)
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
        $record = DailyQuote::find($id);
        if ($record) {
            $record->delete();
        }

        $this->loadRecords();
        $this->dispatch('notify', type: 'success', message: __('quote_deleted'));
    }
}
