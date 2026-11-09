# STOP-IT-APP
 STOP-IT-APP
# STOP IT! — private digital self-discipline companion

**Control your desires. Protect your mind. Remember Allah.**

This repository contains a Flutter Android application and its Kotlin local-DNS VPN service. It is a real starter release implementation—not a guarantee that every adult website, image, application, or route can be blocked. Protection is opt-in and uses Android's system VPN consent screen.

> **Gentle support, not shame:** recovery is personal and setbacks do not erase your worth. This app is not a substitute for professional mental-health care.

## What is in the app

- Five bottom-navigation sections: Home, Protection, Progress, Activities, and Settings.
- English, Urdu, and Arabic UI strings. Urdu and Arabic use right-to-left layout and Android's installed Arabic-script fonts.
- First-launch language selection and an in-app, affirmative VPN disclosure before protection is enabled.
- An optional Android `VpnService` that filters selected DNS lookups on-device. It uses a curated starter domain list plus the user's custom list and subdomains.
- A local log of **blocked domain names and timestamps** (up to 150 records), an immediate, throttled motivational notification when a block happens, and an optional inexact daily Quran reminder (about 9:00 AM) that can be switched off in Settings.
- Recovery start date, current streak, cumulative days across restarts, milestone display, weekly/monthly views, one personal goal, and a private daily reflection.
- Offline memory sequence, arithmetic quiz, guided breathing timer, five-minute focus timer, a practical discipline challenge, and Quran/Hadith reading card.
- Local-only data deletion and a privacy/limitations FAQ.
- No account, analytics SDK, advertising SDK, or cloud backup.

## How website filtering works—and what it cannot do

On Android, the user-approved `DnsFilterVpnService` configures a local VPN interface and only routes DNS packets addressed to its local resolver (`10.111.0.1`) through the app. The app parses IPv4/UDP DNS questions, matches the domain (including subdomains) against the built-in set and the editable private list, and returns an NXDOMAIN response for a match. A blocked domain and timestamp are recorded on the phone. Allowed DNS questions are forwarded using **DNS-over-TLS to Cloudflare at 1.1.1.1**; the TLS hostname is verified. This requires an internet connection for ordinary name lookups. The local VPN is not a remote VPN and ordinary web traffic is not forwarded to STOP IT! or Cloudflare.

Because a DNS resolver must see the name it resolves, Cloudflare can observe allowed domain names sent to its resolver. Those allowed lookups are encrypted in transit but are **not anonymous**. STOP IT! does not save allowed-domain lookups. Blocked-domain names and times are saved locally for the user's review. No full URLs, page paths, search terms, page contents, images, or video contents are collected by the app.

**Known limitations:** this is domain-level filtering, not content recognition. It cannot reliably block HTTPS URL paths, embedded/adult media served from an allowed domain, IP-address-only access, all IPv6 or DNS-over-TCP paths, or all apps' custom/encrypted DNS. Another VPN, private DNS, a proxy, a different resolver, a direct IP, a rooted/modified device, or uninstalling/turning off protection can bypass it. The starter domain list is not exhaustive and is not automatically updated. The app cannot identify adult images/videos by their content. Do not represent this as 100% protection or a substitute for device-level supervision.

The VPN can interrupt name resolution if the upstream resolver is unavailable. If a DNS-over-TLS request times out, the service returns a temporary DNS failure; it does not silently resolve that domain by an unencrypted fallback.

## Privacy and security

