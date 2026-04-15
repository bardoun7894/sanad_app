<?php

namespace App\Filament\Resources\SubscriptionProductResource\Pages;

use App\Filament\Resources\SubscriptionProductResource;
use App\Models\SubscriptionProduct;
use Filament\Resources\Pages\Page;

class CreateSubscriptionProduct extends Page
{
    protected static string $resource = SubscriptionProductResource::class;
    protected static string $view = 'filament.resources.subscription-product-resource.pages.create-subscription-product';

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
        return __('create_subscription_product');
    }

    public function getHeading(): string
    {
        return __('create_subscription_product');
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

        $features = array_filter(array_map('trim', explode("\n", $this->features_input)));

        SubscriptionProduct::create([
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

        $this->dispatch('notify', type: 'success', message: __('product_created'));
        $this->redirect(SubscriptionProductResource::getUrl('index'));
    }
}
