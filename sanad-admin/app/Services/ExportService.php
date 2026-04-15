<?php

namespace App\Services;

class ExportService
{
    /**
     * Export data to CSV. Returns file path.
     *
     * @param  array  $data  Array of rows (arrays or FirestoreModel instances).
     * @param  array  $columns  Map of field key => header label (e.g. ['email' => 'Email']).
     * @param  string  $filename  Base filename (without extension or timestamp).
     * @return string Absolute path to the generated CSV file.
     */
    public function exportToCsv(array $data, array $columns, string $filename): string
    {
        $dir = storage_path('app/exports');
        if (! is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        $path = $dir.'/'.$filename.'_'.date('Y-m-d_His').'.csv';
        $handle = fopen($path, 'w');

        // Write headers
        fputcsv($handle, array_values($columns));

        // Write data rows
        foreach ($data as $row) {
            $rowData = [];
            foreach (array_keys($columns) as $field) {
                $value = is_array($row) ? ($row[$field] ?? '') : ($row->getAttribute($field) ?? '');
                if (is_array($value)) {
                    $value = implode(', ', $value);
                }
                $rowData[] = $value;
            }
            fputcsv($handle, $rowData);
        }

        fclose($handle);

        return $path;
    }

    /**
     * Export data to PDF. Returns file path.
     *
     * Uses barryvdh/laravel-dompdf to render an HTML table as a landscape A4 PDF.
     *
     * @param  array  $data  Array of rows (arrays or FirestoreModel instances).
     * @param  array  $columns  Map of field key => header label.
     * @param  string  $filename  Base filename (without extension or timestamp).
     * @param  string  $title  Optional title printed at the top of the PDF.
     * @return string Absolute path to the generated PDF file.
     */
    public function exportToPdf(array $data, array $columns, string $filename, string $title = ''): string
    {
        $dir = storage_path('app/exports');
        if (! is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        $path = $dir.'/'.$filename.'_'.date('Y-m-d_His').'.pdf';

        // Build HTML table
        $html = '<html><head><style>';
        $html .= 'body { font-family: Arial, sans-serif; font-size: 12px; }';
        $html .= 'h1 { color: #4A90D9; font-size: 18px; }';
        $html .= 'table { width: 100%; border-collapse: collapse; margin-top: 10px; }';
        $html .= 'th { background-color: #4A90D9; color: white; padding: 8px; text-align: left; font-size: 11px; }';
        $html .= 'td { padding: 6px 8px; border-bottom: 1px solid #ddd; font-size: 11px; }';
        $html .= 'tr:nth-child(even) { background-color: #f9f9f9; }';
        $html .= '.footer { margin-top: 20px; font-size: 10px; color: #666; }';
        $html .= '</style></head><body>';
        $html .= '<h1>'.htmlspecialchars($title ?: 'Sanad Admin Export').'</h1>';
        $html .= '<p>Generated: '.date('Y-m-d H:i:s').'</p>';
        $html .= '<table><thead><tr>';

        foreach ($columns as $header) {
            $html .= '<th>'.htmlspecialchars($header).'</th>';
        }
        $html .= '</tr></thead><tbody>';

        foreach ($data as $row) {
            $html .= '<tr>';
            foreach (array_keys($columns) as $field) {
                $value = is_array($row) ? ($row[$field] ?? '') : ($row->getAttribute($field) ?? '');
                if (is_array($value)) {
                    $value = implode(', ', $value);
                }
                $html .= '<td>'.htmlspecialchars((string) $value).'</td>';
            }
            $html .= '</tr>';
        }

        $html .= '</tbody></table>';
        $html .= '<div class="footer">Sanad Admin - Confidential</div>';
        $html .= '</body></html>';

        // Use DomPDF
        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadHTML($html);
        $pdf->setPaper('A4', 'landscape');
        $pdf->save($path);

        return $path;
    }
}
