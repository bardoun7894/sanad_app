<?php

namespace App\Filament\Pages;

use App\Services\ActivityLogService;
use App\Services\FirestoreService;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class CommunityModeration extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-shield-exclamation';

    protected static ?int $navigationSort = 6;

    protected static string $view = 'filament.pages.community-moderation';

    public array $flaggedPosts = [];

    public function getTitle(): string
    {
        return __('community_moderation');
    }

    public static function getNavigationLabel(): string
    {
        return __('community_moderation');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('communication');
    }

    public static function getNavigationBadge(): ?string
    {
        try {
            $firestore = app(FirestoreService::class);
            $flagged = $firestore->queryCollection('posts', [
                ['report_count', '>', 0],
            ], 'report_count', 'DESC', 500);

            return count($flagged) > 0 ? (string) count($flagged) : null;
        } catch (\Exception $e) {
            return null;
        }
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'danger';
    }

    public function mount(): void
    {
        $this->loadFlaggedPosts();
    }

    /**
     * Load all flagged posts from Firestore.
     */
    public function loadFlaggedPosts(): void
    {
        try {
            $firestore = app(FirestoreService::class);
            $this->flaggedPosts = $firestore->queryCollection('posts', [
                ['report_count', '>', 0],
            ], 'report_count', 'DESC', 100);
        } catch (\Exception $e) {
            Log::error("CommunityModeration loadFlaggedPosts failed: {$e->getMessage()}");
            $this->flaggedPosts = [];
        }
    }

    /**
     * Approve a post: reset report_count to 0.
     */
    public function approvePost(string $postId): void
    {
        try {
            $admin = Auth::user();
            $adminId = $admin?->getKey() ?? 'system';

            $firestore = app(FirestoreService::class);
            $firestore->updateDocument('posts', $postId, [
                'report_count' => 0,
                'moderated_by' => $adminId,
                'moderated_at' => now()->toDateTimeString(),
            ]);

            app(ActivityLogService::class)->log(
                'communityPostApproved',
                __('post_approved_log', ['id' => $postId]),
                ['post_id' => $postId, 'actor_uid' => $adminId],
            );

            Notification::make()
                ->title(__('post_approved'))
                ->body(__('post_approved_description'))
                ->success()
                ->send();

            $this->loadFlaggedPosts();
        } catch (\Exception $e) {
            Log::error("CommunityModeration approvePost failed: {$e->getMessage()}");
            Notification::make()
                ->title(__('action_failed'))
                ->body($e->getMessage())
                ->danger()
                ->send();
        }
    }

    /**
     * Remove a post: delete the document.
     */
    public function removePost(string $postId): void
    {
        try {
            $admin = Auth::user();
            $adminId = $admin?->getKey() ?? 'system';

            $firestore = app(FirestoreService::class);
            $firestore->deleteDocument('posts', $postId);

            app(ActivityLogService::class)->log(
                'communityPostRemoved',
                __('post_removed_log', ['id' => $postId]),
                ['post_id' => $postId, 'actor_uid' => $adminId],
            );

            Notification::make()
                ->title(__('post_removed'))
                ->body(__('post_removed_description'))
                ->success()
                ->send();

            $this->loadFlaggedPosts();
        } catch (\Exception $e) {
            Log::error("CommunityModeration removePost failed: {$e->getMessage()}");
            Notification::make()
                ->title(__('action_failed'))
                ->body($e->getMessage())
                ->danger()
                ->send();
        }
    }

    /**
     * Warn a user: create a notification document in the notifications collection.
     */
    public function warnUser(string $postId, string $authorId): void
    {
        try {
            if (empty($authorId)) {
                Notification::make()
                    ->title(__('action_failed'))
                    ->body(__('no_author_id'))
                    ->danger()
                    ->send();

                return;
            }

            $admin = Auth::user();
            $adminId = $admin?->getKey() ?? 'system';

            $firestore = app(FirestoreService::class);

            // Create a notification for the user
            $firestore->addDocument('notifications', [
                'user_id' => $authorId,
                'type' => 'community',
                'title' => __('community_warning_title'),
                'body' => __('community_warning_body'),
                'is_read' => false,
                'created_at' => now()->toDateTimeString(),
                'created_by' => $adminId,
                'metadata' => [
                    'post_id' => $postId,
                    'action' => 'warning',
                    'actor_uid' => $adminId,
                ],
            ]);

            app(ActivityLogService::class)->log(
                'communityUserWarned',
                __('user_warned_log', ['user_id' => $authorId, 'post_id' => $postId]),
                ['post_id' => $postId, 'author_id' => $authorId, 'actor_uid' => $adminId],
            );

            Notification::make()
                ->title(__('warning_sent'))
                ->body(__('warning_sent_description'))
                ->success()
                ->send();
        } catch (\Exception $e) {
            Log::error("CommunityModeration warnUser failed: {$e->getMessage()}");
            Notification::make()
                ->title(__('action_failed'))
                ->body($e->getMessage())
                ->danger()
                ->send();
        }
    }

    /**
     * Get the category badge Tailwind classes.
     */
    public static function getCategoryBadgeClasses(string $category): string
    {
        return match ($category) {
            'general' => 'bg-primary-500/10 text-primary-400 border-primary-500/20',
            'anxiety' => 'bg-warning-500/10 text-warning-400 border-warning-500/20',
            'depression' => 'bg-info-500/10 text-info-400 border-info-500/20',
            'relationships' => 'bg-success-500/10 text-success-400 border-success-500/20',
            'selfCare' => 'bg-purple-500/10 text-purple-400 border-purple-500/20',
            'motivation' => 'bg-primary-500/10 text-primary-400 border-primary-500/20',
            default => 'bg-gray-500/10 text-gray-400 border-gray-500/20',
        };
    }

    /**
     * Get a human-readable category label.
     */
    public static function getCategoryLabel(string $category): string
    {
        return match ($category) {
            'general' => __('category_general'),
            'anxiety' => __('category_anxiety'),
            'depression' => __('category_depression'),
            'relationships' => __('category_relationships'),
            'selfCare' => __('category_self_care'),
            'motivation' => __('category_motivation'),
            default => __('category_unknown'),
        };
    }
}
