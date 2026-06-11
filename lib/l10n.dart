// lib/l10n.dart
// ══════════════════════════════════════════════════════════════════════════
//  App localization — French (fr) + English (en)
//  Usage: L10n.s.someKey  (uses current localeNotifier.value)
// ══════════════════════════════════════════════════════════════════════════

import 'app_state.dart';

abstract class AppStrings {
  // ── Periods ──────────────────────────────────────────────────────────────
  String get period7day;
  String get period1month;
  String get period3month;
  String get period6month;
  String get period12month;
  String get periodOverall;

  // ── Navigation ───────────────────────────────────────────────────────────
  String get navDashboard;
  String get navSearch;
  String get navRankings;
  String get navCharts;
  String get navHistory;
  String get navSettings;

  // ── Common ───────────────────────────────────────────────────────────────
  String get commonArtists;
  String get commonAlbums;
  String get commonTracks;
  String get commonNoResults;
  String get commonRetry;
  String get commonCancel;
  String get commonApply;
  String get commonPlays;       // "écoutes" / "plays"
  String get commonListeners;   // "auditeurs" / "listeners"
  String get commonNowPlayingBadge; // "EN COURS" / "LIVE"
  String get commonNowPlayingLong;  // "En cours d'écoute" / "Now listening"
  String get commonRecentTracks;
  String get commonNoRecentTracks;
  String get commonTopArtists;

  // ── Rankings ─────────────────────────────────────────────────────────────
  String get rankingsTitle;
  String get rankingsPodium;
  String get rankingsContinued;
  String get rankingsAllYears;

  // ── Charts ───────────────────────────────────────────────────────────────
  String get chartsTitle;
  String get chartsMonthly;
  String get chartsArtistDist;
  String get chartsMainstreamTitle;
  String get chartsMainstreamSubtitle;
  String get chartsCompute;
  String get chartsRecompute;
  String get chartsGem;
  String get chartsMainstream;
  String globalListeners(String count);

  // ── History ──────────────────────────────────────────────────────────────
  String get historyTitle;
  String get historySubtitle;
  String get historyToday;
  String get historySelectDate;
  String get historyChronological;
  String get historyList;
  String get historyStats;
  String get historyNoTracks;
  String historyScrobbles(int n);
  String historyArtistsCount(int n);
  String historyAlbumsCount(int n);
  String get historyTopArtists;
  String get historyTopAlbums;
  String get historyTopTracks;
  String get historyHourTracks;   // "${n} titre(s)" / "${n} track(s)"
  List<String> get months;        // index 0 = empty
  String dayLabel(DateTime d);

  // ── Search ───────────────────────────────────────────────────────────────
  String get searchTitle;
  String get searchProfiles;
  String get searchHintBar;
  String get searchHintProfiles;
  String get searchHintArtists;
  String get searchHintAlbums;
  String get searchHintTracks;
  String get searchTypePrompt;
  String get searchAll;
  String memberSince(String date);
  String get perDay;
  String get activityDays;

  // ── Dashboard ─────────────────────────────────────────────────────────────
  String get dashStats;
  String get dashTopTracks;
  String get dashFriends;
  String get dashRefresh;
  String get dashRefreshFriends;
  String get dashScrobbles;
  String get dashScrobblesPerDay;
  String get dashDaysActive;
  String get dashLastTrack;
  String get dashArtist1;
  String get dashAlbum1;
  String get dashTrack1;
  String get dashNoFriends;
  String get dashFriendsActivity;

