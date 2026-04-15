<div>
    {{-- Error flash message --}}
    @if (session('error'))
        <div class="mb-6 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-sm text-red-600 dark:text-red-400 text-center">
            {{ session('error') }}
        </div>
    @endif

    {{-- Branded header --}}
    <div class="text-center mb-8">
        {{-- Logo icon --}}
        <div class="inline-flex items-center justify-center w-[4.5rem] h-[4.5rem] rounded-2xl bg-gradient-to-br from-blue-400 via-primary-500 to-blue-700 mb-5 shadow-xl shadow-primary-500/20 ring-1 ring-gray-900/10 dark:ring-white/10">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-9 h-9 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z" />
            </svg>
        </div>

        {{-- Brand name --}}
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white tracking-tight">
            {{ filament()->getBrandName() }}
        </h1>
        <p class="text-sm text-gray-500 dark:text-slate-400 mt-1.5 font-medium">
            {{ __('Healthcare Management Portal') }}
        </p>

        {{-- Decorative line --}}
        <div class="flex items-center justify-center gap-2 mt-5">
            <div class="h-px w-12 bg-gradient-to-r from-transparent to-primary-500/40"></div>
            <div class="w-1.5 h-1.5 rounded-full bg-primary-500/50"></div>
            <div class="h-px w-12 bg-gradient-to-l from-transparent to-primary-500/40"></div>
        </div>
    </div>

    {{-- Login form --}}
    <x-filament-panels::form wire:submit="authenticate">
        {{ $this->form }}

        <x-filament-panels::form.actions
            :actions="$this->getCachedFormActions()"
            :full-width="$this->hasFullWidthFormActions()"
        />
    </x-filament-panels::form>

    {{-- Divider --}}
    <div class="flex items-center gap-4 my-6">
        <div class="flex-1 h-px bg-gray-200 dark:bg-gray-700"></div>
        <span class="text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wider">{{ __('or') }}</span>
        <div class="flex-1 h-px bg-gray-200 dark:bg-gray-700"></div>
    </div>

    {{-- Google Sign-In Button --}}
    <a href="{{ route('auth.google.redirect') }}"
       class="flex items-center justify-center gap-3 w-full px-4 py-3 rounded-lg
              bg-white border border-gray-300 text-gray-700
              dark:bg-gray-800 dark:border-gray-600 dark:text-gray-200
              text-sm font-medium
              transition-all duration-200
              hover:bg-gray-50 hover:border-gray-400
              dark:hover:bg-gray-700 dark:hover:border-gray-500
              focus:outline-none focus:ring-2 focus:ring-primary-500/30">
        {{-- Google "G" Logo --}}
        <svg class="w-5 h-5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
            <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
            <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
            <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
        </svg>
        {{ __('sign_in_with_google') }}
    </a>

    {{-- Footer --}}
    <div class="text-center mt-8 pt-5 border-t border-gray-200 dark:border-gray-700">
        <p class="text-xs text-gray-500 dark:text-gray-400">
            &copy; {{ date('Y') }} Sanad &middot; {{ __('All rights reserved') }}
        </p>
    </div>
</div>
