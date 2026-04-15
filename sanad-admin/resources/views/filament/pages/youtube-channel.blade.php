<x-filament-panels::page>
    {{-- ── Header Info ────────────────────────────────────────── --}}
    <div class="mb-6 rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-center gap-4">
                <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-red-500/20">
                    <svg class="h-6 w-6 text-red-400" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814z"/>
                        <path d="M9.545 15.568V8.432L15.818 12l-6.273 3.568z" fill="white"/>
                    </svg>
                </div>
                <div>
                    <h3 class="text-lg font-bold text-gray-200">{{ __('youtube_channel') }}</h3>
                    <a href="https://www.youtube.com/channel/UCWS5K6VFx3YrGBqhoVmMRSQ"
                       target="_blank"
                       class="text-sm text-primary-400 hover:text-primary-300 transition">
                        {{ __('view_channel') }} &rarr;
                    </a>
                </div>
            </div>

            <div class="flex flex-wrap gap-3">
                <button
                    wire:click="refreshVideos"
                    class="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                >
                    <x-heroicon-o-arrow-path class="h-4 w-4" wire:loading.class="animate-spin" wire:target="refreshVideos" />
                    {{ __('refresh') }}
                </button>

                <button
                    wire:click="syncAllVideos('video')"
                    wire:confirm="{{ __('confirm_sync_all_videos') }}"
                    class="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-primary-700"
                >
                    <x-heroicon-o-cloud-arrow-down class="h-4 w-4" />
                    {{ __('sync_all_as_video') }}
                </button>

                <button
                    wire:click="syncAllVideos('podcast')"
                    wire:confirm="{{ __('confirm_sync_all_podcasts') }}"
                    class="inline-flex items-center gap-2 rounded-xl bg-info-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-info-700"
                >
                    <x-heroicon-o-cloud-arrow-down class="h-4 w-4" />
                    {{ __('sync_all_as_podcast') }}
                </button>
            </div>
        </div>

        {{-- Stats --}}
        <div class="mt-4 flex flex-wrap gap-6 border-t border-white/10 pt-4">
            <div class="text-sm">
                <span class="text-gray-500">{{ __('total_videos') }}:</span>
                <span class="ml-1 font-semibold text-gray-200">{{ count($videos) }}</span>
            </div>
            <div class="text-sm">
                <span class="text-gray-500">{{ __('synced') }}:</span>
                <span class="ml-1 font-semibold text-success-400">{{ count($syncedVideoIds) }}</span>
            </div>
            <div class="text-sm">
                <span class="text-gray-500">{{ __('not_synced') }}:</span>
                <span class="ml-1 font-semibold text-warning-400">{{ count($videos) - count($syncedVideoIds) }}</span>
            </div>
        </div>
    </div>

    {{-- ── Videos Grid ────────────────────────────────────────── --}}
    @if (count($videos) > 0)
        <div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            @foreach ($videos as $video)
                @php
                    $isSynced = in_array($video['video_id'], $syncedVideoIds);
                @endphp
                <div class="group relative overflow-hidden rounded-xl border border-white/10 bg-white/5 backdrop-blur-xl transition hover:border-white/20 hover:bg-white/[0.07]">
                    {{-- Thumbnail --}}
                    <div class="relative aspect-video overflow-hidden">
                        <img
                            src="{{ $video['thumbnail_url'] }}"
                            alt="{{ $video['title'] }}"
                            class="h-full w-full object-cover transition group-hover:scale-105"
                            loading="lazy"
                        />
                        {{-- Play overlay --}}
                        <a href="{{ $video['video_url'] }}" target="_blank"
                           class="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 transition group-hover:opacity-100">
                            <div class="flex h-14 w-14 items-center justify-center rounded-full bg-red-600 shadow-lg">
                                <svg class="h-7 w-7 text-white ml-1" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M8 5v14l11-7z"/>
                                </svg>
                            </div>
                        </a>
                        {{-- Synced badge --}}
                        @if ($isSynced)
                            <div class="absolute left-3 top-3 inline-flex items-center gap-1 rounded-full bg-success-500/90 px-2.5 py-1 text-xs font-semibold text-white">
                                <x-heroicon-o-check-circle class="h-3.5 w-3.5" />
                                {{ __('synced') }}
                            </div>
                        @endif
                    </div>

                    {{-- Content --}}
                    <div class="p-4">
                        <h4 class="line-clamp-2 text-sm font-semibold text-gray-200 leading-snug">
                            {{ $video['title'] }}
                        </h4>
                        @if (!empty($video['description']))
                            <p class="mt-2 line-clamp-2 text-xs text-gray-500 leading-relaxed">
                                {{ $video['description'] }}
                            </p>
                        @endif
                        @if (!empty($video['published_at']))
                            <p class="mt-2 text-xs text-gray-600">
                                {{ \Carbon\Carbon::parse($video['published_at'])->format('Y-m-d') }}
                            </p>
                        @endif

                        {{-- Actions --}}
                        <div class="mt-4 flex flex-wrap gap-2">
                            @if (!$isSynced)
                                <button
                                    wire:click="syncVideo('{{ $video['video_id'] }}', 'video')"
                                    class="inline-flex items-center gap-1.5 rounded-lg bg-warning-500/20 px-3 py-1.5 text-xs font-medium text-warning-400 transition hover:bg-warning-500/30"
                                >
                                    <x-heroicon-o-film class="h-3.5 w-3.5" />
                                    {{ __('sync_as_video') }}
                                </button>
                                <button
                                    wire:click="syncVideo('{{ $video['video_id'] }}', 'podcast')"
                                    class="inline-flex items-center gap-1.5 rounded-lg bg-info-500/20 px-3 py-1.5 text-xs font-medium text-info-400 transition hover:bg-info-500/30"
                                >
                                    <x-heroicon-o-microphone class="h-3.5 w-3.5" />
                                    {{ __('sync_as_podcast') }}
                                </button>
                            @else
                                <span class="inline-flex items-center gap-1.5 rounded-lg bg-success-500/10 px-3 py-1.5 text-xs font-medium text-success-400">
                                    <x-heroicon-o-check class="h-3.5 w-3.5" />
                                    {{ __('already_synced') }}
                                </span>
                            @endif

                            <a
                                href="{{ $video['video_url'] }}"
                                target="_blank"
                                class="inline-flex items-center gap-1.5 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-medium text-gray-400 transition hover:bg-white/10 hover:text-white"
                            >
                                <x-heroicon-o-arrow-top-right-on-square class="h-3.5 w-3.5" />
                                {{ __('watch') }}
                            </a>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    @else
        <div class="flex flex-col items-center justify-center rounded-xl border border-white/10 bg-white/5 px-6 py-16 backdrop-blur-xl">
            <x-heroicon-o-video-camera class="h-12 w-12 text-gray-600" />
            <p class="mt-4 text-gray-500">{{ __('no_youtube_videos') }}</p>
            <button
                wire:click="refreshVideos"
                class="mt-4 inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-primary-700"
            >
                <x-heroicon-o-arrow-path class="h-4 w-4" />
                {{ __('retry') }}
            </button>
        </div>
    @endif
</x-filament-panels::page>
