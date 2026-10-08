// lib/l10n/strings_en.dart
// ══════════════════════════════════════════════════════════════════════════
//  English
// ══════════════════════════════════════════════════════════════════════════

import "app_strings.dart";

class AppStringsEn implements AppStrings {
  const AppStringsEn();

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

  @override String get cacheTitle                  => 'Storage';
  @override String get cacheUsage                  => 'Usage';
  @override String get cacheLimit                  => 'Storage limit';
  @override String get cacheLimitHint              => 'When the limit is reached, least-recently-used images are deleted automatically.';
  @override String get cacheClearSection           => 'Clear';
  @override String get cacheImages                 => 'Images';
  @override String get cacheImagesSubtitle         => 'Artist, album, track artwork';
  @override String get cacheApiData                => 'API data';
  @override String get cacheApiDataSubtitle        => 'Top artists, albums, recent tracks…';
  @override String get cacheScrobbles              => 'Scrobble history';
  @override String get cacheScrobblesSubtitle      => 'All downloaded scrobble records';
  @override String get cacheClearBtn               => 'Clear';
  @override String get cacheConfirmScrobblesTitle  => 'Clear scrobble history?';
  @override String get cacheConfirmScrobblesBody   => 'The full history will be deleted and re-downloaded on next launch.';
  @override String get cacheConfirmAllTitle        => 'Clear all cache?';
  @override String get cacheConfirmAllBody         => 'Images, API data and scrobble history will all be deleted.';
  @override String get cacheDelete                 => 'Delete';

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
  @override String get chartsMonthly            => 'Scrobbles (12 months)';
  @override String get chartsArtistDist         => 'Top artists (breakdown)';
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
  @override String get searchFolders => 'Folders';
  @override String get searchFoldersHint => 'Create a folder to save tracks, albums or artists.';
  @override String memberSince(String date) => 'Since $date';
  @override String get perDay             => 'per day';
  @override String get activityDays       => 'active days';

  @override String get dashStats           => 'Stats';
  @override String get dashTopTracks       => 'Top Tracks';
  @override String get dashFriends         => 'Friends';
  @override String get dashRefresh         => 'Refresh';
  @override String get dashRefreshFriends  => 'Refresh friends';
  @override String get dashScrobbles       => 'scrobbles';
  @override String get dashScrobblesPerDay => 'per day';
  @override String get dashDaysActive      => 'active days';
  @override String get dashLastTrack       => 'Last played';
  @override String get dashArtist1         => 'Artist #1';
  @override String get dashAlbum1          => 'Album #1';
  @override String get dashTrack1          => 'Track #1';
  @override String get dashNoFriends       => 'No friends found';
  @override String get dashResetCache      => 'Reset cache';
  @override String get dashResetCacheConfirm => 'All locally cached scrobble data will be deleted and re-downloaded from Last.fm.';

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
  @override String get settingsDayNightAccent          => 'Day/night accent';
  @override String get settingsDayNightAccentToggle    => 'Different colors for day/night';
  @override String get settingsDayNightAccentToggleSub => 'Uses a different accent color for the dark theme.';
  @override String get settingsDayNightAccentDark      => 'Color (dark theme)';
  @override String get settingsDayNightUseHours        => 'Use specific hours';
  @override String get settingsDayNightUseHoursSub     => 'Switches color by time of day instead of the active theme.';
  @override String get settingsDayNightDayStart        => 'Day starts at';
  @override String get settingsDayNightNightStart      => 'Night starts at';
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
  @override String settingsUpdateBanner(String v) => 'Update v$v';
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
  @override String get settingsFaq               => 'FAQ';

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
  @override String get detailUserPlays       => 'your plays';
  @override String get detailGlobalPlays      => 'total plays';
  @override String get detailUserRank        => 'rank';
  @override String get detailUserRankNA      => 'N/A';
  @override String get detailGlobalListeners => 'listeners';
  @override String get detailPeriod          => 'Period';
  @override String get detailBiography       => 'Biography';
  @override String get detailGlobalListenersLabel => 'Listeners';
  @override String get detailTranslate       => 'Translate';
  @override String get detailShowOriginal    => 'Show original';
  @override String get detailLyrics          => 'Lyrics';
  @override String get detailLyricsNotFound  => 'Lyrics not available';
  @override String get detailCopyLyrics      => 'Copy lyrics';
  @override String get detailLyricsCopied    => 'Lyrics copied';

  @override String get detailShoutbox => 'Last.fm shoutbox';
  @override String get detailShoutboxReply => 'Reply';  @override String get dashPerWeek           => 'per week';

  @override String get onboardSkip             => 'Skip';
  @override String get onboardNext             => 'Next';
  @override String get onboardFinish           => 'Finish';
  @override String get onboardBack             => 'Back';
  @override String get onboardAppearanceTitle  => 'Personalize your style';
  @override String get onboardAppearanceSub    => 'Theme, accent color and Material You.';
  @override String get onboardNotifTitle       => 'Stay in the loop';
  @override String get onboardNotifSub         => 'Notifications and vibrations.';
  @override String get onboardFavTitle         => 'Your favorite profiles';
  @override String get onboardFavSub           => 'Add Last.fm friends to find them quickly.';
  @override String get onboardFavHint          => 'Last.fm username';
  @override String get onboardFavAdd           => 'Add';
  @override String get onboardFavEmpty         => 'No favorites yet';
  @override String get onboardFavSearchHint    => 'Search a Last.fm profile…';
  @override String get onboardFavNoResults     => 'No profile found';
  @override String get onboardFavFriendsTitle  => 'Your Last.fm friends';
  @override String get onboardFavNoFriends     => 'No friends found on this account';
  @override String get onboardFavSelected      => 'Selected favorites';
  @override String get onboardDashTitle        => 'Your dashboard';
  @override String get onboardDashSub          => 'Choose which sections to show.';
  @override String get onboardStartupTitle     => 'Startup screen';
  @override String get onboardStartupSub       => 'Which tab do you want to see first?';
  @override String get onboardPlatformTitle    => 'What do you listen on?';
  @override String get onboardPlatformSub      => 'This only shows the useful links on track/artist/album pages.';
  @override String get platformLastfm          => 'Last.fm';
  @override String get platformSpotify         => 'Spotify';
  @override String get platformYtMusic         => 'YouTube Music';
  @override String get platformOther           => 'Other / show all';
  @override String get settingsMusicPlatform          => 'Music platform';
  @override String get settingsMusicPlatformSub       => 'Filters the links shown on detail pages';
  @override String get settingsShowAllPlatformLinks    => 'Always show all';
  @override String get settingsShowAllPlatformLinksSub => 'Ignore the filter and show every link (Last.fm, Spotify, YT Music, Web)';
  @override String get onboardUpdatesTitle     => 'Updates';
  @override String get onboardUpdatesSub       => 'Automatic check for new versions.';
  @override String get onboardStyle              => 'Style';
  @override String get onboardStyleMaterialYou    => 'Material You';
  @override String get onboardStyleNothing        => 'Nothing OS';
  @override String get onboardPreview             => 'Preview';
  @override String get onboardPreviewButton       => 'Button';
  @override String get onboardPreviewOutline      => 'Outline';
  @override String get onboardPreviewText         => 'Sample text';
  @override String get onboardPreviewBubble       => 'Bubble';
  @override String get onboardAccentTint          => 'Accent tint';
  @override String get onboardNothingRedOnly      => 'Red only';
  @override String get onboardNothingRedYellow    => 'Red + yellow';
  @override String get onboardDisplay             => 'Display';
  @override String get onboardOledTitle           => 'OLED true black';
  @override String get onboardOledSub             => 'Pure black background in dark mode';
  @override String get onboardArtworkColorTitle   => 'Color from artwork';
  @override String get onboardArtworkColorSub     => 'Match accent color to the now-playing cover art';
  @override String get onboardNewsTitle           => 'News notifications';
  @override String get onboardNewsSub             => 'Get notified about new features and fixes';
  @override String get onboardNewsBadgeTitle      => 'News badge dot';
  @override String get onboardNewsBadgeSub        => 'Red dot on the dashboard bell when there\'s news';
  @override String get onboardHapticTitle         => 'Haptic feedback';
  @override String get onboardHapticSub           => 'Feel subtle vibrations on key interactions';
  @override String get onboardRecaps              => 'Recaps';
  @override String get onboardDailyRecapTitle     => 'Daily recap';
  @override String get onboardDailyRecapSub       => 'A quick summary of your day\'s listening';
  @override String get onboardWeeklyRecapTitle    => 'Weekly recap';
  @override String get onboardWeeklyRecapSub      => 'Your week\'s top artists, albums and tracks';
  @override String get onboardMilestonesSection   => 'Scrobble milestones';
  @override String get onboardMilestonesTitle     => 'Milestones';
  @override String get onboardMilestonesSub       => 'Celebrate round-number scrobble counts';
  @override String get onboardGrandMilestonesTitle => 'Grand milestones';
  @override String get onboardGrandMilestonesSub   => 'Extra celebration for major milestones';
  @override String get onboardDynamicColorSub      => 'Use colors from your wallpaper (Android 12+)';
  @override String get onboardBetaTitle            => 'Beta updates';
  @override String get onboardBetaSub              => 'Early access to pre-releases';

