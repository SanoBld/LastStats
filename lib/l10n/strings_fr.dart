// lib/l10n/strings_fr.dart
// ══════════════════════════════════════════════════════════════════════════
//  French
// ══════════════════════════════════════════════════════════════════════════

import "app_strings.dart";

class AppStringsFr implements AppStrings {
  const AppStringsFr();

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

  @override String get cacheTitle                  => 'Stockage';
  @override String get cacheUsage                  => 'Utilisation';
  @override String get cacheLimit                  => 'Limite de stockage';
  @override String get cacheLimitHint              => 'Quand la limite est atteinte, les images les moins récentes sont supprimées automatiquement.';
  @override String get cacheClearSection           => 'Nettoyer';
  @override String get cacheImages                 => 'Images';
  @override String get cacheImagesSubtitle         => 'Artwork artistes, albums, titres';
  @override String get cacheApiData                => 'Données API';
  @override String get cacheApiDataSubtitle        => 'Top artistes, albums, écoutes récentes…';
  @override String get cacheScrobbles              => 'Historique scrobbles';
  @override String get cacheScrobblesSubtitle      => 'Toutes les écoutes téléchargées';
  @override String get cacheClearBtn               => 'Vider';
  @override String get cacheConfirmScrobblesTitle  => "Supprimer l'historique ?";
  @override String get cacheConfirmScrobblesBody   => 'L\'historique complet sera supprimé. Il sera rechargé au prochain démarrage.';
  @override String get cacheConfirmAllTitle        => 'Vider tout le cache ?';
  @override String get cacheConfirmAllBody         => 'Images, données API et historique seront supprimés.';
  @override String get cacheDelete                 => 'Supprimer';

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
  @override String get chartsMonthly           => 'Scrobbles (12 mois)';
  @override String get chartsArtistDist        => 'Top artistes (distribution)';
  @override String get chartsMainstreamTitle   => 'Mainstream vs Pépites';
  @override String get chartsMainstreamSubtitle => 'Popularité mondiale de vos artistes favoris.';
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
  @override String get searchHintProfiles => 'Recherchez un utilisateur Last.fm';
  @override String get searchHintArtists  => 'Recherchez un artiste';
  @override String get searchHintAlbums   => 'Recherchez un album';
  @override String get searchHintTracks   => 'Recherchez une chanson';
  @override String get searchTypePrompt   => 'Tapez dans la barre ci-dessus';
  @override String get searchAll          => 'Tout';
  @override String get searchFolders => 'Dossiers';
  @override String get searchFoldersHint => 'Créez un dossier pour ranger des titres, albums ou artistes.';
  @override String memberSince(String date) => 'Depuis $date';
  @override String get perDay             => 'par jour';
  @override String get activityDays       => 'jours actifs';

  @override String get dashStats           => 'Statistiques';
  @override String get dashTopTracks       => 'Top Titres';
  @override String get dashFriends         => 'Amis';
  @override String get dashRefresh         => 'Actualiser';
  @override String get dashRefreshFriends  => 'Actualiser les amis';
  @override String get dashScrobbles       => 'scrobbles';
  @override String get dashScrobblesPerDay => 'par jour';
  @override String get dashDaysActive      => 'jours actifs';
  @override String get dashLastTrack       => 'Dernière écoute';
  @override String get dashArtist1         => 'Artiste #1';
  @override String get dashAlbum1          => 'Album #1';
  @override String get dashTrack1          => 'Titre #1';
  @override String get dashNoFriends       => 'Aucun ami trouvé';
  @override String get dashResetCache      => 'Réinitialiser le cache';
  @override String get dashResetCacheConfirm => 'Toutes les données scrobbles mises en cache seront supprimées et retéléchargées depuis Last.fm.';

  @override String get dashFriendsActivity => "Activité de vos amis Last.fm";

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
  @override String get settingsDayNightAccent          => 'Accent jour/nuit';
  @override String get settingsDayNightAccentToggle    => 'Couleurs différentes jour/nuit';
  @override String get settingsDayNightAccentToggleSub => "Utilise une autre couleur d'accent pour le thème sombre.";
  @override String get settingsDayNightAccentDark      => 'Couleur (thème sombre)';
  @override String get settingsDayNightUseHours        => 'Utiliser des heures précises';
  @override String get settingsDayNightUseHoursSub     => "Change de couleur selon l'heure au lieu du thème actif.";
  @override String get settingsDayNightDayStart        => 'Début du jour';
  @override String get settingsDayNightNightStart      => 'Début de la nuit';
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
  @override String get settingsHeaderCustomUrlSub  => "Collez l'URL directe d'une image (jpg, png, webp…).";
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
  @override String get settingsFriendsSectionSub => 'Activité de vos amis Last.fm';
  @override String get settingsAccount           => 'Compte';
  @override String get settingsConnectedProfile  => 'Profil Last.fm connecté';
  @override String get settingsLogout            => 'Se déconnecter';
  @override String get settingsLogoutTitle       => 'Se déconnecter ?';
  @override String get settingsLogoutContent     => 'Vos identifiants seront supprimés.';
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
  @override String settingsUpdateBanner(String v) => 'Mise à jour v$v';
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
  @override String get settingsFaq               => 'FAQ';

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
  @override String get headerPeriodAllTime => 'Depuis toujours';

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
  @override String get setupImportHintLabel => 'Collez le contenu de votre fichier JSON ci-dessous.';
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
  @override String get detailUserPlays       => 'vos écoutes';
  @override String get detailGlobalPlays      => 'écoutes totales';
  @override String get detailUserRank        => 'classement';
  @override String get detailUserRankNA      => 'N/A';
  @override String get detailGlobalListeners => 'auditeurs';
  @override String get detailPeriod          => 'Période';
  @override String get detailBiography       => 'Biographie';
  @override String get detailGlobalListenersLabel => 'Auditeurs';
  @override String get detailTranslate       => 'Traduire';
  @override String get detailShowOriginal    => 'Voir l\'original';
  @override String get detailLyrics          => 'Paroles';
  @override String get detailLyricsNotFound  => 'Paroles non disponibles';
  @override String get detailCopyLyrics      => 'Copier les paroles';
  @override String get detailLyricsCopied    => 'Paroles copiées';

  @override String get detailShoutbox => 'Discussion Last.fm';
  @override String get detailShoutboxReply => 'Répondre';  @override String get dashPerWeek           => 'par semaine';

  @override String get onboardSkip             => 'Passer';
  @override String get onboardNext             => 'Suivant';
  @override String get onboardFinish           => 'Terminer';
  @override String get onboardBack             => 'Retour';
  @override String get onboardAppearanceTitle  => 'Personnalisez votre style';
  @override String get onboardAppearanceSub    => 'Thème, couleur d\'accent et Material You.';
  @override String get onboardNotifTitle       => 'Restez informé';
  @override String get onboardNotifSub         => 'Notifications et vibrations.';
  @override String get onboardFavTitle         => 'Vos profils favoris';
  @override String get onboardFavSub           => 'Ajoutez des amis Last.fm à retrouver rapidement.';
  @override String get onboardFavHint          => 'Nom d\'utilisateur Last.fm';
  @override String get onboardFavAdd           => 'Ajouter';
  @override String get onboardFavEmpty         => 'Aucun favori pour l\'instant';
  @override String get onboardFavSearchHint    => 'Rechercher un profil Last.fm…';
  @override String get onboardFavNoResults     => 'Aucun profil trouvé';
  @override String get onboardFavFriendsTitle  => 'Vos amis Last.fm';
  @override String get onboardFavNoFriends     => "Aucun ami trouvé sur ce compte";
  @override String get onboardFavSelected      => 'Favoris sélectionnés';
  @override String get onboardDashTitle        => 'Votre tableau de bord';
  @override String get onboardDashSub          => 'Choisissez les sections à afficher.';
  @override String get onboardStartupTitle     => 'Écran de démarrage';
  @override String get onboardStartupSub       => 'Quel onglet voir en premier ?';
  @override String get onboardPlatformTitle    => 'Vous écoutez sur quoi ?';
  @override String get onboardPlatformSub      => "Ça permet de n'afficher que les liens utiles sur les fiches morceau/artiste/album.";
  @override String get platformLastfm          => 'Last.fm';
  @override String get platformSpotify         => 'Spotify';
  @override String get platformYtMusic         => 'YouTube Music';
  @override String get platformOther           => 'Autre / tout afficher';
  @override String get settingsMusicPlatform          => 'Plateforme musicale';
  @override String get settingsMusicPlatformSub       => 'Filtre les liens affichés sur les fiches détail';
  @override String get settingsShowAllPlatformLinks    => 'Toujours tout afficher';
  @override String get settingsShowAllPlatformLinksSub => 'Ignore le filtre et montre tous les liens (Last.fm, Spotify, YT Music, Web)';
  @override String get onboardUpdatesTitle     => 'Mises à jour';
  @override String get onboardUpdatesSub       => 'Vérification automatique des nouvelles versions.';
  @override String get onboardStyle              => 'Style';
  @override String get onboardStyleMaterialYou    => 'Material You';
  @override String get onboardStyleNothing        => 'Nothing OS';
  @override String get onboardPreview             => 'Aperçu';
  @override String get onboardPreviewButton       => 'Bouton';
  @override String get onboardPreviewOutline      => 'Contour';
  @override String get onboardPreviewText         => 'Texte exemple';
  @override String get onboardPreviewBubble       => 'Bulle';
  @override String get onboardAccentTint          => 'Teinte d\'accent';
  @override String get onboardNothingRedOnly      => 'Rouge seul';
  @override String get onboardNothingRedYellow    => 'Rouge + jaune';
  @override String get onboardDisplay             => 'Affichage';
  @override String get onboardOledTitle           => 'Noir OLED';
  @override String get onboardOledSub             => 'Fond noir pur en mode sombre';
  @override String get onboardArtworkColorTitle   => 'Couleur depuis la pochette';
  @override String get onboardArtworkColorSub     => 'Adapter la couleur d\'accent à la pochette en cours de lecture';
  @override String get onboardNewsTitle           => 'Notifications d\'actualités';
  @override String get onboardNewsSub             => 'Soyez notifié des nouvelles fonctions et correctifs';
  @override String get onboardNewsBadgeTitle      => 'Pastille d\'actualités';
  @override String get onboardNewsBadgeSub        => 'Point rouge sur la cloche du dashboard s\'il y a du nouveau';
  @override String get onboardHapticTitle         => 'Retour haptique';
  @override String get onboardHapticSub           => 'Ressentez de légères vibrations sur les interactions clés';
  @override String get onboardRecaps              => 'Récapitulatifs';
  @override String get onboardDailyRecapTitle     => 'Récap quotidien';
  @override String get onboardDailyRecapSub       => 'Un résumé de votre écoute de la journée';
  @override String get onboardWeeklyRecapTitle    => 'Récap hebdomadaire';
  @override String get onboardWeeklyRecapSub      => 'Vos tops artistes, albums et titres de la semaine';
  @override String get onboardMilestonesSection   => 'Jalons de scrobbles';
  @override String get onboardMilestonesTitle     => 'Jalons';
  @override String get onboardMilestonesSub       => 'Célébrer les chiffres ronds de scrobbles';
  @override String get onboardGrandMilestonesTitle => 'Grands jalons';
  @override String get onboardGrandMilestonesSub   => 'Célébration spéciale pour les grands jalons';
  @override String get onboardDynamicColorSub      => 'Utiliser les couleurs de votre fond d\'écran (Android 12+)';
  @override String get onboardBetaTitle            => 'Mises à jour bêta';
  @override String get onboardBetaSub              => 'Accès anticipé aux pré-versions';

