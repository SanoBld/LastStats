/**
 * wrapped.js — LastStats · Wrapped v5
 * ─────────────────────────────────────────────────────────────────
 * v5 NOUVEAUTÉS :
 *  • SÉLECTEUR D'ANNÉE : choisir librement l'année (défaut : année passée)
 *  • WEEKLY CHART API : données exactes pour l'année calendaire sélectionnée
 *  • PODIUM TOP 10 : #1 centre (surélevé), #2 gauche, #3 droite + liste 4–10
 *  • ANIMATIONS PRO : spring overshoot sur podium, stagger, count-up plays
 *  • SCREENSHOT ROBUSTE : onclone complet (blobs, anim-rise, DNA, bars)
 *  • SHARE CARD FIX : fond solide, backdrop-filter supprimé dans le clone
 *  • CHAMPION SLIDE : count-up animé sur les plays
 *  • IMAGES ENRICHIES : artist.getTopAlbums + album.getInfo pour les podiums
 */

'use strict';

/* ═══════════════════════════════════════════════════════════════
   WRAPPED YEAR — mutable, défini par le sélecteur au démarrage
   ═══════════════════════════════════════════════════════════════ */
let WRAPPED_YEAR = new Date().getFullYear() - 1;

/* ═══════════════════════════════════════════════════════════════
   i18n
   ═══════════════════════════════════════════════════════════════ */
