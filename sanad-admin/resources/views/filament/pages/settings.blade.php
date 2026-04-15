<x-filament-panels::page>
    <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        {{-- Header --}}
        <div class="mb-6">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-200">
                {{ __('system_settings') }}
            </h2>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-500">
                {{ __('settings_description') }}
            </p>
        </div>

        <form wire:submit.prevent="saveSettings">
            <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                {{-- Maintenance Mode --}}
                <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 dark:border-gray-700 dark:bg-gray-700/50">
                    <div class="flex items-center justify-between">
                        <div>
                            <label for="maintenance_mode" class="block text-sm font-medium text-gray-900 dark:text-gray-200">
                                {{ __('maintenance_mode') }}
                            </label>
                            <p class="mt-1 text-xs text-gray-600 dark:text-gray-500">
                                {{ __('maintenance_mode_description') }}
                            </p>
                        </div>
                        <label class="relative inline-flex cursor-pointer items-center">
                            <input
                                type="checkbox"
                                id="maintenance_mode"
                                wire:model="maintenance_mode"
                                class="peer sr-only"
                            />
                            <div class="peer h-6 w-11 rounded-full bg-gray-300 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary-500 peer-checked:after:translate-x-full peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary-500/50 dark:bg-gray-600 dark:after:border-gray-500"></div>
                        </label>
                    </div>
                </div>

                {{-- Therapist Applications --}}
                <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 dark:border-gray-700 dark:bg-gray-700/50">
                    <div class="flex items-center justify-between">
                        <div>
                            <label for="enable_therapist_application" class="block text-sm font-medium text-gray-900 dark:text-gray-200">
                                {{ __('therapist_applications') }}
                            </label>
                            <p class="mt-1 text-xs text-gray-600 dark:text-gray-500">
                                {{ __('therapist_applications_description') }}
                            </p>
                        </div>
                        <label class="relative inline-flex cursor-pointer items-center">
                            <input
                                type="checkbox"
                                id="enable_therapist_application"
                                wire:model="enable_therapist_application"
                                class="peer sr-only"
                            />
                            <div class="peer h-6 w-11 rounded-full bg-gray-300 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary-500 peer-checked:after:translate-x-full peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary-500/50 dark:bg-gray-600 dark:after:border-gray-500"></div>
                        </label>
                    </div>
                </div>

                {{-- Minimum App Version --}}
                <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 dark:border-gray-700 dark:bg-gray-700/50">
                    <label for="min_app_version" class="block text-sm font-medium text-gray-900 dark:text-gray-200">
                        {{ __('min_app_version') }}
                    </label>
                    <p class="mb-3 mt-1 text-xs text-gray-600 dark:text-gray-500">
                        {{ __('min_app_version_description') }}
                    </p>
                    <input
                        type="text"
                        id="min_app_version"
                        wire:model="min_app_version"
                        pattern="\d+\.\d+\.\d+"
                        placeholder="1.0.0"
                        class="w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 placeholder-gray-500 transition-colors focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200 dark:placeholder-gray-400"
                    />
                    @error('min_app_version')
                        <p class="mt-1 text-xs text-red-600 dark:text-red-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Support Email --}}
                <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 dark:border-gray-700 dark:bg-gray-700/50">
                    <label for="contact_email" class="block text-sm font-medium text-gray-900 dark:text-gray-200">
                        {{ __('support_email') }}
                    </label>
                    <p class="mb-3 mt-1 text-xs text-gray-600 dark:text-gray-500">
                        {{ __('support_email_description') }}
                    </p>
                    <input
                        type="email"
                        id="contact_email"
                        wire:model="contact_email"
                        placeholder="support@sanad.app"
                        class="w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 placeholder-gray-500 transition-colors focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200 dark:placeholder-gray-400"
                    />
                    @error('contact_email')
                        <p class="mt-1 text-xs text-red-600 dark:text-red-400">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Language Selection --}}
                <div class="rounded-xl border border-gray-200 bg-gray-50 p-5 dark:border-gray-700 dark:bg-gray-700/50">
                    <label for="locale" class="block text-sm font-medium text-gray-900 dark:text-gray-200">
                        {{ __('language') }}
                    </label>
                    <p class="mb-3 mt-1 text-xs text-gray-600 dark:text-gray-500">
                        {{ __('select_language_description') }}
                    </p>
                    <select
                        id="locale"
                        wire:model="locale"
                        class="w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 transition-colors focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200"
                    >
                        <option value="en">{{ __('english') }}</option>
                        <option value="ar">{{ __('arabic') }}</option>
                        <option value="fr">{{ __('french') }}</option>
                    </select>
                    @error('locale')
                        <p class="mt-1 text-xs text-red-600 dark:text-red-400">{{ $message }}</p>
                    @enderror
                </div>
            </div>

            {{-- Save Button --}}
            <div class="mt-6 flex justify-end">
                <button
                    type="submit"
                    class="inline-flex items-center gap-2 rounded-lg bg-primary-500 px-6 py-2.5 text-sm font-medium text-white transition-all duration-200 hover:bg-primary-600 focus:outline-none focus:ring-2 focus:ring-primary-500/50"
                >
                    <x-heroicon-o-check class="h-4 w-4" />
                    {{ __('save_settings') }}
                </button>
            </div>
        </form>
    </div>
</x-filament-panels::page>
