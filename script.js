'use strict';

const LASTFM_URL  = 'https://ws.audioscrobbler.com/2.0/';
const CACHE_TTL   = 30 * 60 * 1000;
const TOP_LIMIT   = 50;
const DEFAULT_IMG = '2a96cbd8b46e442fc41c2b86b821562f';

// Palette statique de fallback (utilisée uniquement si les CSS vars ne sont pas encore chargées)
// Teintes de base par clé d'accent (correspond aux valeurs _ACCENT_DARK)
const _ACCENT_HUES = { purple: 265, blue: 210, green: 135, red: 0, orange: 28 };

// Cache palette pour éviter de recalculer à chaque accès
let _palCache    = null;
let _palCacheKey = null;

/**
 * Renvoie N couleurs basées sur la teinte de l'accent courant.
 * Pas d'accès DOM — utilise APP.currentAccent ou la CSS var hsl() pour custom/dynamic.
 */
function getAccentPalette(n = 15) {
  const key    = APP?.currentAccent || localStorage.getItem('ls_accent') || 'purple';
  const isDark = APP?.currentTheme === 'dark'
    || (APP?.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme:dark)').matches);
  const cacheId = `${key}|${isDark}`;

  if (_palCache && _palCacheKey === cacheId) {
    return n >= _palCache.length ? _palCache : _palCache.slice(0, n);
  }

  let baseH = _ACCENT_HUES[key] ?? 265;

  // Pour custom / dynamic : lire la CSS var hsl() si disponible
  if (key === 'custom' || key === 'dynamic') {
    try {
      const raw  = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim();
      const hslM = raw.match(/hsl\(\s*(\d+)/);
      if (hslM) baseH = parseInt(hslM[1]);
    } catch {}
  }

  const s     = isDark ? 65 : 55;
  const lBase = isDark ? 68 : 48;

  _palCache    = Array.from({ length: 15 }, (_, i) => {
    const h = (baseH + i * 28) % 360;
    const l = lBase + (i % 3) * 6;
    return `hsl(${h},${s}%,${l}%)`;
  });
  _palCacheKey = cacheId;

  return n >= _palCache.length ? _palCache : _palCache.slice(0, n);
}

/** Invalide le cache palette (appelé par setAccent) */
function _invalidatePalCache() { _palCache = null; _palCacheKey = null; }

/**
 * CHART_PALETTE — tableau vivant basé sur l'accent courant.
 * Proxy Symbol-safe : tous les Symbol-props sont délégués au tableau réel,
 * ce qui évite le "Cannot convert a Symbol value to a number" de Chart.js/D3.
 */
const CHART_PALETTE = new Proxy([], {
  get(_, prop) {
    const pal = getAccentPalette(15);
    // ① Toujours déléguer les Symbol directement (Symbol.iterator, toPrimitive, etc.)
    if (typeof prop === 'symbol') return pal[prop];
    // ② Propriétés numériques
    const idx = Number(prop);
    if (!isNaN(idx) && idx >= 0) return pal[idx];
    // ③ Toutes les méthodes array (map, slice, forEach, fill, reduce, indexOf…)
    const val = pal[prop];
    return typeof val === 'function' ? val.bind(pal) : val;
  },
  // Nécessaire pour Array.isArray() et les checks de type
  getPrototypeOf() { return Array.prototype; },
  has(_, prop)     { return prop in getAccentPalette(15); },
});

const MONTHS       = () => window.I18N?.arr('months')       || ['Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
const MONTHS_SHORT = () => window.I18N?.arr('months_short') || ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
const DAYS         = () => window.I18N?.arr('days')         || ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];

// fallback t() if i18n.js hasn't loaded yet
if (typeof window.t !== 'function') window.t = k => k;

(function _patchI18N() {
  if (typeof I18N_DATA === 'undefined') return;

  const PATCH = {
    share:              { fr:'Partager',      en:'Share',         es:'Compartir',   pt:'Partilhar',  de:'Teilen',      it:'Condividi',  ru:'Поделиться', ar:'مشاركة', ja:'シェア',  zh:'分享', ko:'공유', tr:'Paylaş'   },
    stat_diversity:     { fr:'Ratio de diversité', en:'Diversity ratio', es:'Ratio diversidad', pt:'Rácio diversidade', de:'Diversitätsrate', it:'Ratio diversità', ru:'Коэф. разнообразия', ar:'نسبة التنوع', ja:'多様性率', zh:'多样性比率', ko:'다양성 비율', tr:'Çeşitlilik oranı' },
    stat_diversity_sub: { fr:'(Artistes / Total) × 100', en:'(Artists / Total) × 100', es:'(Artistas / Total) × 100', pt:'(Artistas / Total) × 100', de:'(Künstler / Total) × 100', it:'(Artisti / Totale) × 100', ru:'(Исполнителей / Всего) × 100', ar:'(فنانون / إجمالي) × 100', ja:'(アーティスト / 合計) × 100', zh:'(艺术家 / 总计) × 100', ko:'(아티스트 / 전체) × 100', tr:'(Sanatçı / Toplam) × 100' },
    // new badges — tempo
    badge_crescendo_name: { fr:'Crescendo',         en:'Crescendo',         es:'Crescendo',     pt:'Crescendo',      de:'Crescendo',     it:'Crescendo',     ru:'Крещендо',       ar:'كريشيندو',  ja:'クレッシェンド',    zh:'渐强',     ko:'크레셴도',  tr:'Crescendo'    },
    badge_crescendo_desc: { fr:'Mois consécutifs en hausse (écoutes en progression)', en:'Consecutive months of growth (increasing plays)', es:'Meses consecutivos de crecimiento', pt:'Meses consecutivos de crescimento', de:'Aufeinanderfolgende Wachstumsmonate', it:'Mesi consecutivi di crescita', ru:'Последовательные месяцы роста', ar:'أشهر متتالية من النمو', ja:'連続成長月数', zh:'连续增长月份', ko:'연속 성장 월수', tr:'Ardışık büyüme ayları' },
    badge_regular_name:   { fr:'Régulier',           en:'Consistent',        es:'Constante',     pt:'Regular',        de:'Regelmäßig',    it:'Costante',      ru:'Постоянный',     ar:'منتظم',     ja:'コンスタント',     zh:'规律',     ko:'꾸준함',    tr:'Düzenli'      },
    badge_regular_desc:   { fr:'Jours d\'activité musicale répartis sur la durée', en:'Days of musical activity spread over time', es:'Días de actividad musical repartidos en el tiempo', pt:'Dias de atividade musical ao longo do tempo', de:'Musikalische Aktivitätstage über die Zeit', it:'Giorni di attività musicale nel tempo', ru:'Дни музыкальной активности за период', ar:'أيام النشاط الموسيقي على مدار الوقت', ja:'時間にわたる音楽活動日', zh:'随时间分布的音乐活动日', ko:'시간에 걸친 음악 활동 일수', tr:'Zamanla dağılmış müzik aktivite günleri' },
    badge_comeback_name:  { fr:'Come-back',          en:'Come-back',         es:'Come-back',     pt:'Come-back',      de:'Come-back',     it:'Come-back',     ru:'Камбэк',         ar:'عودة',      ja:'カムバック',       zh:'回归',     ko:'컴백',      tr:'Geri dönüş'   },
    badge_comeback_desc:  { fr:'Pauses de +30 jours puis reprise active', en:'Breaks of +30 days followed by active return', es:'Pausas de +30 días seguidas de regreso activo', pt:'Pausas de +30 dias seguidas de retorno ativo', de:'Pausen von +30 Tagen mit aktivem Comeback', it:'Pause di +30 giorni seguite da ritorno attivo', ru:'Перерывы >30 дней и активное возвращение', ar:'فترات راحة أكثر من 30 يومًا ثم عودة نشطة', ja:'30日超の休止後の復帰', zh:'超30天的休息后活跃回归', ko:'30일 이상 휴식 후 활발한 복귀', tr:'+30 günlük aranın ardından aktif geri dönüş' },
    // new badges — social
    badge_ambassador_name:  { fr:'Ambassadeur',      en:'Ambassador',        es:'Embajador',     pt:'Embaixador',     de:'Botschafter',   it:'Ambasciatore',  ru:'Посол',          ar:'سفير',      ja:'アンバサダー',     zh:'大使',     ko:'앰배서더',  tr:'Büyükelçi'    },
    badge_ambassador_desc:  { fr:'Artistes écoutés ≥ 100 fois (fidèles absolus)', en:'Artists played ≥ 100 times (absolute loyalists)', es:'Artistas escuchados ≥ 100 veces', pt:'Artistas ouvidos ≥ 100 vezes', de:'Künstler ≥ 100 Mal gespielt', it:'Artisti ascoltati ≥ 100 volte', ru:'Артисты прослушаны ≥ 100 раз', ar:'فنانون استُمع إليهم ≥ 100 مرة', ja:'100回以上再生したアーティスト数', zh:'播放次数≥100的艺术家数量', ko:'100회 이상 재생한 아티스트 수', tr:'≥100 kez çalınan sanatçılar' },
    badge_tastemaker_name:  { fr:'Prescripteur',     en:'Tastemaker',        es:'Prescriptor',   pt:'Influenciador',  de:'Trendsetter',   it:'Precursore',    ru:'Законодатель',   ar:'مؤثر',      ja:'テイストメーカー', zh:'品味引领者', ko:'트렌드세터', tr:'Trend belirleyici' },
    badge_tastemaker_desc:  { fr:'Artistes représentant +10% de vos écoutes', en:'Artists representing +10% of your plays', es:'Artistas que representan +10% de tus reproducciones', pt:'Artistas representando +10% das reproduções', de:'Künstler mit +10% Ihrer Wiedergaben', it:'Artisti che rappresentano +10% degli ascolti', ru:'Артисты с долей >10% прослушиваний', ar:'فنانون يمثلون أكثر من 10٪ من استماعاتك', ja:'再生回数の10%超を占めるアーティスト', zh:'占播放总量10%以上的艺术家', ko:'전체 재생의 10% 이상을 차지하는 아티스트', tr:'Çalmalarınızın +%10\'unu temsil eden sanatçılar' },
    badge_nomad_name:       { fr:'Nomade Musical',   en:'Musical Nomad',     es:'Nómada Musical',pt:'Nômade Musical', de:'Musikalischer Nomade', it:'Nomade Musicale', ru:'Музыкальный кочевник', ar:'البدوي الموسيقي', ja:'ミュージカルノマド', zh:'音乐游牧者', ko:'음악 유목민', tr:'Müzik Göçebesi' },
    badge_nomad_desc:       { fr:'Mois avec ≥10 artistes différents actifs', en:'Months with ≥10 different active artists', es:'Meses con ≥10 artistas diferentes activos', pt:'Meses com ≥10 artistas diferentes ativos', de:'Monate mit ≥10 verschiedenen aktiven Künstlern', it:'Mesi con ≥10 artisti diversi attivi', ru:'Месяцы с ≥10 разными активными артистами', ar:'أشهر مع ≥10 فنانين مختلفين نشطين', ja:'10人以上の異なるアーティストがいる月', zh:'有≥10位不同活跃艺术家的月份', ko:'≥10명의 다른 활성 아티스트가 있는 달', tr:'≥10 farklı aktif sanatçılı aylar' },
    profile_retry:      { fr:'Réessayer',     en:'Retry',         es:'Reintentar',  pt:'Tentar novamente', de:'Erneut versuchen', it:'Riprova', ru:'Повторить', ar:'إعادة المحاولة', ja:'再試行', zh:'重试', ko:'재시도', tr:'Tekrar dene' },
    profile_reload:     { fr:'Actualiser',    en:'Reload',        es:'Actualizar',  pt:'Recarregar', de:'Neu laden',   it:'Aggiorna',   ru:'Обновить',   ar:'تحديث',  ja:'更新',    zh:'刷新', ko:'새로고침', tr:'Yenile' },
    nav_history:        { fr:'Historique',    en:'History',       es:'Historial',   pt:'Histórico',  de:'Verlauf',     it:'Cronologia', ru:'История',    ar:'التاريخ', ja:'履歴',   zh:'历史',  ko:'기록',     tr:'Geçmiş' },
    history_title:      { fr:'Historique',    en:'History',       es:'Historial',   pt:'Histórico',  de:'Verlauf',     it:'Cronologia', ru:'История',    ar:'التاريخ', ja:'履歴',   zh:'历史',  ko:'기록',     tr:'Geçmiş' },
    history_sub:        { fr:'Parcourez vos scrobbles jour par jour', en:'Browse your scrobbles day by day', es:'Explora tus scrobbles día a día', pt:'Explore os seus scrobbles dia a dia', de:'Scrobbles täglich durchsuchen', it:'Sfoglia i tuoi scrobbles giorno per giorno', ru:'Просматривайте свои скробблы день за днём', ar:'تصفح سجلاتك يوماً بيوم', ja:'日別にスクロブルを閲覧', zh:'按日浏览你的记录', ko:'일별 스크로블 탐색', tr:'Scrobble\'larına gün gün göz at' },
    history_today:      { fr:'Aujourd\'hui',  en:'Today',         es:'Hoy',         pt:'Hoje',       de:'Heute',       it:'Oggi',       ru:'Сегодня',    ar:'اليوم',  ja:'今日',    zh:'今天',  ko:'오늘',     tr:'Bugün' },
    history_loading:    { fr:'Chargement…',   en:'Loading…',      es:'Cargando…',   pt:'Carregando…',de:'Lädt…',       it:'Caricamento…',ru:'Загрузка…', ar:'جارٍ التحميل…', ja:'読み込み中…', zh:'加载中…', ko:'로딩 중…', tr:'Yükleniyor…' },
    history_viewTimeline:{ fr:'Fil chronologique', en:'Timeline',  es:'Cronología',  pt:'Cronologia', de:'Zeitstrahl',  it:'Sequenza',   ru:'Хронология', ar:'الجدول الزمني', ja:'タイムライン', zh:'时间线', ko:'타임라인', tr:'Zaman çizelgesi' },
    history_viewList:   { fr:'Liste',         en:'List',          es:'Lista',       pt:'Lista',      de:'Liste',       it:'Lista',      ru:'Список',     ar:'قائمة',  ja:'リスト',  zh:'列表',  ko:'목록',     tr:'Liste' },
    history_viewStats:  { fr:'Statistiques',  en:'Stats',         es:'Estadísticas',pt:'Estatísticas',de:'Statistiken', it:'Statistiche',ru:'Статистика', ar:'إحصاءات', ja:'統計',   zh:'统计',  ko:'통계',     tr:'İstatistikler' },
    history_noScrobbles:{ fr:'Aucun scrobble ce jour-là', en:'No scrobbles on this day', es:'Sin scrobbles este día', pt:'Sem scrobbles neste dia', de:'Keine Scrobbles an diesem Tag', it:'Nessun scrobble in questo giorno', ru:'Нет скробблов в этот день', ar:'لا يوجد تسجيل في هذا اليوم', ja:'この日のスクロブルなし', zh:'当天无记录', ko:'이 날 스크로블 없음', tr:'Bu günde scrobble yok' },
    settings_navVisibility:    { fr:'Onglets de navigation', en:'Navigation tabs', es:'Pestañas de navegación', pt:'Abas de navegação', de:'Navigationsreiter', it:'Schede di navigazione', ru:'Вкладки навигации', ar:'علامات التبويب', ja:'ナビゲーションタブ', zh:'导航标签', ko:'내비게이션 탭', tr:'Gezinme sekmeleri' },
    settings_navVisibilityHint:{ fr:'Choisissez quelles sections apparaissent dans la barre de navigation. Dashboard et Paramètres sont toujours visibles.', en:'Choose which sections appear in the navigation bar. Dashboard and Settings are always visible.', es:'Elige qué secciones aparecen en la barra de navegación. Dashboard y Configuración siempre son visibles.', pt:'Escolha quais seções aparecem na barra de navegação. Dashboard e Configurações são sempre visíveis.', de:'Wähle, welche Abschnitte in der Navigationsleiste angezeigt werden. Dashboard und Einstellungen sind immer sichtbar.', it:'Scegli quali sezioni appaiono nella barra di navigazione. Dashboard e Impostazioni sono sempre visibili.', ru:'Выберите, какие разделы отображаются на панели навигации. Панель управления и настройки всегда видны.', ar:'اختر الأقسام التي تظهر في شريط التنقل. لوحة التحكم والإعدادات دائمًا مرئية.', ja:'ナビゲーションバーに表示するセクションを選択してください。ダッシュボードと設定は常に表示されます。', zh:'选择导航栏中显示的部分。仪表板和设置始终可见。', ko:'탐색 바에 표시할 섹션을 선택하세요. 대시보드와 설정은 항상 표시됩니다.', tr:'Gezinme çubuğunda hangi bölümlerin görüneceğini seçin. Gösterge paneli ve Ayarlar her zaman görünür.' },
    toast_settings_saved:{ fr:'Paramètres sauvegardés !', en:'Settings saved!', es:'Ajustes guardados!', pt:'Definições guardadas!', de:'Einstellungen gespeichert!', it:'Impostazioni salvate!', ru:'Настройки сохранены!', ar:'تم حفظ الإعدادات!', ja:'設定を保存しました!', zh:'设置已保存!', ko:'설정이 저장되었습니다!', tr:'Ayarlar kaydedildi!' },
    period_7day:        { fr:'Cette semaine', en:'This week',     es:'Esta semana', pt:'Esta semana', de:'Diese Woche', it:'Questa settimana', ru:'Эта неделя', ar:'هذا الأسبوع', ja:'今週', zh:'本周', ko:'이번 주', tr:'Bu hafta' },
    period_1month:      { fr:'Ce mois',       en:'This month',    es:'Este mes',    pt:'Este mês',   de:'Dieser Monat', it:'Questo mese', ru:'Этот месяц', ar:'هذا الشهر', ja:'今月', zh:'本月', ko:'이번 달', tr:'Bu ay' },
    period_3month:      { fr:'3 derniers mois', en:'Last 3 months', es:'Últimos 3 meses', pt:'Últimos 3 meses', de:'Letzte 3 Monate', it:'Ultimi 3 mesi', ru:'Последние 3 месяца', ar:'آخر 3 أشهر', ja:'過去3ヶ月', zh:'过去3个月', ko:'최근 3개월', tr:'Son 3 ay' },
    period_6month:      { fr:'6 derniers mois', en:'Last 6 months', es:'Últimos 6 meses', pt:'Últimos 6 meses', de:'Letzte 6 Monate', it:'Ultimi 6 mesi', ru:'Последние 6 месяцев', ar:'آخر 6 أشهر', ja:'過去6ヶ月', zh:'过去6个月', ko:'최근 6개월', tr:'Son 6 ay' },
    period_12month:     { fr:'Cette année',   en:'This year',     es:'Este año',    pt:'Este ano',   de:'Dieses Jahr', it:'Quest\'anno', ru:'Этот год', ar:'هذا العام', ja:'今年', zh:'今年', ko:'올해', tr:'Bu yıl' },
    period_overall:     { fr:'Tout le temps', en:'All time',      es:'Todo el tiempo', pt:'Sempre', de:'Alle Zeit',   it:'Sempre',     ru:'Всё время', ar:'كل الوقت', ja:'全期間', zh:'所有时间', ko:'전체', tr:'Tüm zamanlar' },
    listeners_label:    { fr:'auditeurs',     en:'listeners',     es:'oyentes',     pt:'ouvintes',   de:'Hörer',       it:'ascoltatori', ru:'слушателей', ar:'مستمعين', ja:'リスナー', zh:'听众', ko:'청취자', tr:'dinleyici' },
    plays:              { fr:'écoutes',       en:'plays',         es:'reproducciones', pt:'reproduções', de:'Wiedergaben', it:'ascolti', ru:'прослушиваний', ar:'تشغيل', ja:'再生回数', zh:'播放', ko:'재생', tr:'çalma' },
    tier_bronze:        { fr:'Bronze',        en:'Bronze',        es:'Bronce',      pt:'Bronze',     de:'Bronze',      it:'Bronzo',     ru:'Бронза',     ar:'برونز', ja:'ブロンズ', zh:'铜', ko:'브론즈', tr:'Bronz' },
    tier_argent:        { fr:'Argent',        en:'Silver',        es:'Plata',       pt:'Prata',      de:'Silber',      it:'Argento',    ru:'Серебро',    ar:'فضة',   ja:'シルバー', zh:'银', ko:'실버', tr:'Gümüş' },
    tier_or:            { fr:'Or',            en:'Gold',          es:'Oro',         pt:'Ouro',       de:'Gold',        it:'Oro',        ru:'Золото',     ar:'ذهب',   ja:'ゴールド', zh:'金', ko:'골드', tr:'Altın' },
    tier_diamant:       { fr:'Diamant',       en:'Diamond',       es:'Diamante',    pt:'Diamante',   de:'Diamant',     it:'Diamante',   ru:'Бриллиант',  ar:'ماس',   ja:'ダイヤ', zh:'钻石', ko:'다이아', tr:'Elmas' },
    tier_elite:         { fr:'Élite',         en:'Elite',         es:'Élite',       pt:'Élite',      de:'Elite',       it:'Elite',      ru:'Элита',      ar:'نخبة',  ja:'エリート', zh:'精英', ko:'엘리트', tr:'Elit' },
    share_artist_text:  { fr:'{0} — {1} écoutes sur mon LastStats ! 🎵', en:'{0} — {1} plays on my LastStats! 🎵', es:'{0} — {1} reproducciones en mi LastStats! 🎵', pt:'{0} — {1} reproduções no meu LastStats! 🎵', de:'{0} — {1} Plays auf meinem LastStats! 🎵', it:'{0} — {1} ascolti su LastStats! 🎵', ru:'{0} — {1} прослушиваний в моём LastStats! 🎵', ar:'{0} — {1} تشغيل على LastStats الخاص بي! 🎵', ja:'{0} — {1}回再生 (LastStats) 🎵', zh:'{0} — {1}次播放（LastStats）🎵', ko:'{0} — {1}회 재생 (LastStats) 🎵', tr:'{0} — {1} çalma LastStats\'ta! 🎵' },
    share_album_text:   { fr:'{0} par {1} — {2} écoutes 🎵', en:'{0} by {1} — {2} plays 🎵', es:'{0} de {1} — {2} reproducciones 🎵', pt:'{0} de {1} — {2} reproduções 🎵', de:'{0} von {1} — {2} Plays 🎵', it:'{0} di {1} — {2} ascolti 🎵', ru:'{0} от {1} — {2} прослушиваний 🎵', ar:'{0} بواسطة {1} — {2} تشغيل 🎵', ja:'{1}の{0} — {2}回再生 🎵', zh:'{1}的{0} — {2}次播放 🎵', ko:'{1}의 {0} — {2}회 재생 🎵', tr:'{1} tarafından {0} — {2} çalma 🎵' },
    badge_restored:     { fr:'Succès restaurés ({0} jours)', en:'Badges restored ({0} days)', es:'Insignias restauradas ({0} días)', pt:'Insígnias restauradas ({0} dias)', de:'Abzeichen wiederhergestellt ({0} Tage)', it:'Badge ripristinati ({0} giorni)', ru:'Значки восстановлены ({0} дней)', ar:'تم استعادة الإنجازات ({0} أيام)', ja:'バッジ復元済み ({0}日)', zh:'徽章已恢复（{0}天）', ko:'뱃지 복원됨 ({0}일)', tr:'Rozetler geri yüklendi ({0} gün)' },
  };

  Object.entries(PATCH).forEach(([key, langs]) => {
    Object.entries(langs).forEach(([lang, val]) => {
      if (I18N_DATA[lang] && I18N_DATA[lang][key] === undefined) {
        I18N_DATA[lang][key] = val;
      }
    });
  });
})();

function getPeriodLabel(period) {
  const map = {
    '7day':   'period_7day',
    '1month': 'period_1month',
    '3month': 'period_3month',
    '6month': 'period_6month',
    '12month':'period_12month',
    'overall':'period_overall',
  };
  return t(map[period] || 'period_overall');
}

const APP = {
  apiKey:   '',
  username: '',
  userInfo: null,

  charts: {},

  topArtistsData:  [],
  topAlbumsData:   [],
  topTracksData:   [],

  fullHistory: null,
  streakData:  null,

  currentTheme:  'dark',
  currentAccent: 'purple',
  tintBg:        true,
  language:      window.I18N?.getLang?.() || 'fr',
  regYear:       new Date().getFullYear() - 5,

  artistsLayout: 'grid',
  albumsLayout:  'grid',
  tracksLayout:  'list',

  // nav visibility — which sections are shown (default: all)
  navVisibility: null, // loaded from localStorage

  // history section state
  histCurrentDate: null,   // YYYY-MM-DD string
  histCurrentView: 'timeline',
  histCache: {},           // keyed by YYYY-MM-DD

  artistsPage:      1,
  artistsPeriod:    'overall',
  artistsLoading:   false,
  artistsExhausted: false,
  artistsTotalPages:1,

  albumsPage:      1,
  albumsPeriod:    'overall',
  albumsLoading:   false,
  albumsExhausted: false,
  albumsTotalPages:1,

  tracksPage:      1,
  tracksPeriod:    'overall',
  tracksLoading:   false,
  tracksExhausted: false,
  tracksTotalPages:1,
};

const Cache = {
  prefix: 'ls3_',

  _key(method, params) {
    return this.prefix + APP.username + '_' + method + '_' + JSON.stringify(params);
  },

  get(method, params = {}) {
    try {
      const raw = localStorage.getItem(this._key(method, params));
      if (!raw) return null;
      const { data, ts } = JSON.parse(raw);
      if (Date.now() - ts > CACHE_TTL) { localStorage.removeItem(this._key(method, params)); return null; }
      return data;
    } catch { return null; }
  },

  set(method, params = {}, data) {
    try {
      localStorage.setItem(this._key(method, params), JSON.stringify({ data, ts: Date.now() }));
    } catch {
      this._purge();
      try { localStorage.setItem(this._key(method, params), JSON.stringify({ data, ts: Date.now() })); } catch {}
    }
  },

  _purge() {
    const keys = Object.keys(localStorage).filter(k => k.startsWith(this.prefix));
    keys.sort().slice(0, Math.min(30, keys.length)).forEach(k => localStorage.removeItem(k));
  },

  clear() {
    Object.keys(localStorage).filter(k => k.startsWith(this.prefix)).forEach(k => localStorage.removeItem(k));
  },
};

const API = {
  async call(method, params = {}, skipCache = false) {
    if (!skipCache) {
      const cached = Cache.get(method, params);
      if (cached) return cached;
    }
    const data = await this._fetch(method, params);
    Cache.set(method, params, data);
    return data;
  },

  async _fetch(method, params = {}, retries = 3) {
    const url = new URL(LASTFM_URL);
    url.searchParams.set('method',  method);
    url.searchParams.set('api_key', APP.apiKey);
    url.searchParams.set('user',    APP.username);
    url.searchParams.set('format',  'json');
    Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, String(v)));

    for (let attempt = 0; attempt < retries; attempt++) {
      try {
        const res  = await fetch(url.toString());
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        if (data.error) throw new Error(data.message || `API error ${data.error}`);
        return data;
      } catch (e) {
        if (attempt === retries - 1) throw e;
        await sleep(800 * (attempt + 1));
      }
    }
  },

  async getMonthScrobbles(year, month) {
    const from = Math.floor(new Date(year, month, 1).getTime() / 1000);
    const to   = Math.floor(new Date(year, month + 1, 0, 23, 59, 59).getTime() / 1000);
    try {
      const data = await this.call('user.getRecentTracks', { from, to, limit: 1 });
      return parseInt(data.recenttracks?.['@attr']?.total || 0);
    } catch { return 0; }
  },

  /**
   * Fetch toutes les pages en parallèle (batch de 5 requêtes simultanées).
   * 1. Fetch la page 1 pour connaître totalPages.
   * 2. Fetch toutes les pages restantes en batches de BATCH_SIZE.
   * Gain typique : 5-8× plus rapide qu'une boucle séquentielle.
   */
  async fetchAllPages(onProgress, yearFrom = null, yearTo = null) {
    const BATCH_SIZE  = 5;
    const baseParams  = { limit: 200, extended: 0 };
    if (yearFrom) baseParams.from = yearFrom;
    if (yearTo)   baseParams.to   = yearTo;

    // Étape 1 : page 1 pour obtenir totalPages
    const firstData  = await this._fetch('user.getRecentTracks', { ...baseParams, page: 1 });
    const attr       = firstData.recenttracks?.['@attr'] || {};
    const totalPages = parseInt(attr.totalPages || 1);
    const firstRaw   = firstData.recenttracks?.track || [];
    const firstTracks= (Array.isArray(firstRaw) ? firstRaw : [firstRaw])
                         .filter(tr => !tr['@attr']?.nowplaying);

    if (onProgress) onProgress(1, totalPages, firstTracks.length);

    if (totalPages === 1) return firstTracks;

    // Étape 2 : pages 2…N en batches parallèles
    const allPages    = [firstTracks]; // index 0 = page 1
    let   fetched     = 1;

    for (let start = 2; start <= totalPages; start += BATCH_SIZE) {
      const batchNums = [];
      for (let p = start; p < start + BATCH_SIZE && p <= totalPages; p++) {
        batchNums.push(p);
      }

      const batchResults = await Promise.all(
        batchNums.map(p => this._fetch('user.getRecentTracks', { ...baseParams, page: p }))
      );

      for (let i = 0; i < batchResults.length; i++) {
        const data   = batchResults[i];
        const raw    = data.recenttracks?.track || [];
        const tracks = (Array.isArray(raw) ? raw : [raw])
                         .filter(tr => !tr['@attr']?.nowplaying);
        allPages[batchNums[i] - 1] = tracks;
        fetched++;
        if (onProgress) {
          const countSoFar = allPages.reduce((acc, p) => acc + (p?.length || 0), 0);
          onProgress(fetched, totalPages, countSoFar);
        }
      }

      // Pause légère entre les batches pour respecter le rate-limit Last.fm
      if (start + BATCH_SIZE <= totalPages) await sleep(100);
    }

    // Aplatir dans l'ordre des pages
    return allPages.flat();
  },

  /**
   * Fetche uniquement les scrobbles plus récents que fromTs (Unix seconds).
   * Utilisé pour la mise à jour incrémentale du cache historique.
   * Même logique parallèle que fetchAllPages.
   */
  async fetchSince(fromTs, onProgress) {
    const BATCH_SIZE = 5;
    const baseParams = { limit: 200, extended: 0, from: fromTs + 1 };

    // Page 1
    const firstData  = await this._fetch('user.getRecentTracks', { ...baseParams, page: 1 });
    const attr       = firstData.recenttracks?.['@attr'] || {};
    const totalPages = parseInt(attr.totalPages || 1);
    const firstRaw   = firstData.recenttracks?.track || [];
    const firstTracks= (Array.isArray(firstRaw) ? firstRaw : [firstRaw])
                         .filter(tr => !tr['@attr']?.nowplaying);

    if (onProgress) onProgress(1, totalPages, firstTracks.length, true);
    if (totalPages === 1) return firstTracks;

    const allPages = [firstTracks];
    let   fetched  = 1;

    for (let start = 2; start <= totalPages; start += BATCH_SIZE) {
      const batchNums = [];
      for (let p = start; p < start + BATCH_SIZE && p <= totalPages; p++) {
        batchNums.push(p);
      }

      const batchResults = await Promise.all(
        batchNums.map(p => this._fetch('user.getRecentTracks', { ...baseParams, page: p }))
      );

      for (let i = 0; i < batchResults.length; i++) {
        const data   = batchResults[i];
        const raw    = data.recenttracks?.track || [];
        const tracks = (Array.isArray(raw) ? raw : [raw])
                         .filter(tr => !tr['@attr']?.nowplaying);
        allPages[batchNums[i] - 1] = tracks;
        fetched++;
        if (onProgress) {
          const countSoFar = allPages.reduce((acc, p) => acc + (p?.length || 0), 0);
          onProgress(fetched, totalPages, countSoFar, true);
        }
      }

      if (start + BATCH_SIZE <= totalPages) await sleep(100);
    }

    return allPages.flat();
  },
};

const sleep     = ms => new Promise(r => setTimeout(r, ms));
const escHtml   = str => String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const formatNum = n   => (n === null || n === undefined || n === '') ? '—' : Number(n).toLocaleString();
const isDefaultImg = url => !url || url.includes(DEFAULT_IMG) || url.length < 10;

function formatDate(unixTs) {
  if (!unixTs) return '—';
  return new Date(unixTs * 1000).toLocaleDateString(undefined, { year:'numeric', month:'long', day:'numeric' });
}

function timeAgo(unixTs) {
  if (!unixTs) return '';
  const diff = Date.now() - unixTs * 1000;
  const days = Math.floor(diff / 86400000);
  if (days === 0) {
    const h = Math.floor(diff / 3600000);
    if (h === 0) return t('time_few_min');
    return t('time_hours', h);
  }
  if (days === 1)  return t('time_yesterday');
  if (days < 30)  return t('time_days', days);
  if (days < 365) return t('time_months', Math.floor(days / 30));
  return t('time_years', Math.floor(days / 365));
}

function nameToGradient(name = '?') {
  let hash = 5381;
  for (let i = 0; i < name.length; i++) hash = ((hash << 5) + hash) ^ name.charCodeAt(i);
  const h1 = Math.abs(hash) % 360, h2 = (h1 + 42) % 360;
  return `linear-gradient(135deg,hsl(${h1},62%,38%),hsl(${h2},70%,52%))`;
}

function estimateListenTime(scrobbles) {
  const totalMin = Math.round(scrobbles * 3.5);
  const hours    = Math.floor(totalMin / 60);
  const minutes  = totalMin % 60;
  return hours > 0 ? `≈ ${formatNum(hours)}h ${minutes}min` : `≈ ${minutes}min`;
}

function destroyChart(id) {
  // 1. Détruire via notre registre interne
  if (APP.charts[id]) {
    try { APP.charts[id].destroy(); } catch {}
    delete APP.charts[id];
  }
  // 2. Vérifier aussi le registre interne de Chart.js (évite "Canvas is already in use")
  //    Chart.getChart() est dispo depuis Chart.js v3.2
  try {
    const canvasEl = document.getElementById(id);
    if (canvasEl && typeof Chart !== 'undefined') {
      const existing = Chart.getChart(canvasEl);
      if (existing) { existing.destroy(); }
    }
  } catch {}
}

function animateValue(el, from, to, duration = 900) {
  const start  = performance.now();
  const update = now => {
    const p    = Math.min((now - start) / duration, 1);
    const ease = 1 - Math.pow(1 - p, 3);
    el.textContent = formatNum(Math.round(from + (to - from) * ease));
    if (p < 1) requestAnimationFrame(update);
  };
  requestAnimationFrame(update);
}

function showToast(msg, type = 'success') {
  const el  = document.getElementById('toast');
  const ico = document.getElementById('toast-icon');
  if (!el) return;
  document.getElementById('toast-txt').textContent = msg;
  ico.className  = type === 'error' ? 'fas fa-times-circle' : 'fas fa-check-circle';
  ico.style.color= type === 'error' ? '#f87171' : '#22c55e';
  el.classList.add('show');
  clearTimeout(el._t);
  el._t = setTimeout(() => el.classList.remove('show'), 3200);
}

function showSetupError(msg) {
  const el = document.getElementById('setup-err');
  if (el) { document.getElementById('setup-err-txt').textContent = msg; el.classList.remove('hidden'); }
}

function errMsg(e) {
  return `<p style="color:var(--text-muted);grid-column:1/-1;padding:20px">
    <i class="fas fa-exclamation-triangle" style="color:#f97316"></i> ${escHtml(e.message)}
  </p>`;
}

function skeletonMusicCards(n = 8) {
  return Array(n).fill(0).map((_,i) => `
    <div class="music-card sk" style="animation-delay:${i*0.04}s">
      <div class="music-card-img" style="height:160px"><div class="sk-ln" style="width:100%;height:100%;border-radius:0"></div></div>
      <div class="music-card-body"><div class="sk-ln w80"></div><div class="sk-ln w60 mt8"></div></div>
    </div>`).join('');
}

function skeletonTrackItems(n = 10) {
  return Array(n).fill(0).map((_,i) => `
    <div class="track-item sk" style="animation-delay:${i*0.03}s">
      <div class="sk-ln" style="width:36px;height:36px;border-radius:6px;flex-shrink:0"></div>
      <div style="flex:1;display:flex;flex-direction:column;gap:6px">
        <div class="sk-ln w80"></div><div class="sk-ln w50"></div>
      </div>
    </div>`).join('');
}

function getThemeColors() {
  const isDark = APP.currentTheme === 'dark'
    || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme:dark)').matches);
  return {
    grid:   isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.06)',
    text:   isDark ? '#64748b' : '#64748b',
    bg:     isDark ? '#131320' : '#ffffff',
    isDark,
  };
}

function baseChartOpts(extras = {}) {
  const c = getThemeColors();
  return {
    responsive:true, maintainAspectRatio:false,
    animation:{ duration:600, easing:'easeOutQuart' },
    plugins:{
      legend:{ display:false },
      tooltip:{
        backgroundColor: c.isDark ? 'rgba(15,15,35,.95)' : 'rgba(255,255,255,.95)',
        titleColor: c.isDark ? '#e2e8f0' : '#0f172a',
        bodyColor:  c.isDark ? '#94a3b8' : '#475569',
        borderColor:'rgba(99,102,241,.2)', borderWidth:1,
        cornerRadius:8, padding:10,
      },
    },
    scales:{
      x:{ grid:{ color:c.grid }, ticks:{ color:c.text, font:{ size:11 } } },
      y:{ grid:{ color:c.grid }, ticks:{ color:c.text, font:{ size:11 } } },
    },
    ...extras,
  };
}

function updateAllChartThemes() {
  _invalidatePalCache();
  const c   = getThemeColors();
  const pal = getAccentPalette(15);

  Object.values(APP.charts).forEach(chart => {
    if (!chart?.options) return;

    // Update grid + tick colors
    if (chart.options.scales) {
      Object.values(chart.options.scales).forEach(sc => {
        if (sc.grid)  sc.grid.color  = c.grid;
        if (sc.ticks) sc.ticks.color = c.text;
        if (sc.pointLabels) sc.pointLabels.color = c.text;
      });
    }

    // Update tooltip background
    if (chart.options.plugins?.tooltip) {
      chart.options.plugins.tooltip.backgroundColor = c.isDark ? 'rgba(15,15,35,.95)' : 'rgba(255,255,255,.95)';
      chart.options.plugins.tooltip.titleColor = c.isDark ? '#e2e8f0' : '#0f172a';
      chart.options.plugins.tooltip.bodyColor  = c.isDark ? '#94a3b8' : '#475569';
    }

    // Update legend label color
    if (chart.options.plugins?.legend?.labels) {
      chart.options.plugins.legend.labels.color = c.text;
    }

    // Rebuild dataset colors from current accent palette
    (chart.data?.datasets || []).forEach((ds, di) => {
      const base = pal[di % pal.length];
      // Array backgroundColor (bar/donut charts) — rebuild from palette
      if (Array.isArray(ds.backgroundColor) && ds.backgroundColor.length > 1) {
        ds.backgroundColor = ds.backgroundColor.map((_, i) => {
          const col = pal[i % pal.length];
          // Preserve alpha suffix if original had one (e.g. "99", "aa", "bb", "22")
          const alpha = /^hsl/.test(col) ? '' : '';
          return col + (col.length <= 7 ? 'bb' : '');
        });
      }
      if (Array.isArray(ds.borderColor) && ds.borderColor.length > 1) {
        ds.borderColor = ds.borderColor.map((_, i) => pal[i % pal.length]);
      }
      // Single-value borderColor for line charts
      if (typeof ds.borderColor === 'string' && ds._usesAccent) {
        ds.borderColor = base;
      }
      // pointBackgroundColor (radar)
      if (Array.isArray(ds.pointBackgroundColor) && ds.pointBackgroundColor.length > 1) {
        ds.pointBackgroundColor = ds.pointBackgroundColor.map((_, i) => pal[i % pal.length]);
      }
    });

    chart.update('none');
  });
}

const saveSession  = () => { if (APP.username) localStorage.setItem('ls_username', APP.username); if (APP.apiKey) localStorage.setItem('ls_apikey', APP.apiKey); };
const clearSession = () => { localStorage.removeItem('ls_username'); localStorage.removeItem('ls_apikey'); };
const loadSavedCredentials = () => ({ username: localStorage.getItem('ls_username') || '', apiKey: localStorage.getItem('ls_apikey') || '' });

function setTintedBackground(enabled) {
  localStorage.setItem('ls_tint_bg', enabled ? '1' : '0');
  APP.tintBg = enabled;
  const toggle = document.getElementById('tint-bg-toggle');
  if (toggle) toggle.checked = enabled;

  if (!enabled) {
    // Restore plain backgrounds from CSS variable defaults
    const r = document.documentElement.style;
    const isDark = APP.currentTheme === 'dark' || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme:dark)').matches);
    if (isDark) {
      r.setProperty('--bg',                       '#141218');
      r.setProperty('--bg-dim',                   '#0f0d13');
      r.setProperty('--bg-card',                  '#1d1b20');
      r.setProperty('--bg-card-hi',               '#211f26');
      r.setProperty('--bg-sidebar',               '#1c1b1f');
      r.setProperty('--bg-header',                '#1c1b1f');
      r.setProperty('--bg-hover',                 '#2b2930');
      r.setProperty('--bg-elevated',              '#36343b');
      r.setProperty('--surface-container-low',    '#1d1b20');
      r.setProperty('--surface-container',        '#211f26');
      r.setProperty('--surface-container-high',   '#2b2930');
      r.setProperty('--surface-container-highest','#36343b');
    } else {
      r.setProperty('--bg',                       '#f4f4f5');
      r.setProperty('--bg-dim',                   '#e8e8ea');
      r.setProperty('--bg-card',                  '#ffffff');
      r.setProperty('--bg-card-hi',               '#ffffff');
      r.setProperty('--bg-sidebar',               '#ffffff');
      r.setProperty('--bg-header',                '#ffffff');
      r.setProperty('--bg-hover',                 '#ececee');
      r.setProperty('--bg-elevated',              '#e2e2e5');
      r.setProperty('--surface-container-low',    '#f4f4f5');
      r.setProperty('--surface-container',        '#eeeeef');
      r.setProperty('--surface-container-high',   '#e8e8ea');
      r.setProperty('--surface-container-highest','#e2e2e5');
    }
  } else {
    // Re-apply hue tint
    setAccent(APP.currentAccent || localStorage.getItem('ls_accent') || 'purple');
  }
}

function setTheme(theme) {
  APP.currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  localStorage.setItem('ls_theme', theme);
  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === theme));
  updateAllChartThemes();
  const accent = APP.currentAccent || localStorage.getItem('ls_accent') || 'purple';
  if (accent && accent !== 'dynamic') {
    setAccent(accent); // re-applies palette + hue tint for new light/dark context
  } else {
    // dynamic: re-run colorThief with new darkness context
    const npImg = document.querySelector('#np-art img');
    if (npImg?.complete && npImg.naturalWidth > 0) _applyColorThiefFromEl(npImg);
  }
}

function applyTheme(theme) {
  APP.currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === theme));
}

function toggleApiKey() {
  const inp = document.getElementById('input-apikey');
  const ico = document.getElementById('eye-icon');
  if (!inp) return;
  inp.type      = inp.type === 'password' ? 'text' : 'password';
  ico.className = inp.type === 'password' ? 'fas fa-eye' : 'fas fa-eye-slash';
}

// Toggle clé API dans les paramètres
function toggleSettingsApiKey() {
  const inp = document.getElementById('settings-apikey');
  const ico = document.getElementById('settings-eye-icon');
  if (!inp) return;
  inp.type      = inp.type === 'password' ? 'text' : 'password';
  ico.className = inp.type === 'password' ? 'fas fa-eye' : 'fas fa-eye-slash';
}

// Mise à jour du pseudo depuis les paramètres
function updateUsername() {
  const el  = document.getElementById('settings-username');
  const val = (el?.value || '').trim();
  if (!val) { showToast(t('setup_err_username'), 'error'); return; }
  APP.username = val;
  saveSession();
  showToast(t('toast_settings_saved'));
  setupProfileUI();
}

// Mise à jour de la clé API depuis les paramètres
function updateApiKey() {
  const el  = document.getElementById('settings-apikey');
  const val = (el?.value || '').trim();
  if (!val || val.length < 30) { showToast(t('setup_err_apikey'), 'error'); return; }
  APP.apiKey = val;
  saveSession();
  showToast(t('toast_settings_saved'));
}

// Wrapper export (appelé par les boutons HTML)
function exportStats(format) {
  exportData(format);
}

// Wrapper clear cache (appelé par le bouton HTML)
function clearAppCache() {
  clearCache();
}

const _ACCENT_DARK  = {
  purple:{ hue:270, accent:'#d0bcff', h:'#b89af7', a2:'#ccc2dc', container:'#4f378b', on:'#381e72', onCont:'#eaddff', glow:'rgba(208,188,255,.18)', lt:'rgba(208,188,255,.12)', strip:'rgba(208,188,255,.55)', borderGlow:'rgba(208,188,255,.35)' },
  blue:  { hue:210, accent:'#9ecaff', h:'#7bafef', a2:'#aab9cc', container:'#004a77', on:'#001d36', onCont:'#cde5ff', glow:'rgba(158,202,255,.18)', lt:'rgba(158,202,255,.12)', strip:'rgba(158,202,255,.55)', borderGlow:'rgba(158,202,255,.35)' },
  green: { hue:130, accent:'#78dc77', h:'#56bf55', a2:'#88bb88', container:'#1e5c1c', on:'#002105', onCont:'#94f990', glow:'rgba(120,220,119,.18)', lt:'rgba(120,220,119,.12)', strip:'rgba(120,220,119,.55)', borderGlow:'rgba(120,220,119,.35)' },
  red:   { hue:  4, accent:'#ffb4ab', h:'#e08077', a2:'#c9b3b0', container:'#93000a', on:'#690005', onCont:'#ffdad6', glow:'rgba(255,180,171,.18)', lt:'rgba(255,180,171,.12)', strip:'rgba(255,180,171,.55)', borderGlow:'rgba(255,180,171,.35)' },
  orange:{ hue: 28, accent:'#ffb77c', h:'#e09050', a2:'#c9aa90', container:'#6d3400', on:'#3d1d00', onCont:'#ffdcc0', glow:'rgba(255,183,124,.18)', lt:'rgba(255,183,124,.12)', strip:'rgba(255,183,124,.55)', borderGlow:'rgba(255,183,124,.35)' },
  pink:  { hue:330, accent:'#ffb2c8', h:'#e0809a', a2:'#ccb0bb', container:'#810042', on:'#520028', onCont:'#ffd9e3', glow:'rgba(255,178,200,.18)', lt:'rgba(255,178,200,.12)', strip:'rgba(255,178,200,.55)', borderGlow:'rgba(255,178,200,.35)' },
  teal:  { hue:180, accent:'#80d8d0', h:'#55bdb5', a2:'#90c0bc', container:'#006060', on:'#003737', onCont:'#9ef1e8', glow:'rgba(128,216,208,.18)', lt:'rgba(128,216,208,.12)', strip:'rgba(128,216,208,.55)', borderGlow:'rgba(128,216,208,.35)' },
  yellow:{ hue: 46, accent:'#e8c84a', h:'#c9a820', a2:'#c8b870', container:'#614400', on:'#3a2800', onCont:'#ffe08c', glow:'rgba(232,200,74,.18)',  lt:'rgba(232,200,74,.12)',  strip:'rgba(232,200,74,.55)',  borderGlow:'rgba(232,200,74,.35)'  },
};
const _ACCENT_LIGHT = {
  purple:{ hue:270, accent:'#6750a4', h:'#4f378b', a2:'#625b71', container:'#eaddff', on:'#ffffff', onCont:'#21005d', glow:'rgba(103,80,164,.3)',  lt:'rgba(103,80,164,.1)',  strip:'rgba(103,80,164,.50)', borderGlow:'rgba(103,80,164,.30)' },
  blue:  { hue:210, accent:'#0061a4', h:'#004a77', a2:'#3a6f8f', container:'#cde5ff', on:'#ffffff', onCont:'#001d36', glow:'rgba(0,97,164,.3)',    lt:'rgba(0,97,164,.1)',    strip:'rgba(0,97,164,.50)',   borderGlow:'rgba(0,97,164,.30)'   },
  green: { hue:130, accent:'#006e1c', h:'#004c13', a2:'#396b3e', container:'#94f990', on:'#ffffff', onCont:'#002105', glow:'rgba(0,110,28,.3)',    lt:'rgba(0,110,28,.1)',    strip:'rgba(0,110,28,.50)',   borderGlow:'rgba(0,110,28,.30)'   },
  red:   { hue:  4, accent:'#ba1a1a', h:'#930014', a2:'#8c3a3a', container:'#ffdad6', on:'#ffffff', onCont:'#410002', glow:'rgba(186,26,26,.3)',   lt:'rgba(186,26,26,.1)',   strip:'rgba(186,26,26,.50)',  borderGlow:'rgba(186,26,26,.30)'  },
  orange:{ hue: 28, accent:'#9c4e00', h:'#6d3400', a2:'#7a5030', container:'#ffdcc0', on:'#ffffff', onCont:'#3d1d00', glow:'rgba(156,78,0,.3)',    lt:'rgba(156,78,0,.1)',    strip:'rgba(156,78,0,.50)',   borderGlow:'rgba(156,78,0,.30)'   },
  pink:  { hue:330, accent:'#9c0057', h:'#6e003b', a2:'#8c3b65', container:'#ffd9e3', on:'#ffffff', onCont:'#3e0022', glow:'rgba(156,0,87,.3)',    lt:'rgba(156,0,87,.1)',    strip:'rgba(156,0,87,.50)',   borderGlow:'rgba(156,0,87,.30)'   },
  teal:  { hue:180, accent:'#006b66', h:'#004b47', a2:'#3a6b68', container:'#9ef1e8', on:'#ffffff', onCont:'#00201e', glow:'rgba(0,107,102,.3)',   lt:'rgba(0,107,102,.1)',   strip:'rgba(0,107,102,.50)',  borderGlow:'rgba(0,107,102,.30)'  },
  yellow:{ hue: 46, accent:'#6c5c00', h:'#4a4000', a2:'#625e40', container:'#ffe08c', on:'#ffffff', onCont:'#201b00', glow:'rgba(108,92,0,.3)',    lt:'rgba(108,92,0,.1)',    strip:'rgba(108,92,0,.50)',   borderGlow:'rgba(108,92,0,.30)'   },
};

function setAccent(colorKey) {
  APP.currentAccent = colorKey;
  localStorage.setItem('ls_accent', colorKey);
  _invalidatePalCache(); // refrais la palette accent pour les graphiques
  document.querySelectorAll('.acc-dot').forEach(b => b.classList.toggle('active', b.dataset.color === colorKey));

  if (colorKey === 'dynamic') {
    const npImg = document.querySelector('#np-art img');
    if (npImg?.complete && npImg.naturalWidth > 0) _applyColorThiefFromEl(npImg);
    return;
  }

  if (colorKey === 'custom') {
    const hex = localStorage.getItem('ls_accent_custom') || '#d0bcff';
    _syncCustomDotColor(hex);
    const inp = document.getElementById('acc-custom-input');
    if (inp) inp.value = hex;
    const isDark = APP.currentTheme === 'dark' || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme:dark)').matches);
    _applyCSSAccent(_hexToPalette(hex, isDark));
    updateAllChartThemes();
    return;
  }

  const isDark = APP.currentTheme === 'dark' || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme:dark)').matches);
  const pal    = (isDark ? _ACCENT_DARK : _ACCENT_LIGHT)[colorKey] || _ACCENT_DARK.purple;
  _applyCSSAccent(pal);
  updateAllChartThemes();
}

function _applyCSSAccent({ accent, h, a2, container, on, onCont, glow, lt, strip, borderGlow, hue }) {
  const r = document.documentElement.style;
  r.setProperty('--accent',           accent);
  r.setProperty('--accent-h',         h         || accent);
  r.setProperty('--accent-2',         a2        || accent);
  r.setProperty('--accent-container', container);
  r.setProperty('--accent-on',        on);
  r.setProperty('--accent-on-cont',   onCont);
  r.setProperty('--accent-glow',      glow);
  r.setProperty('--accent-lt',        lt);
  r.setProperty('--accent-strip',     strip     || glow);
  r.setProperty('--border-glow',      borderGlow || glow);

  // Tinted backgrounds based on hue angle
  if (hue !== undefined && hue !== null) {
    _applyHueTint(hue);
  }
}

function _applyHueTint(hue) {
  // Respect user toggle — default ON
  if (APP.tintBg === false || localStorage.getItem('ls_tint_bg') === '0') return;
  const isDark = APP.currentTheme === 'dark' || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme:dark)').matches);
  const r = document.documentElement.style;
  if (isDark) {
    // Dark mode: very dark tinted surfaces
    r.setProperty('--bg',                     `hsl(${hue},18%,7%)`);
    r.setProperty('--bg-dim',                 `hsl(${hue},16%,5%)`);
    r.setProperty('--bg-card',                `hsl(${hue},14%,11%)`);
    r.setProperty('--bg-card-hi',             `hsl(${hue},13%,13%)`);
    r.setProperty('--bg-sidebar',             `hsl(${hue},15%,10%)`);
    r.setProperty('--bg-header',              `hsl(${hue},15%,10%)`);
    r.setProperty('--bg-hover',               `hsl(${hue},14%,17%)`);
    r.setProperty('--bg-elevated',            `hsl(${hue},13%,19%)`);
    r.setProperty('--surface-container-low',  `hsl(${hue},14%,11%)`);
    r.setProperty('--surface-container',      `hsl(${hue},14%,13%)`);
    r.setProperty('--surface-container-high', `hsl(${hue},13%,17%)`);
    r.setProperty('--surface-container-highest', `hsl(${hue},12%,21%)`);
  } else {
    // Light mode: very light tinted surfaces
    r.setProperty('--bg',                     `hsl(${hue},30%,97%)`);
    r.setProperty('--bg-dim',                 `hsl(${hue},25%,93%)`);
    r.setProperty('--bg-card',                `hsl(${hue},20%,100%)`);
    r.setProperty('--bg-card-hi',             `hsl(${hue},20%,100%)`);
    r.setProperty('--bg-sidebar',             `hsl(${hue},20%,99%)`);
    r.setProperty('--bg-header',              `hsl(${hue},20%,99%)`);
    r.setProperty('--bg-hover',               `hsl(${hue},25%,92%)`);
    r.setProperty('--bg-elevated',            `hsl(${hue},22%,88%)`);
    r.setProperty('--surface-container-low',  `hsl(${hue},25%,96%)`);
    r.setProperty('--surface-container',      `hsl(${hue},24%,93%)`);
    r.setProperty('--surface-container-high', `hsl(${hue},23%,90%)`);
    r.setProperty('--surface-container-highest', `hsl(${hue},22%,87%)`);
  }
}

const _colorThief = typeof ColorThief !== 'undefined' ? new ColorThief() : null;

function _applyColorThiefFromUrl(imgUrl) {
  if (!_colorThief) return;
  const img = new Image(); img.crossOrigin = 'anonymous';
  img.onload = () => _applyColorThiefFromEl(img); img.src = imgUrl;
}

function _applyColorThiefFromEl(imgEl) {
  if (!_colorThief || !imgEl) return;
  try {
    const [r, g, b] = _colorThief.getColor(imgEl);
    const hue = _rgbToHsl(r, g, b)[0];
    _applyCSSAccent({
      hue,
      accent:     `hsl(${hue},65%,75%)`,
      h:          `hsl(${hue},60%,65%)`,
      a2:         `hsl(${hue},30%,72%)`,
      container:  `hsl(${hue},45%,28%)`,
      on:         `hsl(${hue},45%,14%)`,
      onCont:     `hsl(${hue},65%,90%)`,
      glow:       `hsla(${hue},65%,75%,.18)`,
      lt:         `hsla(${hue},65%,75%,.12)`,
      strip:      `hsla(${hue},65%,75%,.55)`,
      borderGlow: `hsla(${hue},65%,75%,.35)`,
    });
  } catch {}
}

function _rgbToHsl(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r,g,b), min = Math.min(r,g,b);
  let h, s; const l = (max + min) / 2;
  if (max === min) { h = s = 0; } else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
      case g: h = ((b - r) / d + 2) / 6; break;
      default: h = ((r - g) / d + 4) / 6;
    }
  }
  return [Math.round(h * 360), Math.round(s * 100), Math.round(l * 100)];
}

function _hexToPalette(hex, isDark) {
  const rv = parseInt(hex.slice(1,3),16);
  const gv = parseInt(hex.slice(3,5),16);
  const bv = parseInt(hex.slice(5,7),16);
  const [h] = _rgbToHsl(rv, gv, bv);
  if (isDark) {
    return {
      hue: h,
      accent:     `hsl(${h},65%,75%)`,
      h:          `hsl(${h},60%,65%)`,
      a2:         `hsl(${h},30%,72%)`,
      container:  `hsl(${h},45%,28%)`,
      on:         `hsl(${h},45%,14%)`,
      onCont:     `hsl(${h},65%,90%)`,
      glow:       `hsla(${h},65%,75%,.18)`,
      lt:         `hsla(${h},65%,75%,.12)`,
      strip:      `hsla(${h},65%,75%,.55)`,
      borderGlow: `hsla(${h},65%,75%,.35)`,
    };
  } else {
    return {
      hue: h,
      accent:     `hsl(${h},50%,40%)`,
      h:          `hsl(${h},55%,30%)`,
      a2:         `hsl(${h},25%,45%)`,
      container:  `hsl(${h},60%,88%)`,
      on:         `#ffffff`,
      onCont:     `hsl(${h},60%,12%)`,
      glow:       `hsla(${h},50%,40%,.30)`,
      lt:         `hsla(${h},50%,40%,.10)`,
      strip:      `hsla(${h},50%,40%,.50)`,
      borderGlow: `hsla(${h},50%,40%,.30)`,
    };
  }
}

function _syncCustomDotColor(hex) {
  const dot = document.getElementById('acc-custom-wrap');
  if (dot) dot.style.setProperty('--custom-dot-bg', hex);
}

function setCustomAccent(hex) {
  if (!hex) return;
  localStorage.setItem('ls_accent_custom', hex);
  APP.currentAccent = 'custom';
  localStorage.setItem('ls_accent', 'custom');
  _invalidatePalCache();
  document.querySelectorAll('.acc-dot').forEach(b => b.classList.toggle('active', b.dataset.color === 'custom'));
  _syncCustomDotColor(hex);
  const isDark = APP.currentTheme === 'dark' || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme:dark)').matches);
  _applyCSSAccent(_hexToPalette(hex, isDark));
  updateAllChartThemes();
}

const NAV_TITLE_KEYS = {
  dashboard:     'nav_dashboard',
  'top-artists': 'nav_top_artists',
  'top-albums':  'nav_top_albums',
  'top-tracks':  'nav_top_tracks',
  charts:        'nav_charts',
  obscurity:     'nav_obscurity',
  history:       'nav_history',
  wrapped:       'nav_wrapped',
  compare:       'nav_compare',
  settings:      'nav_settings',
  profile:       'nav_profile',
};

function setLanguage(lang) {
  if (!window.I18N?.setLang) return;
  localStorage.setItem('ls_lang', lang);
  APP.language = lang;
  window.I18N.setLang(lang);
  document.documentElement.lang = lang; // ← sync <html lang="">

  requestAnimationFrame(() => {
    document.querySelectorAll('.lang-btn').forEach(b =>
      b.classList.toggle('active', b.dataset.lang === lang)
    );
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const raw = el.getAttribute('data-i18n');
      const key = raw.replace(/\./g, '_');
      const val = t(key) || t(raw);
      if (val && val !== key && val !== raw) el.textContent = val;
    });
    document.querySelectorAll('.nav-lnk[data-s], .bn-item[data-s]').forEach(el => {
      const key  = NAV_TITLE_KEYS[el.dataset.s];
      const span = el.querySelector('span:not(.nav-bdg)');
      if (key && span) span.textContent = t(key);
    });
    const activeSection = document.querySelector('.app-sec.active')?.id?.replace('s-', '');
    if (activeSection) {
      const key = NAV_TITLE_KEYS[activeSection];
      if (key) document.getElementById('hd-title').textContent = t(key);
    }
    document.title = 'LastStats — ' + (t('nav_dashboard') || 'Statistiques Last.fm');
    showToast(t('toast_lang_changed'));
  });
}

function _updateNavMode() {
  const isMobile = window.innerWidth <= 768;
  document.body.classList.toggle('nav-mode-bottom', isMobile);
  if (isMobile) {
    document.getElementById('sidebar')?.classList.remove('open');
    document.getElementById('sidebar-ov')?.classList.remove('open');
    document.body.style.overflow = '';
  }
}

async function initApp(usernameOverride, apiKeyOverride) {
  const username = (usernameOverride || document.getElementById('input-username')?.value || '').trim();
  const apiKey   = (apiKeyOverride   || document.getElementById('input-apikey')?.value   || '').trim();

  document.getElementById('setup-err')?.classList.add('hidden');

  if (!username)                     { showSetupError(t('setup_err_username')); return; }
  if (!apiKey || apiKey.length < 30) { showSetupError(t('setup_err_apikey'));   return; }

  APP.apiKey   = apiKey;
  APP.username = username;

  const btn = document.getElementById('load-btn');
  if (btn) { btn.disabled = true; btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${t('setup_btn_loading')}`; }

  try {
    const info = await API.call('user.getInfo', {}, true);
    APP.userInfo = info.user;
    APP.regYear  = new Date(parseInt(info.user.registered?.unixtime || 0) * 1000).getFullYear() || new Date().getFullYear() - 5;

    saveSession();

    const theme = localStorage.getItem('ls_theme') || 'dark';
    applyTheme(theme);

    document.getElementById('setup-screen')?.classList.add('hidden');
    document.getElementById('app')?.classList.remove('hidden');

    setupProfileUI();
    _updateNavMode();

    await loadDashboard();
    const savedSection = localStorage.getItem('ls_section');
    if (savedSection && document.getElementById('s-' + savedSection)) {
      if (savedSection === 'profile') {
        // Pour le profil, on doit charger les données, pas juste naviguer
        openProfilePage();
      } else {
        nav(savedSection);
      }
    }

    Promise.all([
      loadTopArtists('overall'),
      loadTopAlbums('overall'),
      loadTopTracks('overall'),
    ]).then(() => loadMoodTags());

    setupChartsSection();
    setupWrappedSection();
    initPeriodSelectors();
    pollNowPlaying();
    loadVersus();

    syncSettingsFields();

    // nav visibility
    loadNavVisibility();
    renderNavVisibilitySettings();

    // history section — start on today
    histInit();

    // New Year Wrapped notification
    setupNewYearNotification();
    _syncNotifBtn();

    const savedAccent = localStorage.getItem('ls_accent') || 'purple';
    APP.currentAccent = savedAccent;
    if (savedAccent === 'custom') {
      const customHex = localStorage.getItem('ls_accent_custom') || '#d0bcff';
      _syncCustomDotColor(customHex);
      const inp = document.getElementById('acc-custom-input');
      if (inp) inp.value = customHex;
    }
    if (savedAccent !== 'dynamic') setAccent(savedAccent);

    setArtistsLayout(APP.artistsLayout);
    setAlbumsLayout(APP.albumsLayout);
    setTracksLayout(APP.tracksLayout);

    // language: saved preference first, then auto-detect
    const lang = localStorage.getItem('ls_lang') || window.I18N?.getLang?.() || 'fr';
    APP.language = lang;
    setLanguage(lang);

    _scheduleBackgroundHistoryFetch();

  } catch (err) {
    const msg = err.message.toLowerCase().includes('user not found') || err.message.includes('Invalid API')
      ? t('setup_err_invalid')
      : t('setup_err_generic', err.message);
    showSetupError(msg);
  } finally {
    if (btn) { btn.disabled = false; btn.innerHTML = `<i class="fas fa-chart-bar"></i> ${t('setup_btn_launch')}`; }
  }
}

let _bgHistoryTimer = null;

function _scheduleBackgroundHistoryFetch() {
  clearTimeout(_bgHistoryTimer);

  // Si un cache valide existe, on l'expose en mémoire immédiatement
  // (sections Historique, Badges, Streaks en bénéficient sans attendre)
  // mais on NE rend PAS les charts ici — _applyFullHistory sera appelé
  // une seule fois par fetchFullHistory pour éviter "Canvas already in use"
  const cached = _loadHistoryCache();
  if (cached?.tracks?.length) {
    APP.fullHistory = cached.tracks;
    APP.streakData  = calcStreak(cached.tracks);
    updateStreakUI(APP.streakData);
    console.log(`[History] Cache pre-loaded: ${cached.tracks.length} tracks`);

    // Mise à jour incrémentale légère en arrière-plan
    _bgHistoryTimer = setTimeout(async () => {
      await fetchFullHistory(true);
    }, 2000);
  } else {
    // Pas de cache — chargement complet différé
    _bgHistoryTimer = setTimeout(async () => {
      if (!APP.fullHistory?.length) await fetchFullHistory(true);
    }, 4000);
  }
}

window.addEventListener('DOMContentLoaded', () => {
  // Inject runtime styles
  const shareStyle = document.createElement('style');
  shareStyle.textContent = `
    .track-play-btn.share,.mc-play-btn.share{background:var(--accent-lt)!important;color:var(--accent)!important;border:1px solid var(--border-glow)!important}
    .track-play-btn.share:hover,.mc-play-btn.share:hover{background:var(--accent)!important;color:var(--accent-on)!important;transform:scale(1.12)}
    @media(max-width:768px){.section-toolbar .layout-btn{display:inline-flex!important}}
    .artist-tag-pill{display:inline-block;font-size:.62rem;padding:2px 7px;border-radius:99px;background:rgba(255,255,255,.14);color:rgba(255,255,255,.8);margin:2px 2px 0 0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:90px;vertical-align:middle}
    .artist-hero-tags{position:absolute;bottom:44px;left:10px;right:10px;display:flex;flex-wrap:wrap;z-index:3;pointer-events:none}
    .obs-art-img{width:44px;height:44px;border-radius:50%;overflow:hidden;flex-shrink:0;position:relative;display:flex;align-items:center;justify-content:center;background:var(--surface-2)}
    .obs-art-img img{width:100%;height:100%;object-fit:cover;position:absolute;inset:0}
    .obs-art-letter{font-size:1.1rem;font-weight:700;color:#fff;pointer-events:none;z-index:1}
  `;
  document.head.appendChild(shareStyle);

  // Apply saved theme immediately
  const theme = localStorage.getItem('ls_theme') || 'dark';
  document.documentElement.dataset.theme = theme;
  APP.currentTheme = theme;

  // Init tinted background setting
  APP.tintBg = localStorage.getItem('ls_tint_bg') !== '0';

  // Apply saved language
  const lang = localStorage.getItem('ls_lang') || window.I18N?.getLang?.() || 'fr';
  APP.language = lang;
  document.documentElement.lang = lang;
  if (window.I18N?.setLang) window.I18N.setLang(lang);

  requestAnimationFrame(() => {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const raw = el.getAttribute('data-i18n');
      const key = raw.replace(/\./g, '_');
      const val = t(key) || t(raw);
      if (val && val !== key && val !== raw) el.textContent = val;
    });
    document.querySelectorAll('.lang-btn').forEach(b =>
      b.classList.toggle('active', b.dataset.lang === lang)
    );
  });

  APP.artistsLayout = localStorage.getItem('ls_artists_layout') || 'grid';
  APP.albumsLayout  = localStorage.getItem('ls_albums_layout')  || 'grid';
  APP.tracksLayout  = localStorage.getItem('ls_tracks_layout')  || 'list';

  const { username, apiKey } = loadSavedCredentials();
  const setupScreen = document.getElementById('setup-screen');

  if (username && apiKey) {
    // Credentials exist — keep setup hidden, boot directly
    setupScreen?.classList.add('hidden');
    document.getElementById('app')?.classList.remove('hidden');
    setTimeout(() => initApp(username, apiKey), 0);
  } else {
    // No credentials — show setup, pre-fill any partial values
    setupScreen?.classList.remove('hidden');
    if (document.getElementById('input-username')) document.getElementById('input-username').value = username;
    if (document.getElementById('input-apikey'))   document.getElementById('input-apikey').value   = apiKey;
  }

  window.addEventListener('resize', _updateNavMode, { passive: true });
  _updateNavMode();
  document.getElementById('sw-update-btn')?.addEventListener('click', forceSwUpdate);
});

function nav(section) {
  if (section !== 'profile') {
    document.querySelector('.main-content')?.classList.remove('profile-active');
  }
  const doNav = () => {
    document.querySelectorAll('.nav-lnk, .bn-item').forEach(el =>
      el.classList.toggle('active', el.dataset.s === section)
    );
    document.querySelectorAll('.app-sec').forEach(el => el.classList.remove('active'));
    document.getElementById('s-' + section)?.classList.add('active');
    document.querySelector('.main-content')?.scrollTo({ top:0, behavior:'instant' });

    const titleKey = NAV_TITLE_KEYS[section];
    const titleEl  = document.getElementById('hd-title');
    if (titleEl) titleEl.textContent = titleKey ? t(titleKey) : section;

    localStorage.setItem('ls_section', section);

    if (window.innerWidth <= 1024) closeSb();

    if (section === 'charts')    setupChartsSection();
    if (section === 'obscurity') loadObscurityScore();
    if (section === 'history')   histLoadDay(APP.histCurrentDate || _todayStr());
    if (section === 'compare')   initComparePage();
    if (section === 'profile')   _initProfilePeriodButtons();
  };

  if (document.startViewTransition) {
    document.startViewTransition(doNav);
  } else {
    doNav();
  }
}

function openSb()  {
  document.getElementById('sidebar')?.classList.add('open');
  document.getElementById('sidebar-ov')?.classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeSb() {
  document.getElementById('sidebar')?.classList.remove('open');
  document.getElementById('sidebar-ov')?.classList.remove('open');
  document.body.style.overflow = '';
}

function setupProfileUI() {
  const u = APP.userInfo;
  if (!u) return;

  const letter = (u.name || '?')[0].toUpperCase();
  const imgUrl = u.image?.find(i => i.size === 'medium')?.['#text'] || '';
  const grad   = nameToGradient(u.name);

  const sbAv = document.getElementById('sb-av');
  if (sbAv) {
    if (imgUrl && !isDefaultImg(imgUrl)) {
      const fallbackHTML = `<div style="width:100%;height:100%;background:${grad};display:flex;align-items:center;justify-content:center;font-weight:700;color:white;font-size:1.1rem">${letter}</div>`;
      sbAv.innerHTML = `<img src="${imgUrl}" alt="Avatar" style="width:100%;height:100%;object-fit:cover" onerror="this.outerHTML=${JSON.stringify(fallbackHTML)}">`;
    } else {
      sbAv.innerHTML = `<div style="width:100%;height:100%;background:${grad};display:flex;align-items:center;justify-content:center;font-weight:700;color:white;font-size:1.1rem">${letter}</div>`;
    }
  }

  const setText = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  setText('sb-name',    u.name || APP.username);
  setText('sb-plays',   formatNum(u.playcount) + ' ' + t('scrobbles'));
  if (u.country) setText('sb-country', u.country);
  setText('hd-mini-user', '@' + (u.name || APP.username));
}

/* ─── Profile bubble (sidebar dropdown) ─── */

let _profileBubbleOpen = false;

/* Dropdown profil supprimé — fonctions conservées pour compatibilité */
function toggleProfileBubble() { openProfilePage(); }
function openProfileBubble()   {}
function closeProfileBubble()  { _profileBubbleOpen = false; }
function _bubbleOutsideClick() {}

/* ─── Profile section ─── */

// Stocke les données de l'ami en cours de consultation (évite JSON.stringify dans onclick)
let _profileUsername   = null;
let _profileFriendInfo = null;
let _profileCameFrom   = null; // section de retour

function openProfilePage(username, friendInfoKey, cameFrom) {
  closeProfileBubble();
  if (window.innerWidth <= 1024) closeSb();

  _profileUsername = username || null;
  // Si friendInfoKey est fourni, récupérer dans le cache global
  _profileFriendInfo = friendInfoKey ? (window._vsProfileCache?.[friendInfoKey] || null) : null;
  _profileCameFrom   = cameFrom || (username && username !== APP.username ? 'compare' : null);

  const backBar   = document.getElementById('profile-back-bar');
  const backLabel = document.getElementById('profile-back-label');
  if (backBar) {
    if (_profileCameFrom) {
      backBar.classList.remove('hidden');
      if (backLabel) backLabel.textContent = username;
    } else {
      backBar.classList.add('hidden');
    }
  }

  nav('profile');
  // Supprime le padding de .main-content pour que le hero colle au header
  document.querySelector('.main-content')?.classList.add('profile-active');
  loadProfileSection(_profileUsername || APP.username, _profileFriendInfo);
}

function profileGoBack() {
  nav(_profileCameFrom || 'dashboard');
}

function _initProfilePeriodButtons() {
  const sel = document.getElementById('prd-profile');
  if (!sel || sel.dataset.bound === '1') return;
  sel.dataset.bound = '1';
  sel.querySelectorAll('.prd').forEach(btn => {
    btn.addEventListener('click', () => {
      sel.querySelectorAll('.prd').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      _loadProfileTopData(_profileUsername || APP.username, btn.dataset.p);
    });
  });
}

async function loadProfileSection(username, userInfoObj) {
  _profileSkeletons();
  const isOwn = !username || username === APP.username;

  try {
    const resolvedInfo = userInfoObj
      || (isOwn ? APP.userInfo : null)
      || await _apiFetchUser('user.getInfo', username, {}).then(d => d?.user || null);

    _renderProfileHero(username, resolvedInfo);
    _renderProfileStats(resolvedInfo);

    await Promise.all([
      _loadProfileTopData(username, '7day'),
      _loadProfileNowPlaying(username),
    ]);
  } catch (e) {
    showToast('Erreur profil : ' + e.message, 'error');
  }
}

function _profileSkeletons() {
  ['pstat-scrobbles','pstat-avg','pstat-peryear','pstat-days',
   'ptop-artist','ptop-album','ptop-track'].forEach(id => {
    const el = document.getElementById(id);
    if (el) { el.classList.add('sk'); el.innerHTML = '<div class="sk-ln w70"></div><div class="sk-ln w40 mt4"></div>'; }
  });
  const tl = document.getElementById('profile-tracks-list');
  if (tl) tl.innerHTML = [1,2,3,4,5].map(() =>
    '<div class="profile-track-sk sk"><div class="sk-ln w100"></div></div>'
  ).join('');
  document.getElementById('profile-np-wrap')?.classList.add('hidden');
}

function _renderProfileHero(username, ui) {
  const letter = (username || '?')[0].toUpperCase();
  const grad   = nameToGradient(username);

  // Image de profil (priorité : extralarge > large > medium)
  const imgUrl = ui?.image?.find(i => i.size === 'extralarge')?.['#text']
              || ui?.image?.find(i => i.size === 'large')?.['#text']
              || ui?.image?.find(i => i.size === 'medium')?.['#text'] || '';

  // Fond initial = photo de profil (sera remplacé par pochette nowplaying ou dernier titre)
  const bgEl = document.getElementById('profile-hero-bg');
  if (bgEl) {
    if (imgUrl && !isDefaultImg(imgUrl)) {
      bgEl.style.backgroundImage = `url('${imgUrl}')`;
      bgEl.style.background      = '';
    } else {
      bgEl.style.backgroundImage = '';
      bgEl.style.background      = grad;
    }
  }

  // Avatar centré
  const avEl = document.getElementById('profile-av');
  if (avEl) {
    if (imgUrl && !isDefaultImg(imgUrl)) {
      avEl.innerHTML = `<img src="${imgUrl}" alt="${escHtml(username)}" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">`;
    } else {
      avEl.innerHTML = `<div style="width:100%;height:100%;background:${grad};display:flex;align-items:center;justify-content:center;font-weight:700;color:white;font-size:2.2rem">${letter}</div>`;
    }
  }

  const _set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  _set('profile-username', username || '—');
  _set('profile-country',  ui?.country || '');

  if (ui?.registered?.unixtime) {
    const reg   = new Date(parseInt(ui.registered.unixtime) * 1000);
    const years = ((Date.now() - reg) / (1000*60*60*24*365.25)).toFixed(1);
    _set('profile-since', `Membre depuis ${reg.getFullYear()} · ${years} ans`);
  }
}

function _renderProfileStats(ui) {
  if (!ui) return;
  const total     = parseInt(ui.playcount || 0);
  const regTs     = parseInt(ui.registered?.unixtime || 0);
  const days      = regTs ? Math.floor((Date.now()/1000 - regTs) / 86400) : 1;
  const avgDay    = Math.round(total / Math.max(days, 1));
  const years     = days / 365.25;
  const perYear   = Math.round(total / Math.max(years, 0.1));

  const _chip = (id, icon, val, lbl) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.remove('sk');
    el.innerHTML = `<i class="fas fa-${icon}"></i><strong>${val}</strong><span>${lbl}</span>`;
  };
  _chip('pstat-scrobbles', 'headphones',     formatNum(total),   'Scrobbles');
  _chip('pstat-avg',       'chart-line',     '~' + avgDay,       'par jour');
  _chip('pstat-peryear',   'calendar-check', formatNum(perYear), 'par an');
  _chip('pstat-days',      'calendar-alt',   formatNum(days),    'jours actifs');
}

async function _loadProfileTopData(username, period) {
  ['ptop-artist','ptop-album','ptop-track'].forEach(id => {
    const el = document.getElementById(id);
    if (el) { el.classList.add('sk'); el.innerHTML = '<div class="sk-ln w80"></div><div class="sk-ln w50 mt8"></div>'; }
  });
  const trackList = document.getElementById('profile-tracks-list');
  if (trackList) trackList.innerHTML = [1,2,3,4,5].map(() =>
    '<div class="profile-track-sk sk"><div class="sk-ln w100"></div></div>'
  ).join('');

  try {
    const [artistsData, albumsData, tracksData] = await Promise.all([
      _apiFetchUser('user.getTopArtists', username, { period, limit: 1 }),
      _apiFetchUser('user.getTopAlbums',  username, { period, limit: 1 }),
      _apiFetchUser('user.getTopTracks',  username, { period, limit: 5 }),
    ]);

    const rawArtist = artistsData?.topartists?.artist;
    const artist    = Array.isArray(rawArtist) ? rawArtist[0] : rawArtist;

    const rawAlbum  = albumsData?.topalbums?.album;
    const album     = Array.isArray(rawAlbum) ? rawAlbum[0] : rawAlbum;

    const rawTracks = tracksData?.toptracks?.track || [];
    const tracks    = Array.isArray(rawTracks) ? rawTracks : [rawTracks];

    /* Stocker les MBIDs pour les futures requêtes Cover Art Archive */
    _extractAndStoreMbids(artistsData);
    _extractAndStoreMbids(albumsData);
    _extractAndStoreMbids(tracksData);

    _renderProfileTopCard('ptop-artist', 'microphone-alt', 'Artiste #1',
      artist?.name, artist?.playcount, artist?.image);
    _renderProfileTopCard('ptop-album',  'compact-disc',   'Album #1',
      album?.name,  album?.playcount,  album?.image, album?.artist?.name);
    const t1 = tracks[0];
    _renderProfileTopCard('ptop-track',  'music',          'Titre #1',
      t1?.name,     t1?.playcount,     t1?.image,    t1?.artist?.name);

    // Résolution asynchrone des images — toujours relancer après changement de période
    setTimeout(() => {
      _resolveTopCardImg('ptop-artist', 'artist', artist?.name, null);
      _resolveTopCardImg('ptop-album',  'album',  album?.name,  album?.artist?.name);
      _resolveTopCardImg('ptop-track',  'track',  t1?.name,     t1?.artist?.name);
    }, 0);

    if (trackList) {
      const top5 = tracks.slice(0, 5);
      // Rendu initial avec fallback couleur (instantané)
      trackList.innerHTML = top5.map((tr, i) => {
        const grad   = nameToGradient(tr?.name);
        const letter = (tr?.name || '?')[0];
        const trackUrl = tr?.name ? `https://www.last.fm/music/${encodeURIComponent(tr?.artist?.name||'')}/_/${encodeURIComponent(tr?.name||'')}` : '';
        return `<div class="profile-track-row" id="ptrack-row-${i}" role="link" tabindex="0"
          ${trackUrl ? `onclick="window.open('${trackUrl}','_blank','noopener')" onkeydown="if(event.key==='Enter')window.open('${trackUrl}','_blank','noopener')"` : ''}>
          <span class="ptrack-rank">${i + 1}</span>
          <div class="ptrack-img-fallback" id="ptrack-thumb-${i}" style="background:${grad}">${letter}</div>
          <div class="ptrack-info">
            <span class="ptrack-name">${escHtml(tr?.name || '—')}</span>
            <span class="ptrack-artist">${escHtml(tr?.artist?.name || '—')}</span>
          </div>
          <span class="ptrack-plays">${formatNum(tr?.playcount)}</span>
        </div>`;
      }).join('');
      // Résolution asynchrone des vraies pochettes via track.getInfo
      top5.forEach((tr, i) => _resolveProfileTrackImg(tr, i));
    }
  } catch (e) {
    console.warn('[Profile] _loadProfileTopData:', e);
  }
}

/**
 * Récupère la pochette d'un album via l'API iTunes (CORS natif, gratuit).
 * Retourne null si rien trouvé.
 */
async function _fetchAlbumImageiTunes(albumName, artistName) {
  try {
    const q = artistName ? `${artistName} ${albumName}` : albumName;
    const r = await fetch(
      `https://itunes.apple.com/search?term=${encodeURIComponent(q)}&entity=album&limit=5`,
      { signal: AbortSignal.timeout(4000) }
    );
    if (!r.ok) return null;
    const d = await r.json();
    const exact = d.results?.find(x =>
      x.collectionName?.toLowerCase().includes(albumName.toLowerCase()) ||
      albumName.toLowerCase().includes(x.collectionName?.toLowerCase() || '')
    );
    const hit = exact || d.results?.[0];
    return hit?.artworkUrl100
      ? hit.artworkUrl100.replace('100x100bb', '600x600bb').replace('/100x100/', '/600x600/')
      : null;
  } catch { return null; }
}

/**
 * Récupère la pochette d'un titre via iTunes (prend la pochette de l'album du titre).
 */
async function _fetchTrackImageiTunes(trackName, artistName) {
  try {
    const q = artistName ? `${artistName} ${trackName}` : trackName;
    const r = await fetch(
      `https://itunes.apple.com/search?term=${encodeURIComponent(q)}&entity=song&limit=5`,
      { signal: AbortSignal.timeout(4000) }
    );
    if (!r.ok) return null;
    const d = await r.json();
    const exact = d.results?.find(x =>
      x.trackName?.toLowerCase().includes(trackName.toLowerCase()) ||
      trackName.toLowerCase().includes(x.trackName?.toLowerCase() || '')
    );
    const hit = exact || d.results?.[0];
    return hit?.artworkUrl100
      ? hit.artworkUrl100.replace('100x100bb', '600x600bb').replace('/100x100/', '/600x600/')
      : null;
  } catch { return null; }
}

async function _resolveTopCardImg(cardId, type, name, artist) {
  if (!name) return;
  try {
    const el = document.getElementById(cardId);
    if (!el) return;
    const bgEl = el.querySelector('.ptc-bg');
    if (!bgEl) return;
    let img = '';

    if (type === 'artist') {
      // 1. Wikipedia EN
      try {
        const r = await fetch(
          `https://en.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(name)}&prop=pageimages&format=json&pithumbsize=800&origin=*`,
          { signal: AbortSignal.timeout(5000) }
        );
        if (r.ok) {
          const d = await r.json();
          for (const page of Object.values(d.query?.pages || {})) {
            if (page.thumbnail?.source && !page.missing) { img = page.thumbnail.source; break; }
          }
        }
      } catch {}
      // 2. Wikipedia FR
      if (!img) {
        try {
          const r = await fetch(
            `https://fr.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(name)}&prop=pageimages&format=json&pithumbsize=800&origin=*`,
            { signal: AbortSignal.timeout(4000) }
          );
          if (r.ok) {
            const d = await r.json();
            for (const page of Object.values(d.query?.pages || {})) {
              if (page.thumbnail?.source && !page.missing) { img = page.thumbnail.source; break; }
            }
          }
        } catch {}
      }
      // 3. iTunes artist
      if (!img) {
        try {
          const r = await fetch(
            `https://itunes.apple.com/search?term=${encodeURIComponent(name)}&entity=musicArtist&limit=5`,
            { signal: AbortSignal.timeout(5000) }
          );
          if (r.ok) {
            const d = await r.json();
            const exact = d.results?.find(a => a.artistName?.toLowerCase() === name.toLowerCase());
            const hit   = exact || d.results?.[0];
            if (hit?.artworkUrl100) img = hit.artworkUrl100.replace('100x100bb','600x600bb');
          }
        } catch {}
      }
      // 4. TheAudioDB
      if (!img) {
        try {
          const r = await fetch(`https://www.theaudiodb.com/api/v1/json/2/search.php?s=${encodeURIComponent(name)}`,
            { signal: AbortSignal.timeout(4000) });
          if (r.ok) img = (await r.json()).artists?.[0]?.strArtistThumb || '';
        } catch {}
      }
      // 5. Last.fm top album cover
      if (!img || isDefaultImg(img)) {
        try {
          const d = await API.call('artist.getTopAlbums', { artist: name, limit: 5, autocorrect: 1 });
          for (const alb of (d.topalbums?.album || [])) {
            const u = alb.image?.find(x => x.size === 'extralarge')?.['#text']
                   || alb.image?.find(x => x.size === 'large')?.['#text'] || '';
            if (u && !isDefaultImg(u)) { img = u; break; }
          }
        } catch {}
      }

    } else if (type === 'album') {
      // 1. iTunes album (fast, CORS native)
      try {
        const q = artist ? `${artist} ${name}` : name;
        const r = await fetch(
          `https://itunes.apple.com/search?term=${encodeURIComponent(q)}&entity=album&limit=8`,
          { signal: AbortSignal.timeout(5000) }
        );
        if (r.ok) {
          const d = await r.json();
          const exact = d.results?.find(x =>
            x.collectionName?.toLowerCase().includes(name.toLowerCase()) ||
            name.toLowerCase().includes((x.collectionName || '').toLowerCase())
          );
          const hit = exact || d.results?.[0];
          if (hit?.artworkUrl100) img = hit.artworkUrl100.replace('100x100bb','600x600bb').replace('/100x100/','/600x600/');
        }
      } catch {}
      // 2. Last.fm album.getInfo
      if (!img || isDefaultImg(img)) {
        try {
          const d = await API.call('album.getInfo', { album: name, artist: artist || '', autocorrect: 1 });
          if (d?.album?.mbid) _storeMbid('album', name, d.album.mbid);
          const u = d?.album?.image?.find(x => x.size === 'extralarge')?.['#text']
                 || d?.album?.image?.find(x => x.size === 'large')?.['#text'] || '';
          if (u && !isDefaultImg(u)) img = u;
        } catch {}
      }
      // 3. Cover Art Archive via MBID
      if (!img || isDefaultImg(img)) img = await _fetchAlbumImageWithMbid(name, artist) || '';

    } else if (type === 'track') {
      // 1. iTunes track (fast)
      try {
        const q = artist ? `${artist} ${name}` : name;
        const r = await fetch(
          `https://itunes.apple.com/search?term=${encodeURIComponent(q)}&entity=song&limit=8`,
          { signal: AbortSignal.timeout(5000) }
        );
        if (r.ok) {
          const d = await r.json();
          const exact = d.results?.find(x =>
            x.trackName?.toLowerCase().includes(name.toLowerCase()) ||
            name.toLowerCase().includes((x.trackName || '').toLowerCase())
          );
          const hit = exact || d.results?.[0];
          if (hit?.artworkUrl100) img = hit.artworkUrl100.replace('100x100bb','600x600bb').replace('/100x100/','/600x600/');
        }
      } catch {}
      // 2. Last.fm track.getInfo
      if (!img || isDefaultImg(img)) {
        try {
          const d = await API.call('track.getInfo', { track: name, artist: artist || '', autocorrect: 1 });
          const u = d?.track?.album?.image?.find(x => x.size === 'extralarge')?.['#text']
                 || d?.track?.album?.image?.find(x => x.size === 'large')?.['#text'] || '';
          if (u && !isDefaultImg(u)) img = u;
        } catch {}
      }
      // 3. Fallback: artist image via Wikipedia
      if ((!img || isDefaultImg(img)) && artist) {
        img = await _resolveArtistImageExternal(artist) || '';
      }
    }

    if (img && !isDefaultImg(img)) {
      bgEl.style.backgroundImage = `url('${escHtml(img)}')`;
      bgEl.style.backgroundSize = 'cover';
      bgEl.style.backgroundPosition = 'center';
    }
  } catch {}
}
async function _resolveProfileTrackImg(tr, index) {
  try {
    const thumbEl = document.getElementById(`ptrack-thumb-${index}`);
    if (!thumbEl) return;

    // 1. Image déjà dispo dans les données de l'API
    let img = tr?.image?.find(x => x.size === 'extralarge')?.['#text']
           || tr?.image?.find(x => x.size === 'large')?.['#text']
           || tr?.image?.find(x => x.size === 'medium')?.['#text'] || '';

    // 2. Si absente → appel track.getInfo Last.fm
    if (!img || isDefaultImg(img)) {
      const artistName = tr?.artist?.name || tr?.artist?.['#text'] || '';
      const d = await _apiFetchUser('track.getInfo', artistName, {
        track: tr?.name || '', artist: artistName, autocorrect: 1
      });
      img = d?.track?.album?.image?.find(x => x.size === 'extralarge')?.['#text']
         || d?.track?.album?.image?.find(x => x.size === 'large')?.['#text']
         || d?.track?.album?.image?.find(x => x.size === 'medium')?.['#text'] || '';
    }

    // 3. Fallback iTunes si toujours rien
    if (!img || isDefaultImg(img)) {
      const artistName = tr?.artist?.name || tr?.artist?.['#text'] || '';
      img = await _fetchTrackImageiTunes(tr?.name || '', artistName) || '';
    }

    if (img && !isDefaultImg(img)) {
      thumbEl.outerHTML = `<img src="${escHtml(img)}" alt="" class="ptrack-img" id="ptrack-thumb-${index}" onerror="this.style.display='none'">`;
    }
  } catch {}
}

async function _loadArtistBg(artist) {
  try {
    /* 1. Image déjà disponible dans les données */
    const imgFromData = artist?.image?.find(x => x.size === 'extralarge')?.['#text']
                     || artist?.image?.find(x => x.size === 'large')?.['#text'] || '';
    if (imgFromData && !isDefaultImg(imgFromData)) {
      const bgEl = document.getElementById('profile-hero-bg');
      if (bgEl) bgEl.style.backgroundImage = `url('${imgFromData}')`;
      return;
    }

    /* 2. Cascade multi-API pour vraie photo artiste */
    const externalImg = await _resolveArtistImageExternal(artist.name);
    if (externalImg) {
      const bgEl = document.getElementById('profile-hero-bg');
      if (bgEl) bgEl.style.backgroundImage = `url('${externalImg}')`;
      return;
    }

    /* 3. Fallback Last.fm artist.getInfo */
    const d   = await _apiFetchUser('artist.getInfo', artist.name, { artist: artist.name, autocorrect: 1 });
    const img = d?.artist?.image?.find(x => x.size === 'extralarge')?.['#text'] || '';
    if (img && !isDefaultImg(img)) {
      const bgEl = document.getElementById('profile-hero-bg');
      if (bgEl) bgEl.style.backgroundImage = `url('${img}')`;
    }
  } catch {}
}

function _renderProfileTopCard(id, icon, label, name, plays, imageArr, sub) {
  const el = document.getElementById(id);
  if (!el) return;
  el.classList.remove('sk');
  const imgRaw = Array.isArray(imageArr)
    ? imageArr.find(x => x.size === 'extralarge')?.['#text']
   || imageArr.find(x => x.size === 'large')?.['#text'] || ''
    : '';
  const hasImg = imgRaw && !isDefaultImg(imgRaw);
  const grad   = nameToGradient(name || '?');
  const letter = (name || '?')[0].toUpperCase();

  // Build Last.fm URL based on card type
  let lfmUrl = '';
  if (icon === 'microphone-alt') lfmUrl = `https://www.last.fm/music/${encodeURIComponent(name||'')}`;
  else if (icon === 'compact-disc') lfmUrl = `https://www.last.fm/music/${encodeURIComponent(sub||'')}/${encodeURIComponent(name||'')}`;
  else if (icon === 'music') lfmUrl = `https://www.last.fm/music/${encodeURIComponent(sub||'')}/_/${encodeURIComponent(name||'')}`;

  el.setAttribute('role', 'link');
  el.setAttribute('tabindex', '0');
  el.onclick = lfmUrl ? () => window.open(lfmUrl, '_blank', 'noopener') : null;
  el.onkeydown = lfmUrl ? (e) => { if (e.key === 'Enter') window.open(lfmUrl, '_blank', 'noopener'); } : null;

  el.innerHTML = `
    <div class="ptc-bg" style="${hasImg ? `background-image:url('${escHtml(imgRaw)}')` : `background-image:none;background:${grad}`}"></div>
    <div class="ptc-overlay"></div>
    <div class="ptc-content">
      <span class="ptc-label"><i class="fas fa-${icon}"></i> ${label}</span>
      <strong class="ptc-name">${escHtml(name || '—')}</strong>
      ${sub ? `<span class="ptc-sub">${escHtml(sub)}</span>` : ''}
      <span class="ptc-plays">${formatNum(plays)} écoutes</span>
      ${lfmUrl ? '<span class="ptc-lfm-hint"><i class="fas fa-external-link-alt"></i></span>' : ''}
    </div>`;
}

async function _loadProfileNowPlaying(username) {
  try {
    const data   = await _apiFetchUser('user.getRecentTracks', username, { limit: 1 });
    const tracks = data?.recenttracks?.track;
    const last   = Array.isArray(tracks) ? tracks[0] : tracks;
    const wrap   = document.getElementById('profile-np-wrap');
    const dot    = document.getElementById('profile-now-dot');

    // Priorité fond hero : 1) titre en cours  2) dernier titre  3) (photo profil déjà posée par _renderProfileHero)
    if (last) {
      const isNow = !!last?.['@attr']?.nowplaying;
      const bgImg = last.image?.find(x => x.size === 'extralarge')?.['#text']
                 || last.image?.find(x => x.size === 'large')?.['#text']
                 || last.image?.find(x => x.size === 'medium')?.['#text'] || '';
      if (bgImg && !isDefaultImg(bgImg)) {
        const bgEl = document.getElementById('profile-hero-bg');
        // Toujours mettre à jour : nowplaying a priorité max, sinon dernier titre
        if (bgEl) bgEl.style.backgroundImage = `url('${bgImg}')`;
      }
    }

    if (last?.['@attr']?.nowplaying) {
      const img   = last.image?.find(x => x.size === 'medium')?.['#text'] || '';
      const artEl = document.getElementById('profile-np-art');
      if (artEl) artEl.innerHTML = img && !isDefaultImg(img)
        ? `<img src="${escHtml(img)}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:6px;">`
        : '';
      const _set = (id, v) => { const e = document.getElementById(id); if (e) e.textContent = v; };
      _set('profile-np-track',  last.name || '—');
      _set('profile-np-artist', last.artist?.['#text'] || last.artist?.name || '—');
      wrap?.classList.remove('hidden');
      dot?.classList.remove('hidden');
    } else {
      wrap?.classList.add('hidden');
      dot?.classList.add('hidden');
    }
  } catch {}
}

let _npTimer = null;
let _npIsPlaying = false; // état courant pour adapter la fréquence

async function pollNowPlaying() {
  clearTimeout(_npTimer);
  try {
    const data  = await API._fetch('user.getRecentTracks', { limit: 1, extended: 1 });
    const tracks = data.recenttracks?.track;
    if (!tracks) { _npTimer = setTimeout(pollNowPlaying, 15000); return; }
    const last = Array.isArray(tracks) ? tracks[0] : tracks;
    const wrap = document.getElementById('now-playing-wrap');

    if (last['@attr']?.nowplaying) {
      _npIsPlaying = true;
      const trackName  = last.name || '—';
      const artistName = last.artist?.name || last.artist?.['#text'] || '—';

      const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
      setText('np-track',  trackName);
      setText('np-artist', artistName);

      const artEl = document.getElementById('np-art');
      const img   = last.image?.find(i => i.size === 'medium')?.['#text'];
      if (artEl) {
        artEl.innerHTML = (img && !isDefaultImg(img))
          ? `<img src="${img}" alt="" style="width:100%;height:100%;object-fit:cover">`
          : '';
        if (img && APP.currentAccent === 'dynamic') _applyColorThiefFromUrl(img);
      }

      const q     = encodeURIComponent(`${trackName} ${artistName}`);
      const spBtn = document.getElementById('np-spotify-btn');
      const ytBtn = document.getElementById('np-youtube-btn');
      if (spBtn) spBtn.href = `spotify:search:${encodeURIComponent(trackName + ' ' + artistName)}`;
      if (ytBtn) ytBtn.href = `https://www.youtube.com/results?search_query=${q}`;

      wrap?.classList.remove('hidden');
      /* ── Rafraîchissement 2s pendant l'écoute pour rester en sync ── */
      _npTimer = setTimeout(pollNowPlaying, 2000);
    } else {
      _npIsPlaying = false;
      wrap?.classList.add('hidden');
      /* Pas de lecture : on ralentit à 15s pour économiser les requêtes */
      _npTimer = setTimeout(pollNowPlaying, 15000);
    }
  } catch {
    _npIsPlaying = false;
    _npTimer = setTimeout(pollNowPlaying, 30000);
  }
}

async function shareNowPlaying() {
  const track  = document.getElementById('np-track')?.textContent  || '?';
  const artist = document.getElementById('np-artist')?.textContent || '?';
  const url    = `https://www.last.fm/music/${encodeURIComponent(artist)}/_/${encodeURIComponent(track)}`;
  const text   = t('np_share_text', track, artist);

  if (navigator.share) {
    try { await navigator.share({ title:`${track} — ${artist}`, text, url }); return; } catch {}
  }
  try {
    await navigator.clipboard.writeText(`${text}\n${url}`);
    showToast(t('toast_link_copied'));
  } catch { prompt(t('toast_link_copied') + ':', url); }
}

async function getPeakHourData() {
  try {
    const data   = await API.call('user.getRecentTracks', { limit: 200 });
    const tracks = data.recenttracks?.track || [];
    const counts = Array(24).fill(0);
    tracks.forEach(tr => {
      const uts = parseInt(tr.date?.uts || 0);
      if (uts) counts[new Date(uts * 1000).getHours()]++;
    });
    const peak = counts.indexOf(Math.max(...counts));
    let mood;
    if      (peak >= 5  && peak < 12) mood = t('stat_peak_mood_morning');
    else if (peak >= 12 && peak < 18) mood = t('stat_peak_mood_day');
    else if (peak >= 18 && peak < 23) mood = t('stat_peak_mood_evening');
    else                              mood = t('stat_peak_mood_night');
    return { label: `${peak}h – ${peak + 1}h`, mood };
  } catch { return { label: '—', mood: '' }; }
}

async function loadDashboard() {
  const u = APP.userInfo;
  if (!u) return;

  const regTs      = parseInt(u.registered?.unixtime || 0);
  const daysSince  = regTs ? Math.floor((Date.now() - regTs * 1000) / 86400000) : 1;
  const totalPlay  = parseInt(u.playcount || 0);
  const avgPerDay  = daysSince > 0 ? (totalPlay / daysSince).toFixed(1) : 0;
  const avgPerWeek = (parseFloat(avgPerDay) * 7).toFixed(0);
  const listenHours= Math.round(totalPlay * 3.5 / 60);
  const currentYear= new Date().getFullYear();

  // fetch all dashboard data in parallel
  let uniqueArtistsRaw = 0, uniqueAlbums = '…', uniqueTracks = '…', lastScrobble = '—';
  try {
    const [aData, bData, cData, rData] = await Promise.all([
      APP.topArtistsData.length
        ? API.call('user.getTopArtists', { period:'overall', limit:1 })
        : API.call('user.getTopArtists', { period:'overall', limit: TOP_LIMIT }),
      API.call('user.getTopAlbums',  { period:'overall', limit:1 }),
      API.call('user.getTopTracks',  { period:'overall', limit:1 }),
      API.call('user.getRecentTracks',{ limit:1 }),
    ]);

    if (!APP.topArtistsData.length) {
      // re-request just to get the real total count
      APP.topArtistsData = (await API.call('user.getTopArtists', { period:'overall', limit: TOP_LIMIT })).topartists?.artist || [];
    }
    uniqueArtistsRaw = parseInt(aData.topartists?.['@attr']?.total || APP.topArtistsData.length);
    uniqueAlbums     = formatNum(bData.topalbums?.['@attr']?.total);
    uniqueTracks     = formatNum(cData.toptracks?.['@attr']?.total);

    const tracks = rData.recenttracks?.track;
    if (tracks) {
      const last = Array.isArray(tracks) ? tracks[0] : tracks;
      lastScrobble = last['@attr']?.nowplaying
        ? t('stat_now_playing')
        : timeAgo(parseInt(last.date?.uts || 0));
    }
  } catch {}

  const playcounts   = APP.topArtistsData.map(a => parseInt(a.playcount));
  const eddington    = calcEddington(playcounts);
  const maxArtist    = APP.topArtistsData[0];
  const topPct       = totalPlay > 0 && maxArtist
    ? ((parseInt(maxArtist.playcount) / totalPlay) * 100).toFixed(1) : 0;
  const diversityPct = totalPlay > 0 && uniqueArtistsRaw > 0
    ? ((uniqueArtistsRaw / totalPlay) * 100).toFixed(2) : '0.00';

  // peak hour — loaded in parallel
  const peakData = await getPeakHourData();

  const cards = [
    // ① volume
    { icon:'🎯', value:totalPlay,                      label:t('adv_total'),          sub:t('adv_total_sub'),                                color:'#6366f1' },
    // ② frequency
    { icon:'⚡', value:avgPerDay,                       label:t('adv_per_day'),        sub:t('adv_per_week', avgPerWeek),                     color:'#8b5cf6', noAnim:true },
    // ③ habit — peak hour card
    { icon:'🕐', value:peakData.label,                  label:t('stat_peak_hour'),     sub:peakData.mood,                                     color:'#a78bfa', noAnim:true },
    // ④ exploration
    { icon:'🎤', value:formatNum(uniqueArtistsRaw),     label:t('stat_artists'),       sub:t('stat_since_start'),                             color:'#ec4899', noAnim:true },
    // ⑤ depth
    { icon:'💿', value:uniqueAlbums,                    label:t('stat_albums'),        sub:t('stat_since_start'),                             color:'#d946ef', noAnim:true },
    // ⑥ diversity
    { icon:'📊', value:`${diversityPct}%`,               label:t('stat_diversity'),     sub:t('stat_diversity_sub'),                           color:'#14b8a6', noAnim:true },
    // secondary stat cards
    { icon:'🎼', value:uniqueTracks,                    label:t('stat_tracks'),        sub:t('stat_since_start'),                             color:'#f43f5e', noAnim:true },
    { icon:'⏱️', value:lastScrobble,                    label:t('stat_last_scrobble'), sub:u.name ? `last.fm/user/${u.name}` : '',            color:'#f97316', noAnim:true },
    { icon:'📆', value:formatNum(daysSince),             label:t('adv_days'),           sub:t('adv_days_sub', formatDate(regTs)),              color:'#eab308', noAnim:true },
    { icon:'🌟', value:maxArtist ? maxArtist.name:'—',  label:t('adv_top1_alltime'),   sub:t('adv_top1_pct', topPct),                        color:'#22c55e', noAnim:true },
    { icon:'🔢', value:eddington,                       label:t('adv_eddington'),      sub:t('adv_eddington_sub', eddington),                 color:'#a855f7', noAnim:true },
    { icon:'🎧', value:`${formatNum(listenHours)}h`,    label:t('stat_listen_time'),   sub:t('stat_listen_estimate', formatNum(totalPlay)),   color:'#06b6d4', noAnim:true },
  ];

  const statGrid = document.getElementById('stat-grid');
  if (statGrid) {
    statGrid.innerHTML = cards.map((c, i) => `
      <div class="stat-card" style="--card-accent:${c.color};animation-delay:${i * 0.05}s">
        <div class="stat-card-icon">${c.icon}</div>
        <div class="stat-card-value" id="sv-${i}" style="color:${c.color}">${c.noAnim ? c.value : '0'}</div>
        <div class="stat-card-label">${c.label}</div>
        <div class="stat-card-sub">${c.sub}</div>
      </div>`).join('');

    const scEl = document.getElementById('sv-0');
    if (scEl) animateValue(scEl, 0, totalPlay, 1000);
  }

  loadDashMonthlyChart(currentYear);
  loadDashArtistsChart();
}

async function loadDashMonthlyChart(year) {
  const yrEl = document.getElementById('dash-yr');
  if (yrEl) yrEl.textContent = year;

  const [h1, h2] = await Promise.all([
    Promise.all(Array(6).fill(0).map((_,i) => API.getMonthScrobbles(year, i))),
    Promise.all(Array(6).fill(0).map((_,i) => API.getMonthScrobbles(year, i + 6))),
  ]);
  const counts = [...h1, ...h2];

  destroyChart('dash-monthly');
  const c = getThemeColors();
  APP.charts['dash-monthly'] = new Chart(document.getElementById('dash-monthly'), {
    type: 'bar',
    data: {
      labels: MONTHS_SHORT(),
      datasets:[{ data:counts, backgroundColor:counts.map((_,i) => `${CHART_PALETTE[i % CHART_PALETTE.length]}99`), borderColor:counts.map((_,i) => CHART_PALETTE[i % CHART_PALETTE.length]), borderWidth:1, borderRadius:5 }],
    },
    options:{
      ...baseChartOpts(),
      plugins:{ ...baseChartOpts().plugins, tooltip:{ ...baseChartOpts().plugins.tooltip, callbacks:{ label:ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } } },
      scales:{ x:{ grid:{ display:false }, ticks:{ color:c.text, font:{ size:10 } } }, y:{ grid:{ color:c.grid }, ticks:{ color:c.text, font:{ size:10 } } } },
    },
  });
}

async function loadDashArtistsChart() {
  try {
    const data    = await API.call('user.getTopArtists', { period:'overall', limit:5 });
    const artists = data.topartists?.artist || [];
    if (!artists.length) return;

    destroyChart('dash-artists');
    const c = getThemeColors();
    APP.charts['dash-artists'] = new Chart(document.getElementById('dash-artists'), {
      type: 'doughnut',
      data: {
        labels: artists.map(a => a.name),
        datasets:[{ data:artists.map(a => parseInt(a.playcount)), backgroundColor:CHART_PALETTE.slice(0,5), borderWidth:2, borderColor:c.isDark ? '#07071a' : '#f1f5f9', hoverOffset:6 }],
      },
      options:{
        responsive:true, maintainAspectRatio:false,
        plugins:{ legend:{ display:true, position:'right', labels:{ color:c.text, font:{ size:11 }, boxWidth:12, padding:8 } }, tooltip:{ callbacks:{ label:ctx => ` ${ctx.label}: ${formatNum(ctx.raw)}` } } },
        cutout:'62%', animation:{ duration:700 },
      },
    });
  } catch (e) { console.warn('dash-artists chart:', e); }
}

async function loadVersus() {
  const vsBody = document.getElementById('vs-body');
  if (!vsBody) return;

  try {
    const now       = new Date();
    const currYear  = now.getFullYear();
    const currMonth = now.getMonth();
    const prevMonth = currMonth === 0 ? 11 : currMonth - 1;
    const prevYear  = currMonth === 0 ? currYear - 1 : currYear;

    const [curr, prev] = await Promise.all([
      API.getMonthScrobbles(currYear, currMonth),
      API.getMonthScrobbles(prevYear, prevMonth),
    ]);

    const diff = curr - prev;
    const pct  = prev > 0 ? ((diff / prev) * 100).toFixed(1) : null;

    const arrowBadge = (d, p) => {
      if (p === null || d === 0) return `<span class="vs-arrow flat">${t('versus_stable')}</span>`;
      return `<span class="vs-arrow ${d > 0 ? 'up' : 'down'}">${d > 0 ? '▲' : '▼'} ${d > 0 ? '+' : ''}${p}%</span>`;
    };

    const MONTHS_ARR = MONTHS();
    vsBody.innerHTML = `
      <div class="vs-metric">
        <span class="vs-label">🎵 ${t('scrobbles')}</span>
        <div class="vs-values">
          <span class="vs-curr">${formatNum(curr)}</span>
          ${arrowBadge(diff, pct)}
        </div>
      </div>
      <div class="vs-prev-row"><span class="vs-prev-txt">${formatNum(prev)} ${MONTHS_ARR[prevMonth] || ''}</span></div>
      <div class="vs-months">${MONTHS_ARR[currMonth] || ''} <span>vs</span> ${MONTHS_ARR[prevMonth] || ''}</div>`;

  } catch { vsBody.innerHTML = `<p class="vs-na">${t('versus_unavailable')}</p>`; }
}

const _IGNORED_TAGS = new Set(['seen live','favorites','favourite','love','awesome','beautiful','epic','amazing','classic','favourite music','my favourite','all','featured','good','new','old','best','cool','hot','great','perfect']);

async function loadMoodTags() {
  const tagsEl = document.getElementById('mood-tags');
  if (!tagsEl) return;

  try {
    if (!APP.topArtistsData.length) {
      const d = await API.call('user.getTopArtists', { period:'overall', limit:10 });
      APP.topArtistsData = d.topartists?.artist || [];
    }

    const top10      = APP.topArtistsData.slice(0, 10);
    const tagScores  = new Map();
    const tagResults = await Promise.allSettled(top10.map(a => API.call('artist.getTopTags', { artist:a.name })));

    tagResults.forEach((res, i) => {
      if (res.status !== 'fulfilled') return;
      const tags   = res.value.toptags?.tag || [];
      const weight = 10 - i;
      tags.slice(0, 8).forEach((tag, j) => {
        const name = tag.name?.toLowerCase().trim();
        if (!name || name.length < 2 || _IGNORED_TAGS.has(name)) return;
        tagScores.set(name, (tagScores.get(name) || 0) + (parseInt(tag.count) || 50) * weight * (8 - j));
      });
    });

    const top5 = [...tagScores.entries()].sort((a,b) => b[1]-a[1]).slice(0, 5);
    if (!top5.length) { tagsEl.innerHTML = `<p class="mood-na">${t('mood_none')}</p>`; return; }

    tagsEl.innerHTML = top5.map(([tag], i) =>
      `<span class="mood-tag rank-${i+1}">#${escHtml(tag.charAt(0).toUpperCase() + tag.slice(1))}</span>`
    ).join('');

  } catch (e) { console.warn('loadMoodTags:', e); if (tagsEl) tagsEl.innerHTML = `<p class="mood-na">${t('mood_error')}</p>`; }
}

function calcStreak(tracks) {
  const daySet = new Set();
  for (const tr of tracks) {
    const ts = parseInt(tr.date?.uts || 0);
    if (!ts) continue;
    const d = new Date(ts * 1000);
    daySet.add(`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`);
  }

  const sorted = [...daySet].sort();
  if (!sorted.length) return { best:0, current:0 };

  let best = 1, streak = 1;
  for (let i = 1; i < sorted.length; i++) {
    const diff = Math.round((new Date(sorted[i]) - new Date(sorted[i-1])) / 86400000);
    if (diff === 1) { streak++; if (streak > best) best = streak; } else streak = 1;
  }

  const todayMs  = new Date(); todayMs.setHours(0,0,0,0);
  const todayStr = `${todayMs.getFullYear()}-${String(todayMs.getMonth()+1).padStart(2,'0')}-${String(todayMs.getDate()).padStart(2,'0')}`;
  const yestMs   = new Date(todayMs - 86400000);
  const yestStr  = `${yestMs.getFullYear()}-${String(yestMs.getMonth()+1).padStart(2,'0')}-${String(yestMs.getDate()).padStart(2,'0')}`;

  const rev = [...sorted].reverse();
  let current = 0;
  if (rev[0] === todayStr || rev[0] === yestStr) {
    current = 1;
    for (let i = 1; i < rev.length; i++) {
      const diff = Math.round((new Date(rev[i-1]) - new Date(rev[i])) / 86400000);
      if (diff === 1) current++; else break;
    }
  }
  return { best, current };
}

function updateStreakUI(streakData) {
  const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
  setText('streak-best', streakData.best);
  setText('streak-curr', streakData.current);
  const hintEl = document.getElementById('streak-hint');
  if (hintEl) {
    hintEl.textContent = streakData.current > 0
      ? (streakData.current === streakData.best ? t('streak_on_record') : t('streak_ongoing', streakData.best))
      : t('streak_calc', formatNum(APP.fullHistory?.length || 0));
  }
}

function renderHeatmap(hourCounts) {
  const el = document.getElementById('heatmap-grid');
  if (!el) return;

  document.getElementById('heatmap-empty')?.remove();
  const max   = Math.max(...hourCounts, 1);
  const total = hourCounts.reduce((a,b) => a+b, 0);

  const cells = hourCounts.map((count, h) => {
    const intensity = count / max;
    const r = Math.round(199 + (67-199)*intensity);
    const g = Math.round(210 + (56-210)*intensity);
    const b = Math.round(254 + (202-254)*intensity);
    const alpha = 0.15 + intensity * 0.85;
    const bg  = `rgba(${r},${g},${b},${alpha})`;
    const tc  = intensity > 0.45 ? 'rgba(255,255,255,.95)' : 'rgba(200,195,240,.8)';
    const pct = total > 0 ? ((count/total)*100).toFixed(1) : 0;
    return `<div class="heatmap-cell" style="background:${bg};color:${tc}" title="${h}h–${h+1}h : ${formatNum(count)} ${t('scrobbles')} (${pct}%)">
      <span class="hm-hour">${h}h</span>
      <span class="hm-val">${count > 9999 ? Math.round(count/1000)+'k' : count > 0 ? count : ''}</span>
    </div>`;
  }).join('');

  const scaleStops = [0.1,0.3,0.5,0.7,0.9].map(v => {
    const r = Math.round(199+(67-199)*v), g = Math.round(210+(56-210)*v), b = Math.round(254+(202-254)*v);
    return `<div style="width:28px;height:10px;border-radius:3px;background:rgba(${r},${g},${b},${0.15+v*0.85})"></div>`;
  }).join('');

  el.innerHTML = `
    <div class="heatmap-cells">${cells}</div>
    <div class="heatmap-legend">
      <span>${t('heatmap_calm')}</span>
      <div class="heatmap-scale">${scaleStops}</div>
      <span>${t('heatmap_intense')}</span>
    </div>`;
}

const _imgCache    = new Map();
const _imgInFlight = new Map(); // évite les requêtes parallèles pour le même artiste

/* ── Cache MBID — storé par nom d'artiste/album/titre ── */
const _mbidCache = new Map();

/**
 * Retourne le MBID depuis Last.fm si disponible.
 * Last.fm inclut souvent le champ `mbid` dans les réponses artist/album/track.
 * On le stocke ici pour éviter les homonymes et enrichir les appels externes.
 */
function _storeMbid(type, name, mbid) {
  if (mbid && mbid.length === 36) _mbidCache.set(`${type}:${name.toLowerCase()}`, mbid);
}
function _getMbid(type, name) {
  return _mbidCache.get(`${type}:${name.toLowerCase()}`) || null;
}

async function getArtistImage(artistName) {
  if (_imgCache.has(artistName)) return _imgCache.get(artistName);
  if (_imgInFlight.has(artistName)) return _imgInFlight.get(artistName);

  const promise = _resolveArtistImageExternal(artistName).then(url => {
    _imgCache.set(artistName, url);
    _imgInFlight.delete(artistName);
    return url;
  });
  _imgInFlight.set(artistName, promise);
  return promise;
}

/**
 * Cascade multi-API pour récupérer une vraie photo d'artiste.
 * Ordre : MusicBrainz (si MBID connu) → Wikipedia → iTunes → TheAudioDB → Last.fm album art
 */
async function _resolveArtistImageExternal(artistName) {
  /* 0. MusicBrainz → Cover Art Archive via MBID (précision maximale, pas d'homonymes) */
  const mbid = _getMbid('artist', artistName);
  if (mbid) {
    try {
      const r = await fetch(
        `https://musicbrainz.org/ws/2/artist/${mbid}?inc=url-rels&fmt=json`,
        { headers: { 'User-Agent': 'LastStats/1.0 (github.com/sanobld/LastStats)' },
          signal: AbortSignal.timeout(4000) }
      );
      if (r.ok) {
        const d = await r.json();
        const imgRel = d.relations?.find(rel => rel.type === 'image');
        if (imgRel?.url?.resource) return imgRel.url.resource;
      }
    } catch {}
  }

  /* 1. Wikipedia — photos de qualité pour artistes connus, CORS OK */
  try {
    const r = await fetch(
      `https://en.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(artistName)}&prop=pageimages&format=json&pithumbsize=600&origin=*`,
      { signal: AbortSignal.timeout(4000) }
    );
    if (r.ok) {
      const d = await r.json();
      for (const page of Object.values(d.query?.pages || {})) {
        if (page.thumbnail?.source && !page.missing) return page.thumbnail.source;
      }
    }
  } catch {}

  /* 2. iTunes Search — très fiable, CORS natif */
  try {
    const r = await fetch(
      `https://itunes.apple.com/search?term=${encodeURIComponent(artistName)}&entity=musicArtist&limit=5`,
      { signal: AbortSignal.timeout(4000) }
    );
    if (r.ok) {
      const d = await r.json();
      const exact = d.results?.find(a => a.artistName?.toLowerCase() === artistName.toLowerCase());
      const hit   = exact || d.results?.[0];
      if (hit?.artworkUrl100) {
        return hit.artworkUrl100.replace('100x100bb', '600x600bb').replace('/100x100/', '/600x600/');
      }
    }
  } catch {}

  /* 3. TheAudioDB — base dédiée, bonne couverture */
  try {
    const r = await fetch(
      `https://www.theaudiodb.com/api/v1/json/2/search.php?s=${encodeURIComponent(artistName)}`,
      { signal: AbortSignal.timeout(4000) }
    );
    if (r.ok) {
      const img = (await r.json()).artists?.[0]?.strArtistThumb;
      if (img) return img;
    }
  } catch {}

  /* 4. Last.fm artist.getTopAlbums — fallback : pochette du meilleur album */
  try {
    const data   = await API.call('artist.getTopAlbums', { artist: artistName, limit: 3, autocorrect: 1 });
    const albums = data.topalbums?.album || [];
    for (const alb of albums) {
      const img = alb.image?.find(i => i.size === 'extralarge')?.['#text']
               || alb.image?.find(i => i.size === 'large')?.['#text'] || '';
      if (!isDefaultImg(img)) return img;
    }
  } catch {}

  return null;
}

/**
 * Récupère la pochette d'un album via Cover Art Archive (MusicBrainz) si MBID disponible,
 * sinon via iTunes. Retourne null si rien trouvé.
 */
async function _fetchAlbumImageWithMbid(albumName, artistName) {
  /* Essai MBID album → Cover Art Archive (haute résolution, sans quota) */
  const mbid = _getMbid('album', albumName);
  if (mbid) {
    try {
      const r = await fetch(
        `https://coverartarchive.org/release-group/${mbid}/front-500`,
        { signal: AbortSignal.timeout(4000) }
      );
      if (r.ok && r.headers.get('content-type')?.startsWith('image/')) return r.url;
    } catch {}
  }
  /* Fallback iTunes */
  return _fetchAlbumImageiTunes(albumName, artistName);
}

/**
 * Stocke les MBIDs trouvés dans les réponses Last.fm (artiste, album, titre).
 * À appeler à chaque fois qu'on reçoit des données de l'API Last.fm.
 */
function _extractAndStoreMbids(data) {
  try {
    // Artiste
    const artist = data?.artist || data?.topartists?.artist;
    const artists = Array.isArray(artist) ? artist : (artist ? [artist] : []);
    for (const a of artists) { if (a?.name && a?.mbid) _storeMbid('artist', a.name, a.mbid); }
    // Album
    const album = data?.album || data?.topalbums?.album;
    const albums = Array.isArray(album) ? album : (album ? [album] : []);
    for (const a of albums) { if (a?.name && a?.mbid) _storeMbid('album', a.name, a.mbid); }
    // Track
    const track = data?.track || data?.toptracks?.track || data?.recenttracks?.track;
    const tracks = Array.isArray(track) ? track : (track ? [track] : []);
    for (const tr of tracks) {
      if (tr?.name && tr?.mbid) _storeMbid('track', tr.name, tr.mbid);
      if (tr?.artist?.name && tr?.artist?.mbid) _storeMbid('artist', tr.artist.name, tr.artist.mbid);
      if (tr?.album?.['#text'] && tr?.album?.mbid) _storeMbid('album', tr.album['#text'], tr.album.mbid);
    }
  } catch {}
}

async function injectArtistImage(artistName, containerId, fallbackBg, fallbackLetter) {
  const container = document.getElementById(containerId);
  if (!container) return;
  const img = await getArtistImage(artistName);
  if (img) {
    // overlay image on top of the fallback using position:absolute
    const imgEl = document.createElement('img');
    imgEl.src    = img;
    imgEl.alt    = escHtml(artistName);
    imgEl.loading = 'lazy';
    imgEl.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;object-fit:cover;border-radius:inherit';
    imgEl.onerror = () => imgEl.remove();
    container.style.position = 'relative';
    container.style.overflow = 'hidden';
    container.appendChild(imgEl);
  }
}

/** Injects artist tags into a DOM container */
async function _injectArtistTags(artistName, containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;
  try {
    const data = await API.call('artist.getTopTags', { artist:artistName, autocorrect:1 });
    const tags  = (data.toptags?.tag || [])
      .filter(tg => {
        const n = tg.name?.toLowerCase().trim();
        return n && n.length >= 2 && !_IGNORED_TAGS.has(n);
      })
      .slice(0, 3);
    if (tags.length) {
      container.innerHTML = tags.map(tg =>
        `<span class="artist-tag-pill">${escHtml(tg.name)}</span>`
      ).join('');
    }
  } catch {}
}

let _artistsObserver = null;

function setArtistsLayout(layout) {
  APP.artistsLayout = layout;
  localStorage.setItem('ls_artists_layout', layout);
  const grid = document.getElementById('artists-grid');
  if (grid) {
    grid.className = layout === 'compact' ? 'music-grid layout-compact' : 'hero-grid';
  }
  document.querySelectorAll('#artists-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === layout)
  );
  if (APP.topArtistsData.length && grid) {
    grid.innerHTML = APP.topArtistsData.slice(0, APP.artistsPage * 50).map((a,i) => _buildArtistCard(a, i+1)).join('');
  }
}

function _buildArtistCard(a, rank) {
  const letter = (a.name || '?')[0].toUpperCase();
  const bg     = nameToGradient(a.name);
  const spQ    = encodeURIComponent(a.name);
  const imgId  = `artist-img-r${rank}`;
  const tagsId = `artist-tags-r${rank}`;
  const safeUrl= (a.url || '#').replace(/'/g,'%27');
  const plays  = parseInt(a.playcount || 0);
  const delay  = Math.min(rank % 20, 10) * 0.04;
  const safeName = escHtml(a.name).replace(/'/g,"\\'");

    const heroHtml = `
    <div class="artist-hero-card" style="animation-delay:${delay}s"
         onclick="openArtistModal('${safeName}','${safeUrl}',${plays})">
      <div class="artist-hero-fallback" id="${imgId}-fallback" style="background:${bg}">${letter}</div>
      <img class="artist-hero-img" id="${imgId}" alt="${escHtml(a.name)}" style="display:none">
      <div class="artist-hero-overlay"></div>
      <div class="artist-hero-rank">${rank}</div>
      <div class="artist-hero-tags" id="${tagsId}"></div>
      <div class="artist-hero-body">
        <div class="artist-hero-name">${escHtml(a.name)}</div>
        <div class="artist-hero-plays">${formatNum(a.playcount)} ${t('plays')}</div>
      </div>
      <div class="artist-hero-actions">
        <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" aria-label="Open in Spotify" title="Spotify"><i class="fab fa-spotify"></i></a>
        <a class="mc-play-btn yt" href="https://www.youtube.com/results?search_query=${spQ}" target="_blank" rel="noopener" onclick="event.stopPropagation()" aria-label="Search on YouTube" title="YouTube"><i class="fab fa-youtube"></i></a>
        <button class="mc-play-btn share" onclick="event.stopPropagation();shareArtist(${JSON.stringify(a.name)},${plays},'${safeUrl}')" aria-label="${t('share')} ${escHtml(a.name)}" title="${t('share')}"><i class="fas fa-share-alt"></i></button>
      </div>
    </div>`;

    const listTagsId = `artist-ltags-r${rank}`;
  const listHtml = `
    <div class="music-card" style="animation-delay:${delay}s"
         onclick="openArtistModal('${safeName}','${safeUrl}',${plays})">
      <div class="music-card-img" style="aspect-ratio:1">
        <div class="spotify-cover" id="${imgId}-cover" style="background:${bg}">
          <span class="sc-letter">${letter}</span>
          <span class="sc-name">${escHtml(a.name)}</span>
        </div>
        <div class="music-card-rank">${rank}</div>
        <div class="music-card-actions">
          <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" title="Spotify"><i class="fab fa-spotify"></i></a>
          <a class="mc-play-btn yt" href="https://www.youtube.com/results?search_query=${spQ}" target="_blank" rel="noopener" onclick="event.stopPropagation()" title="YouTube"><i class="fab fa-youtube"></i></a>
          <button class="mc-play-btn share" onclick="event.stopPropagation();shareArtist(${JSON.stringify(a.name)},${plays},'${safeUrl}')" title="${t('share')}"><i class="fas fa-share-alt"></i></button>
        </div>
      </div>
      <div class="music-card-body">
        <div class="music-card-name" title="${escHtml(a.name)}">${escHtml(a.name)}</div>
        <div class="music-card-plays">${formatNum(a.playcount)} ${t('plays')}</div>
        <div class="music-card-tags" id="${listTagsId}" style="margin-top:4px"></div>
      </div>
    </div>`;

    const compactHtml = `
    <div class="track-item" style="animation-delay:${delay}s"
         onclick="openArtistModal('${safeName}','${safeUrl}',${plays})">
      <div class="track-cover" id="${imgId}-compact" style="background:${bg};display:flex;align-items:center;justify-content:center;color:white;font-weight:700;font-size:1rem;flex-shrink:0;width:40px;height:40px;border-radius:6px;overflow:hidden;position:relative">${letter}</div>
      <div class="track-rank">${rank <= 3 ? ['🥇','🥈','🥉'][rank-1] : rank}</div>
      <div class="track-info">
        <div class="track-name" title="${escHtml(a.name)}">${escHtml(a.name)}</div>
        <div class="track-artist">${formatNum(a.playcount)} ${t('plays')}</div>
      </div>
      <div class="track-plays">${formatNum(a.playcount)}</div>
      <div class="track-play-btns">
        <a class="track-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" title="Spotify"><i class="fab fa-spotify"></i></a>
        <a class="track-play-btn yt" href="https://www.youtube.com/results?search_query=${spQ}" target="_blank" rel="noopener" onclick="event.stopPropagation()" title="YouTube"><i class="fab fa-youtube"></i></a>
      </div>
    </div>`;

  const layout = APP.artistsLayout || 'grid';
  const html   = layout === 'grid' ? heroHtml : layout === 'list' ? listHtml : compactHtml;

  // lazy-load image + tags — capped at 500ms
  const lazyDelay = Math.min(rank - 1, 12) * 40;
  setTimeout(() => {
    if (layout === 'grid') {
      getArtistImage(a.name).then(imgUrl => {
        const imgEl      = document.getElementById(imgId);
        const fallbackEl = document.getElementById(`${imgId}-fallback`);
        if (!imgEl) return;
        if (imgUrl) {
          imgEl.classList.add('img-fade');
          imgEl.onload  = () => {
            imgEl.style.display = 'block';
            if (fallbackEl) fallbackEl.style.display = 'none';
            requestAnimationFrame(() => imgEl.classList.add('img-loaded'));
          };
          imgEl.onerror = () => { imgEl.style.display = 'none';  if (fallbackEl) fallbackEl.style.display = 'flex'; };
          imgEl.src = imgUrl;
        }
      });
      _injectArtistTags(a.name, tagsId);
    } else if (layout === 'list') {
      injectArtistImage(a.name, `${imgId}-cover`, bg, letter);
      _injectArtistTags(a.name, listTagsId);
    } else {
      // compact: image is absolute inside the cover div
      getArtistImage(a.name).then(imgUrl => {
        const coverEl = document.getElementById(`${imgId}-compact`);
        if (coverEl && imgUrl) {
          const imgNode = document.createElement('img');
          imgNode.src = imgUrl; imgNode.alt = escHtml(a.name); imgNode.loading = 'lazy';
          imgNode.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;object-fit:cover;border-radius:6px';
          imgNode.onerror = () => imgNode.remove();
          coverEl.style.position = 'relative';
          coverEl.appendChild(imgNode);
        }
      });
    }
  }, lazyDelay);

  return html;
}

async function loadTopArtists(period) {
  APP.artistsPage      = 1;
  APP.artistsPeriod    = period;
  APP.artistsLoading   = false;
  APP.artistsExhausted = false;

  const grid     = document.getElementById('artists-grid');
  const loader   = document.getElementById('artists-page-loader');
  const sentinel = document.getElementById('artists-scroll-sentinel');

  if (grid) {
    grid.className = `music-grid layout-${APP.artistsLayout}`;
    grid.innerHTML = skeletonMusicCards(12);
  }
  if (loader) loader.classList.add('hidden');
  if (_artistsObserver) { _artistsObserver.disconnect(); _artistsObserver = null; }

  document.querySelectorAll('#artists-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === APP.artistsLayout)
  );

  try {
    const data    = await API.call('user.getTopArtists', { period, limit:50, page:1 });
    const artists = data.topartists?.artist || [];
    APP.topArtistsData    = artists;
    APP.artistsTotalPages = parseInt(data.topartists?.['@attr']?.totalPages || 1);
    if (grid) grid.innerHTML = artists.map((a,i) => _buildArtistCard(a, i+1)).join('');

    if (APP.artistsTotalPages > 1 && sentinel) {
      _artistsObserver = new IntersectionObserver(
        entries => { if (entries[0].isIntersecting) _loadMoreArtists(); },
        { rootMargin:'200px' }
      );
      _artistsObserver.observe(sentinel);
    }
  } catch (e) { if (grid) grid.innerHTML = errMsg(e); }
}

async function _loadMoreArtists() {
  if (APP.artistsLoading || APP.artistsExhausted) return;
  if (APP.artistsPage >= APP.artistsTotalPages) { APP.artistsExhausted = true; return; }
  APP.artistsLoading = true;
  APP.artistsPage++;

  const grid   = document.getElementById('artists-grid');
  const loader = document.getElementById('artists-page-loader');
  if (loader) loader.classList.remove('hidden');

  try {
    const data    = await API.call('user.getTopArtists', { period:APP.artistsPeriod, limit:50, page:APP.artistsPage });
    const artists = data.topartists?.artist || [];
    if (!artists.length) { APP.artistsExhausted = true; return; }
    const startRank = (APP.artistsPage - 1) * 50 + 1;
    artists.forEach((a,i) => grid.insertAdjacentHTML('beforeend', _buildArtistCard(a, startRank + i)));
    APP.topArtistsData = [...APP.topArtistsData, ...artists];
  } catch (e) { console.warn('_loadMoreArtists:', e); }
  finally { APP.artistsLoading = false; if (loader) loader.classList.add('hidden'); }
}

let _albumsObserver = null;

function _albumsGridClass(layout) {
  if (layout === 'grid')    return 'hero-grid';
  if (layout === 'list')    return 'music-grid layout-list';
  return 'music-grid layout-compact';
}

function setAlbumsLayout(layout) {
  APP.albumsLayout = layout;
  localStorage.setItem('ls_albums_layout', layout);
  const grid = document.getElementById('albums-grid');
  if (grid) {
    grid.className = _albumsGridClass(layout);
    if (APP.topAlbumsData?.length) {
      grid.innerHTML = APP.topAlbumsData
        .slice(0, APP.albumsPage * 50)
        .map((a, i) => _buildAlbumCard(a, i + 1))
        .join('');
    }
  }
  document.querySelectorAll('#albums-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === layout)
  );
}

function _buildAlbumCard(a, rank) {
  const imgUrl   = a.image?.find(img => img.size === 'extralarge')?.['#text'] || '';
  const hasImg   = !isDefaultImg(imgUrl);
  const letter   = (a.name || '?')[0].toUpperCase();
  const bg       = nameToGradient((a.name || '') + (a.artist?.name || ''));
  const safeUrl  = (a.url || '#').replace(/'/g,'%27');
  const artistNm = a.artist?.name || '';
  const delay    = Math.min((rank-1) % 20, 10) * 0.04;
  const spQ      = encodeURIComponent(`${a.name} ${artistNm}`);

  const gridHtml = `
    <div class="hero-card" style="animation-delay:${delay}s" onclick="window.open('${safeUrl}','_blank')">
      <div class="hc-fallback" style="background:${bg}${hasImg ? ';display:none' : ''}">${letter}</div>
      ${hasImg ? `<img class="hc-img img-fade" src="${imgUrl}" alt="${escHtml(a.name)}" loading="lazy" onload="this.classList.add('img-loaded')" onerror="this.style.display='none';this.previousElementSibling.style.display='flex'">` : ''}
      <div class="hc-overlay"></div>
      <div class="hc-rank">${rank}</div>
      <div class="hc-body">
        <div class="hc-name">${escHtml(a.name)}</div>
        <div class="hc-sub">${escHtml(artistNm)}</div>
        <div class="hc-plays">${formatNum(a.playcount)} ${t('plays')}</div>
      </div>
      <div class="hc-actions">
        <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" title="Spotify"><i class="fab fa-spotify"></i></a>
        <button class="mc-play-btn share" onclick="event.stopPropagation();shareAlbum(${JSON.stringify(a.name)},${JSON.stringify(artistNm)},${a.playcount},'${safeUrl}')" title="${t('share')}"><i class="fas fa-share-alt"></i></button>
      </div>
    </div>`;

  const listHtml = `
    <div class="music-card" style="animation-delay:${delay}s" onclick="window.open('${safeUrl}','_blank')">
      <div class="music-card-img">
        ${hasImg ? `<img src="${imgUrl}" alt="${escHtml(a.name)}" loading="lazy" class="img-fade" onload="this.classList.add('img-loaded')" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
        <div class="spotify-cover" style="background:${bg};display:${hasImg ? 'none' : 'flex'}">
          <span class="sc-letter">${letter}</span>
        </div>
        <div class="music-card-rank">${rank}</div>
        <div class="music-card-actions">
          <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" title="Spotify"><i class="fab fa-spotify"></i></a>
          <button class="mc-play-btn share" onclick="event.stopPropagation();shareAlbum(${JSON.stringify(a.name)},${JSON.stringify(artistNm)},${a.playcount},'${safeUrl}')" title="${t('share')}"><i class="fas fa-share-alt"></i></button>
        </div>
      </div>
      <div class="music-card-body">
        <div class="music-card-name" title="${escHtml(a.name)}">${escHtml(a.name)}</div>
        <div class="music-card-artist">${escHtml(artistNm)}</div>
        <div class="music-card-plays">${formatNum(a.playcount)} ${t('plays')}</div>
      </div>
    </div>`;

  const compactHtml = `
    <div class="track-item" style="animation-delay:${delay}s" onclick="window.open('${safeUrl}','_blank')">
      <div class="track-cover" style="flex-shrink:0;width:40px;height:40px;border-radius:6px;overflow:hidden;position:relative">
        ${hasImg ? `<img src="${imgUrl}" alt="${escHtml(a.name)}" style="width:100%;height:100%;object-fit:cover" loading="lazy" onerror="this.style.display='none'">` : ''}
        <div style="position:absolute;inset:0;background:${bg};display:${hasImg ? 'none' : 'flex'};align-items:center;justify-content:center;color:white;font-weight:700">${letter}</div>
      </div>
      <div class="track-rank">${rank <= 3 ? ['🥇','🥈','🥉'][rank-1] : rank}</div>
      <div class="track-info">
        <div class="track-name">${escHtml(a.name)}</div>
        <div class="track-artist">${escHtml(artistNm)}</div>
      </div>
      <div class="track-plays">${formatNum(a.playcount)}</div>
    </div>`;

  const layout = APP.albumsLayout || 'grid';
  if (layout === 'compact') return compactHtml;
  if (layout === 'list')    return listHtml;
  return gridHtml;
}

async function loadTopAlbums(period) {
  APP.albumsPage      = 1;
  APP.albumsPeriod    = period;
  APP.albumsLoading   = false;
  APP.albumsExhausted = false;

  const grid     = document.getElementById('albums-grid');
  const loader   = document.getElementById('albums-page-loader');
  const sentinel = document.getElementById('albums-scroll-sentinel');

  if (grid) {
    grid.className = _albumsGridClass(APP.albumsLayout);
    grid.innerHTML = skeletonMusicCards(12);
  }
  if (loader) loader.classList.add('hidden');
  if (_albumsObserver) { _albumsObserver.disconnect(); _albumsObserver = null; }

  try {
    const data   = await API.call('user.getTopAlbums', { period, limit:50, page:1 });
    const albums = data.topalbums?.album || [];
    APP.topAlbumsData    = albums;
    APP.albumsTotalPages = parseInt(data.topalbums?.['@attr']?.totalPages || 1);
    if (grid) grid.innerHTML = albums.map((a,i) => _buildAlbumCard(a, i+1)).join('');

    if (APP.albumsTotalPages > 1 && sentinel) {
      _albumsObserver = new IntersectionObserver(
        entries => { if (entries[0].isIntersecting) _loadMoreAlbums(); },
        { rootMargin:'200px' }
      );
      _albumsObserver.observe(sentinel);
    }
  } catch (e) { if (grid) grid.innerHTML = errMsg(e); }
}

async function _loadMoreAlbums() {
  if (APP.albumsLoading || APP.albumsExhausted) return;
  if (APP.albumsPage >= APP.albumsTotalPages) { APP.albumsExhausted = true; return; }
  APP.albumsLoading = true;
  APP.albumsPage++;

  const grid   = document.getElementById('albums-grid');
  const loader = document.getElementById('albums-page-loader');
  if (loader) loader.classList.remove('hidden');

  try {
    const data   = await API.call('user.getTopAlbums', { period:APP.albumsPeriod, limit:50, page:APP.albumsPage });
    const albums = data.topalbums?.album || [];
    if (!albums.length) { APP.albumsExhausted = true; return; }
    const startRank = (APP.albumsPage - 1) * 50 + 1;
    albums.forEach((a,i) => grid.insertAdjacentHTML('beforeend', _buildAlbumCard(a, startRank + i)));
    APP.topAlbumsData = [...APP.topAlbumsData, ...albums];
  } catch (e) { console.warn('_loadMoreAlbums:', e); }
  finally { APP.albumsLoading = false; if (loader) loader.classList.add('hidden'); }
}

let _tracksObserver = null;
const _trackImgCache = new Map();

function setTracksLayout(layout) {
  APP.tracksLayout = layout;
  localStorage.setItem('ls_tracks_layout', layout);
  const list = document.getElementById('tracks-list');
  if (list) list.className = layout === 'grid' ? 'hero-grid' : `tracks-list layout-${layout}`;
  document.querySelectorAll('#tracks-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === layout)
  );
  if (APP.topTracksData.length && list) {
    const maxPlay = APP.topTracksData.length > 0 ? parseInt(APP.topTracksData[0].playcount) : 1;
    _injectAlbumImagesIntoTracks(APP.topTracksData.slice(0, APP.tracksPage * 50));
    list.innerHTML = APP.topTracksData.slice(0, APP.tracksPage * 50).map((tr,i) => _buildTrackItem(tr, i+1, maxPlay)).join('');
    _resolveTrackImages(APP.topTracksData.slice(0, APP.tracksPage * 50), 1);
  }
}

function _buildTrackItem(track, rank, maxPlay) {
  const pct        = ((parseInt(track.playcount) / Math.max(maxPlay, 1)) * 100).toFixed(1);
  const medal      = rank <= 3 ? ['🥇','🥈','🥉'][rank-1] : rank;
  const spQ        = encodeURIComponent(`${track.name} ${track.artist?.name || ''}`);
  const ytQ        = encodeURIComponent(`${track.name} ${track.artist?.name || ''}`);
  const imgUrl     = track.image?.find(im => im.size === 'extralarge')?.['#text'] || track.image?.find(im => im.size === 'large')?.['#text'] || track.image?.find(im => im.size === 'medium')?.['#text'] || '';
  const hasCover   = !isDefaultImg(imgUrl);
  const coverBg    = nameToGradient(track.name + (track.artist?.name || ''));
  const coverLtr   = (track.name || '?')[0].toUpperCase();
  const delay      = Math.min((rank-1) % 20, 10) * 0.025;
  const coverElId  = `track-cover-r${rank}`;
  const safeUrl    = (track.url || '#').replace(/'/g,'%27');

    if ((APP.tracksLayout || 'list') === 'grid') {
    return `
    <div class="hero-card" style="animation-delay:${delay}s" onclick="window.open('${safeUrl}','_blank')">
      <div class="hc-fallback" style="background:${coverBg}${hasCover ? ';display:none' : ''}">${coverLtr}</div>
      <img class="hc-img img-fade" id="${coverElId}-img" ${hasCover ? `src="${imgUrl}"` : 'src=""'} alt="${escHtml(track.name)}" loading="lazy"
           style="${hasCover ? '' : 'display:none'}"
           onload="this.classList.add('img-loaded');this.previousElementSibling.style.display='none';"
           onerror="this.style.display='none';this.previousElementSibling.style.removeProperty('display');">
      <div class="hc-overlay"></div>
      <div class="hc-rank">${rank}</div>
      <div class="hc-body">
        <div class="hc-name">${escHtml(track.name)}</div>
        <div class="hc-sub">${escHtml(track.artist?.name || '')}</div>
        <div class="hc-plays">${formatNum(track.playcount)} ${t('plays')}</div>
      </div>
      <div class="hc-actions">
        <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" title="Spotify"><i class="fab fa-spotify"></i></a>
        <a class="mc-play-btn yt" href="https://www.youtube.com/results?search_query=${ytQ}" target="_blank" rel="noopener" onclick="event.stopPropagation()" title="YouTube"><i class="fab fa-youtube"></i></a>
        <button class="mc-play-btn share" onclick="event.stopPropagation();shareTrack(${JSON.stringify(track.name)},${JSON.stringify(track.artist?.name||'')},${track.playcount},'${safeUrl}')" title="${t('share')}"><i class="fas fa-share-alt"></i></button>
      </div>
    </div>`;
  }

    return `
    <div class="track-item" style="animation-delay:${delay}s"
         onclick="window.open('${safeUrl}','_blank')">
      <div class="track-cover" id="${coverElId}">
        ${hasCover ? `<img src="${imgUrl}" alt="${escHtml(track.name)}" loading="lazy" class="img-fade" onload="this.classList.add('img-loaded')" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
        <div style="width:100%;height:100%;background:${coverBg};display:${hasCover ? 'none' : 'flex'};align-items:center;justify-content:center;font-size:1.2rem;font-weight:900;color:white">${coverLtr}</div>
      </div>
      <div class="track-rank">${medal}</div>
      <div class="track-info">
        <div class="track-name" title="${escHtml(track.name)}">
          <i class="fas fa-music" style="font-size:.65rem;opacity:.35;margin-right:5px"></i>${escHtml(track.name)}
        </div>
        <div class="track-artist">${escHtml(track.artist?.name || '')}</div>
      </div>
      <div class="track-bar-wrap"><div class="track-bar" style="width:${pct}%"></div></div>
      <div class="track-plays">${formatNum(track.playcount)}</div>
      <div class="track-play-btns">
        <a class="track-play-btn sp" href="spotify:search:${spQ}" aria-label="Open in Spotify" title="Spotify" onclick="event.stopPropagation()"><i class="fab fa-spotify"></i></a>
        <a class="track-play-btn yt" href="https://www.youtube.com/results?search_query=${ytQ}" target="_blank" rel="noopener" aria-label="Search on YouTube" title="YouTube" onclick="event.stopPropagation()"><i class="fab fa-youtube"></i></a>
        <button class="track-play-btn share" aria-label="${t('share')} ${escHtml(track.name)}" title="${t('share')}" onclick="event.stopPropagation();shareTrack(${JSON.stringify(track.name)},${JSON.stringify(track.artist?.name||'')},${track.playcount},'${safeUrl}')"><i class="fas fa-share-alt"></i></button>
      </div>
    </div>`;
}

// Injecte les images d'album dans les tracks depuis APP.trackAlbumImgMap
// Modifie les objets track en place pour que _buildTrackItem trouve les URLs.
// Ne fait pas d'appel API — utilise uniquement la map déjà construite.
function _injectAlbumImagesIntoTracks(tracks) {
  if (!APP.trackAlbumImgMap?.size) return;
  tracks.forEach(tr => {
    // check if track already has a real extralarge image
    const existing = tr.image?.find(i => i.size === 'extralarge')?.['#text'] || '';
    if (existing && !isDefaultImg(existing)) return;

    const albumName  = tr.album?.['#text'] || '';
    const artistName = tr.artist?.name || '';
    if (!albumName) return;

    const key    = `${artistName.toLowerCase()}::${albumName.toLowerCase()}`;
    const imgUrl = APP.trackAlbumImgMap.get(key);
    if (!imgUrl) return;

    // inject URL into all sizes so _buildTrackItem can pick it up
    if (!tr.image) tr.image = [];
    ['extralarge','large','medium'].forEach(size => {
      const entry = tr.image.find(i => i.size === size);
      if (entry) entry['#text'] = imgUrl;
      else tr.image.push({ size, '#text': imgUrl });
    });
  });
}

async function _resolveTrackImage(track, rank) {
  // supports list/compact (track-cover div) and grid (hero-card img)
  const coverEl  = document.getElementById(`track-cover-r${rank}`);
  const heroImg  = document.getElementById(`track-cover-r${rank}-img`);
  if (!coverEl && !heroImg) return;

  const existingImg = track.image?.find(im => im.size === 'medium')?.['#text'] || track.image?.find(im => im.size === 'small')?.['#text'] || '';
  if (!isDefaultImg(existingImg)) return;

  const cacheKey = `${(track.artist?.name||'').toLowerCase()}::${(track.album?.['#text']||track.name||'').toLowerCase()}`;
  if (_trackImgCache.has(cacheKey)) {
    const cached = _trackImgCache.get(cacheKey);
    if (cached) {
      if (coverEl) _injectTrackCoverImg(coverEl, cached);
      if (heroImg) _injectHeroImg(heroImg, cached);
    }
    return;
  }

  try {
    let imgUrl = null;
    const albumTitle = track.album?.['#text'] || '';
    if (albumTitle) {
      try {
        const d = await API.call('album.getInfo', { artist:track.artist?.name||'', album:albumTitle, autocorrect:1 });
        imgUrl = d.album?.image?.find(i => i.size === 'extralarge')?.['#text'] || d.album?.image?.find(i => i.size === 'large')?.['#text'] || '';
        if (isDefaultImg(imgUrl)) imgUrl = null;
      } catch {}
    }
    if (!imgUrl) {
      try {
        const d = await API.call('track.getInfo', { artist:track.artist?.name||'', track:track.name||'', autocorrect:1 });
        imgUrl = d.track?.album?.image?.find(i => i.size === 'extralarge')?.['#text'] || d.track?.album?.image?.find(i => i.size === 'large')?.['#text'] || '';
        if (isDefaultImg(imgUrl)) imgUrl = null;
      } catch {}
    }
    _trackImgCache.set(cacheKey, imgUrl || null);
    if (imgUrl) {
      if (coverEl) _injectTrackCoverImg(coverEl, imgUrl);
      if (heroImg) _injectHeroImg(heroImg, imgUrl);
    }
  } catch { _trackImgCache.set(cacheKey, null); }
}

// inject image into an existing hero-card img (grid mode)
function _injectHeroImg(imgEl, imgUrl) {
  if (!imgEl || !imgUrl) return;
  const rawSrc = imgEl.getAttribute('src');
  if (rawSrc && rawSrc.length > 0) return; // already has a real URL
  imgEl.src = imgUrl;
  imgEl.style.display = '';
  imgEl.classList.remove('img-loaded');
  imgEl.onload = () => {
    imgEl.classList.add('img-loaded');
    // hide fallback once image is loaded
    const fallback = imgEl.closest('.hero-card')?.querySelector('.hc-fallback');
    if (fallback) fallback.style.display = 'none';
  };
  imgEl.onerror = () => {
    imgEl.remove();
    // show fallback if image fails
    const card = imgEl.closest?.('.hero-card');
    const fallback = card?.querySelector('.hc-fallback');
    if (fallback) fallback.style.removeProperty('display');
  };
}

function _injectTrackCoverImg(coverEl, imgUrl) {
  if (!coverEl || !imgUrl || coverEl.querySelector('img[src]')) return;
  const img     = document.createElement('img');
  img.src       = imgUrl; img.alt = ''; img.loading = 'lazy';
  img.className = 'img-fade';
  img.style.cssText = 'width:100%;height:100%;object-fit:cover;border-radius:inherit;position:absolute;inset:0';
  img.onerror   = () => img.remove();
  img.onload    = () => {
    img.classList.add('img-loaded');
    const fb = coverEl.querySelector('div');
    if (fb) fb.style.display = 'none';
  };
  coverEl.style.position = 'relative';
  coverEl.prepend(img);
}

function _resolveTrackImages(tracks, startRank = 1) {
  tracks.forEach((track, i) => {
    const img = track.image?.find(im => im.size === 'medium')?.['#text'] || '';
    if (isDefaultImg(img)) setTimeout(() => _resolveTrackImage(track, startRank + i), i * 120);
  });
}

async function loadTopTracks(period) {
  APP.tracksPage      = 1;
  APP.tracksPeriod    = period;
  APP.tracksLoading   = false;
  APP.tracksExhausted = false;

  const list     = document.getElementById('tracks-list');
  const loader   = document.getElementById('tracks-page-loader');
  const sentinel = document.getElementById('tracks-scroll-sentinel');

  if (list) {
    list.className = APP.tracksLayout === 'grid' ? 'hero-grid' : `tracks-list layout-${APP.tracksLayout}`;
    list.innerHTML = skeletonTrackItems(12);
  }
  if (loader) loader.classList.add('hidden');
  if (_tracksObserver) { _tracksObserver.disconnect(); _tracksObserver = null; }

  document.querySelectorAll('#tracks-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === APP.tracksLayout)
  );

  try {
    // fetch tracks + top albums (200) in parallel to resolve images
    const [tracksResp, albumsResp] = await Promise.all([
      API.call('user.getTopTracks',  { period, limit:50,  page:1 }),
      API.call('user.getTopAlbums',  { period, limit:200, page:1 }),
    ]);

    const tracks = tracksResp.toptracks?.track || [];
    const albums = albumsResp.topalbums?.album  || [];

    // build artist::album → imageUrl map from albums
    APP.trackAlbumImgMap = new Map();
    albums.forEach(alb => {
      const img = alb.image?.find(i => i.size === 'extralarge')?.['#text']
               || alb.image?.find(i => i.size === 'large')?.['#text'] || '';
      if (!isDefaultImg(img)) {
        const k = `${(alb.artist?.name||'').toLowerCase()}::${(alb.name||'').toLowerCase()}`;
        APP.trackAlbumImgMap.set(k, img);
      }
    });

    // inject album images into tracks before rendering
    _injectAlbumImagesIntoTracks(tracks);

    APP.topTracksData    = tracks;
    APP.tracksTotalPages = parseInt(tracksResp.toptracks?.['@attr']?.totalPages || 1);
    const maxPlay        = tracks.length > 0 ? parseInt(tracks[0].playcount) : 1;
    if (list) list.innerHTML = tracks.map((tr,i) => _buildTrackItem(tr, i+1, maxPlay)).join('');
    // async fallback for tracks not covered by the album map
    _resolveTrackImages(tracks, 1);

    if (APP.tracksTotalPages > 1 && sentinel) {
      _tracksObserver = new IntersectionObserver(
        entries => { if (entries[0].isIntersecting) _loadMoreTracks(); },
        { rootMargin:'200px' }
      );
      _tracksObserver.observe(sentinel);
    }
  } catch (e) { if (list) list.innerHTML = `<p style="color:var(--text-muted);padding:20px">${escHtml(e.message)}</p>`; }
}

async function _loadMoreTracks() {
  if (APP.tracksLoading || APP.tracksExhausted) return;
  if (APP.tracksPage >= APP.tracksTotalPages) { APP.tracksExhausted = true; return; }
  APP.tracksLoading = true;
  APP.tracksPage++;

  const list   = document.getElementById('tracks-list');
  const loader = document.getElementById('tracks-page-loader');
  if (loader) loader.classList.remove('hidden');

  try {
    const data   = await API.call('user.getTopTracks', { period:APP.tracksPeriod, limit:50, page:APP.tracksPage });
    const tracks = data.toptracks?.track || [];
    if (!tracks.length) { APP.tracksExhausted = true; return; }
    const maxPlay    = APP.topTracksData.length > 0 ? parseInt(APP.topTracksData[0].playcount) : 1;
    const startRank  = (APP.tracksPage - 1) * 50 + 1;
    _injectAlbumImagesIntoTracks(tracks);
    tracks.forEach((tr,i) => list.insertAdjacentHTML('beforeend', _buildTrackItem(tr, startRank + i, maxPlay)));
    _resolveTrackImages(tracks, startRank);
    APP.topTracksData = [...APP.topTracksData, ...tracks];
  } catch (e) { console.warn('_loadMoreTracks:', e); }
  finally { APP.tracksLoading = false; if (loader) loader.classList.add('hidden'); }
}

// period selectors
function initPeriodSelectors() {
  [
    { id:'prd-artists', fn:loadTopArtists },
    { id:'prd-albums',  fn:loadTopAlbums  },
    { id:'prd-tracks',  fn:loadTopTracks  },
  ].forEach(({ id, fn }) => {
    const container = document.getElementById(id);
    if (!container) return;
    container.querySelectorAll('.prd').forEach(btn => {
      btn.addEventListener('click', () => {
        container.querySelectorAll('.prd').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        fn(btn.dataset.p);
      });
    });
  });
}

function setupChartsSection() {
  const currentYear = new Date().getFullYear();
  const sel = document.getElementById('yr-sel');
  if (!sel) return;
  sel.innerHTML = '';
  for (let y = currentYear; y >= APP.regYear; y--) {
    sel.innerHTML += `<option value="${y}">${y}</option>`;
  }
  loadMonthlyChart(currentYear);
  loadCumulativeChart();
  loadPieCharts();

  // if full history is loaded, render charts right away
  if (APP.fullHistory?.length) {
    const hourCounts = Array(24).fill(0);
    for (const tr of APP.fullHistory) {
      const ts = parseInt(tr.date?.uts || 0);
      if (ts) hourCounts[new Date(ts * 1000).getHours()]++;
    }
    _renderHourlyChart(hourCounts);
    _renderDayOfWeekChart(APP.fullHistory);
    _renderOHWList(APP.fullHistory);
    const hourlyHint  = document.getElementById('hourly-hint');
    const weekdayHint = document.getElementById('weekday-hint');
    if (hourlyHint)  hourlyHint.textContent  = '';
    if (weekdayHint) weekdayHint.textContent = '';
    document.getElementById('ohw-empty')?.style.setProperty('display', 'none');

    // ← Fix: render heatmap calendar in charts tab
    _buildCalHeatmapYearSel('charts');
    renderListeningHeatmap(currentYear, 'charts');
  } else {
    // show empty state for one-hit wonders
    const ohwEmpty = document.getElementById('ohw-empty');
    const ohwList  = document.getElementById('ohw-list');
    if (ohwEmpty) ohwEmpty.style.display = '';
    if (ohwList)  ohwList.innerHTML = '';
  }

  // auto-render all charts
  setTimeout(() => {
    loadMusicalProfile();
  }, 1200);
}

async function loadMonthlyChart(year) {
  year = parseInt(year);
  const prog = document.getElementById('monthly-prog');
  const fill = document.getElementById('monthly-fill');
  const txt  = document.getElementById('monthly-prog-txt');
  if (prog) prog.classList.remove('hidden');
  if (fill) fill.style.width = '0%';

  const counts = [];
  for (let m = 0; m < 12; m++) {
    const n = await API.getMonthScrobbles(year, m);
    counts.push(n);
    if (fill) fill.style.width = `${Math.round((m+1)/12*100)}%`;
    if (txt)  txt.textContent  = `${MONTHS_SHORT()[m]} ${year} — ${formatNum(n)} ${t('scrobbles')}`;
  }
  if (prog) prog.classList.add('hidden');

  destroyChart('chart-monthly');
  const c = getThemeColors();
  APP.charts['chart-monthly'] = new Chart(document.getElementById('chart-monthly'), {
    type:'bar',
    data:{
      labels: MONTHS(),
      datasets:[{ label:t('chart_monthly_label', year), data:counts, backgroundColor:CHART_PALETTE.map(p => p+'bb'), borderColor:CHART_PALETTE, borderWidth:1, borderRadius:7 }],
    },
    options:{
      ...baseChartOpts(),
      plugins:{ ...baseChartOpts().plugins, tooltip:{ ...baseChartOpts().plugins.tooltip, callbacks:{ label:ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } } },
      scales:{ x:{ grid:{ display:false }, ticks:{ color:c.text } }, y:{ grid:{ color:c.grid }, ticks:{ color:c.text } } },
    },
  });
}

async function loadCumulativeChart() {
  const currentYear = new Date().getFullYear();
  const labels = [], cumulative = [];
  let total = 0;

  for (let y = APP.regYear; y <= currentYear; y++) {
    const mCounts = await Promise.all(Array(12).fill(0).map((_,m) => API.getMonthScrobbles(y, m)));
    mCounts.forEach((n, m) => {
      if (y < currentYear || m <= new Date().getMonth()) {
        total += n;
        labels.push(`${MONTHS_SHORT()[m]} ${y}`);
        cumulative.push(total);
      }
    });
  }

  destroyChart('chart-cumul');
  const c = getThemeColors();
  APP.charts['chart-cumul'] = new Chart(document.getElementById('chart-cumul'), {
    type:'line',
    data:{
      labels,
      datasets:[{ label:t('chart_cumul_label'), data:cumulative, borderColor:'#6366f1', backgroundColor:'rgba(99,102,241,0.08)', fill:true, tension:0.4, pointRadius:cumulative.length > 60 ? 0 : 3, pointHoverRadius:5, borderWidth:2 }],
    },
    options:{
      ...baseChartOpts(),
      animation:{ duration:cumulative.length > 80 ? 0 : 600, easing:'easeOutQuart' },
      plugins:{ ...baseChartOpts().plugins, tooltip:{ ...baseChartOpts().plugins.tooltip, callbacks:{ label:ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } } },
      scales:{ x:{ grid:{ display:false }, ticks:{ color:c.text, maxTicksLimit:14 } }, y:{ grid:{ color:c.grid }, ticks:{ color:c.text } } },
    },
  });
}

async function loadPieCharts() {
  const c = getThemeColors();
  const pieOpts = {
    responsive:true, maintainAspectRatio:false,
    plugins:{
      legend:{ position:'right', labels:{ color:c.text, boxWidth:12, padding:8, font:{ size:11 } } },
      tooltip:{ callbacks:{ label:ctx => ` ${ctx.label}: ${formatNum(ctx.raw)}` } },
    },
    cutout:'56%', animation:{ duration:700 },
  };

  try {
    if (!APP.topArtistsData.length) {
      const d = await API.call('user.getTopArtists', { period:'overall', limit:10 });
      APP.topArtistsData = d.topartists?.artist || [];
    }
    const top10a = APP.topArtistsData.slice(0, 10);
    destroyChart('chart-art-pie');
    APP.charts['chart-art-pie'] = new Chart(document.getElementById('chart-art-pie'), {
      type:'doughnut',
      data:{ labels:top10a.map(a => a.name), datasets:[{ data:top10a.map(a => parseInt(a.playcount)), backgroundColor:CHART_PALETTE, borderWidth:2, borderColor:c.isDark ? '#07071a' : '#f1f5f9', hoverOffset:8 }] },
      options:pieOpts,
    });
  } catch {}

  try {
    if (!APP.topAlbumsData.length) {
      const d = await API.call('user.getTopAlbums', { period:'overall', limit:10 });
      APP.topAlbumsData = d.topalbums?.album || [];
    }
    const top10b = APP.topAlbumsData.slice(0, 10);
    destroyChart('chart-alb-pie');
    APP.charts['chart-alb-pie'] = new Chart(document.getElementById('chart-alb-pie'), {
      type:'doughnut',
      data:{ labels:top10b.map(a => a.name), datasets:[{ data:top10b.map(a => parseInt(a.playcount)), backgroundColor:CHART_PALETTE, borderWidth:2, borderColor:c.isDark ? '#07071a' : '#f1f5f9', hoverOffset:8 }] },
      options:pieOpts,
    });
  } catch {}
}

function _prevPeriodKey(period) {
  return { '7day':'1month','1month':'3month','3month':'6month','6month':'12month','12month':'overall','overall':'overall' }[period] || 'overall';
}

async function loadPeriodComparison() {
  const selA  = document.getElementById('compare-period-a');
  const selB  = document.getElementById('compare-period-b');
  const resEl = document.getElementById('compare-results');
  const ldEl  = document.getElementById('compare-loading');
  const descEl= document.getElementById('compare-desc');
  if (!selA || !selB) return;

  const periodA = selA.value;
  const labelA  = getPeriodLabel(periodA);
  const labelB  = getPeriodLabel(_prevPeriodKey(periodA));

  if (descEl) descEl.innerHTML = `<strong>${labelA}</strong> <span class="compare-vs-icon">vs</span> <strong>${labelB}</strong>`;

  const tagA = document.getElementById('cmp-period-tag-a');
  const tagB = document.getElementById('cmp-period-tag-b');
  if (tagA) tagA.textContent = labelA;
  if (tagB) tagB.textContent = labelB;

  if (resEl) resEl.classList.add('hidden');
  if (ldEl)  ldEl.classList.remove('hidden');

  try {
    const prevPeriod = _prevPeriodKey(periodA);
    const [dataA, dataB, topArtistsB] = await Promise.all([
      API.call('user.getTopArtists', { period:periodA,   limit:1 }),
      API.call('user.getTopArtists', { period:prevPeriod, limit:1 }),
      API.call('user.getTopArtists', { period:prevPeriod, limit:3 }),
    ]);

    const totalA = parseInt(dataA.topartists?.['@attr']?.total || 0);
    const totalB = parseInt(dataB.topartists?.['@attr']?.total || 0);
    const scDiff = totalA - totalB;
    const scPct  = totalB > 0 ? ((scDiff / totalB) * 100).toFixed(1) : null;
    const top1A  = dataA.topartists?.artist?.[0]?.name || '—';
    const top1B  = (topArtistsB.topartists?.artist || [])[0]?.name || '—';

    const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
    setText('cmp-scrobbles-a', formatNum(totalA));
    setText('cmp-scrobbles-b', formatNum(totalB));
    _setCompareDelta('cmp-scrobbles-delta', scDiff, scPct);
    setText('cmp-artists-a', top1A);
    setText('cmp-artists-b', top1B);
    setText('cmp-listen-a', estimateListenTime(totalA));
    setText('cmp-listen-b', estimateListenTime(totalB));

    if (resEl) resEl.classList.remove('hidden');
  } catch (e) { showToast(t('toast_compare_error', e.message), 'error'); }
  finally { if (ldEl) ldEl.classList.add('hidden'); }
}

function _setCompareDelta(id, diff, pct) {
  const el = document.getElementById(id);
  if (!el) return;
  if (pct === null || diff === 0) { el.textContent = t('versus_stable'); el.className = 'cmp-delta cmp-flat'; }
  else {
    el.textContent = `${diff > 0 ? '▲' : '▼'} ${diff > 0 ? '+' : ''}${pct}%`;
    el.className   = `cmp-delta ${diff > 0 ? 'cmp-up' : 'cmp-down'}`;
  }
  el.classList.remove('hidden');
}

function setupWrappedSection() {
  const currentYear = new Date().getFullYear();
  const sel = document.getElementById('w-yr-sel');
  if (!sel) return;
  sel.innerHTML = '';
  for (let y = currentYear; y >= APP.regYear; y--) {
    sel.innerHTML += `<option value="${y}"${y === currentYear - 1 ? ' selected' : ''}>${y}</option>`;
  }
  loadWrapped(currentYear - 1);
}

async function loadWrapped(year) {
  year = parseInt(year);
  document.getElementById('w-loader')?.classList.remove('hidden');
  const wrappedCard = document.getElementById('wrapped-card');
  if (wrappedCard) wrappedCard.style.opacity = '.4';

  const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
  setText('w-yr-badge', year);
  setText('w-uname',    '@' + (APP.userInfo?.name || APP.username));

  const progFill    = document.getElementById('w-prog-fill');
  const progN       = document.getElementById('w-prog-n');
  const monthCounts = [];

  for (let m = 0; m < 12; m++) {
    const n = await API.getMonthScrobbles(year, m);
    monthCounts.push(n);
    if (progFill) progFill.style.width = Math.round((m+1)/12*100) + '%';
    if (progN)    progN.textContent    = m + 1;
  }

  const totalYear = monthCounts.reduce((a,b) => a+b, 0);
  const maxMonth  = monthCounts.indexOf(Math.max(...monthCounts));

  setText('w-scrobbles',   formatNum(totalYear));
  setText('w-top-m',       MONTHS()[maxMonth] || '');
  const ltEl = document.getElementById('w-listen-time');
  if (ltEl && totalYear > 0) ltEl.textContent = estimateListenTime(totalYear);

  try {
    const [artData, trkData, albData] = await Promise.all([
      API.call('user.getTopArtists', { period:'12month', limit:50 }),
      API.call('user.getTopTracks',  { period:'12month', limit:50 }),
      API.call('user.getTopAlbums',  { period:'12month', limit:50 }),
    ]);
    const arts = artData.topartists?.artist || [];
    const trks = trkData.toptracks?.track   || [];
    const albs = albData.topalbums?.album   || [];

    setText('w-art-cnt', formatNum(artData.topartists?.['@attr']?.total || arts.length));
    if (arts[0]) _fillWrappedPod('art', arts[0].name, arts[0].playcount, arts[0].image?.find(i => i.size === 'extralarge')?.['#text']);
    if (trks[0]) _fillWrappedPod('trk', trks[0].name, trks[0].playcount, null, trks[0].name + (trks[0].artist?.name || ''));
    if (albs[0]) _fillWrappedPod('alb', albs[0].name, albs[0].playcount, albs[0].image?.find(i => i.size === 'extralarge')?.['#text']);
  } catch (e) { console.warn('wrapped tops:', e); }

  destroyChart('w-mini');
  APP.charts['w-mini'] = new Chart(document.getElementById('w-mini'), {
    type:'bar',
    data:{ labels:MONTHS_SHORT(), datasets:[{ data:monthCounts, backgroundColor:'rgba(255,255,255,.25)', borderColor:'rgba(255,255,255,.5)', borderWidth:1, borderRadius:3 }] },
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ display:false } }, scales:{ x:{ grid:{ display:false }, ticks:{ color:'rgba(255,255,255,.55)', font:{ size:8 } } }, y:{ display:false } }, animation:{ duration:500 } },
  });

  document.getElementById('w-loader')?.classList.add('hidden');
  if (wrappedCard) wrappedCard.style.opacity = '1';
}

function _fillWrappedPod(prefix, name, playcount, imgUrl, fallbackSeed) {
  const letter = (name || '?')[0].toUpperCase();
  const seed   = fallbackSeed || name;
  const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
  setText(`w-${prefix}-name`,  name);
  setText(`w-${prefix}-plays`, formatNum(playcount) + ' ' + t('plays'));
  setText(`w-${prefix}-lt`,    letter);

  const imgEl = document.getElementById(`w-${prefix}-img`);
  if (imgEl) {
    imgEl.style.background = nameToGradient(seed);
    if (imgUrl && !isDefaultImg(imgUrl)) {
      const img = document.createElement('img');
      img.src   = imgUrl; img.alt = escHtml(name);
      img.style.cssText = 'width:100%;height:100%;object-fit:cover;border-radius:50%';
      img.onerror = () => img.remove();
      imgEl.innerHTML = '';
      imgEl.appendChild(img);
    }
  }
}

async function exportWrapped() {
  const card = document.getElementById('wrapped-card');
  try {
    showToast(t('wrapped_generating'));
    document.body.classList.add('export-mode');
    if (document.fonts?.ready) await document.fonts.ready;
    await sleep(80);
    const canvas = await html2canvas(card, { scale:2, useCORS:true, allowTaint:true, backgroundColor:null, logging:false });
    document.body.classList.remove('export-mode');
    downloadCanvas(canvas, `laststats-wrapped-${document.getElementById('w-yr-sel').value}.png`);
    showToast(t('wrapped_exported'));
  } catch (e) { document.body.classList.remove('export-mode'); showToast(t('wrapped_export_error', e.message), 'error'); }
}

async function generateStory(type) {
  showToast(t('story_preparing'));
  try {
    const u       = APP.userInfo;
    const year    = document.getElementById('w-yr-sel')?.value || new Date().getFullYear() - 1;
    const artists = APP.topArtistsData.slice(0, 3);
    const tracks  = APP.topTracksData.slice(0, 3);
    if (!artists.length) { showToast(t('story_no_data'), 'error'); return; }

    const username   = u?.name || APP.username;
    const art0       = artists[0];
    const trk0       = tracks[0];
    const alb0       = APP.topAlbumsData[0];
    const scrobbles  = document.getElementById('w-scrobbles')?.textContent || '—';
    const artCnt     = document.getElementById('w-art-cnt')?.textContent   || '—';
    const topMonth   = document.getElementById('w-top-m')?.textContent     || '—';
    const artImgUrl  = await getArtistImage(art0.name);

    const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };

    if (type === 'mini') {
      setText('story-mini-year',      year);
      setText('story-mini-username',  '@' + username);
      setText('story-mini-scrobbles', scrobbles);
      setText('story-mini-artists',   artCnt);
      setText('story-mini-art-name',  art0.name);
      setText('story-mini-art-lt',    art0.name[0].toUpperCase());
      const artImgEl = document.getElementById('story-mini-art-img');
      if (artImgEl) {
        artImgEl.style.background = nameToGradient(art0.name);
        if (artImgUrl) {
          const img = document.createElement('img'); img.src = artImgUrl;
          img.style.cssText = 'width:100%;height:100%;object-fit:cover;border-radius:50%';
          img.onerror = () => img.remove();
          artImgEl.innerHTML = ''; artImgEl.appendChild(img);
        }
      }
      if (trk0) setText('story-mini-trk-name', trk0.name);
      await _captureStory('story-mini-card', 360, 640, `laststats-story-${year}.png`);
    } else {
      setText('story-full-year',      year);
      setText('story-full-username',  '@' + username);
      setText('story-full-scrobbles', scrobbles);
      setText('story-full-artists',   artCnt);
      setText('story-full-month',     topMonth);
      setText('story-full-art-name',  art0.name);
      setText('story-full-art-plays', formatNum(art0.playcount) + ' ' + t('plays'));
      setText('story-full-art-lt',    art0.name[0].toUpperCase());
      const fullArtImg = document.getElementById('story-full-art-img');
      if (fullArtImg) {
        fullArtImg.style.background = nameToGradient(art0.name);
        if (artImgUrl) {
          const img = document.createElement('img'); img.src = artImgUrl;
          img.style.cssText = 'width:100%;height:100%;object-fit:cover;border-radius:50%';
          img.onerror = () => img.remove();
          fullArtImg.innerHTML = ''; fullArtImg.appendChild(img);
        }
      }
      if (trk0) {
        setText('story-full-trk-name',  trk0.name);
        setText('story-full-trk-plays', formatNum(trk0.playcount) + ' ' + t('plays'));
        setText('story-full-trk-lt',    trk0.name[0].toUpperCase());
        const trkImgEl = document.getElementById('story-full-trk-img');
        if (trkImgEl) trkImgEl.style.background = nameToGradient(trk0.name);
      }
      if (alb0) {
        setText('story-full-alb-name',  alb0.name);
        setText('story-full-alb-plays', formatNum(alb0.playcount) + ' ' + t('plays'));
        setText('story-full-alb-lt',    alb0.name[0].toUpperCase());
        const albImgEl  = document.getElementById('story-full-alb-img');
        if (albImgEl) {
          albImgEl.style.background = nameToGradient(alb0.name);
          const albImgUrl = alb0.image?.find(i => i.size === 'medium')?.['#text'];
          if (albImgUrl && !isDefaultImg(albImgUrl)) {
            const img = document.createElement('img'); img.src = albImgUrl;
            img.style.cssText = 'width:100%;height:100%;object-fit:cover;border-radius:50%';
            img.onerror = () => img.remove();
            albImgEl.innerHTML = ''; albImgEl.appendChild(img);
          }
        }
      }
      await _captureStory('story-full-card', 680, 860, `laststats-full-${year}.png`);
    }
    showToast(t('story_downloaded'));
  } catch (e) { document.body.classList.remove('export-mode'); showToast(t('story_error', e.message), 'error'); }
}

async function _captureStory(cardId, w, h, filename) {
  const card = document.getElementById(cardId);
  document.body.classList.add('export-mode');
  if (document.fonts?.ready) await document.fonts.ready;
  await sleep(120);
  const canvas = await html2canvas(card, { scale:2, useCORS:true, allowTaint:true, backgroundColor:null, width:w, height:h, windowWidth:w, windowHeight:h, logging:false });
  document.body.classList.remove('export-mode');
  downloadCanvas(canvas, filename);
}

function downloadCanvas(canvas, filename) {
  const link = document.createElement('a');
  link.download = filename;
  link.href = canvas.toDataURL('image/png');
  link.click();
}

async function exportSectionCard(section) {
  const W = 360, H = 640;
  const canvas  = document.createElement('canvas');
  canvas.width  = W * 2;
  canvas.height = H * 2;
  const ctx = canvas.getContext('2d');
  ctx.scale(2, 2);

  // Fond dégradé
  const bgGrad = ctx.createLinearGradient(0, 0, W, H);
  bgGrad.addColorStop(0,   '#1a1025');
  bgGrad.addColorStop(0.45,'#0f172a');
  bgGrad.addColorStop(1,   '#0d1117');
  ctx.fillStyle = bgGrad;
  ctx.fillRect(0, 0, W, H);

  
  const gCircle = ctx.createRadialGradient(0, 0, 0, 0, 0, 200);
  gCircle.addColorStop(0, 'rgba(99,102,241,0.18)');
  gCircle.addColorStop(1, 'transparent');
  ctx.fillStyle = gCircle;
  ctx.fillRect(0, 0, W, H);

  
  let items = [], sectionLabel = '', filename = 'laststats-story.png';

  if (section === 'top-albums') {
    items        = (APP.topAlbumsData  || []).slice(0, 5);
    sectionLabel = 'Top Albums';
    filename     = 'laststats-top-albums.png';
  } else if (section === 'top-artists') {
    items        = (APP.topArtistsData || []).slice(0, 5);
    sectionLabel = 'Top Artists';
    filename     = 'laststats-top-artists.png';
  } else if (section === 'top-tracks') {
    items        = (APP.topTracksData  || []).slice(0, 5);
    sectionLabel = 'Top Tracks';
    filename     = 'laststats-top-tracks.png';
  }

  if (!items.length) { showToast(t('story_no_data'), 'error'); return; }
  showToast(t('story_preparing'));

  // preload cover images (crossOrigin anonymous)
  const loadImg = url => new Promise(res => {
    if (!url || isDefaultImg(url)) return res(null);
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload  = () => res(img);
    img.onerror = () => res(null);
    img.src     = url + (url.includes('?') ? '&' : '?') + '_nc=' + Date.now();
  });

  const imgUrls = items.map(item =>
    item.image?.find(i => i.size === 'extralarge')?.['#text']
    || item.image?.find(i => i.size === 'large')?.['#text']
    || null
  );
  const imgs = await Promise.all(imgUrls.map(loadImg));

  
  const clampText = (text, maxW) => {
    let s = String(text || '—');
    while (ctx.measureText(s).width > maxW && s.length > 1) s = s.slice(0, -1);
    return s.length < String(text || '—').length ? s + '…' : s;
  };

  
  // logo
  ctx.font = 'bold 20px system-ui, sans-serif';
  ctx.fillStyle = '#a78bfa';
  ctx.textAlign = 'left';
  ctx.fillText('LastStats', 24, 48);

  // username
  const username = '@' + (APP.userInfo?.name || APP.username || '');
  ctx.font = '12px system-ui, sans-serif';
  ctx.fillStyle = 'rgba(255,255,255,0.45)';
  ctx.fillText(username, 24, 68);

  // section title
  ctx.font = 'bold 17px system-ui, sans-serif';
  ctx.fillStyle = '#ffffff';
  ctx.textAlign = 'right';
  ctx.fillText(sectionLabel, W - 24, 48);

  // period label (if available)
  const prdEl = document.querySelector(`#prd-${section.replace('top-', '')} .prd.active`);
  const prdTxt = prdEl ? prdEl.textContent.trim() : '';
  if (prdTxt) {
    ctx.font = '11px system-ui, sans-serif';
    ctx.fillStyle = 'rgba(167,139,250,0.7)';
    ctx.textAlign = 'right';
    ctx.fillText(prdTxt, W - 24, 65);
  }

  // divider line
  const sepGrad = ctx.createLinearGradient(24, 0, W - 24, 0);
  sepGrad.addColorStop(0,   'transparent');
  sepGrad.addColorStop(0.3, 'rgba(167,139,250,0.5)');
  sepGrad.addColorStop(1,   'transparent');
  ctx.strokeStyle = sepGrad; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(24, 84); ctx.lineTo(W - 24, 84); ctx.stroke();

  
  const CARD_H   = 84;
  const CARD_GAP = 8;
  const IMG_SIZE = 62;
  const CARD_X   = 18;
  const CARD_W   = W - 36;
  const START_Y  = 102;

  const rankColors = ['#fbbf24', '#94a3b8', '#cd7c3e', 'rgba(255,255,255,0.22)', 'rgba(255,255,255,0.22)'];
  const isArtist   = section === 'top-artists';
  const isTrack    = section === 'top-tracks';

  items.forEach((item, i) => {
    const cardY = START_Y + i * (CARD_H + CARD_GAP);

    
    const cGrad = ctx.createLinearGradient(CARD_X, cardY, CARD_X + CARD_W, cardY + CARD_H);
    cGrad.addColorStop(0, i === 0 ? 'rgba(167,139,250,0.14)' : 'rgba(255,255,255,0.06)');
    cGrad.addColorStop(1, 'rgba(255,255,255,0.02)');
    ctx.fillStyle = cGrad;
    ctx.beginPath();
    ctx.roundRect(CARD_X, cardY, CARD_W, CARD_H, 14);
    ctx.fill();

    
    ctx.strokeStyle = i === 0 ? 'rgba(167,139,250,0.35)' : 'rgba(255,255,255,0.07)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.roundRect(CARD_X, cardY, CARD_W, CARD_H, 14);
    ctx.stroke();

    
    ctx.font = `bold ${i < 3 ? 20 : 16}px system-ui, sans-serif`;
    ctx.fillStyle = rankColors[i];
    ctx.textAlign = 'center';
    ctx.fillText(`${i + 1}`, CARD_X + 22, cardY + CARD_H / 2 + 7);

    
    const imgX = CARD_X + 42;
    const imgY = cardY + (CARD_H - IMG_SIZE) / 2;

    ctx.save();
    ctx.beginPath();
    if (isArtist) {
      ctx.arc(imgX + IMG_SIZE / 2, imgY + IMG_SIZE / 2, IMG_SIZE / 2, 0, Math.PI * 2);
    } else {
      ctx.roundRect(imgX, imgY, IMG_SIZE, IMG_SIZE, 10);
    }
    ctx.clip();

    if (imgs[i]) {
      ctx.drawImage(imgs[i], imgX, imgY, IMG_SIZE, IMG_SIZE);
    } else {
      // fallback: colored gradient + initial
      const PALETTES = [
        ['#6366f1','#a855f7'],['#ec4899','#f43f5e'],['#06b6d4','#6366f1'],
        ['#22c55e','#14b8a6'],['#f97316','#eab308'],
      ];
      const [c1, c2] = PALETTES[i % PALETTES.length];
      const fbGrad = ctx.createLinearGradient(imgX, imgY, imgX + IMG_SIZE, imgY + IMG_SIZE);
      fbGrad.addColorStop(0, c1); fbGrad.addColorStop(1, c2);
      ctx.fillStyle = fbGrad;
      ctx.fillRect(imgX, imgY, IMG_SIZE, IMG_SIZE);
      ctx.font = `bold 24px system-ui, sans-serif`;
      ctx.fillStyle = 'rgba(255,255,255,0.9)';
      ctx.textAlign = 'center';
      ctx.fillText((item.name || '?')[0].toUpperCase(), imgX + IMG_SIZE / 2, imgY + IMG_SIZE / 2 + 9);
    }
    ctx.restore();

    
    const textX  = imgX + IMG_SIZE + 12;
    const maxTW  = CARD_X + CARD_W - textX - 10;

    ctx.font = `bold ${i === 0 ? 14 : 13}px system-ui, sans-serif`;
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'left';
    ctx.fillText(clampText(item.name, maxTW), textX, cardY + CARD_H / 2 - 6);

    
    let subTxt;
    if (isTrack)       subTxt = item.artist?.name || '';
    else if (isArtist) subTxt = `${formatNum(item.playcount)} ${t('plays')}`;
    else               subTxt = `${item.artist?.name ? item.artist.name + ' · ' : ''}${formatNum(item.playcount)} ${t('plays')}`;

    ctx.font = '11px system-ui, sans-serif';
    ctx.fillStyle = 'rgba(255,255,255,0.48)';
    ctx.fillText(clampText(subTxt, maxTW), textX, cardY + CARD_H / 2 + 12);

    // relative popularity bar (items with playcount only)
    if (item.playcount && items[0]?.playcount) {
      const ratio  = parseInt(item.playcount) / parseInt(items[0].playcount);
      const barW   = maxTW * ratio;
      const barY   = cardY + CARD_H - 14;
      ctx.fillStyle = 'rgba(255,255,255,0.08)';
      ctx.beginPath(); ctx.roundRect(textX, barY, maxTW, 3, 2); ctx.fill();
      const barGrad = ctx.createLinearGradient(textX, 0, textX + barW, 0);
      barGrad.addColorStop(0, '#a78bfa'); barGrad.addColorStop(1, '#6366f1');
      ctx.fillStyle = barGrad;
      ctx.beginPath(); ctx.roundRect(textX, barY, Math.max(barW, 4), 3, 2); ctx.fill();
    }
  });

  
  const footY = START_Y + 5 * (CARD_H + CARD_GAP) + 24;

  const footSep = ctx.createLinearGradient(40, 0, W - 40, 0);
  footSep.addColorStop(0, 'transparent');
  footSep.addColorStop(0.5, 'rgba(167,139,250,0.3)');
  footSep.addColorStop(1, 'transparent');
  ctx.strokeStyle = footSep; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(40, footY); ctx.lineTo(W - 40, footY); ctx.stroke();

  ctx.font = '10px system-ui, sans-serif';
  ctx.fillStyle = 'rgba(255,255,255,0.28)';
  ctx.textAlign = 'center';
  ctx.fillText('laststats.app  ·  powered by last.fm', W / 2, footY + 18);

  downloadCanvas(canvas, filename);
  showToast(t('story_downloaded'));
}
async function loadAdvancedStats() {
  const u        = APP.userInfo;
  const regTs    = parseInt(u?.registered?.unixtime || 0);
  const daysSince= regTs ? Math.floor((Date.now() - regTs * 1000) / 86400000) : 1;
  const total    = parseInt(u?.playcount || 0);
  const avgDay   = daysSince > 0 ? (total / daysSince).toFixed(1) : 0;
  const avgWeek  = (parseFloat(avgDay) * 7).toFixed(0);

  try {
    if (!APP.topArtistsData.length) {
      const d = await API.call('user.getTopArtists', { period:'overall', limit:TOP_LIMIT });
      APP.topArtistsData = d.topartists?.artist || [];
    }

    const playcounts = APP.topArtistsData.map(a => parseInt(a.playcount));
    const eddington  = calcEddington(playcounts);
    const oneHits    = playcounts.filter(p => p === 1).length;
    const maxArtist  = APP.topArtistsData[0];
    const topPct     = total > 0 && maxArtist ? ((parseInt(maxArtist.playcount) / total) * 100).toFixed(1) : 0;

    const cards = [
      { icon:'⚡', value:avgDay,    label:t('adv_per_day'),      sub:t('adv_per_week', avgWeek),           color:'#6366f1' },
      { icon:'🔢', value:eddington, label:t('adv_eddington'),    sub:t('adv_eddington_sub', eddington),    color:'#8b5cf6' },
      { icon:'🌟', value:maxArtist ? maxArtist.name : '—', label:t('adv_top1_alltime'), sub:t('adv_top1_pct', topPct), color:'#a855f7', noAnim:true },
      { icon:'💀', value:oneHits,   label:t('adv_ohw'),          sub:t('adv_ohw_sub'),                     color:'#ec4899' },
      { icon:'📆', value:formatNum(daysSince), label:t('adv_days'), sub:t('adv_days_sub', formatDate(regTs)), color:'#f97316', noAnim:true },
      { icon:'🎯', value:formatNum(total),     label:t('adv_total'), sub:t('adv_total_sub'),               color:'#22c55e', noAnim:true },
    ];

    const grid = document.getElementById('adv-grid');
    if (grid) {
      grid.innerHTML = cards.map((c, i) => `
        <div class="adv-card adv-chip" style="--chip-accent:${c.color};animation-delay:${i * 0.05}s">
          <div class="adv-chip-top">
            <span class="adv-chip-icon">${c.icon}</span>
            <span class="adv-chip-value" style="color:${c.color}">${c.value}</span>
          </div>
          <div class="adv-chip-label">${c.label}</div>
          <div class="adv-chip-sub">${c.sub}</div>
        </div>`).join('');
    }
  } catch (e) {
    const grid = document.getElementById('adv-grid');
    if (grid) grid.innerHTML = `<p style="color:var(--text-muted);grid-column:1/-1">${e.message}</p>`;
  }
}

function calcEddington(playcounts) {
  const sorted = [...playcounts].sort((a,b) => b-a);
  let e = 0;
  for (let i = 0; i < sorted.length; i++) { if (sorted[i] >= i+1) e = i+1; else break; }
  return e;
}

let _historyFetchMinimized = false;
let _bgFetchInProgress     = false;

/* Cache historique persistant — format compact en localStorage
   Clé : ls_hist_v2_{username}
   Structure : { v:2, savedAt:ts, lastTs:unixSeconds, tracks:[compact] }
   ~200 B/scrobble, 4 000 scrobbles ≈ 800 KB */

const HIST_STORAGE_KEY = 'ls_hist_v2_';

/** Compresse un track API en objet minimal pour le localStorage */
function _compactTrack(tr) {
  return {
    n:  tr.name   || '',
    a:  tr.artist?.['#text'] || tr.artist?.name || '',
    al: tr.album?.['#text']  || '',
    u:  parseInt(tr.date?.uts || 0),
    i:  tr.image?.find(i => i.size === 'medium')?.['#text'] || '',
    ul: tr.url || '',
  };
}

/** Reconstruit un track complet depuis le format compact */
function _expandTrack(c) {
  return {
    name:   c.n,
    artist: { '#text': c.a, name: c.a },
    album:  { '#text': c.al },
    date:   { uts: String(c.u) },
    image:  [
      { size: 'small',      '#text': c.i },
      { size: 'medium',     '#text': c.i },
      { size: 'large',      '#text': c.i },
      { size: 'extralarge', '#text': c.i },
    ],
    url: c.ul,
  };
}

/** Sauvegarde l'historique compressé dans localStorage */
function _saveHistoryCache(tracks) {
  if (!APP.username || !tracks?.length) return false;
  try {
    const sorted  = [...tracks].sort((a,b) =>
      parseInt(b.date?.uts||0) - parseInt(a.date?.uts||0)
    );
    const lastTs  = parseInt(sorted[0].date?.uts || 0);
    const payload = JSON.stringify({
      v: 2,
      savedAt: Date.now(),
      lastTs,
      tracks: sorted.map(_compactTrack),
    });
    localStorage.setItem(HIST_STORAGE_KEY + APP.username, payload);
    console.log(`[History] Cache saved: ${tracks.length} tracks, lastTs=${lastTs}`);
    return true;
  } catch (e) {
    // localStorage plein — on essaie de vider les vieux caches de l'API
    console.warn('[History] Save failed (storage full?), clearing API cache…', e);
    try {
      Cache._purge();
      localStorage.setItem(HIST_STORAGE_KEY + APP.username,
        JSON.stringify({ v:2, savedAt:Date.now(), lastTs:0, tracks:[] }));
    } catch {}
    return false;
  }
}

/** Charge l'historique depuis localStorage → { lastTs, tracks } | null */
function _loadHistoryCache() {
  if (!APP.username) return null;
  try {
    const raw = localStorage.getItem(HIST_STORAGE_KEY + APP.username);
    if (!raw) return null;
    const obj = JSON.parse(raw);
    if (obj.v !== 2 || !Array.isArray(obj.tracks)) return null;
    return {
      lastTs: obj.lastTs || 0,
      savedAt: obj.savedAt || 0,
      tracks: obj.tracks.map(_expandTrack),
    };
  } catch { return null; }
}

/** Supprime le cache historique (appelé par logout + clearCache) */
function _clearHistoryCache() {
  if (!APP.username) return;
  localStorage.removeItem(HIST_STORAGE_KEY + APP.username);
}

/* fetchFullHistory — charge l'historique avec mise à jour incrémentale */

async function fetchFullHistory(backgroundMode = false) {
  if (_bgFetchInProgress) return;
  _bgFetchInProgress = true;

  const btn      = document.getElementById('fetch-history-btn');
  const overlay  = document.getElementById('fetch-overlay');
  const fillEl   = document.getElementById('fetch-fill');
  const pctEl    = document.getElementById('fetch-pct');
  const tracksEl = document.getElementById('fetch-tracks');
  const subEl    = document.getElementById('fetch-sub');
  const msgEl    = document.getElementById('fetch-msg');
  const titleEl  = document.getElementById('fetch-title');
  const minBtn   = document.getElementById('fetch-minimize-btn');

  if (btn) { btn.disabled = true; btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${t('fetch_btn_loading')}`; }

  // Vérifier si un cache existe
  const cached    = _loadHistoryCache();
  const hasCache  = cached && cached.tracks.length > 0;
  const isIncremental = hasCache;

  // Affichage overlay
  const showOverlay = (mode) => {
    if (!overlay) return;
    if (mode === 'normal') {
      _historyFetchMinimized = false;
      overlay.classList.remove('hidden', 'fetch-overlay--minimized');
      document.body.classList.add('fetch-active');
      if (fillEl)   fillEl.style.width   = '0%';
      if (pctEl)    pctEl.textContent    = '0%';
      if (tracksEl) tracksEl.textContent = '0 ' + t('scrobbles');
      if (msgEl)    msgEl.textContent    = t('fetch_init');
      if (titleEl)  titleEl.textContent  = isIncremental
        ? `${t('fetch_title')} — Mise à jour`
        : t('fetch_title');
    } else {
      _historyFetchMinimized = true;
      overlay.classList.remove('hidden');
      overlay.classList.add('fetch-overlay--minimized');
      document.body.classList.add('fetch-active');
      _updatePillText(0);
    }
  };

  if (!backgroundMode) showOverlay('normal');
  else                  showOverlay('minimized');

  if (minBtn) minBtn.onclick = () => toggleFetchMinimize();

  const pillEl = overlay?.querySelector('.fetch-pill');
  if (pillEl) {
    pillEl.onclick = () => {
      _historyFetchMinimized = false;
      overlay.classList.remove('fetch-overlay--minimized');
    };
  }

  const onProgress = (page, totalPages, count, incremental = false) => {
    const pct = Math.round((page / Math.max(totalPages, 1)) * 100);
    if (fillEl)   fillEl.style.width   = pct + '%';
    if (pctEl)    pctEl.textContent    = pct + '%';
    if (tracksEl) {
      const base = incremental && hasCache ? cached.tracks.length : 0;
      tracksEl.textContent = formatNum(base + count) + ' ' + t('scrobbles');
    }
    if (subEl)  subEl.textContent  = incremental
      ? `+${formatNum(count)} nouveaux — Page ${page} / ${totalPages}`
      : t('fetch_page', page, totalPages);
    if (msgEl)  msgEl.textContent  = t('fetch_loading');
    _updatePillText(pct);
  };

  try {
    let tracks;

    if (isIncremental) {
      // Mode incrémental : charge uniquement les nouveaux scrobbles
      const ageDays = Math.round((Date.now() - cached.savedAt) / 86400000);
      console.log(`[History] Cache found: ${cached.tracks.length} tracks, age=${ageDays}d, lastTs=${cached.lastTs}`);

      if (subEl)  subEl.textContent  = `Cache: ${formatNum(cached.tracks.length)} scrobbles`;
      if (msgEl)  msgEl.textContent  = 'Récupération des nouveaux scrobbles…';
      if (titleEl) titleEl.textContent = `Mise à jour (${formatNum(cached.tracks.length)} en cache)`;

      // Le cache est disponible en mémoire immédiatement pour les autres sections
      // (historique, badges…) mais on ne rend les charts qu'une seule fois
      // à la fin pour éviter le "Canvas already in use" de Chart.js
      APP.fullHistory = cached.tracks;

      const newTracks = await API.fetchSince(cached.lastTs, onProgress);

      if (newTracks.length > 0) {
        // Merge : nouveaux + cache, triés par timestamp descendant
        const merged = [...newTracks, ...cached.tracks].sort(
          (a,b) => parseInt(b.date?.uts||0) - parseInt(a.date?.uts||0)
        );
        // Dédoublonnage sur (artist+name+uts)
        const seen = new Set();
        tracks = merged.filter(tr => {
          const key = `${tr.artist?.['#text']||''}::${tr.name||''}::${tr.date?.uts||''}`;
          if (seen.has(key)) return false;
          seen.add(key);
          return true;
        });
        console.log(`[History] Incremental: +${newTracks.length} new → ${tracks.length} total`);
        showToast(`+${formatNum(newTracks.length)} nouveaux scrobbles`);
      } else {
        // Aucun nouveau scrobble — cache déjà à jour
        tracks = cached.tracks;
        console.log('[History] Already up to date');
        showToast(t('fetch_auto_done'));
      }
    } else {
      // Chargement complet (premier chargement)
      tracks = await API.fetchAllPages(onProgress);
    }

    APP.fullHistory = tracks;
    _saveHistoryCache(tracks);
    _applyFullHistory(tracks, true);

    if (btn) { btn.disabled = false; btn.innerHTML = `<i class="fas fa-check"></i> ${t('fetch_btn_done')}`; }
    return tracks;

  } catch (e) {
    showToast(t('fetch_error', e.message), 'error');
    if (btn) { btn.disabled = false; btn.innerHTML = `<i class="fas fa-history"></i> ${t('fetch_btn_refresh')}`; }
  } finally {
    _bgFetchInProgress = false;
    if (!backgroundMode) {
      overlay?.classList.add('hidden');
      document.body.classList.remove('fetch-active');
    }
  }
}

/**
 * Applique un historique chargé à toute l'UI (charts, streaks, badges, calendrier…).
 * @param {Array}   tracks
 * @param {boolean} showDoneToast — affiche le toast "terminé" si true
 */
// Guard pour éviter deux appels _applyFullHistory simultanés
let _applyHistoryPending = false;

/**
 * Applique un historique chargé à toute l'UI (charts, streaks, badges, calendrier…).
 * @param {Array}   tracks
 * @param {boolean} showDoneToast — masque l'overlay et affiche le toast "terminé" si true
 */
function _applyFullHistory(tracks, showDoneToast) {
  // Si un render précédent tourne encore, on détruit les charts concernés proprement
  if (_applyHistoryPending) {
    destroyChart('chart-hourly');
    destroyChart('chart-weekday');
  }
  _applyHistoryPending = true;
  const hourCounts = Array(24).fill(0);
  for (const tr of tracks) {
    const ts = parseInt(tr.date?.uts || 0);
    if (ts) hourCounts[new Date(ts * 1000).getHours()]++;
  }
  renderHeatmap(hourCounts);
  _renderHourlyChart(hourCounts);

  APP.streakData = calcStreak(tracks);
  updateStreakUI(APP.streakData);

  const uniqueArtistsEl = document.getElementById('adv-unique');
  if (uniqueArtistsEl) {
    const unique = new Set(
      tracks.map(tr => (tr.artist?.['#text'] || tr.artist?.name || '').toLowerCase())
    ).size;
    uniqueArtistsEl.textContent = formatNum(unique);
  }

  _renderDayOfWeekChart(tracks);
  _renderOHWList(tracks);

  // Calendrier d'Écoute — dashboard + charts
  _buildCalHeatmapYearSel('');
  _buildCalHeatmapYearSel('charts');
  renderListeningHeatmap(new Date().getFullYear(), '');
  renderListeningHeatmap(new Date().getFullYear(), 'charts');

  // Effacer les hints "load history"
  const hourlyHint  = document.getElementById('hourly-hint');
  const weekdayHint = document.getElementById('weekday-hint');
  if (hourlyHint)  hourlyHint.textContent  = '';
  if (weekdayHint) weekdayHint.textContent = '';
  document.getElementById('ohw-empty')?.style?.setProperty?.('display', 'none');

  if (showDoneToast) {
    const overlay = document.getElementById('fetch-overlay');
    overlay?.classList.add('hidden');
    document.body.classList.remove('fetch-active');
  }

  _applyHistoryPending = false;
}


function toggleFetchMinimize() {
  const overlay = document.getElementById('fetch-overlay');
  if (!overlay) return;
  _historyFetchMinimized = !_historyFetchMinimized;
  overlay.classList.toggle('fetch-overlay--minimized', _historyFetchMinimized);
  const minBtn = document.getElementById('fetch-minimize-btn');
  if (minBtn) {
    const ico = minBtn.querySelector('i');
    if (ico) ico.className = _historyFetchMinimized ? 'fas fa-expand-alt' : 'fas fa-minus';
    minBtn.title = _historyFetchMinimized ? t('fetch_expand') : t('fetch_minimize');
  }
}

function _updatePillText(pct) {
  const overlay  = document.getElementById('fetch-overlay');
  const pillTxt  = overlay?.querySelector('.fetch-pill-text');
  const pillPct  = overlay?.querySelector('.fetch-pill-pct');
  const pillFill = overlay?.querySelector('.fetch-pill-bar-fill');
  if (pillTxt)  pillTxt.textContent  = t('fetch_bg_progress', pct);
  if (pillPct)  pillPct.textContent  = pct + '%';
  if (pillFill) pillFill.style.width = pct + '%';
}

function _renderDayOfWeekChart(tracks) {
  const dayCounts = Array(7).fill(0);
  for (const tr of tracks) {
    const ts = parseInt(tr.date?.uts || 0);
    if (ts) dayCounts[(new Date(ts * 1000).getDay() + 6) % 7]++;
  }
  destroyChart('chart-weekday');
  const c = getThemeColors();
  const canvasEl = document.getElementById('chart-weekday');
  if (!canvasEl) return;
  APP.charts['chart-weekday'] = new Chart(canvasEl, {
    type: 'bar',
    data: { labels: DAYS(), datasets: [{ data: dayCounts, backgroundColor: CHART_PALETTE.map(p => p + 'aa'), borderColor: CHART_PALETTE, borderWidth: 1, borderRadius: 6 }] },
    options: { ...baseChartOpts(), plugins: { ...baseChartOpts().plugins, tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } } }, scales: { x: { grid: { display: false }, ticks: { color: c.text } }, y: { grid: { color: c.grid }, ticks: { color: c.text } } } },
  });
}

function _renderHourlyChart(hourCounts) {
  destroyChart('chart-hourly');
  const c = getThemeColors();
  const labels = Array.from({ length: 24 }, (_, i) => i + 'h');
  const canvasEl = document.getElementById('chart-hourly');
  if (!canvasEl) return;
  APP.charts['chart-hourly'] = new Chart(canvasEl, {
    type: 'bar',
    data: { labels, datasets: [{ data: hourCounts, backgroundColor: CHART_PALETTE.map(p => p + 'aa'), borderColor: CHART_PALETTE, borderWidth: 1, borderRadius: 4 }] },
    options: { ...baseChartOpts(), plugins: { ...baseChartOpts().plugins, tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } } }, scales: { x: { grid: { display: false }, ticks: { color: c.text } }, y: { grid: { color: c.grid }, ticks: { color: c.text } } } },
  });
}

/* Calendrier d'Écoute — heatmap annuelle (inspiré GitHub) */

/** Construit le <select> des années disponibles dans le calendrier */
function _buildCalHeatmapYearSel(suffix = '') {
  const id  = suffix ? `cal-heatmap-yr-sel-${suffix}` : 'cal-heatmap-yr-sel';
  const sel = document.getElementById(id);
  if (!sel) return;
  // Always rebuild for 'charts' suffix to ensure it's in sync; skip rebuild only for dashboard if already done
  if (suffix === '' && sel.options.length > 0) return;
  sel.innerHTML = '';
  const currentYear = new Date().getFullYear();
  for (let y = currentYear; y >= APP.regYear; y--) {
    const opt      = document.createElement('option');
    opt.value      = y;
    opt.textContent= y;
    if (y === currentYear) opt.selected = true;
    sel.appendChild(opt);
  }
}

/**
 * Construit et affiche la heatmap calendrier GitHub-style.
 * @param {number} [year]   — année à afficher (défaut : année courante)
 * @param {string} [suffix] — '' pour dashboard, 'charts' pour la section Charts
 */
function renderListeningHeatmap(year, suffix = '') {
  const sfx     = suffix ? `-${suffix}` : '';
  const history = APP.fullHistory;
  const emptyEl = document.getElementById(`listening-heatmap-empty${sfx}`);
  const wrapEl  = document.getElementById(`listening-heatmap-wrap${sfx}`);
  if (!wrapEl) return;

  if (!history?.length) {
    emptyEl?.classList.remove('hidden');
    wrapEl.classList.add('hidden');
    return;
  }

  emptyEl?.classList.add('hidden');
  wrapEl.classList.remove('hidden');

  _buildCalHeatmapYearSel(suffix);

  const targetYear = year || new Date().getFullYear();
  const selId = suffix ? `cal-heatmap-yr-sel-${suffix}` : 'cal-heatmap-yr-sel';
  const sel   = document.getElementById(selId);
  if (sel) sel.value = targetYear;

  // Agrégation des scrobbles par jour
  const dayCounts = new Map();
  for (const tr of history) {
    const ts = parseInt(tr.date?.uts || 0);
    if (!ts) continue;
    const d = new Date(ts * 1000);
    if (d.getFullYear() !== targetYear) continue;
    const key = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    dayCounts.set(key, (dayCounts.get(key) || 0) + 1);
  }

  // Seuils des 4 niveaux d'intensité
  const vals       = dayCounts.size ? [...dayCounts.values()] : [1];
  const maxCount   = Math.max(...vals);
  const thresholds = [1, Math.ceil(maxCount * 0.25), Math.ceil(maxCount * 0.5), Math.ceil(maxCount * 0.75)];

  const getLevel = (count) => {
    if (!count)                  return 0;
    if (count < thresholds[1])   return 1;
    if (count < thresholds[2])   return 2;
    if (count < thresholds[3])   return 3;
    return 4;
  };

  // Construction des cellules (lun=0 … dim=6)
  const jan1     = new Date(targetYear, 0, 1);
  const startPad = (jan1.getDay() + 6) % 7;
  const isLeap   = (targetYear % 4 === 0 && targetYear % 100 !== 0) || targetYear % 400 === 0;
  const totalDays = isLeap ? 366 : 365;

  const allCells = [];
  for (let i = 0; i < startPad; i++) allCells.push(null);
  for (let d = 0; d < totalDays; d++) {
    const date = new Date(targetYear, 0, d + 1);
    const key  = `${targetYear}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`;
    allCells.push({ date, key, count: dayCounts.get(key) || 0 });
  }
  while (allCells.length % 7 !== 0) allCells.push(null);
  const numWeeks = allCells.length / 7;

  // Responsive cell size based on available container width
  const containerW  = wrapEl.parentElement?.clientWidth || 600;
  const isMobile    = containerW < 480;
  const CELL_W      = isMobile ? 9 : 11;
  const CELL_GAP    = 2;
  const COL_W       = CELL_W + CELL_GAP;
  const WD_W        = isMobile ? 18 : 22;
  const BODY_GAP    = 4;

  const MONTHS_FR = MONTHS_SHORT();
  const monthPositions = [];
  let lastMonth = -1;
  for (let w = 0; w < numWeeks; w++) {
    const cell = allCells.slice(w * 7, w * 7 + 7).find(c => c !== null);
    if (cell && cell.date.getMonth() !== lastMonth) {
      monthPositions.push({ week: w, label: MONTHS_FR[cell.date.getMonth()] });
      lastMonth = cell.date.getMonth();
    }
  }

  const wdLabels = DAYS?.() || ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
  const wdHTML   = wdLabels.map((wd, i) =>
    `<span class="cal-wd-lbl">${[0,2,4].includes(i) ? wd : ''}</span>`
  ).join('');

  const monthRowW = numWeeks * COL_W - CELL_GAP;
  const monthHTML = monthPositions.map(({ week, label }) =>
    `<span class="cal-month-label" style="left:${week * COL_W}px">${label}</span>`
  ).join('');

  const weeksHTML = Array(numWeeks).fill(0).map((_, wi) => {
    const days = allCells.slice(wi * 7, wi * 7 + 7).map(cell => {
      if (!cell) return `<div class="cal-day-cell cal-day-empty" style="width:${CELL_W}px;height:${CELL_W}px"></div>`;
      const lv  = getLevel(cell.count);
      const fmt = cell.date.toLocaleDateString(undefined, { weekday:'short', month:'short', day:'numeric' });
      const tip = cell.count > 0
        ? `${fmt} — ${formatNum(cell.count)} ${t('scrobbles')}`
        : fmt;
      return `<div class="cal-day-cell" data-level="${lv}" title="${tip}" style="width:${CELL_W}px;height:${CELL_W}px"></div>`;
    }).join('');
    return `<div class="cal-week-col">${days}</div>`;
  }).join('');

  // Quick stats
  const totalYearScrobbles = [...dayCounts.values()].reduce((a,b) => a+b, 0);
  const activeDays         = dayCounts.size;
  const bestDay            = [...dayCounts.entries()].sort((a,b) => b[1]-a[1])[0];
  const bestDayStr         = bestDay
    ? new Date(bestDay[0]).toLocaleDateString(undefined, { month:'short', day:'numeric' })
      + ` (${formatNum(bestDay[1])})`
    : '—';

  const legendCells = [0,1,2,3,4].map(lv =>
    `<div class="cal-day-cell" data-level="${lv}" style="width:${CELL_W}px;height:${CELL_W}px"></div>`
  ).join('');

  wrapEl.innerHTML = `
    <div class="cal-heatmap-inner">
      <div class="cal-month-row" style="margin-left:${WD_W + BODY_GAP}px;width:${monthRowW}px;min-width:${monthRowW}px">
        ${monthHTML}
      </div>
      <div class="cal-body">
        <div class="cal-weekday-labels" style="width:${WD_W}px">${wdHTML}</div>
        <div class="cal-heatmap-grid">${weeksHTML}</div>
      </div>
      <div class="cal-heatmap-stats">
        <div class="cal-heatmap-stat">
          <i class="fas fa-headphones"></i>
          <span><strong>${formatNum(totalYearScrobbles)}</strong> ${t('scrobbles')} ${targetYear}</span>
        </div>
        <div class="cal-heatmap-stat">
          <i class="fas fa-calendar-check"></i>
          <span><strong>${activeDays}</strong> ${t('cal_active_days')}</span>
        </div>
        <div class="cal-heatmap-stat">
          <i class="fas fa-bolt"></i>
          <span>${t('cal_record')}&nbsp;: <strong>${bestDayStr}</strong></span>
        </div>
      </div>
      <div class="cal-heatmap-legend">
        <span>${t('cal_legend_less')}</span>
        <div class="cal-legend-cells">${legendCells}</div>
        <span>${t('cal_legend_more')}</span>
      </div>
    </div>`;
}

function _renderOHWList(tracks) {
  const playcountByArtist = {};
  for (const tr of tracks) {
    const name = tr.artist?.['#text'] || tr.artist?.name || '';
    if (!name) continue;
    playcountByArtist[name] = (playcountByArtist[name] || 0) + 1;
  }
  const ohwList = document.getElementById('ohw-list');
  if (!ohwList) return;
  const items = Object.entries(playcountByArtist)
    .filter(([, p]) => p >= 1 && p <= 3)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 20);
  if (!items.length) {
    ohwList.innerHTML = `<p style="color:var(--text-muted);padding:10px 0;font-size:.85rem">${t('adv_ohw_none') || 'No one-hit wonders found.'}</p>`;
    return;
  }
  ohwList.innerHTML = items.map(([name, plays], i) => `
    <div class="ohw-item">
      <span class="ohw-num">${i + 1}</span>
      <span class="ohw-name" title="${name}">${name}</span>
      <span class="ohw-plays">${plays} ${t('plays')}</span>
    </div>`).join('');
}

// Smart refresh
async function refreshData() {
  const refreshBtn = document.getElementById('refresh-btn');
  const icon       = refreshBtn?.querySelector('i');
  if (icon) icon.classList.add('fa-spin');

  try {
    const info = await API.call('user.getInfo', {}, true);
    APP.userInfo = info.user;

    await loadDashboard();
    loadVersus();
    loadMoodTags();

    const activeSection = document.querySelector('.app-sec.active')?.id?.replace('s-', '');
    if (activeSection === 'top-artists') await loadTopArtists(APP.artistsPeriod || 'overall');
    if (activeSection === 'top-albums')  await loadTopAlbums(APP.albumsPeriod   || 'overall');
    if (activeSection === 'top-tracks')  await loadTopTracks(APP.tracksPeriod   || 'overall');
    if (activeSection === 'charts'){ setupChartsSection(); }
    if (activeSection === 'obscurity')   loadObscurityScore();

    showToast(t('toast_data_updated'));
  } catch (e) { showToast(e.message, 'error'); }
  finally { if (icon) icon.classList.remove('fa-spin'); }

  _scheduleBackgroundHistoryFetch();
}

// Logout
function logout() {
  _clearHistoryCache();
  Cache.clear();
  clearSession();
  localStorage.removeItem('ls_section');
  APP.username    = '';
  APP.apiKey      = '';
  APP.userInfo    = null;
  APP.fullHistory = null;
  APP.streakData  = null;
  Object.values(APP.charts).forEach(c => c?.destroy());
  APP.charts = {};
  clearTimeout(_npTimer);
  clearTimeout(_bgHistoryTimer);

  document.getElementById('app')?.classList.add('hidden');
  document.getElementById('setup-screen')?.classList.remove('hidden');
  if (document.getElementById('input-username')) document.getElementById('input-username').value = '';
  if (document.getElementById('input-apikey'))   document.getElementById('input-apikey').value   = '';
}

async function openArtistModal(artistName, artistUrl, userPlaycount) {
  const modal = document.getElementById('artist-modal');
  if (!modal) return;
  modal.classList.remove('hidden');
  document.body.style.overflow = 'hidden';

  const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };

    setText('am-name', artistName);
  setText('am-user-plays', formatNum(userPlaycount) + ' ' + t('plays'));
  setText('am-listeners',   '—');
  setText('am-globalplays', '—');

  // bio: show spinner, hide text
  const bioLoadEl   = document.getElementById('am-bio-loading');
  const bioTextEl   = document.getElementById('am-bio-text');
  const bioToggleEl = document.getElementById('am-bio-toggle');
  if (bioLoadEl)   { bioLoadEl.classList.remove('hidden'); }
  if (bioTextEl)   { bioTextEl.classList.add('hidden'); bioTextEl.textContent = ''; }
  if (bioToggleEl) { bioToggleEl.classList.add('hidden'); }

  // tracks: show spinner, hide list
  const trkLoadEl  = document.getElementById('am-tracks-loading');
  const trkListEl  = document.getElementById('am-top-tracks-list');
  if (trkLoadEl) trkLoadEl.classList.remove('hidden');
  if (trkListEl) { trkListEl.classList.add('hidden'); trkListEl.innerHTML = ''; }

  // albums: show spinner, hide grid
  const albLoadEl  = document.getElementById('am-albums-loading');
  const albGridEl  = document.getElementById('am-albums-grid');
  if (albLoadEl) albLoadEl.classList.remove('hidden');
  if (albGridEl) { albGridEl.classList.add('hidden'); albGridEl.innerHTML = ''; }

  // reset tags
  const tagsEl = document.getElementById('am-tags');
  if (tagsEl) tagsEl.innerHTML = '';

    const imgEl     = document.getElementById('am-img-inner');
  const artistImg = await getArtistImage(artistName);
  if (imgEl) {
    imgEl.innerHTML = artistImg
      ? `<img src="${artistImg}" alt="${escHtml(artistName)}"
             style="width:100%;height:100%;object-fit:cover;object-position:center 20%"
             onerror="this.parentElement.innerHTML='<div style=\\'width:100%;height:100%;background:${nameToGradient(artistName)};display:flex;align-items:center;justify-content:center;font-size:3rem;font-weight:800;color:white\\'>${escHtml(artistName[0].toUpperCase())}</div>'">`
      : `<div style="width:100%;height:100%;background:${nameToGradient(artistName)};display:flex;align-items:center;justify-content:center;font-size:3rem;font-weight:800;color:white">${escHtml(artistName[0].toUpperCase())}</div>`;
  }

    const lfmBtn = document.getElementById('am-lfm-link');
  const spBtn  = document.getElementById('am-sp-link');
  const ytBtn  = document.getElementById('am-yt-link');
  if (lfmBtn) lfmBtn.href = artistUrl || `https://www.last.fm/music/${encodeURIComponent(artistName)}`;
  if (spBtn)  spBtn.href  = `spotify:search:${encodeURIComponent(artistName)}`;
  if (ytBtn)  ytBtn.href  = `https://www.youtube.com/results?search_query=${encodeURIComponent(artistName)}`;

  try {
    const [infoData, trkData, albData] = await Promise.all([
      API.call('artist.getInfo',      { artist:artistName, autocorrect:1 }),
      API.call('artist.getTopTracks', { artist:artistName, autocorrect:1, limit:5 }),
      API.call('artist.getTopAlbums', { artist:artistName, autocorrect:1, limit:6 }),
    ]);

    const info = infoData.artist;
    setText('am-listeners',   formatNum(info?.stats?.listeners || 0));
    setText('am-globalplays', formatNum(info?.stats?.playcount  || 0));

        const bioRaw   = info?.bio?.summary || '';
    const bioClean = bioRaw.replace(/<a[^>]*>.*?<\/a>/gi, '').replace(/<[^>]+>/g, '').trim();
    if (bioLoadEl) bioLoadEl.classList.add('hidden');
    if (bioTextEl) {
      bioTextEl.classList.remove('hidden', 'am-bio--collapsed');
      if (bioClean.length > 300) {
        bioTextEl.textContent = bioClean.slice(0, 300) + '…';
        bioTextEl.classList.add('am-bio--collapsed');
        if (bioToggleEl) {
          bioToggleEl.classList.remove('hidden');
          bioToggleEl.querySelector('span').textContent = t('bio_read_more');
          bioToggleEl.onclick = () => {
            const collapsed = bioTextEl.classList.toggle('am-bio--collapsed');
            bioTextEl.textContent = collapsed ? bioClean.slice(0, 300) + '…' : bioClean;
            bioToggleEl.querySelector('span').textContent = collapsed ? t('bio_read_more') : t('bio_collapse');
          };
        }
      } else {
        bioTextEl.textContent = bioClean || t('bio_none');
      }
    }

        if (tagsEl) {
      const tags = (info?.tags?.tag || [])
        .filter(tg => { const n = tg.name?.toLowerCase().trim(); return n && n.length >= 2 && !_IGNORED_TAGS.has(n); })
        .slice(0, 5);
      tagsEl.innerHTML = tags.map(tg => `<span class="am-tag">${escHtml(tg.name)}</span>`).join('');
    }

        if (trkLoadEl) trkLoadEl.classList.add('hidden');
    const tracks = trkData.toptracks?.track || [];
    if (trkListEl) {
      trkListEl.classList.remove('hidden');
      if (tracks.length) {
        const maxPlay = parseInt(tracks[0].playcount || 1);
        trkListEl.innerHTML = tracks.map((tr, i) => `
          <div class="track-item compact" style="animation-delay:${i*0.04}s"
               onclick="window.open('${(tr.url||'#').replace(/'/g,'%27')}','_blank')">
            <div class="track-rank">${i+1}</div>
            <div class="track-info"><div class="track-name">${escHtml(tr.name)}</div></div>
            <div class="track-bar-wrap"><div class="track-bar" style="width:${((parseInt(tr.playcount)/maxPlay)*100).toFixed(0)}%"></div></div>
            <div class="track-plays">${formatNum(tr.playcount)}</div>
          </div>`).join('');
      } else {
        trkListEl.innerHTML = `<p style="color:var(--text-muted);padding:10px">${t('tracks_none')}</p>`;
      }
    }

        if (albLoadEl) albLoadEl.classList.add('hidden');
    const albums = albData.topalbums?.album || [];
    if (albGridEl) {
      albGridEl.classList.remove('hidden');
      albGridEl.innerHTML = albums.map(alb => {
        const aImg = alb.image?.find(i => i.size === 'extralarge')?.['#text'] || '';
        const hasA = !isDefaultImg(aImg);
        const albName = alb.name || '?';
        return `<div class="music-card mini" onclick="window.open('${(alb.url||'#').replace(/'/g,'%27')}','_blank')">
          <div class="music-card-img" style="height:100px;aspect-ratio:1">
            ${hasA ? `<img src="${aImg}" alt="${escHtml(albName)}" loading="lazy" style="width:100%;height:100%;object-fit:cover" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
            <div class="spotify-cover" style="background:${nameToGradient(albName)};display:${hasA?'none':'flex'}">
              <span class="sc-letter">${escHtml(albName[0].toUpperCase())}</span>
            </div>
          </div>
          <div class="music-card-body">
            <div class="music-card-name" title="${escHtml(albName)}">${escHtml(albName)}</div>
          </div>
        </div>`;
      }).join('');
    }

  } catch (e) {
    console.warn('openArtistModal:', e);
    if (bioLoadEl) bioLoadEl.classList.add('hidden');
    if (trkLoadEl) trkLoadEl.classList.add('hidden');
    if (albLoadEl) albLoadEl.classList.add('hidden');
    if (bioTextEl) { bioTextEl.classList.remove('hidden'); bioTextEl.textContent = t('bio_unavailable'); }
  }
}

function closeArtistModal(e) {
  if (e && e.target !== document.getElementById('artist-modal')) return;
  document.getElementById('artist-modal')?.classList.add('hidden');
  document.body.style.overflow = '';
}

async function _shareOrCopy(title, text, url) {
  if (navigator.share) {
    try { await navigator.share({ title, text, url }); return; } catch {}
  }
  try { await navigator.clipboard.writeText(`${text}\n${url}`); showToast(t('toast_link_copied')); }
  catch { prompt(t('toast_link_copied') + ':', url); }
}

function shareArtist(name, plays, url) {
  const text = t('share_artist_text', name, formatNum(plays));
  _shareOrCopy(name, text, url || `https://www.last.fm/music/${encodeURIComponent(name)}`);
}

function shareAlbum(name, artist, plays, url) {
  const text = t('share_album_text', name, artist, formatNum(plays));
  _shareOrCopy(`${name} — ${artist}`, text, url || '#');
}

function shareTrack(name, artist, plays, url) {
  const text = t('share_album_text', name, artist, formatNum(plays));
  _shareOrCopy(`${name} — ${artist}`, text, url || `https://www.last.fm/music/${encodeURIComponent(artist)}/_/${encodeURIComponent(name)}`);
}


async function loadMusicalProfile() {
  const phEl   = document.getElementById('profile-placeholder');
  const wrapEl = document.getElementById('profile-chart-wrap');
  const legEl  = document.getElementById('profile-tag-legend');
  const statusHint = document.getElementById('profile-status-hint');

  if (phEl)  phEl.classList.remove('hidden');

  const TOP_TAGS_COUNT = 5;
  const MONTHS_BACK    = 6;
  const IGNORED_TAGS   = new Set(['seen live','favorites','favourite','love','awesome','beautiful','epic','amazing','classic','my favourite','all','good','new','old','best','cool','hot','great']);

  try {
    const now = new Date();
    const labels  = [];
    const tagData = {};

    // get weekly chart list for historical data access
    let weeklyChartList = null;
    try {
      const wclData    = await API.call('user.getWeeklyChartList', {});
      weeklyChartList  = wclData.weeklychartlist?.chart || [];
    } catch { weeklyChartList = []; }

    for (let mBack = MONTHS_BACK - 1; mBack >= 0; mBack--) {
      const targetDate  = new Date(now.getFullYear(), now.getMonth() - mBack, 1);
      const monthStart  = Math.floor(new Date(targetDate.getFullYear(), targetDate.getMonth(), 1).getTime() / 1000);
      const monthEnd    = Math.floor(new Date(targetDate.getFullYear(), targetDate.getMonth() + 1, 0, 23, 59, 59).getTime() / 1000);
      const monthIdx    = MONTHS_BACK - 1 - mBack; // index in array (0 = oldest)

      labels.push(MONTHS_SHORT()[targetDate.getMonth()] + ' ' + targetDate.getFullYear().toString().slice(-2));

      // aggregate weekly charts covering this month
      let monthArtists = [];

      if (weeklyChartList.length) {
        // find weeks overlapping this month
        const relevantWeeks = weeklyChartList.filter(w => {
          const wFrom = parseInt(w.from);
          const wTo   = parseInt(w.to);
          return wFrom <= monthEnd && wTo >= monthStart;
        });

        if (relevantWeeks.length) {
          const artistPlays = new Map();
          const weekResults = await Promise.allSettled(
            relevantWeeks.map(w => API.call('user.getWeeklyArtistChart', { from:w.from, to:w.to }))
          );

          weekResults.forEach(res => {
            if (res.status !== 'fulfilled') return;
            const artists = res.value.weeklyartistchart?.artist || [];
            artists.forEach(a => {
              const name   = a.name?.trim();
              const plays  = parseInt(a.playcount || 0);
              if (name) artistPlays.set(name, (artistPlays.get(name) || 0) + plays);
            });
          });

          monthArtists = [...artistPlays.entries()]
            .sort((a,b) => b[1]-a[1])
            .slice(0, 8)
            .map(([name, playcount]) => ({ name, playcount }));
        }
      }

      // fallback: use user.getTopArtists with the appropriate rolling period
      if (!monthArtists.length) {
        const period = mBack <= 1 ? '1month' : mBack <= 3 ? '3month' : '6month';
        try {
          const d2 = await API.call('user.getTopArtists', { period, limit:8 }, mBack === 0);
          monthArtists = d2.topartists?.artist || [];
        } catch { monthArtists = APP.topArtistsData.slice(0, 8); }
      }

      if (!monthArtists.length) {
        monthArtists = APP.topArtistsData.slice(0, 8);
      }

      // fetch tags for these artists
      const tagResults = await Promise.allSettled(
        monthArtists.map(a => API.call('artist.getTopTags', { artist:a.name }))
      );

      const monthScores = new Map();
      tagResults.forEach((res, i) => {
        if (res.status !== 'fulfilled') return;
        const tags   = res.value.toptags?.tag || [];
        const weight = monthArtists.length - i;
        tags.slice(0, 6).forEach(tag => {
          const name = (tag.name || '').toLowerCase().trim();
          if (!name || name.length < 2 || IGNORED_TAGS.has(name)) return;
          monthScores.set(name, (monthScores.get(name) || 0) + (parseInt(tag.count) || 30) * weight);
        });
      });

      monthScores.forEach((score, tag) => {
        if (!tagData[tag]) tagData[tag] = Array(MONTHS_BACK).fill(0);
        tagData[tag][monthIdx] = score;
      });

      await sleep(80);
    }

    // pick the top 5 tags across the whole period
    const tagTotals = Object.entries(tagData)
      .map(([tag, scores]) => ({ tag, total:scores.reduce((a,b) => a+b, 0) }))
      .sort((a,b) => b.total - a.total)
      .slice(0, TOP_TAGS_COUNT);

    if (!tagTotals.length) {
      if (phEl) { phEl.classList.remove('hidden'); phEl.querySelector('p').textContent = t('unavailable'); }
      if (statusHint) statusHint.innerHTML = '';
      return;
    }

        if (phEl)  phEl.classList.add('hidden');
    if (wrapEl) { wrapEl.classList.remove('hidden'); wrapEl.style.display = ''; }

        if (legEl) {
      legEl.classList.remove('hidden');
      legEl.style.display = '';
      legEl.innerHTML = tagTotals.map((item, i) => `
        <div class="profile-leg-item">
          <span class="profile-leg-dot" style="background:${CHART_PALETTE[i % CHART_PALETTE.length]}"></span>
          <span>${escHtml(item.tag.charAt(0).toUpperCase() + item.tag.slice(1))}</span>
        </div>`).join('');
    }

    destroyChart('chart-profile');
    const c = getThemeColors();
    APP.charts['chart-profile'] = new Chart(document.getElementById('chart-profile'), {
      type:'line',
      data:{
        labels,
        datasets: tagTotals.map((item, i) => ({
          label:            item.tag.charAt(0).toUpperCase() + item.tag.slice(1),
          data:             tagData[item.tag],
          borderColor:      CHART_PALETTE[i % CHART_PALETTE.length],
          backgroundColor:  CHART_PALETTE[i % CHART_PALETTE.length] + '22',
          tension:          0.4, borderWidth:2, fill:false,
          pointRadius:      4, pointHoverRadius:7,
        })),
      },
      options:{
        ...baseChartOpts(),
        plugins:{
          ...baseChartOpts().plugins,
          // legend is visible to identify each tag
          legend:{
            display:  true,
            position: 'bottom',
            labels:{  color:c.text, font:{ size:11 }, padding:12, boxWidth:12 },
          },
        },
        scales:{
          x:{ grid:{ display:false }, ticks:{ color:c.text } },
          y:{ grid:{ color:c.grid  }, ticks:{ color:c.text }, beginAtZero:true },
        },
      },
    });

    if (statusHint) statusHint.innerHTML = '<i class="fas fa-check" style="font-size:.75rem;margin-right:3px;color:#4ade80"></i>';

  } catch (e) {
    console.error('loadMusicalProfile:', e);
    if (phEl) phEl.classList.remove('hidden');
    if (statusHint) statusHint.innerHTML = '';
  }
}

let _obscurityScored = [];

async function loadObscurityScore() {
  const gaugeArc  = document.getElementById('oh-gauge-arc');
  const scoreVal  = document.getElementById('oh-score-val');
  const labelEl   = document.getElementById('oh-label');
  const spFill    = document.getElementById('oh-sp-fill');
  const emptyEl   = document.getElementById('obscurity-empty');
  const listEl    = document.getElementById('obscurity-list');
  const itemsEl   = document.getElementById('obscurity-items');
  const loadBtn   = document.getElementById('obscurity-load-btn');

  if (loadBtn) { loadBtn.disabled = true; loadBtn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> <span>${t('obs_loading')}</span>`; }

  try {
    let artists = APP.topArtistsData;
    if (!artists.length) {
      const d = await API.call('user.getTopArtists', { period:'overall', limit:30 });
      artists = d.topartists?.artist || [];
    }
    const top30 = artists.slice(0, 30);

    const infoResults = await Promise.allSettled(
      top30.map(a => API.call('artist.getInfo', { artist:a.name, autocorrect:1 }))
    );

    let totalListeners = 0, count = 0;
    const scored = [];

    infoResults.forEach((res, i) => {
      if (res.status !== 'fulfilled') return;
      const listeners = parseInt(res.value.artist?.stats?.listeners || 0);
      const a = top30[i];
      totalListeners += listeners;
      count++;
      scored.push({ name:a.name, listeners, plays:parseInt(a.playcount || 0) });
    });

    if (!count) return;

    _obscurityScored = scored;

    const avgListeners = totalListeners / count;
    const score = Math.max(0, Math.min(100, Math.round(100 - Math.log10(Math.max(1, avgListeners)) * 14)));

    const label = score >= 80 ? t('obs_hunter')
                : score >= 60 ? t('obs_gems')
                : score >= 40 ? t('obs_eclectique')
                : score >= 20 ? t('obs_mainstream')
                : t('obs_very_popular');

    if (scoreVal) animateValue(scoreVal, 0, score, 1200);
    if (labelEl)  labelEl.textContent = label;

    if (gaugeArc) {
      const arcLen = 251.2;
      setTimeout(() => { gaugeArc.style.strokeDashoffset = String(arcLen - (arcLen * score / 100)); }, 150);
    }
    if (spFill) setTimeout(() => { spFill.style.left = score + '%'; }, 200);

    _renderObscurityItems(itemsEl, scored, 'ratio');

    if (emptyEl) emptyEl.classList.add('hidden');
    if (listEl)  listEl.classList.remove('hidden');

    document.querySelectorAll('.obs-filter').forEach(b => b.classList.toggle('active', b.dataset.sort === 'ratio'));

  } catch (e) {
    showToast(t('obs_error', e.message), 'error');
  } finally {
    if (loadBtn) { loadBtn.disabled = false; loadBtn.innerHTML = `<i class="fas fa-search"></i> <span>${t('obs_recalc')}</span>`; }
  }
}

/** Render obscurity items — lazy images + i18n labels */
function _renderObscurityItems(container, scored, sortKey) {
  if (!container || !scored.length) return;
  const sorted = [...scored].sort((a, b) =>
    sortKey === 'plays' ? b.plays - a.plays : a.listeners - b.listeners
  );

  container.innerHTML = sorted.map((a, idx) => {
    const ratioScore = Math.max(0, Math.min(100, Math.round(100 - Math.log10(Math.max(1, a.listeners)) * 14)));
    const isPopular  = a.listeners > 1_000_000;
    const isIndie    = a.listeners > 300_000;
    const type       = isPopular ? t('obs_type_popular') : isIndie ? t('obs_type_indie') : t('obs_type_gems');
    const typeCls    = isPopular ? 'obs-type-populaire' : isIndie ? 'obs-type-indie' : 'obs-type-obscur';
    const listenersStr = a.listeners >= 1_000_000
      ? (a.listeners / 1_000_000).toFixed(1) + 'M'
      : a.listeners >= 1_000 ? Math.round(a.listeners / 1_000) + 'K'
      : String(a.listeners);
    const grad  = nameToGradient(a.name);
    const artId = `obs-art-${idx}`;
    const letter = escHtml(a.name.charAt(0).toUpperCase());

    return `<div class="obscurity-item">
      <span class="obs-rank">${idx + 1}</span>
      <div class="obs-art-img" id="${artId}" style="background:${grad};position:relative;overflow:hidden">
        <span class="obs-art-letter" style="position:relative;z-index:1">${letter}</span>
      </div>
      <div class="obs-info">
        <div class="obs-name">${escHtml(a.name)}</div>
        <div class="obs-plays">${listenersStr} ${t('listeners_label')} · ${formatNum(a.plays)} ${t('plays')}</div>
      </div>
      <div class="obs-bar-wrap"><div class="obs-bar" style="width:${ratioScore}%"></div></div>
      <div class="obs-score-wrap">
        <div class="obs-score">${ratioScore}</div>
        <div class="obs-score-lbl">/100</div>
      </div>
      <span class="obs-type-badge ${typeCls}">${type}</span>
    </div>`;
  }).join('');

  // lazy-load images — capped delay
  sorted.forEach((a, idx) => {
    const delay = Math.min(idx, 15) * 60;
    setTimeout(() => {
      getArtistImage(a.name).then(imgUrl => {
        const artEl = document.getElementById(`obs-art-${idx}`);
        if (!artEl || !imgUrl) return;
        const imgNode = document.createElement('img');
        imgNode.src   = imgUrl;
        imgNode.alt   = escHtml(a.name);
        imgNode.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;object-fit:cover;border-radius:inherit;z-index:2';
        imgNode.onerror = () => imgNode.remove();
        artEl.appendChild(imgNode);
      });
    }, delay);
  });
}

function sortObscurity(sortKey) {
  const itemsEl = document.getElementById('obscurity-items');
  _renderObscurityItems(itemsEl, _obscurityScored, sortKey);
  document.querySelectorAll('.obs-filter').forEach(b =>
    b.classList.toggle('active', b.dataset.sort === sortKey)
  );
}

function syncSettingsFields() {
  const uEl  = document.getElementById('settings-username');
  const aEl  = document.getElementById('settings-apikey');
  if (uEl) uEl.value = APP.username;
  if (aEl) aEl.value = APP.apiKey;

  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === APP.currentTheme));
  document.querySelectorAll('.acc-dot').forEach(b => b.classList.toggle('active', b.dataset.color === APP.currentAccent));
  document.querySelectorAll('.lang-btn').forEach(b => b.classList.toggle('active', b.dataset.lang === APP.language));

  // Tinted background toggle
  APP.tintBg = localStorage.getItem('ls_tint_bg') !== '0';
  const tintToggle = document.getElementById('tint-bg-toggle');
  if (tintToggle) tintToggle.checked = APP.tintBg;

  // Notifications
  _syncNotifBtn();
  _syncNotifOptions();
  loadNotifPrefs();
  _checkScheduledNotifs();
}

function saveSettings() {
  const uEl = document.getElementById('settings-username');
  const aEl = document.getElementById('settings-apikey');
  const newUser = (uEl?.value || '').trim();
  const newKey  = (aEl?.value || '').trim();

  if (!newUser || !newKey || newKey.length < 30) {
    showToast(t('setup_err_apikey'), 'error');
    return;
  }

  if (newUser !== APP.username || newKey !== APP.apiKey) {
    APP.username = newUser;
    APP.apiKey   = newKey;
    saveSession();
    initApp(newUser, newKey);
  } else {
    showToast(t('toast_settings_saved'));
  }
}

/**
 * Exporte le calendrier d'écoute (heatmap) en image PNG via html2canvas.
 */
async function exportHeatmapAsImage() {
  const wrapEl = document.getElementById('listening-heatmap-wrap-charts');
  if (!wrapEl || wrapEl.classList.contains('hidden')) {
    showToast('Chargez l\'historique complet pour afficher le calendrier.', 'error');
    return;
  }

  const btn = document.getElementById('heatmap-export-btn');
  if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'; }

  try {
    const inner = wrapEl.querySelector('.cal-heatmap-inner') || wrapEl;
    const year  = document.getElementById('cal-heatmap-yr-sel-charts')?.value || new Date().getFullYear();

    // Compute exact dimensions
    const rect = inner.getBoundingClientRect();
    const pad  = 24;

    const canvas = await html2canvas(inner, {
      scale: 2,
      useCORS: true,
      allowTaint: true,
      backgroundColor: getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#141218',
      logging: false,
      width:  rect.width  + pad * 2,
      height: rect.height + pad * 2,
      x: -pad,
      y: -pad,
    });

    // Add a branded frame
    const out    = document.createElement('canvas');
    const fw     = canvas.width;
    const fh     = canvas.height + 60; // space for title
    out.width    = fw;
    out.height   = fh;
    const ctx    = out.getContext('2d');

    const bg = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#141218';
    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, fw, fh);

    // Title
    const accent = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#d0bcff';
    ctx.fillStyle = accent;
    ctx.font = `bold ${28}px Inter, system-ui, sans-serif`;
    ctx.fillText(`🎵  Calendrier d'Écoute ${year}`, 32, 42);

    // Heatmap
    ctx.drawImage(canvas, 0, 60);

    // Footer watermark
    ctx.fillStyle = 'rgba(255,255,255,0.25)';
    ctx.font = `12px Inter, system-ui, sans-serif`;
    ctx.fillText('LastStats — sanobld.github.io/LastStats', fw - 300, fh - 14);

    downloadCanvas(out, `laststats-calendrier-${year}.png`);
    showToast('📅 Calendrier exporté !');
  } catch (e) {
    console.error('exportHeatmap:', e);
    showToast('Erreur lors de l\'export : ' + e.message, 'error');
  } finally {
    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-download"></i> <span>Exporter</span>'; }
  }
}

function exportData(format) {
  const sources = [
    { type:t('csv_artist_type'), items:APP.topArtistsData, name:d => d.name, artist:() => '',              plays:d => d.playcount, url:d => d.url },
    { type:t('csv_album_type'),  items:APP.topAlbumsData,  name:d => d.name, artist:d => d.artist?.name||'', plays:d => d.playcount, url:d => d.url },
    { type:t('csv_track_type'),  items:APP.topTracksData,  name:d => d.name, artist:d => d.artist?.name||'', plays:d => d.playcount, url:d => d.url },
  ];

  const allRows = sources.flatMap(s => s.items.map(d => ({
    [t('csv_type')]:   s.type,
    [t('csv_name')]:   s.name(d),
    [t('csv_artist')]: s.artist(d),
    [t('csv_plays')]:  s.plays(d),
    [t('csv_url')]:    s.url(d),
  })));

  if (format === 'json') {
    const blob = new Blob([JSON.stringify(allRows, null, 2)], { type:'application/json' });
    const a    = document.createElement('a');
    a.href     = URL.createObjectURL(blob);
    a.download = `laststats-${APP.username}.json`;
    a.click();
    showToast(t('toast_export_json'));
  } else {
    const headers = Object.keys(allRows[0] || {});
    const csv     = [headers.join(','), ...allRows.map(r => headers.map(h => `"${String(r[h]||'').replace(/"/g,'""')}"`).join(','))].join('\n');
    const blob    = new Blob([csv], { type:'text/csv;charset=utf-8;' });
    const a       = document.createElement('a');
    a.href        = URL.createObjectURL(blob);
    a.download    = `laststats-${APP.username}.csv`;
    a.click();
    showToast(t('toast_export_csv'));
  }
}

function toggleOhwTooltip(e) {
  if (e) e.stopPropagation();
  document.getElementById('ohw-tooltip')?.classList.toggle('ohw-tooltip--visible');
}

function closeOhwTooltip() {
  document.getElementById('ohw-tooltip')?.classList.remove('ohw-tooltip--visible');
}

document.addEventListener('click', e => {
  const tooltip = document.getElementById('ohw-tooltip');
  const btn     = document.querySelector('.info-tooltip-btn');
  if (!tooltip || !btn) return;
  if (!tooltip.contains(e.target) && !btn.contains(e.target)) tooltip.classList.remove('ohw-tooltip--visible');
});

async function forceSwUpdate() {
  const btn = document.getElementById('sw-update-btn') || document.getElementById('btn-force-update');
  if (btn) { btn.disabled = true; btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${t('toast_updating')}`; }
  try {
    if ('caches' in window) { const keys = await caches.keys(); await Promise.all(keys.map(k => caches.delete(k))); }
    if ('serviceWorker' in navigator) { const regs = await navigator.serviceWorker.getRegistrations(); await Promise.all(regs.map(r => r.unregister())); }
    Cache.clear();
    showToast(t('toast_updating'));
    await sleep(800);
    window.location.reload(true);
  } catch {
    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-sync-alt"></i>'; }
    showToast(t('toast_update_error'), 'error');
  }
}

/**
 * Demande la permission de notifications et met à jour l'UI.
 */
async function requestNotificationAccess() {
  if (!('Notification' in window)) {
    showToast('Notifications non supportées sur ce navigateur.', 'error');
    return;
  }
  const permission = await Notification.requestPermission();
  if (permission === 'granted') {
    showToast('🔔 Notifications activées !');
    setupNewYearNotification();
    _syncNotifBtn();
    _syncNotifOptions();
    loadNotifPrefs();
  } else {
    showToast('Permission refusée.', 'error');
    _syncNotifBtn();
  }
}

/**
 * Sauvegarde les préférences de notification cochées.
 */
function saveNotifPrefs() {
  if (Notification?.permission !== 'granted') {
    // Ask permission first if not granted
    requestNotificationAccess();
    return;
  }
  const prefs = {
    weekly:    document.getElementById('notif-weekly')?.checked    || false,
    monthly:   document.getElementById('notif-monthly')?.checked   || false,
    milestone: document.getElementById('notif-milestone')?.checked || false,
    wrapped:   document.getElementById('notif-wrapped')?.checked   || false,
  };
  localStorage.setItem('ls_notif_prefs', JSON.stringify(prefs));
  _scheduleNotifications(prefs);
  showToast('Préférences de notifications sauvegardées.');
}

/**
 * Charge les préférences enregistrées et restitue les checkboxes.
 */
function loadNotifPrefs() {
  try {
    const raw = localStorage.getItem('ls_notif_prefs');
    if (!raw) return;
    const prefs = JSON.parse(raw);
    const set = (id, val) => { const el = document.getElementById(id); if (el) el.checked = !!val; };
    set('notif-weekly',    prefs.weekly);
    set('notif-monthly',   prefs.monthly);
    set('notif-milestone', prefs.milestone);
    set('notif-wrapped',   prefs.wrapped);
  } catch {}
}

/**
 * Planifie les notifications selon les préférences.
 */
function _scheduleNotifications(prefs) {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  if (prefs.wrapped) setupNewYearNotification();
  // Weekly / monthly scheduling done at next visit via _checkScheduledNotifs()
  _checkScheduledNotifs(prefs);
}

function _checkScheduledNotifs(prefs) {
  if (!prefs) {
    try { prefs = JSON.parse(localStorage.getItem('ls_notif_prefs') || '{}'); } catch { return; }
  }
  if (Notification?.permission !== 'granted') return;
  const now = Date.now();

  if (prefs.weekly) {
    const lastWeekly = parseInt(localStorage.getItem('ls_notif_last_weekly') || '0');
    if (now - lastWeekly > 7 * 24 * 3600 * 1000) {
      const today = new Date();
      if (today.getDay() === 1) { // Monday
        localStorage.setItem('ls_notif_last_weekly', String(now));
        _sendNotif('📊 Récap de la semaine', `Bonjour ! Voici le moment de consulter vos stats Last.fm de la semaine passée.`);
      }
    }
  }

  if (prefs.monthly) {
    const lastMonthly = parseInt(localStorage.getItem('ls_notif_last_monthly') || '0');
    if (now - lastMonthly > 28 * 24 * 3600 * 1000) {
      const today = new Date();
      if (today.getDate() === 1) {
        localStorage.setItem('ls_notif_last_monthly', String(now));
        const months = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'];
        _sendNotif('📅 Récap du mois', `Votre récap de ${months[today.getMonth() === 0 ? 11 : today.getMonth() - 1]} est disponible !`);
      }
    }
  }
}

function _sendNotif(title, body) {
  if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
    navigator.serviceWorker.controller.postMessage({ type: 'SHOW_NOTIFICATION', title, body });
  } else {
    new Notification(title, { body, icon: './icons/icon-192.png' });
  }
}

function _syncNotifBtn() {
  const btn   = document.getElementById('btn-notif-enable');
  const label = document.getElementById('btn-notif-label');
  if (!btn || !label) return;
  const perm = Notification?.permission;
  if (perm === 'granted') {
    btn.classList.add('active');
    label.textContent = 'Notifications activées ✓';
  } else if (perm === 'denied') {
    btn.classList.add('disabled');
    label.textContent = 'Permission refusée';
  } else {
    btn.classList.remove('active', 'disabled');
    label.textContent = 'Activer les notifications';
  }
}

function _syncNotifOptions() {
  const grid = document.getElementById('notif-options-grid');
  if (!grid) return;
  const enabled = Notification?.permission === 'granted';
  grid.querySelectorAll('input[type="checkbox"]').forEach(cb => { cb.disabled = !enabled; });
  grid.style.opacity = enabled ? '1' : '0.45';
  grid.style.pointerEvents = enabled ? '' : 'none';
}

/**
 * Planifie la notification Wrapped du Nouvel An.
 */
function setupNewYearNotification() {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  const now         = new Date();
  const nextYear    = now.getFullYear() + 1;
  const wrappedYear = nextYear - 1;
  const storageKey  = `ls_newyear_notif_${nextYear}`;
  if (localStorage.getItem(storageKey)) return;
  const fireNotif = () => {
    localStorage.setItem(storageKey, '1');
    _sendWrappedNotification(wrappedYear);
  };
  const target = new Date(nextYear, 0, 1, 0, 1, 0);
  const ms = target - now;
  if (ms > 0) setTimeout(fireNotif, ms);
  else fireNotif();
}

function _sendWrappedNotification(wrappedYear) {
  const title = 'Bonne année ! 🎧';
  const body  = `Votre Wrapped ${wrappedYear} est prêt. Découvrez vos top artistes et titres de l'année !`;
  _sendNotif(title, body);
}

function clearCache() {
  Cache.clear();
  _clearHistoryCache();
  _imgCache.clear();
  _trackImgCache.clear();
  showToast(t('toast_cache_cleared'));
}

// toggleable sections (dashboard + settings are always locked)
const NAV_SECTIONS = [
  { key: 'top-artists', icon: 'fa-microphone-alt', i18nKey: 'nav_top_artists',  locked: false },
  { key: 'top-albums',  icon: 'fa-compact-disc',   i18nKey: 'nav_top_albums',   locked: false },
  { key: 'top-tracks',  icon: 'fa-music',          i18nKey: 'nav_top_tracks',   locked: false },
  { key: 'charts',      icon: 'fa-chart-bar',      i18nKey: 'nav_charts',       locked: false },
  { key: 'obscurity',   icon: 'fa-gem',            i18nKey: 'nav_obscurity',    locked: false },
  { key: 'history',     icon: 'fa-history',        i18nKey: 'nav_history',      locked: false },
  { key: 'compare',     icon: 'fa-users-rays',     i18nKey: 'nav_compare',      locked: false },
];

function loadNavVisibility() {
  try {
    const saved = localStorage.getItem('ls_nav_visibility');
    APP.navVisibility = saved ? JSON.parse(saved) : null;
  } catch { APP.navVisibility = null; }
  applyNavVisibility();
}

function saveNavVisibility() {
  localStorage.setItem('ls_nav_visibility', JSON.stringify(APP.navVisibility));
}

function applyNavVisibility() {
  const vis = APP.navVisibility;

  // show / hide individual nav items
  NAV_SECTIONS.forEach(({ key, locked }) => {
    if (locked) return;
    const hidden = vis && vis[key] === false;
    document.querySelectorAll(`.nav-lnk[data-s="${key}"], .bn-item[data-s="${key}"]`).forEach(el => {
      el.classList.toggle('nav-hidden', hidden);
    });
  });

  // switch between distributed layout and scrollable carousel
  //    Count visible items: 2 always-locked (dashboard + settings) + visible optional sections
  const visibleOptional = NAV_SECTIONS.filter(({ key, locked }) => {
    if (locked) return true;
    return !(vis && vis[key] === false);
  }).length;
  const totalVisible = 2 + visibleOptional; // +2 for dashboard & settings

  const nav = document.querySelector('.bottom-nav');
  if (nav) {
    // ≤5 items fit on any phone without scrolling
    nav.classList.toggle('bn-fit', totalVisible <= 5);
  }
}

function renderNavVisibilitySettings() {
  const grid = document.getElementById('nav-visibility-grid');
  if (!grid) return;
  const vis = APP.navVisibility || {};
  grid.innerHTML = NAV_SECTIONS.map(({ key, icon, i18nKey, locked }) => {
    const isChecked = locked || (vis[key] !== false);
    return `
      <label class="nav-vis-item${isChecked ? ' checked' : ''}${locked ? ' disabled-item' : ''}"
             data-navkey="${key}" ${locked ? '' : `onclick="toggleNavVisibility('${key}', this)"`}>
        <span class="nav-vis-chk"><i class="fas fa-check"></i></span>
        <span class="nav-vis-icon"><i class="fas ${icon}"></i></span>
        <span class="nav-vis-label">${t(i18nKey) || key}</span>
      </label>`;
  }).join('');
}

function toggleNavVisibility(key, labelEl) {
  if (!APP.navVisibility) APP.navVisibility = {};
  const current = APP.navVisibility[key] !== false; // true = visible
  APP.navVisibility[key] = !current;
  labelEl.classList.toggle('checked', !current);
  saveNavVisibility();
  applyNavVisibility();
  showToast(t('toast_settings_saved'));
}

function _todayStr() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}

function _dateStrToObj(str) {
  const [y, m, d] = str.split('-').map(Number);
  return new Date(y, m - 1, d);
}

function _formatDayLabel(dateStr) {
  const d = _dateStrToObj(dateStr);
  const opts = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
  return d.toLocaleDateString(undefined, opts);
}

function histInit() {
  APP.histCurrentDate = _todayStr();
  APP.histCurrentView = 'timeline';
  APP.histSortOrder   = 'desc'; // desc = recent first, asc = oldest first
  const input = document.getElementById('hist-date-input');
  if (input) input.value = APP.histCurrentDate;
  // don't load until the section is opened
}

function histToggleSort() {
  APP.histSortOrder = APP.histSortOrder === 'desc' ? 'asc' : 'desc';
  const btn = document.getElementById('hist-sort-btn');
  if (btn) {
    const icon = btn.querySelector('i');
    if (icon) {
      icon.className = APP.histSortOrder === 'desc'
        ? 'fas fa-sort-amount-down'
        : 'fas fa-sort-amount-up';
    }
    btn.title = APP.histSortOrder === 'desc' ? 'Plus récent en premier' : 'Plus ancien en premier';
    const span = btn.querySelector('span');
    if (span) span.textContent = APP.histSortOrder === 'desc' ? 'Récent' : 'Ancien';
  }
  if (APP._histLastData) _renderHistView(APP.histCurrentView, APP._histLastData);
}

function histGoToday() {
  const d = _todayStr();
  APP.histCurrentDate = d;
  const input = document.getElementById('hist-date-input');
  if (input) input.value = d;
  histLoadDay(d);
}

function histGoToDate(val) {
  if (!val) return;
  APP.histCurrentDate = val;
  histLoadDay(val);
}

function histNavDay(delta) {
  const d = _dateStrToObj(APP.histCurrentDate || _todayStr());
  d.setDate(d.getDate() + delta);
  const str = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
  // can't navigate into the future
  if (str > _todayStr()) return;
  APP.histCurrentDate = str;
  const input = document.getElementById('hist-date-input');
  if (input) input.value = str;
  histLoadDay(str);
}

function histSetView(view) {
  APP.histCurrentView = view;
  document.querySelectorAll('.hist-tab').forEach(el =>
    el.classList.toggle('active', el.dataset.view === view)
  );
  document.querySelectorAll('.hist-view').forEach(el =>
    el.classList.toggle('active', el.id === `hist-view-${view}`)
  );
  // re-render current data for the newly active tab
  if (APP._histLastData) {
    _renderHistView(view, APP._histLastData);
  }
}

async function histLoadDay(dateStr) {
  if (!dateStr) return;
  APP.histCurrentDate = dateStr;

  // update date input and label
  const input = document.getElementById('hist-date-input');
  if (input) input.value = dateStr;
  const summaryDate = document.getElementById('hist-summary-date');
  if (summaryDate) summaryDate.textContent = _formatDayLabel(dateStr);

  // disable next-day button when on today
  const nextBtn = document.getElementById('hist-next-day');
  if (nextBtn) nextBtn.disabled = (dateStr >= _todayStr());

  // show loading state in all tabs
  _histShowLoading();

  try {
    // check in-memory cache first
    let tracks = APP.histCache[dateStr];
    if (!tracks) {
      const d    = _dateStrToObj(dateStr);
      const from = Math.floor(new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0).getTime() / 1000);
      const to   = Math.floor(new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59).getTime() / 1000);

      const data = await API._fetch('user.getRecentTracks', { from, to, limit: 200 });
      const raw  = data.recenttracks?.track || [];
      tracks = (Array.isArray(raw) ? raw : [raw]).filter(tr => !tr['@attr']?.nowplaying);
      APP.histCache[dateStr] = tracks;
    }

    APP._histLastData = tracks;
    _updateHistSummary(tracks, dateStr);
    _renderHistView(APP.histCurrentView, tracks);

  } catch (e) {
    _histShowError(e.message);
  }
}

function _histShowLoading() {
  ['timeline','list','stats'].forEach(v => {
    const el = document.getElementById(`hist-loading-${v}`);
    if (el) el.style.display = 'flex';
  });
  const tl = document.getElementById('hist-timeline-list');
  if (tl) tl.innerHTML = `<div class="hist-loading"><div class="spinner-sm"></div><span>${t('history_loading') || 'Loading…'}</span></div>`;
  const lw = document.getElementById('hist-list-wrap');
  if (lw) lw.innerHTML = `<div class="hist-loading"><div class="spinner-sm"></div><span>${t('history_loading') || 'Loading…'}</span></div>`;
  const sg = document.getElementById('hist-stats-grid');
  if (sg) sg.innerHTML = `<div class="hist-loading"><div class="spinner-sm"></div><span>${t('history_loading') || 'Loading…'}</span></div>`;
}

function _histShowError(msg) {
  const html = `<div class="hist-empty"><i class="fas fa-exclamation-triangle"></i><span>${escHtml(msg)}</span></div>`;
  ['hist-timeline-list','hist-list-wrap','hist-stats-grid'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.innerHTML = html;
  });
}

function _updateHistSummary(tracks, dateStr) {
  const artists = new Set(tracks.map(tr => tr.artist?.['#text'] || tr.artist?.name || '')).size;
  const albums  = new Set(tracks.map(tr => tr.album?.['#text'] || '')).size;

  const countEl   = document.getElementById('hist-stat-count');
  const artistsEl = document.getElementById('hist-stat-artists');
  const albumsEl  = document.getElementById('hist-stat-albums');

  if (countEl)   countEl.innerHTML   = `<i class="fas fa-headphones"></i> ${tracks.length} scrobbles`;
  if (artistsEl) artistsEl.innerHTML = `<i class="fas fa-microphone-alt"></i> ${artists} artists`;
  if (albumsEl)  albumsEl.innerHTML  = `<i class="fas fa-compact-disc"></i> ${albums} albums`;
}

function _renderHistView(view, tracks) {
  if (view === 'timeline') _renderHistTimeline(tracks);
  if (view === 'list')     _renderHistList(tracks);
  if (view === 'stats')    _renderHistStats(tracks);
}

// Timeline view
function _renderHistTimeline(tracks) {
  const wrap = document.getElementById('hist-timeline-list');
  if (!wrap) return;

  if (!tracks.length) {
    wrap.innerHTML = `<div class="hist-empty"><i class="fas fa-music"></i><span>${t('history_noScrobbles') || 'No scrobbles on this day'}</span></div>`;
    return;
  }

  // Tri global par timestamp : desc = récent en premier, asc = ancien en premier
  const sorted = [...tracks].sort((a, b) => {
    const ta = parseInt(a.date?.uts || 0);
    const tb = parseInt(b.date?.uts || 0);
    return APP.histSortOrder === 'asc' ? ta - tb : tb - ta;
  });

  // Groupage par heure en préservant l'ordre de parcours (hourOrder garde l'ordre des blocs)
  const byHour    = {};
  const hourOrder = [];
  sorted.forEach(tr => {
    const ts = parseInt(tr.date?.uts || 0);
    const hr = ts ? new Date(ts * 1000).getHours() : -1;
    if (!byHour[hr]) { byHour[hr] = []; hourOrder.push(hr); }
    byHour[hr].push(tr);
  });

  wrap.innerHTML = hourOrder.map(hr => {
    const label = hr < 0 ? '??' : `${String(hr).padStart(2,'0')}:00`;
    const items = byHour[hr].map(tr => _histTrackHTML(tr)).join('');
    return `<div class="hist-hour-block">
      <div class="hist-hour-label">${label}</div>
      ${items}
    </div>`;
  }).join('');
}

function _histTrackHTML(tr) {
  const ts      = parseInt(tr.date?.uts || 0);
  const timeStr = ts ? new Date(ts * 1000).toLocaleTimeString(undefined, { hour:'2-digit', minute:'2-digit' }) : '—';
  const name    = escHtml(tr.name || '—');
  const artist  = escHtml(tr.artist?.['#text'] || tr.artist?.name || '—');
  const album   = escHtml(tr.album?.['#text'] || '');
  const imgUrl  = tr.image?.find(i => i.size === 'medium')?.['#text'] || '';
  const hasImg  = imgUrl && !isDefaultImg(imgUrl);
  const letter  = (tr.name || '?')[0].toUpperCase();
  const q       = encodeURIComponent(`${tr.name || ''} ${tr.artist?.['#text'] || tr.artist?.name || ''}`);

  const imgHTML = hasImg
    ? `<img src="${escHtml(imgUrl)}" alt="" loading="lazy" onerror="this.style.display='none'">`
    : escHtml(letter);

  return `<div class="hist-timeline-track">
    <span class="hist-track-time">${timeStr}</span>
    <div class="hist-track-img">${imgHTML}</div>
    <div class="hist-track-info">
      <div class="hist-track-name">${name}</div>
      <div class="hist-track-artist">${artist}</div>
      ${album ? `<div class="hist-track-album"><i class="fas fa-compact-disc" style="font-size:.6rem;opacity:.6"></i> ${album}</div>` : ''}
    </div>
    <div class="hist-track-ext">
      <a href="https://www.youtube.com/results?search_query=${q}" target="_blank" rel="noopener" title="YouTube"><i class="fab fa-youtube"></i></a>
      <a href="spotify:search:${encodeURIComponent((tr.name||'') + ' ' + (tr.artist?.['#text']||''))}" target="_blank" rel="noopener" title="Spotify"><i class="fab fa-spotify"></i></a>
    </div>
  </div>`;
}

// List view
function _renderHistList(tracks) {
  const wrap = document.getElementById('hist-list-wrap');
  if (!wrap) return;

  if (!tracks.length) {
    wrap.innerHTML = `<div class="hist-empty"><i class="fas fa-music"></i><span>${t('history_noScrobbles') || 'No scrobbles on this day'}</span></div>`;
    return;
  }

  const header = `<div class="hist-list-header">
    <span>#</span>
    <span>Time</span>
    <span>Track / Artist</span>
    <span>Album</span>
    <span></span>
  </div>`;

  const ordered = APP.histSortOrder === 'asc' ? [...tracks] : [...tracks].reverse();
  const rows = ordered.map((tr, i) => {
    const ts      = parseInt(tr.date?.uts || 0);
    const timeStr = ts ? new Date(ts * 1000).toLocaleTimeString(undefined, { hour:'2-digit', minute:'2-digit' }) : '—';
    const name    = escHtml(tr.name || '—');
    const artist  = escHtml(tr.artist?.['#text'] || tr.artist?.name || '—');
    const album   = escHtml(tr.album?.['#text'] || '—');
    const q       = encodeURIComponent(`${tr.name || ''} ${tr.artist?.['#text'] || ''}`);
    return `<div class="hist-list-row">
      <span class="hist-list-num">${i + 1}</span>
      <span class="hist-list-time">${timeStr}</span>
      <span class="hist-list-track-cell"><strong>${name}</strong><span>${artist}</span></span>
      <span class="hist-list-album">${album}</span>
      <span class="hist-list-actions">
        <a class="hist-track-ext" href="https://www.youtube.com/results?search_query=${q}" target="_blank" rel="noopener" title="YouTube"
           style="width:26px;height:26px;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:.72rem;color:var(--text-muted);transition:background .15s;text-decoration:none"
           onmouseover="this.style.background='var(--accent-lt)';this.style.color='var(--accent)'"
           onmouseout="this.style.background='';this.style.color='var(--text-muted)'">
          <i class="fab fa-youtube"></i>
        </a>
      </span>
    </div>`;
  }).join('');

  wrap.innerHTML = header + rows;
}

// Stats view
function _renderHistStats(tracks) {
  const grid = document.getElementById('hist-stats-grid');
  if (!grid) return;

  if (!tracks.length) {
    grid.innerHTML = `<div class="hist-empty"><i class="fas fa-music"></i><span>${t('history_noScrobbles') || 'No scrobbles on this day'}</span></div>`;
    return;
  }

  // top artists
  const artistMap = {};
  tracks.forEach(tr => {
    const a = tr.artist?.['#text'] || tr.artist?.name || '?';
    artistMap[a] = (artistMap[a] || 0) + 1;
  });
  const topArtists = Object.entries(artistMap).sort((a,b) => b[1]-a[1]).slice(0, 7);

  // top tracks
  const trackMap = {};
  tracks.forEach(tr => {
    const k = `${tr.name || '?'} — ${tr.artist?.['#text'] || '?'}`;
    trackMap[k] = (trackMap[k] || 0) + 1;
  });
  const topTracks = Object.entries(trackMap).sort((a,b) => b[1]-a[1]).slice(0, 7);

  // top albums
  const albumMap = {};
  tracks.forEach(tr => {
    const al = tr.album?.['#text'];
    if (al) albumMap[al] = (albumMap[al] || 0) + 1;
  });
  const topAlbums = Object.entries(albumMap).sort((a,b) => b[1]-a[1]).slice(0, 5);

  // hour distribution
  const hourMap = Array(24).fill(0);
  tracks.forEach(tr => {
    const ts = parseInt(tr.date?.uts || 0);
    if (ts) hourMap[new Date(ts * 1000).getHours()]++;
  });
  const maxH = Math.max(...hourMap, 1);

    const listItems = arr => arr.map(([name, count], i) =>
    `<li class="hist-top-item">
      <span class="hist-top-rank">${i+1}</span>
      <span class="hist-top-name">${escHtml(name)}</span>
      <span class="hist-top-count">${count}×</span>
    </li>`
  ).join('');

  const hourBars = hourMap.map((v, h) => `
    <div class="hist-hour-bar-row">
      <span class="hist-hour-bar-label">${String(h).padStart(2,'0')}h</span>
      <div class="hist-hour-bar-track">
        <div class="hist-hour-bar-fill" style="width:${Math.round((v/maxH)*100)}%"></div>
      </div>
      <span class="hist-hour-bar-val">${v || ''}</span>
    </div>`
  ).join('');

  grid.innerHTML = `
    <div class="hist-stat-card">
      <div class="hist-stat-card-title"><i class="fas fa-microphone-alt"></i> Top Artists</div>
      <ol class="hist-top-list">${listItems(topArtists)}</ol>
    </div>
    <div class="hist-stat-card">
      <div class="hist-stat-card-title"><i class="fas fa-music"></i> Top Tracks</div>
      <ol class="hist-top-list">${listItems(topTracks)}</ol>
    </div>
    ${topAlbums.length ? `
    <div class="hist-stat-card">
      <div class="hist-stat-card-title"><i class="fas fa-compact-disc"></i> Top Albums</div>
      <ol class="hist-top-list">${listItems(topAlbums)}</ol>
    </div>` : ''}
    <div class="hist-stat-card" style="grid-column: 1 / -1">
      <div class="hist-stat-card-title"><i class="fas fa-clock"></i> Activity by hour</div>
      <div class="hist-hour-chart-wrap">${hourBars}</div>
    </div>`;
}

/* ═══════════════════════════════════════════════════════════════
   COMPARE / VERSUS MODULE
   Compare musical compatibility between the logged-in user
   and any Last.fm friend or username.
═══════════════════════════════════════════════════════════════ */


/* ═══════════════════════════════════════════════════════════════
   COMPARE / VERSUS — v4
   + Playlist commune · Historique recherches · Noms dans phrases
   + Labels génériques · Tooltips explicites · Animations M3
═══════════════════════════════════════════════════════════════ */

const VS = {
  initialized: false,
  running:     false,
  charts:      [],
  _loadTimer:  null,
};

const VS_HISTORY_KEY = () => `ls_vs_history_${APP.username || ''}`;
const VS_HISTORY_MAX = 10;

/* ── Persist & load search history ── */
function _vsHistorySave(name, imgUrl = '') {
  try {
    const raw  = localStorage.getItem(VS_HISTORY_KEY());
    const list = raw ? JSON.parse(raw) : [];
    const filtered = list.filter(h => h.name.toLowerCase() !== name.toLowerCase());
    filtered.unshift({ name, img: imgUrl || '', ts: Date.now() });
    localStorage.setItem(VS_HISTORY_KEY(), JSON.stringify(filtered.slice(0, VS_HISTORY_MAX)));
  } catch {}
}

function _vsHistoryLoad() {
  try {
    const raw = localStorage.getItem(VS_HISTORY_KEY());
    return raw ? JSON.parse(raw) : [];
  } catch { return []; }
}

function _vsHistoryClear() {
  try { localStorage.removeItem(VS_HISTORY_KEY()); } catch {}
  const el = document.getElementById('vs-history-wrap');
  if (el) el.innerHTML = '';
}

function _vsRenderHistory() {
  const wrap = document.getElementById('vs-history-wrap');
  if (!wrap) return;
  const history = _vsHistoryLoad();
  if (!history.length) { wrap.innerHTML = ''; return; }

  wrap.innerHTML = `
    <div class="vs-history-hd">
      <i class="fas fa-clock-rotate-left"></i>
      <span>${t('compare_history_title')}</span>
      <button class="vs-history-clear" onclick="_vsHistoryClear()" title="${t('compare_history_clear')}">
        <i class="fas fa-times"></i>
      </button>
    </div>
    <div class="vs-history-chips">
      ${history.map(h => {
        const name = escHtml(h.name);
        const grad = nameToGradient(h.name);
        const letter = h.name[0].toUpperCase();
        return `<button class="vs-chip vs-chip--history" onclick="runComparison('${name.replace(/'/g,"\\'")}')">
          <span class="vs-chip-av">
            <span class="vs-chip-fallback" style="background:${grad}">${letter}</span>
            ${h.img ? `<img src="${h.img}" alt="${name}" class="vs-chip-img" onerror="this.remove()">` : ''}
          </span>
          <span class="vs-chip-name">${name}</span>
        </button>`;
      }).join('')}
    </div>`;
}

/* ── Destroy charts ── */
function _vsDestroyCharts() {
  VS.charts.forEach(id => {
    try {
      const el = document.getElementById(id);
      if (el && typeof Chart !== 'undefined') { const ex = Chart.getChart(el); if (ex) ex.destroy(); }
    } catch {}
    if (APP.charts[id]) { try { APP.charts[id].destroy(); } catch {}; delete APP.charts[id]; }
  });
  VS.charts = [];
}

/* ── Generic API fetch with cache ── */
async function _apiFetchUser(method, user, params = {}) {
  const url = new URL(LASTFM_URL);
  url.searchParams.set('method',  method);
  url.searchParams.set('api_key', APP.apiKey);
  url.searchParams.set('user',    user);
  url.searchParams.set('format',  'json');
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, String(v)));
  const cacheKey = `vs4_${method}_${user}_${JSON.stringify(params)}`;
  try { const c = sessionStorage.getItem(cacheKey); if (c) return JSON.parse(c); } catch {}
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const res  = await fetch(url.toString());
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      if (data.error) throw new Error(data.message || `API error ${data.error}`);
      try { sessionStorage.setItem(cacheKey, JSON.stringify(data)); } catch {}
      return data;
    } catch (e) {
      if (attempt === 2) throw e;
      await sleep(600 * (attempt + 1));
    }
  }
}

/* ── Animated loading ── */
function _vsShowLoading(friendName) {
  const loadEl = document.getElementById('vs-loading');
  if (!loadEl) return;
  const msgs = ['compare_load_profile','compare_load_artists','compare_load_history','compare_load_analysis'];
  let idx = 0;
  loadEl.innerHTML = `
    <div class="vs-loading-inner">
      <div class="vs-loading-duel">
        <div class="vs-loading-av" style="background:${nameToGradient(APP.username)}">${(APP.username||'?')[0].toUpperCase()}</div>
        <div class="vs-loading-bolt"><i class="fas fa-bolt"></i></div>
        <div class="vs-loading-av vs-loading-av--fr" style="background:${nameToGradient(friendName)}">${friendName[0].toUpperCase()}</div>
      </div>
      <span class="vs-loading-msg" id="vs-load-msg">${t(msgs[0])}</span>
      <div class="vs-loading-steps">
        ${msgs.map((_,i) => `<span class="vs-load-dot${i===0?' active':''}"></span>`).join('')}
      </div>
    </div>`;
  VS._loadTimer = setInterval(() => {
    idx = (idx + 1) % msgs.length;
    const el = document.getElementById('vs-load-msg');
    if (el) el.textContent = t(msgs[idx]);
    loadEl.querySelectorAll('.vs-load-dot').forEach((d, i) => d.classList.toggle('active', i === idx));
  }, 800);
}

/* ── Confetti ── */
function _launchConfetti() {
  const canvas = document.createElement('canvas');
  canvas.style.cssText = 'position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:9999';
  document.body.appendChild(canvas);
  const ctx = canvas.getContext('2d');
  canvas.width = window.innerWidth; canvas.height = window.innerHeight;
  const accent = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#d0bcff';
  const colors = [accent, '#f97316', '#4caf80', '#38bdf8', '#fb7185', '#facc15', '#a78bfa'];
  const pieces = Array.from({ length: 130 }, () => ({
    x: Math.random() * canvas.width, y: -20 - Math.random() * 80,
    w: 6 + Math.random() * 10, h: 3 + Math.random() * 6,
    rot: Math.random() * Math.PI * 2,
    vx: (Math.random() - 0.5) * 5, vy: 1.5 + Math.random() * 3,
    vrot: (Math.random() - 0.5) * 0.25,
    color: colors[Math.floor(Math.random() * colors.length)], alpha: 1,
  }));
  let frame;
  const tick = () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    let alive = false;
    pieces.forEach(p => {
      p.x += p.vx; p.y += p.vy; p.rot += p.vrot; p.vy += 0.08;
      if (p.y < canvas.height + 20) { alive = true; p.alpha = Math.max(0, 1 - (p.y / canvas.height) * 0.9); }
      ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.rot);
      ctx.globalAlpha = p.alpha; ctx.fillStyle = p.color;
      ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
      ctx.restore();
    });
    if (alive) frame = requestAnimationFrame(tick); else canvas.remove();
  };
  frame = requestAnimationFrame(tick);
  setTimeout(() => { cancelAnimationFrame(frame); canvas.remove(); }, 5000);
}

/* ── Ripple effect (M3) ── */
function _vsRipple(e) {
  const btn = e.currentTarget;
  const rect = btn.getBoundingClientRect();
  const ripple = document.createElement('span');
  const size   = Math.max(rect.width, rect.height) * 2;
  ripple.style.cssText = `
    position:absolute; border-radius:50%; pointer-events:none; transform:scale(0);
    width:${size}px; height:${size}px;
    top:${e.clientY - rect.top - size / 2}px;
    left:${e.clientX - rect.left - size / 2}px;
    background:rgba(255,255,255,0.25);
    animation:m3-ripple 500ms var(--ease-decel) forwards;`;
  btn.style.position = 'relative';
  btn.style.overflow = 'hidden';
  btn.appendChild(ripple);
  setTimeout(() => ripple.remove(), 600);
}

/* ── Friend chip builder ── */
function _buildChip(f, isLive) {
  const imgRaw = Array.isArray(f.image) ? f.image.find(i => i.size === 'medium')?.['#text'] : '';
  const imgUrl = imgRaw && !imgRaw.includes(DEFAULT_IMG) ? imgRaw : '';
  const name   = escHtml(f.name);
  const grad   = nameToGradient(f.name);
  const letter = f.name[0].toUpperCase();
  return `
    <button class="vs-chip${isLive ? ' vs-chip--live' : ''}" onclick="runComparison('${name.replace(/'/g,"\\'")}')">
      <span class="vs-chip-av">
        <span class="vs-chip-fallback" style="background:${grad}">${letter}</span>
        ${imgUrl ? `<img src="${imgUrl}" alt="${name}" class="vs-chip-img" onerror="this.remove()">` : ''}
        ${isLive ? '<span class="vs-chip-live-dot" title="Écoute en cours"></span>' : ''}
      </span>
      <span class="vs-chip-name">${name}</span>
    </button>`;
}

/* ── Init ── */
async function initComparePage() {
  if (VS.initialized) return;
  VS.initialized = true;

  _vsRenderHistory();

  const listEl = document.getElementById('vs-friends-list');
  if (!listEl) return;
  listEl.innerHTML = `<div class="vs-chip-skeleton"><i class="fas fa-spinner fa-spin"></i></div>`;
  try {
    const data    = await _apiFetchUser('user.getFriends', APP.username, { limit: 50 });
    const friends = data?.friends?.user;
    if (!friends || (Array.isArray(friends) && friends.length === 0)) {
      listEl.innerHTML = `<p class="vs-no-friend"><i class="fas fa-user-slash"></i> ${t('compare_no_friend')}</p>`;
      return;
    }
    const list = Array.isArray(friends) ? friends : [friends];

    // Render chips immediately then check live status async
    listEl.innerHTML = list.map(f => _buildChip(f, false)).join('');

    // Check now-playing for all friends in parallel (silent failures)
    const liveChecks = await Promise.allSettled(
      list.map(f => _apiFetchUser('user.getRecentTracks', f.name, { limit: 1 }))
    );
    liveChecks.forEach((res, i) => {
      if (res.status !== 'fulfilled') return;
      const track = res.value?.recenttracks?.track;
      const first = Array.isArray(track) ? track[0] : track;
      const isLive = first?.['@attr']?.nowplaying === 'true';
      if (!isLive) return;
      // Replace chip with live version
      const btn = listEl.querySelectorAll('.vs-chip')[i];
      if (btn) btn.outerHTML = _buildChip(list[i], true);
    });
  } catch (e) {
    listEl.innerHTML = `<p class="vs-no-friend"><i class="fas fa-wifi"></i> ${escHtml(e.message)}</p>`;
  }
}

/* ── Manual search ── */
function searchFriend() {
  const inp = document.getElementById('vs-search-input');
  const name = inp?.value?.trim();
  if (!name) return;
  runComparison(name);
}

/* ── Main comparison engine ── */
async function runComparison(friendName) {
  if (VS.running) return;
  VS.running = true;
  _vsDestroyCharts();

  const loadEl    = document.getElementById('vs-loading');
  const displayEl = document.getElementById('vs-display');
  displayEl?.classList.add('hidden');
  loadEl?.classList.remove('hidden');
  _vsShowLoading(friendName);

  try {
    const [frInfo, myArtists, frArtists, myRecent200, frRecent200, myTags, frTags, frNow1] =
      await Promise.all([
        _apiFetchUser('user.getInfo',         friendName, {}),
        _getMyTopArtists(),
        _apiFetchUser('user.getTopArtists',   friendName, { period:'overall', limit:50 }),
        _apiFetchUser('user.getRecentTracks', APP.username, { limit:200 }),
        _apiFetchUser('user.getRecentTracks', friendName,   { limit:200 }),
        _apiFetchUser('user.getTopTags',      APP.username, { limit:20 }),
        _apiFetchUser('user.getTopTags',      friendName,   { limit:20 }),
        _apiFetchUser('user.getRecentTracks', friendName,   { limit:1  }),
      ]);

    const myList  = _extractArtists(myArtists);
    const frList  = _extractArtists(frArtists);
    const score   = _calcMatchScore(myList, frList);
    const common  = _commonArtists(myList, frList);
    const breaker = _findDealbreaker(myList, frList);
    const underground = _undergroundWinner(myList, frList, common);
    const sharedTags  = _commonTags(myTags, frTags);

    const myMetrics = _computeMetrics(APP.userInfo,       myArtists, myRecent200, myTags);
    const frMetrics = _computeMetrics(frInfo?.user || {}, frArtists, frRecent200, frTags);

    const myNow = _extractNowPlaying(myRecent200);
    const frNow = _extractNowPlaying(frNow1);
    const steal = _findStealArtist(myList, frList);

    const radarData   = _buildRadarData(myTags, frTags);
    const journeyData = _buildJourneyData(myRecent200, frRecent200);
    const temporal    = _buildTemporalData(APP.userInfo, frInfo?.user || {}, APP.username, friendName);
    const peaks       = _buildPeakData(myRecent200, frRecent200);
    const curiosities = _buildCuriosities(common, myList, frList);
    const playlist    = _buildSharedPlaylist(myRecent200, frRecent200);

    clearInterval(VS._loadTimer);

    /* Save to search history */
    const _frSaveImg = (() => {
      const arr = frInfo?.user?.image;
      const raw = Array.isArray(arr) ? arr.find(i => i.size === 'medium')?.['#text'] : '';
      return (raw && !raw.includes(DEFAULT_IMG)) ? raw : '';
    })();
    _vsHistorySave(friendName, _frSaveImg);
    _vsRenderHistory();

    renderComparison({
      friendName, score, common, breaker, underground, sharedTags,
      myNow, frNow, myList, frList,
      myMetrics, frMetrics, steal,
      frUserInfo: frInfo?.user || null,
      radarData, journeyData, temporal, peaks, curiosities, playlist,
    });

    if ('vibrate' in navigator) navigator.vibrate(score >= 70 ? [100, 50, 100] : [80]);
    if (score >= 90) setTimeout(_launchConfetti, 600);

  } catch (e) {
    clearInterval(VS._loadTimer);
    loadEl?.classList.add('hidden');
    showToast(`${t('compare_error')}: ${escHtml(e.message)}`, 'error');
    VS.running = false;
  }
}

/* ══════════════════════════════════════════════════════
   DATA BUILDERS
══════════════════════════════════════════════════════ */

function _computeMetrics(userInfo, artistsData, recentData, tagsData) {
  const artists   = _extractArtists(artistsData);
  const recentArr = _extractRecentTracks(recentData);
  const tagArr    = _getRawTags(tagsData);

  const totalScrobbles = parseInt(userInfo?.playcount || 0);
  const regTs          = parseInt(userInfo?.registered?.unixtime || 0);
  const daysElapsed    = regTs ? Math.max(1, Math.floor((Date.now() / 1000 - regTs) / 86400)) : 365;
  const dailyAvg       = totalScrobbles / daysElapsed;
  const listenMins     = totalScrobbles * 3.5;

  const rawDates   = recentArr.map(t => t.date.slice(0, 10)).filter(Boolean);
  const uniqueDays = new Set(rawDates).size;
  const spanDays   = rawDates.length >= 2
    ? Math.max(1, Math.round((new Date(rawDates[0]) - new Date(rawDates[rawDates.length - 1])) / 86400000) + 1)
    : Math.max(1, uniqueDays);
  const consistency = Math.min(100, (uniqueDays / spanDays) * 100);

  const topSet        = new Set(artists.map(a => a.nameLow));
  const recentArtists = [...new Set(recentArr.map(t => t.artist).filter(Boolean))];
  const discoveryRate = recentArtists.length > 0
    ? Math.min(100, (recentArtists.filter(a => !topSet.has(a)).length / recentArtists.length) * 100) : 0;

  const variance      = tagArr.length;
  const totalPc       = artists.reduce((s, a) => s + a.playcount, 0);
  const top5Pc        = artists.slice(0, 5).reduce((s, a) => s + a.playcount, 0);
  const concentration = totalPc > 0 ? Math.min(100, (top5Pc / totalPc) * 100) : 0;

  const counts = {};
  recentArr.map(t => `${t.artist}|||${t.trackLow}`).forEach(k => { counts[k] = (counts[k] || 0) + 1; });
  const uCount    = Object.keys(counts).length;
  const replayRate = uCount > 0 ? Math.min(100, (Object.values(counts).filter(c => c > 1).length / uCount) * 100) : 0;

  return { totalScrobbles, dailyAvg, listenMins, consistency, discoveryRate, variance, concentration, replayRate };
}

/* Build top 3 shared tracks (by combined play freq in recent 200) */
function _buildSharedPlaylist(myData, frData) {
  const myArr = _extractRecentTracksRaw(myData);
  const frArr = _extractRecentTracksRaw(frData);

  /* Count occurrences for each user keyed by "artist|||track" (lowercase) */
  const myCounts = {}, frCounts = {};
  myArr.forEach(t => { myCounts[t.key] = (myCounts[t.key] || 0) + 1; });
  frArr.forEach(t => { frCounts[t.key] = (frCounts[t.key] || 0) + 1; });

  const frKeys = new Set(Object.keys(frCounts));
  const shared = Object.keys(myCounts)
    .filter(k => frKeys.has(k))
    .map(k => {
      const ref = myArr.find(t => t.key === k);
      const frRef = frArr.find(t => t.key === k);
      const imgUrl = (ref?.imgUrl || frRef?.imgUrl || '');
      return {
        key:      k,
        display:  ref ? `${ref.artist} — ${ref.track}` : k,
        artist:   ref?.artist || '',
        track:    ref?.track  || '',
        imgUrl,
        myCount:  myCounts[k],
        frCount:  frCounts[k],
        combined: myCounts[k] + frCounts[k],
      };
    })
    .sort((a, b) => b.combined - a.combined)
    .slice(0, 3);

  return shared.length > 0 ? shared : null;
}

function _buildRadarData(myTags, frTags) {
  const myArr = _getRawTags(myTags);
  const frArr = _getRawTags(frTags);
  if (!myArr.length || !frArr.length) return null;
  const myMap = new Map(myArr.map(t => [t.name.toLowerCase(), parseInt(t.count || 1)]));
  const frMap = new Map(frArr.map(t => [t.name.toLowerCase(), parseInt(t.count || 1)]));
  const myMax = Math.max(...myMap.values(), 1);
  const frMax = Math.max(...frMap.values(), 1);
  const candidates = [...myMap.entries()]
    .filter(([n]) => frMap.has(n))
    .map(([n, mc]) => ({ name: n, my: Math.round((mc / myMax) * 100), fr: Math.round(((frMap.get(n) || 0) / frMax) * 100) }))
    .sort((a, b) => (b.my + b.fr) - (a.my + a.fr))
    .slice(0, 6);
  return candidates.length >= 3 ? candidates : null;
}

function _buildJourneyData(myData, frData) {
  const myArr = _extractRecentTracks(myData);
  const frArr = _extractRecentTracks(frData);
  const days = [], labels = [];
  const now = new Date();
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now); d.setDate(d.getDate() - i);
    days.push(d.toISOString().slice(0, 10));
    labels.push(d.toLocaleDateString(undefined, { weekday: 'short' }));
  }
  const _dayCount = (arr, key) => arr.filter(t => _parseLfmDate(t.date)?.slice(0, 10) === key).length;
  const myCounts = days.map(d => _dayCount(myArr, d));
  const frCounts = days.map(d => _dayCount(frArr, d));
  if (myCounts.every(v => v === 0) && frCounts.every(v => v === 0)) return null;
  return { labels, myCounts, frCounts };
}

function _parseLfmDate(str) {
  if (!str) return null;
  try {
    const months = { jan:'01',feb:'02',mar:'03',apr:'04',may:'05',jun:'06',jul:'07',aug:'08',sep:'09',oct:'10',nov:'11',dec:'12' };
    const m = str.trim().match(/^(\d{1,2})\s+(\w{3})\s+(\d{4})/);
    if (!m) return null;
    const mo = months[m[2].toLowerCase()];
    return mo ? `${m[3]}-${mo}-${m[1].padStart(2,'0')}` : null;
  } catch { return null; }
}

/* Temporal — takes actual usernames as params */
function _buildTemporalData(myUserInfo, frUserInfo, myUsername, frUsername) {
  const myReg = parseInt(myUserInfo?.registered?.unixtime || 0);
  const frReg = parseInt(frUserInfo?.registered?.unixtime  || 0);
  if (!myReg || !frReg) return null;
  const myYear = new Date(myReg * 1000).getFullYear();
  const frYear = new Date(frReg * 1000).getFullYear();
  const _era = y => {
    if (y <= 2008) return t('compare_temporal_veteran');
    if (y <= 2013) return t('compare_temporal_early');
    if (y <= 2018) return t('compare_temporal_mid');
    return t('compare_temporal_newcomer');
  };
  const diff = Math.abs(myYear - frYear);
  let phrase = '';
  if (diff < 2)
    phrase = t('compare_temporal_same');
  else if (myYear < frYear)
    phrase = t('compare_temporal_phrase_me')
      .replace('{myUser}', myUsername).replace('{frUser}', frUsername)
      .replace('{myYear}', myYear).replace('{frYear}', frYear);
  else
    phrase = t('compare_temporal_phrase_fr')
      .replace('{myUser}', myUsername).replace('{frUser}', frUsername)
      .replace('{myYear}', myYear).replace('{frYear}', frYear);
  return { myYear, frYear, myEra: _era(myYear), frEra: _era(frYear), phrase };
}

function _buildPeakData(myData, frData) {
  const _process = (data) => {
    const arr = _extractRecentTracks(data);
    const byDay = {};
    arr.forEach(t => { const d = _parseLfmDate(t.date); if (d) byDay[d] = (byDay[d] || 0) + 1; });
    const peak = Math.max(...Object.values(byDay), 0);
    const sorted = Object.keys(byDay).sort().reverse();
    let streak = 0, prev = null;
    for (const d of sorted) {
      if (!prev) { streak = 1; prev = d; continue; }
      if (Math.round((new Date(prev) - new Date(d)) / 86400000) === 1) { streak++; prev = d; }
      else break;
    }
    return { peak, streak };
  };
  const my = _process(myData), fr = _process(frData);
  return { myPeak: my.peak, frPeak: fr.peak, myStreak: my.streak, frStreak: fr.streak };
}

function _buildCuriosities(common, myList, frList) {
  if (!common.length) return null;
  const frMap = new Map(frList.map(a => [a.nameLow, a]));
  const topShared = [...common]
    .map(a => ({ ...a, combined: a.playcount + (frMap.get(a.nameLow)?.playcount || 0) }))
    .sort((a, b) => b.combined - a.combined)[0] || null;
  const neutral = [...common]
    .filter(a => a.playcount > 0 && (frMap.get(a.nameLow)?.playcount || 0) > 0)
    .map(a => {
      const fc = frMap.get(a.nameLow)?.playcount || 1;
      const mc = a.playcount;
      return { ...a, balance: Math.max(mc, fc) / Math.min(mc, fc) };
    })
    .sort((a, b) => a.balance - b.balance)[0] || null;
  return { topShared, neutral };
}

/* ══════════════════════════════════════════════════════
   RENDER
══════════════════════════════════════════════════════ */

function renderComparison({ friendName, score, common, breaker, underground, sharedTags,
                             myNow, frNow, myList, frList,
                             myMetrics, frMetrics, steal, frUserInfo,
                             radarData, journeyData, temporal, peaks, curiosities, playlist }) {
  clearInterval(VS._loadTimer);
  const loadEl    = document.getElementById('vs-loading');
  const displayEl = document.getElementById('vs-display');
  loadEl?.classList.add('hidden');
  VS.running = false;

  /* Avatars */
  const myUi     = APP.userInfo;
  const myImgRaw = myUi?.image?.find(i => i.size === 'large')?.['#text'] || '';
  const myImg    = myImgRaw && !isDefaultImg(myImgRaw) ? myImgRaw : '';
  const myGrad   = nameToGradient(APP.username);
  const myLetter = (APP.username || '?')[0].toUpperCase();
  const frImgArr = frUserInfo?.image;
  const frImgRaw = Array.isArray(frImgArr) ? frImgArr.find(i => i.size === 'large')?.['#text'] : '';
  const frImg    = frImgRaw && !isDefaultImg(frImgRaw) ? frImgRaw : '';
  const frGrad   = nameToGradient(friendName);
  const frLetter = friendName[0].toUpperCase();

  const _av = (img, grad, letter, cls = '') =>
    `<div class="vs-av${cls}">
       <span class="vs-av-fallback" style="background:${grad}">${letter}</span>
       ${img ? `<img src="${img}" alt="avatar" class="vs-av-img" onerror="this.remove()">` : ''}
     </div>`;

  const scoreColor = score >= 70 ? 'var(--score-high)' : score >= 40 ? 'var(--score-mid)' : 'var(--score-low)';
  const scoreLabel = score >= 70 ? t('compare_level_high') : score >= 40 ? t('compare_level_mid') : t('compare_level_low');
  const scoreEmoji = score >= 90 ? '🎆' : score >= 70 ? '🔥' : score >= 40 ? '🎵' : '🎲';
  const myN = escHtml(APP.username);
  const frN = escHtml(friendName);

  const _section = (icon, title, content, xCls = '') =>
    `<div class="vs-section${xCls?' '+xCls:''}" style="animation-delay:.05s">
       <div class="vs-section-title"><i class="fas fa-${icon}"></i> ${title}</div>
       ${content}
     </div>`;

  /* ── PLAYLIST ── */
  const playlistHTML = playlist ? _section('compact-disc', t('compare_playlist_title'),
    `<p class="vs-section-hint">${t('compare_playlist_sub')}</p>
     <div class="vs-playlist">
       ${playlist.map((item, i) => `
         <div class="vs-playlist-row">
           <div class="vs-playlist-art">
             ${item.imgUrl
               ? `<img src="${escHtml(item.imgUrl)}" alt="" class="vs-playlist-art-img" onerror="this.parentNode.innerHTML='<span class=vs-playlist-art-num>${i+1}</span>'">`
               : `<span class="vs-playlist-art-num">${i + 1}</span>`}
           </div>
           <div class="vs-playlist-info">
             <span class="vs-playlist-track">${escHtml(item.track)}</span>
             <span class="vs-playlist-artist">${escHtml(item.artist)}</span>
           </div>
           <div class="vs-playlist-counts">
             <span class="vs-playlist-me" title="${myN}">${item.myCount}×</span>
             <span class="vs-playlist-sep">·</span>
             <span class="vs-playlist-fr" title="${frN}">${item.frCount}×</span>
           </div>
         </div>`).join('')}
     </div>`) : '';

  /* ── RADAR ── */
  const radarHTML = radarData ? _section('spider', t('compare_radar_title'),
    `<p class="vs-section-hint">${t('compare_radar_sub')}</p>
     <div class="vs-chart-wrap vs-radar-wrap"><canvas id="vs-radar-canvas"></canvas></div>
     <div class="vs-radar-legend">
       <span class="vs-leg-dot" style="background:var(--accent)"></span><span>${myN}</span>
       <span class="vs-leg-dot" style="background:var(--vs-fr-color)"></span><span>${frN}</span>
     </div>`) : '';

  /* ── JOURNEY ── */
  const journeyHTML = journeyData ? _section('route', t('compare_journey_title'),
    `<p class="vs-section-hint">${t('compare_journey_sub').replace('{myUser}', myN).replace('{frUser}', frN)}</p>
     <div class="vs-chart-wrap vs-journey-wrap"><canvas id="vs-journey-canvas"></canvas></div>
     <div class="vs-radar-legend">
       <span class="vs-leg-dot" style="background:var(--accent)"></span><span>${myN}</span>
       <span class="vs-leg-dot" style="background:var(--vs-fr-color)"></span><span>${frN}</span>
     </div>`) : '';

  /* ── TEMPORAL ── */
  const temporalHTML = temporal ? _section('clock-rotate-left', t('compare_temporal_title'),
    `<div class="vs-temporal-grid">
       <div class="vs-temporal-card">
         ${_av(myImg, myGrad, myLetter)}
         <div class="vs-temporal-info">
           <span class="vs-temporal-name">${myN}</span>
           <span class="vs-temporal-year">${temporal.myYear}</span>
           <span class="vs-temporal-era">${temporal.myEra}</span>
         </div>
       </div>
       <div class="vs-temporal-vs"><i class="fas fa-exchange-alt"></i></div>
       <div class="vs-temporal-card vs-temporal-card--fr">
         ${_av(frImg, frGrad, frLetter, ' vs-av--fr')}
         <div class="vs-temporal-info">
           <span class="vs-temporal-name">${frN}</span>
           <span class="vs-temporal-year">${temporal.frYear}</span>
           <span class="vs-temporal-era">${temporal.frEra}</span>
         </div>
       </div>
     </div>
     <p class="vs-temporal-phrase"><i class="fas fa-quote-left"></i> ${temporal.phrase}</p>`) : '';

  /* ── PEAK ── */
  const peakHTML = _section('trophy', t('compare_peak_title'),
    `<div class="vs-peak-grid">
       <div class="vs-peak-card">
         <div class="vs-peak-icon"><i class="fas fa-fire-flame-curved"></i></div>
         <div class="vs-peak-label">${t('compare_peak_record')}</div>
         <div class="vs-peak-row">
           <div class="vs-peak-user"><span class="vs-peak-who vs-peak-who--me">${myN}</span><span class="vs-animnum vs-peak-val" data-to="${peaks.myPeak}">${peaks.myPeak}</span></div>
           <div class="vs-peak-user"><span class="vs-peak-who vs-peak-who--fr">${frN}</span><span class="vs-animnum vs-peak-val" data-to="${peaks.frPeak}">${peaks.frPeak}</span></div>
         </div>
       </div>
       <div class="vs-peak-card">
         <div class="vs-peak-icon"><i class="fas fa-calendar-check"></i></div>
         <div class="vs-peak-label">${t('compare_peak_streak')}</div>
         <div class="vs-peak-row">
           <div class="vs-peak-user"><span class="vs-peak-who vs-peak-who--me">${myN}</span><span class="vs-animnum vs-peak-val" data-to="${peaks.myStreak}">${peaks.myStreak}</span></div>
           <div class="vs-peak-user"><span class="vs-peak-who vs-peak-who--fr">${frN}</span><span class="vs-animnum vs-peak-val" data-to="${peaks.frStreak}">${peaks.frStreak}</span></div>
         </div>
       </div>
     </div>`);

  /* ── METRICS ── */
  const metricsHTML = _section('chart-line', t('compare_report_title'),
    `<div class="vs-metrics-grid">
       ${_metricCard('calendar-check', t('compare_consistency'),   t('compare_consistency_tip'),   myN, myMetrics.consistency,   frN, frMetrics.consistency,   '%', true)}
       ${_metricCard('compass',        t('compare_discovery'),     t('compare_discovery_tip'),     myN, myMetrics.discoveryRate,  frN, frMetrics.discoveryRate,  '%', true)}
       ${_metricCard('crosshairs',     t('compare_concentration'), t('compare_concentration_tip'), myN, myMetrics.concentration,  frN, frMetrics.concentration, '%', false)}
       ${_metricCard('repeat',         t('compare_replay'),        t('compare_replay_tip'),        myN, myMetrics.replayRate,     frN, frMetrics.replayRate,     '%', false)}
     </div>`);

  /* ── VOLUME ── */
  const volumeHTML = _section('database', t('compare_volume_title'),
    `<div class="vs-volume-grid">
       <div class="vs-vol-card">
         <div class="vs-vol-label">${t('compare_volume_scrobbles')}</div>
         <div class="vs-vol-row">
           <div class="vs-vol-user vs-vol-user--me"><span class="vs-vol-name">${myN}</span><span class="vs-animnum vs-vol-num" data-to="${myMetrics.totalScrobbles}">${formatNum(myMetrics.totalScrobbles)}</span></div>
           <div class="vs-vol-user vs-vol-user--fr"><span class="vs-vol-name">${frN}</span><span class="vs-animnum vs-vol-num" data-to="${frMetrics.totalScrobbles}">${formatNum(frMetrics.totalScrobbles)}</span></div>
         </div>
       </div>
       <div class="vs-vol-card">
         <div class="vs-vol-label">${t('compare_volume_time')}</div>
         <div class="vs-vol-row">
           <div class="vs-vol-user vs-vol-user--me"><span class="vs-vol-name">${myN}</span><span class="vs-vol-num">${_formatListenTime(myMetrics.listenMins)}</span></div>
           <div class="vs-vol-user vs-vol-user--fr"><span class="vs-vol-name">${frN}</span><span class="vs-vol-num">${_formatListenTime(frMetrics.listenMins)}</span></div>
         </div>
       </div>
       <div class="vs-vol-card">
         <div class="vs-vol-label">${t('compare_volume_daily')}</div>
         <div class="vs-vol-row">
           <div class="vs-vol-user vs-vol-user--me"><span class="vs-vol-name">${myN}</span><span class="vs-animnum vs-vol-num" data-to="${Math.round(myMetrics.dailyAvg)}">${Math.round(myMetrics.dailyAvg)}</span></div>
           <div class="vs-vol-user vs-vol-user--fr"><span class="vs-vol-name">${frN}</span><span class="vs-animnum vs-vol-num" data-to="${Math.round(frMetrics.dailyAvg)}">${Math.round(frMetrics.dailyAvg)}</span></div>
         </div>
       </div>
     </div>`);

  /* ── LIVE ── */
  const liveHTML = (myNow || frNow) ? _section('signal', t('compare_live_section'),
    `<div class="vs-live-cards">
       ${myNow ? `<div class="vs-live-card vs-live-card--me"><span class="vs-live-dot"></span><div class="vs-live-info"><span class="vs-live-who">${myN}</span><span class="vs-live-track">${escHtml(myNow.artist)} — ${escHtml(myNow.track)}</span></div></div>` : ''}
       ${frNow ? `<div class="vs-live-card vs-live-card--fr"><span class="vs-live-dot vs-live-dot--fr"></span><div class="vs-live-info"><span class="vs-live-who vs-live-who--fr">${frN}</span><span class="vs-live-track">${escHtml(frNow.artist)} — ${escHtml(frNow.track)}</span></div></div>` : ''}
     </div>`) : '';

  /* ── COMMON / CURIOSITIES ── */
  const commonHTML = common.slice(0, 8).map(a => `<span class="vs-tag-pill">${escHtml(a.name)}</span>`).join('');
  const tagsHTML   = sharedTags.map(tg => `<span class="vs-tag-pill vs-tag-genre">${escHtml(tg)}</span>`).join('');

  /* Dealbreaker — label cleaner: just show the artist, no username prefix */
  let breakerHTML = '';
  if (breaker.mine)   breakerHTML += `<div class="vs-breaker-row"><span class="vs-breaker-badge">${myN}</span><i class="fas fa-arrow-right vs-breaker-arrow"></i><span class="vs-breaker-artist">${escHtml(breaker.mine.name)}</span></div>`;
  if (breaker.theirs) breakerHTML += `<div class="vs-breaker-row"><span class="vs-breaker-badge vs-breaker-badge--fr">${frN}</span><i class="fas fa-arrow-right vs-breaker-arrow"></i><span class="vs-breaker-artist">${escHtml(breaker.theirs.name)}</span></div>`;

  let topSharedHTML = '', neutralHTML = '';
  if (curiosities?.topShared) topSharedHTML = `
    <div class="vs-section-subtitle"><i class="fas fa-fire"></i> ${t('compare_top_shared')}</div>
    <div class="vs-tags-wrap"><span class="vs-tag-pill vs-tag-fire">${escHtml(curiosities.topShared.name)}</span></div>`;
  if (curiosities?.neutral) neutralHTML = `
    <div class="vs-section-subtitle"><i class="fas fa-handshake"></i> ${t('compare_neutral_ground')}</div>
    <div class="vs-tags-wrap"><span class="vs-tag-pill vs-tag-neutral">${escHtml(curiosities.neutral.name)}</span></div>`;

  const crossHTML = _section('music', `${t('compare_common_artists')} (${common.length})`,
    `<div class="vs-tags-wrap">${commonHTML || `<p class="vs-empty">${t('compare_no_common')}</p>`}</div>
     ${sharedTags.length ? `<div class="vs-section-subtitle"><i class="fas fa-tags"></i> ${t('compare_shared_genres')}</div><div class="vs-tags-wrap">${tagsHTML}</div>` : ''}
     ${breakerHTML ? `<div class="vs-section-subtitle vs-section-subtitle--warn"><i class="fas fa-bolt"></i> ${t('compare_dealbreaker')} <span class="vs-subtitle-tip">${t('compare_dealbreaker_explain')}</span></div><div class="vs-tags-wrap vs-tags-wrap--col">${breakerHTML}</div>` : ''}
     ${underground ? `<div class="vs-section-subtitle"><i class="fas fa-gem"></i> ${t('compare_underground')}</div><div class="vs-tags-wrap"><span class="vs-tag-pill vs-tag-gem">${underground === 'me' ? myN : frN}</span></div>` : ''}
     ${topSharedHTML}
     ${neutralHTML}`);

  /* ── STEAL ── */
  const stealHTML = steal
    ? `<div class="vs-section vs-steal-section">
         <div class="vs-steal-hd"><i class="fas fa-lightbulb"></i><span>${t('compare_steal_title')}</span></div>
         <p class="vs-steal-sub">${t('compare_steal_sub').replace('{0}', `<strong>${frN}</strong>`)}</p>
         <div class="vs-steal-artist">
           <span class="vs-steal-rank">#${steal.rank}</span>
           <span class="vs-steal-name">${escHtml(steal.name)}</span>
           <span class="vs-steal-pc">${formatNum(steal.playcount)} ${t('scrobbles')}</span>
         </div>
       </div>`
    : `<div class="vs-section vs-steal-section">
         <div class="vs-steal-hd"><i class="fas fa-check-circle"></i></div>
         <p class="vs-steal-sub">${t('compare_steal_none').replace('{0}', `<strong>${frN}</strong>`)}</p>
       </div>`;

  /* ── Cache ami pour l'accès depuis openProfilePage ── */
  window._vsProfileCache = window._vsProfileCache || {};
  const _frCacheKey = 'fr_' + friendName;
  window._vsProfileCache[_frCacheKey] = frUserInfo;

  /* ── ASSEMBLE ── */
  displayEl.innerHTML = `
    <div class="vs-header vs-section">
      <div class="vs-player">
        ${_av(myImg, myGrad, myLetter)}
        <div class="vs-player-name">${myN}</div>
        <div class="vs-player-top3">${myList.slice(0,3).map(a=>`<span class="vs-top3-item">${escHtml(a.name)}</span>`).join('')}</div>
        <button class="vs-profile-btn" onclick="openProfilePage('${escHtml(APP.username||'')}', null, 'compare')">
          <i class="fas fa-user-circle"></i> Profil
        </button>
      </div>
      <div class="vs-score-wrap">
        <div class="vs-score-circle">
          <svg class="vs-gauge-svg" viewBox="0 0 120 120" aria-hidden="true">
            <circle class="vs-gauge-bg" cx="60" cy="60" r="50"/>
            <circle class="vs-gauge-fill" cx="60" cy="60" r="50"
                    stroke="${scoreColor}"
                    style="stroke-dasharray:0 314.159;transition:stroke-dasharray 1.3s cubic-bezier(.4,0,.2,1)"
                    data-target="${score}"/>
          </svg>
          <div class="vs-score-inner">
            <div class="vs-score-val">
              <span class="vs-animnum vs-score-num" data-to="${score}" style="color:${scoreColor}">${score}</span>
              <span class="vs-score-sfx">%</span>
            </div>
          </div>
        </div>
        <div class="vs-score-label">${scoreEmoji} ${escHtml(scoreLabel)}</div>
        <div class="vs-score-sub">${t('compare_match_score')}</div>
        ${score >= 90 ? `<div class="vs-score-wow">${t('compare_score_wow')}</div>` : ''}
      </div>
      <div class="vs-player vs-player--fr">
        ${_av(frImg, frGrad, frLetter, ' vs-av--fr')}
        <div class="vs-player-name">${frN}</div>
        <div class="vs-player-top3">${frList.slice(0,3).map(a=>`<span class="vs-top3-item">${escHtml(a.name)}</span>`).join('')}</div>
        <button class="vs-profile-btn vs-profile-btn--fr" onclick="openProfilePage('${escHtml(friendName)}', '${escHtml(_frCacheKey)}', 'compare')">
          <i class="fas fa-user-circle"></i> Profil
        </button>
      </div>
    </div>

    <div class="vs-gauge-bar-wrap">
      <div class="vs-gauge-bar"><div class="vs-gauge-bar-fill" style="width:0;background:${scoreColor}" data-w="${score}"></div></div>
    </div>

    ${liveHTML}
    ${playlistHTML}
    ${radarHTML}
    ${journeyHTML}
    ${metricsHTML}
    ${volumeHTML}
    ${temporalHTML}
    ${peakHTML}
    ${crossHTML}
    ${stealHTML}

    <div class="vs-again-wrap">
      <button class="vs-again-btn" onclick="resetCompare(); _vsRipple(event)">
        <i class="fas fa-redo"></i> <span>${t('compare_again')}</span>
      </button>
    </div>
  `;

  displayEl.classList.remove('hidden');
  _animateVsResults(displayEl);

  requestAnimationFrame(() => requestAnimationFrame(() => {
    if (radarData)   _buildRadarChart(radarData,   myN, frN);
    if (journeyData) _buildJourneyChart(journeyData, myN, frN);
  }));
}

/* ── Animate bars + count-up + ring + stagger ── */
function _animateVsResults(root) {
  requestAnimationFrame(() => {
    root.querySelectorAll('.vs-bar-fill[data-w]').forEach(el => {
      requestAnimationFrame(() => { el.style.width = el.dataset.w + '%'; });
    });
    const fill = root.querySelector('.vs-gauge-bar-fill[data-w]');
    if (fill) requestAnimationFrame(() => { fill.style.width = fill.dataset.w + '%'; });
  });

  root.querySelectorAll('.vs-animnum[data-to]').forEach((el, i) => {
    const to = parseInt(el.dataset.to);
    if (!isNaN(to) && to > 0) setTimeout(() => animateValue(el, 0, to, 1000), i * 30);
  });

  const ring = root.querySelector('.vs-gauge-fill[data-target]');
  if (ring) {
    const target = parseFloat(ring.dataset.target);
    requestAnimationFrame(() => requestAnimationFrame(() => {
      ring.style.strokeDasharray = `${Math.round(target * 3.14159)} 314.159`;
    }));
  }

  root.querySelectorAll('.vs-section, .vs-steal-section').forEach((el, i) => {
    el.style.animationDelay = `${i * 60}ms`;
    el.classList.add('vs-section-in');
  });

  /* Bind M3 ripple to all interactive VS elements */
  root.querySelectorAll('.vs-again-btn, .vs-chip, .btn-compare-run').forEach(btn => {
    btn.removeEventListener('click', _vsRipple);
    btn.addEventListener('click', _vsRipple);
  });
  /* Stagger playlist rows */
  root.querySelectorAll('.vs-playlist-row').forEach((el, i) => {
    el.style.animationDelay = `${i * 80}ms`;
  });
  /* Stagger metric cards */
  root.querySelectorAll('.vs-metric-card').forEach((el, i) => {
    el.style.animationDelay = `${i * 60}ms`;
  });
}

/* ── Radar chart ── */
function _buildRadarChart(data, myName, frName) {
  const canvas = document.getElementById('vs-radar-canvas');
  if (!canvas) return;
  const c = getThemeColors();
  const accent  = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim()  || '#d0bcff';
  const accent2 = getComputedStyle(document.documentElement).getPropertyValue('--accent-2').trim() || '#ccc2dc';
  const toRgba = (hex, a) => {
    if (!hex || hex[0] !== '#') return `rgba(208,188,255,${a})`;
    const n = parseInt(hex.slice(1), 16);
    return `rgba(${(n>>16)&255},${(n>>8)&255},${n&255},${a})`;
  };
  const chart = new Chart(canvas, {
    type: 'radar',
    data: {
      labels: data.map(d => d.name.charAt(0).toUpperCase() + d.name.slice(1)),
      datasets: [
        { label:myName, data:data.map(d=>d.my), borderColor:accent, backgroundColor:toRgba(accent,.15), pointBackgroundColor:accent, pointRadius:4, borderWidth:2 },
        { label:frName, data:data.map(d=>d.fr), borderColor:accent2, backgroundColor:toRgba(accent2,.10), pointBackgroundColor:accent2, pointRadius:4, borderWidth:2 },
      ],
    },
    options: {
      responsive:true, maintainAspectRatio:false,
      animation:{ duration:800, easing:'easeOutQuart' },
      plugins:{ legend:{display:false}, tooltip:{ backgroundColor:c.isDark?'rgba(15,15,35,.95)':'rgba(255,255,255,.95)', titleColor:c.isDark?'#e2e8f0':'#0f172a', bodyColor:c.isDark?'#94a3b8':'#475569', borderColor:'rgba(99,102,241,.2)', borderWidth:1, cornerRadius:8, padding:10 } },
      scales:{ r:{ angleLines:{color:c.grid}, grid:{color:c.grid}, pointLabels:{color:c.text, font:{size:11, weight:'600'}}, ticks:{display:false}, min:0, max:100, backgroundColor:'transparent' } },
    },
  });
  APP.charts['vs-radar-canvas'] = chart;
  VS.charts.push('vs-radar-canvas');
}

/* ── Journey chart ── */
function _buildJourneyChart(data, myName, frName) {
  const canvas = document.getElementById('vs-journey-canvas');
  if (!canvas) return;
  const c = getThemeColors();
  const accent  = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim()  || '#d0bcff';
  const accent2 = getComputedStyle(document.documentElement).getPropertyValue('--accent-2').trim() || '#ccc2dc';
  const toRgba = (hex, a) => {
    if (!hex || hex[0] !== '#') return `rgba(208,188,255,${a})`;
    const n = parseInt(hex.slice(1), 16);
    return `rgba(${(n>>16)&255},${(n>>8)&255},${n&255},${a})`;
  };
  const chart = new Chart(canvas, {
    type:'line',
    data:{
      labels:data.labels,
      datasets:[
        { label:myName, data:data.myCounts, borderColor:accent, borderWidth:2.5, backgroundColor:toRgba(accent,.12), fill:true, tension:.4, pointBackgroundColor:accent, pointRadius:4, pointHoverRadius:6 },
        { label:frName, data:data.frCounts, borderColor:accent2, borderWidth:2.5, backgroundColor:toRgba(accent2,.08), fill:true, tension:.4, pointBackgroundColor:accent2, pointRadius:4, pointHoverRadius:6 },
      ],
    },
    options:{
      responsive:true, maintainAspectRatio:false,
      animation:{ duration:900, easing:'easeOutQuart' },
      interaction:{ mode:'index', intersect:false },
      plugins:{ legend:{display:false}, tooltip:{ backgroundColor:c.isDark?'rgba(15,15,35,.95)':'rgba(255,255,255,.95)', titleColor:c.isDark?'#e2e8f0':'#0f172a', bodyColor:c.isDark?'#94a3b8':'#475569', borderColor:'rgba(99,102,241,.2)', borderWidth:1, cornerRadius:8, padding:10 } },
      scales:{
        x:{ grid:{color:c.grid}, ticks:{color:c.text, font:{size:11}} },
        y:{ grid:{color:c.grid}, ticks:{color:c.text, font:{size:11}}, min:0 },
      },
    },
  });
  APP.charts['vs-journey-canvas'] = chart;
  VS.charts.push('vs-journey-canvas');
}

/* ── Metric card ── */
function _metricCard(icon, title, tip, myName, myVal, frName, frVal, suffix = '%', higherIsBetter = true) {
  const maxVal = Math.max(myVal, frVal, 0.01);
  const myPct  = Math.round((myVal / maxVal) * 100);
  const frPct  = Math.round((frVal / maxVal) * 100);
  const myWins = higherIsBetter ? myVal >= frVal : myVal <= frVal;
  return `
    <div class="vs-metric-card">
      <div class="vs-metric-hd">
        <i class="fas fa-${icon}"></i>
        <span class="vs-metric-title">${title}</span>
        <button class="vs-metric-tip" type="button"
                data-tip="${escHtml(tip)}"
                onmouseenter="_vsTipShow(this)"
                onmouseleave="_vsTipHide()"
                onclick="_vsTipToggle(this)"
                aria-label="${escHtml(tip)}">
          <i class="fas fa-circle-question"></i>
        </button>
      </div>
      <div class="vs-metric-bars">
        <div class="vs-bar-row">
          <span class="vs-bar-name${myWins?' vs-bar-win':''}">${escHtml(myName)}</span>
          <div class="vs-bar-track"><div class="vs-bar-fill vs-bar-fill--me" style="width:0" data-w="${myPct}"></div></div>
          <span class="vs-bar-valwrap"><span class="vs-bar-num vs-animnum" data-to="${Math.round(myVal)}">${Math.round(myVal)}</span><span class="vs-bar-sfx">${suffix}</span></span>
        </div>
        <div class="vs-bar-row">
          <span class="vs-bar-name${!myWins?' vs-bar-win':''}">${escHtml(frName)}</span>
          <div class="vs-bar-track"><div class="vs-bar-fill vs-bar-fill--fr" style="width:0" data-w="${frPct}"></div></div>
          <span class="vs-bar-valwrap"><span class="vs-bar-num vs-animnum" data-to="${Math.round(frVal)}">${Math.round(frVal)}</span><span class="vs-bar-sfx">${suffix}</span></span>
        </div>
      </div>
      ${myWins
        ? `<div class="vs-metric-verdict vs-verdict--me"><i class="fas fa-trophy"></i> ${escHtml(myName)}</div>`
        : `<div class="vs-metric-verdict vs-verdict--fr"><i class="fas fa-trophy"></i> ${escHtml(frName)}</div>`}
    </div>`;
}

/* ══════════════════════════════════════════════════════
   HELPERS
══════════════════════════════════════════════════════ */

/* Raw tracks WITH original casing for display + lowercase key */
function _extractRecentTracksRaw(data) {
  const raw = data?.recenttracks?.track;
  if (!raw) return [];
  return (Array.isArray(raw) ? raw : [raw])
    .filter(t => !t['@attr']?.nowplaying)
    .map(t => {
      const artist = t.artist?.['#text'] || '';
      const track  = t.name || '';
      const imgs   = t.image || [];
      const img    = (imgs.find(i => i.size === 'medium') || imgs.find(i => i.size === 'small') || imgs[0])?.['#text'] || '';
      const imgUrl = (img && !img.includes('2a96cbd8b46e442fc41c2b86b821562f')) ? img : '';
      return { artist, track, imgUrl, key: `${artist.toLowerCase()}|||${track.toLowerCase()}` };
    });
}

function _extractRecentTracks(data) {
  const raw = data?.recenttracks?.track;
  if (!raw) return [];
  return (Array.isArray(raw) ? raw : [raw])
    .filter(t => !t['@attr']?.nowplaying)
    .map(t => ({
      artist:   (t.artist?.['#text'] || '').toLowerCase(),
      track:    t.name || '',
      trackLow: (t.name || '').toLowerCase(),
      date:     t.date?.['#text'] || '',
    }));
}
function _getRawTags(td) { const r = td?.toptags?.tag; if (!r) return []; return Array.isArray(r) ? r : [r]; }
function _extractArtists(data) {
  const raw = data?.topartists?.artist; if (!raw) return [];
  return (Array.isArray(raw)?raw:[raw]).map(a=>({ name:a.name, nameLow:a.name.toLowerCase(), playcount:parseInt(a.playcount||0), rank:parseInt(a['@attr']?.rank||999) }));
}
function _commonArtists(myList, frList) { const s=new Set(frList.map(a=>a.nameLow)); return myList.filter(a=>s.has(a.nameLow)); }
function _calcMatchScore(myList, frList) {
  const mS=new Set(myList.map(a=>a.nameLow)), fS=new Set(frList.map(a=>a.nameLow));
  let inter=0; mS.forEach(n=>{if(fS.has(n))inter++;});
  const union=mS.size+fS.size-inter; if(!union)return 0;
  const wI=myList.filter(a=>fS.has(a.nameLow)).reduce((s,a)=>s+1/a.rank,0);
  const mW=myList.slice(0,10).reduce((s,_,i)=>s+1/(i+1),0)||1;
  return Math.round(((inter/union)*.5+Math.min(wI/mW,1)*.5)*100);
}
function _findDealbreaker(myList, frList) {
  const fT=new Set(frList.map(a=>a.nameLow)), mT=new Set(myList.map(a=>a.nameLow));
  return { mine:myList.slice(0,10).find(a=>!fT.has(a.nameLow))||null, theirs:frList.slice(0,10).find(a=>!mT.has(a.nameLow))||null };
}
function _undergroundWinner(myList, frList, common) {
  if(!common.length)return null;
  const fm=new Map(frList.map(a=>[a.nameLow,a]));
  let ms=0,fs=0;
  common.forEach(a=>{ms+=a.playcount; fs+=(fm.get(a.nameLow)?.playcount||0);});
  if(ms===fs)return null; return ms<fs?'me':'friend';
}
function _commonTags(myT, frT) {
  const ma=_getRawTags(myT), fa=_getRawTags(frT); if(!ma.length||!fa.length)return[];
  const mS=new Set(ma.map(t=>t.name.toLowerCase()));
  return fa.filter(t=>mS.has(t.name.toLowerCase())).slice(0,5).map(t=>t.name);
}
function _extractNowPlaying(data) {
  const tr=data?.recenttracks?.track; if(!tr)return null;
  const last=Array.isArray(tr)?tr[0]:tr;
  if(!last?.['@attr']?.nowplaying)return null;
  return {artist:last.artist['#text'],track:last.name};
}
function _findStealArtist(myList, frList) {
  const mS=new Set(myList.map(a=>a.nameLow));
  return frList.find(a=>!mS.has(a.nameLow))||null;
}
function _formatListenTime(mins) {
  const d=Math.floor(mins/1440), h=Math.floor((mins%1440)/60);
  return d>0?`${d}d ${h}h`:`${h}h`;
}
async function _getMyTopArtists() {
  const k=`vs4_user.getTopArtists_${APP.username}_overall_50`;
  try{const c=sessionStorage.getItem(k);if(c)return JSON.parse(c);}catch{}
  return _apiFetchUser('user.getTopArtists',APP.username,{period:'overall',limit:50});
}


/* ── Tooltip helpers for metric cards ── */
/* Global floating tooltip — avoids stacking/clipping issues */
let _vsGlobalTip = null;

function _vsEnsureTip() {
  if (_vsGlobalTip && document.body.contains(_vsGlobalTip)) return _vsGlobalTip;
  _vsGlobalTip = document.createElement('div');
  _vsGlobalTip.className = 'vs-global-tip';
  _vsGlobalTip.setAttribute('role', 'tooltip');
  document.body.appendChild(_vsGlobalTip);
  return _vsGlobalTip;
}

function _vsTipShow(btn) {
  const text = btn.dataset.tip || btn.querySelector('.vs-tip-bubble')?.textContent || '';
  if (!text) return;
  const tip = _vsEnsureTip();
  tip.textContent = text;
  tip.style.visibility = 'hidden';
  tip.style.display = 'block';
  const r  = btn.getBoundingClientRect();
  const tw = tip.offsetWidth  || 220;
  const th = tip.offsetHeight || 60;
  let top  = r.top - th - 10;
  let left = r.right - tw;
  if (left < 8)                          left = 8;
  if (left + tw > window.innerWidth - 8) left = window.innerWidth - tw - 8;
  if (top < 8) top = r.bottom + 8;
  tip.style.top        = top  + 'px';
  tip.style.left       = left + 'px';
  tip.style.visibility = 'visible';
  tip.classList.add('vs-global-tip--visible');
}

function _vsTipHide() {
  if (_vsGlobalTip) {
    _vsGlobalTip.classList.remove('vs-global-tip--visible');
    _vsGlobalTip.style.display = 'none';
  }
}

function _vsTipToggle(btn) {
  if (_vsGlobalTip?.classList.contains('vs-global-tip--visible')) { _vsTipHide(); }
  else { _vsTipShow(btn); }
}

document.addEventListener('click', e => {
  if (!e.target.closest('.vs-metric-tip')) _vsTipHide();
}, true);
document.addEventListener('scroll', _vsTipHide, { passive:true, capture:true });

/* ── Reset ── */
function resetCompare() {
  _vsDestroyCharts();
  document.getElementById('vs-display')?.classList.add('hidden');
  const inp=document.getElementById('vs-search-input'); if(inp)inp.value='';
}
