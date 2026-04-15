<?php

namespace App\Auth;

use App\Models\User;
use App\Services\FirestoreService;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Contracts\Auth\UserProvider;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Factory;

class FirebaseUserProvider implements UserProvider
{
    /**
     * Retrieve a user by their unique identifier.
     */
    public function retrieveById($identifier): ?Authenticatable
    {
        try {
            $service = app(FirestoreService::class);
            $data = $service->getDocument('users', $identifier);

            if ($data === null) {
                return null;
            }

            // Only return admin users
            if (($data['role'] ?? '') !== 'admin') {
                return null;
            }

            return User::fromFirestore($data);
        } catch (\Exception $e) {
            Log::error("FirebaseUserProvider retrieveById failed: {$e->getMessage()}", [
                'uid' => $identifier,
            ]);

            return null;
        }
    }

    /**
     * Retrieve a user by their unique identifier and "remember me" token.
     */
    public function retrieveByToken($identifier, $token): ?Authenticatable
    {
        // Firebase doesn't use remember tokens the same way
        return $this->retrieveById($identifier);
    }

    /**
     * Update the "remember me" token for the given user.
     */
    public function updateRememberToken(Authenticatable $user, $token): void
    {
        // No-op: Firebase doesn't use remember tokens
    }

    /**
     * Retrieve a user by the given credentials.
     */
    public function retrieveByCredentials(array $credentials): ?Authenticatable
    {
        if (! isset($credentials['email']) || ! isset($credentials['password'])) {
            return null;
        }

        try {
            $factory = (new Factory)
                ->withServiceAccount(config('firebase.credentials'))
                ->withProjectId(config('firebase.project_id'));

            $auth = $factory->createAuth();
            $signInResult = $auth->signInWithEmailAndPassword(
                $credentials['email'],
                $credentials['password']
            );

            $uid = $signInResult->firebaseUserId();

            if (! $uid) {
                return null;
            }

            return $this->retrieveById($uid);
        } catch (\Exception $e) {
            Log::info("Firebase credential validation failed: {$e->getMessage()}");

            return null;
        }
    }

    /**
     * Validate a user against the given credentials.
     */
    public function validateCredentials(Authenticatable $user, array $credentials): bool
    {
        // The credential check is done in retrieveByCredentials
        // If we got a user back, credentials were valid
        return true;
    }

    /**
     * Rehash the user's password if required and supported.
     */
    public function rehashPasswordIfRequired(Authenticatable $user, array $credentials, bool $force = false): void
    {
        // No-op: Firebase manages password hashing
    }
}
