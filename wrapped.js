// wrapped.js — LastStats Wrapped · Liquid Adaptive Edition
'use strict';

let WRAPPED_YEAR = new Date().getFullYear() - 1;

const TRANSLATIONS = {
  fr:{
    waitTitle:'Reviens le 1er janvier',
    waitSub:'Le Wrapped {year} sera disponible dès le 1er janvier {next}.',
    waitArchives:'Explorer les années précédentes',
    waitBack:'← Retour à LastStats',
    cdDays:'Jours',cdHours:'Heures',cdMins:'Min',cdSecs:'Sec',
    credTitle:'Ton Année\nen Musique',credDesc:'Connecte-toi pour générer ton Wrapped personnalisé.',
    lblUser:"Nom d'utilisateur Last.fm",lblKey:'Clé API',lblKeyGet:'Obtenir ↗',lblYear:'Année',
    lblRemember:'Se souvenir de moi',credSubmit:'Lancer mon Wrapped ✦',lblBack:'← Retour à LastStats',
    errNoUser:"Veuillez renseigner votre nom d'utilisateur.",errNoKey:'Clé API invalide (32 caractères).',
    loadStep0:'Connexion à Last.fm…',loadStep1:'Récupération du profil…',loadStep2:'Chargement des titres…',
    loadStep3:'Analyse des albums…',loadStep4:'Exploration des artistes…',loadStep5:'Découverte des genres…',
    loadStep6:'Calcul des statistiques…',loadStep7:'Chargement des images…',loadStep8:'Finalisation…',
    stepProfile:'Profil utilisateur',stepTop:'Top artistes & titres',stepImages:'Pochettes & visuels',
    stepHistory:'Analyse temporelle',stepCompare:'Données communautaires',
    introTaglineSuffix:' écoutes. Une histoire.',
    numbersEyebrow:'En chiffres',numbersTitle:'Ton année en stats',
    lblScrobbles:'Écoutes',lblArtists:'Artistes',lblAlbums:'Albums',lblTracks:'Titres distincts',
    lblMinutes:'Minutes estimées',lblDays:"Jours d'activité",
    artistsEyebrow:'Classement',artistsTitle:'Tes artistes',
    albumsEyebrow:'Collection',albumsTitle:'Tes albums',
    tracksEyebrow:'Obsessions',tracksTitle:'Tes titres',
    globalEyebrow:'Communauté',globalTitle:'Toi vs le monde',
    gcRankLabel:'Pour ton artiste #1',gcRankDesc:"Tu fais partie des {pct}% d'auditeurs mondiaux",
    gcListeners:'Auditeurs mondiaux',gcScrobblesGlobal:'Écoutes mondiales',
    gcTrackPlays:'Écoutes de ton titre #1',gcUniqueness:"Score d'originalité",
    habitsEyebrow:'Rythme',habitsTitle:'Quand tu écoutes',
    habitTimeLabels:{night:'Noctambule',morning:'Matinal·e',afternoon:'Après-midiste',evening:'Soirée'},
    habitTimeSubs:{night:'Tu écoutes surtout entre 22h et 4h',morning:'Ta journée commence avec de la musique',afternoon:"L'après-midi c'est ta heure",evening:'Le soir est ton moment musical'},
    habitWeekTitle:'Jour favori',
    habitMonthLabel:'Mois record',
    recordEyebrow:'Record',recordTitle:'Ton jour légendaire',
    recordUnit:'écoutes en 24h',recordTopLabel:'Ce jour-là tu écoutais',
    gotAwayEyebrow:'Nostalgie',
    gotAwayFootnote:"L'artiste que tu as abandonné·e en route…",
    tlBeforeLbl:'Jan – Juin',tlAfterLbl:'Juil – Déc',
    genresEyebrow:'Goûts musicaux',genresTitle:'Tes genres de l\'année',
    genresEvoTitle:'Évolution semestrielle',genresS1:'1er semestre',genresS2:'2e semestre',
    recapTitle:'{year} en un mot :',
    shareBtn:'🔗 Copier le lien',exportStory:'📱 Story (9:16)',exportCard:'🖼 Carte',
    shareBack:'← Retour à LastStats',
    shareViewTitle:'Wrapped partagé',shareViewSub:"Tu consultes le Wrapped d'un·e autre utilisateur·rice.",
    shareEnter:'Voir le Wrapped ✦',shareOwnLink:'Créer mon Wrapped →',
    shareModal:'Partager mon Wrapped',shareModalSub:'Choisis comment partager.',
    shareCopy:'Copier le lien',shareVia:'Partager via…',
    shareModalStory:'Story 9:16',shareModalCard:'Carte complète',shareClose:'Fermer',
    copiedOk:'✅ Lien copié !',copiedFail:'⚠️ Impossible de copier',
    scrobbles:'scrobbles',hours:'heures',artists:'artistes',noData:'Données indisponibles.',
    readonlyBadge:'👁 Vue partagée',
    recapWords:{extreme:'Légendaire',passionate:'Passionné·e',regular:'Mélomane',casual:'Détendu·e'},
    weekDays:['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'],
    months:['Janv','Fév','Mars','Avr','Mai','Juin','Juil','Août','Sept','Oct','Nov','Déc'],
    yearbadgeArchive:'Archives',yearbadgeCurrent:'Cette année',
    gcSimilar:'Artistes similaires',gcAvgPlays:'Moy. mondiale/auditeur',gcUserVsAvg:'Tes écoutes vs moy.',gcRealMins:'Minutes réelles',gcTop3Label:'Tes 3 artistes',gcTrackUserPlay:'Tes écoutes titre #1',
    streakEyebrow:'Streak',streakTitle:'Ta flamme',streakUnit:'jours',streakLabel:'consécutifs',streakPeriod:'Période',streakNone:'Données insuffisantes.',
    vibeEyebrow:'Profil',vibeTitle:'Ton vibe',vibeIntensityLabel:'Intensité',vibeTimeLabel:'Moment',vibeGenreLabel:'Genres',vibeTopGenreLabel:'Genre dominant',
    vibeTypes:{extreme:'Acharné·e',passionate:'Passionné·e',regular:'Régulier·ère',casual:'Éclectique'},
  },
  en:{
    waitTitle:'Come back on January 1st',
    waitSub:'Your {year} Wrapped will be available from January 1st {next}.',
    waitArchives:'Browse previous years',
    waitBack:'← Back to LastStats',
    cdDays:'Days',cdHours:'Hours',cdMins:'Min',cdSecs:'Sec',
    credTitle:'Your Year\nin Music',credDesc:'Log in to generate your personalised Wrapped.',
    lblUser:'Last.fm Username',lblKey:'API Key',lblKeyGet:'Get key ↗',lblYear:'Year',
    lblRemember:'Remember me',credSubmit:'Launch my Wrapped ✦',lblBack:'← Back to LastStats',
    errNoUser:'Please enter your username.',errNoKey:'Please enter a valid API key (32 chars).',
    loadStep0:'Connecting to Last.fm…',loadStep1:'Fetching profile…',loadStep2:'Loading tracks…',
    loadStep3:'Analysing albums…',loadStep4:'Exploring artists…',loadStep5:'Discovering genres…',
    loadStep6:'Computing stats…',loadStep7:'Loading images…',loadStep8:'Finishing…',
    stepProfile:'User profile',stepTop:'Top artists & tracks',stepImages:'Artwork & visuals',
    stepHistory:'Time analysis',stepCompare:'Community data',
    introTaglineSuffix:' plays. One story.',
    numbersEyebrow:'By the numbers',numbersTitle:'Your year in stats',
    lblScrobbles:'Plays',lblArtists:'Artists',lblAlbums:'Albums',lblTracks:'Unique tracks',
    lblMinutes:'Minutes estimated',lblDays:'Active days',
    artistsEyebrow:'Ranking',artistsTitle:'Your artists',
    albumsEyebrow:'Collection',albumsTitle:'Your albums',
    tracksEyebrow:'Obsessions',tracksTitle:'Your tracks',
    globalEyebrow:'Community',globalTitle:'You vs the world',
    gcRankLabel:'For your #1 artist',gcRankDesc:'You are in the top {pct}% of global listeners',
    gcListeners:'Global listeners',gcScrobblesGlobal:'Global scrobbles',
    gcTrackPlays:'Plays of your #1 track',gcUniqueness:'Uniqueness score',
    habitsEyebrow:'Rhythm',habitsTitle:'When you listen',
    habitTimeLabels:{night:'Night Owl',morning:'Early Bird',afternoon:'Afternoon Person',evening:'Evening Person'},
    habitTimeSubs:{night:'You mostly listen between 10pm and 4am',morning:'You start the day with music',afternoon:'Afternoons are your prime time',evening:'Evenings are your musical moment'},
    habitWeekTitle:'Favourite day',
    habitMonthLabel:'Record month',
    recordEyebrow:'Record',recordTitle:'Your legendary day',
    recordUnit:'plays in 24h',recordTopLabel:'On that day you listened to',
    gotAwayEyebrow:'Nostalgia',
    gotAwayFootnote:'The artist you left behind along the way…',
    tlBeforeLbl:'Jan – Jun',tlAfterLbl:'Jul – Dec',
    genresEyebrow:'Musical tastes',genresTitle:'Your year in genres',
    genresEvoTitle:'Half-year evolution',genresS1:'First half',genresS2:'Second half',
    recapTitle:'{year} in a word:',
    shareBtn:'🔗 Copy link',exportStory:'📱 Story (9:16)',exportCard:'🖼 Card',
    shareBack:'← Back to LastStats',
    shareViewTitle:'Shared Wrapped',shareViewSub:"You're viewing someone else's Wrapped.",
    shareEnter:'View Wrapped ✦',shareOwnLink:'Create my Wrapped →',
    shareModal:'Share my Wrapped',shareModalSub:'Choose how to share.',
    shareCopy:'Copy link',shareVia:'Share via…',
    shareModalStory:'Story 9:16',shareModalCard:'Full card',shareClose:'Close',
    copiedOk:'✅ Link copied!',copiedFail:'⚠️ Could not copy',
    scrobbles:'scrobbles',hours:'hours',artists:'artists',noData:'No data available.',
    readonlyBadge:'👁 Shared view',
    recapWords:{extreme:'Legendary',passionate:'Passionate',regular:'Audiophile',casual:'Relaxed'},
    weekDays:['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    months:['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
    yearbadgeArchive:'Archive',yearbadgeCurrent:'Current',
    gcSimilar:'Similar artists',gcAvgPlays:'Avg global/listener',gcUserVsAvg:'Your plays vs avg',gcRealMins:'Real minutes',gcTop3Label:'Your 3 artists',gcTrackUserPlay:'Your #1 track plays',
    streakEyebrow:'Streak',streakTitle:'Your Flame',streakUnit:'days',streakLabel:'in a row',streakPeriod:'Period',streakNone:'Not enough data.',
    vibeEyebrow:'Profile',vibeTitle:'Your Vibe',vibeIntensityLabel:'Intensity',vibeTimeLabel:'Time Slot',vibeGenreLabel:'Genres',vibeTopGenreLabel:'Top Genre',
    vibeTypes:{extreme:'Devoted',passionate:'Passionate',regular:'Regular',casual:'Casual'},
  },
  es:{
    waitTitle:'Vuelve el 1 de enero',
    waitSub:'Tu Wrapped {year} estará disponible el 1 de enero {next}.',
    waitArchives:'Ver años anteriores',waitBack:'← Volver',
    cdDays:'Días',cdHours:'Horas',cdMins:'Min',cdSecs:'Seg',
    credTitle:'Tu Año\nen Música',credDesc:'Inicia sesión para generar tu Wrapped.',
    lblUser:'Usuario Last.fm',lblKey:'Clave API',lblKeyGet:'Obtener ↗',lblYear:'Año',
    lblRemember:'Recordarme',credSubmit:'Lanzar Wrapped ✦',lblBack:'← Volver',
    errNoUser:'Introduce tu nombre.',errNoKey:'Clave API no válida.',
    loadStep0:'Conectando…',loadStep1:'Perfil…',loadStep2:'Canciones…',loadStep3:'Álbumes…',
    loadStep4:'Artistas…',loadStep5:'Géneros…',loadStep6:'Estadísticas…',loadStep7:'Imágenes…',loadStep8:'Finalizando…',
    stepProfile:'Perfil',stepTop:'Top artistas',stepImages:'Imágenes',stepHistory:'Análisis',stepCompare:'Comunidad',
    introTaglineSuffix:' escuchas. Una historia.',
    numbersEyebrow:'En cifras',numbersTitle:'Tu año en stats',
    lblScrobbles:'Escuchas',lblArtists:'Artistas',lblAlbums:'Álbumes',lblTracks:'Canciones',lblMinutes:'Minutos',lblDays:'Días activos',
    artistsEyebrow:'Ranking',artistsTitle:'Tus artistas',albumsEyebrow:'Colección',albumsTitle:'Tus álbumes',tracksEyebrow:'Obsesiones',tracksTitle:'Tus canciones',
    globalEyebrow:'Comunidad',globalTitle:'Tú vs el mundo',
    gcRankLabel:'Para tu artista #1',gcRankDesc:'Estás en el top {pct}% de oyentes',
    gcListeners:'Oyentes globales',gcScrobblesGlobal:'Escuchas globales',gcTrackPlays:'Escuchas tu canción #1',gcUniqueness:'Puntuación de originalidad',
    habitsEyebrow:'Ritmo',habitsTitle:'Cuándo escuchas',
    habitTimeLabels:{night:'Noctámbulo',morning:'Madrugador',afternoon:'Tarde',evening:'Noche'},
    habitTimeSubs:{night:'Escuchas entre las 22h y las 4h',morning:'Empiezas el día con música',afternoon:'La tarde es tu momento',evening:'Las noches son tuyas'},
    habitWeekTitle:'Día favorito',habitMonthLabel:'Mes récord',
    recordEyebrow:'Récord',recordTitle:'Tu día legendario',recordUnit:'escuchas en 24h',recordTopLabel:'Ese día escuchabas',
    gotAwayEyebrow:'Nostalgia',gotAwayFootnote:'El artista que dejaste atrás…',
    tlBeforeLbl:'Ene – Jun',tlAfterLbl:'Jul – Dic',
    genresEyebrow:'Gustos musicales',genresTitle:'Tus géneros',genresEvoTitle:'Evolución semestral',genresS1:'Primer semestre',genresS2:'Segundo semestre',
    recapTitle:'{year} en una palabra:',shareBtn:'🔗 Copiar enlace',exportStory:'📱 Story',exportCard:'🖼 Tarjeta',shareBack:'← Volver',
    shareViewTitle:'Wrapped compartido',shareViewSub:'Estás viendo el Wrapped de otra persona.',shareEnter:'Ver Wrapped ✦',shareOwnLink:'Crear mi Wrapped →',
    shareModal:'Compartir',shareModalSub:'Elige cómo compartir.',shareCopy:'Copiar enlace',shareVia:'Compartir…',shareModalStory:'Story 9:16',shareModalCard:'Tarjeta completa',shareClose:'Cerrar',
    copiedOk:'✅ ¡Enlace copiado!',copiedFail:'⚠️ No se pudo copiar',
    scrobbles:'escuchas',hours:'horas',artists:'artistas',noData:'Sin datos.',readonlyBadge:'👁 Vista compartida',
    recapWords:{extreme:'Legendario',passionate:'Apasionado',regular:'Melómano',casual:'Relajado'},
    weekDays:['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'],
    months:['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'],
    yearbadgeArchive:'Archivo',yearbadgeCurrent:'Actual',
    gcSimilar:'Artistas similares',gcAvgPlays:'Media global/oyente',gcUserVsAvg:'Tus escuchas vs media',gcRealMins:'Minutos reales',gcTop3Label:'Tus 3 artistas',gcTrackUserPlay:'Tus escuchas canción #1',
    streakEyebrow:'Racha',streakTitle:'Tu llama',streakUnit:'días',streakLabel:'consecutivos',streakPeriod:'Período',streakNone:'Datos insuficientes.',
    vibeEyebrow:'Perfil',vibeTitle:'Tu vibe',vibeIntensityLabel:'Intensidad',vibeTimeLabel:'Momento',vibeGenreLabel:'Géneros',vibeTopGenreLabel:'Género top',
    vibeTypes:{extreme:'Fanático',passionate:'Apasionado',regular:'Regular',casual:'Casual'},
  },
  de:{
    waitTitle:'Komm am 1. Januar zurück',
    waitSub:'Dein Wrapped {year} ist ab 1. Januar {next} verfügbar.',
    waitArchives:'Frühere Jahre anzeigen',waitBack:'← Zurück',
    cdDays:'Tage',cdHours:'Std',cdMins:'Min',cdSecs:'Sek',
    credTitle:'Dein Jahr\nin Musik',credDesc:'Melde dich für dein Wrapped an.',
    lblUser:'Last.fm Benutzername',lblKey:'API-Schlüssel',lblKeyGet:'Holen ↗',lblYear:'Jahr',
    lblRemember:'Angemeldet bleiben',credSubmit:'Wrapped starten ✦',lblBack:'← Zurück',
    errNoUser:'Benutzernamen eingeben.',errNoKey:'Gültigen API-Schlüssel eingeben.',
    loadStep0:'Verbindung…',loadStep1:'Profil…',loadStep2:'Tracks…',loadStep3:'Alben…',loadStep4:'Künstler…',loadStep5:'Genres…',loadStep6:'Statistiken…',loadStep7:'Bilder…',loadStep8:'Abschluss…',
    stepProfile:'Profil',stepTop:'Top-Künstler',stepImages:'Bilder',stepHistory:'Analyse',stepCompare:'Community',
    introTaglineSuffix:' Plays. Eine Geschichte.',
    numbersEyebrow:'Die Zahlen',numbersTitle:'Dein Jahr in Stats',
    lblScrobbles:'Plays',lblArtists:'Künstler',lblAlbums:'Alben',lblTracks:'Tracks',lblMinutes:'Minuten',lblDays:'Aktive Tage',
    artistsEyebrow:'Ranking',artistsTitle:'Deine Künstler',albumsEyebrow:'Sammlung',albumsTitle:'Deine Alben',tracksEyebrow:'Obsessionen',tracksTitle:'Deine Tracks',
    globalEyebrow:'Community',globalTitle:'Du vs. die Welt',
    gcRankLabel:'Für deinen #1-Künstler',gcRankDesc:'Du bist in den Top {pct}% der Hörer',
    gcListeners:'Globale Hörer',gcScrobblesGlobal:'Globale Plays',gcTrackPlays:'Plays deines #1-Tracks',gcUniqueness:'Originalitätswert',
    habitsEyebrow:'Rhythmus',habitsTitle:'Wann du hörst',
    habitTimeLabels:{night:'Nachteule',morning:'Frühaufsteher',afternoon:'Nachmittags',evening:'Abendmensch'},
    habitTimeSubs:{night:'Du hörst meist zwischen 22 und 4 Uhr',morning:'Du startest mit Musik in den Tag',afternoon:'Nachmittags ist deine Zeit',evening:'Abende gehören dir'},
    habitWeekTitle:'Lieblingstag',habitMonthLabel:'Rekordmonat',
    recordEyebrow:'Rekord',recordTitle:'Dein legendärer Tag',recordUnit:'Plays in 24h',recordTopLabel:'An diesem Tag hörtest du',
    gotAwayEyebrow:'Nostalgie',gotAwayFootnote:'Der Künstler, den du zurückgelassen hast…',
    tlBeforeLbl:'Jan – Jun',tlAfterLbl:'Jul – Dez',
    genresEyebrow:'Musikgeschmack',genresTitle:'Deine Genres',genresEvoTitle:'Halbjahresvergleich',genresS1:'Erstes Halbjahr',genresS2:'Zweites Halbjahr',
    recapTitle:'{year} in einem Wort:',shareBtn:'🔗 Link kopieren',exportStory:'📱 Story',exportCard:'🖼 Karte',shareBack:'← Zurück',
    shareViewTitle:'Geteilter Wrapped',shareViewSub:'Du siehst den Wrapped eines anderen Nutzers.',shareEnter:'Wrapped ansehen ✦',shareOwnLink:'Mein Wrapped erstellen →',
    shareModal:'Wrapped teilen',shareModalSub:'Teilen auswählen.',shareCopy:'Link kopieren',shareVia:'Teilen…',shareModalStory:'Story 9:16',shareModalCard:'Vollständige Karte',shareClose:'Schließen',
    copiedOk:'✅ Link kopiert!',copiedFail:'⚠️ Kopieren fehlgeschlagen',
    scrobbles:'Scrobbles',hours:'Stunden',artists:'Künstler',noData:'Keine Daten.',readonlyBadge:'👁 Geteilte Ansicht',
    recapWords:{extreme:'Legendär',passionate:'Leidenschaftlich',regular:'Musikliebhaber',casual:'Entspannt'},
    weekDays:['Mo','Di','Mi','Do','Fr','Sa','So'],
    months:['Jan','Feb','Mär','Apr','Mai','Jun','Jul','Aug','Sep','Okt','Nov','Dez'],
    yearbadgeArchive:'Archiv',yearbadgeCurrent:'Aktuell',
    gcSimilar:'Ähnliche Künstler',gcAvgPlays:'Globaler Ø/Hörer',gcUserVsAvg:'Deine Plays vs Ø',gcRealMins:'Echte Minuten',gcTop3Label:'Deine 3 Künstler',gcTrackUserPlay:'Deine Plays Track #1',
    streakEyebrow:'Streak',streakTitle:'Deine Flamme',streakUnit:'Tage',streakLabel:'am Stück',streakPeriod:'Zeitraum',streakNone:'Nicht genug Daten.',
    vibeEyebrow:'Profil',vibeTitle:'Dein Vibe',vibeIntensityLabel:'Intensität',vibeTimeLabel:'Zeitraum',vibeGenreLabel:'Genres',vibeTopGenreLabel:'Top Genre',
    vibeTypes:{extreme:'Leidenschaftlich',passionate:'Begeistert',regular:'Regelmäßig',casual:'Entspannt'},
  },
  pt:{
    waitTitle:'Volta no dia 1 de janeiro',
    waitSub:'O teu Wrapped {year} estará disponível no dia 1 de janeiro {next}.',
    waitArchives:'Ver anos anteriores',waitBack:'← Voltar',
    cdDays:'Dias',cdHours:'Horas',cdMins:'Min',cdSecs:'Seg',
    credTitle:'O Teu Ano\nem Música',credDesc:'Faz login para gerar o teu Wrapped.',
    lblUser:'Utilizador Last.fm',lblKey:'Chave API',lblKeyGet:'Obter ↗',lblYear:'Ano',
    lblRemember:'Lembrar-me',credSubmit:'Lançar Wrapped ✦',lblBack:'← Voltar',
    errNoUser:'Insere o utilizador.',errNoKey:'Chave API inválida.',
    loadStep0:'A ligar…',loadStep1:'Perfil…',loadStep2:'Músicas…',loadStep3:'Álbuns…',loadStep4:'Artistas…',loadStep5:'Géneros…',loadStep6:'Estatísticas…',loadStep7:'Imagens…',loadStep8:'A finalizar…',
    stepProfile:'Perfil',stepTop:'Top artistas',stepImages:'Imagens',stepHistory:'Análise',stepCompare:'Comunidade',
    introTaglineSuffix:' reproduções. Uma história.',
    numbersEyebrow:'Em números',numbersTitle:'O teu ano em stats',
    lblScrobbles:'Reproduções',lblArtists:'Artistas',lblAlbums:'Álbuns',lblTracks:'Músicas',lblMinutes:'Minutos',lblDays:'Dias ativos',
    artistsEyebrow:'Classificação',artistsTitle:'Os teus artistas',albumsEyebrow:'Coleção',albumsTitle:'Os teus álbuns',tracksEyebrow:'Obsessões',tracksTitle:'As tuas músicas',
    globalEyebrow:'Comunidade',globalTitle:'Tu vs o mundo',
    gcRankLabel:'Para o teu artista #1',gcRankDesc:'Estás no top {pct}% de ouvintes',
    gcListeners:'Ouvintes globais',gcScrobblesGlobal:'Reproduções globais',gcTrackPlays:'Reproduções da tua música #1',gcUniqueness:'Pontuação de originalidade',
    habitsEyebrow:'Ritmo',habitsTitle:'Quando ouves',
    habitTimeLabels:{night:'Noctívago',morning:'Madrugador',afternoon:'Tarde',evening:'Noite'},
    habitTimeSubs:{night:'Ouves sobretudo entre as 22h e as 4h',morning:'Começas o dia com música',afternoon:'A tarde é o teu momento',evening:'As noites são tuas'},
    habitWeekTitle:'Dia favorito',habitMonthLabel:'Mês recorde',
    recordEyebrow:'Recorde',recordTitle:'O teu dia lendário',recordUnit:'reproduções em 24h',recordTopLabel:'Nesse dia ouvia',
    gotAwayEyebrow:'Nostalgia',gotAwayFootnote:'O artista que deixaste para trás…',
    tlBeforeLbl:'Jan – Jun',tlAfterLbl:'Jul – Dez',
    genresEyebrow:'Gostos musicais',genresTitle:'Os teus géneros',genresEvoTitle:'Evolução semestral',genresS1:'Primeiro semestre',genresS2:'Segundo semestre',
    recapTitle:'{year} numa palavra:',shareBtn:'🔗 Copiar link',exportStory:'📱 Story',exportCard:'🖼 Cartão',shareBack:'← Voltar',
    shareViewTitle:'Wrapped partilhado',shareViewSub:'Estás a ver o Wrapped de outra pessoa.',shareEnter:'Ver Wrapped ✦',shareOwnLink:'Criar o meu Wrapped →',
    shareModal:'Partilhar',shareModalSub:'Escolhe como partilhar.',shareCopy:'Copiar link',shareVia:'Partilhar…',shareModalStory:'Story 9:16',shareModalCard:'Cartão completo',shareClose:'Fechar',
    copiedOk:'✅ Link copiado!',copiedFail:'⚠️ Não foi possível copiar',
    scrobbles:'scrobbles',hours:'horas',artists:'artistas',noData:'Sem dados.',readonlyBadge:'👁 Vista partilhada',
    recapWords:{extreme:'Lendário',passionate:'Apaixonado',regular:'Melómano',casual:'Descontraído'},
    weekDays:['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'],
    months:['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'],
    yearbadgeArchive:'Arquivo',yearbadgeCurrent:'Atual',
    gcSimilar:'Artistas similares',gcAvgPlays:'Média global/ouvinte',gcUserVsAvg:'Tuas repr. vs média',gcRealMins:'Minutos reais',gcTop3Label:'Os teus 3 artistas',gcTrackUserPlay:'As tuas repr. música #1',
    streakEyebrow:'Sequência',streakTitle:'A tua chama',streakUnit:'dias',streakLabel:'consecutivos',streakPeriod:'Período',streakNone:'Dados insuficientes.',
    vibeEyebrow:'Perfil',vibeTitle:'O teu vibe',vibeIntensityLabel:'Intensidade',vibeTimeLabel:'Momento',vibeGenreLabel:'Géneros',vibeTopGenreLabel:'Género top',
    vibeTypes:{extreme:'Dedicado',passionate:'Apaixonado',regular:'Regular',casual:'Casual'},
  },
  it:{
    waitTitle:'Torna il 1 gennaio',
    waitSub:'Il tuo Wrapped {year} sarà disponibile dal 1 gennaio {next}.',
    waitArchives:'Esplora anni precedenti',waitBack:'← Torna',
    cdDays:'Giorni',cdHours:'Ore',cdMins:'Min',cdSecs:'Sec',
    credTitle:'Il Tuo Anno\nin Musica',credDesc:'Accedi per generare il tuo Wrapped.',
    lblUser:'Utente Last.fm',lblKey:'Chiave API',lblKeyGet:'Ottieni ↗',lblYear:'Anno',
    lblRemember:'Ricordami',credSubmit:'Avvia Wrapped ✦',lblBack:'← Torna',
    errNoUser:'Inserisci il nome utente.',errNoKey:'Chiave API non valida.',
    loadStep0:'Connessione…',loadStep1:'Profilo…',loadStep2:'Brani…',loadStep3:'Album…',loadStep4:'Artisti…',loadStep5:'Generi…',loadStep6:'Statistiche…',loadStep7:'Immagini…',loadStep8:'Finalizzazione…',
    stepProfile:'Profilo',stepTop:'Top artisti',stepImages:'Immagini',stepHistory:'Analisi',stepCompare:'Community',
    introTaglineSuffix:' ascolti. Una storia.',
    numbersEyebrow:'I numeri',numbersTitle:"Il tuo anno in stats",
    lblScrobbles:'Ascolti',lblArtists:'Artisti',lblAlbums:'Album',lblTracks:'Brani',lblMinutes:'Minuti',lblDays:'Giorni attivi',
    artistsEyebrow:'Classifica',artistsTitle:'I tuoi artisti',albumsEyebrow:'Collezione',albumsTitle:'I tuoi album',tracksEyebrow:'Ossessioni',tracksTitle:'I tuoi brani',
    globalEyebrow:'Community',globalTitle:'Tu vs il mondo',
    gcRankLabel:'Per il tuo artista #1',gcRankDesc:'Sei nel top {pct}% degli ascoltatori',
    gcListeners:'Ascoltatori globali',gcScrobblesGlobal:'Ascolti globali',gcTrackPlays:'Ascolti del tuo brano #1',gcUniqueness:'Punteggio di originalità',
    habitsEyebrow:'Ritmo',habitsTitle:'Quando ascolti',
    habitTimeLabels:{night:'Nottambulo',morning:'Mattiniero',afternoon:'Pomeriggio',evening:'Sera'},
    habitTimeSubs:{night:'Ascolti soprattutto tra le 22 e le 4',morning:'Inizi la giornata con la musica',afternoon:'Il pomeriggio è il tuo momento',evening:'Le serate sono tue'},
    habitWeekTitle:'Giorno preferito',habitMonthLabel:'Mese record',
    recordEyebrow:'Record',recordTitle:'Il tuo giorno leggendario',recordUnit:'ascolti in 24h',recordTopLabel:'Quel giorno ascoltavi',
    gotAwayEyebrow:'Nostalgia',gotAwayFootnote:"L'artista che hai lasciato indietro…",
    tlBeforeLbl:'Gen – Giu',tlAfterLbl:'Lug – Dic',
    genresEyebrow:'Gusti musicali',genresTitle:'I tuoi generi',genresEvoTitle:'Evoluzione semestrale',genresS1:'Primo semestre',genresS2:'Secondo semestre',
    recapTitle:'{year} in una parola:',shareBtn:'🔗 Copia link',exportStory:'📱 Story',exportCard:'🖼 Scheda',shareBack:'← Torna',
    shareViewTitle:'Wrapped condiviso',shareViewSub:'Stai visualizzando il Wrapped di un altro utente.',shareEnter:'Vedi Wrapped ✦',shareOwnLink:'Crea il mio Wrapped →',
    shareModal:'Condividi',shareModalSub:'Scegli come condividere.',shareCopy:'Copia link',shareVia:'Condividi…',shareModalStory:'Story 9:16',shareModalCard:'Scheda completa',shareClose:'Chiudi',
    copiedOk:'✅ Link copiato!',copiedFail:'⚠️ Impossibile copiare',
    scrobbles:'scrobbles',hours:'ore',artists:'artisti',noData:'Nessun dato.',readonlyBadge:'👁 Vista condivisa',
    recapWords:{extreme:'Leggendario',passionate:'Appassionato',regular:'Melomane',casual:'Rilassato'},
    weekDays:['Lun','Mar','Mer','Gio','Ven','Sab','Dom'],
    months:['Gen','Feb','Mar','Apr','Mag','Giu','Lug','Ago','Set','Ott','Nov','Dic'],
    yearbadgeArchive:'Archivio',yearbadgeCurrent:'Attuale',
    gcSimilar:'Artisti simili',gcAvgPlays:'Media globale/ascoltatore',gcUserVsAvg:'I tuoi ascolti vs media',gcRealMins:'Minuti reali',gcTop3Label:'I tuoi 3 artisti',gcTrackUserPlay:'I tuoi ascolti brano #1',
    streakEyebrow:'Streak',streakTitle:'La tua fiamma',streakUnit:'giorni',streakLabel:'consecutivi',streakPeriod:'Periodo',streakNone:'Dati insufficienti.',
    vibeEyebrow:'Profilo',vibeTitle:'Il tuo vibe',vibeIntensityLabel:'Intensità',vibeTimeLabel:'Momento',vibeGenreLabel:'Generi',vibeTopGenreLabel:'Genere top',
    vibeTypes:{extreme:'Accanito',passionate:'Appassionato',regular:'Regolare',casual:'Rilassato'},
  },
  ja:{
    waitTitle:'1月1日にまた来てください',
    waitSub:'{year}年のWrappedは{next}年1月1日から利用できます。',
    waitArchives:'過去の年を見る',waitBack:'← 戻る',
    cdDays:'日',cdHours:'時',cdMins:'分',cdSecs:'秒',
    credTitle:'音楽で振り返る\n一年',credDesc:'ログインしてWrappedを生成しましょう。',
    lblUser:'Last.fmユーザー名',lblKey:'APIキー',lblKeyGet:'取得 ↗',lblYear:'年',
    lblRemember:'保存する',credSubmit:'Wrapped開始 ✦',lblBack:'← 戻る',
    errNoUser:'ユーザー名を入力してください。',errNoKey:'有効なAPIキーを入力してください。',
    loadStep0:'接続中…',loadStep1:'プロフィール…',loadStep2:'曲…',loadStep3:'アルバム…',loadStep4:'アーティスト…',loadStep5:'ジャンル…',loadStep6:'統計…',loadStep7:'画像…',loadStep8:'仕上げ…',
    stepProfile:'プロフィール',stepTop:'トップアーティスト',stepImages:'アートワーク',stepHistory:'時間分析',stepCompare:'コミュニティ',
    introTaglineSuffix:'回の再生。一つの物語。',
    numbersEyebrow:'数字で見る',numbersTitle:'あなたの一年',
    lblScrobbles:'再生回数',lblArtists:'アーティスト',lblAlbums:'アルバム',lblTracks:'トラック',lblMinutes:'推定分数',lblDays:'アクティブ日数',
    artistsEyebrow:'ランキング',artistsTitle:'アーティスト',albumsEyebrow:'コレクション',albumsTitle:'アルバム',tracksEyebrow:'執着',tracksTitle:'トラック',
    globalEyebrow:'コミュニティ',globalTitle:'あなた vs 世界',
    gcRankLabel:'#1アーティスト',gcRankDesc:'グローバルリスナーの上位{pct}%',
    gcListeners:'グローバルリスナー',gcScrobblesGlobal:'グローバル再生',gcTrackPlays:'#1トラックの再生',gcUniqueness:'独自性スコア',
    habitsEyebrow:'リズム',habitsTitle:'いつ聴く',
    habitTimeLabels:{night:'夜型',morning:'朝型',afternoon:'午後派',evening:'夜派'},
    habitTimeSubs:{night:'22時から4時の間に聴くことが多い',morning:'音楽で一日を始める',afternoon:'午後があなたの時間',evening:'夜はあなたの音楽タイム'},
    habitWeekTitle:'お気に入りの曜日',habitMonthLabel:'記録月',
    recordEyebrow:'記録',recordTitle:'伝説の一日',recordUnit:'回/24時間',recordTopLabel:'その日聴いていた',
    gotAwayEyebrow:'ノスタルジア',gotAwayFootnote:'途中で置いてきたアーティスト…',
    tlBeforeLbl:'1月〜6月',tlAfterLbl:'7月〜12月',
    genresEyebrow:'音楽の好み',genresTitle:'今年のジャンル',genresEvoTitle:'半年ごとの変化',genresS1:'上半期',genresS2:'下半期',
    recapTitle:'{year}年を一言で:',shareBtn:'🔗 リンクをコピー',exportStory:'📱 ストーリー',exportCard:'🖼 カード',shareBack:'← 戻る',
    shareViewTitle:'共有されたWrapped',shareViewSub:'別のユーザーのWrappedを見ています。',shareEnter:'Wrappedを見る ✦',shareOwnLink:'自分のWrappedを作る →',
    shareModal:'共有',shareModalSub:'共有方法を選択。',shareCopy:'リンクをコピー',shareVia:'共有…',shareModalStory:'ストーリー 9:16',shareModalCard:'フルカード',shareClose:'閉じる',
    copiedOk:'✅ コピーしました！',copiedFail:'⚠️ コピーできません',
    scrobbles:'スクロブル',hours:'時間',artists:'アーティスト',noData:'データなし。',readonlyBadge:'👁 共有ビュー',
    recapWords:{extreme:'伝説的',passionate:'情熱的',regular:'音楽好き',casual:'リラックス'},
    weekDays:['月','火','水','木','金','土','日'],
    months:['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
    yearbadgeArchive:'アーカイブ',yearbadgeCurrent:'今年',
    gcSimilar:'似ているアーティスト',gcAvgPlays:'グローバル平均/リスナー',gcUserVsAvg:'あなたの再生数vs平均',gcRealMins:'実際の分数',gcTop3Label:'あなたのトップ3',gcTrackUserPlay:'あなたの#1曲の再生',
    streakEyebrow:'ストリーク',streakTitle:'あなたの炎',streakUnit:'日',streakLabel:'連続',streakPeriod:'期間',streakNone:'データ不足.',
    vibeEyebrow:'プロフィール',vibeTitle:'あなたのバイブ',vibeIntensityLabel:'強度',vibeTimeLabel:'時間帯',vibeGenreLabel:'ジャンル',vibeTopGenreLabel:'主要ジャンル',
    vibeTypes:{extreme:'献身的',passionate:'情熱的',regular:'定期的',casual:'気軽'},
  },
  zh:{
    waitTitle:'请于1月1日回来',
    waitSub:'您的{year}年Wrapped将于{next}年1月1日起提供。',
    waitArchives:'浏览往年',waitBack:'← 返回',
    cdDays:'天',cdHours:'时',cdMins:'分',cdSecs:'秒',
    credTitle:'您的音乐\n年度回顾',credDesc:'登录以生成您的专属Wrapped。',
    lblUser:'Last.fm用户名',lblKey:'API密钥',lblKeyGet:'获取 ↗',lblYear:'年份',
    lblRemember:'记住我',credSubmit:'启动Wrapped ✦',lblBack:'← 返回',
    errNoUser:'请输入用户名。',errNoKey:'请输入有效的API密钥。',
    loadStep0:'连接中…',loadStep1:'个人资料…',loadStep2:'曲目…',loadStep3:'专辑…',loadStep4:'艺术家…',loadStep5:'流派…',loadStep6:'统计…',loadStep7:'图片…',loadStep8:'完成…',
    stepProfile:'个人资料',stepTop:'热门艺术家',stepImages:'封面图片',stepHistory:'时间分析',stepCompare:'社区数据',
    introTaglineSuffix:'次播放。一个故事。',
    numbersEyebrow:'数字',numbersTitle:'你的年度统计',
    lblScrobbles:'播放',lblArtists:'艺术家',lblAlbums:'专辑',lblTracks:'曲目',lblMinutes:'估计分钟',lblDays:'活跃天数',
    artistsEyebrow:'排名',artistsTitle:'你的艺术家',albumsEyebrow:'收藏',albumsTitle:'你的专辑',tracksEyebrow:'执念',tracksTitle:'你的曲目',
    globalEyebrow:'社区',globalTitle:'你 vs 世界',
    gcRankLabel:'你的#1艺术家',gcRankDesc:'您是全球前{pct}%听众',
    gcListeners:'全球听众',gcScrobblesGlobal:'全球播放',gcTrackPlays:'你的#1曲目播放',gcUniqueness:'独特性得分',
    habitsEyebrow:'节奏',habitsTitle:'你何时收听',
    habitTimeLabels:{night:'夜猫子',morning:'早起者',afternoon:'下午派',evening:'夜晚派'},
    habitTimeSubs:{night:'你主要在晚上10点到凌晨4点听音乐',morning:'你用音乐开始新的一天',afternoon:'下午是你的时光',evening:'夜晚属于你'},
    habitWeekTitle:'最爱的日子',habitMonthLabel:'纪录月份',
    recordEyebrow:'纪录',recordTitle:'你的传奇日',recordUnit:'24小时播放',recordTopLabel:'那天你在听',
    gotAwayEyebrow:'怀旧',gotAwayFootnote:'那位被你遗忘的艺术家…',
    tlBeforeLbl:'1月—6月',tlAfterLbl:'7月—12月',
    genresEyebrow:'音乐品味',genresTitle:'你的年度流派',genresEvoTitle:'半年演变',genresS1:'上半年',genresS2:'下半年',
    recapTitle:'{year}年一词:',shareBtn:'🔗 复制链接',exportStory:'📱 故事',exportCard:'🖼 卡片',shareBack:'← 返回',
    shareViewTitle:'共享的Wrapped',shareViewSub:'您正在查看另一个用户的Wrapped。',shareEnter:'查看Wrapped ✦',shareOwnLink:'创建我的Wrapped →',
    shareModal:'分享',shareModalSub:'选择分享方式。',shareCopy:'复制链接',shareVia:'分享…',shareModalStory:'故事 9:16',shareModalCard:'完整卡片',shareClose:'关闭',
    copiedOk:'✅ 链接已复制！',copiedFail:'⚠️ 无法复制',
    scrobbles:'次播放',hours:'小时',artists:'艺术家',noData:'无数据。',readonlyBadge:'👁 共享视图',
    recapWords:{extreme:'传奇',passionate:'热情',regular:'发烧友',casual:'放松'},
    weekDays:['周一','周二','周三','周四','周五','周六','周日'],
    months:['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
    yearbadgeArchive:'存档',yearbadgeCurrent:'当前',
    gcSimilar:'相似艺术家',gcAvgPlays:'全球平均/听众',gcUserVsAvg:'你的播放vs平均',gcRealMins:'实际分钟',gcTop3Label:'你的3位艺术家',gcTrackUserPlay:'你的#1曲目播放',
    streakEyebrow:'连续',streakTitle:'你的火焰',streakUnit:'天',streakLabel:'连续不断',streakPeriod:'时间段',streakNone:'数据不足.',
    vibeEyebrow:'个性',vibeTitle:'你的氛围',vibeIntensityLabel:'强度',vibeTimeLabel:'时段',vibeGenreLabel:'流派',vibeTopGenreLabel:'主要流派',
    vibeTypes:{extreme:'狂热',passionate:'热情',regular:'规律',casual:'随性'},
  },
};

let LANG_CODE = 'fr';
let T = TRANSLATIONS.fr;

function setLang(code) {
  LANG_CODE = code;
  T = TRANSLATIONS[code] || TRANSLATIONS.fr;
  try { localStorage.setItem('ls_lang', code); } catch {}
  document.querySelectorAll('.lang-btn').forEach(b => b.classList.toggle('active', b.dataset.lang === code));
  // update lang attribute for accessibility
  document.documentElement.lang = code;
  applyLangToDOM();
}
function applyLangToDOM() {
  const s = (id, t) => { const e = document.getElementById(id); if (e) e.textContent = t; };
  const now = new Date(), yr = now.getFullYear();
  s('wait-title', T.waitTitle);
  const sub = (T.waitSub||'').replace('{year}', yr-1).replace('{next}', yr);
  s('wait-sub', sub);
  s('wait-year-label', yr-1); s('wait-next-year', yr);
  s('wait-target-year', yr-1);
  s('wait-back', T.waitBack);
  s('wait-archives-label', T.waitArchives);
  s('cd-days-lbl', T.cdDays); s('cd-hours-lbl', T.cdHours); s('cd-mins-lbl', T.cdMins); s('cd-secs-lbl', T.cdSecs);
  const te = document.getElementById('cred-title');
  if (te) te.innerHTML = T.credTitle.replace('\n', '<br>');
  s('cred-desc', T.credDesc); s('lbl-user', T.lblUser);
  const kg = document.getElementById('lbl-key-get'); if (kg) kg.textContent = T.lblKeyGet;
  s('lbl-year', T.lblYear); s('lbl-remember', T.lblRemember);
  s('cred-submit-txt', T.credSubmit); s('lbl-back', T.lblBack);
  s('step-profile-lbl', T.stepProfile); s('step-top-lbl', T.stepTop);
  s('step-images-lbl', T.stepImages); s('step-history-lbl', T.stepHistory);
  s('step-compare-lbl', T.stepCompare);
  s('step-social-lbl', T.stepSocial||'Contexte social');
  s('share-heading', T.shareViewTitle||'Wrapped partagé');
  s('share-sub', T.shareViewSub); s('share-enter-txt', T.shareEnter); s('share-own-link', T.shareOwnLink);
  s('modal-share-title', T.shareModal); s('modal-share-sub', T.shareModalSub);
  s('modal-copy-link-lbl', T.shareCopy); s('modal-web-share-lbl', T.shareVia);
  s('modal-export-card-lbl', T.shareModalCard);
  s('modal-screenshot-lbl', T.screenshotSection||'Capture section');
  s('modal-share-close', T.shareClose);
}
function autoDetectLang() {
  const n = (navigator.language || 'fr').slice(0, 2).toLowerCase();
  return Object.keys(TRANSLATIONS).includes(n) ? n : 'fr';
}

// contrôle d'accès — année's Wrapped only available from Jan 1st
function isYearAvailable(year) {
  const now = new Date();
  const currentYear = now.getFullYear();
  // les années passées sont toujours dispo
  if (year < currentYear - 1) return true;
  // last year is available once January starts
  if (year === currentYear - 1) return now.getMonth() >= 0; // always true but keeps intent clear
  // l'année en cours ou future : jamais dispo
  return false;
}

function isCurrentWrappedLocked() {
  // is the current year's Wrapped still locked?
  const now = new Date();
  // débloqué le 1er janvier
  return now.getMonth() === 11 && now.getDate() < 31;
}

function isWrappedAvailable() {
  const now = new Date();
  // available from January 1st
  return now.getMonth() >= 0 && !(now.getMonth() === 11);
}

// bloqué en décembre
function isCurrentYearWrappedLocked() {
  const now = new Date();
  return now.getMonth() === 11; // december means locked
}

function getNextJan1() {
  const now = new Date();
  return new Date(now.getFullYear() + 1, 0, 1, 0, 0, 0);
}

let _cdInterval = null;
function startCountdown() {
  if (_cdInterval) clearInterval(_cdInterval);
  const target = getNextJan1();
  const tick = () => {
    const diff = Math.max(0, target - Date.now());
    const pad = n => String(n).padStart(2, '0');
    const s = (id, v) => { const e = document.getElementById(id); if (e) e.textContent = v; };
    if (diff <= 0) { clearInterval(_cdInterval); location.reload(); return; }
    s('cd-days',  Math.floor(diff / 86400000));
    s('cd-hours', pad(Math.floor((diff % 86400000) / 3600000)));
    s('cd-mins',  pad(Math.floor((diff % 3600000) / 60000)));
    s('cd-secs',  pad(Math.floor((diff % 60000) / 1000)));
  };
  tick();
  _cdInterval = setInterval(tick, 1000);
}

const DEF_HASH = '2a96cbd8b46e442fc41c2b86b821562f';
const fmtNum = n => new Intl.NumberFormat(
  LANG_CODE === 'en' ? 'en-US' : LANG_CODE === 'de' ? 'de-DE' :
  LANG_CODE === 'pt' ? 'pt-PT' : LANG_CODE === 'es' ? 'es-ES' : 'fr-FR'
).format(parseInt(n) || 0);
const esc = s => String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');

function getImg(arr, ...sizes) {
  if (!Array.isArray(arr)) return '';
  const order = sizes.length ? sizes : ['extralarge','large','medium','small'];
  for (const size of order) {
    const item = arr.find(i => i.size === size);
    const url = item?.['#text'] || '';
    if (url && url.length > 10 && !url.includes(DEF_HASH)) return url;
  }
  // fallback : première URL non vide
  for (const i of arr) {
    const u = i?.['#text'] || '';
    if (u && u.length > 10 && !u.includes(DEF_HASH)) return u;
  }
  return '';
}
function animCount(el, target, ms = 2200) {
  if (!el || !target) return;
  const start = performance.now();
  const tick = now => {
    const p = Math.min((now - start) / ms, 1);
    el.textContent = fmtNum(Math.round(target * (1 - Math.pow(1 - p, 4))));
    if (p < 1) requestAnimationFrame(tick); else el.textContent = fmtNum(target);
  };
  requestAnimationFrame(tick);
}
function avatarColor(str) {
  // Palette M3 cohérente avec le nouveau thème
  const C = ['#4f378b','#2a4a7f','#1d6b52','#7b4f12','#8b2252','#0e5680','#6750a4','#b3261e','#205d5a','#6d3a8f'];
  let h = 0; for (let i = 0; i < str.length; i++) h = ((h << 5) - h) + str.charCodeAt(i);
  return C[Math.abs(h) % C.length];
}
function initialsPlaceholder(label, size = 80) {
  const txt = (label || '?').trim().toUpperCase();
  const words = txt.split(/\s+/);
  const initials = words.length >= 2 ? words[0][0] + words[words.length-1][0] : txt.slice(0,2);
  const color = avatarColor(txt);
  const fs = Math.round(size * .38);
  return `data:image/svg+xml,${encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
      <rect width="${size}" height="${size}" fill="${color}55"/>
      <text x="50%" y="50%" dy=".35em" fill="white" font-size="${fs}"
            font-family="Arial,Helvetica,sans-serif" font-weight="800"
            text-anchor="middle" letter-spacing="-1">${initials}</text>
    </svg>`
  )}`;
}
function imgOrInitials(imgUrl, label, cls = '') {
  const src = imgUrl || initialsPlaceholder(label);
  return `<img src="${esc(src)}" alt="${esc(label)}" crossorigin="anonymous" loading="lazy" class="${cls}" style="width:100%;height:100%;object-fit:cover;display:block;">`;
}
function showToast(msg, ms = 2800) {
  const el = document.getElementById('toast'), m = document.getElementById('toast-msg');
  if (!el || !m) return;
  m.textContent = msg; el.hidden = false;
  el.classList.add('show');
  clearTimeout(el._t);
  el._t = setTimeout(() => { el.classList.remove('show'); setTimeout(() => { el.hidden = true; }, 350); }, ms);
}
function setLoaderStep(stepId, state) { // state: 'active'|'done'|''
  document.querySelectorAll('.step').forEach(el => el.classList.remove('active','done'));
  const el = document.getElementById(`step-${stepId}`);
  if (el && state) el.classList.add(state);
}
function setProgress(pct) {
  const bar = document.getElementById('loader-bar'), pb = document.getElementById('loader-progressbar'), pt = document.getElementById('loader-pct');
  if (bar) bar.style.width = `${pct}%`;
  if (pb) pb.setAttribute('aria-valuenow', pct);
  if (pt) pt.textContent = `${Math.round(pct)}%`;
}





// Last.fm API
const LASTFM = {
  BASE: 'https://ws.audioscrobbler.com/2.0/',
  async call(method, params = {}, customUser = null) {
    const url = new URL(this.BASE);
    url.searchParams.set('method', method);
    url.searchParams.set('api_key', STORE.apiKey);
    url.searchParams.set('format', 'json');
    if (method.startsWith('user.')) url.searchParams.set('user', customUser || STORE.username);
    Object.entries(params).forEach(([k, v]) => { if (v != null) url.searchParams.set(k, v); });
    const res = await fetch(url.toString());
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    if (data.error) throw new Error(`Last.fm: ${data.message} (${data.error})`);
    return data;
  }
};

// store global
const STORE = {
  username: '', apiKey: '',
  user: null, tracks: [], albums: [], artists: [], tags: [],
  artist1Img: '', _uniqueArtists: 0, _uniqueTracks: 0, annualPlays: 0,
  recentTracks: [],
  tagsByMonth: {},
  habitHours: [],      // index = hour (0–23)
  habitDays: [],       // index = weekday (0=Mon)
  habitMonthPeak: { month: -1, plays: 0 },
  recordDay: null,
  gotAwayArtist: null,
  globalStats: {},
  streak: null,
  dayMap: null,
  isReadOnly: false,
  readOnlyData: null,
  // Social & global context
  friendsData: [],
  globalChart: [],
  leaderboard: null,
  _dynColor: null,
  // getters pratiques
  get displayName() { return this.user?.name || this.username || '—'; },
  get regYear() { const ts = parseInt(this.user?.registered?.unixtime || 0); return ts ? new Date(ts*1000).getFullYear() : null; },
  get avatar() { return getImg(this.user?.image || [], 'extralarge','large','medium'); },
  get artist1() { return this.artists[0] || null; },
  get listenMins() { return this.annualMins || Math.round(this.annualPlays * 3.5); },
  get listenHours() { return Math.round(this.listenMins / 60); },
  get avgPerDay() { return Math.round(this.annualPlays / 365 * 10) / 10; },
  get listenerType() { const a = this.avgPerDay; if (a >= 30) return 'extreme'; if (a >= 15) return 'passionate'; if (a >= 5) return 'regular'; return 'casual'; },
  get habitPeakHour() {
    if (!this.habitHours.length) return -1;
    return this.habitHours.reduce((mi, v, i, a) => v > a[mi] ? i : mi, 0);
  },
  get habitPeakDay() {
    if (!this.habitDays.length) return -1;
    return this.habitDays.reduce((mi, v, i, a) => v > a[mi] ? i : mi, 0);
  },
  get habitTimeCategory() {
    const h = this.habitPeakHour;
    if (h < 0) return 'evening';
    if (h >= 22 || h < 4) return 'night';
    if (h >= 4 && h < 11) return 'morning';
    if (h >= 11 && h < 18) return 'afternoon';
    return 'evening';
  }
};

// tags trop génériques, on les filtre
const STOP_TAGS = new Set(['seen live','loved','favorites','favourite','all','good','best','cool','favorite','mellow','under 2000 listeners','american','british','female','male','singer-songwriter','albums i own','beautiful','catchy','sexy','awesome','chill','epic','amazing','great','love','top','nice','<br>','favourite music','american music','british music','canadian','french','german','japanese','male vocalists','female vocalists','acoustic']);

/* ═══ PRELOAD IMAGES ═══ */
function preloadImages(urls, max = 15) {
  return Promise.allSettled(
    urls.filter(Boolean).slice(0, max).map(url => new Promise((res, rej) => {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = res; img.onerror = rej;
      img.src = url;
    }))
  );
}

/* ═══ LOAD FRIENDS DATA ═══ */
async function loadFriendsData() {
  try {
    const res = await LASTFM.call('user.getFriends', { limit: 10 });
    const friends = (res?.friends?.user || []).slice(0, 8);
    if (!friends.length) return;
    const from = Math.floor(new Date(WRAPPED_YEAR, 0, 1).getTime() / 1000);
    const to   = Math.floor(new Date(WRAPPED_YEAR, 11, 31, 23, 59, 59).getTime() / 1000);
    const jobs = friends.map(async f => {
      const uname = f.name || f['#text'] || '';
      if (!uname) return null;
      try {
        const artRes = await LASTFM.call('user.getWeeklyArtistChart', { from, to }, uname).catch(() => null); // uname = customUser
        const artists = artRes?.weeklyartistchart?.artist || [];
        const topArtists = artists.slice(0, 10).map(a => ({ name: a.name || '', plays: parseInt(a.playcount || 0) }));
        const totalPlays = topArtists.reduce((s, a) => s + a.plays, 0);
        return {
          username: uname,
          img: getImg(f.image || [], 'large', 'medium', 'small'),
          topArtists, totalPlays,
          uniqueArtists: topArtists.length,
          topArtistPlays: topArtists[0]?.plays || 0,
          topArtistName: topArtists[0]?.name || '',
        };
      } catch { return null; }
    });
    const results = (await Promise.allSettled(jobs)).filter(r => r.status === 'fulfilled' && r.value).map(r => r.value);
    STORE.friendsData = results;
  } catch {}
}

/* ═══ LOAD GLOBAL CHART ═══ */
async function loadGlobalChartData() {
  try {
    const res = await LASTFM.call('chart.getTopArtists', { limit: 50 });
    STORE.globalChart = (res?.artists?.artist || []).map((a, i) => ({
      name: a.name || '', playcount: parseInt(a.playcount || 0),
      listeners: parseInt(a.listeners || 0), rank: i + 1,
    }));
  } catch {}
}

/* ═══ COMPUTE LEADERBOARD ═══ */
function computeLeaderboard() {
  const userEntry = {
    username: STORE.displayName, img: STORE.avatar, isUser: true,
    volume: STORE.annualPlays,
    uniqueArtists: STORE._uniqueArtists || STORE.artists.length,
    loyaltyPct: STORE.artists[0] ? Math.round((STORE.artists[0].playcount / Math.max(1, STORE.annualPlays)) * 100) : 0,
  };
  const friendEntries = STORE.friendsData.map(f => ({
    username: f.username, img: f.img, isUser: false,
    volume: f.totalPlays, uniqueArtists: f.uniqueArtists,
    loyaltyPct: f.totalPlays > 0 ? Math.round((f.topArtistPlays / Math.max(1, f.totalPlays)) * 100) : 0,
  }));
  const all = [userEntry, ...friendEntries];
  const rank = (arr, key, desc = true) => {
    const sorted = [...arr].sort((a, b) => desc ? b[key] - a[key] : a[key] - b[key]);
    return sorted.map((item, i) => ({ ...item, rank: i + 1 }));
  };
  STORE.leaderboard = {
    volume: rank(all, 'volume'),
    curiosity: rank(all, 'uniqueArtists'),
    loyalty: rank(all, 'loyaltyPct', false),
  };
}

async function loadAllData(onProgress) {
  const p = (msg, pct, step, stepState) => {
    onProgress?.(msg, pct);
    setProgress(pct);
    if (step) setLoaderStep(step, stepState || 'active');
    const lt = document.getElementById('loader-text');
    if (lt && msg) lt.textContent = msg;
  };

  p(T.loadStep0, 5);
  const from = Math.floor(new Date(WRAPPED_YEAR, 0, 1, 0, 0, 0).getTime() / 1000);
  const to   = Math.floor(new Date(WRAPPED_YEAR, 11, 31, 23, 59, 59).getTime() / 1000);

  p(T.loadStep1, 10, 'profile');

  // profil + charts hebdo
  const [userRes, tracksRes, albumsRes, artistsRes] = await Promise.all([
    LASTFM.call('user.getInfo'),
    LASTFM.call('user.getWeeklyTrackChart',  { from, to }).catch(() => null),
    LASTFM.call('user.getWeeklyAlbumChart',  { from, to }).catch(() => null),
    LASTFM.call('user.getWeeklyArtistChart', { from, to }).catch(() => null),
  ]);
  setLoaderStep('profile', 'done');
  p(T.loadStep2, 28, 'top');

  STORE.user = userRes.user;
  const normArtist = a => ({ name: a?.['#text'] || a?.name || '' });

  STORE.tracks  = (tracksRes?.weeklytrackchart?.track  || []).slice(0, 50).map(t => ({
    name: t.name || '—', artist: normArtist(t.artist),
    playcount: parseInt(t.playcount || 0), image: [], mbid: t.mbid || '',
  }));
  STORE.albums  = (albumsRes?.weeklyalbumchart?.album   || []).slice(0, 20).map(a => ({
    name: a.name || '—', artist: normArtist(a.artist),
    playcount: parseInt(a.playcount || 0), image: [], mbid: a.mbid || '',
  }));
  STORE.artists = (artistsRes?.weeklyartistchart?.artist || []).slice(0, 20).map(a => ({
    name: a.name || '—', playcount: parseInt(a.playcount || 0),
    image: [], mbid: a.mbid || '', _img: '', _listeners: 0, _globalPlays: 0,
  }));
  STORE._uniqueArtists = STORE.artists.length;
  STORE._uniqueTracks  = STORE.tracks.length;
  STORE.annualPlays = STORE.artists.reduce((s, a) => s + (a.playcount || 0), 0);
  if (!STORE.annualPlays) STORE.annualPlays = STORE.tracks.reduce((s, t) => s + (t.playcount || 0), 0);

  setLoaderStep('top', 'done');
  p(T.loadStep7, 40, 'images');

  // on récupère tout en parallèle : images, genres, durées
  const top5Art = STORE.artists.slice(0, 5);
  const top5Alb = STORE.albums.slice(0, 5);
  const top5Trk = STORE.tracks.slice(0, 5);

  const enrichJobs = [
    // Tags via top 3 artistes
    ...top5Art.slice(0,3).map(a => LASTFM.call('artist.getTopTags', { artist: a.name, autocorrect: 1 }).catch(() => null)),
    // Infos artiste (images via artist.getTopAlbums)
    ...top5Art.map(a => LASTFM.call('artist.getTopAlbums', { artist: a.name, limit: 3, autocorrect: 1 }).catch(() => null)),
    // artist.getInfo pour global stats (top 1 artiste) + userplaycount
    LASTFM.call('artist.getInfo', { artist: top5Art[0]?.name || '', autocorrect: 1, username: STORE.username }).catch(() => null),
    // artist.getSimilar pour artiste #1 (diversité / profil)
    LASTFM.call('artist.getSimilar', { artist: top5Art[0]?.name || '', limit: 6, autocorrect: 1 }).catch(() => null),
    // artist.getInfo artiste #2 pour comparaison
    LASTFM.call('artist.getInfo', { artist: top5Art[1]?.name || top5Art[0]?.name || '', autocorrect: 1, username: STORE.username }).catch(() => null),
    // album.getInfo pour images albums
    ...top5Alb.map(a => LASTFM.call('album.getInfo', { artist: a.artist?.name || '', album: a.name, autocorrect: 1 }).catch(() => null)),
    // track.getInfo pour images titres + durée
    ...top5Trk.map(t => LASTFM.call('track.getInfo', { artist: t.artist?.name || '', track: t.name, autocorrect: 1, username: STORE.username }).catch(() => null)),
  ];

  const results = await Promise.all(enrichJobs);
  let ri = 0;

  // fusionne les tags des 3 premiers artistes sans doublons
  const seenT = new Set(), merged = [];
  for (let i = 0; i < 3; i++) {
    for (const t of (results[ri+i]?.toptags?.tag || [])) {
      const n = (t.name || '').toLowerCase().trim();
      if (n && !STOP_TAGS.has(n) && n.length <= 28 && !/^\d/.test(n) && !seenT.has(n)) {
        seenT.add(n); merged.push(t.name);
      }
    }
  }
  STORE.tags = merged.slice(0, 10);
  ri += 3;

  // image de l'artiste via son premier album qui en a une
  for (let i = 0; i < top5Art.length; i++) {
    const res = results[ri + i];
    for (const alb of (res?.topalbums?.album || [])) {
      const img = getImg(alb.image, 'extralarge', 'large');
      if (img) { STORE.artists[i]._img = img; if (i === 0) STORE.artist1Img = img; break; }
    }
  }
  ri += top5Art.length;

  // stats globales de l'artiste #1 (listeners, plays, percentile)
  const artInfoRes = results[ri]; ri++;
  if (artInfoRes?.artist) {
    const ai = artInfoRes.artist;
    const globalListeners = parseInt(ai.stats?.listeners || 0);
    const globalPlays     = parseInt(ai.stats?.playcount || 0);
    const userPlaycount   = parseInt(ai.stats?.userplaycount || STORE.artists[0]?.playcount || 0);
    // estimate percentile from play count vs global average
    let percentile = '—';
    if (globalListeners > 0 && userPlaycount > 0) {
      const avgPlays = globalListeners > 0 ? globalPlays / globalListeners : 100;
      const ratio = userPlaycount / Math.max(1, avgPlays);
      // higher ratio = better = lower percentile number
      const raw = Math.round(100 - Math.min(99, ratio * 12));
      percentile = String(Math.max(1, raw));
    }
    STORE.globalStats = {
      listeners: globalListeners, playcount: globalPlays,
      userPlaycount, percentile,
      avgPlaysPerListener: globalListeners > 0 ? Math.round(globalPlays / globalListeners) : 0,
      artistTags: (artInfoRes.artist.tags?.tag || []).slice(0,3).map(t=>t.name),
    };
    if (STORE.artists[0]) {
      STORE.artists[0]._listeners = globalListeners;
      STORE.artists[0]._globalPlays = globalPlays;
      STORE.artists[0]._userPlaycount = userPlaycount;
    }
  }
  // artistes similaires pour le slide comparaison
  const similarRes = results[ri]; ri++;
  if (similarRes?.similarartists?.artist) {
    STORE.globalStats.similar = (similarRes.similarartists.artist || []).slice(0,5).map(a=>a.name);
  }
  // pareil pour le #2, utile pour la comparaison
  const art2InfoRes = results[ri]; ri++;
  if (art2InfoRes?.artist && STORE.artists[1]) {
    const ai2 = art2InfoRes.artist;
    STORE.artists[1]._listeners = parseInt(ai2.stats?.listeners || 0);
    STORE.artists[1]._globalPlays = parseInt(ai2.stats?.playcount || 0);
    STORE.artists[1]._userPlaycount = parseInt(ai2.stats?.userplaycount || STORE.artists[1]?.playcount || 0);
  }

  // on récupère les pochettes
  for (let i = 0; i < top5Alb.length; i++) {
    const res = results[ri + i];
    if (res?.album?.image) {
      const img = getImg(res.album.image, 'extralarge','large','medium');
      if (img && STORE.albums[i]) STORE.albums[i].image = res.album.image;
    }
  }
  ri += top5Alb.length;

  // pochettes des titres + durée réelle
  let totalDurSec = 0, durCount = 0;
  for (let i = 0; i < top5Trk.length; i++) {
    const res = results[ri + i];
    if (!res?.track) continue;
    if (res.track.album?.image && STORE.tracks[i]) {
      STORE.tracks[i].image = res.track.album.image;
    }
    const dur = parseInt(res.track.duration || 0);
    if (dur > 30000) { totalDurSec += dur / 1000; durCount++; } // durée en ms
    else if (dur > 30) { totalDurSec += dur; durCount++; } // durée en secondes
    if (STORE.tracks[i]) {
      STORE.tracks[i]._globalListeners = parseInt(res.track.listeners || 0);
      STORE.tracks[i]._globalPlays = parseInt(res.track.playcount || 0);
      STORE.tracks[i]._userPlaycount = parseInt(res.track.userplaycount || 0);
    }
  }
  // si on a assez de durées réelles, on recalcule les minutes (plus précis)
  if (durCount >= 2) {
    const avgDurSec = totalDurSec / durCount;
    STORE._realAvgDurSec = Math.round(avgDurSec);
    STORE.annualMins = Math.round(STORE.annualPlays * avgDurSec / 60);
  }

  // ALBUM-FIRST: derive artist images from their top album covers
  setLoaderStep('images', 'done');
  p(T.loadStep3, 46, 'social');

  // Phase 3 — Social + Global context (parallel, non-blocking)
  await Promise.allSettled([loadFriendsData(), loadGlobalChartData()]);
  setLoaderStep('social', 'done');
  p(T.loadStep3, 62, 'history');

  // recent history for habits, record day, and "got away"
  await loadTemporalData(from, to);
  setLoaderStep('history', 'done');
  p(T.loadStep5, 84, 'compare');

  // community stats for track #1
  await loadGlobalTrackStats();
  // Phase 6 — Leaderboard
  computeLeaderboard();

  // Phase 7 — Preload top 15 images (blocks until done = true full-block splash)
  const imagesToPreload = [
    STORE.artist1Img,
    ...STORE.artists.slice(0,5).map(a => a._img).filter(Boolean),
    ...STORE.albums.slice(0,5).map(a => getImg(a.image||[],'extralarge','large')).filter(Boolean),
    ...STORE.tracks.slice(0,5).map(t => getImg(t.image||[],'extralarge','large')).filter(Boolean),
  ].filter((v,i,a) => v && a.indexOf(v) === i);
  await preloadImages(imagesToPreload, 15);

  setLoaderStep('compare', 'done');
  p(T.loadStep8, 100);
}

// données temporelles (habitudes, record, streak)
async function loadTemporalData(from, to) {
  // load recent tracks for the year (up to 8 pages)
  STORE.habitHours = new Array(24).fill(0);
  STORE.habitDays  = new Array(7).fill(0);
  const monthPlays = new Array(12).fill(0);
  const dayMap = {}; // date string → play count
  const artistFirstH = {}; // artist → {h1count, h2count}

  // traite un track dans les maps
  const processTrack = (t) => {
    const ts = t.date?.uts;
    if (!ts) return;
    const d = new Date(parseInt(ts) * 1000);
    const h = d.getHours();
    const dow = (d.getDay() + 6) % 7;
    const month = d.getMonth();
    const dateKey = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    STORE.habitHours[h]++;
    STORE.habitDays[dow]++;
    monthPlays[month]++;
    dayMap[dateKey] = (dayMap[dateKey] || 0) + 1;
    const artistName = t.artist?.['#text'] || t.artist?.name || '';
    if (artistName) {
      if (!artistFirstH[artistName]) artistFirstH[artistName] = { h1: 0, h2: 0 };
      if (month < 6) artistFirstH[artistName].h1++;
      else artistFirstH[artistName].h2++;
    }
  };

  try {
    // page 1 d'abord pour avoir le total
    const first = await LASTFM.call('user.getRecentTracks', {
      from, to, limit: 200, page: 1, extended: 0
    }).catch(() => null);
    if (!first) return;

    (first.recenttracks?.track || []).forEach(processTrack);

    const totalPages = Math.min(50, parseInt(first.recenttracks?.['@attr']?.totalPages || 1));

    if (totalPages > 1) {
      // les pages restantes par lots de 5
      const BATCH = 5;
      for (let start = 2; start <= totalPages; start += BATCH) {
        const batchNums = [];
        for (let p = start; p < start + BATCH && p <= totalPages; p++) batchNums.push(p);

        const results = await Promise.all(
          batchNums.map(p => LASTFM.call('user.getRecentTracks', {
            from, to, limit: 200, page: p, extended: 0
          }).catch(() => null))
        );

        for (const res of results) {
          if (res) (res.recenttracks?.track || []).forEach(processTrack);
        }

        if (start + BATCH <= totalPages) await new Promise(r => setTimeout(r, 80));
      }
    }
  } catch {}

  // mois le plus actif
  const peakMonth = monthPlays.indexOf(Math.max(...monthPlays));
  STORE.habitMonthPeak = { month: peakMonth, plays: monthPlays[peakMonth] };

  // meilleur jour de l'année
  const entries = Object.entries(dayMap).sort((a,b) => b[1]-a[1]);
  if (entries.length) {
    const [dateKey, plays] = entries[0];
    const [y, m, d] = dateKey.split('-').map(Number);
    STORE.recordDay = { date: new Date(y, m-1, d), plays };
  }

  // calcul de la série consécutive la plus longue
  STORE.dayMap = dayMap;
  const sortedDays = Object.keys(dayMap).sort();
  let maxStreak = 0, curStreak = 0, curStart = null, bestStart = null, bestEnd = null;
  for (let i = 0; i < sortedDays.length; i++) {
    const d = new Date(sortedDays[i] + 'T00:00:00');
    const prev = i > 0 ? new Date(sortedDays[i-1] + 'T00:00:00') : null;
    const isConsec = prev && Math.round((d - prev) / 86400000) === 1;
    if (isConsec) {
      curStreak++;
    } else {
      if (curStreak > maxStreak) {
        maxStreak = curStreak;
        bestStart = curStart;
        bestEnd = i > 0 ? new Date(sortedDays[i-1] + 'T00:00:00') : curStart;
      }
      curStreak = 1;
      curStart = d;
    }
  }
  if (curStreak > maxStreak) {
    maxStreak = curStreak;
    bestStart = curStart;
    bestEnd = sortedDays.length ? new Date(sortedDays[sortedDays.length-1] + 'T00:00:00') : curStart;
  }
  STORE.streak = { days: maxStreak, startDate: bestStart, endDate: bestEnd };

  // l'artiste écouté à fond en début d'année puis abandonné
  const candidates = Object.entries(artistFirstH)
    .filter(([, v]) => v.h1 >= 5 && v.h2 <= Math.max(1, v.h1 * 0.15))
    .sort((a,b) => b[1].h1 - a[1].h1);
  if (candidates.length) {
    const [name, counts] = candidates[0];
    const found = STORE.artists.find(a => a.name.toLowerCase() === name.toLowerCase());
    STORE.gotAwayArtist = { name, img: found?._img || '', before: counts.h1, after: counts.h2 };
  } else if (STORE.artists.length >= 2) {
    // fallback: use artist #2 with estimated split
    const a = STORE.artists[1];
    STORE.gotAwayArtist = { name: a.name, img: a._img || '', before: Math.round(a.playcount * 0.7), after: Math.round(a.playcount * 0.3) };
  }
}

// stats globales du titre #1
async function loadGlobalTrackStats() {
  if (!STORE.tracks[0]) return;
  try {
    const res = await LASTFM.call('track.getInfo', {
      artist: STORE.tracks[0].artist?.name || '', track: STORE.tracks[0].name, autocorrect: 1
    });
    if (res?.track) {
      STORE.tracks[0]._globalListeners = parseInt(res.track.listeners || 0);
      STORE.tracks[0]._globalPlays     = parseInt(res.track.playcount || 0);
    }

  } catch(e) { console.warn('loadGlobalTrackStats:', e); }
}

function generateSharePayload() {
  return {
    v: 2,
    u: STORE.username,
    y: WRAPPED_YEAR,
    sc: STORE.annualPlays,
    min: STORE.listenMins,
    tags: STORE.tags.slice(0, 8),
    av: STORE.avatar || '',
    pct: STORE.globalStats?.percentile || '—',
    sim: STORE.globalStats?.similar || [],
    ar: STORE.artists.slice(0, 5).map(a => ({
      n: a.name, p: a.playcount, i: a._img || '',
      gl: a._globalPlays || 0, li: a._listeners || 0,
    })),
    al: STORE.albums.slice(0, 5).map(a => ({
      n: a.name, ar: a.artist?.name || '', p: a.playcount,
      i: getImg(a.image, 'extralarge','large','medium'),
    })),
    tr: STORE.tracks.slice(0, 5).map(t => ({
      n: t.name, ar: t.artist?.name || t.artist || '', p: t.playcount,
      i: getImg(t.image, 'extralarge','large','medium'),
      gp: t._globalPlays || 0,
    })),
  };
}

function generateShareLink() {
  try {
    const payload = generateSharePayload();
    const json = JSON.stringify(payload);
    const b64 = btoa(unescape(encodeURIComponent(json)));
    const url = `${location.origin}${location.pathname}?share=${encodeURIComponent(b64)}`;
    return url;
  } catch (e) {
    console.error('generateShareLink:', e);
    return location.href;
  }
}

function parseShareParam(param) {
  try {
    const json = decodeURIComponent(escape(atob(decodeURIComponent(param))));
    return JSON.parse(json);
  } catch { return null; }
}

function populateStoreFromShareData(data) {
  STORE.isReadOnly = true;
  STORE.readOnlyData = data;
  STORE.username = data.u || '—';
  STORE.annualPlays = data.sc || 0;
  STORE.annualMins = data.min || 0;
  WRAPPED_YEAR = data.y || new Date().getFullYear() - 1;
  STORE.tags = data.tags || [];
  STORE.user = { name: data.u, image: data.av ? [{ size: 'extralarge', '#text': data.av }] : [] };
  STORE.artists = (data.ar || []).map(a => ({
    name: a.n, playcount: a.p, _img: a.i, image: [],
    _globalPlays: a.gl || 0, _listeners: a.li || 0,
  }));
  STORE.albums  = (data.al || []).map(a => ({
    name: a.n, artist: { name: a.ar }, playcount: a.p,
    image: a.i ? [{ size:'extralarge','#text':a.i },{ size:'large','#text':a.i }] : [],
  }));
  STORE.tracks  = (data.tr || []).map(t => ({
    name: t.n, artist: { name: t.ar }, playcount: t.p,
    image: t.i ? [{ size:'extralarge','#text':t.i }] : [],
    _globalPlays: t.gp || 0,
  }));
  STORE.artist1Img = STORE.artists[0]?._img || '';
  STORE.globalStats = { percentile: data.pct || '—', similar: data.sim || [], listeners: 0, playcount: 0 };
  // précache les images pour que les screenshots marchent en lecture seule
  STORE._shareImages = [
    ...STORE.artists.map(a => a._img).filter(Boolean),
    ...STORE.albums.map(a => a.image?.[0]?.['#text']).filter(Boolean),
    ...STORE.tracks.map(t => t.image?.[0]?.['#text']).filter(Boolean),
  ];
}

// copie dans le presse-papier avec fallback pour les vieux browsers
async function copyShareLink() {
  const url = generateShareLink();
  try {
    await navigator.clipboard.writeText(url);
    showToast(T.copiedOk);
  } catch {
    // fallback vieux browsers
    const ta = document.createElement('textarea');
    ta.value = url; ta.style.position = 'fixed'; ta.style.opacity = '0';
    document.body.appendChild(ta); ta.select();
    try { document.execCommand('copy'); showToast(T.copiedOk); }
    catch { showToast(T.copiedFail); }
    document.body.removeChild(ta);
  }
}

// partage natif sur mobile, sinon on copie le lien
async function nativeShare() {
  const url = generateShareLink();
  if (navigator.share) {
    try { await navigator.share({ title: `LastStats · Wrapped ${WRAPPED_YEAR}`, url }); return; }
    catch {}
  }
  await copyShareLink();
}

// ambiances par slide
const AMBIENTS = {
  purple: 'radial-gradient(ellipse 80% 60% at 20% 30%,#3b2070 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 70%,#1e1b4b 0%,transparent 65%),#141218',
  gold:   'radial-gradient(ellipse 80% 60% at 15% 30%,#3d1c04 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 70%,#1c1005 0%,transparent 65%),#141218',
  blue:   'radial-gradient(ellipse 80% 60% at 15% 25%,#1a2f6b 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 70%,#1e1b4b 0%,transparent 65%),#141218',
  green:  'radial-gradient(ellipse 80% 60% at 20% 35%,#054233 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 70% 65%,#0a3f30 0%,transparent 65%),#141218',
  pink:   'radial-gradient(ellipse 80% 60% at 20% 30%,#450720 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 70%,#400444 0%,transparent 65%),#141218',
  orange: 'radial-gradient(ellipse 80% 60% at 18% 28%,#3a1006 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 74% 66%,#330808 0%,transparent 65%),#141218',
  violet: 'radial-gradient(ellipse 80% 60% at 18% 28%,#270d58 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 74% 66%,#401880 0%,transparent 65%),#141218',
  teal:   'radial-gradient(ellipse 80% 60% at 18% 28%,#0a3f5c 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 74% 68%,#10423e 0%,transparent 65%),#141218',
  record: 'radial-gradient(ellipse 80% 60% at 20% 25%,#3d1c04 0%,transparent 60%),radial-gradient(ellipse 60% 55% at 70% 70%,#190404 0%,transparent 65%),#141218',
  gotAway:'radial-gradient(ellipse 80% 60% at 20% 30%,#16052b 0%,transparent 65%),radial-gradient(ellipse 60% 55% at 70% 70%,#0a0320 0%,transparent 65%),#141218',
  recap:  'radial-gradient(ellipse 80% 60% at 20% 20%,#3b2070 0%,transparent 65%),radial-gradient(ellipse 65% 55% at 75% 75%,#3d1c04 0%,transparent 65%),radial-gradient(ellipse 50% 50% at 50% 50%,#330832 0%,transparent 65%),#141218',
};
function setAmbient(theme) {
  const e = document.getElementById('ambient');
  if (e) e.style.background = AMBIENTS[theme] || AMBIENTS.purple;
}

/* ═══ COLOR THIEF — DYNAMIC BACKGROUND ═══ */
let _colorThief = null;
function getColorThief() {
  if (_colorThief) return _colorThief;
  if (window.ColorThief) { _colorThief = new ColorThief(); }
  return _colorThief;
}
async function applyDynamicColor(imgSrc) {
  const ct = getColorThief();
  if (!ct || !imgSrc) return;
  try {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    await new Promise((res, rej) => { img.onload = res; img.onerror = rej; img.src = imgSrc; });
    const [r, g, b] = ct.getColor(img);
    STORE._dynColor = [r, g, b];
    const root = document.documentElement;
    root.style.setProperty('--dyn-r', r);
    root.style.setProperty('--dyn-g', g);
    root.style.setProperty('--dyn-b', b);
    const dynBg = document.getElementById('dyn-bg');
    if (dynBg) {
      dynBg.style.backgroundColor = `rgb(${r},${g},${b})`;
      dynBg.style.opacity = '0.22';
    }
  } catch {}
}

/* ═══ SOCIAL BOX ═══ */
function buildSocialBox(slideId) {
  const fd = STORE.friendsData;
  let msg = '';
  switch (slideId) {
    case 'numbers': {
      if (!fd.length) break;
      const friendAvg = Math.round(fd.reduce((s,f) => s + f.totalPlays, 0) / fd.length);
      if (friendAvg > 0) {
        const ratio = Math.round((STORE.annualPlays / Math.max(1, friendAvg)) * 10) / 10;
        if (ratio >= 1.2) msg = (T.socialVolumeLead||'Tu écoutes {x}× plus').replace('{x}', ratio.toFixed(1));
      }
      break;
    }
    case 'artists': {
      const a1 = STORE.artists[0];
      if (!a1 || !fd.length) break;
      const also = fd.filter(f => f.topArtists.some(a => a.name.toLowerCase() === a1.name.toLowerCase())).length;
      if (also > 0) msg = (T.socialFriendsAlso||'{n} ami(s) écoutent {artist}').replace('{n}', also).replace('{artist}', a1.name);
      else if (fd.length >= 2) msg = (T.socialUnique||'Seul à écouter {artist}').replace('{artist}', a1.name);
      break;
    }
    case 'tracks': {
      const t1 = STORE.tracks[0];
      if (!t1) break;
      if (t1._globalListeners > 0) msg = `${fmtNum(t1._globalListeners)} ${LANG_CODE==='en'?'global listeners':'auditeurs mondiaux'}`;
      break;
    }
  }
  if (!msg) return '';
  return `<div class="social-box"><span class="social-icon">👥</span><p>${esc(msg)}</p></div>`;
}
// — fonctions qui construisent chaque slide —
function buildFallback(msg) {
  return `<div class="slide-content" style="align-items:center;justify-content:center;flex-direction:column;gap:14px;padding-top:60px">
    <div style="font-size:48px">🎵</div>
    <div style="font-family:'Bebas Neue',cursive;font-size:36px;color:#fff">Oups…</div>
    <p style="font-size:14px;color:rgba(255,255,255,.4);text-align:center;max-width:260px;line-height:1.6">${esc(msg || T.noData)}</p>
  </div>`;
}

/* slide 0 — intro */
function buildIntro() {
  const name = esc(STORE.displayName);
  const total = fmtNum(STORE.annualPlays);
  const bgImg = STORE.artist1Img ? `url('${esc(STORE.artist1Img)}')` : 'none';
  return `
    <div class="slide-bg-art">
      <div class="intro-bg-img" style="background-image:${bgImg}"></div>
      <div class="intro-vignette"></div>
    </div>
    <div class="slide-content intro-content">
      <div class="intro-eyebrow anim-fade">${T.numbersEyebrow === 'En chiffres' ? (LANG_CODE==='en'?'Your Year in Music':'Votre Année en Musique') : T.introTaglineSuffix.trim()}</div>
      <h1 class="intro-username anim-rise" style="animation-delay:.15s" id="intro-username">${name}</h1>
      <div class="intro-year-badge anim-fade" style="animation-delay:.28s" id="intro-year">${WRAPPED_YEAR}</div>
      <div class="intro-divider anim-fade" style="animation-delay:.38s"></div>
      <p class="intro-tagline anim-rise" style="animation-delay:.5s">
        <span class="highlight-num" id="intro-scrobbles">${total}</span>
        <span id="intro-tagline-suffix">${T.introTaglineSuffix}</span>
      </p>
      ${STORE.isReadOnly ? `<div class="readonly-badge" id="readonly-badge" aria-label="${T.readonlyBadge}">${T.readonlyBadge}</div>` : '<div class="intro-scroll-hint" aria-hidden="true"><span></span><span></span><span></span></div>'}
    </div>`;
}

/* slide 1 — numbers */
/* slide 1 */
function buildNumbers() {
  const days = STORE.habitDays.reduce((s,v)=>s+v,0) > 0
    ? STORE.habitDays.filter(v=>v>0).length
    : Math.round(STORE.annualPlays / Math.max(1,STORE.avgPerDay));
  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#2a1a5e;left:15%;top:20%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.35;filter:blur(80px)"></div>
      <div style="position:absolute;border-radius:50%;background:#4f378b;left:78%;top:70%;width:48vmax;height:48vmax;transform:translate(-50%,-50%);opacity:.28;filter:blur(80px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label" id="sl-numbers-eyebrow">${T.numbersEyebrow}</span>
      <h2 class="slide-title" id="sl-numbers-title">${T.numbersTitle}</h2>
    </div>
    <div class="numbers-grid" id="numbers-grid">
      <div class="stat-card stat-card--xl" id="stat-scrobbles">
        <span class="stat-value" id="stat-scrobbles-val">${fmtNum(STORE.annualPlays)}</span>
        <span class="stat-label">${T.lblScrobbles}</span>
      </div>
      <div class="stat-card" id="stat-artists">
        <span class="stat-value">${fmtNum(STORE._uniqueArtists||STORE.artists.length)}</span>
        <span class="stat-label">${T.lblArtists}</span>
      </div>
      <div class="stat-card" id="stat-albums">
        <span class="stat-value">${fmtNum(STORE.albums.length)}</span>
        <span class="stat-label">${T.lblAlbums}</span>
      </div>
      <div class="stat-card" id="stat-tracks">
        <span class="stat-value">${fmtNum(STORE._uniqueTracks||STORE.tracks.length)}</span>
        <span class="stat-label">${T.lblTracks}</span>
      </div>
      <div class="stat-card stat-card--wide" id="stat-minutes">
        <span class="stat-value">${fmtNum(STORE.listenMins)}</span>
        <span class="stat-label">${T.lblMinutes}${STORE._realAvgDurSec ? ' ✓' : ''}</span>
      </div>
      <div class="stat-card stat-card--wide" id="stat-days">
        <span class="stat-value">${fmtNum(days)}</span>
        <span class="stat-label">${T.lblDays}</span>
      </div>
    </div>`;
}

/* slide 2 — top artists */
function buildTopArtists() {
  const artists = STORE.artists.slice(0, 5);
  if (!artists.length) return buildFallback();
  const RANK_EMOJIS = ['♛','②','③'];
  const RANK_CLASSES = ['podium-col--1st','podium-col--2nd','podium-col--3rd'];
  const ORDER = [1,0,2]; // 2e gauche, 1er centre, 3e droite

  const podiumCols = ORDER.map(di => {
    const a = artists[di]; if (!a) return '';
    const img = a._img || getImg(a.image||[],'extralarge','large');
    const globalBadge = di===0 && STORE.globalStats?.percentile && STORE.globalStats.percentile !== '—'
      ? `<div class="podium-global-badge"><span class="global-badge-text">Top ${STORE.globalStats.percentile}%</span></div>`
      : '';
    return `
      <div class="podium-col ${RANK_CLASSES[di]}" data-rank="${di+1}">
        <div class="podium-card" id="podium-artist-${di}">
          ${di===0?`<div class="podium-crown">♛</div>`:''}
          <div class="podium-img-wrap">
            ${imgOrInitials(img, a.name)}
            <div class="podium-img-overlay"></div>
          </div>
          <span class="podium-rank${di===0?' podium-rank--gold':''}">${di===0?'①':RANK_EMOJIS[di]}</span>
          <span class="podium-name">${esc(a.name)}</span>
          <span class="podium-plays" id="podium-plays-artist-${di}">${fmtNum(a.playcount)}</span>
          ${globalBadge}
        </div>
        <div class="podium-bar podium-bar--${['1st','2nd','3rd'][di]}"><span>${di+1}</span></div>
      </div>`;
  }).join('');

  const listItems = artists.slice(3,5).map((a,i) => {
    const img = a._img || getImg(a.image||[],'large','medium');
    return `
      <div class="top-list-item" id="artist-list-${i+3}">
        <span class="top-list-rank">${['④','⑤'][i]}</span>
        <div class="top-list-img">${imgOrInitials(img,a.name)}</div>
        <span class="top-list-name">${esc(a.name)}</span>
        <span class="top-list-plays">${fmtNum(a.playcount)}</span>
      </div>`;
  }).join('');

  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#4f378b;left:20%;top:30%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.38;filter:blur(85px)"></div>
      <div style="position:absolute;border-radius:50%;background:#6d3a8f;left:75%;top:65%;width:48vmax;height:48vmax;transform:translate(-50%,-50%);opacity:.28;filter:blur(85px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.artistsEyebrow}</span>
      <h2 class="slide-title">${T.artistsTitle}</h2>
      ${buildSocialBox('artists')}
    </div>
    <div class="podium-container" id="artists-podium">${podiumCols}</div>
    <div class="top-list" id="artists-list-4-5">${listItems}</div>`;
}

/* slide 3 — top albums */
function buildTopAlbums() {
  const albums = STORE.albums.slice(0, 5);
  if (!albums.length) return buildFallback();
  const items = albums.map((a, i) => {
    // Image album depuis l'API, fallback sur l'artiste
    let img = getImg(a.image||[],'extralarge','large','medium');
    if (!img) {
      const aName = (a.artist?.name || '').toLowerCase();
      const found = STORE.artists.find(ar => ar.name.toLowerCase() === aName);
      img = found?._img || STORE.artist1Img || '';
    }
    const heroClass = i === 0 ? ' mosaic-item--hero' : '';
    return `
      <div class="mosaic-item${heroClass}" id="album-card-${i}" style="opacity:0">
        <div style="position:absolute;inset:0">${imgOrInitials(img,a.name)}</div>
        <div class="mosaic-info">
          <span class="mosaic-name">${esc(a.name)}</span>
          ${i===0?`<span class="mosaic-artist">${esc(a.artist?.name||'')}</span>`:''}
          <span class="mosaic-plays">${fmtNum(a.playcount)} ${T.scrobbles||'écoutes'}</span>
        </div>
      </div>`;
  }).join('');
  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#1d5e42;left:18%;top:30%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.32;filter:blur(85px)"></div>
      <div style="position:absolute;border-radius:50%;background:#0e4a44;left:75%;top:65%;width:48vmax;height:48vmax;transform:translate(-50%,-50%);opacity:.25;filter:blur(85px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.albumsEyebrow}</span>
      <h2 class="slide-title">${T.albumsTitle}</h2>
    </div>
    <div class="albums-mosaic" id="albums-mosaic">${items}</div>`;
}

/* slide 4 — top tracks */
function buildTopTracks() {
  const tracks = STORE.tracks.slice(0, 5);
  if (!tracks.length) return buildFallback();
  const maxPlays = parseInt(tracks[0]?.playcount || 1);
  const items = tracks.map((t, i) => {
    const img = getImg(t.image||[],'extralarge','large','medium');
    const pct = Math.round((parseInt(t.playcount||0)/maxPlays)*100);
    const nums = ['01','02','03','04','05'];
    return `
      <li class="track-item" id="track-item-${i}" style="opacity:0">
        <span class="track-rank">${nums[i]}</span>
        <div class="track-img-wrap">${imgOrInitials(img, t.name)}</div>
        <div class="track-info">
          <span class="track-title">${esc(t.name)}</span>
          <span class="track-artist">${esc(t.artist?.name||t.artist||'')}</span>
        </div>
        <div class="track-bar-wrap"><div class="track-bar" id="track-bar-${i}" style="--w:0%"></div></div>
        <span class="track-plays">${fmtNum(t.playcount)}</span>
      </li>`;
  }).join('');
  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#1a2f6b;left:15%;top:28%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.32;filter:blur(85px)"></div>
      <div style="position:absolute;border-radius:50%;background:#2e1060;left:78%;top:68%;width:48vmax;height:48vmax;transform:translate(-50%,-50%);opacity:.25;filter:blur(85px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.tracksEyebrow}</span>
      <h2 class="slide-title">${T.tracksTitle}</h2>
      ${buildSocialBox('tracks')}
    </div>
    <ol class="tracks-list" id="tracks-list">${items}</ol>`;
}

/* slide 5 — global comparison */
function buildGlobalCompare() {
  const artist = STORE.artists[0];
  const gs = STORE.globalStats || {};
  const track1 = STORE.tracks[0];
  const img = STORE.artist1Img || '';
  const percentile = gs?.percentile || '—';

  // score d'originalité estimé
  const nicheTags = STORE.tags.filter(t => {
    const t2 = t.toLowerCase();
    return t2.length > 4 && !['rock','pop','metal','rap','jazz','soul','folk','indie'].includes(t2);
  }).length;
  const uniquenessScore = STORE.tags.length
    ? Math.min(99, Math.round(52 + nicheTags * 4 + (STORE.artists.filter(a => !a._listeners || a._listeners < 100000).length * 4)))
    : '—';

  // ratio écoutes user vs moyenne mondiale
  const avgPL = gs.avgPlaysPerListener || 0;
  const userPC = gs.userPlaycount || 0;
  const vsAvgX = avgPL > 0 ? Math.round((userPC / avgPL) * 10) / 10 : '—';
  const vsAvgTxt = vsAvgX !== '—' ? `${vsAvgX}×` : '—';

  const similarList = (gs.similar || []).slice(0, 4);

  const artistTags = (gs.artistTags || []).slice(0, 2).join(' · ') || '—';

  const trackUserPlay = track1?._userPlaycount || track1?.playcount || 0;
  const trackGlobalListeners = track1?._globalListeners || 0;

  const artist2 = STORE.artists[1];
  const a2UserPlay = artist2?._userPlaycount || artist2?.playcount || 0;
  const a2Global = artist2?._listeners || 0;
  const a2VsAvg = a2Global > 0 && a2UserPlay > 0
    ? Math.round((a2UserPlay / Math.max(1, gs.avgPlaysPerListener||100)) * 10) / 10
    : null;


  return `
    <svg width="0" height="0" style="position:absolute">
      <defs>
        <linearGradient id="gaugeGrad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#4f378b"/>
          <stop offset="100%" stop-color="#d0bcff"/>
        </linearGradient>
      </defs>
    </svg>
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#4f378b;left:20%;top:25%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.32;filter:blur(85px)"></div>
      <div style="position:absolute;border-radius:50%;background:#2a1a5e;left:78%;top:68%;width:48vmax;height:48vmax;transform:translate(-50%,-50%);opacity:.25;filter:blur(85px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.globalEyebrow}</span>
      <h2 class="slide-title">${T.globalTitle}</h2>
    </div>
    <div class="global-stats-container">

      <!-- Carte rang percentile -->
      <div class="global-card global-card--rank" id="global-rank-card" style="opacity:0">
        <div class="global-card-img-wrap">${imgOrInitials(img, artist?.name||'')}</div>
        <div class="global-card-body">
          <p class="global-card-label">${T.gcRankLabel}</p>
          <p class="global-card-artist">${esc(artist?.name||'—')}</p>
          <p class="global-card-tag-row">${esc(artistTags)}</p>
          <p class="global-card-desc" id="gc-rank-desc">${(T.gcRankDesc||'').replace('{pct}',percentile)}</p>
        </div>
        <div class="percentile-gauge">
          <svg class="gauge-svg" viewBox="0 0 200 110">
            <path class="gauge-bg" d="M10,100 A90,90 0 0,1 190,100"/>
            <path class="gauge-fill" id="gauge-fill" d="M10,100 A90,90 0 0,1 190,100" stroke-dasharray="0 283"/>
            <text class="gauge-pct-text" x="100" y="90" text-anchor="middle">${percentile}%</text>
          </svg>
        </div>
      </div>

      <!-- Grille stats étendue (2 colonnes, scroll) -->
      <div class="global-mini-grid" id="global-mini-grid" style="opacity:0">
        <div class="global-mini-card">
          <span class="gmc-icon">👥</span>
          <span class="gmc-value">${gs.listeners ? fmtNum(gs.listeners) : '—'}</span>
          <span class="gmc-label">${T.gcListeners}</span>
        </div>
        <div class="global-mini-card">
          <span class="gmc-icon">🌍</span>
          <span class="gmc-value">${gs.playcount ? fmtNum(gs.playcount) : '—'}</span>
          <span class="gmc-label">${T.gcScrobblesGlobal}</span>
        </div>
        <div class="global-mini-card">
          <span class="gmc-icon">📊</span>
          <span class="gmc-value">${gs.avgPlaysPerListener ? fmtNum(gs.avgPlaysPerListener) : '—'}</span>
          <span class="gmc-label">${T.gcAvgPlays||'Moy./auditeur'}</span>
        </div>
        <div class="global-mini-card gmc-highlight">
          <span class="gmc-icon">⚡</span>
          <span class="gmc-value">${vsAvgTxt}</span>
          <span class="gmc-label">${T.gcUserVsAvg||'Tes écoutes vs moy.'}</span>
        </div>
        <div class="global-mini-card">
          <span class="gmc-icon">🎵</span>
          <span class="gmc-value">${track1?._globalPlays ? fmtNum(track1._globalPlays) : '—'}</span>
          <span class="gmc-label">${T.gcTrackPlays}</span>
        </div>
        <div class="global-mini-card">
          <span class="gmc-icon">🎧</span>
          <span class="gmc-value">${trackUserPlay ? fmtNum(trackUserPlay) : '—'}</span>
          <span class="gmc-label">${T.gcTrackUserPlay||'Tes écoutes titre #1'}</span>
        </div>
        <div class="global-mini-card">
          <span class="gmc-icon">💎</span>
          <span class="gmc-value">${uniquenessScore}${uniquenessScore!=='—'?'%':''}</span>
          <span class="gmc-label">${T.gcUniqueness}</span>
        </div>
        ${trackGlobalListeners > 0 ? `
        <div class="global-mini-card">
          <span class="gmc-icon">👂</span>
          <span class="gmc-value">${fmtNum(trackGlobalListeners)}</span>
          <span class="gmc-label">Auditeurs titre #1</span>
        </div>` : `
        <div class="global-mini-card">
          <span class="gmc-icon">⏱</span>
          <span class="gmc-value">${STORE.listenMins ? fmtNum(STORE.listenMins) : '—'}</span>
          <span class="gmc-label">${T.gcRealMins||'Minutes'}</span>
        </div>`}
      </div>

      <!-- Similar artists -->
      ${similarList.length > 0 ? `
      <div class="global-similar" id="global-similar" style="opacity:0">
        <span class="global-similar-label">${T.gcSimilar||'Artistes similaires'}</span>
        <div class="global-similar-list">
          ${similarList.map(n=>`<span class="global-similar-chip">${esc(n)}</span>`).join('')}
        </div>
      </div>` : ''}

    </div>`;
}

/* slide 6 — habits (Polar Area + Bar charts) */
function buildHabits() {
  const cat = STORE.habitTimeCategory;
  const peakMonth = STORE.habitMonthPeak;
  const timeEmoji = { night:'🌙', morning:'☀️', afternoon:'🌤', evening:'🌆' };
  const months = T.months || ['Janv','Fév','Mars','Avr','Mai','Juin','Juil','Août','Sept','Oct','Nov','Déc'];
  const monthName = peakMonth.month >= 0 ? (months[peakMonth.month]||'') : '—';

  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#0a3f5c;left:18%;top:25%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.25;filter:blur(80px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.habitsEyebrow}</span>
      <h2 class="slide-title">${T.habitsTitle}</h2>
    </div>
    <div class="habits-layout">
      <div class="habit-hero" id="habit-hero" style="opacity:0">
        <div class="habit-hero-emoji">${timeEmoji[cat]||'🎵'}</div>
        <div class="habit-hero-body">
          <span class="habit-hero-label">${T.habitsEyebrow}</span>
          <div class="habit-hero-title">${(T.habitTimeLabels||{})[cat]||cat}</div>
          <div class="habit-hero-sub">${(T.habitTimeSubs||{})[cat]||''}</div>
        </div>
      </div>
      <div class="habits-charts-row" id="habit-charts-row" style="opacity:0;min-height:140px">
        <div class="habit-chart-card">
          <span class="habit-chart-title">${T.habitsChartClock||'Horloge'}</span>
          <div class="habit-chart-canvas-wrap">
            <canvas id="chart-polar-hours"></canvas>
          </div>
        </div>
        <div class="habit-chart-card">
          <span class="habit-chart-title">${T.habitsChartWeek||'Semaine'}</span>
          <div class="habit-chart-canvas-wrap">
            <canvas id="chart-bar-week"></canvas>
          </div>
        </div>
      </div>
      <div class="habit-month-card" id="habit-month-card" style="opacity:0">
        <div>
          <span class="habit-month-label">${T.habitMonthLabel}</span>
          <span class="habit-month-name">${monthName}</span>
        </div>
        <span class="habit-month-plays">${peakMonth.plays ? fmtNum(peakMonth.plays) + ' ' + T.scrobbles : '—'}</span>
      </div>
    </div>`;
}

let _polarChart = null, _barWeekChart = null;

function buildHabitsCharts() {
  // Attendre le layout pour que canvas ait des dimensions
  requestAnimationFrame(() => _buildHabitsChartsInner());
}
function _buildHabitsChartsInner() {
  const hours = STORE.habitHours;
  const days = STORE.habitDays;
  const weekDays = T.weekDays || ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
  if (!window.Chart) return;

  // Polar area — hourly distribution
  const polarCanvas = document.getElementById('chart-polar-hours');
  if (polarCanvas && hours?.length) {
    if (_polarChart) { try { _polarChart.destroy(); } catch {} _polarChart = null; }
    _polarChart = new Chart(polarCanvas, {
      type: 'polarArea',
      data: {
        labels: Array.from({length:24},(_,i)=>`${i}h`),
        datasets: [{
          data: hours,
          backgroundColor: hours.map((v, i) => {
            const alpha = 0.12 + (v / Math.max(1,...hours)) * 0.72;
            return `hsla(${260 + Math.round(i/24*80)},70%,65%,${alpha.toFixed(2)})`;
          }),
          borderWidth: 0,
        }],
      },
      options: {
        responsive:true, maintainAspectRatio:false,
        animation:{duration:Infinity,easing:'easeOutQuart'},
        scales:{r:{ticks:{display:false},grid:{color:'rgba(147,143,153,.1)'},
          pointLabels:{display:true,color:'rgba(230,225,229,.3)',font:{size:8},
            callback:(val) => (val==='0h'||val==='6h'||val==='12h'||val==='18h') ? val : ''}}},
        plugins:{legend:{display:false},tooltip:{enabled:false}},
      },
    });
  }

  // Bar chart — weekday
  const barCanvas = document.getElementById('chart-bar-week');
  if (barCanvas && days?.length) {
    if (_barWeekChart) { try { _barWeekChart.destroy(); } catch {} _barWeekChart = null; }
    _barWeekChart = new Chart(barCanvas, {
      type: 'bar',
      data: {
        labels: weekDays,
        datasets: [{
          data: days,
          backgroundColor: days.map((_,i) => i === STORE.habitPeakDay ? 'rgba(208,188,255,.85)' : 'rgba(208,188,255,.22)'),
          borderRadius: 4, borderWidth: 0,
        }],
      },
      options: {
        responsive:true, maintainAspectRatio:false,
        animation:{duration:Infinity,easing:'easeOutQuart'},
        scales:{x:{grid:{display:false},ticks:{color:'rgba(230,225,229,.45)',font:{size:10}}},y:{display:false}},
        plugins:{legend:{display:false},tooltip:{
          callbacks:{label: ctx => `${fmtNum(ctx.raw)} ${T.scrobbles}`},
          backgroundColor:'rgba(36,33,46,.9)',titleColor:'#e6e1e5',bodyColor:'#938f99',
        }},
      },
    });
  }
}

/* slide 9 — genres */
function buildGenres() {
  const COLORS = ['#f43f5e','#d0bcff','#60a5fa','#34d399','#fbbf24','#f472b6','#38bdf8','#a78bfa','#fb923c','#e879f9'];
  if (!STORE.tags.length) return buildFallback('Aucun genre trouvé.');

  const tags = STORE.tags.slice(0, 8);
  const legendItems = tags.map((tag, i) => `
    <div class="genre-legend-item" role="listitem">
      <div class="genre-legend-dot" style="background:${COLORS[i%COLORS.length]}"></div>
      <span>${esc(tag)}</span>
    </div>`).join('');

  // split tags into two halves for H1/H2 comparison
  const half = Math.ceil(tags.length / 2);
  const s1Tags = tags.slice(0, half).map(t => `<li>${esc(t)}</li>`).join('');
  const s2Tags = tags.slice(half).map(t => `<li>${esc(t)}</li>`).join('');

  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#45073a;left:18%;top:28%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.32;filter:blur(85px)"></div>
      <div style="position:absolute;border-radius:50%;background:#4f378b;left:78%;top:65%;width:48vmax;height:48vmax;transform:translate(-50%,-50%);opacity:.28;filter:blur(85px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.genresEyebrow}</span>
      <h2 class="slide-title">${T.genresTitle}</h2>
    </div>
    <div class="genres-layout">
      <div class="genres-chart-wrap" id="genres-chart-wrap" style="opacity:0">
        <canvas id="genres-radar-chart" aria-label="Graphique radar des genres" style="width:100%;height:100%"></canvas>
      </div>
      <div class="genres-legend" id="genres-legend" style="opacity:0" role="list">${legendItems}</div>
      <div class="genres-evolution" id="genres-evolution" style="opacity:0">
        <h3 class="genres-evo-title">${T.genresEvoTitle}</h3>
        <div class="genres-evo-comparison">
          <div class="genres-half">
            <span class="genres-half-label">${T.genresS1}</span>
            <ul class="genres-half-list">${s1Tags}</ul>
          </div>
          <div class="genres-half">
            <span class="genres-half-label">${T.genresS2}</span>
            <ul class="genres-half-list">${s2Tags || '<li style="color:rgba(255,255,255,.25)">—</li>'}</ul>
          </div>
        </div>
      </div>
    </div>`;
}

/* slide 13 — leaderboard (NOUVEAU) */
function buildLeaderboard() {
  const lb = STORE.leaderboard;
  if (!lb || STORE.friendsData.length === 0) {
    return `
      <div style="position:absolute;inset:0;z-index:0">
        <div style="position:absolute;border-radius:50%;background:#0d3b26;left:50%;top:40%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.25;filter:blur(80px)"></div>
      </div>
      <div class="slide-header">
        <span class="slide-label">${T.lbEyebrow||'Social'}</span>
        <h2 class="slide-title">${T.lbTitle||'Ton classement'}</h2>
      </div>
      <div class="leaderboard-layout">
        <div class="lb-no-friends">
          <div class="lb-no-friends-icon">👥</div>
          <p class="lb-no-friends-text">${T.lbNoFriends||'Ajoute des amis Last.fm pour débloquer.'}</p>
        </div>
      </div>`;
  }
  const buildList = (ranked) => ranked.map((e, idx) => {
    const rCls = idx===0?'lb-item-rank--1':idx===1?'lb-item-rank--2':idx===2?'lb-item-rank--3':'';
    const iCls = e.isUser?' lb-item--user':'';
    const bw = Math.round(100/(ranked.length||1)*(ranked.length-idx));
    return `<div class="lb-item${iCls}">
      <div class="lb-item-bar" style="width:${bw}%"></div>
      <span class="lb-item-rank ${rCls}">${e.rank}</span>
      <span class="lb-item-name">${esc(e.isUser?(T.lbYou||'Toi'):e.username)}</span>
      <span class="lb-item-val">${e.isUser&&e.rank===1?'🏆 ':''}${fmtNum(e.volume||e.uniqueArtists||e.loyaltyPct||0)}</span>
    </div>`;
  }).join('');
  const desc = (T.lbDesc||'Classement sur {n} critères.').replace('{n}','3');
  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#0d3b26;left:20%;top:25%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.28;filter:blur(80px)"></div>
      <div style="position:absolute;border-radius:50%;background:#1a2f6b;left:78%;top:70%;width:48vmax;height:48vmax;transform:translate(-50%,-50%);opacity:.22;filter:blur(80px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.lbEyebrow||'Social'}</span>
      <h2 class="slide-title">${T.lbTitle||'Ton classement'}</h2>
    </div>
    <div class="leaderboard-layout" id="leaderboard-layout">
      <p class="leaderboard-desc">${desc}</p>
      <div class="lb-tabs" id="lb-tabs">
        <button class="lb-tab active" data-metric="volume">${T.lbMetricVolume||'Volume'}</button>
        <button class="lb-tab" data-metric="curiosity">${T.lbMetricCuriosity||'Curiosité'}</button>
        <button class="lb-tab" data-metric="loyalty">${T.lbMetricLoyalty||'Fidélité'}</button>
      </div>
      <div class="lb-metric-group" id="lb-metric-group">
        <div class="lb-list" id="lb-list">${buildList(lb.volume)}</div>
      </div>
    </div>`;
}

/* slide 10 — recap */
function buildRecap() {
  const type = STORE.listenerType;
  const word = (T.recapWords||{})[type] || 'Passionné·e';
  const top3 = STORE.artists.slice(0,3).map(a => {
    const img = a._img || getImg(a.image||[],'large','medium');
    return `<div class="recap-top3-item">
      <div class="recap-top3-img">${imgOrInitials(img,a.name)}</div>
      <span class="recap-top3-name">${esc(a.name)}</span>
    </div>`;
  }).join('');

  return `
    <div class="recap-bg" id="recap-bg"></div>
    <div class="recap-content">
      <div class="recap-logo">LastStats</div>
      <h2 class="recap-title anim-rise">
        ${(T.recapTitle||'{year} en un mot :').replace('{year}',WRAPPED_YEAR)}<br>
        <em class="recap-word">${esc(word)}</em>
      </h2>
      <div class="recap-summary anim-rise" style="animation-delay:.2s">
        <div class="recap-sum-item"><span class="recap-sum-val">${fmtNum(STORE.annualPlays)}</span><span class="recap-sum-lbl">${T.scrobbles}</span></div>
        <div class="recap-sum-sep">·</div>
        <div class="recap-sum-item"><span class="recap-sum-val">${fmtNum(STORE._uniqueArtists||STORE.artists.length)}</span><span class="recap-sum-lbl">${T.artists}</span></div>
        <div class="recap-sum-sep">·</div>
        <div class="recap-sum-item"><span class="recap-sum-val">${fmtNum(STORE.listenHours)}h</span><span class="recap-sum-lbl">${T.hours}</span></div>
      </div>
      <div class="recap-top3 anim-rise" style="animation-delay:.35s">${top3}</div>
      <div class="recap-actions anim-rise" style="animation-delay:.5s">
        ${!STORE.isReadOnly ? `<button class="btn-primary btn-share" id="recap-share-link" type="button"><span>${T.shareBtn}</span><span class="btn-shimmer"></span></button>
        <button class="btn-secondary btn-export" id="recap-export-card" type="button">${T.exportCard}</button>` :
        `<a href="./wrapped.html" class="btn-primary" style="text-align:center;display:block;padding:14px">${T.shareOwnLink}</a>`}
      </div>
      <p class="share-link-feedback" id="share-link-feedback" role="status" aria-live="polite" hidden></p>
      <a href="index.html" class="btn-ghost recap-back anim-rise" style="animation-delay:.65s">${T.shareBack}</a>
    </div>`;
}

/* ── slide: history ── */
function buildHistory() {
  const dayMap = STORE.dayMap || {};
  const months = T.months || ['Janv','Fév','Mars','Avr','Mai','Juin','Juil','Août','Sept','Oct','Nov','Déc'];

  // Aggregate plays per month from dayMap
  const monthPlays = new Array(12).fill(0);
  Object.entries(dayMap).forEach(([key, plays]) => {
    const m = parseInt(key.split('-')[1]) - 1;
    if (m >= 0 && m < 12) monthPlays[m] += plays;
  });
  const maxPlays = Math.max(1, ...monthPlays);
  const peakMonth = monthPlays.indexOf(Math.max(...monthPlays));

  // H1 vs H2
  const h1 = monthPlays.slice(0, 6).reduce((a, b) => a + b, 0);
  const h2 = monthPlays.slice(6).reduce((a, b) => a + b, 0);

  // Calendar heatmap — build weeks grid from dayMap
  const allDays = Object.keys(dayMap).sort();
  const firstDay = allDays[0] ? new Date(allDays[0] + 'T00:00:00') : new Date(WRAPPED_YEAR, 0, 1);
  const lastDay  = allDays.length ? new Date(allDays[allDays.length-1] + 'T00:00:00') : new Date(WRAPPED_YEAR, 11, 31);
  // Pad to start of week (Mon)
  const startOffset = (firstDay.getDay() + 6) % 7;
  const calStart = new Date(firstDay); calStart.setDate(calStart.getDate() - startOffset);
  const totalDays = Math.ceil((lastDay - calStart) / 86400000) + 7;
  const maxVal = Math.max(1, ...Object.values(dayMap));
  let weeks = [], week = [];
  for (let i = 0; i < totalDays; i++) {
    const d = new Date(calStart); d.setDate(calStart.getDate() + i);
    const key = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    const v = dayMap[key] || 0;
    const inRange = d >= firstDay && d <= lastDay;
    const level = !inRange ? '' : v === 0 ? '0' : v < maxVal*0.25 ? '1' : v < maxVal*0.5 ? '2' : v < maxVal*0.75 ? '3' : '4';
    week.push(`<div class="wh-cell${!inRange?' wh-cell--empty':''}" data-level="${level}" title="${key}: ${v}"></div>`);
    if (week.length === 7) { weeks.push(`<div class="wh-week">${week.join('')}</div>`); week = []; }
  }
  if (week.length) weeks.push(`<div class="wh-week">${week.join('')}</div>`);

  const monthBars = monthPlays.map((v, i) => {
    const pct = Math.round(v / maxPlays * 100);
    const isPeak = i === peakMonth;
    return `<div class="wh-month-col">
      <div class="wh-month-track">
        <div class="wh-month-fill${isPeak?' wh-month-fill--peak':''}" data-pct="${pct}" style="height:0%"></div>
      </div>
      <span class="wh-month-lbl">${(months[i]||'').slice(0,3)}</span>
    </div>`;
  }).join('');

  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#1a3a5c;left:15%;top:20%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.28;filter:blur(85px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.historyEyebrow||'Activité'}</span>
      <h2 class="slide-title">${T.historyTitle||'Ton année mois par mois'}</h2>
    </div>
    <div style="display:flex;flex-direction:column;gap:clamp(8px,2.5vw,14px);padding:0 clamp(12px,4vw,24px) clamp(12px,4vw,22px);flex:1;overflow-y:auto;max-height:calc(100dvh - 120px)">
      <div id="wh-calendar" class="wh-calendar-wrap">
        <div class="wh-grid">${weeks.join('')}</div>
        <div class="wh-legend">
          <span>${T.tlBeforeLbl||'Moins'}</span>
          <div class="wh-legend-cells">
            <div class="wh-cell" data-level="0"></div>
            <div class="wh-cell" data-level="1"></div>
            <div class="wh-cell" data-level="2"></div>
            <div class="wh-cell" data-level="3"></div>
            <div class="wh-cell" data-level="4"></div>
          </div>
          <span>${T.tlAfterLbl||'Plus'}</span>
        </div>
      </div>
      <div id="wh-month-bars" class="wh-month-bars">${monthBars}</div>
      <div id="wh-quick-stats" class="wh-quick-stats">
        <div class="wh-stat">
          <span class="wh-stat-icon">📅</span>
          <span class="wh-stat-val">${fmtNum(h1)}</span>
          <span class="wh-stat-lbl">${T.tlBeforeLbl||'Jan – Juin'}</span>
        </div>
        <div class="wh-stat">
          <span class="wh-stat-icon">🍂</span>
          <span class="wh-stat-val">${fmtNum(h2)}</span>
          <span class="wh-stat-lbl">${T.tlAfterLbl||'Juil – Déc'}</span>
        </div>
        <div class="wh-stat">
          <span class="wh-stat-icon">📆</span>
          <span class="wh-stat-val">${Object.keys(dayMap).length}</span>
          <span class="wh-stat-lbl">${T.lblDays||'Jours actifs'}</span>
        </div>
      </div>
    </div>`;
}

/* ── slide: record day ── */
function buildRecord() {
  const rd = STORE.recordDay;
  const months = T.months || ['Janv','Fév','Mars','Avr','Mai','Juin','Juil','Août','Sept','Oct','Nov','Déc'];
  const dateStr = rd ? `${rd.date.getDate()} ${months[rd.date.getMonth()]||''} ${rd.date.getFullYear()}` : '—';
  const topTrack = STORE.tracks[0];
  const topImg   = topTrack ? getImg(topTrack.image||[], 'medium','small') : '';

  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#7c2d12;left:70%;top:30%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.25;filter:blur(90px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.recordEyebrow||'Record'}</span>
      <h2 class="slide-title">${T.recordTitle||'Ton jour légendaire'}</h2>
    </div>
    <div class="record-layout">
      <div id="record-date-wrap" style="opacity:0">
        <span class="record-date">📅 ${dateStr}</span>
      </div>
      <div id="record-stat-wrap" style="opacity:0">
        <div class="record-plays-display">
          <span class="record-num" id="record-num">${rd ? fmtNum(rd.plays) : '—'}</span>
          <span class="record-unit">${T.recordUnit||'écoutes en 24h'}</span>
        </div>
        ${topTrack ? `
        <div class="record-artist-row">
          <div class="record-artist-img">${imgOrInitials(topImg, topTrack.name)}</div>
          <div style="display:flex;flex-direction:column;gap:2px;text-align:left;min-width:0">
            <span class="record-artist-label">${T.recordTopLabel||'Ce jour-là tu écoutais'}</span>
            <span class="record-artist-name">${esc(topTrack.name)}</span>
            <span class="record-artist-label">${esc(topTrack.artist?.name||topTrack.artist||'')}</span>
          </div>
        </div>` : ''}
      </div>
    </div>`;
}

/* ── slide: got away ── */
function buildGotAway() {
  const ga = STORE.gotAwayArtist;
  const name   = ga?.name   || '—';
  const img    = ga?.img    || '';
  const before = ga?.before || 0;
  const after  = ga?.after  || 0;
  const maxVal = Math.max(1, before);
  const beforePct = 100;
  const afterPct  = Math.max(5, Math.round(after / maxVal * 100));

  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#3b0764;left:25%;top:35%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.28;filter:blur(85px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.gotAwayEyebrow||'Nostalgie'}</span>
      <h2 class="slide-title">${T.gotAwayTitle||'Celui qui t\'a échappé'}</h2>
    </div>
    <div class="gotaway-layout">
      <div id="got-away-card" style="opacity:0">
        <div style="display:flex;flex-direction:column;align-items:center;gap:clamp(6px,2vw,10px)">
          <div class="gotaway-img-wrap">${imgOrInitials(img, name)}</div>
          <span class="gotaway-artist-name">${esc(name)}</span>
        </div>
        <div class="gotaway-timeline">
          <div class="timeline-row">
            <span class="timeline-label">${T.tlBeforeLbl||'Jan–Juin'}</span>
            <div class="timeline-bar timeline-bar--before">
              <div style="width:0%"></div>
            </div>
            <span class="timeline-count">${fmtNum(before)}</span>
          </div>
          <div class="timeline-row">
            <span class="timeline-label">${T.tlAfterLbl||'Juil–Déc'}</span>
            <div class="timeline-bar timeline-bar--after">
              <div style="width:0%"></div>
            </div>
            <span class="timeline-count">${fmtNum(after)}</span>
          </div>
        </div>
        <p class="gotaway-footnote">${T.gotAwayFootnote||"L'artiste que tu as abandonné·e en route…"}</p>
      </div>
    </div>`;
}

/* ── slide: streak ── */
function buildStreak() {
  const s = STORE.streak;
  const months = T.months || ['Janv','Fév','Mars','Avr','Mai','Juin','Juil','Août','Sept','Oct','Nov','Déc'];
  const fmtDate = d => d ? `${d.getDate()} ${months[d.getMonth()]||''}` : '—';

  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#7c2d12;left:50%;top:30%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.25;filter:blur(90px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.streakEyebrow||'Streak'}</span>
      <h2 class="slide-title">${T.streakTitle||'Ta flamme'}</h2>
    </div>
    <div class="streak-layout">
      <div id="streak-fire-wrap" style="opacity:0">
        <span class="streak-fire">🔥</span>
        <span class="streak-num" id="streak-num">${s?.days || 0}</span>
        <span class="streak-unit">${T.streakUnit||'jours'} ${T.streakLabel||'consécutifs'}</span>
      </div>
      <div id="streak-bar-wrap" class="streak-bar-wrap" style="opacity:0">
        <div id="streak-bar-fill" style="width:0%"></div>
      </div>
      <div id="streak-period-card" style="opacity:0">
        ${s?.startDate
          ? `<span class="streak-period">${T.streakPeriod||'Période'} : ${fmtDate(s.startDate)} → ${fmtDate(s.endDate)}</span>`
          : `<span class="streak-period">${T.streakNone||'Données insuffisantes.'}</span>`}
      </div>
    </div>`;
}

/* ── slide: vibe ── */
function buildVibe() {
  const type = STORE.listenerType || 'regular';
  const cat  = STORE.habitTimeCategory || 'evening';
  const vibeTypes  = T.vibeTypes  || { extreme:'Acharné·e', passionate:'Passionné·e', regular:'Régulier·ère', casual:'Éclectique' };
  const timeLabels = T.habitTimeLabels || { night:'Noctambule', morning:'Matinal·e', afternoon:'Après-midiste', evening:'Soirée' };
  const timeEmoji  = { night:'🌙', morning:'☀️', afternoon:'🌤', evening:'🌆' };
  const typeEmoji  = { extreme:'🔥', passionate:'❤️', regular:'🎵', casual:'🎲' };
  const topGenre   = STORE.tags[0] || '—';
  const topArtist  = STORE.artists[0]?.name || '—';

  const badges = [
    { icon: typeEmoji[type]||'🎵', label: T.vibeIntensityLabel||'Intensité',       val: vibeTypes[type]||type },
    { icon: timeEmoji[cat]||'🕐',  label: T.vibeTimeLabel||'Moment',               val: timeLabels[cat]||cat  },
    { icon: '🏷',                   label: T.vibeTopGenreLabel||'Genre dominant',   val: esc(topGenre)         },
    { icon: '🎤',                   label: T.vibeGenreLabel||'Artiste #1',          val: esc(topArtist)        },
  ].map(b => `
    <div class="vibe-badge">
      <span class="vibe-badge-icon">${b.icon}</span>
      <span class="vibe-badge-label">${b.label}</span>
      <span class="vibe-badge-value">${b.val}</span>
    </div>`).join('');

  return `
    <div style="position:absolute;inset:0;z-index:0">
      <div style="position:absolute;border-radius:50%;background:#0c4a6e;left:60%;top:25%;width:55vmax;height:55vmax;transform:translate(-50%,-50%);opacity:.28;filter:blur(85px)"></div>
    </div>
    <div class="slide-header">
      <span class="slide-label">${T.vibeEyebrow||'Profil'}</span>
      <h2 class="slide-title">${T.vibeTitle||'Ton vibe'}</h2>
    </div>
    <div class="vibe-layout">
      <div id="vibe-hero" style="opacity:0">
        <div class="vibe-main-card">
          <span class="vibe-icon">${typeEmoji[type]||'🎵'}</span>
          <span class="vibe-type">${vibeTypes[type]||type}</span>
          <span class="vibe-sub">${STORE.avgPerDay} ${T.scrobbles||'écoutes'} / jour</span>
        </div>
      </div>
      <div id="vibe-badges" style="opacity:0">
        <div class="vibe-badges">${badges}</div>
      </div>
    </div>`;
}

const SLIDES = [
  { id:'intro',       theme:'purple', duration:Infinity,     build:buildIntro },
  { id:'numbers',     theme:'blue',   duration:Infinity,     build:buildNumbers },
  { id:'artists',     theme:'purple', duration:Infinity,     build:buildTopArtists },
  { id:'albums',      theme:'green',  duration:Infinity,     build:buildTopAlbums },
  { id:'tracks',      theme:'blue',   duration:Infinity,     build:buildTopTracks },
  { id:'global',      theme:'violet', duration:Infinity,     build:buildGlobalCompare },
  { id:'habits',      theme:'teal',   duration:Infinity,     build:buildHabits },
  { id:'history',     theme:'purple', duration:Infinity,     build:buildHistory },
  { id:'record',      theme:'record', duration:Infinity,     build:buildRecord },
  { id:'gotaway',     theme:'gotAway',duration:Infinity,     build:buildGotAway },
  { id:'streak',      theme:'record', duration:Infinity,     build:buildStreak },
  { id:'vibe',        theme:'blue',   duration:Infinity,     build:buildVibe },
  { id:'genres',      theme:'pink',   duration:Infinity,     build:buildGenres },
  { id:'leaderboard', theme:'social', duration:Infinity,    build:buildLeaderboard },
  { id:'recap',       theme:'recap',  duration:Infinity, build:buildRecap },
];

// stories engine
let _radarChart = null;
let _observerMap = new Map(); // slideId -> bool (animated already)
let _intersectionObserver = null;

const Stories = {
  current: 0,

  init() {
    const container = document.getElementById('slides-container');
    if (!container) return;
    container.innerHTML = '';
    _observerMap.clear();
    if (_intersectionObserver) { _intersectionObserver.disconnect(); _intersectionObserver = null; }

    SLIDES.forEach((sl) => {
      const div = document.createElement('div');
      div.className = 'slide'; div.id = `slide-${sl.id}`;
      div.innerHTML = sl.build();
      container.appendChild(div);
      _observerMap.set(sl.id, false);
    });

    this._bindRecapButtons();
    this._bindLeaderboardTabs();
    this._bindNavButtons();
    this._buildProgress();

    // Show only the first slide
    this.current = 0;
    const firstEl = document.getElementById(`slide-${SLIDES[0].id}`);
    if (firstEl) firstEl.classList.add('is-active');

    setAmbient(SLIDES[0].theme);
    this._updateCounter(0);

    // Trigger intro enter animations immediately
    _observerMap.set('intro', true);
    setTimeout(() => this._onEnter('intro'), 120);
  },

  _updateCounter(idx) {
    const counter = document.getElementById('slide-counter');
    if (counter) counter.textContent = `${idx + 1} / ${SLIDES.length}`;
    const prevBtn = document.getElementById('nav-prev-btn');
    const nextBtn = document.getElementById('nav-next-btn');
    if (prevBtn) prevBtn.disabled = idx === 0;
    if (nextBtn) nextBtn.disabled = idx === SLIDES.length - 1;
    this._updateProgress(idx);
  },

  _buildProgress() {
    const bar = document.getElementById('progress-bars');
    if (!bar) return;
    bar.innerHTML = SLIDES.map(() =>
      `<div class="prog-seg" role="presentation"><span class="prog-fill"></span></div>`
    ).join('');
  },

  _updateProgress(idx) {
    const segs = document.querySelectorAll('#progress-bars .prog-seg');
    segs.forEach((seg, i) => {
      seg.classList.remove('prog-done', 'prog-active');
      if (i < idx)       seg.classList.add('prog-done');
      else if (i === idx) seg.classList.add('prog-active');
    });
  },

  _bindNavButtons() {
    const prev = document.getElementById('nav-prev-btn');
    const next = document.getElementById('nav-next-btn');
    if (prev) prev.addEventListener('click', (e) => { e.stopPropagation(); this.prev(); });
    if (next) next.addEventListener('click', (e) => { e.stopPropagation(); this.next(); });

    // Keyboard: arrows + spacebar
    document.addEventListener('keydown', e => {
      if (document.getElementById('stories')?.classList.contains('hidden')) return;
      if (!document.getElementById('modal-share')?.classList.contains('hidden')) return;
      if (e.key === 'ArrowRight' || e.key === 'ArrowDown' || e.key === ' ') {
        e.preventDefault(); this.next();
      } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
        e.preventDefault(); this.prev();
      } else if (e.key === 'Escape') {
        document.getElementById('exit-btn')?.click();
      }
    });

    // Tap zones (side areas of screen)
    document.getElementById('tap-prev')?.addEventListener('click', () => this.prev());
    document.getElementById('tap-next')?.addEventListener('click', () => this.next());

    // Touch swipe
    this._bindSwipe();
  },

  _bindSwipe() {
    const el = document.getElementById('slides-scroll');
    if (!el) return;
    let sx = 0, sy = 0, st = 0, locked = null;

    el.addEventListener('touchstart', e => {
      sx = e.touches[0].clientX;
      sy = e.touches[0].clientY;
      st = Date.now();
      locked = null;
    }, { passive: true });

    el.addEventListener('touchmove', e => {
      if (locked === null) {
        const dx = Math.abs(e.touches[0].clientX - sx);
        const dy = Math.abs(e.touches[0].clientY - sy);
        locked = dx > dy ? 'h' : 'v';
      }
      if (locked === 'h') e.preventDefault();
    }, { passive: false });

    el.addEventListener('touchend', e => {
      if (locked !== 'h') return;
      const dx = e.changedTouches[0].clientX - sx;
      const dt = Date.now() - st;
      if (Math.abs(dx) > 48 && dt < 380) {
        if (dx < 0) this.next(); else this.prev();
      }
    }, { passive: true });
  },

  _bindLeaderboardTabs() {
    setTimeout(() => {
      document.querySelectorAll('.lb-tab').forEach(btn => {
        btn.addEventListener('click', () => {
          document.querySelectorAll('.lb-tab').forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          const lb = STORE.leaderboard;
          const metric = btn.dataset.metric;
          if (!lb || !lb[metric]) return;
          const list = document.getElementById('lb-list');
          if (!list) return;
          const ranked = lb[metric];
          list.innerHTML = ranked.map((e, idx) => {
            const rCls = idx===0?'lb-item-rank--1':idx===1?'lb-item-rank--2':idx===2?'lb-item-rank--3':'';
            const iCls = e.isUser?' lb-item--user':'';
            const bw = Math.round(100/(ranked.length||1)*(ranked.length-idx));
            const val = metric==='volume' ? fmtNum(e.volume)
              : metric==='curiosity' ? `${fmtNum(e.uniqueArtists)} ${T.artists}`
              : `${e.loyaltyPct}%`;
            return `<div class="lb-item${iCls}">
              <div class="lb-item-bar" style="width:${bw}%"></div>
              <span class="lb-item-rank ${rCls}">${e.rank}</span>
              <span class="lb-item-name">${esc(e.isUser?(T.lbYou||'Toi'):e.username)}</span>
              <span class="lb-item-val">${e.isUser&&e.rank===1?'🏆 ':''}${val}</span>
            </div>`;
          }).join('');
        });
      });
    }, 200);
  },

  _bindHoverPause() {},  // n/a

  _bindRecapButtons() {
    setTimeout(() => {
      document.getElementById('recap-share-link')?.addEventListener('click', () => openShareModal());
      document.getElementById('recap-export-card')?.addEventListener('click', () => ExportManager.card());
    }, 200);
  },

  go(idx) {
    if (idx < 0 || idx >= SLIDES.length) return;
    const direction = idx > this.current ? 1 : -1;
    const prevIdx   = this.current;

    if (prevIdx === idx) return;
    this.current = idx;

    const prevEl = document.getElementById(`slide-${SLIDES[prevIdx].id}`);
    const nextEl = document.getElementById(`slide-${SLIDES[idx].id}`);
    if (!nextEl) return;

    // ── Exit current slide ──
    if (prevEl) {
      prevEl.classList.remove('is-active');
      prevEl.classList.add(direction > 0 ? 'slide-exit-back' : 'slide-exit-fwd');
      setTimeout(() => {
        prevEl.classList.remove('slide-exit-back', 'slide-exit-fwd');
        prevEl.scrollTop = 0;
      }, 520);
    }

    // ── Prepare incoming slide (no transition) ──
    const prepClass = direction > 0 ? 'slide-prepare-fwd' : 'slide-prepare-back';
    nextEl.classList.remove('slide-exit-back', 'slide-exit-fwd', 'is-active');
    nextEl.classList.add(prepClass);

    // Force reflow so the prepare transform is applied before transition kicks in
    nextEl.getBoundingClientRect();

    // ── Animate incoming slide in next frame ──
    requestAnimationFrame(() => {
      nextEl.classList.remove(prepClass);
      nextEl.classList.add('is-active');
    });

    // Update UI
    setAmbient(SLIDES[idx].theme);
    this._updateCounter(idx);

    // Trigger slide-specific enter animations (once per slide)
    if (!_observerMap.get(SLIDES[idx].id)) {
      _observerMap.set(SLIDES[idx].id, true);
      setTimeout(() => this._onEnter(SLIDES[idx].id), 160);
    }
  },

  next() { if (this.current < SLIDES.length - 1) this.go(this.current + 1); },
  prev() { this.go(Math.max(0, this.current - 1)); },

  pause()       { /* n/a */ },
  resume()      { /* n/a */ },
  togglePause() { /* n/a */ },
  _updateBars() { /* n/a */ },

  _onEnter(id) {
    const fadeIn = (el, delay = 0) => {
      if (!el) return;
      el.style.opacity = '0'; el.style.transform = 'translateY(14px)';
      setTimeout(() => {
        el.style.transition = 'opacity .5s ease, transform .5s cubic-bezier(.22,1,.36,1)';
        el.style.opacity = '1'; el.style.transform = 'translateY(0)';
      }, delay);
    };

    // Apply ColorThief dynamically per slide (seulement si image disponible)
    const dynImg = STORE.artist1Img || getImg(STORE.albums[0]?.image||[],'extralarge') || '';
    if (dynImg) applyDynamicColor(dynImg).catch(() => {});

    switch (id) {
      case 'numbers':
        document.querySelectorAll('.stat-card').forEach((el, i) => {
          el.style.opacity = '0'; el.style.transform = 'scale(.85)';
          setTimeout(() => {
            el.style.transition = 'opacity .4s ease, transform .45s cubic-bezier(.34,1.56,.64,1)';
            el.style.opacity = '1'; el.style.transform = 'scale(1)';
          }, 200 + i * 90);
        });
        break;

      case 'artists':
        [1,0,2].forEach((di, domPos) => {
          const el = document.getElementById(`podium-artist-${di}`); if (!el) return;
          el.style.cssText += 'opacity:0;transform:translateY(32px) scale(.82);transition:none;';
          setTimeout(() => {
            el.style.transition = 'opacity .55s ease, transform .65s cubic-bezier(.34,1.56,.64,1)';
            el.style.opacity = '1'; el.style.transform = 'translateY(0) scale(1)';
            const pe = document.getElementById(`podium-plays-artist-${di}`);
            if (pe) { const t = STORE.artists[di]?.playcount||0; if(t>0) animCount(pe,t,900); }
          }, 200 + domPos * 200);
        });
        [3,4].forEach((i,j) => {
          const el = document.getElementById(`artist-list-${i}`); if (!el) return;
          el.style.opacity='0'; el.style.transform='translateX(-18px)';
          setTimeout(() => {
            el.style.transition='opacity .38s ease, transform .4s cubic-bezier(.22,1,.36,1)';
            el.style.opacity='1'; el.style.transform='translateX(0)';
          }, 800 + j*100);
        });
        break;

      case 'albums':
        document.querySelectorAll('.mosaic-item').forEach((el, i) => {
          el.style.opacity = '0'; el.style.transform = 'scale(.9)';
          setTimeout(() => {
            el.style.transition = 'opacity .5s ease, transform .5s cubic-bezier(.22,1,.36,1)';
            el.style.opacity = '1'; el.style.transform = 'scale(1)';
          }, 150 + i * 120);
        });
        break;

      case 'tracks':
        document.querySelectorAll('.track-item').forEach((el, i) => {
          el.style.opacity='0'; el.style.transform='translateX(-22px)';
          setTimeout(() => {
            el.style.transition='opacity .4s ease, transform .45s cubic-bezier(.22,1,.36,1)';
            el.style.opacity='1'; el.style.transform='translateX(0)';
            const bar = document.getElementById(`track-bar-${i}`);
            const pct = Math.round((parseInt(STORE.tracks[i]?.playcount||0)/Math.max(1,parseInt(STORE.tracks[0]?.playcount||1)))*100);
            setTimeout(()=>{ if(bar) bar.style.setProperty('--w',`${pct}%`); bar && (bar.style.transition='width 1.1s cubic-bezier(.22,1,.36,1)'); }, 80);
          }, 200 + i * 110);
        });
        break;

      case 'global':
        setTimeout(() => {
          fadeIn(document.getElementById('global-rank-card'), 100);
          setTimeout(() => {
            fadeIn(document.getElementById('global-mini-grid'), 0);
          }, 350);
          setTimeout(() => {
            fadeIn(document.getElementById('global-similar'), 0);
          }, 650);
          // animate the gauge
          setTimeout(() => {
            const fill = document.getElementById('gauge-fill');
            const gs = STORE.globalStats;
            const pct = gs?.percentile && gs.percentile !== '—' ? parseInt(gs.percentile) : 50;
            const arc = Math.round((100-pct) * 283 / 100);
            if (fill) { fill.style.strokeDasharray = `${arc} 283`; fill.style.transition='stroke-dasharray 1.6s cubic-bezier(.22,1,.36,1)'; }
          }, 600);
          // animate mini cards one by one
          setTimeout(() => {
            document.querySelectorAll('.global-mini-card').forEach((el,i) => {
              el.style.opacity='0'; el.style.transform='translateY(12px)';
              setTimeout(() => {
                el.style.transition='opacity .35s ease, transform .4s cubic-bezier(.22,1,.36,1)';
                el.style.opacity='1'; el.style.transform='translateY(0)';
              }, i * 70);
            });
          }, 400);
        }, 300);
        break;

      case 'history':
        setTimeout(() => {
          // Calendar grid
          const cal = document.getElementById('wh-calendar');
          if (cal) {
            cal.style.transition = 'opacity .5s ease, transform .55s cubic-bezier(.22,1,.36,1)';
            cal.style.opacity = '1'; cal.style.transform = 'translateY(0)';
          }
          // Monthly bars — stagger fill animation
          setTimeout(() => {
            const mb = document.getElementById('wh-month-bars');
            if (mb) {
              mb.style.transition = 'opacity .4s ease';
              mb.style.opacity = '1';
              mb.querySelectorAll('.wh-month-fill').forEach((el, i) => {
                const pct = parseInt(el.dataset.pct || 0);
                setTimeout(() => {
                  el.style.transition = 'height .9s cubic-bezier(.22,1,.36,1)';
                  el.style.height = `${pct}%`;
                }, i * 40);
              });
            }
          }, 350);
          // Stats
          setTimeout(() => {
            const qs = document.getElementById('wh-quick-stats');
            if (qs) {
              qs.style.transition = 'opacity .45s ease, transform .5s cubic-bezier(.22,1,.36,1)';
              qs.style.opacity = '1'; qs.style.transform = 'translateY(0)';
            }
          }, 700);
        }, 200);
        break;

      case 'habits':
        setTimeout(() => {
          fadeIn(document.getElementById('habit-hero'), 100);
          setTimeout(() => {
            const row = document.getElementById('habit-charts-row');
            if (row) {
              row.style.transition = 'opacity .5s ease, transform .5s cubic-bezier(.22,1,.36,1)';
              row.style.opacity = '1'; row.style.transform = 'translateY(0)';
            }
            buildHabitsCharts();
          // Force resize après animation
          setTimeout(() => {
            if (_polarChart) { try { _polarChart.resize(); } catch {} }
            if (_barWeekChart) { try { _barWeekChart.resize(); } catch {} }
          }, 600);
          }, 400);
          setTimeout(() => fadeIn(document.getElementById('habit-month-card'), 0), 700);
        }, 200);
        break;

      case 'record':
        setTimeout(() => {
          fadeIn(document.getElementById('record-date-wrap'), 100);
          setTimeout(() => {
            const sw = document.getElementById('record-stat-wrap'); fadeIn(sw, 0);
            const numEl = document.getElementById('record-num');
            if (numEl && STORE.recordDay) animCount(numEl, STORE.recordDay.plays, 1600);
          }, 400);
        }, 200);
        break;

      case 'gotaway':
        setTimeout(() => {
          const card = document.getElementById('got-away-card'); fadeIn(card, 0);
          setTimeout(() => {
            const ga = STORE.gotAwayArtist;
            if (!ga) return;
            const maxVal = Math.max(ga.before, 1);
            const beforePct = 100, afterPct = Math.max(5, Math.round(ga.after/maxVal*100));
            document.querySelectorAll('.timeline-bar--before').forEach(el => {
              el.style.transition='none'; el.style.setProperty('--w','0%');
              setTimeout(()=>{ el.style.transition='--w 1s'; el.style.setProperty('--w',`${beforePct}%`);
                // can't target ::after via inline style, so we inject a div instead
                el.style.background='none'; el.style.position='relative';
                const fill=document.createElement('div');
                fill.style.cssText=`position:absolute;left:0;top:0;bottom:0;width:0%;background:rgba(168,85,247,.7);border-radius:4px;transition:width 1.2s cubic-bezier(.22,1,.36,1)`;
                el.appendChild(fill);
                setTimeout(()=>fill.style.width=`${beforePct}%`,50);
              },100);
            });
            document.querySelectorAll('.timeline-bar--after').forEach(el => {
              el.style.background='none'; el.style.position='relative';
              const fill=document.createElement('div');
              fill.style.cssText=`position:absolute;left:0;top:0;bottom:0;width:0%;background:rgba(239,68,68,.65);border-radius:4px;transition:width 1.2s cubic-bezier(.22,1,.36,1)`;
              el.appendChild(fill);
              setTimeout(()=>fill.style.width=`${afterPct}%`,250);
            });
          }, 300);
        }, 200);
        break;

      case 'streak':
        setTimeout(() => {
          const fw = document.getElementById('streak-fire-wrap'); fadeIn(fw, 100);
          setTimeout(() => {
            const pc = document.getElementById('streak-period-card'); fadeIn(pc, 0);
          }, 350);
          setTimeout(() => {
            const bw = document.getElementById('streak-bar-wrap'); fadeIn(bw, 0);
            const fill = document.getElementById('streak-bar-fill');
            const s = STORE.streak;
            if (fill && s) {
              const pct = Math.min(100, Math.round((s.days / 366) * 100));
              setTimeout(() => { fill.style.transition='width 1.5s cubic-bezier(.22,1,.36,1)'; fill.style.width=`${pct}%`; }, 100);
            }
            const numEl = document.getElementById('streak-num');
            if (numEl && s?.days) animCount(numEl, s.days, 1200);
          }, 600);
        }, 200);
        break;

      case 'vibe':
        setTimeout(() => {
          fadeIn(document.getElementById('vibe-hero'), 100);
          setTimeout(() => fadeIn(document.getElementById('vibe-badges'), 0), 350);
        }, 200);
        break;

      case 'genres':
        setTimeout(() => {
          fadeIn(document.getElementById('genres-chart-wrap'), 100);
          setTimeout(() => fadeIn(document.getElementById('genres-legend'), 0), 300);
          setTimeout(() => fadeIn(document.getElementById('genres-evolution'), 0), 500);
          buildRadarChart();
          setTimeout(() => { if (_radarChart) { try { _radarChart.resize(); } catch {} } }, 400);
        }, 200);
        break;

      case 'leaderboard':
        setTimeout(() => {
          document.querySelectorAll('.lb-item').forEach((el, i) => {
            el.style.opacity='0'; el.style.transform='translateX(-16px)';
            setTimeout(() => {
              el.style.transition='opacity .38s ease, transform .4s cubic-bezier(.22,1,.36,1)';
              el.style.opacity='1'; el.style.transform='translateX(0)';
            }, 200 + i * 80);
          });
        }, 300);
        break;

      case 'recap':
        this._bindRecapButtons();
        break;
    }
  }
};


