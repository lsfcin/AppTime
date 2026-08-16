# AppTime — Roadmap

Read the next milestone, implement it bullet by bullet. After a bullet is done, change the dash - to an x, and commit.

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

---

## Workspace drift, refiled from the wos ledger 2026-08-16

These were tracked in `/ROADMAP.md`, which was the wrong home: the files live here and no
workspace-level commit can touch them. The wos ledger's own rule is that a pointer to another
ROADMAP is a duplicate by definition. Counts regenerate in `/entropy.md`; never copy them here.

- 🟡 **directories over the fanout cap** — `lib/screens/analytics` (18), `lib/screens` (15),
  `lib/data` (14). Limits are `WARN_FILES=7` / `BLOCK_FILES=10` in `core/hooks/limits.env`.
  **A split only pays once each new directory declares itself with a `CONTEXT.md`**: the routing
  generator folds any directory under the warn back into its parent, so moving files without
  writing that file leaves the parent's table exactly as long. A split that does not shrink the
  parent table is the check being gamed, not answered.
- 🟢 **`CONTEXT.md` hand-lists 40 files under `## File Map`.** The routing block below it is
  generated from first-line comments and already owns inventory; the hand-written half is a second
  copy that goes stale silently. Delete it — but read it first, because a hand list sometimes
  exists to name files the generator cannot reach, and those need a generator fix rather than a
  deletion.
- 🟢 **no gate has ever been exercised on this repo.** The routing generator and the facade gate
  both know `index.dart`, but Dart/Flutter has never run through them here, and `flutter` is an
  undeclared dependency — `verify:fast` cannot run at all on a fresh clone. Expect the first pass
  to find generator bugs rather than file problems; that has been true in every repo so far.

Two hazards worth expecting, both learned the expensive way in `aiwbot` and `flows`:
a new subdirectory turns a flat import into a module boundary, so the facade gate starts firing on
imports that were legal the day before — re-export from the new facade rather than importing past
it. And **grep this ROADMAP for a filename before calling it dead**: `flows` nearly lost five
components that its own milestones had deliberately unwired and planned to reuse.