const TRANSLATIONS = {
  fr:{
    waitTitle:'Reviens le 31 décembre',waitSub:"Ton Wrapped annuel sera disponible dès le 31 décembre.",waitBack:'← Retour à LastStats',
    cdDays:'Jours',cdHours:'Heures',cdMins:'Min',cdSecs:'Sec',
    credTitle:"Votre Année\nen Musique",credDesc:'Connectez-vous pour générer votre Wrapped personnalisé.',
    lblUser:"Nom d'utilisateur Last.fm",lblKey:'Clé API',lblKeyGet:'Obtenir ↗',lblYear:'Année',
    lblRemember:'Se souvenir de moi',credSubmit:'Lancer mon Wrapped ✦',lblBack:'← Retour à LastStats',
    errNoUser:"Veuillez renseigner votre nom d'utilisateur.",errNoKey:'Clé API invalide (32 caractères).',
    loadStep0:'Connexion à Last.fm…',loadStep1:'Récupération du profil…',loadStep2:'Chargement des titres…',
    loadStep3:'Analyse des albums…',loadStep4:'Exploration des artistes…',loadStep5:'Découverte des genres…',
    loadStep6:'Calcul des statistiques…',loadStep7:'Chargement des images…',loadStep8:'Finalisation…',
    s1Year:'Votre Année en Musique',s1MemberSince:'Membre depuis',s1Scrobbles:'scrobbles',
    s2Eyebrow:'🏆 Titre Champion',s2Plays:'fois écouté',
    s3Header:'Top 10 Titres',s4Eyebrow:"⭐ Artiste de l'Année",s4Listened:'Vous avez écouté',s4Times:'fois',
    s5Header:'Top 10 Artistes',s6Header:'Top 10 Albums',
    s7Eyebrow:"⏱ Temps d'Écoute",s7Unit:'minutes',s7Hours:'heures estimées',s7Equiv1:'films de 2h',s7Equiv2:'jours non-stop',
    s8Header:'Vos Genres Musicaux',s9Eyebrow:'🧬 ADN Musical',
    s9TypeLabel:{extreme:'EXTRÊME',passionate:'PASSIONNÉ',regular:'RÉGULIER',casual:'CASUAL'},
    s9TypeDesc:{extreme:'La musique est votre mode de vie. Vous ne faites pas les choses à moitié.',passionate:'Vous vivez au rythme des notes. Un vrai mélomane.',regular:'La musique est votre fidèle compagnon du quotidien.',casual:'La musique ponctue vos moments, à votre rythme.'},
    s9AvgDay:'Scrobbles / jour',s9UniqueArtists:'Artistes',s9UniqueTracks:'Titres',s9ListenHours:'Heures',s9Badge:'Auditeur',
    sDiscEyebrow:'🔭 Loyauté vs Découverte',sDiscLoyal:'Fidélité absolue',sDiscNew:"Surprise de l'année",sDiscPlays:'écoutes',sDiscRank:'#',
    s10TopArtist:'Artiste',s10TopTrack:'Titre',s10TopAlbum:'Album',s10Period:'Année',
    s10SaveCard:'📸 Sauvegarder',s10BackDash:'← Retour au Dashboard',
    scrobbles:'scrobbles',hours:'heures',artists:'artistes',noData:'Données indisponibles.',
    screenshotOk:'✅ Enregistré !',screenshotFail:'⚠️ Erreur',screenshotGen:'⏳',
  },
  en:{
    waitTitle:'Come back on December 31st',waitSub:'Your annual Wrapped will be available from December 31st.',waitBack:'← Back to LastStats',
    cdDays:'Days',cdHours:'Hours',cdMins:'Min',cdSecs:'Sec',
    credTitle:'Your Year\nin Music',credDesc:'Log in to generate your personalised Wrapped.',
    lblUser:'Last.fm Username',lblKey:'API Key',lblKeyGet:'Get key ↗',lblYear:'Year',
    lblRemember:'Remember me',credSubmit:'Launch my Wrapped ✦',lblBack:'← Back to LastStats',
    errNoUser:'Please enter your username.',errNoKey:'Please enter a valid API key (32 chars).',
    loadStep0:'Connecting to Last.fm…',loadStep1:'Fetching profile…',loadStep2:'Loading tracks…',
    loadStep3:'Analysing albums…',loadStep4:'Exploring artists…',loadStep5:'Discovering genres…',
    loadStep6:'Computing stats…',loadStep7:'Loading images…',loadStep8:'Finishing…',
    s1Year:'Your Year in Music',s1MemberSince:'Member since',s1Scrobbles:'scrobbles',
    s2Eyebrow:'🏆 Track of the Year',s2Plays:'times played',
    s3Header:'Top 10 Tracks',s4Eyebrow:'⭐ Artist of the Year',s4Listened:'You listened to',s4Times:'times',
    s5Header:'Top 10 Artists',s6Header:'Top 10 Albums',
    s7Eyebrow:'⏱ Listening Time',s7Unit:'minutes',s7Hours:'estimated hours',s7Equiv1:'2h movies',s7Equiv2:'days non-stop',
    s8Header:'Your Music Genres',s9Eyebrow:'🧬 Musical DNA',
    s9TypeLabel:{extreme:'EXTREME',passionate:'PASSIONATE',regular:'REGULAR',casual:'CASUAL'},
    s9TypeDesc:{extreme:'Music is your lifestyle. You never do things by halves.',passionate:'You live to the beat of the music.',regular:'Music is your faithful daily companion.',casual:'Music punctuates your moments.'},
    s9AvgDay:'Scrobbles / day',s9UniqueArtists:'Artists',s9UniqueTracks:'Tracks',s9ListenHours:'Hours',s9Badge:'Listener',
    sDiscEyebrow:'🔭 Loyalty vs Discovery',sDiscLoyal:'Absolute loyalty',sDiscNew:"Year's surprise",sDiscPlays:'plays',sDiscRank:'#',
    s10TopArtist:'Artist',s10TopTrack:'Track',s10TopAlbum:'Album',s10Period:'Year',
    s10SaveCard:'📸 Save Card',s10BackDash:'← Back to Dashboard',
    scrobbles:'scrobbles',hours:'hours',artists:'artists',noData:'No data available.',
    screenshotOk:'✅ Saved!',screenshotFail:'⚠️ Error',screenshotGen:'⏳',
  },
  es:{
    waitTitle:'Vuelve el 31 de diciembre',waitSub:'Tu Wrapped anual estará disponible el 31 de diciembre.',waitBack:'← Volver',
    cdDays:'Días',cdHours:'Horas',cdMins:'Min',cdSecs:'Seg',
    credTitle:'Tu Año\nen Música',credDesc:'Inicia sesión para generar tu Wrapped.',
    lblUser:'Usuario Last.fm',lblKey:'Clave API',lblKeyGet:'Obtener ↗',lblYear:'Año',
    lblRemember:'Recordarme',credSubmit:'Lanzar Wrapped ✦',lblBack:'← Volver',
    errNoUser:'Introduce tu nombre.',errNoKey:'Clave API no válida.',
    loadStep0:'Conectando…',loadStep1:'Perfil…',loadStep2:'Canciones…',loadStep3:'Álbumes…',loadStep4:'Artistas…',loadStep5:'Géneros…',loadStep6:'Estadísticas…',loadStep7:'Imágenes…',loadStep8:'Finalizando…',
    s1Year:'Tu Año en Música',s1MemberSince:'Miembro desde',s1Scrobbles:'scrobbles',
    s2Eyebrow:'🏆 Canción del Año',s2Plays:'veces escuchada',
    s3Header:'Top 10 Canciones',s4Eyebrow:'⭐ Artista del Año',s4Listened:'Has escuchado',s4Times:'veces',
    s5Header:'Top 10 Artistas',s6Header:'Top 10 Álbumes',
    s7Eyebrow:'⏱ Tiempo de Escucha',s7Unit:'minutos',s7Hours:'horas estimadas',s7Equiv1:'películas 2h',s7Equiv2:'días seguidos',
    s8Header:'Tus Géneros',s9Eyebrow:'🧬 ADN Musical',
    s9TypeLabel:{extreme:'EXTREMO',passionate:'APASIONADO',regular:'REGULAR',casual:'CASUAL'},
    s9TypeDesc:{extreme:'La música es tu estilo.',passionate:'Vives al ritmo.',regular:'Tu compañera diaria.',casual:'A tu ritmo.'},
    s9AvgDay:'Scrobbles/día',s9UniqueArtists:'Artistas',s9UniqueTracks:'Canciones',s9ListenHours:'Horas',s9Badge:'Oyente',
    sDiscEyebrow:'🔭 Lealtad vs Descubrimiento',sDiscLoyal:'Lealtad absoluta',sDiscNew:'Sorpresa del año',sDiscPlays:'escuchas',sDiscRank:'#',
    s10TopArtist:'Artista',s10TopTrack:'Canción',s10TopAlbum:'Álbum',s10Period:'Año',
    s10SaveCard:'📸 Guardar',s10BackDash:'← Dashboard',
    scrobbles:'scrobbles',hours:'horas',artists:'artistas',noData:'Sin datos.',
    screenshotOk:'✅ ¡Guardado!',screenshotFail:'⚠️ Error',screenshotGen:'⏳',
  },
  de:{
    waitTitle:'Komm am 31. Dezember wieder',waitSub:'Dein Wrapped ist ab 31. Dezember verfügbar.',waitBack:'← Zurück',
    cdDays:'Tage',cdHours:'Std',cdMins:'Min',cdSecs:'Sek',
    credTitle:'Dein Jahr\nin Musik',credDesc:'Melde dich für dein Wrapped an.',
    lblUser:'Last.fm Benutzername',lblKey:'API-Schlüssel',lblKeyGet:'Holen ↗',lblYear:'Jahr',
    lblRemember:'Angemeldet bleiben',credSubmit:'Wrapped starten ✦',lblBack:'← Zurück',
    errNoUser:'Bitte Benutzernamen eingeben.',errNoKey:'Gültigen API-Schlüssel eingeben.',
    loadStep0:'Verbindung…',loadStep1:'Profil…',loadStep2:'Tracks…',loadStep3:'Alben…',loadStep4:'Künstler…',loadStep5:'Genres…',loadStep6:'Statistiken…',loadStep7:'Bilder…',loadStep8:'Abschluss…',
    s1Year:'Dein Musikjahr',s1MemberSince:'Mitglied seit',s1Scrobbles:'Scrobbles',
    s2Eyebrow:'🏆 Track des Jahres',s2Plays:'Mal gehört',
    s3Header:'Top 10 Tracks',s4Eyebrow:'⭐ Künstler des Jahres',s4Listened:'Gehört',s4Times:'Mal',
    s5Header:'Top 10 Künstler',s6Header:'Top 10 Alben',
    s7Eyebrow:'⏱ Hörzeit',s7Unit:'Minuten',s7Hours:'Stunden',s7Equiv1:'Filme',s7Equiv2:'Tage',
    s8Header:'Deine Genres',s9Eyebrow:'🧬 Musik-DNA',
    s9TypeLabel:{extreme:'EXTREM',passionate:'LEIDENSCHAFTLICH',regular:'REGELMÄSSIG',casual:'GELEGENTLICH'},
    s9TypeDesc:{extreme:'Musik ist dein Lebensstil.',passionate:'Du lebst im Takt.',regular:'Deine tägliche Begleiterin.',casual:'Musik zu deinem Tempo.'},
    s9AvgDay:'Scrobbles/Tag',s9UniqueArtists:'Künstler',s9UniqueTracks:'Tracks',s9ListenHours:'Stunden',s9Badge:'Hörer',
    sDiscEyebrow:'🔭 Treue vs Entdeckung',sDiscLoyal:'Absolute Treue',sDiscNew:'Jahresüberraschung',sDiscPlays:'Plays',sDiscRank:'#',
    s10TopArtist:'Künstler',s10TopTrack:'Track',s10TopAlbum:'Album',s10Period:'Jahr',
    s10SaveCard:'📸 Speichern',s10BackDash:'← Dashboard',
    scrobbles:'Scrobbles',hours:'Stunden',artists:'Künstler',noData:'Keine Daten.',
    screenshotOk:'✅ Gespeichert!',screenshotFail:'⚠️ Fehler',screenshotGen:'⏳',
  },
  pt:{
    waitTitle:'Volta no dia 31 de dezembro',waitSub:'O Wrapped estará disponível no dia 31 de dezembro.',waitBack:'← Voltar',
    cdDays:'Dias',cdHours:'Horas',cdMins:'Min',cdSecs:'Seg',
    credTitle:'O Seu Ano\nem Música',credDesc:'Faça login para gerar o seu Wrapped.',
    lblUser:'Utilizador Last.fm',lblKey:'Chave API',lblKeyGet:'Obter ↗',lblYear:'Ano',
    lblRemember:'Lembrar-me',credSubmit:'Lançar Wrapped ✦',lblBack:'← Voltar',
    errNoUser:'Insira o nome de utilizador.',errNoKey:'Chave API inválida.',
    loadStep0:'A ligar…',loadStep1:'Perfil…',loadStep2:'Músicas…',loadStep3:'Álbuns…',loadStep4:'Artistas…',loadStep5:'Géneros…',loadStep6:'Estatísticas…',loadStep7:'Imagens…',loadStep8:'A finalizar…',
    s1Year:'O Seu Ano em Música',s1MemberSince:'Membro desde',s1Scrobbles:'scrobbles',
    s2Eyebrow:'🏆 Música do Ano',s2Plays:'vezes ouvida',
    s3Header:'Top 10 Músicas',s4Eyebrow:'⭐ Artista do Ano',s4Listened:'Ouviu',s4Times:'vezes',
    s5Header:'Top 10 Artistas',s6Header:'Top 10 Álbuns',
    s7Eyebrow:'⏱ Tempo de Escuta',s7Unit:'minutos',s7Hours:'horas estimadas',s7Equiv1:'filmes 2h',s7Equiv2:'dias seguidos',
    s8Header:'Os Seus Géneros',s9Eyebrow:'🧬 ADN Musical',
    s9TypeLabel:{extreme:'EXTREMO',passionate:'APAIXONADO',regular:'REGULAR',casual:'CASUAL'},
    s9TypeDesc:{extreme:'A música é o seu estilo.',passionate:'Vive ao ritmo.',regular:'A sua companheira.',casual:'Ao seu ritmo.'},
    s9AvgDay:'Scrobbles/dia',s9UniqueArtists:'Artistas',s9UniqueTracks:'Músicas',s9ListenHours:'Horas',s9Badge:'Ouvinte',
    sDiscEyebrow:'🔭 Lealdade vs Descoberta',sDiscLoyal:'Lealdade total',sDiscNew:'Surpresa do ano',sDiscPlays:'ouv.',sDiscRank:'#',
    s10TopArtist:'Artista',s10TopTrack:'Música',s10TopAlbum:'Álbum',s10Period:'Ano',
    s10SaveCard:'📸 Guardar',s10BackDash:'← Dashboard',
    scrobbles:'scrobbles',hours:'horas',artists:'artistas',noData:'Sem dados.',
    screenshotOk:'✅ Guardado!',screenshotFail:'⚠️ Erro',screenshotGen:'⏳',
  },
  it:{
    waitTitle:'Torna il 31 dicembre',waitSub:'Il tuo Wrapped sarà disponibile dal 31 dicembre.',waitBack:'← Torna',
    cdDays:'Giorni',cdHours:'Ore',cdMins:'Min',cdSecs:'Sec',
    credTitle:'Il Tuo Anno\nin Musica',credDesc:'Accedi per generare il tuo Wrapped.',
    lblUser:'Utente Last.fm',lblKey:'Chiave API',lblKeyGet:'Ottieni ↗',lblYear:'Anno',
    lblRemember:'Ricordami',credSubmit:'Avvia Wrapped ✦',lblBack:'← Torna',
    errNoUser:'Inserisci il nome utente.',errNoKey:'Chiave API non valida.',
    loadStep0:'Connessione…',loadStep1:'Profilo…',loadStep2:'Brani…',loadStep3:'Album…',loadStep4:'Artisti…',loadStep5:'Generi…',loadStep6:'Statistiche…',loadStep7:'Immagini…',loadStep8:'Finalizzazione…',
    s1Year:'Il Tuo Anno in Musica',s1MemberSince:'Membro dal',s1Scrobbles:'scrobbles',
    s2Eyebrow:"🏆 Brano dell'Anno",s2Plays:'volte ascoltato',
    s3Header:'Top 10 Brani',s4Eyebrow:"⭐ Artista dell'Anno",s4Listened:'Hai ascoltato',s4Times:'volte',
    s5Header:'Top 10 Artisti',s6Header:'Top 10 Album',
    s7Eyebrow:"⏱ Tempo d'Ascolto",s7Unit:'minuti',s7Hours:'ore stimate',s7Equiv1:'film 2h',s7Equiv2:'giorni',
    s8Header:'I Tuoi Generi',s9Eyebrow:'🧬 DNA Musicale',
    s9TypeLabel:{extreme:'ESTREMO',passionate:'APPASSIONATO',regular:'REGOLARE',casual:'CASUAL'},
    s9TypeDesc:{extreme:'La musica è il tuo stile.',passionate:'Vivi al ritmo.',regular:'La tua compagna.',casual:'Al tuo ritmo.'},
    s9AvgDay:'Scrobbles/giorno',s9UniqueArtists:'Artisti',s9UniqueTracks:'Brani',s9ListenHours:'Ore',s9Badge:'Ascoltatore',
    sDiscEyebrow:'🔭 Fedeltà vs Scoperta',sDiscLoyal:'Fedeltà assoluta',sDiscNew:"Sorpresa dell'anno",sDiscPlays:'ascolti',sDiscRank:'#',
    s10TopArtist:'Artista',s10TopTrack:'Brano',s10TopAlbum:'Album',s10Period:'Anno',
    s10SaveCard:'📸 Salva',s10BackDash:'← Dashboard',
    scrobbles:'scrobbles',hours:'ore',artists:'artisti',noData:'Nessun dato.',
    screenshotOk:'✅ Salvato!',screenshotFail:'⚠️ Errore',screenshotGen:'⏳',
  },
  ja:{
    waitTitle:'12月31日にまた来てください',waitSub:'年次Wrappedは12月31日から利用できます。',waitBack:'← 戻る',
    cdDays:'日',cdHours:'時',cdMins:'分',cdSecs:'秒',
    credTitle:'音楽で振り返る\n一年',credDesc:'ログインしてWrappedを生成しましょう。',
    lblUser:'Last.fmユーザー名',lblKey:'APIキー',lblKeyGet:'取得 ↗',lblYear:'年',
    lblRemember:'保存する',credSubmit:'Wrapped開始 ✦',lblBack:'← 戻る',
    errNoUser:'ユーザー名を入力してください。',errNoKey:'有効なAPIキーを入力してください。',
    loadStep0:'接続中…',loadStep1:'プロフィール…',loadStep2:'曲…',loadStep3:'アルバム…',loadStep4:'アーティスト…',loadStep5:'ジャンル…',loadStep6:'統計…',loadStep7:'画像…',loadStep8:'仕上げ…',
    s1Year:'あなたの音楽の一年',s1MemberSince:'登録',s1Scrobbles:'スクロブル',
    s2Eyebrow:'🏆 今年の曲',s2Plays:'回再生',
    s3Header:'トップ10トラック',s4Eyebrow:'⭐ 今年のアーティスト',s4Listened:'',s4Times:'回聴きました',
    s5Header:'トップ10アーティスト',s6Header:'トップ10アルバム',
    s7Eyebrow:'⏱ リスニング時間',s7Unit:'分',s7Hours:'推定時間',s7Equiv1:'2時間映画',s7Equiv2:'連続日数',
    s8Header:'音楽ジャンル',s9Eyebrow:'🧬 音楽DNA',
    s9TypeLabel:{extreme:'エクストリーム',passionate:'パッション',regular:'レギュラー',casual:'カジュアル'},
    s9TypeDesc:{extreme:'音楽はあなたのライフスタイル。',passionate:'音楽と共に生きる。',regular:'音楽は毎日の友。',casual:'自分のペースで。'},
    s9AvgDay:'1日/スクロブル',s9UniqueArtists:'アーティスト',s9UniqueTracks:'トラック',s9ListenHours:'時間',s9Badge:'リスナー',
    sDiscEyebrow:'🔭 忠実 vs 発見',sDiscLoyal:'絶対的な忠実',sDiscNew:'今年の発見',sDiscPlays:'回',sDiscRank:'#',
    s10TopArtist:'アーティスト',s10TopTrack:'トラック',s10TopAlbum:'アルバム',s10Period:'年',
    s10SaveCard:'📸 保存',s10BackDash:'← ダッシュボード',
    scrobbles:'スクロブル',hours:'時間',artists:'アーティスト',noData:'データなし。',
    screenshotOk:'✅ 完了！',screenshotFail:'⚠️ エラー',screenshotGen:'⏳',
  },
  zh:{
    waitTitle:'请于12月31日回来',waitSub:'您的年度Wrapped将于12月31日起提供。',waitBack:'← 返回',
    cdDays:'天',cdHours:'时',cdMins:'分',cdSecs:'秒',
    credTitle:'您的音乐\n年度回顾',credDesc:'登录以生成您的专属Wrapped。',
    lblUser:'Last.fm用户名',lblKey:'API密钥',lblKeyGet:'获取 ↗',lblYear:'年份',
    lblRemember:'记住我',credSubmit:'启动Wrapped ✦',lblBack:'← 返回',
    errNoUser:'请输入用户名。',errNoKey:'请输入有效的API密钥。',
    loadStep0:'连接中…',loadStep1:'个人资料…',loadStep2:'曲目…',loadStep3:'专辑…',loadStep4:'艺术家…',loadStep5:'流派…',loadStep6:'统计…',loadStep7:'图片…',loadStep8:'完成…',
    s1Year:'您的音乐之年',s1MemberSince:'加入于',s1Scrobbles:'次播放',
    s2Eyebrow:'🏆 年度歌曲',s2Plays:'次播放',
    s3Header:'Top 10 曲目',s4Eyebrow:'⭐ 年度艺术家',s4Listened:'您收听了',s4Times:'次',
    s5Header:'Top 10 艺术家',s6Header:'Top 10 专辑',
    s7Eyebrow:'⏱ 收听时间',s7Unit:'分钟',s7Hours:'预计小时数',s7Equiv1:'2小时电影',s7Equiv2:'连续天数',
    s8Header:'音乐流派',s9Eyebrow:'🧬 音乐DNA',
    s9TypeLabel:{extreme:'极限',passionate:'热情',regular:'规律',casual:'休闲'},
    s9TypeDesc:{extreme:'音乐是您的生活方式。',passionate:'随音乐节拍而生。',regular:'音乐是您的日常。',casual:'按您的节奏。'},
    s9AvgDay:'每日播放',s9UniqueArtists:'艺术家',s9UniqueTracks:'曲目',s9ListenHours:'小时',s9Badge:'听众',
    sDiscEyebrow:'🔭 忠诚 vs 发现',sDiscLoyal:'绝对忠诚',sDiscNew:'年度惊喜',sDiscPlays:'次',sDiscRank:'#',
    s10TopArtist:'艺术家',s10TopTrack:'曲目',s10TopAlbum:'专辑',s10Period:'年',
    s10SaveCard:'📸 保存',s10BackDash:'← 仪表板',
    scrobbles:'次播放',hours:'小时',artists:'艺术家',noData:'无数据。',
    screenshotOk:'✅ 已保存！',screenshotFail:'⚠️ 错误',screenshotGen:'⏳',
  },
};