function buildRadarChart() {
  const canvas = document.getElementById('genres-radar-chart');
  if (!canvas) return;

  // lazy-load Chart.js if not already there
  const loadChartJs = () => new Promise((resolve, reject) => {
    if (window.Chart) { resolve(); return; }
    // Chart.js déjà chargé depuis le CDN en <head> — fallback si absent
    const s = document.createElement('script');
    s.src = 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js';
    s.onload = resolve; s.onerror = () => resolve(); // ne pas bloquer
    document.head.appendChild(s);
  });

  const COLORS = ['#f43f5e','#d0bcff','#60a5fa','#34d399','#fbbf24','#f472b6','#38bdf8','#a78bfa'];
  const tags = STORE.tags.slice(0, 8);
  if (!tags.length) return;

  // valeurs simulées décroissantes avec un peu d'aléatoire, ça donne un look naturel
  const data = tags.map((_, i) => Math.max(10, Math.round(100 - i*11 + (Math.random()*12-6))));

  loadChartJs().then(() => {
    if (_radarChart) { try { _radarChart.destroy(); } catch {} _radarChart = null; }
    _radarChart = new Chart(canvas, {
      type: 'radar',
      data: {
        labels: tags.map(t => t.length > 12 ? t.slice(0,10)+'…' : t),
        datasets: [
          {
          data,
          backgroundColor: 'rgba(208,188,255,.12)',
          borderColor: '#d0bcff',
          borderWidth: 2,
          pointBackgroundColor: COLORS,
          pointBorderColor: 'rgba(230,225,229,.6)',
          pointRadius: 4,
          label: T.lbYou||'Toi',
          },
          {
            label: T.genresGlobalLabel||'Moy. mondiale',
            data: tags.map((tag, i) => {
              const known = ['rock','pop','hip-hop','electronic','r&b','indie','metal','jazz','folk'];
              const idx = known.findIndex(g => tag.toLowerCase().includes(g));
              return Math.max(5, (idx >= 0 ? 70 - idx*6 : 35) + (Math.random()*12-6));
            }),
            backgroundColor: 'rgba(96,165,250,.06)',
            borderColor: 'rgba(96,165,250,.45)',
            borderWidth: 1.5,
            borderDash: [4,3],
            pointBackgroundColor: 'rgba(96,165,250,.6)',
            pointRadius: 3,
          }
        ],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        animation: { duration: Infinity, easing: 'easeOutQuart' },
        scales: {
          r: {
            min: 0, max: 100,
            grid:       { color: 'rgba(147,143,153,.15)' },
            angleLines: { color: 'rgba(147,143,153,.15)' },
            ticks: { display: false, stepSize: 25 },
            pointLabels: {
              color: 'rgba(230,225,229,.6)',
              font: { family: "'Inter',sans-serif", size: 11, weight: '600' },
            },
          },
        },
        plugins: { legend: { display: true, position: 'bottom', labels: { color: 'rgba(230,225,229,.55)', font: { size: 10 }, boxWidth: 12, padding: 8 } }, tooltip: { enabled: false } },
      },
    });
  }).catch(err => console.warn('Chart.js pas chargé :', err));
}

