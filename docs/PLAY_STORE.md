# Google Play listing and release checklist

**Package:** `com.stopit.app`
**Proposed category:** Health & Fitness (confirm fit with current Play Console category list)
**Current app target:** API 36 / Android 16 for phone/tablet. Check current requirements before every upload.

## Draft store listing

**App name:** STOP IT! — Self-Control & Wellbeing
**Short description (under 80 characters):** Private DNS filtering, recovery tools and faith-based reminders.

**Full description draft:**

> STOP IT! helps you make more intentional digital choices with optional, on-device DNS domain filtering, private recovery tracking, gentle Quran and Hadith reminders, and offline activities.
>
> **Optional domain protection** — When you turn it on and approve Android's VPN permission, STOP IT! checks DNS domain requests against a built-in starter blocklist and domains you add yourself. A blocked domain lookup is stopped, and the domain and time are recorded locally. Protection is visible and can be turned off at any time.
>
> **Important limitations:** STOP IT! filters domain lookups; it does not scan page contents or block every adult site, image, video, app, direct IP address, encrypted/custom DNS request, or traffic in another VPN. Filtering may be bypassed. The built-in list is not exhaustive.
>
> **Private recovery tools** — Track a recovery streak and goals, reflect privately, restart without shame, choose an optional local daily Quran reminder, and work through simple offline memory, number, breathing, and focus activities.
>
> **Faith reminders** — Read Quran 96:14 and a source-cited authentic reminder. English, Urdu, and Arabic interfaces are available.
>
> **Data and DNS** — Recovery notes, goals, custom domains, and blocked domain names/times stay in app-private storage on your device. To resolve allowed domain names, DNS questions are encrypted to Cloudflare Public DNS at 1.1.1.1; Cloudflare can see those requested names. STOP IT! has no account, analytics, ads, or publisher-operated browsing-history server. See [public privacy policy URL].
>
> STOP IT! is a self-discipline aid, not professional treatment and not a guarantee against exposure. Please use the app's settings and review the privacy policy before enabling protection.

**Contact email:** [insert publisher support email]
**Privacy policy URL:** [publish `PRIVACY_POLICY.md` at a stable public HTTPS URL after completing it]
**Feature graphic/icon/screenshots:** create and capture genuine assets from a tested app build; do not use fabricated screenshots.

## Permissions and prominent disclosure

| Permission/API | Why it is used | What to say to users |
| --- | --- | --- |
| `android.permission.INTERNET` | Establish encrypted DNS-over-TLS to Cloudflare Public DNS for domains not blocked locally. | Allowed domain names are sent to Cloudflare to resolve; the resolver can see them. |
| `VpnService` / `BIND_VPN_SERVICE` | Route DNS packets to the app's local resolver and filter domains only when the user enables protection. | The service does not inspect page content or route ordinary web traffic through a remote VPN. Blocked domains/times are stored locally. Android's system VPN consent is required. |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE` | Keep a user-started protection service visible and running. | A persistent notification indicates protection is active. |
| `POST_NOTIFICATIONS` | Display the optional immediate alert when a blocked lookup is detected and the user's opt-in daily reminder. | Denying notifications does not stop basic filtering; Android may suppress alerts. |
| `RECEIVE_BOOT_COMPLETED` | Reschedule only the explicitly enabled local daily reminder after device reboot/time change. | No browsing data is transmitted; reminder scheduling is local and user-controlled. |

The live first-enable dialog is in the normal app flow and requires an explicit tap before Android's VPN consent prompt. Keep that disclosure synchronized with this table and the privacy policy if implementation changes.

## VPN policy and launch gates

Google Play's official [VpnService policy guidance](https://support.google.com/googleplay/android-developer/answer/12564964?hl=en) and [sensitive data / permissions policy](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en) should be re-read immediately before submission. The Play VpnService declaration, store description, review video, privacy policy, in-app disclosure, and Data safety answers must all describe the real DNS behavior consistently. Google limits VpnService to eligible core functionality/use cases, expects clear documentation and encrypted traffic to the VPN endpoint, and requires prominent consent where sensitive information is accessed. A personal self-control DNS filter may not fit every Play eligibility category; approval is not guaranteed. Ask Play support or a policy specialist if uncertain before investing in release.

Target API requirements change yearly. Official [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en) specify Android 16 / API 36 for new phone/tablet apps and updates from August 31, 2026. This source was checked on November 9, 2026; verify it again before upload.

Before submitting:

- [ ] Build and test a signed release on more than one supported Android version and screen size.
- [ ] Review every Android permission and the VPN use case against current policy.
- [ ] Complete the VpnService declaration; provide the requested short video showing first launch, full disclosure, opt-in, and actual protection.
- [ ] Host a complete privacy policy and provide a support email.
- [ ] Complete Data safety accurately. Disclose the on-device blocked-domain history and Cloudflare DNS processing; do not assume that “local VPN” means no domain leaves the phone.
- [ ] Verify Quran/Hadith references, translation attributions, typography, and permission disclosures.
- [ ] Add age/content rating, store icon, feature graphic, screenshots, and internal-test instructions.
- [ ] Use Play App Signing and keep the upload key/password in a secure offline backup.
- [ ] Release to internal testers first. Play approval, eligibility, and availability are Google decisions, not guaranteed by this project.
