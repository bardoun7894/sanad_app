<?php

namespace App\Filament\Resources;

use App\Filament\Resources\QuoteResource\Pages;
use Filament\Resources\Resource;

class QuoteResource extends Resource
{
    protected static ?string $model = null; // We don't use Eloquent

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-bottom-center-text';

    protected static ?int $navigationSort = 11;

    protected static ?string $slug = 'quotes';

    public static function getNavigationLabel(): string
    {
        return __('quotes');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    public static function getModelLabel(): string
    {
        return __('quote');
    }

    public static function getPluralModelLabel(): string
    {
        return __('quotes');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListQuotes::route('/'),
            'create' => Pages\CreateQuote::route('/create'),
            'edit' => Pages\EditQuote::route('/{record}/edit'),
        ];
    }
}