- State is held in the Android app's private `SharedPreferences` file. The app does not include internet-facing APIs, accounts, telemetry, or cloud sync.
- The app stores recovery start dates, previous recovery-day totals, language, one goal, the latest reflection, custom domains, and blocked-domain events. A person with access to the unlocked phone or app data could see that information.
- Allowed DNS queries are sent encrypted to Cloudflare Public DNS (`1.1.1.1` over TLS/853); the resolver may log/process queries under its own terms. Read the [current Cloudflare resolver privacy commitment](https://developers.cloudflare.com/1.1.1.1/privacy/public-dns-resolver/) before release and include it in the app's store/privacy disclosures.
- Android shows the standard VPN consent dialog. A persistent foreground-service notification is shown while protection is active. Android 13+ notification permission is requested so block alerts can be shown; notification delivery can still be disabled by the user or system.
- No Accessibility Service, broad installed-app inventory permission, device-admin control, hidden monitoring, secret reporting, or third-party VPN is used.
- `android/key.properties`, signing files, local SDK settings, and build output are excluded from Git.

## Project map

```text
lib/
  main.dart                  Flutter app, theme, locale setup
  theme.dart                 Dark emerald/gold design tokens
  models/app_data.dart       Local recovery state and input validation
  localization/strings.dart  Full 145-key English/Urdu/Arabic catalog
  services/native_bridge.dart Flutter ↔ Kotlin method channel
  screens/                   Five app sections and offline activity screens
  widgets/ui.dart             Reusable premium cards and controls
assets/content/app_*.arb      Full English, Urdu, Arabic ARB catalogs
android/app/src/main/kotlin/  MainActivity and local DNS VPN service
android/gradle/               Gradle wrapper
 test/                        Flutter unit/localization tests
 tool/verify_project.py       Dependency-free source/configuration checks
 docs/                         Privacy policy, store listing, manual test plan
```

## Versions and dependencies

- Flutter/Dart: use a current stable Flutter SDK (Dart 3.6 or later).
- Android application ID: `com.stopit.app`.
- Android `minSdk`: 23; `compileSdk` / `targetSdk`: 36.
- Android Gradle Plugin: 8.9.1; Gradle wrapper: 8.11.1; Kotlin Gradle plugin: 2.1.0.
- Runtime packages: only Flutter SDK (`flutter`, `flutter_localizations`). Development: `flutter_test`, `flutter_lints`.
- Android build requires JDK 17 and Android SDK Platform 36. This project does not contain a prebuilt APK/AAB or a release signing key.

## Beginner setup on Windows

### 1. Install the tools once

1. Install **Git for Windows**, **Visual Studio Code**, and **Android Studio**.
2. Install the current **Flutter stable SDK** from Flutter's official Windows installation guide. Add its `bin` folder to your Windows `PATH` (for example, `C:\src\flutter\bin`).
3. In Android Studio → **SDK Manager**, install Android SDK Platform 36, Android SDK Build-Tools, Android SDK Command-line Tools, and Platform-Tools. In **SDK Tools**, install Android SDK Command-line Tools and Android Emulator if desired.
4. Open a new PowerShell window and accept Android licenses:

```powershell
flutter doctor -v
flutter doctor --android-licenses
```

Resolve any red errors in `flutter doctor -v` before building. Flutter uses JDK 17; Android Studio's bundled JDK is generally suitable.

### 2. Open the project and install dependencies

Download/clone this repository, then open the `STOP-IT-APP` folder in VS Code (**File → Open Folder**). In the VS Code terminal (PowerShell):

```powershell
cd C:\path\to\STOP-IT-APP
flutter pub get
flutter analyze
flutter test
python tool\verify_project.py
```

Replace `C:\path\to\STOP-IT-APP` with the folder where you saved it. The `flutter test` command runs the Dart tests; the Python command checks catalog/configuration consistency but does **not** compile the app.

### 3. Run on a physical Android phone

1. On the phone, open Settings → About phone and tap **Build number** seven times to enable Developer options.
2. In Developer options, turn on **USB debugging**. Connect the unlocked phone to the computer and accept its debugging prompt.
3. Check that Flutter sees the phone, then run:

```powershell
flutter devices
flutter run
```

In the app choose English, اردو, or العربية. To test protection, open **Protection → Turn on protection**, read the disclosure, tap **I understand. Continue**, and approve Android's VPN prompt. Android permits one active VPN per user/profile; another VPN may need to be disconnected. Try a domain in the built-in list (for example `examplepornsite.com` is **not** a test domain; use an actually listed host such as `pornhub.com`) and verify an NXDOMAIN/block event. Also try a normal site and confirm it resolves. Do not test by visiting adult content; a DNS lookup or `nslookup` is enough.

To stop, use the app's Protection page or Android's VPN settings. If Android or another VPN disconnects it, reopen the app and refresh status. Protection is only active while the VPN service is active.

### 4. Build an installable APK

```powershell
flutter build apk --release
```

The output is `build\app\outputs\flutter-apk\app-release.apk`. Install it on a connected device with:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Before creating a Play Store release, set up a private upload key as described below; without it the local release build uses the debug signing configuration and is **not suitable for Play publishing**.

### 5. Create an upload key and Play Store AAB

Keep the upload key safe and backed up. Losing it can prevent future app updates. Never send the key or passwords in chat, commit them, or put them in the ZIP/repository.

```powershell
keytool -genkey -v -keystore android\stop-it-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias stopit-upload
```

Create `android\key.properties` in Notepad (this file is Git-ignored) and fill in the values you chose. The `storeFile` path is relative to `android\app`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=stopit-upload
storeFile=../stop-it-upload.jks
```

Then build and inspect the bundle:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

AAB output: `build\app\outputs\bundle\release\app-release.aab`. Google Play App Signing is recommended: upload this signed AAB through Play Console's internal testing track first. Do not share the upload key; only upload the generated AAB to your own Play Console account.

## GitHub

This project is GitHub-ready, but **no new GitHub repository has been created and nothing has been uploaded by this delivery**. The working repository here is `hamrazashfaq/STOP-IT-APP`; the suggested `stop-it-android-app` name is not an already-confirmed destination. To publish it yourself after choosing the destination, use GitHub's **New repository** page, create an empty repository, then in PowerShell run:

```powershell
cd C:\path\to\STOP-IT-APP
git status
git add .
git commit -m "Build STOP IT Android app"
git remote -v
```

If using your existing GitHub clone, push only the Arena working branch when asked to preserve this session's branch:

```powershell
git push origin arena/0d24a82f-stop-it-app
```

If you created a **new empty** destination repository and want to push this existing branch there, first confirm its URL, then replace the example username below with your own GitHub username:

```powershell
git remote add origin https://github.com/YOUR-USERNAME/stop-it-android-app.git
git push -u origin arena/0d24a82f-stop-it-app
```

Do not run `git remote add` if `origin` already exists. Do not add `.jks`, `key.properties`, `android/local.properties`, `build/`, or browsing records to Git. Check `git status` before every commit.

## Islamic references and translations

The Quran reminder is Qur'an 96:14: Arabic `أَلَمْ يَعْلَمْ بِأَنَّ اللَّهَ يَرَىٰ`; English “Does he not know that Allah sees?” (Saheeh International); Urdu translation credited in-app to Muhammad Junagarhi. The reminder is based on the verse, not an invented quote. The Hadith is the authentic narration about true strength being self-control in anger, cited as Sahih al-Bukhari 6114 / Sahih Muslim 2609. Arabic and English are included in-app; Urdu is a concise translation. Sources are listed in `docs/CONTENT_SOURCES.md`. Have a qualified reviewer check wording and licensing before wider publication.

## Google Play preparation (not an approval promise)

- Use the application ID `com.stopit.app`; do not change it after publishing.
- Play requires a currently compliant target API. This project targets API 36 for phone/tablet submissions as of **9 November 2026**; re-check policy on the day you upload.
- Complete Play Console's VPN Service declaration and explain the local DNS filtering purpose. Google limits VpnService use to eligible core functionality/use cases, requires clear store-listing documentation and encryption to the VPN endpoint, and requires a prominent in-app disclosure/affirmative consent where applicable. A self-control DNS filter may need policy review; **approval is not guaranteed**. See the official links in `docs/PLAY_STORE.md`.
- Provide a public privacy-policy URL and accurately complete Data safety. Be clear that blocked domain names/times are stored on-device and allowed DNS names are sent over encrypted DNS-over-TLS to Cloudflare, which may see them. Read Cloudflare's current resolver policy before release.
- Prepare 512×512 launcher art and a 1024×500 feature graphic, screenshots on real Android devices, app category, age/content rating, contact email, and a short video showing the in-app VPN disclosure and consent.
- Start with Play internal testing; verify VPN activation/revocation, notification behavior, DNS allowed/blocked tests, offline screens, and data deletion on real devices. Do not imply full content blocking.
- Store listing draft and permission/data explanations: `docs/PLAY_STORE.md`. Privacy-policy template: `docs/PRIVACY_POLICY.md`.

## Verification status in this delivery

- **Executed here:** `python3 tool/verify_project.py` (source/localization/manifest/wrapper integrity checks).
- **Not executed here:** `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, Android/Kotlin compilation, APK/AAB builds, emulator/physical-device tests, notification runtime checks, or Play Console review. The environment used to prepare these files has no Flutter, Dart, Java/JDK, Android SDK, or connected Android device.
- Automated Dart tests are included in `test/app_data_test.dart`; run them on a machine with Flutter installed. A manual verification checklist is in `docs/TEST_PLAN.md`.

Please treat the first build as a test release, not a published or fully QA-verified production build.
