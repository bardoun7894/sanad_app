<?php

namespace App\Filament\Pages;

use App\Services\ReportService;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class Reports extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-document-chart-bar';

    protected static ?int $navigationSort = 7;

    protected static string $view = 'filament.pages.reports';

    public array $templates = [];

    public array $recentReports = [];

    public bool $isGenerating = false;

    public ?string $generatingTemplate = null;

    public function getTitle(): string
    {
        return __('reports');
    }

    public static function getNavigationLabel(): string
    {
        return __('reports');
    }

    public static function getNavigationGroup(): ?string
    {
        return __('insights');
    }

    public function mount(): void
    {
        $this->loadData();
    }

    protected function loadData(): void
    {
        try {
            $reportService = app(ReportService::class);
            $this->templates = $reportService->getAvailableTemplates();
            $this->recentReports = $reportService->getRecentReports(10);
        } catch (\Exception $e) {
            Log::error("Reports page data loading failed: {$e->getMessage()}");
            $this->templates = [];
            $this->recentReports = [];
        }
    }

    public function generateReport(string $template, string $format = 'pdf'): ?BinaryFileResponse
    {
        try {
            $this->isGenerating = true;
            $this->generatingTemplate = $template;

            $reportService = app(ReportService::class);
            $result = $reportService->generate($template, $format);

            $this->isGenerating = false;
            $this->generatingTemplate = null;

            // Refresh recent reports list
            $this->recentReports = $reportService->getRecentReports(10);

            $mimeType = $format === 'csv' ? 'text/csv' : 'application/pdf';

            return response()->download($result['path'], $result['filename'], [
                'Content-Type' => $mimeType,
            ]);
        } catch (\Exception $e) {
            Log::error("Report generation failed: {$e->getMessage()}", [
                'template' => $template,
                'format' => $format,
            ]);

            $this->isGenerating = false;
            $this->generatingTemplate = null;

            $this->dispatch('notify', [
                'type' => 'danger',
                'message' => __('report_generation_failed'),
            ]);

            return null;
        }
    }

    public function downloadReport(string $filename): ?BinaryFileResponse
    {
        try {
            $path = storage_path('app/exports/'.basename($filename));

            if (! file_exists($path)) {
                $this->dispatch('notify', [
                    'type' => 'danger',
                    'message' => __('report_not_found'),
                ]);

                return null;
            }

            $extension = pathinfo($path, PATHINFO_EXTENSION);
            $mimeType = $extension === 'csv' ? 'text/csv' : 'application/pdf';

            return response()->download($path, $filename, [
                'Content-Type' => $mimeType,
            ]);
        } catch (\Exception $e) {
            Log::error("Report download failed: {$e->getMessage()}", [
                'filename' => $filename,
            ]);

            return null;
        }
    }

    protected function getViewData(): array
    {
        return [
            'templates' => $this->templates,
            'recentReports' => $this->recentReports,
        ];
    }
}
