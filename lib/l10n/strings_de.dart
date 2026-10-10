// lib/l10n/strings_de.dart
// ══════════════════════════════════════════════════════════════════════════
//  German
// ══════════════════════════════════════════════════════════════════════════

import "app_strings.dart";

class AppStringsDe implements AppStrings {
  const AppStringsDe();

  @override String get period7day => 'Woche';
  @override String get period1month => 'Monat';
  @override String get period3month => '3 Monate';
  @override String get period6month => '6 Monate';
  @override String get period12month => 'Jahr';
  @override String get periodOverall => 'Gesamt';
  @override String get navDashboard => 'Übersicht';
  @override String get navSearch => 'Suche';
  @override String get navRankings => 'Ranglisten';
  @override String get navCharts => 'Charts';
  @override String get navHistory => 'Verlauf';
  @override String get navSettings => 'Einstellungen';
  @override String get cacheTitle => 'Speicher';
  @override String get cacheUsage => 'Belegung';
  @override String get cacheLimit => 'Speicherlimit';
  @override String get cacheLimitHint => 'Wird das Limit erreicht, werden die am längsten nicht verwendeten Bilder automatisch gelöscht.';
  @override String get cacheClearSection => 'Leeren';
  @override String get cacheImages => 'Bilder';
  @override String get cacheImagesSubtitle => 'Cover von Künstlern, Alben und Titeln';
  @override String get cacheApiData => 'API-Daten';
  @override String get cacheApiDataSubtitle => 'Top-Künstler, Alben, letzte Titel…';
  @override String get cacheScrobbles => 'Scrobble-Verlauf';
  @override String get cacheScrobblesSubtitle => 'Alle heruntergeladenen Scrobble-Daten';
  @override String get cacheClearBtn => 'Leeren';
  @override String get cacheConfirmScrobblesTitle => 'Scrobble-Verlauf löschen?';
  @override String get cacheConfirmScrobblesBody => 'Der gesamte Verlauf wird gelöscht und beim nächsten Start erneut heruntergeladen.';
  @override String get cacheConfirmAllTitle => 'Gesamten Cache löschen?';
  @override String get cacheConfirmAllBody => 'Bilder, API-Daten und Scrobble-Verlauf werden vollständig gelöscht.';
  @override String get cacheDelete => 'Löschen';
  @override String get commonArtists => 'Künstler';
  @override String get commonAlbums => 'Alben';
  @override String get commonTracks => 'Titel';
  @override String get commonNoResults => 'Keine Ergebnisse';
  @override String get commonRetry => 'Erneut versuchen';
  @override String get commonCancel => 'Abbrechen';
  @override String get commonApply => 'Anwenden';
  @override String get commonPlays => 'Wiedergaben';
  @override String get commonListeners => 'Hörer';
  @override String get commonNowPlayingBadge => 'LIVE';
  @override String get commonNowPlayingLong => 'Läuft gerade';
  @override String get commonRecentTracks => 'Letzte Titel';
  @override String get commonNoRecentTracks => 'Keine letzten Titel';
  @override String get commonTopArtists => 'Top-Künstler';
  @override String get rankingsTitle => 'Ranglisten';
  @override String get rankingsPodium => 'Podium';
  @override String get rankingsContinued => 'Restliche Rangliste';
  @override String get rankingsAllYears => 'Alle Jahre';
  @override String get chartsTitle => 'Charts';
  @override String get chartsMonthly => 'Scrobbles (12 Monate)';
  @override String get chartsArtistDist => 'Top-Künstler (Aufteilung)';
  @override String get chartsMainstreamTitle => 'Mainstream vs. Geheimtipps';
  @override String get chartsMainstreamSubtitle => 'Globale Popularität Ihrer Lieblingskünstler.';
  @override String get chartsCompute => 'Berechnen';
  @override String get chartsRecompute => 'Neu berechnen';
  @override String get chartsGem => 'Geheimtipp';
  @override String get chartsMainstream => 'Mainstream';
  @override String get historyTitle => 'Verlauf';
  @override String get historySubtitle => 'Ihre Anhörungen, Tag für Tag';
  @override String get historyToday => 'Heute';
  @override String get historySelectDate => 'Datum auswählen';
  @override String get historyChronological => 'Chronologisch';
  @override String get historyList => 'Liste';
  @override String get historyStats => 'Statistik';
  @override String get historyNoTracks => 'Keine Anhörungen an diesem Tag';
  @override String get historyTopArtists => 'Top-Künstler';
  @override String get historyTopAlbums => 'Top-Alben';
  @override String get historyTopTracks => 'Top-Titel';
  @override String get historyHourTracks => 'Titel';
  @override String get searchTitle => 'Suche';
  @override String get searchProfiles => 'Profile';
  @override String get searchHintBar => 'Künstler, Album, Titel oder Profil…';
  @override String get searchHintProfiles => 'Last.fm-Nutzer finden';
  @override String get searchHintArtists => 'Künstler finden';
  @override String get searchHintAlbums => 'Album finden';
  @override String get searchHintTracks => 'Song finden';
  @override String get searchTypePrompt => 'Oben in die Suchleiste tippen';
  @override String get searchAll => 'Alle';
  @override String get searchFolders => 'Ordner';
  @override String get searchFoldersHint => 'Erstellen Sie einen Ordner, um Titel, Alben oder Künstler zu speichern.';
  @override String get perDay => 'pro Tag';
  @override String get activityDays => 'aktive Tage';
  @override String get dashStats => 'Statistik';
  @override String get dashTopTracks => 'Top-Titel';
  @override String get dashFriends => 'Freunde';
  @override String get dashRefresh => 'Aktualisieren';
  @override String get dashRefreshFriends => 'Freunde aktualisieren';
  @override String get dashScrobbles => 'Scrobbles';
  @override String get dashScrobblesPerDay => 'pro Tag';
  @override String get dashDaysActive => 'aktive Tage';
  @override String get dashLastTrack => 'Zuletzt gehört';
  @override String get dashArtist1 => 'Künstler Nr. 1';
  @override String get dashAlbum1 => 'Album Nr. 1';
  @override String get dashTrack1 => 'Titel Nr. 1';
  @override String get dashNoFriends => 'Keine Freunde gefunden';
  @override String get dashResetCache => 'Cache zurücksetzen';
  @override String get dashResetCacheConfirm => 'Alle lokal zwischengespeicherten Scrobble-Daten werden gelöscht und erneut von Last.fm heruntergeladen.';
  @override String get dashFriendsActivity => 'Aktivität Ihrer Last.fm-Freunde';
  @override String get settingsTitle => 'Einstellungen';
  @override String get settingsAppearance => 'Erscheinungsbild';
  @override String get settingsTheme => 'Design';
  @override String get settingsThemeAuto => 'Automatisch';
  @override String get settingsThemeLight => 'Hell';
  @override String get settingsThemeDark => 'Dunkel';
  @override String get settingsAccentColor => 'Akzentfarbe';
  @override String get settingsAccentAuto => 'Automatisch';
  @override String get settingsCustomColor => 'Benutzerdefiniert';
  @override String get settingsCustomColorEdit => 'Bearbeiten';
  @override String get settingsDynamicColor => 'Dynamische Farbe';
  @override String get settingsDayNightAccent          => 'Tag/Nacht-Akzent';
  @override String get settingsDayNightAccentToggle    => 'Unterschiedliche Farben für Tag/Nacht';
  @override String get settingsDayNightAccentToggleSub => 'Verwendet eine andere Akzentfarbe für das dunkle Design.';
  @override String get settingsDayNightAccentDark      => 'Farbe (dunkles Design)';
  @override String get settingsDayNightUseHours        => 'Feste Uhrzeiten verwenden';
  @override String get settingsDayNightUseHoursSub     => 'Wechselt die Farbe nach Uhrzeit statt nach aktivem Design.';
  @override String get settingsDayNightDayStart        => 'Tag beginnt um';
  @override String get settingsDayNightNightStart      => 'Nacht beginnt um';
  @override String get settingsMaterialYou => 'Material You';
  @override String get settingsMaterialYouSub => 'Android-Hintergrundfarbe verwenden';
  @override String get settingsMusicColor => 'Farbe aus Musik';
  @override String get settingsMusicColorSub => 'Extrahiert die Farbe aus dem aktuellen Albumcover';
  @override String get settingsMusicColorNote => 'Die dominante Farbe des aktuellen Albumcovers ersetzt den Akzent.';
  @override String get settingsMusicColorLocked => 'Zuerst Material You deaktivieren';
  @override String get settingsStartupPage => 'Startseite';
  @override String get settingsStartupTab => 'Tab beim Start';
  @override String get settingsDashboardSection => 'Übersicht';
  @override String get settingsHeaderImage => 'Kopfbild';
  @override String get settingsHeaderImageSub => 'Das gewählte Cover wird als Hintergrund der Startseite angezeigt.';
  @override String get settingsHeaderSource => 'Quelle';
  @override String get settingsHeaderPeriod => 'Zeitraum';
  @override String get settingsHeaderAnimation => 'Übergang';
  @override String get settingsHeaderAnimationSub => 'Animation beim Wechsel des Covers.';
  @override String get settingsHeaderBlur => 'Weichzeichnung';
  @override String get settingsHeaderBlurNone => 'Keine';
  @override String get settingsHeaderCustomUrl => 'Bild-URL';
  @override String get settingsHeaderCustomUrlHint => 'https://example.com/image.jpg';
  @override String get settingsHeaderCustomUrlSub => 'Fügen Sie die direkte URL eines Bildes ein (jpg, png, webp…).';
  @override String get settingsHeaderApply => 'Anwenden';
  @override String get settingsHeaderFallback => 'Standardbild';
  @override String get settingsHeaderFallbackSub => 'Wird angezeigt, wenn keine Musik läuft.';
  @override String get settingsHeaderFallbackUrlLabel => 'URL des Standardbilds';
  @override String get settingsVisibleSections => 'Sichtbare Bereiche';
  @override String get settingsNowPlayingSection => 'Läuft gerade';
  @override String get settingsStatsSection => 'Statistik';
  @override String get settingsTopArtistsSection => 'Top-Künstler';
  @override String get settingsTopTracksSection => 'Top-Titel';
  @override String get settingsFriendsSection => 'Freunde';
  @override String get settingsFriendsSectionSub => 'Aktivität Ihrer Last.fm-Freunde';
  @override String get settingsAccount => 'Konto';
  @override String get settingsConnectedProfile => 'Verbundenes Last.fm-Profil';
  @override String get settingsLogout => 'Abmelden';
  @override String get settingsLogoutTitle => 'Abmelden?';
  @override String get settingsLogoutContent => 'Ihre Zugangsdaten werden gelöscht.';
  @override String get settingsLogoutConfirm => 'Abmelden';
  @override String get settingsBackup => 'Sicherung & Wiederherstellung';
  @override String get settingsExport => 'Einstellungen exportieren';
  @override String get settingsExportSub => 'Kopiert ein JSON in die Zwischenablage';
  @override String get settingsImport => 'Sicherung wiederherstellen';
  @override String get settingsImportSub => 'Zuvor exportiertes JSON einfügen';
  @override String get settingsBackupInfo => 'Enthält: Design, Farben, API-Schlüssel, Benutzername, Kopfbild, Favoriten. Versionsübergreifend kompatibel.';
  @override String get settingsUpdates => 'Updates';
  @override String get settingsAutoUpdate => 'Automatische Prüfung';
  @override String get settingsAutoUpdateSub => 'Einmal täglich';
  @override String get settingsCheckNow => 'Jetzt prüfen';
  @override String get settingsUpToDate => 'Aktuell';
  @override String get settingsCheckFailed => 'Prüfung fehlgeschlagen.';
  @override String get settingsDownload => 'Herunterladen';
  @override String get settingsViewRelease => 'Ansehen';
  @override String get settingsAbout => 'Über';
  @override String get settingsVersion => 'Version';
  @override String get settingsWebVersion => 'Web-Version';
  @override String get settingsWebVersionSub => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode => 'Quellcode';
  @override String get settingsSourceCodeSub => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage => 'Sprache';
  @override String get settingsAboutProjectDesc => 'LastStats ist ein persönliches Open-Source-Projekt. Es kann Fehler enthalten.';
  @override String get settingsAboutSupport => 'Projekt unterstützen';
  @override String get settingsAboutSupportSub => '⭐ Hinterlassen Sie einen Stern auf GitHub';
  @override String get settingsFaq => 'FAQ';
  @override String get headerNowPlaying => 'Läuft gerade';
  @override String get headerTopTrack => 'Titel Nr. 1';
  @override String get headerTopAlbum => 'Album Nr. 1';
  @override String get headerTopArtist => 'Künstler Nr. 1';
  @override String get headerCustomImage => 'Eigenes Bild';
  @override String get headerThemeColor => 'Designfarbe';
  @override String get headerAnimNone => 'Keine';
  @override String get headerAnimFade => 'Überblenden';
  @override String get headerAnimSlide => 'Schieben';
  @override String get headerAnimZoom => 'Zoom';
  @override String get headerPeriodWeek => 'Woche';
  @override String get headerPeriodMonth => 'Monat';
  @override String get headerPeriodAllTime => 'Gesamt';
  @override String get colorPickerTitle => 'Benutzerdefinierte Farbe';
  @override String get colorPickerHue => 'Farbton';
  @override String get colorPickerSaturation => 'Sättigung';
  @override String get colorPickerBrightness => 'Helligkeit';
  @override String get colorPickerQuickColors => 'Schnellfarben';
  @override String get colorPickerInvalid => 'Ungültiges Format';
  @override String get colorCustomTooltip => 'Benutzerdefiniert';
  @override String get exportTitle => 'Einstellungen exportieren';
  @override String get exportFilename => 'Dateiname';
  @override String get exportJsonContent => 'JSON-Inhalt';
  @override String get exportInfo => 'Kopieren Sie dieses JSON, fügen Sie es in eine Textdatei ein und benennen Sie sie mit .json';
  @override String get exportCopy => 'JSON kopieren';
  @override String get exportCopied => 'Kopiert!';
  @override String get importTitle => 'Sicherung wiederherstellen';
  @override String get importHintLabel => 'Fügen Sie hier Ihre LastStats-Sicherung ein.';
  @override String get importEmpty => 'Feld ist leer.';
  @override String get importInvalidJson => 'Ungültiges JSON.';
  @override String get importUnknownFile => 'Nicht erkannte Datei.';
  @override String get importInvalidFormat => 'Ungültiges Format.';
  @override String get importSuccess => 'Einstellungen erfolgreich wiederhergestellt ✓';
  @override String get importRestore => 'Wiederherstellen';
  @override String get setupImportJson => 'JSON importieren';
  @override String get setupImportHintLabel => 'Fügen Sie unten den Inhalt Ihrer JSON-Datei ein.';
  @override String get setupImportNote => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields => 'Ungültiges JSON: Felder "username" oder "api_key" fehlen.';
  @override String get detailTracklist => 'Titel';
  @override String get detailAlbumLabel => 'Album';
  @override String get detailDuration => 'Dauer';
  @override String get detailTopTracks => 'Beliebte Titel';
  @override String get detailTopAlbums => 'Beliebte Alben';
  @override String get detailBioReadMore => 'Mehr lesen';
  @override String get detailBioReadLess => 'Weniger anzeigen';
  @override String get detailUserPlays => 'Ihre Wiedergaben';
  @override String get detailGlobalPlays => 'Wiedergaben insgesamt';
  @override String get detailUserRank => 'Rang';
  @override String get detailUserRankNA => 'k. A.';
  @override String get detailGlobalListeners => 'Hörer';
  @override String get detailPeriod => 'Zeitraum';
  @override String get detailBiography => 'Biografie';
  @override String get detailGlobalListenersLabel => 'Hörer';
  @override String get detailTranslate => 'Übersetzen';
  @override String get detailShowOriginal => 'Original anzeigen';
  @override String get detailLyrics => 'Songtext';
  @override String get detailLyricsNotFound => 'Songtext nicht verfügbar';
  @override String get detailCopyLyrics => 'Songtext kopieren';
  @override String get detailLyricsCopied => 'Songtext kopiert';

