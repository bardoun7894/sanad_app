<x-filament-panels::page>
    <div class="mb-6 flex items-center justify-between">
        <p class="text-sm text-gray-400">{{ count($records) }} {{ __('products') }}</p>
        <a href="{{ \App\Filament\Resources\SubscriptionProductResource::getUrl('create') }}"
           class="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-primary-700">
            <x-heroicon-o-plus class="h-4 w-4" />
            {{ __('create_subscription_product') }}
        </a>
    </div>

    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        @forelse ($records as $record)
            @php
                $features = $record->getAttribute('features');
                $featureList = is_array($features) ? $features : [];
            @endphp
            <div @class([
                'rounded-xl border bg-white/5 backdrop-blur-xl p-5 space-y-4 transition hover:bg-white/10',
                'border-warning-500/50 ring-1 ring-warning-500/20' => $record->getAttribute('is_featured'),
                'border-white/10' => !$record->getAttribute('is_featured'),
            ])>
                {{-- Header --}}
                <div class="flex items-start justify-between">
                    <div>
                        <h3 class="text-base font-semibold text-gray-200">{{ $record->safeGet('title', 'Untitled') }}</h3>
                        <p class="mt-1 text-xs text-gray-400">{{ $record->safeGet('description', '') }}</p>
                    </div>
                    @if ($record->getAttribute('is_featured'))
                        <span class="inline-flex items-center rounded-full bg-warning-500/20 px-2 py-0.5 text-xs font-semibold text-warning-400">
                            {{ __('featured') }}
                        </span>
                    @endif
                </div>

                {{-- Price --}}
                <div class="flex items-baseline gap-1">
                    <span class="text-2xl font-bold text-primary-400">{{ number_format((float) $record->getAttribute('price'), 2) }}</span>
                    <span class="text-sm text-gray-400">{{ $record->safeGet('currency_code', 'SAR') }}</span>
                    <span class="text-xs text-gray-500">/ {{ __($record->safeGet('billing_period', 'monthly')) }}</span>
                </div>

                {{-- Features --}}
                @if (count($featureList) > 0)
                    <ul class="space-y-1.5">
                        @foreach ($featureList as $feature)
                            <li class="flex items-start gap-2 text-xs text-gray-300">
                                <x-heroicon-o-check class="mt-0.5 h-3.5 w-3.5 shrink-0 text-success-400" />
                                {{ $feature }}
                            </li>
                        @endforeach
                    </ul>
                @endif

                {{-- Meta --}}
                <div class="flex items-center gap-3 text-xs text-gray-500">
                    <span>{{ $record->safeGet('billing_period_days', 30) }} {{ __('days') }}</span>
                    @if ($record->safeGet('localized_price'))
                        <span>{{ $record->safeGet('localized_price') }}</span>
                    @endif
                </div>

                {{-- Actions --}}
                <div class="flex items-center gap-2 border-t border-white/10 pt-3">
                    <a href="{{ \App\Filament\Resources\SubscriptionProductResource::getUrl('edit', ['record' => $record->getKey()]) }}"
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
            </div>
        @empty
            <div class="col-span-full rounded-xl border border-white/10 bg-white/5 px-6 py-12 text-center">
                <div class="flex flex-col items-center gap-2 text-gray-500">
                    <x-heroicon-o-credit-card class="h-8 w-8 text-gray-600" />
                    <span>{{ __('no_products_found') }}</span>
                </div>
            </div>
        @endforelse
    </div>
</x-filament-panels::page>
