<?php

namespace App\Auth;

use App\Models\User;
use App\Services\FirestoreService;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Guard;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Session;
use Kreait\Firebase\Exception\Auth\InvalidPassword;
use Kreait\Firebase\Exception\Auth\UserNotFound;
use Kreait\Firebase\Factory;

class FirebaseGuard implements Guard
{
    protected ?Authenticatable $user = null;

    protected Request $request;

    protected FirebaseUserProvider $provider;

    public function __construct(FirebaseUserProvider $provider, Request $request)
    {
        $this->provider = $provider;
        $this->request = $request;
    }

    /**
     * Determine if the current user is authenticated.
     */
    public function check(): bool
    {
        return $this->user() !== null;
    }

    /**
     * Determine if the current user is a guest.
     */
    public function guest(): bool
    {
        return ! $this->check();
    }

    /**
     * Get the currently authenticated user.
     */
    public function user(): ?Authenticatable
    {
        if ($this->user !== null) {
            return $this->user;
        }

        $uid = Session::get('firebase_uid');

        if ($uid) {
            $this->user = $this->provider->retrieveById($uid);
        }

        return $this->user;
    }

    /**
     * Get the ID for the currently authenticated user.
     */
    public function id(): ?string
    {
        $user = $this->user();

        return $user ? $user->getAuthIdentifier() : null;
    }

    /**
     * Validate a user's credentials.
     */
    public function validate(array $credentials = []): bool
    {
        $user = $this->provider->retrieveByCredentials($credentials);

        return $user !== null;
    }

    /**
     * Determine if the guard has a user instance.
     */
    public function hasUser(): bool
    {
        return $this->user !== null;
    }

    /**
     * Set the current user.
     */
    public function setUser(Authenticatable $user): static
    {
        $this->user = $user;

        return $this;
    }

    /**
     * Attempt to authenticate a user using the given credentials.
     */
    public function attempt(array $credentials = [], bool $remember = false): bool
    {
        try {
            $factory = (new Factory)
                ->withServiceAccount(config('firebase.credentials'))
                ->withProjectId(config('firebase.project_id'));

            $auth = $factory->createAuth();

            // Verify email/password with Firebase Auth
            $signInResult = $auth->signInWithEmailAndPassword(
                $credentials['email'],
                $credentials['password']
            );

            $uid = $signInResult->firebaseUserId();

            if (! $uid) {
                return false;
            }

            // Fetch user document from Firestore
            $firestoreService = app(FirestoreService::class);
            $userData = $firestoreService->getDocument('users', $uid);

            if (! $userData) {
                Log::warning('Firebase auth: user document not found in Firestore', ['uid' => $uid]);

                return false;
            }

            // Check admin role
            $role = $userData['role'] ?? '';
            if ($role !== 'admin') {
                Log::warning('Firebase auth: non-admin user attempted login', [
                    'uid' => $uid,
                    'role' => $role,
                ]);

                return false;
            }

            // Create session
            Session::put('firebase_uid', $uid);
            Session::save();

            // Update last login
            try {
                $firestoreService->updateDocument('users', $uid, [
                    'last_login' => new \DateTime,
                ]);
            } catch (\Exception $e) {
                // Non-critical: don't fail login if last_login update fails
                Log::warning("Failed to update last_login: {$e->getMessage()}");
            }

            // Set the user
            $this->user = User::fromFirestore($userData);

            return true;
        } catch (InvalidPassword $e) {
            Log::info('Firebase auth: invalid password', ['email' => $credentials['email'] ?? '']);

            return false;
        } catch (UserNotFound $e) {
            Log::info('Firebase auth: user not found', ['email' => $credentials['email'] ?? '']);

            return false;
        } catch (\Exception $e) {
            Log::error("Firebase auth failed: {$e->getMessage()}", [
                'email' => $credentials['email'] ?? '',
            ]);

            return false;
        }
    }

    /**
     * Log the user out.
     */
    public function logout(): void
    {
        Session::forget('firebase_uid');
        Session::save();
        $this->user = null;
    }
}