  // ── Settings ─────────────────────────────────────────────────────────────
  String get settingsTitle;
  String get settingsAppearance;
  String get settingsTheme;
  String get settingsThemeAuto;
  String get settingsThemeLight;
  String get settingsThemeDark;
  String get settingsAccentColor;
  String get settingsAccentAuto;
  String get settingsCustomColor;
  String get settingsCustomColorEdit;
  String get settingsDynamicColor;
  String get settingsMaterialYou;
  String get settingsMaterialYouSub;
  String get settingsMusicColor;
  String get settingsMusicColorSub;
  String get settingsMusicColorNote;
  String get settingsMusicColorLocked;
  String get settingsStartupPage;
  String get settingsStartupTab;
  String get settingsDashboardSection;
  String get settingsHeaderImage;
  String get settingsHeaderImageSub;
  String get settingsHeaderSource;
  String get settingsHeaderPeriod;
  String get settingsHeaderAnimation;
  String get settingsHeaderAnimationSub;
  String get settingsHeaderBlur;
  String get settingsHeaderBlurNone;
  String get settingsHeaderCustomUrl;
  String get settingsHeaderCustomUrlHint;
  String get settingsHeaderCustomUrlSub;
  String get settingsHeaderApply;
  String get settingsHeaderFallback;
  String get settingsHeaderFallbackSub;
  String get settingsHeaderFallbackUrlLabel;
  String get settingsVisibleSections;
  String get settingsNowPlayingSection;
  String get settingsStatsSection;
  String get settingsTopArtistsSection;
  String get settingsTopTracksSection;
  String get settingsFriendsSection;
  String get settingsFriendsSectionSub;
  String get settingsAccount;
  String get settingsConnectedProfile;
  String get settingsLogout;
  String get settingsLogoutTitle;
  String get settingsLogoutContent;
  String get settingsLogoutConfirm;
  String get settingsBackup;
  String get settingsExport;
  String get settingsExportSub;
  String get settingsImport;
  String get settingsImportSub;
  String get settingsBackupInfo;
  String get settingsUpdates;
  String get settingsAutoUpdate;
  String get settingsAutoUpdateSub;
  String get settingsCheckNow;
  String get settingsUpToDate;
  String settingsUpdateAvailable(String v);
  String get settingsCheckFailed;
  String settingsUpdateBanner(String v);
  String get settingsDownload;
  String get settingsViewRelease;
  String get settingsAbout;
  String get settingsVersion;
  String get settingsWebVersion;
  String get settingsWebVersionSub;
  String get settingsSourceCode;
  String get settingsSourceCodeSub;
  String get settingsLanguage;
  String get settingsAboutProjectDesc;
  String get settingsAboutSupport;
  String get settingsAboutSupportSub;

  // ── Header source / animation labels ─────────────────────────────────────
  String get headerNowPlaying;
  String get headerTopTrack;
  String get headerTopAlbum;
  String get headerTopArtist;
  String get headerCustomImage;
  String get headerThemeColor;
  String get headerAnimNone;
  String get headerAnimFade;
  String get headerAnimSlide;
  String get headerAnimZoom;
  String get headerPeriodWeek;
  String get headerPeriodMonth;
  String get headerPeriodAllTime;

  // ── Color picker ─────────────────────────────────────────────────────────
  String get colorPickerTitle;
  String get colorPickerHue;
  String get colorPickerSaturation;
  String get colorPickerBrightness;
  String get colorPickerQuickColors;
  String get colorPickerInvalid;
  String get colorCustomTooltip;

  // ── Export / Import sheet ─────────────────────────────────────────────────
  String get exportTitle;
  String get exportFilename;
  String get exportJsonContent;
  String get exportInfo;
  String get exportCopy;
  String get exportCopied;
  String get importTitle;
  String get importHintLabel;
  String get importEmpty;
  String get importInvalidJson;
  String get importUnknownFile;
  String get importInvalidFormat;
  String get importSuccess;
  String get importRestore;

  // ── Setup screen ──────────────────────────────────────────────────────────
  String get setupImportJson;
  String get setupImportHintLabel;
  String get setupImportNote;
  String get setupImportFormat;
  String get setupInvalidFields;

  // ── Detail sheet ──────────────────────────────────────────────────────────
  String get detailTracklist;
  String get detailAlbumLabel;
  String get detailDuration;
  String get detailTopTracks;
  String get detailTopAlbums;
  String get detailBioReadMore;
  String get detailBioReadLess;
  String get detailUserPlays;
  String get detailUserRank;
  String get detailUserRankNA;
  String get detailGlobalListeners;
  String get detailPeriod;
  String get detailBiography;
  String get detailGlobalListenersLabel; // "Auditeurs" / "Listeners"

  // ── Dashboard extra ─────────────────────────────────────────────────────────
  String get dashPerWeek;
}

// ══════════════════════════════════════════════════════════════════════════
//  French
// ══════════════════════════════════════════════════════════════════════════

class _AppStringsFr implements AppStrings {
  const _AppStringsFr();

  @override String get period7day     => 'Semaine';
  @override String get period1month   => 'Mois';
  @override String get period3month   => '3 mois';
  @override String get period6month   => '6 mois';
  @override String get period12month  => 'Année';
  @override String get periodOverall  => 'Tout';

