<x-filament-widgets::widget>
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="mb-4 text-lg font-semibold text-gray-900 dark:text-white">{{ __('top_therapists') }}</h2>

        @php
            $therapists = $this->getTherapists();
        @endphp

        @if (count($therapists) > 0)
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm">
                    <thead class="border-b border-gray-200 bg-gray-50 text-xs uppercase text-gray-700 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-400">
                        <tr>
                            <th class="px-4 py-3">{{ __('therapist_name') }}</th>
                            <th class="px-4 py-3 text-center">{{ __('total_sessions') }}</th>
                            <th class="px-4 py-3 text-center">{{ __('completed') }}</th>
                            <th class="px-4 py-3 text-center">{{ __('rating') }}</th>
                            <th class="px-4 py-3 text-center">{{ __('completion_rate') }}</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                        @foreach ($therapists as $therapist)
                            <tr class="hover:bg-gray-50 dark:hover:bg-gray-900">
                                <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">
                                    {{ $therapist['name'] }}
                                </td>
                                <td class="px-4 py-3 text-center">
                                    <span class="inline-flex items-center rounded-full bg-primary-100 px-2.5 py-0.5 text-xs font-medium text-primary-800 dark:bg-primary-900/30 dark:text-primary-300">
                                        {{ $therapist['session_count'] }}
                                    </span>
                                </td>
                                <td class="px-4 py-3 text-center">
                                    <span class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800 dark:bg-green-900/30 dark:text-green-300">
                                        {{ $therapist['completed_count'] }}
                                    </span>
                                </td>
                                <td class="px-4 py-3 text-center text-gray-900 dark:text-white">
                                    {{ number_format($therapist['average_rating'], 1) }} ⭐
                                </td>
                                <td class="px-4 py-3 text-center">
                                    <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium
                                        {{ $therapist['completion_rate'] >= 80 ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300' : 
                                           ($therapist['completion_rate'] >= 60 ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300' : 
                                           'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300') }}">
                                        {{ $therapist['completion_rate'] }}%
                                    </span>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @else
            <div class="flex flex-col items-center justify-center py-12 text-center">
                <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-800">
                    <x-heroicon-o-user-group class="h-8 w-8 text-gray-400" />
                </div>
                <p class="text-sm font-medium text-gray-900 dark:text-white">{{ __('no_therapists_found') }}</p>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">{{ __('therapist_data_will_appear_here') }}</p>
            </div>
        @endif
    </div>
</x-filament-widgets::widget>
