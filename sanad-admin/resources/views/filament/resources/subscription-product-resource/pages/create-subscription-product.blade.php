<x-filament-panels::page>
    <div class="mx-auto max-w-3xl">
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
            <form wire:submit="save" class="space-y-6">
                {{-- Title --}}
                <div>
                    <label for="title" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('title') }} <span class="text-danger-400">*</span>
                    </label>
                    <input id="title" wire:model="product_title" type="text"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_title') }}" />
                    @error('product_title') <p class="mt-1 text-xs text-danger-400">{{ $message }}</p> @enderror
                </div>

                {{-- Description --}}
                <div>
                    <label for="description" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('description') }} <span class="text-danger-400">*</span>
                    </label>
                    <textarea id="description" wire:model="product_description" rows="3"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_description') }}"></textarea>
                    @error('product_description') <p class="mt-1 text-xs text-danger-400">{{ $message }}</p> @enderror
                </div>

                {{-- Price + Currency --}}
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label for="price" class="mb-1 block text-sm font-medium text-gray-300">
                            {{ __('price') }} <span class="text-danger-400">*</span>
                        </label>
                        <input id="price" wire:model="price" type="number" step="0.01" min="0"
                            class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                            placeholder="0.00" />
                        @error('price') <p class="mt-1 text-xs text-danger-400">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label for="currency_code" class="mb-1 block text-sm font-medium text-gray-300">
                            {{ __('currency') }} <span class="text-danger-400">*</span>
                        </label>
                        <select id="currency_code" wire:model="currency_code"
                            class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30">
                            <option value="SAR">SAR</option>
                            <option value="USD">USD</option>
                            <option value="EUR">EUR</option>
                        </select>
                        @error('currency_code') <p class="mt-1 text-xs text-danger-400">{{ $message }}</p> @enderror
                    </div>
                </div>

                {{-- Billing Period + Days --}}
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label for="billing_period" class="mb-1 block text-sm font-medium text-gray-300">
                            {{ __('billing_period') }} <span class="text-danger-400">*</span>
                        </label>
                        <select id="billing_period" wire:model="billing_period"
                            class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30">
                            <option value="weekly">{{ __('weekly') }}</option>
                            <option value="monthly">{{ __('monthly') }}</option>
                        </select>
                        @error('billing_period') <p class="mt-1 text-xs text-danger-400">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label for="billing_period_days" class="mb-1 block text-sm font-medium text-gray-300">
                            {{ __('billing_period_days') }} <span class="text-danger-400">*</span>
                        </label>
                        <input id="billing_period_days" wire:model="billing_period_days" type="number" min="1"
                            class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                            placeholder="30" />
                        @error('billing_period_days') <p class="mt-1 text-xs text-danger-400">{{ $message }}</p> @enderror
                    </div>
                </div>

                {{-- Localized Price --}}
                <div>
                    <label for="localized_price" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('localized_price') }}
                    </label>
                    <input id="localized_price" wire:model="localized_price" type="text"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="SAR 199.00" />
                    <p class="mt-1 text-xs text-gray-500">{{ __('localized_price_hint') }}</p>
                </div>

                {{-- Features --}}
                <div>
                    <label for="features_input" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('features') }}
                    </label>
                    <textarea id="features_input" wire:model="features_input" rows="5"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('features_placeholder') }}"></textarea>
                    <p class="mt-1 text-xs text-gray-500">{{ __('features_hint') }}</p>
                </div>

                {{-- Is Featured Toggle --}}
                <div class="flex items-center gap-3">
                    <button type="button" wire:click="$toggle('is_featured')"
                        @class([
                            'relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none',
                            'bg-warning-600' => $is_featured,
                            'bg-gray-600' => !$is_featured,
                        ])
                        role="switch"
                        aria-checked="{{ $is_featured ? 'true' : 'false' }}">
                        <span @class([
                            'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                            'translate-x-5' => $is_featured,
                            'translate-x-0' => !$is_featured,
                        ])></span>
                    </button>
                    <label class="text-sm font-medium text-gray-300">{{ __('is_featured') }}</label>
                </div>

                {{-- Actions --}}
                <div class="flex items-center justify-end gap-3 border-t border-white/10 pt-6">
                    <a href="{{ \App\Filament\Resources\SubscriptionProductResource::getUrl('index') }}"
                        class="rounded-xl border border-white/10 bg-white/5 px-5 py-2.5 text-sm font-medium text-gray-300 transition hover:bg-white/10 hover:text-white">
                        {{ __('cancel') }}
                    </a>
                    <button type="submit"
                        class="rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-primary-700">
                        {{ __('save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</x-filament-panels::page>
