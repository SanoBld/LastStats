// lib/l10n/l10n.dart
// ══════════════════════════════════════════════════════════════════════════
//  App localization — single entry point.
//  Usage: L.someKey  (uses current localeNotifier.value)
//
//  To add a language:
//    1. Create lib/l10n/strings_xx.dart implementing AppStrings
//       (copy an existing one as a template).
//    2. Add its 4 strings to lib/supported_locales.dart.
//    3. Add the two lines below (const + switch case).
//  You never need to touch the other strings_xx.dart files.
// ══════════════════════════════════════════════════════════════════════════

import '../app_state.dart';
import 'app_strings.dart';
import 'strings_fr.dart';
import 'strings_en.dart';
import 'strings_es.dart';
import 'strings_zh.dart';
import 'strings_pt.dart';
import 'strings_de.dart';
import 'strings_it.dart';
import 'strings_ja.dart';
import 'strings_ru.dart';
import 'strings_ar.dart';

export 'app_strings.dart' show AppStrings;

const _fr = AppStringsFr();
const _en = AppStringsEn();
const _es = AppStringsEs();
const _zh = AppStringsZh();
const _pt = AppStringsPt();
const _de = AppStringsDe();
const _it = AppStringsIt();
const _ja = AppStringsJa();
const _ru = AppStringsRu();
const _ar = AppStringsAr();

/// Returns the current [AppStrings] based on [localeNotifier].
AppStrings get L {
  switch (localeNotifier.value) {
    case 'en': return _en;
    case 'es': return _es;
    case 'zh': return _zh;
    case 'pt': return _pt;
    case 'de': return _de;
    case 'it': return _it;
    case 'ja': return _ja;
    case 'ru': return _ru;
    case 'ar': return _ar;
    default:   return _fr;
  }
}
