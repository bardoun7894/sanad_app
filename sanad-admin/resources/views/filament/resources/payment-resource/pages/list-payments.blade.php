<x-filament-panels::page>
    {{-- ── Stat Cards (3x2 Grid) ──────────────────────────────── --}}
    <div class="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {{-- Total Revenue --}}
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-5">
            <div class="flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-success-500/20">
                    <x-heroicon-o-currency-dollar class="h-5 w-5 text-success-400" />
                </div>
                <div>
                    <p class="text-xs font-medium text-gray-400">{{ __('total_revenue') }}</p>
                    <p class="text-xl font-bold text-gray-100">{{ $totalRevenue }}</p>
                </div>
            </div>
        </div>

        {{-- This Month Revenue --}}
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-5">
            <div class="flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-500/20">
                    <x-heroicon-o-calendar-days class="h-5 w-5 text-primary-400" />
                </div>
                <div>
                    <p class="text-xs font-medium text-gray-400">{{ __('month_revenue') }}</p>
                    <p class="text-xl font-bold text-gray-100">{{ $monthRevenue }}</p>
                </div>
            </div>
        </div>

        {{-- Average Transaction --}}
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-5">
            <div class="flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-info-500/20">
                    <x-heroicon-o-calculator class="h-5 w-5 text-info-400" />
                </div>
                <div>
                    <p class="text-xs font-medium text-gray-400">{{ __('avg_transaction') }}</p>
                    <p class="text-xl font-bold text-gray-100">{{ $avgTransaction }}</p>
                </div>
            </div>
        </div>

        {{-- Conversion Rate --}}
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-5">
            <div class="flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-warning-500/20">
                    <x-heroicon-o-arrow-trending-up class="h-5 w-5 text-warning-400" />
                </div>
                <div>
                    <p class="text-xs font-medium text-gray-400">{{ __('conversion_rate') }}</p>
                    <p class="text-xl font-bold text-gray-100">{{ $conversionRate }}</p>
                </div>
            </div>
        </div>

        {{-- Payment Success Rate --}}
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-5">
            <div class="flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-success-500/20">
                    <x-heroicon-o-check-badge class="h-5 w-5 text-success-400" />
                </div>
                <div>
                    <p class="text-xs font-medium text-gray-400">{{ __('success_rate') }}</p>
                    <p class="text-xl font-bold text-gray-100">{{ $successRate }}</p>
                </div>
            </div>
        </div>

        {{-- Verification Approval Rate --}}
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-5">
            <div class="flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-500/20">
                    <x-heroicon-o-shield-check class="h-5 w-5 text-primary-400" />
                </div>
                <div>
                    <p class="text-xs font-medium text-gray-400">{{ __('approval_rate') }}</p>
                    <p class="text-xl font-bold text-gray-100">{{ $approvalRate }}</p>
                </div>
            </div>
        </div>
    </div>

    {{-- ── Tab Navigation ───────────────────────────────────── --}}
    <div class="mb-6 flex flex-wrap items-center gap-3">
        <button
            wire:click="switchTab('all')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-primary-500/20 text-primary-400 border border-primary-500/30 shadow-sm' => $activeTab === 'all',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'all',
            ])
        >
            <x-heroicon-o-banknotes class="h-4 w-4" />
            {{ __('all') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary-500/30 px-1.5 text-xs font-semibold text-primary-300">
                {{ $allCount }}
            </span>
        </button>

        <button
            wire:click="switchTab('completed')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-success-500/20 text-success-400 border border-success-500/30 shadow-sm' => $activeTab === 'completed',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'completed',
            ])
        >
            <x-heroicon-o-check-circle class="h-4 w-4" />
            {{ __('completed') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-success-500/30 px-1.5 text-xs font-semibold text-success-300">
                {{ $completedCount }}
            </span>
        </button>

        <button
            wire:click="switchTab('pending')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-warning-500/20 text-warning-400 border border-warning-500/30 shadow-sm' => $activeTab === 'pending',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'pending',
            ])
        >
            <x-heroicon-o-clock class="h-4 w-4" />
            {{ __('pending') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-warning-500/30 px-1.5 text-xs font-semibold text-warning-300">
                {{ $pendingCount }}
            </span>
        </button>

        <button
            wire:click="switchTab('failed')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-danger-500/20 text-danger-400 border border-danger-500/30 shadow-sm' => $activeTab === 'failed',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'failed',
            ])
        >
            <x-heroicon-o-x-circle class="h-4 w-4" />
            {{ __('failed') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-danger-500/30 px-1.5 text-xs font-semibold text-danger-300">
                {{ $failedCount }}
            </span>
        </button>
    </div>

    {{-- ── Search + Export Bar ───────────────────────────────── --}}
    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="relative w-full sm:max-w-sm">
            <x-heroicon-o-magnifying-glass class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
                wire:model.live.debounce.300ms="search"
                type="text"
                placeholder="{{ __('search_payments') }}"
                class="w-full rounded-xl border border-white/10 bg-white/5 py-2.5 pl-10 pr-4 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
            />
        </div>

        <div class="flex items-center gap-2">
            <button
                wire:click="exportCsv"
                class="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm font-medium text-gray-300 backdrop-blur-xl transition hover:bg-white/10 hover:text-white"
            >
                <x-heroicon-o-document-arrow-down class="h-4 w-4" />
                {{ __('export_csv') }}
            </button>
            <button
                wire:click="exportPdf"
                class="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm font-medium text-gray-300 backdrop-blur-xl transition hover:bg-white/10 hover:text-white"
            >
                <x-heroicon-o-document-text class="h-4 w-4" />
                {{ __('export_pdf') }}
            </button>
        </div>
    </div>

    {{-- ── Payments Table ──────────────────────────────────── --}}
    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <table class="w-full text-left text-sm">
            <thead>
                <tr class="border-b border-white/10 bg-white/5">
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('email') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('amount') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('status') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('payment_method') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('transaction_id') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('created_at') }}</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
                @forelse ($payments as $payment)
                    @php
                        $statusColor = $payment->getStatusColor();
                    @endphp
                    <tr class="transition hover:bg-white/5">
                        {{-- Email --}}
                        <td class="px-6 py-4">
                            <span class="font-medium text-gray-200">{{ $payment->safeGet('user_email') }}</span>
                            @if ($payment->getAttribute('product_title'))
                                <div class="text-xs text-gray-500">{{ $payment->safeGet('product_title') }}</div>
                            @endif
                        </td>

                        {{-- Amount --}}
                        <td class="px-6 py-4 font-semibold text-gray-200">
                            {{ $payment->getFormattedAmount() }}
                        </td>

                        {{-- Status --}}
                        <td class="px-6 py-4">
                            <span @class([
                                'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold',
                                'bg-success-500/20 text-success-400' => $statusColor === 'success',
                                'bg-warning-500/20 text-warning-400' => $statusColor === 'warning',
                                'bg-danger-500/20 text-danger-400'   => $statusColor === 'danger',
                                'bg-info-500/20 text-info-400'       => $statusColor === 'info',
                                'bg-gray-500/20 text-gray-400'       => $statusColor === 'gray',
                            ])>
                                {{ __($payment->safeGet('status', 'unknown')) }}
                            </span>
                        </td>

                        {{-- Payment Method --}}
                        <td class="px-6 py-4 text-gray-300">
                            {{ $payment->safeGet('payment_method', '-') }}
                        </td>

                        {{-- Transaction ID --}}
                        <td class="px-6 py-4 text-gray-400 text-xs font-mono">
                            {{ $payment->safeGet('gateway_transaction_id', '-') }}
                        </td>

                        {{-- Created At --}}
                        <td class="px-6 py-4 text-gray-400">
                            {{ $payment->safeGet('created_at', '-') }}
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-gray-500">
                            <div class="flex flex-col items-center gap-2">
                                <x-heroicon-o-banknotes class="h-8 w-8 text-gray-600" />
                                <span>{{ __('no_payments_found') }}</span>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{-- ── Pagination Controls ─────────────────────────────────── --}}
    @if (!empty($cursorStack) || $hasMore)
        <div class="mt-6 flex items-center justify-between">
            <button
                wire:click="previousPage"
                @if (empty($cursorStack)) disabled @endif
                @class([
                    'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                    'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => !empty($cursorStack),
                    'bg-white/5 text-gray-600 border border-white/5 cursor-not-allowed' => empty($cursorStack),
                ])
            >
                <x-heroicon-o-chevron-left class="h-4 w-4" />
                {{ __('previous') }}
            </button>

            <div class="text-sm text-gray-400">
                {{ __('showing_results_per_page', ['count' => count($payments), 'per_page' => $perPage]) }}
            </div>

            <button
                wire:click="nextPage"
                @if (!$hasMore) disabled @endif
                @class([
                    'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                    'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $hasMore,
                    'bg-white/5 text-gray-600 border border-white/5 cursor-not-allowed' => !$hasMore,
                ])
            >
                {{ __('next') }}
                <x-heroicon-o-chevron-right class="h-4 w-4" />
            </button>
        </div>
    @endif
</x-filament-panels::page>
