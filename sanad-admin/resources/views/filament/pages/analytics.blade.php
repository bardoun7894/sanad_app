<x-filament-panels::page>
    {{-- Chart.js CDN --}}
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>

    {{-- Section Tabs --}}
    <div class="flex flex-wrap gap-2 mb-6 border-b border-white/10 pb-2">
        @foreach(['clinical', 'retention', 'community_section', 'habits', 'ai_platform_insights'] as $section)
            <button
                wire:click="$set('activeSection', '{{ $section }}')"
                @class([
                    'px-4 py-2 rounded-t-lg text-sm font-medium transition-colors',
                    'bg-primary-500/20 text-primary-400 border-b-2 border-primary-500' => $activeSection === $section,
                    'text-gray-400 hover:text-gray-200 hover:bg-white/5' => $activeSection !== $section,
                ])
            >
                {{ __($section) }}
            </button>
        @endforeach
    </div>

    {{-- Clinical Section (existing) --}}
    @if($activeSection === 'clinical')
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">

        {{-- 1. Therapist Ratings Distribution --}}
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="mb-4 flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-yellow-100 dark:bg-yellow-500/10">
                    <x-heroicon-o-star class="h-5 w-5 text-yellow-600 dark:text-yellow-400" />
                </div>
                <div>
                    <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ __('therapist_ratings') }}</h3>
                    <p class="text-xs text-gray-500">{{ __('average_rating_per_therapist') }}</p>
                </div>
            </div>
            <div class="relative h-72">
                <canvas id="therapistRatingsChart"></canvas>
            </div>
        </div>

        {{-- 2. Session Volume Over Time --}}
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="mb-4 flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-100 dark:bg-blue-500/10">
                    <x-heroicon-o-calendar-days class="h-5 w-5 text-blue-600 dark:text-blue-400" />
                </div>
                <div>
                    <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ __('session_volume') }}</h3>
                    <p class="text-xs text-gray-500">{{ __('sessions_over_time') }}</p>
                </div>
            </div>
            <div class="relative h-72">
                <canvas id="sessionVolumeChart"></canvas>
            </div>
        </div>

        {{-- 3. Revenue Trends --}}
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="mb-4 flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100 dark:bg-green-500/10">
                    <x-heroicon-o-banknotes class="h-5 w-5 text-green-600 dark:text-green-400" />
                </div>
                <div>
                    <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ __('revenue_trends') }}</h3>
                    <p class="text-xs text-gray-500">{{ __('revenue_over_time') }}</p>
                </div>
            </div>
            <div class="relative h-72">
                <canvas id="revenueTrendsChart"></canvas>
            </div>
        </div>

        {{-- 4. No-Show Rates --}}
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="mb-4 flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-red-100 dark:bg-red-500/10">
                    <x-heroicon-o-x-circle class="h-5 w-5 text-red-600 dark:text-red-400" />
                </div>
                <div>
                    <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ __('no_show_rates') }}</h3>
                    <p class="text-xs text-gray-500">{{ __('completed_vs_no_show') }}</p>
                </div>
            </div>
            <div class="relative h-72">
                <canvas id="noShowRateChart"></canvas>
            </div>
        </div>

        {{-- 5. Session Type Distribution --}}
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="mb-4 flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-purple-100 dark:bg-purple-500/10">
                    <x-heroicon-o-chart-pie class="h-5 w-5 text-purple-600 dark:text-purple-400" />
                </div>
                <div>
                    <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ __('session_type_distribution') }}</h3>
                    <p class="text-xs text-gray-500">{{ __('breakdown_by_session_type') }}</p>
                </div>
            </div>
            <div class="relative h-72">
                <canvas id="sessionTypeChart"></canvas>
            </div>
        </div>

        {{-- 6. Clinician Performance Comparison --}}
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="mb-4 flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-cyan-100 dark:bg-cyan-500/10">
                    <x-heroicon-o-academic-cap class="h-5 w-5 text-cyan-600 dark:text-cyan-400" />
                </div>
                <div>
                    <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ __('clinician_performance') }}</h3>
                    <p class="text-xs text-gray-500">{{ __('sessions_per_clinician') }}</p>
                </div>
            </div>
            <div class="relative h-72">
                <canvas id="clinicianPerformanceChart"></canvas>
            </div>
        </div>

    </div>

    {{-- Clinical Charts JS --}}
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const isDark = document.documentElement.classList.contains('dark');
            const textColor = isDark ? '#9ca3af' : '#6b7280';
            const gridColor = isDark ? 'rgba(255, 255, 255, 0.06)' : 'rgba(0, 0, 0, 0.06)';
            Chart.defaults.color = textColor;
            Chart.defaults.borderColor = gridColor;

            const chartColors = {
                primary: 'rgba(74, 144, 217, 1)', primaryBg: 'rgba(74, 144, 217, 0.15)',
                green: 'rgba(16, 185, 129, 1)', greenBg: 'rgba(16, 185, 129, 0.15)',
                red: 'rgba(239, 68, 68, 1)', redBg: 'rgba(239, 68, 68, 0.15)',
                palette: ['rgba(74,144,217,0.8)','rgba(16,185,129,0.8)','rgba(245,158,11,0.8)','rgba(139,92,246,0.8)','rgba(6,182,212,0.8)','rgba(239,68,68,0.8)','rgba(236,72,153,0.8)','rgba(99,102,241,0.8)'],
            };

            const ratingsData = @json($therapistRatings);
            if (document.getElementById('therapistRatingsChart')) {
                new Chart(document.getElementById('therapistRatingsChart'), {
                    type: 'bar',
                    data: { labels: ratingsData.map(r => r.name), datasets: [{ label: '{{ __("average_rating") }}', data: ratingsData.map(r => r.average_rating), backgroundColor: chartColors.palette.slice(0, ratingsData.length), borderRadius: 6, maxBarThickness: 40 }] },
                    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, max: 5 }, x: { grid: { display: false } } } },
                });
            }

            const volumeData = @json($sessionVolume);
            if (document.getElementById('sessionVolumeChart')) {
                new Chart(document.getElementById('sessionVolumeChart'), {
                    type: 'line',
                    data: { labels: volumeData.map(v => v.label), datasets: [{ label: '{{ __("sessions") }}', data: volumeData.map(v => v.count), borderColor: chartColors.primary, backgroundColor: chartColors.primaryBg, fill: true, tension: 0.4, pointRadius: 4 }] },
                    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true }, x: { grid: { display: false } } } },
                });
            }

            const revenueData = @json($revenueTrends);
            if (document.getElementById('revenueTrendsChart')) {
                new Chart(document.getElementById('revenueTrendsChart'), {
                    type: 'line',
                    data: { labels: revenueData.map(r => r.label), datasets: [{ label: '{{ __("revenue") }} (SAR)', data: revenueData.map(r => r.amount), borderColor: chartColors.green, backgroundColor: chartColors.greenBg, fill: true, tension: 0.4, pointRadius: 4 }] },
                    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { callback: v => 'SAR ' + v.toLocaleString() } }, x: { grid: { display: false } } } },
                });
            }

            const noShowData = @json($noShowRate);
            if (document.getElementById('noShowRateChart')) {
                new Chart(document.getElementById('noShowRateChart'), {
                    type: 'doughnut',
                    data: { labels: ['{{ __("completed") }}', '{{ __("no_show") }}'], datasets: [{ data: [noShowData.total - noShowData.no_show_count, noShowData.no_show_count], backgroundColor: [chartColors.green, chartColors.red], borderWidth: 2, hoverOffset: 8 }] },
                    options: { responsive: true, maintainAspectRatio: false, cutout: '65%', plugins: { legend: { position: 'bottom' } } },
                });
            }

            const sessionTypeData = @json($sessionTypeDistribution);
            if (document.getElementById('sessionTypeChart')) {
                new Chart(document.getElementById('sessionTypeChart'), {
                    type: 'doughnut',
                    data: { labels: sessionTypeData.map(s => s.type), datasets: [{ data: sessionTypeData.map(s => s.count), backgroundColor: chartColors.palette.slice(0, sessionTypeData.length), borderWidth: 2, hoverOffset: 8 }] },
                    options: { responsive: true, maintainAspectRatio: false, cutout: '65%', plugins: { legend: { position: 'bottom' } } },
                });
            }

            const perfData = @json($clinicianPerformance);
            if (document.getElementById('clinicianPerformanceChart')) {
                new Chart(document.getElementById('clinicianPerformanceChart'), {
                    type: 'bar',
                    data: { labels: perfData.map(p => p.name), datasets: [{ label: '{{ __("completed") }}', data: perfData.map(p => p.completed_count), backgroundColor: chartColors.green, borderRadius: 4, maxBarThickness: 20 }, { label: '{{ __("no_show") }}', data: perfData.map(p => p.no_show_count), backgroundColor: chartColors.red, borderRadius: 4, maxBarThickness: 20 }] },
                    options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top' } }, scales: { x: { beginAtZero: true, stacked: true }, y: { stacked: true, grid: { display: false } } } },
                });
            }
        });
    </script>
    @endif

    {{-- Retention Section --}}
    @if($activeSection === 'retention')
    <div class="space-y-6">
        {{-- KPIs --}}
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <div class="text-sm text-gray-500 dark:text-gray-400">{{ __('at_risk_users') }}</div>
                <div class="text-3xl font-bold text-red-500 mt-1">{{ count($retentionData) }}</div>
            </div>
            @php
                $criticalCount = collect($retentionData)->where('risk_level', 'critical')->count();
                $highCount = collect($retentionData)->where('risk_level', 'high')->count();
            @endphp
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <div class="text-sm text-gray-500 dark:text-gray-400">{{ __('critical_risk') }}</div>
                <div class="text-3xl font-bold text-red-600 mt-1">{{ $criticalCount }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <div class="text-sm text-gray-500 dark:text-gray-400">{{ __('high_risk') }}</div>
                <div class="text-3xl font-bold text-orange-500 mt-1">{{ $highCount }}</div>
            </div>
        </div>

        {{-- Engagement Distribution Chart --}}
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">{{ __('engagement_distribution') }}</h3>
            <div class="relative h-64">
                <canvas id="engagementDistChart"></canvas>
            </div>
        </div>

        {{-- At-Risk Users Table --}}
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800 overflow-hidden">
            <div class="p-6 border-b border-gray-200 dark:border-gray-700">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ __('at_risk_users_list') }}</h3>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="border-b border-gray-200 dark:border-gray-700">
                            <th class="text-left px-6 py-3 text-gray-500 font-medium">{{ __('name') }}</th>
                            <th class="text-left px-6 py-3 text-gray-500 font-medium">{{ __('risk_level') }}</th>
                            <th class="text-left px-6 py-3 text-gray-500 font-medium">{{ __('risk_score') }}</th>
                            <th class="text-left px-6 py-3 text-gray-500 font-medium">{{ __('engagement_score') }}</th>
                            <th class="text-left px-6 py-3 text-gray-500 font-medium">{{ __('top_signal') }}</th>
                            <th class="text-left px-6 py-3 text-gray-500 font-medium">{{ __('days_inactive') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($retentionData as $riskUser)
                            <tr class="border-b border-gray-100 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30">
                                <td class="px-6 py-3 text-gray-900 dark:text-white font-medium">{{ $riskUser['user_name'] }}</td>
                                <td class="px-6 py-3">
                                    <span @class([
                                        'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                                        'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400' => $riskUser['risk_level'] === 'critical',
                                        'bg-orange-100 text-orange-700 dark:bg-orange-500/20 dark:text-orange-400' => $riskUser['risk_level'] === 'high',
                                        'bg-blue-100 text-blue-700 dark:bg-blue-500/20 dark:text-blue-400' => $riskUser['risk_level'] === 'moderate',
                                    ])>
                                        {{ ucfirst($riskUser['risk_level']) }}
                                    </span>
                                </td>
                                <td class="px-6 py-3 text-gray-900 dark:text-white">{{ $riskUser['risk_score'] }}/100</td>
                                <td class="px-6 py-3 text-gray-900 dark:text-white">{{ $riskUser['engagement_score'] }}/100</td>
                                <td class="px-6 py-3 text-gray-500 dark:text-gray-400 truncate max-w-xs">{{ $riskUser['top_signal'] }}</td>
                                <td class="px-6 py-3 text-gray-900 dark:text-white">{{ $riskUser['days_inactive'] }}d</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="px-6 py-8 text-center text-gray-500">{{ __('no_at_risk_patients') }}</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const engDist = @json($engagementDistribution);
            if (document.getElementById('engagementDistChart')) {
                new Chart(document.getElementById('engagementDistChart'), {
                    type: 'bar',
                    data: {
                        labels: Object.keys(engDist),
                        datasets: [{
                            label: '{{ __("users") }}',
                            data: Object.values(engDist),
                            backgroundColor: ['rgba(239,68,68,0.7)', 'rgba(245,158,11,0.7)', 'rgba(74,144,217,0.7)', 'rgba(139,92,246,0.7)', 'rgba(16,185,129,0.7)'],
                            borderRadius: 6, maxBarThickness: 60,
                        }],
                    },
                    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true }, x: { grid: { display: false } } } },
                });
            }
        });
    </script>
    @endif

    {{-- Community Section --}}
    @if($activeSection === 'community_section')
    <div class="space-y-6">
        {{-- Stats --}}
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 text-center">
                <div class="text-3xl font-bold text-blue-500">{{ $communityHealth['total_posts_30d'] ?? 0 }}</div>
                <div class="text-xs text-gray-500 mt-1">{{ __('posts_last_30d') }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 text-center">
                <div class="text-3xl font-bold text-green-500">{{ $communityHealth['posts_per_day'] ?? 0 }}</div>
                <div class="text-xs text-gray-500 mt-1">{{ __('avg_posts_per_day') }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 text-center">
                <div class="text-3xl font-bold text-purple-500">{{ $communityHealth['active_contributors'] ?? 0 }}</div>
                <div class="text-xs text-gray-500 mt-1">{{ __('active_contributors') }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 text-center">
                <div class="text-3xl font-bold text-yellow-500">{{ $communityHealth['total_reactions'] ?? 0 }}</div>
                <div class="text-xs text-gray-500 mt-1">{{ __('total_reactions') }}</div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            {{-- Daily Posts Chart --}}
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">{{ __('posts_per_day') }}</h3>
                <div class="relative h-64">
                    <canvas id="dailyPostsChart"></canvas>
                </div>
            </div>

            {{-- Category Distribution --}}
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">{{ __('category_distribution') }}</h3>
                <div class="relative h-64">
                    <canvas id="categoryDistChart"></canvas>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const dailyPosts = @json($communityHealth['daily_posts'] ?? []);
            const catDist = @json($communityHealth['category_distribution'] ?? []);
            const palette = ['rgba(74,144,217,0.8)','rgba(16,185,129,0.8)','rgba(245,158,11,0.8)','rgba(139,92,246,0.8)','rgba(6,182,212,0.8)','rgba(239,68,68,0.8)'];

            if (document.getElementById('dailyPostsChart')) {
                const sortedDates = Object.keys(dailyPosts).sort();
                new Chart(document.getElementById('dailyPostsChart'), {
                    type: 'line',
                    data: { labels: sortedDates, datasets: [{ label: '{{ __("posts") }}', data: sortedDates.map(d => dailyPosts[d]), borderColor: 'rgba(74,144,217,1)', backgroundColor: 'rgba(74,144,217,0.15)', fill: true, tension: 0.4, pointRadius: 3 }] },
                    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true }, x: { display: false } } },
                });
            }

            if (document.getElementById('categoryDistChart')) {
                new Chart(document.getElementById('categoryDistChart'), {
                    type: 'doughnut',
                    data: { labels: Object.keys(catDist).map(c => c.charAt(0).toUpperCase() + c.slice(1)), datasets: [{ data: Object.values(catDist), backgroundColor: palette, borderWidth: 0 }] },
                    options: { responsive: true, maintainAspectRatio: false, cutout: '60%', plugins: { legend: { position: 'bottom', labels: { color: '#9ca3af' } } } },
                });
            }
        });
    </script>
    @endif

    {{-- Habits Section --}}
    @if($activeSection === 'habits')
    <div class="space-y-6">
        {{-- Stats --}}
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 text-center">
                <div class="text-3xl font-bold text-green-500">{{ $challengeAnalytics['total_completions'] ?? 0 }}</div>
                <div class="text-xs text-gray-500 mt-1">{{ __('total_challenge_completions') }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 text-center">
                <div class="text-3xl font-bold text-blue-500">{{ $challengeAnalytics['unique_users'] ?? 0 }}</div>
                <div class="text-xs text-gray-500 mt-1">{{ __('active_challengers') }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 text-center">
                <div class="text-3xl font-bold text-purple-500">{{ $challengeAnalytics['completion_rate'] ?? 0 }}</div>
                <div class="text-xs text-gray-500 mt-1">{{ __('avg_completions_per_user') }}</div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            {{-- Streak Distribution --}}
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">{{ __('streak_distribution') }}</h3>
                <div class="relative h-64">
                    <canvas id="streakDistChart"></canvas>
                </div>
            </div>

            {{-- Most Popular Challenges --}}
            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">{{ __('most_popular_challenges') }}</h3>
                <div class="space-y-3">
                    @forelse($challengeAnalytics['most_popular'] ?? [] as $name => $count)
                        <div class="flex items-center justify-between">
                            <span class="text-sm text-gray-700 dark:text-gray-300">{{ $name }}</span>
                            <span class="text-sm font-medium text-gray-900 dark:text-white">{{ $count }}</span>
                        </div>
                        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                            @php $maxCount = max(1, max(array_values($challengeAnalytics['most_popular'] ?? [1]))); @endphp
                            <div class="bg-green-500 h-1.5 rounded-full" style="width: {{ ($count / $maxCount) * 100 }}%"></div>
                        </div>
                    @empty
                        <p class="text-sm text-gray-500">{{ __('no_records_found') }}</p>
                    @endforelse
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const streakDist = @json($challengeAnalytics['streak_distribution'] ?? []);
            if (document.getElementById('streakDistChart')) {
                new Chart(document.getElementById('streakDistChart'), {
                    type: 'bar',
                    data: {
                        labels: Object.keys(streakDist),
                        datasets: [{
                            label: '{{ __("users") }}',
                            data: Object.values(streakDist),
                            backgroundColor: ['rgba(239,68,68,0.7)', 'rgba(245,158,11,0.7)', 'rgba(74,144,217,0.7)', 'rgba(139,92,246,0.7)', 'rgba(16,185,129,0.7)'],
                            borderRadius: 6, maxBarThickness: 60,
                        }],
                    },
                    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true }, x: { grid: { display: false } } } },
                });
            }
        });
    </script>
    @endif

    {{-- AI Platform Insights Section --}}
    @if($activeSection === 'ai_platform_insights')
    <div class="space-y-6">
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ __('ai_platform_analysis') }}</h3>
                <button
                    wire:click="generateAiPlatformSummary"
                    wire:loading.attr="disabled"
                    class="inline-flex items-center gap-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors disabled:opacity-50 text-sm"
                >
                    <span wire:loading.remove wire:target="generateAiPlatformSummary">
                        <x-heroicon-o-sparkles class="w-4 h-4" />
                    </span>
                    <span wire:loading wire:target="generateAiPlatformSummary">
                        <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                    </span>
                    {{ __('generate_platform_summary') }}
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
            @elseif(!empty($aiPlatformSummary))
                <div class="prose prose-sm dark:prose-invert max-w-none bg-gray-50 dark:bg-gray-900/50 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
                    {!! \Illuminate\Support\Str::markdown($aiPlatformSummary) !!}
                </div>
            @else
                <div class="flex flex-col items-center justify-center py-12 text-gray-400">
                    <x-heroicon-o-sparkles class="w-12 h-12 mb-3 text-gray-400" />
                    <p class="text-sm">{{ __('click_generate_platform_insights') }}</p>
                </div>
            @endif
        </div>
    </div>
    @endif
</x-filament-panels::page>
