<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class UserInsightsService
{
    public function __construct(
        protected FirestoreService $firestore,
    ) {}

    /**
     * Get comprehensive insights for a single user.
     */
    public function getUserInsights(string $userId): array
    {
        return Cache::remember("user_insights_{$userId}", 300, function () use ($userId) {
            try {
                $profile = $this->firestore->getDocument('users', $userId);
                $moodEntries = $this->fetchMoodEntries($userId);
                $bookings = $this->fetchBookings($userId);
                $posts = $this->fetchCommunityPosts($userId);
                $aiMessages = $this->fetchAiChatMessages($userId);
                $challengeCompletions = $this->fetchChallengeCompletions($userId);
                $assessments = $this->fetchAssessments($userId);

                $mood = $this->analyzeMood($moodEntries);
                $sessions = $this->analyzeSessions($bookings);
                $community = $this->analyzeCommunity($posts);
                $aiChat = $this->analyzeAiChat($aiMessages);
                $tests = $this->analyzeTests($assessments);
                $challenges = $this->analyzeChallenges($challengeCompletions);
                $engagement = $this->calculateEngagement($profile, $moodEntries, $bookings, $posts, $challengeCompletions);
                $retention = $this->calculateRetention($profile, $engagement, $mood, $sessions);
                $flags = $this->detectFlags($mood, $aiChat, $sessions, $community, $engagement);

                return [
                    'user_id' => $userId,
                    'profile' => $profile,
                    'mood' => $mood,
                    'engagement' => $engagement,
                    'retention' => $retention,
                    'sessions' => $sessions,
                    'flags' => $flags,
                    'community' => $community,
                    'ai_chat' => $aiChat,
                    'tests' => $tests,
                    'challenges' => $challenges,
                ];
            } catch (\Exception $e) {
                Log::error("UserInsightsService::getUserInsights failed for {$userId}: {$e->getMessage()}");

                return $this->emptyInsights($userId);
            }
        });
    }

    /**
     * Get engagement score distribution across all users.
     *
     * M6.2: Optimized to compute lightweight engagement scores directly
     * from user profile fields (last_login, current_streak) instead of
     * calling getUserInsights() per user (which triggers 6+ sub-queries each).
     */
    public function getEngagementDistribution(): array
    {
        return Cache::remember('engagement_distribution', 900, function () {
            try {
                $users = $this->firestore->queryCollection('users', [], null, 'DESC', 500);
                $brackets = ['0-20' => 0, '21-40' => 0, '41-60' => 0, '61-80' => 0, '81-100' => 0];

                $now = Carbon::now();

                foreach ($users as $user) {
                    $userId = $user['id'] ?? null;
                    if (! $userId || ($user['role'] ?? 'user') !== 'user') {
                        continue;
                    }

                    // M6.2: Lightweight engagement estimate from profile fields
                    // instead of full getUserInsights() which causes N+1 queries.
                    $score = $this->estimateEngagementScore($user, $now);

                    if ($score <= 20) {
                        $brackets['0-20']++;
                    } elseif ($score <= 40) {
                        $brackets['21-40']++;
                    } elseif ($score <= 60) {
                        $brackets['41-60']++;
                    } elseif ($score <= 80) {
                        $brackets['61-80']++;
                    } else {
                        $brackets['81-100']++;
                    }
                }

                return $brackets;
            } catch (\Exception $e) {
                Log::error("UserInsightsService::getEngagementDistribution failed: {$e->getMessage()}");

                return ['0-20' => 0, '21-40' => 0, '41-60' => 0, '61-80' => 0, '81-100' => 0];
            }
        });
    }

    /**
     * Get users sorted by retention risk (critical first).
     *
     * M6.2: First pass uses lightweight risk estimation from profile fields
     * to identify candidates. Only fetches full insights for the top candidates.
     */
    public function getAtRiskUsers(int $limit = 50): array
    {
        return Cache::remember("at_risk_users_{$limit}", 900, function () use ($limit) {
            try {
                $users = $this->firestore->queryCollection('users', [], null, 'DESC', 500);
                $now = Carbon::now();

                // M6.2: First pass — lightweight risk estimation (no sub-queries)
                $candidates = [];
                foreach ($users as $user) {
                    $userId = $user['id'] ?? null;
                    if (! $userId || ($user['role'] ?? 'user') !== 'user') {
                        continue;
                    }

                    $riskEstimate = $this->estimateRiskScore($user, $now);
                    if ($riskEstimate >= 30) { // Slightly lower threshold to catch edge cases
                        $candidates[] = [
                            'user' => $user,
                            'risk_estimate' => $riskEstimate,
                        ];
                    }
                }

                // Sort by estimated risk descending, take top candidates
                usort($candidates, fn ($a, $b) => $b['risk_estimate'] <=> $a['risk_estimate']);
                $topCandidates = array_slice($candidates, 0, min($limit * 2, 100));

                // M6.2: Second pass — full insights only for top candidates
                $riskUsers = [];
                foreach ($topCandidates as $candidate) {
                    $user = $candidate['user'];
                    $userId = $user['id'];

                    $insights = $this->getUserInsights($userId);
                    $riskScore = $insights['retention']['risk_score'] ?? 0;

                    if ($riskScore >= 35) {
                        $riskUsers[] = [
                            'user_id' => $userId,
                            'user_name' => $user['display_name'] ?? $user['full_name'] ?? __('unknown_user'),
                            'risk_level' => $insights['retention']['risk_level'],
                            'risk_score' => $riskScore,
                            'engagement_score' => $insights['engagement']['score'] ?? 0,
                            'top_signal' => $insights['retention']['risk_factors'][0] ?? '-',
                            'days_inactive' => $insights['retention']['days_since_last_login'] ?? 0,
                            'flags' => $insights['flags'],
                        ];
                    }
                }

                usort($riskUsers, fn ($a, $b) => $b['risk_score'] <=> $a['risk_score']);

                return array_slice($riskUsers, 0, $limit);
            } catch (\Exception $e) {
                Log::error("UserInsightsService::getAtRiskUsers failed: {$e->getMessage()}");

                return [];
            }
        });
    }

    /**
     * Get community-wide analytics.
     */
    public function getCommunityAnalytics(): array
    {
        return Cache::remember('community_analytics', 900, function () {
            try {
                $thirtyDaysAgo = Carbon::now()->subDays(30)->toDateTimeString();
                $posts = $this->firestore->queryCollection('posts', [
                    ['created_at', '>=', $thirtyDaysAgo],
                ], 'created_at', 'DESC', 500);

                $totalPosts = count($posts);
                $postsPerDay = $totalPosts > 0 ? round($totalPosts / 30, 1) : 0;

                $authors = [];
                $categories = [];
                $totalReactions = 0;
                $dailyPosts = [];

                foreach ($posts as $post) {
                    $authorId = $post['author_id'] ?? $post['userId'] ?? null;
                    if ($authorId) {
                        $authors[$authorId] = true;
                    }

                    $category = $post['category'] ?? 'general';
                    $categories[$category] = ($categories[$category] ?? 0) + 1;

                    $reactions = $post['reactions_count'] ?? $post['likes'] ?? 0;
                    if (is_array($reactions)) {
                        $reactions = count($reactions);
                    }
                    $totalReactions += (int) $reactions;

                    $date = substr($post['created_at'] ?? '', 0, 10);
                    if ($date) {
                        $dailyPosts[$date] = ($dailyPosts[$date] ?? 0) + 1;
                    }
                }

                return [
                    'total_posts_30d' => $totalPosts,
                    'posts_per_day' => $postsPerDay,
                    'active_contributors' => count($authors),
                    'total_reactions' => $totalReactions,
                    'avg_reactions' => $totalPosts > 0 ? round($totalReactions / $totalPosts, 1) : 0,
                    'category_distribution' => $categories,
                    'daily_posts' => $dailyPosts,
                ];
            } catch (\Exception $e) {
                Log::error("UserInsightsService::getCommunityAnalytics failed: {$e->getMessage()}");

                return [
                    'total_posts_30d' => 0, 'posts_per_day' => 0, 'active_contributors' => 0,
                    'total_reactions' => 0, 'avg_reactions' => 0, 'category_distribution' => [], 'daily_posts' => [],
                ];
            }
        });
    }

    /**
     * Get challenge analytics.
     */
    public function getChallengeAnalytics(): array
    {
        return Cache::remember('challenge_analytics', 900, function () {
            try {
                $completions = $this->firestore->queryCollectionGroup('challenge_completions', [], null, 'DESC', 500);
                $totalCompletions = count($completions);

                $challengeCounts = [];
                $userStreaks = [];

                foreach ($completions as $completion) {
                    $name = $completion['challenge_name'] ?? $completion['title'] ?? 'Unknown';
                    $challengeCounts[$name] = ($challengeCounts[$name] ?? 0) + 1;

                    $userId = $completion['_parent_id'] ?? null;
                    if ($userId) {
                        $userStreaks[$userId] = ($userStreaks[$userId] ?? 0) + 1;
                    }
                }

                arsort($challengeCounts);
                $popular = array_slice($challengeCounts, 0, 5, true);

                $streakBrackets = ['1-3' => 0, '4-7' => 0, '8-14' => 0, '15-30' => 0, '30+' => 0];
                foreach ($userStreaks as $count) {
                    if ($count <= 3) {
                        $streakBrackets['1-3']++;
                    } elseif ($count <= 7) {
                        $streakBrackets['4-7']++;
                    } elseif ($count <= 14) {
                        $streakBrackets['8-14']++;
                    } elseif ($count <= 30) {
                        $streakBrackets['15-30']++;
                    } else {
                        $streakBrackets['30+']++;
                    }
                }

                return [
                    'total_completions' => $totalCompletions,
                    'unique_users' => count($userStreaks),
                    'completion_rate' => count($userStreaks) > 0 ? round($totalCompletions / count($userStreaks), 1) : 0,
                    'most_popular' => $popular,
                    'streak_distribution' => $streakBrackets,
                ];
            } catch (\Exception $e) {
                Log::error("UserInsightsService::getChallengeAnalytics failed: {$e->getMessage()}");

                return [
                    'total_completions' => 0, 'unique_users' => 0, 'completion_rate' => 0,
                    'most_popular' => [], 'streak_distribution' => [],
                ];
            }
        });
    }

    // ──────────────────────────────────────────────────────────────
    // Data Fetching
    // ──────────────────────────────────────────────────────────────

    private function fetchMoodEntries(string $userId): array
    {
        try {
            $ninetyDaysAgo = Carbon::now()->subDays(90)->toDateTimeString();

            return $this->firestore->getSubcollection('users', $userId, 'mood_entries', [
                ['date', '>=', $ninetyDaysAgo],
            ], 'date', 'DESC', 200);
        } catch (\Exception $e) {
            return [];
        }
    }

    private function fetchBookings(string $userId): array
    {
        try {
            return $this->firestore->queryCollection('bookings', [
                ['client_id', '=', $userId],
            ], null, 'DESC', 100);
        } catch (\Exception $e) {
            return [];
        }
    }

    private function fetchCommunityPosts(string $userId): array
    {
        try {
            return $this->firestore->queryCollection('posts', [
                ['author_id', '=', $userId],
            ], null, 'DESC', 50);
        } catch (\Exception $e) {
            return [];
        }
    }

    private function fetchAiChatMessages(string $userId): array
    {
        try {
            return $this->firestore->getSubcollection('ai_chats', $userId, 'messages', [], null, 'DESC', 50);
        } catch (\Exception $e) {
            return [];
        }
    }

    private function fetchChallengeCompletions(string $userId): array
    {
        try {
            return $this->firestore->getSubcollection('users', $userId, 'challenge_completions', [], null, 'DESC', 30);
        } catch (\Exception $e) {
            return [];
        }
    }

    private function fetchAssessments(string $userId): array
    {
        try {
            return $this->firestore->queryCollection('assessments', [
                ['user_id', '=', $userId],
            ], null, 'DESC', 20);
        } catch (\Exception $e) {
            return [];
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Analysis Methods
    // ──────────────────────────────────────────────────────────────

    private function analyzeMood(array $entries): array
    {
        if (empty($entries)) {
            return [
                'avg_7d' => null, 'avg_30d' => null, 'avg_90d' => null,
                'trend' => 'unknown', 'dominant_mood' => null,
                'logging_frequency' => 0, 'entry_count' => 0, 'entries' => [],
            ];
        }

        $now = Carbon::now();
        $scores7d = [];
        $scores30d = [];
        $scores90d = [];
        $moodCounts = [];

        foreach ($entries as $entry) {
            $mood = (int) ($entry['mood'] ?? 0);
            $date = $entry['date'] ?? '';
            $moodLabel = RiskAlertService::MOOD_TYPES[$mood] ?? 'unknown';
            $moodCounts[$moodLabel] = ($moodCounts[$moodLabel] ?? 0) + 1;

            try {
                $entryDate = Carbon::parse($date);
                $daysAgo = $now->diffInDays($entryDate);

                if ($daysAgo <= 7) {
                    $scores7d[] = $mood;
                }
                if ($daysAgo <= 30) {
                    $scores30d[] = $mood;
                }
                $scores90d[] = $mood;
            } catch (\Exception $e) {
                $scores90d[] = $mood;
            }
        }

        $avg7d = count($scores7d) > 0 ? round(array_sum($scores7d) / count($scores7d), 2) : null;
        $avg30d = count($scores30d) > 0 ? round(array_sum($scores30d) / count($scores30d), 2) : null;
        $avg90d = count($scores90d) > 0 ? round(array_sum($scores90d) / count($scores90d), 2) : null;

        // Trend: compare first half vs second half of entries
        $trend = 'stable';
        if (count($scores30d) >= 4) {
            $mid = (int) (count($scores30d) / 2);
            $recentHalf = array_slice($scores30d, 0, $mid);
            $olderHalf = array_slice($scores30d, $mid);
            $recentAvg = array_sum($recentHalf) / count($recentHalf);
            $olderAvg = array_sum($olderHalf) / count($olderHalf);

            if ($recentAvg < $olderAvg - 0.3) {
                $trend = 'improving';
            } elseif ($recentAvg > $olderAvg + 0.3) {
                $trend = 'declining';
            }
        }

        arsort($moodCounts);
        $dominantMood = array_key_first($moodCounts);

        $weeksInPeriod = max(1, count($scores30d) > 0 ? 4 : 1);
        $loggingFrequency = round(count($scores30d) / $weeksInPeriod, 1);

        return [
            'avg_7d' => $avg7d,
            'avg_30d' => $avg30d,
            'avg_90d' => $avg90d,
            'trend' => $trend,
            'dominant_mood' => $dominantMood,
            'logging_frequency' => $loggingFrequency,
            'entry_count' => count($entries),
            'entries' => array_slice($entries, 0, 30),
        ];
    }

    private function analyzeSessions(array $bookings): array
    {
        $total = count($bookings);
        $completed = 0;
        $cancelled = 0;
        $noShow = 0;

        foreach ($bookings as $booking) {
            $status = $booking['status'] ?? '';
            match ($status) {
                'completed' => $completed++,
                'cancelled' => $cancelled++,
                'no_show' => $noShow++,
                default => null,
            };
        }

        return [
            'total' => $total,
            'completed' => $completed,
            'cancelled' => $cancelled,
            'no_show' => $noShow,
            'completion_rate' => $total > 0 ? round(($completed / $total) * 100, 1) : 0,
            'cancellation_rate' => $total > 0 ? round(($cancelled / $total) * 100, 1) : 0,
            'recent' => array_slice($bookings, 0, 10),
        ];
    }

    private function analyzeCommunity(array $posts): array
    {
        $totalReactions = 0;
        $categories = [];
        $lastPostDate = null;

        foreach ($posts as $post) {
            $reactions = $post['reactions_count'] ?? $post['likes'] ?? 0;
            if (is_array($reactions)) {
                $reactions = count($reactions);
            }
            $totalReactions += (int) $reactions;

            $cat = $post['category'] ?? 'general';
            $categories[$cat] = ($categories[$cat] ?? 0) + 1;

            if (! $lastPostDate) {
                $lastPostDate = $post['created_at'] ?? null;
            }
        }

        $isActiveContributor = false;
        if ($lastPostDate) {
            try {
                $isActiveContributor = Carbon::parse($lastPostDate)->isAfter(Carbon::now()->subDays(14));
            } catch (\Exception $e) {
            }
        }

        return [
            'posts_count' => count($posts),
            'reactions_received' => $totalReactions,
            'categories_used' => $categories,
            'last_post_date' => $lastPostDate,
            'is_active_contributor' => $isActiveContributor,
        ];
    }

    private function analyzeAiChat(array $messages): array
    {
        $crisisCount = 0;
        $escalationCount = 0;
        $moodsDetected = [];

        foreach ($messages as $msg) {
            if (($msg['crisis_detected'] ?? false) || ($msg['is_crisis'] ?? false)) {
                $crisisCount++;
            }
            if (($msg['escalation_suggested'] ?? false) || ($msg['needs_escalation'] ?? false)) {
                $escalationCount++;
            }
            $mood = $msg['detected_mood'] ?? $msg['mood'] ?? null;
            if ($mood) {
                $moodsDetected[$mood] = ($moodsDetected[$mood] ?? 0) + 1;
            }
        }

        return [
            'message_count' => count($messages),
            'crisis_count' => $crisisCount,
            'escalation_count' => $escalationCount,
            'moods_detected' => $moodsDetected,
        ];
    }

    private function analyzeTests(array $assessments): array
    {
        if (empty($assessments)) {
            return [
                'completed_count' => 0,
                'latest_risk_level' => null,
                'latest_score' => null,
                'recent' => [],
            ];
        }

        $latest = $assessments[0];

        return [
            'completed_count' => count($assessments),
            'latest_risk_level' => $latest['risk_level'] ?? null,
            'latest_score' => $latest['score'] ?? null,
            'recent' => array_slice($assessments, 0, 5),
        ];
    }

    private function analyzeChallenges(array $completions): array
    {
        return [
            'completions_count' => count($completions),
            'recent' => array_slice($completions, 0, 10),
        ];
    }

    // ──────────────────────────────────────────────────────────────
    // Composite Scores
    // ──────────────────────────────────────────────────────────────

    private function calculateEngagement(array $profile, array $moodEntries, array $bookings, array $posts, array $challengeCompletions): array
    {
        // Login recency: 30% (0-30 pts)
        $lastLogin = $profile['last_login'] ?? null;
        $daysSinceLogin = 999;
        if ($lastLogin) {
            try {
                $daysSinceLogin = Carbon::parse($lastLogin)->diffInDays(Carbon::now());
            } catch (\Exception $e) {
            }
        }
        $loginScore = max(0, 30 - $daysSinceLogin);

        // Mood logging: 25% (based on entries/week in last 30d)
        $now = Carbon::now();
        $moodEntriesLast30d = 0;
        foreach ($moodEntries as $entry) {
            try {
                if (Carbon::parse($entry['date'] ?? '')->isAfter($now->copy()->subDays(30))) {
                    $moodEntriesLast30d++;
                }
            } catch (\Exception $e) {
            }
        }
        $entriesPerWeek = $moodEntriesLast30d / 4;
        $moodScore = min(25, round($entriesPerWeek * 5));

        // Session attendance: 20%
        $completedSessions = 0;
        foreach ($bookings as $b) {
            if (($b['status'] ?? '') === 'completed') {
                $completedSessions++;
            }
        }
        $sessionScore = min(20, $completedSessions * 4);

        // Challenge completion: 15%
        $recentChallenges = 0;
        foreach ($challengeCompletions as $c) {
            try {
                $completedAt = $c['completed_at'] ?? $c['created_at'] ?? '';
                if ($completedAt && Carbon::parse($completedAt)->isAfter($now->copy()->subDays(30))) {
                    $recentChallenges++;
                }
            } catch (\Exception $e) {
            }
        }
        $challengeScore = min(15, $recentChallenges * 3);

        // Community activity: 10%
        $recentPosts = 0;
        foreach ($posts as $p) {
            try {
                if (Carbon::parse($p['created_at'] ?? '')->isAfter($now->copy()->subDays(30))) {
                    $recentPosts++;
                }
            } catch (\Exception $e) {
            }
        }
        $communityScore = min(10, $recentPosts * 2);

        $totalScore = $loginScore + $moodScore + $sessionScore + $challengeScore + $communityScore;

        // Streak data
        $currentStreak = (int) ($profile['current_streak'] ?? $profile['streak'] ?? 0);
        $longestStreak = (int) ($profile['longest_streak'] ?? 0);

        // Activity trend
        $activityTrend = 'stable';
        if ($daysSinceLogin > 14) {
            $activityTrend = 'declining';
        } elseif ($totalScore >= 60) {
            $activityTrend = 'active';
        }

        return [
            'score' => min(100, max(0, $totalScore)),
            'current_streak' => $currentStreak,
            'longest_streak' => $longestStreak,
            'last_activity' => $lastLogin,
            'days_since_login' => $daysSinceLogin,
            'activity_trend' => $activityTrend,
            'feature_usage' => [
                'mood' => $moodEntriesLast30d > 0,
                'sessions' => $completedSessions > 0,
                'community' => $recentPosts > 0,
                'ai_chat' => false, // set by caller if needed
                'challenges' => $recentChallenges > 0,
            ],
        ];
    }

    private function calculateRetention(array $profile, array $engagement, array $mood, array $sessions): array
    {
        $riskScore = 0;
        $riskFactors = [];

        // Days inactive: 30% weight
        $daysSinceLogin = $engagement['days_since_login'] ?? 999;
        $inactiveScore = min(100, $daysSinceLogin * 3);
        $riskScore += $inactiveScore * 0.30;
        if ($daysSinceLogin > 7) {
            $riskFactors[] = __('no_login_days', ['days' => $daysSinceLogin]);
        }

        // Engagement trend: 25% weight
        $engagementScore = $engagement['score'] ?? 0;
        $engagementRisk = max(0, 100 - $engagementScore);
        $riskScore += $engagementRisk * 0.25;
        if ($engagementScore < 30) {
            $riskFactors[] = __('low_engagement_score', ['score' => $engagementScore]);
        }

        // Mood trend: 20% weight
        $moodAvg = $mood['avg_30d'] ?? null;
        $moodRisk = 0;
        if ($moodAvg !== null) {
            $moodRisk = min(100, $moodAvg * 20);
        }
        $riskScore += $moodRisk * 0.20;
        if ($moodAvg !== null && $moodAvg >= 3.0) {
            $riskFactors[] = __('high_avg_mood', ['mood' => number_format($moodAvg, 1)]);
        }

        // Cancellation rate: 15% weight
        $cancellationRate = $sessions['cancellation_rate'] ?? 0;
        $riskScore += $cancellationRate * 0.15;
        if ($cancellationRate > 40) {
            $riskFactors[] = __('high_cancellation_rate', ['rate' => $cancellationRate]);
        }

        // Subscription status: 10% weight
        $subStatus = $profile['subscription_status'] ?? 'free';
        $subRisk = match ($subStatus) {
            'active' => 0,
            'expired' => 60,
            'cancelled' => 80,
            default => 40,
        };
        $riskScore += $subRisk * 0.10;
        if (in_array($subStatus, ['expired', 'cancelled'])) {
            $riskFactors[] = __('subscription_at_risk', ['status' => $subStatus]);
        }

        $riskScore = min(100, max(0, round($riskScore)));

        if ($riskScore >= 75) {
            $riskLevel = 'critical';
        } elseif ($riskScore >= 55) {
            $riskLevel = 'high';
        } elseif ($riskScore >= 35) {
            $riskLevel = 'moderate';
        } else {
            $riskLevel = 'low';
        }

        return [
            'risk_level' => $riskLevel,
            'risk_score' => $riskScore,
            'risk_factors' => $riskFactors,
            'days_since_last_login' => $daysSinceLogin,
        ];
    }

    private function detectFlags(array $mood, array $aiChat, array $sessions, array $community, array $engagement): array
    {
        return [
            'crisis_detected' => ($aiChat['crisis_count'] ?? 0) > 0,
            'escalation_suggested' => ($aiChat['escalation_count'] ?? 0) > 0,
            'high_cancellation' => ($sessions['cancellation_rate'] ?? 0) > 40,
            'community_withdrawal' => ($community['is_active_contributor'] ?? false) === false && ($community['posts_count'] ?? 0) > 3,
            'mood_crisis' => ($mood['avg_30d'] ?? 0) >= 3.5,
            'engagement_dropping' => ($engagement['activity_trend'] ?? '') === 'declining',
        ];
    }

    private function emptyInsights(string $userId): array
    {
        return [
            'user_id' => $userId,
            'profile' => [],
            'mood' => ['avg_7d' => null, 'avg_30d' => null, 'avg_90d' => null, 'trend' => 'unknown', 'dominant_mood' => null, 'logging_frequency' => 0, 'entry_count' => 0, 'entries' => []],
            'engagement' => ['score' => 0, 'current_streak' => 0, 'longest_streak' => 0, 'last_activity' => null, 'days_since_login' => 999, 'activity_trend' => 'unknown', 'feature_usage' => ['mood' => false, 'sessions' => false, 'community' => false, 'ai_chat' => false, 'challenges' => false]],
            'retention' => ['risk_level' => 'unknown', 'risk_score' => 0, 'risk_factors' => [], 'days_since_last_login' => 0],
            'sessions' => ['total' => 0, 'completed' => 0, 'cancelled' => 0, 'no_show' => 0, 'completion_rate' => 0, 'cancellation_rate' => 0, 'recent' => []],
            'flags' => ['crisis_detected' => false, 'escalation_suggested' => false, 'high_cancellation' => false, 'community_withdrawal' => false, 'mood_crisis' => false, 'engagement_dropping' => false],
            'community' => ['posts_count' => 0, 'reactions_received' => 0, 'categories_used' => [], 'last_post_date' => null, 'is_active_contributor' => false],
            'ai_chat' => ['message_count' => 0, 'crisis_count' => 0, 'escalation_count' => 0, 'moods_detected' => []],
            'tests' => ['completed_count' => 0, 'latest_risk_level' => null, 'latest_score' => null, 'recent' => []],
            'challenges' => ['completions_count' => 0, 'recent' => []],
        ];
    }


    // ──────────────────────────────────────────────────────────────
    // M6.2: Lightweight Estimation Helpers (avoid N+1 sub-queries)
    // ──────────────────────────────────────────────────────────────

    /**
     * Estimate engagement score from user profile fields only (no sub-queries).
     *
     * This is a lightweight approximation used for bulk operations like
     * getEngagementDistribution() to avoid N+1 query patterns.
     */
    private function estimateEngagementScore(array $user, Carbon $now): int
    {
        $score = 0;

        // Login recency: 30% (0-30 pts)
        $lastLogin = $user['last_login'] ?? null;
        $daysSinceLogin = 999;
        if ($lastLogin) {
            try {
                $daysSinceLogin = Carbon::parse($lastLogin)->diffInDays($now);
            } catch (\Exception $e) {
            }
        }
        $score += max(0, 30 - $daysSinceLogin);

        // Streak as proxy for mood logging: 25%
        $streak = (int) ($user['current_streak'] ?? $user['streak'] ?? 0);
        $score += min(25, $streak * 5);

        // Premium status as proxy for session attendance: 20%
        $isPremium = $user['is_premium'] ?? false;
        $subStatus = $user['subscription_status'] ?? 'free';
        if ($isPremium || $subStatus === 'active') {
            $score += 15;
        }

        // Account age bonus: 10%
        $createdAt = $user['created_at'] ?? null;
        if ($createdAt) {
            try {
                $daysOld = Carbon::parse($createdAt)->diffInDays($now);
                if ($daysOld > 30) {
                    $score += min(10, (int) ($daysOld / 30) * 2);
                }
            } catch (\Exception $e) {
            }
        }

        return min(100, max(0, $score));
    }

    /**
     * Estimate retention risk score from user profile fields only (no sub-queries).
     *
     * Used as a first-pass filter in getAtRiskUsers() to reduce the number
     * of users that need full getUserInsights() calls.
     */
    private function estimateRiskScore(array $user, Carbon $now): int
    {
        $riskScore = 0;

        // Days inactive: 30% weight
        $lastLogin = $user['last_login'] ?? null;
        $daysSinceLogin = 999;
        if ($lastLogin) {
            try {
                $daysSinceLogin = Carbon::parse($lastLogin)->diffInDays($now);
            } catch (\Exception $e) {
            }
        }
        $inactiveScore = min(100, $daysSinceLogin * 3);
        $riskScore += (int) ($inactiveScore * 0.30);

        // Low engagement estimate: 25% weight
        $engagementScore = $this->estimateEngagementScore($user, $now);
        $engagementRisk = max(0, 100 - $engagementScore);
        $riskScore += (int) ($engagementRisk * 0.25);

        // Subscription status: 10% weight
        $subStatus = $user['subscription_status'] ?? 'free';
        $subRisk = match ($subStatus) {
            'active' => 0,
            'expired' => 60,
            'cancelled' => 80,
            default => 40,
        };
        $riskScore += (int) ($subRisk * 0.10);

        return min(100, max(0, $riskScore));
    }

}
