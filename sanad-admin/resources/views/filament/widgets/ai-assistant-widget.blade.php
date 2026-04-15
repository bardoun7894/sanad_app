<x-filament-widgets::widget>
    <div class="relative overflow-hidden rounded-xl border border-primary-200 bg-gradient-to-br from-primary-50 to-white p-5 shadow-sm transition-all duration-300 hover:shadow-md dark:border-primary-800 dark:from-primary-900/20 dark:to-gray-900">
        {{-- Decorative Background Glow --}}
        <div class="absolute -right-4 -top-4 h-24 w-24 rounded-full bg-primary-500/10 blur-2xl"></div>

        <div class="relative z-10 flex items-center justify-between gap-4">
            <div class="flex items-center gap-4">
                <div class="group flex h-12 w-12 items-center justify-center rounded-xl bg-white text-primary-600 shadow-sm ring-1 ring-primary-100 dark:bg-primary-900/30 dark:text-primary-400 dark:ring-primary-800">
                    <x-heroicon-o-sparkles class="h-6 w-6 transition-transform duration-500 group-hover:rotate-12 group-hover:scale-110" />
                </div>
                <div>
                    <h3 class="flex items-center gap-2 text-sm font-bold text-gray-900 dark:text-white">
                        {{ __('ai_assistant') }}
                        <span class="inline-flex items-center rounded-full bg-primary-100 px-2 py-0.5 text-[10px] font-medium text-primary-700 dark:bg-primary-900/50 dark:text-primary-300">
                            Beta
                        </span>
                    </h3>
                    <p class="mt-0.5 text-xs text-gray-600 dark:text-gray-400">
                        {{ __('ai_assistant_widget_description') }}
                    </p>
                </div>
            </div>

            <button
                onclick="window.dispatchEvent(new CustomEvent('toggle-ai-panel'))"
                class="group relative inline-flex items-center gap-2 overflow-hidden rounded-lg bg-primary-600 px-5 py-2.5 text-sm font-medium text-white shadow-md transition-all duration-300 hover:bg-primary-700 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-primary-500/50"
            >
                 <span class="absolute inset-0 translate-x-[-100%] bg-gradient-to-r from-transparent via-white/20 to-transparent transition-transform duration-700 group-hover:translate-x-[100%]"></span>
                <x-heroicon-o-chat-bubble-left-right class="relative h-4 w-4" />
                <span class="relative">{{ __('open_assistant') }}</span>
            </button>
        </div>
    </div>
</x-filament-widgets::widget>
