<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class YouTubeService
{
    public const CHANNEL_ID = 'UCWS5K6VFx3YrGBqhoVmMRSQ';
    public const CHANNEL_URL = 'https://www.youtube.com/channel/' . self::CHANNEL_ID;

    private const FEED_URL = 'https://www.youtube.com/feeds/videos.xml?channel_id=' . self::CHANNEL_ID;

    /**
     * Fetch videos from the YouTube channel RSS/Atom feed.
     * No API key required.
     *
     * @param int $limit
     * @return array<array{video_id: string, title: string, description: string, thumbnail_url: string, published_at: string, video_url: string}>
     */
    public function getChannelVideos(int $limit = 15): array
    {
        try {
            $response = Http::timeout(10)->get(self::FEED_URL);

            if (! $response->successful()) {
                return [];
            }

            return $this->parseAtomFeed($response->body(), $limit);
        } catch (\Exception $e) {
            return [];
        }
    }

    /**
     * Parse the Atom XML feed into an array of video data.
     */
    private function parseAtomFeed(string $xml, int $limit): array
    {
        $videos = [];

        try {
            $feed = new \SimpleXMLElement($xml);

            // Register namespaces
            $namespaces = $feed->getNamespaces(true);

            foreach ($feed->entry as $entry) {
                if (count($videos) >= $limit) {
                    break;
                }

                $yt = $entry->children($namespaces['yt'] ?? 'http://www.youtube.com/xml/schemas/2015');
                $media = $entry->children($namespaces['media'] ?? 'http://search.yahoo.com/mrss/');

                $videoId = (string) $yt->videoId;
                $title = (string) $entry->title;
                $published = (string) $entry->published;
                $description = '';

                if (isset($media->group->description)) {
                    $description = (string) $media->group->description;
                }

                if (empty($videoId) || empty($title)) {
                    continue;
                }

                $videos[] = [
                    'video_id' => $videoId,
                    'title' => $title,
                    'description' => mb_substr($description, 0, 500),
                    'thumbnail_url' => "https://img.youtube.com/vi/{$videoId}/hqdefault.jpg",
                    'published_at' => $published,
                    'video_url' => "https://www.youtube.com/watch?v={$videoId}",
                ];
            }
        } catch (\Exception $e) {
            // Fall back to empty
        }

        return $videos;
    }
}