  @override String get notifDetailTitle            => 'Notification';
  @override String get notifDetailOpenLink         => 'Open link';

  @override String get settingsCheckingUpdates     => 'Checking for updates…';
  @override String get settingsTapToDownload       => 'Tap to download';

  @override String get detailLookingForPreview     => 'Looking for a preview…';
  @override String get detailPreview30Sec          => 'Preview · 30 sec';

  @override String get setupTagline                => 'Your Last.fm stats, reinvented.';
  @override String get setupAnalyseProfile         => 'Analyse a profile';
  @override String get setupConnecting             => 'Connecting…';
  @override String get setupStartAnalysis          => 'Start analysis';
  @override String get setupOr                     => 'or';
  @override String setupWelcome(String username)   => 'Welcome, $username!';
  @override String get setupUsernameLabel          => 'Last.fm username';
  @override String get setupApiKeyLabel            => 'Last.fm API key';
  @override String get setupApiKeyHint             => '32-character hex key';
  @override String get setupApiKeyPrivacyNote      => 'Stored locally. Never sent to a third party.';
  @override String get setupRememberMe             => 'Remember me';
  @override String get setupGetApiKey              => 'Get a free API key';
  @override String setupScrobblesToImport(String c) => '$c scrobbles to import';
  @override String get setupWelcomeBanner          => 'Welcome to LastStats!';
  @override String get setupOneTimeImportNote      => 'One-time import, future launches will be instant.';

  @override String get dashTapToDownload           => 'Tap to download.';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      '${isBeta ? "Beta" : "New"} update: v$version';
  @override String get dashWeekLabel               => 'THIS WEEK';
  @override String get dashMonthLabel              => 'THIS MONTH';
  @override String get dashYearLabel               => 'THIS YEAR';
  @override String get dashTopArtistLabel          => 'Top artist';
  @override String get dashTopTrackLabel           => 'Top track';
  @override String get dashScrobblesLabel          => 'Scrobbles';
  @override String get newsTypeFeatures            => 'Features';
  @override String get newsTypeFixes               => 'Fixes';
  @override String get newsTypeUpdates             => 'Updates';
  @override String get newsTypeAlerts              => 'Alerts';
  @override String get newsTypeInfo                => 'Info';
  @override String get newsWhatsNew                => "What's new";
  @override String newsItemsCount(int n)           => '$n ${n > 1 ? "items" : "item"}';
  @override String get newsFilters                 => 'Filters';
  @override String get newsAll                     => 'All';
  @override String get newsAnyDate                 => 'Any date';
  @override String get newsNoNewsYet               => 'No news yet';
  @override String get settingsNotifications        => 'Notifications';
  @override String get settingsCache                 => 'Cache';
  @override String get settingsCardAppearanceSub     => 'Theme, accent, layout, Material You';
  @override String get settingsCardDashboardSub      => 'Header image, visible sections, stat cards';
  @override String get settingsCardStartupSub        => 'Tab displayed on app launch';
  @override String get settingsCardNotificationsSub  => 'Milestones, daily & weekly recaps';
  @override String get settingsSync                  => 'Sync';
  @override String get settingsCardSyncSub           => 'Background scrobble auto-sync';
  @override String get settingsCardAccountSub        => 'Connected Last.fm profile, sign out';
  @override String get settingsCardCacheSub          => 'History, images, API data';
  @override String get settingsCardBackupSub         => 'Export & restore your settings';
  @override String get settingsCardUpdatesSub        => 'Check for new versions';
  @override String get settingsCardAboutSub          => 'Version, source code, credits';
  @override String get settingsCardFaqSub            => 'Scrobbling, platforms, open source';
  @override String get settingsRestartNotice => 'Some settings require restarting the app to take full effect.';
  @override String get syncPageTitle           => 'Scrobble sync';
  @override String get syncAutoTitle           => 'Automatic sync';
  @override String get syncAutoSubtitle        => 'Syncs your history in the background at a regular interval';
  @override String get syncFrequencyLabel      => 'Frequency';
  @override String syncFrequencyHours(int h)   => 'Every ${h}h';
  @override String get syncFrequencyDaily      => 'Once a day';
  @override String get syncManualTitle         => 'Manual sync';
  @override String get syncNowButton           => 'Sync now';
  @override String get syncInProgress          => 'Syncing…';
  @override String get syncLastSyncLabel       => 'Last sync';
  @override String get syncNeverLabel          => 'Never';
  @override String get syncTotalScrobblesLabel => 'Cached scrobbles';
  @override String syncNewScrobblesFound(int n) => n == 0 ? 'No new scrobbles' : '$n new scrobble(s) found';
  @override String get syncUpToDateMsg         => 'History up to date';
  @override String get syncNotifNote           => 'A progress notification shows up during a full sync.';
  @override String get pcModeLayout      => 'Layout';
  @override String get pcModeNavLayout   => 'Navigation layout';
  @override String get pcModeAuto        => 'Auto';
  @override String get pcModeSideRail    => 'Side rail';
  @override String get pcModeBottomBar   => 'Bottom bar';
  @override String get pcModeHintAuto    => 'Side rail on wide screens (≥ 720 dp), bottom bar on narrow screens.';
  @override String get pcModeHintOn      => 'Always use the side navigation rail, regardless of screen size.';
  @override String get pcModeHintOff     => 'Always use the bottom navigation bar, regardless of screen size.';
  @override String get aboutTagline               => 'Your Last.fm stats companion';
  @override String get aboutAppInfo                => 'App info';
  @override String get aboutScrobbleDownloader     => 'Scrobble downloader';
  @override String get aboutScrobbleDownloaderSub  => 'Export all your scrobbles to a file';
  @override String get aboutPoweredBy              => 'Powered by';
  @override String get aboutImageDisclaimer        => 'Artist, album and track images are fetched automatically from these sources and may sometimes be incorrect or not match the actual content.';
  @override String get aboutFooter                 => 'Made with ❤️ · Not affiliated with Last.fm / CBS';

  @override String updatesPublishedOn(String date) => 'Published on $date';
  @override String get updatesCurrentVersion       => 'Current version';
  @override String get updatesBetaTitle            => 'Beta updates';
  @override String get updatesBetaSub              => 'Get early access to pre-release versions';

  @override String get backupWhatsIncluded         => "What's included";
  @override String get backupDownloadFile          => 'Downloads a .json file';
  @override String get backupChooseFile            => 'Choose a backup file';
  @override String get backupFileSaved             => 'Backup saved';
  @override String get backupFileSaveFailed        => 'Failed to save the file';
  @override String get setupRestoreBackup          => 'Restore a backup';
  @override String get setupRestoreBackupSub       => 'Get your account and settings back from a .json backup file';
  @override String get backupRestoreKeysTitle => 'Restore API keys';
  @override String get backupRestoreKeysDesc => 'Choose which Last.fm keys to restore from this backup.';
  @override String get backupRestoreApiKeyLabel => 'API key';
  @override String get backupRestoreSecretKeyLabel => 'Secret key';
  @override String get backupIncludeFoldersLabel => 'Include folders';
  @override String get backupIncludeFoldersDesc => 'Carries your track folders and their content.';
  @override String get backupIncludeKeysDesc => 'Include the keys in the exported file';

  @override String get backupIncludeThemesLabel => 'Export themes';
  @override String get backupIncludeThemesDesc => 'Lets you share just the look (colors, style) with someone else.';

  @override String get backupAutoTitle => 'Automatic backup';
  @override String get backupAutoEnableLabel => 'Enable automatic backup';
  @override String get backupAutoEnableDesc => 'Saves a backup by itself, on the interval chosen below.';
  @override String get backupAutoFreqLabel => 'Frequency';
  @override String get backupAutoFreqDaily => 'Every day';
  @override String get backupAutoFreqWeekly => 'Every week';
  @override String get backupAutoFreqMonthly => 'Every month';
  @override String get backupAutoFreqYearly => 'Every year';
  @override String get backupAutoFolderLabel => 'Backup folder';
  @override String get backupAutoFolderDefault => 'App\'s default folder';
  @override String backupAutoNextLabel(String date) => 'Next backup: $date';  @override String get backupIncludeScrobblesLabel => 'Include full history';
  @override String get backupIncludeScrobblesDesc => 'Adds every track you have ever played (can be large).';

