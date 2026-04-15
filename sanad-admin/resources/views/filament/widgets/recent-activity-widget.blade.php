<x-filament-widgets::widget class="fi-recent-activity-widget">
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="mb-4 text-lg font-semibold text-gray-900 dark:text-white">{{ __('recent_activity') }}</h2>

        @php
            $activities = $this->getActivities();
        @endphp

        @if (count($activities) > 0)
            <div class="space-y-4">
                @foreach ($activities as $activity)
                    @php
                        $type = $activity->type ?? 'default';
                        $typeIcon = $this->getTypeIcon($type);
                        $typeColor = $this->getTypeColor($type);
                        $typeBgColor = $this->getTypeBgColor($type);
                        $timestamp = $activity->timestamp ?? null;
                        $relativeTime = $timestamp
                            ? \Carbon\Carbon::parse($timestamp)->diffForHumans()
                            : __('unknown_time');
                    @endphp

                    <div class="flex items-start gap-4">
                         {{-- Timeline Line (Visual only, optional) --}}
                        <div class="relative flex flex-col items-center">
                            <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gray-50 dark:bg-gray-700">
                                <x-dynamic-component
                                    :component="$typeIcon"
                                    class="h-5 w-5 {{ $typeColor }}"
                                />
                            </div>
                        </div>

                        <div class="min-w-0 flex-1 pt-1.5">
                            <div class="flex items-center justify-between gap-2">
                                <p class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ $activity->user_name ?? __('unknown_user') }}
                                </p>
                                <span class="text-xs text-gray-500 dark:text-gray-400">
                                    {{ $relativeTime }}
                                </span>
                            </div>
                            <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">
                                {{ $activity->description ?? __('no_description') }}
                            </p>
                        </div>
                    </div>
                @endforeach
            </div>
        @else
            <div class="flex flex-col items-center justify-center py-8">
                <x-heroicon-o-clock class="mb-2 h-8 w-8 text-gray-400 dark:text-gray-500" />
                <p class="text-sm text-gray-500 dark:text-gray-400">{{ __('no_recent_activity') }}</p>
            </div>
        @endif
    </div>
</x-filament-widgets::widget>
