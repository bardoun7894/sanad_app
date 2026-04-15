<x-filament-widgets::widget class="fi-quick-actions-widget">
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="mb-4 text-lg font-semibold text-gray-900 dark:text-white">{{ __('quick_actions') }}</h2>

        <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
            @foreach ($this->getActions() as $action)
                <a
                    href="{{ $action['url'] }}"
                    class="group flex flex-col items-center gap-3 rounded-xl border border-gray-200 bg-gray-50 p-4 shadow-sm transition-all duration-200 hover:-translate-y-1 hover:shadow-md dark:border-gray-700 dark:bg-gray-900/50"
                >
                    @php
                        $colorClasses = match($action['color']) {
                            'primary' => 'text-primary-600 bg-white dark:text-primary-400 dark:bg-gray-800',
                            'success' => 'text-green-600 bg-white dark:text-green-400 dark:bg-gray-800',
                            'info' => 'text-cyan-600 bg-white dark:text-cyan-400 dark:bg-gray-800',
                            'warning' => 'text-amber-600 bg-white dark:text-amber-400 dark:bg-gray-800',
                            default => 'text-gray-600 bg-white dark:text-gray-400 dark:bg-gray-800',
                        };
                    @endphp

                    <div class="flex h-12 w-12 items-center justify-center rounded-full shadow-sm {{ $colorClasses }} transition-colors duration-200">
                        <x-dynamic-component
                            :component="$action['icon']"
                            class="h-6 w-6"
                        />
                    </div>

                    <span class="text-sm font-medium text-gray-700 transition-colors duration-200 group-hover:text-primary-600 dark:text-gray-300 dark:group-hover:text-primary-400">
                        {{ $action['label'] }}
                    </span>
                </a>
            @endforeach
        </div>
    </div>
</x-filament-widgets::widget>
