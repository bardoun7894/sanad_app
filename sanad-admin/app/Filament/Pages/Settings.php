<?php

namespace App\Filament\Pages;

use App\Models\SystemSetting;
use App\Services\ActivityLogService;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Log;

class Settings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';

    protected static ?int $navigationSort = 13;

    protected static string $view = 'filament.pages.settings';

    // ─── Livewire Properties ─────────────────────────────────

    public bool $maintenance_mode = false;

    public bool $enable_therapist_application = true;

    public string $min_app_version = '1.0.0';

    public string $contact_email = '';

    public string $locale = 'en';

    // ─── Navigation ──────────────────────────────────────────

    public function getTitle(): string
    {
        return __('settings');
    }

    public static function getNavigationLabel(): string
    {
        return __('settings');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('system');
    }

    // ─── Lifecycle ───────────────────────────────────────────

    public function mount(): void
    {
        $config = SystemSetting::getConfig();

        $this->maintenance_mode = (bool) $config->getAttribute('maintenance_mode');
        $this->enable_therapist_application = (bool) $config->getAttribute('enable_therapist_application');
        $this->min_app_version = (string) ($config->getAttribute('min_app_version') ?? '1.0.0');
        $this->contact_email = (string) ($config->getAttribute('contact_email') ?? '');
        $this->locale = (string) (session('locale', config('app.locale', 'en')));
    }

    // ─── Actions ─────────────────────────────────────────────

    public function saveSettings(): void
    {
        $this->validate([
            'min_app_version' => ['required', 'string', 'regex:/^\d+\.\d+\.\d+$/'],
            'contact_email' => ['required', 'email'],
            'locale' => ['required', 'string', 'in:en,ar,fr'],
        ]);

        try {
            $config = SystemSetting::getConfig();

            $config->setAttribute('maintenance_mode', $this->maintenance_mode);
            $config->setAttribute('enable_therapist_application', $this->enable_therapist_application);
            $config->setAttribute('min_app_version', $this->min_app_version);
            $config->setAttribute('contact_email', $this->contact_email);

            // Set locale in session
            session(['locale' => $this->locale]);

            $config->saveConfig();

            // Log the settings change
            app(ActivityLogService::class)->log(
                'settingsUpdated',
                __('settings_updated_log'),
                [
                    'maintenance_mode' => $this->maintenance_mode,
                    'enable_therapist_application' => $this->enable_therapist_application,
                    'min_app_version' => $this->min_app_version,
                    'contact_email' => $this->contact_email,
                ],
            );

            Notification::make()
                ->title(__('settings_saved'))
                ->success()
                ->send();
        } catch (\Exception $e) {
            Log::error("Settings::saveSettings failed: {$e->getMessage()}");

            Notification::make()
                ->title(__('settings_save_failed'))
                ->danger()
                ->send();
        }
    }
}
