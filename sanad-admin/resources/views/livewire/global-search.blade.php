<div class="relative" x-data="{ open: @entangle('isOpen') }" @click.outside="open = false; $wire.closeSearch()">
    <div class="relative">
        <x-heroicon-m-magnifying-glass class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-500 dark:text-gray-400" />
        <input type="search" wire:model.live.debounce.300ms="query"
               placeholder="{{ __('global_search_placeholder') }}"
               @focus="if($wire.query.length >= 2) open = true"
               class="w-64 rounded-lg border-gray-300 bg-gray-100 py-2 pl-10 pr-4 text-sm text-gray-900 placeholder-gray-500 focus:border-primary-500 focus:ring-primary-500 focus:w-96 transition-all dark:border-gray-700 dark:bg-gray-800 dark:text-white dark:placeholder-gray-400">
    </div>

    @if($isOpen && (!empty($results['users']) || !empty($results['therapists']) || !empty($results['bookings'])))
    <div class="absolute left-0 top-full z-50 mt-2 w-96 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-2xl dark:border-gray-700 dark:bg-gray-900">
        @if(!empty($results['users']))
        <div class="border-b border-gray-100 px-3 py-2 dark:border-gray-700">
            <h4 class="text-xs font-semibold uppercase text-gray-500">{{ __('users') }}</h4>
        </div>
        @foreach($results['users'] as $item)
        <a href="{{ $item['url'] }}" class="flex items-center gap-3 px-3 py-2 hover:bg-gray-50 transition-colors dark:hover:bg-gray-800">
            <x-heroicon-m-user class="h-4 w-4 text-primary-600 dark:text-primary-400 shrink-0" />
            <div class="min-w-0">
                <div class="truncate text-sm text-gray-900 dark:text-white">{{ $item['label'] }}</div>
                <div class="truncate text-xs text-gray-500">{{ $item['sub'] }}</div>
            </div>
        </a>
        @endforeach
        @endif

        @if(!empty($results['therapists']))
        <div class="border-b border-gray-100 px-3 py-2 dark:border-gray-700">
            <h4 class="text-xs font-semibold uppercase text-gray-500">{{ __('clinicians') }}</h4>
        </div>
        @foreach($results['therapists'] as $item)
        <a href="{{ $item['url'] }}" class="flex items-center gap-3 px-3 py-2 hover:bg-gray-50 transition-colors dark:hover:bg-gray-800">
            <x-heroicon-m-academic-cap class="h-4 w-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
            <div class="min-w-0">
                <div class="truncate text-sm text-gray-900 dark:text-white">{{ $item['label'] }}</div>
                <div class="truncate text-xs text-gray-500">{{ $item['sub'] }}</div>
            </div>
        </a>
        @endforeach
        @endif

        @if(!empty($results['bookings']))
        <div class="border-b border-gray-100 px-3 py-2 dark:border-gray-700">
            <h4 class="text-xs font-semibold uppercase text-gray-500">{{ __('appointments') }}</h4>
        </div>
        @foreach($results['bookings'] as $item)
        <a href="{{ $item['url'] }}" class="flex items-center gap-3 px-3 py-2 hover:bg-gray-50 transition-colors dark:hover:bg-gray-800">
            <x-heroicon-m-calendar class="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0" />
            <div class="min-w-0">
                <div class="truncate text-sm text-gray-900 dark:text-white">{{ $item['label'] }}</div>
                <div class="truncate text-xs text-gray-500">{{ $item['sub'] }}</div>
            </div>
        </a>
        @endforeach
        @endif

        @if(empty($results['users']) && empty($results['therapists']) && empty($results['bookings']))
        <div class="px-4 py-6 text-center text-sm text-gray-500">{{ __('no_results_found') }}</div>
        @endif
    </div>
    @endif
</div>
