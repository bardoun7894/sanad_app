<?php

namespace App\Http\Livewire;

use App\Models\Notification;
use App\Services\FirestoreService;
use Livewire\Component;

class NotificationBell extends Component
{
    public array $notifications = [];

    public int $unreadCount = 0;

    public bool $isOpen = false;

    public function mount(): void
    {
        $this->loadNotifications();
    }

    public function loadNotifications(): void
    {
        try {
            $adminId = auth()->id();
            if (! $adminId) {
                return;
            }

            $results = Notification::all(
                wheres: [['user_id', '=', $adminId]],
                orderBy: 'created_at',
                direction: 'DESC',
                limit: 20,
            );

            $this->notifications = $results;

            $this->unreadCount = count(array_filter(
                $this->notifications,
                fn ($n) => ! ($n->getAttribute('is_read') ?? false)
            ));

        } catch (\Exception $e) {
            $this->notifications = [];
            $this->unreadCount = 0;
        }
    }

    public function toggleDropdown(): void
    {
        $this->isOpen = ! $this->isOpen;
    }

    public function markRead(string $notificationId): void
    {
        try {
            app(FirestoreService::class)->updateDocument('notifications', $notificationId, [
                'is_read' => true,
                'read_at' => now()->toDateTimeString(),
            ]);
            $this->loadNotifications();
        } catch (\Exception $e) {
            // Silently fail
        }
    }

    public function markAllRead(): void
    {
        try {
            $service = app(FirestoreService::class);
            foreach ($this->notifications as $notification) {
                if (! ($notification->getAttribute('is_read') ?? false)) {
                    $service->updateDocument('notifications', $notification->getKey(), [
                        'is_read' => true,
                        'read_at' => now()->toDateTimeString(),
                    ]);
                }
            }
            $this->loadNotifications();
        } catch (\Exception $e) {
            // Silently fail
        }
    }

    public function refreshData(): void
    {
        $this->loadNotifications();
    }

    public function render()
    {
        return view('livewire.notification-bell');
    }
}
