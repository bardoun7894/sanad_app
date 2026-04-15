<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PsychTestResource\Pages;
use Filament\Resources\Resource;

class PsychTestResource extends Resource
{
    protected static ?string $model = null;
    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-check';
    protected static ?int $navigationSort = 13;
    protected static ?string $slug = 'psych-tests';

    public static function getNavigationLabel(): string
    {
        return __('psychological_tests');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    public static function getModelLabel(): string
    {
        return __('psychological_test');
    }

    public static function getPluralModelLabel(): string
    {
        return __('psychological_tests');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPsychTests::route('/'),
            'create' => Pages\CreatePsychTest::route('/create'),
            'edit' => Pages\EditPsychTest::route('/{record}/edit'),
        ];
    }
}
