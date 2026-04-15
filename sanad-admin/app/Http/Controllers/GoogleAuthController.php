<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\FirestoreService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Session;
use Laravel\Socialite\Facades\Socialite;

class GoogleAuthController
{
    /**
     * Redirect to Google OAuth consent screen.
     */
    public function redirect(): RedirectResponse
    {
        return Socialite::driver('google')
            ->scopes(['email', 'profile'])
            ->redirect();
    }

    /**
     * Handle callback from Google OAuth.
     */
    public function callback(): RedirectResponse
    {
        try {
            $googleUser = Socialite::driver('google')->user();
        } catch (\Exception $e) {
            Log::error('Google OAuth callback failed: '.$e->getMessage());

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('google_auth_failed'));
        }

        $email = $googleUser->getEmail();

        if (! $email) {
            Log::warning('Google OAuth: no email returned');

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('google_auth_no_email'));
        }

        // Query Firestore for user with this email
        try {
            $firestoreService = app(FirestoreService::class);
            $users = $firestoreService->queryCollection('users', [
                ['email', '=', $email],
            ], null, 'DESC', 1);
        } catch (\Exception $e) {
            Log::error('Google OAuth Firestore query failed: '.$e->getMessage());

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('google_auth_failed'));
        }

        if (empty($users)) {
            Log::info('Google OAuth: no user found for email', ['email' => $email]);

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('google_auth_no_account'));
        }

        $userData = $users[0];
        $role = $userData['role'] ?? '';

        if ($role !== 'admin') {
            Log::warning('Google OAuth: non-admin user attempted login', [
                'email' => $email,
                'role' => $role,
            ]);

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('access_denied'));
        }

        // Get the Firebase UID (document ID)
        $uid = $userData['id'] ?? null;

        if (! $uid) {
            Log::error('Google OAuth: user document missing ID', ['email' => $email]);

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('google_auth_failed'));
        }

        // Create session (matching FirebaseGuard::attempt() pattern)
        Session::put('firebase_uid', $uid);
        Session::regenerate();
        Session::save();

        // Update last login
        try {
            $firestoreService->updateDocument('users', $uid, [
                'last_login' => new \DateTime,
            ]);
        } catch (\Exception $e) {
            Log::warning('Failed to update last_login: '.$e->getMessage());
        }

        // Set the user on the guard for this request
        $user = User::fromFirestore($userData);
        auth()->guard('firebase')->setUser($user);

        Log::info('Google OAuth login successful', ['uid' => $uid, 'email' => $email]);

        return redirect('/admin');
    }
}
