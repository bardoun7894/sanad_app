<?php

namespace App\Http\Livewire;

use App\Services\ChatService;
use Livewire\Component;

class ChatPanel extends Component
{
    public array $threads = [];

    public ?string $selectedThreadId = null;

    public array $messages = [];

    public string $newMessage = '';

    public array $stats = [];

    public function mount(): void
    {
        $chatService = app(ChatService::class);
        $this->threads = $chatService->getThreads();
        $this->stats = $chatService->getStats();
    }

    /**
     * Select a thread and load its messages.
     */
    public function selectThread(string $threadId): void
    {
        $this->selectedThreadId = $threadId;

        $chatService = app(ChatService::class);
        $this->messages = $chatService->getMessages($threadId);
        $chatService->markThreadRead($threadId);

        // Update thread unread count locally
        foreach ($this->threads as &$thread) {
            if (($thread['id'] ?? '') === $threadId) {
                $thread['unread_count_admin'] = 0;
                break;
            }
        }
    }

    /**
     * Send a new message to the selected thread.
     */
    public function sendMessage(): void
    {
        if (trim($this->newMessage) === '' || $this->selectedThreadId === null) {
            return;
        }

        $chatService = app(ChatService::class);
        $chatService->sendMessage($this->selectedThreadId, trim($this->newMessage));

        // Reload messages
        $this->messages = $chatService->getMessages($this->selectedThreadId);
        $this->newMessage = '';

        // Refresh threads to update last message preview
        $this->threads = $chatService->getThreads();
    }

    /**
     * Refresh data for polling.
     */
    public function refreshData(): void
    {
        $chatService = app(ChatService::class);
        $this->threads = $chatService->getThreads();
        $this->stats = $chatService->getStats();

        if ($this->selectedThreadId !== null) {
            $this->messages = $chatService->getMessages($this->selectedThreadId);
        }
    }

    /**
     * Event listeners.
     */
    protected function getListeners(): array
    {
        return ['$refresh'];
    }

    public function render()
    {
        return view('livewire.chat-panel');
    }
}
