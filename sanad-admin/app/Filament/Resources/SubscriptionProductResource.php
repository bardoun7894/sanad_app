<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SubscriptionProductResource\Pages;
use Filament\Resources\Resource;

class SubscriptionProductResource extends Resource
{
    protected static ?string $model = null;
    protected static ?string $navigationIcon = 'heroicon-o-credit-card';
    protected static ?int $navigationSort = 14;
    protected static ?string $slug = 'subscription-products';

    public static function getNavigationLabel(): string
    {
        return __('subscription_products');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    public static function getModelLabel(): string
    {
        return __('subscription_product');
    }

    public static function getPluralModelLabel(): string
    {
        return __('subscription_products');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSubscriptionProducts::route('/'),
            'create' => Pages\CreateSubscriptionProduct::route('/create'),
            'edit' => Pages\EditSubscriptionProduct::route('/{record}/edit'),
        ];
    }
}
