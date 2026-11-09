#!/usr/bin/env python3
"""Dependency-free structural checks for this repository (not a Flutter build/test)."""
import json
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
errors = []

def check(condition, message):
    if not condition:
        errors.append(message)

def read(path):
    return (ROOT / path).read_text(encoding='utf-8')

# Verify hand-authored Dart translation catalogs and ARB mirrors stay aligned.
strings = read('lib/localization/strings.dart')
translations = {}
for lang in ('en', 'ur', 'ar'):
    match = re.search(r"static const _%s = <String, String>\{(.*?)\n  \};" % lang, strings, re.S)
    check(match is not None, f'missing {lang} Dart translation map')
    entries = dict(re.findall(r"'([^']+)':'((?:\\.|[^'\\])*)'", match.group(1))) if match else {}
    translations[lang] = entries
    arb_path = ROOT / f'assets/content/app_{lang}.arb'
    try:
        arb = json.loads(arb_path.read_text(encoding='utf-8'))
        arb.pop('@@locale', None)
        check(arb == entries, f'{arb_path.name} differs from the Dart translation catalog')
    except (OSError, json.JSONDecodeError) as error:
        check(False, f'invalid {arb_path.name}: {error}')
check(bool(translations['en']), 'English translation catalog is empty')
check(set(translations['en']) == set(translations['ur']) == set(translations['ar']), 'localized catalogs have inconsistent keys')
refs = set()
for path in (ROOT / 'lib').rglob('*.dart'):
    refs.update(re.findall(r"\.t\('([^']+)'\)", path.read_text(encoding='utf-8')))
check(refs <= set(translations['en']), f'UI references missing strings: {sorted(refs - set(translations["en"]))}')

# Validate project metadata and Android's least-privilege VPN service wiring.
pubspec = read('pubspec.yaml')
check("flutter_localizations:" in pubspec and "name: stop_it" in pubspec, 'Flutter localization or project metadata missing')
manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml').getroot()
android = '{http://schemas.android.com/apk/res/android}'
permissions = {node.attrib.get(android + 'name') for node in manifest.findall('uses-permission')}
check('android.permission.INTERNET' in permissions, 'Android DNS transport needs INTERNET permission')
check('android.permission.RECEIVE_BOOT_COMPLETED' in permissions, 'Opt-in daily reminders must be restored after restart')
vpn_service = next((node for node in manifest.findall('.//service') if node.attrib.get(android + 'name') == '.DnsFilterVpnService'), None)
check(vpn_service is not None and vpn_service.attrib.get(android + 'exported') == 'true' and vpn_service.attrib.get(android + 'permission') == 'android.permission.BIND_VPN_SERVICE', 'VPN service must be system-bindable only through its signature permission')
check('android.permission.QUERY_ALL_PACKAGES' not in permissions, 'App must not request broad installed-app inventory')
check((ROOT / 'android/app/src/main/kotlin/com/stopit/app/DailyReminderReceiver.kt').is_file(), 'Daily reminder receiver missing')
application = manifest.find('application')
check(application is not None and application.attrib.get(android + 'allowBackup') == 'false', 'Sensitive local state must be excluded from Android backup')
check('android:usesCleartextTraffic="false"' in read('android/app/src/main/AndroidManifest.xml'), 'Cleartext Android network traffic should be disabled')
service = read('android/app/src/main/kotlin/com/stopit/app/DnsFilterVpnService.kt')
for marker in ('addDnsServer("10.111.0.1")', 'addRoute("10.111.0.1", 32)', 'protect(raw)', 'cloudflare-dns.com', 'recordBlocked(domain)', 'makeDnsError(dns)'):
    check(marker in service, f'VPN implementation marker missing: {marker}')
check('*.jks' in read('.gitignore') and 'android/key.properties' in read('.gitignore'), 'signing secrets are not ignored')
check((ROOT / 'android/gradlew.bat').is_file() and (ROOT / 'android/gradle/wrapper/gradle-wrapper.jar').is_file(), 'Gradle wrapper files missing')

if errors:
    print('FAIL')
    for error in errors:
        print(f'- {error}')
    sys.exit(1)
print(f'PASS: {len(translations["en"])} EN/UR/AR strings, {len(refs)} UI string references, Android manifest, DNS/VPN wiring, and signing-file safeguards.')
print('This check does not compile Flutter/Kotlin code or test an Android device.')
