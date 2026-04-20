# AppTime — Roadmap

Read the next milestone, implement it bullet by bullet. After a bullet is done, change the dash - to an x, and commit.

## Milestone — Security and privacy check

x Point core security issues apps may impose on users

x Assess which of those are relevant to our app/context

x Add all relevant points to this milestone and go fix or propose solutions, one by one.

### Relevant issues and fixes

x `android:usesCleartextTraffic="false"` — declare in AndroidManifest; proves to Play scanners no network communication is possible

x Data retention — auto-delete SharedPreferences keys older than 90 days on app start; prevents unbounded accumulation of sensitive usage history

x Delete all data — add a "Delete all data" action in Settings so the user can wipe their history at any time (right to erasure, expected by Play reviewers)

x Privacy policy — draft a minimal policy (data stays on-device, no network, no third parties); host on GitHub Pages; link from Settings and store listing
  x Hosted at https://lsfcin.github.io/apptime/privacy_policy.html

x Overlay clickjacking — verify FLAG_NOT_TOUCHABLE is set on the overlay window; confirm overlay cannot intercept user input (already implemented — mark after verification)

x Encrypted storage — deferred post-launch; EncryptedSharedPreferences requires migrating both Flutter plugin and Kotlin service; revisit if Play rejects

x Perform a major code review checking for possible hacker/malicious activities. Injections, don't know, it is not my area, but we must review our code thorouglhy to guarantee with the best of our knowledge that our app is safe. If you find any points then do not fix it yet, place bullets here.

### Code review findings

x Dead permission `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` in AndroidManifest — declared but never called in code. Play Store reviewers will demand justification for every dangerous permission; remove it.

x `BootReceiver` exported without `android:permission` guard — `BOOT_COMPLETED` is a protected broadcast (only OS can send it), but `QUICKBOOT_POWERON` is a vendor-custom action; any app on the device could broadcast it and unexpectedly start MonitoringService. Fix: add `android:permission="android.permission.RECEIVE_BOOT_COMPLETED"` to the receiver declaration in the manifest.

x `parseDisabledApps` swallows all JSON exceptions silently returning `emptySet()` — corrupted or tampered SharedPreferences data (rooted device) would silently re-enable the overlay on all apps the user disabled. Fix: validate that every element of the decoded array is a non-empty string matching a package-name pattern before trusting it.


## Milestone — Prepare to PlayStore submission

### Checklist

#### 0. Check legal concerns
x Once launched we'll expose the app to everyone, first review what issues may imply in legal concerns
x Consider a launch route that protects us, if there is not, it is fine
x Define protection strategy
x Build all materials/documents, manifests, don't know, what you can so we avoid being sued, I have no money or energy to handle that

**Strategy:** local-only architecture means LGPD exposure is minimal (no data leaves device). Key protections implemented:
- Privacy policy live at https://lsfcin.github.io/apptime/privacy_policy.html
- Disclaimer tile in Settings (not medical advice, not a medical device)
- Scientific claims softened from definitive to hedged ("may impair", "may spike")
- Play Console Data Safety form: mark "no data collected", "no account required"
- No INTERNET permission in manifest — reviewers can verify network-free claim instantly

#### 1. App identity & metadata
x Set a real `applicationId` (e.g. `com.lsf.apptime`) and confirm it is final — it cannot change after publish
  - Using `com.lsf.apptime` — confirmed final (changed from com.lucasf.apptime to bypass a MIUI install block)
x Bump `versionName` to `1.0.0` and `versionCode` to `1` in `build.gradle`
  - Set via pubspec.yaml `version: 1.0.0+1`
x Replace placeholder app name in `strings.xml` / `AndroidManifest.xml` (`AppTime`)
x Replace `ic_launcher` placeholder icon with final adaptive icon (foreground + background layers, 108dp safe zone)
x Add a short app description in PT-BR and EN (30 chars) and a long description (4 000 chars max) for the store listing
  - Written in docs/store_listing.md — ready to paste into Play Console

#### 2. Signing
- Create a release keystore (`keytool -genkey ...`) and store it outside the repo
- Configure `signingConfigs.release` in `build.gradle` (read credentials from `local.properties` or env vars — never commit the keystore)
- Build a signed AAB: `flutter build appbundle --release`

#### 3. Permissions audit
x Confirm every permission in `AndroidManifest.xml` has a visible rationale shown to the user (onboarding covers `SYSTEM_ALERT_WINDOW` + `PACKAGE_USAGE_STATS`)
x `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` — foregroundServiceType="specialUse" declared on both services with subtype properties
x Remove any unused permissions — `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` removed

#### 4. Privacy policy
x PlayStore requires a privacy policy URL for apps that request sensitive permissions (`PACKAGE_USAGE_STATS`, `SYSTEM_ALERT_WINDOW`)
x Draft a minimal policy (data stays on-device, no network calls, no analytics); host it (GitHub Pages or similar)
x Add the URL to the store listing and optionally link it from the app's Settings screen
  - Live at https://lsfcin.github.io/apptime/privacy_policy.html

#### 5. Store listing assets
- Feature graphic: 1024 × 500 px
- Phone screenshots: minimum 2, recommended 4–8 (use emulator or device)
- Short and full descriptions translated to both PT-BR and EN
- Content rating questionnaire (IARC) — likely "Everyone"

#### 6. Target API & compliance
x `targetSdkVersion` must be ≥ 34 (current Play requirement for new apps) — uses `flutter.targetSdkVersion` (Flutter 3.x defaults to 35)
x Verify `compileSdkVersion` ≥ 35 — uses `flutter.compileSdkVersion`
x Declare `android:exported` on every `<activity>`, `<service>`, and `<receiver>` in the manifest — all declared

#### 7. Release track
- Create a Google Play Developer account (one-time $25 fee)
- Upload the AAB to the **Internal testing** track first and install via Play to verify signing + permissions
- Promote to **Closed testing** (beta) before production if desired
- Production review typically takes 1–3 days for a new app

#### 8. Post-launch minimum
- Set up crash reporting (Firebase Crashlytics free tier, or just monitor Play's built-in ANR/crash dashboard)
- Prepare a `1.0.1` patch plan for any day-one issues