# QA checklist

## Automated commands (Windows PowerShell)

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python tool\verify_project.py
flutter build apk --debug
```

A release build and AAB require a correctly configured release signing key for Play distribution.

## Manual Android checks

### Installation, layout, and language

- [ ] Install fresh app on API 23+ and current API 36; verify first-launch language picker and no crash.
- [ ] Switch English → Urdu → Arabic in Settings and back; confirm every tab, dialog, button, error, and FAQ changes language and text flows RTL for Urdu/Arabic.
- [ ] Try narrow and large screens, system font scaling, dark mode, keyboard open, and back navigation. Check domain input and reflection can scroll without clipping.
- [ ] Verify Android-installed Arabic/Urdu glyphs render (no missing squares); verify Quran/Hadith Arabic spelling and attribution.

### Recovery and offline activities

- [ ] Start recovery and verify first day, next-day streak, cumulative total, weekly and monthly views, and 1/3/7/14/30/60/90-day milestones.
- [ ] Save a goal/reflection, close/reopen the app, verify data persists, then test a setback/restart without shaming language.
- [ ] Complete memory sequence, arithmetic correct/incorrect cases, breathing countdown, focus pause/resume/finish, challenge, and reading page with airplane mode enabled.
- [ ] Confirm no activity requires a server and no network request occurs from game screens.

### VPN/DNS behavior

Use only benign, domain-level lookups. Do not visit adult content. Record device, Android version, DNS/private-DNS setting, and network for every result.

- [ ] Read the full disclosure, decline/accept the Android VPN prompt, and verify app state matches outcome.
- [ ] With protection on, resolve a known curated test domain using the phone's system resolver. Verify lookup fails, a blocked attempt is recorded locally, and notification appears if permission is granted.
- [ ] Resolve a benign allowed domain and verify it returns an address through Cloudflare DoT; check mobile data and Wi-Fi separately.
- [ ] Add a custom test domain and subdomain; verify immediate blocking; remove it and retest.
- [ ] Deny notifications, repeat a blocked lookup, verify filtering remains functional and no crash occurs.
- [ ] Revoke VPN from Android system settings, enable Airplane mode, switch Wi-Fi/mobile network, kill/restart the process, reboot, and disconnect another VPN. Confirm status and recovery behavior; document platform-specific limitations.
- [ ] Try Android Private DNS, a browser secure-DNS mode, IPv6-only networking, DNS-over-TCP fallback, a direct-IP URL, and another VPN. Confirm limitations are disclosed and do not call bypassed traffic “blocked.”
- [ ] Confirm no full URL/path or allowed-domain lookup is stored by STOP IT!, inspect the local blocked log, clear data, and verify the log is gone.

### Notifications, privacy, and signing

- [ ] Test Android 13+ notification permission allowed/denied and notification channel settings.
- [ ] Opt into the approximate 9 AM daily reminder, verify it after its scheduled time and after reboot/time-zone change, then opt out and verify the alarm stops.
- [ ] Confirm persistent foreground notification while VPN runs and removal when stopped.
- [ ] Check app-private storage and the built artifact for secrets, signing keys, debug logs, and unexpected permissions.
- [ ] Validate release APK/AAB signing with Play Console internal testing. Never publish a debug-signed bundle.

## Result recording

This repository was prepared without Flutter, Dart, JDK/Java, Android SDK, emulator, or device access. Consequently none of the Android-runtime boxes above, Flutter tests/analyzer, or Android builds have been run in this environment. Mark actual device/build results only after running the checklist on a real development machine.
