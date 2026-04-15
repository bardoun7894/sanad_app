<x-filament-panels::page>
    {{-- ── Header Info ─────────────────────────────────────────── --}}
    <div class="mb-6">
        <p class="text-sm text-gray-600 dark:text-gray-400">
            {{ __('pending_verifications_description') }}
        </p>
    </div>

    {{-- ── Pending Verifications List ──────────────────────────── --}}
    @if (count($verifications) > 0)
        <div class="space-y-4">
            @foreach ($verifications as $verification)
                <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm transition hover:border-gray-300 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-gray-600">
                    <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                        {{-- Left: User & Product Info --}}
                        <div class="flex-1 space-y-2">
                            <div class="flex items-center gap-3">
                                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 dark:bg-warning-500/20">
                                    <x-heroicon-o-user class="h-5 w-5 text-amber-600 dark:text-warning-400" />
                                </div>
                                <div>
                                    <p class="font-semibold text-gray-900 dark:text-gray-100">{{ $verification->safeGet('user_name', __('unknown_user')) }}</p>
                                    <p class="text-xs text-gray-500 dark:text-gray-400">{{ $verification->safeGet('user_email') }}</p>
                                </div>
                            </div>

                            <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
                                {{-- Product --}}
                                <div>
                                    <p class="text-xs font-medium text-gray-500">{{ __('product') }}</p>
                                    <p class="text-sm text-gray-900 dark:text-gray-200">{{ $verification->safeGet('product_title', '-') }}</p>
                                </div>

                                {{-- Amount --}}
                                <div>
                                    <p class="text-xs font-medium text-gray-500">{{ __('amount') }}</p>
                                    <p class="text-sm font-semibold text-gray-900 dark:text-gray-200">
                                        {{ $verification->safeGet('currency', 'USD') }}
                                        {{ number_format((float) ($verification->getAttribute('amount') ?? 0), 2) }}
                                    </p>
                                </div>

                                {{-- Reference Code --}}
                                <div>
                                    <p class="text-xs font-medium text-gray-500">{{ __('reference_code') }}</p>
                                    <p class="text-sm font-mono text-gray-900 dark:text-gray-200">{{ $verification->safeGet('reference_code', '-') }}</p>
                                </div>

                                {{-- Created At --}}
                                <div>
                                    <p class="text-xs font-medium text-gray-500">{{ __('created_at') }}</p>
                                    <p class="text-sm text-gray-900 dark:text-gray-200">{{ $verification->safeGet('created_at', '-') }}</p>
                                </div>
                            </div>

                            {{-- Receipt Link --}}
                            @if ($verification->getAttribute('receipt_url'))
                                <div class="mt-1">
                                    <a
                                        href="{{ $verification->getAttribute('receipt_url') }}"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="inline-flex items-center gap-1.5 text-sm font-medium text-primary-600 transition hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300"
                                    >
                                        <x-heroicon-o-document-magnifying-glass class="h-4 w-4" />
                                        {{ __('view_receipt') }}
                                        <x-heroicon-o-arrow-top-right-on-square class="h-3 w-3" />
                                    </a>
                                </div>
                            @endif
                        </div>

                        {{-- Right: Actions --}}
                        <div class="flex items-center gap-2 lg:flex-col lg:items-stretch">
                            <button
                                wire:click="approve('{{ $verification->getKey() }}')"
                                wire:confirm="{{ __('confirm_approve_verification') }}"
                                class="inline-flex items-center justify-center gap-2 rounded-xl border border-green-200 bg-green-50 px-5 py-2.5 text-sm font-medium text-green-700 transition hover:bg-green-100 dark:border-success-500/20 dark:bg-success-500/20 dark:text-success-400 dark:hover:bg-success-500/30"
                            >
                                <x-heroicon-o-check class="h-4 w-4" />
                                {{ __('approve') }}
                            </button>

                            <button
                                wire:click="openRejectModal('{{ $verification->getKey() }}', '{{ addslashes($verification->safeGet('user_name', __('unknown_user'))) }}')"
                                class="inline-flex items-center justify-center gap-2 rounded-xl border border-red-200 bg-red-50 px-5 py-2.5 text-sm font-medium text-red-700 transition hover:bg-red-100 dark:border-danger-500/20 dark:bg-danger-500/20 dark:text-danger-400 dark:hover:bg-danger-500/30"
                            >
                                <x-heroicon-o-x-mark class="h-4 w-4" />
                                {{ __('reject') }}
                            </button>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    @else
        {{-- Empty State --}}
        <div class="rounded-xl border border-gray-200 bg-white px-6 py-16 text-center shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="flex flex-col items-center gap-3">
                <div class="flex h-14 w-14 items-center justify-center rounded-full bg-green-100 dark:bg-success-500/10">
                    <x-heroicon-o-shield-check class="h-7 w-7 text-green-600 dark:text-success-400" />
                </div>
                <p class="text-lg font-medium text-gray-900 dark:text-gray-300">{{ __('no_pending_verifications') }}</p>
                <p class="text-sm text-gray-600 dark:text-gray-500">{{ __('all_verifications_processed') }}</p>
            </div>
        </div>
    @endif

    {{-- ── Reject Modal ──────────────────────────────────────── --}}
    @if ($showRejectModal)
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
            <div class="w-full max-w-md rounded-2xl border border-gray-200 bg-white p-6 shadow-2xl dark:border-gray-700 dark:bg-gray-900">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    {{ __('reject_verification') }}
                </h3>
                <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                    {{ __('reject_verification_confirm', ['name' => $rejectUserName]) }}
                </p>

                <div class="mt-4">
                    <label for="rejection-reason" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300">
                        {{ __('rejection_reason') }}
                    </label>
                    <textarea
                        id="rejection-reason"
                        wire:model="rejectionReason"
                        rows="4"
                        class="w-full rounded-xl border border-gray-300 bg-white px-4 py-3 text-sm text-gray-900 placeholder-gray-500 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200"
                        placeholder="{{ __('enter_rejection_reason') }}"
                    ></textarea>
                </div>

                <div class="mt-6 flex items-center justify-end gap-3">
                    <button
                        wire:click="cancelReject"
                        class="rounded-xl border border-gray-300 bg-white px-5 py-2.5 text-sm font-medium text-gray-700 transition hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ __('cancel') }}
                    </button>
                    <button
                        wire:click="confirmReject"
                        class="rounded-xl bg-red-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-red-700"
                    >
                        {{ __('confirm_reject') }}
                    </button>
                </div>
            </div>
        </div>
    @endif
</x-filament-panels::page>
