<?php

namespace App\Filament\Resources\ChallengeResource\Pages;

use App\Filament\Resources\ChallengeResource;
use App\Models\DailyChallenge;
use Filament\Resources\Pages\Page;

class CreateChallenge extends Page
{
    protected static string $resource = ChallengeResource::class;

    protected static string $view = 'filament.resources.challenge-resource.pages.create-challenge';

    // ─── Form State ──────────────────────────────────────────

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
        return __('create_challenge');
    }

    public function getHeading(): string
    {
        return __('create_challenge');
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

        DailyChallenge::create([
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

        $this->dispatch('notify', type: 'success', message: __('challenge_created'));
        $this->redirect(ChallengeResource::getUrl('index'));
    }
}