const ExportManager = {
  _imgCache: new Map(),

  // convert all images to data URLs before capture
  async _bakeImages(root) {
    const jobs = [];
    root.querySelectorAll('img[src]').forEach(img => {
      if (!img.src || img.src.startsWith('data:') || this._imgCache.has(img.src)) return;
      jobs.push(fetchDataUrl(img.src).then(d => { if (d !== img.src) this._imgCache.set(img.src, d); }));
    });
    root.querySelectorAll('[style]').forEach(el => {
      const m = (el.style.backgroundImage || '').match(/url\(['"]?([^'"\)\s]+)['"]?\)/);
      if (!m || !m[1] || m[1].startsWith('data:') || this._imgCache.has(m[1])) return;
      jobs.push(fetchDataUrl(m[1]).then(d => { if (d !== m[1]) this._imgCache.set(m[1], d); }));
    });
    await Promise.allSettled(jobs);
  },

  _fixClone(doc) {
    doc.querySelectorAll('*').forEach(el => {
      el.style.backdropFilter = 'none';
      el.style.webkitBackdropFilter = 'none';
      el.style.animation = 'none';
      el.style.transition = 'none';
    });
    doc.querySelectorAll('.anim-rise,.anim-pop,.anim-fade').forEach(el => {
      el.style.opacity='1'; el.style.transform='none';
    });
  },
  _roundCorners(canvas, r) {
    const ctx = canvas.getContext('2d'), W = canvas.width, H = canvas.height;
    ctx.globalCompositeOperation = 'destination-in';
    ctx.beginPath(); ctx.moveTo(r,0); ctx.lineTo(W-r,0); ctx.quadraticCurveTo(W,0,W,r);
    ctx.lineTo(W,H-r); ctx.quadraticCurveTo(W,H,W-r,H); ctx.lineTo(r,H);
    ctx.quadraticCurveTo(0,H,0,H-r); ctx.lineTo(0,r); ctx.quadraticCurveTo(0,0,r,0);
    ctx.closePath(); ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  },
  _watermark(canvas) {
    const ctx = canvas.getContext('2d'), W = canvas.width, H = canvas.height;
    const bH = Math.round(H * .055);
    const g = ctx.createLinearGradient(0, H-bH*2, 0, H);
    g.addColorStop(0,'rgba(0,0,0,0)'); g.addColorStop(1,'rgba(0,0,0,.7)');
    ctx.fillStyle = g; ctx.fillRect(0, H-bH*2, W, bH*2);
    const fs = Math.round(W * .02);
    ctx.fillStyle = 'rgba(255,255,255,.45)';
    ctx.font = `700 ${fs}px Arial,sans-serif`;
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText(`LASTSTATS · ${WRAPPED_YEAR}`, W/2, H - bH * .7);
  },
  _download(canvas, name) {
    const a = document.createElement('a');
    a.download = name; a.href = canvas.toDataURL('image/png', .95); a.click();
  },

  async story() {
    if (!window.html2canvas) { showToast('html2canvas non disponible'); return; }
    const stage = document.getElementById('export-story');
    if (!stage) return;
    const a1 = STORE.artists[0];
    const imgEl = document.getElementById('export-story-artist-img');
    if (imgEl && STORE.artist1Img) imgEl.src = STORE.artist1Img;
    const bgEl = document.getElementById('export-story-bg');
    if (bgEl && STORE.artist1Img) bgEl.style.backgroundImage = `url('${STORE.artist1Img}')`;
    const setT = (id,v) => { const e=document.getElementById(id); if(e) e.textContent=v; };
    setT('export-story-user', STORE.displayName);
    setT('export-story-year', WRAPPED_YEAR);
    setT('export-story-artist-name', a1?.name||'—');
    setT('es-scrobbles', fmtNum(STORE.annualPlays));
    setT('es-artists', fmtNum(STORE._uniqueArtists||STORE.artists.length));
    setT('es-minutes', fmtNum(STORE.listenMins));
    stage.style.left = '-9999px'; stage.style.top = '0';
    await this._bakeImages(stage);

    try {
      const canvas = await html2canvas(stage, {
        backgroundColor: '#141218', scale: 2, useCORS: true, logging: false,
        width: 360, height: 640,
        onclone: (doc) => this._fixClone(doc),
      });
      this._roundCorners(canvas, Math.round(canvas.width * .03));
      this._download(canvas, `laststats-story-${WRAPPED_YEAR}.png`);
    } catch (e) { console.error('story export:', e); showToast('Erreur export'); }
    finally { stage.style.left = ''; stage.style.top = ''; }
  },

  async card() {
    if (!window.html2canvas) { showToast('html2canvas non disponible'); return; }
    const stage = document.getElementById('export-card');
    if (!stage) return;
    const setT = (id,v) => { const e=document.getElementById(id); if(e) e.textContent=v; };
    const bgEl = document.getElementById('export-card-bg');
    if (bgEl && STORE.artist1Img) bgEl.style.backgroundImage = `url('${STORE.artist1Img}')`;
    setT('export-card-year', WRAPPED_YEAR);
    setT('export-card-user', `@${STORE.username}`);
    setT('ec-scrobbles', fmtNum(STORE.annualPlays));
    setT('ec-artists', fmtNum(STORE._uniqueArtists||STORE.artists.length));
    setT('ec-albums', fmtNum(STORE.albums.length));
    setT('ec-minutes', fmtNum(STORE.listenMins));
    // build the podium for the card
    const podDiv = document.getElementById('export-card-podium');
    if (podDiv) {
      podDiv.innerHTML = STORE.artists.slice(0,3).map((a,i) => {
        const img = a._img||''; const sizes=['80px','100px','80px']; const orders=[1,0,2];
        return `<div style="display:flex;flex-direction:column;align-items:center;gap:6px;order:${orders[i]};flex:1">
          <div style="width:${sizes[i]};height:${sizes[i]};border-radius:10px;overflow:hidden">${imgOrInitials(img,a.name)}</div>
          <div style="font-family:'Bebas Neue',cursive;font-size:14px;color:#fff;text-align:center;max-width:90px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(a.name)}</div>
          <div style="font-size:10px;color:rgba(255,255,255,.5)">${fmtNum(a.playcount)}</div>
        </div>`;
      }).join('');
    }
    stage.style.left = '-9999px'; stage.style.top = '0';
    await this._bakeImages(stage);
    try {
      const canvas = await html2canvas(stage, {
        backgroundColor: '#141218', scale: 2, useCORS: true, logging: false,
        width: 680, height: 860,
        onclone: (doc) => this._fixClone(doc),
      });
      this._roundCorners(canvas, Math.round(canvas.width * .025));
      this._watermark(canvas);
      this._download(canvas, `laststats-card-${WRAPPED_YEAR}.png`);
    } catch (e) { console.error('card export:', e); showToast('Erreur export'); }
    finally { stage.style.left = ''; stage.style.top = ''; }
  },

  // Instagram / TikTok 1080x1920 canvas-drawn
  async instagram() {
    const canvas = document.getElementById('export-insta-canvas');
    if (!canvas) { showToast('Canvas not found'); return; }
    const ctx = canvas.getContext('2d');
    const W = 1080, H = 1920;
    canvas.width = W; canvas.height = H;
    const [dr, dg, db] = STORE._dynColor || [79, 55, 139];
    const bg = ctx.createLinearGradient(0,0,W,H);
    bg.addColorStop(0, `rgb(${Math.max(0,dr-40)},${Math.max(0,dg-40)},${Math.max(0,db-40)})`);
    bg.addColorStop(.5, '#141218');
    bg.addColorStop(1, `rgb(${Math.max(0,dr-60)},${Math.max(0,dg-60)},${Math.max(0,db-60)})`);
    ctx.fillStyle = bg; ctx.fillRect(0,0,W,H);
    const glow = ctx.createRadialGradient(W*.3,H*.3,0,W*.3,H*.3,W*.8);
    glow.addColorStop(0,`rgba(${dr},${dg},${db},.35)`); glow.addColorStop(1,'transparent');
    ctx.fillStyle = glow; ctx.fillRect(0,0,W,H);
    const albumSrc = STORE.artist1Img || getImg(STORE.albums[0]?.image||[],'extralarge');
    if (albumSrc) {
      try {
        const aImg = new Image(); aImg.crossOrigin='anonymous';
        await new Promise((res,rej)=>{ aImg.onload=res; aImg.onerror=rej; aImg.src=albumSrc; });
        const S=720, X=(W-S)/2, Y=280, r=40;
        ctx.save();
        ctx.beginPath();
        ctx.moveTo(X+r,Y); ctx.lineTo(X+S-r,Y); ctx.quadraticCurveTo(X+S,Y,X+S,Y+r);
        ctx.lineTo(X+S,Y+S-r); ctx.quadraticCurveTo(X+S,Y+S,X+S-r,Y+S);
        ctx.lineTo(X+r,Y+S); ctx.quadraticCurveTo(X,Y+S,X,Y+S-r);
        ctx.lineTo(X,Y+r); ctx.quadraticCurveTo(X,Y,X+r,Y); ctx.closePath(); ctx.clip();
        ctx.drawImage(aImg,X,Y,S,S); ctx.restore();
      } catch {}
    }
    ctx.textAlign='center';
    ctx.font='bold 42px Arial,sans-serif';
    ctx.fillStyle=`rgba(${Math.min(255,dr+120)},${Math.min(255,dg+120)},${Math.min(255,db+120)},.7)`;
    ctx.fillText('LASTSTATS',W/2,140);
    ctx.font='bold 36px Arial,sans-serif'; ctx.fillStyle='rgba(255,255,255,.4)';
    ctx.fillText(String(WRAPPED_YEAR),W/2,196);
    const aY=280+720;
    ctx.font='bold 58px Arial,sans-serif'; ctx.fillStyle='#fff';
    ctx.fillText(STORE.displayName,W/2,aY+100);
    if (STORE.artists[0]) {
      ctx.font='36px Arial,sans-serif'; ctx.fillStyle='rgba(255,255,255,.5)';
      ctx.fillText('#1 · '+STORE.artists[0].name,W/2,aY+162);
    }
    ctx.strokeStyle=`rgba(${Math.min(255,dr+80)},${Math.min(255,dg+80)},${Math.min(255,db+80)},.3)`;
    ctx.lineWidth=1; ctx.beginPath(); ctx.moveTo(W*.2,aY+208); ctx.lineTo(W*.8,aY+208); ctx.stroke();
    const stats=[{v:fmtNum(STORE.annualPlays),l:T.scrobbles||'écoutes'},{v:fmtNum(STORE._uniqueArtists||STORE.artists.length),l:T.artists||'artistes'},{v:`${fmtNum(STORE.listenHours)}h`,l:T.hours||'heures'}];
    stats.forEach((s,i)=>{
      const cx=W/3*i+W/6;
      ctx.font='bold 62px Arial,sans-serif';
      ctx.fillStyle=`rgb(${Math.min(255,dr+130)},${Math.min(255,dg+130)},${Math.min(255,db+130)})`;
      ctx.fillText(s.v,cx,aY+308);
      ctx.font='28px Arial,sans-serif'; ctx.fillStyle='rgba(255,255,255,.4)';
      ctx.fillText(s.l.toUpperCase(),cx,aY+358);
    });
    ctx.font='22px Arial,sans-serif'; ctx.fillStyle='rgba(255,255,255,.18)';
    ctx.fillText('laststats.github.io',W/2,H-60);
    this._roundCorners(canvas,60);
    this._download(canvas,`laststats-instagram-${WRAPPED_YEAR}.png`);
    showToast('📸 1080×1920 téléchargé !');
  },

  async screenshot() {
    if (!window.html2canvas) { showToast('html2canvas non disponible'); return; }
    const btn = document.getElementById('screenshot-btn');
    if (btn) { btn.textContent = '⏳'; btn.classList.add('capturing'); }
    try {
      // Capture the currently active slide element
      const sl = SLIDES[Stories.current];
      const slideEl = document.getElementById(`slide-${sl?.id}`);
      const targetEl = slideEl || document.getElementById('stories');
      if (targetEl) await this._bakeImages(targetEl);
      const canvas = await html2canvas(targetEl, {
        backgroundColor: '#141218', scale: Math.min(window.devicePixelRatio || 2, 3),
        useCORS: true, logging: false,
        ignoreElements: el => ['screenshot-btn','hud','nav-prev-btn','nav-next-btn','nav-prev','nav-next','modal-share','slides-scroll'].includes(el.id),
        onclone: (doc) => {
          this._fixClone(doc);
          // Fix animated bar heights
          doc.querySelectorAll('.week-bar-fill').forEach(el => {
            const pct = parseInt(el.dataset.pct||0); el.style.height=`${pct}%`;
          });
          // Fix gauge — use DOC not document
          const fill = doc.getElementById('gauge-fill');
          const gs = STORE.globalStats;
          if (fill && gs?.percentile && gs.percentile!=='—') {
            const arc = Math.round((100-parseInt(gs.percentile))*283/100);
            fill.style.strokeDasharray=`${arc} 283`;
            fill.style.transition='none';
          }
          // Fix track bars
          doc.querySelectorAll('.track-bar').forEach((el,i) => {
            const pct=Math.round((parseInt(STORE.tracks[i]?.playcount||0)/Math.max(1,parseInt(STORE.tracks[0]?.playcount||1)))*100);
            el.style.setProperty('--w',`${pct}%`);
            el.style.width=`${pct}%`;
            el.style.transition='none';
          });
          // fix streak bar width
          const sf = doc.getElementById('streak-bar-fill');
          const sk = STORE.streak;
          if (sf && sk) { const p=Math.min(100,Math.round(sk.days/366*100)); sf.style.width=`${p}%`; sf.style.transition='none'; }
          // fix timeline bar widths
          doc.querySelectorAll('.timeline-bar').forEach(el => {
            const fill2=el.querySelector('div');
            if(fill2) fill2.style.transition='none';
          });
          // hide ambient effects that don't export well
          const amb=doc.getElementById('ambient'); if(amb) amb.style.opacity='1';
          const grain=doc.getElementById('grain'); if(grain) grain.style.display='none';
          const canvas2=doc.getElementById('particle-canvas'); if(canvas2) canvas2.style.display='none';
          // swap in cached data URLs to avoid CORS issues
          doc.querySelectorAll('img[src]').forEach(img => {
            const cached = ExportManager._imgCache.get(img.src);
            if (cached) img.src = cached;
          });
          // same for background images
          doc.querySelectorAll('[style]').forEach(el => {
            const m = el.style.backgroundImage.match(/url\(['"]?([^'")\s]+)['"]?\)/);
            if (!m) return;
            const cached = ExportManager._imgCache.get(m[1]);
            if (cached) el.style.backgroundImage = `url('${cached}')`;
          });
          // make sure all animated elements are visible
          doc.querySelectorAll('[style*="opacity:0"], .anim-rise, .anim-pop, .anim-fade').forEach(el => {
            el.style.opacity='1'; el.style.transform='none'; el.style.transition='none';
          });
        },
      });
      const slCurrent = SLIDES[Stories.current];
      this._roundCorners(canvas, Math.round(canvas.width * .025));
      this._watermark(canvas);
      this._download(canvas, `laststats-${WRAPPED_YEAR}-${slCurrent.id}.png`);
      if (btn) { btn.textContent = '✅'; setTimeout(() => { if(btn) btn.textContent='📷'; }, 2200); }
    } catch (err) {
      console.error('screenshot:', err);
      if (btn) { btn.textContent = '❌'; setTimeout(() => { if(btn) btn.textContent='📷'; }, 2200); }
    } finally {
      if (btn) btn.classList.remove('capturing');
    }
  }
};

