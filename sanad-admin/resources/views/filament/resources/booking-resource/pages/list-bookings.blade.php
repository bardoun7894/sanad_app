<x-filament-panels::page>
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
            <x-heroicon-o-rectangle-stack class="h-4 w-4" />
            {{ __('all') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary-500/30 px-1.5 text-xs font-semibold text-primary-300">
                {{ $allCount }}
            </span>
        </button>

        <button
            wire:click="switchTab('upcoming')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-warning-500/20 text-warning-400 border border-warning-500/30 shadow-sm' => $activeTab === 'upcoming',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'upcoming',
            ])
        >
            <x-heroicon-o-clock class="h-4 w-4" />
            {{ __('upcoming') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-warning-500/30 px-1.5 text-xs font-semibold text-warning-300">
                {{ $upcomingCount }}
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
            wire:click="switchTab('cancelled')"
            @class([
                'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                'bg-danger-500/20 text-danger-400 border border-danger-500/30 shadow-sm' => $activeTab === 'cancelled',
                'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $activeTab !== 'cancelled',
            ])
        >
            <x-heroicon-o-x-circle class="h-4 w-4" />
            {{ __('cancelled') }}
            <span class="ml-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-danger-500/30 px-1.5 text-xs font-semibold text-danger-300">
                {{ $cancelledCount }}
            </span>
        </button>
    </div>

    {{-- ── Search + Filter + Export Bar ──────────────────────── --}}
    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
            {{-- Search --}}
            <div class="relative w-full sm:w-72">
                <x-heroicon-o-magnifying-glass class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input
                    wire:model.live.debounce.300ms="search"
                    type="text"
                    placeholder="{{ __('search_bookings') }}"
                    class="w-full rounded-xl border border-white/10 bg-white/5 py-2.5 pl-10 pr-4 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                />
            </div>

            {{-- Session Type Filter --}}
            <select
                wire:model.live="sessionTypeFilter"
                class="rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
            >
                <option value="">{{ __('all_session_types') }}</option>
                <option value="video">{{ __('video') }}</option>
                <option value="audio">{{ __('audio') }}</option>
                <option value="chat">{{ __('chat') }}</option>
                <option value="in_person">{{ __('in_person') }}</option>
            </select>
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

    {{-- ── Bookings Table ────────────────────────────────────── --}}
    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm">
                <thead>
                    <tr class="border-b border-white/10 bg-white/5">
                        <th class="px-6 py-4 font-medium text-gray-400">{{ __('client') }}</th>
                        <th class="px-6 py-4 font-medium text-gray-400">{{ __('date_time') }}</th>
                        <th class="px-6 py-4 font-medium text-gray-400">{{ __('duration') }}</th>
                        <th class="px-6 py-4 font-medium text-gray-400">{{ __('session_type') }}</th>
                        <th class="px-6 py-4 font-medium text-gray-400">{{ __('status') }}</th>
                        <th class="px-6 py-4 font-medium text-gray-400">{{ __('amount') }}</th>
                        <th class="px-6 py-4 font-medium text-gray-400">{{ __('actions') }}</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-white/5">
                    @forelse ($bookings as $booking)
                        @php
                            $statusColor = match ($booking->safeGet('status', 'pending')) {
                                'completed' => 'success',
                                'confirmed' => 'primary',
                                'pending'   => 'warning',
                                'cancelled' => 'danger',
                                'rejected'  => 'danger',
                                'no_show'   => 'gray',
                                default     => 'gray',
                            };
                            $typeColor = match ($booking->safeGet('session_type')) {
                                'video'    => 'primary',
                                'audio'    => 'success',
                                'chat'     => 'info',
                                'in_person' => 'warning',
                                default    => 'gray',
                            };
                            $typeIcon = match ($booking->safeGet('session_type')) {
                                'video'    => 'heroicon-o-video-camera',
                                'audio'    => 'heroicon-o-phone',
                                'chat'     => 'heroicon-o-chat-bubble-left-right',
                                'in_person' => 'heroicon-o-building-office',
                                default    => 'heroicon-o-question-mark-circle',
                            };
                        @endphp
                        <tr class="transition hover:bg-white/5">
                            {{-- Client --}}
                            <td class="px-6 py-4">
                                <a
                                    href="{{ route('filament.admin.resources.appointments.view', ['record' => $booking->getKey()]) }}"
                                    class="font-medium text-gray-200 hover:text-primary-400 transition"
                                >
                                    {{ $booking->safeGet('client_name') }}
                                </a>
                                @if ($booking->getAttribute('therapist_id'))
                                    <div class="text-xs text-gray-500">
                                        {{ __('therapist') }}: {{ $this->getTherapistName($booking->getAttribute('therapist_id')) }}
                                    </div>
                                @endif
                            </td>

                            {{-- Date/Time --}}
                            <td class="px-6 py-4 text-gray-300">
                                {{ $booking->safeGet('scheduled_time', '-') }}
                            </td>

                            {{-- Duration --}}
                            <td class="px-6 py-4 text-gray-300">
                                {{ $booking->safeGet('duration_minutes', '60') }} {{ __('min') }}
                            </td>

                            {{-- Session Type --}}
                            <td class="px-6 py-4">
                                <span @class([
                                    'inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold',
                                    'bg-primary-500/20 text-primary-400' => $typeColor === 'primary',
                                    'bg-success-500/20 text-success-400' => $typeColor === 'success',
                                    'bg-cyan-500/20 text-cyan-400'       => $typeColor === 'info',
                                    'bg-warning-500/20 text-warning-400' => $typeColor === 'warning',
                                    'bg-gray-500/20 text-gray-400'       => $typeColor === 'gray',
                                ])>
                                    <x-dynamic-component :component="$typeIcon" class="h-3.5 w-3.5" />
                                    {{ __($booking->safeGet('session_type', 'unknown')) }}
                                </span>
                            </td>

                            {{-- Status --}}
                            <td class="px-6 py-4">
                                <span @class([
                                    'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold',
                                    'bg-warning-500/20 text-warning-400' => $statusColor === 'warning',
                                    'bg-primary-500/20 text-primary-400' => $statusColor === 'primary',
                                    'bg-success-500/20 text-success-400' => $statusColor === 'success',
                                    'bg-danger-500/20 text-danger-400'   => $statusColor === 'danger',
                                    'bg-gray-500/20 text-gray-400'       => $statusColor === 'gray',
                                ])>
                                    {{ __($booking->safeGet('status', 'pending')) }}
                                </span>
                            </td>

                            {{-- Amount --}}
                            <td class="px-6 py-4 text-gray-300">
                                {{ $booking->safeGet('currency', 'SAR') }} {{ $booking->safeGet('amount', '0') }}
                            </td>

                            {{-- Actions --}}
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-2">
                                    <a
                                        href="{{ route('filament.admin.resources.appointments.view', ['record' => $booking->getKey()]) }}"
                                        class="inline-flex items-center gap-1 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                                    >
                                        <x-heroicon-o-eye class="h-3.5 w-3.5" />
                                        {{ __('view') }}
                                    </a>

                                    @if (in_array($booking->safeGet('status'), ['pending', 'confirmed']))
                                        <button
                                            wire:click="openCancelModal('{{ $booking->getKey() }}', '{{ addslashes($booking->safeGet('client_name')) }}')"
                                            class="inline-flex items-center gap-1 rounded-lg bg-danger-500/20 px-3 py-1.5 text-xs font-medium text-danger-400 transition hover:bg-danger-500/30"
                                        >
                                            <x-heroicon-o-x-mark class="h-3.5 w-3.5" />
                                            {{ __('cancel') }}
                                        </button>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-6 py-12 text-center text-gray-500">
                                <div class="flex flex-col items-center gap-2">
                                    <x-heroicon-o-calendar class="h-8 w-8 text-gray-600" />
                                    <span>{{ __('no_bookings_found') }}</span>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
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
                {{ __('showing_results_per_page', ['count' => count($bookings), 'per_page' => $perPage]) }}
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

    {{-- ── Cancel Modal ──────────────────────────────────────── --}}
    @if ($showCancelModal)
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
            <div class="w-full max-w-md rounded-2xl border border-white/10 bg-gray-900 p-6 shadow-2xl">
                <h3 class="text-lg font-semibold text-gray-100">
                    {{ __('cancel_booking') }}
                </h3>
                <p class="mt-1 text-sm text-gray-400">
                    {{ __('cancel_booking_confirm', ['client' => $cancelBookingClient]) }}
                </p>

                <div class="mt-4">
                    <label for="cancellation-reason" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('cancellation_reason') }}
                    </label>
                    <textarea
                        id="cancellation-reason"
                        wire:model="cancellationReason"
                        rows="4"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_cancellation_reason') }}"
                    ></textarea>
                </div>

                <div class="mt-6 flex items-center justify-end gap-3">
                    <button
                        wire:click="dismissCancelModal"
                        class="rounded-xl border border-white/10 bg-white/5 px-5 py-2.5 text-sm font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                    >
                        {{ __('dismiss') }}
                    </button>
                    <button
                        wire:click="confirmCancel"
                        class="rounded-xl bg-danger-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-danger-700"
                    >
                        {{ __('confirm_cancel') }}
                    </button>
                </div>
            </div>
        </div>
    @endif
</x-filament-panels::page>
