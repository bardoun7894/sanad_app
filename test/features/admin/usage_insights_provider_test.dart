import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/usage_insights_provider.dart';

void main() {
  final insights = AdminUsageInsights.fromMap({
    'windowDays': 30,
    'totals': {
      'users': 991,
      'active1d': 10,
      'active7d': 38,
      'active30d': 121,
      'newUsers': 54,
    },
    'sections': [
      {
        'key': 'challenges', // secret-scan:allow
        'labelAr': 'التحديات اليومية',
        'uniqueUsers': 16,
        'events': 26,
        'uniqueUsersAllTime': 296,
        'eventsAllTime': 574,
      },
      {
        'key': 'tests',
        'labelAr': 'الاختبارات النفسية',
        'uniqueUsers': 2,
        'events': 21,
        'uniqueUsersAllTime': 7,
        'eventsAllTime': 48,
      },
    ],
    'firstFeature': [
      {'key': 'mood', 'labelAr': 'تسجيل المشاعر (المزاج)', 'users': 205},
    ],
    'peakHours': [
      {'hour': 9, 'count': 10},
    ],
    'busiestWeekdays': [
      {'day': 2, 'labelAr': 'الثلاثاء', 'count': 20},
    ],
    'topUsers': [
      {
        'uid': 'u1',
        'name': 'Hidden Person',
        'activeDays': 29,
        'events': 159,
        'bySection': {'challenges': 5},
        'aiConsent': false,
      },
      {
        'uid': 'u2',
        'name': 'Shared Person',
        'activeDays': 28,
        'events': 66,
        'bySection': {'tests': 3},
        'aiConsent': true,
      },
    ],
    'notTracked': [
      {'key': 'content_views', 'ar': 'مشاهدات المقالات'}, // secret-scan:allow
    ],
  });

  test('only consenting top users become AI-transfer subjects', () {
    expect(insights.consentingTopUserIds, {'u2'});
  });

  test('prompt names consenting users and masks the rest', () {
    final text = insights.toPromptContext();
    expect(text, contains('Shared Person'));
    expect(text, isNot(contains('Hidden Person')));
    expect(text, contains('مستخدم #1 (اسمه محجوب'));
  });

  test('prompt carries section ranking, peaks and untracked data', () {
    final text = insights.toPromptContext();
    expect(text, contains('1. التحديات اليومية: 16 مستخدم / 26 نشاط'));
    expect(text, contains('2. الاختبارات النفسية'));
    expect(text, contains('09:00'));
    expect(text, contains('الثلاثاء'));
    expect(text, contains('تسجيل المشاعر (المزاج) 205'));
    expect(text, contains('غير متتبعة'));
    expect(text, contains('آخر 7 أيام 38'));
  });

  test('empty payload still yields a valid block', () {
    final text = const AdminUsageInsights({}).toPromptContext();
    expect(text, contains('إحصائيات استخدام التطبيق'));
  });
}
