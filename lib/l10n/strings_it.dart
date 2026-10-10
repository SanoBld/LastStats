// lib/l10n/strings_it.dart
// ══════════════════════════════════════════════════════════════════════════
//  Italian
// ══════════════════════════════════════════════════════════════════════════

import "app_strings.dart";

class AppStringsIt implements AppStrings {
  const AppStringsIt();

  @override String get period7day => 'Settimana';
  @override String get period1month => 'Mese';
  @override String get period3month => '3 mesi';
  @override String get period6month => '6 mesi';
  @override String get period12month => 'Anno';
  @override String get periodOverall => 'Sempre';
  @override String get navDashboard => 'Panoramica';
  @override String get navSearch => 'Cerca';
  @override String get navRankings => 'Classifiche';
  @override String get navCharts => 'Grafici';
  @override String get navHistory => 'Cronologia';
  @override String get navSettings => 'Impostazioni';
  @override String get cacheTitle => 'Archiviazione';
  @override String get cacheUsage => 'Utilizzo';
  @override String get cacheLimit => 'Limite di archiviazione';
  @override String get cacheLimitHint => 'Al raggiungimento del limite, le immagini usate meno di recente vengono eliminate automaticamente.';
  @override String get cacheClearSection => 'Svuota';
  @override String get cacheImages => 'Immagini';
  @override String get cacheImagesSubtitle => 'Copertine di artisti, album e brani';
  @override String get cacheApiData => 'Dati API';
  @override String get cacheApiDataSubtitle => 'Artisti principali, album, brani recenti…';
  @override String get cacheScrobbles => 'Cronologia scrobble';
  @override String get cacheScrobblesSubtitle => 'Tutti gli scrobble scaricati';
  @override String get cacheClearBtn => 'Svuota';
  @override String get cacheConfirmScrobblesTitle => 'Cancellare la cronologia scrobble?';
  @override String get cacheConfirmScrobblesBody => 'L\'intera cronologia verrà eliminata e riscaricata al prossimo avvio.';
  @override String get cacheConfirmAllTitle => 'Cancellare tutta la cache?';
  @override String get cacheConfirmAllBody => 'Immagini, dati API e cronologia scrobble verranno tutti eliminati.';
  @override String get cacheDelete => 'Elimina';
  @override String get commonArtists => 'Artisti';
  @override String get commonAlbums => 'Album';
  @override String get commonTracks => 'Brani';
  @override String get commonNoResults => 'Nessun risultato';
  @override String get commonRetry => 'Riprova';
  @override String get commonCancel => 'Annulla';
  @override String get commonApply => 'Applica';
  @override String get commonPlays => 'riproduzioni';
  @override String get commonListeners => 'ascoltatori';
  @override String get commonNowPlayingBadge => 'LIVE';
  @override String get commonNowPlayingLong => 'In riproduzione';
  @override String get commonRecentTracks => 'Brani recenti';
  @override String get commonNoRecentTracks => 'Nessun brano recente';
  @override String get commonTopArtists => 'Artisti principali';
  @override String get rankingsTitle => 'Classifiche';
  @override String get rankingsPodium => 'Podio';
  @override String get rankingsContinued => 'Resto della classifica';
  @override String get rankingsAllYears => 'Tutti gli anni';
  @override String get chartsTitle => 'Grafici';
  @override String get chartsMonthly => 'Scrobble (12 mesi)';
  @override String get chartsArtistDist => 'Artisti principali (ripartizione)';
  @override String get chartsMainstreamTitle => 'Mainstream vs Perle nascoste';
  @override String get chartsMainstreamSubtitle => 'Popolarità globale dei suoi artisti preferiti.';
  @override String get chartsCompute => 'Calcola';
  @override String get chartsRecompute => 'Ricalcola';
  @override String get chartsGem => 'Perla nascosta';
  @override String get chartsMainstream => 'Mainstream';
  @override String get historyTitle => 'Cronologia';
  @override String get historySubtitle => 'I suoi ascolti, giorno per giorno';
  @override String get historyToday => 'Oggi';
  @override String get historySelectDate => 'Seleziona una data';
  @override String get historyChronological => 'Cronologico';
  @override String get historyList => 'Elenco';
  @override String get historyStats => 'Statistiche';
  @override String get historyNoTracks => 'Nessun ascolto in questo giorno';
  @override String get historyTopArtists => 'Artisti principali';
  @override String get historyTopAlbums => 'Album principali';
  @override String get historyTopTracks => 'Brani principali';
  @override String get historyHourTracks => 'brano';
  @override String get searchTitle => 'Cerca';
  @override String get searchProfiles => 'Profili';
  @override String get searchHintBar => 'Artista, album, brano o profilo…';
  @override String get searchHintProfiles => 'Trova un utente Last.fm';
  @override String get searchHintArtists => 'Trova un artista';
  @override String get searchHintAlbums => 'Trova un album';
  @override String get searchHintTracks => 'Trova un brano';
  @override String get searchTypePrompt => 'Digiti nella barra di ricerca sopra';
  @override String get searchAll => 'Tutti';
  @override String get searchFolders => 'Cartelle';
  @override String get searchFoldersHint => 'Crei una cartella per salvare brani, album o artisti.';
  @override String get perDay => 'al giorno';
  @override String get activityDays => 'giorni attivi';
  @override String get dashStats => 'Statistiche';
  @override String get dashTopTracks => 'Brani principali';
  @override String get dashFriends => 'Amici';
  @override String get dashRefresh => 'Aggiorna';
  @override String get dashRefreshFriends => 'Aggiorna amici';
  @override String get dashScrobbles => 'scrobble';
  @override String get dashScrobblesPerDay => 'al giorno';
  @override String get dashDaysActive => 'giorni attivi';
  @override String get dashLastTrack => 'Ultimo ascoltato';
  @override String get dashArtist1 => 'Artista n. 1';
  @override String get dashAlbum1 => 'Album n. 1';
  @override String get dashTrack1 => 'Brano n. 1';
  @override String get dashNoFriends => 'Nessun amico trovato';
  @override String get dashResetCache => 'Reimposta cache';
  @override String get dashResetCacheConfirm => 'Tutti i dati scrobble salvati localmente verranno eliminati e riscaricati da Last.fm.';
  @override String get dashFriendsActivity => 'Attività dei suoi amici Last.fm';
  @override String get settingsTitle => 'Impostazioni';
  @override String get settingsAppearance => 'Aspetto';
  @override String get settingsTheme => 'Tema';
  @override String get settingsThemeAuto => 'Automatico';
  @override String get settingsThemeLight => 'Chiaro';
  @override String get settingsThemeDark => 'Scuro';
  @override String get settingsAccentColor => 'Colore accento';
  @override String get settingsAccentAuto => 'Automatico';
  @override String get settingsCustomColor => 'Personalizzato';
  @override String get settingsCustomColorEdit => 'Modifica';
  @override String get settingsDynamicColor => 'Colore dinamico';
  @override String get settingsDayNightAccent          => 'Accento giorno/notte';
  @override String get settingsDayNightAccentToggle    => 'Colori diversi giorno/notte';
  @override String get settingsDayNightAccentToggleSub => 'Usa un colore di accento diverso per il tema scuro.';
  @override String get settingsDayNightAccentDark      => 'Colore (tema scuro)';
  @override String get settingsDayNightUseHours        => 'Usa orari specifici';
  @override String get settingsDayNightUseHoursSub     => "Cambia colore in base all'ora invece che al tema attivo.";
  @override String get settingsDayNightDayStart        => 'Il giorno inizia alle';
  @override String get settingsDayNightNightStart      => 'La notte inizia alle';
  @override String get settingsMaterialYou => 'Material You';
  @override String get settingsMaterialYouSub => 'Usa il colore dello sfondo Android';
  @override String get settingsMusicColor => 'Colore dalla musica';
  @override String get settingsMusicColorSub => 'Estrae il colore dalla copertina dell\'album attuale';
  @override String get settingsMusicColorNote => 'Il colore dominante della copertina attuale sostituisce l\'accento.';
  @override String get settingsMusicColorLocked => 'Disattivi prima Material You';
  @override String get settingsStartupPage => 'Pagina di avvio';
  @override String get settingsStartupTab => 'Scheda all\'avvio';
  @override String get settingsDashboardSection => 'Panoramica';
  @override String get settingsHeaderImage => 'Immagine di intestazione';
  @override String get settingsHeaderImageSub => 'La copertina scelta viene mostrata come sfondo della home.';
  @override String get settingsHeaderSource => 'Fonte';
  @override String get settingsHeaderPeriod => 'Periodo';
  @override String get settingsHeaderAnimation => 'Transizione';
  @override String get settingsHeaderAnimationSub => 'Animazione quando cambia la copertina.';
  @override String get settingsHeaderBlur => 'Sfocatura';
  @override String get settingsHeaderBlurNone => 'Nessuna';
  @override String get settingsHeaderCustomUrl => 'URL immagine';
  @override String get settingsHeaderCustomUrlHint => 'https://example.com/image.jpg';
  @override String get settingsHeaderCustomUrlSub => 'Incolli l\'URL diretto di un\'immagine (jpg, png, webp…).';
  @override String get settingsHeaderApply => 'Applica';
  @override String get settingsHeaderFallback => 'Immagine predefinita';
  @override String get settingsHeaderFallbackSub => 'Mostrata quando non c\'è musica in riproduzione.';
  @override String get settingsHeaderFallbackUrlLabel => 'URL immagine predefinita';
  @override String get settingsVisibleSections => 'Sezioni visibili';
  @override String get settingsNowPlayingSection => 'In riproduzione';
  @override String get settingsStatsSection => 'Statistiche';
  @override String get settingsTopArtistsSection => 'Artisti principali';
  @override String get settingsTopTracksSection => 'Brani principali';
  @override String get settingsFriendsSection => 'Amici';
  @override String get settingsFriendsSectionSub => 'Attività dei suoi amici Last.fm';
  @override String get settingsAccount => 'Account';
  @override String get settingsConnectedProfile => 'Profilo Last.fm collegato';
  @override String get settingsLogout => 'Disconnetti';
  @override String get settingsLogoutTitle => 'Disconnettersi?';
  @override String get settingsLogoutContent => 'Le sue credenziali verranno eliminate.';
  @override String get settingsLogoutConfirm => 'Disconnetti';
  @override String get settingsBackup => 'Backup e ripristino';
  @override String get settingsExport => 'Esporta impostazioni';
  @override String get settingsExportSub => 'Copia un JSON negli appunti';
  @override String get settingsImport => 'Ripristina un backup';
  @override String get settingsImportSub => 'Incolli un JSON esportato in precedenza';
  @override String get settingsBackupInfo => 'Include: tema, colori, chiave API, nome utente, intestazione, preferiti. Compatibile tra le versioni.';
  @override String get settingsUpdates => 'Aggiornamenti';
  @override String get settingsAutoUpdate => 'Verifica automatica';
  @override String get settingsAutoUpdateSub => 'Una volta al giorno';
  @override String get settingsCheckNow => 'Verifica ora';
  @override String get settingsUpToDate => 'Aggiornato';
  @override String get settingsCheckFailed => 'Verifica non riuscita.';
  @override String get settingsDownload => 'Scarica';
  @override String get settingsViewRelease => 'Visualizza';
  @override String get settingsAbout => 'Info';
  @override String get settingsVersion => 'Versione';
  @override String get settingsWebVersion => 'Versione web';
  @override String get settingsWebVersionSub => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode => 'Codice sorgente';
  @override String get settingsSourceCodeSub => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage => 'Lingua';
  @override String get settingsAboutProjectDesc => 'LastStats è un progetto open-source personale. Potrebbe contenere bug.';
  @override String get settingsAboutSupport => 'Sostieni il progetto';
  @override String get settingsAboutSupportSub => '⭐ Lasci una stella su GitHub';
  @override String get settingsFaq => 'FAQ';
  @override String get headerNowPlaying => 'In riproduzione';
  @override String get headerTopTrack => 'Brano n. 1';
  @override String get headerTopAlbum => 'Album n. 1';
  @override String get headerTopArtist => 'Artista n. 1';
  @override String get headerCustomImage => 'Immagine personalizzata';
  @override String get headerThemeColor => 'Colore del tema';
  @override String get headerAnimNone => 'Nessuna';
  @override String get headerAnimFade => 'Dissolvenza';
  @override String get headerAnimSlide => 'Scorrimento';
  @override String get headerAnimZoom => 'Zoom';
  @override String get headerPeriodWeek => 'Settimana';
  @override String get headerPeriodMonth => 'Mese';
  @override String get headerPeriodAllTime => 'Sempre';
  @override String get colorPickerTitle => 'Colore personalizzato';
  @override String get colorPickerHue => 'Tonalità';
  @override String get colorPickerSaturation => 'Saturazione';
  @override String get colorPickerBrightness => 'Luminosità';
  @override String get colorPickerQuickColors => 'Colori rapidi';
  @override String get colorPickerInvalid => 'Formato non valido';
  @override String get colorCustomTooltip => 'Personalizzato';
  @override String get exportTitle => 'Esporta impostazioni';
  @override String get exportFilename => 'Nome file';
  @override String get exportJsonContent => 'Contenuto JSON';
  @override String get exportInfo => 'Copi questo JSON, lo incolli in un file di testo e lo nomini con .json';
  @override String get exportCopy => 'Copia JSON';
  @override String get exportCopied => 'Copiato!';
  @override String get importTitle => 'Ripristina un backup';
  @override String get importHintLabel => 'Incolli qui il suo backup di LastStats.';
  @override String get importEmpty => 'Il campo è vuoto.';
  @override String get importInvalidJson => 'JSON non valido.';
  @override String get importUnknownFile => 'File non riconosciuto.';
  @override String get importInvalidFormat => 'Formato non valido.';
  @override String get importSuccess => 'Impostazioni ripristinate con successo ✓';
  @override String get importRestore => 'Ripristina';
  @override String get setupImportJson => 'Importa JSON';
  @override String get setupImportHintLabel => 'Incolli qui sotto il contenuto del suo file JSON.';
  @override String get setupImportNote => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields => 'JSON non valido: campi "username" o "api_key" mancanti.';
  @override String get detailTracklist => 'Brani';
  @override String get detailAlbumLabel => 'Album';
  @override String get detailDuration => 'Durata';
  @override String get detailTopTracks => 'Brani popolari';
  @override String get detailTopAlbums => 'Album popolari';
  @override String get detailBioReadMore => 'Leggi di più';
  @override String get detailBioReadLess => 'Mostra meno';
  @override String get detailUserPlays => 'i suoi ascolti';
  @override String get detailGlobalPlays => 'riproduzioni totali';
  @override String get detailUserRank => 'posizione';
  @override String get detailUserRankNA => 'N/D';
  @override String get detailGlobalListeners => 'ascoltatori';
  @override String get detailPeriod => 'Periodo';
  @override String get detailBiography => 'Biografia';
  @override String get detailGlobalListenersLabel => 'Ascoltatori';
  @override String get detailTranslate => 'Traduci';
  @override String get detailShowOriginal => 'Mostra originale';
  @override String get detailLyrics => 'Testo';
  @override String get detailLyricsNotFound => 'Testo non disponibile';
  @override String get detailCopyLyrics => 'Copia testo';
  @override String get detailLyricsCopied => 'Testo copiato';

