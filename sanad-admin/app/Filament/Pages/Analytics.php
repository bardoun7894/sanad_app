<?php

namespace App\Filament\Pages;

use App\Services\AnalyticsService;
use App\Services\GeminiService;
use App\Services\UserInsightsService;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Log;

class Analytics extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-chart-bar';

    protected static ?int $navigationSort = 6;

    protected static string $view = 'filament.pages.analytics';

    public string $activeSection = 'clinical';

    public array $therapistRatings = [];

    public array $sessionVolume = [];

    public array $revenueTrends = [];

    public array $noShowRate = [];

    public array $sessionTypeDistribution = [];

    public array $clinicianPerformance = [];

    // New analytics data
    public array $retentionData = [];

    public array $engagementDistribution = [];

    public array $communityHealth = [];

    public array $challengeAnalytics = [];

    public string $aiPlatformSummary = '';

    public bool $aiLoading = false;

    public function getTitle(): string
    {
        return __('analytics');
    }

    public static function getNavigationLabel(): string
    {
        return __('analytics');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('insights');
    }

    public function mount(): void
    {
        $this->loadAnalyticsData();
    }

    protected function loadAnalyticsData(): void
    {
        try {
            $analytics = app(AnalyticsService::class);

            $this->therapistRatings = $analytics->getTherapistRatings();
            $this->sessionVolume = $analytics->getSessionVolume('monthly');
            $this->revenueTrends = $analytics->getRevenueTrends('monthly');
            $this->noShowRate = $analytics->getNoShowRate();
            $this->sessionTypeDistribution = $analytics->getSessionTypeDistribution();
            $this->clinicianPerformance = $analytics->getClinicianPerformance();
        } catch (\Exception $e) {
            Log::error("Analytics page clinical data loading failed: {$e->getMessage()}");

            $this->therapistRatings = [];
            $this->sessionVolume = [];
            $this->revenueTrends = [];
            $this->noShowRate = ['rate' => 0, 'no_show_count' => 0, 'total' => 0];
            $this->sessionTypeDistribution = [];
            $this->clinicianPerformance = [];
        }

        $this->loadExtendedAnalytics();
    }

    protected function loadExtendedAnalytics(): void
    {
        try {
            $insights = app(UserInsightsService::class);

            $this->engagementDistribution = $insights->getEngagementDistribution();
            $this->retentionData = $insights->getAtRiskUsers(20);
            $this->communityHealth = $insights->getCommunityAnalytics();
            $this->challengeAnalytics = $insights->getChallengeAnalytics();
        } catch (\Exception $e) {
            Log::error("Analytics page extended data loading failed: {$e->getMessage()}");

            $this->engagementDistribution = ['0-20' => 0, '21-40' => 0, '41-60' => 0, '61-80' => 0, '81-100' => 0];
            $this->retentionData = [];
            $this->communityHealth = [
                'total_posts_30d' => 0, 'posts_per_day' => 0, 'active_contributors' => 0,
                'total_reactions' => 0, 'avg_reactions' => 0, 'category_distribution' => [], 'daily_posts' => [],
            ];
            $this->challengeAnalytics = [
                'total_completions' => 0, 'unique_users' => 0, 'completion_rate' => 0,
                'most_popular' => [], 'streak_distribution' => [],
            ];
        }
    }

    public function generateAiPlatformSummary(): void
    {
        $this->aiLoading = true;

        try {
            $gemini = app(GeminiService::class);

            if (! empty($this->retentionData)) {
                $this->aiPlatformSummary = $gemini->generateRetentionInsights($this->retentionData);
            } else {
                $this->aiPlatformSummary = $gemini->analyzeCommunityHealth($this->communityHealth);
            }
        } catch (\Exception $e) {
            $this->aiPlatformSummary = __('ai_processing_error');
        }

        $this->aiLoading = false;
    }

    protected function getViewData(): array
    {
        return [
            'therapistRatings' => $this->therapistRatings,
            'sessionVolume' => $this->sessionVolume,
            'revenueTrends' => $this->revenueTrends,
            'noShowRate' => $this->noShowRate,
            'sessionTypeDistribution' => $this->sessionTypeDistribution,
            'clinicianPerformance' => $this->clinicianPerformance,
            'engagementDistribution' => $this->engagementDistribution,
            'retentionData' => $this->retentionData,
            'communityHealth' => $this->communityHealth,
            'challengeAnalytics' => $this->challengeAnalytics,
        ];
    }
}
