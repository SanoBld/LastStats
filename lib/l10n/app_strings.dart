// lib/l10n/app_strings.dart
// ══════════════════════════════════════════════════════════════════════════
//  Abstract contract every language must implement.
//  Add a new key here, then implement it in every strings_xx.dart file.
// ══════════════════════════════════════════════════════════════════════════

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

  // ── Cache / Storage page ───────────────────────────────────────────────
  String get cacheTitle;
  String get cacheUsage;
  String get cacheLimit;
  String get cacheLimitHint;
  String get cacheOffline;
  String get cacheClearSection;
  String get cacheImages;
  String get cacheImagesSubtitle;
  String get cacheApiData;
  String get cacheApiDataSubtitle;
  String get cacheScrobbles;
  String get cacheScrobblesSubtitle;
  String get cacheClearBtn;
  String get cacheConfirmScrobblesTitle;
  String get cacheConfirmScrobblesBody;
  String get cacheConfirmAllTitle;
  String get cacheConfirmAllBody;
  String get cacheDelete;
  String get cacheOfflineTitle;
  String get cacheOfflineSubtitle;

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
  String get dashResetCache;
  String get dashResetCacheConfirm;

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
  String get settingsFaq;

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
  String get detailTranslate;
  String get detailShowOriginal;
  String get detailLyrics;
  String get detailLyricsNotFound;
  String get detailCopyLyrics;
  String get detailLyricsCopied;

  // ── Dashboard extra ─────────────────────────────────────────────────────────
  String get dashPerWeek;

  // ── Onboarding ───────────────────────────────────────────────────────────
  String get onboardSkip;
  String get onboardNext;
  String get onboardFinish;
  String get onboardBack;
  String get onboardAppearanceTitle;
  String get onboardAppearanceSub;
  String get onboardNotifTitle;
  String get onboardNotifSub;
  String get onboardFavTitle;
  String get onboardFavSub;
  String get onboardFavHint;
  String get onboardFavAdd;
  String get onboardFavEmpty;
  String get onboardFavSearchHint;
  String get onboardFavNoResults;
  String get onboardFavFriendsTitle;
  String get onboardFavNoFriends;
  String get onboardFavSelected;
  String get onboardDashTitle;
  String get onboardDashSub;
  String get onboardStartupTitle;
  String get onboardStartupSub;
  String get onboardPlatformTitle;
  String get onboardPlatformSub;
  String get platformLastfm;
  String get platformSpotify;
  String get platformYtMusic;
  String get platformOther;
  String get settingsMusicPlatform;
  String get settingsMusicPlatformSub;
  String get settingsShowAllPlatformLinks;
  String get settingsShowAllPlatformLinksSub;
  String get onboardUpdatesTitle;
  String get onboardUpdatesSub;
  String get onboardStyle;
  String get onboardStyleMaterialYou;
  String get onboardStyleNothing;
  String get onboardPreview;
  String get onboardPreviewButton;
  String get onboardPreviewOutline;
  String get onboardPreviewText;
  String get onboardPreviewBubble;
  String get onboardAccentTint;
  String get onboardNothingRedOnly;
  String get onboardNothingRedYellow;
  String get onboardDisplay;
  String get onboardOledTitle;
  String get onboardOledSub;
  String get onboardArtworkColorTitle;
  String get onboardArtworkColorSub;
  String get onboardNewsTitle;
  String get onboardNewsSub;
  String get onboardNewsBadgeTitle;
  String get onboardNewsBadgeSub;
  String get onboardHapticTitle;
  String get onboardHapticSub;
  String get onboardRecaps;
  String get onboardDailyRecapTitle;
  String get onboardDailyRecapSub;
  String get onboardWeeklyRecapTitle;
  String get onboardWeeklyRecapSub;
  String get onboardMilestonesSection;
  String get onboardMilestonesTitle;
  String get onboardMilestonesSub;
  String get onboardGrandMilestonesTitle;
  String get onboardGrandMilestonesSub;
  String get onboardDynamicColorSub;
  String get onboardBetaTitle;
  String get onboardBetaSub;

  // ── Notification detail ─────────────────────────────────────────────────
  String get notifDetailTitle;
  String get notifDetailOpenLink;

  // ── Settings page (update banner) ───────────────────────────────────────
  String get settingsCheckingUpdates;
  String get settingsTapToDownload;

  // ── Detail sheet (audio preview) ────────────────────────────────────────
  String get detailLookingForPreview;
  String get detailPreview30Sec;

  // ── Setup screen ─────────────────────────────────────────────────────────
  String get setupTagline;
  String get setupAnalyseProfile;
  String get setupConnecting;
  String get setupStartAnalysis;
  String get setupOr;
  String setupWelcome(String username);
  String get setupUsernameLabel;
  String get setupApiKeyLabel;
  String get setupApiKeyHint;
  String get setupApiKeyPrivacyNote;
  String get setupRememberMe;
  String get setupGetApiKey;
  String setupScrobblesToImport(String count);
  String get setupWelcomeBanner;
  String get setupOneTimeImportNote;

  // ── Dashboard: header hint + stat labels + news sheet ───────────────────
  String get dashTapToDownload;
  String dashUpdateTitle(String version, bool isBeta);
  String get dashWeekLabel;
  String get dashMonthLabel;
  String get dashYearLabel;
  String get dashTopArtistLabel;
  String get dashTopTrackLabel;
  String get dashScrobblesLabel;
  String get newsTypeFeatures;
  String get newsTypeFixes;
  String get newsTypeUpdates;
  String get newsTypeAlerts;
  String get newsTypeInfo;
  String get newsWhatsNew;
  String newsItemsCount(int n);
  String get newsFilters;
  String get newsAll;
  String get newsAnyDate;
  String get newsNoNewsYet;

  // ── Settings hub cards (main settings list) ─────────────────────────────
  String get settingsNotifications; // section title, was hardcoded 'Notifications'
  String get settingsCache;         // section title, was hardcoded 'Cache'
  String get settingsCardAppearanceSub;
  String get settingsCardDashboardSub;
  String get settingsCardStartupSub;
  String get settingsCardNotificationsSub;
  String get settingsSync;
  String get settingsCardSyncSub;
  String get settingsCardAccountSub;
  String get settingsCardCacheSub;
  String get settingsCardBackupSub;
  String get settingsCardUpdatesSub;
  String get settingsCardAboutSub;
  String get settingsCardFaqSub;
  String get settingsRestartNotice;

  // ── Scrobble sync page ───────────────────────────────────────────────────
  String get syncPageTitle;
  String get syncAutoTitle;
  String get syncAutoSubtitle;
  String get syncFrequencyLabel;
  String syncFrequencyHours(int h);
  String get syncFrequencyDaily;
  String get syncManualTitle;
  String get syncNowButton;
  String get syncInProgress;
  String get syncLastSyncLabel;
  String get syncNeverLabel;
  String get syncTotalScrobblesLabel;
  String syncNewScrobblesFound(int n);
  String get syncUpToDateMsg;
  String get syncNotifNote;

  // ── PC mode / navigation layout section ─────────────────────────────────
  String get pcModeLayout;
  String get pcModeNavLayout;
  String get pcModeAuto;
  String get pcModeSideRail;
  String get pcModeBottomBar;
  String get pcModeHintAuto;
  String get pcModeHintOn;
  String get pcModeHintOff;

  // ── About page ───────────────────────────────────────────────────────────
  String get aboutTagline;
  String get aboutAppInfo;
  String get aboutScrobbleDownloader;
  String get aboutScrobbleDownloaderSub;
  String get aboutPoweredBy;
  String get aboutImageDisclaimer;
  String get aboutFooter;

  // ── Updates page ─────────────────────────────────────────────────────────
  String updatesPublishedOn(String date);
  String get updatesCurrentVersion;
  String get updatesBetaTitle;
  String get updatesBetaSub;

  // ── Backup page ──────────────────────────────────────────────────────────
  String get backupWhatsIncluded;
  String get backupDownloadFile;
  String get backupChooseFile;
  String get backupFileSaved;
  String get backupFileSaveFailed;
  String get setupRestoreBackup;
  String get setupRestoreBackupSub;
  String get backupRestoreKeysTitle;
  String get backupRestoreKeysDesc;
  String get backupRestoreApiKeyLabel;
  String get backupRestoreSecretKeyLabel;
  String get backupIncludeKeysDesc;

  // ── FAQ page ─────────────────────────────────────────────────────────────
  String get faqSectionLabel;
  String get backupOverwriteWarning;
  String get faqOpenSourceBadge;
  String get cacheUnlimited;
  String get cacheTotalUsed;
  String get cacheScrobblesShort;
  String get restartHintFeatures;
  String get reorderCardsTitle;
  String get commonSave;

  // ── Dashboard settings: header fallback ─────────────────────────────────
  String get dashFallbackWhenNoMusic;
  String get dashFallbackChooseDisplay;
  String get dashFallbackPeriodLabel;
  String get fallbackPeriod1Week;
  String get fallbackPeriod1Month;
  String get fallbackPeriodAllTime;
  String get fallbackTypeNothing;
  String get fallbackTypeTopTrack;
  String get fallbackTypeTopAlbum;
  String get fallbackTypeTopArtist;
  String get fallbackTypeCustomImage;
  String fallbackWillShow(String detail);
  String get fallbackWillShowCustomUrl;

  // ── Dashboard settings: animation & blur ────────────────────────────────
  String get dashAnimationBlurSection;
  String get dashMusicAnimationTitle;
  String get dashMusicAnimationSub;
  String get dashMusicAnimationInfo;

  // ── Dashboard settings: sections & stat cards ───────────────────────────
  String get settingsTopAlbumsSection;
  String get dashRecentPlaysLabel;
  String get dashStatCardsSectionLabel;
  String get dashStatCardsHeading;
  String get dashStatCardsSub;

  // ── Notifications page ───────────────────────────────────────────────────
  String get notifWorkManagerInfo;
  String get notifIntervalTitle;
  String get notifIntervalSubtitle;
  String get notifRecapsSection;
  String get notifDailyRecapSubtitle;
  String get notifWeeklyRecapSubtitle;
  String get notifNewsSection;
  String get notifSyncSection;
  String get notifSyncTitle;
  String get notifSyncSubtitle;
  String get notifSyncDetailTitle;
  String get notifSyncDetailSubtitle;
  String get notifNewsSubtitle;
  String get notifBadgeOnDashboard;
  String get notifBadgeSubtitle;
  String get notifTestLabel;
  String get notifPermissionDisabledTitle;
  String get notifPermissionDisabledBody;
  String get notifGrantPermission;
  String get notifThresholdIntro;
  List<String> get notifThresholdMessages; // 4 entries: 1K, 10K, 100K, 1M
  String get notifIntervalDescription;
  String get notifCustomValueLabel;
  String get notifTimeNotifyAt;
  String get notifDayOfWeek;
  List<String> get weekdaysShort; // Mon..Sun order, 7 entries
  String get notifSendTest;
  String get notifSentCheckBar;
  String get notifMakeSureWorks;
  String get notifSentBang;
  String get notifSendButton;

  // ── Appearance page ──────────────────────────────────────────────────────
  String get apVisualStyle;
  String get apStyleDefault;
  String get apNothingAccentLabel;
  String get apNothingClassic;
  String get apRedOnlyDesc;
  String get apNothingMixed;
  String get apRedYellowDesc;
  String get apNothingActiveBanner;
  String get apNothingOledInherent;
  String get apOledTitle;
  String get apOledBuiltIntoNothing;
  String get apOledPureBlack;
  String get apCustomColorTooltip;
  String get apColorWhenNothingPlays;
  String get apColorWhenNothingPlaysSub;
  String get apKeepLastArtworkTitle;
  String get apKeepLastArtworkSub;
  String get apDetailPagesSection;
  String get apArtworkColorTheme;
  String get apBeta;
  String get apArtworkColorThemeSub;
  String get apNavBarSection;
  String get apShowTabLabels;
  String get apShowTabLabelsSub;
  String get apInteractionsSection;
  String get apHapticFeedbackSub;

  // ── Account page ─────────────────────────────────────────────────────────
  String get acctRemoveTitle;
  String acctRemoveBody(String username);
  String get acctRemoveAction;
  String get acctAlreadyAddedOrFull;
  String acctAddedSuccess(String username);
  String get acctLogoutAllBody;
  String acctMyAccounts(int count, int max);
  String get acctActive;
  String get acctTapSwitchToActivate;
  String get acctSwitch;
  String get acctAddAnAccount;
  String acctSlotsRemaining(int n);
  String acctMaxReached(int max);
  String get acctApiKeyInfo;
  String get acctLastfmProfileSection;
  String get acctViewOnLastfm;
  String get acctDangerZone;
  String get acctLogoutAllSub;
  String get acctUsernameRequired;
  String get acctApiKeyRequired;
  String get acctUsernameLabel;
  String get acctSameApiKey;
  String get acctApiKeyLabel;
  String get acctAdd;
  String get languageChangeNote;

  // ── Dashboard page: extra stat cards ────────────────────────────────────
  String get dashTotalScrobblesLabel;
  String get dashMemberSinceLabel;
  String get dashCountryLabel;
  String get dashArtistWeekLabel;
  String get dashAlbumWeekLabel;
  String get dashTrackWeekLabel;
  String get dashUniqueArtistsLabel;
  String get dashUniqueTracksLabel;
  String get dashUniqueAlbumsLabel;
  String get dashThisWeekLabel;
  String get dashDayUnitShort;

  // ── Favorites (loved tracks) ────────────────────────────────────────────
  String get setupEnableFavorites;
  String get setupFavoritesExplain;
  String get setupSecretKeyLabel;
  String get favConnectInvalidSecret;
  String get favConnectDialogTitle;
  String get favConnectDialogBody;
  String get favConnectDialogConfirm;
  String get favConnectSuccess;
  String get favConnectError;
  String get acctApiKeysSection;
  String get acctSecretKeyLabel;
  String get acctSecretKeyNotSet;
  String get acctFavoritesExplain;
  String get acctConnectFavorites;
  String get acctDisconnectFavorites;
  String get settingsFavoritesSection;
  String get settingsFavoritesSectionSub;
  String get settingsFavoritesNeedsKey;
  String get favSectionTitle;
  String get commonSeeMore;
  String get favPageTitle;
  String get favSearchHint;
  String get favEmpty;
  String get settingsLovedBadgeTitle;
  String get settingsLovedBadgeSub;
  String get favSortRecent;
  String get favSortOldest;
  String get favSortArtistAz;
  String get favSortTitleAz;
  String get rankingsWholeYear;
  String get chartsExportGeneratedOn;

  // ── FAQ ──────────────────────────────────────────────────────────────────
  String get faqQ1;
  String get faqA1;
  String get faqQ2;
  String get faqA2;
  String get faqQ3;
  String get faqA3;
  String get faqQ4;
  String get faqA4;
  String get faqQ5;
  String get faqA5;
  String get faqQ6;
  String get faqA6;
  String get settingsPlatformDisabledByShowAll;
  String get commonInDevelopment;
  String get commonSeeLess;
  String get commonShare;
  String get newsCustomDate;

  // ── Keyboard shortcuts (desktop) ────────────────────────────────────────
  String get aboutShortcuts;
  String get aboutShortcutsSub;
  String get shortcutSwitchTabs;
  String get shortcutSearch;
  String get shortcutClose;
  String get shortcutRefresh;
  String get aboutDiscord;
  String get aboutDiscordSub;
}