<?php

namespace App\Filament\Resources\TherapistResource\Pages;

use App\Filament\Resources\TherapistResource;
use App\Models\TherapistProfile;
use App\Services\ActivityLogService;
use App\Services\ExportService;
use App\Services\FirestoreService;
use Filament\Resources\Pages\Page;
use Illuminate\Support\Facades\Auth;
use Livewire\Attributes\Url;

class ListTherapists extends Page
{
    protected static string $resource = TherapistResource::class;

    protected static string $view = 'filament.resources.therapist-resource.pages.list-therapists';

    #[Url]
    public string $activeTab = 'pending';

    public array $therapists = [];

    public int $pendingCount = 0;

    public int $approvedCount = 0;

    public int $rejectedCount = 0;

    public string $search = '';

    // Pagination properties
    public int $perPage = 25;

    public ?string $currentCursor = null;

    public array $cursorStack = [];

    public bool $hasMore = false;

    // ─── Reject Modal State ──────────────────────────────────

    public bool $showRejectModal = false;

    public string $rejectTherapistId = '';

    public string $rejectTherapistName = '';

    public string $rejectionReason = '';

    public function getTitle(): string
    {
        return __('clinicians');
    }

    public function getHeading(): string
    {
        return __('clinicians');
    }

    public function mount(): void
    {
        $this->loadCounts();
        $this->loadTherapists();
    }

    // ─── Data Loading ────────────────────────────────────────

    public function loadCounts(): void
    {
        $firestore = app(FirestoreService::class);

        $this->pendingCount = $firestore->countDocuments('therapists', [['approval_status', '=', 'pending']]);
        $this->approvedCount = $firestore->countDocuments('therapists', [['approval_status', '=', 'approved']]);
        $this->rejectedCount = $firestore->countDocuments('therapists', [['approval_status', '=', 'rejected']]);
    }

