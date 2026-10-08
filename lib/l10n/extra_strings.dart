// lib/l10n/extra_strings.dart
// tx('key') / tx('key', {'n': '3'}) — keyed UI strings.
// The texts themselves live in each language's own file (kTxFr in
// strings_fr.dart, kTxEn in strings_en.dart, …). Falls back to English,
// then French, then the key itself, so a missing entry never shows blank.
import '../app_state.dart';
import 'strings_fr.dart' show kTxFr;
import 'strings_en.dart' show kTxEn;
import 'strings_es.dart' show kTxEs;
import 'strings_zh.dart' show kTxZh;
import 'strings_pt.dart' show kTxPt;
import 'strings_de.dart' show kTxDe;
import 'strings_it.dart' show kTxIt;
import 'strings_ja.dart' show kTxJa;
import 'strings_ru.dart' show kTxRu;
import 'strings_ar.dart' show kTxAr;

const Map<String, Map<String, String>> _kTx = {
  'fr': kTxFr,
  'en': kTxEn,
  'es': kTxEs,
  'zh': kTxZh,
  'pt': kTxPt,
  'de': kTxDe,
  'it': kTxIt,
  'ja': kTxJa,
  'ru': kTxRu,
  'ar': kTxAr,
};

String tx(String key, [Map<String, String>? args]) {
  var s = _kTx[localeNotifier.value]?[key] ?? kTxEn[key] ?? kTxFr[key] ?? key;
  if (args != null) {
    args.forEach((k, v) { s = s.replaceAll('{$k}', v); });
  }
  return s;
}
