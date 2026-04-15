<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PaymentResource\Pages;
use Filament\Resources\Resource;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class PaymentResource extends Resource
{
    protected static ?string $model = null; // We don't use Eloquent

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';

    protected static ?int $navigationSort = 8;

    protected static ?string $slug = 'billing';

    public static function getNavigationLabel(): string
    {
        return __('billing');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    public static function getModelLabel(): string
    {
        return __('payment');
    }

    public static function getPluralModelLabel(): string
    {
        return __('billing');
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('user_email')
                    ->label(__('email'))
                    ->searchable(),
                TextColumn::make('amount')
                    ->label(__('amount'))
                    ->formatStateUsing(function ($record) {
                        $currency = $record->safeGet('currency', 'SAR');
                        $amount = $record->getAttribute('amount') ?? 0;

                        return $currency.' '.number_format((float) $amount, 2);
                    }),
                TextColumn::make('status')
                    ->label(__('status'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'completed' => 'success',
                        'pending' => 'warning',
                        'failed' => 'danger',
                        'refunded' => 'info',
                        default => 'gray',
                    }),
                TextColumn::make('payment_method')
                    ->label(__('payment_method')),
                TextColumn::make('created_at')
                    ->label(__('created_at'))
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('gateway_transaction_id')
                    ->label(__('transaction_id'))
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPayments::route('/'),
        ];
    }
}