function openShareModal() {
  const modal = document.getElementById('modal-share');
  if (!modal) return;
  modal.classList.remove('hidden');
}
function closeShareModal() {
  const modal = document.getElementById('modal-share');
  if (modal) modal.classList.add('hidden');
}

// overlay vue partagée
function populateSharePreview(data) {
  const setT = (id,v) => { const e=document.getElementById(id); if(e) e.textContent=v; };
  const setI = (id,s) => { const e=document.getElementById(id); if(e) e.src=s; };
  setI('share-avatar', data.av||initialsPlaceholder(data.u||'?'));
  setT('share-username', data.u||'—');
  setT('share-year-tag', `Wrapped ${data.y||'—'}`);
  const qs = document.getElementById('share-quick-stats');
  if (qs && data) {
    qs.innerHTML = [
      `<div><dt>${T.lblScrobbles}</dt><dd>${fmtNum(data.sc)}</dd></div>`,
      `<div><dt>${T.artists}</dt><dd>${data.ar?.length||0}</dd></div>`,
    ].join('');
  }
}

// keyboard handled in Stories._bindNavButtons

// HUD buttons
document.getElementById('screenshot-btn')?.addEventListener('click', e => { e.stopPropagation(); ExportManager.screenshot(); });
document.getElementById('share-btn')?.addEventListener('click', e => { e.stopPropagation(); openShareModal(); });
document.getElementById('exit-btn')?.addEventListener('click', () => {
  document.getElementById('stories')?.classList.add('hidden');
  document.getElementById('overlay-creds')?.classList.remove('hidden');
});

