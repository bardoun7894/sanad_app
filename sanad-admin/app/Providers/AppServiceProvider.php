<?php

namespace App\Providers;

use Illuminate\Support\Facades\App;
use Illuminate\Support\ServiceProvider;
use Livewire\Livewire;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Set locale from session or default
        $locale = session('locale', config('app.locale', 'en'));
        App::setLocale($locale);

        // Set RTL direction for Arabic
        view()->share('isRtl', $locale === 'ar');
        view()->share('textDir', $locale === 'ar' ? 'rtl' : 'ltr');
        view()->share('currentLocale', $locale);

        // Register Livewire components (app/Http/Livewire is not auto-discovered in v3)
        Livewire::component('ai-assistant-panel', \App\Http\Livewire\AiAssistantPanel::class);
        Livewire::component('notification-bell', \App\Http\Livewire\NotificationBell::class);
        Livewire::component('chat-panel', \App\Http\Livewire\ChatPanel::class);
        Livewire::component('global-search', \App\Http\Livewire\GlobalSearch::class);
    }
}
