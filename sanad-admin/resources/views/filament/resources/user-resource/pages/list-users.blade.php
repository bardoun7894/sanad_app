<x-filament-panels::page>
    {{-- ── Filters Bar ────────────────────────────────────────── --}}
    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
            {{-- Role Filter --}}
            <select
                wire:model.live="filters.role"
                class="rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
            >
                <option value="">{{ __('all_roles') }}</option>
                <option value="user">{{ __('user') }}</option>
                <option value="therapist">{{ __('therapist') }}</option>
                <option value="admin">{{ __('admin') }}</option>
            </select>

            {{-- Subscription Status Filter --}}
            <select
                wire:model.live="filters.subscription_status"
                class="rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 backdrop-blur-xl transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"
            >
                <option value="">{{ __('all_subscriptions') }}</option>
                <option value="free">{{ __('free') }}</option>
                <option value="active">{{ __('active') }}</option>
                <option value="expired">{{ __('expired') }}</option>
                <option value="pending">{{ __('pending') }}</option>
            </select>
        </div>
    </div>

    {{-- ── Users Table ────────────────────────────────────────── --}}
    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <table class="w-full text-left text-sm">
            <thead>
                <tr class="border-b border-white/10 bg-white/5">
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('name') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('email') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('role') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('subscription_status') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('created_at') }}</th>
                    <th class="px-6 py-4 font-medium text-gray-400">{{ __('actions') }}</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
                @forelse ($users as $user)
                    @php
                        $roleColor = match ($user->safeGet('role', 'user')) {
                            'admin' => 'danger',
                            'therapist' => 'warning',
                            default => 'gray',
                        };
                        $subColor = match ($user->safeGet('subscription_status', 'free')) {
                            'active' => 'success',
                            'expired' => 'danger',
                            'pending' => 'warning',
                            default => 'gray',
                        };
                    @endphp
                    <tr class="transition hover:bg-white/5">
                        {{-- Name --}}
                        <td class="px-6 py-4">
                            <a
                                href="{{ route('filament.admin.resources.users.view', ['record' => $user->getKey()]) }}"
                                class="font-medium text-gray-200 hover:text-primary-400 transition"
                            >
                                {{ $user->safeGet('display_name', $user->safeGet('name', $user->safeGet('email'))) }}
                            </a>
                        </td>

                        {{-- Email --}}
                        <td class="px-6 py-4 text-gray-300">
                            {{ $user->safeGet('email', '-') }}
                        </td>

                        {{-- Role --}}
                        <td class="px-6 py-4">
                            <span @class([
                                'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold',
                                'bg-danger-500/20 text-danger-400' => $roleColor === 'danger',
                                'bg-warning-500/20 text-warning-400' => $roleColor === 'warning',
                                'bg-gray-500/20 text-gray-400' => $roleColor === 'gray',
                            ])>
                                {{ __($user->safeGet('role', 'user')) }}
                            </span>
                        </td>

                        {{-- Subscription Status --}}
                        <td class="px-6 py-4">
                            <span @class([
                                'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold',
                                'bg-success-500/20 text-success-400' => $subColor === 'success',
                                'bg-danger-500/20 text-danger-400' => $subColor === 'danger',
                                'bg-warning-500/20 text-warning-400' => $subColor === 'warning',
                                'bg-gray-500/20 text-gray-400' => $subColor === 'gray',
                            ])>
                                {{ __($user->safeGet('subscription_status', 'free')) }}
                            </span>
                        </td>

                        {{-- Created At --}}
                        <td class="px-6 py-4 text-gray-400">
                            {{ $user->safeGet('created_at', '-') }}
                        </td>

                        {{-- Actions --}}
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-2">
                                <a
                                    href="{{ route('filament.admin.resources.users.view', ['record' => $user->getKey()]) }}"
                                    class="inline-flex items-center gap-1 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                                >
                                    <x-heroicon-o-eye class="h-3.5 w-3.5" />
                                    {{ __('view') }}
                                </a>
                                <a
                                    href="{{ route('filament.admin.resources.users.edit', ['record' => $user->getKey()]) }}"
                                    class="inline-flex items-center gap-1 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-medium text-gray-300 transition hover:bg-white/10 hover:text-white"
                                >
                                    <x-heroicon-o-pencil class="h-3.5 w-3.5" />
                                    {{ __('edit') }}
                                </a>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-gray-500">
                            <div class="flex flex-col items-center gap-2">
                                <x-heroicon-o-users class="h-8 w-8 text-gray-600" />
                                <span>{{ __('no_users_found') }}</span>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{-- ── Pagination Controls ─────────────────────────────────── --}}
    @if (!empty($cursorStack) || $hasMore)
        <div class="mt-6 flex items-center justify-between">
            <button
                wire:click="previousPage"
                @if (empty($cursorStack)) disabled @endif
                @class([
                    'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                    'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => !empty($cursorStack),
                    'bg-white/5 text-gray-600 border border-white/5 cursor-not-allowed' => empty($cursorStack),
                ])
            >
                <x-heroicon-o-chevron-left class="h-4 w-4" />
                {{ __('previous') }}
            </button>

            <div class="text-sm text-gray-400">
                {{ __('showing_results_per_page', ['count' => count($users), 'per_page' => $perPage]) }}
            </div>

            <button
                wire:click="nextPage"
                @if (!$hasMore) disabled @endif
                @class([
                    'flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-medium transition-all duration-200',
                    'bg-white/5 text-gray-400 border border-white/10 hover:bg-white/10 hover:text-gray-200' => $hasMore,
                    'bg-white/5 text-gray-600 border border-white/5 cursor-not-allowed' => !$hasMore,
                ])
            >
                {{ __('next') }}
                <x-heroicon-o-chevron-right class="h-4 w-4" />
            </button>
        </div>
    @endif
</x-filament-panels::page>