let LANG_CODE = 'fr';
let T = TRANSLATIONS.fr;

function setLang(code) {
  LANG_CODE = code;
  T = TRANSLATIONS[code] || TRANSLATIONS.fr;
  try{ localStorage.setItem('ls_lang',code); }catch{}
  document.querySelectorAll('.lang-btn').forEach(b=>b.classList.toggle('active',b.dataset.lang===code));
  applyLangToDOM();
}
function applyLangToDOM() {
  const s=(id,t)=>{const e=document.getElementById(id);if(e)e.textContent=t;};
  s('wait-title',T.waitTitle); s('wait-sub',T.waitSub); s('wait-back',T.waitBack);
  s('cd-days-lbl',T.cdDays); s('cd-hours-lbl',T.cdHours); s('cd-mins-lbl',T.cdMins); s('cd-secs-lbl',T.cdSecs);
  const te=document.getElementById('cred-title');
  if(te)te.innerHTML=T.credTitle.replace('\n','<br>');
  s('cred-desc',T.credDesc); s('lbl-user',T.lblUser);
  const kg=document.getElementById('lbl-key-get'); if(kg)kg.textContent=T.lblKeyGet;
  s('lbl-year',T.lblYear);
  s('lbl-remember',T.lblRemember); s('cred-submit-txt',T.credSubmit); s('lbl-back',T.lblBack);
}
function autoDetectLang() {
  const n=(navigator.language||'fr').slice(0,2).toLowerCase();
  return Object.keys(TRANSLATIONS).includes(n)?n:'fr';
}

/* ═══════════════════════════════════════════════════════════════
   AVAILABILITY & COUNTDOWN (31 Décembre + Janvier)
   ═══════════════════════════════════════════════════════════════ */

/**
 * Disponible le 31 décembre ET janvier.
 */
function isWrappedAvailable() {
  const now = new Date();
  const month = now.getMonth(); // 0 = Janvier, 11 = Décembre
  const day = now.getDate();

  return (month === 0) || (month === 11 && day === 31);
}

/**
 * Cible le 31 Décembre de l'année en cours à 00:00:00.
 * Si la date est passée, cible le 31 Décembre de l'année suivante.
 */
function getNextDec31() {
  const now = new Date();
  let target = new Date(now.getFullYear(), 11, 31, 0, 0, 0);

  if (now > target && now.getMonth() !== 0) {
    target.setFullYear(now.getFullYear() + 1);
  }
  return target;
}

let _cdInterval = null;

function startCountdown() {
  if (_cdInterval) clearInterval(_cdInterval);

  const target = getNextDec31();
  
  const tick = () => {
    const diff = Math.max(0, target - Date.now());
    const pad = n => String(n).padStart(2, '0');
    const s = (id, v) => { 
      const e = document.getElementById(id); 
      if (e) e.textContent = v; 
    };

    if (diff <= 0) {
      clearInterval(_cdInterval);
      location.reload(); 
      return;
    }

    s('cd-days',  Math.floor(diff / 86400000));
    s('cd-hours', pad(Math.floor((diff % 86400000) / 3600000)));
    s('cd-mins',  pad(Math.floor((diff % 3600000) / 60000)));
    s('cd-secs',  pad(Math.floor((diff % 60000) / 1000)));
  };

  tick();
  _cdInterval = setInterval(tick, 1000);
}

/* ═══════════════════════════════════════════════════════════════
   UTILITIES
   ═══════════════════════════════════════════════════════════════ */
const DEF_HASH='2a96cbd8b46e442fc41c2b86b821562f';
const fmtNum=n=>new Intl.NumberFormat(LANG_CODE==='en'?'en-US':LANG_CODE==='de'?'de-DE':'fr-FR').format(parseInt(n)||0);
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');

