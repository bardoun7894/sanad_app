<x-filament-panels::page>
    <div class="mb-6 flex items-center justify-between">
        <p class="text-sm text-gray-400">{{ count($records) }} {{ __('tests') }}</p>
        <a href="{{ \App\Filament\Resources\PsychTestResource::getUrl('create') }}"
           class="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-primary-700">
            <x-heroicon-o-plus class="h-4 w-4" />
            {{ __('create_psychological_test') }}
        </a>
    </div>

    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <table class="w-full text-left text-sm">
            <thead>
                <tr class="border-b border-white/10 bg-white/5">
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('title') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('type') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('questions') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('duration') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('active') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('actions') }}</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
                @forelse ($records as $record)
                    @php
                        $questions = $record->getAttribute('questions');
                        $qCount = is_array($questions) ? count($questions) : 0;
                    @endphp
                    <tr class="transition hover:bg-white/5">
                        <td class="px-6 py-4">
                            <div class="font-medium text-gray-200">{{ $record->safeGet('title_en', $record->safeGet('title')) }}</div>
                            <div class="text-xs text-gray-500">{{ $record->safeGet('title') }}</div>
                        </td>
                        <td class="px-6 py-4">
                            <span class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold bg-gray-500/20 text-gray-400">
                                {{ $record->safeGet('type', '-') }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-gray-300">{{ $qCount }}</td>
                        <td class="px-6 py-4 text-gray-300">{{ $record->safeGet('duration_minutes', '-') }} min</td>
                        <td class="px-6 py-4">
                            <button wire:click="toggleActive('{{ $record->getKey() }}')" class="focus:outline-none">
                                @if ($record->getAttribute('is_active'))
                                    <x-heroicon-o-check-circle class="h-5 w-5 text-success-400" />
                                @else
                                    <x-heroicon-o-x-circle class="h-5 w-5 text-gray-500" />
                                @endif
                            </button>
                        </td>
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-2">
                                <a href="{{ \App\Filament\Resources\PsychTestResource::getUrl('edit', ['record' => $record->getKey()]) }}"
                                   class="inline-flex items-center gap-1 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-medium text-gray-300 transition hover:bg-white/10 hover:text-white">
                                    <x-heroicon-o-pencil-square class="h-3.5 w-3.5" />
                                    {{ __('edit') }}
                                </a>
                                <button wire:click="deleteRecord('{{ $record->getKey() }}')" wire:confirm="{{ __('confirm_delete') }}"
                                        class="inline-flex items-center gap-1 rounded-lg bg-danger-500/20 px-3 py-1.5 text-xs font-medium text-danger-400 transition hover:bg-danger-500/30">
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
                                <x-heroicon-o-clipboard-document-check class="h-8 w-8 text-gray-600" />
                                <span>{{ __('no_tests_found') }}</span>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</x-filament-panels::page>
