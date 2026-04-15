<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class VerifyAdminRole
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = auth()->user();

        if (! $user) {
            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('session_expired'));
        }

        // Check if session has expired (Laravel session timeout)
        if (! $request->session()->has('_token')) {
            auth()->guard('firebase')->logout();

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('session_expired'));
        }

        // Check if Firebase UID is in session (set by both email/password and OAuth flows)
        $firebaseUid = session('firebase_uid');
        if (! $firebaseUid) {
            auth()->guard('firebase')->logout();

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('session_expired'));
        }

        $role = $user->getAttribute('role');

        if ($role !== 'admin') {
            auth()->guard('firebase')->logout();

            return redirect()->route('filament.admin.auth.login')
                ->with('error', __('access_denied'));
        }

        return $next($request);
    }
}
