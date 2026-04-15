<x-filament-panels::page>
    {{-- Tab Navigation --}}
    <div class="flex flex-wrap gap-2 mb-6 border-b border-white/10 pb-2">
        @foreach(['overview', 'sessions', 'assessments', 'billing', 'mood_history', 'engagement', 'community', 'ai_insights'] as $tab)
            <button
                wire:click="$set('activeTab', '{{ $tab }}')"
                @class([
                    'px-4 py-2 rounded-t-lg text-sm font-medium transition-colors',
                    'bg-primary-500/20 text-primary-400 border-b-2 border-primary-500' => $activeTab === $tab,
                    'text-gray-400 hover:text-gray-200 hover:bg-white/5' => $activeTab !== $tab,
                ])
            >
                {{ __($tab) }}
            </button>
        @endforeach
    </div>

    {{-- Overview Tab --}}
    @if($activeTab === 'overview')
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            {{-- Profile Card --}}
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                <h3 class="text-lg font-semibold text-white mb-4">{{ __('user_information') }}</h3>
                <div class="space-y-3">
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('name') }}</span>
                        <span class="text-white">{{ $user->getDisplayName() }}</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('email') }}</span>
                        <span class="text-white">{{ $user->safeGet('email') }}</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('phone_number') }}</span>
                        <span class="text-white">{{ $user->safeGet('phone_number', '-') }}</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('role') }}</span>
                        <span @class([
                            'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                            'bg-red-500/20 text-red-400' => $user->role === 'admin',
                            'bg-yellow-500/20 text-yellow-400' => $user->role === 'therapist',
                            'bg-gray-500/20 text-gray-400' => !in_array($user->role, ['admin', 'therapist']),
                        ])>
                            {{ $user->safeGet('role', 'user') }}
                        </span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('date_of_birth') }}</span>
                        <span class="text-white">{{ $user->safeGet('date_of_birth', '-') }}</span>
                    </div>
                </div>
            </div>

            {{-- Subscription Card --}}
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                <h3 class="text-lg font-semibold text-white mb-4">{{ __('subscription_details') }}</h3>
                <div class="space-y-3">
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('subscription_status') }}</span>
                        <span @class([
                            'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                            'bg-green-500/20 text-green-400' => $user->subscription_status === 'active',
                            'bg-red-500/20 text-red-400' => $user->subscription_status === 'expired',
                            'bg-yellow-500/20 text-yellow-400' => $user->subscription_status === 'pending',
                            'bg-gray-500/20 text-gray-400' => !in_array($user->subscription_status, ['active', 'expired', 'pending']),
                        ])>
                            {{ $user->safeGet('subscription_status', 'free') }}
                        </span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('premium') }}</span>
                        <span class="text-white">
                            @if($user->isPremium())
                                <x-heroicon-s-check-circle class="w-5 h-5 text-green-400 inline" />
                            @else
                                <x-heroicon-s-x-circle class="w-5 h-5 text-gray-500 inline" />
                            @endif
                        </span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('subscription_plan') }}</span>
                        <span class="text-white">{{ $user->safeGet('subscription_product_title', $user->safeGet('subscription_plan', '-')) }}</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('subscription_start') }}</span>
                        <span class="text-white">{{ $user->safeGet('subscription_start_date', '-') }}</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">{{ __('subscription_expiry') }}</span>
                        <span class="text-white">{{ $user->safeGet('subscription_expiry_date', '-') }}</span>
                    </div>
                </div>
            </div>

            {{-- Risk Assessment Card --}}
            @php
                $retention = $userInsights['retention'] ?? [];
                $riskLevel = $retention['risk_level'] ?? 'unknown';
                $riskScore = $retention['risk_score'] ?? 0;
                $riskFactors = $retention['risk_factors'] ?? [];
            @endphp
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                <h3 class="text-lg font-semibold text-white mb-4">{{ __('risk_assessment') }}</h3>
                <div class="space-y-4">
                    <div class="flex items-center gap-3">
                        <span @class([
                            'inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold',
                            'bg-red-500/20 text-red-400' => $riskLevel === 'critical',
                            'bg-orange-500/20 text-orange-400' => $riskLevel === 'high',
                            'bg-blue-500/20 text-blue-400' => $riskLevel === 'moderate',
                            'bg-green-500/20 text-green-400' => $riskLevel === 'low',
                            'bg-gray-500/20 text-gray-400' => $riskLevel === 'unknown',
                        ])>
                            {{ ucfirst($riskLevel) }}
                        </span>
                        <span class="text-gray-400 text-sm">{{ __('risk_score') }}: {{ $riskScore }}/100</span>
                    </div>
                    <div class="w-full bg-gray-700 rounded-full h-2">
                        <div @class([
                            'h-2 rounded-full transition-all',
                            'bg-red-500' => $riskScore >= 75,
                            'bg-orange-500' => $riskScore >= 55 && $riskScore < 75,
                            'bg-blue-500' => $riskScore >= 35 && $riskScore < 55,
                            'bg-green-500' => $riskScore < 35,
                        ]) style="width: {{ $riskScore }}%"></div>
                    </div>
                    @if(!empty($riskFactors))
                        <ul class="space-y-1 text-sm text-gray-400">
                            @foreach($riskFactors as $factor)
                                <li class="flex items-center gap-2">
                                    <x-heroicon-o-exclamation-triangle class="w-4 h-4 text-orange-400 shrink-0" />
                                    {{ $factor }}
                                </li>
                            @endforeach
                        </ul>
                    @endif
                </div>
            </div>

            {{-- Engagement Score Card --}}
            @php
                $engagement = $userInsights['engagement'] ?? [];
                $engScore = $engagement['score'] ?? 0;
            @endphp
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                <h3 class="text-lg font-semibold text-white mb-4">{{ __('engagement_score') }}</h3>
                <div class="flex items-center gap-6">
                    <div class="relative w-24 h-24">
                        <svg class="w-24 h-24 transform -rotate-90" viewBox="0 0 36 36">
                            <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="3"/>
                            <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="{{ $engScore >= 60 ? '#10b981' : ($engScore >= 30 ? '#f59e0b' : '#ef4444') }}" stroke-width="3" stroke-dasharray="{{ $engScore }}, 100"/>
                        </svg>
                        <span class="absolute inset-0 flex items-center justify-center text-xl font-bold text-white">{{ $engScore }}</span>
                    </div>
                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between gap-8">
                            <span class="text-gray-400">{{ __('current_streak') }}</span>
                            <span class="text-white font-medium">{{ $engagement['current_streak'] ?? 0 }} {{ __('days') }}</span>
                        </div>
                        <div class="flex justify-between gap-8">
                            <span class="text-gray-400">{{ __('longest_streak') }}</span>
                            <span class="text-white font-medium">{{ $engagement['longest_streak'] ?? 0 }} {{ __('days') }}</span>
                        </div>
                        <div class="flex justify-between gap-8">
                            <span class="text-gray-400">{{ __('activity_trend') }}</span>
                            <span @class([
                                'font-medium',
                                'text-green-400' => ($engagement['activity_trend'] ?? '') === 'active',
                                'text-yellow-400' => ($engagement['activity_trend'] ?? '') === 'stable',
                                'text-red-400' => ($engagement['activity_trend'] ?? '') === 'declining',
                                'text-gray-400' => !in_array($engagement['activity_trend'] ?? '', ['active', 'stable', 'declining']),
                            ])>
                                {{ ucfirst($engagement['activity_trend'] ?? 'unknown') }}
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Behavioral Flags Card --}}
            @php $flags = $userInsights['flags'] ?? []; @endphp
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6 md:col-span-2">
                <h3 class="text-lg font-semibold text-white mb-4">{{ __('behavioral_flags') }}</h3>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
                    @foreach([
                        'crisis_detected' => ['icon' => 'heroicon-o-exclamation-triangle', 'color' => 'red'],
                        'escalation_suggested' => ['icon' => 'heroicon-o-arrow-trending-up', 'color' => 'orange'],
                        'high_cancellation' => ['icon' => 'heroicon-o-x-circle', 'color' => 'yellow'],
                        'community_withdrawal' => ['icon' => 'heroicon-o-user-minus', 'color' => 'purple'],
                        'mood_crisis' => ['icon' => 'heroicon-o-face-frown', 'color' => 'red'],
                        'engagement_dropping' => ['icon' => 'heroicon-o-arrow-trending-down', 'color' => 'orange'],
                    ] as $flagKey => $flagMeta)
                        @php $isActive = $flags[$flagKey] ?? false; @endphp
                        <div @class([
                            'flex items-center gap-2 p-3 rounded-lg border text-sm',
                            "bg-{$flagMeta['color']}-500/10 border-{$flagMeta['color']}-500/30 text-{$flagMeta['color']}-400" => $isActive,
                            'bg-white/5 border-white/10 text-gray-500' => !$isActive,
                        ])>
                            <x-dynamic-component :component="$flagMeta['icon']" class="w-5 h-5 shrink-0" />
                            <span>{{ __($flagKey) }}</span>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>
    @endif

    {{-- Sessions Tab --}}
    @if($activeTab === 'sessions')
        <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 overflow-hidden">
            <div class="p-6 border-b border-white/10">
                <h3 class="text-lg font-semibold text-white">{{ __('sessions') }}</h3>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="border-b border-white/10">
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('scheduled_time') }}</th>
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('session_type') }}</th>
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('status') }}</th>
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('therapist') }}</th>
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('duration') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($this->getUserBookings() as $booking)
                            <tr class="border-b border-white/5 hover:bg-white/5 transition-colors">
                                <td class="px-6 py-3 text-white">{{ $booking->safeGet('scheduled_time', '-') }}</td>
                                <td class="px-6 py-3 text-white">{{ $booking->safeGet('session_type', '-') }}</td>
                                <td class="px-6 py-3">
                                    <span @class([
                                        'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                                        'bg-yellow-500/20 text-yellow-400' => $booking->status === 'pending',
                                        'bg-blue-500/20 text-blue-400' => $booking->status === 'confirmed',
                                        'bg-green-500/20 text-green-400' => $booking->status === 'completed',
                                        'bg-red-500/20 text-red-400' => in_array($booking->status, ['rejected', 'no_show']),
                                        'bg-gray-500/20 text-gray-400' => $booking->status === 'cancelled',
                                    ])>
                                        {{ $booking->safeGet('status', '-') }}
                                    </span>
                                </td>
                                <td class="px-6 py-3 text-white">{{ $booking->safeGet('therapist_id', '-') }}</td>
                                <td class="px-6 py-3 text-white">{{ $booking->safeGet('duration_minutes', '60') }} {{ __('minutes') }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="px-6 py-8 text-center text-gray-500">
                                    {{ __('no_records_found') }}
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    @endif

    {{-- Assessments Tab --}}
    @if($activeTab === 'assessments')
        <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 overflow-hidden">
            <div class="p-6 border-b border-white/10">
                <h3 class="text-lg font-semibold text-white">{{ __('assessments') }}</h3>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="border-b border-white/10">
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('date') }}</th>
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('risk_level') }}</th>
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('score') }}</th>
                            <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('notes') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($this->getUserAssessments() as $assessment)
                            <tr class="border-b border-white/5 hover:bg-white/5 transition-colors">
                                <td class="px-6 py-3 text-white">{{ $assessment->safeGet('created_at', '-') }}</td>
                                <td class="px-6 py-3">
                                    <span @class([
                                        'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                                        'bg-red-500/20 text-red-400' => $assessment->risk_level === 'high',
                                        'bg-yellow-500/20 text-yellow-400' => $assessment->risk_level === 'moderate',
                                        'bg-green-500/20 text-green-400' => $assessment->risk_level === 'low',
                                        'bg-gray-500/20 text-gray-400' => !in_array($assessment->risk_level, ['high', 'moderate', 'low']),
                                    ])>
                                        {{ $assessment->safeGet('risk_level', '-') }}
                                    </span>
                                </td>
                                <td class="px-6 py-3 text-white">{{ $assessment->safeGet('score', '-') }}</td>
                                <td class="px-6 py-3 text-white truncate max-w-xs">{{ $assessment->safeGet('notes', '-') }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="4" class="px-6 py-8 text-center text-gray-500">
                                    {{ __('no_records_found') }}
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    @endif

    {{-- Billing Tab --}}
    @if($activeTab === 'billing')
        <div class="space-y-6">
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                <h3 class="text-lg font-semibold text-white mb-4">{{ __('subscription_details') }}</h3>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div class="p-4 bg-white/5 rounded-lg">
                        <div class="text-xs text-gray-400 mb-1">{{ __('subscription_status') }}</div>
                        <div @class([
                            'text-lg font-semibold',
                            'text-green-400' => $user->subscription_status === 'active',
                            'text-red-400' => $user->subscription_status === 'expired',
                            'text-yellow-400' => $user->subscription_status === 'pending',
                            'text-gray-400' => !in_array($user->subscription_status, ['active', 'expired', 'pending']),
                        ])>
                            {{ ucfirst($user->safeGet('subscription_status', 'free')) }}
                        </div>
                    </div>
                    <div class="p-4 bg-white/5 rounded-lg">
                        <div class="text-xs text-gray-400 mb-1">{{ __('subscription_plan') }}</div>
                        <div class="text-lg font-semibold text-white">
                            {{ $user->safeGet('subscription_product_title', $user->safeGet('subscription_plan', '-')) }}
                        </div>
                    </div>
                    <div class="p-4 bg-white/5 rounded-lg">
                        <div class="text-xs text-gray-400 mb-1">{{ __('subscription_expiry') }}</div>
                        <div class="text-lg font-semibold text-white">
                            {{ $user->safeGet('subscription_expiry_date', '-') }}
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 overflow-hidden">
                <div class="p-6 border-b border-white/10">
                    <h3 class="text-lg font-semibold text-white">{{ __('payment_history') }}</h3>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="border-b border-white/10">
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('date') }}</th>
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('amount') }}</th>
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('status') }}</th>
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('payment_method') }}</th>
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('description') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($this->getUserPayments() as $payment)
                                <tr class="border-b border-white/5 hover:bg-white/5 transition-colors">
                                    <td class="px-6 py-3 text-white">{{ $payment->safeGet('created_at', '-') }}</td>
                                    <td class="px-6 py-3 text-white font-medium">
                                        {{ $payment->safeGet('amount', '0') }}
                                        {{ $payment->safeGet('currency', 'SAR') }}
                                    </td>
                                    <td class="px-6 py-3">
                                        <span @class([
                                            'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                                            'bg-green-500/20 text-green-400' => in_array($payment->status, ['completed', 'succeeded']),
                                            'bg-yellow-500/20 text-yellow-400' => $payment->status === 'pending',
                                            'bg-red-500/20 text-red-400' => $payment->status === 'failed',
                                            'bg-blue-500/20 text-blue-400' => $payment->status === 'refunded',
                                            'bg-gray-500/20 text-gray-400' => !in_array($payment->status, ['completed', 'succeeded', 'pending', 'failed', 'refunded']),
                                        ])>
                                            {{ $payment->safeGet('status', '-') }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-3 text-white">{{ $payment->safeGet('gateway', $payment->safeGet('payment_method', '-')) }}</td>
                                    <td class="px-6 py-3 text-white truncate max-w-xs">{{ $payment->safeGet('product_title', $payment->safeGet('description', '-')) }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="px-6 py-8 text-center text-gray-500">
                                        {{ __('no_records_found') }}
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @endif

    {{-- Mood History Tab --}}
    @if($activeTab === 'mood_history')
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
        <div class="space-y-6">
            {{-- Stats Row --}}
            @php $mood = $userInsights['mood'] ?? []; @endphp
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-4 text-center">
                    <div class="text-2xl font-bold text-white">{{ $mood['avg_30d'] !== null ? number_format($mood['avg_30d'], 1) : '-' }}</div>
                    <div class="text-xs text-gray-400 mt-1">{{ __('avg_mood_30d') }}</div>
                </div>
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-4 text-center">
                    <div class="text-2xl font-bold text-white">{{ $mood['entry_count'] ?? 0 }}</div>
                    <div class="text-xs text-gray-400 mt-1">{{ __('total_entries') }}</div>
                </div>
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-4 text-center">
                    <div class="text-2xl font-bold text-white">{{ ucfirst($mood['dominant_mood'] ?? '-') }}</div>
                    <div class="text-xs text-gray-400 mt-1">{{ __('dominant_mood') }}</div>
                </div>
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-4 text-center">
                    <span @class([
                        'text-2xl font-bold',
                        'text-green-400' => ($mood['trend'] ?? '') === 'improving',
                        'text-yellow-400' => ($mood['trend'] ?? '') === 'stable',
                        'text-red-400' => ($mood['trend'] ?? '') === 'declining',
                        'text-gray-400' => !in_array($mood['trend'] ?? '', ['improving', 'stable', 'declining']),
                    ])>
                        {{ ucfirst($mood['trend'] ?? 'unknown') }}
                    </span>
                    <div class="text-xs text-gray-400 mt-1">{{ __('mood_trend') }}</div>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                {{-- Mood Line Chart --}}
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                    <h3 class="text-lg font-semibold text-white mb-4">{{ __('mood_over_time') }}</h3>
                    <div class="relative h-64">
                        <canvas id="moodLineChart"></canvas>
                    </div>
                </div>

                {{-- Mood Distribution Doughnut --}}
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                    <h3 class="text-lg font-semibold text-white mb-4">{{ __('mood_distribution') }}</h3>
                    <div class="relative h-64">
                        <canvas id="moodDoughnutChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        @php
            $chartData = $this->getUserMoodChartData();
            $moodDist = $this->getMoodDistribution();
        @endphp
        <script>
            document.addEventListener('DOMContentLoaded', function() {
                const lineData = @json($chartData);
                const distData = @json($moodDist);
                const moodColors = {
                    happy: 'rgba(16, 185, 129, 0.8)',
                    calm: 'rgba(74, 144, 217, 0.8)',
                    anxious: 'rgba(245, 158, 11, 0.8)',
                    sad: 'rgba(139, 92, 246, 0.8)',
                    angry: 'rgba(239, 68, 68, 0.8)',
                    tired: 'rgba(107, 114, 128, 0.8)',
                };

                if (lineData.labels.length > 0) {
                    new Chart(document.getElementById('moodLineChart'), {
                        type: 'line',
                        data: {
                            labels: lineData.labels,
                            datasets: [{
                                label: '{{ __("mood_score") }}',
                                data: lineData.data,
                                borderColor: 'rgba(74, 144, 217, 1)',
                                backgroundColor: 'rgba(74, 144, 217, 0.15)',
                                fill: true, tension: 0.4, pointRadius: 3,
                            }],
                        },
                        options: {
                            responsive: true, maintainAspectRatio: false,
                            scales: { y: { beginAtZero: true, max: 5 }, x: { display: false } },
                            plugins: { legend: { display: false } },
                        },
                    });
                }

                const distLabels = Object.keys(distData);
                const distValues = Object.values(distData);
                const distColors = distLabels.map(l => moodColors[l] || 'rgba(107, 114, 128, 0.8)');

                if (distLabels.length > 0) {
                    new Chart(document.getElementById('moodDoughnutChart'), {
                        type: 'doughnut',
                        data: {
                            labels: distLabels.map(l => l.charAt(0).toUpperCase() + l.slice(1)),
                            datasets: [{ data: distValues, backgroundColor: distColors, borderWidth: 0 }],
                        },
                        options: {
                            responsive: true, maintainAspectRatio: false, cutout: '60%',
                            plugins: { legend: { position: 'bottom', labels: { color: '#9ca3af' } } },
                        },
                    });
                }
            });
        </script>
    @endif

    {{-- Engagement Tab --}}
    @if($activeTab === 'engagement')
        @php $engagement = $userInsights['engagement'] ?? []; @endphp
        <div class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                {{-- Score Gauge --}}
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6 flex flex-col items-center">
                    <h3 class="text-lg font-semibold text-white mb-4">{{ __('engagement_score') }}</h3>
                    @php $engScore = $engagement['score'] ?? 0; @endphp
                    <div class="relative w-36 h-36">
                        <svg class="w-36 h-36 transform -rotate-90" viewBox="0 0 36 36">
                            <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="3"/>
                            <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="{{ $engScore >= 60 ? '#10b981' : ($engScore >= 30 ? '#f59e0b' : '#ef4444') }}" stroke-width="3" stroke-dasharray="{{ $engScore }}, 100"/>
                        </svg>
                        <span class="absolute inset-0 flex items-center justify-center text-3xl font-bold text-white">{{ $engScore }}</span>
                    </div>
                    <span class="mt-2 text-sm text-gray-400">{{ __('out_of_100') }}</span>
                </div>

                {{-- Streak Info --}}
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                    <h3 class="text-lg font-semibold text-white mb-4">{{ __('streak_info') }}</h3>
                    <div class="space-y-4">
                        <div class="flex justify-between items-center p-3 bg-white/5 rounded-lg">
                            <span class="text-gray-400">{{ __('current_streak') }}</span>
                            <span class="text-xl font-bold text-white">{{ $engagement['current_streak'] ?? 0 }} {{ __('days') }}</span>
                        </div>
                        <div class="flex justify-between items-center p-3 bg-white/5 rounded-lg">
                            <span class="text-gray-400">{{ __('longest_streak') }}</span>
                            <span class="text-xl font-bold text-white">{{ $engagement['longest_streak'] ?? 0 }} {{ __('days') }}</span>
                        </div>
                        <div class="flex justify-between items-center p-3 bg-white/5 rounded-lg">
                            <span class="text-gray-400">{{ __('last_activity') }}</span>
                            <span class="text-white">{{ $engagement['last_activity'] ?? '-' }}</span>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Feature Usage --}}
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                <h3 class="text-lg font-semibold text-white mb-4">{{ __('feature_usage') }}</h3>
                <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
                    @php $featureUsage = $engagement['feature_usage'] ?? []; @endphp
                    @foreach(['mood' => 'mood_tracking', 'sessions' => 'sessions', 'community' => 'community', 'ai_chat' => 'ai_chat', 'challenges' => 'challenges'] as $key => $label)
                        <div class="flex items-center gap-2 p-3 bg-white/5 rounded-lg">
                            @if($featureUsage[$key] ?? false)
                                <x-heroicon-s-check-circle class="w-5 h-5 text-green-400 shrink-0" />
                            @else
                                <x-heroicon-s-x-circle class="w-5 h-5 text-gray-500 shrink-0" />
                            @endif
                            <span class="text-sm text-gray-300">{{ __($label) }}</span>
                        </div>
                    @endforeach
                </div>
            </div>

            {{-- Challenge Completions --}}
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 overflow-hidden">
                <div class="p-6 border-b border-white/10">
                    <h3 class="text-lg font-semibold text-white">{{ __('challenge_completions') }} ({{ $userInsights['challenges']['completions_count'] ?? 0 }})</h3>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="border-b border-white/10">
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('challenge') }}</th>
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('completed_at') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($this->getUserChallengeCompletions() as $completion)
                                <tr class="border-b border-white/5 hover:bg-white/5 transition-colors">
                                    <td class="px-6 py-3 text-white">{{ $completion['challenge_name'] ?? $completion['title'] ?? '-' }}</td>
                                    <td class="px-6 py-3 text-gray-400">{{ $completion['completed_at'] ?? $completion['created_at'] ?? '-' }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="2" class="px-6 py-8 text-center text-gray-500">{{ __('no_records_found') }}</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @endif

    {{-- Community Tab --}}
    @if($activeTab === 'community')
        @php $community = $userInsights['community'] ?? []; @endphp
        <div class="space-y-6">
            {{-- Stats --}}
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-4 text-center">
                    <div class="text-2xl font-bold text-white">{{ $community['posts_count'] ?? 0 }}</div>
                    <div class="text-xs text-gray-400 mt-1">{{ __('total_posts') }}</div>
                </div>
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-4 text-center">
                    <div class="text-2xl font-bold text-white">{{ $community['reactions_received'] ?? 0 }}</div>
                    <div class="text-xs text-gray-400 mt-1">{{ __('reactions_received') }}</div>
                </div>
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-4 text-center">
                    <div class="text-2xl font-bold text-white">{{ $community['last_post_date'] ? substr($community['last_post_date'], 0, 10) : '-' }}</div>
                    <div class="text-xs text-gray-400 mt-1">{{ __('last_post') }}</div>
                </div>
                <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-4 text-center">
                    <span @class([
                        'text-2xl font-bold',
                        'text-green-400' => $community['is_active_contributor'] ?? false,
                        'text-gray-400' => !($community['is_active_contributor'] ?? false),
                    ])>
                        {{ ($community['is_active_contributor'] ?? false) ? __('yes') : __('no') }}
                    </span>
                    <div class="text-xs text-gray-400 mt-1">{{ __('active_contributor') }}</div>
                </div>
            </div>

            {{-- Posts Table --}}
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 overflow-hidden">
                <div class="p-6 border-b border-white/10">
                    <h3 class="text-lg font-semibold text-white">{{ __('community_posts') }}</h3>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="border-b border-white/10">
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('date') }}</th>
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('content') }}</th>
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('category') }}</th>
                                <th class="text-left px-6 py-3 text-gray-400 font-medium">{{ __('reactions') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($this->getUserCommunityPosts() as $post)
                                <tr class="border-b border-white/5 hover:bg-white/5 transition-colors">
                                    <td class="px-6 py-3 text-white whitespace-nowrap">{{ substr($post['created_at'] ?? '-', 0, 10) }}</td>
                                    <td class="px-6 py-3 text-white truncate max-w-xs">{{ \Illuminate\Support\Str::limit($post['content'] ?? $post['text'] ?? '-', 80) }}</td>
                                    <td class="px-6 py-3 text-gray-400">{{ $post['category'] ?? '-' }}</td>
                                    <td class="px-6 py-3 text-white">{{ is_array($post['reactions_count'] ?? null) ? count($post['reactions_count']) : ($post['reactions_count'] ?? $post['likes'] ?? 0) }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="4" class="px-6 py-8 text-center text-gray-500">{{ __('no_records_found') }}</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @endif

    {{-- AI Insights Tab --}}
    @if($activeTab === 'ai_insights')
        <div class="space-y-6">
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-lg font-semibold text-white">{{ __('ai_user_analysis') }}</h3>
                    <button
                        wire:click="generateAiAnalysis"
                        wire:loading.attr="disabled"
                        class="inline-flex items-center gap-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors disabled:opacity-50"
                    >
                        <span wire:loading.remove wire:target="generateAiAnalysis">
                            <x-heroicon-o-sparkles class="w-4 h-4" />
                        </span>
                        <span wire:loading wire:target="generateAiAnalysis">
                            <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                        </span>
                        {{ __('generate_ai_analysis') }}
                    </button>
                </div>

                @if($aiLoading)
                    <div class="flex items-center justify-center py-12">
                        <div class="flex items-center gap-3 text-gray-400">
                            <svg class="animate-spin h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            {{ __('ai_thinking') }}
                        </div>
                    </div>
                @elseif(!empty($aiAnalysis))
                    <div class="prose prose-invert prose-sm max-w-none bg-white/5 rounded-lg p-6 border border-white/10">
                        {!! \Illuminate\Support\Str::markdown($aiAnalysis) !!}
                    </div>
                @else
                    <div class="flex flex-col items-center justify-center py-12 text-gray-400">
                        <x-heroicon-o-sparkles class="w-12 h-12 mb-3 text-gray-500" />
                        <p class="text-sm">{{ __('click_generate_analysis') }}</p>
                    </div>
                @endif
            </div>
        </div>
    @endif
</x-filament-panels::page>
