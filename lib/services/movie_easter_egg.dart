// Easter egg: tracks from the Cars (🏎️), How to Train Your Dragon (🐉) and
// WALL·E (🤖) films show an emoji instead of the arrow on the back button.

String _n(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), ' ')
    .replaceAll('œ', 'oe')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

String _a(String s) => s.toLowerCase()
    .replaceAll(RegExp(r'[éèê]'), 'e')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _anyIn(String artist, List<String> keys) => keys.any(artist.contains);

// title -> artists (normalised substrings). Empty list = any artist.
const Map<String, List<String>> _cars = {
  // Cars (2006)
  'realgone': ['sherylcrow'], 'route66': ['chuckberry', 'johnmayer'],
  'lifeisahighway': ['rascalflatts'], 'behindtheclouds': ['bradpaisley'],
  'ourtown': ['jamestaylor', 'randynewman'], 'shboom': ['thechords'],
  'findyourself': ['bradpaisley'], 'myheartwouldknow': ['hankwilliams'],
  'openingrace': ['randynewman'], 'mcqueenslost': ['randynewman'],
  'bessie': ['randynewman'], 'dirtisdifferent': ['randynewman'],
  'newroad': ['randynewman'], 'tractortipping': ['randynewman'],
  'mcqueenandsally': ['randynewman'], 'prerace pageantry': ['randynewman'],
  'preracepageantry': ['randynewman'], 'thepistoncup': ['randynewman'],
  'thebigrace': ['randynewman'],
  // Cars 2
  'youmightthink': ['weezer'], 'collisionofworlds': ['robbiewilliams', 'bradpaisley'],
  'moncoeurfaitvroum': ['benabar', 'bénabar'], 'nobodysfool': ['bradpaisley'],
  'polyrhythm': ['perfume'], 'turbotransmission': ['giacchino'],
  'itsfinnmcmissile': ['giacchino'], 'towkyotakeout': ['giacchino'],
  'tarmacthemagnificent': ['giacchino'], 'portocorsa': ['giacchino'],
  'thelemonpledge': ['giacchino'], 'materthewaiter': ['giacchino'],
  'materofdisguise': ['giacchino'], 'matersthebomb': ['giacchino'],
  'blunderandlightning': ['giacchino'], 'axlerodexposed': ['giacchino'],
  'theturbomater': ['giacchino'], 'radiatorreunion': ['giacchino'],
  'crankinguptheheat': ['giacchino'],
  // Cars 3
  'runthatrace': ['danauerbach'], 'ride': ['zzward'],
  'kingshighway': ['jamesbay'], 'glorydays': ['andraday'],
  'drivemycar': ['jorgeblanco'], 'freewayoflove': ['leadelaria'],
  'truckaroo': ['bradpaisley'], 'thunderhollowbreakdown': ['bradpaisley'],
  'ifthistrackcouldtalk': ['randynewman'],
};

const Map<String, List<String>> _dragon = {
  'sticksandstones': ['jonsi'], 'togetherfromafar': ['jonsi', 'powell'],
  'wherenoonegoes': ['jonsi'], 'togetherwemaptheworld': ['powell', 'jonsi'],
  'dragonracing': ['powell'], 'valkasdragonsanctuary': ['powell'],
  'thehiddenworld': ['powell', 'jonsi'], 'testdrive': ['powell'],
  'romanticflight': ['powell'], 'forbiddenfriendship': ['powell'],
  'thisisberk': ['powell'], 'dragontraining': ['powell'],
  'dragonbattle': ['powell'], 'thedowneddragon': ['powell'],
  'thedragonbook': ['powell'], 'dragonsden': ['powell'],
};

const Map<String, List<String>> _walle = {
  'downtoearth': ['petergabriel'], 'definedancing': ['thomasnewman'],
  'thespaceship': ['thomasnewman'], 'directive': ['thomasnewman'],
  'putonyoursundayclothes': ['michaelcrawford', 'pearlbailey'],
  'itonlytakesamoment': ['michaelcrawford', 'pearlbailey'],
};

/// Returns the emoji for a track that belongs to a Cars / Dragon / WALL·E
/// film, or null. [album] is optional but makes the detection more reliable
/// (and is the only way to catch songs shared with other albums).
String? movieEasterEgg({required String title, required String artist, String album = ''}) {
  final t = _n(title), ar = _a(artist), al = _n(album);

  final isSoundtrackAlbum = al.contains('soundtrack') || al.contains('motionpicture') ||
      al.contains('score') || al.contains('ost') || al.contains('musicfrom');
  if (al.startsWith('cars') && isSoundtrackAlbum) return '🏎️';
  if (al.contains('howtotrainyourdragon')) return '🐉';
  if (al.startsWith('walle')) return '🤖';

  bool hit(Map<String, List<String>> m) {
    final who = m[t];
    return who != null && (who.isEmpty || _anyIn(ar, who));
  }
  if (hit(_cars)) return '🏎️';
  if (hit(_dragon)) return '🐉';
  if (hit(_walle)) return '🤖';
  return null;
}
