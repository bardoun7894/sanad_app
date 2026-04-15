<?php

namespace App\Filament\Resources\PaymentResource\Pages;

use App\Filament\Resources\PaymentResource;
use App\Models\Payment;
use App\Models\PaymentVerification;
use App\Services\ExportService;
use App\Services\FirestoreService;
use Filament\Resources\Pages\Page;
use Livewire\Attributes\Url;

class ListPayments extends Page
{
    protected static string $resource = PaymentResource::class;

    protected static string $view = 'filament.resources.payment-resource.pages.list-payments';

    #[Url]
    public string $activeTab = 'all';

    public array $payments = [];

    public string $search = '';

    // ─── Stat Card Data ──────────────────────────────────────

    public string $totalRevenue = '0.00';

    public string $monthRevenue = '0.00';

    public string $avgTransaction = '0.00';

    public string $conversionRate = '0%';

    public string $successRate = '0%';

    public string $approvalRate = '0%';

    public int $allCount = 0;

    public int $completedCount = 0;

    public int $pendingCount = 0;

    public int $failedCount = 0;

    // Pagination properties
    public int $perPage = 25;

    public ?string $currentCursor = null;

    public array $cursorStack = [];

    public bool $hasMore = false;

    public function getTitle(): string
    {
        return __('billing');
    }

    public function getHeading(): string
    {
        return __('billing');
    }

    public function mount(): void
    {
        $this->loadStats();
        $this->loadPayments();
    }

    // ─── Stats Calculation ───────────────────────────────────

    public function loadStats(): void
    {
        $firestore = app(FirestoreService::class);

        // Fetch all payments
        $allPayments = Payment::all();
        $this->allCount = count($allPayments);

        $completed = array_filter($allPayments, fn (Payment $p) => $p->status === 'completed');
        $this->completedCount = count($completed);
        $this->pendingCount = count(array_filter($allPayments, fn (Payment $p) => $p->status === 'pending'));
        $this->failedCount = count(array_filter($allPayments, fn (Payment $p) => $p->status === 'failed'));

        // Total revenue (sum of completed amounts)
        $totalRev = array_sum(array_map(fn (Payment $p) => (float) ($p->amount ?? 0), $completed));
        $this->totalRevenue = number_format($totalRev, 2);

        // This month revenue
        $startOfMonth = date('Y-m-01');
        $monthCompleted = array_filter($completed, function (Payment $p) use ($startOfMonth) {
            $createdAt = $p->getAttribute('created_at');

            return $createdAt && $createdAt >= $startOfMonth;
        });
        $monthRev = array_sum(array_map(fn (Payment $p) => (float) ($p->amount ?? 0), $monthCompleted));
        $this->monthRevenue = number_format($monthRev, 2);

        // Average transaction
        if ($this->completedCount > 0) {
            $this->avgTransaction = number_format($totalRev / $this->completedCount, 2);
        }

        // Free-to-Premium Conversion Rate
        $totalUsers = $firestore->countDocuments('users');
        $premiumUsers = $firestore->countDocuments('users', [['subscription_status', '=', 'active']]);
        if ($totalUsers > 0) {
            $this->conversionRate = number_format(($premiumUsers / $totalUsers) * 100, 1).'%';
        }

        // Payment Success Rate
        if ($this->allCount > 0) {
            $this->successRate = number_format(($this->completedCount / $this->allCount) * 100, 1).'%';
        }

        // Verification Approval Rate
        $allVerifications = PaymentVerification::all();
        $approvedVerifications = array_filter($allVerifications, fn ($v) => $v->status === 'approved');
        $totalVerifications = count($allVerifications);
        if ($totalVerifications > 0) {
            $this->approvalRate = number_format((count($approvedVerifications) / $totalVerifications) * 100, 1).'%';
        }
    }

    // ─── Data Loading ────────────────────────────────────────

    public function loadPayments(): void
    {
        $wheres = [];

        if ($this->activeTab !== 'all') {
            $wheres[] = ['status', '=', $this->activeTab];
        }

        // Use paginated query
        $result = Payment::paginate(
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
            $all = array_filter($all, function (Payment $p) use ($query) {
                return str_contains(mb_strtolower($p->safeGet('user_email', '')), $query)
                    || str_contains(mb_strtolower($p->safeGet('reference_code', '')), $query)
                    || str_contains(mb_strtolower($p->safeGet('gateway_transaction_id', '')), $query);
            });
            $all = array_values($all);
        }

        $this->payments = $all;
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
        if ($this->hasMore && ! empty($this->payments)) {
            if ($this->currentCursor) {
                $this->cursorStack[] = $this->currentCursor;
            }
            $lastPayment = end($this->payments);
            $this->currentCursor = $lastPayment->getKey();
            $this->loadPayments();
        }
    }

    public function previousPage(): void
    {
        if (! empty($this->cursorStack)) {
            $this->currentCursor = array_pop($this->cursorStack);
            $this->loadPayments();
        }
    }

    public function resetPagination(): void
    {
        $this->currentCursor = null;
        $this->cursorStack = [];
        $this->loadPayments();
    }

    // ─── Export Actions ──────────────────────────────────────

    public function exportCsv(): mixed
    {
        $export = app(ExportService::class);
        $columns = [
            'user_email' => __('email'),
            'amount' => __('amount'),
            'currency' => __('currency'),
            'status' => __('status'),
            'payment_method' => __('payment_method'),
            'reference_code' => __('reference_code'),
            'gateway_transaction_id' => __('transaction_id'),
            'created_at' => __('created_at'),
        ];

        $rows = array_map(fn (Payment $p) => $p->toArray(), $this->payments);
        $path = $export->exportToCsv($rows, $columns, 'payments');

        return response()->download($path)->deleteFileAfterSend();
    }

    public function exportPdf(): mixed
    {
        $export = app(ExportService::class);
        $columns = [
            'user_email' => __('email'),
            'amount' => __('amount'),
            'currency' => __('currency'),
            'status' => __('status'),
            'payment_method' => __('payment_method'),
            'reference_code' => __('reference_code'),
            'gateway_transaction_id' => __('transaction_id'),
            'created_at' => __('created_at'),
        ];

        $rows = array_map(fn (Payment $p) => $p->toArray(), $this->payments);
        $path = $export->exportToPdf($rows, $columns, 'payments', __('billing'));

        return response()->download($path)->deleteFileAfterSend();
    }
}
