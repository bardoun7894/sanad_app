<x-filament-widgets::widget class="fi-habit-progress-widget">
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="mb-4 text-lg font-semibold text-gray-900 dark:text-white">{{ __('habit_progress') }}</h2>

        @php $data = $this->getData(); @endphp

        <div class="space-y-4">
            <div class="flex items-center justify-between rounded-lg bg-green-50 dark:bg-green-500/10 p-4">
                <div>
                    <div class="text-xs text-green-600 dark:text-green-300">{{ __('total_challenge_completions') }}</div>
                    <div class="text-2xl font-bold text-green-700 dark:text-green-400">{{ $data['total_completions'] }}</div>
                </div>
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100 dark:bg-green-500/20">
                    <x-heroicon-o-trophy class="h-5 w-5 text-green-600 dark:text-green-400" />
                </div>
            </div>

            <div class="flex items-center justify-between rounded-lg bg-blue-50 dark:bg-blue-500/10 p-4">
                <div>
                    <div class="text-xs text-blue-600 dark:text-blue-300">{{ __('active_challengers') }}</div>
                    <div class="text-2xl font-bold text-blue-700 dark:text-blue-400">{{ $data['unique_users'] }}</div>
                </div>
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-100 dark:bg-blue-500/20">
                    <x-heroicon-o-user-group class="h-5 w-5 text-blue-600 dark:text-blue-400" />
                </div>
            </div>

            <div class="flex items-center justify-between rounded-lg bg-purple-50 dark:bg-purple-500/10 p-4">
                <div>
                    <div class="text-xs text-purple-600 dark:text-purple-300">{{ __('avg_completions_per_user') }}</div>
                    <div class="text-2xl font-bold text-purple-700 dark:text-purple-400">{{ $data['completion_rate'] }}</div>
                </div>
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-purple-100 dark:bg-purple-500/20">
                    <x-heroicon-o-chart-bar class="h-5 w-5 text-purple-600 dark:text-purple-400" />
                </div>
            </div>
        </div>
    </div>
</x-filament-widgets::widget>