  @override String get notifDetailTitle            => 'Notification';
  @override String get notifDetailOpenLink         => 'Ouvrir le lien';

  @override String get settingsCheckingUpdates     => 'Vérification des mises à jour…';
  @override String get settingsTapToDownload       => 'Touchez pour télécharger';

  @override String get detailLookingForPreview     => "Recherche d'un extrait…";
  @override String get detailPreview30Sec          => 'Extrait · 30 sec';

  @override String get setupTagline                => 'Vos stats Last.fm, réinventées.';
  @override String get setupAnalyseProfile         => 'Analyser un profil';
  @override String get setupConnecting             => 'Connexion…';
  @override String get setupStartAnalysis          => "Lancer l'analyse";
  @override String get setupOr                     => 'ou';
  @override String setupWelcome(String username)   => 'Bienvenue, $username\u00a0!';
  @override String get setupUsernameLabel          => 'Pseudo Last.fm';
  @override String get setupApiKeyLabel            => 'Clé API Last.fm';
  @override String get setupApiKeyHint             => 'Clé hexadécimale de 32 caractères';
  @override String get setupApiKeyPrivacyNote      => 'Stockée localement. Jamais envoyée à un tiers.';
  @override String get setupRememberMe             => 'Se souvenir de moi';
  @override String get setupGetApiKey              => 'Obtenir une clé API gratuitement';
  @override String setupScrobblesToImport(String c) => '$c scrobbles à importer';
  @override String get setupWelcomeBanner          => 'Bienvenue sur LastStats\u00a0!';
  @override String get setupOneTimeImportNote      => 'Import unique, les prochains lancements seront instantanés.';

  @override String get dashTapToDownload           => 'Appuyez pour télécharger.';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      '${isBeta ? "Bêta" : "Nouvelle"} mise à jour : v$version';
  @override String get dashWeekLabel               => 'CETTE SEMAINE';
  @override String get dashMonthLabel              => 'CE MOIS';
  @override String get dashYearLabel               => 'CETTE ANNÉE';
  @override String get dashTopArtistLabel          => 'Artiste top';
  @override String get dashTopTrackLabel           => 'Titre top';
  @override String get dashScrobblesLabel          => 'Scrobbles';
  @override String get newsTypeFeatures            => 'Fonctions';
  @override String get newsTypeFixes               => 'Correctifs';
  @override String get newsTypeUpdates             => 'Mises à jour';
  @override String get newsTypeAlerts              => 'Alertes';
  @override String get newsTypeInfo                => 'Infos';
  @override String get newsWhatsNew                => 'Actualités';
  @override String newsItemsCount(int n)           => '$n ${n > 1 ? "éléments" : "élément"}';
  @override String get newsFilters                 => 'Filtres';
  @override String get newsAll                     => 'Tous';
  @override String get newsAnyDate                 => 'Toute date';
  @override String get newsNoNewsYet               => "Pas d'actualité pour le moment";
  @override String get settingsNotifications        => 'Notifications';
  @override String get settingsCache                 => 'Cache';
  @override String get settingsCardAppearanceSub     => 'Thème, accent, disposition, Material You';
  @override String get settingsCardDashboardSub      => 'Image d\'en-tête, sections visibles, cartes de stats';
  @override String get settingsCardStartupSub        => 'Onglet affiché au démarrage';
  @override String get settingsCardNotificationsSub  => 'Jalons, récaps quotidiens & hebdo';
  @override String get settingsSync                  => 'Synchronisation';
  @override String get settingsCardSyncSub           => 'Synchro auto des scrobbles en arrière-plan';
  @override String get settingsCardAccountSub        => 'Profil Last.fm connecté, déconnexion';
  @override String get settingsCardCacheSub          => 'Historique, images, données API';
  @override String get settingsCardBackupSub         => 'Exporter et restaurer vos paramètres';
  @override String get settingsCardUpdatesSub        => 'Vérifier les nouvelles versions';
  @override String get settingsCardAboutSub          => 'Version, code source, crédits';
  @override String get settingsCardFaqSub            => 'Scrobbling, plateformes, open source';
  @override String get settingsRestartNotice => "Certains paramètres nécessitent un redémarrage de l'app pour être pleinement appliqués.";
  @override String get syncPageTitle           => 'Synchronisation des scrobbles';
  @override String get syncAutoTitle           => 'Synchro automatique';
  @override String get syncAutoSubtitle        => "Synchronise l'historique en arrière-plan à intervalle régulier";
  @override String get syncFrequencyLabel      => 'Fréquence';
  @override String syncFrequencyHours(int h)   => 'Toutes les ${h}h';
  @override String get syncFrequencyDaily      => 'Une fois par jour';
  @override String get syncManualTitle         => 'Synchronisation manuelle';
  @override String get syncNowButton           => 'Synchroniser maintenant';
  @override String get syncInProgress          => 'Synchronisation en cours…';
  @override String get syncLastSyncLabel       => 'Dernière synchro';
  @override String get syncNeverLabel          => 'Jamais';
  @override String get syncTotalScrobblesLabel => 'Scrobbles en cache';
  @override String syncNewScrobblesFound(int n) => n == 0 ? 'Aucun nouveau scrobble' : '$n nouveau(x) scrobble(s) trouvé(s)';
  @override String get syncUpToDateMsg         => 'Historique à jour';
  @override String get syncNotifNote           => 'Une notification avec la progression s\'affiche pendant la synchro complète.';
  @override String get pcModeLayout      => 'Disposition';
  @override String get pcModeNavLayout   => 'Disposition de navigation';
  @override String get pcModeAuto        => 'Auto';
  @override String get pcModeSideRail    => 'Barre latérale';
  @override String get pcModeBottomBar   => 'Barre du bas';
  @override String get pcModeHintAuto    => 'Barre latérale sur grand écran (≥ 720 dp), barre du bas sur petit écran.';
  @override String get pcModeHintOn      => "Toujours utiliser la barre de navigation latérale, quelle que soit la taille de l'écran.";
  @override String get pcModeHintOff     => "Toujours utiliser la barre de navigation du bas, quelle que soit la taille de l'écran.";
  @override String get aboutTagline               => 'Votre compagnon de stats Last.fm';
  @override String get aboutAppInfo                => 'Infos';
  @override String get aboutScrobbleDownloader     => 'Téléchargeur de scrobbles';
  @override String get aboutScrobbleDownloaderSub  => 'Exporter tous vos scrobbles dans un fichier';
  @override String get aboutPoweredBy              => 'Propulsé par';
  @override String get aboutImageDisclaimer        => 'Les images des artistes, albums et titres sont récupérées automatiquement depuis ces sources et peuvent parfois être incorrectes ou ne pas correspondre au contenu réel.';
  @override String get aboutFooter                 => 'Fait avec ❤️ · Non affilié à Last.fm / CBS';

  @override String updatesPublishedOn(String date) => 'Publié le $date';
  @override String get updatesCurrentVersion       => 'Version actuelle';
  @override String get updatesBetaTitle            => 'Mises à jour bêta';
  @override String get updatesBetaSub              => 'Recevoir les versions pré-publiées en avant-première';

  @override String get backupWhatsIncluded         => 'Ce qui est inclus';
  @override String get backupDownloadFile          => 'Téléchargez un fichier .json';
  @override String get backupChooseFile            => 'Choisir un fichier de sauvegarde';
  @override String get backupFileSaved             => 'Sauvegarde enregistrée';
  @override String get backupFileSaveFailed        => "Échec de l'enregistrement";
  @override String get setupRestoreBackup          => 'Restaurer une sauvegarde';
  @override String get setupRestoreBackupSub       => "Retrouvez votre compte et vos réglages depuis un fichier de sauvegarde .json";
  @override String get backupRestoreKeysTitle => "Restaurer les clés API";
  @override String get backupRestoreKeysDesc => "Choisissez les clés Last.fm à restaurer depuis cette sauvegarde.";
  @override String get backupRestoreApiKeyLabel => "Clé API";
  @override String get backupRestoreSecretKeyLabel => "Clé secrète";
  @override String get backupIncludeFoldersLabel => 'Inclure les dossiers';
  @override String get backupIncludeFoldersDesc => 'Emportez vos dossiers de titres et leur contenu.';
  @override String get backupIncludeKeysDesc => "Inclure les clés dans le fichier exporté";

  @override String get backupIncludeThemesLabel => 'Exporter les thèmes';
  @override String get backupIncludeThemesDesc => 'Permet de partager juste l\'apparence (couleurs, style) avec quelqu\'un d\'autre.';

