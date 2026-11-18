import 'all_string_getters_1.dart';
import 'all_string_getters_2.dart';
import 'all_string_getters_3.dart';
import 'all_string_getters_4.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';

Map<String, String> allStringGetters(S s) => {
  ...stringGetters1(s),
  ...stringGetters2(s),
  ...stringGetters3(s),
  ...stringGetters4(s),
};
