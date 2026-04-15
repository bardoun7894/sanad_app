<div class="relative" wire:poll.10s="refreshData">
    {{-- Bell Icon Button --}}
    <button
        wire:click="toggleDropdown"
        type="button"
        class="relative flex h-9 w-9 items-center justify-center rounded-lg text-gray-600 transition-colors duration-200 hover:bg-gray-100 hover:text-gray-900 focus:outline-none dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-white"
        aria-label="{{ __('notifications') }}"
    >
        <x-heroicon-o-bell class="h-5 w-5" />

        {{-- Unread Count Badge --}}
        @if ($unreadCount > 0)
            <span class="absolute -right-0.5 -top-0.5 flex h-4 min-w-[1rem] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold leading-none text-white shadow-lg shadow-red-500/30">
                {{ $unreadCount > 9 ? '9+' : $unreadCount }}
            </span>
        @endif
    </button>

    {{-- Dropdown Panel --}}
    @if ($isOpen)
        {{-- Backdrop overlay to close dropdown --}}
        <div
            wire:click="toggleDropdown"
            class="fixed inset-0 z-40"
        ></div>

        <div class="absolute right-0 top-full z-50 mt-2 w-96 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-2xl dark:border-gray-700 dark:bg-gray-900/95 dark:backdrop-blur-xl">
            {{-- Header --}}
            <div class="flex items-center justify-between border-b border-gray-200 px-4 py-3 dark:border-gray-700">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white">
                    {{ __('notifications') }}
                </h3>

                @if ($unreadCount > 0)
                    <button
                        wire:click="markAllRead"
                        type="button"
                        class="text-xs font-medium text-primary-600 transition-colors duration-200 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300"
                    >
                        {{ __('mark_all_read') }}
                    </button>
                @endif
            </div>

            {{-- Notifications List --}}
            <div class="max-h-96 overflow-y-auto">
                @if (count($notifications) > 0)
                    @php
                        $groupedNotifications = [];
                        foreach ($notifications as $notification) {
                            $type = $notification->safeGet('type', 'system');
                            $groupedNotifications[$type][] = $notification;
                        }

                        $typeLabels = [
                            'booking' => __('booking'),
                            'message' => __('message'),
                            'community' => __('community'),
                            'mood' => __('mood'),
                            'therapist' => __('therapist'),
                            'payment' => __('payment'),
                            'system' => __('system'),
                        ];
                    @endphp

                    <div>
                        @foreach ($groupedNotifications as $type => $items)
                            <div class="border-b border-gray-100 last:border-b-0 dark:border-gray-700">
                                <div class="px-4 py-2 text-[10px] font-semibold uppercase tracking-wide text-gray-500">
                                    {{ $typeLabels[$type] ?? ucfirst($type) }}
                                </div>

                                <div class="divide-y divide-gray-100 dark:divide-gray-700">
                                    @foreach ($items as $notification)
                                        @php
                                            $isRead = $notification->getAttribute('is_read') ?? false;
                                            $typeIcon = $notification->getTypeIcon();
                                            $typeColor = $notification->getTypeColor();
                                            $typeBgColor = $notification->getTypeBgColor();
                                            $actionUrl = $notification->getActionUrl();
                                            $timeAgo = $notification->getTimeAgo();
                                        @endphp

                                        <a
                                            href="{{ $actionUrl }}"
                                            wire:click.prevent="markRead('{{ $notification->getKey() }}')"
                                            onclick="window.location.href='{{ $actionUrl }}'"
                                            class="flex items-start gap-3 px-4 py-3 transition-colors duration-200 hover:bg-gray-50 dark:hover:bg-gray-800 {{ !$isRead ? 'bg-primary-50/50 dark:bg-gray-800/50' : '' }}"
                                        >
                                            {{-- Type Icon --}}
                                            <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg {{ $typeBgColor }}">
                                                <x-dynamic-component
                                                    :component="$typeIcon"
                                                    class="h-4 w-4 {{ $typeColor }}"
                                                />
                                            </div>

                                            {{-- Content --}}
                                            <div class="min-w-0 flex-1">
                                                <div class="flex items-start justify-between gap-2">
                                                    <p class="truncate text-sm font-medium {{ !$isRead ? 'text-gray-900 dark:text-white' : 'text-gray-600 dark:text-gray-400' }}">
                                                        {{ $notification->safeGet('title', __('notification')) }}
                                                    </p>

                                                    {{-- Unread Indicator --}}
                                                    @if (!$isRead)
                                                        <span class="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-primary-500 dark:bg-primary-400"></span>
                                                    @endif
                                                </div>

                                                <p class="mt-0.5 line-clamp-2 text-xs {{ !$isRead ? 'text-gray-700 dark:text-gray-300' : 'text-gray-500' }}">
                                                    {{ $notification->safeGet('body', '') }}
                                                </p>

                                                <p class="mt-1 text-[10px] text-gray-500 dark:text-gray-600">
                                                    {{ $timeAgo }}
                                                </p>
                                            </div>
                                        </a>
                                    @endforeach
                                </div>
                            </div>
                        @endforeach
                    </div>
                @else
                    {{-- Empty State --}}
                    <div class="flex flex-col items-center justify-center py-12">
                        <div class="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-500/10">
                            <x-heroicon-o-bell-slash class="h-6 w-6 text-gray-500" />
                        </div>
                        <p class="text-sm font-medium text-gray-600 dark:text-gray-400">
                            {{ __('no_new_notifications') }}
                        </p>
                        <p class="mt-1 text-xs text-gray-500 dark:text-gray-600">
                            {{ __('notifications_will_appear_here') }}
                        </p>
                    </div>
                @endif
            </div>
        </div>
    @endif
</div>
