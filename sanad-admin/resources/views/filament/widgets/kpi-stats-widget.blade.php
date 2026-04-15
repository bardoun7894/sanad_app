<x-filament-widgets::widget class="fi-kpi-stats-widget">
    <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        @foreach ($this->getCachedStats() as $stat)
            @php
                $color = $stat['color'] ?? 'gray';
                $colorClasses = match ($color) {
                    'primary' => 'text-primary-600 dark:text-primary-400 bg-primary-50 dark:bg-primary-900/10',
                    'success' => 'text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/10',
                    'danger' => 'text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/10',
                    'warning' => 'text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/10',
                    default => 'text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-700/50',
                };
                
                $iconColorClasses = match ($color) {
                     'primary' => 'text-primary-500 dark:text-primary-400',
                     'success' => 'text-green-500 dark:text-green-400',
                     'danger' => 'text-red-500 dark:text-red-400',
                     'warning' => 'text-amber-500 dark:text-amber-400',
                     default => 'text-gray-500 dark:text-gray-400',
                };
            @endphp

            <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 transition-all duration-200 hover:-translate-y-1 hover:shadow-md">
                <div class="flex items-center justify-between gap-x-2">
                    <span class="text-sm font-medium text-gray-500 dark:text-gray-400">
                        {{ $stat['label'] }}
                    </span>
                    <div class="flex h-8 w-8 items-center justify-center rounded-lg {{ $colorClasses }}">
                         <x-dynamic-component
                            :component="$stat['icon']"
                            class="h-5 w-5"
                        />
                    </div>
                </div>

                <div class="mt-4 text-3xl font-bold tracking-tight text-gray-950 dark:text-white">
                    {{ $stat['value'] }}
                </div>

                <div class="mt-4 flex items-center justify-between">
                    <div class="flex items-center gap-x-1 {{ $stat['descriptionColor'] === 'success' ? 'text-green-600 dark:text-green-400' : ($stat['descriptionColor'] === 'danger' ? 'text-red-600 dark:text-red-400' : 'text-gray-500') }}">
                        @if ($stat['descriptionIcon'])
                            <x-dynamic-component
                                :component="$stat['descriptionIcon']"
                                class="h-4 w-4"
                            />
                        @endif
                        <span class="text-xs font-medium">
                            {{ $stat['description'] }}
                        </span>
                    </div>
                </div>
                
                 @if (! empty($stat['chart']))
                    <div class="mt-4 h-10">
                        <div x-data="{
                                chart: @js($stat['chart']),
                                backgroundColor: getComputedStyle($el).getPropertyValue('--color-{{ $color }}-50'),
                                borderColor: getComputedStyle($el).getPropertyValue('--color-{{ $color }}-500'),
                            }"
                            x-init=""
                            class="flex h-full items-end gap-1"
                        >
                            <template x-for="(point, index) in chart" :key="index">
                                <div
                                    class="w-full rounded-sm opacity-50 transition-all duration-500 hover:opacity-100"
                                    :style="`height: ${ (point / Math.max(...chart)) * 100 }%; background-color: ${ $data.borderColor || 'currentColor' }`"
                                ></div>
                            </template>
                        </div>
                    </div>
                @endif
            </div>
        @endforeach
    </div>
</x-filament-widgets::widget>
