<x-filament-panels::page>
    <div class="mx-auto max-w-3xl">
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
            <form wire:submit="save" class="space-y-6">
                {{-- Title (AR) --}}
                <div>
                    <label for="title" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('title_ar') }} <span class="text-danger-400">*</span>
                    </label>
                    <input
                        id="title"
                        wire:model="challengeTitle"
                        type="text"
                        maxlength="200"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_title_ar') }}"
                    />
                    @error('challengeTitle')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Title (EN) --}}
                <div>
                    <label for="title_en" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('title_en') }} <span class="text-danger-400">*</span>
                    </label>
                    <input
                        id="title_en"
                        wire:model="challengeTitleEn"
                        type="text"
                        maxlength="200"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_title_en') }}"
                    />
                    @error('challengeTitleEn')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Description (AR) --}}
                <div>
                    <label for="description" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('description_ar') }} <span class="text-danger-400">*</span>
                    </label>
                    <textarea
                        id="description"
                        wire:model="description"
                        rows="3"
                        maxlength="1000"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_description_ar') }}"
                    ></textarea>
                    @error('description')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Description (EN) --}}
                <div>
                    <label for="description_en" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('description_en') }} <span class="text-danger-400">*</span>
                    </label>
                    <textarea
                        id="description_en"
                        wire:model="description_en"
                        rows="3"
                        maxlength="1000"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_description_en') }}"
                    ></textarea>
                    @error('description_en')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Type --}}
                <div>
                    <label for="type" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('type') }} <span class="text-danger-400">*</span>
                    </label>
                    <select
                        id="type"
                        wire:model.live="type"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                    >
                        @foreach (['breathing', 'gratitude', 'mindfulness', 'exercise', 'journaling', 'social', 'selfCare', 'general'] as $t)
                            <option value="{{ $t }}">{{ ucfirst($t) }}</option>
                        @endforeach
                    </select>
                    @error('type')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Duration & Order (side by side) --}}
                <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                        <label for="duration_minutes" class="mb-1 block text-sm font-medium text-gray-300">
                            {{ __('duration_minutes') }} <span class="text-danger-400">*</span>
                        </label>
                        <input
                            id="duration_minutes"
                            wire:model="duration_minutes"
                            type="number"
                            min="1"
                            max="120"
                            class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        />
                        @error('duration_minutes')
                            <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                        @enderror
                    </div>
                    <div>
                        <label for="order" class="mb-1 block text-sm font-medium text-gray-300">
                            {{ __('order') }} <span class="text-danger-400">*</span>
                        </label>
                        <input
                            id="order"
                            wire:model="order"
                            type="number"
                            min="0"
                            class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        />
                        @error('order')
                            <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                        @enderror
                    </div>
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
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                    />
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
                        href="{{ \App\Filament\Resources\ChallengeResource::getUrl('index') }}"
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
