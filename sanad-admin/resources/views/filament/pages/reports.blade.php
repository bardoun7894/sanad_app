<x-filament-panels::page>
    {{-- Report Templates Grid --}}
    <div class="mb-8">
        <div class="mb-4 flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-500/10">
                <x-heroicon-o-document-chart-bar class="h-5 w-5 text-primary-600 dark:text-primary-400" />
            </div>
            <div>
                <h3 class="text-base font-semibold text-gray-900 dark:text-white">{{ __('report_templates') }}</h3>
                <p class="text-xs text-gray-500">{{ __('generate_reports_from_templates') }}</p>
            </div>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            @foreach ($templates as $template)
                <div class="group flex flex-col justify-between rounded-xl border border-gray-200 bg-white p-6 shadow-sm transition-all duration-200 hover:bg-gray-50 hover:shadow-lg dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700/50">
                    {{-- Header --}}
                    <div class="mb-4">
                        <div class="mb-3 flex items-center gap-3">
                            @php
                                $iconColor = match($template['id']) {
                                    'monthly_summary' => 'text-blue-600 bg-blue-100 dark:text-blue-400 dark:bg-blue-500/10',
                                    'patient_activity' => 'text-purple-600 bg-purple-100 dark:text-purple-400 dark:bg-purple-500/10',
                                    'clinician_report' => 'text-emerald-600 bg-emerald-100 dark:text-emerald-400 dark:bg-emerald-500/10',
                                    'financial_report' => 'text-green-600 bg-green-100 dark:text-green-400 dark:bg-green-500/10',
                                    'risk_assessment' => 'text-red-600 bg-red-100 dark:text-red-400 dark:bg-red-500/10',
                                    'custom_report' => 'text-cyan-600 bg-cyan-100 dark:text-cyan-400 dark:bg-cyan-500/10',
                                    default => 'text-gray-600 bg-gray-100 dark:text-gray-400 dark:bg-gray-500/10',
                                };
                            @endphp

                            <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg {{ $iconColor }}">
                                <x-dynamic-component
                                    :component="$template['icon']"
                                    class="h-5 w-5"
                                />
                            </div>

                            <h4 class="text-sm font-semibold text-gray-900 dark:text-white">
                                {{ $template['title'] }}
                            </h4>
                        </div>

                        <p class="text-xs leading-relaxed text-gray-600 dark:text-gray-400">
                            {{ $template['description'] }}
                        </p>
                    </div>

                    {{-- Actions --}}
                    <div class="flex items-center gap-2">
                        <button
                            wire:click="generateReport('{{ $template['id'] }}', 'pdf')"
                            wire:loading.attr="disabled"
                            wire:target="generateReport('{{ $template['id'] }}', 'pdf')"
                            type="button"
                            class="inline-flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-2 text-xs font-medium text-gray-700 transition-colors duration-200 hover:bg-gray-50 disabled:cursor-wait disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                        >
                            <x-heroicon-o-document-arrow-down class="h-3.5 w-3.5" />
                            <span wire:loading.remove wire:target="generateReport('{{ $template['id'] }}', 'pdf')">
                                {{ __('pdf') }}
                            </span>
                            <span wire:loading wire:target="generateReport('{{ $template['id'] }}', 'pdf')">
                                {{ __('generating') }}...
                            </span>
                        </button>

                        <button
                            wire:click="generateReport('{{ $template['id'] }}', 'csv')"
                            wire:loading.attr="disabled"
                            wire:target="generateReport('{{ $template['id'] }}', 'csv')"
                            type="button"
                            class="inline-flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-2 text-xs font-medium text-gray-700 transition-colors duration-200 hover:bg-gray-50 disabled:cursor-wait disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                        >
                            <x-heroicon-o-table-cells class="h-3.5 w-3.5" />
                            <span wire:loading.remove wire:target="generateReport('{{ $template['id'] }}', 'csv')">
                                {{ __('csv') }}
                            </span>
                            <span wire:loading wire:target="generateReport('{{ $template['id'] }}', 'csv')">
                                {{ __('generating') }}...
                            </span>
                        </button>
                    </div>
                </div>
            @endforeach
        </div>
    </div>

    {{-- Recent Reports Section --}}
    <div>
        <div class="mb-4 flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gray-100 dark:bg-gray-500/10">
                <x-heroicon-o-clock class="h-5 w-5 text-gray-600 dark:text-gray-400" />
            </div>
            <div>
                <h3 class="text-base font-semibold text-gray-900 dark:text-white">{{ __('recent_reports') }}</h3>
                <p class="text-xs text-gray-500">{{ __('previously_generated_reports') }}</p>
            </div>
        </div>

        @if (count($recentReports) > 0)
            <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <table class="w-full">
                    <thead>
                        <tr class="border-b border-gray-200 dark:border-gray-700">
                            <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                                {{ __('filename') }}
                            </th>
                            <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                                {{ __('format') }}
                            </th>
                            <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                                {{ __('size') }}
                            </th>
                            <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                                {{ __('generated_at') }}
                            </th>
                            <th class="px-4 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                                {{ __('actions') }}
                            </th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 dark:divide-gray-700">
                        @foreach ($recentReports as $report)
                            <tr class="transition-colors duration-200 hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                <td class="px-4 py-3">
                                    <div class="flex items-center gap-2">
                                        @php
                                            $formatIcon = ($report['format'] ?? 'pdf') === 'csv'
                                                ? 'heroicon-o-table-cells'
                                                : 'heroicon-o-document-text';
                                            $formatColor = ($report['format'] ?? 'pdf') === 'csv'
                                                ? 'text-green-600 dark:text-green-400'
                                                : 'text-red-600 dark:text-red-400';
                                        @endphp
                                        <x-dynamic-component
                                            :component="$formatIcon"
                                            class="h-4 w-4 {{ $formatColor }}"
                                        />
                                        <span class="text-sm text-gray-900 dark:text-gray-300">
                                            {{ $report['filename'] }}
                                        </span>
                                    </div>
                                </td>
                                <td class="px-4 py-3">
                                    <span class="inline-flex items-center rounded-full border border-gray-200 bg-gray-50 px-2 py-0.5 text-[10px] font-semibold uppercase text-gray-600 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-400">
                                        {{ strtoupper($report['format'] ?? 'pdf') }}
                                    </span>
                                </td>
                                <td class="px-4 py-3 text-sm text-gray-600 dark:text-gray-500">
                                    {{ $report['size'] }}
                                </td>
                                <td class="px-4 py-3 text-sm text-gray-600 dark:text-gray-500">
                                    {{ $report['created_at'] }}
                                </td>
                                <td class="px-4 py-3 text-right">
                                    <button
                                        wire:click="downloadReport('{{ $report['filename'] }}')"
                                        type="button"
                                        class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-primary-600 transition-colors duration-200 hover:bg-primary-50 dark:text-primary-400 dark:hover:bg-primary-500/10"
                                    >
                                        <x-heroicon-o-arrow-down-tray class="h-3.5 w-3.5" />
                                        {{ __('download') }}
                                    </button>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @else
            {{-- Empty State --}}
            <div class="flex flex-col items-center justify-center rounded-xl border border-gray-200 bg-white py-12 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <div class="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-500/10">
                    <x-heroicon-o-document-text class="h-6 w-6 text-gray-500" />
                </div>
                <p class="text-sm font-medium text-gray-600 dark:text-gray-400">
                    {{ __('no_recent_reports') }}
                </p>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-600">
                    {{ __('generate_report_to_see_here') }}
                </p>
            </div>
        @endif
    </div>
</x-filament-panels::page>
