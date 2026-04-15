<?php

namespace App\Filament\Pages;

use App\Models\User;
use App\Services\ActivityLogService;
use App\Services\ChatService;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class ChatSupport extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-right';

    protected static ?int $navigationSort = 5;

    protected static string $view = 'filament.pages.chat-support';

    public function getTitle(): string
    {
        return __('chat_support');
    }

    public static function getNavigationLabel(): string
    {
        return __('chat_support');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('communication');
    }

    public static function getNavigationBadge(): ?string
    {
        try {
            $chatService = app(ChatService::class);
            $unread = $chatService->getTotalUnreadCount();

            return $unread > 0 ? (string) $unread : null;
        } catch (\Exception $e) {
            return null;
        }
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('newChat')
                ->label(__('new_chat'))
                ->icon('heroicon-o-plus-circle')
                ->color('primary')
                ->form([
                    TextInput::make('user_email')
                        ->label(__('user_email'))
                        ->email()
                        ->required()
                        ->placeholder(__('enter_user_email')),
                ])
                ->action(function (array $data): void {
                    $email = $data['user_email'];

                    // Attempt to find user by email
                    $firestore = app(\App\Services\FirestoreService::class);
                    $users = $firestore->queryCollection('users', [
                        ['email', '=', $email],
                    ], null, 'DESC', 1);

                    if (empty($users)) {
                        Notification::make()
                            ->title(__('user_not_found'))
                            ->body(__('no_user_with_email', ['email' => $email]))
                            ->danger()
                            ->send();

                        return;
                    }

                    $user = $users[0];
                    $userId = $user['id'] ?? '';
                    $userName = $user['display_name'] ?? $user['name'] ?? $email;
                    $userEmail = $user['email'] ?? $email;

                    $chatService = app(ChatService::class);
                    $chatService->createThread($userId, $userName, $userEmail);

                    app(ActivityLogService::class)->log(
                        'chatThreadCreated',
                        __('chat_thread_created_for', ['user' => $userName]),
                        ['user_id' => $userId, 'user_email' => $userEmail],
                    );

                    Notification::make()
                        ->title(__('chat_created'))
                        ->body(__('chat_thread_created_for', ['user' => $userName]))
                        ->success()
                        ->send();

                    $this->dispatch('$refresh');
                }),

            Action::make('broadcastAll')
                ->label(__('broadcast_all'))
                ->icon('heroicon-o-megaphone')
                ->color('warning')
                ->requiresConfirmation()
                ->modalHeading(__('broadcast_message'))
                ->modalDescription(__('broadcast_message_warning'))
                ->modalSubmitActionLabel(__('send_broadcast'))
                ->form([
                    Textarea::make('message')
                        ->label(__('message'))
                        ->required()
                        ->rows(4)
                        ->placeholder(__('type_broadcast_message')),
                ])
                ->action(function (array $data): void {
                    $chatService = app(ChatService::class);
                    $count = $chatService->broadcastMessage($data['message']);

                    app(ActivityLogService::class)->log(
                        'chatBroadcast',
                        __('broadcast_sent_to_count', ['count' => $count]),
                        ['message_preview' => mb_substr($data['message'], 0, 100)],
                    );

                    Notification::make()
                        ->title(__('broadcast_sent'))
                        ->body(__('broadcast_sent_to_count', ['count' => $count]))
                        ->success()
                        ->send();

                    $this->dispatch('$refresh');
                }),
        ];
    }
}