  @override String get navDashboard => 'Dashboard';
  @override String get navSearch    => 'Recherche';
  @override String get navRankings  => 'Classements';
  @override String get navCharts    => 'Graphiques';
  @override String get navHistory   => 'Historique';
  @override String get navSettings  => 'Paramètres';

  @override String get commonArtists          => 'Artistes';
  @override String get commonAlbums           => 'Albums';
  @override String get commonTracks           => 'Titres';
  @override String get commonNoResults        => 'Aucun résultat';
  @override String get commonRetry            => 'Réessayer';
  @override String get commonCancel           => 'Annuler';
  @override String get commonApply            => 'Appliquer';
  @override String get commonPlays            => 'écoutes';
  @override String get commonListeners        => 'auditeurs';
  @override String get commonNowPlayingBadge  => 'EN COURS';
  @override String get commonNowPlayingLong   => "En cours d'écoute";
  @override String get commonRecentTracks     => 'Écoutes récentes';
  @override String get commonNoRecentTracks   => 'Aucune écoute récente';
  @override String get commonTopArtists       => 'Top Artistes';

  @override String get rankingsTitle     => 'Classements';
  @override String get rankingsPodium    => 'Podium';
  @override String get rankingsContinued => 'Suite du classement';
  @override String get rankingsAllYears  => 'Toutes les années';

  @override String get chartsTitle             => 'Graphiques';
  @override String get chartsMonthly           => 'Scrobbles — 12 mois';
  @override String get chartsArtistDist        => 'Top artistes — distribution';
  @override String get chartsMainstreamTitle   => 'Mainstream vs Pépites';
  @override String get chartsMainstreamSubtitle => 'Popularité mondiale de tes artistes favoris.';
  @override String get chartsCompute           => 'Calculer';
  @override String get chartsRecompute         => 'Recalculer';
  @override String get chartsGem               => 'Pépite';
  @override String get chartsMainstream        => 'Mainstream';
  @override String globalListeners(String count) => '$count auditeurs mondiaux';

  @override String get historyTitle          => 'Historique';
  @override String get historySubtitle       => 'Vos écoutes, jour par jour';
  @override String get historyToday          => "Aujourd'hui";
  @override String get historySelectDate     => 'Sélectionner une date';
  @override String get historyChronological  => 'Chronologique';
  @override String get historyList           => 'Liste';
  @override String get historyStats          => 'Statistiques';
  @override String get historyNoTracks       => 'Aucune écoute ce jour-là';
  @override String historyScrobbles(int n)   => '$n scrobbles';
  @override String historyArtistsCount(int n) => '$n artistes';
  @override String historyAlbumsCount(int n)  => '$n albums';
  @override String get historyTopArtists     => 'Top artistes';
  @override String get historyTopAlbums      => 'Top albums';
  @override String get historyTopTracks      => 'Top titres';
  @override String get historyHourTracks     => 'titre';
  @override List<String> get months => const [
    '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
  ];
  @override String dayLabel(DateTime d) {
    const jours = ['lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche'];
    const mois  = ['','janvier','février','mars','avril','mai','juin',
        'juillet','août','septembre','octobre','novembre','décembre'];
    return '${jours[d.weekday - 1]} ${d.day} ${mois[d.month]} ${d.year}';
  }

  @override String get searchTitle        => 'Recherche';
  @override String get searchProfiles     => 'Profils';
  @override String get searchHintBar      => 'Artiste, album, titre ou profil…';
  @override String get searchHintProfiles => 'Recherche un utilisateur Last.fm';
  @override String get searchHintArtists  => 'Recherche un artiste';
  @override String get searchHintAlbums   => 'Recherche un album';
  @override String get searchHintTracks   => 'Recherche une chanson';
  @override String get searchTypePrompt   => 'Tape dans la barre ci-dessus';
  @override String get searchAll          => 'Tout';
  @override String memberSince(String date) => 'Depuis $date';
  @override String get perDay             => 'par jour';
  @override String get activityDays       => "d'activité";

