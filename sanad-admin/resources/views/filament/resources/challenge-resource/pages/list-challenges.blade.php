<x-filament-panels::page>
    {{-- ── Search + Actions Bar ────────────────────────────────── --}}
    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="relative w-full sm:max-w-sm">
            <x-heroicon-o-magnifying-glass class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
                wire:model.live.debounce.300ms="search"
                type="text"
                placeholder="{{ __('search_challenges') }}"
                class="w-full rounded-xl border border-white/10 bg-white/5 py-2.5 pl-10 pr-4 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
            />
        </div>

        <a
            href="{{ \App\Filament\Resources\ChallengeResource::getUrl('create') }}"
            class="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-primary-700"
        >
            <x-heroicon-o-plus class="h-4 w-4" />
            {{ __('create_challenge') }}
        </a>
    </div>

    {{-- ── Challenges Table ──────────────────────────────────────── --}}
    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <table class="w-full text-left text-sm">
            <thead>
                <tr class="border-b border-white/10 bg-white/5">
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('title') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('type') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('duration') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('order') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('active') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('actions') }}</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
                @forelse ($records as $record)
                    @php
                        $typeColor = $record->getTypeColor();
                    @endphp
                    <tr class="transition hover:bg-white/5">
                        <td class="px-6 py-4">
                            <div class="font-medium text-gray-200">{{ $record->safeGet('title') }}</div>
                            <div class="text-xs text-gray-500">{{ $record->safeGet('title_en') }}</div>
                        </td>
                        <td class="px-6 py-4">
                            <span @class([
                                'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold',
                                'bg-info-500/20 text-info-400'       => $typeColor === 'info',
                                'bg-success-500/20 text-success-400' => $typeColor === 'success',
                                'bg-primary-500/20 text-primary-400' => $typeColor === 'primary',
                                'bg-warning-500/20 text-warning-400' => $typeColor === 'warning',
                                'bg-danger-500/20 text-danger-400'   => $typeColor === 'danger',
                                'bg-gray-500/20 text-gray-400'       => $typeColor === 'gray',
                            ])>
                                {{ ucfirst($record->safeGet('type', 'general')) }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-gray-300">
                            {{ $record->safeGet('duration_minutes', '0') }}m
                        </td>
                        <td class="px-6 py-4 text-gray-300">
                            {{ $record->safeGet('order', '0') }}
                        </td>
                        <td class="px-6 py-4">
                            @if ($record->getAttribute('is_active'))
                                <x-heroicon-o-check-circle class="h-5 w-5 text-success-400" />
                            @else
                                <x-heroicon-o-x-circle class="h-5 w-5 text-gray-500" />
                            @endif
                        </td>
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-2">
                                <a
                                    href="{{ \App\Filament\Resources\ChallengeResource::getUrl('edit', ['record' => $record->getKey()]) }}"
                                    class="inline-flex items-center gap-1 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                                >
                                    <x-heroicon-o-pencil-square class="h-3.5 w-3.5" />
                                    {{ __('edit') }}
                                </a>
                                <button
                                    wire:click="deleteRecord('{{ $record->getKey() }}')"
                                    wire:confirm="{{ __('confirm_delete') }}"
                                    class="inline-flex items-center gap-1 rounded-lg bg-danger-500/20 px-3 py-1.5 text-xs font-medium text-danger-400 transition hover:bg-danger-500/30"
                                >
                                    <x-heroicon-o-trash class="h-3.5 w-3.5" />
                                    {{ __('delete') }}
                                </button>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-gray-500">
                            <div class="flex flex-col items-center gap-2">
                                <x-heroicon-o-trophy class="h-8 w-8 text-gray-600" />
                                <span>{{ __('no_challenges_found') }}</span>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</x-filament-panels::page>
