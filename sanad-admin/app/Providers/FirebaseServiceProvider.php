<?php

namespace App\Providers;

use App\Auth\FirebaseGuard;
use App\Auth\FirebaseUserProvider;
use App\Services\FirestoreService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\ServiceProvider;

class FirebaseServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Register FirestoreService as singleton
        $this->app->singleton(FirestoreService::class, function ($app) {
            return new FirestoreService;
        });
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Register the Firebase auth guard driver
        Auth::extend('firebase', function ($app, $name, array $config) {
            $provider = new FirebaseUserProvider;

            return new FirebaseGuard($provider, $app['request']);
        });

        // Register the Firebase user provider
        Auth::provider('firebase', function ($app, array $config) {
            return new FirebaseUserProvider;
        });
    }
}
