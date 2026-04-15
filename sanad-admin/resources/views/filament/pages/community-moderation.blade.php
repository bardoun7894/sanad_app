<x-filament-panels::page>
    <div class="space-y-4">
        @forelse ($this->flaggedPosts as $post)
            @php
                $postId = $post['id'] ?? '';
                $authorId = $post['author_id'] ?? '';
                $authorName = !empty($post['is_anonymous'])
                    ? __('anonymous')
                    : ($post['author_name'] ?? __('unknown_user'));
                $content = $post['content'] ?? '';
                $contentPreview = mb_strlen($content) > 200
                    ? mb_substr($content, 0, 200) . '...'
                    : $content;
                $category = $post['category'] ?? 'general';
                $reportCount = (int) ($post['report_count'] ?? 0);
                $commentsCount = (int) ($post['comments_count'] ?? 0);
                $reactions = $post['reactions'] ?? [];
                $categoryClasses = \App\Filament\Pages\CommunityModeration::getCategoryBadgeClasses($category);
                $categoryLabel = \App\Filament\Pages\CommunityModeration::getCategoryLabel($category);

                // Time display
                $createdAt = '';
                if (!empty($post['created_at'])) {
                    try {
                        $createdAt = \Carbon\Carbon::parse($post['created_at'])->diffForHumans();
                    } catch (\Exception $e) {
                        $createdAt = $post['created_at'];
                    }
                }

                // Reactions summary
                $reactionParts = [];
                if (is_array($reactions)) {
                    foreach ($reactions as $type => $count) {
                        if (is_numeric($count) && (int) $count > 0) {
                            $reactionParts[] = "{$type}: {$count}";
                        } elseif (is_array($count)) {
                            $reactionParts[] = "{$type}: " . count($count);
                        }
                    }
                }
                $reactionsSummary = !empty($reactionParts)
                    ? implode(', ', $reactionParts)
                    : __('no_reactions');
            @endphp

            <div class="rounded-xl border border-gray-200 bg-white p-5 shadow-sm transition-colors duration-200 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700/50">
                {{-- Post Header --}}
                <div class="flex items-start justify-between gap-4">
                    <div class="min-w-0 flex-1">
                        <div class="flex flex-wrap items-center gap-2">
                            {{-- Author --}}
                            <div class="flex items-center gap-2">
                                <div class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-500/20">
                                    <x-heroicon-o-user class="h-4 w-4 text-gray-600 dark:text-gray-400" />
                                </div>
                                <span class="text-sm font-medium text-gray-900 dark:text-gray-200">{{ $authorName }}</span>
                            </div>

                            {{-- Category Badge --}}
                            <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[11px] font-medium {{ $categoryClasses }}">
                                {{ $categoryLabel }}
                            </span>

                            {{-- Report Count Badge --}}
                            <span class="inline-flex items-center gap-1 rounded-full border border-red-200 bg-red-50 px-2.5 py-0.5 text-[11px] font-medium text-red-700 dark:border-danger-500/20 dark:bg-danger-500/10 dark:text-danger-400">
                                <x-heroicon-o-flag class="h-3 w-3" />
                                {{ $reportCount }} {{ trans_choice('reports_count', $reportCount, ['count' => $reportCount]) }}
                            </span>

                            {{-- Time --}}
                            @if ($createdAt)
                                <span class="text-xs text-gray-500">{{ $createdAt }}</span>
                            @endif
                        </div>
                    </div>
                </div>

                {{-- Post Content --}}
                <div class="mt-3">
                    <p class="text-sm leading-relaxed text-gray-700 dark:text-gray-300">{{ $contentPreview }}</p>
                </div>

                {{-- Post Meta (reactions, comments) --}}
                <div class="mt-3 flex flex-wrap items-center gap-4 text-xs text-gray-500">
                    <span class="flex items-center gap-1">
                        <x-heroicon-o-heart class="h-3.5 w-3.5" />
                        {{ $reactionsSummary }}
                    </span>
                    <span class="flex items-center gap-1">
                        <x-heroicon-o-chat-bubble-left class="h-3.5 w-3.5" />
                        {{ $commentsCount }} {{ __('comments') }}
                    </span>
                </div>

                {{-- Actions --}}
                <div class="mt-4 flex items-center gap-2 border-t border-gray-200 pt-4 dark:border-gray-700">
                    {{-- Approve --}}
                    <button
                        wire:click="approvePost('{{ $postId }}')"
                        wire:confirm="{{ __('confirm_approve_post') }}"
                        class="inline-flex items-center gap-1.5 rounded-lg border border-green-200 bg-green-50 px-3 py-1.5 text-xs font-medium text-green-700 transition-colors duration-150 hover:bg-green-100 dark:border-success-500/20 dark:bg-success-500/10 dark:text-success-400 dark:hover:bg-success-500/20"
                    >
                        <x-heroicon-o-check-circle class="h-4 w-4" />
                        {{ __('approve') }}
                    </button>

                    {{-- Remove --}}
                    <button
                        wire:click="removePost('{{ $postId }}')"
                        wire:confirm="{{ __('confirm_remove_post') }}"
                        class="inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-medium text-red-700 transition-colors duration-150 hover:bg-red-100 dark:border-danger-500/20 dark:bg-danger-500/10 dark:text-danger-400 dark:hover:bg-danger-500/20"
                    >
                        <x-heroicon-o-trash class="h-4 w-4" />
                        {{ __('remove') }}
                    </button>

                    {{-- Warn User --}}
                    @if (!empty($authorId))
                        <button
                            wire:click="warnUser('{{ $postId }}', '{{ $authorId }}')"
                            wire:confirm="{{ __('confirm_warn_user') }}"
                            class="inline-flex items-center gap-1.5 rounded-lg border border-amber-200 bg-amber-50 px-3 py-1.5 text-xs font-medium text-amber-700 transition-colors duration-150 hover:bg-amber-100 dark:border-warning-500/20 dark:bg-warning-500/10 dark:text-warning-400 dark:hover:bg-warning-500/20"
                        >
                            <x-heroicon-o-exclamation-triangle class="h-4 w-4" />
                            {{ __('warn_user') }}
                        </button>
                    @endif
                </div>
            </div>
        @empty
            {{-- Empty State --}}
            <div class="flex flex-col items-center justify-center rounded-xl border border-gray-200 bg-white py-16 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-green-100 dark:bg-success-500/10">
                    <x-heroicon-o-shield-check class="h-8 w-8 text-green-600 dark:text-success-400" />
                </div>
                <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-200">{{ __('no_flagged_posts') }}</h3>
                <p class="mt-2 max-w-sm text-center text-sm text-gray-600 dark:text-gray-500">
                    {{ __('no_flagged_posts_description') }}
                </p>
            </div>
        @endforelse
    </div>
</x-filament-panels::page>