  @override String get dashStats           => 'Statistiques';
  @override String get dashTopTracks       => 'Top Titres';
  @override String get dashFriends         => 'Amis';
  @override String get dashRefresh         => 'Actualiser';
  @override String get dashRefreshFriends  => 'Actualiser les amis';
  @override String get dashScrobbles       => 'scrobbles';
  @override String get dashScrobblesPerDay => 'par jour';
  @override String get dashDaysActive      => "d'activité";
  @override String get dashLastTrack       => 'Dernière écoute';
  @override String get dashArtist1         => 'Artiste #1';
  @override String get dashAlbum1          => 'Album #1';
  @override String get dashTrack1          => 'Titre #1';
  @override String get dashNoFriends       => 'Aucun ami trouvé';
  @override String get dashFriendsActivity => "Activité de tes amis Last.fm";

  @override String get settingsTitle             => 'Paramètres';
  @override String get settingsAppearance        => 'Apparence';
  @override String get settingsTheme             => 'Thème';
  @override String get settingsThemeAuto         => 'Auto';
  @override String get settingsThemeLight        => 'Clair';
  @override String get settingsThemeDark         => 'Sombre';
  @override String get settingsAccentColor       => "Couleur d'accent";
  @override String get settingsAccentAuto        => 'Auto';
  @override String get settingsCustomColor       => 'Personnalisé';
  @override String get settingsCustomColorEdit   => 'Modifier';
  @override String get settingsDynamicColor      => 'Couleur dynamique';
  @override String get settingsMaterialYou       => 'Material You';
  @override String get settingsMaterialYouSub    => 'Utilise la couleur du thème Android';
  @override String get settingsMusicColor        => 'Couleur depuis la musique';
  @override String get settingsMusicColorSub     => 'Extrait la couleur de la pochette en cours';
  @override String get settingsMusicColorNote    => "La couleur dominante de la pochette en cours remplace l'accent.";
  @override String get settingsMusicColorLocked  => "Désactiver Material You d'abord";
  @override String get settingsStartupPage       => 'Page de démarrage';
  @override String get settingsStartupTab        => "Onglet à l'ouverture";
  @override String get settingsDashboardSection  => 'Dashboard';
  @override String get settingsHeaderImage       => "Image d'en-tête";
  @override String get settingsHeaderImageSub    => "La pochette choisie s'affiche en fond de l'accueil.";
  @override String get settingsHeaderSource      => 'Source';
  @override String get settingsHeaderPeriod      => 'Période';
  @override String get settingsHeaderAnimation   => 'Transition';
  @override String get settingsHeaderAnimationSub => 'Animation lors du changement de pochette.';
  @override String get settingsHeaderBlur        => 'Flou';
  @override String get settingsHeaderBlurNone    => 'Aucun';
  @override String get settingsHeaderCustomUrl   => "URL de l'image";
  @override String get settingsHeaderCustomUrlHint => 'https://exemple.com/image.jpg';
  @override String get settingsHeaderCustomUrlSub  => "Colle l'URL directe d'une image (jpg, png, webp…).";
  @override String get settingsHeaderApply       => 'Appliquer';
  @override String get settingsHeaderFallback    => 'Image par défaut';
  @override String get settingsHeaderFallbackSub => "Affichée si aucune musique n'est en cours.";
  @override String get settingsHeaderFallbackUrlLabel => "URL de l'image par défaut";
  @override String get settingsVisibleSections   => 'Sections visibles';
  @override String get settingsNowPlayingSection => 'En cours de lecture';
  @override String get settingsStatsSection      => 'Statistiques';
  @override String get settingsTopArtistsSection => 'Top Artistes';
  @override String get settingsTopTracksSection  => 'Top Titres';
  @override String get settingsFriendsSection    => 'Amis';
  @override String get settingsFriendsSectionSub => 'Activité de tes amis Last.fm';
  @override String get settingsAccount           => 'Compte';
  @override String get settingsConnectedProfile  => 'Profil Last.fm connecté';
  @override String get settingsLogout            => 'Se déconnecter';
  @override String get settingsLogoutTitle       => 'Se déconnecter ?';
  @override String get settingsLogoutContent     => 'Tes identifiants seront supprimés.';
  @override String get settingsLogoutConfirm     => 'Déconnecter';
  @override String get settingsBackup            => 'Sauvegarde & restauration';
  @override String get settingsExport            => 'Exporter les paramètres';
  @override String get settingsExportSub         => 'Copie un JSON dans le presse-papier';
  @override String get settingsImport            => 'Restaurer une sauvegarde';
  @override String get settingsImportSub         => 'Collez un JSON précédemment exporté';
  @override String get settingsBackupInfo        => 'Inclut : thème, couleurs, clé API, pseudo, en-tête, favoris. Compatible entre versions.';
  @override String get settingsUpdates           => 'Mises à jour';
  @override String get settingsAutoUpdate        => 'Vérification automatique';
  @override String get settingsAutoUpdateSub     => '1 fois par jour';
  @override String get settingsCheckNow          => 'Vérifier maintenant';
  @override String get settingsUpToDate          => 'À jour';
  @override String settingsUpdateAvailable(String v) => 'v$v disponible';
  @override String get settingsCheckFailed       => 'Vérification impossible.';
  @override String settingsUpdateBanner(String v) => 'Mise à jour — v$v';
  @override String get settingsDownload          => 'Télécharger';
  @override String get settingsViewRelease       => 'Voir';
  @override String get settingsAbout             => 'À propos';
  @override String get settingsVersion           => 'Version';
  @override String get settingsWebVersion        => 'Version web';
  @override String get settingsWebVersionSub     => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode        => 'Code source';
  @override String get settingsSourceCodeSub     => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage          => 'Langue';
  @override String get settingsAboutProjectDesc  => 'LastStats est un projet personnel open-source. Il peut contenir des bugs.';
  @override String get settingsAboutSupport      => 'Soutenir le projet';
  @override String get settingsAboutSupportSub   => '⭐ Laisser une étoile sur GitHub';