  @override String get backupScrobblesSlowWarning => 'This can take a while and is slower than a normal backup.';  @override String backupExportedOn(String date) => 'Backup from $date';
  @override String get backupScrobblesErrorTitle => 'Error in history';
  @override String get backupScrobblesErrorDesc => 'Some years in the history look corrupted in this file. What do you want to do?';
  @override String get backupScrobblesKeepAnyway => 'Continue anyway';
  @override String get backupScrobblesCancel => 'Cancel history';
  @override String get backupScrobblesSkipRefetch => 'Skip and re-download online';  @override String get settingsCrashLog => 'Error log';
  @override String get backupCrashLogDesc => 'Records errors the app runs into — useful when reporting a bug.';
  @override String get backupCrashLogShare => 'Share log';
  @override String get backupCrashLogClear => 'Clear log';
  @override String get backupCrashLogEmpty => 'No errors recorded';
  @override String get backupCrashLogCleared => 'Log cleared';
  @override String get backupCrashLogClearConfirm => 'Clear the error log?';

  @override String get faqSectionLabel             => 'Frequently asked questions';
  @override String get backupOverwriteWarning => 'Restoring a backup will overwrite your current settings.';
  @override String get faqOpenSourceBadge => 'LastStats is a free, open-source project made with ❤️ by SanoBld.';
  @override String get cacheUnlimited     => 'Unlimited';
  @override String get cacheTotalUsed     => 'Total used';
  @override String get cacheScrobblesShort => 'Scrobbles';
  @override String get restartHintFeatures => 'Some features may require restarting the app to take effect.';
  @override String get reorderCardsTitle   => 'Reorder cards';
  @override String get commonSave          => 'Save';
  @override String get dashFallbackWhenNoMusic   => 'When no music is playing';
  @override String get dashFallbackChooseDisplay => 'Choose what to display as background instead';
  @override String get dashFallbackPeriodLabel   => 'Backup period';
  @override String get fallbackPeriod1Week       => '1 week';
  @override String get fallbackPeriod1Month      => '1 month';
  @override String get fallbackPeriodAllTime     => 'All time';
  @override String get fallbackTypeNothing       => 'Nothing';
  @override String get fallbackTypeTopTrack      => 'Top Track';
  @override String get fallbackTypeTopAlbum      => 'Top Album';
  @override String get fallbackTypeTopArtist     => 'Top Artist';
  @override String get fallbackTypeCustomImage   => 'Custom image';
  @override String fallbackWillShow(String detail) => 'Will show: $detail';
  @override String get fallbackWillShowCustomUrl => 'Will show: custom image URL';

  @override String get dashAnimationBlurSection  => 'Animation & Blur';
  @override String get dashMusicAnimationTitle   => 'Music animation';
  @override String get dashMusicAnimationSub     => 'When music is playing, the header image slowly blurs and drifts, like Apple Music.';
  @override String get dashMusicAnimationInfo    => 'Blur is set automatically when this mode is active. The blur slider above has no effect while music is playing.';

