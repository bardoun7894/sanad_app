<x-filament-widgets::widget class="fi-community-health-widget">
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="mb-4 text-lg font-semibold text-gray-900 dark:text-white">{{ __('community_health') }}</h2>

        @php $data = $this->getData(); @endphp

        <div class="grid grid-cols-2 gap-3">
            <div class="rounded-lg bg-blue-50 dark:bg-blue-500/10 p-3 text-center">
                <div class="text-xl font-bold text-blue-600 dark:text-blue-400">{{ $data['total_posts_30d'] }}</div>
                <div class="text-xs text-blue-500 dark:text-blue-300">{{ __('posts_this_month') }}</div>
            </div>
            <div class="rounded-lg bg-green-50 dark:bg-green-500/10 p-3 text-center">
                <div class="text-xl font-bold text-green-600 dark:text-green-400">{{ $data['posts_per_day'] }}</div>
                <div class="text-xs text-green-500 dark:text-green-300">{{ __('avg_posts_per_day') }}</div>
            </div>
            <div class="rounded-lg bg-purple-50 dark:bg-purple-500/10 p-3 text-center">
                <div class="text-xl font-bold text-purple-600 dark:text-purple-400">{{ $data['active_contributors'] }}</div>
                <div class="text-xs text-purple-500 dark:text-purple-300">{{ __('active_contributors') }}</div>
            </div>
            <div class="rounded-lg bg-yellow-50 dark:bg-yellow-500/10 p-3 text-center">
                <div class="text-xl font-bold text-yellow-600 dark:text-yellow-400">{{ $data['total_reactions'] }}</div>
                <div class="text-xs text-yellow-500 dark:text-yellow-300">{{ __('total_reactions') }}</div>
            </div>
        </div>
    </div>
</x-filament-widgets::widget>