  @override String get headerNowPlaying  => 'Musique en cours';
  @override String get headerTopTrack    => 'Titre #1';
  @override String get headerTopAlbum    => 'Album #1';
  @override String get headerTopArtist   => 'Artiste #1';
  @override String get headerCustomImage => 'Image perso.';
  @override String get headerThemeColor  => 'Couleur du thème';
  @override String get headerAnimNone    => 'Aucune';
  @override String get headerAnimFade    => 'Fondu';
  @override String get headerAnimSlide   => 'Glissement';
  @override String get headerAnimZoom    => 'Zoom';
  @override String get headerPeriodWeek  => 'Semaine';
  @override String get headerPeriodMonth => 'Mois';
  @override String get headerPeriodAllTime => 'Tout temps';

  @override String get colorPickerTitle       => 'Couleur personnalisée';
  @override String get colorPickerHue         => 'Teinte';
  @override String get colorPickerSaturation  => 'Saturation';
  @override String get colorPickerBrightness  => 'Luminosité';
  @override String get colorPickerQuickColors => 'Couleurs rapides';
  @override String get colorPickerInvalid     => 'Format invalide';
  @override String get colorCustomTooltip     => 'Personnalisé';

  @override String get exportTitle      => 'Exporter les paramètres';
  @override String get exportFilename   => 'Nom du fichier';
  @override String get exportJsonContent => 'Contenu JSON';
  @override String get exportInfo       => 'Copiez ce JSON, collez-le dans un fichier texte et nommez-le avec .json';
  @override String get exportCopy       => 'Copier le JSON';
  @override String get exportCopied     => 'Copié !';
  @override String get importTitle      => 'Restaurer une sauvegarde';
  @override String get importHintLabel  => 'Collez ici votre sauvegarde LastStats.';
  @override String get importEmpty      => 'Champ vide.';
  @override String get importInvalidJson  => 'JSON invalide.';
  @override String get importUnknownFile  => 'Fichier non reconnu.';
  @override String get importInvalidFormat => 'Format invalide.';
  @override String get importSuccess    => 'Paramètres restaurés avec succès ✓';
  @override String get importRestore    => 'Restaurer';

  @override String get setupImportJson      => 'Importer JSON';
  @override String get setupImportHintLabel => 'Colle le contenu de ton fichier JSON ci-dessous.';
  @override String get setupImportNote      => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat    => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields   => 'JSON invalide : champs "username" ou "api_key" manquants.';

  @override String get detailTracklist       => 'Titres';
  @override String get detailAlbumLabel      => 'Album';
  @override String get detailDuration        => 'Durée';
  @override String get detailTopTracks       => 'Titres populaires';
  @override String get detailTopAlbums       => 'Albums populaires';
  @override String get detailBioReadMore     => 'Lire la suite';
  @override String get detailBioReadLess     => 'Réduire';
  @override String get detailUserPlays       => 'écoutes';
  @override String get detailUserRank        => 'classement';
  @override String get detailUserRankNA      => 'N/A';
  @override String get detailGlobalListeners => 'auditeurs';
  @override String get detailPeriod          => 'Période';
  @override String get detailBiography       => 'Biographie';
  @override String get detailGlobalListenersLabel => 'Auditeurs';
  @override String get dashPerWeek           => 'par semaine';
}

