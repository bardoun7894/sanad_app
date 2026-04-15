<x-filament-panels::page>
    <div class="max-w-2xl">
        {{-- User Info Summary --}}
        <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6 mb-6">
            <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-full bg-primary-500/20 flex items-center justify-center">
                    <x-heroicon-o-user class="w-6 h-6 text-primary-400" />
                </div>
                <div>
                    <h3 class="text-lg font-semibold text-white">{{ $user->getDisplayName() }}</h3>
                    <p class="text-sm text-gray-400">{{ $user->safeGet('email') }}</p>
                </div>
            </div>
        </div>

        {{-- Edit Form --}}
        <form wire:submit.prevent="save">
            <div class="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6 space-y-6">
                <h3 class="text-lg font-semibold text-white">{{ __('edit_user') }}</h3>

                {{-- Role Select --}}
                <div>
                    <label for="role" class="block text-sm font-medium text-gray-400 mb-2">
                        {{ __('role') }}
                    </label>
                    <select
                        id="role"
                        wire:model="data.role"
                        class="w-full rounded-lg border border-white/10 bg-white/5 px-4 py-2.5 text-white focus:border-primary-500 focus:ring-primary-500 focus:ring-1 focus:outline-none"
                    >
                        <option value="user">{{ __('user') }}</option>
                        <option value="therapist">{{ __('therapist') }}</option>
                        <option value="admin">{{ __('admin') }}</option>
                    </select>
                </div>

                {{-- Subscription Status Select --}}
                <div>
                    <label for="subscription_status" class="block text-sm font-medium text-gray-400 mb-2">
                        {{ __('subscription_status') }}
                    </label>
                    <select
                        id="subscription_status"
                        wire:model="data.subscription_status"
                        class="w-full rounded-lg border border-white/10 bg-white/5 px-4 py-2.5 text-white focus:border-primary-500 focus:ring-primary-500 focus:ring-1 focus:outline-none"
                    >
                        <option value="free">{{ __('free') }}</option>
                        <option value="active">{{ __('active') }}</option>
                        <option value="cancelled">{{ __('cancelled') }}</option>
                        <option value="expired">{{ __('expired') }}</option>
                        <option value="pending">{{ __('pending') }}</option>
                        <option value="suspended">{{ __('suspended') }}</option>
                    </select>
                </div>

                {{-- Save Button --}}
                <div class="flex justify-end gap-3 pt-4 border-t border-white/10">
                    <a
                        href="{{ \App\Filament\Resources\UserResource::getUrl('view', ['record' => $record]) }}"
                        class="px-4 py-2 rounded-lg text-sm font-medium text-gray-400 bg-white/5 hover:bg-white/10 transition-colors"
                    >
                        {{ __('cancel') }}
                    </a>
                    <button
                        type="submit"
                        class="px-4 py-2 rounded-lg text-sm font-medium text-white bg-primary-500 hover:bg-primary-600 transition-colors"
                    >
                        {{ __('save_changes') }}
                    </button>
                </div>
            </div>
        </form>
    </div>
</x-filament-panels::page>