  @override String get detailShoutbox => 'Last.fm-Shoutbox';
  @override String get detailShoutboxReply => 'Antworten';  @override String get dashPerWeek => 'pro Woche';
  @override String get onboardSkip => 'Überspringen';
  @override String get onboardNext => 'Weiter';
  @override String get onboardFinish => 'Fertig';
  @override String get onboardBack => 'Zurück';
  @override String get onboardAppearanceTitle => 'Personalisieren Sie Ihren Stil';
  @override String get onboardAppearanceSub => 'Design, Akzentfarbe und Material You.';
  @override String get onboardNotifTitle => 'Immer auf dem Laufenden';
  @override String get onboardNotifSub => 'Benachrichtigungen und Vibrationen.';
  @override String get onboardFavTitle => 'Ihre Lieblingsprofile';
  @override String get onboardFavSub => 'Fügen Sie Last.fm-Freunde hinzu, um sie schnell zu finden.';
  @override String get onboardFavHint => 'Last.fm-Benutzername';
  @override String get onboardFavAdd => 'Hinzufügen';
  @override String get onboardFavEmpty => 'Noch keine Favoriten';
  @override String get onboardFavSearchHint => 'Last.fm-Profil suchen…';
  @override String get onboardFavNoResults => 'Kein Profil gefunden';
  @override String get onboardFavFriendsTitle => 'Ihre Last.fm-Freunde';
  @override String get onboardFavNoFriends => 'Keine Freunde auf diesem Konto gefunden';
  @override String get onboardFavSelected => 'Ausgewählte Favoriten';
  @override String get onboardDashTitle => 'Ihre Übersicht';
  @override String get onboardDashSub => 'Wählen Sie, welche Bereiche angezeigt werden.';
  @override String get onboardStartupTitle => 'Startbildschirm';
  @override String get onboardStartupSub => 'Welchen Tab möchten Sie zuerst sehen?';
  @override String get onboardPlatformTitle => 'Worauf hören Sie Musik?';
  @override String get onboardPlatformSub => 'Damit werden nur die nützlichen Links auf Titel-/Künstler-/Album-Seiten angezeigt.';
  @override String get platformLastfm => 'Last.fm';
  @override String get platformSpotify => 'Spotify';
  @override String get platformYtMusic => 'YouTube Music';
  @override String get platformOther => 'Andere / alle anzeigen';
  @override String get settingsMusicPlatform => 'Musikplattform';
  @override String get settingsMusicPlatformSub => 'Filtert die auf Detailseiten angezeigten Links';
  @override String get settingsShowAllPlatformLinks => 'Immer alle anzeigen';
  @override String get settingsShowAllPlatformLinksSub => 'Filter ignorieren und jeden Link anzeigen (Last.fm, Spotify, YT Music, Web)';
  @override String get onboardUpdatesTitle => 'Updates';
  @override String get onboardUpdatesSub => 'Automatische Prüfung auf neue Versionen.';
  @override String get onboardStyle => 'Stil';
  @override String get onboardStyleMaterialYou => 'Material You';
  @override String get onboardStyleNothing => 'Nothing OS';
  @override String get onboardPreview => 'Vorschau';
  @override String get onboardPreviewButton => 'Button';
  @override String get onboardPreviewOutline => 'Umriss';
  @override String get onboardPreviewText => 'Beispieltext';
  @override String get onboardPreviewBubble => 'Sprechblase';
  @override String get onboardAccentTint => 'Akzentton';
  @override String get onboardNothingRedOnly => 'Nur Rot';
  @override String get onboardNothingRedYellow => 'Rot + Gelb';
  @override String get onboardDisplay => 'Anzeige';
  @override String get onboardOledTitle => 'OLED-Echtschwarz';
  @override String get onboardOledSub => 'Reiner schwarzer Hintergrund im Dunkelmodus';
  @override String get onboardArtworkColorTitle => 'Farbe aus dem Cover';
  @override String get onboardArtworkColorSub => 'Akzentfarbe an das aktuelle Cover anpassen';
  @override String get onboardNewsTitle => 'Neuigkeiten-Benachrichtigungen';
  @override String get onboardNewsSub => 'Werden Sie über neue Funktionen und Fehlerbehebungen informiert';
  @override String get onboardNewsBadgeTitle => 'Neuigkeiten-Punkt';
  @override String get onboardNewsBadgeSub => 'Roter Punkt auf der Glocke, wenn es Neuigkeiten gibt';
  @override String get onboardHapticTitle => 'Haptisches Feedback';
  @override String get onboardHapticSub => 'Spüren Sie leichte Vibrationen bei wichtigen Interaktionen';
  @override String get onboardRecaps => 'Zusammenfassungen';
  @override String get onboardDailyRecapTitle => 'Tageszusammenfassung';
  @override String get onboardDailyRecapSub => 'Eine kurze Übersicht Ihres Höralltags';
  @override String get onboardWeeklyRecapTitle => 'Wochenzusammenfassung';
  @override String get onboardWeeklyRecapSub => 'Ihre Top-Künstler, Alben und Titel der Woche';
  @override String get onboardMilestonesSection => 'Scrobble-Meilensteine';
  @override String get onboardMilestonesTitle => 'Meilensteine';
  @override String get onboardMilestonesSub => 'Feiern Sie runde Scrobble-Zahlen';
  @override String get onboardGrandMilestonesTitle => 'Große Meilensteine';
  @override String get onboardGrandMilestonesSub => 'Extra-Feier bei großen Meilensteinen';
  @override String get onboardDynamicColorSub => 'Farben aus Ihrem Hintergrundbild verwenden (Android 12+)';
  @override String get onboardBetaTitle => 'Beta-Updates';
  @override String get onboardBetaSub => 'Früher Zugriff auf Vorabversionen';
  @override String get notifDetailTitle => 'Benachrichtigung';
  @override String get notifDetailOpenLink => 'Link öffnen';
  @override String get settingsCheckingUpdates => 'Suche nach Updates…';
  @override String get settingsTapToDownload => 'Zum Herunterladen tippen';
  @override String get detailLookingForPreview => 'Suche nach einer Vorschau…';
  @override String get detailPreview30Sec => 'Vorschau · 30 Sek.';
  @override String get setupTagline => 'Ihre Last.fm-Statistiken, neu erfunden.';
  @override String get setupAnalyseProfile => 'Ein Profil analysieren';
  @override String get setupConnecting => 'Verbindung wird hergestellt…';
  @override String get setupStartAnalysis => 'Analyse starten';
  @override String get setupOr => 'oder';
  @override String get setupUsernameLabel => 'Last.fm-Benutzername';
  @override String get setupApiKeyLabel => 'Last.fm-API-Schlüssel';
  @override String get setupApiKeyHint => '32-stelliger Hex-Schlüssel';
  @override String get setupApiKeyPrivacyNote => 'Wird lokal gespeichert. Wird niemals an Dritte gesendet.';
  @override String get setupRememberMe => 'Angemeldet bleiben';
  @override String get setupGetApiKey => 'Kostenlosen API-Schlüssel holen';
  @override String get setupWelcomeBanner => 'Willkommen bei LastStats!';
  @override String get setupOneTimeImportNote => 'Einmaliger Import, künftige Starts sind sofort.';
  @override String get dashTapToDownload => 'Zum Herunterladen tippen.';
  @override String get dashWeekLabel => 'DIESE WOCHE';
  @override String get dashMonthLabel => 'DIESER MONAT';
  @override String get dashYearLabel => 'DIESES JAHR';
  @override String get dashTopArtistLabel => 'Top-Künstler';
  @override String get dashTopTrackLabel => 'Top-Titel';
  @override String get dashScrobblesLabel => 'Scrobbles';
  @override String get newsTypeFeatures => 'Funktionen';
  @override String get newsTypeFixes => 'Fehlerbehebungen';
  @override String get newsTypeUpdates => 'Updates';
  @override String get newsTypeAlerts => 'Hinweise';
  @override String get newsTypeInfo => 'Info';
  @override String get newsWhatsNew => 'Neuigkeiten';
  @override String get newsFilters => 'Filter';
  @override String get newsAll => 'Alle';
  @override String get newsAnyDate => 'Beliebiges Datum';
  @override String get newsNoNewsYet => 'Noch keine Neuigkeiten';
  @override String get settingsNotifications => 'Benachrichtigungen';
  @override String get settingsCache => 'Cache';
  @override String get settingsCardAppearanceSub => 'Design, Akzent, Layout, Material You';
  @override String get settingsCardDashboardSub => 'Kopfbild, sichtbare Bereiche, Statistikkarten';
  @override String get settingsCardStartupSub => 'Tab beim App-Start';
  @override String get settingsCardNotificationsSub => 'Meilensteine, tägliche & wöchentliche Zusammenfassungen';
  @override String get settingsSync => 'Synchronisierung';
  @override String get settingsCardSyncSub => 'Automatische Scrobble-Synchronisierung im Hintergrund';
  @override String get settingsCardAccountSub => 'Verbundenes Last.fm-Profil, Abmeldung';
  @override String get settingsCardCacheSub => 'Verlauf, Bilder, API-Daten';
  @override String get settingsCardBackupSub => 'Einstellungen exportieren & wiederherstellen';
  @override String get settingsCardUpdatesSub => 'Nach neuen Versionen suchen';
  @override String get settingsCardAboutSub => 'Version, Quellcode, Credits';
  @override String get settingsCardFaqSub => 'Scrobbling, Plattformen, Open Source';
  @override String get settingsRestartNotice => 'Manche Einstellungen erfordern einen Neustart der App, um vollständig wirksam zu werden.';
  @override String get syncPageTitle => 'Scrobble-Synchronisierung';
  @override String get syncAutoTitle => 'Automatische Synchronisierung';
  @override String get syncAutoSubtitle => 'Synchronisiert Ihren Verlauf regelmäßig im Hintergrund';
  @override String get syncFrequencyLabel => 'Häufigkeit';
  @override String get syncFrequencyDaily => 'Einmal täglich';
  @override String get syncManualTitle => 'Manuelle Synchronisierung';
  @override String get syncNowButton => 'Jetzt synchronisieren';
  @override String get syncInProgress => 'Synchronisiere…';
  @override String get syncLastSyncLabel => 'Letzte Synchronisierung';
  @override String get syncNeverLabel => 'Nie';
  @override String get syncTotalScrobblesLabel => 'Zwischengespeicherte Scrobbles';
  @override String get syncUpToDateMsg => 'Verlauf ist aktuell';
  @override String get syncNotifNote => 'Während einer vollständigen Synchronisierung erscheint eine Fortschrittsbenachrichtigung.';
  @override String get pcModeLayout => 'Layout';
  @override String get pcModeNavLayout => 'Navigationslayout';
  @override String get pcModeAuto => 'Automatisch';
  @override String get pcModeSideRail => 'Seitenleiste';
  @override String get pcModeBottomBar => 'Untere Leiste';
  @override String get pcModeHintAuto => 'Seitenleiste auf breiten Bildschirmen (≥ 720 dp), untere Leiste auf schmalen Bildschirmen.';
  @override String get pcModeHintOn => 'Immer die seitliche Navigationsleiste verwenden, unabhängig von der Bildschirmgröße.';
  @override String get pcModeHintOff => 'Immer die untere Navigationsleiste verwenden, unabhängig von der Bildschirmgröße.';
  @override String get aboutTagline => 'Ihr Last.fm-Statistik-Begleiter';
  @override String get aboutAppInfo => 'App-Info';
  @override String get aboutScrobbleDownloader => 'Scrobble-Downloader';
  @override String get aboutScrobbleDownloaderSub => 'Exportiert alle Ihre Scrobbles in eine Datei';
  @override String get aboutPoweredBy => 'Unterstützt von';
  @override String get aboutImageDisclaimer => 'Bilder von Künstlern, Alben und Titeln werden automatisch aus diesen Quellen abgerufen und können gelegentlich falsch sein oder nicht zum tatsächlichen Inhalt passen.';
  @override String get aboutFooter => 'Mit ❤️ gemacht · Nicht mit Last.fm / CBS verbunden';
  @override String get updatesCurrentVersion => 'Aktuelle Version';
  @override String get updatesBetaTitle => 'Beta-Updates';
  @override String get updatesBetaSub => 'Früherer Zugriff auf Vorabversionen';
  @override String get backupWhatsIncluded => 'Was ist enthalten';
  @override String get backupDownloadFile => 'Lädt eine .json-Datei herunter';
  @override String get backupChooseFile => 'Sicherungsdatei auswählen';
  @override String get backupFileSaved => 'Sicherung gespeichert';
  @override String get backupFileSaveFailed => 'Datei konnte nicht gespeichert werden';
  @override String get setupRestoreBackup => 'Sicherung wiederherstellen';
  @override String get setupRestoreBackupSub => 'Stellt Ihr Konto und Ihre Einstellungen aus einer .json-Sicherungsdatei wieder her';
  @override String get backupRestoreKeysTitle => 'API-Schlüssel wiederherstellen';
  @override String get backupRestoreKeysDesc => 'Wählen Sie, welche Last.fm-Schlüssel aus dieser Sicherung wiederhergestellt werden sollen.';
  @override String get backupRestoreApiKeyLabel => 'API-Schlüssel';
  @override String get backupRestoreSecretKeyLabel => 'Geheimer Schlüssel';
  @override String get backupIncludeFoldersLabel => 'Ordner einschließen';
  @override String get backupIncludeFoldersDesc => 'Enthält Ihre Titelordner und deren Inhalt.';
  @override String get backupIncludeKeysDesc => 'Schlüssel in die exportierte Datei einbeziehen';

