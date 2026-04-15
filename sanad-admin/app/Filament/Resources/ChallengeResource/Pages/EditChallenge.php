<?php

namespace App\Filament\Resources\ChallengeResource\Pages;

use App\Filament\Resources\ChallengeResource;
use App\Models\DailyChallenge;
use Filament\Resources\Pages\Page;

class EditChallenge extends Page
{
    protected static string $resource = ChallengeResource::class;

    protected static string $view = 'filament.resources.challenge-resource.pages.edit-challenge';

    // ─── Form State ──────────────────────────────────────────

    public string $recordId = '';

    public string $challengeTitle = '';

    public string $challengeTitleEn = '';

    public string $description = '';

    public string $description_en = '';

    public string $type = 'general';

    public int $duration_minutes = 10;

    public int $order = 0;

    public ?string $publish_date = null;

    public bool $is_active = true;

    public function getTitle(): string
    {
        return __('edit_challenge');
    }

    public function getHeading(): string
    {
        return __('edit_challenge');
    }

    public function mount(string|DailyChallenge $record): void
    {
        $model = $record instanceof DailyChallenge ? $record : DailyChallenge::find($record);

        if (! $model) {
            $this->redirect(ChallengeResource::getUrl('index'));

            return;
        }

        $this->recordId = $model->getKey();
        $this->challengeTitle = $model->safeGet('title', '');
        $this->challengeTitleEn = $model->safeGet('title_en', '');
        $this->description = $model->safeGet('description', '');
        $this->description_en = $model->safeGet('description_en', '');
        $this->type = $model->safeGet('type', 'general');
        $this->duration_minutes = (int) ($model->getAttribute('duration_minutes') ?? 10);
        $this->order = (int) ($model->getAttribute('order') ?? 0);
        $this->publish_date = $model->safeGet('publish_date', '');
        $this->is_active = (bool) $model->getAttribute('is_active');
    }

    // ─── Save Action ─────────────────────────────────────────

    public function save(): void
    {
        $this->validate([
            'challengeTitle' => 'required|string|max:200',
            'challengeTitleEn' => 'required|string|max:200',
            'description' => 'required|string|max:1000',
            'description_en' => 'required|string|max:1000',
            'type' => 'required|in:breathing,gratitude,mindfulness,exercise,journaling,social,selfCare,general',
            'duration_minutes' => 'required|integer|min:1|max:120',
            'order' => 'required|integer|min:0',
        ]);

        $model = DailyChallenge::find($this->recordId);
        if (! $model) {
            $this->dispatch('notify', type: 'danger', message: __('record_not_found'));

            return;
        }

        $model->fill([
            'title' => $this->challengeTitle,
            'title_en' => $this->challengeTitleEn,
            'description' => $this->description,
            'description_en' => $this->description_en,
            'type' => $this->type,
            'duration_minutes' => $this->duration_minutes,
            'order' => $this->order,
            'publish_date' => $this->publish_date,
            'is_active' => $this->is_active,
        ]);
        $model->save();

        $this->dispatch('notify', type: 'success', message: __('challenge_updated'));
        $this->redirect(ChallengeResource::getUrl('index'));
    }
}