  @override String get detailShoutbox => 'Shoutbox di Last.fm';
  @override String get detailShoutboxReply => 'Rispondi';  @override String get dashPerWeek => 'a settimana';
  @override String get onboardSkip => 'Salta';
  @override String get onboardNext => 'Avanti';
  @override String get onboardFinish => 'Fine';
  @override String get onboardBack => 'Indietro';
  @override String get onboardAppearanceTitle => 'Personalizzi il suo stile';
  @override String get onboardAppearanceSub => 'Tema, colore accento e Material You.';
  @override String get onboardNotifTitle => 'Resta aggiornato';
  @override String get onboardNotifSub => 'Notifiche e vibrazioni.';
  @override String get onboardFavTitle => 'I suoi profili preferiti';
  @override String get onboardFavSub => 'Aggiunga amici Last.fm per trovarli rapidamente.';
  @override String get onboardFavHint => 'Nome utente Last.fm';
  @override String get onboardFavAdd => 'Aggiungi';
  @override String get onboardFavEmpty => 'Nessun preferito ancora';
  @override String get onboardFavSearchHint => 'Cerchi un profilo Last.fm…';
  @override String get onboardFavNoResults => 'Nessun profilo trovato';
  @override String get onboardFavFriendsTitle => 'I suoi amici Last.fm';
  @override String get onboardFavNoFriends => 'Nessun amico trovato su questo account';
  @override String get onboardFavSelected => 'Preferiti selezionati';
  @override String get onboardDashTitle => 'La sua panoramica';
  @override String get onboardDashSub => 'Scelga quali sezioni mostrare.';
  @override String get onboardStartupTitle => 'Schermata di avvio';
  @override String get onboardStartupSub => 'Quale scheda vuole vedere per prima?';
  @override String get onboardPlatformTitle => 'Su cosa ascolta musica?';
  @override String get onboardPlatformSub => 'Mostra solo i link utili sulle pagine di brani/artisti/album.';
  @override String get platformLastfm => 'Last.fm';
  @override String get platformSpotify => 'Spotify';
  @override String get platformYtMusic => 'YouTube Music';
  @override String get platformOther => 'Altro / mostra tutto';
  @override String get settingsMusicPlatform => 'Piattaforma musicale';
  @override String get settingsMusicPlatformSub => 'Filtra i link mostrati nelle pagine di dettaglio';
  @override String get settingsShowAllPlatformLinks => 'Mostra sempre tutto';
  @override String get settingsShowAllPlatformLinksSub => 'Ignora il filtro e mostra ogni link (Last.fm, Spotify, YT Music, Web)';
  @override String get onboardUpdatesTitle => 'Aggiornamenti';
  @override String get onboardUpdatesSub => 'Verifica automatica di nuove versioni.';
  @override String get onboardStyle => 'Stile';
  @override String get onboardStyleMaterialYou => 'Material You';
  @override String get onboardStyleNothing => 'Nothing OS';
  @override String get onboardPreview => 'Anteprima';
  @override String get onboardPreviewButton => 'Pulsante';
  @override String get onboardPreviewOutline => 'Contorno';
  @override String get onboardPreviewText => 'Testo di esempio';
  @override String get onboardPreviewBubble => 'Fumetto';
  @override String get onboardAccentTint => 'Tonalità accento';
  @override String get onboardNothingRedOnly => 'Solo rosso';
  @override String get onboardNothingRedYellow => 'Rosso + giallo';
  @override String get onboardDisplay => 'Schermo';
  @override String get onboardOledTitle => 'Nero puro OLED';
  @override String get onboardOledSub => 'Sfondo nero puro in modalità scura';
  @override String get onboardArtworkColorTitle => 'Colore dalla copertina';
  @override String get onboardArtworkColorSub => 'Adatta il colore accento alla copertina in riproduzione';
  @override String get onboardNewsTitle => 'Notifiche novità';
  @override String get onboardNewsSub => 'Riceva notifiche su nuove funzionalità e correzioni';
  @override String get onboardNewsBadgeTitle => 'Puntino novità';
  @override String get onboardNewsBadgeSub => 'Puntino rosso sulla campanella quando ci sono novità';
  @override String get onboardHapticTitle => 'Feedback aptico';
  @override String get onboardHapticSub => 'Percepisci lievi vibrazioni sulle interazioni principali';
  @override String get onboardRecaps => 'Riepiloghi';
  @override String get onboardDailyRecapTitle => 'Riepilogo giornaliero';
  @override String get onboardDailyRecapSub => 'Un breve riassunto degli ascolti della giornata';
  @override String get onboardWeeklyRecapTitle => 'Riepilogo settimanale';
  @override String get onboardWeeklyRecapSub => 'I suoi artisti, album e brani principali della settimana';
  @override String get onboardMilestonesSection => 'Traguardi scrobble';
  @override String get onboardMilestonesTitle => 'Traguardi';
  @override String get onboardMilestonesSub => 'Festeggia i numeri tondi di scrobble';
  @override String get onboardGrandMilestonesTitle => 'Grandi traguardi';
  @override String get onboardGrandMilestonesSub => 'Festeggiamento speciale per i grandi traguardi';
  @override String get onboardDynamicColorSub => 'Usa i colori del suo sfondo (Android 12+)';
  @override String get onboardBetaTitle => 'Aggiornamenti beta';
  @override String get onboardBetaSub => 'Accesso anticipato alle versioni pre-rilascio';
  @override String get notifDetailTitle => 'Notifica';
  @override String get notifDetailOpenLink => 'Apri link';
  @override String get settingsCheckingUpdates => 'Ricerca aggiornamenti…';
  @override String get settingsTapToDownload => 'Tocchi per scaricare';
  @override String get detailLookingForPreview => 'Ricerca di un\'anteprima…';
  @override String get detailPreview30Sec => 'Anteprima · 30 sec';
  @override String get setupTagline => 'Le sue statistiche Last.fm, reinventate.';
  @override String get setupAnalyseProfile => 'Analizza un profilo';
  @override String get setupConnecting => 'Connessione in corso…';
  @override String get setupStartAnalysis => 'Avvia analisi';
  @override String get setupOr => 'oppure';
  @override String get setupUsernameLabel => 'Nome utente Last.fm';
  @override String get setupApiKeyLabel => 'Chiave API Last.fm';
  @override String get setupApiKeyHint => 'Chiave esadecimale di 32 caratteri';
  @override String get setupApiKeyPrivacyNote => 'Salvata localmente. Mai inviata a terzi.';
  @override String get setupRememberMe => 'Ricordami';
  @override String get setupGetApiKey => 'Ottieni una chiave API gratuita';
  @override String get setupWelcomeBanner => 'Benvenuto su LastStats!';
  @override String get setupOneTimeImportNote => 'Importazione unica, i prossimi avvii saranno istantanei.';
  @override String get dashTapToDownload => 'Tocchi per scaricare.';
  @override String get dashWeekLabel => 'QUESTA SETTIMANA';
  @override String get dashMonthLabel => 'QUESTO MESE';
  @override String get dashYearLabel => 'QUEST\'ANNO';
  @override String get dashTopArtistLabel => 'Artista principale';
  @override String get dashTopTrackLabel => 'Brano principale';
  @override String get dashScrobblesLabel => 'Scrobble';
  @override String get newsTypeFeatures => 'Funzionalità';
  @override String get newsTypeFixes => 'Correzioni';
  @override String get newsTypeUpdates => 'Aggiornamenti';
  @override String get newsTypeAlerts => 'Avvisi';
  @override String get newsTypeInfo => 'Info';
  @override String get newsWhatsNew => 'Novità';
  @override String get newsFilters => 'Filtri';
  @override String get newsAll => 'Tutte';
  @override String get newsAnyDate => 'Qualsiasi data';
  @override String get newsNoNewsYet => 'Nessuna novità ancora';
  @override String get settingsNotifications => 'Notifiche';
  @override String get settingsCache => 'Cache';
  @override String get settingsCardAppearanceSub => 'Tema, accento, layout, Material You';
  @override String get settingsCardDashboardSub => 'Immagine di intestazione, sezioni visibili, schede statistiche';
  @override String get settingsCardStartupSub => 'Scheda mostrata all\'avvio dell\'app';
  @override String get settingsCardNotificationsSub => 'Traguardi, riepiloghi giornalieri e settimanali';
  @override String get settingsSync => 'Sincronizzazione';
  @override String get settingsCardSyncSub => 'Sincronizzazione automatica scrobble in background';
  @override String get settingsCardAccountSub => 'Profilo Last.fm collegato, disconnessione';
  @override String get settingsCardCacheSub => 'Cronologia, immagini, dati API';
  @override String get settingsCardBackupSub => 'Esporta e ripristina le sue impostazioni';
  @override String get settingsCardUpdatesSub => 'Verifica nuove versioni';
  @override String get settingsCardAboutSub => 'Versione, codice sorgente, crediti';
  @override String get settingsCardFaqSub => 'Scrobbling, piattaforme, open source';
  @override String get settingsRestartNotice => 'Alcune impostazioni richiedono il riavvio dell\'app per avere pieno effetto.';
  @override String get syncPageTitle => 'Sincronizzazione scrobble';
  @override String get syncAutoTitle => 'Sincronizzazione automatica';
  @override String get syncAutoSubtitle => 'Sincronizza la cronologia in background a intervalli regolari';
  @override String get syncFrequencyLabel => 'Frequenza';
  @override String get syncFrequencyDaily => 'Una volta al giorno';
  @override String get syncManualTitle => 'Sincronizzazione manuale';
  @override String get syncNowButton => 'Sincronizza ora';
  @override String get syncInProgress => 'Sincronizzazione…';
  @override String get syncLastSyncLabel => 'Ultima sincronizzazione';
  @override String get syncNeverLabel => 'Mai';
  @override String get syncTotalScrobblesLabel => 'Scrobble in cache';
  @override String get syncUpToDateMsg => 'Cronologia aggiornata';
  @override String get syncNotifNote => 'Durante una sincronizzazione completa appare una notifica di avanzamento.';
  @override String get pcModeLayout => 'Layout';
  @override String get pcModeNavLayout => 'Layout di navigazione';
  @override String get pcModeAuto => 'Automatico';
  @override String get pcModeSideRail => 'Barra laterale';
  @override String get pcModeBottomBar => 'Barra inferiore';
  @override String get pcModeHintAuto => 'Barra laterale su schermi larghi (≥ 720 dp), barra inferiore su schermi stretti.';
  @override String get pcModeHintOn => 'Usa sempre la barra di navigazione laterale, indipendentemente dalle dimensioni dello schermo.';
  @override String get pcModeHintOff => 'Usa sempre la barra di navigazione inferiore, indipendentemente dalle dimensioni dello schermo.';
  @override String get aboutTagline => 'Il suo compagno per le statistiche Last.fm';
  @override String get aboutAppInfo => 'Info app';
  @override String get aboutScrobbleDownloader => 'Downloader scrobble';
  @override String get aboutScrobbleDownloaderSub => 'Esporta tutti i suoi scrobble in un file';
  @override String get aboutPoweredBy => 'Basato su';
  @override String get aboutImageDisclaimer => 'Le immagini di artisti, album e brani vengono recuperate automaticamente da queste fonti e a volte potrebbero essere errate o non corrispondere al contenuto reale.';
  @override String get aboutFooter => 'Fatto con ❤️ · Non affiliato con Last.fm / CBS';
  @override String get updatesCurrentVersion => 'Versione attuale';
  @override String get updatesBetaTitle => 'Aggiornamenti beta';
  @override String get updatesBetaSub => 'Accesso anticipato alle versioni pre-rilascio';
  @override String get backupWhatsIncluded => 'Cosa è incluso';
  @override String get backupDownloadFile => 'Scarica un file .json';
  @override String get backupChooseFile => 'Scegli un file di backup';
  @override String get backupFileSaved => 'Backup salvato';
  @override String get backupFileSaveFailed => 'Impossibile salvare il file';
  @override String get setupRestoreBackup => 'Ripristina un backup';
  @override String get setupRestoreBackupSub => 'Recupera il suo account e le impostazioni da un file di backup .json';
  @override String get backupRestoreKeysTitle => 'Ripristina chiavi API';
  @override String get backupRestoreKeysDesc => 'Scelga quali chiavi Last.fm ripristinare da questo backup.';
  @override String get backupRestoreApiKeyLabel => 'Chiave API';
  @override String get backupRestoreSecretKeyLabel => 'Chiave segreta';
  @override String get backupIncludeFoldersLabel => 'Includi cartelle';
  @override String get backupIncludeFoldersDesc => 'Include le sue cartelle di brani e il loro contenuto.';
  @override String get backupIncludeKeysDesc => 'Includi le chiavi nel file esportato';

