'use strict';

/* ============================================================
   LASTSTATS — script.js v7
   Vanilla JS · Material You M3 · PWA
   ============================================================
   Fixes v7 :
   - i18n : applyI18n() appelé via setLanguage() + data-i18n dot→underscore
   - Musical Profile : tag-legend toujours visible + chart corrigé
   - Artist Modal : loading states gérés, bio/tracks/albums visibles
   - Artist Cards : images lazies robustes + tags injectés correctement
   - Obscurity : images artistes + score calculé correctement
   - CSS : uniformité Artistes/Albums/Titres
   ============================================================ */

// ── Constants ──────────────────────────────────────────────────
const LASTFM_URL  = 'https://ws.audioscrobbler.com/2.0/';
const CACHE_TTL   = 30 * 60 * 1000;
const TOP_LIMIT   = 50;
const DEFAULT_IMG = '2a96cbd8b46e442fc41c2b86b821562f';

const CHART_PALETTE = [
  '#6366f1','#8b5cf6','#a855f7','#d946ef','#ec4899',
  '#f43f5e','#f97316','#eab308','#22c55e','#06b6d4',
  '#3b82f6','#0ea5e9','#14b8a6','#84cc16','#78716c',
];

const MONTHS       = () => window.I18N?.arr('months')       || ['Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
const MONTHS_SHORT = () => window.I18N?.arr('months_short') || ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
const DAYS         = () => window.I18N?.arr('days')         || ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];

// Fallback t() si i18n.js pas encore chargé
if (typeof window.t !== 'function') window.t = k => k;

/* ============================================================
   PATCH DES CLÉS i18n MANQUANTES
   Injectées dans I18N_DATA avant toute utilisation
   ============================================================ */
(function _patchI18N() {
  if (typeof I18N_DATA === 'undefined') return;

  const PATCH = {
    share:              { fr:'Partager',      en:'Share',         es:'Compartir',   pt:'Partilhar',  de:'Teilen',      it:'Condividi',  ru:'Поделиться', ar:'مشاركة', ja:'シェア',  zh:'分享', ko:'공유', tr:'Paylaş'   },
    stat_diversity:     { fr:'Ratio de diversité', en:'Diversity ratio', es:'Ratio diversidad', pt:'Rácio diversidade', de:'Diversitätsrate', it:'Ratio diversità', ru:'Коэф. разнообразия', ar:'نسبة التنوع', ja:'多様性率', zh:'多样性比率', ko:'다양성 비율', tr:'Çeşitlilik oranı' },
    stat_diversity_sub: { fr:'(Artistes / Total) × 100', en:'(Artists / Total) × 100', es:'(Artistas / Total) × 100', pt:'(Artistas / Total) × 100', de:'(Künstler / Total) × 100', it:'(Artisti / Totale) × 100', ru:'(Исполнителей / Всего) × 100', ar:'(فنانون / إجمالي) × 100', ja:'(アーティスト / 合計) × 100', zh:'(艺术家 / 总计) × 100', ko:'(아티스트 / 전체) × 100', tr:'(Sanatçı / Toplam) × 100' },
    // Nouveaux succès — Tempo
    badge_crescendo_name: { fr:'Crescendo',         en:'Crescendo',         es:'Crescendo',     pt:'Crescendo',      de:'Crescendo',     it:'Crescendo',     ru:'Крещендо',       ar:'كريشيندو',  ja:'クレッシェンド',    zh:'渐强',     ko:'크레셴도',  tr:'Crescendo'    },
    badge_crescendo_desc: { fr:'Mois consécutifs en hausse (écoutes en progression)', en:'Consecutive months of growth (increasing plays)', es:'Meses consecutivos de crecimiento', pt:'Meses consecutivos de crescimento', de:'Aufeinanderfolgende Wachstumsmonate', it:'Mesi consecutivi di crescita', ru:'Последовательные месяцы роста', ar:'أشهر متتالية من النمو', ja:'連続成長月数', zh:'连续增长月份', ko:'연속 성장 월수', tr:'Ardışık büyüme ayları' },
    badge_regular_name:   { fr:'Régulier',           en:'Consistent',        es:'Constante',     pt:'Regular',        de:'Regelmäßig',    it:'Costante',      ru:'Постоянный',     ar:'منتظم',     ja:'コンスタント',     zh:'规律',     ko:'꾸준함',    tr:'Düzenli'      },
    badge_regular_desc:   { fr:'Jours d\'activité musicale répartis sur la durée', en:'Days of musical activity spread over time', es:'Días de actividad musical repartidos en el tiempo', pt:'Dias de atividade musical ao longo do tempo', de:'Musikalische Aktivitätstage über die Zeit', it:'Giorni di attività musicale nel tempo', ru:'Дни музыкальной активности за период', ar:'أيام النشاط الموسيقي على مدار الوقت', ja:'時間にわたる音楽活動日', zh:'随时间分布的音乐活动日', ko:'시간에 걸친 음악 활동 일수', tr:'Zamanla dağılmış müzik aktivite günleri' },
    badge_comeback_name:  { fr:'Come-back',          en:'Come-back',         es:'Come-back',     pt:'Come-back',      de:'Come-back',     it:'Come-back',     ru:'Камбэк',         ar:'عودة',      ja:'カムバック',       zh:'回归',     ko:'컴백',      tr:'Geri dönüş'   },
    badge_comeback_desc:  { fr:'Pauses de +30 jours puis reprise active', en:'Breaks of +30 days followed by active return', es:'Pausas de +30 días seguidas de regreso activo', pt:'Pausas de +30 dias seguidas de retorno ativo', de:'Pausen von +30 Tagen mit aktivem Comeback', it:'Pause di +30 giorni seguite da ritorno attivo', ru:'Перерывы >30 дней и активное возвращение', ar:'فترات راحة أكثر من 30 يومًا ثم عودة نشطة', ja:'30日超の休止後の復帰', zh:'超30天的休息后活跃回归', ko:'30일 이상 휴식 후 활발한 복귀', tr:'+30 günlük aranın ardından aktif geri dönüş' },
    // Nouveaux succès — Social
    badge_ambassador_name:  { fr:'Ambassadeur',      en:'Ambassador',        es:'Embajador',     pt:'Embaixador',     de:'Botschafter',   it:'Ambasciatore',  ru:'Посол',          ar:'سفير',      ja:'アンバサダー',     zh:'大使',     ko:'앰배서더',  tr:'Büyükelçi'    },
    badge_ambassador_desc:  { fr:'Artistes écoutés ≥ 100 fois (fidèles absolus)', en:'Artists played ≥ 100 times (absolute loyalists)', es:'Artistas escuchados ≥ 100 veces', pt:'Artistas ouvidos ≥ 100 vezes', de:'Künstler ≥ 100 Mal gespielt', it:'Artisti ascoltati ≥ 100 volte', ru:'Артисты прослушаны ≥ 100 раз', ar:'فنانون استُمع إليهم ≥ 100 مرة', ja:'100回以上再生したアーティスト数', zh:'播放次数≥100的艺术家数量', ko:'100회 이상 재생한 아티스트 수', tr:'≥100 kez çalınan sanatçılar' },
    badge_tastemaker_name:  { fr:'Prescripteur',     en:'Tastemaker',        es:'Prescriptor',   pt:'Influenciador',  de:'Trendsetter',   it:'Precursore',    ru:'Законодатель',   ar:'مؤثر',      ja:'テイストメーカー', zh:'品味引领者', ko:'트렌드세터', tr:'Trend belirleyici' },
    badge_tastemaker_desc:  { fr:'Artistes représentant +10% de vos écoutes', en:'Artists representing +10% of your plays', es:'Artistas que representan +10% de tus reproducciones', pt:'Artistas representando +10% das reproduções', de:'Künstler mit +10% Ihrer Wiedergaben', it:'Artisti che rappresentano +10% degli ascolti', ru:'Артисты с долей >10% прослушиваний', ar:'فنانون يمثلون أكثر من 10٪ من استماعاتك', ja:'再生回数の10%超を占めるアーティスト', zh:'占播放总量10%以上的艺术家', ko:'전체 재생의 10% 이상을 차지하는 아티스트', tr:'Çalmalarınızın +%10\'unu temsil eden sanatçılar' },
    badge_nomad_name:       { fr:'Nomade Musical',   en:'Musical Nomad',     es:'Nómada Musical',pt:'Nômade Musical', de:'Musikalischer Nomade', it:'Nomade Musicale', ru:'Музыкальный кочевник', ar:'البدوي الموسيقي', ja:'ミュージカルノマド', zh:'音乐游牧者', ko:'음악 유목민', tr:'Müzik Göçebesi' },
    badge_nomad_desc:       { fr:'Mois avec ≥10 artistes différents actifs', en:'Months with ≥10 different active artists', es:'Meses con ≥10 artistas diferentes activos', pt:'Meses com ≥10 artistas diferentes ativos', de:'Monate mit ≥10 verschiedenen aktiven Künstlern', it:'Mesi con ≥10 artisti diversi attivi', ru:'Месяцы с ≥10 разными активными артистами', ar:'أشهر مع ≥10 فنانين مختلفين نشطين', ja:'10人以上の異なるアーティストがいる月', zh:'有≥10位不同活跃艺术家的月份', ko:'≥10명의 다른 활성 아티스트가 있는 달', tr:'≥10 farklı aktif sanatçılı aylar' },
    profile_retry:      { fr:'Réessayer',     en:'Retry',         es:'Reintentar',  pt:'Tentar novamente', de:'Erneut versuchen', it:'Riprova', ru:'Повторить', ar:'إعادة المحاولة', ja:'再試行', zh:'重试', ko:'재시도', tr:'Tekrar dene' },
    profile_reload:     { fr:'Actualiser',    en:'Reload',        es:'Actualizar',  pt:'Recarregar', de:'Neu laden',   it:'Aggiorna',   ru:'Обновить',   ar:'تحديث',  ja:'更新',    zh:'刷新', ko:'새로고침', tr:'Yenile' },
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

// ── Période label (i18n) ───────────────────────────────────────
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

// ── Global Application State ───────────────────────────────────
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
  language:      window.I18N?.getLang?.() || 'fr',
  regYear:       new Date().getFullYear() - 5,

  artistsLayout: 'grid',
  albumsLayout:  'grid',
  tracksLayout:  'list',

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

/* ============================================================
   CACHE  (localStorage TTL 30 min)
   ============================================================ */
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

/* ============================================================
   API  (Last.fm REST · retry · cache)
   ============================================================ */
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

  async fetchAllPages(onProgress, yearFrom = null, yearTo = null) {
    const allTracks = [];
    let page = 1, totalPages = 1;
    const baseParams = { limit: 200, extended: 0 };
    if (yearFrom) baseParams.from = yearFrom;
    if (yearTo)   baseParams.to   = yearTo;

    do {
      const data = await this._fetch('user.getRecentTracks', { ...baseParams, page });
      const attr  = data.recenttracks?.['@attr'] || {};
      totalPages  = parseInt(attr.totalPages || 1);
      const raw   = data.recenttracks?.track || [];
      const tracks = Array.isArray(raw) ? raw : [raw];
      for (const tr of tracks) { if (!tr['@attr']?.nowplaying) allTracks.push(tr); }
      if (onProgress) onProgress(page, totalPages, allTracks.length);
      page++;
      if (page <= totalPages) await sleep(150);
    } while (page <= totalPages);

    return allTracks;
  },
};

/* ============================================================
   UTILITIES
   ============================================================ */
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
  if (APP.charts[id]) { APP.charts[id].destroy(); delete APP.charts[id]; }
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

// ── Toast ──────────────────────────────────────────────────────
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

// ── Skeletons ──────────────────────────────────────────────────
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

// ── Chart theme helpers ────────────────────────────────────────
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
  Object.values(APP.charts).forEach(chart => {
    if (!chart?.options) return;
    const c = getThemeColors();
    if (chart.options.scales) {
      Object.values(chart.options.scales).forEach(s => {
        if (s.grid)  s.grid.color  = c.grid;
        if (s.ticks) s.ticks.color = c.text;
      });
    }
    if (chart.options.plugins?.tooltip) {
      chart.options.plugins.tooltip.backgroundColor = c.isDark ? 'rgba(15,15,35,.95)' : 'rgba(255,255,255,.95)';
    }
    chart.update('none');
  });
}

/* ============================================================
   SESSION PERSISTENCE
   ============================================================ */
const saveSession  = () => { if (APP.username) localStorage.setItem('ls_username', APP.username); if (APP.apiKey) localStorage.setItem('ls_apikey', APP.apiKey); };
const clearSession = () => { localStorage.removeItem('ls_username'); localStorage.removeItem('ls_apikey'); };
const loadSavedCredentials = () => ({ username: localStorage.getItem('ls_username') || '', apiKey: localStorage.getItem('ls_apikey') || '' });

/* ============================================================
   THEME & ACCENT
   ============================================================ */
function setTheme(theme) {
  APP.currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  localStorage.setItem('ls_theme', theme);
  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === theme));
  updateAllChartThemes();
  const accent = APP.currentAccent || localStorage.getItem('ls_accent') || 'purple';
  if (accent && accent !== 'dynamic') setAccent(accent);
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

