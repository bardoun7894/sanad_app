<?php

namespace App\Filament\Resources\SubscriptionProductResource\Pages;

use App\Filament\Resources\SubscriptionProductResource;
use App\Models\SubscriptionProduct;
use Filament\Resources\Pages\Page;

class ListSubscriptionProducts extends Page
{
    protected static string $resource = SubscriptionProductResource::class;
    protected static string $view = 'filament.resources.subscription-product-resource.pages.list-subscription-products';

    public array $records = [];

    public function getTitle(): string
    {
        return __('subscription_products');
    }

    public function getHeading(): string
    {
        return __('subscription_products');
    }

    public function mount(): void
    {
        $this->loadRecords();
    }

    public function loadRecords(): void
    {
        $this->records = SubscriptionProduct::all();
    }

    public function deleteRecord(string $id): void
    {
        $record = SubscriptionProduct::find($id);
        if ($record) {
            $record->delete();
        }
        $this->loadRecords();
        $this->dispatch('notify', type: 'success', message: __('record_deleted'));
    }
}