  @override String get backupIncludeThemesLabel => 'Esporta temi';
  @override String get backupIncludeThemesDesc => 'Ti permette di condividere solo l\'aspetto (colori, stile) con qualcun altro.';

  @override String get backupAutoTitle => 'Backup automatico';
  @override String get backupAutoEnableLabel => 'Attiva il backup automatico';
  @override String get backupAutoEnableDesc => 'Salva un backup da solo, all\'intervallo scelto qui sotto.';
  @override String get backupAutoFreqLabel => 'Frequenza';
  @override String get backupAutoFreqDaily => 'Ogni giorno';
  @override String get backupAutoFreqWeekly => 'Ogni settimana';
  @override String get backupAutoFreqMonthly => 'Ogni mese';
  @override String get backupAutoFreqYearly => 'Ogni anno';
  @override String get backupAutoFolderLabel => 'Cartella di backup';
  @override String get backupAutoFolderDefault => 'Cartella predefinita dell\'app';
  @override String backupAutoNextLabel(String date) => 'Prossimo backup: $date';  @override String get backupIncludeScrobblesLabel => 'Includi tutta la cronologia';
  @override String get backupIncludeScrobblesDesc => 'Aggiunge tutti i brani ascoltati dall\'inizio (può essere corposo).';

  @override String get backupScrobblesSlowWarning => 'Questo può richiedere tempo ed è più lento di un backup normale.';  @override String backupExportedOn(String date) => 'Backup del $date';
  @override String get backupScrobblesErrorTitle => 'Errore nella cronologia';
  @override String get backupScrobblesErrorDesc => 'Alcuni anni della cronologia sembrano danneggiati in questo file. Cosa vuole fare?';
  @override String get backupScrobblesKeepAnyway => 'Continua comunque';
  @override String get backupScrobblesCancel => 'Annulla cronologia';
  @override String get backupScrobblesSkipRefetch => 'Ignora e riscarica online';  @override String get settingsCrashLog => 'Registro errori';
  @override String get backupCrashLogDesc => 'Registra gli errori riscontrati dall\'app, utile per segnalare un bug.';
  @override String get backupCrashLogShare => 'Condividi registro';
  @override String get backupCrashLogClear => 'Svuota registro';
  @override String get backupCrashLogEmpty => 'Nessun errore registrato';
  @override String get backupCrashLogCleared => 'Registro svuotato';
  @override String get backupCrashLogClearConfirm => 'Svuotare il registro degli errori?';
  @override String get faqSectionLabel => 'Domande frequenti';
  @override String get backupOverwriteWarning => 'Il ripristino di un backup sovrascriverà le sue impostazioni attuali.';
  @override String get faqOpenSourceBadge => 'LastStats è un progetto gratuito e open-source realizzato con ❤️ da SanoBld.';
  @override String get cacheUnlimited => 'Illimitato';
  @override String get cacheTotalUsed => 'Totale usato';
  @override String get cacheScrobblesShort => 'Scrobble';
  @override String get restartHintFeatures => 'Alcune funzionalità potrebbero richiedere il riavvio dell\'app per avere effetto.';
  @override String get reorderCardsTitle => 'Riordina schede';
  @override String get commonSave => 'Salva';
  @override String get dashFallbackWhenNoMusic => 'Quando non c\'è musica in riproduzione';
  @override String get dashFallbackChooseDisplay => 'Scelga cosa mostrare come sfondo al suo posto';
  @override String get dashFallbackPeriodLabel => 'Periodo di riserva';
  @override String get fallbackPeriod1Week => '1 settimana';
  @override String get fallbackPeriod1Month => '1 mese';
  @override String get fallbackPeriodAllTime => 'Sempre';
  @override String get fallbackTypeNothing => 'Niente';
  @override String get fallbackTypeTopTrack => 'Brano principale';
  @override String get fallbackTypeTopAlbum => 'Album principale';
  @override String get fallbackTypeTopArtist => 'Artista principale';
  @override String get fallbackTypeCustomImage => 'Immagine personalizzata';
  @override String get fallbackWillShowCustomUrl => 'Verrà mostrato: URL immagine personalizzata';
  @override String get dashAnimationBlurSection => 'Animazione e sfocatura';
  @override String get dashMusicAnimationTitle => 'Animazione musicale';
  @override String get dashMusicAnimationSub => 'Quando la musica è in riproduzione, l\'immagine di intestazione si sfoca e si muove lentamente, come Apple Music.';
  @override String get dashMusicAnimationInfo => 'La sfocatura viene impostata automaticamente in questa modalità. Il cursore sopra non ha effetto durante la riproduzione.';
  @override String get settingsTopAlbumsSection => 'Album principali';
  @override String get dashRecentPlaysLabel => 'Riproduzioni recenti';
  @override String get dashStatCardsSectionLabel => 'Schede statistiche';
  @override String get dashStatCardsHeading => 'Schede statistiche';
  @override String get dashStatCardsSub => 'Scelga e riordini le schede mostrate nel blocco statistiche.';
  @override String get settingsDashboardChartSection => 'Grafico della dashboard';
  @override String get dashChartCalendarLabel => "Calendario d'ascolto";
  @override String get dashChartMonthlyLabel => 'Barre mensili';
  @override String get settingsDisplayNameSection => 'Nome personalizzato';
  @override String get settingsDisplayNameLabel => 'Come vuole essere chiamato?';
  @override String get settingsDisplayNameHint => "Es. Sano Bld — lascia vuoto per usare il nome dell'account";
  @override String get newsSearchHint => 'Cerchi nelle novità…';
  @override String get aboutOpenSourceLibs => 'Librerie open source';
  @override String get aboutOpenSourceLibsSub => "Tutti i pacchetti Flutter usati per creare l'app.";
  @override String get aboutLicenseSection => 'Licenza';
  @override String get aboutLicenseText => 'Questo progetto è pubblicato con licenza MIT: è libero di usarlo, modificarlo, duplicarlo o ridistribuirlo, basta citarmi.';
  @override String get aboutLicenseLink => 'Vedi la licenza completa';
  @override String get languageAiNote => "Le traduzioni sono state generate dall'IA e potrebbero contenere imprecisioni.";
  @override String get aboutAiDevNote => "L'IA è stata usata anche per sviluppare questa app.";
  @override String get notifWorkManagerInfo => 'Le notifiche vengono eseguite in background tramite WorkManager. L\'app non deve essere aperta. È richiesta una connessione a internet.';
  @override String get notifIntervalTitle => 'Ogni X scrobble';
  @override String get notifIntervalSubtitle => 'Riceva notifiche a intervalli regolari';
  @override String get notifRecapsSection => 'Riepiloghi d\'ascolto';
  @override String get notifDailyRecapSubtitle => 'Numero di scrobble + artista principale del giorno';
  @override String get notifWeeklyRecapSubtitle => 'Numero di scrobble + artista principale della settimana';
  @override String get notifNewsSection => 'Novità';
  @override String get notifSyncSection => 'Sincronizzazione';
  @override String get notifSyncTitle => 'Notifiche di sincronizzazione';
  @override String get notifSyncSubtitle => 'Avvisa quando termina una sincronizzazione della cronologia';
  @override String get notifSyncDetailTitle => 'Dettaglio avanzamento';
  @override String get notifSyncDetailSubtitle => 'Mostra l\'avanzamento in tempo reale (anno corrente, contatore) durante la sincronizzazione';
  @override String get notifNewsSubtitle => 'Riceva notifiche su nuove funzionalità, correzioni e annunci';
  @override String get notifBadgeOnDashboard => 'Badge sulla panoramica';
  @override String get notifBadgeSubtitle => 'Mostra il puntino non letto sull\'icona della campanella';
  @override String get notifTestLabel => 'Test';
  @override String get notifPermissionDisabledTitle => 'Notifiche disattivate';
  @override String get notifPermissionDisabledBody => 'Conceda il permesso affinché LastStats possa inviarle avvisi.';
  @override String get notifGrantPermission => 'Concedi permesso';
  @override String get notifThresholdIntro => 'Riceverà una notifica speciale a ciascuno di questi traguardi:';
  @override String get notifIntervalDescription => 'Invia una notifica ogni X scrobble';
  @override String get notifCustomValueLabel => 'Valore personalizzato';
  @override String get notifTimeNotifyAt => 'Notifica alle';
  @override String get notifDayOfWeek => 'Giorno della settimana';
  @override String get notifSendTest => 'Invia una notifica di prova';
  @override String get notifSentCheckBar => 'Controlli la barra delle notifiche!';
  @override String get notifMakeSureWorks => 'Si assicuri che tutto funzioni.';
  @override String get notifSentBang => 'Inviata!';
  @override String get notifSendButton => 'Invia';
  @override String get apVisualStyle => 'Stile visivo';
  @override String get apStyleDefault => 'Predefinito';
  @override String get apNothingAccentLabel => 'Accento';
  @override String get apNothingClassic => 'Classico';
  @override String get apRedOnlyDesc => 'Solo rosso';
  @override String get apNothingMixed => 'Misto';
  @override String get apRedYellowDesc => 'Rosso + tocchi di giallo';
  @override String get apNothingActiveBanner => 'Stile Nothing OS attivo. Accento, colore dinamico e colore musica sono disattivati.';
  @override String get apNothingOledInherent => 'La modalità scura Nothing è già nero OLED per natura. L\'interruttore OLED non è necessario.';
  @override String get apOledTitle => 'Tema nero OLED';
  @override String get apOledBuiltIntoNothing => 'Integrato nella modalità scura Nothing';
  @override String get apOledPureBlack => 'Sfondi neri puri quando la modalità scura è attiva';
  @override String get apCustomColorTooltip => 'Colore personalizzato';
  @override String get apColorWhenNothingPlays => 'Colore quando nulla è in riproduzione';
  @override String get apColorWhenNothingPlaysSub => 'Accento usato mentre nessun brano viene scrobbelato';
  @override String get apKeepLastArtworkTitle => 'Mantieni ultimo colore copertina';
  @override String get apKeepLastArtworkSub => 'Mantieni l\'ultimo colore della copertina invece di reimpostarlo quando nulla è in riproduzione';
  @override String get apDetailPagesSection => 'Pagine di dettaglio';
  @override String get apArtworkColorTheme => 'Tema colore copertina';
  @override String get apBeta => 'BETA';
  @override String get apArtworkColorThemeSub => 'Le pagine di dettaglio adattano i colori al colore dominante della copertina';
  @override String get apNavBarSection => 'Barra di navigazione';
  @override String get apShowTabLabels => 'Mostra etichette schede';
  @override String get apShowTabLabelsSub => 'Mostra i nomi delle schede sotto le icone nella barra inferiore';
  @override String get apInteractionsSection => 'Interazioni';
  @override String get apHapticFeedbackSub => 'Vibrazioni su tocchi, selezioni e gesti';
  @override String get acctRemoveTitle => 'Rimuovere l\'account?';
  @override String get acctRemoveAction => 'Rimuovi';
  @override String get acctAlreadyAddedOrFull => 'Questo account è già stato aggiunto oppure l\'elenco è pieno.';
  @override String get acctLogoutAllBody => 'Tutti gli account verranno rimossi. Tornerai alla schermata di configurazione.';
  @override String get acctActive => 'Attivo';
  @override String get acctTapSwitchToActivate => 'Tocchi "Cambia" per attivare';
  @override String get acctSwitch => 'Cambia';
  @override String get acctAddAnAccount => 'Aggiungi un account';
  @override String get acctApiKeyInfo => 'Ogni account può usare una chiave API diversa o la stessa. Può trovare la sua chiave API su last.fm/api/accounts.';
  @override String get acctLastfmProfileSection => 'Profilo Last.fm';
  @override String get acctViewOnLastfm => 'Visualizza su Last.fm';
  @override String get acctDangerZone => 'Zona pericolosa';
  @override String get acctLogoutAllSub => 'Rimuove tutti gli account e torna alla schermata di configurazione.';
  @override String get acctUsernameRequired => 'Il nome utente è obbligatorio.';
  @override String get acctApiKeyRequired => 'La chiave API è obbligatoria.';
  @override String get acctUsernameLabel => 'Nome utente Last.fm';
  @override String get acctSameApiKey => 'Stessa chiave API dell\'account attivo';
  @override String get acctApiKeyLabel => 'Chiave API';
  @override String get acctAdd => 'Aggiungi';
  @override String get languageChangeNote => 'La lingua cambia immediatamente in tutta l\'app.';
  @override String get dashTotalScrobblesLabel => 'Scrobble totali';
  @override String get dashMemberSinceLabel => 'Membro da';
  @override String get dashCountryLabel => 'Paese';
  @override String get dashArtistWeekLabel => 'Artista n. 1 (settimana)';
  @override String get dashAlbumWeekLabel => 'Album n. 1 (settimana)';
  @override String get dashTrackWeekLabel => 'Brano n. 1 (settimana)';
  @override String get dashUniqueArtistsLabel => 'Artisti unici';
  @override String get dashUniqueTracksLabel => 'Brani unici';
  @override String get dashUniqueAlbumsLabel => 'Album unici';
  @override String get dashThisWeekLabel => 'Questa settimana';
  @override String get dashDayUnitShort => 'g';
  @override String get setupEnableFavorites      => 'Attiva preferiti (facoltativo)';
  @override String get setupFavoritesExplain     => 'La sua chiave segreta permette all\'app di aggiungere (o rimuovere) brani dai preferiti direttamente su Last.fm.';
  @override String get setupSecretKeyLabel       => 'Chiave segreta Last.fm';
  @override String get favConnectInvalidSecret   => 'La chiave segreta deve avere 32 caratteri.';
  @override String get favConnectDialogTitle     => 'Autorizza i preferiti';
  @override String get favConnectDialogBody      => 'Autorizzi l\'app nella pagina Last.fm aperta nel browser, poi torni qui per confermare.';
  @override String get favConnectDialogConfirm   => 'Ho autorizzato';
  @override String get favConnectSuccess         => 'Preferiti attivati con successo!';
  @override String get favConnectError           => 'Impossibile attivare i preferiti. Controlli la chiave segreta.';
  @override String get acctApiKeysSection        => 'Chiavi API';
  @override String get acctSecretKeyLabel        => 'Chiave segreta';
  @override String get acctSecretKeyNotSet       => 'Non impostata';
  @override String get acctFavoritesExplain      => 'La chiave segreta permette di aggiungere (o rimuovere) brani dai preferiti direttamente su Last.fm.';
  @override String get acctConnectFavorites      => 'Attiva preferiti';
  @override String get acctDisconnectFavorites   => 'Disattiva preferiti';
  @override String get settingsFavoritesSection    => 'Preferiti';
  @override String get settingsFavoritesSectionSub => 'Mostra il numero di preferiti nelle statistiche';
  @override String get settingsFavoritesNeedsKey   => 'Aggiunga la chiave segreta in Account per attivare';
  @override String get favSectionTitle           => 'Preferiti';
  @override String get commonSeeMore             => 'Vedi altro';
  @override String get favPageTitle              => 'I miei preferiti';
  @override String get favSearchHint             => 'Cerchi un brano o un artista';
  @override String get favEmpty                  => 'Ancora nessun preferito.';
  @override String get settingsLovedBadgeTitle => 'Icona cuore discreta';
  @override String get settingsLovedBadgeSub   => 'Mostra un piccolo cuore sui brani preferiti in ascolti recenti, cronologia e ricerca';
  @override String get favSortRecent   => 'Recenti';
  @override String get favSortOldest   => 'Meno recenti';
  @override String get favSortArtistAz => 'Artista A-Z';
  @override String get favSortTitleAz  => 'Titolo A-Z';
  @override String get favFolderSortCustom => 'Manuale';
  @override String get favFoldersAll => 'Tutti';
  @override String get favFolderNew => 'Nuova cartella';
  @override String get favFolderNamePlaceholder => 'Nome cartella';
  @override String get favFolderCustomEmojiTitle => "Scegli un'emoji";
  @override String get favFolderCustomEmojiHelper => "Solo un'emoji, niente testo.";
  @override String get favFolderDescPlaceholder => 'Descrizione (opzionale)';
  @override String get favFolderRecentlyPlayed => 'Ascoltati di recente';
  @override String get favFolderCreate => 'Crea';
  @override String get favFolderEdit => 'Modifica cartella';
  @override String get favFolderDelete => 'Elimina';
  @override String get favFolderDeleteConfirm => 'Eliminare questa cartella? I brani non saranno più organizzati al suo interno.';
  @override String get favFolderAssignTitle => 'Aggiungi a una cartella';
  @override String get favFolderEmoji => 'Emoji';
  @override String get favFolderColor => 'Colore';
  @override String get favFolderSave => 'Salva';
  @override String get favFolderEmpty => 'Nessun brano in questa cartella';
  @override String get rankingsWholeYear       => 'Anno intero';
  @override String get chartsExportGeneratedOn => 'generato il';
  @override String get faqQ1 => 'LastStats fa lo scrobble della mia musica?';
  @override String get faqA1 => 'No. LastStats è un\'app di visualizzazione: mostra gli scrobble già registrati sul suo account Last.fm, ma non ne registra alcuno da sola.\n\nPer fare lo scrobble automatico della sua musica, usi un\'app dedicata come Pano Scrobbler (disponibile su Android).';
  @override String get faqQ3 => 'L\'app funziona su macOS o altre piattaforme?';
  @override String get faqA3 => 'LastStats è sviluppato e testato su Android. Il funzionamento su altre piattaforme (macOS, Windows, Linux…) non è verificato: possono verificarsi bug o comportamenti imprevisti.';
  @override String get faqQ4 => 'LastStats è open source?';
  @override String get faqA4 => 'Sì! Il codice sorgente è liberamente disponibile su GitHub. Il progetto è indipendente, realizzato con passione da SanoBld. Sentiti libero di contribuire, segnalare bug o lasciare una stella ⭐.';
  @override String get faqQ5 => 'Dove vengono archiviati i miei dati?';
  @override String get faqA5 => 'Solo sul suo dispositivo. LastStats non ha alcun server: i suoi scrobble vengono memorizzati localmente per un accesso rapido, e anche le sue credenziali Last.fm restano salvate in locale. Nulla viene inviato se non all\'API ufficiale di Last.fm.';
  @override String get faqQ6 => 'Come attivo i preferiti?';
  @override String get faqA6 => 'Vada su Impostazioni > Account e inserisca la sua chiave segreta Last.fm (la trova accanto alla chiave API su last.fm/api/accounts), poi segua i passaggi sullo schermo. Una volta connessa, potrà aggiungere brani ai preferiti direttamente dall\'app. Con la chiave interna dell\'app questa funzione non è disponibile.';
  @override String get faqQ7 => 'Cos\u2019\u00e8 uno \'scrobble\'?';
  @override String get faqA7 => 'Uno scrobble \u00e8 un brano registrato come ascoltato sul suo account Last.fm: \u00e8 il termine ufficiale di Last.fm per \'un ascolto conteggiato\'. Tutti i suoi totali (artisti top, statistiche, ecc.) si basano su questo.';
  @override String get faqQ8 => 'Come funzionano livelli e obiettivi?';
  @override String get faqA8 => 'Il suo livello account cresce con il numero totale di scrobble (non c\u2019\u00e8 un livello massimo). Le card mostrano anche un bordo (bronzo \u2192 iridescente) in base a quante volte quell\u2019artista/brano/album \u00e8 stato ascoltato. Tutto viene calcolato automaticamente dalle statistiche gi\u00e0 in cache locale, senza chiamate di rete aggiuntive.';
  @override String get faqQ9 => 'Come funziona la modalità risparmio energetico?';
  @override String get faqA9 => 'La modalità risparmio energetico distanzia le sincronizzazioni automatiche per risparmiare batteria. Può restare sempre attiva, seguire il risparmio energetico del telefono o attivarsi sotto un livello di batteria scelto, da Impostazioni > Generali.';
  @override String get faqQ10 => 'Come faccio un backup o lo ripristino?';
  @override String get faqA10 => 'Vada su Impostazioni > Backup. Può esportare un file di backup, con o senza la sua chiave Last.fm a sua scelta, e importarlo in seguito su questo telefono o su un altro dispositivo per ritrovare le sue impostazioni.';
  @override String get faqQ11 => 'L\'app funziona offline?';
  @override String get faqA11 => 'Sì, entro certi limiti. Le statistiche già caricate restano disponibili offline grazie alla cache locale, ma serve una connessione per recuperare nuovi scrobble.';
  @override String get faqQ12 => 'Posso cambiare account Last.fm?';
  @override String get faqA12 => 'Sì, può salvare fino a 3 account Last.fm. Da Impostazioni > Account, tocchi «Aggiungi un account» e poi passi dall\'uno all\'altro quando vuole. Quando cambia account, la cache locale viene azzerata automaticamente, così i dati di due account non si mescolano mai.';
  @override String get faqQ13 => 'Come configuro le notifiche?';
  @override String get faqA13 => 'Da Impostazioni > Notifiche può attivare un avviso al termine di una sincronizzazione, scegliere ogni quanto compaiono gli avvisi oppure disattivare del tutto le notifiche.';
  @override String get faqQ14 => 'Mancano le immagini o caricano all’infinito. Cosa fare?';
  @override String get faqA14 => 'Svuota la cache nell’app (Impostazioni > Cache), poi in Android (Impostazioni > App > LastStats > Archiviazione > Svuota cache). Se le immagini mancano ancora, fai un backup (Impostazioni > Backup), disinstalla e reinstalla l’app, poi ripristina il backup.';
  @override String get settingsPlatformDisabledByShowAll => 'Disattivato: tutti i link sono già mostrati.';
  @override String get commonInDevelopment => 'In sviluppo';
  @override String get commonSeeLess => 'Vedi meno';
  @override String get commonShare => 'Condividi';
  @override String get newsCustomDate => 'Data personalizzata';
  @override String get aboutShortcuts => 'Scorciatoie da tastiera';
  @override String get aboutShortcutsSub => 'Disponibili su PC / schermo grande';
  @override String get shortcutSwitchTabs => 'Cambia scheda';
  @override String get shortcutSearch => 'Cerca';
  @override String get shortcutClose => 'Chiudi una scheda';
  @override String get shortcutRefresh => 'Aggiorna';
  @override String get aboutDiscord => 'Unisciti a Discord';
  @override String get aboutDiscordSub => 'Chat, suggerimenti e annunci in diretta';