  @override String get backupAutoTitle => 'Sauvegarde automatique';
  @override String get backupAutoEnableLabel => 'Activer la sauvegarde automatique';
  @override String get backupAutoEnableDesc => 'Enregistre une sauvegarde toute seule, à l\'intervalle choisi ci-dessous.';
  @override String get backupAutoFreqLabel => 'Fréquence';
  @override String get backupAutoFreqDaily => 'Tous les jours';
  @override String get backupAutoFreqWeekly => 'Toutes les semaines';
  @override String get backupAutoFreqMonthly => 'Tous les mois';
  @override String get backupAutoFreqYearly => 'Tous les ans';
  @override String get backupAutoFolderLabel => 'Dossier de sauvegarde';
  @override String get backupAutoFolderDefault => 'Dossier par défaut de l\'application';
  @override String backupAutoNextLabel(String date) => 'Prochaine sauvegarde : $date';  @override String get backupIncludeScrobblesLabel => 'Inclure tout l\'historique';
  @override String get backupIncludeScrobblesDesc => 'Ajoutez tous vos titres écoutés depuis le début (peut être volumineux).';

  @override String get backupScrobblesSlowWarning => 'Cela peut prendre du temps et être moins rapide qu\'une sauvegarde normale.';  @override String backupExportedOn(String date) => 'Sauvegarde du $date';
  @override String get backupScrobblesErrorTitle => 'Erreur dans l\'historique';
  @override String get backupScrobblesErrorDesc => 'Certaines années de l\'historique semblent corrompues dans ce fichier. Que voulez-vous faire ?';
  @override String get backupScrobblesKeepAnyway => 'Continuer quand même';
  @override String get backupScrobblesCancel => 'Annuler l\'historique';
  @override String get backupScrobblesSkipRefetch => 'Ignorer et retélécharger en ligne';  @override String get settingsCrashLog => 'Journal d\'erreurs';
  @override String get backupCrashLogDesc => 'Enregistre les erreurs rencontrées par l\'app, utile pour signaler un bug.';
  @override String get backupCrashLogShare => 'Partager le journal';
  @override String get backupCrashLogClear => 'Vider le journal';
  @override String get backupCrashLogEmpty => 'Aucune erreur enregistrée';
  @override String get backupCrashLogCleared => 'Journal vidé';
  @override String get backupCrashLogClearConfirm => 'Vider le journal d\'erreurs ?';

  @override String get faqSectionLabel             => 'Questions fréquentes';
  @override String get backupOverwriteWarning => 'Restaurer une sauvegarde écrasera vos paramètres actuels.';
  @override String get faqOpenSourceBadge => 'LastStats est un projet gratuit et open source réalisé avec ❤️ par SanoBld.';
  @override String get cacheUnlimited     => 'Illimité';
  @override String get cacheTotalUsed     => 'Espace utilisé';
  @override String get cacheScrobblesShort => 'Historique';
  @override String get restartHintFeatures => "Certaines fonctionnalités nécessitent un redémarrage de l'app pour s'appliquer.";
  @override String get reorderCardsTitle   => 'Réordonner les cartes';
  @override String get commonSave          => 'Enregistrer';
  @override String get dashFallbackWhenNoMusic   => "Quand aucune musique n'est en cours";
  @override String get dashFallbackChooseDisplay => "Choisissez ce qui s'affiche en arrière-plan à la place";
  @override String get dashFallbackPeriodLabel   => 'Période de secours';
  @override String get fallbackPeriod1Week       => '1 semaine';
  @override String get fallbackPeriod1Month      => '1 mois';
  @override String get fallbackPeriodAllTime     => 'Tout le temps';
  @override String get fallbackTypeNothing       => 'Rien';
  @override String get fallbackTypeTopTrack      => 'Titre #1';
  @override String get fallbackTypeTopAlbum      => 'Album #1';
  @override String get fallbackTypeTopArtist     => 'Artiste #1';
  @override String get fallbackTypeCustomImage   => 'Image perso.';
  @override String fallbackWillShow(String detail) => 'Affichera : $detail';
  @override String get fallbackWillShowCustomUrl => "Affichera : URL d'image personnalisée";

  @override String get dashAnimationBlurSection  => 'Animation & Flou';
  @override String get dashMusicAnimationTitle   => 'Animation musique';
  @override String get dashMusicAnimationSub     => "Quand une musique joue, l'image se floute et bouge doucement, comme dans Apple Music.";
  @override String get dashMusicAnimationInfo    => "Le flou est appliqué automatiquement dans ce mode. Le curseur de flou ci-dessus n'a aucun effet pendant la lecture.";

