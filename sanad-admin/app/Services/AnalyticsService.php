<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class AnalyticsService
{
    public function __construct(
        protected FirestoreService $firestore,
    ) {}

    /**
     * Count active users who logged in within the last 30 days,
     * with trend comparison against the previous 30-day period.
     *
     * @return array{count: int, trend: float}
     */
    public function countActiveUsers(): array
    {
        return Cache::remember('analytics.active_users', 60, function () {
            try {
                $now = Carbon::now();
                $thirtyDaysAgo = $now->copy()->subDays(30);
                $sixtyDaysAgo = $now->copy()->subDays(60);

                $currentCount = $this->firestore->countDocuments('users', [
                    ['last_login', '>', $thirtyDaysAgo->toDateTimeString()],
                ]);

                $previousCount = $this->firestore->countDocuments('users', [
                    ['last_login', '>', $sixtyDaysAgo->toDateTimeString()],
                    ['last_login', '<=', $thirtyDaysAgo->toDateTimeString()],
                ]);

                $trend = $previousCount > 0
                    ? round((($currentCount - $previousCount) / $previousCount) * 100, 1)
                    : 0.0;

                return [
                    'count' => $currentCount,
                    'trend' => $trend,
                ];
            } catch (\Exception $e) {
                Log::error("AnalyticsService::countActiveUsers failed: {$e->getMessage()}");

                return ['count' => 0, 'trend' => 0.0];
            }
        });
    }

    /**
     * Count assessments flagged as high or critical risk.
     *
     * @return array{count: int, trend: float}
     */
    public function countCriticalFlags(): array
    {
        return Cache::remember('analytics.critical_flags', 60, function () {
            try {
                $highCount = $this->firestore->countDocuments('assessments', [
                    ['risk_level', '=', 'high'],
                ]);

                $criticalCount = $this->firestore->countDocuments('assessments', [
                    ['risk_level', '=', 'critical'],
                ]);

                $totalCount = $highCount + $criticalCount;

                // Trend: compare against count from 30+ days ago
                $thirtyDaysAgo = Carbon::now()->subDays(30);

                $previousHigh = $this->firestore->countDocuments('assessments', [
                    ['risk_level', '=', 'high'],
                    ['created_at', '<', $thirtyDaysAgo->toDateTimeString()],
                ]);

                $previousCritical = $this->firestore->countDocuments('assessments', [
                    ['risk_level', '=', 'critical'],
                    ['created_at', '<', $thirtyDaysAgo->toDateTimeString()],
                ]);

                $previousTotal = $previousHigh + $previousCritical;

                $trend = $previousTotal > 0
                    ? round((($totalCount - $previousTotal) / $previousTotal) * 100, 1)
                    : 0.0;

                return [
                    'count' => $totalCount,
                    'trend' => $trend,
                ];
            } catch (\Exception $e) {
                Log::error("AnalyticsService::countCriticalFlags failed: {$e->getMessage()}");

                return ['count' => 0, 'trend' => 0.0];
            }
        });
    }

    /**
     * Count today's scheduled sessions with trend against yesterday.
     *
     * @return array{count: int, trend: float}
     */
    public function countTodaySessions(): array
    {
        return Cache::remember('analytics.todays_sessions', 60, function () {
            try {
                $todayStart = Carbon::today()->toDateTimeString();
                $todayEnd = Carbon::tomorrow()->toDateTimeString();
                $yesterdayStart = Carbon::yesterday()->toDateTimeString();

                $todayCount = $this->firestore->countDocuments('bookings', [
                    ['scheduled_time', '>=', $todayStart],
                    ['scheduled_time', '<', $todayEnd],
                ]);

                $yesterdayCount = $this->firestore->countDocuments('bookings', [
                    ['scheduled_time', '>=', $yesterdayStart],
                    ['scheduled_time', '<', $todayStart],
                ]);

                $trend = $yesterdayCount > 0
                    ? round((($todayCount - $yesterdayCount) / $yesterdayCount) * 100, 1)
                    : 0.0;

                return [
                    'count' => $todayCount,
                    'trend' => $trend,
                ];
            } catch (\Exception $e) {
                Log::error("AnalyticsService::countTodaySessions failed: {$e->getMessage()}");

                return ['count' => 0, 'trend' => 0.0];
            }
        });
    }

    /**
     * Calculate total completed-payment earnings for the current month,
     * with trend comparison against the previous month.
     *
     * @return array{amount: float, trend: float, currency: string}
     */
    public function calculateEarnings(): array
    {
        return Cache::remember('analytics.earnings', 60, function () {
            try {
                $currentMonthStart = Carbon::now()->startOfMonth()->toDateTimeString();
                $previousMonthStart = Carbon::now()->subMonth()->startOfMonth()->toDateTimeString();
                $previousMonthEnd = Carbon::now()->startOfMonth()->toDateTimeString();

                $currentPayments = $this->firestore->queryCollection('payments', [
                    ['status', '=', 'completed'],
                    ['created_at', '>=', $currentMonthStart],
                ]);

                $currentAmount = array_sum(array_map(
                    fn (array $payment) => (float) ($payment['amount'] ?? 0),
                    $currentPayments,
                ));

                $previousPayments = $this->firestore->queryCollection('payments', [
                    ['status', '=', 'completed'],
                    ['created_at', '>=', $previousMonthStart],
                    ['created_at', '<', $previousMonthEnd],
                ]);

                $previousAmount = array_sum(array_map(
                    fn (array $payment) => (float) ($payment['amount'] ?? 0),
                    $previousPayments,
                ));

                $trend = $previousAmount > 0
                    ? round((($currentAmount - $previousAmount) / $previousAmount) * 100, 1)
                    : 0.0;

                return [
                    'amount' => round($currentAmount, 2),
                    'trend' => $trend,
                    'currency' => 'SAR',
                ];
            } catch (\Exception $e) {
                Log::error("AnalyticsService::calculateEarnings failed: {$e->getMessage()}");

                return ['amount' => 0.0, 'trend' => 0.0, 'currency' => 'SAR'];
            }
        });
    }

    /**
     * Get average ratings per therapist from the `therapists` collection (M6.4).
     *
     * Aligned with Flutter AdminAnalyticsService.fetchTherapistRatings() which
     * reads from the `therapists` collection (rating + review_count fields).
     * This avoids the N+1 pattern of fetching individual reviews + user names.
     *
     * @return array<int, array{therapist_id: string, name: string, average_rating: float, review_count: int}>
     */
    public function getTherapistRatings(): array
    {
        try {
            // M6.4: Use `therapists` collection (same as Flutter) for KPI parity
            $therapists = $this->firestore->queryCollection('therapists');

            $results = [];
            foreach ($therapists as $therapist) {
                $reviewCount = (int) ($therapist['review_count'] ?? 0);
                if ($reviewCount <= 0) {
                    continue;
                }

                $rating = (float) ($therapist['rating'] ?? 0);
                $name = $therapist['name'] ?? $therapist['full_name'] ?? 'Unknown';

                $results[] = [
                    'therapist_id' => $therapist['id'],
                    'name' => $name,
                    'average_rating' => round($rating, 2),
                    'review_count' => $reviewCount,
                ];
            }

            // Sort by average rating descending
            usort($results, fn ($a, $b) => $b['average_rating'] <=> $a['average_rating']);

            return $results;
        } catch (\Exception $e) {
            Log::error("AnalyticsService::getTherapistRatings failed: {$e->getMessage()}");

            return [];
        }
    }

    /**
     * Get session volume grouped by month or week.
     *
     * @return array<int, array{label: string, count: int}>
     */
    public function getSessionVolume(string $period = 'monthly'): array
    {
        try {
            $months = $period === 'weekly' ? 3 : 12;
            $startDate = Carbon::now()->subMonths($months)->startOfMonth()->toDateTimeString();

            $bookings = $this->firestore->queryCollection('bookings', [
                ['scheduled_time', '>=', $startDate],
            ], 'scheduled_time', 'ASC');

            $grouped = [];
            foreach ($bookings as $booking) {
                $scheduledTime = $booking['scheduled_time'] ?? null;
                if ($scheduledTime === null) {
                    continue;
                }

                $date = Carbon::parse($scheduledTime);
                $label = $period === 'weekly'
                    ? $date->startOfWeek()->format('M d')
                    : $date->format('M Y');

                if (! isset($grouped[$label])) {
                    $grouped[$label] = 0;
                }
                $grouped[$label]++;
            }

            $results = [];
            foreach ($grouped as $label => $count) {
                $results[] = [
                    'label' => $label,
                    'count' => $count,
                ];
            }

            return $results;
        } catch (\Exception $e) {
            Log::error("AnalyticsService::getSessionVolume failed: {$e->getMessage()}");

            return [];
        }
    }

    /**
     * Get revenue trends grouped by month or week.
     *
     * @return array<int, array{label: string, amount: float}>
     */
    public function getRevenueTrends(string $period = 'monthly'): array
    {
        try {
            $months = $period === 'weekly' ? 3 : 12;
            $startDate = Carbon::now()->subMonths($months)->startOfMonth()->toDateTimeString();

            $payments = $this->firestore->queryCollection('payments', [
                ['status', '=', 'completed'],
                ['created_at', '>=', $startDate],
            ], 'created_at', 'ASC');

            $grouped = [];
            foreach ($payments as $payment) {
                $createdAt = $payment['created_at'] ?? null;
                if ($createdAt === null) {
                    continue;
                }

                $date = Carbon::parse($createdAt);
                $label = $period === 'weekly'
                    ? $date->startOfWeek()->format('M d')
                    : $date->format('M Y');

                if (! isset($grouped[$label])) {
                    $grouped[$label] = 0.0;
                }
                $grouped[$label] += (float) ($payment['amount'] ?? 0);
            }

            $results = [];
            foreach ($grouped as $label => $amount) {
                $results[] = [
                    'label' => $label,
                    'amount' => round($amount, 2),
                ];
            }

            return $results;
        } catch (\Exception $e) {
            Log::error("AnalyticsService::getRevenueTrends failed: {$e->getMessage()}");

            return [];
        }
    }

    /**
     * Calculate the no-show rate across completed and no-show bookings (M6.4).
     *
     * Formula (aligned with Flutter AdminAnalyticsService.fetchNoShowRate):
     *   no_show_rate = no_show_count / (no_show_count + completed_count) * 100
     *
     * Both Flutter and Laravel now use the same denominator (no_show + completed)
     * instead of all bookings, giving a more accurate clinical no-show rate.
     *
     * @return array{rate: float, no_show_count: int, total: int}
     */
    public function getNoShowRate(): array
    {
        try {
            $noShowCount = $this->firestore->countDocuments('bookings', [
                ['status', '=', 'no_show'],
            ]);

            $completedCount = $this->firestore->countDocuments('bookings', [
                ['status', '=', 'completed'],
            ]);

            $total = $noShowCount + $completedCount;
            $rate = $total > 0
                ? round(($noShowCount / $total) * 100, 1)
                : 0.0;

            return [
                'rate' => $rate,
                'no_show_count' => $noShowCount,
                'total' => $total,
            ];
        } catch (\Exception $e) {
            Log::error("AnalyticsService::getNoShowRate failed: {$e->getMessage()}");

            return ['rate' => 0.0, 'no_show_count' => 0, 'total' => 0];
        }
    }

    /**
     * Get session type distribution across all bookings.
     *
     * @return array<int, array{type: string, count: int, percentage: float}>
     */
    public function getSessionTypeDistribution(): array
    {
        try {
            $bookings = $this->firestore->queryCollection('bookings');

            $grouped = [];
            $total = 0;

            foreach ($bookings as $booking) {
                $type = $booking['session_type'] ?? 'unknown';

                if (! isset($grouped[$type])) {
                    $grouped[$type] = 0;
                }
                $grouped[$type]++;
                $total++;
            }

            $results = [];
            foreach ($grouped as $type => $count) {
                $results[] = [
                    'type' => $type,
                    'count' => $count,
                    'percentage' => $total > 0
                        ? round(($count / $total) * 100, 1)
                        : 0.0,
                ];
            }

            // Sort by count descending
            usort($results, fn ($a, $b) => $b['count'] <=> $a['count']);

            return $results;
        } catch (\Exception $e) {
            Log::error("AnalyticsService::getSessionTypeDistribution failed: {$e->getMessage()}");

            return [];
        }
    }

    /**
     * Get clinician performance data: session count + average rating per therapist.
     *
     * M6.2: Batch-fetches therapist names from `therapists` collection instead
     * of N+1 individual getDocument() calls. Also reads ratings from `therapists`
     * collection for KPI parity with Flutter (M6.4).
     *
     * @return array<int, array{therapist_id: string, name: string, session_count: int, completed_count: int, no_show_count: int, average_rating: float, review_count: int, completion_rate: float}>
     */
    public function getClinicianPerformance(): array
    {
        try {
            $bookings = $this->firestore->queryCollection('bookings');

            // Group bookings by therapist
            $therapistSessions = [];
            foreach ($bookings as $booking) {
                $therapistId = $booking['therapist_id'] ?? null;
                if ($therapistId === null) {
                    continue;
                }

                if (! isset($therapistSessions[$therapistId])) {
                    $therapistSessions[$therapistId] = [
                        'total' => 0,
                        'completed' => 0,
                        'no_show' => 0,
                    ];
                }

                $therapistSessions[$therapistId]['total']++;

                $status = $booking['status'] ?? '';
                if ($status === 'completed') {
                    $therapistSessions[$therapistId]['completed']++;
                } elseif ($status === 'no_show') {
                    $therapistSessions[$therapistId]['no_show']++;
                }
            }

            // M6.2 + M6.4: Batch-fetch all therapist profiles in one query
            // instead of N+1 individual getDocument() calls.
            // Also reads rating/review_count from `therapists` collection
            // for KPI parity with Flutter.
            $therapists = $this->firestore->queryCollection('therapists');
            $therapistMap = [];
            foreach ($therapists as $t) {
                $therapistMap[$t['id']] = $t;
            }

            $allTherapistIds = array_unique(array_merge(
                array_keys($therapistSessions),
                array_keys($therapistMap),
            ));

            $results = [];
            foreach ($allTherapistIds as $therapistId) {
                $sessions = $therapistSessions[$therapistId] ?? ['total' => 0, 'completed' => 0, 'no_show' => 0];
                $therapistData = $therapistMap[$therapistId] ?? [];

                // M6.4: Read rating from therapists collection (same as Flutter)
                $averageRating = (float) ($therapistData['rating'] ?? 0);
                $reviewCount = (int) ($therapistData['review_count'] ?? 0);

                $completionRate = $sessions['total'] > 0
                    ? round(($sessions['completed'] / $sessions['total']) * 100, 1)
                    : 0.0;

                $name = $therapistData['name']
                    ?? $therapistData['full_name']
                    ?? $therapistData['display_name']
                    ?? 'Unknown';

                $results[] = [
                    'therapist_id' => $therapistId,
                    'name' => $name,
                    'session_count' => $sessions['total'],
                    'completed_count' => $sessions['completed'],
                    'no_show_count' => $sessions['no_show'],
                    'average_rating' => round($averageRating, 2),
                    'review_count' => $reviewCount,
                    'completion_rate' => $completionRate,
                ];
            }

            // Sort by session count descending
            usort($results, fn ($a, $b) => $b['session_count'] <=> $a['session_count']);

            return $results;
        } catch (\Exception $e) {
            Log::error("AnalyticsService::getClinicianPerformance failed: {$e->getMessage()}");

            return [];
        }
    }
}
