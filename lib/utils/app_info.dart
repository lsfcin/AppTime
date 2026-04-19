import 'package:flutter/material.dart';

// ─── Three-tier naming + classification strategy ──────────────────────────────
//
// TIER 1 — Android PackageManager (primary, most reliable)
//   Queried at runtime via getInstalledApps() in MainActivity.kt.
//   Filters FLAG_SYSTEM == 0 → user-installed apps only.
//   Label = the display name the user sees in their launcher.
//   Stored in _appLabels (MonitoringScreen). Handles ~95 % of apps.
//
// TIER 2 — Static maps kAppLabels / kAppColors
//   Overrides or supplements PM for:
//   • Apps with confusing internal names (e.g. com.google.android.apps.tachyon → "Meet")
//   • Brand colors (PM does not provide these)
//   • Historic usage data for apps that were later uninstalled
//
// TIER 3 — labelForApp() fallback
//   Last resort for packages absent from both Tier 1 and Tier 2.
//   Strips TLD / vendor / generic segments, capitalises the brand name.
//
// CLASSIFICATION (decides whether an app appears in lists / charts)
//   isLauncherPkg() — home-screen launchers: counted but not listed
//   isSystemPkg()   — OS daemons / services: suppressed entirely
//   The PackageManager FLAG_SYSTEM filter in Kotlin handles most system apps.
//   isSystemPkg() catches the remainder (GMS, sync adapters, STK, etc.).
//   Rule of thumb for new strange packages:
//     • If PM has loaded and the package is NOT in _appLabels → background/system
//       → _showInList() already excludes it (see MonitoringScreen).
//     • If it still appears, add it to the isSystemPkg() patterns below.
//
// ─────────────────────────────────────────────────────────────────────────────

// ─── Brand colors ─────────────────────────────────────────────────────────────
const kAppColors = <String, Color>{
  'com.whatsapp':                            Color(0xFF25D366),
  'com.instagram.android':                   Color(0xFFFF80AB),
  'com.instagram.barcelona':                 Color(0xFF000000), // Threads — black icon
  'com.tinder':                              Color(0xFFFE3C72),
  'org.telegram.messenger':                  Color(0xFF2AABEE),
  'com.spotify.music':                       Color(0xFF168D3F),
  'com.google.android.apps.maps':            Color(0xFF009688),
  'com.android.chrome':                      Color(0xFF4285F4),
  'com.google.android.youtube':              Color(0xFFFF0000),
  'com.supercell.clashroyale':               Color(0xFF2B59C3),
  'com.supercell.clashofclans':              Color(0xFFFBBC04),
  'com.bumble.app':                          Color(0xFFFFC629),
  'com.openai.chatgpt':                      Color(0xFF000000), // ChatGPT — black icon
  'com.nu.production':                       Color(0xFF8A05BE),
  'com.studiosol.cifraclub':                 Color(0xFFFF6600),
  'com.google.android.keep':                 Color(0xFFFF7043),
  'com.lucasf.apptime':                      Color(0xFF6366F1),
  'com.google.android.gm':                   Color(0xFFD44638),
  'com.facebook.katana':                     Color(0xFF1877F2),
  'com.miui.home':                           Color(0xFF78909C),
  'com.google.android.apps.messaging':       Color(0xFF1A73E8),
  'br.com.brainweb.ifood':                   Color(0xFFEA1D2C),
  'com.android.deskclock':                   Color(0xFF607D8B),
  'com.google.android.googlequicksearchbox': Color(0xFFDB4437),
  'com.google.android.apps.bard':            Color(0xFFF48FB1),
  'com.google.android.apps.aistudio':       Color(0xFF000000), // AI Studio — black icon
  'com.google.android.apps.docs':            Color(0xFF1565C0),
  'com.ovelin.guitartuna':                   Color(0xFFAA00FF),
  'com.stremio.one':                         Color(0xFF26C6DA),
  'br.com.bradseg.segurobradescosaude':      Color(0xFFCC092F),
  'org.mozilla.firefox':                     Color(0xFFFF9500),
  // ── Additional common apps ──────────────────────────────────────────────────
  'com.brave.browser':                       Color(0xFFFF5500),
  'com.google.android.calendar':             Color(0xFF1A73E8),
  'com.discord':                             Color(0xFF5865F2),
  'br.com.bb.android':                       Color(0xFFFFD700),
  'com.amazon.mShop.android.shopping':       Color(0xFFFF9900),
  'com.mercadolibre':                        Color(0xFFFFE600),
  'com.picpay':                              Color(0xFF11C76F),
  'br.com.xp.investimentos':                 Color(0xFF005AA3),
  'com.rico.android':                        Color(0xFF0071BC),
  'com.sympla.app':                          Color(0xFF6B2D8B),
  'com.google.android.apps.youtube.music':   Color(0xFFFF0000),
  'com.netflix.mediaclient':                 Color(0xFFE50914),
  'com.linkedin.android':                    Color(0xFF0077B5),
  'com.twitter.android':                     Color(0xFF1DA1F2),
  'com.snapchat.android':                    Color(0xFFFFFC00),
  'com.reddit.frontpage':                    Color(0xFFFF4500),
  'com.pinterest':                           Color(0xFFE60023),
  'com.shazam.android':                      Color(0xFF1DBFFF),
  'com.duolingo':                            Color(0xFF58CC02),
  'com.google.android.apps.translate':       Color(0xFF4285F4),
  'com.todoist.android.Todoist':             Color(0xFFDB4035),
  'com.notion.id':                           Color(0xFF000000),
  'com.ubercab':                             Color(0xFF000000),
  'br.com.99app.android':                    Color(0xFFFFD500),
  'com.ifood.driver':                        Color(0xFFEA1D2C),
  'com.google.android.apps.photos':          Color(0xFF4285F4),
  'com.paypal.android.p2pmobile':            Color(0xFF003087),
  'com.google.android.apps.finance':         Color(0xFF34A853),
  'com.google.android.apps.tachyon':         Color(0xFF00897B), // Google Meet
};

