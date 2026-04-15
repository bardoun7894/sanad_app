<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TherapistResource\Pages;
use Filament\Resources\Resource;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class TherapistResource extends Resource
{
    protected static ?string $model = null;

    protected static ?string $navigationIcon = 'heroicon-o-academic-cap';

    protected static ?int $navigationSort = 3;

    protected static ?string $slug = 'clinicians';

    public static function getNavigationLabel(): string
    {
        return __('clinicians');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('main');
    }

    public static function getModelLabel(): string
    {
        return __('clinician');
    }

    public static function getPluralModelLabel(): string
    {
        return __('clinicians');
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label(__('name'))
                    ->searchable()
                    ->getStateUsing(fn ($record) => $record->safeGet('name')),

                TextColumn::make('title')
                    ->label(__('title'))
                    ->getStateUsing(fn ($record) => $record->safeGet('title', '-')),

                TextColumn::make('specialties')
                    ->label(__('specialties'))
                    ->badge()
                    ->getStateUsing(fn ($record) => $record->getAttribute('specialties') ?? [])
                    ->separator(','),

                TextColumn::make('rating')
                    ->label(__('rating'))
                    ->getStateUsing(fn ($record) => number_format($record->getAttribute('rating') ?? 0, 1)),

                TextColumn::make('session_price')
                    ->label(__('price'))
                    ->getStateUsing(fn ($record) => $record->safeGet('currency', 'SAR').' '.$record->safeGet('session_price', '0')),

                TextColumn::make('approval_status')
                    ->label(__('status'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'approved' => 'success',
                        'pending' => 'warning',
                        'rejected' => 'danger',
                        'suspended' => 'gray',
                        default => 'gray',
                    })
                    ->getStateUsing(fn ($record) => $record->safeGet('approval_status', 'pending')),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListTherapists::route('/'),
            'view' => Pages\ViewTherapist::route('/{record}'),
        ];
    }
}
