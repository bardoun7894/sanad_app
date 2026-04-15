<?php

return [
    'defaults' => [
        'guard' => 'firebase',
        'passwords' => 'users',
    ],

    'guards' => [
        'firebase' => [
            'driver' => 'firebase',
            'provider' => 'firebase_users',
        ],
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],
    ],

    'providers' => [
        'firebase_users' => [
            'driver' => 'firebase',
        ],
        'users' => [
            'driver' => 'eloquent',
            'model' => App\Models\User::class,
        ],
    ],

    'passwords' => [
        'users' => [
            'provider' => 'users',
            'table' => 'password_reset_tokens',
            'expire' => 60,
            'throttle' => 60,
        ],
    ],

    'password_timeout' => 10800,
];