const kAppLabels = <String, String>{
  'com.whatsapp':                            'WhatsApp',
  'com.instagram.android':                   'Instagram',
  'com.instagram.barcelona':                 'Threads',
  'com.tinder':                              'Tinder',
  'org.telegram.messenger':                  'Telegram',
  'com.spotify.music':                       'Spotify',
  'com.google.android.apps.maps':            'Maps',
  'com.android.chrome':                      'Chrome',
  'com.google.android.youtube':              'YouTube',
  'com.supercell.clashroyale':               'Clash Royale',
  'com.supercell.clashofclans':              'Clash of Clans',
  'com.bumble.app':                          'Bumble',
  'com.openai.chatgpt':                      'ChatGPT',
  'com.nu.production':                       'Nubank',
  'com.studiosol.cifraclub':                 'CifraClub',
  'com.google.android.keep':                 'Keep',
  'com.lucasf.apptime':                      'AppTime',
  'com.google.android.gm':                   'Gmail',
  'com.facebook.katana':                     'Facebook',
  'com.miui.home':                           'Início',
  'com.google.android.apps.messaging':       'Messages',
  'br.com.brainweb.ifood':                   'iFood',
  'com.android.deskclock':                   'Relógio',
  'com.google.android.googlequicksearchbox': 'Google Search',
  'com.google.android.apps.bard':            'Gemini',
  'com.google.android.apps.aistudio':       'AI Studio',
  'com.google.android.apps.docs':            'Docs',
  'com.ovelin.guitartuna':                   'GuitarTuna',
  'com.stremio.one':                         'Stremio',
  'br.com.bradseg.segurobradescosaude':      'Bradesco Saúde',
  'org.mozilla.firefox':                     'Firefox',
  // ── Additional common apps ──────────────────────────────────────────────────
  'com.brave.browser':                       'Brave',
  'com.google.android.calendar':             'Google Calendar',
  'com.discord':                             'Discord',
  'br.com.bb.android':                       'Banco do Brasil',
  'com.amazon.mShop.android.shopping':       'Amazon Shopping',
  'com.mercadolibre':                        'Mercado Livre',
  'com.picpay':                              'PicPay',
  'br.com.xp.investimentos':                 'XP Investimentos',
  'com.rico.android':                        'Rico',
  'com.sympla.app':                          'Sympla',
  'com.google.android.apps.youtube.music':   'YouTube Music',
  'com.netflix.mediaclient':                 'Netflix',
  'com.linkedin.android':                    'LinkedIn',
  'com.twitter.android':                     'X (Twitter)',
  'com.snapchat.android':                    'Snapchat',
  'com.reddit.frontpage':                    'Reddit',
  'com.pinterest':                           'Pinterest',
  'com.shazam.android':                      'Shazam',
  'com.duolingo':                            'Duolingo',
  'com.google.android.apps.translate':       'Google Translate',
  'com.todoist.android.Todoist':             'Todoist',
  'com.notion.id':                           'Notion',
  'com.ubercab':                             'Uber',
  'br.com.99app.android':                    '99',
  'com.google.android.apps.photos':          'Google Photos',
  'com.paypal.android.p2pmobile':            'PayPal',
  'com.google.android.apps.finance':         'Google Finance',
  'com.google.android.apps.tachyon':         'Meet',            // internal codename: Tachyon
};

