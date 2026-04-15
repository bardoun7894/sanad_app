<?php

namespace App\Filament\Pages;

use App\Models\AppContent;
use App\Services\YouTubeService;
use Filament\Pages\Page;

class YouTubeChannel extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-play-circle';

    protected static ?int $navigationSort = 11;

    protected static ?string $slug = 'youtube-channel';

    protected static string $view = 'filament.pages.youtube-channel';

    public array $videos = [];

    public array $syncedVideoIds = [];

    public bool $loading = false;

    public static function getNavigationLabel(): string
    {
        return __('youtube_channel');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    public function getTitle(): string
    {
        return __('youtube_channel');
    }

    public function getHeading(): string
    {
        return __('youtube_channel');
    }

    public function mount(): void
    {
        $this->loadVideos();
        $this->loadSyncedIds();
    }

    public function loadVideos(): void
    {
        $service = new YouTubeService();
        $this->videos = $service->getChannelVideos(15);
    }

    /**
     * Load IDs of YouTube videos already synced to Firestore.
     */
    public function loadSyncedIds(): void
    {
        $allContent = AppContent::all();
        $this->syncedVideoIds = [];

        foreach ($allContent as $content) {
            $mediaUrl = $content->safeGet('media_url', '');
            $linkUrl = $content->safeGet('link_url', '');

            foreach ($this->videos as $video) {
                if (
                    str_contains($mediaUrl, $video['video_id']) ||
                    str_contains($linkUrl, $video['video_id'])
                ) {
                    $this->syncedVideoIds[] = $video['video_id'];
                }
            }
        }

        $this->syncedVideoIds = array_unique($this->syncedVideoIds);
    }

    /**
     * Sync a single YouTube video to Firestore as content.
     */
    public function syncVideo(string $videoId, string $type = 'video'): void
    {
        // Find the video in our fetched list
        $video = collect($this->videos)->firstWhere('video_id', $videoId);
        if (! $video) {
            $this->dispatch('notify', type: 'danger', message: __('video_not_found'));
            return;
        }

        // Check if already synced
        if (in_array($videoId, $this->syncedVideoIds)) {
            $this->dispatch('notify', type: 'warning', message: __('video_already_synced'));
            return;
        }

        AppContent::create([
            'title' => $video['title'],
            'category' => $type === 'podcast' ? __('podcast') : __('video'),
            'type' => $type,
            'content_text' => $video['description'],
            'media_url' => $video['video_url'],
            'link_url' => $video['video_url'],
            'thumbnail_url' => $video['thumbnail_url'],
            'is_premium' => false,
            'mood_tags' => [],
            'is_published' => true,
            'created_at' => now()->toDateTimeString(),
        ]);

        $this->syncedVideoIds[] = $videoId;
        $this->dispatch('notify', type: 'success', message: __('video_synced_successfully'));
    }

    /**
     * Sync all unsyced videos at once.
     */
    public function syncAllVideos(string $type = 'video'): void
    {
        $synced = 0;

        foreach ($this->videos as $video) {
            if (! in_array($video['video_id'], $this->syncedVideoIds)) {
                AppContent::create([
                    'title' => $video['title'],
                    'category' => $type === 'podcast' ? __('podcast') : __('video'),
                    'type' => $type,
                    'content_text' => $video['description'],
                    'media_url' => $video['video_url'],
                    'link_url' => $video['video_url'],
                    'thumbnail_url' => $video['thumbnail_url'],
                    'is_premium' => false,
                    'mood_tags' => [],
                    'is_published' => true,
                    'created_at' => now()->toDateTimeString(),
                ]);

                $this->syncedVideoIds[] = $video['video_id'];
                $synced++;
            }
        }

        if ($synced > 0) {
            $this->dispatch('notify', type: 'success', message: __('videos_synced_count', ['count' => $synced]));
        } else {
            $this->dispatch('notify', type: 'info', message: __('all_videos_already_synced'));
        }
    }

    public function refreshVideos(): void
    {
        $this->loadVideos();
        $this->loadSyncedIds();
        $this->dispatch('notify', type: 'success', message: __('videos_refreshed'));
    }
}
