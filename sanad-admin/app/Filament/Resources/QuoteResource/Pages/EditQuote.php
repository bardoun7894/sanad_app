<?php

namespace App\Filament\Resources\QuoteResource\Pages;

use App\Filament\Resources\QuoteResource;
use App\Models\DailyQuote;
use Filament\Resources\Pages\Page;

class EditQuote extends Page
{
    protected static string $resource = QuoteResource::class;

    protected static string $view = 'filament.resources.quote-resource.pages.edit-quote';

    // ─── Form State ──────────────────────────────────────────

    public string $recordId = '';

    public string $text = '';

    public string $author = '';

    public string $category = '';

    public ?string $publish_date = null;

    public bool $is_active = true;

    public function getTitle(): string
    {
        return __('edit_quote');
    }

    public function getHeading(): string
    {
        return __('edit_quote');
    }

    public function mount(string|DailyQuote $record): void
    {
        $model = $record instanceof DailyQuote ? $record : DailyQuote::find($record);

        if (! $model) {
            $this->redirect(QuoteResource::getUrl('index'));

            return;
        }

        $this->recordId = $model->getKey();
        $this->text = $model->safeGet('text', '');
        $this->author = $model->safeGet('author', '');
        $this->category = $model->safeGet('category', '');
        $this->publish_date = $model->safeGet('publish_date', '');
        $this->is_active = (bool) $model->getAttribute('is_active');
    }

    // ─── Save Action ─────────────────────────────────────────

    public function save(): void
    {
        $this->validate([
            'text' => 'required|string|max:500',
            'category' => 'required|string|max:255',
        ]);

        $model = DailyQuote::find($this->recordId);
        if (! $model) {
            $this->dispatch('notify', type: 'danger', message: __('record_not_found'));

            return;
        }

        $model->fill([
            'text' => $this->text,
            'author' => $this->author,
            'category' => $this->category,
            'publish_date' => $this->publish_date,
            'is_active' => $this->is_active,
        ]);
        $model->save();

        $this->dispatch('notify', type: 'success', message: __('quote_updated'));
        $this->redirect(QuoteResource::getUrl('index'));
    }
}