const _ACCENT_DARK  = {
  purple:{ accent:'#d0bcff', container:'#4f378b', on:'#381e72', onCont:'#eaddff', glow:'rgba(208,188,255,.18)', lt:'rgba(208,188,255,.12)' },
  blue:  { accent:'#9ecaff', container:'#004a77', on:'#001d36', onCont:'#cde5ff', glow:'rgba(158,202,255,.18)', lt:'rgba(158,202,255,.12)' },
  green: { accent:'#78dc77', container:'#1e5c1c', on:'#002105', onCont:'#94f990', glow:'rgba(120,220,119,.18)', lt:'rgba(120,220,119,.12)' },
  red:   { accent:'#ffb4ab', container:'#93000a', on:'#690005', onCont:'#ffdad6', glow:'rgba(255,180,171,.18)', lt:'rgba(255,180,171,.12)' },
  orange:{ accent:'#ffb77c', container:'#6d3400', on:'#3d1d00', onCont:'#ffdcc0', glow:'rgba(255,183,124,.18)', lt:'rgba(255,183,124,.12)' },
};
const _ACCENT_LIGHT = {
  purple:{ accent:'#6750a4', container:'#eaddff', on:'#ffffff', onCont:'#21005d', glow:'rgba(103,80,164,.3)',   lt:'rgba(103,80,164,.1)'   },
  blue:  { accent:'#0061a4', container:'#cde5ff', on:'#ffffff', onCont:'#001d36', glow:'rgba(0,97,164,.3)',     lt:'rgba(0,97,164,.1)'     },
  green: { accent:'#006e1c', container:'#94f990', on:'#ffffff', onCont:'#002105', glow:'rgba(0,110,28,.3)',     lt:'rgba(0,110,28,.1)'     },
  red:   { accent:'#ba1a1a', container:'#ffdad6', on:'#ffffff', onCont:'#410002', glow:'rgba(186,26,26,.3)',    lt:'rgba(186,26,26,.1)'    },
  orange:{ accent:'#9c4e00', container:'#ffdcc0', on:'#ffffff', onCont:'#3d1d00', glow:'rgba(156,78,0,.3)',     lt:'rgba(156,78,0,.1)'     },
};

function setAccent(colorKey) {
  APP.currentAccent = colorKey;
  localStorage.setItem('ls_accent', colorKey);
  document.querySelectorAll('.acc-dot').forEach(b => b.classList.toggle('active', b.dataset.color === colorKey));

  if (colorKey === 'dynamic') {
    const npImg = document.querySelector('#np-art img');
    if (npImg?.complete && npImg.naturalWidth > 0) _applyColorThiefFromEl(npImg);
    return;
  }

  const isDark = APP.currentTheme === 'dark' || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme:dark)').matches);
  const pal    = (isDark ? _ACCENT_DARK : _ACCENT_LIGHT)[colorKey] || _ACCENT_DARK.purple;
  _applyCSSAccent(pal);
  updateAllChartThemes();
}

function _applyCSSAccent({ accent, container, on, onCont, glow, lt }) {
  const r = document.documentElement.style;
  r.setProperty('--accent',           accent);
  r.setProperty('--accent-container', container);
  r.setProperty('--accent-on',        on);
  r.setProperty('--accent-on-cont',   onCont);
  r.setProperty('--accent-glow',      glow);
  r.setProperty('--accent-lt',        lt);
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
    const h = _rgbToHsl(r, g, b)[0];
    _applyCSSAccent({
      accent:    `hsl(${h},65%,75%)`,
      container: `hsl(${h},45%,28%)`,
      on:        `hsl(${h},45%,14%)`,
      onCont:    `hsl(${h},65%,90%)`,
      glow:      `hsla(${h},65%,75%,.18)`,
      lt:        `hsla(${h},65%,75%,.12)`,
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

/* ============================================================
   LANGUAGE  (délègue à i18n.js)
   ============================================================ */
const NAV_TITLE_KEYS = {
  dashboard:     'nav_dashboard',
  'top-artists': 'nav_top_artists',
  'top-albums':  'nav_top_albums',
  'top-tracks':  'nav_top_tracks',
  charts:        'nav_charts',
  vizplus:       'nav_vizplus',
  badges:        'nav_badges',
  obscurity:     'nav_obscurity',
  wrapped:       'nav_wrapped',
  settings:      'nav_settings',
};

function setLanguage(lang) {
  if (!window.I18N?.setLang) return;

  // ── 0. Persister et synchroniser immédiatement ──────────────
  localStorage.setItem('ls_lang', lang);
  APP.language = lang;
  window.I18N.setLang(lang);

  // ── 1. Boutons langue ───────────────────────────────────────
  document.querySelectorAll('.lang-btn').forEach(b => b.classList.toggle('active', b.dataset.lang === lang));

  // ── 2. Appliquer TOUTES les traductions data-i18n ───────────
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const raw = el.getAttribute('data-i18n');
    const key = raw.replace(/\./g, '_');
    const val = t(key) || t(raw);
    if (val && val !== key && val !== raw) el.textContent = val;
  });

  // ── 3. Navigation labels (sidebar + bottom nav) ──────────────
  document.querySelectorAll('.nav-lnk[data-s], .bn-item[data-s]').forEach(el => {
    const key  = NAV_TITLE_KEYS[el.dataset.s];
    const span = el.querySelector('span:not(.nav-bdg)');
    if (key && span) span.textContent = t(key);
  });

  // ── 4. Titre de la section active ───────────────────────────
  const activeSection = document.querySelector('.app-sec.active')?.id?.replace('s-', '');
  if (activeSection) {
    const key = NAV_TITLE_KEYS[activeSection];
    if (key) document.getElementById('hd-title').textContent = t(key);
  }

  // ── 5. Titre page ────────────────────────────────────────────
  document.title = 'LastStats — ' + (t('nav_dashboard') || 'Statistiques Last.fm');

  showToast(t('toast_lang_changed'));
}

/* ============================================================
   MOBILE NAVIGATION
   ============================================================ */
function _updateNavMode() {
  const isMobile = window.innerWidth <= 768;
  document.body.classList.toggle('nav-mode-bottom', isMobile);
  if (isMobile) {
    document.getElementById('sidebar')?.classList.remove('open');
    document.getElementById('sidebar-ov')?.classList.remove('open');
    document.body.style.overflow = '';
  }
}

/* ============================================================
   INITIALISATION
   ============================================================ */
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
      nav(savedSection);
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
    restoreBadgesFromStorage();

    // Notification Wrapped Nouvel An
    setupNewYearNotification();
    _syncNotifBtn();

    const savedAccent = localStorage.getItem('ls_accent') || 'purple';
    APP.currentAccent = savedAccent;
    if (savedAccent !== 'dynamic') setAccent(savedAccent);

    setArtistsLayout(APP.artistsLayout);
    setAlbumsLayout(APP.albumsLayout);
    setTracksLayout(APP.tracksLayout);

    // Langue : priorité à la préférence sauvegardée, sinon i18n.js auto-detect
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
  _bgHistoryTimer = setTimeout(async () => {
    if (!APP.fullHistory?.length) await fetchFullHistory(true);
  }, 4000);
}

/* ============================================================
   DOMContentLoaded
   ============================================================ */
window.addEventListener('DOMContentLoaded', () => {
  // Styles share buttons + layout fixes
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

  const theme = localStorage.getItem('ls_theme') || 'dark';
  document.documentElement.dataset.theme = theme;
  APP.currentTheme = theme;

  // Langue : i18n.js auto-detect en premier
  const lang = localStorage.getItem('ls_lang') || window.I18N?.getLang?.() || 'fr';
  APP.language = lang;
  if (window.I18N?.setLang) window.I18N.setLang(lang);

  // Traduire tous les éléments data-i18n dès le chargement
  requestAnimationFrame(() => {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const raw = el.getAttribute('data-i18n');
      const key = raw.replace(/\./g, '_');
      const val = t(key) || t(raw);
      if (val && val !== key && val !== raw) el.textContent = val;
    });
    // Marquer les boutons de langue actifs
    document.querySelectorAll('.lang-btn').forEach(b =>
      b.classList.toggle('active', b.dataset.lang === lang)
    );
  });

  APP.artistsLayout = localStorage.getItem('ls_artists_layout') || 'grid';
  APP.albumsLayout  = localStorage.getItem('ls_albums_layout')  || 'grid';
  APP.tracksLayout  = localStorage.getItem('ls_tracks_layout')  || 'list';

  const { username, apiKey } = loadSavedCredentials();
  if (document.getElementById('input-username')) document.getElementById('input-username').value = username;
  if (document.getElementById('input-apikey'))   document.getElementById('input-apikey').value   = apiKey;

  if (username && apiKey) setTimeout(() => initApp(username, apiKey), 150);

  window.addEventListener('resize', _updateNavMode, { passive: true });
  _updateNavMode();

  document.getElementById('sw-update-btn')?.addEventListener('click', forceSwUpdate);
});

/* ============================================================
   NAVIGATION
   ============================================================ */
