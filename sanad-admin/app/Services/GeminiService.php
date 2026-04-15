<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiService
{
    protected string $apiKey;

    protected string $baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

    public function __construct()
    {
        $this->apiKey = config('services.gemini.api_key', env('GEMINI_API_KEY', ''));
    }

    /**
     * Generate content from Gemini API.
     *
     * @param  string  $prompt  The user's question.
     * @param  array  $context  Dashboard context data (KPIs, risk alerts, etc.).
     * @param  array  $history  Previous conversation messages.
     * @return string The AI response text.
     */
    public function generateContent(string $prompt, array $context = [], array $history = []): string
    {
        try {
            $systemPrompt = $this->buildSystemPrompt($context);

            $contents = [];

            // Add system context as first user message.
            if (! empty($context)) {
                $contents[] = [
                    'role' => 'user',
                    'parts' => [['text' => $systemPrompt]],
                ];
                $contents[] = [
                    'role' => 'model',
                    'parts' => [['text' => __('ai_context_acknowledged')]],
                ];
            }

            // Add conversation history.
            foreach ($history as $msg) {
                $contents[] = [
                    'role' => $msg['role'] === 'user' ? 'user' : 'model',
                    'parts' => [['text' => $msg['content']]],
                ];
            }

            // Add current prompt.
            $contents[] = [
                'role' => 'user',
                'parts' => [['text' => $prompt]],
            ];

            $response = Http::timeout(30)->post(
                "{$this->baseUrl}/models/gemini-2.5-flash:generateContent?key={$this->apiKey}",
                [
                    'contents' => $contents,
                    'generationConfig' => [
                        'temperature' => 0.7,
                        'maxOutputTokens' => 1024,
                        'topP' => 0.8,
                        'topK' => 40,
                    ],
                ],
            );

            if ($response->failed()) {
                Log::error('Gemini API request failed', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                return __('ai_response_error');
            }

            $data = $response->json();

            return $data['candidates'][0]['content']['parts'][0]['text']
                ?? __('ai_no_response');
        } catch (\Exception $e) {
            Log::error("GeminiService generateContent failed: {$e->getMessage()}");

            return __('ai_processing_error');
        }
    }

    /**
     * Generate a dashboard summary.
     */
    public function generateSummary(array $dashboardData): string
    {
        $prompt = "Based on the clinic dashboard data provided, generate a concise summary with key insights and recommendations. Focus on:\n"
            ."1. Patient engagement trends\n"
            ."2. Risk alerts that need attention\n"
            ."3. Revenue and booking performance\n"
            .'4. Actionable recommendations for the clinic admin';

        return $this->generateContent($prompt, $dashboardData);
    }

    /**
     * Analyze a single user's comprehensive data and generate clinical insights.
     */
    public function analyzeUser(array $userInsights): string
    {
        try {
            $prompt = $this->buildUserAnalysisPrompt($userInsights);

            $contents = [
                [
                    'role' => 'user',
                    'parts' => [['text' => $prompt]],
                ],
            ];

            $response = Http::timeout(60)->post(
                "{$this->baseUrl}/models/gemini-2.5-flash:generateContent?key={$this->apiKey}",
                [
                    'contents' => $contents,
                    'generationConfig' => [
                        'temperature' => 0.6,
                        'maxOutputTokens' => 2048,
                        'topP' => 0.8,
                        'topK' => 40,
                    ],
                ],
            );

            if ($response->failed()) {
                Log::error('Gemini analyzeUser failed', ['status' => $response->status()]);

                return __('ai_response_error');
            }

            return $response->json()['candidates'][0]['content']['parts'][0]['text'] ?? __('ai_no_response');
        } catch (\Exception $e) {
            Log::error("GeminiService::analyzeUser failed: {$e->getMessage()}");

            return __('ai_processing_error');
        }
    }

    /**
     * Generate retention insights from a batch of at-risk users.
     */
    public function generateRetentionInsights(array $atRiskUsers): string
    {
        try {
            $prompt = "You are a clinical psychologist and data analyst for the Sanad mental health platform. ";
            $prompt .= "Analyze the following at-risk users and identify common patterns, systemic issues, and priority actions.\n\n";
            $prompt .= "AT-RISK USERS (" . count($atRiskUsers) . " total):\n";

            foreach (array_slice($atRiskUsers, 0, 15) as $user) {
                $prompt .= "- {$user['user_name']}: Risk={$user['risk_level']} (score: {$user['risk_score']}), ";
                $prompt .= "Engagement={$user['engagement_score']}, ";
                $prompt .= "Inactive={$user['days_inactive']}d, ";
                $prompt .= "Signal: {$user['top_signal']}\n";
            }

            $prompt .= "\nProvide:\n1. Common patterns across at-risk users\n2. Systemic interventions the clinic should consider\n3. Top 5 priority actions\n4. Recommendations for prevention\n\nBe concise, clinical, and actionable.";

            return $this->generateContent($prompt);
        } catch (\Exception $e) {
            Log::error("GeminiService::generateRetentionInsights failed: {$e->getMessage()}");

            return __('ai_processing_error');
        }
    }

    /**
     * Analyze community health and generate recommendations.
     */
    public function analyzeCommunityHealth(array $communityStats): string
    {
        try {
            $prompt = "You are a community health analyst for the Sanad mental health platform. ";
            $prompt .= "Analyze these community metrics and provide insights.\n\n";
            $prompt .= "COMMUNITY DATA (Last 30 Days):\n";
            $prompt .= "- Posts: {$communityStats['total_posts_30d']}\n";
            $prompt .= "- Posts/Day: {$communityStats['posts_per_day']}\n";
            $prompt .= "- Active Contributors: {$communityStats['active_contributors']}\n";
            $prompt .= "- Total Reactions: {$communityStats['total_reactions']}\n";
            $prompt .= "- Avg Reactions/Post: {$communityStats['avg_reactions']}\n";

            if (! empty($communityStats['category_distribution'])) {
                $prompt .= "- Categories: ";
                foreach ($communityStats['category_distribution'] as $cat => $count) {
                    $prompt .= "{$cat}({$count}), ";
                }
                $prompt .= "\n";
            }

            $prompt .= "\nProvide:\n1. Community health assessment\n2. Engagement quality analysis\n3. Concerning trends (if any)\n4. Recommendations for improving community engagement\n\nBe concise and actionable.";

            return $this->generateContent($prompt);
        } catch (\Exception $e) {
            Log::error("GeminiService::analyzeCommunityHealth failed: {$e->getMessage()}");

            return __('ai_processing_error');
        }
    }

    /**
     * Build a structured analysis prompt from user insights data.
     */
    private function buildUserAnalysisPrompt(array $insights): string
    {
        $prompt = "You are a clinical psychologist assistant analyzing patient data for the Sanad mental health platform. ";
        $prompt .= "Provide a comprehensive analysis based on the following user data. ";
        $prompt .= "Include: clinical observations, retention risk assessment, recommended interventions, and progress summary.\n\n";

        $profile = $insights['profile'] ?? [];
        $prompt .= "PATIENT PROFILE:\n";
        $prompt .= "- Name: " . ($profile['display_name'] ?? $profile['full_name'] ?? 'Unknown') . "\n";
        $prompt .= "- Subscription: " . ($profile['subscription_status'] ?? 'free') . "\n\n";

        $mood = $insights['mood'] ?? [];
        $prompt .= "MOOD DATA:\n";
        $prompt .= "- 7-Day Average: " . ($mood['avg_7d'] !== null ? number_format($mood['avg_7d'], 2) : 'N/A') . " (0=happy, 5=negative)\n";
        $prompt .= "- 30-Day Average: " . ($mood['avg_30d'] !== null ? number_format($mood['avg_30d'], 2) : 'N/A') . "\n";
        $prompt .= "- Trend: " . ($mood['trend'] ?? 'unknown') . "\n";
        $prompt .= "- Dominant Mood: " . ($mood['dominant_mood'] ?? 'N/A') . "\n";
        $prompt .= "- Logging Frequency: " . ($mood['logging_frequency'] ?? 0) . " entries/week\n\n";

        $engagement = $insights['engagement'] ?? [];
        $prompt .= "ENGAGEMENT:\n";
        $prompt .= "- Score: " . ($engagement['score'] ?? 0) . "/100\n";
        $prompt .= "- Current Streak: " . ($engagement['current_streak'] ?? 0) . " days\n";
        $prompt .= "- Days Since Login: " . ($engagement['days_since_login'] ?? 'unknown') . "\n";
        $prompt .= "- Activity Trend: " . ($engagement['activity_trend'] ?? 'unknown') . "\n\n";

        $sessions = $insights['sessions'] ?? [];
        $prompt .= "SESSIONS:\n";
        $prompt .= "- Total: " . ($sessions['total'] ?? 0) . "\n";
        $prompt .= "- Completed: " . ($sessions['completed'] ?? 0) . "\n";
        $prompt .= "- Cancelled: " . ($sessions['cancelled'] ?? 0) . "\n";
        $prompt .= "- Completion Rate: " . ($sessions['completion_rate'] ?? 0) . "%\n\n";

        $retention = $insights['retention'] ?? [];
        $prompt .= "RETENTION RISK:\n";
        $prompt .= "- Level: " . ($retention['risk_level'] ?? 'unknown') . "\n";
        $prompt .= "- Score: " . ($retention['risk_score'] ?? 0) . "/100\n";
        if (! empty($retention['risk_factors'])) {
            $prompt .= "- Factors: " . implode(', ', $retention['risk_factors']) . "\n";
        }
        $prompt .= "\n";

        $flags = $insights['flags'] ?? [];
        $activeFlags = array_keys(array_filter($flags));
        if (! empty($activeFlags)) {
            $prompt .= "BEHAVIORAL FLAGS: " . implode(', ', $activeFlags) . "\n\n";
        }

        $community = $insights['community'] ?? [];
        $prompt .= "COMMUNITY: " . ($community['posts_count'] ?? 0) . " posts, ";
        $prompt .= ($community['reactions_received'] ?? 0) . " reactions received\n\n";

        $aiChat = $insights['ai_chat'] ?? [];
        if (($aiChat['message_count'] ?? 0) > 0) {
            $prompt .= "AI CHAT: " . ($aiChat['message_count'] ?? 0) . " messages, ";
            $prompt .= ($aiChat['crisis_count'] ?? 0) . " crisis messages, ";
            $prompt .= ($aiChat['escalation_count'] ?? 0) . " escalation suggestions\n\n";
        }

        $prompt .= "Provide your analysis in markdown format with clear sections. Be clinical, empathetic, and actionable.";

        return $prompt;
    }

    /**
     * Build the system prompt with dashboard context data.
     */
    protected function buildSystemPrompt(array $context): string
    {
        $prompt = 'You are an AI assistant for the Sanad mental health clinic admin dashboard. ';
        $prompt .= 'You help clinic administrators understand their data and make informed decisions. ';
        $prompt .= "Here is the current dashboard data:\n\n";

        if (isset($context['active_users'])) {
            $prompt .= "Active Users (30 days): {$context['active_users']}\n";
        }

        if (isset($context['critical_flags'])) {
            $prompt .= "Critical Risk Flags: {$context['critical_flags']}\n";
        }

        if (isset($context['todays_sessions'])) {
            $prompt .= "Today's Sessions: {$context['todays_sessions']}\n";
        }

        if (isset($context['earnings'])) {
            $prompt .= "This Month's Earnings: {$context['earnings']}\n";
        }

        if (isset($context['risk_alerts']) && is_array($context['risk_alerts'])) {
            $prompt .= 'At-Risk Patients: '.count($context['risk_alerts'])."\n";

            foreach (array_slice($context['risk_alerts'], 0, 5) as $alert) {
                $userName = $alert['user_name'] ?? 'Unknown';
                $riskLevel = $alert['risk_level'] ?? 'unknown';
                $avgMood = $alert['average_mood'] ?? 0;

                $prompt .= "  - {$userName}: {$riskLevel} risk (avg mood: {$avgMood})\n";
            }
        }

        $prompt .= "\nProvide clear, actionable insights. Be concise and professional.";

        return $prompt;
    }
}
