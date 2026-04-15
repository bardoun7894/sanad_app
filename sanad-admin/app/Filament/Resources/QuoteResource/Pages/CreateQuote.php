<?php

namespace App\Filament\Resources\QuoteResource\Pages;

use App\Filament\Resources\QuoteResource;
use App\Models\DailyQuote;
use Filament\Resources\Pages\Page;

class CreateQuote extends Page
{
    protected static string $resource = QuoteResource::class;

    protected static string $view = 'filament.resources.quote-resource.pages.create-quote';

    // ─── Form State ──────────────────────────────────────────

    public string $text = '';

    public string $author = '';

    public string $category = '';

    public ?string $publish_date = null;

    public bool $is_active = true;

    public function getTitle(): string
    {
        return __('create_quote');
    }

    public function getHeading(): string
    {
        return __('create_quote');
    }

    // ─── Save Action ─────────────────────────────────────────

    public function save(): void
    {
        $this->validate([
            'text' => 'required|string|max:500',
            'category' => 'required|string|max:255',
        ]);

        DailyQuote::create([
            'text' => $this->text,
            'author' => $this->author,
            'category' => $this->category,
            'publish_date' => $this->publish_date,
            'is_active' => $this->is_active,
        ]);

        $this->dispatch('notify', type: 'success', message: __('quote_created'));
        $this->redirect(QuoteResource::getUrl('index'));
    }
}
