<?php

namespace App\Filament\Resources\ContentResource\Pages;

use App\Filament\Resources\ContentResource;
use App\Models\AppContent;
use Filament\Resources\Pages\Page;

class EditContent extends Page
{
    protected static string $resource = ContentResource::class;

    protected static string $view = 'filament.resources.content-resource.pages.edit-content';

    public string $recordId = '';
    public string $contentTitle = '';
    public string $category = '';
    public string $type = 'article';
    public string $content_text = '';
    public string $media_url = '';
    public string $link_url = '';
    public string $thumbnail_url = '';
    public bool $is_premium = false;
    public string $mood_tags_input = '';
    public bool $is_published = false;

    public function getTitle(): string
    {
        return __('edit_content');
    }

    public function getHeading(): string
    {
        return __('edit_content');
    }

    public function mount(string|AppContent $record): void
    {
        $model = $record instanceof AppContent ? $record : AppContent::find($record);

        if (! $model) {
            $this->redirect(ContentResource::getUrl('index'));
            return;
        }

        $this->recordId = $model->getKey();
        $this->contentTitle = $model->safeGet('title', '');
        $this->category = $model->safeGet('category', '');
        $this->type = $model->safeGet('type', 'article');
        $this->content_text = $model->safeGet('content_text', '');
        $this->media_url = $model->safeGet('media_url', '');
        $this->link_url = $model->safeGet('link_url', '');
        $this->thumbnail_url = $model->safeGet('thumbnail_url', '');
        $this->is_premium = (bool) $model->getAttribute('is_premium');
        $tags = $model->getAttribute('mood_tags');
        $this->mood_tags_input = is_array($tags) ? implode(', ', $tags) : '';
        $this->is_published = (bool) $model->getAttribute('is_published');
    }

    public function save(): void
    {
        $this->validate([
            'contentTitle' => 'required|string|max:255',
            'category' => 'required|string|max:255',
            'type' => 'required|in:article,exercise,video,podcast',
        ]);

        if ($this->type === 'article' && empty($this->content_text)) {
            $this->addError('content_text', __('content_text_required_for_article'));
            return;
        }

        if (in_array($this->type, ['video', 'podcast']) && empty($this->media_url)) {
            $this->addError('media_url', __('media_url_required_for_video'));
            return;
        }

        $model = AppContent::find($this->recordId);
        if (! $model) {
            $this->dispatch('notify', type: 'danger', message: __('record_not_found'));
            return;
        }

        $moodTags = array_filter(array_map('trim', explode(',', $this->mood_tags_input)));

        $model->fill([
            'title' => $this->contentTitle,
            'category' => $this->category,
            'type' => $this->type,
            'content_text' => $this->content_text,
            'media_url' => $this->media_url,
            'link_url' => $this->link_url,
            'thumbnail_url' => $this->thumbnail_url,
            'is_premium' => $this->is_premium,
            'mood_tags' => $moodTags,
            'is_published' => $this->is_published,
        ]);
        $model->save();

        $this->dispatch('notify', type: 'success', message: __('content_updated'));
        $this->redirect(ContentResource::getUrl('index'));
    }
}
