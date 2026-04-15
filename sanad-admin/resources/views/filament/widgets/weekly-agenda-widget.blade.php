<x-filament-widgets::widget class="fi-weekly-agenda-widget">
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="mb-4 text-lg font-semibold text-gray-900 dark:text-white">{{ __('weekly_agenda') }}</h2>

        @php
            $weekData = $this->getWeekData();
            $today = now()->format('Y-m-d');
            $todayBookings = $weekData[$today]['bookings'] ?? [];
        @endphp

        {{-- Week strip --}}
        <div class="mb-6 flex items-center gap-2 overflow-x-auto pb-2">
            @foreach ($weekData as $dateKey => $day)
                <div
                    class="flex min-w-[4rem] flex-col items-center gap-1 rounded-xl px-3 py-2 transition-colors duration-200
                        {{ $day['isToday']
                            ? 'border border-primary-200 bg-primary-50 ring-1 ring-primary-500/20 dark:border-primary-700 dark:bg-primary-900/20'
                            : 'border border-gray-100 bg-gray-50 dark:border-gray-700 dark:bg-gray-800' }}"
                >
                    <span class="text-xs font-medium {{ $day['isToday'] ? 'text-primary-600 dark:text-primary-400' : 'text-gray-500 dark:text-gray-400' }}">
                        {{ $day['label'] }}
                    </span>
                    <span class="text-sm font-semibold {{ $day['isToday'] ? 'text-primary-700 dark:text-primary-300' : 'text-gray-700 dark:text-gray-300' }}">
                        {{ \Illuminate\Support\Str::after($day['date'], ' ') }}
                    </span>
                    @if (count($day['bookings']) > 0)
                        <span
                            class="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full px-1 text-[10px] font-bold
                                {{ $day['isToday']
                                    ? 'bg-primary-600 text-white dark:bg-primary-500'
                                    : 'bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-300' }}"
                        >
                            {{ count($day['bookings']) }}
                        </span>
                    @else
                        <span class="h-5 min-w-[1.25rem]"></span>
                    @endif
                </div>
            @endforeach
        </div>

        {{-- Today's bookings --}}
        <div>
            <h4 class="mb-3 text-sm font-semibold text-gray-500 dark:text-gray-400">
                {{ __('todays_schedule') }}
            </h4>

            @if (count($todayBookings) > 0)
                <div class="space-y-3">
                    @foreach ($todayBookings as $booking)
                        <div class="flex items-center gap-3 rounded-lg border border-gray-100 bg-white p-3 shadow-sm transition-colors duration-200 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700/50">
                            <div class="flex h-9 w-9 items-center justify-center rounded-lg bg-primary-50 text-primary-600 dark:bg-primary-900/20 dark:text-primary-400">
                                <x-dynamic-component
                                    :component="$this->getSessionIcon($booking->session_type ?? 'default')"
                                    class="h-5 w-5"
                                />
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="truncate text-sm font-medium text-gray-900 dark:text-white">
                                    {{ $booking->client_name ?? __('unknown_client') }}
                                </p>
                                <p class="text-xs text-gray-500 dark:text-gray-400">
                                    {{ \Carbon\Carbon::parse($booking->scheduled_time)->format('h:i A') }}
                                    @if ($booking->session_type)
                                        &middot; {{ ucfirst(str_replace('_', ' ', $booking->session_type)) }}
                                    @endif
                                </p>
                            </div>
                        </div>
                    @endforeach
                </div>
            @else
                <div class="flex flex-col items-center justify-center rounded-xl border border-gray-200 bg-white py-8 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                    <x-heroicon-o-calendar-days class="mb-2 h-8 w-8 text-gray-400 dark:text-gray-500" />
                    <p class="text-sm text-gray-500 dark:text-gray-400">{{ __('no_sessions_today') }}</p>
                </div>
            @endif
        </div>
    </div>
</x-filament-widgets::widget>
