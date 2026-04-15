<?php

namespace App\Http\Livewire;

use App\Models\Booking;
use App\Models\TherapistProfile;
use App\Models\User;
use Livewire\Component;

class GlobalSearch extends Component
{
    public string $query = '';

    public bool $isOpen = false;

    public array $results = [];

    public function updatedQuery(): void
    {
        if (strlen($this->query) < 2) {
            $this->results = [];

            return;
        }

        $this->search();
    }

    public function search(): void
    {
        $q = mb_strtolower($this->query);
        $results = ['users' => [], 'therapists' => [], 'bookings' => []];

        try {
            // Search users by name/email
            $users = User::all([], 'created_at', 'DESC', 50);
            foreach ($users as $user) {
                if (str_contains(mb_strtolower($user->safeGet('display_name', '')), $q)
                    || str_contains(mb_strtolower($user->safeGet('name', '')), $q)
                    || str_contains(mb_strtolower($user->safeGet('email', '')), $q)) {
                    $results['users'][] = [
                        'id' => $user->getKey(),
                        'label' => $user->safeGet('display_name', $user->safeGet('name', $user->safeGet('email', 'Unknown'))),
                        'sub' => $user->safeGet('email', ''),
                        'url' => route('filament.admin.resources.users.view', ['record' => $user->getKey()]),
                    ];
                }
                if (count($results['users']) >= 5) {
                    break;
                }
            }

            // Search therapists by name
            $therapists = TherapistProfile::all([], 'created_at', 'DESC', 50);
            foreach ($therapists as $therapist) {
                if (str_contains(mb_strtolower($therapist->safeGet('name', '')), $q)
                    || str_contains(mb_strtolower($therapist->safeGet('email', '')), $q)) {
                    $results['therapists'][] = [
                        'id' => $therapist->getKey(),
                        'label' => $therapist->safeGet('name', 'Unknown'),
                        'sub' => $therapist->safeGet('title', ''),
                        'url' => route('filament.admin.resources.clinicians.view', ['record' => $therapist->getKey()]),
                    ];
                }
                if (count($results['therapists']) >= 5) {
                    break;
                }
            }

            // Search bookings by client name
            $bookings = Booking::all([], 'scheduled_time', 'DESC', 50);
            foreach ($bookings as $booking) {
                if (str_contains(mb_strtolower($booking->safeGet('client_name', '')), $q)
                    || str_contains(mb_strtolower($booking->safeGet('client_email', '')), $q)) {
                    $results['bookings'][] = [
                        'id' => $booking->getKey(),
                        'label' => $booking->safeGet('client_name', 'Unknown'),
                        'sub' => $booking->safeGet('scheduled_time', '').' - '.ucfirst($booking->safeGet('status', '')),
                        'url' => route('filament.admin.resources.appointments.view', ['record' => $booking->getKey()]),
                    ];
                }
                if (count($results['bookings']) >= 5) {
                    break;
                }
            }
        } catch (\Exception $e) {
            // Silently fail search
        }

        $this->results = $results;
        $this->isOpen = ! empty($results['users']) || ! empty($results['therapists']) || ! empty($results['bookings']);
    }

    public function closeSearch(): void
    {
        $this->isOpen = false;
        $this->query = '';
        $this->results = [];
    }

    public function render()
    {
        return view('livewire.global-search');
    }
}
