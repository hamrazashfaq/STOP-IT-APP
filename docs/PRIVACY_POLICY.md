# STOP IT! Privacy Policy — publication template

**Last updated:** [insert date]
**Publisher/contact:** [insert legal publisher name and support email]
**Public URL:** [host this policy on a public website before Play submission]

STOP IT! is designed to keep recovery and protection records on your Android device. This policy must be reviewed and completed by the publisher before release; it is a template, not legal advice.

## Information handled on your device

STOP IT! stores app preferences, selected language, a recovery start date and accumulated recovery-day count, one personal goal, the latest daily reflection, domains you add to your personal blocklist, and up to 150 blocked-domain names with timestamps. These items are stored in the app's private Android preferences. They are not uploaded to an account operated by the publisher. Someone who can access your unlocked phone, backups, or app data may be able to see them.

You can remove saved information from Settings → Delete all my data. Android cloud backup and device-transfer backup are disabled for the app. Uninstalling the app removes its app-private data. Android VPN authorization is managed by Android and can be revoked in system settings.

## DNS and network processing

When protection is enabled, Android routes DNS packets addressed to the app's local DNS endpoint through a local VPN interface. STOP IT! compares domain names with its local blocklist. For a blocked domain, the app returns a local DNS failure and stores that domain and the time on the device. It does not store full URLs, page paths, search terms, or the content of pages/images/videos.

For an allowed domain, the DNS question is forwarded using encrypted DNS-over-TLS to **Cloudflare Public DNS at 1.1.1.1**. Cloudflare necessarily receives the requested domain names and network metadata to answer DNS queries and may process them under its own current terms/privacy practices. Review Cloudflare's [current Public DNS Resolver privacy commitment](https://developers.cloudflare.com/1.1.1.1/privacy/public-dns-resolver/) before publishing. STOP IT! does not save the allowed-domain query history and does not send it to a STOP IT! server. Ordinary web traffic is not tunneled through a remote STOP IT! server.

## Permissions

- **Internet:** required to resolve permitted domain lookups using the encrypted external DNS resolver.
- **Android VPN (`VpnService`):** routes the local resolver's DNS traffic through the app when the user explicitly activates protection. Android shows a system VPN consent dialog. Protection is visible and can be stopped by the user.
- **Notifications:** Android 13 and later can ask permission to display blocked-access reminders and the optional daily Quran reminder. Denying it does not grant the app access to other notification content. Daily reminders use an inexact on-device alarm around 9:00 AM and can be disabled in Settings.
- **Foreground service:** keeps the user-requested VPN service running and visible while protection is active.

The app does not request location, contacts, microphone, camera, Accessibility, device-admin, or broad app-inventory permissions.

## Data sharing, advertising, analytics, and accounts

The project contains no account service, advertising SDK, analytics SDK, or publisher-operated cloud endpoint. Allowed DNS questions are shared with Cloudflare as described above. There is no social sharing or secret reporting. Users must still check the current Cloudflare policy and the actual Play Data safety definitions before publishing.

## Security and retention

Records stay in private app storage and blocked history is capped at 150 entries. The app does not encrypt local preference values with an app-managed encryption key; Android app sandboxing protects ordinary access but is not protection against a compromised/rooted device or a person using the unlocked phone. Do not promise stronger protection than this. DNS-over-TLS encrypts the connection to the resolver, but does not hide the requested domain from that resolver.

## Children, changes, and contact

[Publisher: add your age suitability/children's privacy position.] This app is not designed to collect information from children. The publisher may revise this policy; update the date and notify users as legally required. For privacy questions or deletion requests, contact [support email].