function getImg(arr,...sizes){
  if(!Array.isArray(arr))return'';
  const order=sizes.length?sizes:['extralarge','large','medium','small'];
  for(const size of order){
    const item=arr.find(i=>i.size===size)||(size===arr[0]?.size?arr[0]:null);
    const url=item?.['#text']||'';
    if(url&&url.length>10&&!url.includes(DEF_HASH))return url;
  }
  return'';
}
function animCount(el,target,ms=2200){
  if(!el||!target)return;
  const start=performance.now();
  const tick=now=>{
    const p=Math.min((now-start)/ms,1);
    el.textContent=fmtNum(Math.round(target*(1-Math.pow(1-p,4))));
    if(p<1)requestAnimationFrame(tick);else el.textContent=fmtNum(target);
  };
  requestAnimationFrame(tick);
}
function avatarColor(str){
  const C=['#7c3aed','#2563eb','#059669','#d97706','#db2777','#0891b2','#4f46e5','#dc2626','#0d9488','#9333ea'];
  let h=0;for(let i=0;i<str.length;i++)h=((h<<5)-h)+str.charCodeAt(i);
  return C[Math.abs(h)%C.length];
}
function initialsPlaceholder(label,size=80){
  const txt=(label||'?').trim().toUpperCase();
  const words=txt.split(/\s+/);
  const initials=words.length>=2?words[0][0]+words[words.length-1][0]:txt.slice(0,2);
  const color=avatarColor(txt);
  const fs=Math.round(size*.38);
  return`data:image/svg+xml,${encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
      <rect width="${size}" height="${size}" fill="${color}55"/>
      <text x="50%" y="50%" dy=".35em" fill="white" font-size="${fs}"
            font-family="Arial,Helvetica,sans-serif" font-weight="800"
            text-anchor="middle" letter-spacing="-1">${initials}</text>
    </svg>`
  )}`;
}
function imgOrInitials(imgUrl,label,style=''){
  const src=imgUrl||initialsPlaceholder(label);
  return`<img src="${esc(src)}" alt="${esc(label)}" crossorigin="anonymous" style="width:100%;height:100%;object-fit:cover;display:block;${style}">`;
}

/* ═══════════════════════════════════════════════════════════════
   LAST.FM API
   ═══════════════════════════════════════════════════════════════ */
const LASTFM={
  BASE:'https://ws.audioscrobbler.com/2.0/',
  async call(method,params={}){
    const url=new URL(this.BASE);
    url.searchParams.set('method',method);
    url.searchParams.set('api_key',STORE.apiKey);
    url.searchParams.set('format','json');
    if(method.startsWith('user.'))url.searchParams.set('user',STORE.username);
    Object.entries(params).forEach(([k,v])=>{if(v!=null)url.searchParams.set(k,v);});
    const res=await fetch(url.toString());
    if(!res.ok)throw new Error(`HTTP ${res.status}`);
    const data=await res.json();
    if(data.error)throw new Error(`Last.fm: ${data.message} (${data.error})`);
    return data;
  }
};

/* ═══════════════════════════════════════════════════════════════
   DATA STORE
   ═══════════════════════════════════════════════════════════════ */
const STORE={
  username:'',apiKey:'',
  user:null,tracks:[],albums:[],artists:[],tags:[],
  artist1Img:'',_uniqueArtists:0,_uniqueTracks:0,annualPlays:0,
  get displayName(){return this.user?.name||this.username||'—';},
  get regYear(){const ts=parseInt(this.user?.registered?.unixtime||0);return ts?new Date(ts*1000).getFullYear():null;},
  get avatar(){return getImg(this.user?.image||[],'extralarge','large','medium');},
  get artist1(){return this.artists[0]||null;},
  get listenMins(){return Math.round(this.annualPlays*3.5);},
  get listenHours(){return Math.round(this.listenMins/60);},
  get avgPerDay(){return Math.round(this.annualPlays/365*10)/10;},
  get listenerType(){const a=this.avgPerDay;if(a>=30)return'extreme';if(a>=15)return'passionate';if(a>=5)return'regular';return'casual';}
};

/* ═══════════════════════════════════════════════════════════════
   DATA LOADING
   Stratégie : Weekly Chart API pour données exactes par année
   calendaire + enrichissement images en parallèle
   ═══════════════════════════════════════════════════════════════ */
const STOP_TAGS=new Set(['seen live','loved','favorites','favourite','all','good','best','cool','favorite','mellow','under 2000 listeners','american','british','female','male','singer-songwriter','albums i own','beautiful','catchy','sexy','awesome','chill','epic','amazing','great','love','top','nice','<br>','favourite music','american music','british music','canadian','french','german','japanese']);

async function loadAllData(onProgress){
  const p=(msg,pct)=>onProgress?.(msg,pct);
  p(T.loadStep0,5);

  // Bornes de l'année calendaire sélectionnée (timestamps UNIX)
  const from=Math.floor(new Date(WRAPPED_YEAR,0,1,0,0,0).getTime()/1000);
  const to  =Math.floor(new Date(WRAPPED_YEAR,11,31,23,59,59).getTime()/1000);

  p(T.loadStep1,10);

  // Round 1 : profil + weekly charts (parallèle)
  const [userRes,tracksRes,albumsRes,artistsRes]=await Promise.all([
    LASTFM.call('user.getInfo'),
    LASTFM.call('user.getWeeklyTrackChart', {from,to}).catch(()=>null),
    LASTFM.call('user.getWeeklyAlbumChart', {from,to}).catch(()=>null),
    LASTFM.call('user.getWeeklyArtistChart',{from,to}).catch(()=>null),
  ]);
  p(T.loadStep6,52);

  STORE.user=userRes.user;

  // Normaliser le champ artist (#text → name) pour les tracks/albums weekly
  const normArtist=a=>({name:a?.['#text']||a?.name||''});

  STORE.tracks=(tracksRes?.weeklytrackchart?.track||[]).slice(0,50).map(t=>({
    name:t.name||'—',artist:normArtist(t.artist),playcount:t.playcount||0,image:[],mbid:t.mbid||'',
  }));
  STORE.albums=(albumsRes?.weeklyalbumchart?.album||[]).slice(0,20).map(a=>({
    name:a.name||'—',artist:normArtist(a.artist),playcount:a.playcount||0,image:[],mbid:a.mbid||'',
  }));
  STORE.artists=(artistsRes?.weeklyartistchart?.artist||[]).slice(0,20).map(a=>({
    name:a.name||'—',playcount:a.playcount||0,image:[],mbid:a.mbid||'',_img:'',
  }));
  STORE._uniqueArtists=STORE.artists.length;
  STORE._uniqueTracks=STORE.tracks.length;

  STORE.annualPlays=STORE.artists.reduce((s,a)=>s+parseInt(a.playcount||0),0);
  if(!STORE.annualPlays)STORE.annualPlays=STORE.tracks.reduce((s,t)=>s+parseInt(t.playcount||0),0);

  p(T.loadStep5,62);

  // Round 2 : genres + images (parallèle)
  const top3Art  =STORE.artists.slice(0,3);
  const top5Alb  =STORE.albums.slice(0,5);

  const enrichJobs=[
    // Tags genres via top 3 artistes
    ...top3Art.map(a=>LASTFM.call('artist.getTopTags',{artist:a.name,autocorrect:1}).catch(()=>null)),
    // Images albums via album.getInfo (top 5)
    ...top5Alb.map(a=>LASTFM.call('album.getInfo',{artist:a.artist?.name||'',album:a.name,autocorrect:1}).catch(()=>null)),
    // Images artistes via artist.getTopAlbums (top 3)
    ...top3Art.map(a=>LASTFM.call('artist.getTopAlbums',{artist:a.name,limit:3,autocorrect:1}).catch(()=>null)),
  ];
  p(T.loadStep7,78);
  const results=await Promise.all(enrichJobs);

  // Assign tags
  const seenT=new Set(),merged=[];
  for(let i=0;i<3;i++){
    for(const t of(results[i]?.toptags?.tag||[])){
      const n=(t.name||'').toLowerCase().trim();
      if(n&&!STOP_TAGS.has(n)&&n.length<=28&&!/^\d/.test(n)&&!seenT.has(n)){seenT.add(n);merged.push(t.name);}
    }
  }
  STORE.tags=merged.slice(0,8);

  // Assign album images
  for(let i=0;i<top5Alb.length;i++){
    const res=results[3+i];
    if(res?.album?.image){
      const img=getImg(res.album.image,'extralarge','large','medium');
      if(img&&STORE.albums[i])STORE.albums[i].image=res.album.image;
    }
  }

  // Assign artist images
  for(let i=0;i<top3Art.length;i++){
    const res=results[3+top5Alb.length+i];
    for(const alb of(res?.topalbums?.album||[])){
      const img=getImg(alb.image,'extralarge','large');
      if(img){STORE.artists[i]._img=img;if(i===0)STORE.artist1Img=img;break;}
    }
  }

  p(T.loadStep8,100);
}

/* ═══════════════════════════════════════════════════════════════
   AMBIENT BACKGROUNDS
   ═══════════════════════════════════════════════════════════════ */
const AMBIENTS={
  purple:'radial-gradient(ellipse 80% 60% at 20% 30%,#3b0764 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 70%,#1e1b4b 0%,transparent 65%),#060610',
  gold:'radial-gradient(ellipse 80% 60% at 15% 30%,#451a03 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 70%,#1c1005 0%,transparent 65%),#060610',
  blue:'radial-gradient(ellipse 80% 60% at 15% 25%,#1e3a8a 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 70%,#1e1b4b 0%,transparent 65%),#060610',
  green:'radial-gradient(ellipse 80% 60% at 20% 35%,#064e3b 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 70% 65%,#0d4a38 0%,transparent 65%),#060610',
  pink:'radial-gradient(ellipse 80% 60% at 20% 30%,#500724 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 70%,#4a044e 0%,transparent 65%),#060610',
  orange:'radial-gradient(ellipse 80% 60% at 18% 28%,#431407 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 74% 66%,#3b0a0a 0%,transparent 65%),#060610',
  violet:'radial-gradient(ellipse 80% 60% at 18% 28%,#2e1065 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 74% 66%,#4c1d95 0%,transparent 65%),#060610',
  teal:'radial-gradient(ellipse 80% 60% at 18% 28%,#0c4a6e 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 74% 68%,#134e4a 0%,transparent 65%),#060610',
  summary:'radial-gradient(ellipse 80% 60% at 20% 20%,#3b0764 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 75%,#451a03 0%,transparent 65%),radial-gradient(ellipse 50% 50% at 50% 50%,#3b0a3b 0%,transparent 65%),#060610',
};
function setAmbient(theme){const e=document.getElementById('ambient');if(e)e.style.background=AMBIENTS[theme]||AMBIENTS.purple;}

/* ═══════════════════════════════════════════════════════════════
   SLIDE BUILDERS
   ═══════════════════════════════════════════════════════════════ */
function avatarHtml(){
  const n=STORE.displayName,src=STORE.avatar||initialsPlaceholder(n,90);
  return`<img src="${esc(src)}" alt="" crossorigin="anonymous" style="width:100%;height:100%;object-fit:cover;display:block;">`;
}

/* ── SLIDE 1 — INTRO ── */
function buildIntro(){
  const name=esc(STORE.displayName);
  const since=STORE.regYear?`${T.s1MemberSince} ${STORE.regYear}`:'';
  const plays=STORE.annualPlays?`${fmtNum(STORE.annualPlays)} ${T.s1Scrobbles}`:'';
  const pills=[since,plays].filter(Boolean).map(p=>`<span class="pill">${p}</span>`).join('');
  return`
    <div class="slide-bg">
      <div class="blob" style="--c:#7c3aed;--x:18%;--y:32%;--s:60vmax;--dur:10s;--op:.35"></div>
      <div class="blob" style="--c:#4338ca;--x:72%;--y:65%;--s:50vmax;--dur:13s;--dl:-4s;--op:.25"></div>
      <div class="blob" style="--c:#a21caf;--x:52%;--y:16%;--s:42vmax;--dur:8s;--dl:-7s;--op:.2"></div>
    </div>
    <div class="slide-content s-intro">
      <div class="intro-logo anim-rise">LastStats</div>
      <div class="intro-av anim-pop" style="animation-delay:.1s">${avatarHtml()}</div>
      <h1 class="intro-name anim-rise" style="animation-delay:.25s">${name}</h1>
      <div class="intro-sub anim-rise" style="animation-delay:.4s">${pills}</div>
      <p class="intro-year anim-rise" style="animation-delay:.56s">${T.s1Year} · ${WRAPPED_YEAR}</p>
    </div>`;
}

/* ── SLIDE 2 — CHAMPION ── */
function buildChampion(){
  const t1=STORE.tracks[0];if(!t1)return buildFallback();
  const nm=esc(t1.name||'—'),ar=esc(t1.artist?.name||t1.artist||'');
  const img=getImg(t1.image||[],'extralarge','large','medium');
  return`
    <div class="slide-bg">
      <div class="blob" style="--c:#b45309;--x:20%;--y:30%;--s:60vmax;--dur:11s;--op:.38"></div>
      <div class="blob" style="--c:#7c2d12;--x:74%;--y:64%;--s:50vmax;--dur:9s;--dl:-5s;--op:.28"></div>
    </div>
    <div class="slide-content s-champion">
      <div class="champ-eyebrow anim-rise">${T.s2Eyebrow}</div>
      <div class="champ-cover anim-pop" style="animation-delay:.12s">${imgOrInitials(img,t1.name||ar)}</div>
      <h1 class="champ-track anim-rise" style="animation-delay:.26s">${nm}</h1>
      <div class="champ-artist anim-rise" style="animation-delay:.38s">${ar}</div>
      <div class="champ-count anim-rise" style="animation-delay:.5s" id="champ-count">🎧 0 ${T.s2Plays}</div>
    </div>`;
}

/* ── PODIUM BUILDER (shared between tracks / artists / albums) ──
   top3  = [{name,sub,img,plays,rawPlays}]  indices 0=1er,1=2e,2=3e
   rest7 = [{name,sub,img,plays}]           indices 3–9
   cfg   = {header, idBase, circle, slideClass, blobs}
*/
function buildPodium(top3,rest7,cfg){
  const {header,idBase,circle,slideClass,blobs}=cfg;
  const r=circle?'50%':'10px';
  // Ordre visuel : 2e gauche · 1er centre (surélevé) · 3e droite
  const visuOrder=[1,0,2];
  const slotCls=['pod-first','pod-second','pod-third'];

  const podHtml=visuOrder.map(di=>{
    const item=top3[di];if(!item)return'';
    const rank=di+1;
    return`
      <div class="pod-slot ${slotCls[di]}" id="pod-${idBase}-${di}">
        ${rank===1?'<div class="pod-crown">👑</div>':''}
        <div class="pod-img${rank===1?' pod-img-lg':' pod-img-sm'}" style="border-radius:${r}">
          ${imgOrInitials(item.img,item.name)}
        </div>
        <div class="pod-meta">
          <div class="pod-name">${esc(item.name)}</div>
          ${item.sub?`<div class="pod-sub">${esc(item.sub)}</div>`:''}
          <div class="pod-plays" id="pod-plays-${idBase}-${di}">${item.plays}</div>
        </div>
        <div class="pod-base pod-base-${rank}"><span class="pod-base-num">${rank}</span></div>
      </div>`;
  }).join('');

  const restHtml=rest7.map((item,i)=>`
    <div class="pod-rest-item" id="pod-rest-${idBase}-${i}">
      <span class="pod-rest-rank">${i+4}</span>
      <div class="pod-rest-img" style="border-radius:${circle?'50%':'5px'}">${imgOrInitials(item.img,item.name)}</div>
      <div class="pod-rest-info">
        <div class="pod-rest-name">${esc(item.name)}</div>
        ${item.sub?`<div class="pod-rest-sub">${esc(item.sub)}</div>`:''}
      </div>
      <div class="pod-rest-plays">${item.plays}</div>
    </div>`).join('');

  return`
    <div class="slide-bg">${blobs}</div>
    <div class="slide-content ${slideClass}">
      <div class="top10-header anim-rise">${header}</div>
      <div class="podium-wrap">${podHtml}</div>
      <div class="pod-rest">${restHtml}</div>
    </div>`;
}

/* ── SLIDE 3 — TOP 10 TRACKS ── */
function buildTop10Tracks(){
  const tracks=STORE.tracks.slice(0,10);if(!tracks.length)return buildFallback();
  const mk=t=>({name:t.name||'—',sub:t.artist?.name||t.artist||'',img:getImg(t.image||[],'medium','small'),plays:fmtNum(t.playcount),rawPlays:parseInt(t.playcount||0)});
  return buildPodium(tracks.slice(0,3).map(mk),tracks.slice(3,10).map(mk),{
    header:T.s3Header,idBase:'trk',circle:false,slideClass:'s-top10',
    blobs:`<div class="blob" style="--c:#2563eb;--x:15%;--y:28%;--s:55vmax;--dur:11s;--op:.3"></div><div class="blob" style="--c:#4f46e5;--x:76%;--y:68%;--s:48vmax;--dur:9s;--dl:-5s;--op:.22"></div>`,
  });
}

/* ── SLIDE 4 — ARTISTE ── */
function buildArtist(){
  if(!STORE.artist1)return buildFallback();
  const nm=esc(STORE.artist1.name);
  const bg=STORE.artist1Img?`style="--art-bg:url('${esc(STORE.artist1Img)}')"` :'';
  const ph=STORE.artist1Img?'<div class="art-photo-bg"></div>':'';
  return`
    <div class="slide-bg artist-bg" ${bg}>
      ${ph}
      <div class="blob" style="--c:#d97706;--x:16%;--y:28%;--s:50vmax;--dur:11s;--op:.35"></div>
      <div class="blob" style="--c:#b45309;--x:76%;--y:68%;--s:45vmax;--dur:9s;--dl:-5s;--op:.22"></div>
    </div>
    <div class="slide-content s-artist">
      <div class="art-eyebrow anim-rise">${T.s4Eyebrow}</div>
      <div class="art-img-wrap anim-pop" style="animation-delay:.14s">${imgOrInitials(STORE.artist1Img,STORE.artist1.name)}</div>
      <h1 class="art-name anim-rise" style="animation-delay:.26s">${nm}</h1>
      <div class="art-plays-label anim-rise" style="animation-delay:.36s">${T.s4Listened}</div>
      <span class="art-plays-num anim-pop" id="art-count" style="animation-delay:.44s">0</span>
      <div class="art-plays-label anim-rise" style="animation-delay:.52s">${T.s4Times}</div>
      <div class="art-bar anim-rise" style="animation-delay:.62s"><div class="art-bar-fill" id="art-bar-fill"></div></div>
    </div>`;
}

/* ── SLIDE 5 — TOP 10 ARTISTS ── */
function buildTop10Artists(){
  const artists=STORE.artists.slice(0,10);if(!artists.length)return buildFallback();
  const mk=a=>({name:a.name||'—',sub:'',img:a._img||getImg(a.image||[],'large','medium'),plays:fmtNum(a.playcount),rawPlays:parseInt(a.playcount||0)});
  return buildPodium(artists.slice(0,3).map(mk),artists.slice(3,10).map(mk),{
    header:T.s5Header,idBase:'art',circle:true,slideClass:'s-top10',
    blobs:`<div class="blob" style="--c:#7c3aed;--x:20%;--y:32%;--s:52vmax;--dur:10s;--op:.3"></div><div class="blob" style="--c:#ec4899;--x:72%;--y:62%;--s:46vmax;--dur:12s;--dl:-4s;--op:.22"></div>`,
  });
}

/* ── SLIDE 6 — TOP 10 ALBUMS ── */
function buildTop10Albums(){
  const albums=STORE.albums.slice(0,10);if(!albums.length)return buildFallback();
  const mk=a=>({name:a.name||'—',sub:a.artist?.name||a.artist||'',img:getImg(a.image||[],'extralarge','large','medium'),plays:fmtNum(a.playcount),rawPlays:parseInt(a.playcount||0)});
  return buildPodium(albums.slice(0,3).map(mk),albums.slice(3,10).map(mk),{
    header:T.s6Header,idBase:'alb',circle:false,slideClass:'s-top10',
    blobs:`<div class="blob" style="--c:#059669;--x:18%;--y:30%;--s:55vmax;--dur:10s;--op:.28"></div><div class="blob" style="--c:#0d9488;--x:72%;--y:62%;--s:48vmax;--dur:13s;--dl:-5s;--op:.22"></div>`,
  });
}

/* ── SLIDE 7 — TEMPS ── */
function buildTimeVerdict(){
  const mins=STORE.listenMins,hours=STORE.listenHours,films=Math.round(mins/120),days=Math.round(mins/1440);
  return`
    <div class="slide-bg">
      <div class="blob" style="--c:#a16207;--x:18%;--y:32%;--s:58vmax;--dur:11s;--op:.32"></div>
      <div class="blob" style="--c:#b45309;--x:74%;--y:62%;--s:52vmax;--dur:9s;--dl:-5s;--op:.24"></div>
    </div>
    <div class="slide-content s-time">
      <div class="time-eyebrow anim-rise">${T.s7Eyebrow}</div>
      <div class="time-counter-wrap anim-pop" style="animation-delay:.16s">
        <span class="time-counter" id="time-counter">0</span>
        <span class="time-unit-lbl">${T.s7Unit}</span>
      </div>
      <div class="time-hours-sub anim-rise" style="animation-delay:.28s">≈ ${fmtNum(hours)} ${T.s7Hours}</div>
      <div class="time-equiv anim-rise" style="animation-delay:.42s">
        ${films>0?`<div class="time-equiv-pill">🎬 ${fmtNum(films)} ${T.s7Equiv1}</div>`:''}
        ${days>0?`<div class="time-equiv-pill">🔥 ${days} ${T.s7Equiv2}</div>`:''}
      </div>
    </div>`;
}

/* ── SLIDE 8 — GENRES ── */
function buildGenres(){
  const COLORS=['#f43f5e','#a855f7','#3b82f6','#10b981','#f59e0b','#ec4899','#06b6d4','#8b5cf6'];
  if(!STORE.tags.length)return`
    <div class="slide-bg"><div class="blob" style="--c:#db2777;--x:18%;--y:28%;--s:55vmax;--dur:10s;--op:.28"></div></div>
    <div class="slide-content s-genres"><div class="genres-header anim-rise">${T.s8Header}</div><p class="genres-no-data anim-rise" style="animation-delay:.2s">No genre tags found.</p></div>`;
  const top5=STORE.tags.slice(0,5);
  const bars=top5.map((tag,i)=>`
    <div class="genre-bar-row" id="gbar-${i}">
      <span class="genre-bar-rank">${i+1}</span>
      <span class="genre-bar-label">${esc(tag)}</span>
      <div class="genre-bar-track"><div class="genre-bar-fill" id="gbar-fill-${i}" style="--gc:${COLORS[i%COLORS.length]};"></div></div>
    </div>`).join('');
  const extra=STORE.tags.slice(5).map((tag,i)=>`<span class="genre-pill-sm" style="--gc:${COLORS[(i+5)%COLORS.length]}">${esc(tag)}</span>`).join('');
  return`
    <div class="slide-bg">
      <div class="blob" style="--c:#db2777;--x:18%;--y:28%;--s:55vmax;--dur:10s;--op:.28"></div>
      <div class="blob" style="--c:#9333ea;--x:74%;--y:64%;--s:50vmax;--dur:12s;--dl:-5s;--op:.22"></div>
    </div>
    <div class="slide-content s-genres">
      <div class="genres-header anim-rise">${T.s8Header}</div>
      <div class="genre-bars">${bars}</div>
      ${extra?`<div class="genre-cloud-small anim-rise" style="animation-delay:.8s">${extra}</div>`:''}
    </div>`;
}

/* ── SLIDE 9 — ADN MUSICAL ── */
function buildMusicalDNA(){
  const type=STORE.listenerType,lbl=T.s9TypeLabel[type]||type.toUpperCase(),desc=T.s9TypeDesc[type]||'';
  const typeOrder=['casual','regular','passionate','extreme'];
  const typeIdx=Math.max(0,typeOrder.indexOf(type));
  const spectrumPct=[10,38,65,90][typeIdx];
  return`
    <div class="slide-bg">
      <div class="blob" style="--c:#581c87;--x:18%;--y:28%;--s:56vmax;--dur:10s;--op:.35"></div>
      <div class="blob" style="--c:#7c3aed;--x:72%;--y:64%;--s:50vmax;--dur:12s;--dl:-4s;--op:.25"></div>
    </div>
    <div class="slide-content s-dna">
      <div class="dna-eyebrow anim-rise">${T.s9Eyebrow}</div>
      <div class="dna-type anim-pop" style="animation-delay:.16s">${lbl}</div>
      <p class="dna-type-sub anim-rise" style="animation-delay:.28s">${esc(desc)}</p>
      <div class="dna-spectrum anim-rise" style="animation-delay:.38s">
        <div class="dna-spectrum-track">
          <div class="dna-spectrum-fill" id="dna-spec-fill" data-pct="${spectrumPct}"></div>
          <div class="dna-spectrum-dot" id="dna-spec-dot"></div>
        </div>
        <div class="dna-spectrum-lbls">
          ${typeOrder.map(t=>`<span class="dna-spectrum-lbl${t===type?' active':''}">${T.s9TypeLabel[t]}</span>`).join('')}
        </div>
      </div>
      <div class="dna-stats anim-rise" style="animation-delay:.5s">
        <div class="dna-stat"><div class="dna-stat-icon">📅</div><div class="dna-stat-val" id="dna-avgday">—</div><div class="dna-stat-lbl">${T.s9AvgDay}</div></div>
        <div class="dna-stat"><div class="dna-stat-icon">🎤</div><div class="dna-stat-val">${fmtNum(STORE._uniqueArtists||STORE.artists.length)}</div><div class="dna-stat-lbl">${T.s9UniqueArtists}</div></div>
        <div class="dna-stat"><div class="dna-stat-icon">🎵</div><div class="dna-stat-val">${fmtNum(STORE._uniqueTracks||STORE.tracks.length)}</div><div class="dna-stat-lbl">${T.s9UniqueTracks}</div></div>
        <div class="dna-stat"><div class="dna-stat-icon">⏱</div><div class="dna-stat-val">${fmtNum(STORE.listenHours)}h</div><div class="dna-stat-lbl">${T.s9ListenHours}</div></div>
      </div>
      <div class="dna-badge anim-rise" style="animation-delay:.65s">✦ ${esc(T.s9Badge)} ${esc(lbl)} ✦</div>
    </div>`;
}

/* ── SLIDE 10 — LOYAUTÉ VS DÉCOUVERTE ── */
function buildDiscovery(){
  const artists=STORE.artists;if(artists.length<2)return buildFallback();
  const loyal=artists[0],disc=artists[Math.min(9,artists.length-1)];
  const loyalImg=STORE.artist1Img||loyal._img||'';
  const discImg=disc._img||'';
  return`
    <div class="slide-bg">
      <div class="blob" style="--c:#0c4a6e;--x:18%;--y:28%;--s:55vmax;--dur:11s;--op:.32"></div>
      <div class="blob" style="--c:#4f46e5;--x:74%;--y:64%;--s:50vmax;--dur:9s;--dl:-5s;--op:.24"></div>
    </div>
    <div class="slide-content s-discovery">
      <div class="disc-eyebrow anim-rise">${T.sDiscEyebrow}</div>
      <div class="disc-versus anim-rise" style="animation-delay:.14s">
        <div class="disc-card anim-pop" style="animation-delay:.2s">
          <div class="disc-photo">${imgOrInitials(loyalImg,loyal.name)}</div>
          <div class="disc-tag">${T.sDiscLoyal}</div>
          <div class="disc-name">${esc(loyal.name)}</div>
          <div class="disc-plays">${fmtNum(loyal.playcount)} ${T.sDiscPlays}</div>
          <div class="disc-rank-badge">${T.sDiscRank}1</div>
        </div>
        <div class="disc-vs">VS</div>
        <div class="disc-card anim-pop" style="animation-delay:.34s">
          <div class="disc-photo">${imgOrInitials(discImg,disc.name)}</div>
          <div class="disc-tag">${T.sDiscNew}</div>
          <div class="disc-name">${esc(disc.name)}</div>
          <div class="disc-plays">${fmtNum(disc.playcount)} ${T.sDiscPlays}</div>
          <div class="disc-rank-badge">${T.sDiscRank}${artists.indexOf(disc)+1}</div>
        </div>
      </div>
    </div>`;
}

/* ── SLIDE 11 — RÉSUMÉ FINAL ── */
function buildSummary(){
  const uname=esc(STORE.displayName),art1=esc(STORE.artists[0]?.name||'—'),trk1=esc(STORE.tracks[0]?.name||'—'),alb1=esc(STORE.albums[0]?.name||'—');
  const uArt=STORE._uniqueArtists||STORE.artists.length;
  const avSrc=STORE.avatar||initialsPlaceholder(STORE.displayName,44);
  return`
    <div class="slide-bg">
      <div class="blob" style="--c:#f59e0b;--x:18%;--y:22%;--s:50vmax;--dur:11s;--op:.25"></div>
      <div class="blob" style="--c:#7c3aed;--x:74%;--y:68%;--s:50vmax;--dur:9s;--dl:-5s;--op:.25"></div>
    </div>
    <div class="slide-content s-summary">
      <div id="share-card" class="summary-poster anim-rise">
        <div class="sum-header">
          <div class="sum-av"><img src="${esc(avSrc)}" alt="" crossorigin="anonymous" style="width:100%;height:100%;object-fit:cover;border-radius:50%;"></div>
          <div><div class="sum-uname">${uname}</div><div class="sum-brand">LastStats · ${WRAPPED_YEAR}</div></div>
        </div>
        <div class="sum-divider"></div>
        <div class="sum-stats">
          <div class="sum-stat"><div class="sum-stat-val">${fmtNum(STORE.annualPlays)}</div><div class="sum-stat-lbl">${T.scrobbles}</div></div>
          <div class="sum-stat"><div class="sum-stat-val">${fmtNum(STORE.listenHours)}h</div><div class="sum-stat-lbl">${T.hours}</div></div>
          <div class="sum-stat"><div class="sum-stat-val">${fmtNum(uArt)}</div><div class="sum-stat-lbl">${T.artists}</div></div>
        </div>
        <div class="sum-top">
          <div class="sum-row"><div class="sum-icon">🎤</div><div><div class="sum-row-lbl">${T.s10TopArtist}</div><div class="sum-row-val">${art1}</div></div></div>
          <div class="sum-row"><div class="sum-icon">🎵</div><div><div class="sum-row-lbl">${T.s10TopTrack}</div><div class="sum-row-val">${trk1}</div></div></div>
          <div class="sum-row"><div class="sum-icon">💿</div><div><div class="sum-row-lbl">${T.s10TopAlbum}</div><div class="sum-row-val">${alb1}</div></div></div>
        </div>
        <div class="sum-divider"></div>
        <div class="sum-period">${T.s10Period} ${WRAPPED_YEAR} · laststats</div>
      </div>
      <div class="sum-footer-row anim-rise" style="animation-delay:.32s">
        <button class="sum-share-btn" id="sum-share-btn" onclick="Stories.shareCard()">${T.s10SaveCard}</button>
        <a href="index.html" class="sum-back-btn">${T.s10BackDash}</a>
      </div>
    </div>`;
}

function buildFallback(msg){
  return`
    <div class="slide-bg"><div class="blob" style="--c:#7c3aed;--x:50%;--y:50%;--s:60vmax;--dur:10s;--op:.28"></div></div>
    <div class="slide-content s-nodata">
      <div class="nd-icon">🎵</div>
      <div class="nd-title anim-rise">Oups…</div>
      <p class="nd-sub anim-rise" style="animation-delay:.2s">${esc(msg||T.noData)}</p>
    </div>`;
}

/* ═══════════════════════════════════════════════════════════════
   SLIDE MANIFEST
   ═══════════════════════════════════════════════════════════════ */
const SLIDES=[
  {id:'intro',       theme:'purple', duration:5500,    build:buildIntro},
  {id:'champion',    theme:'gold',   duration:7000,    build:buildChampion},
  {id:'top10tracks', theme:'blue',   duration:12000,   build:buildTop10Tracks},
  {id:'artist',      theme:'gold',   duration:7000,    build:buildArtist},
  {id:'top10artists',theme:'purple', duration:10000,   build:buildTop10Artists},
  {id:'top10albums', theme:'green',  duration:10000,   build:buildTop10Albums},
  {id:'time',        theme:'orange', duration:7000,    build:buildTimeVerdict},
  {id:'genres',      theme:'pink',   duration:8000,    build:buildGenres},
  {id:'dna',         theme:'violet', duration:8000,    build:buildMusicalDNA},
  {id:'discovery',   theme:'teal',   duration:8000,    build:buildDiscovery},
  {id:'summary',     theme:'summary',duration:Infinity,build:buildSummary},
];

/* ═══════════════════════════════════════════════════════════════
   STORIES ENGINE
   ═══════════════════════════════════════════════════════════════ */
const Stories={
  current:0,_timer:null,_paused:false,_slideStart:0,_pauseStart:0,_totalPauseMs:0,

  init(){
    const container=document.getElementById('slides-container'),bars=document.getElementById('progress-bars');
    container.innerHTML='';bars.innerHTML='';
    SLIDES.forEach((sl,i)=>{
      const div=document.createElement('div');
      div.className='slide';div.id=`slide-${sl.id}`;div.innerHTML=sl.build();container.appendChild(div);
      const seg=document.createElement('div');seg.className='prog-seg';seg.id=`prog-${i}`;
      seg.innerHTML='<div class="prog-fill"></div>';bars.appendChild(seg);
    });
    this.go(0);
  },

  go(idx){
    if(idx<0||idx>=SLIDES.length)return;
    clearTimeout(this._timer);
    const keepPaused=this._paused;
    this._slideStart=Date.now();this._totalPauseMs=0;this._paused=false;

    const prev=document.querySelector('.slide.active');
    if(prev){prev.classList.remove('active');prev.classList.add('exit');setTimeout(()=>prev.classList.remove('exit'),550);}

    this.current=idx;
    const sl=SLIDES[idx],slideEl=document.getElementById(`slide-${sl.id}`);
    setAmbient(sl.theme);
    requestAnimationFrame(()=>requestAnimationFrame(()=>slideEl.classList.add('active')));
    this._updateBars(idx,sl.duration);
    this._onEnter(sl.id);

    if(isFinite(sl.duration)){
      if(keepPaused){
        this._paused=true;this._pauseStart=Date.now();
        requestAnimationFrame(()=>{
          const fill=document.querySelector(`#prog-${idx} .prog-fill`);
          if(fill)fill.style.animationPlayState='paused';
          document.getElementById('stories')?.classList.add('paused');
          const btn=document.getElementById('pause-btn');if(btn){btn.textContent='▶';btn.classList.add('is-paused');}
        });
      } else {
        const btn=document.getElementById('pause-btn');if(btn){btn.textContent='⏸';btn.classList.remove('is-paused');}
        document.getElementById('stories')?.classList.remove('paused');
        this._timer=setTimeout(()=>this.go(idx+1),sl.duration);
      }
    } else {
      const btn=document.getElementById('pause-btn');if(btn){btn.textContent='⏸';btn.classList.remove('is-paused');}
      document.getElementById('stories')?.classList.remove('paused');
    }
  },

  next(){if(this.current<SLIDES.length-1)this.go(this.current+1);},
  prev(){this.go(Math.max(0,this.current-1));},

  pause(){
    if(this._paused||!isFinite(SLIDES[this.current].duration))return;
    this._paused=true;this._pauseStart=Date.now();clearTimeout(this._timer);
    const fill=document.querySelector(`#prog-${this.current} .prog-fill`);if(fill)fill.style.animationPlayState='paused';
    document.getElementById('stories')?.classList.add('paused');
    const btn=document.getElementById('pause-btn');if(btn){btn.textContent='▶';btn.classList.add('is-paused');}
  },
  resume(){
    if(!this._paused)return;
    this._totalPauseMs+=Date.now()-this._pauseStart;this._paused=false;
    const fill=document.querySelector(`#prog-${this.current} .prog-fill`);if(fill)fill.style.animationPlayState='running';
    document.getElementById('stories')?.classList.remove('paused');
    const btn=document.getElementById('pause-btn');if(btn){btn.textContent='⏸';btn.classList.remove('is-paused');}
    const sl=SLIDES[this.current];
    if(isFinite(sl.duration)){const rem=Math.max(0,sl.duration-(Date.now()-this._slideStart-this._totalPauseMs));this._timer=setTimeout(()=>this.go(this.current+1),rem);}
  },
  togglePause(){this._paused?this.resume():this.pause();},

  _updateBars(active,duration){
    SLIDES.forEach((_,i)=>{
      const seg=document.getElementById(`prog-${i}`);if(!seg)return;
      const fill=seg.querySelector('.prog-fill');
      fill.style.animation='none';fill.getBoundingClientRect();
      if(i<active){fill.style.width='100%';fill.style.animation='';}
      else if(i===active&&isFinite(duration)){fill.style.width='0%';fill.style.animation=`progFill ${duration}ms linear forwards`;}
      else{fill.style.width='0%';fill.style.animation='';}
    });
  },

  /* ── Animations par slide ── */
  _onEnter(id){
    /* Podium : spring sur les 3 slots + stagger slide-in sur les 7 autres */
    const animPodium=(base,raw3)=>{
      // Ordre DOM : 2e gauche (index 1), 1er centre (index 0), 3e droite (index 2)
      [1,0,2].forEach((dataIdx,domPos)=>{
        const el=document.getElementById(`pod-${base}-${dataIdx}`);if(!el)return;
        el.style.cssText+='opacity:0;transform:translateY(32px) scale(.8);transition:none;';
        const delay=180+domPos*180;
        setTimeout(()=>{
          el.style.transition='opacity .55s ease,transform .6s cubic-bezier(.34,1.56,.64,1)';
          el.style.opacity='1';el.style.transform='translateY(0) scale(1)';
          // Count-up plays
          const pe=document.getElementById(`pod-plays-${base}-${dataIdx}`);
          const target=raw3?.[dataIdx]||0;
          if(pe&&target>0){
            const s=performance.now(),d=900;
            const tick=now=>{const p=Math.min((now-s)/d,1);pe.textContent=fmtNum(Math.round(target*(1-Math.pow(1-p,3))));if(p<1)requestAnimationFrame(tick);else pe.textContent=fmtNum(target);};
            requestAnimationFrame(tick);
          }
        },delay);
      });
      // Liste 4–10 : slide depuis la gauche
      for(let i=0;i<7;i++){
        const el=document.getElementById(`pod-rest-${base}-${i}`);if(!el)continue;
        el.style.cssText+='opacity:0;transform:translateX(-20px);transition:none;';
        setTimeout(()=>{
          el.style.transition='opacity .38s ease,transform .4s cubic-bezier(.22,1,.36,1)';
          el.style.opacity='1';el.style.transform='translateX(0)';
        },780+i*70);
      }
    };

    switch(id){
      case'champion':
        setTimeout(()=>{
          const el=document.getElementById('champ-count'),t=parseInt(STORE.tracks[0]?.playcount||0);
          if(el&&t>0){const s=performance.now(),d=1800;const tick=now=>{const p=Math.min((now-s)/d,1);el.textContent=`🎧 ${fmtNum(Math.round(t*(1-Math.pow(1-p,4))))} ${T.s2Plays}`;if(p<1)requestAnimationFrame(tick);else el.textContent=`🎧 ${fmtNum(t)} ${T.s2Plays}`;};requestAnimationFrame(tick);}
        },700);
        break;
      case'top10tracks':
        animPodium('trk',STORE.tracks.slice(0,3).map(t=>parseInt(t.playcount||0)));break;
      case'artist':
        setTimeout(()=>{
          animCount(document.getElementById('art-count'),parseInt(STORE.artist1?.playcount||0),2200);
          const bar=document.getElementById('art-bar-fill');if(bar)bar.style.width='100%';
        },700);
        break;
      case'top10artists':
        animPodium('art',STORE.artists.slice(0,3).map(a=>parseInt(a.playcount||0)));break;
      case'top10albums':
        animPodium('alb',STORE.albums.slice(0,3).map(a=>parseInt(a.playcount||0)));break;
      case'time':
        setTimeout(()=>animCount(document.getElementById('time-counter'),STORE.listenMins,2800),500);break;
      case'genres':
        STORE.tags.slice(0,5).forEach((_,i)=>{
          const row=document.getElementById(`gbar-${i}`);
          if(row){row.style.opacity='0';row.style.transform='translateX(-22px)';}
          setTimeout(()=>{if(!row)return;row.style.transition='opacity .4s ease,transform .4s cubic-bezier(.22,1,.36,1)';row.style.opacity='1';row.style.transform='translateX(0)';},300+i*130);
          const fill=document.getElementById(`gbar-fill-${i}`);
          setTimeout(()=>{if(fill)fill.style.width=`${Math.round(100-i*17)}%`;},500+i*130);
        });
        break;
      case'dna':
        setTimeout(()=>{
          const fill=document.getElementById('dna-spec-fill'),dot=document.getElementById('dna-spec-dot');
          const pct=parseFloat(fill?.dataset?.pct||'50');
          if(fill)fill.style.width=`${pct}%`;if(dot)dot.style.left=`${pct}%`;
          const avg=document.getElementById('dna-avgday');
          if(avg){const t=STORE.avgPerDay,s=performance.now(),d=1600;const tick=now=>{const p=Math.min((now-s)/d,1);avg.textContent=(t*(1-Math.pow(1-p,3))).toFixed(1);if(p<1)requestAnimationFrame(tick);else avg.textContent=t.toFixed(1);};requestAnimationFrame(tick);}
        },550);
        break;
    }
  },

  /* ── SCREENSHOT slide courante ── */
  async screenshotCurrentSlide(){
    const btn=document.getElementById('screenshot-btn');
    if(!window.html2canvas)return;
    if(btn){btn.classList.add('capturing');btn.textContent='⏳';}
    try{
      const canvas=await html2canvas(document.getElementById('stories'),{
        backgroundColor:'#060610',
        scale:Math.min(window.devicePixelRatio||2,3),
        useCORS:true,allowTaint:true,logging:false,
        ignoreElements:el=>['screenshot-btn','hud','nav-prev','nav-next'].includes(el.id),
        onclone:(doc)=>{
          // 1. Supprimer tous les backdrop-filter (rendu noir dans html2canvas)
          doc.querySelectorAll('*').forEach(el=>{el.style.backdropFilter='none';el.style.webkitBackdropFilter='none';});
          // 2. Blobs : retirer blur + figer + booster opacité
          doc.querySelectorAll('.blob').forEach(el=>{
            el.style.filter='none';el.style.animation='none';
            el.style.transform='translate(-50%,-50%)';
            const m=(el.getAttribute('style')||'').match(/--op:([\d.]+)/);
            el.style.opacity=String(Math.min((m?parseFloat(m[1]):0.28)*2,0.75));
          });
          // 3. Cacher le grain (parasite)
          const g=doc.getElementById('grain');if(g)g.style.display='none';
          // 4. Art photo bg
          doc.querySelectorAll('.art-photo-bg').forEach(el=>{el.style.filter='none';el.style.opacity='0.18';});
          // 5. Forcer la visibilité de tout ce qui est animé
          doc.querySelectorAll('.anim-rise,.anim-pop,.pod-slot,.pod-rest-item,.genre-bar-row').forEach(el=>{
            el.style.opacity='1';el.style.transform='none';el.style.animation='none';el.style.transition='none';
          });
          // 6. Genre bars à leur largeur finale
          doc.querySelectorAll('.genre-bar-fill').forEach((el,i)=>{el.style.width=`${Math.max(10,Math.round(100-i*17))}%`;el.style.transition='none';});
          // 7. DNA spectre
          const sf=doc.getElementById('dna-spec-fill'),sd=doc.getElementById('dna-spec-dot');
          if(sf){const p=sf.dataset?.pct||'50';sf.style.width=`${p}%`;sf.style.transition='none';}
          if(sd&&sf){sd.style.left=`${sf.dataset?.pct||50}%`;sd.style.transition='none';}
          // 8. Art bar fill
          const ab=doc.getElementById('art-bar-fill');if(ab){ab.style.width='100%';ab.style.transition='none';}
          // 9. Count-up : afficher la valeur finale
          const cc=doc.getElementById('champ-count');if(cc&&STORE.tracks[0])cc.textContent=`🎧 ${fmtNum(parseInt(STORE.tracks[0].playcount||0))} ${T.s2Plays}`;
          const ac=doc.getElementById('art-count');if(ac)ac.textContent=fmtNum(parseInt(STORE.artist1?.playcount||0));
          const tc=doc.getElementById('time-counter');if(tc)tc.textContent=fmtNum(STORE.listenMins);
          const da=doc.getElementById('dna-avgday');if(da)da.textContent=STORE.avgPerDay.toFixed(1);
          // 10. Podium plays
          ['trk','art','alb'].forEach((base,bi)=>{
            const src=[STORE.tracks,STORE.artists,STORE.albums][bi];
            [0,1,2].forEach(i=>{const e=doc.getElementById(`pod-plays-${base}-${i}`);if(e&&src[i])e.textContent=fmtNum(parseInt(src[i].playcount||0));});
          });
          // 11. Ambient visible
          const amb=doc.getElementById('ambient');if(amb)amb.style.opacity='1';
        }
      });
      // Post-traitement : coins arrondis + watermark
      const ctx=canvas.getContext('2d'),W=canvas.width,H=canvas.height,R=Math.round(W*.025);
      ctx.globalCompositeOperation='destination-in';
      ctx.beginPath();ctx.moveTo(R,0);ctx.lineTo(W-R,0);ctx.quadraticCurveTo(W,0,W,R);
      ctx.lineTo(W,H-R);ctx.quadraticCurveTo(W,H,W-R,H);ctx.lineTo(R,H);ctx.quadraticCurveTo(0,H,0,H-R);
      ctx.lineTo(0,R);ctx.quadraticCurveTo(0,0,R,0);ctx.closePath();ctx.fill();
      ctx.globalCompositeOperation='source-over';
      const bH=Math.round(H*.065),g2=ctx.createLinearGradient(0,H-bH*1.8,0,H);
      g2.addColorStop(0,'rgba(0,0,0,0)');g2.addColorStop(1,'rgba(0,0,0,.65)');
      ctx.fillStyle=g2;ctx.fillRect(0,H-bH*1.8,W,bH*1.8);
      const fs=Math.round(W*.022);ctx.fillStyle='rgba(255,255,255,.5)';
      ctx.font=`700 ${fs}px Arial,sans-serif`;ctx.textAlign='center';ctx.textBaseline='middle';
      ctx.fillText(`LASTSTATS · ${WRAPPED_YEAR}`,W/2,H-bH*.7);
      const a=document.createElement('a');
      a.download=`laststats-${WRAPPED_YEAR}-${SLIDES[this.current].id}.png`;
      a.href=canvas.toDataURL('image/png',.95);a.click();
      if(btn){btn.textContent='✅';setTimeout(()=>{if(btn)btn.textContent='📷';},2200);}
    }catch(err){
      console.error('screenshot:',err);
      if(btn){btn.textContent='❌';setTimeout(()=>{if(btn)btn.textContent='📷';},2200);}
    }finally{if(btn)btn.classList.remove('capturing');}
  },

  /* ── SHARE CARD ── */
  async shareCard(){
    const card=document.getElementById('share-card'),btn=document.getElementById('sum-share-btn');
    if(!card||!window.html2canvas){alert('html2canvas non disponible.');return;}
    if(btn){btn.textContent=T.screenshotGen;btn.disabled=true;}
    try{
      const canvas=await html2canvas(card,{
        backgroundColor:'#100820',scale:2,useCORS:true,allowTaint:true,logging:false,
        onclone:(doc)=>{
          // Fond solide sur la carte (pas de backdrop-filter)
          const c=doc.getElementById('share-card');
          if(c){c.style.background='linear-gradient(145deg,#1a0b2e 0%,#0d1b2a 60%,#0a1628 100%)';c.style.backdropFilter='none';c.style.webkitBackdropFilter='none';c.style.border='1px solid rgba(255,255,255,.15)';}
          doc.querySelectorAll('*').forEach(el=>{el.style.backdropFilter='none';el.style.webkitBackdropFilter='none';});
          doc.querySelectorAll('.anim-rise,.anim-pop').forEach(el=>{el.style.opacity='1';el.style.transform='none';el.style.animation='none';});
        }
      });
      // Coins arrondis
      const ctx=canvas.getContext('2d'),W=canvas.width,H=canvas.height,R=Math.round(W*.042);
      ctx.globalCompositeOperation='destination-in';
      ctx.beginPath();ctx.moveTo(R,0);ctx.lineTo(W-R,0);ctx.quadraticCurveTo(W,0,W,R);
      ctx.lineTo(W,H-R);ctx.quadraticCurveTo(W,H,W-R,H);ctx.lineTo(R,H);ctx.quadraticCurveTo(0,H,0,H-R);
      ctx.lineTo(0,R);ctx.quadraticCurveTo(0,0,R,0);ctx.closePath();ctx.fill();
      ctx.globalCompositeOperation='source-over';
      const a=document.createElement('a');a.download=`laststats-${STORE.username||'user'}-${WRAPPED_YEAR}.png`;
      a.href=canvas.toDataURL('image/png',.95);a.click();
      if(btn){btn.textContent=T.screenshotOk;btn.disabled=false;}
      setTimeout(()=>{if(btn)btn.textContent=T.s10SaveCard;},2500);
    }catch(err){
      console.error('shareCard:',err);
      if(btn){btn.textContent=T.screenshotFail;btn.disabled=false;}
    }
  }
};

