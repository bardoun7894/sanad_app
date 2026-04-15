<?php

namespace App\Filament\Resources\BookingResource\Pages;

use App\Filament\Resources\BookingResource;
use App\Models\Booking;
use App\Models\TherapistProfile;
use App\Services\ActivityLogService;
use App\Services\ExportService;
use App\Services\FirestoreService;
use Filament\Resources\Pages\Page;
use Illuminate\Support\Facades\Auth;
use Livewire\Attributes\Url;

class ListBookings extends Page
{
    protected static string $resource = BookingResource::class;

    protected static string $view = 'filament.resources.booking-resource.pages.list-bookings';

    #[Url]
    public string $activeTab = 'all';

    #[Url]
    public string $sessionTypeFilter = '';

    public array $bookings = [];

    public int $allCount = 0;

    public int $upcomingCount = 0;

    public int $completedCount = 0;

    public int $cancelledCount = 0;

    public string $search = '';

    // Pagination properties
    public int $perPage = 25;

    public ?string $currentCursor = null;

    public array $cursorStack = [];

    public bool $hasMore = false;

    // ─── Cancel Modal State ──────────────────────────────────

    public bool $showCancelModal = false;

    public string $cancelBookingId = '';

    public string $cancelBookingClient = '';

    public string $cancellationReason = '';

    public function getTitle(): string
    {
        return __('appointments');
    }

    public function getHeading(): string
    {
        return __('appointments');
    }

    public function mount(): void
    {
        $this->loadCounts();
        $this->loadBookings();
    }

    // ─── Data Loading ────────────────────────────────────────

    public function loadCounts(): void
    {
        $firestore = app(FirestoreService::class);

        // Total count (all statuses)
        $allBookings = Booking::all();
        $this->allCount = count($allBookings);

        // Upcoming: status in [pending, confirmed] and scheduled_time > now
        $upcomingBookings = array_filter($allBookings, fn (Booking $b) => $b->isUpcoming());
        $this->upcomingCount = count($upcomingBookings);

        $this->completedCount = $firestore->countDocuments('bookings', [['status', '=', 'completed']]);
        $this->cancelledCount = $firestore->countDocuments('bookings', [['status', '=', 'cancelled']]);
    }

    public function loadBookings(): void
    {
        $wheres = [];

        // Tab-based filtering
        if ($this->activeTab === 'completed') {
            $wheres[] = ['status', '=', 'completed'];
        } elseif ($this->activeTab === 'cancelled') {
            $wheres[] = ['status', '=', 'cancelled'];
        } elseif ($this->activeTab === 'upcoming') {
            // Firestore cannot do complex OR + time queries, so we filter in PHP
        }

        // Session type filter
        if ($this->sessionTypeFilter !== '') {
            $wheres[] = ['session_type', '=', $this->sessionTypeFilter];
        }

        // Use paginated query
        $result = Booking::paginate(
            perPage: $this->perPage,
            wheres: $wheres,
            orderBy: 'scheduled_time',
            direction: 'DESC',
            startAfterId: $this->currentCursor
        );

        $all = $result['data'];
        $this->hasMore = $result['has_more'];

        // Apply upcoming filter in PHP (needs time comparison)
        if ($this->activeTab === 'upcoming') {
            $all = array_filter($all, fn (Booking $b) => $b->isUpcoming());
            $all = array_values($all);
        }

        // Search filter (client name)
        if ($this->search !== '') {
            $query = mb_strtolower($this->search);
            $all = array_filter($all, function (Booking $b) use ($query) {
                return str_contains(mb_strtolower($b->safeGet('client_name', '')), $query)
                    || str_contains(mb_strtolower($b->safeGet('client_email', '')), $query);
            });
            $all = array_values($all);
        }

        $this->bookings = $all;
    }

    // ─── Tab Switching ───────────────────────────────────────

    public function switchTab(string $tab): void
    {
        $this->activeTab = $tab;
        $this->search = '';
        $this->resetPagination();
    }

    public function updatedSearch(): void
    {
        $this->resetPagination();
    }

