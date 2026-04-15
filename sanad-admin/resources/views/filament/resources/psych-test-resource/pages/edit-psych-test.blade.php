<x-filament-panels::page>
    <div class="mx-auto max-w-4xl">
        <form wire:submit="save" class="space-y-8">
            {{-- Basic Info --}}
            <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl space-y-6">
                <h3 class="text-lg font-semibold text-gray-200">{{ __('basic_info') }}</h3>

                <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-300">{{ __('title_arabic') }} <span class="text-danger-400">*</span></label>
                        <input wire:model="title_ar" type="text" dir="rtl" class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30" />
                        @error('title_ar') <p class="mt-1 text-xs text-danger-400">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-300">{{ __('title_english') }} <span class="text-danger-400">*</span></label>
                        <input wire:model="title_en" type="text" class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 placeholder-gray-500 transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30" />
                        @error('title_en') <p class="mt-1 text-xs text-danger-400">{{ $message }}</p> @enderror
                    </div>
                </div>

                <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-300">{{ __('description_arabic') }}</label>
                        <textarea wire:model="description_ar" rows="3" dir="rtl" class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"></textarea>
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-300">{{ __('description_english') }}</label>
                        <textarea wire:model="description_en" rows="3" class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200 placeholder-gray-500 transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30"></textarea>
                    </div>
                </div>

                <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-300">{{ __('type') }}</label>
                        <select wire:model="type" class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30">
                            <option value="depression">{{ __('depression') }}</option>
                            <option value="anxiety">{{ __('anxiety') }}</option>
                            <option value="stress">{{ __('stress') }}</option>
                            <option value="general">{{ __('general') }}</option>
                        </select>
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium text-gray-300">{{ __('duration_minutes') }}</label>
                        <input wire:model="duration_minutes" type="number" min="1" class="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-gray-200 transition focus:border-primary-500/50 focus:outline-none focus:ring-1 focus:ring-primary-500/30" />
                    </div>
                    <div class="flex items-end gap-3 pb-1">
                        <button type="button" wire:click="$toggle('is_active')"
                            @class(['relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none', 'bg-primary-600' => $is_active, 'bg-gray-600' => !$is_active])
                            role="switch">
                            <span @class(['pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out', 'translate-x-5' => $is_active, 'translate-x-0' => !$is_active])></span>
                        </button>
                        <label class="text-sm font-medium text-gray-300">{{ __('active') }}</label>
                    </div>
                </div>
            </div>

            {{-- Questions --}}
            <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl space-y-4">
                <div class="flex items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-200">{{ __('questions') }} ({{ count($questions) }})</h3>
                    <button type="button" wire:click="addQuestion" class="inline-flex items-center gap-1 rounded-lg bg-primary-600/20 px-3 py-1.5 text-xs font-medium text-primary-400 transition hover:bg-primary-600/30">
                        <x-heroicon-o-plus class="h-3.5 w-3.5" /> {{ __('add_question') }}
                    </button>
                </div>
                @error('questions') <p class="text-xs text-danger-400">{{ $message }}</p> @enderror

                @foreach ($questions as $qi => $question)
                    <div class="rounded-lg border border-white/10 bg-white/5 p-4 space-y-3">
                        <div class="flex items-center justify-between">
                            <span class="text-sm font-semibold text-gray-300">Q{{ $qi + 1 }}</span>
                            <button type="button" wire:click="removeQuestion({{ $qi }})" class="text-xs text-danger-400 hover:text-danger-300">{{ __('remove') }}</button>
                        </div>
                        <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
                            <input wire:model="questions.{{ $qi }}.text" type="text" dir="rtl" placeholder="{{ __('question_text_ar') }}" class="w-full rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm text-gray-200 placeholder-gray-500 focus:border-primary-500/50 focus:outline-none" />
                            <input wire:model="questions.{{ $qi }}.text_en" type="text" placeholder="{{ __('question_text_en') }}" class="w-full rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm text-gray-200 placeholder-gray-500 focus:border-primary-500/50 focus:outline-none" />
                        </div>

                        <div class="ml-4 space-y-2">
                            <div class="flex items-center justify-between">
                                <span class="text-xs font-medium text-gray-400">{{ __('options') }}</span>
                                <button type="button" wire:click="addOption({{ $qi }})" class="text-xs text-primary-400 hover:text-primary-300">+ {{ __('add_option') }}</button>
                            </div>
                            @foreach ($question['options'] ?? [] as $oi => $option)
                                <div class="flex items-center gap-2">
                                    <input wire:model="questions.{{ $qi }}.options.{{ $oi }}.text" type="text" dir="rtl" placeholder="{{ __('option_ar') }}" class="flex-1 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-gray-200 placeholder-gray-500 focus:border-primary-500/50 focus:outline-none" />
                                    <input wire:model="questions.{{ $qi }}.options.{{ $oi }}.text_en" type="text" placeholder="{{ __('option_en') }}" class="flex-1 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-gray-200 placeholder-gray-500 focus:border-primary-500/50 focus:outline-none" />
                                    <input wire:model="questions.{{ $qi }}.options.{{ $oi }}.score" type="number" placeholder="{{ __('score') }}" class="w-16 rounded-lg border border-white/10 bg-white/5 px-2 py-1.5 text-xs text-gray-200 text-center focus:border-primary-500/50 focus:outline-none" />
                                    <button type="button" wire:click="removeOption({{ $qi }}, {{ $oi }})" class="text-danger-400 hover:text-danger-300">
                                        <x-heroicon-o-x-mark class="h-4 w-4" />
                                    </button>
                                </div>
                            @endforeach
                        </div>
                    </div>
                @endforeach
            </div>

            {{-- Scoring Ranges --}}
            <div class="rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl space-y-4">
                <div class="flex items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-200">{{ __('scoring_ranges') }}</h3>
                    <button type="button" wire:click="addScoringRange" class="inline-flex items-center gap-1 rounded-lg bg-primary-600/20 px-3 py-1.5 text-xs font-medium text-primary-400 transition hover:bg-primary-600/30">
                        <x-heroicon-o-plus class="h-3.5 w-3.5" /> {{ __('add_range') }}
                    </button>
                </div>

                @foreach ($scoring_ranges as $ri => $range)
                    <div class="flex flex-wrap items-center gap-2 rounded-lg border border-white/10 bg-white/5 p-3">
                        <input wire:model="scoring_ranges.{{ $ri }}.min" type="number" placeholder="Min" class="w-16 rounded-lg border border-white/10 bg-white/5 px-2 py-1.5 text-xs text-gray-200 text-center focus:border-primary-500/50 focus:outline-none" />
                        <span class="text-gray-500">-</span>
                        <input wire:model="scoring_ranges.{{ $ri }}.max" type="number" placeholder="Max" class="w-16 rounded-lg border border-white/10 bg-white/5 px-2 py-1.5 text-xs text-gray-200 text-center focus:border-primary-500/50 focus:outline-none" />
                        <input wire:model="scoring_ranges.{{ $ri }}.level" type="text" placeholder="{{ __('level') }}" class="w-28 rounded-lg border border-white/10 bg-white/5 px-2 py-1.5 text-xs text-gray-200 placeholder-gray-500 focus:border-primary-500/50 focus:outline-none" />
                        <input wire:model="scoring_ranges.{{ $ri }}.text" type="text" dir="rtl" placeholder="{{ __('interpretation_ar') }}" class="flex-1 min-w-[120px] rounded-lg border border-white/10 bg-white/5 px-2 py-1.5 text-xs text-gray-200 placeholder-gray-500 focus:border-primary-500/50 focus:outline-none" />
                        <input wire:model="scoring_ranges.{{ $ri }}.text_en" type="text" placeholder="{{ __('interpretation_en') }}" class="flex-1 min-w-[120px] rounded-lg border border-white/10 bg-white/5 px-2 py-1.5 text-xs text-gray-200 placeholder-gray-500 focus:border-primary-500/50 focus:outline-none" />
                        <button type="button" wire:click="removeScoringRange({{ $ri }})" class="text-danger-400 hover:text-danger-300">
                            <x-heroicon-o-x-mark class="h-4 w-4" />
                        </button>
                    </div>
                @endforeach
            </div>

            {{-- Actions --}}
            <div class="flex items-center justify-end gap-3">
                <a href="{{ \App\Filament\Resources\PsychTestResource::getUrl('index') }}" class="rounded-xl border border-white/10 bg-white/5 px-5 py-2.5 text-sm font-medium text-gray-300 transition hover:bg-white/10 hover:text-white">{{ __('cancel') }}</a>
                <button type="submit" class="rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-primary-700">{{ __('save') }}</button>
            </div>
        </form>
    </div>
</x-filament-panels::page>
