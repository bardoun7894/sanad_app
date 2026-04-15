<x-filament-panels::page>
    <div class="mx-auto max-w-3xl">
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
            <form wire:submit="save" class="space-y-6">
                {{-- Quote Text --}}
                <div>
                    <label for="text" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('quote_text') }} <span class="text-danger-400">*</span>
                    </label>
                    <textarea
                        id="text"
                        wire:model="text"
                        rows="4"
                        maxlength="500"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_quote_text') }}"
                    ></textarea>
                    @error('text')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Author --}}
                <div>
                    <label for="author" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('author') }}
                    </label>
                    <input
                        id="author"
                        wire:model="author"
                        type="text"
                        maxlength="100"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_author') }}"
                    />
                    @error('author')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Category --}}
                <div>
                    <label for="category" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('category') }} <span class="text-danger-400">*</span>
                    </label>
                    <select
                        id="category"
                        wire:model="category"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                    >
                        <option value="">{{ __('select_category') }}</option>
                        <option value="Anxiety">{{ __('anxiety') }}</option>
                        <option value="Depression">{{ __('depression') }}</option>
                        <option value="General">{{ __('general') }}</option>
                        <option value="Motivation">{{ __('motivation') }}</option>
                        <option value="Self-Care">{{ __('self_care') }}</option>
                    </select>
                    @error('category')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Publish Date --}}
                <div>
                    <label for="publish_date" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('publish_date') }}
                    </label>
                    <input
                        id="publish_date"
                        wire:model="publish_date"
                        type="date"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                    />
                    @error('publish_date')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Is Active Toggle --}}
                <div class="flex items-center gap-3">
                    <button
                        type="button"
                        wire:click="$toggle('is_active')"
                        @class([
                            'relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none',
                            'bg-primary-600' => $is_active,
                            'bg-gray-600' => !$is_active,
                        ])
                        role="switch"
                        aria-checked="{{ $is_active ? 'true' : 'false' }}"
                    >
                        <span
                            @class([
                                'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                                'translate-x-5' => $is_active,
                                'translate-x-0' => !$is_active,
                            ])
                        ></span>
                    </button>
                    <label class="text-sm font-medium text-gray-300">{{ __('active') }}</label>
                </div>

                {{-- Actions --}}
                <div class="flex items-center justify-end gap-3 border-t border-white/10 pt-6">
                    <a
                        href="{{ \App\Filament\Resources\QuoteResource::getUrl('index') }}"
                        class="rounded-xl border border-white/10 bg-white/5 px-5 py-2.5 text-sm font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                    >
                        {{ __('cancel') }}
                    </a>
                    <button
                        type="submit"
                        class="rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-primary-700"
                    >
                        {{ __('save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</x-filament-panels::page>