  @override String globalListeners(String count) => '$count ascoltatori globali';
  @override String historyScrobbles(int n) => '$n scrobble';
  @override String historyArtistsCount(int n) => '$n artisti';
  @override String historyAlbumsCount(int n) => '$n album';
  @override List<String> get months => const ['', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
  @override String dayLabel(DateTime d) {
    const days = ['Lunedì','Martedì','Mercoledì','Giovedì','Venerdì','Sabato','Domenica'];
    const months = ['','Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno','Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month]} ${d.year}';
  }
  @override String memberSince(String date) => 'Membro dal $date';
  @override String settingsUpdateAvailable(String v) => 'v$v disponibile';
  @override String settingsUpdateBanner(String v) => 'Aggiornamento v$v';
  @override String setupWelcome(String username) => 'Benvenuto, $username!';
  @override String setupScrobblesToImport(String c) => '$c scrobble da importare';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      'Aggiornamento ${isBeta ? "beta" : "nuovo"}: v$version';
  @override String newsItemsCount(int n) => '$n ${n > 1 ? "elementi" : "elemento"}';
  @override String syncFrequencyHours(int h) => 'Ogni ${h}h';
  @override String syncNewScrobblesFound(int n) => n == 0 ? 'Nessun nuovo scrobble' : '$n nuovo/i scrobble trovato/i';
  @override String updatesPublishedOn(String date) => 'Pubblicato il $date';
  @override String fallbackWillShow(String detail) => 'Verrà mostrato: $detail';
  @override String acctRemoveBody(String username) => 'Rimuovere @$username dai suoi account?';
  @override String acctAddedSuccess(String username) => '@$username aggiunto con successo.';
  @override String acctMyAccounts(int count, int max) => 'I miei account ($count/$max)';
  @override String acctSlotsRemaining(int n) => '$n posto/i rimanente/i';
  @override String acctMaxReached(int max) => 'Raggiunto il massimo di $max account.';
  @override List<String> get weekdaysShort => const ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  @override List<String> get weekdaysNarrow => const ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
  @override String get weekAbbrev => 'S';
  @override List<String> get notifThresholdMessages => const [
    'I suoi primi 1.000 scrobble. Il viaggio inizia. 🎵',
    'Ha raggiunto cinque cifre! 🎉',
    'È un vero appassionato di musica. 🔥',
    'Un milione di scrobble. Leggendario. 🎸',
  ];
  @override String get achvTitle => 'Obiettivi';
  @override String achvUnlocked(int unlocked, int total) => '$unlocked / $total sbloccati';
  @override String get achvCatListening => 'Ascolto';
  @override String get achvCatArtists => 'Artisti';
  @override String get achvCatAlbums => 'Album';
  @override String get achvCatLoyalty => 'Fedeltà';
  @override String get achvDescListening => 'Totale brani ascoltati (scrobble), tutti gli artisti.';
  @override String get achvDescArtists => 'Numero di artisti diversi ascoltati almeno una volta.';
  @override String get achvDescAlbums => 'Numero di album diversi ascoltati almeno una volta.';
  @override String get achvDescLoyalty => "Anzianità dell'account Last.fm.";
  @override String get achvCatTracks => 'Brani';
  @override String get achvDescTracks => 'Numero di brani diversi ascoltati.';
  @override String get achvCatPace => 'Ritmo';
  @override String get achvDescPace => 'Media di scrobble a settimana.';
  @override String get achvCatStreak => 'Costanza';
  @override String get achvDescStreak => 'La serie più lunga di giorni consecutivi con almeno un ascolto.';
  @override String get achvCatMarathon => 'Maratona';
  @override String get achvDescMarathon => 'Il maggior numero di ascolti in un solo giorno.';
  @override String get achvCatSocial => 'Social';
  @override String get achvDescSocial => 'Il numero di amici o profili aggiunti.';
  @override String get achvCatComparisons => 'Confronti';
  @override String get achvDescComparisons => 'Il numero di confronti di gusti musicali effettuati.';
  @override String get achvUnlockedBadge => 'Sbloccato';
  @override String get achvLockedBadge => 'Bloccato';
  @override String get dashRecap => 'Riepilogo';
  @override String get recapDay => 'Oggi';
  @override String get recapWeek => 'Questa settimana';
  @override String get recapMonth => 'Questo mese';
  @override String get recapScrobbles => 'ascolti';
  @override String get recapArtists => 'Artisti';
  @override String get recapTracks => 'Brani';
  @override String get recapTopArtist => 'Artista top';
  @override String get recapTopTrack => 'Brano top';
  @override String get recapTopAlbum => 'Album top';
  @override String get recapAvgDay => 'Media/giorno';
  @override String get recapNoData => 'Nessun ascolto in questo periodo.';
  @override String get recapSeeFull => 'Vedi riepilogo completo';
  @override String get recapTop10 => 'Top 10';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => 'Il filtro più utile per primo';
  @override String get discoverSmartSub => 'In base a ora, giorno e a ciò che usa di più';
  @override String get discoverForYou => 'Per lei';
  @override String get discoverGlobalTrends => 'Tendenze globali';
  @override String get discoverSrcForyou => 'Il suo mix';
  @override String get discoverSrcOnthisday => 'In questo giorno';
  @override String get discoverSrcFresh => 'Questo mese';
  @override String get discoverSrcGenre => 'I suoi generi';
  @override String get discoverSrcDeeper => 'Perle nascoste';
  @override String get discoverSrcForgotten => 'Dimenticate';
  @override String get discoverSrcAlbums => 'Album';
  @override String get discoverSrcCountry => 'Il suo paese';
  @override String get discoverTracks => 'Brani';
  @override String get discoverArtists => 'Artisti';
  @override String get discoverWeek => 'settimana';
  @override String get discoverMonth => 'mese';
  @override String get discoverYear => 'anno';
  @override String get discoverNothing => 'Ancora niente da mostrare';
  @override String discoverLike(String names) => 'Come $names';
  @override String get dashReorderSections => 'Cambia l\'ordine delle sezioni';
  @override String get dashInfiniteTitle => 'Scorrimento infinito';
  @override String get dashInfiniteSub => 'Scopri si ripete e continua a proporre altro';
  @override String get dashDiscoverTitle => 'Scopri';
  @override String get dashDiscoverSub => 'Idee musicali da scorrere';
  @override String get dashSortButton => 'Ordina';
  @override String get dashSortDone => 'Fatto';
  @override String get dashSortHint => 'Trascini per cambiare l\'ordine';
  @override String get dashSortSmartNote => 'L\'ordine intelligente è attivo, quindi può cambiare questa sequenza in base al momento.';
  @override String get dashSeparateRow => 'Su una riga a parte';
  @override String dashFiltersOf(String group) => 'Filtri di «$group»';
  @override String get apShapeSingle => 'Una sola forma';
  @override String get mvSource => 'Fonte video';
  @override String get mvSrcAuto => 'Auto (Apple Music, poi YouTube)';
  @override String get mvSrcApple => 'Solo Apple Music';
  @override String get mvSrcYt => 'Solo YouTube (brani)';
  @override String get mvQualityT => 'Qualità video';
  @override String get mvQAuto => 'Auto';
  @override String get mvQLow => 'Risparmio (360p)';
  @override String get mvTypesT => 'Mostra il video per';
  @override String get mvTracks => 'Brani';
  @override String get mvAlbums => 'Album';
  @override String get mvArtists => 'Artisti';
  @override String get mvModeT => 'Modalità';
  @override String get mvModeBest => 'Consigliato';
  @override String get mvModeSaver => 'Risparmio';
  @override String get mvModeMax => 'Qualità massima';
  @override String get mvModeCustom => 'Personalizzato';
  @override String get mvSrcYtFirst => 'YouTube, poi Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => 'Servizi usati, quote e consumo';
  @override String get apiSumToday => 'Richieste oggi';
  @override String get apiSumErrors => 'Errori';
  @override String get apiSumLimited => 'Limitate';
  @override String get apiIntro => 'I contatori riguardano solo questo dispositivo. I fornitori applicano i limiti per indirizzo IP, quindi contano anche le altre app sulla stessa rete. L\'app rallenta o salta automaticamente le richieste per restare nei limiti.';
  @override String get apiCatListening => 'Dati di ascolto';
  @override String get apiCatMetadata => 'Metadati musicali';
  @override String get apiCatArtwork => 'Copertine';
  @override String get apiCatLyrics => 'Testi';
  @override String get apiCatTranslate => 'Traduzione';
  @override String get apiCatUpdates => 'Aggiornamenti e novità';
  @override String get apiCatOther => 'Download di immagini';
  @override String get apiStatusIdle => 'Non ancora usata';
  @override String get apiStatusOk => 'OK';
  @override String get apiStatusNear => 'Vicino al limite';
  @override String get apiStatusPaused => 'In pausa';
  @override String get apiProviderLimit => 'Limite del fornitore';
  @override String get apiNoLimit => 'Nessuno pubblicato';
  @override String get apiAppCeiling => 'Tetto dell\'app';
  @override String apiLimitPer(int n, String win) => '$n richieste / $win';
  @override String get apiWinSecond => 'secondo';
  @override String get apiWinMinute => 'minuto';
  @override String get apiWinHour => 'ora';
  @override String apiWinSeconds(int s) => '$s secondi';
  @override String get apiWindowUsage => 'Finestra corrente';
  @override String get apiRemaining => 'Rimanenti';
  @override String apiResetsIn(String t) => 'Si azzera tra $t';
  @override String apiPausedFor(String t) => 'In pausa per $t dopo una risposta di limite raggiunto';
  @override String get apiToday => 'Oggi';
  @override String get apiLastHour => 'Ultima ora';
  @override String get apiTotal => 'Totale';
  @override String get apiRateLimited => 'Risposte di limite raggiunto';
  @override String get apiSkipped => 'Saltate dall\'app';
  @override String get apiLastCall => 'Ultima chiamata';
  @override String get apiNever => 'Mai';
  @override String get apiNoKey => 'Nessuna chiave API necessaria';
  @override String get apiSharedKey => 'Chiave di prova pubblica condivisa (piano gratuito)';
  @override String get apiUnofficial => 'Endpoint non ufficiale: nessuna quota garantita, può cambiare o essere bloccato senza preavviso.';
  @override String get apiKeyInUse => 'Chiave in uso';
  @override String get apiOwnKey => 'La tua chiave Last.fm';
  @override String apiBuiltinKey(int n, int total) => 'Chiave integrata $n di $total';
  @override String get apiBackupOn => 'Chiave di riserva: attiva';
  @override String get apiBackupOff => 'Chiave di riserva: disattivata';
  @override String get apiPerKey => 'Richieste per chiave (oggi / totale)';
  @override String get apiLastfmNote => 'Last.fm non pubblica alcun numero: risponde con l\'errore 29 quando un IP invia troppe richieste e i suoi termini vietano di aggirarlo. Circa 5 richieste al secondo per IP è l\'indicazione abituale; l\'app resta sotto 4.';
  @override String get apiStorageTitle => 'Dati Last.fm archiviati';
  @override String apiStorageValue(String used, String cap) => '$used su $cap consentiti';
  @override String get apiStorageOver => 'Oltre il limite di 100 MB fissato dai termini dell\'API di Last.fm. Cancella la cronologia degli scrobble in Archiviazione per rispettarlo.';
  @override String get apiReset => 'Azzera contatori';
  @override String get apiLimiter => 'Limita le richieste';
  @override String get apiLimiterSub => 'Rallenta le richieste per restare entro i limiti delle API. Disattivato = più veloce, senza attese.';
  @override String get apiResetBody => 'Tutti i contatori delle richieste saranno azzerati.';
  @override String get apiResetDone => 'Contatori azzerati';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (it) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxIt = {
  'st_notif_on': 'Notifiche attive',
  'st_notif_off': 'Notifiche disattivate',
  'st_notif_count': '{n} tipi attivi',
  'st_notif_perm': 'Serve il permesso di sistema',
  'st_notif_none': 'Nessun tipo di notifica scelto',
  'st_sync_on': 'Sincronizzazione automatica attiva',
  'st_sync_off': 'Sincronizzazione automatica disattivata',
  'st_sync_on_s': 'I suoi dati si aggiornano da soli.',
  'st_sync_off_s': 'I dati si aggiornano solo su richiesta.',
  'st_bkp_on': 'Backup automatico attivo',
  'st_bkp_off': 'Backup automatico disattivato',
  'st_bkp_on_s': 'Le sue impostazioni vengono salvate automaticamente.',
  'st_bkp_off_s': 'Attivalo per non perdere mai le impostazioni.',
  'st_bkp_next': 'Prossimo backup: {d}',
  'cmp_breakdown': 'Cosa li avvicina',
  'cmp_by_artists': 'Artisti',
  'cmp_by_genres': 'Generi',
  'cmp_by_tracks': 'Brani',
  'cmp_by_albums': 'Album',
  'eco_on': 'Risparmio energetico attivo',
  'eco_off': 'Risparmio energetico disattivato',
  'eco_why_manual': 'Sempre attivo, scelto da lei',
  'eco_why_system': 'Il risparmio batteria del dispositivo è attivo',
  'eco_why_battery': 'La batteria è al {n}%',
  'eco_off_hint': 'Scelga qui sotto quando attivarlo',
  'eco_trig': 'Quando attivarlo',
  'eco_sys_t': 'Quando il risparmio batteria del dispositivo è attivo',
  'eco_sys_s': 'Segue il risparmio energetico integrato del telefono e si disattiva con esso.',
  'eco_sys_na': 'Non disponibile su questo dispositivo.',
  'eco_chg': 'Cosa cambia',
  'eco_chg1': 'Il parallasse al movimento viene disattivato',
  'eco_chg2': 'La frequenza dello schermo è limitata a circa 60 Hz',
  'eco_chg3': 'Gli aggiornamenti in background sono meno frequenti',
  'eco_chg4': 'Le copertine animate e il riflesso dei badge sono in pausa',
  'eco_chg_note': 'Tutto il resto mantiene la piena qualità: immagini, esportazioni e schede di condivisione.',
  'lib_section': 'Libreria',
  'lib_merge_t': 'Unisci le versioni dello stesso brano',
  'lib_merge_s': 'Remaster, singoli, (feat. …) ed edizioni deluxe contano come un solo brano o album, con gli ascolti sommati. Remix, live e strumentali restano separati.',
  'lib_split_t': 'Separa le collaborazioni',
  'lib_split_s': '«Gims & Damso» conta per Gims e per Damso invece di essere un artista a sé. Gruppi come «Simon & Garfunkel» restano interi.',
  'lib_step_t': 'La sua libreria',
  'lib_step_s': 'Scelga come raggruppare i suoi ascolti. Può cambiarlo in qualsiasi momento nelle impostazioni.',
  'bk_dash_t': 'Dashboard e avvio',
  'bk_dash_s': 'Sezioni, intestazione, schede statistiche, scopri, scheda iniziale',
  'bk_notif_t': 'Notifiche',
  'bk_notif_s': 'Riepiloghi, traguardi, novità e badge',
  'bk_lib_t': 'Opzioni libreria',
  'bk_lib_s': 'Unisci versioni, separa collaborazioni',
  'bk_prof_t': 'Profili preferiti',
  'bk_prof_s': 'I profili Last.fm che ha messo tra i preferiti',
  'about_readme_t': 'README e attività del progetto',
  'about_readme_s': 'Leggi il README, ultimi commit, workflow, versione, download',
  'fold_show': 'Mostra ({n})',
  'fold_hide': 'Comprimi',
  'readme_sub': 'Il progetto e la sua attività',
  'readme_version': 'Versione',
  'readme_downloads': 'Download',
  'readme_stars': 'Stelle',
  'readme_license': 'Licenza',
  'readme_commits': 'Ultimi commit',
  'readme_workflows': 'Ultimi workflow',
  'readme_retry': 'Riprova',
  'readme_github': 'Apri su GitHub',
  'readme_failed': 'Impossibile caricare (offline o limite GitHub raggiunto).',
  'ago_min': '{n} min fa',
  'ago_h': '{n} h fa',
  'ago_d': '{n} g fa',
  'load_restored': '{n} scrobble ripristinati',
  'load_ready': 'Pronto per importare',
  'load_connecting': 'Connessione a Last.fm…',
  'load_done': 'Importazione completata',
  'onb_cov_t': 'Copertine e immagini',
  'onb_cov_s': 'Scelga la forma delle immagini e il comportamento delle copertine.',
  'onb_sync_t': 'Sincronizzazione e batteria',
  'onb_sync_s': 'Mantenga aggiornate le sue statistiche senza scaricare la batteria.',
  'onb_autosync_t': 'Sincronizzazione automatica',
  'onb_autosync_s': 'Controlla regolarmente i suoi nuovi scrobble in background.',
  'onb_freq': 'Frequenza di controllo',
  'onb_every_h': 'Ogni {h} h',
  'load_backup_note': 'Backup rilevato: verranno controllati solo gli scrobble più recenti.',
  'dash_nowplay': 'In riproduzione',
  'dash_stats': 'Statistiche',
  'dash_recent': 'Ascolti recenti',
  'dash_discover': 'Scopri',
  'dash_friends': 'Amici',
  'dash_chart': 'Grafico della dashboard',
  'dash_calendar': 'Calendario',
  'dash_monthly': 'Mensile',
  'cache_video_t': 'Copertine animate (Apple Music)',
  'cache_video_s': 'Memoria video in uso: {mem} · {players} player attivo/i · {links} link in cache',
  'cache_video_short': 'Copertine animate',
  'cache_video_cleared': 'Memoria video liberata',
  'cache_memory_section': 'Memoria',
  'cache_storage_section': 'Archivio',
  'lvl': 'Livello {n}',
  'lvl_history': 'Cronologia livelli',
  'set_living_t': 'Copertine animate',
  'set_living_s': 'Zoom morbido ed effetto profondità sulle immagini',
  'set_motion_t': 'Copertine video',
  'set_motion_s': 'Riproduce la copertina animata quando esiste',
  'set_achv_t': 'Traguardi e livelli',
  'set_achv_s': 'Livelli, badge e livello dell’account',
  'cache_img_limit_t': 'Limite cache foto',
  'cache_img_limit_s': 'Copertine, foto degli artisti e avatar. Le più vecchie vengono eliminate per prime.',
  'cache_vid_limit_t': 'Limite cache video',
  'cache_vid_limit_s': 'Copertine animate di Apple Music salvate su disco per rivederle offline (Android).',
  'cache_video_off': 'Disattivato',
  'cache_vid_disk_t': 'Video Apple Music',
  'cache_vid_disk_s': '{size} · Copertine animate salvate',
  'cache_no_limit_note': 'Scrobble e dati API non hanno mai limiti.',
  'key_internal_use': 'Usa la chiave interna dell\'app',
  'key_internal_help': 'Opzione di riserva: questa chiave è condivisa tra gli utenti. Può raggiungere i limiti o smettere di funzionare e alcune funzioni potrebbero non andare. Usi la sua chiave quando può.',
  'key_internal_active': 'Chiave interna dell\'app',
  'key_fallback_title': 'Chiave interna di riserva',
  'key_fallback_sub': 'Viene usata prima la sua chiave. Se Last.fm la rifiuta, l\'app riprova automaticamente con la chiave interna.',
  'key_use_own': 'Usa la mia chiave API',
  'key_change_title': 'Cambia la chiave API',
  'key_change_sub': 'Sostituisca la sua chiave con un\'altra, oppure passi alla chiave interna dell\'app.',
  'key_change_sub_internal': 'Sta usando la chiave condivisa dell\'app. Aggiunga la sua chiave personale per non dipendere più dai limiti degli altri utenti.',
  'key_change_intro': 'Inserisca una nuova chiave API per questo account, oppure torni alla chiave interna dell\'app. Il suo nome utente e le sue statistiche non cambiano.',
  'key_change_intro_internal': 'Questo account usa al momento la chiave interna dell\'app. Incolli qui sotto la sua chiave API di Last.fm per sostituirla. Il suo nome utente e le sue statistiche non cambiano.',
  'key_change_hint': 'Una chiave API è lunga 32 caratteri. Può crearla o trovarla su last.fm/api/accounts.',
  'key_change_invalid_len': 'Una chiave API deve avere esattamente 32 caratteri. Controlli di averla copiata per intero.',
  'key_change_same': 'Questo account usa già questa chiave. Ne inserisca una diversa.',
  'key_change_check_failed': 'Last.fm non ha accettato questa chiave. Controlli che sia corretta e che sia connesso a Internet, poi riprovi.',
  'key_change_favorites_warn': 'La connessione ai preferiti verrà rimossa, perché dipende dalla vecchia chiave. Potrà ricollegarla in seguito con la sua chiave segreta.',
  'key_change_apply': 'Applica',
  'key_change_success': 'La chiave API è stata aggiornata.',
  'key_internal_fav_note': 'I preferiti richiedono la sua chiave API personale e la sua chiave segreta di Last.fm. Aggiunga la sua chiave qui sopra per poterli attivare.',
  'faq_q15': 'Posso cambiare la mia chiave API dopo aver effettuato l\'accesso?',
  'faq_a15': 'Sì. Vada su Impostazioni > Account e tocchi «Cambia la chiave API». Può sostituire la sua chiave con un\'altra, oppure aggiungere la propria se all\'inizio aveva scelto la chiave interna. Le statistiche restano le stesse, va solo rifatta la connessione ai preferiti.',
  'nothing_wip_badge': 'In miglioramento',
  'nothing_wip_msg': 'Lo stile Nothing OS è in fase di miglioramento e per ora non è disponibile. Potrà essere attivato in una versione futura.',
  'ui_play_preview': 'Riproduci anteprima',
  'ntf_test_title': '🔔 Notifica di prova',
  'ntf_test_body': 'Le notifiche di LastStats funzionano!',
  'ui_not_enough_data_yet_sy': 'Non ci sono ancora abbastanza dati: sincronizza la cronologia completa nelle impostazioni.',
  'ui_level': 'Livello {level}',
  'ui_fetching': 'Recupero {currentYea}… ({yearIndex}/{totalYears})',
  'ui_which_chart': 'Quale grafico?',
  'ui_which_period': 'Quale periodo?',
  'ui_all_time': 'Sempre',
  'ui_exporting': 'Esportazione in corso…',
  'ui_chart_not_available_fo': 'Grafico non disponibile per questo periodo',
  'ui_could_not_generate_the': 'Impossibile generare l\'immagine',
  'ui_error': 'Errore',
  'ui_loading_history': 'Caricamento cronologia{yearLabel}… {pct}%',
  'ui_charts_will_be_more_ac': 'I grafici saranno più precisi dopo il caricamento.',
  'ui_load_the_full_history_': 'Carichi la cronologia completa per accedere a tutti gli anni.',
  'ui_load': 'Carica',
  'ui_based_on_scrobbles_all': 'Basato su {v_hourlyCou} scrobble (tutti gli anni)',
  'ui_all_available_years': 'Tutti gli anni disponibili',
  'ui_based_on_scrobbles_fro': 'Basato su {v_hourlyCou} scrobble del {v_selectedY}',
  'ui_based_on_recent_scrobb': 'Basato su {v_hourlyCou} scrobble recenti',
  'ui_analysing_your_last_20': 'Analisi degli ultimi ~200 scrobble',
  'ui_all_time_loading': 'Sempre (dati {v_selectedY} in caricamento)',
  'ui_all_time_2': 'Sempre',
  'ui_export_a_chart': 'Esporta un grafico',
  'ui_scrobble_progression': 'Andamento degli scrobble',
  'ui_your_musical_genres': 'I suoi generi musicali',
  'ui_based_on_your_top_arti': 'Basato sui suoi artisti preferiti (sempre)',
  'ui_listening_habits': 'Abitudini di ascolto',
  'ui_album_distribution': 'Distribuzione per album',
  'ui_listening_calendar': 'Calendario musicale',
  'ui_daily_activity_to': 'Attività giornaliera — da {first} a {last}',
  'ui_daily_activity_all_yea': 'Attività giornaliera — tutti gli anni',
  'ui_daily_activity': 'Attività giornaliera — {v_selectedY}',
  'ui_load_history_to_see': 'Carichi la cronologia per vedere il {v_selectedY}',
  'ui_daily_activity_last_12': 'Attività giornaliera — ultimi 12 mesi',
  'ui_all_years': 'tutti gli anni',
  'ui_listening_streaks': 'Serie di ascolto',
  'ui_total': 'Totale',
  'ui_avg_mo': 'Media/mese',
  'ui_best_month': 'Mese migliore',
  'ui_hourly_distribution': 'Distribuzione oraria',
  'ui_activity_by_day_of_wee': 'Attività per giorno della settimana',
  'ui_current_streak': 'Serie attuale',
  'ui_d': 'g',
  'ui_best_streak': 'Serie migliore',
  'ui_best_streak_started_on': 'Miglior serie dal {bestStart}',
  'ui_no_data_for_this_perio': 'Nessun dato per questo periodo',
  'ui_load_history_to_displa': 'Carichi la cronologia per mostrare {what}',
  'ui_less': 'Meno',
  'ui_more': 'Più',
  'ui_scan_a_profile': 'Scansiona un profilo',
  'ui_lvl': 'Liv. {level}',
  'ui_qr_code': 'Codice QR?',
  'ui_add_a_qr_code_to_the_s': 'Aggiungere un codice QR all\'immagine condivisa, così chi la vede può scansionare il suo profilo?',
  'ui_no_qr': 'Senza QR',
  'ui_to_the_app': 'All\'app',
  'ui_to_last_fm': 'A Last.fm',
  'ui_compare_music_taste': 'Confronta i gusti musicali',
  'ui_syncing_full_library': 'Sincronizzazione dei dati…',
  'ui_see_more': 'Mostra altro',
  'ui_no_achievements_unlock': 'Nessun traguardo sbloccato per ora',
  'ui_no_animated_cover_for_': 'Nessuna copertina animata per questo album',
  'ui_source': 'Fonte: {source}',
  'ui_view_on_last_fm': 'Vedi su Last.fm',
  'ui_original_text_last_fm_': 'Testo originale: Last.fm — Traduzione: Google Translate',
  'ui_source_last_fm': 'Fonte: Last.fm',
  'ui_dark': 'Scuro',
  'ui_light': 'Chiaro',
  'ui_system': 'Sistema',
  'ui_colored_widgets': 'Widget colorati',
  'ui_tint_home_screen_widge': 'Colora i widget con il colore d\'accento',
  'ui_search_settings': 'Cerca un\'impostazione…',
  'ui_no_settings_found': 'Nessuna impostazione trovata',
  'ui_all': 'Tutte',
  'ui_battery_saver': 'Risparmio batteria',
  'ui_save_battery_fewer_eff': 'Risparmia batteria, meno effetti',
  'ui_musical_soulmates': 'Anime musicali gemelle',
  'ui_great_compatibility': 'Ottima compatibilità',
  'ui_some_common_ground': 'Qualcosa in comune',
  'ui_fairly_different_taste': 'Gusti piuttosto diversi',
  'ui_worlds_apart_musically': 'Mondi musicali opposti',
  'ui_this_is_your_own_profi': 'È il suo profilo!',
  'ui_artists_from_your_hist': '{uniqueArti} artisti dalla sua cronologia · libreria completa di {targetUser}',
  'ui_artists_from_your_hist_2': '{uniqueArti} artisti dalla sua cronologia · top 200 di {targetUser}',
  'ui_full_library_api': 'Libreria completa (API)',
  'ui_top_200_artists_tracks': 'Top 200 artisti e brani (API)',
  'ui_could_not_work_out_the': 'Impossibile calcolare la compatibilità.',
  'ui_music_compatibility': 'Compatibilità musicale',
  'ui_analyzing_musical_tast': 'Analisi dei gusti musicali…',
  'ui_artist': '{v_totalArti} artisti',
  'ui_track': '{v_totalTrac} brani',
  'ui_album': '{v_totalAlbu} album',
  'ui_shared_tracks': 'Brani in comune',
  'ui_shared_artists': 'Artisti in comune',
  'ui_no_shared_artists_foun': 'Nessun artista in comune trovato.',
  'ui_shared_albums': 'Album in comune',
  'ui_play_count_unavailable': 'Numero di ascolti non disponibile per uno dei due.',
  'ui_you_listen_to_this_x_m': 'Lo ascolta {x}x più di {theirUsern}.',
  'ui_listens_to_this_x_more': '{theirUsern} lo ascolta {x}x più di lei.',
  'ui_you_both_listen_to_thi': 'Lo ascoltano più o meno allo stesso modo.',
  'ui_plays': '{plays} ascolti',
  'ui_compatibility': 'compatibilità',
  'ui_you_both_love': 'PIACE A ENTRAMBI',
  'ui_shared_top_artist': 'ARTISTA PREFERITO IN COMUNE',
  'ui_achievements': 'Traguardi',
  'ui_qr_not_recognized_not_': 'QR non riconosciuto: non è un profilo LastStats/Last.fm',
  'ui_scan_a_profile_s_qr_co': 'Scansioni il codice QR di un profilo',
  'ui_favorites': 'Preferiti',
  'ui_advanced_youtube_music': 'Client avanzato per YouTube Music.',
  'ui_syncs_the_glyphs_of_no': 'Sincronizza i Glyph dei telefoni Nothing con la musica.',
  'ui_sources': 'Fonti',
  'ui_official_flutter_docs_': 'Documentazione ufficiale di Flutter.',
  'ui_official_material_3_gu': 'Guida ufficiale a Material 3 per Flutter.',
  'ui_flutter_api_reference_': 'Riferimento API Flutter per Material 3.',
  'ui_official_flutter_packa': 'Pacchetto ufficiale Flutter per layout adattivi.',
  'ui_android_widgets': 'Widget Android',
  'ui_applies_the_accent_col': 'Applica il colore d\'accento allo sfondo dei widget nella schermata home. Disattivato: bianco o nero puro.',
  'ui_turns_off_tilt_paralla': 'Disattiva il parallasse al movimento, limita la frequenza di aggiornamento dello schermo e rallenta gli aggiornamenti in background: tutto il resto mantiene la piena qualità (immagini, esportazioni, schede di condivisione).',
  'ui_always_on': 'Sempre attivo',
  'ui_force_eco_mode_on_rega': 'Forza la modalità risparmio, indipendentemente dal livello della batteria.',
  'ui_auto_activate': 'Attivazione automatica',
  'ui_turn_on_below_a_batter': 'Attiva sotto una % di batteria',
  'ui_switches_on_by_itself_': 'Si attiva da sola quando la batteria scende al livello indicato sotto.',
  'ui_threshold': 'Soglia',
  'ui_choose_the_tab_display': 'Scelga la scheda mostrata all\'avvio dell\'app.',
  'ui_the_selected_tab_will_': 'La scheda selezionata apparirà al prossimo avvio dell\'app.',
  'ui_friends_sync': 'Sincronizzazione amici',
  'ui_sync_frequency': 'Frequenza di sincronizzazione',
  'ui_daily': 'Ogni giorno',
  'ui_resync_everyone': 'Risincronizza tutto',
  'ui_version_history': 'Cronologia versioni',
  'ui_could_not_load_release': 'Impossibile caricare la cronologia.',
  'ui_installed_dev_build_un': 'Installata: build di sviluppo (versione sconosciuta)',
  'ui_installed': 'Installata: {displayVer}',
  'ui_search_a_version_or_ch': 'Cerchi una versione o un changelog…',
  'ui_official': 'Ufficiale',
  'ui_no_release_matches_you': 'Nessuna versione corrisponde alla ricerca.',
  'ui_latest': 'ULTIMA',
  'ui_installed_2': 'INSTALLATA',
  'ui_no_description': 'Nessuna descrizione.',
  'ui_download': 'Scarica',
  'ui_view_release': 'Vedi release',
  'ui_details': 'Dettagli',
  'ui_all_past_releases_chan': 'Tutte le versioni passate, changelog e download',
  'ui_please_fill_both_field': 'Compili entrambi i campi.',
  'ui_api_key_must_be_32_cha': 'La chiave API deve avere 32 caratteri.',
  'ui_profile_not_found': 'Profilo non trovato.',
  'ui_chart_monthly': 'Barre mensili',
  'ui_chart_cumul': 'Progressione',
  'ui_chart_genres': 'Generi musicali',
  'ui_chart_habits': 'Abitudini di ascolto',
  'ui_chart_artists': 'Distribuzione degli artisti',
  'ui_chart_albums': 'Distribuzione degli album',
  'ui_chart_calendar': 'Calendario di ascolto',
  'ui_chart_streaks': 'Serie di ascolto',
  'ui_band_night': 'Notte',
  'ui_band_morning': 'Mattina',
  'ui_band_afternoon': 'Pomeriggio',
  'ui_band_evening': 'Sera',
  'qs_t1_t': 'Modalità OLED',
  'qs_t1_s': 'Sfondo nero puro',
  'qs_t2_t': 'Modalità risparmio energetico',
  'qs_t2_s': 'Riduce il consumo della batteria',
  'qs_t3_t': 'Notifiche notizie',
  'qs_t3_s': 'Avvisi sulle novità di Last.fm',
  'qs_t4_t': 'Feedback aptico',
  'qs_t4_s': 'Vibrazioni durante le interazioni',
  'qs_t5_t': 'Obiettivi',
  'qs_t5_s': 'Mostra gli obiettivi sbloccati',
  'qs_l1_t': 'Colore accento',
  'qs_l2_t': 'Tema',
  'qs_l3_t': 'Lingua',
  'qs_l4_t': 'Piattaforma musicale',
  'qs_l5_t': 'Account',
  'qs_l6_t': 'Sincronizzazione',
  'qs_l7_t': 'Cache',
  'img_src_lastfm': 'Fonte: Last.fm',
  'img_src_ytmusic': 'Fonte: YouTube Music',
  'img_src_itunes': 'Fonte: iTunes',
  'img_src_deezer': 'Fonte: Deezer',
  'img_src_audiodb': 'Fonte: TheAudioDB',
  'img_src_musicbrainz': 'Fonte: MusicBrainz',
  'img_src_wikipedia': 'Fonte: Wikipedia',
  'ds_type_artist': 'Artista',
  'ds_type_album': 'Album',
  'ds_type_track': 'Brano',
  'pf_1': '👤 Profilo utente',
  'pf_2': '🎤 Top artisti — Globale',
  'pf_3': '💿 Top album — Globale',
  'pf_4': '🎵 Top brani — Globale',
  'pf_5': '⏱️ Ascolti recenti',
  'pf_6': '🗓️ Questa settimana',
  'pf_7': '📅 Questo mese',
  'pf_8': '📅 Ultimi 3 mesi',
  'pf_9': '📅 Ultimi 6 mesi',
  'pf_10': '📅 Ultimi 12 mesi',
  'pf_11': '📊 Cronologia mensile',
  'pf_12': '❤️ Brani preferiti',
  'pf_13': '🗓️ Top artisti — Settimana',
  'pf_14': '🗓️ Album e brani — Settimana',
  'ds_tier_next': '{n} / {next} al prossimo livello',
  'ds_tier_max': 'Livello massimo raggiunto 🎉',
  'ds_tier_first': 'Ascolti questo brano per sbloccare un primo livello (da {n} ascolti).',
  'sl_import': 'Importazione dei suoi dati',
  'sl_done': 'Importato!',
  'sl_connect': 'Connessione a Last.fm…',
  'sec_chart': 'Grafico / calendario',
  'stat_avg_day': 'Media / giorno',
  'stat_avg_week': 'Media / settimana',
  'stat_days_active': 'Giorni attivi',
  'stat_scrobbles_week': 'Scrobble (settimana)',
  'accent_purple': 'Viola',
  'accent_blue': 'Blu',
  'accent_green': 'Verde',
  'accent_red': 'Rosso',
  'accent_orange': 'Arancione',
  'accent_pink': 'Rosa',
  'accent_teal': 'Verde acqua',
  'accent_neutral': 'Neutro',
  'shape_title': 'Forme delle immagini',
  'shape_covers': 'Copertine, artisti e album',
  'shape_mix': 'Misto',
  'shape_square': 'Quadrato',
  'shape_circle': 'Cerchio',
  'shape_pick_one': 'O scegli una sola forma',
  'friend_listening': 'In ascolto',
  'friend_offline': 'Offline',
  'tier_none': 'Nessun livello',
  'src_title': 'Fonti',
  'src_scrobbles_meta': 'Scrobble e metadati',
  'src_artwork': 'Copertina',
  'src_audio_preview': 'Anteprima audio',
  'src_video_artwork': 'Copertina video',
  'tip_love': 'Aggiungi ai preferiti',
  'rail_expand': 'Espandi barra laterale',
  'rail_collapse': 'Comprimi barra laterale',
  'a11y_loading': 'Caricamento',
  'bk_pick_folder': 'Scegli la cartella del backup automatico',
  'bk_save_title': 'Salva il backup di LastStats',
  'bk_pick_file': 'Scegli un file di backup di LastStats',
  'nch_milestone_d': 'Avvisa quando raggiungi un traguardo di scrobble',
  'nch_grand_d': 'Avvisi speciali per i grandi traguardi (1K, 10K, 100K, 1M…)',
  'nch_recap_d': 'Riepiloghi di ascolto giornalieri e settimanali',
  'nch_update_d': 'Avvisa quando è disponibile una nuova versione di LastStats',
  'nch_news_d': 'Novità, correzioni e annunci su LastStats',
  'nch_sync_d': 'Avanzamento della sincronizzazione dell’intera cronologia',
  'ntf_grand_1000000': 'Un milione di scrobble. Leggendario. 🎸',
  'ntf_grand_500000': 'Mezzo milione di scrobble. Non ti fermi mai. 🎧',
  'ntf_grand_250000': '{n} scrobble: la musica non finisce mai. 🎶',
  'ntf_grand_100000': '{n} scrobble! Sei un vero appassionato di musica. 🔥',
  'ntf_grand_50000': '{n} scrobble. Davvero impressionante. 🎵',
  'ntf_grand_25000': '{n} scrobble e sei ancora in forma!',
  'ntf_grand_10000': '{n} scrobble: hai raggiunto le cinque cifre! 🎉',
  'ntf_grand_5000': '{n} scrobble e si continua!',
  'ntf_grand_1000': 'I tuoi primi {n} scrobble. Il viaggio inizia. 🎵',
  'ntf_update_title': 'LastStats {v} disponibile',
  'ntf_update_body': 'Una nuova versione è pronta per essere scaricata.',
  'ntf_milestone_title': '🎵 Traguardo: {n} scrobble',
  'ntf_milestone_body': 'Hai appena raggiunto {n} scrobble su Last.fm 🎶',
  'ntf_daily_title': '📊 Riepilogo del giorno · {d}',
  'ntf_weekly_title': '📅 Riepilogo settimanale · {w}',
  'ntf_recap_body': '{n} scrobble · Top: {a}',
  'ntf_n_today': '{n} scrobble oggi',
  'ntf_n_week': '{n} scrobble questa settimana',
  'ntf_top_artist': 'Artista top: {a}',
  'ntf_update_avail': '🆕 Aggiornamento disponibile',
  'ntf_update_ready': 'LastStats {v} è pronto: tocca per vedere.',
  'ntf_sync_title': '🔄 Sincronizzazione scrobble…',
  'ntf_sync_done': '✅ Scrobble sincronizzati',
  'ntf_sync_new': '{n} nuovo/i scrobble aggiunto/i.',
  'ntf_grand_t': '{v} scrobble!',
  'ntf_year': 'Anno {y}',
  'ntf_week': 'Settimana {w}',
  'reorder': 'Riordina',
  'sp_login_t': 'Accesso a Spotify',
  'sp_login_hint': 'Acceda con la sua e-mail e la sua password di Spotify. La finestra si chiude da sola al termine.',
  'sp_t': 'Spotify (Canvas)',
  'sp_on': 'Connesso',
  'sp_off': 'Non connesso',
  'sp_off_s': 'Disconnesso da Spotify',
  'sp_need': 'Spotify richiede l\'accesso: Profilo > Pagina di connessione.',
  'conn_title': 'Connessioni',
  'conn_btn_t': 'Pagina di connessione',
  'conn_btn_s': 'Last.fm, Spotify e chiavi API',
  'conn_sp_desc': 'Serve per i video di copertina (Canvas). È necessario un account Spotify.',
  'conn_connect': 'Connetti',
  'conn_disconnect': 'Disconnetti',
  'conn_keys': 'Chiavi API',
  'conn_manage': 'Gestisci account',
  'conn_test': 'Prova Spotify',
  'conn_testing': 'Prova in corso…',
  'conn_q_note': 'Spotify Canvas ha una sola qualità. Le impostazioni di qualità valgono solo per Apple Music e YouTube.',
  'conn_lfm_desc': 'Due metodi: accedere dal sito di Last.fm (viene usata la chiave integrata nell\'app) oppure usare la sua chiave API.',
  'conn_lfm_web': 'Accedi con Last.fm',
  'lfm_login_t': 'Accesso a Last.fm',
  'lfm_login_hint': 'Acceda al sito di Last.fm. L\'app rileverà il suo nome utente e chiuderà la finestra.',
  'dg_cookie': 'Cookie di accesso',
  'dg_token': 'Token web',
  'dg_search': 'Ricerca',
  'dg_ok': 'ok',
  'dg_missing': 'ASSENTE',
  'dg_failed': 'ERRORE',
  'dg_found': 'video trovato',
  'dg_nofound': 'nessun video',
  'dg_notpl': 'modello di ricerca assente (riprovi tra un momento)',
  'dg_results': 'risultati',
  'lfm_web_sub': 'Nessuna chiave API: viene usata la chiave integrata nell\'app.',
  'lfm_manual_hint': 'Nome utente non trovato automaticamente. Lo inserisca qui sotto dopo l\'accesso.',
  'lfm_manual_label': 'Nome utente',
  'rec': 'consigliato',
  'not_rec': 'sconsigliato',
  'sm_title': 'Metodo di connessione',
  'sm_key_t': 'La mia chiave API',
  'sm_key_s': 'Quota solo sua, preferiti possibili.',
  'sm_builtin_t': 'Chiave integrata',
  'sm_builtin_s': 'Solo nome utente. Quota condivisa con altri utenti.',
  'wl_title': 'Benvenuto',
  'wl_sub': 'Scelga come desidera connettersi a Last.fm.',
};
