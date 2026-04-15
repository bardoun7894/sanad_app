<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use App\Models\Assessment;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\SubscriptionProduct;
use App\Models\User;
use App\Services\ActivityLogService;
use App\Services\FirestoreService;
use App\Services\GeminiService;
use App\Services\UserInsightsService;
use Filament\Actions;
use Filament\Forms\Components\Select;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\Page;
use Illuminate\Support\Facades\Auth;

class ViewUser extends Page
{
    protected static string $resource = UserResource::class;

    protected static string $view = 'filament.resources.user-resource.pages.view-user';

    public ?string $record = null;

    public ?User $user = null;

    public string $activeTab = 'overview';

    public array $userInsights = [];

    public string $aiAnalysis = '';

    public bool $aiLoading = false;

    public function mount(string|User $record): void
    {
        $recordId = $record instanceof User ? $record->getKey() : $record;
        $this->record = $recordId;
        $this->user = $record instanceof User ? $record : User::find($record);

        if (! $this->user) {
            abort(404);
        }

        try {
            $this->userInsights = app(UserInsightsService::class)->getUserInsights($this->record);
        } catch (\Exception $e) {
            $this->userInsights = [];
        }
    }

    public function getTitle(): string
    {
        return $this->user?->getDisplayName() ?? __('view').' '.__('user');
    }

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('edit')
                ->label(__('edit_user'))
                ->url(UserResource::getUrl('edit', ['record' => $this->record]))
                ->icon('heroicon-o-pencil'),
            Actions\Action::make('assign_subscription')
                ->label(__('assign_subscription'))
                ->icon('heroicon-o-credit-card')
                ->form([
                    Select::make('product_id')
                        ->label(__('select_plan'))
                        ->options(function () {
                            $products = SubscriptionProduct::all();

                            return collect($products)->mapWithKeys(
                                fn ($p) => [$p->getKey() => $p->safeGet('title').' - '.$p->safeGet('price')]
                            );
                        })
                        ->required(),
                    Select::make('duration')
                        ->label(__('select_duration'))
                        ->options([
                            '7' => __('days_7'),
                            '30' => __('days_30'),
                            '90' => __('days_90'),
                            '365' => __('days_365'),
                        ])
                        ->required(),
                ])
                ->action(function (array $data) {
                    $admin = Auth::user();
                    $adminId = $admin?->getKey() ?? 'system';

                    $service = app(FirestoreService::class);
                    $product = SubscriptionProduct::find($data['product_id']);
                    $duration = (int) $data['duration'];
                    $expiry = now()->addDays($duration);

                    $service->updateDocument('users', $this->record, [
                        'is_premium' => true,
                        'subscription_status' => 'active',
                        'subscription_plan' => $data['product_id'],
                        'productId' => $data['product_id'], // Added for Flutter compatibility
                        'subscription_product_title' => $product?->safeGet('title', 'Premium'),
                        'subscription_expiry_date' => FirestoreService::timestamp($expiry),
                        'subscription_start_date' => FirestoreService::now(),
                        'subscription_assigned_by' => $adminId,
                        'subscription_assigned_at' => FirestoreService::now(),
                        'payment_gateway' => 'admin_grant',
                        'premium_updated_at' => FirestoreService::now(),
                    ]);

                    app(ActivityLogService::class)->log(
                        'subscriptionAssigned',
                        "Assigned subscription to {$this->user->getDisplayName()} for {$duration} days",
                        ['user_id' => $this->record, 'product_id' => $data['product_id'], 'duration' => $duration, 'actor_uid' => $adminId]
                    );

                    Notification::make()->success()->title(__('subscription_activated'))->send();
                    $this->user = User::find($this->record);
                }),
            Actions\Action::make('revoke_subscription')
                ->label(__('revoke_subscription'))
                ->icon('heroicon-o-x-circle')
                ->color('danger')
                ->requiresConfirmation()
                ->action(function () {
                    $admin = Auth::user();
                    $adminId = $admin?->getKey() ?? 'system';

                    $service = app(FirestoreService::class);
                    $service->updateDocument('users', $this->record, [
                        'is_premium' => false,
                        'subscription_status' => 'cancelled',
                        'subscription_revoked_at' => FirestoreService::now(),
                        'subscription_revoked_by' => $adminId,
                        'premium_updated_at' => FirestoreService::now(),
                    ]);

                    app(ActivityLogService::class)->log(
                        'subscriptionRevoked',
                        "Revoked subscription for {$this->user->getDisplayName()}",
                        ['user_id' => $this->record, 'actor_uid' => $adminId]
                    );

                    Notification::make()->success()->title(__('subscription_revoked'))->send();
                    $this->user = User::find($this->record);
                })
                ->visible(fn () => $this->user?->isSubscriptionActive()),
        ];
    }

    public function getUserBookings(): array
    {
        try {
            return Booking::all(
                wheres: [['client_id', '=', $this->record]],
                orderBy: 'scheduled_time',
                direction: 'DESC',
                limit: 20,
            );
        } catch (\Exception $e) {
            return [];
        }
    }

    public function getUserAssessments(): array
    {
        try {
            return Assessment::all(
                wheres: [['user_id', '=', $this->record]],
                orderBy: 'created_at',
                direction: 'DESC',
                limit: 20,
            );
        } catch (\Exception $e) {
            return [];
        }
    }

    public function getUserPayments(): array
    {
        try {
            return Payment::all(
                wheres: [['user_id', '=', $this->record]],
                orderBy: 'created_at',
                direction: 'DESC',
                limit: 20,
            );
        } catch (\Exception $e) {
            return [];
        }
    }

    public function generateAiAnalysis(): void
    {
        $this->aiLoading = true;

        try {
            if (empty($this->userInsights)) {
                $this->userInsights = app(UserInsightsService::class)->getUserInsights($this->record);
            }

            $this->aiAnalysis = app(GeminiService::class)->analyzeUser($this->userInsights);
        } catch (\Exception $e) {
            $this->aiAnalysis = __('ai_processing_error');
        }

        $this->aiLoading = false;
    }

    public function getUserMoodChartData(): array
    {
        $entries = $this->userInsights['mood']['entries'] ?? [];
        $labels = [];
        $data = [];

        foreach (array_reverse($entries) as $entry) {
            $date = substr($entry['date'] ?? '', 0, 10);
            $labels[] = $date;
            $data[] = (int) ($entry['mood'] ?? 0);
        }

        return ['labels' => $labels, 'data' => $data];
    }

    public function getMoodDistribution(): array
    {
        $entries = $this->userInsights['mood']['entries'] ?? [];
        $counts = [];

        foreach ($entries as $entry) {
            $mood = (int) ($entry['mood'] ?? 0);
            $label = \App\Services\RiskAlertService::MOOD_TYPES[$mood] ?? 'unknown';
            $counts[$label] = ($counts[$label] ?? 0) + 1;
        }

        return $counts;
    }

    public function getUserCommunityPosts(): array
    {
        try {
            $firestore = app(FirestoreService::class);

            return $firestore->queryCollection('posts', [
                ['author_id', '=', $this->record],
            ], null, 'DESC', 20);
        } catch (\Exception $e) {
            return [];
        }
    }

    public function getUserChallengeCompletions(): array
    {
        return $this->userInsights['challenges']['recent'] ?? [];
    }
}