/* ═══════════════════════════════════════════════════════════════
   INPUT HANDLERS
   ═══════════════════════════════════════════════════════════════ */
document.addEventListener('keydown',e=>{
  if(document.getElementById('stories')?.classList.contains('hidden'))return;
  if(e.key==='ArrowRight'||e.key==='Enter'){e.preventDefault();Stories.next();}
  else if(e.key==='ArrowLeft'){e.preventDefault();Stories.prev();}
  else if(e.key===' '){e.preventDefault();Stories.togglePause();}
});
document.getElementById('nav-prev')?.addEventListener('click',()=>Stories.prev());
document.getElementById('nav-next')?.addEventListener('click',()=>Stories.next());
document.getElementById('pause-btn')?.addEventListener('click',e=>{e.stopPropagation();Stories.togglePause();});
document.getElementById('screenshot-btn')?.addEventListener('click',e=>{e.stopPropagation();Stories.screenshotCurrentSlide();});

let _tx=0,_ty=0,_tt=0;
document.addEventListener('touchstart',e=>{_tx=e.touches[0].clientX;_ty=e.touches[0].clientY;_tt=Date.now();},{passive:true});
document.addEventListener('touchend',e=>{
  const dx=e.changedTouches[0].clientX-_tx,dy=e.changedTouches[0].clientY-_ty;
  if(Math.abs(dx)>Math.abs(dy)&&Math.abs(dx)>44&&Date.now()-_tt<400){if(dx<0)Stories.next();else Stories.prev();}
},{passive:true});

