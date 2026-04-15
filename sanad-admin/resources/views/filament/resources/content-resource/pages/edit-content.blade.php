<x-filament-panels::page>
    <div class="mx-auto max-w-3xl">
        <div class="bg-white/5 dark:bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6">
            <form wire:submit="save" class="space-y-6">
                {{-- Title --}}
                <div>
                    <label for="title" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('title') }} <span class="text-danger-400">*</span>
                    </label>
                    <input
                        id="title"
                        wire:model="contentTitle"
                        type="text"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_title') }}"
                    />
                    @error('contentTitle')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Category --}}
                <div>
                    <label for="category" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('category') }} <span class="text-danger-400">*</span>
                    </label>
                    <input
                        id="category"
                        wire:model="category"
                        type="text"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_category') }}"
                    />
                    @error('category')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Type --}}
                <div>
                    <label for="type" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('type') }}
                    </label>
                    <select
                        id="type"
                        wire:model.live="type"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                    >
                        <option value="article">{{ __('article') }}</option>
                        <option value="exercise">{{ __('exercise') }}</option>
                        <option value="video">{{ __('video') }}</option>
                        <option value="podcast">{{ __('podcast') }}</option>
                    </select>
                    @error('type')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Content Text --}}
                <div>
                    <label for="content_text" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('content_text') }}
                        @if ($type === 'article')
                            <span class="text-danger-400">*</span>
                        @endif
                    </label>
                    <textarea
                        id="content_text"
                        wire:model="content_text"
                        rows="8"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('enter_content_text') }}"
                    ></textarea>
                    @error('content_text')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Media URL --}}
                <div>
                    <label for="media_url" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('media_url') }}
                        @if (in_array($type, ['video', 'podcast']))
                            <span class="text-danger-400">*</span>
                        @endif
                    </label>
                    <input
                        id="media_url"
                        wire:model="media_url"
                        type="url"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="https://..."
                    />
                    @error('media_url')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Link URL --}}
                <div>
                    <label for="link_url" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('link_url') }}
                    </label>
                    <input
                        id="link_url"
                        wire:model="link_url"
                        type="url"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="https://..."
                    />
                    @error('link_url')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Thumbnail URL --}}
                <div>
                    <label for="thumbnail_url" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('thumbnail_url') }}
                    </label>
                    <input
                        id="thumbnail_url"
                        wire:model="thumbnail_url"
                        type="url"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="https://..."
                    />
                    @error('thumbnail_url')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Mood Tags --}}
                <div>
                    <label for="mood_tags" class="mb-1 block text-sm font-medium text-gray-300">
                        {{ __('mood_tags') }}
                    </label>
                    <input
                        id="mood_tags"
                        wire:model="mood_tags_input"
                        type="text"
                        class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
                        placeholder="{{ __('mood_tags_placeholder') }}"
                    />
                    <p class="mt-1 text-xs text-gray-500">{{ __('mood_tags_hint') }}</p>
                    @error('mood_tags_input')
                        <p class="mt-1 text-xs text-danger-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Is Premium Toggle --}}
                <div class="flex items-center gap-3">
                    <button
                        type="button"
                        wire:click="$toggle('is_premium')"
                        @class([
                            'relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none',
                            'bg-warning-600' => $is_premium,
                            'bg-gray-600' => !$is_premium,
                        ])
                        role="switch"
                        aria-checked="{{ $is_premium ? 'true' : 'false' }}"
                    >
                        <span
                            @class([
                                'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                                'translate-x-5' => $is_premium,
                                'translate-x-0' => !$is_premium,
                            ])
                        ></span>
                    </button>
                    <label class="text-sm font-medium text-gray-300">{{ __('is_premium') }}</label>
                </div>

                {{-- Is Published Toggle --}}
                <div class="flex items-center gap-3">
                    <button
                        type="button"
                        wire:click="$toggle('is_published')"
                        @class([
                            'relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none',
                            'bg-primary-600' => $is_published,
                            'bg-gray-600' => !$is_published,
                        ])
                        role="switch"
                        aria-checked="{{ $is_published ? 'true' : 'false' }}"
                    >
                        <span
                            @class([
                                'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                                'translate-x-5' => $is_published,
                                'translate-x-0' => !$is_published,
                            ])
                        ></span>
                    </button>
                    <label class="text-sm font-medium text-gray-300">{{ __('is_published') }}</label>
                </div>

                {{-- Actions --}}
                <div class="flex items-center justify-end gap-3 border-t border-white/10 pt-6">
                    <a
                        href="{{ \App\Filament\Resources\ContentResource::getUrl('index') }}"
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
