import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/utils/revenue_split.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';
import 'package:sanad_app/features/admin/utils/invoices_csv.dart';

/// Unit tests for the pure CSV-builder function.
/// These tests NEVER call DateTime.now() — all dates are fixed values.
/// The browser download side-effect is NOT tested here (Flutter web only).
void main() {
  // Fixed invoice records with known values for deterministic assertions.
  final inv1 = InvoiceRecord(
    id: 'b1',
    clientName: 'فهد القحطاني',
    therapistId: 't1',
    therapistName: 'Lamia Salah',
    currency: 'USD',
    status: 'completed',
    paymentMethod: 'paypal',
    amount: 100.0,
    date: DateTime(2026, 5, 17),
    shares: RevenueSplit.compute(
      amount: 100.0,
      therapistPct: 60,
      appPct: 30,
      maintenancePct: 10,
    ),
  );

  final inv2 = InvoiceRecord(
    id: 'b2',
    clientName: 'Mona Dugag',
    therapistId: 't2',
    therapistName: 'Ahmed Suleiman',
    currency: 'USD',
    status: 'completed',
    paymentMethod: 'bank_transfer',
    amount: 50.0,
    date: DateTime(2026, 6, 1),
    shares: RevenueSplit.compute(
      amount: 50.0,
      therapistPct: 60,
      appPct: 30,
      maintenancePct: 10,
    ),
  );

  test('CSV header row is correct Arabic columns', () {
    final csv = buildInvoicesCsv([]);
    final lines = csv.split('\n');
    expect(lines.isNotEmpty, isTrue);
    // The header must contain the 7 required Arabic column names.
    final header = lines[0];
    expect(header, contains('العميل'));
    expect(header, contains('تاريخ الاشتراك'));
    expect(header, contains('المعالج المخصص'));
    expect(header, contains('قيمة الاشتراك الإجمالية'));
    expect(header, contains('حصة المعالج'));
    expect(header, contains('حصة التطبيق'));
    expect(header, contains('حصة الصيانة'));
  });

  test('empty invoice list produces only header row', () {
    final csv = buildInvoicesCsv([]);
    final lines = csv.split('\n').where((l) => l.trim().isNotEmpty).toList();
    expect(lines.length, 1); // header only
  });

  test('two invoices produce header + 2 data rows', () {
    final csv = buildInvoicesCsv([inv1, inv2]);
    final lines = csv.split('\n').where((l) => l.trim().isNotEmpty).toList();
    expect(lines.length, 3); // header + 2 rows
  });

  test('data row contains correct client name and therapist name', () {
    final csv = buildInvoicesCsv([inv1]);
    expect(csv, contains('فهد القحطاني'));
    expect(csv, contains('Lamia Salah'));
  });

  test('data row contains correct date formatted as YYYY-MM-DD', () {
    final csv = buildInvoicesCsv([inv1]);
    expect(csv, contains('2026-05-17'));
  });

  test('data row contains correct total amount', () {
    final csv = buildInvoicesCsv([inv1]);
    expect(csv, contains('100.00'));
  });

  test('share columns reflect 60/30/10 split on \$100', () {
    final csv = buildInvoicesCsv([inv1]);
    // therapist = 60.00, app = 30.00, maintenance = 10.00
    expect(csv, contains('60.00'));
    expect(csv, contains('30.00'));
    expect(csv, contains('10.00'));
  });

  test('only the provided (filtered) rows are exported — not all invoices', () {
    // Only pass inv2 — inv1 must not appear in the output.
    final csv = buildInvoicesCsv([inv2]);
    expect(csv, isNot(contains('فهد القحطاني')));
    expect(csv, contains('Mona Dugag'));
    expect(csv, contains('50.00'));
  });

  test('Arabic client name in cell is properly quoted when it contains a comma',
      () {
    final invWithComma = InvoiceRecord(
      id: 'b3',
      clientName: 'علي، محمد', // Arabic name with Arabic comma
      therapistId: 't1',
      therapistName: 'Dr. Test',
      currency: 'USD',
      status: 'completed',
      paymentMethod: 'paypal',
      amount: 75.0,
      date: DateTime(2026, 3, 10),
      shares: RevenueSplit.compute(
        amount: 75.0,
        therapistPct: 60,
        appPct: 30,
        maintenancePct: 10,
      ),
    );
    final csv = buildInvoicesCsv([invWithComma]);
    // The cell with a comma must be wrapped in double-quotes.
    expect(csv, contains('"علي، محمد"'));
  });

  test('double-quotes in cell values are escaped as two double-quotes', () {
    final invWithQuote = InvoiceRecord(
      id: 'b4',
      clientName: 'He said "hello"',
      therapistId: 't1',
      therapistName: 'Dr. Test',
      currency: 'USD',
      status: 'completed',
      paymentMethod: 'paypal',
      amount: 20.0,
      date: DateTime(2026, 1, 5),
      shares: RevenueSplit.compute(
        amount: 20.0,
        therapistPct: 60,
        appPct: 30,
        maintenancePct: 10,
      ),
    );
    final csv = buildInvoicesCsv([invWithQuote]);
    // RFC 4180: double-quote inside quoted field → ""
    expect(csv, contains('"He said ""hello"""'));
  });

  test('CSV starts with UTF-8 BOM bytes for Excel Arabic compatibility', () {
    final csv = buildInvoicesCsv([]);
    // BOM is the string representation of the UTF-8 BOM character (U+FEFF).
    expect(csv.startsWith('﻿'), isTrue);
  });
}
