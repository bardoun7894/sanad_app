import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Usage insights computed server-side by the `getAdminUsageInsights`
/// callable: section usage, active users, most active users, first feature
/// tried, and peak times. Fetched once per admin session (autoDispose off) so
/// every assistant message doesn't re-read thousands of documents.
final adminUsageInsightsProvider = FutureProvider<AdminUsageInsights>((
  ref,
) async {
  final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
      .httpsCallable(
        'getAdminUsageInsights',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      )
      .call({'windowDays': 30});
  return AdminUsageInsights.fromMap(
    Map<String, dynamic>.from(result.data as Map),
  );
});

class AdminUsageInsights {
  final Map<String, dynamic> raw;
  const AdminUsageInsights(this.raw);

  factory AdminUsageInsights.fromMap(Map<String, dynamic> map) =>
      AdminUsageInsights(map);

  List<Map<String, dynamic>> _list(String key) => (raw[key] as List? ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  /// IDs of listed top users who accepted AI data sharing. Only these users
  /// are named in the prompt, so only these are AI-transfer subjects.
  Set<String> get consentingTopUserIds => {
    for (final u in _list('topUsers'))
      if (u['aiConsent'] == true && u['uid'] is String) u['uid'] as String,
  };

  /// Arabic prompt block. Users without AI consent appear only as an
  /// anonymous rank with activity counts, never by name.
  String toPromptContext() {
    final b = StringBuffer();
    final days = raw['windowDays'] ?? 30;
    final totals = Map<String, dynamic>.from(raw['totals'] as Map? ?? {});
    b.writeln('\nإحصائيات استخدام التطبيق (آخر $days يوماً) / App usage:');
    b.writeln(
      '- المستخدمون النشطون: آخر 24 ساعة ${totals['active1d'] ?? 0}، '
      'آخر 7 أيام ${totals['active7d'] ?? 0}، آخر $days يوماً ${totals['active30d'] ?? 0} '
      '(من أصل ${totals['users'] ?? 0}). مستخدمون جدد: ${totals['newUsers'] ?? 0}.',
    );

    final sections = _list('sections');
    if (sections.isNotEmpty) {
      b.writeln(
        '- الأقسام مرتبة حسب عدد المستخدمين خلال الفترة (المستخدمون / عدد الأنشطة | منذ البداية):',
      );
      var i = 1;
      for (final s in sections) {
        b.writeln(
          '  ${i++}. ${s['labelAr']}: ${s['uniqueUsers']} مستخدم / ${s['events']} نشاط '
          '| منذ البداية ${s['uniqueUsersAllTime']} مستخدم / ${s['eventsAllTime']} نشاط',
        );
      }
    }

    final first = _list('firstFeature');
    if (first.isNotEmpty) {
      b.writeln(
        '- أول قسم يستخدمه كل مستخدم بعد التسجيل (عدد المستخدمين): '
        '${first.map((f) => '${f['labelAr']} ${f['users']}').join('، ')}',
      );
    }

    final hours = _list('peakHours');
    if (hours.isNotEmpty) {
      b.writeln(
        '- أوقات الذروة بتوقيت الرياض: '
        '${hours.map((h) => '${h['hour'].toString().padLeft(2, '0')}:00').join('، ')}',
      );
    }
    final weekdays = _list('busiestWeekdays');
    if (weekdays.isNotEmpty) {
      b.writeln(
        '- أكثر الأيام نشاطاً: ${weekdays.map((d) => d['labelAr']).join('، ')}',
      );
    }

    final top = _list('topUsers');
    if (top.isNotEmpty) {
      b.writeln('- أكثر المستخدمين نشاطاً (حسب عدد أيام النشاط):');
      final labels = {
        for (final s in sections) s['key'] as String: s['labelAr'] as String,
      };
      var i = 1;
      for (final u in top) {
        final who = u['aiConsent'] == true
            ? '${u['name']}'
            : 'مستخدم #$i (اسمه محجوب: لم يوافق على مشاركة بياناته مع الذكاء الاصطناعي)';
        final by = Map<String, dynamic>.from(u['bySection'] as Map? ?? {});
        final parts = by.entries
            .map((e) => '${labels[e.key] ?? e.key} ${e.value}')
            .join('، ');
        b.writeln(
          '  $i. $who: ${u['activeDays']} يوم نشاط، ${u['events']} نشاط ($parts)',
        );
        i++;
      }
    }

    final missing = _list('notTracked');
    if (missing.isNotEmpty) {
      b.writeln(
        '- بيانات غير متتبعة حالياً في التطبيق: '
        '${missing.map((m) => m['ar']).join('، ')}. '
        'إذا سُئلت عنها فقل بوضوح إنها غير متتبعة بعد، ولا تخمّن أرقاماً.',
      );
    }
    b.writeln(
      '- عند سؤالك عن الأقسام التي تحتاج تحسيناً: الأقسام ذات الإقبال الضعيف هي التي تحتاج تطويراً، '
      'والأقسام ذات الإقبال العالي هي التي تستحق الاستثمار فيها أكثر.',
    );
    return b.toString();
  }
}
