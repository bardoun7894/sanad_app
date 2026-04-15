<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use App\Models\User;
use App\Services\ActivityLogService;
use App\Services\FirestoreService;
use Filament\Actions;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\Page;
use Illuminate\Support\Facades\Auth;

class EditUser extends Page
{
    protected static string $resource = UserResource::class;

    protected static string $view = 'filament.resources.user-resource.pages.edit-user';

    public ?string $record = null;

    public ?User $user = null;

    public ?array $data = [];

    public function mount(string|User $record): void
    {
        $recordId = $record instanceof User ? $record->getKey() : $record;
        $this->record = $recordId;
        $this->user = $record instanceof User ? $record : User::find($record);

        if (! $this->user) {
            abort(404);
        }

        $this->data = [
            'role' => $this->user->role,
            'subscription_status' => $this->user->subscription_status,
        ];
    }

    public function getTitle(): string
    {
        return __('edit_user').': '.($this->user?->getDisplayName() ?? '');
    }

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('suspend_account')
                ->label(__('suspend_account'))
                ->icon('heroicon-o-no-symbol')
                ->color('warning')
                ->requiresConfirmation()
                ->modalHeading(__('confirm_suspend'))
                ->action(function () {
                    $admin = Auth::user();
                    $adminId = $admin?->getKey() ?? 'system';

                    $service = app(FirestoreService::class);
                    $service->updateDocument('users', $this->record, [
                        'subscription_status' => 'suspended',
                        'is_premium' => false,
                        'updated_at' => FirestoreService::now(),
                        'suspended_by' => $adminId,
                    ]);

                    app(ActivityLogService::class)->log(
                        'userSuspended',
                        "Suspended account for {$this->user->getDisplayName()}",
                        ['user_id' => $this->record, 'actor_uid' => $adminId]
                    );

                    Notification::make()->success()->title(__('account_suspended'))->send();
                    $this->user = User::find($this->record);
                    $this->data['subscription_status'] = 'suspended';
                }),
            Actions\Action::make('delete_account')
                ->label(__('delete_account'))
                ->icon('heroicon-o-trash')
                ->color('danger')
                ->requiresConfirmation()
                ->modalHeading(__('confirm_delete'))
                ->action(function () {
                    $admin = Auth::user();
                    $adminId = $admin?->getKey() ?? 'system';

                    $service = app(FirestoreService::class);
                    $service->deleteDocument('users', $this->record);

                    app(ActivityLogService::class)->log(
                        'userDeleted',
                        "Deleted account for {$this->user->getDisplayName()}",
                        ['user_id' => $this->record, 'actor_uid' => $adminId]
                    );

                    Notification::make()->success()->title(__('account_deleted'))->send();
                    redirect(UserResource::getUrl());
                }),
        ];
    }

    public function save(): void
    {
        $admin = Auth::user();
        $adminId = $admin?->getKey() ?? 'system';

        $service = app(FirestoreService::class);
        $updates = [];

        if (isset($this->data['role']) && $this->data['role'] !== $this->user->role) {
            $updates['role'] = $this->data['role'];
        }

        if (isset($this->data['subscription_status']) && $this->data['subscription_status'] !== $this->user->subscription_status) {
            $updates['subscription_status'] = $this->data['subscription_status'];
            // Keep is_premium in sync: active = premium, anything else = not premium
            $updates['is_premium'] = ($this->data['subscription_status'] === 'active');
        }

        if (! empty($updates)) {
            $updates['updated_at'] = FirestoreService::now();
            $updates['updated_by'] = $adminId;
            $service->updateDocument('users', $this->record, $updates);

            app(ActivityLogService::class)->log(
                'userUpdated',
                "Updated user {$this->user->getDisplayName()}: ".implode(', ', array_keys($updates)),
                ['user_id' => $this->record, 'changes' => $updates, 'actor_uid' => $adminId]
            );

            Notification::make()->success()->title(__('save_changes'))->send();
            $this->user = User::find($this->record);
        }
    }
}