function nav(section) {
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
    if (section === 'vizplus')   loadVizPlus();
    if (section === 'obscurity') loadObscurityScore();
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

/* ============================================================
   PROFILE UI
   ============================================================ */
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

/* ============================================================
   NOW PLAYING
   ============================================================ */
let _npTimer = null;

async function pollNowPlaying() {
  clearTimeout(_npTimer);
  try {
    const data  = await API._fetch('user.getRecentTracks', { limit: 1, extended: 1 });
    const tracks = data.recenttracks?.track;
    if (!tracks) return;
    const last = Array.isArray(tracks) ? tracks[0] : tracks;
    const wrap = document.getElementById('now-playing-wrap');

    if (last['@attr']?.nowplaying) {
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
      _npTimer = setTimeout(pollNowPlaying, 30000);
    } else {
      wrap?.classList.add('hidden');
      _npTimer = setTimeout(pollNowPlaying, 60000);
    }
  } catch { _npTimer = setTimeout(pollNowPlaying, 120000); }
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

/* ============================================================
   DASHBOARD — Heure de pointe (200 derniers scrobbles)
   ============================================================ */
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

/* ============================================================
   DASHBOARD — grille unifiée 12 cartes
   ① Volume · ② Fréquence · ③ Habitude · ④ Exploration
   ⑤ Profondeur · ⑥ Diversité · + secondaires
   ============================================================ */
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

  // Parallel: top artists + albums total + tracks total + last scrobble
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
      // first time: we got TOP_LIMIT artists — re-request just for the total
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

  // Heure de pointe — chargée en parallèle
  const peakData = await getPeakHourData();

  const cards = [
    // ① Volume
    { icon:'🎯', value:totalPlay,                      label:t('adv_total'),          sub:t('adv_total_sub'),                                color:'#6366f1' },
    // ② Fréquence
    { icon:'⚡', value:avgPerDay,                       label:t('adv_per_day'),        sub:t('adv_per_week', avgPerWeek),                     color:'#8b5cf6', noAnim:true },
    // ③ Habitude — nouvelle carte Heure de pointe
    { icon:'🕐', value:peakData.label,                  label:t('stat_peak_hour'),     sub:peakData.mood,                                     color:'#a78bfa', noAnim:true },
    // ④ Exploration
    { icon:'🎤', value:formatNum(uniqueArtistsRaw),     label:t('stat_artists'),       sub:t('stat_since_start'),                             color:'#ec4899', noAnim:true },
    // ⑤ Profondeur
    { icon:'💿', value:uniqueAlbums,                    label:t('stat_albums'),        sub:t('stat_since_start'),                             color:'#d946ef', noAnim:true },
    // ⑥ Diversité
    { icon:'📊', value:`${diversityPct}%`,               label:t('stat_diversity'),     sub:t('stat_diversity_sub'),                           color:'#14b8a6', noAnim:true },
    // — Cartes secondaires —
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

/* ============================================================
   VERSUS  (comparaison mois sur mois)
   ============================================================ */
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

/* ============================================================
   MOOD TAGS  (tags de genres depuis les top artistes)
   ============================================================ */
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

/* ============================================================
   LISTENING STREAK
   ============================================================ */
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

/* ============================================================
   HEATMAP
   ============================================================ */
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

/* ============================================================
   ARTIST IMAGE CACHE
   ============================================================ */
const _imgCache = new Map();

async function getArtistImage(artistName) {
  if (_imgCache.has(artistName)) return _imgCache.get(artistName);
  try {
    // FIX: API.call (avec cache) au lieu de API._fetch (sans cache)
    const data   = await API.call('artist.getTopAlbums', { artist:artistName, limit:3, autocorrect:1 });
    const albums = data.topalbums?.album || [];
    for (const alb of albums) {
      const img = alb.image?.find(i => i.size === 'extralarge')?.['#text'] || alb.image?.find(i => i.size === 'large')?.['#text'] || '';
      if (!isDefaultImg(img)) { _imgCache.set(artistName, img); return img; }
    }
  } catch {}
  _imgCache.set(artistName, null);
  return null;
}

async function injectArtistImage(artistName, containerId, fallbackBg, fallbackLetter) {
  const container = document.getElementById(containerId);
  if (!container) return;
  const img = await getArtistImage(artistName);
  if (img) {
    // Overlay l'image sur le fallback existant via position:absolute
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

/** Injecte les tags d'un artiste dans un conteneur DOM */
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

/* ============================================================
   TOP ARTISTS  — layout unifié
   ============================================================ */
let _artistsObserver = null;

function setArtistsLayout(layout) {
  APP.artistsLayout = layout;
  localStorage.setItem('ls_artists_layout', layout);
  const grid = document.getElementById('artists-grid');
  if (grid) {
    grid.className = grid.className.replace(/\blayout-\S+/g, '').trim();
    grid.classList.add('layout-' + layout);
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

  // ── HERO (grid) ──
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

  // ── LIST (music-card) ──
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

  // ── COMPACT ──
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

  // Lazy-load image + tags — délai plafonné à 500ms max
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
      // compact : image en absolute dans le cover
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

/* ============================================================
   TOP ALBUMS  — layout unifié
   ============================================================ */
let _albumsObserver = null;

function setAlbumsLayout(layout) {
  APP.albumsLayout = layout;
  localStorage.setItem('ls_albums_layout', layout);
  const grid = document.getElementById('albums-grid');
  if (grid) {
    grid.className = grid.className.replace(/\blayout-\S+/g, '').trim();
    grid.classList.add('layout-' + layout);
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
    <div class="music-card" style="animation-delay:${delay}s" onclick="window.open('${safeUrl}','_blank')">
      <div class="music-card-img" style="height:160px">
        ${hasImg ? `<img src="${imgUrl}" alt="${escHtml(a.name)}" loading="lazy" class="img-fade" onload="this.classList.add('img-loaded')" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
        <div class="spotify-cover" style="background:${bg};display:${hasImg ? 'none' : 'flex'}">
          <span class="sc-letter">${letter}</span><span class="sc-name">${escHtml(a.name)}</span>
        </div>
        <div class="music-card-rank">${rank}</div>
        <div class="music-card-actions">
          <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" aria-label="Open in Spotify" title="Spotify"><i class="fab fa-spotify"></i></a>
          <button class="mc-play-btn share" onclick="event.stopPropagation();shareAlbum(${JSON.stringify(a.name)},${JSON.stringify(artistNm)},${a.playcount},'${safeUrl}')" aria-label="${t('share')} ${escHtml(a.name)}" title="${t('share')}"><i class="fas fa-share-alt"></i></button>
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
      <div class="track-cover" style="flex-shrink:0;width:40px;height:40px;border-radius:6px;overflow:hidden">
        ${hasImg ? `<img src="${imgUrl}" alt="${escHtml(a.name)}" style="width:100%;height:100%;object-fit:cover" loading="lazy" onerror="this.style.display='none'">` : ''}
        <div style="width:100%;height:100%;background:${bg};display:${hasImg ? 'none' : 'flex'};align-items:center;justify-content:center;color:white;font-weight:700">${letter}</div>
      </div>
      <div class="track-rank">${rank <= 3 ? ['🥇','🥈','🥉'][rank-1] : rank}</div>
      <div class="track-info">
        <div class="track-name">${escHtml(a.name)}</div>
        <div class="track-artist">${escHtml(artistNm)}</div>
      </div>
      <div class="track-plays">${formatNum(a.playcount)}</div>
    </div>`;

  return APP.albumsLayout === 'compact' ? compactHtml : gridHtml;
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
    grid.className = `music-grid layout-${APP.albumsLayout}`;
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

/* ============================================================
   TOP TRACKS  — layout unifié
   ============================================================ */
let _tracksObserver = null;
const _trackImgCache = new Map();

function setTracksLayout(layout) {
  APP.tracksLayout = layout;
  localStorage.setItem('ls_tracks_layout', layout);
  const list = document.getElementById('tracks-list');
  if (list) list.className = `tracks-list layout-${layout}`;
  document.querySelectorAll('#tracks-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === layout)
  );
  if (APP.topTracksData.length && list) {
    const maxPlay = APP.topTracksData.length > 0 ? parseInt(APP.topTracksData[0].playcount) : 1;
    list.innerHTML = APP.topTracksData.slice(0, APP.tracksPage * 50).map((tr,i) => _buildTrackItem(tr, i+1, maxPlay)).join('');
    _resolveTrackImages(APP.topTracksData.slice(0, APP.tracksPage * 50), 1);
  }
}

function _buildTrackItem(track, rank, maxPlay) {
  const pct        = ((parseInt(track.playcount) / Math.max(maxPlay, 1)) * 100).toFixed(1);
  const medal      = rank <= 3 ? ['🥇','🥈','🥉'][rank-1] : rank;
  const spQ        = encodeURIComponent(`${track.name} ${track.artist?.name || ''}`);
  const ytQ        = encodeURIComponent(`${track.name} ${track.artist?.name || ''}`);
  const imgUrl     = track.image?.find(im => im.size === 'medium')?.['#text'] || track.image?.find(im => im.size === 'small')?.['#text'] || '';
  const hasCover   = !isDefaultImg(imgUrl);
  const coverBg    = nameToGradient(track.name + (track.artist?.name || ''));
  const coverLtr   = (track.name || '?')[0].toUpperCase();
  const delay      = Math.min((rank-1) % 20, 10) * 0.025;
  const coverElId  = `track-cover-r${rank}`;

  return `
    <div class="track-item" style="animation-delay:${delay}s"
         onclick="window.open('${(track.url || '#').replace(/'/g,'%27')}','_blank')">
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
        <button class="track-play-btn share" aria-label="${t('share')} ${escHtml(track.name)}" title="${t('share')}" onclick="event.stopPropagation();shareTrack(${JSON.stringify(track.name)},${JSON.stringify(track.artist?.name||'')},${track.playcount},'${(track.url||'').replace(/'/g,'%27')}')"><i class="fas fa-share-alt"></i></button>
      </div>
    </div>`;
}

async function _resolveTrackImage(track, rank) {
  const coverEl = document.getElementById(`track-cover-r${rank}`);
  if (!coverEl) return;

  const existingImg = track.image?.find(im => im.size === 'medium')?.['#text'] || track.image?.find(im => im.size === 'small')?.['#text'] || '';
  if (!isDefaultImg(existingImg)) return;

  const cacheKey = `${(track.artist?.name||'').toLowerCase()}::${(track.album?.['#text']||track.name||'').toLowerCase()}`;
  if (_trackImgCache.has(cacheKey)) {
    const cached = _trackImgCache.get(cacheKey);
    if (cached) _injectTrackCoverImg(coverEl, cached);
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
    if (imgUrl) _injectTrackCoverImg(coverEl, imgUrl);
  } catch { _trackImgCache.set(cacheKey, null); }
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
    list.className = `tracks-list layout-${APP.tracksLayout}`;
    list.innerHTML = skeletonTrackItems(12);
  }
  if (loader) loader.classList.add('hidden');
  if (_tracksObserver) { _tracksObserver.disconnect(); _tracksObserver = null; }

  document.querySelectorAll('#tracks-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === APP.tracksLayout)
  );

  try {
    const data   = await API.call('user.getTopTracks', { period, limit:50, page:1 });
    const tracks = data.toptracks?.track || [];
    APP.topTracksData    = tracks;
    APP.tracksTotalPages = parseInt(data.toptracks?.['@attr']?.totalPages || 1);
    const maxPlay        = tracks.length > 0 ? parseInt(tracks[0].playcount) : 1;
    if (list) list.innerHTML = tracks.map((tr,i) => _buildTrackItem(tr, i+1, maxPlay)).join('');
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
    tracks.forEach((tr,i) => list.insertAdjacentHTML('beforeend', _buildTrackItem(tr, startRank + i, maxPlay)));
    _resolveTrackImages(tracks, startRank);
    APP.topTracksData = [...APP.topTracksData, ...tracks];
  } catch (e) { console.warn('_loadMoreTracks:', e); }
  finally { APP.tracksLoading = false; if (loader) loader.classList.add('hidden'); }
}

/* ── Sélecteurs de période ─────────────────────────────────── */
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

/* ============================================================
   CHARTS SECTION
   ============================================================ */
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

  // If full history already loaded, render hourly/weekday/OHW immediately
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
  } else {
    // Show empty placeholder for OHW
    const ohwEmpty = document.getElementById('ohw-empty');
    const ohwList  = document.getElementById('ohw-list');
    if (ohwEmpty) ohwEmpty.style.display = '';
    if (ohwList)  ohwList.innerHTML = '';
  }

  // Auto-render all visualisations — no button needed
  setTimeout(() => {
    loadVizPlus();
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

/* ============================================================
   PERIOD COMPARISON  — labels i18n
   ============================================================ */
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

/* ============================================================
   WRAPPED
   ============================================================ */
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

/* ============================================================
   STORY / EXPORT
   ============================================================ */
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

/* ============================================================
   SECTION CARD EXPORT — Story 9:16 (Canvas natif, crossOrigin)
   Génère une image verticale 360×640 avec les 5 meilleurs items
   de la section : Top Artistes, Top Albums ou Top Titres.
   ============================================================ */
async function exportSectionCard(section) {
  const W = 360, H = 640;
  const canvas  = document.createElement('canvas');
  canvas.width  = W * 2;
  canvas.height = H * 2;
  const ctx = canvas.getContext('2d');
  ctx.scale(2, 2);

  /* ── Fond dégradé ─────────────────────────────────────────── */
  const bgGrad = ctx.createLinearGradient(0, 0, W, H);
  bgGrad.addColorStop(0,   '#1a1025');
  bgGrad.addColorStop(0.45,'#0f172a');
  bgGrad.addColorStop(1,   '#0d1117');
  ctx.fillStyle = bgGrad;
  ctx.fillRect(0, 0, W, H);

  /* Cercle décoratif haut-gauche */
  const gCircle = ctx.createRadialGradient(0, 0, 0, 0, 0, 200);
  gCircle.addColorStop(0, 'rgba(99,102,241,0.18)');
  gCircle.addColorStop(1, 'transparent');
  ctx.fillStyle = gCircle;
  ctx.fillRect(0, 0, W, H);

  /* ── Données selon la section ─────────────────────────────── */
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

  /* ── Chargement des pochettes (crossOrigin anonymous) ─────── */
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

  /* ── Helper : texte tronqué ───────────────────────────────── */
  const clampText = (text, maxW) => {
    let s = String(text || '—');
    while (ctx.measureText(s).width > maxW && s.length > 1) s = s.slice(0, -1);
    return s.length < String(text || '—').length ? s + '…' : s;
  };

  /* ── Header ──────────────────────────────────────────────── */
  // Logo
  ctx.font = 'bold 20px system-ui, sans-serif';
  ctx.fillStyle = '#a78bfa';
  ctx.textAlign = 'left';
  ctx.fillText('LastStats', 24, 48);

  // Pseudo
  const username = '@' + (APP.userInfo?.name || APP.username || '');
  ctx.font = '12px system-ui, sans-serif';
  ctx.fillStyle = 'rgba(255,255,255,0.45)';
  ctx.fillText(username, 24, 68);

  // Titre de section
  ctx.font = 'bold 17px system-ui, sans-serif';
  ctx.fillStyle = '#ffffff';
  ctx.textAlign = 'right';
  ctx.fillText(sectionLabel, W - 24, 48);

  // Période (si disponible)
  const prdEl = document.querySelector(`#prd-${section.replace('top-', '')} .prd.active`);
  const prdTxt = prdEl ? prdEl.textContent.trim() : '';
  if (prdTxt) {
    ctx.font = '11px system-ui, sans-serif';
    ctx.fillStyle = 'rgba(167,139,250,0.7)';
    ctx.textAlign = 'right';
    ctx.fillText(prdTxt, W - 24, 65);
  }

  // Ligne séparatrice
  const sepGrad = ctx.createLinearGradient(24, 0, W - 24, 0);
  sepGrad.addColorStop(0,   'transparent');
  sepGrad.addColorStop(0.3, 'rgba(167,139,250,0.5)');
  sepGrad.addColorStop(1,   'transparent');
  ctx.strokeStyle = sepGrad; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(24, 84); ctx.lineTo(W - 24, 84); ctx.stroke();

  /* ── Cartes des items ─────────────────────────────────────── */
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

    /* Fond carte */
    const cGrad = ctx.createLinearGradient(CARD_X, cardY, CARD_X + CARD_W, cardY + CARD_H);
    cGrad.addColorStop(0, i === 0 ? 'rgba(167,139,250,0.14)' : 'rgba(255,255,255,0.06)');
    cGrad.addColorStop(1, 'rgba(255,255,255,0.02)');
    ctx.fillStyle = cGrad;
    ctx.beginPath();
    ctx.roundRect(CARD_X, cardY, CARD_W, CARD_H, 14);
    ctx.fill();

    /* Bordure subtile */
    ctx.strokeStyle = i === 0 ? 'rgba(167,139,250,0.35)' : 'rgba(255,255,255,0.07)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.roundRect(CARD_X, cardY, CARD_W, CARD_H, 14);
    ctx.stroke();

    /* Numéro de rang */
    ctx.font = `bold ${i < 3 ? 20 : 16}px system-ui, sans-serif`;
    ctx.fillStyle = rankColors[i];
    ctx.textAlign = 'center';
    ctx.fillText(`${i + 1}`, CARD_X + 22, cardY + CARD_H / 2 + 7);

    /* Image pochette / avatar */
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
      /* Fallback : dégradé coloré + initiale */
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

    /* Texte — titre */
    const textX  = imgX + IMG_SIZE + 12;
    const maxTW  = CARD_X + CARD_W - textX - 10;

    ctx.font = `bold ${i === 0 ? 14 : 13}px system-ui, sans-serif`;
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'left';
    ctx.fillText(clampText(item.name, maxTW), textX, cardY + CARD_H / 2 - 6);

    /* Texte — sous-titre */
    let subTxt;
    if (isTrack)       subTxt = item.artist?.name || '';
    else if (isArtist) subTxt = `${formatNum(item.playcount)} ${t('plays')}`;
    else               subTxt = `${item.artist?.name ? item.artist.name + ' · ' : ''}${formatNum(item.playcount)} ${t('plays')}`;

    ctx.font = '11px system-ui, sans-serif';
    ctx.fillStyle = 'rgba(255,255,255,0.48)';
    ctx.fillText(clampText(subTxt, maxTW), textX, cardY + CARD_H / 2 + 12);

    /* Barre de popularité relative (uniquement pour items avec playcount) */
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

  /* ── Footer ───────────────────────────────────────────────── */
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

/* ============================================================
   FULL HISTORY FETCH — overlay minimisable
   ============================================================ */
let _historyFetchMinimized = false;
let _bgFetchInProgress     = false;

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

  if (!backgroundMode && overlay) {
    _historyFetchMinimized = false;
    overlay.classList.remove('hidden', 'fetch-overlay--minimized');
    document.body.classList.add('fetch-active');
    if (fillEl)   fillEl.style.width   = '0%';
    if (pctEl)    pctEl.textContent    = '0%';
    if (tracksEl) tracksEl.textContent = '0 ' + t('scrobbles');
    if (msgEl)    msgEl.textContent    = t('fetch_init');
    if (titleEl)  titleEl.textContent  = t('fetch_title');
  } else if (backgroundMode && overlay) {
    _historyFetchMinimized = true;
    overlay.classList.remove('hidden');
    overlay.classList.add('fetch-overlay--minimized');
    document.body.classList.add('fetch-active');
    _updatePillText(0);
  }

  if (minBtn) minBtn.onclick = () => toggleFetchMinimize();

  const pillEl = overlay?.querySelector('.fetch-pill');
  if (pillEl) {
    pillEl.onclick = () => { _historyFetchMinimized = false; overlay.classList.remove('fetch-overlay--minimized'); };
  }

  try {
    const tracks = await API.fetchAllPages((page, totalPages, count) => {
      const pct = Math.round((page / Math.max(totalPages, 1)) * 100);
      if (fillEl)   fillEl.style.width   = pct + '%';
      if (pctEl)    pctEl.textContent    = pct + '%';
      if (tracksEl) tracksEl.textContent = formatNum(count) + ' ' + t('scrobbles');
      if (subEl)    subEl.textContent    = t('fetch_page', page, totalPages);
      if (msgEl)    msgEl.textContent    = t('fetch_loading');
      _updatePillText(pct);
    });

    APP.fullHistory = tracks;

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
      const unique = new Set(tracks.map(tr => (tr.artist?.['#text'] || tr.artist?.name || '').toLowerCase())).size;
      uniqueArtistsEl.textContent = formatNum(unique);
    }

    _renderDayOfWeekChart(tracks);
    _renderOHWList(tracks);

    // Clear "load history" hints from charts section
    const hourlyHint  = document.getElementById('hourly-hint');
    const weekdayHint = document.getElementById('weekday-hint');
    if (hourlyHint)  hourlyHint.textContent  = '';
    if (weekdayHint) weekdayHint.textContent = '';

    // Hide OHW empty state if it was showing
    document.getElementById('ohw-empty')?.style?.setProperty?.('display', 'none');

    if (backgroundMode) {
      showToast(t('fetch_auto_done'));
      overlay?.classList.add('hidden');
      document.body.classList.remove('fetch-active');
    }

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

/* ── Smart refresh ───────────────────────────────────────────── */
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
    if (activeSection === 'charts')      { _vizPlusLoaded = false; setupChartsSection(); }
    if (activeSection === 'vizplus')     { _vizPlusLoaded = false; loadVizPlus(); }
    if (activeSection === 'obscurity')   loadObscurityScore();

    showToast(t('toast_data_updated'));
  } catch (e) { showToast(e.message, 'error'); }
  finally { if (icon) icon.classList.remove('fa-spin'); }

  _scheduleBackgroundHistoryFetch();
}

/* ── Logout ─────────────────────────────────────────────────── */
function logout() {
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

/* ============================================================
   ARTIST MODAL
   ============================================================ */
async function openArtistModal(artistName, artistUrl, userPlaycount) {
  const modal = document.getElementById('artist-modal');
  if (!modal) return;
  modal.classList.remove('hidden');
  document.body.style.overflow = 'hidden';

  const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };

  // ── Reset état de chargement ─────────────────────────────────
  setText('am-name', artistName);
  setText('am-user-plays', formatNum(userPlaycount) + ' ' + t('plays'));
  setText('am-listeners',   '—');
  setText('am-globalplays', '—');

  // Bio: spinner visible, texte caché
  const bioLoadEl   = document.getElementById('am-bio-loading');
  const bioTextEl   = document.getElementById('am-bio-text');
  const bioToggleEl = document.getElementById('am-bio-toggle');
  if (bioLoadEl)   { bioLoadEl.classList.remove('hidden'); }
  if (bioTextEl)   { bioTextEl.classList.add('hidden'); bioTextEl.textContent = ''; }
  if (bioToggleEl) { bioToggleEl.classList.add('hidden'); }

  // Tracks: spinner visible, liste cachée
  const trkLoadEl  = document.getElementById('am-tracks-loading');
  const trkListEl  = document.getElementById('am-top-tracks-list');
  if (trkLoadEl) trkLoadEl.classList.remove('hidden');
  if (trkListEl) { trkListEl.classList.add('hidden'); trkListEl.innerHTML = ''; }

  // Albums: spinner visible, grille cachée
  const albLoadEl  = document.getElementById('am-albums-loading');
  const albGridEl  = document.getElementById('am-albums-grid');
  if (albLoadEl) albLoadEl.classList.remove('hidden');
  if (albGridEl) { albGridEl.classList.add('hidden'); albGridEl.innerHTML = ''; }

  // Tags reset
  const tagsEl = document.getElementById('am-tags');
  if (tagsEl) tagsEl.innerHTML = '';

  // ── Image de l'artiste ───────────────────────────────────────
  const imgEl     = document.getElementById('am-img');
  const artistImg = await getArtistImage(artistName);
  if (imgEl) {
    imgEl.innerHTML = artistImg
      ? `<img src="${artistImg}" alt="${escHtml(artistName)}"
             style="width:100%;height:100%;object-fit:cover;object-position:center top"
             onerror="this.parentElement.innerHTML='<div style=\\'width:100%;height:100%;background:${nameToGradient(artistName)};display:flex;align-items:center;justify-content:center;font-size:3rem;font-weight:800;color:white\\'>${escHtml(artistName[0].toUpperCase())}</div>'">`
      : `<div style="width:100%;height:100%;background:${nameToGradient(artistName)};display:flex;align-items:center;justify-content:center;font-size:3rem;font-weight:800;color:white">${escHtml(artistName[0].toUpperCase())}</div>`;
  }

  // ── Liens externes ───────────────────────────────────────────
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

    // ── Bio ────────────────────────────────────────────────────
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

    // ── Tags ───────────────────────────────────────────────────
    if (tagsEl) {
      const tags = (info?.tags?.tag || [])
        .filter(tg => { const n = tg.name?.toLowerCase().trim(); return n && n.length >= 2 && !_IGNORED_TAGS.has(n); })
        .slice(0, 5);
      tagsEl.innerHTML = tags.map(tg => `<span class="am-tag">${escHtml(tg.name)}</span>`).join('');
    }

    // ── Top Tracks ─────────────────────────────────────────────
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

    // ── Albums ─────────────────────────────────────────────────
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

/* ============================================================
   SHARE HELPERS  — texte traduit
   ============================================================ */
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

/* ============================================================
   VIZ PLUS  (Radar → Sunburst chaîné · Treemap · Sankey)
   ============================================================ */
let _vizPlusLoaded = false;

async function loadVizPlus() {
  const statusEl  = document.getElementById('vizplus-status');
  const statusTxt = document.getElementById('vizplus-status-txt');
  // Update status hint in charts section header (button removed)
  const radarHint = document.getElementById('radar-status-hint');

  if (statusEl) statusEl.classList.remove('hidden');
  if (radarHint) radarHint.innerHTML = '<i class="fas fa-spinner fa-spin" style="font-size:.75rem;margin-right:4px"></i>';

  try {
    if (statusTxt) statusTxt.textContent = t('loading');
    await _buildRadarChart();
    await _buildTreemap();
    await _buildSankey();
    if (statusEl) statusEl.classList.add('hidden');
    if (radarHint) radarHint.innerHTML = '<i class="fas fa-check" style="font-size:.75rem;margin-right:3px;color:#4ade80"></i>';
    _vizPlusLoaded = true;
  } catch (e) {
    console.error('loadVizPlus:', e);
    if (statusTxt) statusTxt.textContent = t('obs_error', e.message);
    if (radarHint) radarHint.innerHTML = '';
    setTimeout(() => statusEl?.classList.add('hidden'), 3500);
  }
}

async function _buildRadarChart() {
  const phEl = document.getElementById('vizplus-radar-ph');
  const wrap = document.getElementById('vizplus-radar-wrap');

  let topArtists = APP.topArtistsData.length
    ? APP.topArtistsData.slice(0, 15)
    : (await API.call('user.getTopArtists', { period:'overall', limit:15 })).topartists?.artist || [];

  const TARGET_GENRES = ['rock','pop','electronic','hip-hop','metal','jazz','classical','indie','r&b','country'];
  const scores = {};
  TARGET_GENRES.forEach(g => { scores[g] = 0; });

  const tagResults = await Promise.allSettled(topArtists.map(a => API.call('artist.getTopTags', { artist:a.name })));
  const IGNORED    = new Set(['seen live','favorites','favourite','love','awesome','all','good','new','old']);

  tagResults.forEach((res, i) => {
    if (res.status !== 'fulfilled') return;
    const tags   = res.value.toptags?.tag || [];
    const weight = topArtists.length - i;
    tags.slice(0, 10).forEach(tag => {
      const name = (tag.name || '').toLowerCase().trim();
      for (const genre of TARGET_GENRES) {
        if (name.includes(genre) && !IGNORED.has(name)) scores[genre] += (parseInt(tag.count) || 30) * weight;
      }
    });
  });

  const labels = TARGET_GENRES.map(g => g.charAt(0).toUpperCase() + g.slice(1));
  const data   = TARGET_GENRES.map(g => scores[g]);

  if (data.every(v => v === 0)) {
    if (phEl) phEl.innerHTML = `<i class="fas fa-spider fa-2x"></i><p>${t('unavailable')}</p>`;
    return;
  }

  if (phEl) phEl.classList.add('hidden');
  if (wrap) wrap.classList.remove('hidden');

  destroyChart('chart-radar');
  const c = getThemeColors();
  APP.charts['chart-radar'] = new Chart(document.getElementById('chart-radar'), {
    type:'radar',
    data:{
      labels,
      datasets:[{ label:'Genres', data, backgroundColor:'rgba(99,102,241,.15)', borderColor:'#6366f1', pointBackgroundColor:CHART_PALETTE, pointBorderColor:'#fff', pointBorderWidth:2, pointRadius:5, borderWidth:2 }],
    },
    options:{
      responsive:true, maintainAspectRatio:false, animation:{ duration:800 },
      plugins:{ legend:{ display:false }, tooltip:{ callbacks:{ label:ctx => ` ${ctx.raw}` } } },
      scales:{ r:{ grid:{ color:c.grid }, ticks:{ color:c.text, font:{ size:10 }, backdropColor:'transparent' }, pointLabels:{ color:c.text, font:{ size:12 } }, beginAtZero:true } },
    },
  });

  await _buildSunburst();
}

async function _buildSunburst() {
  const phEl   = document.getElementById('vizplus-sunburst-ph');
  const wrapEl = document.getElementById('vizplus-sunburst-wrap');
  const svgEl  = document.getElementById('chart-sunburst');
  if (!svgEl) return;

  const artists = APP.topArtistsData.length
    ? APP.topArtistsData.slice(0, 20)
    : (await API.call('user.getTopArtists', { period:'overall', limit:20 })).topartists?.artist || [];

  const IGNORED  = new Set(['seen live','favorites','favourite','love','awesome','all','good','new','old','best','epic']);
  const genreMap = new Map();

  const tagResults = await Promise.allSettled(artists.map(a => API.call('artist.getTopTags', { artist:a.name })));
  tagResults.forEach((res, i) => {
    if (res.status !== 'fulfilled') return;
    const tags  = (res.value.toptags?.tag || []).slice(0, 4);
    const artist= artists[i];
    const plays = parseInt(artist.playcount || 1);
    tags.forEach(tag => {
      const g = (tag.name || '').toLowerCase().trim();
      if (!g || g.length < 2 || IGNORED.has(g)) return;
      if (!genreMap.has(g)) genreMap.set(g, new Map());
      const aMap = genreMap.get(g);
      aMap.set(artist.name, (aMap.get(artist.name) || 0) + plays);
    });
  });

  const topGenres = [...genreMap.entries()]
    .map(([g, aMap]) => ({ g, total:[...aMap.values()].reduce((a,b) => a+b, 0) }))
    .sort((a,b) => b.total - a.total).slice(0, 8).map(({ g }) => g);

  if (!topGenres.length) {
    if (phEl) { phEl.classList.remove('hidden'); const p = phEl.querySelector('p'); if (p) p.textContent = t('unavailable'); }
    return;
  }

  const rootData = {
    name: 'Genres',
    children: topGenres.map((genre, gi) => ({
      name: genre.charAt(0).toUpperCase() + genre.slice(1),
      color: CHART_PALETTE[gi % CHART_PALETTE.length],
      children: [...genreMap.get(genre).entries()].sort((a,b) => b[1]-a[1]).slice(0, 5).map(([artist, plays]) => ({ name:artist, value:plays })),
    })),
  };

  if (phEl)   phEl.classList.add('hidden');
  if (wrapEl) wrapEl.classList.remove('hidden');

  if (typeof d3 === 'undefined') return;

  const container = svgEl.parentElement;
  const size      = Math.min(container?.clientWidth || 500, 500);
  const radius    = size / 2;

  d3.select(svgEl).selectAll('*').remove();
  const svg = d3.select(svgEl).attr('width', size).attr('height', size);
  const g   = svg.append('g').attr('transform', `translate(${radius},${radius})`);

  const hierarchy = d3.hierarchy(rootData).sum(d => d.value || 0);
  const partition = d3.partition().size([2 * Math.PI, radius]);
  const root      = partition(hierarchy);

  const arc = d3.arc()
    .startAngle(d => d.x0).endAngle(d => d.x1)
    .innerRadius(d => d.y0).outerRadius(d => d.y1 - 2);

  const centerText = svg.append('text')
    .attr('text-anchor', 'middle').attr('dominant-baseline', 'middle')
    .attr('transform', `translate(${radius},${radius})`)
    .attr('fill', getThemeColors().text).attr('font-size', '11px').text('');

  g.selectAll('path')
    .data(root.descendants().filter(d => d.depth))
    .join('path')
    .attr('d', arc)
    .attr('fill', d => { let node = d; while (node.depth > 1) node = node.parent; return node.data.color || '#6366f1'; })
    .attr('opacity', d => 1 - d.depth * 0.15)
    .attr('stroke', '#1a1033').attr('stroke-width', 1)
    .style('cursor', 'pointer')
    .on('mouseover', (_, d) => { centerText.text(d.data.name); })
    .on('mouseout', () => { centerText.text(''); })
    .append('title').text(d => `${d.data.name}: ${formatNum(d.value)}`);
}

async function _buildTreemap() {
  const phEl = document.getElementById('vizplus-treemap-ph');
  const wrap = document.getElementById('vizplus-treemap-wrap');

  let artists = APP.topArtistsData;
  if (artists.length < 20) {
    const d = await API.call('user.getTopArtists', { period:'overall', limit:100 });
    artists = d.topartists?.artist || [];
    APP.topArtistsData = artists;
  }
  const top100 = artists.slice(0, 100);
  if (!top100.length) return;

  if (phEl) phEl.classList.add('hidden');
  if (wrap) wrap.classList.remove('hidden');

  const treeData = top100.map((a, i) => ({ label:a.name, value:parseInt(a.playcount) || 1, color:CHART_PALETTE[i % CHART_PALETTE.length] + 'cc' }));
  destroyChart('chart-treemap');
  APP.charts['chart-treemap'] = new Chart(document.getElementById('chart-treemap'), {
    type:'treemap',
    data:{ datasets:[{ tree:treeData, key:'value', labels:{ display:true, formatter:ctx => ctx.raw?.g?.label || '', color:'#fff', font:{ size:10 } }, backgroundColor:ctx => ctx.raw?.g?.color || '#6366f1cc', borderColor:'transparent', borderWidth:1, spacing:1 }] },
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ display:false }, tooltip:{ callbacks:{ label:ctx => ` ${ctx.raw?.g?.label}: ${formatNum(ctx.raw?.g?.value)}` } } } },
  });
}

async function _buildSankey() {
  const phEl = document.getElementById('vizplus-sankey-ph');
  const wrap = document.getElementById('vizplus-sankey-wrap');
  const svgEl= document.getElementById('chart-sankey');
  if (!svgEl) return;

  const history = APP.fullHistory;
  if (!history?.length) {
    if (phEl) { phEl.classList.remove('hidden'); const p = phEl.querySelector('p'); if (p) p.textContent = t('fetch_btn_refresh') + ' required'; }
    return;
  }

  const transitions = new Map();
  let prevArtist = '', prevTs = 0;

  for (const tr of history) {
    const ts     = parseInt(tr.date?.uts || 0);
    const artist = (tr.artist?.['#text'] || tr.artist?.name || '').trim();
    if (!artist || !ts) { prevArtist = artist; prevTs = ts; continue; }
    if (prevArtist && prevArtist !== artist && ts - prevTs < 3600) {
      const key = `${prevArtist}→${artist}`;
      transitions.set(key, (transitions.get(key) || 0) + 1);
    }
    prevArtist = artist; prevTs = ts;
  }

  const topLinks  = [...transitions.entries()].sort((a,b) => b[1]-a[1]).slice(0, 30);
  if (!topLinks.length) {
    if (phEl) { phEl.classList.remove('hidden'); const p = phEl.querySelector('p'); if (p) p.textContent = t('unavailable'); }
    if (wrap) wrap.classList.add('hidden');
    return;
  }

  const nodeNames = [...new Set(topLinks.flatMap(([k]) => k.split('→')))];
  const nodeIdx   = Object.fromEntries(nodeNames.map((n,i) => [n,i]));
  const nodes     = nodeNames.map(n => ({ name:n }));
  const links     = topLinks.map(([k,v]) => {
    const [src, tgt] = k.split('→');
    if (nodeIdx[src] === undefined || nodeIdx[tgt] === undefined) return null;
    return { source:nodeIdx[src], target:nodeIdx[tgt], value:v };
  }).filter(Boolean);

  const contSize  = Math.min(svgEl.parentElement?.clientWidth || 500, 500);

  if (typeof d3 === 'undefined' || typeof d3.sankey === 'undefined') {
    if (phEl) { phEl.classList.remove('hidden'); const p = phEl.querySelector('p'); if (p) p.textContent = 'D3 Sankey unavailable'; }
    return;
  }

  if (phEl) phEl.classList.add('hidden');
  if (wrap) wrap.classList.remove('hidden');

  d3.select(svgEl).selectAll('*').remove();
  const margin = { top:10, right:10, bottom:10, left:10 };
  const width  = contSize - margin.left - margin.right;
  const height = Math.min(contSize, 400) - margin.top - margin.bottom;

  const gEl = d3.select(svgEl)
    .attr('width', contSize).attr('height', Math.min(contSize, 400))
    .append('g').attr('transform', `translate(${margin.left},${margin.top})`);

  const sankey = d3.sankey().nodeWidth(15).nodePadding(10).size([width, height]);
  const graph  = sankey({ nodes:nodes.map(d => ({...d})), links:links.map(d => ({...d})) });

  gEl.append('g').selectAll('path').data(graph.links).join('path')
    .attr('d', d3.sankeyLinkHorizontal())
    .attr('stroke', (d,i) => CHART_PALETTE[i % CHART_PALETTE.length])
    .attr('stroke-width', d => Math.max(1, d.width))
    .attr('fill', 'none').attr('opacity', 0.45);

  gEl.append('g').selectAll('rect').data(graph.nodes).join('rect')
    .attr('x', d => d.x0).attr('y', d => d.y0)
    .attr('height', d => d.y1 - d.y0).attr('width', d => d.x1 - d.x0)
    .attr('fill', (_,i) => CHART_PALETTE[i % CHART_PALETTE.length])
    .append('title').text(d => d.name);

  gEl.append('g').selectAll('text').data(graph.nodes).join('text')
    .attr('x', d => d.x0 < width / 2 ? d.x1 + 6 : d.x0 - 6)
    .attr('y', d => (d.y1 + d.y0) / 2).attr('dy', '0.35em')
    .attr('text-anchor', d => d.x0 < width / 2 ? 'start' : 'end')
    .attr('font-size', '11px').attr('fill', getThemeColors().text)
    .text(d => d.name.length > 18 ? d.name.slice(0, 16) + '…' : d.name);
}

/* ============================================================
   MUSICAL PROFILE  — Évolution tags par mois (données réelles)
   FIX CRITIQUE : weekly charts par mois au lieu de global cache
   ============================================================ */
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

    // Récupération de la liste des charts hebdomadaires (pour accès aux données historiques)
    let weeklyChartList = null;
    try {
      const wclData    = await API.call('user.getWeeklyChartList', {});
      weeklyChartList  = wclData.weeklychartlist?.chart || [];
    } catch { weeklyChartList = []; }

    for (let mBack = MONTHS_BACK - 1; mBack >= 0; mBack--) {
      const targetDate  = new Date(now.getFullYear(), now.getMonth() - mBack, 1);
      const monthStart  = Math.floor(new Date(targetDate.getFullYear(), targetDate.getMonth(), 1).getTime() / 1000);
      const monthEnd    = Math.floor(new Date(targetDate.getFullYear(), targetDate.getMonth() + 1, 0, 23, 59, 59).getTime() / 1000);
      const monthIdx    = MONTHS_BACK - 1 - mBack; // index dans le tableau (0 = le plus ancien)

      labels.push(MONTHS_SHORT()[targetDate.getMonth()] + ' ' + targetDate.getFullYear().toString().slice(-2));

      // Stratégie : agréger les charts hebdomadaires couvrant ce mois
      let monthArtists = [];

      if (weeklyChartList.length) {
        // Trouver les semaines qui chevauchent ce mois
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

      // Fallback : user.getTopArtists avec la période rolling appropriée
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

      // Récupérer les tags de ces artistes
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

    // Sélection des top 5 tags sur l'ensemble de la période
    const tagTotals = Object.entries(tagData)
      .map(([tag, scores]) => ({ tag, total:scores.reduce((a,b) => a+b, 0) }))
      .sort((a,b) => b.total - a.total)
      .slice(0, TOP_TAGS_COUNT);

    if (!tagTotals.length) {
      if (phEl) { phEl.classList.remove('hidden'); phEl.querySelector('p').textContent = t('unavailable'); }
      if (statusHint) statusHint.innerHTML = '';
      return;
    }

    // ── Révéler le graphique ─────────────────────────────────
    if (phEl)  phEl.classList.add('hidden');
    if (wrapEl) { wrapEl.classList.remove('hidden'); wrapEl.style.display = ''; }

    // ── Légende externe ──────────────────────────────────────
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
          // FIX: légende visible pour identifier chaque tag
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

/* ============================================================
   OBSCURITY SCORE  — images + labels i18n
   ============================================================ */
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

/** Rendu des items d'obscurité — images lazies + labels i18n */
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

  // Lazy-load des images — délai plafonné
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

/* ============================================================
   BADGE ENGINE  — labels i18n complets
   ============================================================ */
const BadgeEngine = (() => {
  // FIX: tiers labels en i18n (plus d'anglais hardcodé)
  const TIERS = [
    { key:'bronze',  get label(){ return t('tier_bronze');  }, icon:'🥉', xp:10  },
    { key:'argent',  get label(){ return t('tier_argent');  }, icon:'🥈', xp:25  },
    { key:'or',      get label(){ return t('tier_or');      }, icon:'🥇', xp:50  },
    { key:'diamant', get label(){ return t('tier_diamant'); }, icon:'💎', xp:100 },
    { key:'elite',   get label(){ return t('tier_elite');   }, icon:'👑', xp:200 },
  ];

  const thresholds = (base, count = 5) => Array(count).fill(0).map((_,i) => Math.round(base * Math.pow(2, i)));

  const BADGE_DEFS = [
    { id:'night_owl',      cat:'noctambule', icon:'🦉', get name(){return t('badge_night_owl_name');},    get desc(){return t('badge_night_owl_desc');},   thresholds:thresholds(50),   compute:(hist) => hist.filter(tr => { const h = new Date(parseInt(tr.date?.uts||0)*1000).getHours(); return h>=0&&h<5; }).length },
    { id:'early_bird',     cat:'noctambule', icon:'🐦', get name(){return t('badge_early_bird_name');},   get desc(){return t('badge_early_bird_desc');},  thresholds:thresholds(30),   compute:(hist) => hist.filter(tr => { const h = new Date(parseInt(tr.date?.uts||0)*1000).getHours(); return h>=5&&h<8; }).length },
    { id:'weekend_warrior',cat:'noctambule', icon:'🎉', get name(){return t('badge_weekend_name');},      get desc(){return t('badge_weekend_desc');},     thresholds:thresholds(200),  compute:(hist) => hist.filter(tr => { const d = new Date(parseInt(tr.date?.uts||0)*1000).getDay(); return d===0||d===6; }).length },
    { id:'explorer',       cat:'exploration',icon:'🧭', get name(){return t('badge_explorer_name');},     get desc(){return t('badge_explorer_desc');},    thresholds:thresholds(50),   compute:(hist) => { if(!hist.length) return 0; const u=new Set(hist.map(tr=>(tr.artist?.['#text']||tr.artist?.name||'').toLowerCase())).size; return Math.round((u/hist.length)*1000); } },
    { id:'discoverer',     cat:'exploration',icon:'🔭', get name(){return t('badge_discoverer_name');},   get desc(){return t('badge_discoverer_desc');},  thresholds:thresholds(50),   compute:(hist) => new Set(hist.map(tr=>(tr.artist?.['#text']||tr.artist?.name||'').toLowerCase())).size },
    { id:'hidden_gems',    cat:'exploration',icon:'💎', get name(){return t('badge_hidden_gems_name');},  get desc(){return t('badge_hidden_gems_desc');}, thresholds:thresholds(10),   compute:(hist) => { const m=new Map(); hist.forEach(tr=>{const a=(tr.artist?.['#text']||tr.artist?.name||'').toLowerCase();if(a)m.set(a,(m.get(a)||0)+1);}); return [...m.values()].filter(v=>v<=2).length; } },
    { id:'loyal',          cat:'fidelite',   icon:'💖', get name(){return t('badge_loyal_name');},        get desc(){return t('badge_loyal_desc');},       thresholds:thresholds(20),   compute:(hist) => { if(!hist.length) return 0; const wm=new Map(); for(const tr of hist){const ts=parseInt(tr.date?.uts||0);if(!ts)continue;const d=new Date(ts*1000);const wk=`${d.getFullYear()}-W${Math.ceil((d.getDate()+6-(d.getDay()||7))/7)}`;const art=(tr.artist?.['#text']||tr.artist?.name||'').toLowerCase();const k=`${wk}::${art}`;wm.set(k,(wm.get(k)||0)+1);}return Math.max(0,...[...wm.values()]); } },
    { id:'obsessed',       cat:'fidelite',   icon:'🔁', get name(){return t('badge_obsessed_name');},     get desc(){return t('badge_obsessed_desc');},    thresholds:thresholds(10),   compute:(hist) => { const dm=new Map(); for(const tr of hist){const ts=parseInt(tr.date?.uts||0);if(!ts)continue;const d=new Date(ts*1000);const k=`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}::${(tr.artist?.['#text']||'').toLowerCase()}`;dm.set(k,(dm.get(k)||0)+1);} return Math.max(0,...[...dm.values()]); } },
    { id:'collector',      cat:'fidelite',   icon:'📀', get name(){return t('badge_collector_name');},    get desc(){return t('badge_collector_desc');},   thresholds:thresholds(20),   compute:(hist) => new Set(hist.map(tr=>{const alb=tr.album?.['#text']||'';const art=tr.artist?.['#text']||tr.artist?.name||'';return alb?`${art}::${alb}`.toLowerCase():null;}).filter(Boolean)).size },
    { id:'scrobbler',      cat:'volume',     icon:'🎵', get name(){return t('badge_scrobbler_name');},    get desc(){return t('badge_scrobbler_desc');},   thresholds:thresholds(1000), compute:(hist) => hist.length },
    { id:'binge',          cat:'volume',     icon:'🎧', get name(){return t('badge_binge_name');},        get desc(){return t('badge_binge_desc');},       thresholds:thresholds(50),   compute:(hist) => { const dm=new Map(); for(const tr of hist){const ts=parseInt(tr.date?.uts||0);if(!ts)continue;const d=new Date(ts*1000);const k=`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;dm.set(k,(dm.get(k)||0)+1);} return Math.max(0,...[...dm.values()]); } },
    { id:'marathon',       cat:'volume',     icon:'🏃', get name(){return t('badge_marathon_name');},     get desc(){return t('badge_marathon_desc');},    thresholds:thresholds(7),    compute:() => APP.streakData?.best || 0 },
    { id:'record_day',     cat:'volume',     icon:'📈', get name(){return t('badge_record_day_name');},   get desc(){return t('badge_record_day_desc');},  thresholds:thresholds(5),    compute:(hist) => { const dm=new Map(); for(const tr of hist){const ts=parseInt(tr.date?.uts||0);if(!ts)continue;const d=new Date(ts*1000);const k=`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;dm.set(k,(dm.get(k)||0)+1);}return [...dm.values()].filter(v=>v>=50).length; } },
    { id:'listen_time',    cat:'volume',     icon:'⏳', get name(){return t('badge_listen_time_name');},  get desc(){return t('badge_listen_time_desc');}, thresholds:thresholds(100),  compute:(hist) => Math.round(hist.length*3.5/60) },
    { id:'diversified',    cat:'diversite',  icon:'🌈', get name(){return t('badge_diversified_name');},  get desc(){return t('badge_diversified_desc');}, thresholds:thresholds(5),    compute:() => document.querySelectorAll('.mood-tag').length },
    { id:'genre_curious',  cat:'diversite',  icon:'🎭', get name(){return t('badge_genre_curious_name');}, get desc(){return t('badge_genre_curious_desc');}, thresholds:thresholds(6), compute:(hist) => new Set(hist.map(tr=>{const ts=parseInt(tr.date?.uts||0);if(!ts)return null;const d=new Date(ts*1000);return `${d.getFullYear()}-${d.getMonth()}`;}).filter(Boolean)).size },
    { id:'multilingual',   cat:'diversite',  icon:'🌍', get name(){return t('badge_multilingual_name');}, get desc(){return t('badge_multilingual_desc');}, thresholds:thresholds(5),   compute:(hist) => { const nl=/[^\u0000-\u007F\u00C0-\u024F]/;return new Set(hist.filter(tr=>{const a=tr.artist?.['#text']||tr.artist?.name||'';return nl.test(a);}).map(tr=>(tr.artist?.['#text']||tr.artist?.name||'').toLowerCase())).size; } },
    // ── Tempo (rythme d'écoute dans le temps) ──
    { id:'crescendo',      cat:'tempo',      icon:'📈', get name(){return t('badge_crescendo_name');},    get desc(){return t('badge_crescendo_desc');},   thresholds:thresholds(3),    compute:(hist) => { if(hist.length<2)return 0; const byMonth=new Map(); for(const tr of hist){const ts=parseInt(tr.date?.uts||0);if(!ts)continue;const d=new Date(ts*1000);const k=`${d.getFullYear()}-${String(d.getMonth()).padStart(2,'0')}`;byMonth.set(k,(byMonth.get(k)||0)+1);} const months=[...byMonth.entries()].sort((a,b)=>a[0]<b[0]?-1:1); let runs=0,streak=0; for(let i=1;i<months.length;i++){if(months[i][1]>months[i-1][1]){streak++;if(streak>=2)runs++;} else streak=0;} return runs; } },
    { id:'regular',        cat:'tempo',      icon:'📅', get name(){return t('badge_regular_name');},      get desc(){return t('badge_regular_desc');},     thresholds:thresholds(4),    compute:(hist) => { if(!hist.length)return 0; const days=new Set(hist.map(tr=>{const ts=parseInt(tr.date?.uts||0);if(!ts)return null;const d=new Date(ts*1000);return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;}).filter(Boolean)); return Math.round(days.size/Math.max(1,hist.length/50)); } },
    { id:'comeback',       cat:'tempo',      icon:'🔄', get name(){return t('badge_comeback_name');},     get desc(){return t('badge_comeback_desc');},    thresholds:thresholds(1),    compute:(hist) => { if(hist.length<2)return 0; let gaps=0; for(let i=1;i<hist.length;i++){const t1=parseInt(hist[i-1].date?.uts||0),t2=parseInt(hist[i].date?.uts||0);if(t1&&t2&&Math.abs(t1-t2)>30*86400)gaps++;} return gaps; } },
    // ── Social (partage & affinités) ──
    { id:'ambassador',     cat:'social',     icon:'📣', get name(){return t('badge_ambassador_name');},   get desc(){return t('badge_ambassador_desc');},  thresholds:thresholds(5),    compute:(hist) => { const am=new Map(); hist.forEach(tr=>{const a=(tr.artist?.['#text']||tr.artist?.name||'').toLowerCase();if(a)am.set(a,(am.get(a)||0)+1);}); return [...am.values()].filter(v=>v>=100).length; } },
    { id:'tastemaker',     cat:'social',     icon:'🎯', get name(){return t('badge_tastemaker_name');},   get desc(){return t('badge_tastemaker_desc');},  thresholds:thresholds(2),    compute:(hist) => { const am=new Map(); hist.forEach(tr=>{const a=(tr.artist?.['#text']||tr.artist?.name||'').toLowerCase();if(a)am.set(a,(am.get(a)||0)+1);}); const total=hist.length; return [...am.values()].filter(v=>v/total>0.1).length; } },
    { id:'nomad',          cat:'social',     icon:'✈️', get name(){return t('badge_nomad_name');},        get desc(){return t('badge_nomad_desc');},       thresholds:thresholds(5),    compute:(hist) => { const byMonth=new Map(); for(const tr of hist){const ts=parseInt(tr.date?.uts||0);if(!ts)continue;const d=new Date(ts*1000);const mk=`${d.getFullYear()}-${d.getMonth()}`;const ak=(tr.artist?.['#text']||tr.artist?.name||'').toLowerCase();if(!byMonth.has(mk))byMonth.set(mk,new Set());byMonth.get(mk).add(ak);} let months=0; byMonth.forEach(s=>{if(s.size>=10)months++;}); return months; } },
  ];

  function computeBadge(def, history) {
    const value = def.compute(history);
    let tierIdx = -1;
    for (let i = def.thresholds.length - 1; i >= 0; i--) {
      if (value >= def.thresholds[i]) { tierIdx = i; break; }
    }
    return {
      ...def, value, tierIdx,
      tier:          tierIdx >= 0 ? TIERS[tierIdx] : null,
      unlocked:      tierIdx >= 0,
      nextThreshold: tierIdx < def.thresholds.length - 1 ? def.thresholds[tierIdx + 1] : null,
    };
  }

  // FIX: level_titles — gère à la fois array et string csv
  function levelFromXP(xp) {
    let LEVEL_TITLES;
    const raw = I18N_DATA?.[window.I18N?.getLang?.() || 'fr']?.level_titles || I18N_DATA?.fr?.level_titles;
    if (Array.isArray(raw)) {
      LEVEL_TITLES = raw;
    } else if (typeof raw === 'string') {
      LEVEL_TITLES = raw.split(',').map(s => s.trim());
    } else {
      LEVEL_TITLES = ['Débutant','Mélomane','Scrobbleur','Curateur','Expert','Pro','Légende','Demi-Dieu'];
    }
    if (xp <= 0) return { level:1, xpCurr:0, xpNext:100, pct:0, title:LEVEL_TITLES[0] };
    const level    = Math.min(LEVEL_TITLES.length, Math.floor(Math.log2(xp/50+1))+1);
    const xpForLvl = Math.round(50*(Math.pow(2,level-1)-1));
    const xpForNxt = Math.round(50*(Math.pow(2,level)-1));
    const pct      = Math.min(100, Math.round(((xp-xpForLvl)/Math.max(1,xpForNxt-xpForLvl))*100));
    return { level, xpCurr:xp, xpNext:xpForNxt, pct, title:LEVEL_TITLES[level-1] || LEVEL_TITLES.at(-1) };
  }

  function compute() {
    const history = APP.fullHistory;
    if (!history?.length) {
      document.getElementById('badges-empty')?.classList.remove('hidden');
      document.getElementById('badges-container')?.classList.add('hidden');
      showToast(t('toast_badges_need_hist'), 'error');
      return;
    }
    document.getElementById('badges-empty')?.classList.add('hidden');
    const loadBtn = document.getElementById('badges-load-btn');
    if (loadBtn) loadBtn.innerHTML = t('badge_calc');

    const results = [];
    let i = 0;
    const processNext = () => {
      if (i >= BADGE_DEFS.length) {
        _render(results);
        saveBadgesToStorage(results);
        showToast(t('toast_badges_saved'));
        if (loadBtn) loadBtn.innerHTML = t('badge_recalc');
        return;
      }
      results.push(computeBadge(BADGE_DEFS[i], history));
      i++;
      setTimeout(processNext, 0);
    };
    processNext();
  }

  function _badgeCard(b) {
    const tierClass = b.unlocked ? `tier-${b.tier.key}` : 'tier-bronze';
    const tierLabel = b.unlocked ? `${b.tier.icon} ${b.tier.label}` : t('badge_locked');
    const nextInfo  = b.nextThreshold !== null ? `${b.value} / ${b.nextThreshold}` : b.unlocked ? t('badge_max') : '';
    const delay     = b.unlocked ? `animation-delay:${(b.tierIdx||0)*0.08}s` : '';
    return `
      <div class="${b.unlocked ? 'badge-card unlocked' : 'badge-card locked'}" style="${delay}" onclick="showBadgeModal('${b.id}')">
        <div class="badge-card-icon">${b.icon}</div>
        <div class="badge-card-name">${escHtml(b.name)}</div>
        <div class="badge-card-tier ${tierClass}">${tierLabel}</div>
        ${nextInfo ? `<div class="badge-card-progress">${nextInfo}</div>` : ''}
      </div>`;
  }

  function _render(results) {
    document.getElementById('badges-container')?.classList.remove('hidden');
    const totalXP  = results.reduce((acc, b) => acc + (b.unlocked ? TIERS[b.tierIdx].xp : 0), 0);
    const unlocked = results.filter(b => b.unlocked).length;
    const lvlData  = levelFromXP(totalXP);

    const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
    setText('bsc-level',   lvlData.level);
    setText('bsc-title',   lvlData.title);
    setText('bsc-xp-val',  `${totalXP} XP`);
    setText('bsc-unlocked',t('badge_unlocked_count', unlocked));
    setText('bsc-total',   t('badge_total', results.length));

    const xpFill = document.getElementById('bsc-xp-fill');
    if (xpFill) setTimeout(() => { xpFill.style.width = lvlData.pct + '%'; }, 200);

    const navBadge = document.getElementById('badges-count-badge');
    if (navBadge) {
      if (unlocked > 0) { navBadge.textContent = unlocked; navBadge.style.display = ''; }
      else navBadge.style.display = 'none';
    }

    ['noctambule','exploration','fidelite','volume','diversite','tempo','social'].forEach(cat => {
      const grid = document.getElementById(`badge-grid-${cat}`);
      if (!grid) return;
      grid.innerHTML = results.filter(b => b.cat === cat).map(b => _badgeCard(b)).join('');
    });

    window._badgeResults = results;
  }

  return { compute, BADGE_DEFS, TIERS, levelFromXP };
})();

/* ── Badge modal ─────────────────────────────────────────────── */
function showBadgeModal(badgeId) {
  const results = window._badgeResults || [];
  const b = results.find(r => r.id === badgeId);
  if (!b) return;

  const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
  setText('bm-icon',  b.icon);
  setText('bm-title', b.name);
  setText('bm-desc',  b.desc);

  const tierEl = document.getElementById('bm-tier');
  if (tierEl) {
    if (b.unlocked) { tierEl.className = `bm-tier badge-card-tier tier-${b.tier.key}`; tierEl.textContent = `${b.tier.icon} ${b.tier.label}`; }
    else            { tierEl.className = 'bm-tier'; tierEl.textContent = t('badge_locked'); }
  }

  const nextT  = b.nextThreshold !== null ? b.nextThreshold : b.thresholds.at(-1);
  const pct    = nextT > 0 ? Math.min(100, Math.round((b.value/nextT)*100)) : 100;
  const fillEl = document.getElementById('bm-progress-fill');
  if (fillEl) setTimeout(() => { fillEl.style.width = pct + '%'; }, 150);
  setText('bm-progress-cur',  `${b.value}`);
  setText('bm-progress-next', b.nextThreshold ? `${b.nextThreshold}` : t('badge_max'));

  const tiersRow = document.getElementById('bm-tiers-row');
  if (tiersRow) {
    tiersRow.innerHTML = b.thresholds.map((thresh, i) => {
      const tier     = BadgeEngine.TIERS[i];
      const achieved = b.value >= thresh;
      const isCurr   = b.unlocked && b.tierIdx === i;
      const cls      = isCurr ? 'bm-tier-chip current' : achieved ? 'bm-tier-chip achieved' : 'bm-tier-chip';
      return `<span class="${cls}" title="${tier.label}: ${thresh}">${tier.icon} ${thresh}</span>`;
    }).join('');
  }

  const shareBtn  = document.getElementById('bm-share-btn');
  const exportBtn = document.getElementById('bm-export-btn');
  if (shareBtn)  shareBtn.onclick  = () => shareBadgeAsImage(badgeId);
  if (exportBtn) exportBtn.onclick = () => exportBadgeAsImage(badgeId);

  document.getElementById('badge-modal')?.classList.remove('hidden');
}

function closeBadgeModal(e) {
  if (e && e.target !== document.getElementById('badge-modal')) return;
  document.getElementById('badge-modal')?.classList.add('hidden');
}

/* ── Badge persistence ───────────────────────────────────────── */
const BADGES_STORAGE_KEY = 'ls_badges_v2_';

function saveBadgesToStorage(results) {
  if (!APP.username) return;
  try {
    const compact = results.map(b => ({ id:b.id, value:b.value, tierIdx:b.tierIdx, unlocked:b.unlocked }));
    localStorage.setItem(BADGES_STORAGE_KEY + APP.username, JSON.stringify({ ts:Date.now(), badges:compact }));
  } catch (e) { console.warn('saveBadges:', e); }
}

function restoreBadgesFromStorage() {
  if (!APP.username) return;
  try {
    const raw = localStorage.getItem(BADGES_STORAGE_KEY + APP.username);
    if (!raw) return;
    const { badges, ts } = JSON.parse(raw);
    if (!Array.isArray(badges)) return;

    const unlocked = badges.filter(b => b.unlocked).length;

    const navBadge = document.getElementById('badges-count-badge');
    if (navBadge && unlocked > 0) { navBadge.textContent = String(unlocked); navBadge.style.display = ''; }

    const ageMs = Date.now() - (ts || 0);
    if (ageMs < 7 * 24 * 3600 * 1000) {
      const setText = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
      setText('bsc-unlocked', t('badge_unlocked_count', unlocked));
      setText('bsc-total',    t('badge_total', badges.length));

      const badgesSection = document.getElementById('s-badges');
      if (badgesSection) {
        const existing = document.getElementById('badge-persist-notice');
        if (!existing) {
          const notice       = document.createElement('p');
          notice.id          = 'badge-persist-notice';
          notice.className   = 'badge-persist-notice';
          const ageDays      = Math.round(ageMs / 86400000);
          notice.textContent = t('badge_restored', ageDays || 0);
          const emptyEl = document.getElementById('badges-empty');
          if (emptyEl) emptyEl.parentElement?.insertBefore(notice, emptyEl);
        }
      }

      const BADGE_DEFS = BadgeEngine.BADGE_DEFS;
      const TIERS      = BadgeEngine.TIERS;
      window._badgeResults = badges.map(saved => {
        const def = BADGE_DEFS.find(d => d.id === saved.id);
        if (!def) return null;
        return {
          ...def,
          value:     saved.value,
          tierIdx:   saved.tierIdx,
          unlocked:  saved.unlocked,
          tier:      saved.tierIdx >= 0 ? TIERS[saved.tierIdx] : null,
          nextThreshold: saved.tierIdx < (def.thresholds.length - 1) ? def.thresholds[saved.tierIdx + 1] : null,
        };
      }).filter(Boolean);

      if (window._badgeResults.length) {
        document.getElementById('badges-container')?.classList.remove('hidden');
        const totalXP = window._badgeResults.reduce((acc, b) => acc + (b.unlocked ? TIERS[b.tierIdx]?.xp || 0 : 0), 0);
        const lvlData = BadgeEngine.levelFromXP(totalXP);
        setText('bsc-level', lvlData.level);
        setText('bsc-title', lvlData.title);
        setText('bsc-xp-val', `${totalXP} XP`);
        const xpFill = document.getElementById('bsc-xp-fill');
        if (xpFill) setTimeout(() => { xpFill.style.width = lvlData.pct + '%'; }, 300);

        ['noctambule','exploration','fidelite','volume','diversite','tempo','social'].forEach(cat => {
          const grid = document.getElementById(`badge-grid-${cat}`);
          if (!grid) return;
          grid.innerHTML = window._badgeResults.filter(b => b.cat === cat).map(b => {
            const tierClass = b.unlocked ? `tier-${b.tier.key}` : 'tier-bronze';
            const tierLabel = b.unlocked ? `${b.tier.icon} ${b.tier.label}` : t('badge_locked');
            const nextInfo  = b.nextThreshold !== null ? `${b.value} / ${b.nextThreshold}` : b.unlocked ? t('badge_max') : '';
            return `<div class="${b.unlocked ? 'badge-card unlocked' : 'badge-card locked'}" onclick="showBadgeModal('${b.id}')">
              <div class="badge-card-icon">${b.icon}</div>
              <div class="badge-card-name">${escHtml(b.name)}</div>
              <div class="badge-card-tier ${tierClass}">${tierLabel}</div>
              ${nextInfo ? `<div class="badge-card-progress">${nextInfo}</div>` : ''}
            </div>`;
          }).join('');
        });
      }
    }
  } catch {}
}

/* ── Badge image export ─────────────────────────────────────── */
async function shareBadgeAsImage(badgeId) { await _captureBadgeAsImage(badgeId, 'share'); }
async function exportBadgeAsImage(badgeId) { await _captureBadgeAsImage(badgeId, 'download'); }

async function _captureBadgeAsImage(badgeId, mode) {
  const results = window._badgeResults || [];
  const b       = results.find(r => r.id === badgeId);
  if (!b) { showToast(t('toast_badge_not_found'), 'error'); return; }

  const cc = document.createElement('div');
  cc.style.cssText = 'position:fixed;left:-9999px;top:0;width:360px;height:360px;background:linear-gradient(135deg,#1a1033,#0f0a1e);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:32px;border-radius:24px;font-family:Inter,sans-serif;';
  const accentColor = b.tier?.key==='elite'?'#a78bfa':b.tier?.key==='diamant'?'#60a5fa':b.tier?.key==='or'?'#fbbf24':b.tier?.key==='argent'?'#94a3b8':'#cd7f32';
  const tierLabel   = b.unlocked&&b.tier ? `${b.tier.icon} ${b.tier.label}` : t('badge_locked');
  cc.innerHTML = `
    <div style="font-size:72px;line-height:1">${b.icon}</div>
    <div style="color:#fff;font-size:22px;font-weight:700;text-align:center">${escHtml(b.name)}</div>
    <div style="background:${accentColor}22;color:${accentColor};font-size:14px;font-weight:600;padding:6px 16px;border-radius:99px;border:1px solid ${accentColor}55">${tierLabel}</div>
    <div style="color:rgba(255,255,255,.55);font-size:12px;text-align:center;max-width:240px">${escHtml(b.desc)}</div>
    <div style="color:rgba(255,255,255,.35);font-size:11px;margin-top:12px">LastStats · last.fm</div>`;
  document.body.appendChild(cc);

  try {
    if (document.fonts?.ready) await document.fonts.ready;
    await sleep(120);
    const canvas = await html2canvas(cc, { scale:2, useCORS:true, allowTaint:true, backgroundColor:null, logging:false, width:360, height:360 });
    document.body.removeChild(cc);

    if (mode === 'share' && navigator.share && navigator.canShare) {
      canvas.toBlob(async blob => {
        if (!blob) { downloadCanvas(canvas, `badge-${b.id}.png`); return; }
        const file = new File([blob], `badge-${b.id}.png`, { type:'image/png' });
        try { await navigator.share({ title:b.name, text:`${b.name} — LastStats`, files:[file] }); }
        catch { downloadCanvas(canvas, `badge-${b.id}.png`); }
      }, 'image/png');
    } else {
      downloadCanvas(canvas, `badge-${b.id}.png`);
      showToast(t('toast_badge_downloaded'));
    }
  } catch (e) {
    if (document.body.contains(cc)) document.body.removeChild(cc);
    showToast(t('toast_badge_error', e.message), 'error');
  }
}

/* ============================================================
   SETTINGS
   ============================================================ */
function syncSettingsFields() {
  const uEl  = document.getElementById('settings-username');
  const aEl  = document.getElementById('settings-apikey');
  if (uEl) uEl.value = APP.username;
  if (aEl) aEl.value = APP.apiKey;

  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === APP.currentTheme));
  document.querySelectorAll('.acc-dot').forEach(b => b.classList.toggle('active', b.dataset.color === APP.currentAccent));
  document.querySelectorAll('.lang-btn').forEach(b => b.classList.toggle('active', b.dataset.lang === APP.language));
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

/* ============================================================
   EXPORT  (CSV / JSON)
   ============================================================ */
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

/* ============================================================
   ONE-HIT WONDERS TOOLTIP
   ============================================================ */
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

/* ============================================================
   PWA — Force Update
   ============================================================ */
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

/* ============================================================
   NEW YEAR WRAPPED NOTIFICATION
   ============================================================ */

/**
 * Demande la permission de notifications puis active l'alerte Wrapped.
 * Appelé par le bouton cloche dans les paramètres.
 */
async function requestNotificationAccess() {
  const btn = document.getElementById('btn-notif-wrapped');
  if (!('Notification' in window)) {
    showToast('Notifications not supported on this browser.', 'error');
    return;
  }

  const permission = await Notification.requestPermission();
  if (permission === 'granted') {
    showToast('🔔 Wrapped notification enabled!');
    setupNewYearNotification();
    _syncNotifBtn();
  } else {
    showToast('Notification permission denied.', 'error');
    _syncNotifBtn();
  }
}

/**
 * Met à jour l'état visuel du bouton cloche selon la permission actuelle.
 */
function _syncNotifBtn() {
  const btn = document.getElementById('btn-notif-wrapped');
  if (!btn) return;
  const perm = Notification?.permission;
  if (perm === 'granted') {
    btn.classList.add('active');
    btn.title = 'New Year Wrapped notification: ON';
    btn.querySelector('span').textContent = 'Notification enabled';
  } else if (perm === 'denied') {
    btn.classList.add('disabled');
    btn.title = 'Permission denied in browser settings';
    btn.querySelector('span').textContent = 'Permission denied';
  } else {
    btn.classList.remove('active', 'disabled');
    btn.querySelector('span').textContent = 'Enable Wrapped notification';
  }
}

/**
 * Planifie (ou déclenche immédiatement) la notification Wrapped du Nouvel An.
 * - Si on est avant le 1er janvier → setTimeout jusqu'à 00:01:00.
 * - Si on est après le 1er janvier et la notif n'a pas encore été envoyée → envoi immédiat.
 * Utilise localStorage 'ls_newyear_notif_{YEAR}' pour n'envoyer qu'une seule fois.
 */
function setupNewYearNotification() {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;

  const now        = new Date();
  const nextYear   = now.getFullYear() + (now.getMonth() >= 0 && now.getDate() >= 1 ? 1 : 0);
  // Wrapped de l'année écoulée (ex. Wrapped 2025 → notif le 1er jan 2026)
  const wrappedYear = nextYear - 1;
  const storageKey  = `ls_newyear_notif_${nextYear}`;

  // Déjà envoyé pour ce Nouvel An → ne rien faire
  if (localStorage.getItem(storageKey)) return;

  const fireNotif = () => {
    localStorage.setItem(storageKey, '1');
    _sendWrappedNotification(wrappedYear);
  };

  // Date cible : 1er janvier nextYear à 00:01:00
  const target = new Date(nextYear, 0, 1, 0, 1, 0);
  const msUntilNewYear = target - now;

  if (msUntilNewYear > 0) {
    // L'utilisateur est connecté avant minuit → on planifie
    setTimeout(fireNotif, msUntilNewYear);
  } else {
    // L'utilisateur ouvre l'app après le 1er janvier sans avoir encore reçu la notif
    fireNotif();
  }
}

/**
 * Envoie la notification via le Service Worker actif.
 */
function _sendWrappedNotification(wrappedYear) {
  const title = 'Happy New Year! 🎧';
  const body  = `Your ${wrappedYear} Music Wrapped is officially ready. Discover your top artists and tracks of the past year now!`;

  if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
    navigator.serviceWorker.controller.postMessage({
      type: 'SHOW_NOTIFICATION',
      title,
      body,
      tag: `laststats-wrapped-${wrappedYear}`,
    });
  } else {
    // Fallback : notification directe si pas de SW actif
    new Notification(title, {
      body,
      icon: './icons/icon-192.png',
    });
  }
}

/* ============================================================
   CLEAR CACHE
   ============================================================ */
function clearCache() {
  Cache.clear();
  _imgCache.clear();
  _trackImgCache.clear();
  _vizPlusLoaded = false;
  showToast(t('toast_cache_cleared'));
}
