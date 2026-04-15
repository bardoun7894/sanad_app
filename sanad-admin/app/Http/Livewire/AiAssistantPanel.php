<?php

namespace App\Http\Livewire;

use App\Models\AdminAIChat;
use App\Services\AnalyticsService;
use App\Services\GeminiService;
use App\Services\RiskAlertService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Livewire\Component;

class AiAssistantPanel extends Component
{
    /**
     * Conversation message list.
     *
     * @var array<int, array{role: string, content: string}>
     */
    public array $messages = [];

    /**
     * Current user input text.
     */
    public string $userInput = '';

    /**
     * Whether the AI is currently generating a response.
     */
    public bool $isLoading = false;

    /**
     * Whether the panel is open / visible.
     */
    public bool $isOpen = false;

    // ─── Lifecycle ───────────────────────────────────────────

    public function mount(): void
    {
        $this->loadMessages();
    }

    // ─── Actions ─────────────────────────────────────────────

    /**
     * Toggle the panel open/closed.
     */
    public function toggle(): void
    {
        $this->isOpen = ! $this->isOpen;

        if ($this->isOpen) {
            $this->loadMessages();
        }
    }

    /**
     * Send a user message, call Gemini, and store both messages.
     */
    public function sendMessage(): void
    {
        $input = trim($this->userInput);

        if ($input === '') {
            return;
        }

        $this->userInput = '';
        $this->isLoading = true;

        try {
            $adminId = $this->getAdminId();

            // Add user message to local state immediately.
            $this->messages[] = [
                'role' => 'user',
                'content' => $input,
            ];

            // Persist user message to Firestore.
            AdminAIChat::addMessage($adminId, 'user', $input);

            // Build dashboard context for the AI.
            $context = $this->getDashboardContext();

            // Build history for Gemini (exclude the just-added message; it is sent as the prompt).
            $history = array_slice($this->messages, 0, -1);

            // Call Gemini.
            $gemini = app(GeminiService::class);
            $response = $gemini->generateContent($input, $context, $history);

            // Add assistant message to local state.
            $this->messages[] = [
                'role' => 'assistant',
                'content' => $response,
            ];

            // Persist assistant message to Firestore.
            AdminAIChat::addMessage($adminId, 'assistant', $response);
        } catch (\Exception $e) {
            Log::error("AiAssistantPanel::sendMessage failed: {$e->getMessage()}");

            $this->messages[] = [
                'role' => 'assistant',
                'content' => __('ai_processing_error'),
            ];
        } finally {
            $this->isLoading = false;
        }

        $this->dispatch('scroll-to-bottom');
    }

    /**
     * Generate an AI summary of the current dashboard data.
     */
    public function generateSummary(): void
    {
        $this->isLoading = true;

        try {
            $adminId = $this->getAdminId();
            $context = $this->getDashboardContext();

            $gemini = app(GeminiService::class);
            $summary = $gemini->generateSummary($context);

            // Store as a pair: a system-triggered user message + the AI response.
            $systemPrompt = __('generate_dashboard_summary');

            $this->messages[] = [
                'role' => 'user',
                'content' => $systemPrompt,
            ];
            AdminAIChat::addMessage($adminId, 'user', $systemPrompt);

            $this->messages[] = [
                'role' => 'assistant',
                'content' => $summary,
            ];
            AdminAIChat::addMessage($adminId, 'assistant', $summary);
        } catch (\Exception $e) {
            Log::error("AiAssistantPanel::generateSummary failed: {$e->getMessage()}");

            $this->messages[] = [
                'role' => 'assistant',
                'content' => __('ai_processing_error'),
            ];
        } finally {
            $this->isLoading = false;
        }

        $this->dispatch('scroll-to-bottom');
    }

    /**
     * Clear all chat messages from Firestore and reset local state.
     */
    public function clearChat(): void
    {
        try {
            AdminAIChat::clearMessages($this->getAdminId());
            $this->messages = [];
        } catch (\Exception $e) {
            Log::error("AiAssistantPanel::clearChat failed: {$e->getMessage()}");
        }
    }

    // ─── Render ──────────────────────────────────────────────

    public function render(): \Illuminate\View\View
    {
        return view('livewire.ai-assistant');
    }

    // ─── Helpers ─────────────────────────────────────────────

    /**
     * Load conversation history from Firestore.
     */
    protected function loadMessages(): void
    {
        try {
            $adminId = $this->getAdminId();
            $raw = AdminAIChat::getMessages($adminId);

            $this->messages = array_map(fn (array $msg) => [
                'role' => $msg['role'] ?? 'assistant',
                'content' => $msg['content'] ?? '',
            ], $raw);
        } catch (\Exception $e) {
            Log::error("AiAssistantPanel::loadMessages failed: {$e->getMessage()}");
            $this->messages = [];
        }
    }

    /**
     * Get the authenticated admin's Firebase UID.
     */
    protected function getAdminId(): string
    {
        return Auth::user()?->getKey() ?? 'unknown';
    }

    /**
     * Gather current dashboard KPIs as context for the AI.
     */
    protected function getDashboardContext(): array
    {
        try {
            $analytics = app(AnalyticsService::class);

            $activeUsers = $analytics->countActiveUsers();
            $criticalFlags = $analytics->countCriticalFlags();
            $todaySessions = $analytics->countTodaySessions();
            $earnings = $analytics->calculateEarnings();

            $context = [
                'active_users' => $activeUsers['count'] ?? 0,
                'critical_flags' => $criticalFlags['count'] ?? 0,
                'todays_sessions' => $todaySessions['count'] ?? 0,
                'earnings' => ($earnings['currency'] ?? 'SAR').' '.number_format($earnings['amount'] ?? 0, 2),
            ];

            // Attempt to fetch risk alerts if the service exists.
            try {
                $riskService = app(RiskAlertService::class);
                $context['risk_alerts'] = $riskService->getRiskAlerts();
            } catch (\Exception $e) {
                $context['risk_alerts'] = [];
            }

            return $context;
        } catch (\Exception $e) {
            Log::error("AiAssistantPanel::getDashboardContext failed: {$e->getMessage()}");

            return [];
        }
    }
}