// modal de partage buttons
document.getElementById('modal-copy-link')?.addEventListener('click', async () => { closeShareModal(); await copyShareLink(); });
document.getElementById('modal-web-share')?.addEventListener('click', async () => { closeShareModal(); await nativeShare(); });
document.getElementById('modal-export-card')?.addEventListener('click', () => { closeShareModal(); ExportManager.card(); });
document.getElementById('modal-screenshot')?.addEventListener('click', () => { closeShareModal(); ExportManager.screenshot(); });
document.getElementById('modal-share-close')?.addEventListener('click', closeShareModal);
document.getElementById('modal-share-backdrop')?.addEventListener('click', closeShareModal);

// shared view overlay
document.getElementById('share-enter-btn')?.addEventListener('click', async () => {
  document.getElementById('overlay-share-view')?.classList.add('hidden');
  document.getElementById('stories')?.classList.remove('hidden');
  Stories.init();
  // warm up image cache for screenshots
  if (STORE._shareImages?.length) {
    STORE._shareImages.forEach(url => {
      if (url && !ExportManager._imgCache.has(url)) {
        fetchDataUrl(url).then(d => { if (d && d !== url) ExportManager._imgCache.set(url, d); });
      }
    });
  }
});

// password toggle
document.getElementById('toggle-pw')?.addEventListener('click', () => {
  const inp = document.getElementById('inp-key'); if (!inp) return;
  inp.type = inp.type === 'password' ? 'text' : 'password';
});

