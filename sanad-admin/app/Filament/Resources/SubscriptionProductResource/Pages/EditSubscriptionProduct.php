<?php

namespace App\Filament\Resources\SubscriptionProductResource\Pages;

use App\Filament\Resources\SubscriptionProductResource;
use App\Models\SubscriptionProduct;
use Filament\Resources\Pages\Page;

class EditSubscriptionProduct extends Page
{
    protected static string $resource = SubscriptionProductResource::class;
    protected static string $view = 'filament.resources.subscription-product-resource.pages.edit-subscription-product';

    public string $recordId = '';
    public string $product_title = '';
    public string $product_description = '';
    public float $price = 0;
    public string $currency_code = 'SAR';
    public string $billing_period = 'monthly';
    public int $billing_period_days = 30;
    public string $localized_price = '';
    public bool $is_featured = false;
    public string $features_input = '';

    public function getTitle(): string
    {
        return __('edit_subscription_product');
    }

    public function getHeading(): string
    {
        return __('edit_subscription_product');
    }

    public function mount(string|SubscriptionProduct $record): void
    {
        $model = $record instanceof SubscriptionProduct ? $record : SubscriptionProduct::find($record);

        if (! $model) {
            $this->redirect(SubscriptionProductResource::getUrl('index'));
            return;
        }

        $this->recordId = $model->getKey();
        $this->product_title = $model->safeGet('title', '');
        $this->product_description = $model->safeGet('description', '');
        $this->price = (float) ($model->getAttribute('price') ?? 0);
        $this->currency_code = $model->safeGet('currency_code', 'SAR');
        $this->billing_period = $model->safeGet('billing_period', 'monthly');
        $this->billing_period_days = (int) ($model->getAttribute('billing_period_days') ?? 30);
        $this->localized_price = $model->safeGet('localized_price', '');
        $this->is_featured = (bool) $model->getAttribute('is_featured');

        $features = $model->getAttribute('features');
        $this->features_input = is_array($features) ? implode("\n", $features) : '';
    }

    public function save(): void
    {
        $this->validate([
            'product_title' => 'required|string|max:255',
            'product_description' => 'required|string',
            'price' => 'required|numeric|min:0',
            'currency_code' => 'required|string|max:10',
            'billing_period' => 'required|in:weekly,monthly',
            'billing_period_days' => 'required|integer|min:1',
        ]);

        $model = SubscriptionProduct::find($this->recordId);
        if (! $model) {
            $this->dispatch('notify', type: 'danger', message: __('record_not_found'));
            return;
        }

        $features = array_filter(array_map('trim', explode("\n", $this->features_input)));

        $model->fill([
            'title' => $this->product_title,
            'description' => $this->product_description,
            'price' => $this->price,
            'currency_code' => $this->currency_code,
            'billing_period' => $this->billing_period,
            'billing_period_days' => $this->billing_period_days,
            'localized_price' => $this->localized_price,
            'is_featured' => $this->is_featured,
            'features' => $features,
        ]);
        $model->save();

        $this->dispatch('notify', type: 'success', message: __('product_updated'));
        $this->redirect(SubscriptionProductResource::getUrl('index'));
    }
}
