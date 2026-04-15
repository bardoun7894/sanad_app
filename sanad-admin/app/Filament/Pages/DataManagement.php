<?php

namespace App\Filament\Pages;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\User;
use App\Services\ActivityLogService;
use App\Services\ExportService;
use App\Services\FirestoreService;
use Carbon\Carbon;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Log;

class DataManagement extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-circle-stack';

    protected static ?int $navigationSort = 14;

    protected static string $view = 'filament.pages.data-management';

    // ─── Navigation ──────────────────────────────────────────

    public function getTitle(): string
    {
        return __('data_management');
    }

    public static function getNavigationLabel(): string
    {
        return __('data_management');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    // ─── Collection Counts ───────────────────────────────────

    /**
     * Get record counts for each major collection.
     *
     * @return array<string, int>
     */
    public function getCollectionCounts(): array
    {
        try {
            $firestore = app(FirestoreService::class);

            return [
                'users' => $firestore->countDocuments('users'),
                'bookings' => $firestore->countDocuments('bookings'),
                'payments' => $firestore->countDocuments('payments'),
                'activity_logs' => $firestore->countDocuments('activity_logs'),
            ];
        } catch (\Exception $e) {
            Log::error("DataManagement::getCollectionCounts failed: {$e->getMessage()}");

            return [
                'users' => 0,
                'bookings' => 0,
                'payments' => 0,
                'activity_logs' => 0,
            ];
        }
    }

    // ─── Export Actions ──────────────────────────────────────

    public function exportUsersCsv(): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $users = User::all();
        $columns = [
            'id' => __('id'),
            'display_name' => __('name'),
            'email' => __('email'),
            'role' => __('role'),
            'is_premium' => __('premium'),
            'last_login' => __('last_login'),
            'created_at' => __('created_at'),
        ];

        $path = app(ExportService::class)->exportToCsv($users, $columns, 'users');

        $this->logExport('users', 'CSV');

        return response()->download($path)->deleteFileAfterSend();
    }

    public function exportUsersPdf(): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $users = User::all();
        $columns = [
            'id' => __('id'),
            'display_name' => __('name'),
            'email' => __('email'),
            'role' => __('role'),
            'is_premium' => __('premium'),
            'last_login' => __('last_login'),
            'created_at' => __('created_at'),
        ];

        $path = app(ExportService::class)->exportToPdf($users, $columns, 'users', __('users_export'));

        $this->logExport('users', 'PDF');

        return response()->download($path)->deleteFileAfterSend();
    }

    public function exportBookingsCsv(): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $bookings = Booking::all();
        $columns = [
            'id' => __('id'),
            'client_name' => __('client'),
            'therapist_id' => __('therapist'),
            'scheduled_time' => __('scheduled_time'),
            'session_type' => __('session_type'),
            'status' => __('status'),
            'amount' => __('amount'),
            'created_at' => __('created_at'),
        ];

        $path = app(ExportService::class)->exportToCsv($bookings, $columns, 'bookings');

        $this->logExport('bookings', 'CSV');

        return response()->download($path)->deleteFileAfterSend();
    }

    public function exportBookingsPdf(): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $bookings = Booking::all();
        $columns = [
            'id' => __('id'),
            'client_name' => __('client'),
            'therapist_id' => __('therapist'),
            'scheduled_time' => __('scheduled_time'),
            'session_type' => __('session_type'),
            'status' => __('status'),
            'amount' => __('amount'),
            'created_at' => __('created_at'),
        ];

        $path = app(ExportService::class)->exportToPdf($bookings, $columns, 'bookings', __('bookings_export'));

        $this->logExport('bookings', 'PDF');

        return response()->download($path)->deleteFileAfterSend();
    }

    public function exportPaymentsCsv(): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $payments = Payment::all();
        $columns = [
            'id' => __('id'),
            'user_email' => __('email'),
            'amount' => __('amount'),
            'currency' => __('currency'),
            'status' => __('status'),
            'payment_method' => __('payment_method'),
            'product_title' => __('product'),
            'created_at' => __('created_at'),
        ];

        $path = app(ExportService::class)->exportToCsv($payments, $columns, 'payments');

        $this->logExport('payments', 'CSV');

        return response()->download($path)->deleteFileAfterSend();
    }

    public function exportPaymentsPdf(): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $payments = Payment::all();
        $columns = [
            'id' => __('id'),
            'user_email' => __('email'),
            'amount' => __('amount'),
            'currency' => __('currency'),
            'status' => __('status'),
            'payment_method' => __('payment_method'),
            'product_title' => __('product'),
            'created_at' => __('created_at'),
        ];

        $path = app(ExportService::class)->exportToPdf($payments, $columns, 'payments', __('payments_export'));

        $this->logExport('payments', 'PDF');

        return response()->download($path)->deleteFileAfterSend();
    }

    // ─── Cleanup Actions ─────────────────────────────────────

    /**
     * Archive (delete) activity log entries older than 90 days.
     */
    public function archiveOldActivityLogs(): void
    {
        try {
            $firestore = app(FirestoreService::class);
            $cutoff = Carbon::now()->subDays(90)->toDateTimeString();

            $oldLogs = $firestore->queryCollection('activity_logs', [
                ['timestamp', '<', $cutoff],
            ]);

            $deletedCount = 0;

            foreach ($oldLogs as $log) {
                if (isset($log['id'])) {
                    $firestore->deleteDocument('activity_logs', $log['id']);
                    $deletedCount++;
                }
            }

            app(ActivityLogService::class)->log(
                'dataCleanup',
                __('archived_activity_logs', ['count' => $deletedCount]),
                ['deleted_count' => $deletedCount, 'cutoff_date' => $cutoff],
            );

            Notification::make()
                ->title(__('cleanup_complete'))
                ->body(__('archived_activity_logs', ['count' => $deletedCount]))
                ->success()
                ->send();
        } catch (\Exception $e) {
            Log::error("DataManagement::archiveOldActivityLogs failed: {$e->getMessage()}");

            Notification::make()
                ->title(__('cleanup_failed'))
                ->danger()
                ->send();
        }
    }

    // ─── Helpers ─────────────────────────────────────────────

    protected function logExport(string $collection, string $format): void
    {
        try {
            app(ActivityLogService::class)->log(
                'dataExport',
                __('exported_collection', ['collection' => $collection, 'format' => $format]),
                ['collection' => $collection, 'format' => $format],
            );
        } catch (\Exception $e) {
            Log::error("DataManagement::logExport failed: {$e->getMessage()}");
        }
    }
}
