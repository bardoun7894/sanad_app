#!/bin/bash
set -e

# Build Vite assets if public/build doesn't exist
if [ ! -d "public/build" ]; then
    echo "Building Vite assets..."
    npm run build
fi

# Publish Filament assets if not present
if [ ! -d "public/css/filament" ]; then
    echo "Publishing Filament assets..."
    php artisan filament:assets
fi

# Run migrations
php artisan migrate --force 2>/dev/null || true

# Clear caches
php artisan view:clear
php artisan config:clear

exec php artisan serve --host=0.0.0.0 --port=8000
