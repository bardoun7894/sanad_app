<x-filament::widget>
    <div class="relative flex items-center justify-between gap-4 p-6 overflow-hidden rounded-2xl bg-gradient-to-br from-primary-50 to-primary-100 shadow-md dark:from-primary-700 dark:to-primary-900 border border-primary-200 dark:border-primary-800">
        {{-- Content --}}
        <div class="relative z-10">
            <h2 class="text-3xl font-bold tracking-tight text-gray-900 dark:text-white">
                {{ __('welcome') }}, {{ auth()->user()->name }}! 👋
            </h2>
            <p class="mt-2 text-lg text-gray-700 dark:text-white/90">
                {{ __('dashboard_overview_message') }}
            </p>
            <div class="flex items-center gap-4 mt-6">
                <a
                    href="{{ filament()->getUrl() }}/users"
                    class="inline-flex items-center justify-center rounded-lg bg-primary-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all duration-200 hover:bg-primary-700 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-primary-500/50 dark:bg-primary-500 dark:hover:bg-primary-600"
                >
                    {{ __('manage_users') }}
                </a>

                <a
                    href="{{ filament()->getUrl() }}/reports"
                    class="inline-flex items-center justify-center rounded-lg border border-primary-300 bg-white px-5 py-2.5 text-sm font-semibold text-primary-700 transition-all duration-200 hover:bg-primary-50 focus:outline-none focus:ring-2 focus:ring-primary-500/50 dark:border-primary-600 dark:bg-primary-800/30 dark:text-white dark:hover:bg-primary-800/50"
                >
                    {{ __('view_reports') }}
                </a>
            </div>
        </div>

        {{-- Decorative Icon/Image --}}
        <div class="hidden md:block relative z-10 opacity-30 dark:opacity-90 transform translate-x-4 translate-y-2">
             <svg xmlns="http://www.w3.org/2000/svg" class="w-48 h-48 text-primary-300 dark:text-white/20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="0.5" d="M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25" />
            </svg>
        </div>

        {{-- Background Decoration --}}
        <div class="absolute right-0 top-0 w-64 h-64 bg-primary-200/30 dark:bg-white/10 rounded-full blur-3xl transform -translate-y-1/2 translate-x-1/2"></div>
    </div>
</x-filament::widget>