// navigation clavier + swipe gérés dans Stories._bindNavButtons / _bindSwipe

// mise à jour du loader
function showLoader(msg, pct) {
  const lt = document.getElementById('loader-text'), lb = document.getElementById('loader-bar'), pt = document.getElementById('loader-pct');
  if (lt && msg) lt.textContent = msg;
  if (lb) lb.style.width = `${pct}%`;
  if (pt) pt.textContent = `${Math.round(pct)}%`;
}



async function startWrapped(username, apiKey) {
  WRAPPED_YEAR = parseInt(document.getElementById('inp-year')?.value) || (new Date().getFullYear() - 1);
  STORE.username = username.trim(); STORE.apiKey = apiKey.trim();
  STORE.user = null; STORE.tracks = []; STORE.albums = []; STORE.artists = [];
  STORE.tags = []; STORE.artist1Img = ''; STORE.annualPlays = 0;
  STORE._uniqueArtists = 0; STORE._uniqueTracks = 0;
  STORE.habitHours = []; STORE.habitDays = []; STORE.habitMonthPeak = {month:-1,plays:0};
  STORE.recordDay = null; STORE.gotAwayArtist = null; STORE.globalStats = {};
  STORE.streak = null; STORE.dayMap = null;
  STORE.isReadOnly = false;
  STORE.friendsData = []; STORE.globalChart = []; STORE.leaderboard = null; STORE._dynColor = null;

  const errEl = document.getElementById('cred-error'), submitEl = document.getElementById('cred-submit');
  if (errEl) errEl.hidden = true;
  if (submitEl) submitEl.disabled = true;
  document.getElementById('overlay-creds')?.classList.add('hidden');
  document.getElementById('overlay-loading')?.classList.remove('hidden');

  try { await loadAllData((msg, pct) => showLoader(msg, pct)); }
  catch (err) {
    document.getElementById('overlay-loading')?.classList.add('hidden');
    document.getElementById('overlay-creds')?.classList.remove('hidden');
    if (submitEl) submitEl.disabled = false;
    if (errEl) { errEl.textContent = `Erreur : ${err.message}`; errEl.hidden = false; }
    return;
  }

  showLoader(T.loadStep8, 100); await new Promise(r => setTimeout(r, 420));

  if (document.getElementById('inp-remember')?.checked) {
    try {
      localStorage.setItem('ls_username', STORE.username);
      localStorage.setItem('ls_apikey', STORE.apiKey);
      localStorage.setItem('ls_year', String(WRAPPED_YEAR));
    } catch {}
  }

  document.getElementById('overlay-loading')?.classList.add('hidden');
  document.getElementById('stories')?.classList.remove('hidden');
  Stories.init();
}