  @override String get backupIncludeThemesLabel => 'Designs exportieren';
  @override String get backupIncludeThemesDesc => 'Damit können Sie nur das Aussehen (Farben, Stil) mit jemandem teilen.';

  @override String get backupAutoTitle => 'Automatische Sicherung';
  @override String get backupAutoEnableLabel => 'Automatische Sicherung aktivieren';
  @override String get backupAutoEnableDesc => 'Erstellt selbstständig eine Sicherung, im unten gewählten Intervall.';
  @override String get backupAutoFreqLabel => 'Häufigkeit';
  @override String get backupAutoFreqDaily => 'Täglich';
  @override String get backupAutoFreqWeekly => 'Wöchentlich';
  @override String get backupAutoFreqMonthly => 'Monatlich';
  @override String get backupAutoFreqYearly => 'Jährlich';
  @override String get backupAutoFolderLabel => 'Sicherungsordner';
  @override String get backupAutoFolderDefault => 'Standardordner der App';
  @override String backupAutoNextLabel(String date) => 'Nächste Sicherung: $date';  @override String get backupIncludeScrobblesLabel => 'Gesamten Verlauf einschließen';
  @override String get backupIncludeScrobblesDesc => 'Fügt alle jemals gehörten Titel hinzu (kann groß sein).';