    public function loadTherapists(): void
    {
        $wheres = [['approval_status', '=', $this->activeTab]];

        // Use paginated query
        $result = TherapistProfile::paginate(
            perPage: $this->perPage,
            wheres: $wheres,
            orderBy: 'created_at',
            direction: 'DESC',
            startAfterId: $this->currentCursor
        );

        $all = $result['data'];
        $this->hasMore = $result['has_more'];

        // Apply search filter in PHP (Firestore doesn't support text search)
        if ($this->search !== '') {
            $query = mb_strtolower($this->search);
            $all = array_filter($all, function (TherapistProfile $t) use ($query) {
                return str_contains(mb_strtolower($t->safeGet('name', '')), $query)
                    || str_contains(mb_strtolower($t->safeGet('email', '')), $query);
            });
            $all = array_values($all);
        }

        $this->therapists = $all;
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

    // ─── Pagination Actions ──────────────────────────────────

    public function nextPage(): void
    {
        if ($this->hasMore && ! empty($this->therapists)) {
            if ($this->currentCursor) {
                $this->cursorStack[] = $this->currentCursor;
            }
            $lastTherapist = end($this->therapists);
            $this->currentCursor = $lastTherapist->getKey();
            $this->loadTherapists();
        }
    }

    public function previousPage(): void
    {
        if (! empty($this->cursorStack)) {
            $this->currentCursor = array_pop($this->cursorStack);
            $this->loadTherapists();
        }
    }

    public function resetPagination(): void
    {
        $this->currentCursor = null;
        $this->cursorStack = [];
        $this->loadTherapists();
    }

    // ─── Approve Action ──────────────────────────────────────

    public function approve(string $id): void
    {
        $firestore = app(FirestoreService::class);
        $admin = Auth::user();
        $adminId = $admin?->getKey() ?? 'system';

        // Ensure therapist profile doc exists (create if missing, matching Flutter logic)
        $therapistDoc = $firestore->getDocument('therapists', $id);
        if (! $therapistDoc) {
            // Fetch user data for defaults
            $userDoc = $firestore->getDocument('users', $id);
            $userName = $userDoc['name'] ?? $userDoc['display_name'] ?? 'New Therapist';
            $userEmail = $userDoc['email'] ?? '';

            $firestore->setDocument('therapists', $id, [
                'id' => $id,
                'name' => $userName,
                'email' => $userEmail,
                'title' => 'Mental Health Specialist',
                'bio' => 'Welcome to my profile. I am dedicated to helping you achieve your mental health goals.',
                'approval_status' => 'approved',
                'status' => 'active',
                'is_active' => true,
                'specialties' => ['General Counseling'],
                'session_types' => ['video', 'audio', 'chat'],
                'session_price' => 150.0,
                'currency' => 'SAR',
                'languages' => ['Arabic', 'English'],
                'years_experience' => 1,
                'rating' => 5.0,
                'review_count' => 0,
                'created_at' => now()->toDateTimeString(),
                'updated_at' => now()->toDateTimeString(),
                'approved_at' => now()->toDateTimeString(),
                'approved_by' => $adminId,
            ], false);
        } else {
            // Update existing therapists collection (match Flutter: is_active = true)
            $firestore->updateDocument('therapists', $id, [
                'approval_status' => 'approved',
                'approved_at' => now()->toDateTimeString(),
                'approved_by' => $adminId,
                'is_active' => true,
                'updated_at' => now()->toDateTimeString(),
            ]);
        }

        // Update users collection (match Flutter: role = therapist + therapist_status)
        $firestore->updateDocument('users', $id, [
            'role' => 'therapist',
            'therapist_status' => 'approved',
            'updated_at' => now()->toDateTimeString(),
        ]);

        // Log the action
        app(ActivityLogService::class)->log(
            'therapist_approved',
            "Approved therapist {$id}",
            ['therapist_id' => $id, 'admin_id' => $adminId],
        );

        $this->loadCounts();
        $this->loadTherapists();

        $this->dispatch('notify', type: 'success', message: __('therapist_approved'));
    }

    // ─── Reject Action ───────────────────────────────────────

    public function openRejectModal(string $id, string $name): void
    {
        $this->rejectTherapistId = $id;
        $this->rejectTherapistName = $name;
        $this->rejectionReason = '';
        $this->showRejectModal = true;
    }

    public function cancelReject(): void
    {
        $this->showRejectModal = false;
        $this->rejectTherapistId = '';
        $this->rejectTherapistName = '';
        $this->rejectionReason = '';
    }

    public function confirmReject(): void
    {
        if ($this->rejectTherapistId === '') {
            return;
        }

        $firestore = app(FirestoreService::class);
        $admin = Auth::user();

        $adminId = $admin?->getKey() ?? 'system';

        $firestore->updateDocument('therapists', $this->rejectTherapistId, [
            'approval_status' => 'rejected',
            'rejection_reason' => $this->rejectionReason,
            'rejected_by' => $adminId,
            'updated_at' => now()->toDateTimeString(),
        ]);

        $firestore->updateDocument('users', $this->rejectTherapistId, [
            'therapist_status' => 'rejected',
            'updated_at' => now()->toDateTimeString(),
        ]);

        app(ActivityLogService::class)->log(
            'therapist_rejected',
            "Rejected therapist {$this->rejectTherapistId}",
            [
                'therapist_id' => $this->rejectTherapistId,
                'actor_uid' => $admin?->getKey() ?? 'system',
                'rejection_reason' => $this->rejectionReason,
            ],
        );

        $this->cancelReject();
        $this->loadCounts();
        $this->loadTherapists();

        $this->dispatch('notify', type: 'success', message: __('therapist_rejected'));
    }

    // ─── Export Actions ──────────────────────────────────────

    public function exportCsv(): mixed
    {
        $export = app(ExportService::class);
        $columns = [
            'name' => __('name'),
            'email' => __('email'),
            'title' => __('title'),
            'approval_status' => __('status'),
            'rating' => __('rating'),
            'session_price' => __('price'),
        ];

        $rows = array_map(fn (TherapistProfile $t) => $t->toArray(), $this->therapists);
        $path = $export->exportToCsv($rows, $columns, 'therapists');

        return response()->download($path)->deleteFileAfterSend();
    }

    public function exportPdf(): mixed
    {
        $export = app(ExportService::class);
        $columns = [
            'name' => __('name'),
            'email' => __('email'),
            'title' => __('title'),
            'approval_status' => __('status'),
            'rating' => __('rating'),
            'session_price' => __('price'),
        ];

        $rows = array_map(fn (TherapistProfile $t) => $t->toArray(), $this->therapists);
        $path = $export->exportToPdf($rows, $columns, 'therapists', __('clinicians'));

        return response()->download($path)->deleteFileAfterSend();
    }
}
