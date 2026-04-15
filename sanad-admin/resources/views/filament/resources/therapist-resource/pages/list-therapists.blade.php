<x-filament-panels::page>
    {{-- ── Tab Navigation ───────────────────────────────────── --}}
    <div class="mb-6 flex flex-wrap items-center gap-3">
        <button
            wire:click="switchTab('pending')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-warning-500/20 text-warning-400 border border-warning-500/30 shadow-sm' => $activeTab === 'pending',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'pending',
            ])
        >
            <x-heroicon-o-clock class="h-4 w-4" />
            {{ __('pending_review') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-warning-500/30 px-1.5 text-xs font-semibold text-warning-300">
                {{ $pendingCount }}
            </span>
        </button>

        <button
            wire:click="switchTab('approved')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-success-500/20 text-success-400 border border-success-500/30 shadow-sm' => $activeTab === 'approved',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'approved',
            ])
        >
            <x-heroicon-o-check-circle class="h-4 w-4" />
            {{ __('approved') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-success-500/30 px-1.5 text-xs font-semibold text-success-300">
                {{ $approvedCount }}
            </span>
        </button>

        <button
            wire:click="switchTab('rejected')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-danger-500/20 text-danger-400 border border-danger-500/30 shadow-sm' => $activeTab === 'rejected',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'rejected',
            ])
        >
            <x-heroicon-o-x-circle class="h-4 w-4" />
            {{ __('rejected') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-danger-500/30 px-1.5 text-xs font-semibold text-danger-300">
                {{ $rejectedCount }}
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
                placeholder="{{ __('search_clinicians') }}"
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

    {{-- ── Therapists Table ──────────────────────────────────── --}}
    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <table class="w-full text-left text-sm">
            <thead>
                <tr class="border-b border-white/10 bg-white/5">
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('name') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('title') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('specialties') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('rating') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('price') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('status') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('actions') }}</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
                @forelse ($therapists as $therapist)
                    @php
                        $statusColor = match ($therapist->safeGet('approval_status', 'pending')) {
                            'approved'  => 'success',
                            'pending'   => 'warning',
                            'rejected'  => 'danger',
                            'suspended' => 'gray',
                            default     => 'gray',
                        };
                        $specialties = $therapist->getAttribute('specialties') ?? [];
                    @endphp
                    <tr class="transition hover:bg-white/5">
                        {{-- Name --}}
                        <td class="px-6 py-4">
                            <a
                                href="{{ route('filament.admin.resources.clinicians.view', ['record' => $therapist->getKey()]) }}"
                                class="font-medium text-gray-200 hover:text-primary-400 transition"
                            >
                                {{ $therapist->safeGet('name') }}
                            </a>
                            <div class="text-xs text-gray-500">{{ $therapist->safeGet('email', '') }}</div>
                        </td>

                        {{-- Title --}}
                        <td class="px-6 py-4 text-gray-300">
                            {{ $therapist->safeGet('title', '-') }}
                        </td>

                        {{-- Specialties --}}
                        <td class="px-6 py-4">
                            <div class="flex flex-wrap gap-1">
                                @foreach (array_slice($specialties, 0, 3) as $spec)
                                    <span class="inline-flex rounded-md bg-primary-500/10 px-2 py-0.5 text-xs font-medium text-primary-400">
                                        {{ $spec }}
                                    </span>
                                @endforeach
                                @if (count($specialties) > 3)
                                    <span class="inline-flex rounded-md bg-white/10 px-2 py-0.5 text-xs text-gray-400">
                                        +{{ count($specialties) - 3 }}
                                    </span>
                                @endif
                            </div>
                        </td>

                        {{-- Rating --}}
                        <td class="px-6 py-4 text-gray-300">
                            <div class="flex items-center gap-1">
                                <x-heroicon-s-star class="h-4 w-4 text-amber-400" />
                                {{ number_format($therapist->getAttribute('rating') ?? 0, 1) }}
                                <span class="text-xs text-gray-500">({{ $therapist->getAttribute('review_count') ?? 0 }})</span>
                            </div>
                        </td>

                        {{-- Price --}}
                        <td class="px-6 py-4 text-gray-300">
                            {{ $therapist->safeGet('currency', 'SAR') }} {{ $therapist->safeGet('session_price', '0') }}
                        </td>

                        {{-- Status --}}
                        <td class="px-6 py-4">
                            <span @class([
                                'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold',
                                'bg-warning-500/20 text-warning-400' => $statusColor === 'warning',
                                'bg-success-500/20 text-success-400' => $statusColor === 'success',
                                'bg-danger-500/20 text-danger-400'   => $statusColor === 'danger',
                                'bg-gray-500/20 text-gray-400'      => $statusColor === 'gray',
                            ])>
                                {{ __($therapist->safeGet('approval_status', 'pending')) }}
                            </span>
                        </td>

                        {{-- Actions --}}
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-2">
                                {{-- View button (always visible) --}}
                                <a
                                    href="{{ route('filament.admin.resources.clinicians.view', ['record' => $therapist->getKey()]) }}"
                                    class="inline-flex items-center gap-1 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                                >
                                    <x-heroicon-o-eye class="h-3.5 w-3.5" />
                                    {{ __('view') }}
                                </a>

                                @if ($activeTab === 'pending')
                                    {{-- Approve --}}
                                    <button
                                        wire:click="approve('{{ $therapist->getKey() }}')"
                                        wire:confirm="{{ __('confirm_approve_therapist') }}"
                                        class="inline-flex items-center gap-1 rounded-lg bg-success-500/20 px-3 py-1.5 text-xs font-medium text-success-400 transition hover:bg-success-500/30"
                                    >
                                        <x-heroicon-o-check class="h-3.5 w-3.5" />
                                        {{ __('approve') }}
                                    </button>

                                    {{-- Reject --}}
                                    <button
                                        wire:click="openRejectModal('{{ $therapist->getKey() }}', '{{ addslashes($therapist->safeGet('name')) }}')"
                                        class="inline-flex items-center gap-1 rounded-lg bg-danger-500/20 px-3 py-1.5 text-xs font-medium text-danger-400 transition hover:bg-danger-500/30"
                                    >
                                        <x-heroicon-o-x-mark class="h-3.5 w-3.5" />
                                        {{ __('reject') }}
                                    </button>
                                @endif
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="px-6 py-12 text-center text-gray-500">
                            <div class="flex flex-col items-center gap-2">
                                <x-heroicon-o-users class="h-8 w-8 text-gray-600" />
                                <span>{{ __('no_clinicians_found') }}</span>
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
                {{ __('showing_results_per_page', ['count' => count($therapists), 'per_page' => $perPage]) }}
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

    {{-- ── Reject Modal ──────────────────────────────────────── --}}
    @if ($showRejectModal)
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
            <div class="w-full max-w-md rounded-2xl border border-white/10 bg-gray-900 p-6 shadow-2xl">
                <h3 class="text-lg font-semibold text-gray-100">
                    {{ __('reject_clinician') }}
                </h3>
                <p class="mt-1 text-sm text-gray-400">
                    {{ __('reject_clinician_confirm', ['name' => $rejectTherapistName]) }}
                </p>

                <div class="mt-4">
                    <label for="rejection-reason" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('rejection_reason') }}
                    </label>
                    <textarea
                        id="rejection-reason"
                        wire:model="rejectionReason"
                        rows="4"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_rejection_reason') }}"
                    ></textarea>
                </div>

                <div class="mt-6 flex items-center justify-end gap-3">
                    <button
                        wire:click="cancelReject"
                        class="rounded-xl border border-white/10 bg-white/5 px-5 py-2.5 text-sm font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                    >
                        {{ __('cancel') }}
                    </button>
                    <button
                        wire:click="confirmReject"
                        class="rounded-xl bg-danger-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-danger-700"
                    >
                        {{ __('confirm_reject') }}
                    </button>
                </div>
            </div>
        </div>
    @endif
</x-filament-panels::page>
