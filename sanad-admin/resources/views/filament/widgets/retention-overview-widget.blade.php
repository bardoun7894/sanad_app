<x-filament-widgets::widget class="fi-retention-overview-widget">
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="mb-4 text-lg font-semibold text-gray-900 dark:text-white">{{ __('retention_overview') }}</h2>

        @php $data = $this->getData(); @endphp

        <div class="grid grid-cols-2 gap-3 mb-4">
            <div class="rounded-lg bg-red-50 dark:bg-red-500/10 p-3 text-center">
                <div class="text-2xl font-bold text-red-600 dark:text-red-400">{{ $data['at_risk_count'] }}</div>
                <div class="text-xs text-red-500 dark:text-red-300">{{ __('at_risk') }}</div>
            </div>
            <div class="rounded-lg bg-orange-50 dark:bg-orange-500/10 p-3 text-center">
                <div class="text-2xl font-bold text-orange-600 dark:text-orange-400">{{ $data['critical_count'] }}</div>
                <div class="text-xs text-orange-500 dark:text-orange-300">{{ __('critical') }}</div>
            </div>
        </div>

        {{-- Mini engagement bars --}}
        <div class="space-y-2">
            <p class="text-xs text-gray-500 dark:text-gray-400 font-medium">{{ __('engagement_distribution') }}</p>
            @php $maxDist = max(1, max(array_values($data['distribution']))); @endphp
            @foreach($data['distribution'] as $bracket => $count)
                <div class="flex items-center gap-2">
                    <span class="text-xs text-gray-500 w-10">{{ $bracket }}</span>
                    <div class="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                        <div class="h-2 rounded-full bg-primary-500" style="width: {{ ($count / $maxDist) * 100 }}%"></div>
                    </div>
                    <span class="text-xs text-gray-500 w-6 text-right">{{ $count }}</span>
                </div>
            @endforeach
        </div>
    </div>
</x-filament-widgets::widget>
