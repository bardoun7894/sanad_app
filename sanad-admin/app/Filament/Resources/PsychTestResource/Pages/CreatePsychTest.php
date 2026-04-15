<?php

namespace App\Filament\Resources\PsychTestResource\Pages;

use App\Filament\Resources\PsychTestResource;
use App\Models\PsychologicalTest;
use Filament\Resources\Pages\Page;

class CreatePsychTest extends Page
{
    protected static string $resource = PsychTestResource::class;
    protected static string $view = 'filament.resources.psych-test-resource.pages.create-psych-test';

    public string $title_ar = '';
    public string $title_en = '';
    public string $description_ar = '';
    public string $description_en = '';
    public string $type = 'general';
    public int $duration_minutes = 5;
    public bool $is_active = true;
    public array $questions = [];
    public array $scoring_ranges = [];

    public function getTitle(): string
    {
        return __('create_psychological_test');
    }

    public function getHeading(): string
    {
        return __('create_psychological_test');
    }

    public function addQuestion(): void
    {
        $this->questions[] = [
            'text' => '',
            'text_en' => '',
            'options' => [
                ['text' => '', 'text_en' => '', 'score' => 0],
            ],
        ];
    }

    public function removeQuestion(int $index): void
    {
        unset($this->questions[$index]);
        $this->questions = array_values($this->questions);
    }

    public function addOption(int $questionIndex): void
    {
        $this->questions[$questionIndex]['options'][] = [
            'text' => '',
            'text_en' => '',
            'score' => 0,
        ];
    }

    public function removeOption(int $questionIndex, int $optionIndex): void
    {
        unset($this->questions[$questionIndex]['options'][$optionIndex]);
        $this->questions[$questionIndex]['options'] = array_values($this->questions[$questionIndex]['options']);
    }

    public function addScoringRange(): void
    {
        $this->scoring_ranges[] = [
            'min' => 0,
            'max' => 0,
            'level' => '',
            'text' => '',
            'text_en' => '',
        ];
    }

    public function removeScoringRange(int $index): void
    {
        unset($this->scoring_ranges[$index]);
        $this->scoring_ranges = array_values($this->scoring_ranges);
    }

    public function save(): void
    {
        $this->validate([
            'title_ar' => 'required|string|max:255',
            'title_en' => 'required|string|max:255',
            'type' => 'required|string',
            'duration_minutes' => 'required|integer|min:1',
        ]);

        if (empty($this->questions)) {
            $this->addError('questions', __('at_least_one_question'));
            return;
        }

        PsychologicalTest::create([
            'title' => $this->title_ar,
            'title_en' => $this->title_en,
            'description' => $this->description_ar,
            'description_en' => $this->description_en,
            'type' => $this->type,
            'duration_minutes' => $this->duration_minutes,
            'is_active' => $this->is_active,
            'questions' => $this->questions,
            'scoring' => ['ranges' => $this->scoring_ranges],
        ]);

        $this->dispatch('notify', type: 'success', message: __('test_created'));
        $this->redirect(PsychTestResource::getUrl('index'));
    }
}