// ══════════════════════════════════════════════════════════════════════════
//  English
// ══════════════════════════════════════════════════════════════════════════

class _AppStringsEn implements AppStrings {
  const _AppStringsEn();

  @override String get period7day     => 'Week';
  @override String get period1month   => 'Month';
  @override String get period3month   => '3 months';
  @override String get period6month   => '6 months';
  @override String get period12month  => 'Year';
  @override String get periodOverall  => 'All time';

  @override String get navDashboard => 'Dashboard';
  @override String get navSearch    => 'Search';
  @override String get navRankings  => 'Rankings';
  @override String get navCharts    => 'Charts';
  @override String get navHistory   => 'History';
  @override String get navSettings  => 'Settings';

  @override String get commonArtists          => 'Artists';
  @override String get commonAlbums           => 'Albums';
  @override String get commonTracks           => 'Tracks';
  @override String get commonNoResults        => 'No results';
  @override String get commonRetry            => 'Retry';
  @override String get commonCancel           => 'Cancel';
  @override String get commonApply            => 'Apply';
  @override String get commonPlays            => 'plays';
  @override String get commonListeners        => 'listeners';
  @override String get commonNowPlayingBadge  => 'LIVE';
  @override String get commonNowPlayingLong   => 'Now listening';
  @override String get commonRecentTracks     => 'Recent tracks';
  @override String get commonNoRecentTracks   => 'No recent tracks';
  @override String get commonTopArtists       => 'Top Artists';

  @override String get rankingsTitle     => 'Rankings';
  @override String get rankingsPodium    => 'Podium';
  @override String get rankingsContinued => 'Rest of ranking';
  @override String get rankingsAllYears  => 'All years';

  @override String get chartsTitle              => 'Charts';
  @override String get chartsMonthly            => 'Scrobbles — 12 months';
  @override String get chartsArtistDist         => 'Top artists — breakdown';
  @override String get chartsMainstreamTitle    => 'Mainstream vs Hidden gems';
  @override String get chartsMainstreamSubtitle => 'Global popularity of your favourite artists.';
  @override String get chartsCompute            => 'Compute';
  @override String get chartsRecompute          => 'Recompute';
  @override String get chartsGem                => 'Hidden gem';
  @override String get chartsMainstream         => 'Mainstream';
  @override String globalListeners(String count) => '$count global listeners';