  @override String get settingsTopAlbumsSection  => 'Top Albums';
  @override String get dashRecentPlaysLabel      => 'Écoutes récentes';
  @override String get dashStatCardsSectionLabel => 'Cartes de statistiques';
  @override String get dashStatCardsHeading      => 'Cartes de stats';
  @override String get dashStatCardsSub          => 'Choisissez les cartes affichées dans le bloc statistiques.';
  @override String get settingsDashboardChartSection => 'Graphique du dashboard';
  @override String get dashChartCalendarLabel => 'Calendrier musical';
  @override String get dashChartMonthlyLabel => 'Barres mensuelles';
  @override String get settingsDisplayNameSection => 'Nom personnalisé';
  @override String get settingsDisplayNameLabel => "Comment voulez-vous qu'on vous appelle ?";
  @override String get settingsDisplayNameHint => 'Ex. Sano Bld — laissez vide pour utiliser votre nom de compte';
  @override String get newsSearchHint => 'Rechercher dans les actualités…';
  @override String get aboutOpenSourceLibs => 'Bibliothèques open source';
  @override String get aboutOpenSourceLibsSub => "Tous les packages Flutter utilisés pour construire l'app.";
  @override String get aboutLicenseSection => 'Licence';
  @override String get aboutLicenseText => "Ce projet est publié sous licence MIT : libre à vous de l'utiliser, le modifier, le dupliquer ou le redistribuer, tant que vous me citez.";
  @override String get aboutLicenseLink => 'Voir la licence complète';
  @override String get languageAiNote => 'Les traductions ont été générées par IA et peuvent contenir des imprécisions.';
  @override String get aboutAiDevNote => "L'IA a aussi été utilisée pour le développement de cette app.";
  @override String get notifWorkManagerInfo => "Les notifications tournent en arrière-plan via WorkManager. L'app n'a pas besoin d'être ouverte. Une connexion internet est nécessaire.";
  @override String get notifIntervalTitle       => 'Tous les X scrobbles';
  @override String get notifIntervalSubtitle    => 'Notification à intervalle régulier';
  @override String get notifRecapsSection       => 'Récapitulatifs';
  @override String get notifDailyRecapSubtitle  => 'Scrobbles du jour + artiste favori';
  @override String get notifWeeklyRecapSubtitle => 'Scrobbles de la semaine + artiste favori';
  @override String get notifNewsSection         => 'Actualités';
  @override String get notifSyncSection         => 'Synchronisation';
  @override String get notifSyncTitle           => 'Notifications de synchro';
  @override String get notifSyncSubtitle        => "Alerte quand une synchro de l'historique se termine";
  @override String get notifSyncDetailTitle     => 'Détail de la progression';
  @override String get notifSyncDetailSubtitle  => "Afficher l'avancement (année en cours, compteur) pendant la synchro";
  @override String get notifNewsSubtitle        => 'Soyez notifié des nouveautés, correctifs et annonces';
  @override String get notifBadgeOnDashboard    => "Pastille sur l'accueil";
  @override String get notifBadgeSubtitle       => "Afficher le point rouge sur la cloche d'actualités";
  @override String get notifTestLabel           => 'Test';
  @override String get notifPermissionDisabledTitle => 'Notifications désactivées';
  @override String get notifPermissionDisabledBody  => 'Accordez la permission pour recevoir les alertes.';
  @override String get notifGrantPermission     => 'Autoriser';
  @override String get notifThresholdIntro      => 'Une notification spéciale à chacun de ces paliers :';
  @override List<String> get notifThresholdMessages => const [
    "Vos 1 000 premiers scrobbles. L'aventure commence. 🎵",
    'Vous passez les cinq chiffres ! 🎉',
    'Vous êtes un vrai accro à la musique. 🔥',
    'Un million de scrobbles. C\'est légendaire. 🎸',
  ];
  @override String get notifIntervalDescription => 'Envoyer une notification tous les X scrobbles';
  @override String get notifCustomValueLabel    => 'Valeur personnalisée';
  @override String get notifTimeNotifyAt        => 'Notifier à';
  @override String get notifDayOfWeek           => 'Jour de la semaine';
  @override List<String> get weekdaysShort => const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  @override List<String> get weekdaysNarrow => const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  @override String get weekAbbrev => 'S';
  @override String get notifSendTest            => 'Envoyer une notification test';
  @override String get notifSentCheckBar        => 'Vérifiez la barre de notifs !';
  @override String get notifMakeSureWorks       => 'Vérifiez que tout fonctionne.';
  @override String get notifSentBang            => 'Envoyé !';
  @override String get notifSendButton          => 'Envoyer';
  @override String get apVisualStyle             => 'Style visuel';
  @override String get apStyleDefault            => 'Défaut';
  @override String get apNothingAccentLabel      => 'Accent';
  @override String get apNothingClassic          => 'Classique';
  @override String get apRedOnlyDesc             => 'Rouge uniquement';
  @override String get apNothingMixed            => 'Mixte';
  @override String get apRedYellowDesc           => 'Rouge + touches jaunes';
  @override String get apNothingActiveBanner     => 'Style Nothing OS actif. Accent, couleur dynamique et couleur musicale sont désactivés.';
  @override String get apNothingOledInherent     => 'Le mode sombre Nothing est nativement OLED noir. Le réglage OLED est inutile.';
  @override String get apOledTitle               => 'Thème noir OLED';
  @override String get apOledBuiltIntoNothing    => 'Intégré au mode sombre Nothing';
  @override String get apOledPureBlack           => 'Fonds noirs purs quand le mode sombre est actif';
  @override String get apCustomColorTooltip      => 'Couleur personnalisée';
  @override String get apColorWhenNothingPlays   => 'Couleur quand rien ne joue';
  @override String get apColorWhenNothingPlaysSub => "Accent utilisé quand aucune piste n'est en cours";
  @override String get apKeepLastArtworkTitle    => 'Garder la dernière couleur';
  @override String get apKeepLastArtworkSub      => 'Conserver la couleur de la dernière pochette plutôt qu\'une image de secours';
  @override String get apDetailPagesSection      => 'Fiches détail';
  @override String get apArtworkColorTheme       => "Thème couleur de l'affiche";
  @override String get apBeta                    => 'BÊTA';
  @override String get apArtworkColorThemeSub    => "Les fiches adaptent leurs couleurs à la couleur dominante de l'affiche";
  @override String get apNavBarSection           => 'Barre de navigation';
  @override String get apShowTabLabels           => 'Afficher les libellés';
  @override String get apShowTabLabelsSub        => 'Afficher les noms des onglets sous les icônes';
  @override String get apInteractionsSection     => 'Interactions';
  @override String get apHapticFeedbackSub       => 'Vibrations sur les appuis, sélections et gestes';
  @override String get acctRemoveTitle          => 'Supprimer le compte ?';
  @override String acctRemoveBody(String username) => 'Supprimer @$username de vos comptes ?';
  @override String get acctRemoveAction         => 'Supprimer';
  @override String get acctAlreadyAddedOrFull   => 'Ce compte est déjà ajouté ou la liste est pleine.';
  @override String acctAddedSuccess(String username) => '@$username ajouté avec succès.';
  @override String get acctLogoutAllBody        => "Tous les comptes seront supprimés, vous retournerez à l'écran de configuration.";
  @override String acctMyAccounts(int count, int max) => 'Mes comptes ($count/$max)';
  @override String get acctActive               => 'Actif';
  @override String get acctTapSwitchToActivate  => 'Touchez "Activer" pour basculer';
  @override String get acctSwitch               => 'Activer';
  @override String get acctAddAnAccount         => 'Ajouter un compte';
  @override String acctSlotsRemaining(int n)    => '$n emplacement(s) restant(s)';
  @override String acctMaxReached(int max)      => 'Maximum de $max comptes atteint.';
  @override String get acctApiKeyInfo           => 'Chaque compte peut utiliser une clé API différente ou la même, vous la trouvez sur last.fm/api/accounts.';
  @override String get acctLastfmProfileSection => 'Profil Last.fm';
  @override String get acctViewOnLastfm         => 'Voir sur Last.fm';
  @override String get acctDangerZone           => 'Zone de danger';
  @override String get acctLogoutAllSub         => 'Supprimer tous les comptes et revenir à la configuration.';
  @override String get acctUsernameRequired     => 'Le pseudo est requis.';
  @override String get acctApiKeyRequired       => 'La clé API est requise.';
  @override String get acctUsernameLabel        => 'Pseudo Last.fm';
  @override String get acctSameApiKey           => 'Même clé API que le compte actif';
  @override String get acctApiKeyLabel          => 'Clé API';
  @override String get acctAdd                  => 'Ajouter';
  @override String get languageChangeNote => "La langue change immédiatement dans toute l'application.";
  @override String get dashTotalScrobblesLabel  => 'Total scrobbles';
  @override String get dashMemberSinceLabel     => 'Membre depuis';
  @override String get dashCountryLabel         => 'Pays';
  @override String get dashArtistWeekLabel      => 'Artiste #1 (semaine)';
  @override String get dashAlbumWeekLabel       => 'Album #1 (semaine)';
  @override String get dashTrackWeekLabel       => 'Titre #1 (semaine)';
  @override String get dashUniqueArtistsLabel   => 'Artistes uniques';
  @override String get dashUniqueTracksLabel    => 'Titres uniques';
  @override String get dashUniqueAlbumsLabel    => 'Albums uniques';
  @override String get dashThisWeekLabel        => 'Cette semaine';
  @override String get dashDayUnitShort         => 'j';
  @override String get setupEnableFavorites      => 'Activer les favoris (facultatif)';
  @override String get setupFavoritesExplain     => 'Votre clé secrète permet à l\'application de marquer des titres en favori (ou de les retirer) directement sur Last.fm.';
  @override String get setupSecretKeyLabel       => 'Clé secrète Last.fm';
  @override String get favConnectInvalidSecret   => 'La clé secrète doit faire 32 caractères.';
  @override String get favConnectDialogTitle     => 'Autoriser les favoris';
  @override String get favConnectDialogBody      => 'Autorisez l\'application sur la page Last.fm ouverte dans votre navigateur, puis revenez ici et confirmez.';
  @override String get favConnectDialogConfirm   => 'J\'ai autorisé';
  @override String get favConnectSuccess         => 'Favoris activés avec succès !';
  @override String get favConnectError           => 'Impossible d\'activer les favoris. Vérifiez votre clé secrète.';
  @override String get acctApiKeysSection        => 'Clés API';
  @override String get acctSecretKeyLabel        => 'Clé secrète';
  @override String get acctSecretKeyNotSet       => 'Non renseignée';
  @override String get acctFavoritesExplain      => 'La clé secrète permet de mettre en favori (ou retirer) des titres directement sur Last.fm.';
  @override String get acctConnectFavorites      => 'Activer les favoris';
  @override String get acctDisconnectFavorites   => 'Désactiver les favoris';
  @override String get settingsFavoritesSection    => 'Favoris';
  @override String get settingsFavoritesSectionSub => 'Affiche le nombre de favoris dans les statistiques';
  @override String get settingsFavoritesNeedsKey   => 'Ajoutez votre clé secrète dans Compte pour activer';
  @override String get favSectionTitle           => 'Favoris';
  @override String get commonSeeMore             => 'Voir plus';
  @override String get favPageTitle              => 'Mes favoris';
  @override String get favSearchHint             => 'Rechercher un titre ou un artiste';
  @override String get favEmpty                  => 'Aucun favori pour le moment.';
  @override String get settingsLovedBadgeTitle => 'Badge cœur discret';
  @override String get settingsLovedBadgeSub   => 'Affiche un petit cœur sur les titres favoris dans les écoutes récentes, l\'historique et la recherche';
  @override String get favSortRecent   => 'Récents';
  @override String get favSortOldest   => 'Anciens';
  @override String get favSortArtistAz => 'Artiste A-Z';
  @override String get favSortTitleAz  => 'Titre A-Z';
  @override String get favFolderSortCustom => 'Manuel';
  @override String get favFoldersAll => 'Tous';
  @override String get favFolderNew => 'Nouveau dossier';
  @override String get favFolderNamePlaceholder => 'Nom du dossier';
  @override String get favFolderCustomEmojiTitle => 'Choisissez un emoji';
  @override String get favFolderCustomEmojiHelper => 'Un seul emoji, pas de texte.';
  @override String get favFolderDescPlaceholder => 'Description (optionnel)';
  @override String get favFolderRecentlyPlayed => 'Écoutés récemment';
  @override String get favFolderCreate => 'Créer';
  @override String get favFolderEdit => 'Modifier le dossier';
  @override String get favFolderDelete => 'Supprimer';
  @override String get favFolderDeleteConfirm => 'Supprimer ce dossier ? Les titres n\'y seront plus rangés.';
  @override String get favFolderAssignTitle => 'Ranger dans un dossier';
  @override String get favFolderEmoji => 'Emoji';
  @override String get favFolderColor => 'Couleur';
  @override String get favFolderSave => 'Enregistrer';
  @override String get favFolderEmpty => 'Aucun titre dans ce dossier';
  @override String get rankingsWholeYear       => 'Toute l\'année';
  @override String get chartsExportGeneratedOn => 'généré le';
  @override String get faqQ1 => 'LastStats scrobble-t-il ma musique ?';
  @override String get faqA1 => 'Non. LastStats se contente d’afficher les scrobbles déjà enregistrés sur votre compte Last.fm, elle n’en enregistre aucun elle-même.\n\nPour scrobbler automatiquement votre musique, il vous faut une appli dédiée comme Pano Scrobbler (sur Android).';
  @override String get faqQ3 => 'L’application fonctionne-t-elle sur macOS ou d’autres plateformes ?';
  @override String get faqA3 => 'LastStats est développée et testée sur Android. Le fonctionnement sur les autres plateformes (macOS, Windows, Linux…) n’est pas garanti, des bugs ou comportements inattendus restent possibles.';
  @override String get faqQ4 => 'LastStats est-elle open source ?';
  @override String get faqA4 => 'Oui ! Le code source est en libre accès sur GitHub. C’est un projet indépendant, fait avec passion par SanoBld. Vous pouvez y contribuer, signaler un bug ou juste laisser une étoile ⭐.';
  @override String get faqQ5 => 'Où sont stockées mes données ?';
  @override String get faqA5 => 'Uniquement sur votre appareil. LastStats n’a pas de serveur, vos scrobbles sont mis en cache en local pour aller plus vite, et vos identifiants Last.fm restent aussi sur votre appareil. Rien n’est envoyé ailleurs qu’à l’API officielle de Last.fm.';
  @override String get faqQ6 => 'Comment activer les favoris ?';
  @override String get faqA6 => 'Allez dans Paramètres > Compte et renseignez votre clé secrète Last.fm (vous la trouvez à côté de votre clé API sur last.fm/api/accounts), puis suivez les étapes à l\'écran. Une fois connecté, vous pourrez ajouter des titres en favori directement depuis l\'application. Cette option n\'est pas disponible avec la clé interne de l\'application.';
  @override String get faqQ7 => 'C\'est quoi un \u00abscrobble\u00bb ?';
  @override String get faqA7 => 'Un scrobble, c\'est un titre enregistr\u00e9 comme \u00e9cout\u00e9 sur votre compte Last.fm, c\'est le terme officiel de Last.fm pour \u00abune \u00e9coute compt\u00e9e\u00bb. Tous vos totaux (top artistes, statistiques, etc.) sont bas\u00e9s dessus.';
  @override String get faqQ8 => 'Comment fonctionnent les niveaux et les succ\u00e8s ?';
  @override String get faqA8 => 'Votre niveau de compte augmente avec votre nombre total de scrobbles, il n\'y a pas de maximum. Les cartes affichent aussi une bordure (du bronze \u00e0 l\'iridescent) selon le nombre d\'\u00e9coutes de l\'artiste, du titre ou de l\'album concern\u00e9. Tout est calcul\u00e9 automatiquement \u00e0 partir de vos statistiques d\u00e9j\u00e0 en cache, sans requ\u00eate suppl\u00e9mentaire.';
  @override String get faqQ9 => 'Comment fonctionne le mode économie d\'énergie ?';
  @override String get faqA9 => 'Le mode économie d\'énergie espace les synchronisations automatiques pour économiser la batterie. Il peut s\'activer en permanence, avec le mode économie d\'énergie de votre téléphone, ou sous un niveau de batterie choisi, depuis Paramètres > Général.';
  @override String get faqQ10 => 'Comment sauvegarder ou restaurer mes données ?';
  @override String get faqA10 => 'Allez dans Paramètres > Sauvegarde. Vous pouvez exporter un fichier de sauvegarde, avec ou sans votre clé Last.fm selon votre choix, puis l\'importer plus tard sur ce téléphone ou sur un autre appareil pour retrouver vos réglages.';
  @override String get faqQ11 => 'L\'application fonctionne-t-elle hors ligne ?';
  @override String get faqA11 => 'Oui, dans une certaine mesure. Les statistiques déjà chargées restent consultables sans connexion grâce au cache local, mais une connexion reste nécessaire pour récupérer de nouveaux scrobbles.';
  @override String get faqQ12 => 'Puis-je changer de compte Last.fm ?';
  @override String get faqA12 => 'Oui, vous pouvez enregistrer jusqu\'à 3 comptes Last.fm. Depuis Paramètres > Compte, touchez « Ajouter un compte » puis passez de l\'un à l\'autre quand vous voulez. Le cache local est réinitialisé automatiquement lors du changement, pour que les données de deux comptes ne se mélangent jamais.';
  @override String get faqQ13 => 'Comment configurer les notifications ?';
  @override String get faqA13 => 'Depuis Paramètres > Notifications, vous pouvez activer une alerte à la fin de chaque synchronisation, choisir la fréquence des alertes, ou désactiver complètement les notifications si vous préférez.';
  @override String get faqQ14 => 'Les images manquent ou chargent sans fin. Que faire ?';
  @override String get faqA14 => 'Videz le cache dans l’application (Paramètres > Cache), puis dans Android (Paramètres > Applications > LastStats > Stockage > Vider le cache). Si les images manquent toujours, sauvegardez vos données (Paramètres > Sauvegarde), désinstallez puis réinstallez l’application, et restaurez la sauvegarde.';
  @override String get settingsPlatformDisabledByShowAll => 'Choix désactivé : tous les liens sont déjà affichés.';
  @override String get commonInDevelopment => 'En développement';
  @override String get commonSeeLess => 'Voir moins';
  @override String get commonShare => 'Partager';
  @override String get newsCustomDate => 'Date personnalisée';
  @override String get aboutShortcuts => 'Raccourcis clavier';
  @override String get aboutShortcutsSub => 'Disponibles sur PC / grand écran';
  @override String get shortcutSwitchTabs => 'Changer d’onglet';
  @override String get shortcutSearch => 'Rechercher';
  @override String get shortcutClose => 'Fermer une fiche';
  @override String get shortcutRefresh => 'Actualiser';
  @override String get aboutDiscord => 'Rejoindre le Discord';
  @override String get aboutDiscordSub => 'Échange, suggestions et annonces en direct';
  @override String get achvTitle => 'Succès';
  @override String achvUnlocked(int unlocked, int total) => '$unlocked / $total débloqués';
  @override String get achvCatListening => 'Écoute';
  @override String get achvCatArtists => 'Artistes';
  @override String get achvCatAlbums => 'Albums';
  @override String get achvCatLoyalty => 'Fidélité';
  @override String get achvDescListening => 'Total de titres écoutés (scrobbles), tous artistes confondus.';
  @override String get achvDescArtists => "Nombre d'artistes différents écoutés au moins une fois.";
  @override String get achvDescAlbums => "Nombre d'albums différents écoutés au moins une fois.";
  @override String get achvDescLoyalty => 'Ancienneté du compte Last.fm.';
  @override String get achvCatTracks => 'Titres';
  @override String get achvDescTracks => 'Nombre de titres différents (distincts) écoutés.';
  @override String get achvCatPace => 'Rythme';
  @override String get achvDescPace => "Moyenne d'écoutes par semaine.";
  @override String get achvCatStreak => 'Assiduité';
  @override String get achvDescStreak => "Plus longue série de jours d'affilée avec au moins une écoute.";
  @override String get achvCatMarathon => 'Marathon';
  @override String get achvDescMarathon => "Le plus grand nombre d'écoutes en une seule journée.";
  @override String get achvCatSocial => 'Social';
  @override String get achvDescSocial => "Le nombre d'amis ou de profils ajoutés.";
  @override String get achvCatComparisons => 'Comparaisons';
  @override String get achvDescComparisons => 'Le nombre de comparaisons de goûts musicaux effectuées.';
  @override String get achvUnlockedBadge => 'Débloqué';
  @override String get achvLockedBadge => 'Verrouillé';
  @override String get dashRecap => 'Récap';
  @override String get recapDay => 'Aujourd\'hui';
  @override String get recapWeek => 'Cette semaine';
  @override String get recapMonth => 'Ce mois-ci';
  @override String get recapScrobbles => 'écoutes';
  @override String get recapArtists => 'Artistes';
  @override String get recapTracks => 'Titres';
  @override String get recapTopArtist => 'Artiste top';
  @override String get recapTopTrack => 'Titre top';
  @override String get recapTopAlbum => 'Album top';
  @override String get recapAvgDay => 'Moy/jour';
  @override String get recapNoData => 'Aucune écoute pour cette période.';
  @override String get recapSeeFull => 'Voir le récap complet';
  @override String get recapTop10 => 'Top 10';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => 'Filtre le plus utile en premier';
  @override String get discoverSmartSub => 'Selon l\'heure, le jour et ce que vous écoutez le plus';
  @override String get discoverForYou => 'Pour vous';
  @override String get discoverGlobalTrends => 'Tendances mondiales';
  @override String get discoverSrcForyou => 'Votre mix';
  @override String get discoverSrcOnthisday => 'Ce jour-là';
  @override String get discoverSrcFresh => 'Ce mois-ci';
  @override String get discoverSrcGenre => 'Vos genres';
  @override String get discoverSrcDeeper => 'Titres cachés';
  @override String get discoverSrcForgotten => 'Oubliés';
  @override String get discoverSrcAlbums => 'Albums';
  @override String get discoverSrcCountry => 'Votre pays';
  @override String get discoverTracks => 'Titres';
  @override String get discoverArtists => 'Artistes';
  @override String get discoverWeek => 'semaine';
  @override String get discoverMonth => 'mois';
  @override String get discoverYear => 'année';
  @override String get discoverNothing => 'Rien à afficher pour l\'instant';
  @override String discoverLike(String names) => 'Comme $names';
  @override String get dashReorderSections => 'Changer l\'ordre des sections';
  @override String get dashInfiniteTitle => 'Défilement infini';
  @override String get dashInfiniteSub => 'Découvrir tourne en boucle et propose toujours plus d\'idées';
  @override String get dashDiscoverTitle => 'Découvrir';
  @override String get dashDiscoverSub => 'Des idées de musique à faire défiler';
  @override String get dashSortButton => 'Trier';
  @override String get dashSortDone => 'Terminé';
  @override String get dashSortHint => 'Glissez pour changer l\'ordre';
  @override String get dashSortSmartNote => 'Le tri intelligent est activé, il peut donc changer cet ordre selon le moment.';
  @override String get dashSeparateRow => 'Sur sa propre ligne';
  @override String dashFiltersOf(String group) => 'Filtres de « $group »';
  @override String get apShapeSingle => 'Une seule forme';
  @override String get mvSource => 'Source vidéo';
  @override String get mvSrcAuto => 'Auto (Apple Music, puis YouTube)';
  @override String get mvSrcApple => 'Apple Music seulement';
  @override String get mvSrcYt => 'YouTube seulement (titres)';
  @override String get mvQualityT => 'Qualité vidéo';
  @override String get mvQAuto => 'Auto';
  @override String get mvQLow => 'Économie (360p)';
  @override String get mvTypesT => 'Afficher la vidéo pour';
  @override String get mvTracks => 'Titres';
  @override String get mvAlbums => 'Albums';
  @override String get mvArtists => 'Artistes';
  @override String get mvModeT => 'Mode';
  @override String get mvModeBest => 'Recommandé';
  @override String get mvModeSaver => 'Économie';
  @override String get mvModeMax => 'Qualité max';
  @override String get mvModeCustom => 'Personnalisé';
  @override String get mvSrcYtFirst => 'YouTube, puis Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => 'Services utilisés, quotas et consommation';
  @override String get apiSumToday => 'Requêtes aujourd\'hui';
  @override String get apiSumErrors => 'Erreurs';
  @override String get apiSumLimited => 'Limitées';
  @override String get apiIntro => 'Les compteurs ne concernent que cet appareil. Les fournisseurs appliquent leurs limites par adresse IP : les autres applications du même réseau comptent aussi. L\'app ralentit ou ignore automatiquement des requêtes pour rester dans ces limites.';
  @override String get apiCatListening => 'Données d\'écoute';
  @override String get apiCatMetadata => 'Métadonnées musicales';
  @override String get apiCatArtwork => 'Pochettes';
  @override String get apiCatLyrics => 'Paroles';
  @override String get apiCatTranslate => 'Traduction';
  @override String get apiCatUpdates => 'Mises à jour et actus';
  @override String get apiCatOther => 'Téléchargements d\'images';
  @override String get apiStatusIdle => 'Pas encore utilisée';
  @override String get apiStatusOk => 'OK';
  @override String get apiStatusNear => 'Proche de la limite';
  @override String get apiStatusPaused => 'En pause';
  @override String get apiProviderLimit => 'Limite du fournisseur';
  @override String get apiNoLimit => 'Aucune publiée';
  @override String get apiAppCeiling => 'Plafond de l\'app';
  @override String apiLimitPer(int n, String win) => '$n requêtes / $win';
  @override String get apiWinSecond => 'seconde';
  @override String get apiWinMinute => 'minute';
  @override String get apiWinHour => 'heure';
  @override String apiWinSeconds(int s) => '$s secondes';
  @override String get apiWindowUsage => 'Fenêtre en cours';
  @override String get apiRemaining => 'Restant';
  @override String apiResetsIn(String t) => 'Réinitialisation dans $t';
  @override String apiPausedFor(String t) => 'En pause pendant $t après une réponse de limite atteinte';
  @override String get apiToday => 'Aujourd\'hui';
  @override String get apiLastHour => 'Dernière heure';
  @override String get apiTotal => 'Total';
  @override String get apiRateLimited => 'Réponses de limite atteinte';
  @override String get apiSkipped => 'Ignorées par l\'app';
  @override String get apiLastCall => 'Dernier appel';
  @override String get apiNever => 'Jamais';
  @override String get apiNoKey => 'Aucune clé API requise';
  @override String get apiSharedKey => 'Clé de test publique partagée (offre gratuite)';
  @override String get apiUnofficial => 'Point d\'accès non officiel : aucun quota garanti, peut changer ou être bloqué sans préavis.';
  @override String get apiKeyInUse => 'Clé utilisée';
  @override String get apiOwnKey => 'Votre propre clé Last.fm';
  @override String apiBuiltinKey(int n, int total) => 'Clé intégrée $n sur $total';
  @override String get apiBackupOn => 'Clé de secours : activée';
  @override String get apiBackupOff => 'Clé de secours : désactivée';
  @override String get apiPerKey => 'Requêtes par clé (aujourd\'hui / total)';
  @override String get apiLastfmNote => 'Last.fm ne publie aucun chiffre : il renvoie l\'erreur 29 quand une IP envoie trop de requêtes, et ses conditions interdisent de contourner cette limite. Environ 5 requêtes par seconde par IP est la valeur habituelle ; l\'app reste sous 4.';
  @override String get apiStorageTitle => 'Données Last.fm stockées';
  @override String apiStorageValue(String used, String cap) => '$used sur $cap autorisés';
  @override String get apiStorageOver => 'Au-dessus de la limite de 100 Mo fixée par les conditions de l\'API Last.fm. Videz l\'historique des scrobbles dans Stockage pour être conforme.';
  @override String get apiReset => 'Réinitialiser les compteurs';
  @override String get apiLimiter => 'Limiter les requêtes';
  @override String get apiLimiterSub => 'Ralentit les requêtes pour rester sous les quotas des API. Désactivé = plus rapide, sans attente.';
  @override String get apiResetBody => 'Tous les compteurs de requêtes seront remis à zéro.';
  @override String get apiResetDone => 'Compteurs réinitialisés';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (fr) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxFr = {
  'st_notif_on': 'Notifications activées',
  'st_notif_off': 'Notifications désactivées',
  'st_notif_count': '{n} types actifs',
  'st_notif_perm': 'Autorisation du système requise',
  'st_notif_none': 'Aucun type de notification choisi',
  'st_sync_on': 'Synchronisation automatique activée',
  'st_sync_off': 'Synchronisation automatique désactivée',
  'st_sync_on_s': 'Vos données se mettent à jour toutes seules.',
  'st_sync_off_s': 'Les données ne se mettent à jour que sur demande.',
  'st_bkp_on': 'Sauvegarde automatique activée',
  'st_bkp_off': 'Sauvegarde automatique désactivée',
  'st_bkp_on_s': 'Vos réglages sont sauvegardés automatiquement.',
  'st_bkp_off_s': 'Activez-la pour ne jamais perdre vos réglages.',
  'st_bkp_next': 'Prochaine sauvegarde : {d}',
  'cmp_breakdown': 'Ce qui vous rapproche',
  'cmp_by_artists': 'Artistes',
  'cmp_by_genres': 'Genres',
  'cmp_by_tracks': 'Titres',
  'cmp_by_albums': 'Albums',
  'eco_on': 'Économie d\'énergie activée',
  'eco_off': 'Économie d\'énergie désactivée',
  'eco_why_manual': 'Activée en permanence, par vos soins',
  'eco_why_system': 'L\'économiseur de batterie de votre appareil est activé',
  'eco_why_battery': 'La batterie est à {n} %',
  'eco_off_hint': 'Choisissez ci-dessous quand l\'activer',
  'eco_trig': 'Quand l\'activer',
  'eco_sys_t': 'Quand l\'économiseur de batterie de l\'appareil est activé',
  'eco_sys_s': 'Suit le mode économie d\'énergie natif de votre téléphone et se désactive avec lui.',
  'eco_sys_na': 'Indisponible sur cet appareil.',
  'eco_chg': 'Ce qui change',
  'eco_chg1': 'Le parallaxe au mouvement est désactivé',
  'eco_chg2': 'La fréquence de l\'écran est limitée à environ 60 Hz',
  'eco_chg3': 'Les mises à jour en arrière-plan sont moins fréquentes',
  'eco_chg4': 'Les pochettes animées et les reflets des badges sont en pause',
  'eco_chg_note': 'Tout le reste garde sa pleine qualité : images, exports et cartes de partage.',
  'lib_section': 'Bibliothèque',
  'lib_merge_t': 'Lier les versions d\'un même titre',
  'lib_merge_s': 'Remaster, single, (feat. …), édition deluxe : comptés comme un seul titre ou album, écoutes additionnées. Les remix, lives et instrumentaux restent séparés.',
  'lib_split_t': 'Séparer les collaborations',
  'lib_split_s': '« Gims & Damso » compte pour Gims et pour Damso au lieu d\'être un artiste à part. Les groupes comme « Simon & Garfunkel » restent entiers.',
  'lib_step_t': 'Votre bibliothèque',
  'lib_step_s': 'Choisissez comment regrouper vos écoutes. Vous pouvez changer cela à tout moment dans les réglages.',
  'bk_dash_t': 'Tableau de bord et démarrage',
  'bk_dash_s': 'Sections, en-tête, cartes de stats, découverte, onglet de démarrage',
  'bk_notif_t': 'Notifications',
  'bk_notif_s': 'Récaps, jalons, actualités et pastilles',
  'bk_lib_t': 'Options de bibliothèque',
  'bk_lib_s': 'Lier les versions d\'un titre, séparer les collaborations',
  'bk_prof_t': 'Profils favoris',
  'bk_prof_s': 'Les profils Last.fm que vous avez mis en favori',
  'about_readme_t': 'README et activité du projet',
  'about_readme_s': 'Lire le README, derniers commits, workflows, version, téléchargements',
  'fold_show': 'Afficher ({n})',
  'fold_hide': 'Réduire',
  'readme_sub': 'Le projet et son activité',
  'readme_version': 'Version',
  'readme_downloads': 'Téléchargements',
  'readme_stars': 'Étoiles',
  'readme_license': 'Licence',
  'readme_commits': 'Derniers commits',
  'readme_workflows': 'Derniers workflows',
  'readme_retry': 'Réessayer',
  'readme_github': 'Ouvrir sur GitHub',
  'readme_failed': 'Impossible de charger (hors ligne ou limite GitHub atteinte).',
  'ago_min': 'il y a {n} min',
  'ago_h': 'il y a {n} h',
  'ago_d': 'il y a {n} j',
  'load_restored': '{n} scrobbles restaurés',
  'load_ready': 'Prêt à importer',
  'load_connecting': 'Connexion à Last.fm…',
  'load_done': 'Import terminé',
  'load_backup_note': 'Sauvegarde détectée : seuls les scrobbles plus récents seront vérifiés.',
  'dash_nowplay': 'En cours d\'écoute',
  'dash_stats': 'Statistiques',
  'dash_recent': 'Écoutes récentes',
  'dash_discover': 'Découverte',
  'dash_friends': 'Amis',
  'dash_chart': 'Graphique du tableau de bord',
  'dash_calendar': 'Calendrier',
  'dash_monthly': 'Mensuel',
  'cache_video_t': 'Vidéos animées (Apple Music)',
  'cache_video_s': 'Mémoire vidéo utilisée : {mem} · {players} lecteur(s) actif(s) · {links} lien(s) en mémoire',
  'cache_video_short': 'Vidéos animées',
  'cache_video_cleared': 'Mémoire vidéo libérée',
  'cache_memory_section': 'Mémoire',
  'cache_storage_section': 'Stockage',
  'lvl': 'Niveau {n}',
  'lvl_history': 'Historique des niveaux',
  'set_living_t': 'Pochettes animées',
  'set_living_s': 'Zoom doux et effet de profondeur sur les images',
  'set_motion_t': 'Pochettes vidéo',
  'set_motion_s': 'Joue la pochette animée quand elle existe',
  'set_achv_t': 'Succès et niveaux',
  'set_achv_s': 'Paliers, badges et niveau de compte',
  'cache_img_limit_t': 'Limite du cache photos',
  'cache_img_limit_s': 'Pochettes, photos d\'artistes et avatars. Les plus anciennes sont supprimées en premier.',
  'cache_vid_limit_t': 'Limite du cache vidéo',
  'cache_vid_limit_s': 'Pochettes animées Apple Music gardées sur le disque pour les revoir hors ligne (Android).',
  'cache_video_off': 'Désactivé',
  'cache_vid_disk_t': 'Vidéos Apple Music',
  'cache_vid_disk_s': '{size} · Pochettes animées enregistrées',
  'cache_no_limit_note': 'Les scrobbles et les données API ne sont jamais limités.',
  'key_internal_use': 'Utiliser la clé interne de l\'application',
  'key_internal_help': 'Option de secours : cette clé est partagée entre les utilisateurs. Elle peut atteindre ses limites ou cesser de fonctionner, et certaines fonctions peuvent alors dysfonctionner. Préférez votre propre clé lorsque c\'est possible.',
  'key_internal_active': 'Clé interne de l\'application',
  'key_fallback_title': 'Clé interne en secours',
  'key_fallback_sub': 'Votre clé est utilisée en priorité. Si Last.fm la refuse, l\'application réessaie automatiquement avec la clé interne.',
  'key_use_own': 'Utiliser ma propre clé API',
  'key_change_title': 'Changer de clé API',
  'key_change_sub': 'Remplacez votre clé par une autre, ou passez à la clé interne de l\'application.',
  'key_change_sub_internal': 'Vous utilisez la clé partagée de l\'application. Ajoutez votre propre clé pour ne plus dépendre des limites des autres utilisateurs.',
  'key_change_intro': 'Saisissez une nouvelle clé API pour ce compte, ou revenez à la clé interne de l\'application. Votre nom d\'utilisateur et vos statistiques ne changent pas.',
  'key_change_intro_internal': 'Ce compte utilise actuellement la clé interne de l\'application. Collez ci-dessous votre propre clé API Last.fm pour la remplacer. Votre nom d\'utilisateur et vos statistiques ne changent pas.',
  'key_change_hint': 'Une clé API fait 32 caractères. Vous pouvez la créer ou la retrouver sur last.fm/api/accounts.',
  'key_change_invalid_len': 'Une clé API doit contenir exactement 32 caractères. Vérifiez que vous l\'avez copiée en entier.',
  'key_change_same': 'Ce compte utilise déjà cette clé. Saisissez-en une différente.',
  'key_change_check_failed': 'Last.fm n\'a pas accepté cette clé. Vérifiez qu\'elle est correcte et que vous êtes connecté à Internet, puis réessayez.',
  'key_change_favorites_warn': 'La connexion aux favoris sera retirée, car elle dépend de l\'ancienne clé. Vous pourrez la reconnecter ensuite avec votre clé secrète.',
  'key_change_apply': 'Appliquer',
  'key_change_success': 'La clé API a bien été mise à jour.',
  'key_internal_fav_note': 'Les favoris nécessitent votre propre clé API et votre clé secrète Last.fm. Ajoutez votre clé ci-dessus pour pouvoir les activer.',
  'faq_q15': 'Puis-je changer ma clé API après la connexion ?',
  'faq_a15': 'Oui. Allez dans Paramètres > Compte, puis touchez « Changer de clé API ». Vous pouvez remplacer votre clé par une autre, ou ajouter la vôtre si vous aviez choisi la clé interne au départ. Vos statistiques restent les mêmes, seule la connexion aux favoris doit être refaite.',
  'nothing_wip_badge': 'En cours d\'amélioration',
  'nothing_wip_msg': 'Le style Nothing OS est en cours d\'amélioration, il n\'est donc pas disponible pour le moment. Il pourra être activé dans une prochaine version.',
  'ui_play_preview': 'Écouter l\'extrait',
  'ntf_test_title': '🔔 Notification de test',
  'ntf_test_body': 'Les notifications LastStats fonctionnent !',
  'ui_not_enough_data_yet_sy': 'Pas encore assez de données — synchronisez votre historique complet dans les réglages.',
  'ui_level': 'Niveau {level}',
  'ui_fetching': 'Récupération de {currentYea}… ({yearIndex}/{totalYears})',
  'ui_which_chart': 'Quel graphique ?',
  'ui_which_period': 'Quelle période ?',
  'ui_all_time': 'Tout le temps',
  'ui_exporting': 'Export en cours…',
  'ui_chart_not_available_fo': 'Graphique non disponible pour cette période',
  'ui_could_not_generate_the': 'Impossible de générer l\'image',
  'ui_error': 'Erreur',
  'ui_loading_history': 'Chargement de l\'historique{yearLabel}… {pct} %',
  'ui_charts_will_be_more_ac': 'Les graphiques seront plus précis une fois chargé.',
  'ui_load_the_full_history_': 'Chargez l\'historique complet pour accéder à toutes les années.',
  'ui_load': 'Charger',
  'ui_based_on_scrobbles_all': 'Basé sur {v_hourlyCou} scrobbles (toutes les années)',
  'ui_all_available_years': 'Toutes les années disponibles',
  'ui_based_on_scrobbles_fro': 'Basé sur {v_hourlyCou} scrobbles de {v_selectedY}',
  'ui_based_on_recent_scrobb': 'Basé sur {v_hourlyCou} scrobbles récents',
  'ui_analysing_your_last_20': 'Analyse vos ~200 derniers scrobbles',
  'ui_all_time_loading': 'All-time (données {v_selectedY} en cours)',
  'ui_all_time_2': 'All-time',
  'ui_export_a_chart': 'Exporter un graphique',
  'ui_scrobble_progression': 'Progression des scrobbles',
  'ui_your_musical_genres': 'Vos genres musicaux',
  'ui_based_on_your_top_arti': 'Basé sur vos top artistes (all-time)',
  'ui_listening_habits': 'Habitudes d\'écoute',
  'ui_album_distribution': 'Répartition par album',
  'ui_listening_calendar': 'Calendrier musical',
  'ui_daily_activity_to': 'Activité journalière — {first} à {last}',
  'ui_daily_activity_all_yea': 'Activité journalière — toutes les années',
  'ui_daily_activity': 'Activité journalière — {v_selectedY}',
  'ui_load_history_to_see': 'Chargez l\'historique pour voir {v_selectedY}',
  'ui_daily_activity_last_12': 'Activité journalière — 12 mois',
  'ui_all_years': 'toutes les années',
  'ui_listening_streaks': 'Séries d\'écoute',
  'ui_total': 'Total',
  'ui_avg_mo': 'Moy./mois',
  'ui_best_month': 'Meilleur mois',
  'ui_hourly_distribution': 'Répartition horaire',
  'ui_activity_by_day_of_wee': 'Activité par jour de la semaine',
  'ui_current_streak': 'Série actuelle',
  'ui_d': 'j',
  'ui_best_streak': 'Meilleure série',
  'ui_best_streak_started_on': 'Meilleure série depuis le {bestStart}',
  'ui_no_data_for_this_perio': 'Aucune donnée pour cette période',
  'ui_load_history_to_displa': 'Chargez l\'historique pour afficher {what}',
  'ui_less': 'Moins',
  'ui_more': 'Plus',
  'ui_scan_a_profile': 'Scanner un profil',
  'ui_lvl': 'Niv. {level}',
  'ui_qr_code': 'QR code ?',
  'ui_add_a_qr_code_to_the_s': 'Ajouter un QR code à l’image partagée, pour que la personne qui la voit puisse scanner votre profil ?',
  'ui_no_qr': 'Sans QR',
  'ui_to_the_app': 'Vers l’app',
  'ui_to_last_fm': 'Vers Last.fm',
  'ui_compare_music_taste': 'Comparer les goûts musicaux',
  'ui_syncing_full_library': 'Synchronisation des données…',
  'ui_see_more': 'Voir plus',
  'ui_no_achievements_unlock': 'Aucun succès débloqué pour l’instant',
  'ui_no_animated_cover_for_': 'Pas de pochette animée pour cet album',
  'ui_source': 'Source : {source}',
  'ui_view_on_last_fm': 'Voir sur Last.fm',
  'ui_original_text_last_fm_': 'Texte original : Last.fm — Traduction : Google Translate',
  'ui_source_last_fm': 'Source : Last.fm',
  'ui_dark': 'Sombre',
  'ui_light': 'Clair',
  'ui_system': 'Système',
  'ui_colored_widgets': 'Widgets colorés',
  'ui_tint_home_screen_widge': 'Teinte les widgets de l\'écran d\'accueil avec l\'accent',
  'ui_search_settings': 'Rechercher un réglage…',
  'ui_no_settings_found': 'Aucun réglage trouvé',
  'ui_all': 'Toutes',
  'ui_battery_saver': 'Mode économie d\'énergie',
  'ui_save_battery_fewer_eff': 'Économiser la batterie, moins d\'effets',
  'ui_musical_soulmates': 'Âmes musicales sœurs',
  'ui_great_compatibility': 'Très belle compatibilité',
  'ui_some_common_ground': 'Quelques points communs',
  'ui_fairly_different_taste': 'Goûts plutôt différents',
  'ui_worlds_apart_musically': 'Univers musicaux opposés',
  'ui_this_is_your_own_profi': 'C\'est votre propre profil !',
  'ui_artists_from_your_hist': '{uniqueArti} artistes de votre historique · bibliothèque complète de {targetUser}',
  'ui_artists_from_your_hist_2': '{uniqueArti} artistes de votre historique · top 200 de {targetUser}',
  'ui_full_library_api': 'Bibliothèque complète (API)',
  'ui_top_200_artists_tracks': 'Top 200 artistes & titres (API)',
  'ui_could_not_work_out_the': 'Impossible de calculer la compatibilité.',
  'ui_music_compatibility': 'Compatibilité musicale',
  'ui_analyzing_musical_tast': 'Analyse des goûts musicaux…',
  'ui_artist': '{v_totalArti} artiste{v_totalArti2}',
  'ui_track': '{v_totalTrac} titre{v_totalTrac2}',
  'ui_album': '{v_totalAlbu} album{v_totalAlbu2}',
  'ui_shared_tracks': 'Titres en commun',
  'ui_shared_artists': 'Artistes en commun',
  'ui_no_shared_artists_foun': 'Aucun artiste en commun trouvé.',
  'ui_shared_albums': 'Albums en commun',
  'ui_play_count_unavailable': 'Décompte d\'écoutes indisponible pour l\'un des deux.',
  'ui_you_listen_to_this_x_m': 'Vous écoutez ça {x}x plus que {theirUsern}.',
  'ui_listens_to_this_x_more': '{theirUsern} écoute ça {x}x plus que vous.',
  'ui_you_both_listen_to_thi': 'Vous l\'écoutez à peu près autant tous les deux.',
  'ui_plays': '{plays} écoutes',
  'ui_compatibility': 'compatibilité',
  'ui_you_both_love': 'VOUS ADOREZ TOUS LES DEUX',
  'ui_shared_top_artist': 'ARTISTE PRÉFÉRÉ EN COMMUN',
  'ui_achievements': 'Succès',
  'ui_qr_not_recognized_not_': 'QR non reconnu — pas un profil LastStats/Last.fm',
  'ui_scan_a_profile_s_qr_co': 'Scannez un QR code de profil',
  'ui_favorites': 'Coups de cœur',
  'ui_advanced_youtube_music': 'Client YouTube Music avancé.',
  'ui_syncs_the_glyphs_of_no': 'Synchronise les Glyphs des téléphones Nothing à la musique.',
  'ui_sources': 'Sources',
  'ui_official_flutter_docs_': 'Doc officielle Flutter (widgets, thèmes, API).',
  'ui_official_material_3_gu': 'Guide officiel Material 3 pour développer avec Flutter.',
  'ui_flutter_api_reference_': 'Référence API Flutter pour le thème Material 3.',
  'ui_official_flutter_packa': 'Package Flutter officiel pour les layouts adaptatifs.',
  'ui_android_widgets': 'Widgets Android',
  'ui_applies_the_accent_col': 'Applique la couleur d\'accent au fond des widgets de l\'écran d\'accueil. Désactivé : blanc ou noir pur.',
  'ui_turns_off_tilt_paralla': 'Désactive le parallaxe au mouvement, plafonne le taux de rafraîchissement de l\'écran, et ralentit les mises à jour en arrière-plan — le reste garde sa pleine qualité (images, exports, cartes de partage).',
  'ui_always_on': 'Toujours activé',
  'ui_force_eco_mode_on_rega': 'Force le mode économie d\'énergie, quel que soit le niveau de batterie.',
  'ui_auto_activate': 'Activation automatique',
  'ui_turn_on_below_a_batter': 'Activer sous un % de batterie',
  'ui_switches_on_by_itself_': 'S\'active toute seule dès que la batterie atteint le niveau ci-dessous.',
  'ui_threshold': 'Seuil',
  'ui_choose_the_tab_display': 'Choisissez l\'onglet affiché au lancement de l\'app.',
  'ui_the_selected_tab_will_': 'L\'onglet sélectionné apparaîtra au prochain démarrage de l\'app.',
  'ui_friends_sync': 'Synchronisation des amis',
  'ui_sync_frequency': 'Fréquence de synchronisation',
  'ui_daily': 'Chaque jour',
  'ui_resync_everyone': 'Tout resynchroniser',
  'ui_version_history': 'Historique des versions',
  'ui_could_not_load_release': 'Impossible de charger l\'historique.',
  'ui_installed_dev_build_un': 'Installée : build de dev (version inconnue)',
  'ui_installed': 'Installée : {displayVer}',
  'ui_search_a_version_or_ch': 'Rechercher une version ou un changelog…',
  'ui_official': 'Officiel',
  'ui_no_release_matches_you': 'Aucune version ne correspond à votre recherche.',
  'ui_latest': 'DERNIÈRE',
  'ui_installed_2': 'INSTALLÉE',
  'ui_no_description': 'Aucune description.',
  'ui_download': 'Télécharger',
  'ui_view_release': 'Voir la release',
  'ui_details': 'Détails',
  'ui_all_past_releases_chan': 'Toutes les anciennes versions, changelogs et téléchargements',
  'ui_please_fill_both_field': 'Remplissez les deux champs.',
  'ui_api_key_must_be_32_cha': 'La clé API doit faire 32 caractères.',
  'ui_profile_not_found': 'Profil introuvable.',
  'ui_chart_monthly': 'Barres mensuelles',
  'ui_chart_cumul': 'Progression',
  'ui_chart_genres': 'Genres musicaux',
  'ui_chart_habits': 'Habitudes d\'écoute',
  'ui_chart_artists': 'Top artistes',
  'ui_chart_albums': 'Top albums',
  'ui_chart_calendar': 'Calendrier musical',
  'ui_chart_streaks': 'Séries d\'écoute',
  'ui_band_night': 'Nuit',
  'ui_band_morning': 'Matin',
  'ui_band_afternoon': 'Après-midi',
  'ui_band_evening': 'Soir',
  'qs_t1_t': 'Mode OLED',
  'qs_t1_s': 'Fond noir pur',
  'qs_t2_t': 'Mode économie d\'énergie',
  'qs_t2_s': 'Réduit l\'usage batterie',
  'qs_t3_t': 'Notifications actualités',
  'qs_t3_s': 'Alertes sur les nouveautés Last.fm',
  'qs_t4_t': 'Retour haptique',
  'qs_t4_s': 'Vibrations lors des interactions',
  'qs_t5_t': 'Succès',
  'qs_t5_s': 'Affiche les succès débloqués',
  'qs_l1_t': 'Couleur d\'accent',
  'qs_l2_t': 'Thème',
  'qs_l3_t': 'Langue',
  'qs_l4_t': 'Plateforme musicale',
  'qs_l5_t': 'Compte',
  'qs_l6_t': 'Synchronisation',
  'qs_l7_t': 'Cache',
  'img_src_lastfm': 'Source : Last.fm',
  'img_src_ytmusic': 'Source : YouTube Music',
  'img_src_itunes': 'Source : iTunes',
  'img_src_deezer': 'Source : Deezer',
  'img_src_audiodb': 'Source : TheAudioDB',
  'img_src_musicbrainz': 'Source : MusicBrainz',
  'img_src_wikipedia': 'Source : Wikipédia',
  'ds_type_artist': 'Artiste',
  'ds_type_album': 'Album',
  'ds_type_track': 'Titre',
  'pf_1': '👤 Profil utilisateur',
  'pf_2': '🎤 Top artistes — Global',
  'pf_3': '💿 Top albums — Global',
  'pf_4': '🎵 Top titres — Global',
  'pf_5': '⏱️ Écoutes récentes',
  'pf_6': '🗓️ Cette semaine',
  'pf_7': '📅 Ce mois-ci',
  'pf_8': '📅 3 derniers mois',
  'pf_9': '📅 6 derniers mois',
  'pf_10': '📅 12 derniers mois',
  'pf_11': '📊 Historique mensuel',
  'pf_12': '❤️ Titres aimés',
  'pf_13': '🗓️ Top artistes — Semaine',
  'pf_14': '🗓️ Albums & titres — Semaine',
  'ds_tier_next': '{n} / {next} pour le palier suivant',
  'ds_tier_max': 'Palier maximum atteint 🎉',
  'ds_tier_first': 'Écoutez ce titre pour débloquer un premier palier (dès {n} écoutes).',
  'sl_import': 'Import de vos données',
  'sl_done': 'Importé !',
  'sl_connect': 'Connexion à Last.fm…',
  'sec_chart': 'Graphique / calendrier',
  'stat_avg_day': 'Moy. / jour',
  'stat_avg_week': 'Moy. / semaine',
  'stat_days_active': 'Jours actifs',
  'stat_scrobbles_week': 'Scrobbles (semaine)',
  'accent_purple': 'Violet',
  'accent_blue': 'Bleu',
  'accent_green': 'Vert',
  'accent_red': 'Rouge',
  'accent_orange': 'Orange',
  'accent_pink': 'Rose',
  'accent_teal': 'Sarcelle',
  'accent_neutral': 'Neutre',
  'shape_title': 'Formes des images',
  'shape_covers': 'Pochettes, artistes et albums',
  'shape_mix': 'Mélange',
  'shape_square': 'Carré',
  'shape_circle': 'Cercle',
  'shape_pick_one': 'Ou choisissez une seule forme',
  'friend_listening': 'En écoute',
  'friend_offline': 'Hors ligne',
  'tier_none': 'Aucun palier',
  'src_title': 'Sources',
  'src_scrobbles_meta': 'Scrobbles et métadonnées',
  'src_artwork': 'Pochette',
  'src_audio_preview': 'Extrait audio',
  'src_video_artwork': 'Pochette animée',
  'tip_love': 'Ajouter aux favoris',
  'rail_expand': 'Agrandir la barre latérale',
  'rail_collapse': 'Réduire la barre latérale',
  'a11y_loading': 'Chargement',
  'bk_pick_folder': 'Choisir le dossier de sauvegarde auto',
  'bk_save_title': 'Enregistrer la sauvegarde LastStats',
  'bk_pick_file': 'Choisir un fichier de sauvegarde LastStats',
  'nch_milestone_d': 'Prévient quand vous atteignez un jalon de scrobbles',
  'nch_grand_d': 'Alertes spéciales pour les grands jalons (1K, 10K, 100K, 1M…)',
  'nch_recap_d': 'Résumés d’écoute quotidiens et hebdomadaires',
  'nch_update_d': 'Prévient quand une nouvelle version de LastStats est disponible',
  'nch_news_d': 'Nouveautés, correctifs et annonces concernant LastStats',
  'nch_sync_d': 'Progression de la synchronisation de tout votre historique',
  'ntf_grand_1000000': 'Un million de scrobbles. C’est légendaire. 🎸',
  'ntf_grand_500000': 'Un demi-million de scrobbles. Vous ne vous arrêtez jamais. 🎧',
  'ntf_grand_250000': '{n} scrobbles : la musique ne s’arrête jamais. 🎶',
  'ntf_grand_100000': '{n} scrobbles ! Vous êtes un vrai passionné de musique. 🔥',
  'ntf_grand_50000': '{n} scrobbles. Vraiment impressionnant. 🎵',
  'ntf_grand_25000': '{n} scrobbles et vous êtes toujours à fond !',
  'ntf_grand_10000': '{n} scrobbles : vous passez à cinq chiffres ! 🎉',
  'ntf_grand_5000': '{n} scrobbles, et ce n’est pas fini !',
  'ntf_grand_1000': 'Vos {n} premiers scrobbles. Le voyage commence. 🎵',
  'ntf_update_title': 'LastStats {v} disponible',
  'ntf_update_body': 'Une nouvelle version est prête à être téléchargée.',
  'ntf_milestone_title': '🎵 Jalon : {n} scrobbles',
  'ntf_milestone_body': 'Vous venez d’atteindre {n} scrobbles sur Last.fm 🎶',
  'ntf_daily_title': '📊 Récap du jour · {d}',
  'ntf_weekly_title': '📅 Récap de la semaine · {w}',
  'ntf_recap_body': '{n} scrobbles · Top : {a}',
  'ntf_n_today': '{n} scrobbles aujourd’hui',
  'ntf_n_week': '{n} scrobbles cette semaine',
  'ntf_top_artist': 'Artiste top : {a}',
  'ntf_update_avail': '🆕 Mise à jour disponible',
  'ntf_update_ready': 'LastStats {v} est prête — touchez pour voir.',
  'ntf_sync_title': '🔄 Synchronisation des scrobbles…',
  'ntf_sync_done': '✅ Scrobbles synchronisés',
  'ntf_sync_new': '{n} nouveau(x) scrobble(s) ajouté(s).',
  'ntf_grand_t': '{v} scrobbles !',
  'ntf_year': 'Année {y}',
  'ntf_week': 'Semaine {w}',
  'reorder': 'Réorganiser',
  'sp_login_t': 'Connexion à Spotify',
  'sp_login_hint': 'Connecte-toi avec ton e-mail et ton mot de passe Spotify. La fenêtre se ferme toute seule quand c\'est bon.',
  'sp_t': 'Spotify (Canvas)',
  'sp_off': 'Non connecté. Touche pour te connecter.',
  'sp_on': 'Connecté. Touche pour te déconnecter.',
  'sp_off_s': 'Déconnecté de Spotify',
  'sp_need': 'Spotify demande une connexion : connecte-toi dans les réglages.',
};