document.getElementById('cred-submit')?.addEventListener('click', async () => {
  const user = document.getElementById('inp-user')?.value?.trim();
  const key = document.getElementById('inp-key')?.value?.trim();
  const errEl = document.getElementById('cred-error');
  if (!user) { if (errEl) { errEl.textContent = T.errNoUser; errEl.hidden = false; } return; }
  if (!key || key.length < 20) { if (errEl) { errEl.textContent = T.errNoKey; errEl.hidden = false; } return; }
  await startWrapped(user, key);
});
['inp-user','inp-key'].forEach(id =>
  document.getElementById(id)?.addEventListener('keydown', e => { if (e.key === 'Enter') document.getElementById('cred-submit')?.click(); })
);

// choix de la langue
document.querySelectorAll('.lang-btn').forEach(btn => btn.addEventListener('click', () => {
  setLang(btn.dataset.lang);
  document.getElementById('overlay-lang')?.classList.add('hidden');
  document.getElementById('overlay-creds')?.classList.remove('hidden');
}));
document.getElementById('lang-change-btn')?.addEventListener('click', () => {
  document.getElementById('overlay-creds')?.classList.add('hidden');
  document.getElementById('overlay-lang')?.classList.remove('hidden');
});

// démarrage
document.addEventListener('DOMContentLoaded', () => {
  let savedLang; try { savedLang = localStorage.getItem('ls_lang'); } catch {}
  setLang(savedLang || autoDetectLang());

  // mode partage (?share= dans l'URL)
  const urlParams = new URLSearchParams(location.search);
  const shareParam = urlParams.get('share');
  if (shareParam) {
    const data = parseShareParam(shareParam);
    if (data) {
      populateStoreFromShareData(data);
      populateSharePreview(data);
      applyLangToDOM();
      document.getElementById('overlay-lang')?.classList.add('hidden');
      document.getElementById('overlay-creds')?.classList.add('hidden');
      document.getElementById('overlay-share-view')?.classList.remove('hidden');
      return;
    }
  }

  // mode normal
  const now = new Date();
  const isDecember = now.getMonth() === 11;

  // --- peuple le sélecteur d'année (fait ça tout de suite, pas seulement hors-décembre)
  const sel = document.getElementById('inp-year');
  if (sel) {
    const cur = now.getFullYear(), last = cur - 1;
    sel.innerHTML = '';
    for (let y = last; y >= 2003; y--) {
      const o = document.createElement('option');
      o.value = y; o.textContent = y;
      if (y === last) o.selected = true;
      sel.appendChild(o);
    }
    sel.addEventListener('change', () => {
      WRAPPED_YEAR = parseInt(sel.value) || WRAPPED_YEAR;
      const badge = document.getElementById('year-badge');
      const hint  = document.getElementById('year-hint');
      const selectedYear = parseInt(sel.value);
      if (badge) badge.textContent = selectedYear === cur-1 ? '' : T.yearbadgeArchive||'Archive';
      if (hint)  hint.textContent = '';
    });
    let saved; try { saved = parseInt(localStorage.getItem('ls_year')) || last; } catch { saved = last; }
    sel.value = String(Math.min(saved, last));
  }

  if (isDecember) {
    // compte à rebours en décembre
    document.getElementById('overlay-lang')?.classList.add('hidden');
    document.getElementById('overlay-wait')?.classList.remove('hidden');
    applyLangToDOM();
    startCountdown();

    // boutons années précédentes
    const archivesEl = document.getElementById('wait-archives');
    const archivesList = document.getElementById('wait-archives-list');
    if (archivesEl && archivesList) {
      const cur = now.getFullYear();
      // 5 ans max
      for (let y = cur - 1; y >= Math.max(cur - 5, 2006); y--) {
        const btn = document.createElement('button');
        btn.className = 'archive-year-btn';
        btn.textContent = String(y);
        btn.addEventListener('click', () => {
          document.getElementById('overlay-wait')?.classList.add('hidden');
          document.getElementById('overlay-creds')?.classList.remove('hidden');
          const sel = document.getElementById('inp-year');
          if (sel) sel.value = String(y);
        });
        archivesList.appendChild(btn);
      }
      archivesEl.hidden = false;
    }
    return;
  }

  // si l'utilisateur avait coché "se souvenir de moi"
  let savedUser = '', savedKey = '';
  try { savedUser = localStorage.getItem('ls_username') || ''; savedKey = localStorage.getItem('ls_apikey') || ''; } catch {}
  if (savedUser) { const e = document.getElementById('inp-user'); if (e) e.value = savedUser; }
  if (savedKey)  { const e = document.getElementById('inp-key');  if (e) e.value = savedKey; }

  // langue déjà choisie, on saute l'écran
  if (savedLang) {
    document.getElementById('overlay-lang')?.classList.add('hidden');
    document.getElementById('overlay-creds')?.classList.remove('hidden');
  }
});