  @override String get backupScrobblesSlowWarning => 'Das kann eine Weile dauern und ist langsamer als eine normale Sicherung.';  @override String backupExportedOn(String date) => 'Sicherung vom $date';
  @override String get backupScrobblesErrorTitle => 'Fehler im Verlauf';
  @override String get backupScrobblesErrorDesc => 'Einige Jahre im Verlauf scheinen in dieser Datei beschädigt zu sein. Was möchten Sie tun?';
  @override String get backupScrobblesKeepAnyway => 'Trotzdem fortfahren';
  @override String get backupScrobblesCancel => 'Verlauf verwerfen';
  @override String get backupScrobblesSkipRefetch => 'Überspringen und online neu laden';  @override String get settingsCrashLog => 'Fehlerprotokoll';
  @override String get backupCrashLogDesc => 'Zeichnet App-Fehler auf, nützlich zum Melden eines Bugs.';
  @override String get backupCrashLogShare => 'Protokoll teilen';
  @override String get backupCrashLogClear => 'Protokoll leeren';
  @override String get backupCrashLogEmpty => 'Keine Fehler aufgezeichnet';
  @override String get backupCrashLogCleared => 'Protokoll geleert';
  @override String get backupCrashLogClearConfirm => 'Fehlerprotokoll leeren?';
  @override String get faqSectionLabel => 'Häufig gestellte Fragen';
  @override String get backupOverwriteWarning => 'Das Wiederherstellen einer Sicherung überschreibt Ihre aktuellen Einstellungen.';
  @override String get faqOpenSourceBadge => 'LastStats ist ein kostenloses Open-Source-Projekt, mit ❤️ erstellt von SanoBld.';
  @override String get cacheUnlimited => 'Unbegrenzt';
  @override String get cacheTotalUsed => 'Gesamt belegt';
  @override String get cacheScrobblesShort => 'Scrobbles';
  @override String get restartHintFeatures => 'Manche Funktionen erfordern möglicherweise einen Neustart der App, um wirksam zu werden.';
  @override String get reorderCardsTitle => 'Karten neu anordnen';
  @override String get commonSave => 'Speichern';
  @override String get dashFallbackWhenNoMusic => 'Wenn keine Musik läuft';
  @override String get dashFallbackChooseDisplay => 'Wählen Sie, was stattdessen als Hintergrund angezeigt wird';
  @override String get dashFallbackPeriodLabel => 'Ersatzzeitraum';
  @override String get fallbackPeriod1Week => '1 Woche';
  @override String get fallbackPeriod1Month => '1 Monat';
  @override String get fallbackPeriodAllTime => 'Gesamt';
  @override String get fallbackTypeNothing => 'Nichts';
  @override String get fallbackTypeTopTrack => 'Top-Titel';
  @override String get fallbackTypeTopAlbum => 'Top-Album';
  @override String get fallbackTypeTopArtist => 'Top-Künstler';
  @override String get fallbackTypeCustomImage => 'Eigenes Bild';
  @override String get fallbackWillShowCustomUrl => 'Wird angezeigt: eigene Bild-URL';
  @override String get dashAnimationBlurSection => 'Animation & Weichzeichnung';
  @override String get dashMusicAnimationTitle => 'Musikanimation';
  @override String get dashMusicAnimationSub => 'Während Musik läuft, verschwimmt und bewegt sich das Kopfbild sanft, wie bei Apple Music.';
  @override String get dashMusicAnimationInfo => 'Die Weichzeichnung wird in diesem Modus automatisch eingestellt. Der obige Regler hat keine Wirkung, während Musik läuft.';
  @override String get settingsTopAlbumsSection => 'Top-Alben';
  @override String get dashRecentPlaysLabel => 'Letzte Wiedergaben';
  @override String get dashStatCardsSectionLabel => 'Statistikkarten';
  @override String get dashStatCardsHeading => 'Statistikkarten';
  @override String get dashStatCardsSub => 'Wählen und ordnen Sie die im Statistikblock angezeigten Karten.';
  @override String get settingsDashboardChartSection => 'Dashboard-Diagramm';
  @override String get dashChartCalendarLabel => 'Hörkalender';
  @override String get dashChartMonthlyLabel => 'Monatsbalken';
  @override String get settingsDisplayNameSection => 'Eigener Name';
  @override String get settingsDisplayNameLabel => 'Wie sollen wir Sie nennen?';
  @override String get settingsDisplayNameHint => 'Z. B. Sano Bld — leer lassen, um den Kontonamen zu verwenden';
  @override String get newsSearchHint => 'News durchsuchen…';
  @override String get aboutOpenSourceLibs => 'Open-Source-Bibliotheken';
  @override String get aboutOpenSourceLibsSub => 'Alle Flutter-Pakete, die für diese App verwendet wurden.';
  @override String get aboutLicenseSection => 'Lizenz';
  @override String get aboutLicenseText => 'Dieses Projekt steht unter der MIT-Lizenz: Sie dürfen es frei nutzen, verändern, duplizieren oder weiterverbreiten, nennen Sie einfach meinen Namen.';
  @override String get aboutLicenseLink => 'Vollständige Lizenz ansehen';
  @override String get languageAiNote => 'Die Übersetzungen wurden von KI erstellt und können Ungenauigkeiten enthalten.';
  @override String get aboutAiDevNote => 'KI wurde auch bei der Entwicklung dieser App eingesetzt.';
  @override String get notifWorkManagerInfo => 'Benachrichtigungen laufen über WorkManager im Hintergrund. Die App muss nicht geöffnet sein. Eine Internetverbindung ist erforderlich.';
  @override String get notifIntervalTitle => 'Alle X Scrobbles';
  @override String get notifIntervalSubtitle => 'In regelmäßigen Abständen benachrichtigt werden';
  @override String get notifRecapsSection => 'Hörzusammenfassungen';
  @override String get notifDailyRecapSubtitle => 'Anzahl Scrobbles + Lieblingskünstler des Tages';
  @override String get notifWeeklyRecapSubtitle => 'Anzahl Scrobbles + Lieblingskünstler der Woche';
  @override String get notifNewsSection => 'Neuigkeiten';
  @override String get notifSyncSection => 'Synchronisierung';
  @override String get notifSyncTitle => 'Synchronisierungsbenachrichtigungen';
  @override String get notifSyncSubtitle => 'Benachrichtigt, wenn eine Verlaufssynchronisierung abgeschlossen ist';
  @override String get notifSyncDetailTitle => 'Fortschrittsdetail';
  @override String get notifSyncDetailSubtitle => 'Live-Fortschritt (aktuelles Jahr, Zähler) während der Synchronisierung anzeigen';
  @override String get notifNewsSubtitle => 'Benachrichtigt über neue Funktionen, Fehlerbehebungen und Ankündigungen';
  @override String get notifBadgeOnDashboard => 'Abzeichen auf der Übersicht';
  @override String get notifBadgeSubtitle => 'Zeigt den ungelesen-Punkt am Neuigkeiten-Glockensymbol';
  @override String get notifTestLabel => 'Test';
  @override String get notifPermissionDisabledTitle => 'Benachrichtigungen deaktiviert';
  @override String get notifPermissionDisabledBody => 'Erteilen Sie die Berechtigung, damit LastStats Ihnen Hinweise senden kann.';
  @override String get notifGrantPermission => 'Berechtigung erteilen';
  @override String get notifThresholdIntro => 'Sie erhalten bei jedem dieser Meilensteine eine besondere Benachrichtigung:';
  @override String get notifIntervalDescription => 'Alle X Scrobbles eine Benachrichtigung auslösen';
  @override String get notifCustomValueLabel => 'Eigener Wert';
  @override String get notifTimeNotifyAt => 'Benachrichtigen um';
  @override String get notifDayOfWeek => 'Wochentag';
  @override String get notifSendTest => 'Testbenachrichtigung senden';
  @override String get notifSentCheckBar => 'Schauen Sie in Ihre Benachrichtigungsleiste!';
  @override String get notifMakeSureWorks => 'Stellen Sie sicher, dass alles funktioniert.';
  @override String get notifSentBang => 'Gesendet!';
  @override String get notifSendButton => 'Senden';
  @override String get apVisualStyle => 'Visueller Stil';
  @override String get apStyleDefault => 'Standard';
  @override String get apNothingAccentLabel => 'Akzent';
  @override String get apNothingClassic => 'Klassisch';
  @override String get apRedOnlyDesc => 'Nur Rot';
  @override String get apNothingMixed => 'Gemischt';
  @override String get apRedYellowDesc => 'Rot + gelbe Akzente';
  @override String get apNothingActiveBanner => 'Nothing-OS-Stil aktiv. Akzent, dynamische Farbe und Musikfarbe sind deaktiviert.';
  @override String get apNothingOledInherent => 'Der Nothing-Dunkelmodus ist von Natur aus OLED-Schwarz. Der OLED-Schalter ist nicht nötig.';
  @override String get apOledTitle => 'OLED-Schwarz-Design';
  @override String get apOledBuiltIntoNothing => 'Im Nothing-Dunkelmodus integriert';
  @override String get apOledPureBlack => 'Reines Schwarz im Hintergrund, wenn der Dunkelmodus aktiv ist';
  @override String get apCustomColorTooltip => 'Benutzerdefinierte Farbe';
  @override String get apColorWhenNothingPlays => 'Farbe, wenn nichts läuft';
  @override String get apColorWhenNothingPlaysSub => 'Akzent, solange kein Titel gescrobbelt wird';
  @override String get apKeepLastArtworkTitle => 'Letzte Coverfarbe beibehalten';
  @override String get apKeepLastArtworkSub => 'Letzte Coverfarbe beibehalten, statt zurückzusetzen, wenn nichts läuft';
  @override String get apDetailPagesSection => 'Detailseiten';
  @override String get apArtworkColorTheme => 'Cover-Farbdesign';
  @override String get apBeta => 'BETA';
  @override String get apArtworkColorThemeSub => 'Detailseiten passen ihre Farben an die dominante Farbe des Covers an';
  @override String get apNavBarSection => 'Navigationsleiste';
  @override String get apShowTabLabels => 'Tab-Beschriftungen anzeigen';
  @override String get apShowTabLabelsSub => 'Tab-Namen unter den Symbolen in der unteren Leiste anzeigen';
  @override String get apInteractionsSection => 'Interaktionen';
  @override String get apHapticFeedbackSub => 'Vibrationen bei Tipps, Auswahlen und Gesten';
  @override String get acctRemoveTitle => 'Konto entfernen?';
  @override String get acctRemoveAction => 'Entfernen';
  @override String get acctAlreadyAddedOrFull => 'Dieses Konto ist bereits hinzugefügt oder die Liste ist voll.';
  @override String get acctLogoutAllBody => 'Alle Konten werden entfernt. Sie gelangen zurück zum Einrichtungsbildschirm.';
  @override String get acctActive => 'Aktiv';
  @override String get acctTapSwitchToActivate => 'Zum Aktivieren auf „Wechseln“ tippen';
  @override String get acctSwitch => 'Wechseln';
  @override String get acctAddAnAccount => 'Konto hinzufügen';
  @override String get acctApiKeyInfo => 'Jedes Konto kann einen anderen oder denselben API-Schlüssel verwenden. Sie finden Ihren API-Schlüssel unter last.fm/api/accounts.';
  @override String get acctLastfmProfileSection => 'Last.fm-Profil';
  @override String get acctViewOnLastfm => 'Auf Last.fm ansehen';
  @override String get acctDangerZone => 'Gefahrenzone';
  @override String get acctLogoutAllSub => 'Alle Konten entfernen und zurück zum Einrichtungsbildschirm.';
  @override String get acctUsernameRequired => 'Benutzername ist erforderlich.';
  @override String get acctApiKeyRequired => 'API-Schlüssel ist erforderlich.';
  @override String get acctUsernameLabel => 'Last.fm-Benutzername';
  @override String get acctSameApiKey => 'Gleicher API-Schlüssel wie das aktive Konto';
  @override String get acctApiKeyLabel => 'API-Schlüssel';
  @override String get acctAdd => 'Hinzufügen';
  @override String get languageChangeNote => 'Die Sprache ändert sich sofort in der gesamten App.';
  @override String get dashTotalScrobblesLabel => 'Scrobbles insgesamt';
  @override String get dashMemberSinceLabel => 'Mitglied seit';
  @override String get dashCountryLabel => 'Land';
  @override String get dashArtistWeekLabel => 'Künstler Nr. 1 (Woche)';
  @override String get dashAlbumWeekLabel => 'Album Nr. 1 (Woche)';
  @override String get dashTrackWeekLabel => 'Titel Nr. 1 (Woche)';
  @override String get dashUniqueArtistsLabel => 'Einzigartige Künstler';
  @override String get dashUniqueTracksLabel => 'Einzigartige Titel';
  @override String get dashUniqueAlbumsLabel => 'Einzigartige Alben';
  @override String get dashThisWeekLabel => 'Diese Woche';
  @override String get dashDayUnitShort => 'T';
  @override String get setupEnableFavorites      => 'Favoriten aktivieren (optional)';
  @override String get setupFavoritesExplain     => 'Mit Ihrem geheimen Schlüssel kann die App Titel direkt auf Last.fm favorisieren (oder entfernen).';
  @override String get setupSecretKeyLabel       => 'Last.fm Secret Key';
  @override String get favConnectInvalidSecret   => 'Der geheime Schlüssel muss 32 Zeichen lang sein.';
  @override String get favConnectDialogTitle     => 'Favoriten autorisieren';
  @override String get favConnectDialogBody      => 'Autorisieren Sie die App auf der im Browser geöffneten Last.fm-Seite und kehren Sie dann hierher zurück, um zu bestätigen.';
  @override String get favConnectDialogConfirm   => 'Ich habe autorisiert';
  @override String get favConnectSuccess         => 'Favoriten erfolgreich aktiviert!';
  @override String get favConnectError           => 'Favoriten konnten nicht aktiviert werden. Prüfen Sie Ihren geheimen Schlüssel.';
  @override String get acctApiKeysSection        => 'API-Schlüssel';
  @override String get acctSecretKeyLabel        => 'Geheimer Schlüssel';
  @override String get acctSecretKeyNotSet       => 'Nicht festgelegt';
  @override String get acctFavoritesExplain      => 'Der geheime Schlüssel erlaubt es, Titel direkt auf Last.fm zu favorisieren (oder zu entfernen).';
  @override String get acctConnectFavorites      => 'Favoriten aktivieren';
  @override String get acctDisconnectFavorites   => 'Favoriten deaktivieren';
  @override String get settingsFavoritesSection    => 'Favoriten';
  @override String get settingsFavoritesSectionSub => 'Zeigt die Anzahl Ihrer Favoriten in der Statistik';
  @override String get settingsFavoritesNeedsKey   => 'Fügen Sie Ihren geheimen Schlüssel im Konto hinzu, um zu aktivieren';
  @override String get favSectionTitle           => 'Favoriten';
  @override String get commonSeeMore             => 'Mehr anzeigen';
  @override String get favPageTitle              => 'Meine Favoriten';
  @override String get favSearchHint             => 'Titel oder Künstler suchen';
  @override String get favEmpty                  => 'Noch keine Favoriten.';
  @override String get settingsLovedBadgeTitle => 'Dezentes Herz-Symbol';
  @override String get settingsLovedBadgeSub   => 'Zeigt ein kleines Herz bei favorisierten Titeln in zuletzt gehört, Verlauf und Suche';
  @override String get favSortRecent   => 'Neueste';
  @override String get favSortOldest   => 'Älteste';
  @override String get favSortArtistAz => 'Künstler A-Z';
  @override String get favSortTitleAz  => 'Titel A-Z';
  @override String get favFolderSortCustom => 'Manuell';
  @override String get favFoldersAll => 'Alle';
  @override String get favFolderNew => 'Neuer Ordner';
  @override String get favFolderNamePlaceholder => 'Ordnername';
  @override String get favFolderCustomEmojiTitle => 'Emoji auswählen';
  @override String get favFolderCustomEmojiHelper => 'Nur ein Emoji, kein Text.';
  @override String get favFolderDescPlaceholder => 'Beschreibung (optional)';
  @override String get favFolderRecentlyPlayed => 'Kürzlich gehört';
  @override String get favFolderCreate => 'Erstellen';
  @override String get favFolderEdit => 'Ordner bearbeiten';
  @override String get favFolderDelete => 'Löschen';
  @override String get favFolderDeleteConfirm => 'Diesen Ordner löschen? Titel werden nicht mehr darin einsortiert.';
  @override String get favFolderAssignTitle => 'Zu einem Ordner hinzufügen';
  @override String get favFolderEmoji => 'Emoji';
  @override String get favFolderColor => 'Farbe';
  @override String get favFolderSave => 'Speichern';
  @override String get favFolderEmpty => 'Keine Titel in diesem Ordner';
  @override String get rankingsWholeYear       => 'Ganzes Jahr';
  @override String get chartsExportGeneratedOn => 'erstellt am';
  @override String get faqQ1 => 'Scrobbelt LastStats meine Musik?';
  @override String get faqA1 => 'Nein. LastStats ist eine Visualisierungs-App: Sie zeigt die bereits auf Ihrem Last.fm-Konto gespeicherten Scrobbles an, zeichnet aber selbst keine auf.\n\nUm Ihre Musik automatisch zu scrobbeln, nutzen Sie eine dedizierte App wie Pano Scrobbler (verfügbar für Android).';
  @override String get faqQ3 => 'Funktioniert die App unter macOS oder anderen Plattformen?';
  @override String get faqA3 => 'LastStats wird auf Android entwickelt und getestet. Das Verhalten auf anderen Plattformen (macOS, Windows, Linux…) ist nicht überprüft, Fehler oder unerwartetes Verhalten sind möglich.';
  @override String get faqQ4 => 'Ist LastStats Open Source?';
  @override String get faqA4 => 'Ja! Der Quellcode ist frei auf GitHub verfügbar. Das Projekt ist unabhängig und wird mit Leidenschaft von SanoBld entwickelt. Sie können gerne beitragen, Fehler melden oder einfach einen Stern ⭐ dalassen.';
  @override String get faqQ5 => 'Wo werden meine Daten gespeichert?';
  @override String get faqA5 => 'Nur auf Ihrem Gerät. LastStats hat keinen Server: Ihre Scrobbles werden lokal zwischengespeichert, und auch Ihre Last.fm-Zugangsdaten bleiben lokal gespeichert. Es wird nichts irgendwohin gesendet außer an die offizielle Last.fm-API.';
  @override String get faqQ6 => 'Wie aktiviere ich Favoriten?';
  @override String get faqA6 => 'Gehen Sie zu Einstellungen > Konto und geben Sie Ihren Last.fm-Secret-Key ein (Sie finden ihn neben Ihrem API-Schlüssel unter last.fm/api/accounts). Folgen Sie dann den Schritten auf dem Bildschirm. Nach der Verbindung können Sie Titel direkt in der App favorisieren. Mit dem internen Schlüssel der App ist das nicht möglich.';
  @override String get faqQ7 => 'Was ist ein \'Scrobble\'?';
  @override String get faqA7 => 'Ein Scrobble ist ein Titel, der als geh\u00f6rt auf Ihrem Last.fm-Konto erfasst wird \u2014 das ist Last.fms eigener Begriff f\u00fcr \'ein gez\u00e4hltes Abspielen\'. Alle Ihre Gesamtwerte (Top-Interpreten, Statistiken usw.) basieren darauf.';
  @override String get faqQ8 => 'Wie funktionieren Level und Erfolge?';
  @override String get faqA8 => 'Ihr Kontolevel steigt mit Ihrer Gesamtzahl an Scrobbles (es gibt kein H\u00f6chstlevel). Karten erhalten au\u00dferdem einen Rahmen (Bronze \u2192 schillernd), je nachdem wie oft der jeweilige Interpret/Titel/das Album gespielt wurde. Alles wird automatisch aus bereits lokal zwischengespeicherten Statistiken berechnet, ohne zus\u00e4tzliche Netzwerkaufrufe.';
  @override String get faqQ9 => 'Wie funktioniert der Energiesparmodus?';
  @override String get faqA9 => 'Der Energiesparmodus verlängert die Abstände zwischen automatischen Synchronisierungen, um Akku zu sparen. Er kann dauerhaft an sein, dem Energiesparmodus Ihres Telefons folgen oder sich unter einem gewählten Akkustand einschalten, unter Einstellungen > Allgemein.';
  @override String get faqQ10 => 'Wie sichere oder stelle ich meine Daten wieder her?';
  @override String get faqA10 => 'Gehen Sie zu Einstellungen > Sicherung. Sie können eine Sicherungsdatei exportieren, wahlweise mit oder ohne Ihren Last.fm-Schlüssel, und sie später auf diesem Telefon oder einem anderen Gerät wieder importieren, um Ihre Einstellungen zurückzuholen.';
  @override String get faqQ11 => 'Funktioniert die App offline?';
  @override String get faqA11 => 'Ja, bis zu einem gewissen Grad. Bereits geladene Statistiken bleiben dank lokalem Cache offline verfügbar, für neue Scrobbles ist aber eine Verbindung nötig.';
  @override String get faqQ12 => 'Kann ich das Last.fm-Konto wechseln?';
  @override String get faqA12 => 'Ja, Sie können bis zu 3 Last.fm-Konten speichern. Tippen Sie unter Einstellungen > Konto auf „Konto hinzufügen“ und wechseln Sie danach jederzeit zwischen den Konten. Beim Wechsel wird der lokale Cache automatisch zurückgesetzt, damit sich die Daten zweier Konten nie vermischen.';
  @override String get faqQ13 => 'Wie richte ich Benachrichtigungen ein?';
  @override String get faqA13 => 'Unter Einstellungen > Benachrichtigungen können Sie einen Hinweis aktivieren, sobald eine Synchronisierung abgeschlossen ist, die Häufigkeit der Hinweise festlegen oder die Benachrichtigungen ganz ausschalten.';
  @override String get faqQ14 => 'Cover fehlen oder laden endlos. Was tun?';
  @override String get faqA14 => 'Leere den Cache in der App (Einstellungen > Cache) und dann in Android (Einstellungen > Apps > LastStats > Speicher > Cache leeren). Fehlen die Bilder weiterhin, sichere deine Daten (Einstellungen > Sicherung), deinstalliere die App, installiere sie neu und stelle die Sicherung wieder her.';
  @override String get settingsPlatformDisabledByShowAll => 'Deaktiviert: Es werden bereits alle Links angezeigt.';
  @override String get commonInDevelopment => 'In Entwicklung';
  @override String get commonSeeLess => 'Weniger anzeigen';
  @override String get commonShare => 'Teilen';
  @override String get newsCustomDate => 'Eigener Zeitraum';
  @override String get aboutShortcuts => 'Tastenkürzel';
  @override String get aboutShortcutsSub => 'Verfügbar auf dem PC / großen Bildschirmen';
  @override String get shortcutSwitchTabs => 'Tab wechseln';
  @override String get shortcutSearch => 'Suchen';
  @override String get shortcutClose => 'Ansicht schließen';
  @override String get shortcutRefresh => 'Aktualisieren';
  @override String get aboutDiscord => 'Discord beitreten';
  @override String get aboutDiscordSub => 'Austausch, Vorschläge und Live-Ankündigungen';