Color colorForApp(String pkg) => kAppColors[pkg] ?? const Color(0xFFB0BEC5);

// Segments that carry no brand information and should be stripped when
// deriving a fallback label from a package name (Tier 3).
const _kTld      = {'com', 'org', 'net', 'io', 'br', 'uk', 'de', 'fr', 'co'};
const _kNoise    = {'android', 'app', 'apps', 'mobile', 'production', 'release',
                    'mediaclient', 'frontpage', 'katana', 'barcelona'};
// Generic English nouns that describe a category, not a brand.
const _kGeneric  = {'music', 'messenger', 'messages', 'browser', 'player',
                    'service', 'manager', 'provider', 'launcher', 'home',
                    'camera', 'gallery', 'notes', 'note', 'calendar', 'mail',
                    'clock', 'dialer', 'phone', 'contacts', 'photos', 'video',
                    'wallet', 'store', 'market', 'search', 'assistant', 'one'};

/// Returns the best display label for a package name.
/// Tier 2 (kAppLabels) → Tier 3 fallback (heuristic from package ID).
String labelForApp(String pkg) {
  if (kAppLabels.containsKey(pkg)) return kAppLabels[pkg]!;

  final segments = pkg.split('.');

  // Strip TLDs and noise from both ends, keep brand-like segments.
  final meaningful = segments
      .where((s) => !_kTld.contains(s) && !_kNoise.contains(s) && s.length > 1)
      .toList();

  if (meaningful.isEmpty) return segments.last;

  // Prefer the first segment that is NOT a generic category word.
  // e.g. ['spotify', 'music'] → 'spotify'; ['telegram', 'messenger'] → 'telegram'
  final brand = meaningful.firstWhere(
    (s) => !_kGeneric.contains(s.toLowerCase()),
    orElse: () => meaningful.first,
  );

  // Capitalise first letter only (preserve camelCase if present).
  return '${brand[0].toUpperCase()}${brand.substring(1)}';
}

bool isLauncherPkg(String pkg) =>
    pkg == 'com.miui.home' ||
    pkg == 'com.google.android.googlequicksearchbox' ||
    pkg.contains('.launcher') ||
    pkg.endsWith('.home') ||
    pkg == 'com.android.systemui';

bool isSystemPkg(String pkg) {
  // ── Exact known system packages ────────────────────────────────────────────
  const exact = {
    'android',
    'com.android.phone',
    'com.android.contacts',
    'com.android.mms',
    'com.android.dialer',
    'com.android.settings',
    'com.android.systemui',
    'com.android.permissioncontroller',
    'com.android.packageinstaller',
    'com.android.documentsuI',
    'com.android.stk',                  // SIM Toolkit
    'com.google.android.gms',           // Play Services
    'com.google.android.gsf',           // Google Services Framework
    'com.google.android.vending',       // Play Store process
    'com.android.vending',
    'com.google.android.packageinstaller',
    'com.google.android.providers.media.module',
    'com.google.android.documentsui',
    'com.qualcomm.qti.sta',
    'com.miui.securitycenter',
    'com.miui.securityadd',
    'com.miui.analytics',
    'com.miui.systemAdSolution',
  };
  if (exact.contains(pkg)) return true;

  // ── Vendor-namespace prefixes (all packages in these namespaces are system) ─
  if (pkg.startsWith('com.qualcomm.') ||
      pkg.startsWith('com.qti.') ||
      pkg.startsWith('com.mediatek.') ||
      pkg.startsWith('com.android.internal.') ||
      pkg.startsWith('com.google.android.syncadapters.') ||
      pkg.startsWith('com.google.android.gsf.') ||
      pkg.startsWith('com.xiaomi.bluetooth')) { return true; }

  // ── Substring patterns ──────────────────────────────────────────────────────
  return pkg.contains('photopicker')           ||
      pkg.contains('permissioncontroller')     ||
      pkg.contains('.provision')               ||
      pkg.contains('.setup')                   ||
      pkg.contains('btcontrol')                || // Bluetooth chip controllers
      pkg.contains('.inputmethod')             ||
      pkg.contains('wallpaper')                ||
      pkg.contains('.systemui')                ||
      pkg.contains('miui.system')              ||
      pkg.contains('.stk')                     || // SIM Toolkit variants
      // Background service/daemon suffixes — user apps are never named like this
      pkg.endsWith('.service')                 ||
      pkg.endsWith('.services')                ||
      pkg.endsWith('.provider')                ||
      pkg.endsWith('.providers')               ||
      pkg.endsWith('.daemon');
}

bool isUserFacingApp(String pkg) =>
    !isLauncherPkg(pkg) && !isSystemPkg(pkg);