/* ═══════════════════════════════════════════════════════════════
   LOADING
   ═══════════════════════════════════════════════════════════════ */
function showLoader(msg,pct){const t=document.getElementById('loader-text'),b=document.getElementById('loader-bar');if(t)t.textContent=msg;if(b)b.style.width=`${pct}%`;}

async function startWrapped(username,apiKey){
  // Lire l'année sélectionnée
  WRAPPED_YEAR=parseInt(document.getElementById('inp-year')?.value)||(new Date().getFullYear()-1);

  // Reset STORE
  STORE.username=username.trim();STORE.apiKey=apiKey.trim();
  STORE.user=null;STORE.tracks=[];STORE.albums=[];STORE.artists=[];
  STORE.tags=[];STORE.artist1Img='';STORE.annualPlays=0;STORE._uniqueArtists=0;STORE._uniqueTracks=0;

  const errEl=document.getElementById('cred-error'),submitEl=document.getElementById('cred-submit');
  if(errEl)errEl.hidden=true;if(submitEl)submitEl.disabled=true;
  document.getElementById('overlay-creds').classList.add('hidden');
  document.getElementById('overlay-loading').classList.remove('hidden');

  const STEPS=[T.loadStep0,T.loadStep1,T.loadStep2,T.loadStep3,T.loadStep4,T.loadStep5,T.loadStep6,T.loadStep7,T.loadStep8];
  let si=0;const iv=setInterval(()=>{si=Math.min(si+1,STEPS.length-2);showLoader(STEPS[si],Math.round(10+si/STEPS.length*60));},900);

  try{await loadAllData((msg,pct)=>showLoader(msg,pct));}
  catch(err){
    clearInterval(iv);
    document.getElementById('overlay-loading').classList.add('hidden');
    document.getElementById('overlay-creds').classList.remove('hidden');
    if(submitEl)submitEl.disabled=false;
    if(errEl){errEl.textContent=`Erreur : ${err.message}`;errEl.hidden=false;}
    return;
  }
  clearInterval(iv);showLoader(T.loadStep8,100);
  await new Promise(r=>setTimeout(r,420));

  if(document.getElementById('inp-remember')?.checked){
    try{localStorage.setItem('ls_username',STORE.username);localStorage.setItem('ls_apikey',STORE.apiKey);localStorage.setItem('ls_year',String(WRAPPED_YEAR));}catch{}
  }
  document.getElementById('overlay-loading').classList.add('hidden');
  document.getElementById('stories').classList.remove('hidden');
  Stories.init();
}

