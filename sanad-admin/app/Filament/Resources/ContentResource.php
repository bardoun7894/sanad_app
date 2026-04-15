<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ContentResource\Pages;
use Filament\Resources\Resource;

class ContentResource extends Resource
{
    protected static ?string $model = null; // We don't use Eloquent

    protected static ?string $navigationIcon = 'heroicon-o-document-text';

    protected static ?int $navigationSort = 10;

    protected static ?string $slug = 'content';

    public static function getNavigationLabel(): string
    {
        return __('content');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    public static function getModelLabel(): string
    {
        return __('content');
    }

    public static function getPluralModelLabel(): string
    {
        return __('content');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListContent::route('/'),
            'create' => Pages\CreateContent::route('/create'),
            'edit' => Pages\EditContent::route('/{record}/edit'),
        ];
    }
}