  @override String get settingsTopAlbumsSection  => 'Top Albums';
  @override String get dashRecentPlaysLabel      => 'Recent plays';
  @override String get dashStatCardsSectionLabel => 'Stat Cards';
  @override String get dashStatCardsHeading      => 'Stat Cards';
  @override String get dashStatCardsSub          => 'Choose and reorder the cards shown in the stats block.';
  @override String get settingsDashboardChartSection => 'Dashboard chart';
  @override String get dashChartCalendarLabel => 'Listening calendar';
  @override String get dashChartMonthlyLabel => 'Monthly bars';
  @override String get settingsDisplayNameSection => 'Custom name';
  @override String get settingsDisplayNameLabel => 'What should we call you?';
  @override String get settingsDisplayNameHint => 'E.g. Sano Bld — leave empty to use your account name';
  @override String get newsSearchHint => 'Search the news…';
  @override String get aboutOpenSourceLibs => 'Open-source libraries';
  @override String get aboutOpenSourceLibsSub => 'Every Flutter package used to build this app.';
  @override String get aboutLicenseSection => 'License';
  @override String get aboutLicenseText => 'This project is released under the MIT License: feel free to use, modify, duplicate or redistribute it, just credit me.';
  @override String get aboutLicenseLink => 'View full license';
  @override String get languageAiNote => 'Translations were generated by AI and may contain inaccuracies.';
  @override String get aboutAiDevNote => 'AI was also used to help develop this app.';
  @override String get notifWorkManagerInfo => 'Notifications run in the background via WorkManager. The app does not need to be open. An internet connection is required.';
  @override String get notifIntervalTitle       => 'Every X scrobbles';
  @override String get notifIntervalSubtitle    => 'Get notified at regular intervals';
  @override String get notifRecapsSection       => 'Listening recaps';
  @override String get notifDailyRecapSubtitle  => 'Scrobble count + top artist for the day';
  @override String get notifWeeklyRecapSubtitle => 'Scrobble count + top artist for the week';
  @override String get notifNewsSection         => 'News';
  @override String get notifSyncSection         => 'Sync';
  @override String get notifSyncTitle           => 'Sync notifications';
  @override String get notifSyncSubtitle        => 'Alert when a history sync finishes';
  @override String get notifSyncDetailTitle     => 'Progress detail';
  @override String get notifSyncDetailSubtitle  => 'Show live progress (current year, counter) during sync';
  @override String get notifNewsSubtitle        => 'Get notified for new features, fixes and announcements';
  @override String get notifBadgeOnDashboard    => 'Badge on the dashboard';
  @override String get notifBadgeSubtitle       => 'Show the unread dot on the news bell icon';
  @override String get notifTestLabel           => 'Test';
  @override String get notifPermissionDisabledTitle => 'Notifications disabled';
  @override String get notifPermissionDisabledBody  => 'Grant permission so LastStats can send you alerts.';
  @override String get notifGrantPermission     => 'Grant permission';
  @override String get notifThresholdIntro      => "You'll get a special notification at each of these thresholds:";
  @override List<String> get notifThresholdMessages => const [
    'Your first 1,000 scrobbles. The journey begins. 🎵',
    'You hit five figures! 🎉',
    "You're a true music addict. 🔥",
    "One million scrobbles. That's legendary. 🎸",
  ];
  @override String get notifIntervalDescription => 'Fire a notification every X scrobbles';
  @override String get notifCustomValueLabel    => 'Custom value';
  @override String get notifTimeNotifyAt        => 'Notify at';
  @override String get notifDayOfWeek           => 'Day of the week';
  @override List<String> get weekdaysShort => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  @override List<String> get weekdaysNarrow => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  @override String get weekAbbrev => 'W';
  @override String get notifSendTest            => 'Send a test notification';
  @override String get notifSentCheckBar        => 'Check your notification bar!';
  @override String get notifMakeSureWorks       => 'Make sure everything works.';
  @override String get notifSentBang            => 'Sent!';
  @override String get notifSendButton          => 'Send';
  @override String get apVisualStyle             => 'Visual style';
  @override String get apStyleDefault            => 'Default';
  @override String get apNothingAccentLabel      => 'Accent';
  @override String get apNothingClassic          => 'Classic';
  @override String get apRedOnlyDesc             => 'Red only';
  @override String get apNothingMixed            => 'Mixed';
  @override String get apRedYellowDesc           => 'Red + yellow touches';
  @override String get apNothingActiveBanner     => 'Nothing OS style active. Accent, dynamic color and music color are disabled.';
  @override String get apNothingOledInherent     => 'Nothing dark mode is inherently OLED black. OLED toggle is not needed.';
  @override String get apOledTitle               => 'OLED black theme';
  @override String get apOledBuiltIntoNothing    => 'Built into Nothing dark mode';
  @override String get apOledPureBlack           => 'Pure black backgrounds when dark mode is active';
  @override String get apCustomColorTooltip      => 'Custom color';
  @override String get apColorWhenNothingPlays   => 'Color when nothing plays';
  @override String get apColorWhenNothingPlaysSub => 'Accent used while no track is scrobbling';
  @override String get apKeepLastArtworkTitle    => 'Keep last artwork color';
  @override String get apKeepLastArtworkSub      => 'Keep last artwork color instead of resetting when nothing plays';
  @override String get apDetailPagesSection      => 'Detail pages';
  @override String get apArtworkColorTheme       => 'Artwork color theme';
  @override String get apBeta                    => 'BETA';
  @override String get apArtworkColorThemeSub    => "Detail pages adapt their colors to the artwork's dominant color";
  @override String get apNavBarSection           => 'Navigation bar';
  @override String get apShowTabLabels           => 'Show tab labels';
  @override String get apShowTabLabelsSub        => 'Display tab names below icons in the bottom bar';
  @override String get apInteractionsSection     => 'Interactions';
  @override String get apHapticFeedbackSub       => 'Vibrations on taps, selections and gestures';
  @override String get acctRemoveTitle          => 'Remove account?';
  @override String acctRemoveBody(String username) => 'Remove @$username from your accounts?';
  @override String get acctRemoveAction         => 'Remove';
  @override String get acctAlreadyAddedOrFull   => 'This account is already added or the list is full.';
  @override String acctAddedSuccess(String username) => '@$username added successfully.';
  @override String get acctLogoutAllBody        => 'All accounts will be removed. You will return to the setup screen.';
  @override String acctMyAccounts(int count, int max) => 'My accounts ($count/$max)';
  @override String get acctActive               => 'Active';
  @override String get acctTapSwitchToActivate  => 'Tap "Switch" to activate';
  @override String get acctSwitch               => 'Switch';
  @override String get acctAddAnAccount         => 'Add an account';
  @override String acctSlotsRemaining(int n)    => '$n slot(s) remaining';
  @override String acctMaxReached(int max)      => 'Maximum of $max accounts reached.';
  @override String get acctApiKeyInfo           => 'Each account can use a different API key or the same one. You can find your API key at last.fm/api/accounts.';
  @override String get acctLastfmProfileSection => 'Last.fm Profile';
  @override String get acctViewOnLastfm         => 'View on Last.fm';
  @override String get acctDangerZone           => 'Danger Zone';
  @override String get acctLogoutAllSub         => 'Remove all accounts and return to the setup screen.';
  @override String get acctUsernameRequired     => 'Username is required.';
  @override String get acctApiKeyRequired       => 'API key is required.';
  @override String get acctUsernameLabel        => 'Last.fm username';
  @override String get acctSameApiKey           => 'Same API key as the active account';
  @override String get acctApiKeyLabel          => 'API key';
  @override String get acctAdd                  => 'Add';
  @override String get languageChangeNote => 'The language changes immediately throughout the app.';
  @override String get dashTotalScrobblesLabel  => 'Total scrobbles';
  @override String get dashMemberSinceLabel     => 'Member since';
  @override String get dashCountryLabel         => 'Country';
  @override String get dashArtistWeekLabel      => 'Artist #1 (week)';
  @override String get dashAlbumWeekLabel       => 'Album #1 (week)';
  @override String get dashTrackWeekLabel       => 'Track #1 (week)';
  @override String get dashUniqueArtistsLabel   => 'Unique artists';
  @override String get dashUniqueTracksLabel    => 'Unique tracks';
  @override String get dashUniqueAlbumsLabel    => 'Unique albums';
  @override String get dashThisWeekLabel        => 'This week';
  @override String get dashDayUnitShort         => 'd';
  @override String get setupEnableFavorites      => 'Enable favorites (optional)';
  @override String get setupFavoritesExplain     => 'Your secret key lets the app love (or unlove) tracks directly on Last.fm.';
  @override String get setupSecretKeyLabel       => 'Last.fm secret key';
  @override String get favConnectInvalidSecret   => 'The secret key must be 32 characters long.';
  @override String get favConnectDialogTitle     => 'Authorize favorites';
  @override String get favConnectDialogBody      => 'Authorize the app on the Last.fm page opened in your browser, then come back here and confirm.';
  @override String get favConnectDialogConfirm   => 'I authorized it';
  @override String get favConnectSuccess         => 'Favorites enabled successfully!';
  @override String get favConnectError           => 'Could not enable favorites. Check your secret key.';
  @override String get acctApiKeysSection        => 'API keys';
  @override String get acctSecretKeyLabel        => 'Secret key';
  @override String get acctSecretKeyNotSet       => 'Not set';
  @override String get acctFavoritesExplain      => 'The secret key lets you love (or unlove) tracks directly on Last.fm.';
  @override String get acctConnectFavorites      => 'Enable favorites';
  @override String get acctDisconnectFavorites   => 'Disable favorites';
  @override String get settingsFavoritesSection    => 'Favorites';
  @override String get settingsFavoritesSectionSub => 'Shows your favorites count in the statistics';
  @override String get settingsFavoritesNeedsKey   => 'Add your secret key in Account to enable';
  @override String get favSectionTitle           => 'Favorites';
  @override String get commonSeeMore             => 'See more';
  @override String get favPageTitle              => 'My favorites';
  @override String get favSearchHint             => 'Search a track or artist';
  @override String get favEmpty                  => 'No favorites yet.';
  @override String get settingsLovedBadgeTitle => 'Discreet heart badge';
  @override String get settingsLovedBadgeSub   => 'Shows a small heart on favorite tracks in recent tracks, history, and search';
  @override String get favSortRecent   => 'Recent';
  @override String get favSortOldest   => 'Oldest';
  @override String get favSortArtistAz => 'Artist A-Z';
  @override String get favSortTitleAz  => 'Title A-Z';
  @override String get favFolderSortCustom => 'Manual';
  @override String get favFoldersAll => 'All';
  @override String get favFolderNew => 'New folder';
  @override String get favFolderNamePlaceholder => 'Folder name';
  @override String get favFolderCustomEmojiTitle => 'Choose an emoji';
  @override String get favFolderCustomEmojiHelper => 'Just one emoji, no text.';
  @override String get favFolderDescPlaceholder => 'Description (optional)';
  @override String get favFolderRecentlyPlayed => 'Recently played';
  @override String get favFolderCreate => 'Create';
  @override String get favFolderEdit => 'Edit folder';
  @override String get favFolderDelete => 'Delete';
  @override String get favFolderDeleteConfirm => 'Delete this folder? Tracks won\'t be sorted into it anymore.';
  @override String get favFolderAssignTitle => 'Add to a folder';
  @override String get favFolderEmoji => 'Emoji';
  @override String get favFolderColor => 'Color';
  @override String get favFolderSave => 'Save';
  @override String get favFolderEmpty => 'No tracks in this folder';
  @override String get rankingsWholeYear       => 'Whole year';
  @override String get chartsExportGeneratedOn => 'generated on';
  @override String get faqQ1 => 'Does LastStats scrobble my music?';
  @override String get faqA1 => 'No. LastStats is a visualisation app: it displays the scrobbles already recorded on your Last.fm account, but it does not record any itself.\n\nTo automatically scrobble your music, use a dedicated app such as Pano Scrobbler (available on Android).';
  @override String get faqQ2 => 'Is an iOS version planned?';
  @override String get faqA2 => 'No, an iOS version is not planned at the moment. If enough people ask for it, the decision may be reconsidered.';
  @override String get faqQ3 => 'Does the app work on macOS or other platforms?';
  @override String get faqA3 => 'LastStats is developed and tested on Android. Behaviour on other platforms (macOS, Windows, Linux…) is unverified, bugs or unexpected behaviour may occur.';
  @override String get faqQ4 => 'Is LastStats open source?';
  @override String get faqA4 => 'Yes! The source code is freely available on GitHub. The project is independent, built with passion by SanoBld. Feel free to contribute, report bugs, or leave a star ⭐.';
  @override String get faqQ5 => 'Where is my data stored?';
  @override String get faqA5 => 'On your device only. LastStats has no server: your scrobbles are cached locally for fast access, and your Last.fm credentials are stored locally too. Nothing is sent anywhere except Last.fm\'s official API.';
  @override String get faqQ6 => 'How do I enable favorites?';
  @override String get faqA6 => 'Go to Settings > Account and enter your Last.fm secret key (you can find it next to your API key at last.fm/api/accounts), then follow the steps on screen. Once connected, you can favorite tracks directly from the app. This is not available with the app\'s built-in key.';
  @override String get faqQ7 => 'What is a \'scrobble\'?';
  @override String get faqA7 => 'A scrobble is a track logged as played on your Last.fm account \u2014 it\'s Last.fm\'s own term for \'one counted listen\'. All your totals (top artists, stats, etc.) are based on it.';
  @override String get faqQ8 => 'How do levels and achievements work?';
  @override String get faqA8 => 'Your account level grows with your total scrobble count (there\'s no max level). Cards also get a border (bronze \u2192 iridescent) based on how many times that artist/track/album has been played. Everything is computed automatically from stats already cached locally, with no extra network calls.';
  @override String get faqQ9 => 'How does power saving mode work?';
  @override String get faqA9 => 'Power saving mode spaces out automatic syncs to save battery. It can be always on, follow your phone\'s own power saving mode, or turn on below a battery level you choose, from Settings > General.';
  @override String get faqQ10 => 'How do I back up or restore my data?';
  @override String get faqA10 => 'Go to Settings > Backup. You can export a backup file, with or without your Last.fm key as you prefer, and import it later on this phone or on another device to get your settings back.';
  @override String get faqQ11 => 'Does the app work offline?';
  @override String get faqA11 => 'Yes, to some extent. Stats already loaded stay available offline thanks to local caching, but a connection is still needed to fetch new scrobbles.';
  @override String get faqQ12 => 'Can I switch Last.fm accounts?';
  @override String get faqA12 => 'Yes, you can save up to 3 Last.fm accounts. From Settings > Account, tap "Add an account" and then switch between them whenever you like. The local cache is automatically reset when you switch, so the data of two accounts never gets mixed.';
  @override String get faqQ13 => 'How do I set up notifications?';
  @override String get faqA13 => 'From Settings > Notifications, you can turn on an alert when a sync finishes, choose how often alerts appear, or turn notifications off completely if you prefer.';
  @override String get faqQ14 => 'Artwork is missing or keeps loading. What can I do?';
  @override String get faqA14 => 'Clear the cache in the app (Settings > Cache), then in Android (Settings > Apps > LastStats > Storage > Clear cache). If images are still missing, back up your data (Settings > Backup), uninstall and reinstall the app, then restore your backup.';
  @override String get settingsPlatformDisabledByShowAll => 'Disabled: all links are already shown.';
  @override String get commonInDevelopment => 'In development';
  @override String get commonSeeLess => 'See less';
  @override String get commonShare => 'Share';
  @override String get newsCustomDate => 'Custom date';
  @override String get aboutShortcuts => 'Keyboard shortcuts';
  @override String get aboutShortcutsSub => 'Available on desktop / large screens';
  @override String get shortcutSwitchTabs => 'Switch tabs';
  @override String get shortcutSearch => 'Search';
  @override String get shortcutClose => 'Close a sheet';
  @override String get shortcutRefresh => 'Refresh';
  @override String get aboutDiscord => 'Join the Discord';
  @override String get aboutDiscordSub => 'Chat, suggestions and live announcements';
  @override String get achvTitle => 'Achievements';
  @override String achvUnlocked(int unlocked, int total) => '$unlocked / $total unlocked';
  @override String get achvCatListening => 'Listening';
  @override String get achvCatArtists => 'Artists';
  @override String get achvCatAlbums => 'Albums';
  @override String get achvCatLoyalty => 'Loyalty';
  @override String get achvDescListening => 'Total tracks scrobbled, across every artist.';
  @override String get achvDescArtists => 'Number of different artists listened to at least once.';
  @override String get achvDescAlbums => 'Number of different albums listened to at least once.';
  @override String get achvDescLoyalty => 'How long the Last.fm account has existed.';
  @override String get achvCatTracks => 'Tracks';
  @override String get achvDescTracks => 'Number of different (distinct) tracks listened to.';
  @override String get achvCatPace => 'Pace';
  @override String get achvDescPace => 'Average scrobbles per week.';
  @override String get achvCatStreak => 'Streak';
  @override String get achvDescStreak => 'Longest run of consecutive days with at least one scrobble.';
  @override String get achvCatMarathon => 'Marathon';
  @override String get achvDescMarathon => 'The most scrobbles in a single day.';
  @override String get achvCatSocial => 'Social';
  @override String get achvDescSocial => 'The number of friends or profiles added.';
  @override String get achvCatComparisons => 'Comparisons';
  @override String get achvDescComparisons => 'The number of taste comparisons made.';
  @override String get achvUnlockedBadge => 'Unlocked';
  @override String get achvLockedBadge => 'Locked';
  @override String get dashRecap => 'Recap';
  @override String get recapDay => 'Today';
  @override String get recapWeek => 'This week';
  @override String get recapMonth => 'This month';
  @override String get recapScrobbles => 'scrobbles';
  @override String get recapArtists => 'Artists';
  @override String get recapTracks => 'Tracks';
  @override String get recapTopArtist => 'Top artist';
  @override String get recapTopTrack => 'Top track';
  @override String get recapTopAlbum => 'Top album';
  @override String get recapAvgDay => 'Avg/day';
  @override String get recapNoData => 'No scrobbles for this period yet.';
  @override String get recapSeeFull => 'See full recap';
  @override String get recapTop10 => 'Top 10';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => 'Best filter first';
  @override String get discoverSmartSub => 'Based on the time, the day and what you use most';
  @override String get discoverForYou => 'For you';
  @override String get discoverGlobalTrends => 'Global trends';
  @override String get discoverSrcForyou => 'Your mix';
  @override String get discoverSrcOnthisday => 'On this day';
  @override String get discoverSrcFresh => 'This month';
  @override String get discoverSrcGenre => 'Your genres';
  @override String get discoverSrcDeeper => 'Deep cuts';
  @override String get discoverSrcForgotten => 'Forgotten';
  @override String get discoverSrcAlbums => 'Albums';
  @override String get discoverSrcCountry => 'Your country';
  @override String get discoverTracks => 'Tracks';
  @override String get discoverArtists => 'Artists';
  @override String get discoverWeek => 'week';
  @override String get discoverMonth => 'month';
  @override String get discoverYear => 'year';
  @override String get discoverNothing => 'Nothing to show yet';
  @override String discoverLike(String names) => 'Like $names';
  @override String get dashReorderSections => 'Change section order';
  @override String get dashInfiniteTitle => 'Infinite scroll';
  @override String get dashInfiniteSub => 'Discover loops and keeps suggesting more';
  @override String get dashDiscoverTitle => 'Discover';
  @override String get dashDiscoverSub => 'Music ideas to swipe through';
  @override String get dashSortButton => 'Sort';
  @override String get dashSortDone => 'Done';
  @override String get dashSortHint => 'Drag to change the order';
  @override String get dashSortSmartNote => 'Smart order is on, so it may shuffle these depending on the moment.';
  @override String get dashSeparateRow => 'On its own row';
  @override String dashFiltersOf(String group) => '$group filters';
  @override String get apShapeSingle => 'One shape only';
  @override String get mvSource => 'Video source';
  @override String get mvSrcAuto => 'Auto (Apple Music, then YouTube)';
  @override String get mvSrcApple => 'Apple Music only';
  @override String get mvSrcYt => 'YouTube only (tracks)';
  @override String get mvQualityT => 'Video quality';
  @override String get mvQAuto => 'Auto';
  @override String get mvQLow => 'Data saver (360p)';
  @override String get mvTypesT => 'Show video for';
  @override String get mvTracks => 'Tracks';
  @override String get mvAlbums => 'Albums';
  @override String get mvArtists => 'Artists';
  @override String get mvModeT => 'Mode';
  @override String get mvModeBest => 'Recommended';
  @override String get mvModeSaver => 'Data saver';
  @override String get mvModeMax => 'Max quality';
  @override String get mvModeCustom => 'Custom';
  @override String get mvSrcYtFirst => 'YouTube, then Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => 'Services used, quotas and consumption';
  @override String get apiSumToday => 'Requests today';
  @override String get apiSumErrors => 'Errors';
  @override String get apiSumLimited => 'Rate-limited';
  @override String get apiIntro => 'Counters cover this device only. Providers enforce their limits per IP address, so other apps on the same network count too. The app automatically slows down or skips requests to stay within them.';
  @override String get apiCatListening => 'Listening data';
  @override String get apiCatMetadata => 'Music metadata';
  @override String get apiCatArtwork => 'Artwork';
  @override String get apiCatLyrics => 'Lyrics';
  @override String get apiCatTranslate => 'Translation';
  @override String get apiCatUpdates => 'Updates & news';
  @override String get apiCatOther => 'Image downloads';
  @override String get apiStatusIdle => 'Not used yet';
  @override String get apiStatusOk => 'OK';
  @override String get apiStatusNear => 'Near the limit';
  @override String get apiStatusPaused => 'Paused';
  @override String get apiProviderLimit => 'Provider limit';
  @override String get apiNoLimit => 'None published';
  @override String get apiAppCeiling => 'App ceiling';
  @override String apiLimitPer(int n, String win) => '$n requests / $win';
  @override String get apiWinSecond => 'second';
  @override String get apiWinMinute => 'minute';
  @override String get apiWinHour => 'hour';
  @override String apiWinSeconds(int s) => '$s seconds';
  @override String get apiWindowUsage => 'Current window';
  @override String get apiRemaining => 'Remaining';
  @override String apiResetsIn(String t) => 'Resets in $t';
  @override String apiPausedFor(String t) => 'Paused for $t after a rate-limit answer';
  @override String get apiToday => 'Today';
  @override String get apiLastHour => 'Last hour';
  @override String get apiTotal => 'Total';
  @override String get apiRateLimited => 'Rate-limited answers';
  @override String get apiSkipped => 'Skipped by the app';
  @override String get apiLastCall => 'Last call';
  @override String get apiNever => 'Never';
  @override String get apiNoKey => 'No API key needed';
  @override String get apiSharedKey => 'Shared public test key (free tier)';
  @override String get apiUnofficial => 'Unofficial endpoint: no guaranteed quota, may change or block without notice.';
  @override String get apiKeyInUse => 'Key in use';
  @override String get apiOwnKey => 'Your own Last.fm key';
  @override String apiBuiltinKey(int n, int total) => 'Built-in key $n of $total';
  @override String get apiBackupOn => 'Backup key: on';
  @override String get apiBackupOff => 'Backup key: off';
  @override String get apiPerKey => 'Requests per key (today / total)';
  @override String get apiLastfmNote => 'Last.fm publishes no number: it answers error 29 when an IP sends too many requests, and its terms forbid working around that. About 5 requests per second per IP is the usual guidance; the app stays under 4.';
  @override String get apiStorageTitle => 'Last.fm data stored';
  @override String apiStorageValue(String used, String cap) => '$used of $cap allowed';
  @override String get apiStorageOver => 'Over the 100 MB limit set by the Last.fm API terms. Clear the scrobble history in Storage to comply.';
  @override String get apiReset => 'Reset counters';
  @override String get apiLimiter => 'Limit requests';
  @override String get apiLimiterSub => 'Slows down requests to stay under API limits. Off = faster, no waiting.';
  @override String get apiResetBody => 'All request counters will be set back to zero.';
  @override String get apiResetDone => 'Counters reset';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (en) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxEn = {
  'st_notif_on': 'Notifications are on',
  'st_notif_off': 'Notifications are off',
  'st_notif_count': '{n} types active',
  'st_notif_perm': 'System permission needed',
  'st_notif_none': 'No notification type selected',
  'st_sync_on': 'Automatic sync is on',
  'st_sync_off': 'Automatic sync is off',
  'st_sync_on_s': 'Your data updates by itself.',
  'st_sync_off_s': 'Data only updates when you ask.',
  'st_bkp_on': 'Automatic backup is on',
  'st_bkp_off': 'Automatic backup is off',
  'st_bkp_on_s': 'Your settings are backed up automatically.',
  'st_bkp_off_s': 'Turn it on to never lose your settings.',
  'st_bkp_next': 'Next backup: {d}',
  'cmp_breakdown': 'What brings you together',
  'cmp_by_artists': 'Artists',
  'cmp_by_genres': 'Genres',
  'cmp_by_tracks': 'Tracks',
  'cmp_by_albums': 'Albums',
  'eco_on': 'Power saving is on',
  'eco_off': 'Power saving is off',
  'eco_why_manual': 'Always on, set by you',
  'eco_why_system': 'Your device\'s battery saver is on',
  'eco_why_battery': 'Battery is at {n}%',
  'eco_off_hint': 'Choose below when it should turn on',
  'eco_trig': 'When to turn on',
  'eco_sys_t': 'When the device battery saver is on',
  'eco_sys_s': 'Follows your phone\'s built-in power saving mode and turns off with it.',
  'eco_sys_na': 'Not available on this device.',
  'eco_chg': 'What changes',
  'eco_chg1': 'Tilt parallax is turned off',
  'eco_chg2': 'Screen refresh rate is capped at about 60 Hz',
  'eco_chg3': 'Background updates run less often',
  'eco_chg4': 'Animated artwork and badge shine are paused',
  'eco_chg_note': 'Everything else keeps full quality: images, exports and share cards.',
  'lib_section': 'Library',
  'lib_merge_t': 'Link versions of the same track',
  'lib_merge_s': 'Remasters, singles, (feat. …), deluxe editions: counted as one track or album, plays added together. Remixes, live and instrumental versions stay separate.',
  'lib_split_t': 'Split collaborations',
  'lib_split_s': '"Gims & Damso" counts for Gims and for Damso instead of being a separate artist. Bands like "Simon & Garfunkel" stay whole.',
  'lib_step_t': 'Your library',
  'lib_step_s': 'Choose how your listens are grouped. You can change this any time in settings.',
  'bk_dash_t': 'Dashboard and start-up',
  'bk_dash_s': 'Sections, header, stat cards, discover, start-up tab',
  'bk_notif_t': 'Notifications',
  'bk_notif_s': 'Recaps, milestones, news and badges',
  'bk_lib_t': 'Library options',
  'bk_lib_s': 'Link track versions, split collaborations',
  'bk_prof_t': 'Favourite profiles',
  'bk_prof_s': 'The Last.fm profiles you starred',
  'about_readme_t': 'README and project activity',
  'about_readme_s': 'Read the README, latest commits, workflows, version, downloads',
  'fold_show': 'Show ({n})',
  'fold_hide': 'Collapse',
  'readme_sub': 'The project and its activity',
  'readme_version': 'Version',
  'readme_downloads': 'Downloads',
  'readme_stars': 'Stars',
  'readme_license': 'License',
  'readme_commits': 'Latest commits',
  'readme_workflows': 'Latest workflows',
  'readme_retry': 'Retry',
  'readme_github': 'Open on GitHub',
  'readme_failed': 'Could not load (offline or GitHub rate limit reached).',
  'ago_min': '{n} min ago',
  'ago_h': '{n} h ago',
  'ago_d': '{n} d ago',
  'load_restored': '{n} scrobbles restored',
  'load_ready': 'Ready to import',
  'load_connecting': 'Connecting to Last.fm…',
  'load_done': 'Import complete',
  'load_backup_note': 'Backup found: only newer scrobbles will be checked.',
  'dash_nowplay': 'Now playing',
  'dash_stats': 'Stats',
  'dash_recent': 'Recent plays',
  'dash_discover': 'Discover',
  'dash_friends': 'Friends',
  'dash_chart': 'Dashboard chart',
  'dash_calendar': 'Calendar',
  'dash_monthly': 'Monthly',
  'cache_video_t': 'Animated covers (Apple Music)',
  'cache_video_s': 'Video memory in use: {mem} · {players} active player(s) · {links} link(s) cached',
  'cache_video_short': 'Animated covers',
  'cache_video_cleared': 'Video memory released',
  'cache_memory_section': 'Memory',
  'cache_storage_section': 'Storage',
  'lvl': 'Level {n}',
  'lvl_history': 'Level history',
  'set_living_t': 'Animated covers',
  'set_living_s': 'Soft zoom and depth effect on images',
  'set_motion_t': 'Video covers',
  'set_motion_s': 'Plays the animated cover when one exists',
  'set_achv_t': 'Achievements and levels',
  'set_achv_s': 'Tiers, badges, and account level',
  'cache_img_limit_t': 'Photo cache limit',
  'cache_img_limit_s': 'Covers, artist photos and avatars. Oldest ones are removed first.',
  'cache_vid_limit_t': 'Video cache limit',
  'cache_vid_limit_s': 'Apple Music animated covers kept on disk to replay offline (Android).',
  'cache_video_off': 'Off',
  'cache_vid_disk_t': 'Apple Music videos',
  'cache_vid_disk_s': '{size} · Saved animated covers',
  'cache_no_limit_note': 'Scrobbles and API data are never limited.',
  'key_internal_use': 'Use the app\'s built-in key',
  'key_internal_help': 'Backup option: this key is shared between users. It may hit its limits or stop working, and some features may then fail. Prefer your own key when you can.',
  'key_internal_active': 'App built-in key',
  'key_fallback_title': 'Built-in key as backup',
  'key_fallback_sub': 'Your own key is used first. If Last.fm rejects it, the app automatically tries again with the built-in key.',
  'key_use_own': 'Use my own API key',
  'key_change_title': 'Change API key',
  'key_change_sub': 'Replace your key with another one, or switch to the app\'s built-in key.',
  'key_change_sub_internal': 'You are using the app\'s shared key. Add your own key so you no longer depend on the limits of other users.',
  'key_change_intro': 'Enter a new API key for this account, or go back to the app\'s built-in key. Your username and your stats stay the same.',
  'key_change_intro_internal': 'This account currently uses the app\'s built-in key. Paste your own Last.fm API key below to replace it. Your username and your stats stay the same.',
  'key_change_hint': 'An API key is 32 characters long. You can create or find yours at last.fm/api/accounts.',
  'key_change_invalid_len': 'An API key must be exactly 32 characters long. Make sure you copied the whole key.',
  'key_change_same': 'This account already uses this key. Enter a different one.',
  'key_change_check_failed': 'Last.fm did not accept this key. Check that it is correct and that you are online, then try again.',
  'key_change_favorites_warn': 'Your favorites connection will be removed because it depends on the old key. You can reconnect it afterwards with your secret key.',
  'key_change_apply': 'Apply',
  'key_change_success': 'Your API key has been updated.',
  'key_internal_fav_note': 'Favorites need your own API key and your Last.fm secret key. Add your own key above to be able to turn them on.',
  'faq_q15': 'Can I change my API key after signing in?',
  'faq_a15': 'Yes. Go to Settings > Account and tap "Change API key". You can replace your key with another one, or add your own if you chose the built-in key at the start. Your stats stay the same, only the favorites connection has to be set up again.',
  'nothing_wip_badge': 'Being improved',
  'nothing_wip_msg': 'The Nothing OS style is being improved, so it is not available right now. It may be enabled in a future version.',
  'ui_play_preview': 'Play preview',
  'ntf_test_title': '🔔 Test notification',
  'ntf_test_body': 'LastStats notifications are working!',
  'ui_not_enough_data_yet_sy': 'Not enough data yet — sync your full history in Settings.',
  'ui_level': 'Level {level}',
  'ui_fetching': 'Fetching {currentYea}… ({yearIndex}/{totalYears})',
  'ui_which_chart': 'Which chart?',
  'ui_which_period': 'Which period?',
  'ui_all_time': 'All time',
  'ui_exporting': 'Exporting…',
  'ui_chart_not_available_fo': 'Chart not available for this period',
  'ui_could_not_generate_the': 'Could not generate the image',
  'ui_error': 'Error',
  'ui_loading_history': 'Loading history{yearLabel}… {pct}%',
  'ui_charts_will_be_more_ac': 'Charts will be more accurate once loaded.',
  'ui_load_the_full_history_': 'Load the full history to access all years.',
  'ui_load': 'Load',
  'ui_based_on_scrobbles_all': 'Based on {v_hourlyCou} scrobbles (all years)',
  'ui_all_available_years': 'All available years',
  'ui_based_on_scrobbles_fro': 'Based on {v_hourlyCou} scrobbles from {v_selectedY}',
  'ui_based_on_recent_scrobb': 'Based on {v_hourlyCou} recent scrobbles',
  'ui_analysing_your_last_20': 'Analysing your last ~200 scrobbles',
  'ui_all_time_loading': 'All-time ({v_selectedY} loading)',
  'ui_all_time_2': 'All-time',
  'ui_export_a_chart': 'Export a chart',
  'ui_scrobble_progression': 'Scrobble progression',
  'ui_your_musical_genres': 'Your musical genres',
  'ui_based_on_your_top_arti': 'Based on your top artists (all-time)',
  'ui_listening_habits': 'Listening habits',
  'ui_album_distribution': 'Album distribution',
  'ui_listening_calendar': 'Listening calendar',
  'ui_daily_activity_to': 'Daily activity — {first} to {last}',
  'ui_daily_activity_all_yea': 'Daily activity — all years',
  'ui_daily_activity': 'Daily activity — {v_selectedY}',
  'ui_load_history_to_see': 'Load history to see {v_selectedY}',
  'ui_daily_activity_last_12': 'Daily activity — last 12 months',
  'ui_all_years': 'all years',
  'ui_listening_streaks': 'Listening streaks',
  'ui_total': 'Total',
  'ui_avg_mo': 'Avg/mo',
  'ui_best_month': 'Best month',
  'ui_hourly_distribution': 'Hourly distribution',
  'ui_activity_by_day_of_wee': 'Activity by day of week',
  'ui_current_streak': 'Current streak',
  'ui_d': 'd',
  'ui_best_streak': 'Best streak',
  'ui_best_streak_started_on': 'Best streak started on {bestStart}',
  'ui_no_data_for_this_perio': 'No data for this period',
  'ui_load_history_to_displa': 'Load history to display {what}',
  'ui_less': 'Less',
  'ui_more': 'More',
  'ui_scan_a_profile': 'Scan a profile',
  'ui_lvl': 'Lvl {level}',
  'ui_qr_code': 'QR code?',
  'ui_add_a_qr_code_to_the_s': 'Add a QR code to the shared image, so whoever sees it can scan your profile?',
  'ui_no_qr': 'No QR',
  'ui_to_the_app': 'To the app',
  'ui_to_last_fm': 'To Last.fm',
  'ui_compare_music_taste': 'Compare Music Taste',
  'ui_syncing_full_library': 'Syncing full library…',
  'ui_see_more': 'See more',
  'ui_no_achievements_unlock': 'No achievements unlocked yet',
  'ui_no_animated_cover_for_': 'No animated cover for this album',
  'ui_source': 'Source: {source}',
  'ui_view_on_last_fm': 'View on Last.fm',
  'ui_original_text_last_fm_': 'Original text: Last.fm — Translation: Google Translate',
  'ui_source_last_fm': 'Source: Last.fm',
  'ui_dark': 'Dark',
  'ui_light': 'Light',
  'ui_system': 'System',
  'ui_colored_widgets': 'Colored widgets',
  'ui_tint_home_screen_widge': 'Tint home screen widgets with the accent color',
  'ui_search_settings': 'Search settings…',
  'ui_no_settings_found': 'No settings found',
  'ui_all': 'All',
  'ui_battery_saver': 'Power saving mode',
  'ui_save_battery_fewer_eff': 'Save battery, fewer effects',
  'ui_musical_soulmates': 'Musical soulmates',
  'ui_great_compatibility': 'Great compatibility',
  'ui_some_common_ground': 'Some common ground',
  'ui_fairly_different_taste': 'Fairly different tastes',
  'ui_worlds_apart_musically': 'Worlds apart, musically',
  'ui_this_is_your_own_profi': 'This is your own profile!',
  'ui_artists_from_your_hist': '{uniqueArti} artists from your history · {targetUser}\'s full library',
  'ui_artists_from_your_hist_2': '{uniqueArti} artists from your history · {targetUser}\'s top 200',
  'ui_full_library_api': 'Full library (API)',
  'ui_top_200_artists_tracks': 'Top 200 artists & tracks (API)',
  'ui_could_not_work_out_the': 'Could not work out the compatibility.',
  'ui_music_compatibility': 'Music compatibility',
  'ui_analyzing_musical_tast': 'Analyzing musical taste…',
  'ui_artist': '{v_totalArti} artist{v_totalArti2}',
  'ui_track': '{v_totalTrac} track{v_totalTrac2}',
  'ui_album': '{v_totalAlbu} album{v_totalAlbu2}',
  'ui_shared_tracks': 'Shared tracks',
  'ui_shared_artists': 'Shared artists',
  'ui_no_shared_artists_foun': 'No shared artists found.',
  'ui_shared_albums': 'Shared albums',
  'ui_play_count_unavailable': 'Play count unavailable for one of you.',
  'ui_you_listen_to_this_x_m': 'You listen to this {x}x more than {theirUsern}.',
  'ui_listens_to_this_x_more': '{theirUsern} listens to this {x}x more than you.',
  'ui_you_both_listen_to_thi': 'You both listen to this about equally.',
  'ui_plays': '{plays} plays',
  'ui_compatibility': 'compatibility',
  'ui_you_both_love': 'YOU BOTH LOVE',
  'ui_shared_top_artist': 'SHARED TOP ARTIST',
  'ui_achievements': 'Achievements',
  'ui_qr_not_recognized_not_': 'QR not recognized — not a LastStats/Last.fm profile',
  'ui_scan_a_profile_s_qr_co': 'Scan a profile\'s QR code',
  'ui_favorites': 'Favorites',
  'ui_advanced_youtube_music': 'Advanced YouTube Music client.',
  'ui_syncs_the_glyphs_of_no': 'Syncs the Glyphs of Nothing phones to the music.',
  'ui_sources': 'Sources',
  'ui_official_flutter_docs_': 'Official Flutter docs (widgets, theming, API).',
  'ui_official_material_3_gu': 'Official Material 3 guide for developing with Flutter.',
  'ui_flutter_api_reference_': 'Flutter API reference for the Material 3 theme flag.',
  'ui_official_flutter_packa': 'Official Flutter package for adaptive layouts.',
  'ui_android_widgets': 'Android widgets',
  'ui_applies_the_accent_col': 'Applies the accent color to the home screen widgets\' background. Off: pure white or black.',
  'ui_turns_off_tilt_paralla': 'Turns off tilt parallax, caps the screen refresh rate, and slows down background updates — everything else stays full quality (images, exports, share cards).',
  'ui_always_on': 'Always on',
  'ui_force_eco_mode_on_rega': 'Force power saving mode on, regardless of battery level.',
  'ui_auto_activate': 'Auto-activate',
  'ui_turn_on_below_a_batter': 'Turn on below a battery %',
  'ui_switches_on_by_itself_': 'Switches on by itself once the battery drops to the level below.',
  'ui_threshold': 'Threshold',
  'ui_choose_the_tab_display': 'Choose the tab displayed when the app launches.',
  'ui_the_selected_tab_will_': 'The selected tab will appear on next launch of the app.',
  'ui_friends_sync': 'Friends sync',
  'ui_sync_frequency': 'Sync frequency',
  'ui_daily': 'Daily',
  'ui_resync_everyone': 'Resync everyone',
  'ui_version_history': 'Version history',
  'ui_could_not_load_release': 'Could not load release history.',
  'ui_installed_dev_build_un': 'Installed: dev build (unknown version)',
  'ui_installed': 'Installed: {displayVer}',
  'ui_search_a_version_or_ch': 'Search a version or changelog…',
  'ui_official': 'Official',
  'ui_no_release_matches_you': 'No release matches your search.',
  'ui_latest': 'LATEST',
  'ui_installed_2': 'INSTALLED',
  'ui_no_description': 'No description.',
  'ui_download': 'Download',
  'ui_view_release': 'View release',
  'ui_details': 'Details',
  'ui_all_past_releases_chan': 'All past releases, changelogs and downloads',
  'ui_please_fill_both_field': 'Please fill both fields.',
  'ui_api_key_must_be_32_cha': 'API key must be 32 characters.',
  'ui_profile_not_found': 'Profile not found.',
  'ui_chart_monthly': 'Monthly bars',
  'ui_chart_cumul': 'Progression',
  'ui_chart_genres': 'Musical genres',
  'ui_chart_habits': 'Listening habits',
  'ui_chart_artists': 'Artist distribution',
  'ui_chart_albums': 'Album distribution',
  'ui_chart_calendar': 'Listening calendar',
  'ui_chart_streaks': 'Listening streaks',
  'ui_band_night': 'Night',
  'ui_band_morning': 'Morning',
  'ui_band_afternoon': 'Afternoon',
  'ui_band_evening': 'Evening',
  'qs_t1_t': 'OLED mode',
  'qs_t1_s': 'Pure black background',
  'qs_t2_t': 'Power saving mode',
  'qs_t2_s': 'Cuts battery use',
  'qs_t3_t': 'News notifications',
  'qs_t3_s': 'Alerts about Last.fm news',
  'qs_t4_t': 'Haptic feedback',
  'qs_t4_s': 'Vibrations on interactions',
  'qs_t5_t': 'Achievements',
  'qs_t5_s': 'Shows unlocked achievements',
  'qs_l1_t': 'Accent color',
  'qs_l2_t': 'Theme',
  'qs_l3_t': 'Language',
  'qs_l4_t': 'Music platform',
  'qs_l5_t': 'Account',
  'qs_l6_t': 'Sync',
  'qs_l7_t': 'Cache',
  'img_src_lastfm': 'Source: Last.fm',
  'img_src_ytmusic': 'Source: YouTube Music',
  'img_src_itunes': 'Source: iTunes',
  'img_src_deezer': 'Source: Deezer',
  'img_src_audiodb': 'Source: TheAudioDB',
  'img_src_musicbrainz': 'Source: MusicBrainz',
  'img_src_wikipedia': 'Source: Wikipedia',
  'ds_type_artist': 'Artist',
  'ds_type_album': 'Album',
  'ds_type_track': 'Track',
  'pf_1': '👤 User profile',
  'pf_2': '🎤 Top artists — All time',
  'pf_3': '💿 Top albums — All time',
  'pf_4': '🎵 Top tracks — All time',
  'pf_5': '⏱️ Recent plays',
  'pf_6': '🗓️ This week',
  'pf_7': '📅 This month',
  'pf_8': '📅 Last 3 months',
  'pf_9': '📅 Last 6 months',
  'pf_10': '📅 Last 12 months',
  'pf_11': '📊 Monthly history',
  'pf_12': '❤️ Loved tracks',
  'pf_13': '🗓️ Top artists — This week',
  'pf_14': '🗓️ Albums & tracks — This week',
  'ds_tier_next': '{n} / {next} to the next tier',
  'ds_tier_max': 'Max tier reached 🎉',
  'ds_tier_first': 'Listen to this track to unlock a first tier (from {n} plays).',
  'sl_import': 'Importing your data',
  'sl_done': 'Imported!',
  'sl_connect': 'Connecting to Last.fm…',
  'sec_chart': 'Chart / calendar',
  'stat_avg_day': 'Avg / day',
  'stat_avg_week': 'Avg / week',
  'stat_days_active': 'Active days',
  'stat_scrobbles_week': 'Scrobbles (week)',
  'accent_purple': 'Purple',
  'accent_blue': 'Blue',
  'accent_green': 'Green',
  'accent_red': 'Red',
  'accent_orange': 'Orange',
  'accent_pink': 'Pink',
  'accent_teal': 'Teal',
  'accent_neutral': 'Neutral',
  'shape_title': 'Image shapes',
  'shape_covers': 'Covers, artists and albums',
  'shape_mix': 'Mix',
  'shape_square': 'Square',
  'shape_circle': 'Circle',
  'shape_pick_one': 'Or pick a single shape',
  'friend_listening': 'Listening now',
  'friend_offline': 'Offline',
  'tier_none': 'No tier',
  'src_title': 'Sources',
  'src_scrobbles_meta': 'Scrobbles & metadata',
  'src_artwork': 'Artwork',
  'src_audio_preview': 'Audio preview',
  'src_video_artwork': 'Video artwork',
  'tip_love': 'Love',
  'rail_expand': 'Expand sidebar',
  'rail_collapse': 'Collapse sidebar',
  'a11y_loading': 'Loading',
  'bk_pick_folder': 'Choose auto-backup folder',
  'bk_save_title': 'Save LastStats backup',
  'bk_pick_file': 'Choose a LastStats backup file',
  'nch_milestone_d': 'Notifies when you hit a scrobble milestone',
  'nch_grand_d': 'Special alerts for big milestones (1K, 10K, 100K, 1M…)',
  'nch_recap_d': 'Daily and weekly listening summaries',
  'nch_update_d': 'Notifies when a new version of LastStats is available',
  'nch_news_d': 'New features, fixes and announcements about LastStats',
  'nch_sync_d': 'Progress while syncing your full scrobble history',
  'ntf_grand_1000000': 'One million scrobbles. That\'s legendary. 🎸',
  'ntf_grand_500000': 'Half a million scrobbles. You never stop. 🎧',
  'ntf_grand_250000': '{n} scrobbles — the music never ends. 🎶',
  'ntf_grand_100000': '{n} scrobbles! You\'re a true music addict. 🔥',
  'ntf_grand_50000': '{n} scrobbles. Seriously impressive. 🎵',
  'ntf_grand_25000': '{n} scrobbles and still going strong!',
  'ntf_grand_10000': '{n} scrobbles — you hit five figures! 🎉',
  'ntf_grand_5000': '{n} scrobbles and counting!',
  'ntf_grand_1000': 'Your first {n} scrobbles. The journey begins. 🎵',
  'ntf_update_title': 'LastStats {v} available',
  'ntf_update_body': 'A new version is ready to download.',
  'ntf_milestone_title': '🎵 Milestone: {n} scrobbles',
  'ntf_milestone_body': 'You just hit {n} scrobbles on Last.fm 🎶',
  'ntf_daily_title': '📊 Daily recap · {d}',
  'ntf_weekly_title': '📅 Weekly recap · {w}',
  'ntf_recap_body': '{n} scrobbles · Top: {a}',
  'ntf_n_today': '{n} scrobbles today',
  'ntf_n_week': '{n} scrobbles this week',
  'ntf_top_artist': 'Top artist: {a}',
  'ntf_update_avail': '🆕 Update available',
  'ntf_update_ready': 'LastStats {v} is ready — tap to view.',
  'ntf_sync_title': '🔄 Syncing scrobbles…',
  'ntf_sync_done': '✅ Scrobbles synced',
  'ntf_sync_new': '{n} new scrobble(s) added.',
  'ntf_grand_t': '{v} scrobbles!',
  'ntf_year': 'Year {y}',
  'ntf_week': 'Week {w}',
  'reorder': 'Reorder',
};
