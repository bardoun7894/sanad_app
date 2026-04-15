<?php

namespace App\Filament\Pages;

use App\Models\Payment;
use App\Models\PaymentVerification as PaymentVerificationModel;
use App\Services\ActivityLogService;
use App\Services\FirestoreService;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Auth;

class PaymentVerification extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-shield-check';

    protected static ?int $navigationSort = 9;

    protected static string $view = 'filament.pages.payment-verification';

    public static function getNavigationLabel(): string
    {
        return __('payment_verification');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    public function getTitle(): string
    {
        return __('payment_verification');
    }

    public function getHeading(): string
    {
        return __('payment_verification');
    }

    // ─── State ───────────────────────────────────────────────

    public array $verifications = [];

    public bool $showRejectModal = false;

    public string $rejectVerificationId = '';

    public string $rejectUserName = '';

    public string $rejectionReason = '';

    // ─── Lifecycle ───────────────────────────────────────────

    public function mount(): void
    {
        $this->loadVerifications();
    }

    public function loadVerifications(): void
    {
        $this->verifications = PaymentVerificationModel::all(
            [['status', '=', 'pending']],
            'created_at',
            'DESC',
        );
    }

    // ─── Approve Action ──────────────────────────────────────

    public function approve(string $id): void
    {
        $firestore = app(FirestoreService::class);
        $admin = Auth::user();

        // Fetch the verification first
        $verification = PaymentVerificationModel::find($id);

        if (! $verification || ! $verification->isPending()) {
            $this->dispatch('notify', type: 'warning', message: __('already_processed'));
            $this->loadVerifications();

            return;
        }

        $now = FirestoreService::now();
        $adminId = $admin?->getKey() ?? 'system';

        // 1. Update the verification record
        $firestore->updateDocument('payment_verifications', $id, [
            'status' => 'approved',
            'reviewed_at' => $now,
            'reviewed_by' => $adminId,
        ]);

        // 2. Update the user record (activate premium)
        // Match Flutter expiry logic: yearly if productId contains 'yearly' or 'annual'
        $productId = $verification->product_id ?? '';
        $isYearly = str_contains($productId, 'yearly') || str_contains($productId, 'annual');
        $expiryDate = $isYearly
            ? FirestoreService::timestamp(now()->addYear())
            : FirestoreService::timestamp(now()->addDays(30));

        $userId = $verification->user_id;
        if ($userId) {
            $firestore->updateDocument('users', $userId, [
                'is_premium' => true,
                'subscription_status' => 'active',
                'subscription_plan' => $productId,
                'subscription_product_title' => $verification->product_title ?? '',
                'subscription_expiry_date' => $expiryDate,
                'subscription_start_date' => $now,
                'payment_gateway' => 'bank_transfer',
                'auto_renew' => false,
                'updated_at' => $now,
            ]);
        }

        // 3. Create a payments record (fields aligned with Flutter admin_provider.dart)
        Payment::create([
            'user_id' => $verification->user_id,
            'user_email' => $verification->user_email,
            'product_id' => $verification->product_id,
            'product_title' => $verification->product_title,
            'amount' => $verification->amount,
            'currency' => $verification->currency ?? 'SAR',
            'payment_method' => 'bank_transfer',
            'status' => 'completed',
            'reference_code' => $verification->reference_code,
            'gateway_transaction_id' => 'VRF-'.$id,
            'start_date' => $now,
            'end_date' => $expiryDate,
            'notes' => __('approved_via_verification'),
            'created_at' => $now,
        ]);

        // 4. Log the activity
        app(ActivityLogService::class)->log(
            'payment_verification_approved',
            "Approved payment verification {$id} for user {$userId}",
            [
                'verification_id' => $id,
                'user_id' => $userId,
                'amount' => $verification->amount,
                'actor_uid' => $adminId,
            ],
        );

        $this->loadVerifications();
        $this->dispatch('notify', type: 'success', message: __('verification_approved'));
    }

    // ─── Reject Action ───────────────────────────────────────

    public function openRejectModal(string $id, string $userName): void
    {
        $this->rejectVerificationId = $id;
        $this->rejectUserName = $userName;
        $this->rejectionReason = '';
        $this->showRejectModal = true;
    }

    public function cancelReject(): void
    {
        $this->showRejectModal = false;
        $this->rejectVerificationId = '';
        $this->rejectUserName = '';
        $this->rejectionReason = '';
    }

    public function confirmReject(): void
    {
        if ($this->rejectVerificationId === '') {
            return;
        }

        $firestore = app(FirestoreService::class);
        $admin = Auth::user();

        // Check for concurrent processing
        $verification = PaymentVerificationModel::find($this->rejectVerificationId);

        if (! $verification || ! $verification->isPending()) {
            $this->dispatch('notify', type: 'warning', message: __('already_processed'));
            $this->cancelReject();
            $this->loadVerifications();

            return;
        }

        $now = FirestoreService::now();
        $adminId = $admin?->getKey() ?? 'system';

        $firestore->updateDocument('payment_verifications', $this->rejectVerificationId, [
            'status' => 'rejected',
            'rejection_reason' => $this->rejectionReason,
            'reviewed_at' => $now,
            'reviewed_by' => $adminId,
        ]);

        app(ActivityLogService::class)->log(
            'payment_verification_rejected',
            "Rejected payment verification {$this->rejectVerificationId}",
            [
                'verification_id' => $this->rejectVerificationId,
                'user_id' => $verification->user_id,
                'actor_uid' => $adminId,
                'rejection_reason' => $this->rejectionReason,
            ],
        );

        $this->cancelReject();
        $this->loadVerifications();
        $this->dispatch('notify', type: 'success', message: __('verification_rejected'));
    }
}