  @override String get historyTitle           => 'History';
  @override String get historySubtitle        => 'Your listens, day by day';
  @override String get historyToday           => 'Today';
  @override String get historySelectDate      => 'Select a date';
  @override String get historyChronological   => 'Chronological';
  @override String get historyList            => 'List';
  @override String get historyStats           => 'Stats';
  @override String get historyNoTracks        => 'No listens on this day';
  @override String historyScrobbles(int n)    => '$n scrobbles';
  @override String historyArtistsCount(int n) => '$n artists';
  @override String historyAlbumsCount(int n)  => '$n albums';
  @override String get historyTopArtists      => 'Top artists';
  @override String get historyTopAlbums       => 'Top albums';
  @override String get historyTopTracks       => 'Top tracks';
  @override String get historyHourTracks      => 'track';
  @override List<String> get months => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  @override String dayLabel(DateTime d) {
    const days   = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['','January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    return '${days[d.weekday - 1]}, ${months[d.month]} ${d.day}, ${d.year}';
  }

  @override String get searchTitle        => 'Search';
  @override String get searchProfiles     => 'Profiles';
  @override String get searchHintBar      => 'Artist, album, track or profile…';
  @override String get searchHintProfiles => 'Find a Last.fm user';
  @override String get searchHintArtists  => 'Find an artist';
  @override String get searchHintAlbums   => 'Find an album';
  @override String get searchHintTracks   => 'Find a song';
  @override String get searchTypePrompt   => 'Type in the search bar above';
  @override String get searchAll          => 'All';
  @override String memberSince(String date) => 'Since $date';
  @override String get perDay             => 'per day';
  @override String get activityDays       => 'of activity';

  @override String get dashStats           => 'Stats';
  @override String get dashTopTracks       => 'Top Tracks';
  @override String get dashFriends         => 'Friends';
  @override String get dashRefresh         => 'Refresh';
  @override String get dashRefreshFriends  => 'Refresh friends';
  @override String get dashScrobbles       => 'scrobbles';
  @override String get dashScrobblesPerDay => 'per day';
  @override String get dashDaysActive      => 'of activity';
  @override String get dashLastTrack       => 'Last played';
  @override String get dashArtist1         => 'Artist #1';
  @override String get dashAlbum1          => 'Album #1';
  @override String get dashTrack1          => 'Track #1';
  @override String get dashNoFriends       => 'No friends found';
  @override String get dashFriendsActivity => "Your Last.fm friends' activity";

  @override String get settingsTitle             => 'Settings';
  @override String get settingsAppearance        => 'Appearance';
  @override String get settingsTheme             => 'Theme';
  @override String get settingsThemeAuto         => 'Auto';
  @override String get settingsThemeLight        => 'Light';
  @override String get settingsThemeDark         => 'Dark';
  @override String get settingsAccentColor       => 'Accent color';
  @override String get settingsAccentAuto        => 'Auto';
  @override String get settingsCustomColor       => 'Custom';
  @override String get settingsCustomColorEdit   => 'Edit';
  @override String get settingsDynamicColor      => 'Dynamic color';
  @override String get settingsMaterialYou       => 'Material You';
  @override String get settingsMaterialYouSub    => 'Use Android wallpaper color';
  @override String get settingsMusicColor        => 'Color from music';
  @override String get settingsMusicColorSub     => 'Extracts color from the current album art';
  @override String get settingsMusicColorNote    => 'The dominant color of the current album art replaces the accent.';
  @override String get settingsMusicColorLocked  => 'Disable Material You first';
  @override String get settingsStartupPage       => 'Startup page';
  @override String get settingsStartupTab        => 'Tab on launch';
  @override String get settingsDashboardSection  => 'Dashboard';
  @override String get settingsHeaderImage       => 'Header image';
  @override String get settingsHeaderImageSub    => 'The chosen artwork is shown as the home background.';
  @override String get settingsHeaderSource      => 'Source';
  @override String get settingsHeaderPeriod      => 'Period';
  @override String get settingsHeaderAnimation   => 'Transition';
  @override String get settingsHeaderAnimationSub => 'Animation when the artwork changes.';
  @override String get settingsHeaderBlur        => 'Blur';
  @override String get settingsHeaderBlurNone    => 'None';
  @override String get settingsHeaderCustomUrl   => 'Image URL';
  @override String get settingsHeaderCustomUrlHint => 'https://example.com/image.jpg';
  @override String get settingsHeaderCustomUrlSub  => 'Paste the direct URL of an image (jpg, png, webp…).';
  @override String get settingsHeaderApply       => 'Apply';
  @override String get settingsHeaderFallback    => 'Default image';
  @override String get settingsHeaderFallbackSub => 'Shown when no music is playing.';
  @override String get settingsHeaderFallbackUrlLabel => 'Default image URL';
  @override String get settingsVisibleSections   => 'Visible sections';
  @override String get settingsNowPlayingSection => 'Now playing';
  @override String get settingsStatsSection      => 'Stats';
  @override String get settingsTopArtistsSection => 'Top Artists';
  @override String get settingsTopTracksSection  => 'Top Tracks';
  @override String get settingsFriendsSection    => 'Friends';
  @override String get settingsFriendsSectionSub => 'Your Last.fm friends\' activity';
  @override String get settingsAccount           => 'Account';
  @override String get settingsConnectedProfile  => 'Connected Last.fm profile';
  @override String get settingsLogout            => 'Sign out';
  @override String get settingsLogoutTitle       => 'Sign out?';
  @override String get settingsLogoutContent     => 'Your credentials will be deleted.';
  @override String get settingsLogoutConfirm     => 'Sign out';
  @override String get settingsBackup            => 'Backup & restore';
  @override String get settingsExport            => 'Export settings';
  @override String get settingsExportSub         => 'Copy a JSON to the clipboard';
  @override String get settingsImport            => 'Restore a backup';
  @override String get settingsImportSub         => 'Paste a previously exported JSON';
  @override String get settingsBackupInfo        => 'Includes: theme, colors, API key, username, header, favourites. Compatible across versions.';
  @override String get settingsUpdates           => 'Updates';
  @override String get settingsAutoUpdate        => 'Automatic check';
  @override String get settingsAutoUpdateSub     => 'Once a day';
  @override String get settingsCheckNow          => 'Check now';
  @override String get settingsUpToDate          => 'Up to date';
  @override String settingsUpdateAvailable(String v) => 'v$v available';
  @override String get settingsCheckFailed       => 'Check failed.';
  @override String settingsUpdateBanner(String v) => 'Update — v$v';
  @override String get settingsDownload          => 'Download';
  @override String get settingsViewRelease       => 'View';
  @override String get settingsAbout             => 'About';
  @override String get settingsVersion           => 'Version';
  @override String get settingsWebVersion        => 'Web version';
  @override String get settingsWebVersionSub     => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode        => 'Source code';
  @override String get settingsSourceCodeSub     => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage          => 'Language';
  @override String get settingsAboutProjectDesc  => 'LastStats is a personal open-source project. It may contain bugs.';
  @override String get settingsAboutSupport      => 'Support the project';
  @override String get settingsAboutSupportSub   => '⭐ Leave a star on GitHub';

  @override String get headerNowPlaying  => 'Now playing';
  @override String get headerTopTrack    => 'Track #1';
  @override String get headerTopAlbum    => 'Album #1';
  @override String get headerTopArtist   => 'Artist #1';
  @override String get headerCustomImage => 'Custom image';
  @override String get headerThemeColor  => 'Theme color';
  @override String get headerAnimNone    => 'None';
  @override String get headerAnimFade    => 'Fade';
  @override String get headerAnimSlide   => 'Slide';
  @override String get headerAnimZoom    => 'Zoom';
  @override String get headerPeriodWeek  => 'Week';
  @override String get headerPeriodMonth => 'Month';
  @override String get headerPeriodAllTime => 'All time';

  @override String get colorPickerTitle       => 'Custom color';
  @override String get colorPickerHue         => 'Hue';
  @override String get colorPickerSaturation  => 'Saturation';
  @override String get colorPickerBrightness  => 'Brightness';
  @override String get colorPickerQuickColors => 'Quick colors';
  @override String get colorPickerInvalid     => 'Invalid format';
  @override String get colorCustomTooltip     => 'Custom';

  @override String get exportTitle       => 'Export settings';
  @override String get exportFilename    => 'File name';
  @override String get exportJsonContent => 'JSON content';
  @override String get exportInfo        => 'Copy this JSON, paste it into a text file and name it with .json';
  @override String get exportCopy        => 'Copy JSON';
  @override String get exportCopied      => 'Copied!';
  @override String get importTitle       => 'Restore a backup';
  @override String get importHintLabel   => 'Paste your LastStats backup here.';
  @override String get importEmpty       => 'Field is empty.';
  @override String get importInvalidJson  => 'Invalid JSON.';
  @override String get importUnknownFile  => 'Unrecognised file.';
  @override String get importInvalidFormat => 'Invalid format.';
  @override String get importSuccess     => 'Settings restored successfully ✓';
  @override String get importRestore     => 'Restore';

  @override String get setupImportJson      => 'Import JSON';
  @override String get setupImportHintLabel => 'Paste your JSON file content below.';
  @override String get setupImportNote      => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat    => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields   => 'Invalid JSON: missing "username" or "api_key" fields.';

  @override String get detailTracklist       => 'Tracks';
  @override String get detailAlbumLabel      => 'Album';
  @override String get detailDuration        => 'Duration';
  @override String get detailTopTracks       => 'Popular tracks';
  @override String get detailTopAlbums       => 'Popular albums';
  @override String get detailBioReadMore     => 'Read more';
  @override String get detailBioReadLess     => 'Show less';
  @override String get detailUserPlays       => 'plays';
  @override String get detailUserRank        => 'rank';
  @override String get detailUserRankNA      => 'N/A';
  @override String get detailGlobalListeners => 'listeners';
  @override String get detailPeriod          => 'Period';
  @override String get detailBiography       => 'Biography';
  @override String get detailGlobalListenersLabel => 'Listeners';
  @override String get dashPerWeek           => 'per week';
}

// ══════════════════════════════════════════════════════════════════════════
//  Accessor
// ══════════════════════════════════════════════════════════════════════════

const _fr = _AppStringsFr();
const _en = _AppStringsEn();

/// Returns the current [AppStrings] based on [localeNotifier].
AppStrings get L => localeNotifier.value == 'en' ? _en : _fr;