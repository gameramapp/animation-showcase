// Multi-language UI: English (default), Russian, Spanish, French, German.
//
// Every user-visible string is written as a pair right where it is used:
//   Text(tr('Duration', '<the same text in Russian>'))
// tr() reads the current language. Switching the language re-runs every
// build() in the app (see AnimationSamples in main.dart) while keeping state,
// so UI strings must be produced inside build() (or getters/functions called
// from it) — never stored in `const` values, top-level `final`s or State
// fields, which would keep the old language.
//
// English and Russian live inline in the code. Spanish / French / German are
// looked up by the English text in lib/src/l10n/translations.g.dart,
// generated from tool/i18n/<lang>.json by tool/i18n_extract.py. Strings with
// interpolation are matched by template ("⟪0⟫ ms"); a missing translation
// falls back to English and is recorded in [debugMissingTranslations].
//
// The choice is remembered in the browser (shared_preferences → localStorage)
// and can be forced with a link parameter: https://…/?lang=de

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/translations.g.dart';

enum AppLang {
  en('EN', 'English'),
  ru('RU', 'Русский'), // i18n-ignore: a language's own name
  es('ES', 'Español'),
  fr('FR', 'Français'),
  de('DE', 'Deutsch');

  const AppLang(this.code, this.nativeName);

  /// Short code for the switch.
  final String code;

  /// The language's name in that language — the way language menus show it.
  final String nativeName;
}

/// Current UI language. Listen to it to rebuild on change.
final appLang = ValueNotifier<AppLang>(AppLang.en);

/// Picks the string for the current language.
String tr(String en, String ru) => switch (appLang.value) {
  AppLang.en => en,
  AppLang.ru => ru,
  final lang => _translate(lang.name, en),
};

bool get isRu => appLang.value == AppLang.ru;

/// English strings that had no translation in the current table. Tests check
/// it stays empty; in the app a miss just shows English.
final debugMissingTranslations = <String>{};

final _cache = <String, Map<String, String>>{};
final _templates = <String, List<(RegExp, String)>>{};
final _placeholder = RegExp('⟪(\\d+)⟫');

String _translate(String lang, String en) {
  final table = kTranslations[lang];
  if (table == null) return en;
  final exact = table[en];
  if (exact != null) return exact;
  final cache = _cache.putIfAbsent(lang, () => {});
  final cached = cache[en];
  if (cached != null) return cached;
  // Interpolated strings: the key is a template like "Speed (cycle ⟪0⟫ ms)".
  final templates = _templates.putIfAbsent(lang, () => [
    for (final MapEntry(:key, :value) in table.entries)
      if (key.contains('⟪'))
        (
          RegExp(
            '^${key.split(_placeholder).map(RegExp.escape).join('(.*?)')}\$',
            dotAll: true,
          ),
          value,
        ),
  ]);
  var result = en;
  var found = false;
  for (final (pattern, translation) in templates) {
    final m = pattern.firstMatch(en);
    if (m == null) continue;
    // Placeholders are numbered in the English order; the translation may
    // use them in any order.
    result = translation.replaceAllMapped(
      _placeholder,
      (p) => m.group(int.parse(p.group(1)!) + 1) ?? '',
    );
    found = true;
    break;
  }
  if (!found) debugMissingTranslations.add(en);
  if (cache.length > 5000) cache.clear();
  cache[en] = result;
  return result;
}

const _prefsKey = 'app_lang';

/// Restores the language: `?lang=` in the URL wins, then the saved choice.
Future<void> initLang() async {
  final fromUrl = Uri.base.queryParameters['lang'];
  final parsed = _parse(fromUrl);
  if (parsed != null) {
    appLang.value = parsed;
    return;
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    appLang.value = _parse(prefs.getString(_prefsKey)) ?? AppLang.en;
  } catch (_) {
    // No storage (private mode, tests) — stay on the default.
  }
}

Future<void> setLang(AppLang lang) async {
  appLang.value = lang;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, lang.name);
  } catch (_) {
    // Remembering the choice is a convenience; ignore storage errors.
  }
}

AppLang? _parse(String? value) {
  for (final lang in AppLang.values) {
    if (lang.name == value) return lang;
  }
  return null;
}

/// Language menu for app bars. Put it into `AppBar(actions: [...])`.
class LangButton extends StatelessWidget {
  const LangButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: appLang,
      builder: (context, lang, _) => PopupMenuButton<AppLang>(
        tooltip: tr('Language', 'Язык'),
        initialValue: lang,
        onSelected: setLang,
        itemBuilder: (context) => [
          for (final l in AppLang.values)
            PopupMenuItem(
              value: l,
              child: Row(
                children: [
                  SizedBox(width: 32, child: Text(l.code, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text(l.nativeName),
                ],
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate, size: 18),
              const SizedBox(width: 4),
              Text(lang.code, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
