<?php

namespace App\Models;

class PsychologicalTest extends FirestoreModel
{
    protected function getCollectionName(): string
    {
        return 'psychological_tests';
    }

    protected array $fillable = [
        'title',
        'title_en',
        'description',
        'description_en',
        'type',
        'duration_minutes',
        'is_active',
        'questions',
        'scoring',
    ];

    protected array $casts = [
        'title' => 'string',
        'title_en' => 'string',
        'description' => 'string',
        'description_en' => 'string',
        'type' => 'string',
        'duration_minutes' => 'integer',
        'is_active' => 'boolean',
        'questions' => 'array',
        'scoring' => 'array',
    ];

    public function __construct(array $attributes = [])
    {
        $defaults = [
            'type' => 'general',
            'duration_minutes' => 5,
            'is_active' => true,
            'questions' => [],
            'scoring' => ['ranges' => []],
        ];

        parent::__construct(array_merge($defaults, $attributes));
    }

    public function getTypeColor(): string
    {
        return match ($this->type) {
            'depression' => 'danger',
            'anxiety' => 'warning',
            'stress' => 'info',
            default => 'gray',
        };
    }
}
