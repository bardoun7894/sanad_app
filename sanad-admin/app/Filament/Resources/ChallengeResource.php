<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ChallengeResource\Pages;
use Filament\Resources\Resource;

class ChallengeResource extends Resource
{
    protected static ?string $model = null; // We don't use Eloquent

    protected static ?string $navigationIcon = 'heroicon-o-trophy';

    protected static ?int $navigationSort = 12;

    protected static ?string $slug = 'challenges';

    public static function getNavigationLabel(): string
    {
        return __('challenges');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    public static function getModelLabel(): string
    {
        return __('challenge');
    }

    public static function getPluralModelLabel(): string
    {
        return __('challenges');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListChallenges::route('/'),
            'create' => Pages\CreateChallenge::route('/create'),
            'edit' => Pages\EditChallenge::route('/{record}/edit'),
        ];
    }
}
