// TDD — red phase: verify InsightsScreen and ClinicReportViewerScreen exist
// and that AppRoutes has the two new constants.
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/insights/insights_screen.dart';
import 'package:sanad_app/features/admin/screens/clinic_report_viewer_screen.dart';
import 'package:sanad_app/routes/app_routes.dart';

void main() {
  group('AppRoutes — new AI route constants', () {
    test('insights route constant exists and is /insights', () {
      expect(AppRoutes.insights, '/insights');
    });

    test('adminPatientReports route constant exists', () {
      expect(AppRoutes.adminPatientReports, '/admin/patients/reports');
    });

    test('insights is in protectedRoutes', () {
      expect(AppRoutes.protectedRoutes, contains(AppRoutes.insights));
    });
  });

  group('InsightsScreen — class exists and is a Widget', () {
    test('InsightsScreen can be instantiated', () {
      const screen = InsightsScreen();
      expect(screen, isNotNull);
    });
  });

  group('ClinicReportViewerScreen — class exists and takes userId', () {
    test('ClinicReportViewerScreen can be instantiated with userId', () {
      const screen = ClinicReportViewerScreen(userId: 'test-uid');
      expect(screen, isNotNull);
      expect(screen.userId, 'test-uid');
    });
  });
}
