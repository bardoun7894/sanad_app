<x-filament-panels::page>
    @if ($record)
        <div class="grid gap-6 lg:grid-cols-3">

            {{-- ── Left Column: Session Overview ────────────────── --}}
            <div class="space-y-6 lg:col-span-1">

                {{-- Session Status Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <div class="flex flex-col items-center text-center">
                        @php
                            $status = $record->safeGet('status', 'pending');
                            $statusColorMap = [
                                'completed' => 'bg-success-500/20 text-success-400 border-success-500/30',
                                'confirmed' => 'bg-primary-500/20 text-primary-400 border-primary-500/30',
                                'pending'   => 'bg-warning-500/20 text-warning-400 border-warning-500/30',
                                'cancelled' => 'bg-danger-500/20 text-danger-400 border-danger-500/30',
                                'rejected'  => 'bg-danger-500/20 text-danger-400 border-danger-500/30',
                                'no_show'   => 'bg-gray-500/20 text-gray-400 border-gray-500/30',
                            ];
                            $statusClass = $statusColorMap[$status] ?? 'bg-gray-500/20 text-gray-400 border-gray-500/30';

                            $typeIcon = match ($record->safeGet('session_type')) {
                                'video'    => 'heroicon-o-video-camera',
                                'audio'    => 'heroicon-o-phone',
                                'chat'     => 'heroicon-o-chat-bubble-left-right',
                                'in_person' => 'heroicon-o-building-office',
                                default    => 'heroicon-o-question-mark-circle',
                            };
                        @endphp

                        <div class="flex h-16 w-16 items-center justify-center rounded-2xl border {{ $statusClass }}">
                            <x-dynamic-component :component="$typeIcon" class="h-8 w-8" />
                        </div>

                        <div class="mt-4">
                            <span class="inline-flex items-center rounded-full px-4 py-1.5 text-sm font-semibold {{ $statusClass }}">
                                {{ __($status) }}
                            </span>
                        </div>

                        <p class="mt-3 text-sm text-gray-400">
                            {{ __($record->safeGet('session_type', 'unknown')) }} {{ __('session') }}
                        </p>
                    </div>
                </div>

                {{-- Date & Time Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                        {{ __('schedule') }}
                    </h4>
                    <div class="space-y-3">
                        <div>
                            <span class="text-xs text-gray-500">{{ __('date_time') }}</span>
                            <p class="mt-1 text-sm font-medium text-gray-200">
                                {{ $record->safeGet('scheduled_time', '-') }}
                            </p>
                        </div>
                        <div>
                            <span class="text-xs text-gray-500">{{ __('duration') }}</span>
                            <p class="mt-1 text-sm font-medium text-gray-200">
                                {{ $record->safeGet('duration_minutes', '60') }} {{ __('minutes') }}
                            </p>
                        </div>
                    </div>
                </div>

                {{-- Amount Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                        {{ __('payment') }}
                    </h4>
                    <div class="flex items-baseline gap-1">
                        <span class="text-3xl font-bold text-gray-100">
                            {{ $record->safeGet('amount', '0') }}
                        </span>
                        <span class="text-sm text-gray-400">
                            {{ $record->safeGet('currency', 'SAR') }}
                        </span>
                    </div>
                </div>
            </div>

            {{-- ── Right Column: Details ────────────────────────── --}}
            <div class="space-y-6 lg:col-span-2">

                {{-- Client Info Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                        {{ __('client_info') }}
                    </h4>
                    <div class="grid gap-4 sm:grid-cols-2">
                        <div>
                            <span class="text-xs text-gray-500">{{ __('name') }}</span>
                            <p class="mt-1 text-sm font-medium text-gray-200">
                                {{ $record->safeGet('client_name') }}
                            </p>
                        </div>

                        @if ($record->getAttribute('client_email'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('email') }}</span>
                                <p class="mt-1 text-sm text-gray-300">
                                    {{ $record->safeGet('client_email') }}
                                </p>
                            </div>
                        @endif

                        @if ($record->getAttribute('client_age'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('age') }}</span>
                                <p class="mt-1 text-sm text-gray-300">
                                    {{ $record->safeGet('client_age') }}
                                </p>
                            </div>
                        @endif

                        @if ($record->getAttribute('primary_complaint'))
                            <div class="sm:col-span-2">
                                <span class="text-xs text-gray-500">{{ __('primary_complaint') }}</span>
                                <p class="mt-1 rounded-lg bg-white/5 p-3 text-sm text-gray-300">
                                    {{ $record->safeGet('primary_complaint') }}
                                </p>
                            </div>
                        @endif
                    </div>
                </div>

                {{-- Therapist Info Card --}}
                @if ($record->getAttribute('therapist_id'))
                    <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                        <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                            {{ __('therapist_info') }}
                        </h4>
                        <div class="grid gap-4 sm:grid-cols-2">
                            <div>
                                <span class="text-xs text-gray-500">{{ __('therapist') }}</span>
                                <p class="mt-1 text-sm font-medium text-gray-200">
                                    {{ $therapistName ?? __('unknown') }}
                                </p>
                            </div>
                            <div>
                                <span class="text-xs text-gray-500">{{ __('therapist_id') }}</span>
                                <p class="mt-1 text-xs font-mono text-gray-400">
                                    {{ $record->safeGet('therapist_id') }}
                                </p>
                            </div>
                        </div>
                    </div>
                @endif

                {{-- Notes Card --}}
                @if ($record->getAttribute('notes') || $record->getAttribute('cancellation_reason'))
                    <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                        <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                            {{ __('notes') }}
                        </h4>
                        <div class="space-y-4">
                            @if ($record->getAttribute('notes'))
                                <div>
                                    <span class="text-xs text-gray-500">{{ __('session_notes') }}</span>
                                    <p class="mt-1 rounded-lg bg-white/5 p-3 text-sm leading-relaxed text-gray-300">
                                        {{ $record->safeGet('notes') }}
                                    </p>
                                </div>
                            @endif

                            @if ($record->getAttribute('cancellation_reason'))
                                <div>
                                    <span class="text-xs text-gray-500">{{ __('cancellation_reason') }}</span>
                                    <p class="mt-1 rounded-lg bg-danger-500/10 p-3 text-sm text-danger-300">
                                        {{ $record->safeGet('cancellation_reason') }}
                                    </p>
                                </div>
                            @endif
                        </div>
                    </div>
                @endif

                {{-- Timestamps Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                        {{ __('timestamps') }}
                    </h4>
                    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                        @if ($record->getAttribute('created_at'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('created_at') }}</span>
                                <p class="mt-1 text-sm text-gray-300">{{ $record->safeGet('created_at') }}</p>
                            </div>
                        @endif

                        @if ($record->getAttribute('confirmed_at'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('confirmed_at') }}</span>
                                <p class="mt-1 text-sm text-gray-300">{{ $record->safeGet('confirmed_at') }}</p>
                            </div>
                        @endif

                        @if ($record->getAttribute('completed_at'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('completed_at') }}</span>
                                <p class="mt-1 text-sm text-gray-300">{{ $record->safeGet('completed_at') }}</p>
                            </div>
                        @endif

                        @if ($record->getAttribute('cancelled_at'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('cancelled_at') }}</span>
                                <p class="mt-1 text-sm text-danger-300">{{ $record->safeGet('cancelled_at') }}</p>
                            </div>
                        @endif
                    </div>
                </div>

                {{-- Back Button --}}
                <div class="flex justify-start">
                    <a
                        href="{{ route('filament.admin.resources.appointments.index') }}"
                        class="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-5 py-2.5 text-sm font-medium text-gray-300 backdrop-blur-xl transition hover:bg-white/10 hover:text-white"
                    >
                        <x-heroicon-o-arrow-left class="h-4 w-4" />
                        {{ __('back_to_list') }}
                    </a>
                </div>
            </div>
        </div>
    @endif
</x-filament-panels::page>
