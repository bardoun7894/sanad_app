<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use App\Models\User;
use App\Services\ExportService;
use Filament\Actions;
use Filament\Resources\Pages\Page;

class ListUsers extends Page
{
    protected static string $resource = UserResource::class;

    protected static string $view = 'filament.resources.user-resource.pages.list-users';

    // Pagination properties
    public int $perPage = 25;

    public ?string $currentCursor = null;

    public array $cursorStack = []; // Stack to track previous page cursors

    public bool $hasMore = false;

    public array $users = [];

    public array $filters = [];

    public function getTitle(): string
    {
        return __('users');
    }

    public function mount(): void
    {
        $this->loadUsers();
    }

    public function loadUsers(): void
    {
        $wheres = [];

        // Apply filters
        if (! empty($this->filters['role'])) {
            $wheres[] = ['role', '=', $this->filters['role']];
        }
        if (! empty($this->filters['subscription_status'])) {
            $wheres[] = ['subscription_status', '=', $this->filters['subscription_status']];
        }

        $result = User::paginate(
            perPage: $this->perPage,
            wheres: $wheres,
            orderBy: 'created_at',
            direction: 'DESC',
            startAfterId: $this->currentCursor
        );

        $this->users = $result['data'];
        $this->hasMore = $result['has_more'];
    }

    public function nextPage(): void
    {
        if ($this->hasMore && ! empty($this->users)) {
            // Save current cursor to stack for "previous" navigation
            if ($this->currentCursor) {
                $this->cursorStack[] = $this->currentCursor;
            }
            // Move to next page using last document ID
            $lastUser = end($this->users);
            $this->currentCursor = $lastUser->getKey();
            $this->loadUsers();
        }
    }

    public function previousPage(): void
    {
        if (! empty($this->cursorStack)) {
            // Pop the previous cursor from stack
            $this->currentCursor = array_pop($this->cursorStack);
            $this->loadUsers();
        }
    }

    public function resetPagination(): void
    {
        $this->currentCursor = null;
        $this->cursorStack = [];
        $this->loadUsers();
    }

    public function updatedFilters(): void
    {
        $this->resetPagination();
    }

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('export_csv')
                ->label(__('export_csv'))
                ->icon('heroicon-o-arrow-down-tray')
                ->action(function () {
                    // For exports, fetch all data (no pagination)
                    $users = User::all(orderBy: 'created_at', direction: 'DESC');
                    $columns = [
                        'display_name' => 'Name',
                        'email' => 'Email',
                        'role' => 'Role',
                        'subscription_status' => 'Subscription',
                        'created_at' => 'Created',
                    ];
                    $path = app(ExportService::class)->exportToCsv(
                        array_map(fn ($u) => $u->toArray(), $users),
                        $columns,
                        'users'
                    );

                    return response()->download($path)->deleteFileAfterSend();
                }),
            Actions\Action::make('export_pdf')
                ->label(__('export_pdf'))
                ->icon('heroicon-o-document')
                ->action(function () {
                    // For exports, fetch all data (no pagination)
                    $users = User::all(orderBy: 'created_at', direction: 'DESC');
                    $columns = [
                        'display_name' => 'Name',
                        'email' => 'Email',
                        'role' => 'Role',
                        'subscription_status' => 'Subscription',
                        'created_at' => 'Created',
                    ];
                    $path = app(ExportService::class)->exportToPdf(
                        array_map(fn ($u) => $u->toArray(), $users),
                        $columns,
                        'users',
                        'Users Report'
                    );

                    return response()->download($path)->deleteFileAfterSend();
                }),
        ];
    }
}
