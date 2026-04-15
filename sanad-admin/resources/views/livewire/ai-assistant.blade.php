<div>
    {{-- Sliding Panel Overlay --}}
    <div
        x-data="{ open: @entangle('isOpen') }"
        @toggle-ai-panel.window="$wire.toggle()"
        x-show="open"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        class="fixed inset-0 z-50"
        style="display: none;"
    >
        {{-- Backdrop --}}
        <div
            class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm"
            @click="$wire.toggle()"
        ></div>

        {{-- Panel --}}
        <div
            x-show="open"
            x-transition:enter="transition ease-out duration-300"
            x-transition:enter-start="translate-x-full"
            x-transition:enter-end="translate-x-0"
            x-transition:leave="transition ease-in duration-200"
            x-transition:leave-start="translate-x-0"
            x-transition:leave-end="translate-x-full"
            class="fixed bottom-0 right-0 top-0 flex w-full max-w-md flex-col border-l border-gray-200 bg-white shadow-2xl dark:border-gray-700 dark:bg-gray-900"
        >
            {{-- Header --}}
            <div class="flex items-center justify-between border-b border-gray-100 px-5 py-4 dark:border-gray-800">
                <div class="flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary-500 to-primary-600 shadow-sm">
                        <x-heroicon-o-sparkles class="h-6 w-6 text-white" />
                    </div>
                    <div>
                        <h2 class="text-base font-bold text-gray-900 dark:text-white">{{ __('ai_assistant') }}</h2>
                        <span class="inline-flex items-center rounded-full bg-primary-50 px-2 py-0.5 text-xs font-medium text-primary-700 dark:bg-primary-900/30 dark:text-primary-300">
                            {{ __('beta_version') }}
                        </span>
                    </div>
                </div>

                <div class="flex items-center gap-1">
                    {{-- Clear Chat --}}
                    <button
                        wire:click="clearChat"
                        wire:confirm="{{ __('clear_chat_confirm') }}"
                        class="rounded-full p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-800 dark:hover:text-gray-300"
                        title="{{ __('clear_chat') }}"
                    >
                        <x-heroicon-o-trash class="h-5 w-5" />
                    </button>

                    {{-- Close --}}
                    <button
                        wire:click="toggle"
                        class="rounded-full p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-800 dark:hover:text-gray-300"
                    >
                        <x-heroicon-o-x-mark class="h-6 w-6" />
                    </button>
                </div>
            </div>

            {{-- Generate Summary Action --}}
            <div class="border-b border-gray-100 bg-gray-50/50 px-5 py-3 dark:border-gray-800 dark:bg-gray-800/50">
                <button
                    wire:click="generateSummary"
                    wire:loading.attr="disabled"
                    class="group flex w-full items-center justify-center gap-2 rounded-xl border border-primary-200 bg-white px-4 py-2.5 text-sm font-semibold text-primary-700 shadow-sm transition-all duration-200 hover:-translate-y-0.5 hover:shadow-md active:translate-y-0 dark:border-primary-800 dark:bg-gray-800 dark:text-primary-400 dark:hover:bg-gray-700"
                >
                    <x-heroicon-o-chart-bar-square class="h-5 w-5 transition-transform group-hover:scale-110" />
                    <span wire:loading.remove wire:target="generateSummary">{{ __('generate_dashboard_summary') }}</span>
                    <span wire:loading wire:target="generateSummary" class="flex items-center gap-2">
                        <svg class="h-4 w-4 animate-spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        {{ __('analyzing_data') }}...
                    </span>
                </button>
            </div>

            {{-- Messages Area --}}
            <div
                class="flex-1 space-y-6 overflow-y-auto bg-gray-50 px-5 py-6 scrollbar-thin scrollbar-thumb-gray-200 dark:bg-gray-900 dark:scrollbar-thumb-gray-800"
                id="ai-messages-area"
                x-ref="messagesArea"
                @scroll-to-bottom.window="$nextTick(() => { $refs.messagesArea.scrollTop = $refs.messagesArea.scrollHeight })"
            >
                @if (empty($messages))
                    {{-- Empty State --}}
                    <div class="flex h-full flex-col items-center justify-center p-8 text-center opacity-60">
                        <div class="mb-4 flex h-20 w-20 items-center justify-center rounded-3xl bg-gradient-to-tr from-primary-100 to-primary-50 dark:from-gray-800 dark:to-gray-700">
                            <x-heroicon-o-chat-bubble-left-ellipsis class="h-10 w-10 text-primary-500/50 dark:text-gray-500" />
                        </div>
                        <h3 class="text-base font-medium text-gray-900 dark:text-white">{{ __('how_can_i_help') }}</h3>
                        <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                            {{ __('ai_welcome_description') }}
                        </p>
                    </div>
                @else
                    @foreach ($messages as $message)
                        <div class="flex flex-col gap-1 {{ $message['role'] === 'user' ? 'items-end' : 'items-start' }}">
                            {{-- Role Label --}}
                            <span class="px-1 text-[10px] font-medium uppercase tracking-wider text-gray-400">
                                {{ $message['role'] === 'user' ? __('you') : __('ai_assistant') }}
                            </span>
                            
                            {{-- Message Bubble --}}
                            <div class="max-w-[85%] rounded-2xl px-5 py-3.5 text-sm leading-relaxed shadow-sm {{ $message['role'] === 'user'
                                ? 'bg-primary-600 text-white rounded-br-sm'
                                : 'bg-white border border-gray-100 text-gray-700 rounded-bl-sm dark:bg-gray-800 dark:border-gray-700 dark:text-gray-200' }}">
                                <div class="prose prose-sm prose-invert max-w-none {{ $message['role'] === 'user' ? 'prose-p:text-white' : 'prose-p:text-gray-700 dark:prose-p:text-gray-200' }}">
                                    {!! nl2br(e($message['content'])) !!}
                                </div>
                            </div>
                        </div>
                    @endforeach
                @endif

                {{-- Loading Indicator --}}
                @if ($isLoading)
                    <div class="flex items-start gap-3 animate-pulse">
                        <div class="flex h-8 w-8 items-center justify-center rounded-full bg-primary-100 dark:bg-primary-900/30">
                            <x-heroicon-o-sparkles class="h-4 w-4 text-primary-600 dark:text-primary-400" />
                        </div>
                        <div class="flex items-center gap-1.5 rounded-2xl bg-white px-4 py-3 shadow-sm dark:bg-gray-800">
                            <span class="block h-2 w-2 animate-bounce rounded-full bg-gray-400" style="animation-delay: 0ms"></span>
                            <span class="block h-2 w-2 animate-bounce rounded-full bg-gray-400" style="animation-delay: 150ms"></span>
                            <span class="block h-2 w-2 animate-bounce rounded-full bg-gray-400" style="animation-delay: 300ms"></span>
                        </div>
                    </div>
                @endif
            </div>

            {{-- Input Area --}}
            <div class="border-t border-gray-100 bg-white px-5 py-4 dark:border-gray-800 dark:bg-gray-900">
                <form wire:submit.prevent="sendMessage" class="relative">
                    <input
                        type="text"
                        wire:model="userInput"
                        placeholder="{{ __('ask_ai_question') }}..."
                        class="w-full rounded-xl border-gray-200 bg-gray-50 py-3.5 pl-4 pr-12 text-sm text-gray-900 placeholder-gray-400 focus:border-primary-500 focus:bg-white focus:ring-1 focus:ring-primary-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white dark:placeholder-gray-500 dark:focus:bg-gray-800"
                        @if ($isLoading) disabled @endif
                    />
                    <button
                        type="submit"
                        class="absolute right-2 top-2 rounded-lg bg-primary-600 p-1.5 text-white transition-all hover:bg-primary-700 disabled:bg-gray-300 disabled:cursor-not-allowed dark:disabled:bg-gray-700"
                        @if ($isLoading) disabled @endif
                    >
                        <x-heroicon-o-paper-airplane class="h-4 w-4 -rotate-45" />
                    </button>
                </form>
                <div class="mt-2 text-center">
                    <p class="text-[10px] text-gray-400 dark:text-gray-600">
                        {{ __('ai_disclaimer_footer') }}
                    </p>
                </div>
            </div>
        </div>
    </div>
</div>
