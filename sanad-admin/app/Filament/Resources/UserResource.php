<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class UserResource extends Resource
{
    protected static ?string $model = null; // We don't use Eloquent

    protected static ?string $navigationIcon = 'heroicon-o-users';

    protected static ?int $navigationSort = 2;

    protected static ?string $slug = 'users';

    public static function getNavigationLabel(): string
    {
        return __('users');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('main');
    }

    public static function getModelLabel(): string
    {
        return __('user');
    }

    public static function getPluralModelLabel(): string
    {
        return __('users');
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make(__('user_information'))
                ->schema([
                    Forms\Components\TextInput::make('display_name')
                        ->label(__('name'))
                        ->disabled(),
                    Forms\Components\TextInput::make('email')
                        ->label(__('email'))
                        ->disabled(),
                    Forms\Components\Select::make('role')
                        ->label(__('role'))
                        ->options([
                            'user' => __('user'),
                            'therapist' => __('therapist'),
                            'admin' => __('admin'),
                        ]),
                    Forms\Components\Select::make('subscription_status')
                        ->label(__('subscription_status'))
                        ->options([
                            'free' => __('free'),
                            'active' => __('active'),
                            'cancelled' => __('cancelled'),
                            'expired' => __('expired'),
                            'pending' => __('pending'),
                        ]),
                ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('display_name')
                    ->label(__('name'))
                    ->searchable()
                    ->sortable()
                    ->getStateUsing(fn ($record) => $record->safeGet('display_name', $record->safeGet('name', $record->safeGet('email')))),
                TextColumn::make('email')
                    ->label(__('email'))
                    ->searchable(),
                TextColumn::make('role')
                    ->label(__('role'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'admin' => 'danger',
                        'therapist' => 'warning',
                        default => 'gray',
                    }),
                TextColumn::make('subscription_status')
                    ->label(__('subscription_status'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'active' => 'success',
                        'expired' => 'danger',
                        'pending' => 'warning',
                        'cancelled' => 'gray',
                        default => 'gray',
                    }),
                IconColumn::make('is_premium')
                    ->label(__('premium'))
                    ->boolean(),
                TextColumn::make('created_at')
                    ->label(__('created_at'))
                    ->dateTime()
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'view' => Pages\ViewUser::route('/{record}'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
