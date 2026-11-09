import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:stop_it/models/app_data.dart';
import 'package:stop_it/localization/strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recovery data and domain validation', () {
    test('fresh recovery starts at day zero before a start date exists', () {
      final data = AppData();
      expect(data.currentStreak, 0);
      expect(data.totalDays, 0);
    });

    test('a recovery does not claim a full day immediately', () {
      final data = AppData()..recoveryStarted = DateTime.now();
      expect(data.currentStreak, 0);
      expect(data.nextMilestone, 1);
    });

    test('domain parser accepts a hostname and strips URL path', () async {
      final data = AppData();
      expect(await data.addDomain('https://sub.example.org/path?q=1'), isTrue);
      expect(data.customDomains, ['sub.example.org']);
    });

    test('domain entries are deduplicated after normalization', () async {
      final data = AppData();
      expect(await data.addDomain('EXAMPLE.org'), isTrue);
      expect(await data.addDomain('https://example.org/path'), isTrue);
      expect(data.customDomains, ['example.org']);
    });

    test('restart preserves completed days without counting a partial day', () async {
      final data = AppData()
        ..recoveryStarted = DateTime.now().subtract(const Duration(days: 3, hours: 2));
      expect(data.currentStreak, 3);
      await data.restartRecovery();
      expect(data.completedDaysBefore, 3);
      expect(data.currentStreak, 0);
    });

    test('domain parser rejects paths masquerading as hostnames and malformed labels', () async {
      final data = AppData();
      expect(await data.addDomain('not a domain'), isFalse);
      expect(await data.addDomain('bad..example.com'), isFalse);
      expect(await data.addDomain('-invalid.example'), isFalse);
      expect(await data.addDomain('192.0.2.1'), isFalse);
      expect(data.customDomains, isEmpty);
    });
  });

  group('Localization catalog', () {
    test('the main app languages include navigation, protection disclosure, and relief content', () {
      for (final locale in AppStrings.supported) {
        final strings = AppStrings(locale);
        for (final key in ['home', 'protection', 'progress', 'activities', 'settings', 'protection_disclosure', 'relapse_body', 'quran_source']) {
          expect(strings.t(key), isNot(key), reason: '${locale.languageCode} is missing $key');
        }
      }
    });

    test('Urdu and Arabic are marked right-to-left', () {
      expect(AppStrings(const Locale('ur')).isRtl, isTrue);
      expect(AppStrings(const Locale('ar')).isRtl, isTrue);
      expect(AppStrings(const Locale('en')).isRtl, isFalse);
    });
  });
}
