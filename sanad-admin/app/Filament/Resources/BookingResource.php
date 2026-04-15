<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BookingResource\Pages;
use Filament\Resources\Resource;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class BookingResource extends Resource
{
    protected static ?string $model = null;

    protected static ?string $navigationIcon = 'heroicon-o-calendar';

    protected static ?int $navigationSort = 4;

    protected static ?string $slug = 'appointments';

    public static function getNavigationLabel(): string
    {
        return __('appointments');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('main');
    }

    public static function getModelLabel(): string
    {
        return __('appointment');
    }

    public static function getPluralModelLabel(): string
    {
        return __('appointments');
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('client_name')
                    ->label(__('client'))
                    ->searchable()
                    ->getStateUsing(fn ($record) => $record->safeGet('client_name')),

                TextColumn::make('scheduled_time')
                    ->label(__('date_time'))
                    ->dateTime()
                    ->sortable()
                    ->getStateUsing(fn ($record) => $record->getAttribute('scheduled_time')),

                TextColumn::make('duration_minutes')
                    ->label(__('duration'))
                    ->suffix(' min')
                    ->getStateUsing(fn ($record) => $record->safeGet('duration_minutes', '60')),

                TextColumn::make('session_type')
                    ->label(__('session_type'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'video' => 'primary',
                        'audio' => 'success',
                        'chat' => 'info',
                        'in_person' => 'warning',
                        default => 'gray',
                    })
                    ->getStateUsing(fn ($record) => $record->safeGet('session_type')),

                TextColumn::make('status')
                    ->label(__('status'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'completed' => 'success',
                        'confirmed' => 'primary',
                        'pending' => 'warning',
                        'cancelled' => 'danger',
                        'rejected' => 'danger',
                        'no_show' => 'gray',
                        default => 'gray',
                    })
                    ->getStateUsing(fn ($record) => $record->safeGet('status')),

                TextColumn::make('amount')
                    ->label(__('amount'))
                    ->getStateUsing(fn ($record) => $record->safeGet('currency', 'SAR').' '.$record->safeGet('amount', '0')),
            ])
            ->defaultSort('scheduled_time', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListBookings::route('/'),
            'view' => Pages\ViewBooking::route('/{record}'),
        ];
    }
}
