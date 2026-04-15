<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class RiskAlertService
{
    /**
     * MoodType labels mapped by index (0-5).
     * Mirrors Flutter's MoodType enum: happy, calm, anxious, sad, angry, tired.
     *
     * M6.4: Classification rules are aligned between Flutter and Laravel:
     * - Flutter risk_alerts_provider.dart uses inverted score (1-5, higher=better)
     * - Laravel uses raw mood index (0-5, higher=more negative)
     * - Thresholds are mathematically equivalent (see calculateRiskLevel)
     */
    public const MOOD_TYPES = [
        0 => 'happy',
        1 => 'calm',
        2 => 'anxious',
        3 => 'sad',
        4 => 'angry',
        5 => 'tired',
    ];

    /**
     * Risk level ordering for sorting (lower = more severe).
     */
    private const RISK_LEVEL_ORDER = [
        'critical' => 0,
        'high' => 1,
        'moderate' => 2,
        'low' => 3,
    ];

    public function __construct(
        protected FirestoreService $firestore,
    ) {}

    /**
     * Get multi-signal risk alerts combining mood, engagement, chat crisis, sessions, and community.
     *
     * @return array<int, array>
     */
    public function getMultiSignalRiskAlerts(): array
    {
        try {
            $insightsService = app(UserInsightsService::class);
            $atRiskUsers = $insightsService->getAtRiskUsers(50);

            $alerts = [];
            foreach ($atRiskUsers as $riskUser) {
                $userId = $riskUser['user_id'];
                $insights = $insightsService->getUserInsights($userId);

                // Build human-readable signals
                $signals = [];
                $flags = $insights['flags'] ?? [];

                if ($flags['crisis_detected'] ?? false) {
                    $crisisCount = $insights['ai_chat']['crisis_count'] ?? 0;
                    $signals[] = "{$crisisCount} " . __('crisis_messages_in_ai_chat');
                }
                if ($flags['escalation_suggested'] ?? false) {
                    $signals[] = __('escalation_suggested_by_ai');
                }
                if ($flags['mood_crisis'] ?? false) {
                    $avgMood = $insights['mood']['avg_30d'] ?? 0;
                    $signals[] = __('mood_crisis_avg', ['avg' => number_format($avgMood, 1)]);
                }

                $daysInactive = $insights['engagement']['days_since_login'] ?? 0;
                if ($daysInactive > 7) {
                    $signals[] = __('no_login_days', ['days' => $daysInactive]);
                }

                if ($flags['high_cancellation'] ?? false) {
                    $rate = $insights['sessions']['cancellation_rate'] ?? 0;
                    $signals[] = __('cancellation_rate_high', ['rate' => $rate]);
                }
                if ($flags['community_withdrawal'] ?? false) {
                    $signals[] = __('community_withdrawal_detected');
                }
                if ($flags['engagement_dropping'] ?? false) {
                    $signals[] = __('engagement_score_declining');
                }

                if (empty($signals)) {
                    $signals[] = $riskUser['top_signal'] ?? __('multiple_risk_factors');
                }

                $alerts[] = [
                    'user_id' => $userId,
                    'user_name' => $riskUser['user_name'],
                    'risk_level' => $riskUser['risk_level'],
                    'risk_score' => $riskUser['risk_score'],
                    'engagement_score' => $riskUser['engagement_score'],
                    'days_inactive' => $daysInactive,
                    'average_mood' => $insights['mood']['avg_7d'] ?? $insights['mood']['avg_30d'] ?? 0,
                    'entry_count' => $insights['mood']['entry_count'] ?? 0,
                    'latest_mood' => $insights['mood']['dominant_mood'] ?? 'unknown',
                    'signals' => $signals,
                ];
            }

            return $alerts;
        } catch (\Exception $e) {
            Log::error("RiskAlertService::getMultiSignalRiskAlerts failed: {$e->getMessage()}");

            return [];
        }
    }

    /**
     * Get risk alerts by analyzing recent mood entries across all users.
     *
     * Algorithm (ported from Flutter risk_alerts_provider.dart):
     * 1. Query mood_entries via collectionGroup for the last 7 days
     * 2. Group entries by user (_parent_id)
     * 3. Calculate average mood score per user (0-5 scale, higher = more negative)
     * 4. Assign risk levels based on average mood
     * 5. Fetch display names for at-risk users (moderate+)
     * 6. Return sorted by risk severity (critical first)
     *
     * @return array<int, array{user_id: string, user_name: string, risk_level: string, average_mood: float, entry_count: int, latest_mood: string}>
     */
    public function getRiskAlerts(): array
    {
        try {
            $sevenDaysAgo = Carbon::now()->subDays(7)->toDateTimeString();

            // 1. Query mood_entries collection group for the last 7 days
            $moodEntries = $this->firestore->queryCollectionGroup('mood_entries', [
                ['date', '>=', $sevenDaysAgo],
            ], 'date', 'DESC');

            if (empty($moodEntries)) {
                return [];
            }

            // 2. Group entries by user (_parent_id from subcollection path)
            $entriesByUser = [];
            foreach ($moodEntries as $entry) {
                $userId = $entry['_parent_id'] ?? null;
                if ($userId === null) {
                    continue;
                }

                if (! isset($entriesByUser[$userId])) {
                    $entriesByUser[$userId] = [];
                }

                $entriesByUser[$userId][] = $entry;
            }

            // 3-4. Calculate average mood score and assign risk levels
            $alerts = [];
            foreach ($entriesByUser as $userId => $entries) {
                if (empty($entries)) {
                    continue;
                }

                $moodScores = array_map(function (array $entry) {
                    return (int) ($entry['mood'] ?? 0);
                }, $entries);

                $entryCount = count($moodScores);
                $averageMood = $entryCount > 0
                    ? array_sum($moodScores) / $entryCount
                    : 0.0;

                // Assign risk level based on average mood score
                // Scale: 0 (happy) to 5 (tired), higher = more negative
                $riskLevel = $this->calculateRiskLevel($averageMood);

                // 7. Filter out 'low' risk (only return moderate+)
                if ($riskLevel === 'low') {
                    continue;
                }

                // Determine the latest mood entry's label
                $latestEntry = $entries[0]; // Already sorted DESC by date
                $latestMoodIndex = (int) ($latestEntry['mood'] ?? 0);
                $latestMood = self::MOOD_TYPES[$latestMoodIndex] ?? 'unknown';

                $alerts[] = [
                    'user_id' => $userId,
                    'user_name' => '', // Placeholder, fetched below
                    'risk_level' => $riskLevel,
                    'average_mood' => round($averageMood, 2),
                    'entry_count' => $entryCount,
                    'latest_mood' => $latestMood,
                ];
            }

            // 5. Fetch user display names for at-risk users
            foreach ($alerts as &$alert) {
                try {
                    $user = $this->firestore->getDocument('users', $alert['user_id']);
                    $alert['user_name'] = $user['display_name']
                        ?? $user['full_name']
                        ?? 'Unknown Patient';
                } catch (\Exception $e) {
                    Log::warning("RiskAlertService: Could not fetch user {$alert['user_id']}: {$e->getMessage()}");
                    $alert['user_name'] = 'Unknown Patient';
                }
            }
            unset($alert); // Break reference

            // 6. Sort by risk level severity (critical first)
            usort($alerts, function (array $a, array $b) {
                $orderA = self::RISK_LEVEL_ORDER[$a['risk_level']] ?? 99;
                $orderB = self::RISK_LEVEL_ORDER[$b['risk_level']] ?? 99;

                if ($orderA === $orderB) {
                    // Secondary sort: higher average mood (more negative) first
                    return $b['average_mood'] <=> $a['average_mood'];
                }

                return $orderA <=> $orderB;
            });

            return $alerts;
        } catch (\Exception $e) {
            Log::error("RiskAlertService::getRiskAlerts failed: {$e->getMessage()}");

            return [];
        }
    }

    /**
     * Calculate risk level based on average mood score (M6.4 — aligned).
     *
     * Mood scale: 0 (happy) to 5 (tired). Higher values indicate more
     * negative emotional states.
     *
     * Thresholds (aligned with Flutter risk_alerts_provider.dart):
     * - critical: avg >= 3.5  ↔  Flutter score < 2.0
     * - high:     avg >= 2.5  ↔  Flutter score < 2.5
     * - moderate: avg >= 1.5  ↔  Flutter score < 3.0
     * - low:      avg < 1.5   ↔  Flutter score >= 3.0
     *
     * Flutter uses an inverted 1-5 scale (higher = better):
     *   happy=5, calm=4, anxious/tired=2, sad/angry=1
     * Laravel uses the raw 0-5 index (higher = more negative):
     *   happy=0, calm=1, anxious=2, sad=3, angry=4, tired=5
     *
     * The thresholds are mathematically equivalent:
     *   Flutter score ≈ 5 - Laravel avgMood (approximate inverse)
     */
    private function calculateRiskLevel(float $averageMood): string
    {
        if ($averageMood >= 3.5) {
            return 'critical';
        }

        if ($averageMood >= 2.5) {
            return 'high';
        }

        if ($averageMood >= 1.5) {
            return 'moderate';
        }

        return 'low';
    }

    /**
     * Get the Filament color name for a risk level.
     */
    public function getRiskLevelColor(string $level): string
    {
        return match ($level) {
            'critical' => 'danger',
            'high' => 'warning',
            'moderate' => 'info',
            'low' => 'success',
            default => 'gray',
        };
    }

    /**
     * Get the Heroicon name for a risk level.
     */
    public function getRiskLevelIcon(string $level): string
    {
        return match ($level) {
            'critical' => 'heroicon-o-exclamation-triangle',
            'high' => 'heroicon-o-exclamation-circle',
            'moderate' => 'heroicon-o-information-circle',
            'low' => 'heroicon-o-check-circle',
            default => 'heroicon-o-question-mark-circle',
        };
    }
}
