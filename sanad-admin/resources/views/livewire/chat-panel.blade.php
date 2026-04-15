<div wire:poll.5s="refreshData" class="flex h-[calc(100vh-14rem)] flex-col">

    {{-- ── Stats Header ──────────────────────────────────────────── --}}
    <div class="mb-4 grid grid-cols-2 gap-3 md:grid-cols-4">
        {{-- Total Conversations --}}
        <div class="rounded-xl border border-gray-200 bg-white p-3 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="flex items-center gap-2">
                <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-500/10">
                    <x-heroicon-o-chat-bubble-left-right class="h-4 w-4 text-primary-600 dark:text-primary-400" />
                </div>
                <div>
                    <p class="text-xs text-gray-600 dark:text-gray-400">{{ __('total_conversations') }}</p>
                    <p class="text-lg font-bold text-gray-900 dark:text-white">{{ $stats['total_conversations'] ?? 0 }}</p>
                </div>
            </div>
        </div>

        {{-- Unread Messages --}}
        <div class="rounded-xl border border-gray-200 bg-white p-3 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="flex items-center gap-2">
                <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-100 dark:bg-warning-500/10">
                    <x-heroicon-o-envelope class="h-4 w-4 text-amber-600 dark:text-warning-400" />
                </div>
                <div>
                    <p class="text-xs text-gray-600 dark:text-gray-400">{{ __('unread_messages') }}</p>
                    <p class="text-lg font-bold text-gray-900 dark:text-white">{{ $stats['unread_messages'] ?? 0 }}</p>
                </div>
            </div>
        </div>

        {{-- Urgent --}}
        <div class="rounded-xl border border-gray-200 bg-white p-3 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="flex items-center gap-2">
                <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-red-100 dark:bg-danger-500/10">
                    <x-heroicon-o-exclamation-triangle class="h-4 w-4 text-red-600 dark:text-danger-400" />
                </div>
                <div>
                    <p class="text-xs text-gray-600 dark:text-gray-400">{{ __('urgent') }}</p>
                    <p class="text-lg font-bold text-gray-900 dark:text-white">{{ $stats['urgent_count'] ?? 0 }}</p>
                </div>
            </div>
        </div>

        {{-- Avg Response Time --}}
        <div class="rounded-xl border border-gray-200 bg-white p-3 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <div class="flex items-center gap-2">
                <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-green-100 dark:bg-success-500/10">
                    <x-heroicon-o-clock class="h-4 w-4 text-green-600 dark:text-success-400" />
                </div>
                <div>
                    <p class="text-xs text-gray-600 dark:text-gray-400">{{ __('avg_response_time') }}</p>
                    <p class="text-lg font-bold text-gray-900 dark:text-white">{{ $stats['avg_response_time'] ?? __('not_available') }}</p>
                </div>
            </div>
        </div>
    </div>

    {{-- ── Chat Split View ───────────────────────────────────────── --}}
    <div class="flex flex-1 gap-4 overflow-hidden">

        {{-- Left Column: Thread List (1/3) --}}
        <div class="flex w-1/3 flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800">
            {{-- Search Header --}}
            <div class="border-b border-gray-200 p-3 dark:border-gray-700">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-200">{{ __('conversations') }}</h3>
            </div>

            {{-- Thread List --}}
            <div class="flex-1 space-y-1 overflow-y-auto p-2">
                @forelse ($threads as $thread)
                    @php
                        $threadId = $thread['id'] ?? '';
                        $isSelected = $selectedThreadId === $threadId;
                        $unread = (int) ($thread['unread_count_admin'] ?? 0);
                        $userName = $thread['user_name'] ?? $thread['user_email'] ?? __('unknown_user');
                        $lastMessage = $thread['last_message'] ?? '';
                        $lastMessagePreview = mb_strlen($lastMessage) > 60
                            ? mb_substr($lastMessage, 0, 60) . '...'
                            : $lastMessage;

                        // Time ago
                        $timeAgo = '';
                        if (!empty($thread['last_message_time'])) {
                            try {
                                $timeAgo = \Carbon\Carbon::parse($thread['last_message_time'])->diffForHumans();
                            } catch (\Exception $e) {
                                $timeAgo = $thread['last_message_time'];
                            }
                        }
                    @endphp

                    <button
                        wire:click="selectThread('{{ $threadId }}')"
                        class="w-full rounded-lg p-3 text-left transition-colors duration-150 {{ $isSelected ? 'bg-primary-100 border border-primary-300 dark:bg-primary-500/20 dark:border-primary-500/30' : 'hover:bg-gray-100 dark:hover:bg-white/5 border border-transparent' }}"
                    >
                        <div class="flex items-start justify-between gap-2">
                            <div class="min-w-0 flex-1">
                                <div class="flex items-center gap-2">
                                    <p class="truncate text-sm font-medium {{ $isSelected ? 'text-primary-700 dark:text-primary-300' : 'text-gray-900 dark:text-gray-200' }}">
                                        {{ $userName }}
                                    </p>
                                    @if ($unread > 0)
                                        <span class="inline-flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-primary-500 px-1.5 text-[10px] font-bold text-white">
                                            {{ $unread }}
                                        </span>
                                    @endif
                                </div>
                                @if ($lastMessagePreview)
                                    <p class="mt-1 truncate text-xs {{ $unread > 0 ? 'text-gray-700 dark:text-gray-300 font-medium' : 'text-gray-500' }}">
                                        {{ $lastMessagePreview }}
                                    </p>
                                @endif
                            </div>
                            @if ($timeAgo)
                                <span class="shrink-0 text-[10px] text-gray-500">{{ $timeAgo }}</span>
                            @endif
                        </div>
                    </button>
                @empty
                    <div class="flex flex-col items-center justify-center py-12 text-center">
                        <div class="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-500/10">
                            <x-heroicon-o-chat-bubble-left-right class="h-6 w-6 text-gray-500" />
                        </div>
                        <p class="text-sm text-gray-600 dark:text-gray-400">{{ __('no_conversations') }}</p>
                    </div>
                @endforelse
            </div>
        </div>

        {{-- Right Column: Message Detail (2/3) --}}
        <div class="flex w-2/3 flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800">
            @if ($selectedThreadId)
                @php
                    $selectedThread = collect($threads)->firstWhere('id', $selectedThreadId);
                    $threadUserName = $selectedThread['user_name'] ?? $selectedThread['user_email'] ?? __('unknown_user');
                    $threadUserEmail = $selectedThread['user_email'] ?? '';
                @endphp

                {{-- Chat Header --}}
                <div class="flex items-center gap-3 border-b border-gray-200 p-4 dark:border-gray-700">
                    <div class="flex h-10 w-10 items-center justify-center rounded-full bg-primary-100 dark:bg-primary-500/20">
                        <x-heroicon-o-user class="h-5 w-5 text-primary-600 dark:text-primary-400" />
                    </div>
                    <div>
                        <p class="text-sm font-semibold text-gray-900 dark:text-gray-200">{{ $threadUserName }}</p>
                        @if ($threadUserEmail)
                            <p class="text-xs text-gray-500">{{ $threadUserEmail }}</p>
                        @endif
                    </div>
                </div>

                {{-- Messages Area --}}
                <div class="flex-1 space-y-3 overflow-y-auto p-4" id="chat-messages">
                    @forelse ($messages as $message)
                        @php
                            $isAdmin = ($message['sender_id'] ?? '') === 'admin';
                            $isBroadcast = (bool) ($message['is_broadcast'] ?? false);
                            $content = $message['content'] ?? '';
                            $msgTime = '';
                            if (!empty($message['timestamp'])) {
                                try {
                                    $msgTime = \Carbon\Carbon::parse($message['timestamp'])->format('M d, H:i');
                                } catch (\Exception $e) {
                                    $msgTime = $message['timestamp'];
                                }
                            }
                        @endphp

                        <div class="flex {{ $isAdmin ? 'justify-end' : 'justify-start' }}">
                            <div class="max-w-[70%] rounded-2xl px-4 py-2.5 {{ $isAdmin ? 'bg-primary-500 text-white rounded-br-md' : 'bg-gray-100 text-gray-900 dark:bg-gray-700 dark:text-gray-200 rounded-bl-md' }}">
                                @if ($isBroadcast)
                                    <div class="mb-1 flex items-center gap-1">
                                        <x-heroicon-o-megaphone class="h-3 w-3 text-amber-300" />
                                        <span class="text-[10px] font-medium text-amber-300">{{ __('broadcast') }}</span>
                                    </div>
                                @endif
                                <p class="text-sm leading-relaxed">{{ $content }}</p>
                                <p class="mt-1 text-[10px] {{ $isAdmin ? 'text-white/70' : 'text-gray-500' }}">
                                    {{ $msgTime }}
                                </p>
                            </div>
                        </div>
                    @empty
                        <div class="flex flex-col items-center justify-center py-12 text-center">
                            <div class="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-500/10">
                                <x-heroicon-o-chat-bubble-bottom-center-text class="h-6 w-6 text-gray-500" />
                            </div>
                            <p class="text-sm text-gray-600 dark:text-gray-400">{{ __('no_messages_yet') }}</p>
                            <p class="mt-1 text-xs text-gray-500">{{ __('send_first_message') }}</p>
                        </div>
                    @endforelse
                </div>

                {{-- Message Input --}}
                <div class="border-t border-gray-200 p-4 dark:border-gray-700">
                    <form wire:submit.prevent="sendMessage" class="flex items-end gap-3">
                        <div class="flex-1">
                            <textarea
                                wire:model.defer="newMessage"
                                rows="2"
                                class="w-full resize-none rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 placeholder-gray-500 transition-colors duration-150 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200"
                                placeholder="{{ __('type_message_placeholder') }}"
                            ></textarea>
                        </div>
                        <button
                            type="submit"
                            class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary-500 text-white transition-colors duration-150 hover:bg-primary-600 focus:outline-none focus:ring-2 focus:ring-primary-500/50"
                        >
                            <x-heroicon-o-paper-airplane class="h-5 w-5" />
                        </button>
                    </form>
                </div>
            @else
                {{-- Empty State: No Thread Selected --}}
                <div class="flex flex-1 flex-col items-center justify-center text-center">
                    <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary-100 dark:bg-primary-500/10">
                        <x-heroicon-o-chat-bubble-left-right class="h-8 w-8 text-primary-600 dark:text-primary-400" />
                    </div>
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-200">{{ __('select_conversation') }}</h3>
                    <p class="mt-2 max-w-sm text-sm text-gray-600 dark:text-gray-500">
                        {{ __('select_conversation_hint') }}
                    </p>
                </div>
            @endif
        </div>
    </div>
</div>
