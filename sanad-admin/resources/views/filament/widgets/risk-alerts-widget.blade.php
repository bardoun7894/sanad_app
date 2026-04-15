<x-filament-widgets::widget class="fi-risk-alerts-widget">
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="mb-4 text-lg font-semibold text-gray-900 dark:text-white">{{ __('risk_alerts') }}</h2>

        @php
            $alerts = $this->getAlerts();
        @endphp

        <div wire:poll.30s>
            @if (count($alerts) > 0)
                <div class="space-y-3">
                    @foreach ($alerts as $alert)
                        @php
                            $riskLevel = $alert['risk_level'] ?? 'low';
                            $riskColor = $this->getRiskColor($riskLevel);
                            $riskBgColor = $this->getRiskBgColor($riskLevel);
                            $badgeClasses = $this->getRiskBadgeClasses($riskLevel);
                        @endphp

                        <div class="flex items-start gap-3 rounded-xl border border-gray-100 bg-white p-3 shadow-sm transition-colors duration-200 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700/50">
                            {{-- Risk level indicator --}}
                            <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg {{ $riskBgColor }}">
                                <x-heroicon-o-exclamation-triangle class="h-5 w-5 {{ $riskColor }}" />
                            </div>

                            {{-- Content --}}
                            <div class="min-w-0 flex-1">
                                <div class="flex items-center gap-2">
                                    <p class="truncate text-sm font-medium text-gray-900 dark:text-white">
                                        {{ $alert['user_name'] ?? __('unknown_user') }}
                                    </p>
                                    <span class="inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] font-semibold uppercase {{ $badgeClasses }}">
                                        {{ ucfirst($riskLevel) }}
                                    </span>
                                </div>

                                <div class="mt-1 flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400">
                                    <span class="flex items-center gap-1">
                                        <x-heroicon-o-face-frown class="h-3.5 w-3.5" />
                                        {{ __('avg_mood') }}: {{ number_format($alert['average_mood'] ?? 0, 1) }}
                                    </span>
                                    <span class="flex items-center gap-1">
                                        <x-heroicon-o-document-text class="h-3.5 w-3.5" />
                                        {{ $alert['entry_count'] ?? 0 }} {{ __('entries') }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            @else
                {{-- Empty state --}}
                <div class="flex flex-col items-center justify-center rounded-xl border border-gray-200 bg-white py-8 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                    <div class="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-green-50 text-green-600 dark:bg-green-900/20 dark:text-green-400">
                        <x-heroicon-o-check-circle class="h-7 w-7" />
                    </div>
                    <p class="text-sm font-medium text-gray-900 dark:text-white">{{ __('all_clear') }}</p>
                    <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">{{ __('no_at_risk_patients') }}</p>
                </div>
            @endif
        </div>
    </div>
</x-filament-widgets::widget>