  @override String globalListeners(String count) => '$count Hörer weltweit';
  @override String historyScrobbles(int n) => '$n Scrobbles';
  @override String historyArtistsCount(int n) => '$n Künstler';
  @override String historyAlbumsCount(int n) => '$n Alben';
  @override List<String> get months => const ['', 'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  @override String dayLabel(DateTime d) {
    const days = ['Montag','Dienstag','Mittwoch','Donnerstag','Freitag','Samstag','Sonntag'];
    const months = ['','Januar','Februar','März','April','Mai','Juni','Juli','August','September','Oktober','November','Dezember'];
    return '${days[d.weekday - 1]}, ${d.day}. ${months[d.month]} ${d.year}';
  }
  @override String memberSince(String date) => 'Mitglied seit $date';
  @override String settingsUpdateAvailable(String v) => 'v$v verfügbar';
  @override String settingsUpdateBanner(String v) => 'Update v$v';
  @override String setupWelcome(String username) => 'Willkommen, $username!';
  @override String setupScrobblesToImport(String c) => '$c Scrobbles zu importieren';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      '${isBeta ? "Beta" : "Neues"}-Update: v$version';
  @override String newsItemsCount(int n) => '$n ${n > 1 ? "Einträge" : "Eintrag"}';
  @override String syncFrequencyHours(int h) => 'Alle $h Std.';
  @override String syncNewScrobblesFound(int n) => n == 0 ? 'Keine neuen Scrobbles' : '$n neue(r) Scrobble(s) gefunden';
  @override String updatesPublishedOn(String date) => 'Veröffentlicht am $date';
  @override String fallbackWillShow(String detail) => 'Wird angezeigt: $detail';
  @override String acctRemoveBody(String username) => '@$username aus Ihren Konten entfernen?';
  @override String acctAddedSuccess(String username) => '@$username erfolgreich hinzugefügt.';
  @override String acctMyAccounts(int count, int max) => 'Meine Konten ($count/$max)';
  @override String acctSlotsRemaining(int n) => '$n Platz/Plätze übrig';
  @override String acctMaxReached(int max) => 'Maximum von $max Konten erreicht.';
  @override List<String> get weekdaysShort => const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  @override List<String> get weekdaysNarrow => const ['M', 'D', 'M', 'D', 'F', 'S', 'S'];
  @override String get weekAbbrev => 'W';
  @override List<String> get notifThresholdMessages => const [
    'Ihre ersten 1.000 Scrobbles. Die Reise beginnt. 🎵',
    'Sie haben fünfstellig geknackt! 🎉',
    'Sie sind ein echter Musikfan. 🔥',
    'Eine Million Scrobbles. Das ist legendär. 🎸',
  ];
  @override String get achvTitle => 'Erfolge';
  @override String achvUnlocked(int unlocked, int total) => '$unlocked / $total freigeschaltet';
  @override String get achvCatListening => 'Hören';
  @override String get achvCatArtists => 'Künstler';
  @override String get achvCatAlbums => 'Alben';
  @override String get achvCatLoyalty => 'Treue';
  @override String get achvDescListening => 'Gesamtzahl gescrobbelter Titel, über alle Künstler hinweg.';
  @override String get achvDescArtists => 'Anzahl verschiedener Künstler, die mindestens einmal gehört wurden.';
  @override String get achvDescAlbums => 'Anzahl verschiedener Alben, die mindestens einmal gehört wurden.';
  @override String get achvDescLoyalty => 'Wie lange das Last.fm-Konto schon besteht.';
  @override String get achvCatTracks => 'Titel';
  @override String get achvDescTracks => 'Anzahl verschiedener gehörter Titel.';
  @override String get achvCatPace => 'Tempo';
  @override String get achvDescPace => 'Durchschnittliche Scrobbles pro Woche.';
  @override String get achvCatStreak => 'Serie';
  @override String get achvDescStreak => 'Die längste Serie aufeinanderfolgender Tage mit mindestens einem Scrobble.';
  @override String get achvCatMarathon => 'Marathon';
  @override String get achvDescMarathon => 'Die meisten Scrobbles an einem einzigen Tag.';
  @override String get achvCatSocial => 'Sozial';
  @override String get achvDescSocial => 'Die Anzahl hinzugefügter Freunde oder Profile.';
  @override String get achvCatComparisons => 'Vergleiche';
  @override String get achvDescComparisons => 'Die Anzahl der durchgeführten Musikgeschmack-Vergleiche.';
  @override String get achvUnlockedBadge => 'Freigeschaltet';
  @override String get achvLockedBadge => 'Gesperrt';
  @override String get dashRecap => 'Rückblick';
  @override String get recapDay => 'Heute';
  @override String get recapWeek => 'Diese Woche';
  @override String get recapMonth => 'Diesen Monat';
  @override String get recapScrobbles => 'Scrobbles';
  @override String get recapArtists => 'Künstler';
  @override String get recapTracks => 'Titel';
  @override String get recapTopArtist => 'Top-Künstler';
  @override String get recapTopTrack => 'Top-Titel';
  @override String get recapTopAlbum => 'Top-Album';
  @override String get recapAvgDay => 'Ø/Tag';
  @override String get recapNoData => 'Noch keine Scrobbles in diesem Zeitraum.';
  @override String get recapSeeFull => 'Ganzen Rückblick ansehen';
  @override String get recapTop10 => 'Top 10';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => 'Nützlichster Filter zuerst';
  @override String get discoverSmartSub => 'Je nach Uhrzeit, Tag und Ihren Vorlieben';
  @override String get discoverForYou => 'Für Sie';
  @override String get discoverGlobalTrends => 'Globale Trends';
  @override String get discoverSrcForyou => 'Ihr Mix';
  @override String get discoverSrcOnthisday => 'An diesem Tag';
  @override String get discoverSrcFresh => 'Diesen Monat';
  @override String get discoverSrcGenre => 'Ihre Genres';
  @override String get discoverSrcDeeper => 'Deep Cuts';
  @override String get discoverSrcForgotten => 'Vergessen';
  @override String get discoverSrcAlbums => 'Alben';
  @override String get discoverSrcCountry => 'Ihr Land';
  @override String get discoverTracks => 'Titel';
  @override String get discoverArtists => 'Künstler';
  @override String get discoverWeek => 'Woche';
  @override String get discoverMonth => 'Monat';
  @override String get discoverYear => 'Jahr';
  @override String get discoverNothing => 'Noch nichts zu zeigen';
  @override String discoverLike(String names) => 'Wie $names';
  @override String get dashReorderSections => 'Reihenfolge der Bereiche ändern';
  @override String get dashInfiniteTitle => 'Endloses Scrollen';
  @override String get dashInfiniteSub => 'Entdecken läuft in Endlosschleife und schlägt immer mehr vor';
  @override String get dashDiscoverTitle => 'Entdecken';
  @override String get dashDiscoverSub => 'Musiktipps zum Durchwischen';
  @override String get dashSortButton => 'Sortieren';
  @override String get dashSortDone => 'Fertig';
  @override String get dashSortHint => 'Zum Umsortieren ziehen';
  @override String get dashSortSmartNote => 'Die intelligente Sortierung ist an und kann diese Reihenfolge je nach Moment ändern.';
  @override String get dashSeparateRow => 'In eigener Zeile';
  @override String dashFiltersOf(String group) => 'Filter für „$group“';
  @override String get apShapeSingle => 'Nur eine Form';
  @override String get mvSource => 'Videoquelle';
  @override String get mvSrcAuto => 'Auto (Apple Music, dann YouTube)';
  @override String get mvSrcApple => 'Nur Apple Music';
  @override String get mvSrcYt => 'Nur YouTube (Titel)';
  @override String get mvQualityT => 'Videoqualität';
  @override String get mvQAuto => 'Auto';
  @override String get mvQLow => 'Sparmodus (360p)';
  @override String get mvTypesT => 'Video anzeigen für';
  @override String get mvTracks => 'Titel';
  @override String get mvAlbums => 'Alben';
  @override String get mvArtists => 'Künstler';
  @override String get mvModeT => 'Modus';
  @override String get mvModeBest => 'Empfohlen';
  @override String get mvModeSaver => 'Sparmodus';
  @override String get mvModeMax => 'Höchste Qualität';
  @override String get mvModeCustom => 'Benutzerdefiniert';
  @override String get mvSrcYtFirst => 'YouTube, dann Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => 'Genutzte Dienste, Kontingente und Verbrauch';
  @override String get apiSumToday => 'Anfragen heute';
  @override String get apiSumErrors => 'Fehler';
  @override String get apiSumLimited => 'Begrenzt';
  @override String get apiIntro => 'Die Zähler gelten nur für dieses Gerät. Die Anbieter wenden ihre Limits pro IP-Adresse an, daher zählen auch andere Apps im selben Netzwerk. Die App drosselt oder überspringt Anfragen automatisch, um darunter zu bleiben.';
  @override String get apiCatListening => 'Hördaten';
  @override String get apiCatMetadata => 'Musik-Metadaten';
  @override String get apiCatArtwork => 'Cover';
  @override String get apiCatLyrics => 'Songtexte';
  @override String get apiCatTranslate => 'Übersetzung';
  @override String get apiCatUpdates => 'Updates & News';
  @override String get apiCatOther => 'Bild-Downloads';
  @override String get apiStatusIdle => 'Noch nicht genutzt';
  @override String get apiStatusOk => 'OK';
  @override String get apiStatusNear => 'Nahe am Limit';
  @override String get apiStatusPaused => 'Pausiert';
  @override String get apiProviderLimit => 'Limit des Anbieters';
  @override String get apiNoLimit => 'Keines veröffentlicht';
  @override String get apiAppCeiling => 'App-Obergrenze';
  @override String apiLimitPer(int n, String win) => '$n Anfragen / $win';
  @override String get apiWinSecond => 'Sekunde';
  @override String get apiWinMinute => 'Minute';
  @override String get apiWinHour => 'Stunde';
  @override String apiWinSeconds(int s) => '$s Sekunden';
  @override String get apiWindowUsage => 'Aktuelles Fenster';
  @override String get apiRemaining => 'Verbleibend';
  @override String apiResetsIn(String t) => 'Zurückgesetzt in $t';
  @override String apiPausedFor(String t) => 'Pausiert für $t nach einer Limit-Antwort';
  @override String get apiToday => 'Heute';
  @override String get apiLastHour => 'Letzte Stunde';
  @override String get apiTotal => 'Gesamt';
  @override String get apiRateLimited => 'Limit-Antworten';
  @override String get apiSkipped => 'Von der App übersprungen';
  @override String get apiLastCall => 'Letzter Aufruf';
  @override String get apiNever => 'Nie';
  @override String get apiNoKey => 'Kein API-Schlüssel nötig';
  @override String get apiSharedKey => 'Gemeinsamer öffentlicher Testschlüssel (kostenlos)';
  @override String get apiUnofficial => 'Inoffizieller Endpunkt: keine garantierte Quote, kann sich ohne Vorwarnung ändern oder gesperrt werden.';
  @override String get apiKeyInUse => 'Verwendeter Schlüssel';
  @override String get apiOwnKey => 'Dein eigener Last.fm-Schlüssel';
  @override String apiBuiltinKey(int n, int total) => 'Integrierter Schlüssel $n von $total';
  @override String get apiBackupOn => 'Ersatzschlüssel: an';
  @override String get apiBackupOff => 'Ersatzschlüssel: aus';
  @override String get apiPerKey => 'Anfragen pro Schlüssel (heute / gesamt)';
  @override String get apiLastfmNote => 'Last.fm nennt keine Zahl: Es antwortet mit Fehler 29, wenn eine IP zu viele Anfragen sendet, und die Bedingungen verbieten Umgehungen. Üblich sind etwa 5 Anfragen pro Sekunde pro IP; die App bleibt unter 4.';
  @override String get apiStorageTitle => 'Gespeicherte Last.fm-Daten';
  @override String apiStorageValue(String used, String cap) => '$used von $cap erlaubt';
  @override String get apiStorageOver => 'Über dem 100-MB-Limit der Last.fm-API-Bedingungen. Lösche den Scrobble-Verlauf unter Speicher, um die Bedingungen einzuhalten.';
  @override String get apiReset => 'Zähler zurücksetzen';
  @override String get apiLimiter => 'Anfragen begrenzen';
  @override String get apiLimiterSub => 'Bremst Anfragen, um unter den API-Limits zu bleiben. Aus = schneller, ohne Warten.';
  @override String get apiResetBody => 'Alle Anfragezähler werden auf null gesetzt.';
  @override String get apiResetDone => 'Zähler zurückgesetzt';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (de) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxDe = {
  'st_notif_on': 'Benachrichtigungen sind an',
  'st_notif_off': 'Benachrichtigungen sind aus',
  'st_notif_count': '{n} Typen aktiv',
  'st_notif_perm': 'Systemberechtigung erforderlich',
  'st_notif_none': 'Kein Benachrichtigungstyp gewählt',
  'st_sync_on': 'Automatische Synchronisierung ist an',
  'st_sync_off': 'Automatische Synchronisierung ist aus',
  'st_sync_on_s': 'Ihre Daten aktualisieren sich von selbst.',
  'st_sync_off_s': 'Daten werden nur auf Anfrage aktualisiert.',
  'st_bkp_on': 'Automatische Sicherung ist an',
  'st_bkp_off': 'Automatische Sicherung ist aus',
  'st_bkp_on_s': 'Ihre Einstellungen werden automatisch gesichert.',
  'st_bkp_off_s': 'Schalten Sie sie ein, damit nichts verloren geht.',
  'st_bkp_next': 'Nächste Sicherung: {d}',
  'cmp_breakdown': 'Was Sie verbindet',
  'cmp_by_artists': 'Künstler',
  'cmp_by_genres': 'Genres',
  'cmp_by_tracks': 'Titel',
  'cmp_by_albums': 'Alben',
  'eco_on': 'Energiesparen ist an',
  'eco_off': 'Energiesparen ist aus',
  'eco_why_manual': 'Dauerhaft an, von Ihnen eingestellt',
  'eco_why_system': 'Der Energiesparmodus Ihres Geräts ist an',
  'eco_why_battery': 'Akku bei {n} %',
  'eco_off_hint': 'Wählen Sie unten, wann er sich einschalten soll',
  'eco_trig': 'Wann einschalten',
  'eco_sys_t': 'Wenn der Energiesparmodus des Geräts an ist',
  'eco_sys_s': 'Folgt dem integrierten Energiesparmodus Ihres Telefons und schaltet sich mit ihm aus.',
  'eco_sys_na': 'Auf diesem Gerät nicht verfügbar.',
  'eco_chg': 'Was sich ändert',
  'eco_chg1': 'Der Neige-Parallax wird abgeschaltet',
  'eco_chg2': 'Die Bildwiederholrate wird auf etwa 60 Hz begrenzt',
  'eco_chg3': 'Hintergrundaktualisierungen laufen seltener',
  'eco_chg4': 'Animierte Cover und der Glanz der Abzeichen pausieren',
  'eco_chg_note': 'Alles andere bleibt in voller Qualität: Bilder, Exporte und Share-Karten.',
  'lib_section': 'Bibliothek',
  'lib_merge_t': 'Versionen desselben Titels verknüpfen',
  'lib_merge_s': 'Remaster, Singles, (feat. …) und Deluxe-Editionen zählen als ein Titel bzw. Album, die Wiedergaben werden addiert. Remixe, Live- und Instrumentalversionen bleiben getrennt.',
  'lib_split_t': 'Kollaborationen aufteilen',
  'lib_split_s': '„Gims & Damso“ zählt für Gims und für Damso, statt ein eigener Künstler zu sein. Bands wie „Simon & Garfunkel“ bleiben ganz.',
  'lib_step_t': 'Ihre Bibliothek',
  'lib_step_s': 'Wählen Sie, wie Ihre Wiedergaben gruppiert werden. Sie können das jederzeit in den Einstellungen ändern.',
  'bk_dash_t': 'Dashboard und Start',
  'bk_dash_s': 'Bereiche, Kopfbereich, Statistikkarten, Entdecken, Start-Tab',
  'bk_notif_t': 'Benachrichtigungen',
  'bk_notif_s': 'Rückblicke, Meilensteine, News und Abzeichen',
  'bk_lib_t': 'Bibliotheksoptionen',
  'bk_lib_s': 'Versionen verknüpfen, Kollaborationen aufteilen',
  'bk_prof_t': 'Lieblingsprofile',
  'bk_prof_s': 'Die Last.fm-Profile, die Sie markiert haben',
  'about_readme_t': 'README und Projektaktivität',
  'about_readme_s': 'README lesen, letzte Commits, Workflows, Version, Downloads',
  'fold_show': 'Anzeigen ({n})',
  'fold_hide': 'Einklappen',
  'readme_sub': 'Das Projekt und seine Aktivität',
  'readme_version': 'Version',
  'readme_downloads': 'Downloads',
  'readme_stars': 'Sterne',
  'readme_license': 'Lizenz',
  'readme_commits': 'Letzte Commits',
  'readme_workflows': 'Letzte Workflows',
  'readme_retry': 'Erneut versuchen',
  'readme_github': 'Auf GitHub öffnen',
  'readme_failed': 'Laden nicht möglich (offline oder GitHub-Limit erreicht).',
  'ago_min': 'vor {n} Min.',
  'ago_h': 'vor {n} Std.',
  'ago_d': 'vor {n} T.',
  'load_restored': '{n} Scrobbles wiederhergestellt',
  'load_ready': 'Bereit zum Import',
  'load_connecting': 'Verbindung zu Last.fm …',
  'load_done': 'Import abgeschlossen',
  'load_backup_note': 'Backup gefunden: Es werden nur neuere Scrobbles geprüft.',
  'dash_nowplay': 'Läuft gerade',
  'dash_stats': 'Statistiken',
  'dash_recent': 'Zuletzt gehört',
  'dash_discover': 'Entdecken',
  'dash_friends': 'Freunde',
  'dash_chart': 'Dashboard-Diagramm',
  'dash_calendar': 'Kalender',
  'dash_monthly': 'Monatlich',
  'cache_video_t': 'Animierte Cover (Apple Music)',
  'cache_video_s': 'Videospeicher in Nutzung: {mem} · {players} aktive(r) Player · {links} Link(s) im Cache',
  'cache_video_short': 'Animierte Cover',
  'cache_video_cleared': 'Videospeicher freigegeben',
  'cache_memory_section': 'Speicher',
  'cache_storage_section': 'Speicher',
  'lvl': 'Level {n}',
  'lvl_history': 'Levelverlauf',
  'set_living_t': 'Animierte Cover',
  'set_living_s': 'Sanfter Zoom und Tiefeneffekt auf Bildern',
  'set_motion_t': 'Video-Cover',
  'set_motion_s': 'Spielt das animierte Cover ab, wenn vorhanden',
  'set_achv_t': 'Erfolge und Level',
  'set_achv_s': 'Stufen, Abzeichen und Kontolevel',
  'cache_img_limit_t': 'Limit für Foto-Cache',
  'cache_img_limit_s': 'Cover, Künstlerfotos und Avatare. Die ältesten werden zuerst gelöscht.',
  'cache_vid_limit_t': 'Limit für Video-Cache',
  'cache_vid_limit_s': 'Animierte Apple-Music-Cover werden offline auf dem Gerät gespeichert (Android).',
  'cache_video_off': 'Aus',
  'cache_vid_disk_t': 'Apple-Music-Videos',
  'cache_vid_disk_s': '{size} · Gespeicherte animierte Cover',
  'cache_no_limit_note': 'Scrobbles und API-Daten werden nie begrenzt.',
  'key_internal_use': 'Interne App-Schlüssel verwenden',
  'key_internal_help': 'Notlösung: Dieser Schlüssel wird von mehreren Nutzern geteilt. Er kann an Grenzen stoßen oder ausfallen, dann funktionieren manche Funktionen nicht. Nutzen Sie nach Möglichkeit Ihren eigenen Schlüssel.',
  'key_internal_active': 'Interner App-Schlüssel',
  'key_fallback_title': 'Interner Schlüssel als Reserve',
  'key_fallback_sub': 'Zuerst wird Ihr eigener Schlüssel verwendet. Lehnt Last.fm ihn ab, versucht es die App automatisch mit dem internen Schlüssel erneut.',
  'key_use_own': 'Meinen eigenen API-Schlüssel verwenden',
  'key_change_title': 'API-Schlüssel ändern',
  'key_change_sub': 'Ersetzen Sie Ihren Schlüssel durch einen anderen oder wechseln Sie zum internen Schlüssel der App.',
  'key_change_sub_internal': 'Sie nutzen den gemeinsamen Schlüssel der App. Fügen Sie Ihren eigenen Schlüssel hinzu, damit Sie nicht mehr von den Grenzen anderer Nutzer abhängen.',
  'key_change_intro': 'Geben Sie einen neuen API-Schlüssel für dieses Konto ein oder kehren Sie zum internen Schlüssel der App zurück. Ihr Benutzername und Ihre Statistiken bleiben unverändert.',
  'key_change_intro_internal': 'Dieses Konto nutzt derzeit den internen Schlüssel der App. Fügen Sie unten Ihren eigenen Last.fm-API-Schlüssel ein, um ihn zu ersetzen. Ihr Benutzername und Ihre Statistiken bleiben unverändert.',
  'key_change_hint': 'Ein API-Schlüssel hat 32 Zeichen. Sie können Ihren unter last.fm/api/accounts erstellen oder dort finden.',
  'key_change_invalid_len': 'Ein API-Schlüssel muss genau 32 Zeichen lang sein. Prüfen Sie, ob Sie ihn vollständig kopiert haben.',
  'key_change_same': 'Dieses Konto verwendet diesen Schlüssel bereits. Geben Sie einen anderen ein.',
  'key_change_check_failed': 'Last.fm hat diesen Schlüssel nicht akzeptiert. Prüfen Sie, ob er stimmt und ob Sie online sind, und versuchen Sie es dann erneut.',
  'key_change_favorites_warn': 'Die Verbindung für Favoriten wird entfernt, weil sie vom alten Schlüssel abhängt. Sie können sie danach mit Ihrem Secret-Key wieder verbinden.',
  'key_change_apply': 'Übernehmen',
  'key_change_success': 'Der API-Schlüssel wurde aktualisiert.',
  'key_internal_fav_note': 'Favoriten benötigen Ihren eigenen API-Schlüssel und Ihren Last.fm-Secret-Key. Fügen Sie oben Ihren Schlüssel hinzu, um sie zu aktivieren.',
  'faq_q15': 'Kann ich meinen API-Schlüssel nach der Anmeldung ändern?',
  'faq_a15': 'Ja. Gehen Sie zu Einstellungen > Konto und tippen Sie auf „API-Schlüssel ändern“. Sie können Ihren Schlüssel durch einen anderen ersetzen oder Ihren eigenen hinzufügen, falls Sie am Anfang den internen Schlüssel gewählt haben. Ihre Statistiken bleiben gleich, nur die Verbindung für Favoriten muss neu eingerichtet werden.',
  'nothing_wip_badge': 'Wird überarbeitet',
  'nothing_wip_msg': 'Der Nothing-OS-Stil wird gerade überarbeitet und ist deshalb vorerst nicht verfügbar. In einer späteren Version kann er möglicherweise aktiviert werden.',
  'ui_play_preview': 'Vorschau abspielen',
  'ntf_test_title': '🔔 Testbenachrichtigung',
  'ntf_test_body': 'LastStats-Benachrichtigungen funktionieren!',
  'ui_not_enough_data_yet_sy': 'Noch nicht genug Daten – synchronisieren Sie Ihren kompletten Verlauf in den Einstellungen.',
  'ui_level': 'Level {level}',
  'ui_fetching': 'Lade {currentYea}… ({yearIndex}/{totalYears})',
  'ui_which_chart': 'Welches Diagramm?',
  'ui_which_period': 'Welcher Zeitraum?',
  'ui_all_time': 'Gesamte Zeit',
  'ui_exporting': 'Export läuft…',
  'ui_chart_not_available_fo': 'Diagramm für diesen Zeitraum nicht verfügbar',
  'ui_could_not_generate_the': 'Bild konnte nicht erstellt werden',
  'ui_error': 'Fehler',
  'ui_loading_history': 'Verlauf{yearLabel} wird geladen… {pct} %',
  'ui_charts_will_be_more_ac': 'Die Diagramme werden nach dem Laden genauer.',
  'ui_load_the_full_history_': 'Laden Sie den kompletten Verlauf, um alle Jahre zu sehen.',
  'ui_load': 'Laden',
  'ui_based_on_scrobbles_all': 'Basierend auf {v_hourlyCou} Scrobbles (alle Jahre)',
  'ui_all_available_years': 'Alle verfügbaren Jahre',
  'ui_based_on_scrobbles_fro': 'Basierend auf {v_hourlyCou} Scrobbles aus {v_selectedY}',
  'ui_based_on_recent_scrobb': 'Basierend auf {v_hourlyCou} letzten Scrobbles',
  'ui_analysing_your_last_20': 'Analysiert Ihre letzten ~200 Scrobbles',
  'ui_all_time_loading': 'Gesamt (Daten für {v_selectedY} werden geladen)',
  'ui_all_time_2': 'Gesamt',
  'ui_export_a_chart': 'Diagramm exportieren',
  'ui_scrobble_progression': 'Verlauf der Scrobbles',
  'ui_your_musical_genres': 'Ihre Musikgenres',
  'ui_based_on_your_top_arti': 'Basierend auf Ihren Top-Künstlern (gesamt)',
  'ui_listening_habits': 'Hörgewohnheiten',
  'ui_album_distribution': 'Verteilung nach Album',
  'ui_listening_calendar': 'Hörkalender',
  'ui_daily_activity_to': 'Tägliche Aktivität — {first} bis {last}',
  'ui_daily_activity_all_yea': 'Tägliche Aktivität — alle Jahre',
  'ui_daily_activity': 'Tägliche Aktivität — {v_selectedY}',
  'ui_load_history_to_see': 'Laden Sie den Verlauf, um {v_selectedY} zu sehen',
  'ui_daily_activity_last_12': 'Tägliche Aktivität — letzte 12 Monate',
  'ui_all_years': 'alle Jahre',
  'ui_listening_streaks': 'Hörserien',
  'ui_total': 'Gesamt',
  'ui_avg_mo': 'Ø/Monat',
  'ui_best_month': 'Bester Monat',
  'ui_hourly_distribution': 'Verteilung nach Stunde',
  'ui_activity_by_day_of_wee': 'Aktivität nach Wochentag',
  'ui_current_streak': 'Aktuelle Serie',
  'ui_d': 'T',
  'ui_best_streak': 'Beste Serie',
  'ui_best_streak_started_on': 'Beste Serie seit dem {bestStart}',
  'ui_no_data_for_this_perio': 'Keine Daten für diesen Zeitraum',
  'ui_load_history_to_displa': 'Laden Sie den Verlauf, um {what} anzuzeigen',
  'ui_less': 'Weniger',
  'ui_more': 'Mehr',
  'ui_scan_a_profile': 'Profil scannen',
  'ui_lvl': 'Lvl {level}',
  'ui_qr_code': 'QR-Code?',
  'ui_add_a_qr_code_to_the_s': 'Einen QR-Code zum geteilten Bild hinzufügen, damit jeder Ihr Profil scannen kann?',
  'ui_no_qr': 'Ohne QR',
  'ui_to_the_app': 'Zur App',
  'ui_to_last_fm': 'Zu Last.fm',
  'ui_compare_music_taste': 'Musikgeschmack vergleichen',
  'ui_syncing_full_library': 'Daten werden synchronisiert…',
  'ui_see_more': 'Mehr anzeigen',
  'ui_no_achievements_unlock': 'Noch keine Erfolge freigeschaltet',
  'ui_no_animated_cover_for_': 'Kein animiertes Cover für dieses Album',
  'ui_source': 'Quelle: {source}',
  'ui_view_on_last_fm': 'Auf Last.fm ansehen',
  'ui_original_text_last_fm_': 'Originaltext: Last.fm — Übersetzung: Google Translate',
  'ui_source_last_fm': 'Quelle: Last.fm',
  'ui_dark': 'Dunkel',
  'ui_light': 'Hell',
  'ui_system': 'System',
  'ui_colored_widgets': 'Farbige Widgets',
  'ui_tint_home_screen_widge': 'Färbt die Homescreen-Widgets mit der Akzentfarbe',
  'ui_search_settings': 'Einstellung suchen…',
  'ui_no_settings_found': 'Keine Einstellung gefunden',
  'ui_all': 'Alle',
  'ui_battery_saver': 'Energiesparmodus',
  'ui_save_battery_fewer_eff': 'Akku sparen, weniger Effekte',
  'ui_musical_soulmates': 'Musikalische Seelenverwandte',
  'ui_great_compatibility': 'Sehr hohe Kompatibilität',
  'ui_some_common_ground': 'Einige Gemeinsamkeiten',
  'ui_fairly_different_taste': 'Eher unterschiedlicher Geschmack',
  'ui_worlds_apart_musically': 'Musikalisch gegensätzliche Welten',
  'ui_this_is_your_own_profi': 'Das ist Ihr eigenes Profil!',
  'ui_artists_from_your_hist': '{uniqueArti} Künstler aus Ihrem Verlauf · komplette Bibliothek von {targetUser}',
  'ui_artists_from_your_hist_2': '{uniqueArti} Künstler aus Ihrem Verlauf · Top 200 von {targetUser}',
  'ui_full_library_api': 'Komplette Bibliothek (API)',
  'ui_top_200_artists_tracks': 'Top 200 Künstler & Titel (API)',
  'ui_could_not_work_out_the': 'Kompatibilität konnte nicht berechnet werden.',
  'ui_music_compatibility': 'Musikalische Kompatibilität',
  'ui_analyzing_musical_tast': 'Musikgeschmack wird analysiert…',
  'ui_artist': '{v_totalArti} Künstler',
  'ui_track': '{v_totalTrac} Titel',
  'ui_album': '{v_totalAlbu} Alben',
  'ui_shared_tracks': 'Gemeinsame Titel',
  'ui_shared_artists': 'Gemeinsame Künstler',
  'ui_no_shared_artists_foun': 'Keine gemeinsamen Künstler gefunden.',
  'ui_shared_albums': 'Gemeinsame Alben',
  'ui_play_count_unavailable': 'Wiedergabezahl für einen von Ihnen nicht verfügbar.',
  'ui_you_listen_to_this_x_m': 'Sie hören das {x}x öfter als {theirUsern}.',
  'ui_listens_to_this_x_more': '{theirUsern} hört das {x}x öfter als Sie.',
  'ui_you_both_listen_to_thi': 'Sie hören das beide etwa gleich oft.',
  'ui_plays': '{plays} Wiedergaben',
  'ui_compatibility': 'Kompatibilität',
  'ui_you_both_love': 'SIE LIEBEN BEIDE',
  'ui_shared_top_artist': 'GEMEINSAMER LIEBLINGSKÜNSTLER',
  'ui_achievements': 'Erfolge',
  'ui_qr_not_recognized_not_': 'QR-Code nicht erkannt – kein LastStats/Last.fm-Profil',
  'ui_scan_a_profile_s_qr_co': 'Scannen Sie den QR-Code eines Profils',
  'ui_favorites': 'Favoriten',
  'ui_advanced_youtube_music': 'Fortschrittlicher YouTube-Music-Client.',
  'ui_syncs_the_glyphs_of_no': 'Synchronisiert die Glyphs der Nothing-Phones mit der Musik.',
  'ui_sources': 'Quellen',
  'ui_official_flutter_docs_': 'Offizielle Flutter-Dokumentation.',
  'ui_official_material_3_gu': 'Offizieller Material-3-Leitfaden für Flutter.',
  'ui_flutter_api_reference_': 'Flutter-API-Referenz für das Material-3-Theme.',
  'ui_official_flutter_packa': 'Offizielles Flutter-Paket für adaptive Layouts.',
  'ui_android_widgets': 'Android-Widgets',
  'ui_applies_the_accent_col': 'Wendet die Akzentfarbe auf den Hintergrund der Homescreen-Widgets an. Aus: reines Weiß oder Schwarz.',
  'ui_turns_off_tilt_paralla': 'Deaktiviert den Neige-Parallax, begrenzt die Bildwiederholrate und verlangsamt Hintergrundaktualisierungen – alles andere bleibt in voller Qualität (Bilder, Exporte, Share-Karten).',
  'ui_always_on': 'Immer an',
  'ui_force_eco_mode_on_rega': 'Erzwingt den Sparmodus, unabhängig vom Akkustand.',
  'ui_auto_activate': 'Automatisch aktivieren',
  'ui_turn_on_below_a_batter': 'Unter einem Akkustand (%) aktivieren',
  'ui_switches_on_by_itself_': 'Schaltet sich von selbst ein, sobald der Akku den unten gewählten Stand erreicht.',
  'ui_threshold': 'Schwellenwert',
  'ui_choose_the_tab_display': 'Wählen Sie den Tab, der beim Start der App angezeigt wird.',
  'ui_the_selected_tab_will_': 'Der gewählte Tab erscheint beim nächsten Start der App.',
  'ui_friends_sync': 'Freunde-Sync',
  'ui_sync_frequency': 'Sync-Häufigkeit',
  'ui_daily': 'Täglich',
  'ui_resync_everyone': 'Alle neu synchronisieren',
  'ui_version_history': 'Versionsverlauf',
  'ui_could_not_load_release': 'Verlauf konnte nicht geladen werden.',
  'ui_installed_dev_build_un': 'Installiert: Dev-Build (Version unbekannt)',
  'ui_installed': 'Installiert: {displayVer}',
  'ui_search_a_version_or_ch': 'Version oder Changelog suchen…',
  'ui_official': 'Offiziell',
  'ui_no_release_matches_you': 'Keine Version entspricht Ihrer Suche.',
  'ui_latest': 'NEUESTE',
  'ui_installed_2': 'INSTALLIERT',
  'ui_no_description': 'Keine Beschreibung.',
  'ui_download': 'Herunterladen',
  'ui_view_release': 'Release ansehen',
  'ui_details': 'Details',
  'ui_all_past_releases_chan': 'Alle früheren Versionen, Changelogs und Downloads',
  'ui_please_fill_both_field': 'Bitte füllen Sie beide Felder aus.',
  'ui_api_key_must_be_32_cha': 'Der API-Schlüssel muss 32 Zeichen lang sein.',
  'ui_profile_not_found': 'Profil nicht gefunden.',
  'ui_chart_monthly': 'Monatliche Balken',
  'ui_chart_cumul': 'Verlauf',
  'ui_chart_genres': 'Musikgenres',
  'ui_chart_habits': 'Hörgewohnheiten',
  'ui_chart_artists': 'Künstlerverteilung',
  'ui_chart_albums': 'Albumverteilung',
  'ui_chart_calendar': 'Hörkalender',
  'ui_chart_streaks': 'Hörserien',
  'ui_band_night': 'Nacht',
  'ui_band_morning': 'Morgen',
  'ui_band_afternoon': 'Nachmittag',
  'ui_band_evening': 'Abend',
  'qs_t1_t': 'OLED-Modus',
  'qs_t1_s': 'Reiner schwarzer Hintergrund',
  'qs_t2_t': 'Energiesparmodus',
  'qs_t2_s': 'Reduziert den Akkuverbrauch',
  'qs_t3_t': 'Nachrichten-Benachrichtigungen',
  'qs_t3_s': 'Benachrichtigungen zu Last.fm-Neuigkeiten',
  'qs_t4_t': 'Haptisches Feedback',
  'qs_t4_s': 'Vibrationen bei Interaktionen',
  'qs_t5_t': 'Erfolge',
  'qs_t5_s': 'Zeigt freigeschaltete Erfolge',
  'qs_l1_t': 'Akzentfarbe',
  'qs_l2_t': 'Design',
  'qs_l3_t': 'Sprache',
  'qs_l4_t': 'Musikplattform',
  'qs_l5_t': 'Konto',
  'qs_l6_t': 'Synchronisierung',
  'qs_l7_t': 'Cache',
  'img_src_lastfm': 'Quelle: Last.fm',
  'img_src_ytmusic': 'Quelle: YouTube Music',
  'img_src_itunes': 'Quelle: iTunes',
  'img_src_deezer': 'Quelle: Deezer',
  'img_src_audiodb': 'Quelle: TheAudioDB',
  'img_src_musicbrainz': 'Quelle: MusicBrainz',
  'img_src_wikipedia': 'Quelle: Wikipedia',
  'ds_type_artist': 'Künstler',
  'ds_type_album': 'Album',
  'ds_type_track': 'Titel',
  'pf_1': '👤 Nutzerprofil',
  'pf_2': '🎤 Top-Künstler — Gesamt',
  'pf_3': '💿 Top-Alben — Gesamt',
  'pf_4': '🎵 Top-Titel — Gesamt',
  'pf_5': '⏱️ Zuletzt gehört',
  'pf_6': '🗓️ Diese Woche',
  'pf_7': '📅 Diesen Monat',
  'pf_8': '📅 Letzte 3 Monate',
  'pf_9': '📅 Letzte 6 Monate',
  'pf_10': '📅 Letzte 12 Monate',
  'pf_11': '📊 Monatsverlauf',
  'pf_12': '❤️ Gelikte Titel',
  'pf_13': '🗓️ Top-Künstler — Woche',
  'pf_14': '🗓️ Alben & Titel — Woche',
  'ds_tier_next': '{n} / {next} bis zur nächsten Stufe',
  'ds_tier_max': 'Höchste Stufe erreicht 🎉',
  'ds_tier_first': 'Hören Sie diesen Titel, um die erste Stufe freizuschalten (ab {n} Wiedergaben).',
  'sl_import': 'Ihre Daten werden importiert',
  'sl_done': 'Importiert!',
  'sl_connect': 'Verbindung zu Last.fm …',
  'sec_chart': 'Diagramm / Kalender',
  'stat_avg_day': 'Ø / Tag',
  'stat_avg_week': 'Ø / Woche',
  'stat_days_active': 'Aktive Tage',
  'stat_scrobbles_week': 'Scrobbles (Woche)',
  'accent_purple': 'Violett',
  'accent_blue': 'Blau',
  'accent_green': 'Grün',
  'accent_red': 'Rot',
  'accent_orange': 'Orange',
  'accent_pink': 'Pink',
  'accent_teal': 'Petrol',
  'accent_neutral': 'Neutral',
  'shape_title': 'Bildformen',
  'shape_covers': 'Cover, Künstler und Alben',
  'shape_mix': 'Mix',
  'shape_square': 'Quadrat',
  'shape_circle': 'Kreis',
  'shape_pick_one': 'Oder wählen Sie eine einzelne Form',
  'friend_listening': 'Hört gerade',
  'friend_offline': 'Offline',
  'tier_none': 'Keine Stufe',
  'src_title': 'Quellen',
  'src_scrobbles_meta': 'Scrobbles und Metadaten',
  'src_artwork': 'Cover',
  'src_audio_preview': 'Audio-Vorschau',
  'src_video_artwork': 'Video-Cover',
  'tip_love': 'Zu Favoriten hinzufügen',
  'rail_expand': 'Seitenleiste erweitern',
  'rail_collapse': 'Seitenleiste einklappen',
  'a11y_loading': 'Wird geladen',
  'bk_pick_folder': 'Ordner für automatische Sicherung wählen',
  'bk_save_title': 'LastStats-Sicherung speichern',
  'bk_pick_file': 'LastStats-Sicherungsdatei auswählen',
  'nch_milestone_d': 'Benachrichtigt, wenn du einen Scrobble-Meilenstein erreichst',
  'nch_grand_d': 'Besondere Hinweise für große Meilensteine (1K, 10K, 100K, 1M…)',
  'nch_recap_d': 'Tägliche und wöchentliche Hörzusammenfassungen',
  'nch_update_d': 'Benachrichtigt, wenn eine neue LastStats-Version verfügbar ist',
  'nch_news_d': 'Neuigkeiten, Fehlerbehebungen und Ankündigungen zu LastStats',
  'nch_sync_d': 'Fortschritt beim Synchronisieren des gesamten Scrobble-Verlaufs',
  'ntf_grand_1000000': 'Eine Million Scrobbles. Das ist legendär. 🎸',
  'ntf_grand_500000': 'Eine halbe Million Scrobbles. Du hörst nie auf. 🎧',
  'ntf_grand_250000': '{n} Scrobbles – die Musik hört nie auf. 🎶',
  'ntf_grand_100000': '{n} Scrobbles! Du bist ein echter Musikjunkie. 🔥',
  'ntf_grand_50000': '{n} Scrobbles. Wirklich beeindruckend. 🎵',
  'ntf_grand_25000': '{n} Scrobbles und kein Ende in Sicht!',
  'ntf_grand_10000': '{n} Scrobbles – du hast die fünfstellige Marke erreicht! 🎉',
  'ntf_grand_5000': '{n} Scrobbles und es werden mehr!',
  'ntf_grand_1000': 'Deine ersten {n} Scrobbles. Die Reise beginnt. 🎵',
  'ntf_update_title': 'LastStats {v} verfügbar',
  'ntf_update_body': 'Eine neue Version steht zum Download bereit.',
  'ntf_milestone_title': '🎵 Meilenstein: {n} Scrobbles',
  'ntf_milestone_body': 'Du hast gerade {n} Scrobbles auf Last.fm erreicht 🎶',
  'ntf_daily_title': '📊 Tagesrückblick · {d}',
  'ntf_weekly_title': '📅 Wochenrückblick · {w}',
  'ntf_recap_body': '{n} Scrobbles · Top: {a}',
  'ntf_n_today': '{n} Scrobbles heute',
  'ntf_n_week': '{n} Scrobbles diese Woche',
  'ntf_top_artist': 'Top-Künstler: {a}',
  'ntf_update_avail': '🆕 Update verfügbar',
  'ntf_update_ready': 'LastStats {v} ist bereit – zum Ansehen tippen.',
  'ntf_sync_title': '🔄 Scrobbles werden synchronisiert…',
  'ntf_sync_done': '✅ Scrobbles synchronisiert',
  'ntf_sync_new': '{n} neue(r) Scrobble(s) hinzugefügt.',
  'ntf_grand_t': '{v} Scrobbles!',
  'ntf_year': 'Jahr {y}',
  'ntf_week': 'Woche {w}',
  'reorder': 'Neu anordnen',
  'sp_login_t': 'Spotify-Anmeldung',
  'sp_login_hint': 'Melden Sie sich mit Ihrer Spotify-E-Mail und Ihrem Passwort an. Das Fenster schließt sich nach der Anmeldung von selbst.',
  'sp_t': 'Spotify (Canvas)',
  'sp_on': 'Verbunden',
  'sp_off': 'Nicht verbunden',
  'sp_off_s': 'Von Spotify abgemeldet',
  'sp_need': 'Spotify braucht eine Anmeldung: Profil > Verbindungsseite.',
  'conn_title': 'Verbindungen',
  'conn_btn_t': 'Verbindungsseite',
  'conn_btn_s': 'Last.fm, Spotify und API-Schlüssel',
  'conn_sp_desc': 'Für Video-Cover (Canvas). Ein Spotify-Konto ist erforderlich.',
  'conn_connect': 'Verbinden',
  'conn_disconnect': 'Trennen',
  'conn_keys': 'API-Schlüssel',
  'conn_manage': 'Konto verwalten',
  'conn_test': 'Spotify testen',
  'conn_testing': 'Test läuft…',
  'conn_q_note': 'Spotify Canvas hat nur eine Qualität. Die Qualitätseinstellungen gelten nur für Apple Music und YouTube.',
  'conn_lfm_desc': 'Zwei Methoden: Anmeldung auf der Last.fm-Website (der in der App integrierte Schlüssel wird verwendet) oder Ihr eigener API-Schlüssel.',
  'conn_lfm_web': 'Mit Last.fm anmelden',
  'lfm_login_t': 'Last.fm-Anmeldung',
  'lfm_login_hint': 'Melden Sie sich auf der Last.fm-Website an. Die App erkennt Ihren Benutzernamen und schließt dann das Fenster.',
  'dg_cookie': 'Login-Cookie',
  'dg_token': 'Web-Token',
  'dg_search': 'Suche',
  'dg_ok': 'ok',
  'dg_missing': 'FEHLT',
  'dg_failed': 'FEHLER',
  'dg_found': 'Video gefunden',
  'dg_nofound': 'kein Video',
  'dg_notpl': 'Suchvorlage fehlt (bitte gleich erneut versuchen)',
  'dg_results': 'Ergebnisse',
  'lfm_web_sub': 'Kein API-Schlüssel nötig: Der in der App integrierte Schlüssel wird verwendet.',
  'lfm_manual_hint': 'Der Benutzername wurde nicht automatisch gefunden. Geben Sie ihn nach der Anmeldung unten ein.',
  'lfm_manual_label': 'Benutzername',
};