    public function updatedSessionTypeFilter(): void
    {
        $this->resetPagination();
    }

    // ─── Pagination Actions ──────────────────────────────────

    public function nextPage(): void
    {
        if ($this->hasMore && ! empty($this->bookings)) {
            if ($this->currentCursor) {
                $this->cursorStack[] = $this->currentCursor;
            }
            $lastBooking = end($this->bookings);
            $this->currentCursor = $lastBooking->getKey();
            $this->loadBookings();
        }
    }

    public function previousPage(): void
    {
        if (! empty($this->cursorStack)) {
            $this->currentCursor = array_pop($this->cursorStack);
            $this->loadBookings();
        }
    }

    public function resetPagination(): void
    {
        $this->currentCursor = null;
        $this->cursorStack = [];
        $this->loadBookings();
    }

    // ─── Cancel Action ───────────────────────────────────────

    public function openCancelModal(string $id, string $clientName): void
    {
        $this->cancelBookingId = $id;
        $this->cancelBookingClient = $clientName;
        $this->cancellationReason = '';
        $this->showCancelModal = true;
    }

    public function dismissCancelModal(): void
    {
        $this->showCancelModal = false;
        $this->cancelBookingId = '';
        $this->cancelBookingClient = '';
        $this->cancellationReason = '';
    }

    public function confirmCancel(): void
    {
        if ($this->cancelBookingId === '') {
            return;
        }

        $firestore = app(FirestoreService::class);
        $admin = Auth::user();

        $adminId = $admin?->getKey() ?? 'system';

        $firestore->updateDocument('bookings', $this->cancelBookingId, [
            'status' => 'cancelled',
            'cancellation_reason' => $this->cancellationReason,
            'cancelled_by' => $adminId,
            'cancelled_at' => FirestoreService::now(),
            'updated_at' => FirestoreService::now(),
        ]);

        app(ActivityLogService::class)->log(
            'booking_cancelled',
            "Cancelled booking {$this->cancelBookingId}",
            [
                'booking_id' => $this->cancelBookingId,
                'actor_uid' => $adminId,
                'cancellation_reason' => $this->cancellationReason,
            ],
        );

        $this->dismissCancelModal();
        $this->loadCounts();
        $this->loadBookings();

        $this->dispatch('notify', type: 'success', message: __('booking_cancelled'));
    }

    // ─── Export Actions ──────────────────────────────────────

    public function exportCsv(): mixed
    {
        $export = app(ExportService::class);
        $columns = [
            'client_name' => __('client'),
            'scheduled_time' => __('date_time'),
            'duration_minutes' => __('duration'),
            'session_type' => __('session_type'),
            'status' => __('status'),
            'amount' => __('amount'),
            'currency' => __('currency'),
        ];

        $rows = array_map(fn (Booking $b) => $b->toArray(), $this->bookings);
        $path = $export->exportToCsv($rows, $columns, 'bookings');

        return response()->download($path)->deleteFileAfterSend();
    }

    public function exportPdf(): mixed
    {
        $export = app(ExportService::class);
        $columns = [
            'client_name' => __('client'),
            'scheduled_time' => __('date_time'),
            'duration_minutes' => __('duration'),
            'session_type' => __('session_type'),
            'status' => __('status'),
            'amount' => __('amount'),
            'currency' => __('currency'),
        ];

        $rows = array_map(fn (Booking $b) => $b->toArray(), $this->bookings);
        $path = $export->exportToPdf($rows, $columns, 'bookings', __('appointments'));

        return response()->download($path)->deleteFileAfterSend();
    }

    /**
     * Resolve therapist name from cache or Firestore for display.
     */
    public function getTherapistName(string $therapistId): string
    {
        static $cache = [];

        if (isset($cache[$therapistId])) {
            return $cache[$therapistId];
        }

        $therapist = TherapistProfile::find($therapistId);
        $cache[$therapistId] = $therapist?->safeGet('name', __('unknown')) ?? __('unknown');

        return $cache[$therapistId];
    }
}
