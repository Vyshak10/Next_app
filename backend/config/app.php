<?php
return [
    // Application settings
    'app' => [
        'name' => 'NEXT',
        'url' => 'http://localhost:8000',
        'debug' => true,
        'timezone' => 'UTC',
    ],

    // Database settings
    'database' => [
        'host' => 'localhost',
        'name' => 'next_app_db',
        'username' => 'your_username',
        'password' => 'your_password',
    ],

    // Email settings
    'mail' => [
        'from' => [
            'address' => 'noreply@indianrupeeservices.in',
            'name' => 'NEXT'
        ],
        'smtp' => [
            'host' => 'smtp.gmail.com',
            'port' => 587,
            'username' => 'your_email@gmail.com',
            'password' => 'your_app_password',
            'encryption' => 'tls'
        ]
    ],

    // JWT settings
    'jwt' => [
        'secret' => 'your_jwt_secret_key',
        'expiration' => 86400, // 24 hours in seconds
    ],

    // File upload settings
    'upload' => [
        'max_size' => 10485760, // 10MB in bytes
        'allowed_types' => [
            'image' => ['jpg', 'jpeg', 'png', 'gif'],
            'video' => ['mp4', 'mov', 'avi'],
            'document' => ['pdf', 'doc', 'docx']
        ],
        'path' => [
            'images' => 'uploads/images',
            'videos' => 'uploads/videos',
            'documents' => 'uploads/documents'
        ]
    ],

    // Security settings
    'security' => [
        'password_min_length' => 8,
        'password_hash_algo' => PASSWORD_BCRYPT,
        'password_hash_options' => [
            'cost' => 12
        ],
        'token_length' => 32,
        'verification_token_expiry' => 86400, // 24 hours in seconds
        'password_reset_token_expiry' => 3600, // 1 hour in seconds
    ],

    // Rate limiting
    'rate_limit' => [
        'enabled' => true,
        'max_attempts' => 60,
        'decay_minutes' => 1,
    ],

    // CORS settings
    'cors' => [
        'allowed_origins' => ['http://localhost:3000'],
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
        'exposed_headers' => [],
        'max_age' => 86400,
        'allow_credentials' => true,
    ]
];
?> 