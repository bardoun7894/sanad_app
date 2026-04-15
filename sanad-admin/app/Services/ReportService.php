<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class ReportService
{
    protected FirestoreService $firestore;

    protected AnalyticsService $analytics;

    protected ExportService $export;

    public function __construct(
        FirestoreService $firestore,
        AnalyticsService $analytics,
        ExportService $export,
    ) {
        $this->firestore = $firestore;
        $this->analytics = $analytics;
        $this->export = $export;
    }

    /**
     * Generate a report by template name.
     *
     * @return array{path: string, filename: string, format: string, title: string}
     */
    public function generate(string $template, string $format = 'pdf', array $params = []): array
    {
        $data = match ($template) {
            'monthly_summary' => $this->getMonthlySummaryData($params),
            'patient_activity' => $this->getPatientActivityData($params),
            'clinician_report' => $this->getClinicianReportData($params),
            'financial_report' => $this->getFinancialReportData($params),
            'risk_assessment' => $this->getRiskAssessmentData($params),
            'custom_report' => $this->getCustomReportData($params),
            default => throw new \InvalidArgumentException("Unknown template: {$template}"),
        };

        $filename = $template.'_'.date('Y-m-d');

        if ($format === 'csv') {
            $path = $this->export->exportToCsv($data['rows'], $data['columns'], $filename);
        } else {
            $path = $this->export->exportToPdf($data['rows'], $data['columns'], $filename, $data['title']);
        }

        return [
            'path' => $path,
            'filename' => basename($path),
            'format' => $format,
            'title' => $data['title'],
        ];
    }

    /**
     * Get all available report templates with their metadata.
     *
     * @return array<int, array{id: string, title: string, description: string, icon: string}>
     */
    public function getAvailableTemplates(): array
    {
        return [
            [
                'id' => 'monthly_summary',
                'title' => __('monthly_summary_report'),
                'description' => __('monthly_summary_report_desc'),
                'icon' => 'heroicon-o-calendar-days',
            ],
            [
                'id' => 'patient_activity',
                'title' => __('patient_activity_report'),
                'description' => __('patient_activity_report_desc'),
                'icon' => 'heroicon-o-user-group',
            ],
            [
                'id' => 'clinician_report',
                'title' => __('clinician_report'),
                'description' => __('clinician_report_desc'),
                'icon' => 'heroicon-o-academic-cap',
            ],
            [
                'id' => 'financial_report',
                'title' => __('financial_report'),
                'description' => __('financial_report_desc'),
                'icon' => 'heroicon-o-banknotes',
            ],
            [
                'id' => 'risk_assessment',
                'title' => __('risk_assessment_report'),
                'description' => __('risk_assessment_report_desc'),
                'icon' => 'heroicon-o-exclamation-triangle',
            ],
            [
                'id' => 'custom_report',
                'title' => __('custom_report'),
                'description' => __('custom_report_desc'),
                'icon' => 'heroicon-o-adjustments-horizontal',
            ],
        ];
    }

    // ─── Template Data Methods ───────────────────────────────

    /**
     * Monthly Summary: KPIs + trends (active users, sessions, revenue, risk alerts).
     *
     * @return array{title: string, columns: array, rows: array}
     */
    protected function getMonthlySummaryData(array $params): array
    {
        try {
            $month = $params['month'] ?? Carbon::now()->format('Y-m');
            $startDate = Carbon::parse($month.'-01')->startOfMonth();
            $endDate = $startDate->copy()->endOfMonth();

            $activeUsers = $this->analytics->countActiveUsers();
            $todaySessions = $this->analytics->countTodaySessions();
            $earnings = $this->analytics->calculateEarnings();
            $criticalFlags = $this->analytics->countCriticalFlags();
            $noShowRate = $this->analytics->getNoShowRate();

            $rows = [
                [
                    'metric' => __('active_users'),
                    'value' => $activeUsers['count'],
                    'trend' => $activeUsers['trend'].'%',
                    'period' => __('last_30_days'),
                ],
                [
                    'metric' => __('todays_sessions'),
                    'value' => $todaySessions['count'],
                    'trend' => $todaySessions['trend'].'%',
                    'period' => __('today'),
                ],
                [
                    'metric' => __('monthly_revenue'),
                    'value' => $earnings['currency'].' '.number_format($earnings['amount'], 2),
                    'trend' => $earnings['trend'].'%',
                    'period' => __('current_month'),
                ],
                [
                    'metric' => __('risk_alerts'),
                    'value' => $criticalFlags['count'],
                    'trend' => $criticalFlags['trend'].'%',
                    'period' => __('total_active'),
                ],
                [
                    'metric' => __('no_show_rate'),
                    'value' => $noShowRate['rate'].'%',
                    'trend' => $noShowRate['no_show_count'].'/'.$noShowRate['total'],
                    'period' => __('all_time'),
                ],
            ];

            return [
                'title' => __('monthly_summary_report').' - '.$month,
                'columns' => [
                    'metric' => __('metric'),
                    'value' => __('value'),
                    'trend' => __('trend'),
                    'period' => __('period'),
                ],
                'rows' => $rows,
            ];
        } catch (\Exception $e) {
            Log::error("ReportService::getMonthlySummaryData failed: {$e->getMessage()}");

            return [
                'title' => __('monthly_summary_report'),
                'columns' => ['metric' => __('metric'), 'value' => __('value'), 'trend' => __('trend'), 'period' => __('period')],
                'rows' => [],
            ];
        }
    }

    /**
     * Patient Activity: User engagement metrics (login frequency, mood entries, bookings).
     *
     * @return array{title: string, columns: array, rows: array}
     */
    protected function getPatientActivityData(array $params): array
    {
        try {
            $limit = $params['limit'] ?? 100;

            $users = $this->firestore->queryCollection('users', [], 'created_at', 'DESC', $limit);

            $rows = [];
            foreach ($users as $user) {
                $userId = $user['id'] ?? '';
                $displayName = $user['display_name'] ?? $user['full_name'] ?? __('unknown');
                $email = $user['email'] ?? '';
                $lastLogin = $user['last_login'] ?? __('never');

                // Count mood entries for this user
                $moodEntryCount = $this->firestore->countDocuments('mood_entries', [
                    ['user_id', '=', $userId],
                ]);

                // Count bookings for this user
                $bookingCount = $this->firestore->countDocuments('bookings', [
                    ['client_id', '=', $userId],
                ]);

                $rows[] = [
                    'name' => $displayName,
                    'email' => $email,
                    'last_login' => $lastLogin,
                    'mood_entries' => $moodEntryCount,
                    'bookings' => $bookingCount,
                ];
            }

            return [
                'title' => __('patient_activity_report'),
                'columns' => [
                    'name' => __('name'),
                    'email' => __('email'),
                    'last_login' => __('last_login'),
                    'mood_entries' => __('mood_entries'),
                    'bookings' => __('bookings'),
                ],
                'rows' => $rows,
            ];
        } catch (\Exception $e) {
            Log::error("ReportService::getPatientActivityData failed: {$e->getMessage()}");

            return [
                'title' => __('patient_activity_report'),
                'columns' => ['name' => __('name'), 'email' => __('email'), 'last_login' => __('last_login'), 'mood_entries' => __('mood_entries'), 'bookings' => __('bookings')],
                'rows' => [],
            ];
        }
    }

    /**
     * Clinician Report: Therapist performance (sessions, ratings, revenue per therapist).
     *
     * @return array{title: string, columns: array, rows: array}
     */
    protected function getClinicianReportData(array $params): array
    {
        try {
            $performance = $this->analytics->getClinicianPerformance();
            $ratings = $this->analytics->getTherapistRatings();

            // Index ratings by therapist_id
            $ratingsMap = [];
            foreach ($ratings as $r) {
                $ratingsMap[$r['therapist_id']] = $r;
            }

            // Calculate revenue per therapist from completed bookings
            $bookings = $this->firestore->queryCollection('bookings', [
                ['status', '=', 'completed'],
            ]);

            $revenueMap = [];
            foreach ($bookings as $booking) {
                $therapistId = $booking['therapist_id'] ?? null;
                if ($therapistId === null) {
                    continue;
                }
                if (! isset($revenueMap[$therapistId])) {
                    $revenueMap[$therapistId] = 0.0;
                }
                $revenueMap[$therapistId] += (float) ($booking['amount'] ?? 0);
            }

            $rows = [];
            foreach ($performance as $therapist) {
                $therapistId = $therapist['therapist_id'];
                $revenue = $revenueMap[$therapistId] ?? 0.0;

                $rows[] = [
                    'name' => $therapist['name'],
                    'sessions' => $therapist['session_count'],
                    'completed' => $therapist['completed_count'],
                    'no_shows' => $therapist['no_show_count'],
                    'completion_rate' => $therapist['completion_rate'].'%',
                    'avg_rating' => number_format($therapist['average_rating'], 2),
                    'reviews' => $therapist['review_count'],
                    'revenue' => 'SAR '.number_format($revenue, 2),
                ];
            }

            return [
                'title' => __('clinician_report'),
                'columns' => [
                    'name' => __('therapist_name'),
                    'sessions' => __('total_sessions'),
                    'completed' => __('completed'),
                    'no_shows' => __('no_shows'),
                    'completion_rate' => __('completion_rate'),
                    'avg_rating' => __('avg_rating'),
                    'reviews' => __('reviews'),
                    'revenue' => __('revenue'),
                ],
                'rows' => $rows,
            ];
        } catch (\Exception $e) {
            Log::error("ReportService::getClinicianReportData failed: {$e->getMessage()}");

            return [
                'title' => __('clinician_report'),
                'columns' => ['name' => __('therapist_name'), 'sessions' => __('total_sessions'), 'completed' => __('completed'), 'no_shows' => __('no_shows'), 'completion_rate' => __('completion_rate'), 'avg_rating' => __('avg_rating'), 'reviews' => __('reviews'), 'revenue' => __('revenue')],
                'rows' => [],
            ];
        }
    }

    /**
     * Financial Report: Revenue + payments breakdown.
     *
     * @return array{title: string, columns: array, rows: array}
     */
    protected function getFinancialReportData(array $params): array
    {
        try {
            $startDate = $params['start_date'] ?? Carbon::now()->subMonths(3)->toDateTimeString();
            $endDate = $params['end_date'] ?? Carbon::now()->toDateTimeString();

            $payments = $this->firestore->queryCollection('payments', [
                ['created_at', '>=', $startDate],
            ], 'created_at', 'DESC');

            $rows = [];
            foreach ($payments as $payment) {
                $rows[] = [
                    'date' => $payment['created_at'] ?? '',
                    'user_email' => $payment['user_email'] ?? __('unknown'),
                    'product' => $payment['product_title'] ?? __('n_a'),
                    'amount' => ($payment['currency'] ?? 'SAR').' '.number_format((float) ($payment['amount'] ?? 0), 2),
                    'method' => $payment['payment_method'] ?? __('n_a'),
                    'status' => ucfirst($payment['status'] ?? __('unknown')),
                    'reference' => $payment['reference_code'] ?? __('n_a'),
                ];
            }

            return [
                'title' => __('financial_report'),
                'columns' => [
                    'date' => __('date'),
                    'user_email' => __('user_email'),
                    'product' => __('product'),
                    'amount' => __('amount'),
                    'method' => __('payment_method'),
                    'status' => __('status'),
                    'reference' => __('reference'),
                ],
                'rows' => $rows,
            ];
        } catch (\Exception $e) {
            Log::error("ReportService::getFinancialReportData failed: {$e->getMessage()}");

            return [
                'title' => __('financial_report'),
                'columns' => ['date' => __('date'), 'user_email' => __('user_email'), 'product' => __('product'), 'amount' => __('amount'), 'method' => __('payment_method'), 'status' => __('status'), 'reference' => __('reference')],
                'rows' => [],
            ];
        }
    }

    /**
     * Risk Assessment: Mood analysis + risk levels per user.
     *
     * @return array{title: string, columns: array, rows: array}
     */
    protected function getRiskAssessmentData(array $params): array
    {
        try {
            // Fetch assessments with risk flags
            $assessments = $this->firestore->queryCollection('assessments', [], 'created_at', 'DESC');

            $rows = [];
            foreach ($assessments as $assessment) {
                $userId = $assessment['user_id'] ?? '';
                $riskLevel = $assessment['risk_level'] ?? 'low';

                // Fetch user info
                $userName = __('unknown');
                $userEmail = '';
                if ($userId) {
                    $user = $this->firestore->getDocument('users', $userId);
                    if ($user) {
                        $userName = $user['display_name'] ?? $user['full_name'] ?? __('unknown');
                        $userEmail = $user['email'] ?? '';
                    }
                }

                // Count mood entries for this user
                $moodCount = 0;
                $avgMood = 0.0;
                if ($userId) {
                    $moodEntries = $this->firestore->queryCollection('mood_entries', [
                        ['user_id', '=', $userId],
                    ], 'created_at', 'DESC', 30);

                    $moodCount = count($moodEntries);
                    if ($moodCount > 0) {
                        $moodSum = array_sum(array_map(
                            fn (array $entry) => (int) ($entry['mood'] ?? 0),
                            $moodEntries,
                        ));
                        $avgMood = round($moodSum / $moodCount, 2);
                    }
                }

                $rows[] = [
                    'user_name' => $userName,
                    'user_email' => $userEmail,
                    'risk_level' => ucfirst($riskLevel),
                    'avg_mood' => number_format($avgMood, 1),
                    'mood_entries' => $moodCount,
                    'assessment_date' => $assessment['created_at'] ?? __('n_a'),
                    'notes' => $assessment['notes'] ?? '',
                ];
            }

            return [
                'title' => __('risk_assessment_report'),
                'columns' => [
                    'user_name' => __('patient_name'),
                    'user_email' => __('email'),
                    'risk_level' => __('risk_level'),
                    'avg_mood' => __('avg_mood'),
                    'mood_entries' => __('mood_entries'),
                    'assessment_date' => __('assessment_date'),
                    'notes' => __('notes'),
                ],
                'rows' => $rows,
            ];
        } catch (\Exception $e) {
            Log::error("ReportService::getRiskAssessmentData failed: {$e->getMessage()}");

            return [
                'title' => __('risk_assessment_report'),
                'columns' => ['user_name' => __('patient_name'), 'user_email' => __('email'), 'risk_level' => __('risk_level'), 'avg_mood' => __('avg_mood'), 'mood_entries' => __('mood_entries'), 'assessment_date' => __('assessment_date'), 'notes' => __('notes')],
                'rows' => [],
            ];
        }
    }

    /**
     * Custom Report: Configurable based on params (collection, fields, filters).
     *
     * Expected params:
     * - collection: string (Firestore collection name)
     * - fields: array (list of field names to include)
     * - filters: array (optional, list of [field, operator, value] triplets)
     * - order_by: string (optional, field to order by)
     * - direction: string (optional, ASC or DESC)
     * - limit: int (optional, max rows)
     *
     * @return array{title: string, columns: array, rows: array}
     */
    protected function getCustomReportData(array $params): array
    {
        try {
            $collection = $params['collection'] ?? 'users';
            $fields = $params['fields'] ?? ['id', 'email', 'display_name', 'created_at'];
            $filters = $params['filters'] ?? [];
            $orderBy = $params['order_by'] ?? 'created_at';
            $direction = $params['direction'] ?? 'DESC';
            $limit = $params['limit'] ?? 100;

            $documents = $this->firestore->queryCollection(
                $collection,
                $filters,
                $orderBy,
                $direction,
                $limit,
            );

            // Build columns from fields
            $columns = [];
            foreach ($fields as $field) {
                $columns[$field] = ucfirst(str_replace('_', ' ', $field));
            }

            $rows = [];
            foreach ($documents as $doc) {
                $row = [];
                foreach ($fields as $field) {
                    $value = $doc[$field] ?? '';
                    if (is_array($value)) {
                        $value = json_encode($value);
                    }
                    $row[$field] = $value;
                }
                $rows[] = $row;
            }

            return [
                'title' => __('custom_report').' - '.ucfirst($collection),
                'columns' => $columns,
                'rows' => $rows,
            ];
        } catch (\Exception $e) {
            Log::error("ReportService::getCustomReportData failed: {$e->getMessage()}");

            return [
                'title' => __('custom_report'),
                'columns' => ['error' => __('error')],
                'rows' => [['error' => $e->getMessage()]],
            ];
        }
    }

    /**
     * List recently generated reports from the exports directory.
     *
     * @return array<int, array{filename: string, path: string, size: string, created_at: string}>
     */
    public function getRecentReports(int $limit = 10): array
    {
        $dir = storage_path('app/exports');

        if (! is_dir($dir)) {
            return [];
        }

        $files = glob($dir.'/*.*');

        if (empty($files)) {
            return [];
        }

        // Sort by modification time, newest first
        usort($files, fn ($a, $b) => filemtime($b) - filemtime($a));

        $reports = [];
        foreach (array_slice($files, 0, $limit) as $file) {
            $reports[] = [
                'filename' => basename($file),
                'path' => $file,
                'size' => $this->formatFileSize(filesize($file)),
                'created_at' => date('Y-m-d H:i:s', filemtime($file)),
                'format' => pathinfo($file, PATHINFO_EXTENSION),
            ];
        }

        return $reports;
    }

    /**
     * Format a file size in bytes to a human-readable string.
     */
    protected function formatFileSize(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $i = 0;

        while ($bytes >= 1024 && $i < count($units) - 1) {
            $bytes /= 1024;
            $i++;
        }

        return round($bytes, 1).' '.$units[$i];
    }
}