document.getElementById('cred-submit')?.addEventListener('click',async()=>{
  const user=document.getElementById('inp-user')?.value?.trim(),key=document.getElementById('inp-key')?.value?.trim();
  const errEl=document.getElementById('cred-error');
  if(!user){if(errEl){errEl.textContent=T.errNoUser;errEl.hidden=false;}return;}
  if(!key||key.length<20){if(errEl){errEl.textContent=T.errNoKey;errEl.hidden=false;}return;}
  await startWrapped(user,key);
});
['inp-user','inp-key'].forEach(id=>document.getElementById(id)?.addEventListener('keydown',e=>{if(e.key==='Enter')document.getElementById('cred-submit')?.click();}));
document.querySelectorAll('.lang-btn').forEach(btn=>btn.addEventListener('click',()=>{
  setLang(btn.dataset.lang);
  document.getElementById('overlay-lang').classList.add('hidden');
  document.getElementById('overlay-creds').classList.remove('hidden');
}));
document.getElementById('lang-change-btn')?.addEventListener('click',()=>{
  document.getElementById('overlay-creds').classList.add('hidden');
  document.getElementById('overlay-lang').classList.remove('hidden');
});

/* ═══════════════════════════════════════════════════════════════
   INIT
   ═══════════════════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded',()=>{
  let savedLang;try{savedLang=localStorage.getItem('ls_lang');}catch{}
  setLang(savedLang||autoDetectLang());

  if(!isWrappedAvailable()){
    document.getElementById('overlay-lang').classList.add('hidden');
    document.getElementById('overlay-wait').classList.remove('hidden');
    applyLangToDOM();startCountdown();return;
  }

  // Peupler le sélecteur d'année (année passée par défaut)
  const sel=document.getElementById('inp-year');
  if(sel){
    const cur=new Date().getFullYear(),last=cur-1;
    for(let y=last;y>=2003;y--){const o=document.createElement('option');o.value=y;o.textContent=y;if(y===last)o.selected=true;sel.appendChild(o);}
    let saved;try{saved=parseInt(localStorage.getItem('ls_year'))||last;}catch{saved=last;}
    sel.value=String(Math.min(saved,last));
  }

  // Pré-remplir identifiants
  let savedUser='',savedKey='';
  try{savedUser=localStorage.getItem('ls_username')||'';savedKey=localStorage.getItem('ls_apikey')||'';}catch{}
  if(savedUser&&savedKey){
    const uEl=document.getElementById('inp-user'),kEl=document.getElementById('inp-key');
    if(uEl)uEl.value=savedUser;if(kEl)kEl.value=savedKey;
  }

  // Toujours afficher le portail de connexion
  if(savedLang){
    document.getElementById('overlay-lang').classList.add('hidden');
    document.getElementById('overlay-creds').classList.remove('hidden');
  }
});
