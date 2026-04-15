<x-filament-panels::page>
    @if ($record)
        <div class="grid gap-6 lg:grid-cols-3">

            {{-- ── Left Column: Profile + Stats ─────────────────── --}}
            <div class="space-y-6 lg:col-span-1">

                {{-- Profile Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <div class="flex flex-col items-center text-center">
                        @php
                            $photoUrl = $record->getAttribute('photo_url');
                        @endphp

                        @if ($photoUrl)
                            <img
                                src="{{ $photoUrl }}"
                                alt="{{ $record->safeGet('name') }}"
                                class="h-24 w-24 rounded-full border-2 border-white/10 object-cover"
                            />
                        @else
                            <div class="flex h-24 w-24 items-center justify-center rounded-full border-2 border-white/10 bg-primary-500/20 text-2xl font-bold text-primary-400">
                                {{ mb_substr($record->safeGet('name', '?'), 0, 1) }}
                            </div>
                        @endif

                        <h3 class="mt-4 text-lg font-semibold text-gray-100">
                            {{ $record->safeGet('name') }}
                        </h3>
                        <p class="text-sm text-gray-400">
                            {{ $record->safeGet('title', '-') }}
                        </p>
                        <p class="mt-1 text-xs text-gray-500">
                            {{ $record->safeGet('email') }}
                        </p>
                    </div>

                    {{-- Bio --}}
                    @if ($record->getAttribute('bio'))
                        <div class="mt-5 border-t border-white/10 pt-4">
                            <h4 class="mb-1 text-xs font-semibold uppercase tracking-wider text-gray-500">{{ __('bio') }}</h4>
                            <p class="text-sm leading-relaxed text-gray-300">
                                {{ $record->safeGet('bio') }}
                            </p>
                        </div>
                    @endif
                </div>

                {{-- Statistics Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                        {{ __('statistics') }}
                    </h4>
                    <div class="grid grid-cols-2 gap-4">
                        <div class="rounded-lg bg-white/5 p-4 text-center">
                            <div class="flex items-center justify-center gap-1 text-2xl font-bold text-amber-400">
                                <x-heroicon-s-star class="h-5 w-5" />
                                {{ number_format($record->getAttribute('rating') ?? 0, 1) }}
                            </div>
                            <div class="mt-1 text-xs text-gray-500">{{ __('rating') }}</div>
                        </div>
                        <div class="rounded-lg bg-white/5 p-4 text-center">
                            <div class="text-2xl font-bold text-primary-400">
                                {{ $record->getAttribute('review_count') ?? 0 }}
                            </div>
                            <div class="mt-1 text-xs text-gray-500">{{ __('reviews') }}</div>
                        </div>
                    </div>
                </div>

                {{-- Pricing Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                        {{ __('pricing') }}
                    </h4>
                    <div class="flex items-baseline gap-1">
                        <span class="text-3xl font-bold text-gray-100">
                            {{ $record->safeGet('session_price', '0') }}
                        </span>
                        <span class="text-sm text-gray-400">
                            {{ $record->safeGet('currency', 'SAR') }} / {{ __('session') }}
                        </span>
                    </div>
                </div>
            </div>

            {{-- ── Right Column: Details ────────────────────────── --}}
            <div class="space-y-6 lg:col-span-2">

                {{-- Approval Status Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                        {{ __('approval_info') }}
                    </h4>
                    <div class="grid gap-4 sm:grid-cols-2">
                        <div>
                            <span class="text-xs text-gray-500">{{ __('status') }}</span>
                            @php
                                $status = $record->safeGet('approval_status', 'pending');
                                $statusColorMap = [
                                    'approved'  => 'bg-success-500/20 text-success-400',
                                    'pending'   => 'bg-warning-500/20 text-warning-400',
                                    'rejected'  => 'bg-danger-500/20 text-danger-400',
                                    'suspended' => 'bg-gray-500/20 text-gray-400',
                                ];
                                $statusClass = $statusColorMap[$status] ?? 'bg-gray-500/20 text-gray-400';
                            @endphp
                            <div class="mt-1">
                                <span class="inline-flex items-center rounded-full px-3 py-1 text-sm font-semibold {{ $statusClass }}">
                                    {{ __($status) }}
                                </span>
                            </div>
                        </div>

                        @if ($record->getAttribute('approved_at'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('approved_at') }}</span>
                                <p class="mt-1 text-sm text-gray-300">{{ $record->safeGet('approved_at') }}</p>
                            </div>
                        @endif

                        @if ($record->getAttribute('approved_by'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('approved_by') }}</span>
                                <p class="mt-1 text-sm text-gray-300">{{ $record->safeGet('approved_by') }}</p>
                            </div>
                        @endif

                        @if ($record->getAttribute('rejection_reason'))
                            <div class="sm:col-span-2">
                                <span class="text-xs text-gray-500">{{ __('rejection_reason') }}</span>
                                <p class="mt-1 rounded-lg bg-danger-500/10 p-3 text-sm text-danger-300">
                                    {{ $record->safeGet('rejection_reason') }}
                                </p>
                            </div>
                        @endif
                    </div>
                </div>

                {{-- Professional Details Card --}}
                <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
                    <h4 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-400">
                        {{ __('professional_details') }}
                    </h4>
                    <div class="grid gap-6 sm:grid-cols-2">
                        {{-- Specialties --}}
                        <div>
                            <span class="text-xs text-gray-500">{{ __('specialties') }}</span>
                            <div class="mt-2 flex flex-wrap gap-1.5">
                                @forelse ($record->getAttribute('specialties') ?? [] as $spec)
                                    <span class="inline-flex rounded-md bg-primary-500/10 px-2.5 py-1 text-xs font-medium text-primary-400">
                                        {{ $spec }}
                                    </span>
                                @empty
                                    <span class="text-sm text-gray-500">{{ __('none') }}</span>
                                @endforelse
                            </div>
                        </div>

                        {{-- Session Types --}}
                        <div>
                            <span class="text-xs text-gray-500">{{ __('session_types') }}</span>
                            <div class="mt-2 flex flex-wrap gap-1.5">
                                @forelse ($record->getAttribute('session_types') ?? [] as $type)
                                    <span class="inline-flex rounded-md bg-cyan-500/10 px-2.5 py-1 text-xs font-medium text-cyan-400">
                                        {{ __($type) }}
                                    </span>
                                @empty
                                    <span class="text-sm text-gray-500">{{ __('none') }}</span>
                                @endforelse
                            </div>
                        </div>

                        {{-- Therapy Types --}}
                        <div>
                            <span class="text-xs text-gray-500">{{ __('therapy_types') }}</span>
                            <div class="mt-2 flex flex-wrap gap-1.5">
                                @forelse ($record->getAttribute('therapy_types') ?? [] as $type)
                                    <span class="inline-flex rounded-md bg-violet-500/10 px-2.5 py-1 text-xs font-medium text-violet-400">
                                        {{ $type }}
                                    </span>
                                @empty
                                    <span class="text-sm text-gray-500">{{ __('none') }}</span>
                                @endforelse
                            </div>
                        </div>

                        {{-- Languages --}}
                        <div>
                            <span class="text-xs text-gray-500">{{ __('languages') }}</span>
                            <div class="mt-2 flex flex-wrap gap-1.5">
                                @forelse ($record->getAttribute('languages') ?? [] as $lang)
                                    <span class="inline-flex rounded-md bg-emerald-500/10 px-2.5 py-1 text-xs font-medium text-emerald-400">
                                        {{ $lang }}
                                    </span>
                                @empty
                                    <span class="text-sm text-gray-500">{{ __('none') }}</span>
                                @endforelse
                            </div>
                        </div>

                        {{-- Qualifications --}}
                        <div class="sm:col-span-2">
                            <span class="text-xs text-gray-500">{{ __('qualifications') }}</span>
                            <div class="mt-2 space-y-1.5">
                                @forelse ($record->getAttribute('qualifications') ?? [] as $qual)
                                    <div class="flex items-start gap-2 text-sm text-gray-300">
                                        <x-heroicon-o-academic-cap class="mt-0.5 h-4 w-4 flex-shrink-0 text-gray-500" />
                                        @if (is_array($qual))
                                            {{ $qual['title'] ?? $qual['name'] ?? json_encode($qual) }}
                                        @else
                                            {{ $qual }}
                                        @endif
                                    </div>
                                @empty
                                    <span class="text-sm text-gray-500">{{ __('none') }}</span>
                                @endforelse
                            </div>
                        </div>

                        {{-- Years of Experience --}}
                        @if ($record->getAttribute('years_experience'))
                            <div>
                                <span class="text-xs text-gray-500">{{ __('years_experience') }}</span>
                                <p class="mt-1 text-sm text-gray-300">
                                    {{ $record->safeGet('years_experience') }} {{ __('years') }}
                                </p>
                            </div>
                        @endif
                    </div>
                </div>

                {{-- Back Button --}}
                <div class="flex justify-start">
                    <a
                        href="{{ route('filament.admin.resources.clinicians.index') }}"
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
