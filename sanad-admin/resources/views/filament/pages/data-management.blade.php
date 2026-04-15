<x-filament-panels::page>
    {{-- Export Section --}}
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <div class="mb-6">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-200">
                {{ __('export_data') }}
            </h2>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-500">
                {{ __('export_data_description') }}
            </p>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {{-- Export Users CSV --}}
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 transition-colors duration-200 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-700/50 dark:hover:bg-gray-700">
                <div class="mb-4 flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-500/10">
                        <x-heroicon-o-users class="h-5 w-5 text-primary-600 dark:text-primary-400" />
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-gray-900 dark:text-gray-200">{{ __('export_users') }}</h3>
                        <p class="text-xs text-gray-500">CSV</p>
                    </div>
                </div>
                <button
                    wire:click="exportUsersCsv"
                    wire:loading.attr="disabled"
                    class="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                >
                    <x-heroicon-o-arrow-down-tray class="h-4 w-4" />
                    <span wire:loading.remove wire:target="exportUsersCsv">{{ __('download') }}</span>
                    <span wire:loading wire:target="exportUsersCsv">{{ __('exporting') }}...</span>
                </button>
            </div>

            {{-- Export Users PDF --}}
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 transition-colors duration-200 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-700/50 dark:hover:bg-gray-700">
                <div class="mb-4 flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-500/10">
                        <x-heroicon-o-users class="h-5 w-5 text-primary-600 dark:text-primary-400" />
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-gray-900 dark:text-gray-200">{{ __('export_users') }}</h3>
                        <p class="text-xs text-gray-500">PDF</p>
                    </div>
                </div>
                <button
                    wire:click="exportUsersPdf"
                    wire:loading.attr="disabled"
                    class="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                >
                    <x-heroicon-o-arrow-down-tray class="h-4 w-4" />
                    <span wire:loading.remove wire:target="exportUsersPdf">{{ __('download') }}</span>
                    <span wire:loading wire:target="exportUsersPdf">{{ __('exporting') }}...</span>
                </button>
            </div>

            {{-- Export Bookings CSV --}}
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 transition-colors duration-200 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-700/50 dark:hover:bg-gray-700">
                <div class="mb-4 flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100 dark:bg-green-500/10">
                        <x-heroicon-o-calendar-days class="h-5 w-5 text-green-600 dark:text-green-400" />
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-gray-900 dark:text-gray-200">{{ __('export_bookings') }}</h3>
                        <p class="text-xs text-gray-500">CSV</p>
                    </div>
                </div>
                <button
                    wire:click="exportBookingsCsv"
                    wire:loading.attr="disabled"
                    class="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                >
                    <x-heroicon-o-arrow-down-tray class="h-4 w-4" />
                    <span wire:loading.remove wire:target="exportBookingsCsv">{{ __('download') }}</span>
                    <span wire:loading wire:target="exportBookingsCsv">{{ __('exporting') }}...</span>
                </button>
            </div>

            {{-- Export Bookings PDF --}}
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 transition-colors duration-200 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-700/50 dark:hover:bg-gray-700">
                <div class="mb-4 flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100 dark:bg-green-500/10">
                        <x-heroicon-o-calendar-days class="h-5 w-5 text-green-600 dark:text-green-400" />
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-gray-900 dark:text-gray-200">{{ __('export_bookings') }}</h3>
                        <p class="text-xs text-gray-500">PDF</p>
                    </div>
                </div>
                <button
                    wire:click="exportBookingsPdf"
                    wire:loading.attr="disabled"
                    class="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                >
                    <x-heroicon-o-arrow-down-tray class="h-4 w-4" />
                    <span wire:loading.remove wire:target="exportBookingsPdf">{{ __('download') }}</span>
                    <span wire:loading wire:target="exportBookingsPdf">{{ __('exporting') }}...</span>
                </button>
            </div>

            {{-- Export Payments CSV --}}
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 transition-colors duration-200 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-700/50 dark:hover:bg-gray-700">
                <div class="mb-4 flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100 dark:bg-amber-500/10">
                        <x-heroicon-o-credit-card class="h-5 w-5 text-amber-600 dark:text-amber-400" />
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-gray-900 dark:text-gray-200">{{ __('export_payments') }}</h3>
                        <p class="text-xs text-gray-500">CSV</p>
                    </div>
                </div>
                <button
                    wire:click="exportPaymentsCsv"
                    wire:loading.attr="disabled"
                    class="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                >
                    <x-heroicon-o-arrow-down-tray class="h-4 w-4" />
                    <span wire:loading.remove wire:target="exportPaymentsCsv">{{ __('download') }}</span>
                    <span wire:loading wire:target="exportPaymentsCsv">{{ __('exporting') }}...</span>
                </button>
            </div>

            {{-- Export Payments PDF --}}
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 transition-colors duration-200 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-700/50 dark:hover:bg-gray-700">
                <div class="mb-4 flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100 dark:bg-amber-500/10">
                        <x-heroicon-o-credit-card class="h-5 w-5 text-amber-600 dark:text-amber-400" />
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-gray-900 dark:text-gray-200">{{ __('export_payments') }}</h3>
                        <p class="text-xs text-gray-500">PDF</p>
                    </div>
                </div>
                <button
                    wire:click="exportPaymentsPdf"
                    wire:loading.attr="disabled"
                    class="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                >
                    <x-heroicon-o-arrow-down-tray class="h-4 w-4" />
                    <span wire:loading.remove wire:target="exportPaymentsPdf">{{ __('download') }}</span>
                    <span wire:loading wire:target="exportPaymentsPdf">{{ __('exporting') }}...</span>
                </button>
            </div>
        </div>
    </div>

    {{-- Cleanup Section --}}
    <div class="mt-6 rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <div class="mb-6">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-200">
                {{ __('data_cleanup') }}
            </h2>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-500">
                {{ __('data_cleanup_description') }}
            </p>
        </div>

        {{-- Collection Counts --}}
        @php
            $counts = $this->getCollectionCounts();
        @endphp

        <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-4 text-center dark:border-gray-700 dark:bg-gray-700/50">
                <p class="text-2xl font-bold text-primary-600 dark:text-primary-400">{{ number_format($counts['users']) }}</p>
                <p class="mt-1 text-xs text-gray-600 dark:text-gray-500">{{ __('users') }}</p>
            </div>
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-4 text-center dark:border-gray-700 dark:bg-gray-700/50">
                <p class="text-2xl font-bold text-green-600 dark:text-green-400">{{ number_format($counts['bookings']) }}</p>
                <p class="mt-1 text-xs text-gray-600 dark:text-gray-500">{{ __('bookings') }}</p>
            </div>
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-4 text-center dark:border-gray-700 dark:bg-gray-700/50">
                <p class="text-2xl font-bold text-amber-600 dark:text-amber-400">{{ number_format($counts['payments']) }}</p>
                <p class="mt-1 text-xs text-gray-600 dark:text-gray-500">{{ __('payments') }}</p>
            </div>
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-4 text-center dark:border-gray-700 dark:bg-gray-700/50">
                <p class="text-2xl font-bold text-cyan-600 dark:text-cyan-400">{{ number_format($counts['activity_logs']) }}</p>
                <p class="mt-1 text-xs text-gray-600 dark:text-gray-500">{{ __('activity_logs') }}</p>
            </div>
        </div>

        {{-- Archive Action --}}
        <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 dark:border-gray-700 dark:bg-gray-700/50">
            <div class="flex items-center justify-between">
                <div>
                    <h3 class="text-sm font-medium text-gray-900 dark:text-gray-200">{{ __('archive_old_logs') }}</h3>
                    <p class="mt-1 text-xs text-gray-600 dark:text-gray-500">
                        {{ __('archive_old_logs_description') }}
                    </p>
                </div>
                <button
                    wire:click="archiveOldActivityLogs"
                    wire:loading.attr="disabled"
                    wire:confirm="{{ __('archive_confirm') }}"
                    class="inline-flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-2 text-sm font-medium text-red-700 transition-all duration-200 hover:bg-red-100 disabled:opacity-50 dark:border-red-500/20 dark:bg-red-500/10 dark:text-red-400 dark:hover:bg-red-500/20"
                >
                    <x-heroicon-o-archive-box class="h-4 w-4" />
                    <span wire:loading.remove wire:target="archiveOldActivityLogs">{{ __('archive') }}</span>
                    <span wire:loading wire:target="archiveOldActivityLogs">{{ __('archiving') }}...</span>
                </button>
            </div>
        </div>
    </div>
</x-filament-panels::page>
