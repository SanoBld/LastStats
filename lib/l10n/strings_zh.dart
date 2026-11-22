// lib/l10n/strings_zh.dart
// ══════════════════════════════════════════════════════════════════════════
//  Chinese
// ══════════════════════════════════════════════════════════════════════════

import '../services/data_source.dart';
import "app_strings.dart";

class AppStringsZh implements AppStrings {
  const AppStringsZh();

  @override String get period7day     => '周';
  @override String get period1month   => '月';
  @override String get period3month   => '3个月';
  @override String get period6month   => '6个月';
  @override String get period12month  => '年';
  @override String get periodOverall  => '全部';

  @override String get navDashboard => '仪表盘';
  @override String get navSearch    => '搜索';
  @override String get navRankings  => '排行榜';
  @override String get navCharts    => '图表';
  @override String get navHistory   => '历史记录';
  @override String get navSettings  => '设置';

  @override String get cacheTitle                  => '存储';
  @override String get cacheUsage                  => '已用空间';
  @override String get cacheLimit                  => '存储上限';
  @override String get cacheLimitHint              => '达到上限后，最久未使用的图片会自动删除。';
  @override String get cacheClearSection           => '清理';
  @override String get cacheImages                 => '图片';
  @override String get cacheImagesSubtitle         => '艺术家、专辑、歌曲封面';
  @override String get cacheApiData                => 'API 数据';
  @override String get cacheApiDataSubtitle        => '热门艺术家、专辑、最近播放…';
  @override String get cacheScrobbles              => 'Scrobble 历史记录';
  @override String get cacheScrobblesSubtitle      => DataSource.lb ? '从 ListenBrainz 下载的完整收听记录' : '从 Last.fm 下载的完整收听记录';
  @override String get cacheClearBtn               => '清空';
  @override String get cacheConfirmScrobblesTitle  => '删除历史记录？';
  @override String get cacheConfirmScrobblesBody   => '完整历史记录将被删除，下次启动时重新下载。';
  @override String get cacheConfirmAllTitle        => '清空全部缓存？';
  @override String get cacheConfirmAllBody         => '图片、API 数据和历史记录都将被删除。';
  @override String get cacheDelete                 => '删除';

  @override String get commonArtists          => '艺术家';
  @override String get commonAlbums           => '专辑';
  @override String get commonTracks           => '歌曲';
  @override String get commonNoResults        => '无结果';
  @override String get commonRetry            => '重试';
  @override String get commonCancel           => '取消';
  @override String get commonApply            => '应用';
  @override String get commonPlays            => '播放次数';
  @override String get commonListeners        => '听众';
  @override String get commonNowPlayingBadge  => '直播中';
  @override String get commonNowPlayingLong   => '正在播放';
  @override String get commonRecentTracks     => '最近播放';
  @override String get commonNoRecentTracks   => '暂无最近播放';
  @override String get commonTopArtists       => '热门艺术家';

  @override String get rankingsTitle     => '排行榜';
  @override String get rankingsPodium    => '领奖台';
  @override String get rankingsContinued => '排行榜其余部分';
  @override String get rankingsAllYears  => '所有年份';

  @override String get chartsTitle              => '图表';
  @override String get chartsMonthly            => 'Scrobbles（12个月）';
  @override String get chartsArtistDist         => '热门艺术家（分布）';
  @override String get chartsMainstreamTitle    => '主流 vs 小众佳作';
  @override String get chartsMainstreamSubtitle => '您喜爱艺术家的全球人气。';
  @override String get chartsCompute            => '计算';
  @override String get chartsRecompute          => '重新计算';
  @override String get chartsGem                => '小众佳作';
  @override String get chartsMainstream         => '主流';
  @override String globalListeners(String count) => '$count 名全球听众';

  @override String get historyTitle           => '历史记录';
  @override String get historySubtitle        => '您的每日收听记录';
  @override String get historyToday           => '今天';
  @override String get historySelectDate      => '选择日期';
  @override String get historyChronological   => '按时间顺序';
  @override String get historyList            => '列表';
  @override String get historyStats           => '统计';
  @override String get historyNoTracks        => '当天没有收听记录';
  @override String historyScrobbles(int n)    => '$n 次 scrobble';
  @override String historyArtistsCount(int n) => '$n 位艺术家';
  @override String historyAlbumsCount(int n)  => '$n 张专辑';
  @override String get historyTopArtists      => '热门艺术家';
  @override String get historyTopAlbums       => '热门专辑';
  @override String get historyTopTracks       => '热门歌曲';
  @override String get historyHourTracks      => '首歌曲';
  @override List<String> get months => const [
    '', '1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月',
  ];
  @override String dayLabel(DateTime d) {
    const wd = ['一','二','三','四','五','六','日'];
    return '${d.year}年${d.month}月${d.day}日 星期${wd[d.weekday - 1]}';
  }

  @override String get searchTitle        => '搜索';
  @override String get searchProfiles     => '用户';
  @override String get searchHintBar      => '艺术家、专辑、歌曲或用户…';
  @override String get searchHintProfiles => DataSource.lb ? '搜索 ListenBrainz 用户' : '搜索 Last.fm 用户';
  @override String get searchHintArtists  => '搜索艺术家';
  @override String get searchHintAlbums   => '搜索专辑';
  @override String get searchHintTracks   => '搜索歌曲';
  @override String get searchTypePrompt   => '在上方搜索栏输入';
  @override String get searchAll          => '全部';
  @override String get searchFolders => '文件夹';
  @override String get searchFoldersHint => '创建文件夹以保存歌曲、专辑或艺术家';
  @override String memberSince(String date) => '加入于 $date';
  @override String get perDay             => '每天';
  @override String get activityDays       => '活跃天数';

  @override String get dashStats           => '统计';
  @override String get dashTopTracks       => '热门歌曲';
  @override String get dashFriends         => '好友';
  @override String get dashRefresh         => '刷新';
  @override String get dashRefreshFriends  => '刷新好友';
  @override String get dashScrobbles       => 'scrobbles';
  @override String get dashScrobblesPerDay => '每天';
  @override String get dashDaysActive      => '活跃天数';
  @override String get dashLastTrack       => '最近播放';
  @override String get dashArtist1         => '第一艺术家';
  @override String get dashAlbum1          => '第一专辑';
  @override String get dashTrack1          => '第一歌曲';
  @override String get dashNoFriends       => '未找到好友';
  @override String get dashResetCache      => '重置缓存';
  @override String get dashResetCacheConfirm => DataSource.lb ? '所有本地缓存的 scrobble 数据将被删除，并从 ListenBrainz 重新下载。' : '所有本地缓存的 scrobble 数据将被删除，并从 Last.fm 重新下载。';

  @override String get dashFriendsActivity => DataSource.lb ? '您的 ListenBrainz 好友动态' : '您的 Last.fm 好友动态';

  @override String get settingsTitle             => '设置';
  @override String get settingsAppearance        => '外观';
  @override String get settingsTheme             => '主题';
  @override String get settingsThemeAuto         => '自动';
  @override String get settingsThemeLight        => '浅色';
  @override String get settingsThemeDark         => '深色';
  @override String get settingsAccentColor       => '强调色';
  @override String get settingsAccentAuto        => '自动';
  @override String get settingsCustomColor       => '自定义';
  @override String get settingsCustomColorEdit   => '编辑';
  @override String get settingsDynamicColor      => '动态取色';
  @override String get settingsDayNightAccent          => '日间/夜间强调色';
  @override String get settingsDayNightAccentToggle    => '日夜使用不同颜色';
  @override String get settingsDayNightAccentToggleSub => '为深色主题使用另一种强调色。';
  @override String get settingsDayNightAccentDark      => '颜色（深色主题）';
  @override String get settingsDayNightUseHours        => '使用指定时间';
  @override String get settingsDayNightUseHoursSub     => '按时间而非当前主题切换颜色。';
  @override String get settingsDayNightDayStart        => '白天开始于';
  @override String get settingsDayNightNightStart      => '夜晚开始于';
  @override String get settingsMaterialYou       => 'Material You';
  @override String get settingsMaterialYouSub    => '使用 Android 壁纸的颜色（需要 Android 12 及以上）';
  @override String get settingsMusicColor        => '取色自音乐';
  @override String get settingsMusicColorSub     => '从当前播放曲目的封面提取强调色';
  @override String get settingsMusicColorNote    => '当前封面的主色调将替代强调色。';
  @override String get settingsMusicColorLocked  => '请先关闭 Material You';
  @override String get settingsStartupPage       => '启动页面';
  @override String get settingsStartupTab        => '启动时的标签页';
  @override String get settingsDashboardSection  => '仪表盘';
  @override String get settingsHeaderImage       => '头图';
  @override String get settingsHeaderImageSub    => '所选封面将作为首页背景显示。';
  @override String get settingsHeaderSource      => '来源';
  @override String get settingsHeaderPeriod      => '时间段';
  @override String get settingsHeaderAnimation   => '过渡动画';
  @override String get settingsHeaderAnimationSub => '切换封面时的动画效果。';
  @override String get settingsHeaderBlur        => '模糊';
  @override String get settingsHeaderBlurNone    => '无';
  @override String get settingsHeaderCustomUrl   => '图片链接';
  @override String get settingsHeaderCustomUrlHint => 'https://example.com/image.jpg';
  @override String get settingsHeaderCustomUrlSub  => '粘贴图片的直接链接（jpg、png、webp 等）。';
  @override String get settingsHeaderApply       => '应用';
  @override String get settingsHeaderFallback    => '默认图片';
  @override String get settingsHeaderFallbackSub => '没有播放音乐时，顶部显示的图片。';
  @override String get settingsHeaderFallbackUrlLabel => '默认图片链接';
  @override String get settingsVisibleSections   => '显示的板块';
  @override String get settingsNowPlayingSection => '正在播放';
  @override String get settingsStatsSection      => '统计';
  @override String get settingsTopArtistsSection => '热门艺术家';
  @override String get settingsTopTracksSection  => '热门歌曲';
  @override String get settingsFriendsSection    => '好友';
  @override String get settingsFriendsSectionSub => DataSource.lb ? '您的 ListenBrainz 好友动态' : '您的 Last.fm 好友动态';
  @override String get settingsAccount           => '账号';
  @override String get settingsConnectedProfile  => DataSource.lb ? '已连接的 ListenBrainz 账号' : '已连接的 Last.fm 账号';
  @override String get settingsLogout            => '退出登录';
  @override String get settingsLogoutTitle       => '退出登录？';
  @override String get settingsLogoutContent     => '您的登录信息将被删除。';
  @override String get settingsLogoutConfirm     => '退出登录';
  @override String get settingsBackup            => '备份与恢复';
  @override String get settingsExport            => '导出设置';
  @override String get settingsExportSub         => '将设置以 JSON 格式复制到剪贴板，便于保存或分享';
  @override String get settingsImport            => '恢复备份';
  @override String get settingsImportSub         => '从之前导出的 JSON 恢复设置';
  @override String get settingsBackupInfo        => '包含：主题、颜色、API 密钥、用户名、头图、收藏。各版本间兼容。';
  @override String get settingsUpdates           => '更新';
  @override String get settingsAutoUpdate        => '自动检查';
  @override String get settingsAutoUpdateSub     => '每天在后台检查一次是否有新版本。';
  @override String get settingsCheckNow          => '立即检查';
  @override String get settingsUpToDate          => '已是最新';
  @override String settingsUpdateAvailable(String v) => 'v$v 可用';
  @override String get settingsCheckFailed       => '无法检查更新。请检查网络连接后重试。';
  @override String settingsUpdateBanner(String v) => '更新 v$v';
  @override String get settingsDownload          => '下载';
  @override String get settingsViewRelease       => '查看';
  @override String get settingsAbout             => '关于';
  @override String get settingsVersion           => '版本';
  @override String get settingsWebVersion        => '网页版';
  @override String get settingsWebVersionSub     => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode        => '源代码';
  @override String get settingsSourceCodeSub     => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage          => '语言';
  @override String get settingsAboutProjectDesc  => 'LastStats 是一个开源个人项目，可能存在一些错误。';
  @override String get settingsAboutSupport      => '支持本项目';
  @override String get settingsAboutSupportSub   => '⭐ 在 GitHub 上点个 star';
  @override String get settingsFaq               => '常见问题';

  @override String get headerNowPlaying  => '正在播放';
  @override String get headerTopTrack    => '第1名歌曲';
  @override String get headerTopAlbum    => '第1名专辑';
  @override String get headerTopArtist   => '第1名艺术家';
  @override String get headerCustomImage => '自定义图片';
  @override String get headerThemeColor  => '主题色';
  @override String get headerAnimNone    => '无';
  @override String get headerAnimFade    => '淡入淡出';
  @override String get headerAnimSlide   => '滑动';
  @override String get headerAnimZoom    => '缩放';
  @override String get headerPeriodWeek  => '周';
  @override String get headerPeriodMonth => '月';
  @override String get headerPeriodAllTime => '全部时间';

  @override String get colorPickerTitle       => '自定义颜色';
  @override String get colorPickerHue         => '色相';
  @override String get colorPickerSaturation  => '饱和度';
  @override String get colorPickerBrightness  => '亮度';
  @override String get colorPickerQuickColors => '快速选色';
  @override String get colorPickerInvalid     => '格式无效';
  @override String get colorCustomTooltip     => '自定义';

  @override String get exportTitle      => '导出设置';
  @override String get exportFilename   => '文件名';
  @override String get exportJsonContent => 'JSON 内容';
  @override String get exportInfo       => '复制此 JSON，粘贴到文本文件中，并以 .json 命名';
  @override String get exportCopy       => '复制 JSON';
  @override String get exportCopied     => '已复制！';
  @override String get importTitle      => '恢复备份';
  @override String get importHintLabel  => '在此粘贴您的 LastStats 备份。';
  @override String get importEmpty      => '没有可导入的内容：输入框为空。请粘贴从 LastStats 导出的 JSON。';
  @override String get importInvalidJson  => 'JSON 无效。';
  @override String get importUnknownFile  => '无法识别的文件。';
  @override String get importInvalidFormat => '格式无效。';
  @override String get importSuccess    => '设置已成功恢复 ✓';
  @override String get importRestore    => '恢复';

  @override String get setupImportJson      => '导入 JSON';
  @override String get setupImportHintLabel => '在下方粘贴您的 JSON 文件内容。';
  @override String get setupImportNote      => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat    => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields   => 'JSON 无效：缺少 "username" 或 "api_key" 字段。';

  @override String get detailTracklist       => '歌曲';
  @override String get detailAlbumLabel      => '专辑';
  @override String get detailDuration        => '时长';
  @override String get detailTopTracks       => '热门歌曲';
  @override String get detailTopAlbums       => '热门专辑';
  @override String get detailBioReadMore     => '展开';
  @override String get detailBioReadLess     => '收起';
  @override String get detailUserPlays       => '您的播放次数';
  @override String get detailGlobalPlays       => '总播放次数';
  @override String get detailUserRank        => '排名';
  @override String get detailUserRankNA      => '无';
  @override String get detailGlobalListeners => '听众';
  @override String get detailPeriod          => '时间段';
  @override String get detailBiography       => '简介';
  @override String get detailGlobalListenersLabel => '听众';
  @override String get detailTranslate       => '翻译';
  @override String get detailShowOriginal    => '查看原文';
  @override String get detailLyrics          => '歌词';
  @override String get detailLyricsNotFound  => '暂无歌词';
  @override String get detailCopyLyrics      => '复制歌词';
  @override String get detailLyricsCopied    => '歌词已复制';

  @override String get detailShoutbox => 'Last.fm 留言板';
  @override String get detailShoutboxReply => '回复';  @override String get dashPerWeek           => '每周';

  @override String get onboardSkip             => '跳过';
  @override String get onboardNext             => '下一步';
  @override String get onboardFinish           => '完成';
  @override String get onboardBack             => '返回';
  @override String get onboardAppearanceTitle  => '自定义您的风格';
  @override String get onboardAppearanceSub    => '选择浅色或深色主题、强调色以及显示选项。';
  @override String get onboardNotifTitle       => '及时获知动态';
  @override String get onboardNotifSub         => '选择要接收的通知,以及手机是否需要振动。';
  @override String get onboardFavTitle         => '您的收藏用户';
  @override String get onboardFavSub           => DataSource.lb ? '添加 ListenBrainz 好友,以便在应用中快速找到他们的资料。' : '添加 Last.fm 好友,以便在应用中快速找到他们的资料。';
  @override String get onboardFavHint          => DataSource.lb ? 'ListenBrainz 用户名' : 'Last.fm 用户名';
  @override String get onboardFavAdd           => '添加';
  @override String get onboardFavEmpty         => '暂无收藏';
  @override String get onboardFavSearchHint    => DataSource.lb ? '搜索 ListenBrainz 用户…' : '搜索 Last.fm 用户…';
  @override String get onboardFavNoResults     => '未找到相关用户';
  @override String get onboardFavFriendsTitle  => DataSource.lb ? '您的 ListenBrainz 好友' : '您的 Last.fm 好友';
  @override String get onboardFavNoFriends     => '该账号没有好友';
  @override String get onboardFavSelected      => '已选收藏';
  @override String get onboardDashTitle        => '您的仪表盘';
  @override String get onboardDashSub          => '选择要在主屏幕上显示的板块。您之后可以在设置中更改。';
  @override String get onboardStartupTitle     => '启动界面';
  @override String get onboardStartupSub       => '选择启动应用时首先打开的标签页。';
  @override String get onboardPlatformTitle    => '您在哪里听音乐？';
  @override String get onboardPlatformSub      => '告诉我们您在哪里听音乐。应用只会在曲目、艺术家和专辑页面中显示有用的链接。';
  @override String get platformLastfm          => 'Last.fm';
  @override String get platformSpotify         => 'Spotify';
  @override String get platformYtMusic         => 'YouTube Music';
  @override String get platformOther           => '其他 / 全部显示';
  @override String get settingsMusicPlatform          => '音乐平台';
  @override String get settingsMusicPlatformSub       => '在艺术家、专辑和曲目页面中，仅显示所选音乐服务的链接';
  @override String get settingsShowAllPlatformLinks    => '始终显示全部';
  @override String get settingsShowAllPlatformLinksSub => DataSource.lb ? '忽略过滤，显示所有链接（ListenBrainz、Spotify、YT Music、网页）' : '忽略过滤，显示所有链接（Last.fm、Spotify、YT Music、网页）';
  @override String get onboardUpdatesTitle     => '更新';
  @override String get onboardUpdatesSub       => '应用会自动检查是否有新版本可用。';
  @override String get onboardPreview             => '预览';
  @override String get onboardPreviewButton       => '按钮';
  @override String get onboardPreviewOutline      => '主按钮';
  @override String get onboardPreviewText         => '示例文字';
  @override String get onboardPreviewBubble       => '气泡';
  @override String get onboardDisplay             => '显示';
  @override String get onboardOledTitle           => 'OLED 纯黑';
  @override String get onboardOledSub             => '在深色模式下背景变为纯黑色,可以在 OLED 屏幕上节省电量。';
  @override String get onboardArtworkColorTitle   => '取色自封面';
  @override String get onboardArtworkColorSub     => '应用的强调色会自动匹配当前正在播放的曲目的封面。';
  @override String get onboardNewsTitle           => '资讯通知';
  @override String get onboardNewsSub             => '添加新功能或修复问题时,您会收到通知。';
  @override String get onboardNewsBadgeTitle      => '资讯红点';
  @override String get onboardNewsBadgeSub        => '有新内容可读时，主屏幕的铃铛图标上会显示提示点。';
  @override String get onboardHapticTitle         => '触感反馈';
  @override String get onboardHapticSub           => '点按按钮和重要元素时,手机会轻轻振动。';
  @override String get onboardRecaps              => '汇总';
  @override String get onboardDailyRecapTitle     => '每日汇总';
  @override String get onboardDailyRecapSub       => '每天收到一份您所听内容的摘要。';
  @override String get onboardWeeklyRecapTitle    => '每周汇总';
  @override String get onboardWeeklyRecapSub      => '每周收到您听得最多的艺术家、专辑和曲目列表。';
  @override String get onboardMilestonesSection   => 'Scrobble 里程碑';
  @override String get onboardMilestonesTitle     => '里程碑';
  @override String get onboardMilestonesSub       => '当播放次数达到整数里程碑时,您会收到一条祝贺通知。';
  @override String get onboardGrandMilestonesTitle => '重大里程碑';
  @override String get onboardGrandMilestonesSub   => '当播放次数达到很大的数字时,会显示特别的庆祝效果。';
  @override String get onboardDynamicColorSub      => '应用会使用您壁纸中的颜色。此选项需要 Android 12 或更高版本。';
  @override String get onboardBetaTitle            => '测试版更新';
  @override String get onboardBetaSub              => '比其他人更早收到测试版本。这些版本可能包含错误。';

  @override String get notifDetailTitle            => '通知';
  @override String get notifDetailOpenLink         => '打开链接';

  @override String get settingsCheckingUpdates     => '正在检查更新…';
  @override String get settingsTapToDownload       => '点击下载';

  @override String get detailLookingForPreview     => '正在查找试听片段…';
  @override String get detailPreview30Sec          => '试听 · 30 秒';

  @override String get setupTagline                => DataSource.lb ? '您的 ListenBrainz 统计，焕然一新。' : '您的 Last.fm 统计，焕然一新。';
  @override String get setupAnalyseProfile         => '分析一个账号';
  @override String get setupConnecting             => '连接中…';
  @override String get setupStartAnalysis          => '开始分析';
  @override String get setupOr                     => '或';
  @override String setupWelcome(String username)   => '欢迎，$username！';
  @override String get setupUsernameLabel          => 'Last.fm 用户名';
  @override String get setupApiKeyLabel            => 'Last.fm API 密钥';
  @override String get setupApiKeyHint             => '32 位十六进制密钥';
  @override String get setupApiKeyPrivacyNote      => '您的密钥只保存在此设备上,绝不会发送给第三方。';
  @override String get setupRememberMe             => '记住我';
  @override String get setupGetApiKey              => '免费获取 API 密钥';
  @override String setupScrobblesToImport(String c) => '待导入 $c 条 scrobble';
  @override String get setupWelcomeBanner          => '欢迎使用 LastStats！';
  @override String get setupOneTimeImportNote      => '仅需导入一次，之后启动会立即完成。';

  @override String get dashTapToDownload           => '点击下载。';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      '${isBeta ? "测试版" : "新版本"}更新：v$version';
  @override String get dashWeekLabel               => '本周';
  @override String get dashMonthLabel              => '本月';
  @override String get dashYearLabel               => '今年';
  @override String get dashTopArtistLabel          => '最常听的艺术家';
  @override String get dashTopTrackLabel           => '最常听的歌曲';
  @override String get dashScrobblesLabel          => 'Scrobbles';
  @override String get newsTypeFeatures            => '新功能';
  @override String get newsTypeFixes               => '修复';
  @override String get newsTypeUpdates             => '更新';
  @override String get newsTypeAlerts              => '提醒';
  @override String get newsTypeInfo                => '信息';
  @override String get newsWhatsNew                => '最新动态';
  @override String newsItemsCount(int n)           => '$n 条';
  @override String get newsFilters                 => '筛选';
  @override String get newsAll                     => '全部';
  @override String get newsAnyDate                 => '任意日期';
  @override String get newsNoNewsYet               => '暂无动态';
  @override String get settingsNotifications        => '通知';
  @override String get settingsCache                 => '缓存';
  @override String get settingsCardAppearanceSub     => '主题、强调色、布局、Material You';
  @override String get settingsCardDashboardSub      => '头图、显示的板块、统计卡片';
  @override String get settingsCardStartupSub        => '启动时显示的标签页';
  @override String get settingsCardNotificationsSub  => '里程碑、每日和每周汇总';
  @override String get settingsSync                  => '同步';
  @override String get settingsCardSyncSub           => '后台自动同步 scrobble 记录';
  @override String get settingsCardAccountSub        => DataSource.lb ? '已连接的 ListenBrainz 账号，退出登录' : '已连接的 Last.fm 账号，退出登录';
  @override String get settingsCardCacheSub          => '历史记录、图片、API 数据';
  @override String get settingsCardBackupSub         => '导出和恢复您的设置';
  @override String get settingsCardUpdatesSub        => '检查新版本';
  @override String get settingsCardAboutSub          => '版本、源代码、鸣谢';
  @override String get settingsCardFaqSub            => 'Scrobbling、平台、开源';
  @override String get settingsRestartNotice => '部分设置需要重启应用才能完全生效。';
  @override String get syncPageTitle           => 'Scrobble 同步';
  @override String get syncAutoTitle           => '自动同步';
  @override String get syncAutoSubtitle        => '按固定间隔在后台同步您的历史记录';
  @override String get syncFrequencyLabel      => '频率';
  @override String syncFrequencyHours(int h)   => '每 $h 小时';
  @override String get syncFrequencyDaily      => '每天一次';
  @override String get syncManualTitle         => '手动同步';
  @override String get syncNowButton           => '立即同步';
  @override String get syncInProgress          => '同步中…';
  @override String get syncLastSyncLabel       => '上次同步';
  @override String get syncNeverLabel          => '从未';
  @override String get syncTotalScrobblesLabel => '已缓存的 scrobble';
  @override String syncNewScrobblesFound(int n) => n == 0 ? '没有新的 scrobble' : '发现 $n 条新 scrobble';
  @override String get syncUpToDateMsg         => '历史记录已是最新：没有需要下载的新 scrobble';
  @override String get syncNotifNote           => '完整同步期间会显示带进度条的通知。';
  @override String get pcModeLayout      => '布局';
  @override String get pcModeNavLayout   => '导航布局';
  @override String get pcModeAuto        => '自动';
  @override String get pcModeSideRail    => '侧边栏';
  @override String get pcModeBottomBar   => '底部导航栏';
  @override String get pcModeHintAuto    => '宽屏（≥ 720 dp）使用侧边栏，窄屏使用底部导航栏。';
  @override String get pcModeHintOn      => '始终使用侧边导航栏，无论屏幕尺寸。';
  @override String get pcModeHintOff     => '始终使用底部导航栏，无论屏幕尺寸。';
  @override String get aboutTagline               => DataSource.lb ? '您的 ListenBrainz 统计伴侣' : '您的 Last.fm 统计伴侣';
  @override String get aboutAppInfo                => '应用信息';
  @override String get aboutScrobbleDownloader     => 'Scrobble 下载器';
  @override String get aboutScrobbleDownloaderSub  => '下载全部 scrobble 历史并保存为文件';
  @override String get aboutPoweredBy              => '技术支持';
  @override String get aboutImageDisclaimer        => '艺术家、专辑和歌曲的图片会自动从这些来源获取，有时可能不准确或与实际内容不符。';
  @override String get aboutFooter                 => '用 ❤️ 制作 · 与 Last.fm 无关联';

  @override String updatesPublishedOn(String date) => '发布于 $date';
  @override String get updatesCurrentVersion       => '当前版本';
  @override String get updatesBetaTitle            => '测试版更新';
  @override String get updatesBetaSub              => '抢先体验预发布版本';

  @override String get backupWhatsIncluded         => '包含内容';
  @override String get backupDownloadFile          => '下载 .json 文件';
  @override String get backupChooseFile            => '选择备份文件';
  @override String get backupFileSaved             => '备份已保存';
  @override String get backupFileSaveFailed        => '无法保存备份文件。请确认存储空间充足且应用有权写入该文件夹，然后重试。';
  @override String get setupRestoreBackup          => '恢复备份';
  @override String get setupRestoreBackupSub       => '从 .json 格式的备份文件中恢复您的账号和设置。';
  @override String get backupRestoreKeysTitle => '恢复 API 密钥';
  @override String get backupRestoreKeysDesc => '选择要从此备份恢复的 Last.fm 密钥。';
  @override String get backupRestoreApiKeyLabel => 'API 密钥';
  @override String get backupRestoreSecretKeyLabel => '密钥';
  @override String get backupIncludeFoldersLabel => '包含文件夹';
  @override String get backupIncludeFoldersDesc => '包含您的歌曲文件夹及其内容';
  @override String get backupIncludeKeysDesc => '在导出的文件中包含密钥';

  @override String get backupIncludeThemesLabel => '导出主题';
  @override String get backupIncludeThemesDesc => '仅将外观(颜色、样式)分享给其他人。';

  @override String get backupAutoTitle => '自动备份';
  @override String get backupAutoEnableLabel => '启用自动备份';
  @override String get backupAutoEnableDesc => '按照下方选择的间隔自动保存备份。';
  @override String get backupAutoFreqLabel => '频率';
  @override String get backupAutoFreqDaily => '每天';
  @override String get backupAutoFreqWeekly => '每周';
  @override String get backupAutoFreqMonthly => '每月';
  @override String get backupAutoFreqYearly => '每年';
  @override String get backupAutoFolderLabel => '备份文件夹';
  @override String get backupAutoFolderDefault => '应用默认文件夹';
  @override String backupAutoNextLabel(String date) => '下次备份:$date';  @override String get backupIncludeScrobblesLabel => '包含完整历史记录';
  @override String get backupIncludeScrobblesDesc => '添加您从一开始播放过的所有曲目(文件可能会很大)。';

  @override String get backupScrobblesSlowWarning => '这可能需要一些时间,比普通备份慢。';  @override String backupExportedOn(String date) => '备份于 $date';
  @override String get backupScrobblesErrorTitle => '历史记录出错';
  @override String get backupScrobblesErrorDesc => '此文件中的部分年份历史记录似乎已损坏。您想怎么做?';
  @override String get backupScrobblesKeepAnyway => '仍然继续';
  @override String get backupScrobblesCancel => '取消历史记录';
  @override String get backupScrobblesSkipRefetch => '跳过并重新在线下载';  @override String get settingsCrashLog => '错误日志';
  @override String get backupCrashLogDesc => '记录应用遇到的错误，方便反馈问题。';
  @override String get backupCrashLogShare => '分享日志';
  @override String get backupCrashLogClear => '清空日志';
  @override String get backupCrashLogEmpty => '没有记录到错误';
  @override String get backupCrashLogCleared => '日志已清空';
  @override String get backupCrashLogClearConfirm => '清空错误日志？';

  @override String get faqSectionLabel             => '常见问题';
  @override String get backupOverwriteWarning => '恢复备份将覆盖您当前的设置。';
  @override String get faqOpenSourceBadge => 'LastStats 是一个由 SanoBld 用 ❤️ 打造的免费开源项目。';
  @override String get cacheUnlimited     => '无限';
  @override String get cacheTotalUsed     => '已用总量';
  @override String get cacheScrobblesShort => '历史记录';
  @override String get restartHintFeatures => '某些功能可能需要重启应用才能生效。';
  @override String get reorderCardsTitle   => '重新排序卡片';
  @override String get commonSave          => '保存';
  @override String get dashFallbackWhenNoMusic   => '当没有音乐播放时';
  @override String get dashFallbackChooseDisplay => '改为选择在背景中显示的内容';
  @override String get dashFallbackPeriodLabel   => '显示第1名的时间段';
  @override String get fallbackPeriod1Week       => '1 周';
  @override String get fallbackPeriod1Month      => '1 个月';
  @override String get fallbackPeriodAllTime     => '全部时间';
  @override String get fallbackTypeNothing       => '无';
  @override String get fallbackTypeTopTrack      => '第1名歌曲';
  @override String get fallbackTypeTopAlbum      => '第1名专辑';
  @override String get fallbackTypeTopArtist     => '第1名艺术家';
  @override String get fallbackTypeCustomImage   => '自定义图片';
  @override String fallbackWillShow(String detail) => '将显示：$detail';
  @override String get fallbackWillShowCustomUrl => '将显示：自定义图片链接';

  @override String get dashAnimationBlurSection  => '动画与模糊';
  @override String get dashMusicAnimationTitle   => '音乐动态背景';
  @override String get dashMusicAnimationSub     => '播放音乐时，顶部图片会变成动态背景：模糊、流动的色彩和轻柔的呼吸感。';
  @override String get dashMusicAnimationInfo    => '此模式下模糊为自动（滑块无效）。如果启用了视频封面，视频会显示在上层，背景将暂停。';

  @override String get settingsTopAlbumsSection  => '热门专辑';
  @override String get dashRecentPlaysLabel      => '最近播放';
  @override String get dashStatCardsSectionLabel => '统计卡片';
  @override String get dashStatCardsHeading      => '统计卡片';
  @override String get dashStatCardsSub          => '选择并重新排序统计区块中显示的卡片。';
  @override String get settingsDashboardChartSection => '仪表盘图表';
  @override String get dashChartCalendarLabel => '收听日历';
  @override String get dashChartMonthlyLabel => '月度柱状图';
  @override String get settingsDisplayNameSection => '自定义名称';
  @override String get settingsDisplayNameLabel => '我们该怎么称呼您？';
  @override String get settingsDisplayNameHint => '例如 Noham — 留空则使用账号名称';
  @override String get newsSearchHint => '搜索动态…';
  @override String get aboutOpenSourceLibs => '开源库';
  @override String get aboutOpenSourceLibsSub => '构建此应用所使用的所有 Flutter 包。';
  @override String get aboutLicenseSection => '许可证';
  @override String get aboutLicenseText => '本项目基于 GNU GPL v3 许可证发布：您可以自由使用、修改和再分发，但衍生作品必须以相同许可证开源，并注明我的名字。';
  @override String get aboutLicenseLink => '查看完整许可证';
  @override String get languageAiNote => '翻译内容由 AI 生成，可能存在不准确之处。';
  @override String get aboutAiDevNote => '本应用的开发也使用了 AI。';
  @override String get notifWorkManagerInfo => '通知通过 WorkManager 在后台运行，应用无需保持打开状态，但需要网络连接。';
  @override String get notifIntervalTitle       => '每 X 次 scrobble';
  @override String get notifIntervalSubtitle    => '每新增指定数量的 scrobble 就通知您一次';
  @override String get notifRecapsSection       => '收听汇总';
  @override String get notifDailyRecapSubtitle  => '当天 scrobble 数 + 最喜爱的艺术家';
  @override String get notifWeeklyRecapSubtitle => '本周 scrobble 数 + 最喜爱的艺术家';
  @override String get notifNewsSection         => '资讯';
  @override String get notifSyncSection         => '同步';
  @override String get notifSyncTitle           => '同步通知';
  @override String get notifSyncSubtitle        => '历史记录同步完成时提醒';
  @override String get notifSyncDetailTitle     => '进度详情';
  @override String get notifSyncDetailSubtitle  => '同步期间显示实时进度（当前年份、计数）';
  @override String get notifNewsSubtitle        => '获取新功能、修复和公告的通知';
  @override String get notifBadgeOnDashboard    => '仪表盘上的徽章';
  @override String get notifBadgeSubtitle       => '有未读公告时，在资讯铃铛图标上显示提示点';
  @override String get notifTestLabel           => '测试';
  @override String get notifPermissionDisabledTitle => '通知已禁用';
  @override String get notifPermissionDisabledBody  => '请在系统设置中允许通知，这样 LastStats 才能向您发送回顾、里程碑和资讯。';
  @override String get notifGrantPermission     => '授予权限';
  @override String get notifThresholdIntro      => '达到以下每个节点时，您都会收到一条特别通知：';
  @override List<String> get notifThresholdMessages => const [
    '您的第一个 1,000 次 scrobble。旅程开始了。🎵',
    '您达到了五位数！🎉',
    '您是真正的音乐狂热者。🔥',
    '一百万次 scrobble。这是传奇。🎸',
  ];
  @override String get notifIntervalDescription => '每新增 X 个 scrobble 就会通知您';
  @override String get notifCustomValueLabel    => '自定义数值';
  @override String get notifTimeNotifyAt        => '通知时间';
  @override String get notifDayOfWeek           => '星期几';
  @override List<String> get weekdaysShort => const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  @override List<String> get weekdaysNarrow => const ['一', '二', '三', '四', '五', '六', '日'];
  @override String get weekAbbrev => '周';
  @override String get notifSendTest            => '发送测试通知';
  @override String get notifSentCheckBar        => '看看您的通知栏！';
  @override String get notifMakeSureWorks       => '检查通知能否在您的手机上正常显示。';
  @override String get notifSentBang            => '已发送！';
  @override String get notifSendButton          => '发送';
  @override String get apVisualStyle             => '视觉风格';
  @override String get apStyleDefault            => '默认';
  @override String get apNothingAccentLabel      => '强调色';
  @override String get apNothingClassic          => '经典';
  @override String get apRedOnlyDesc             => '仅红色';
  @override String get apNothingMixed            => '混合';
  @override String get apRedYellowDesc           => '红色 + 黄色点缀';
  @override String get apNothingActiveBanner     => 'Nothing OS 风格已启用。强调色、动态取色和音乐取色均已禁用。';
  @override String get apNothingOledInherent     => 'Nothing 深色模式本身就是 OLED 纯黑，无需再开启 OLED 开关。';
  @override String get apOledTitle               => 'OLED 黑色主题';
  @override String get apOledBuiltIntoNothing    => '已内置于 Nothing 深色模式';
  @override String get apOledPureBlack           => '深色模式激活时使用纯黑背景';
  @override String get apCustomColorTooltip      => '自定义颜色';
  @override String get apColorWhenNothingPlays   => '无播放时的颜色';
  @override String get apColorWhenNothingPlaysSub => '没有歌曲在播放时使用的强调色';
  @override String get apKeepLastArtworkTitle    => '保留上次封面颜色';
  @override String get apKeepLastArtworkSub      => '无播放时保留上次封面颜色，而不是重置';
  @override String get apDetailPagesSection      => '详情页';
  @override String get apArtworkColorTheme       => '封面配色主题';
  @override String get apArtworkColorThemeSub    => '详情页会根据封面的主色调调整配色';
  @override String get apNavBarSection           => '导航栏';
  @override String get apShowTabLabels           => '显示标签文字';
  @override String get apShowTabLabelsSub        => '在底部导航栏图标下方显示标签名称';
  @override String get apInteractionsSection     => '交互';
  @override String get apHapticFeedbackSub       => '点击、选择和手势时的振动反馈';
  @override String get acctRemoveTitle          => '删除账号？';
  @override String acctRemoveBody(String username) => '从您的账号中删除 @$username？';
  @override String get acctRemoveAction         => '删除';
  @override String get acctAlreadyAddedOrFull   => '该账号已添加，或列表已满。';
  @override String acctAddedSuccess(String username) => '@$username 添加成功。';
  @override String get acctLogoutAllBody        => '所有账号都将被删除，您将返回设置界面。';
  @override String acctMyAccounts(int count, int max) => '我的账号 ($count/$max)';
  @override String get acctActive               => '当前使用';
  @override String get acctTapSwitchToActivate  => '点击"切换"以激活';
  @override String get acctSwitch               => '切换';
  @override String get acctAddAnAccount         => '添加账号';
  @override String acctSlotsRemaining(int n)    => '还可添加 $n 个';
  @override String acctMaxReached(int max)      => '已达到最多 $max 个账号的上限。';
  @override String get acctApiKeyInfo           => '每个账号可以使用不同的 API 密钥，也可以共用同一个。您可以在 last.fm/api/accounts 找到您的 API 密钥。';
  @override String get acctLastfmProfileSection => 'Last.fm 资料';
  @override String get acctViewOnLastfm         => '在 Last.fm 上查看';
  @override String get acctDangerZone           => '危险区域';
  @override String get acctLogoutAllSub         => '删除所有账号并返回设置界面。';
  @override String get acctUsernameRequired     => '用户名为必填项。';
  @override String get acctApiKeyRequired       => 'API 密钥为必填项。';
  @override String get acctUsernameLabel        => 'Last.fm 用户名';
  @override String get acctSameApiKey           => '与当前账号使用相同的 API 密钥';
  @override String get acctApiKeyLabel          => 'API 密钥';
  @override String get acctAdd                  => '添加';
  @override String get languageChangeNote => '语言会立即在整个应用中生效。';
  @override String get dashTotalScrobblesLabel  => '总 scrobble 数';
  @override String get dashMemberSinceLabel     => '加入时间';
  @override String get dashCountryLabel         => '国家';
  @override String get dashArtistWeekLabel      => '第一艺术家（周）';
  @override String get dashAlbumWeekLabel       => '第一专辑（周）';
  @override String get dashTrackWeekLabel       => '第一歌曲（周）';
  @override String get dashUniqueArtistsLabel   => '独立艺术家数';
  @override String get dashUniqueTracksLabel    => '独立歌曲数';
  @override String get dashUniqueAlbumsLabel    => '独立专辑数';
  @override String get dashThisWeekLabel        => '本周';
  @override String get dashDayUnitShort         => '天';
  @override String get setupEnableFavorites      => '启用收藏（可选）';
  @override String get setupFavoritesExplain     => '您的密钥可让应用直接在您的 Last.fm 账号上将曲目添加到收藏或移除。';
  @override String get setupSecretKeyLabel       => 'Last.fm 密钥';
  @override String get favConnectInvalidSecret   => '密钥长度必须为 32 个字符。';
  @override String get favConnectDialogTitle     => '授权收藏功能';
  @override String get favConnectDialogBody      => '请在浏览器打开的 Last.fm 页面上授权本应用，然后返回此处确认。';
  @override String get favConnectDialogConfirm   => '我已授权';
  @override String get favConnectSuccess         => '收藏功能已成功启用！';
  @override String get favConnectError           => '无法启用收藏。请确认密钥正确，并已在 Last.fm 上授权 LastStats，然后重试。';
  @override String get acctApiKeysSection        => 'API 密钥';
  @override String get acctSecretKeyLabel        => '密钥';
  @override String get acctSecretKeyNotSet       => '未设置';
  @override String get acctFavoritesExplain      => '密钥可让您直接在 Last.fm 上添加或取消收藏歌曲。';
  @override String get acctConnectFavorites      => '启用收藏';
  @override String get acctDisconnectFavorites   => '停用收藏';
  @override String get settingsFavoritesSection    => '收藏';
  @override String get settingsFavoritesSectionSub => '在统计中显示收藏数量';
  @override String get settingsFavoritesNeedsKey   => '请在账户中添加密钥以启用';
  @override String get favSectionTitle           => '收藏';
  @override String get commonSeeMore             => '查看更多';
  @override String get favPageTitle              => '我的收藏';
  @override String get favSearchHint             => '搜索歌曲或艺人';
  @override String get favEmpty                  => '还没有收藏。点按曲目上的爱心即可添加。';
  @override String get settingsLovedBadgeTitle => '低调的爱心标记';
  @override String get settingsLovedBadgeSub   => '在最近播放、历史记录和搜索中为收藏的歌曲显示一个小爱心';
  @override String get favSortRecent   => '最近';
  @override String get favSortOldest   => '最早';
  @override String get favSortArtistAz => '艺人 A-Z';
  @override String get favSortTitleAz  => '标题 A-Z';
  @override String get favFolderSortCustom => '手动';
  @override String get favFoldersAll => '全部';
  @override String get favFolderNew => '新建文件夹';
  @override String get favFolderNamePlaceholder => '文件夹名称';
  @override String get favFolderCustomEmojiTitle => '选择一个表情符号';
  @override String get favFolderCustomEmojiHelper => '仅限一个表情符号，不能输入文字';
  @override String get favFolderDescPlaceholder => '描述（可选）';
  @override String get favFolderRecentlyPlayed => '最近播放';
  @override String get favFolderCreate => '创建';
  @override String get favFolderEdit => '编辑文件夹';
  @override String get favFolderDelete => '删除';
  @override String get favFolderDeleteConfirm => '删除此文件夹？歌曲将不再归入其中。';
  @override String get favFolderAssignTitle => '添加到文件夹';
  @override String get favFolderEmoji => '表情符号';
  @override String get favFolderColor => '颜色';
  @override String get favFolderSave => '保存';
  @override String get favFolderEmpty => '此文件夹为空。长按曲目上的爱心即可添加到这里。';
  @override String get rankingsWholeYear       => '全年';
  @override String get chartsExportGeneratedOn => '生成于';
  @override String get faqQ1 => 'LastStats 会记录我的音乐播放记录吗？';
  @override String get faqA1 => DataSource.lb ? '不会。LastStats 是一款可视化应用：它显示您 ListenBrainz 账户上已有的播放记录，但本身不会记录任何内容。\n\n如需自动记录音乐播放，请使用专门的应用，例如 Pano Scrobbler（Android 可用）。' : '不会。LastStats 是一款可视化应用：它显示您 Last.fm 账户上已有的播放记录，但本身不会记录任何内容。\n\n如需自动记录音乐播放，请使用专门的应用，例如 Pano Scrobbler（Android 可用）。';
  @override String get faqQ3 => '该应用能在 macOS 或其他平台运行吗？';
  @override String get faqA3 => 'LastStats 是在 Android 上开发和测试的。其他平台（macOS、Windows、Linux 等）上的表现未经验证，可能出现错误或异常行为。';
  @override String get faqQ4 => 'LastStats 是开源的吗？';
  @override String get faqA4 => '是的！源代码可在 GitHub 上自由获取。该项目由 SanoBld 独立用心打造。欢迎贡献代码、反馈问题，或点个 ⭐。';
  @override String get faqQ5 => '我的数据存储在哪里？';
  @override String get faqA5 => DataSource.lb ? '仅存储在您的设备上。LastStats 没有服务器：您的播放记录会在本地缓存以便快速访问，您的 ListenBrainz 账户信息也保存在本地。除官方 ListenBrainz API 外，不会向任何地方发送数据。' : '仅存储在您的设备上。LastStats 没有服务器：您的播放记录会在本地缓存以便快速访问，您的 Last.fm 账户信息也保存在本地。除官方 Last.fm API 外，不会向任何地方发送数据。';
  @override String get faqQ6 => '如何启用收藏功能？';
  @override String get faqA6 => '使用 Last.fm 时，请前往“设置”>“账户”并输入您的密钥（Secret，位于 last.fm/api/accounts 上 API 密钥的旁边）。使用 ListenBrainz 时无需再添加任何内容：令牌就足够了。连接后，您可以直接在应用中收藏曲目。';
  @override String get faqQ7 => '\u4ec0\u4e48\u662f\u201cscrobble\u201d\uff1f';
  @override String get faqA7 => DataSource.lb ? 'scrobble \u662f\u6307\u5728\u4f60\u7684 ListenBrainz \u8d26\u6237\u4e0a\u8bb0\u5f55\u4e00\u6b21\u64ad\u653e\u2014\u2014\u8fd9\u662f ListenBrainz \u5b98\u65b9\u672f\u8bed\uff0c\u8868\u793a\u201c\u4e00\u6b21\u88ab\u8ba1\u5165\u7684\u64ad\u653e\u201d\u3002\u4f60\u7684\u6240\u6709\u7edf\u8ba1\u6570\u636e\uff08\u6392\u884c\u699c\u3001\u603b\u91cf\u7b49\uff09\u90fd\u57fa\u4e8e\u5b83\u3002' : 'scrobble \u662f\u6307\u5728\u4f60\u7684 Last.fm \u8d26\u6237\u4e0a\u8bb0\u5f55\u4e00\u6b21\u64ad\u653e\u2014\u2014\u8fd9\u662f Last.fm \u5b98\u65b9\u672f\u8bed\uff0c\u8868\u793a\u201c\u4e00\u6b21\u88ab\u8ba1\u5165\u7684\u64ad\u653e\u201d\u3002\u4f60\u7684\u6240\u6709\u7edf\u8ba1\u6570\u636e\uff08\u6392\u884c\u699c\u3001\u603b\u91cf\u7b49\uff09\u90fd\u57fa\u4e8e\u5b83\u3002';
  @override String get faqQ8 => '\u7b49\u7ea7\u4e0e\u6210\u5c31\u7cfb\u7edf\u662f\u600e\u4e48\u8fd0\u4f5c\u7684\uff1f';
  @override String get faqA8 => '\u4f60\u7684\u8d26\u6237\u7b49\u7ea7\u968f\u603b scrobble \u6570\u589e\u957f\uff08\u6ca1\u6709\u4e0a\u9650\uff09\u3002\u5361\u7247\u4e5f\u4f1a\u6839\u636e\u8be5\u827a\u672f\u5bb6/\u6b4c\u66f2/\u4e13\u8f91\u7684\u64ad\u653e\u6b21\u6570\u663e\u793a\u8fb9\u6846\u989c\u8272\uff08\u9752\u94dc\u2192\u4e94\u5f69\uff09\u3002\u8fd9\u4e9b\u90fd\u57fa\u4e8e\u672c\u5730\u5df2\u7f13\u5b58\u7684\u7edf\u8ba1\u6570\u636e\u81ea\u52a8\u8ba1\u7b97\uff0c\u4e0d\u4f1a\u989d\u5916\u8bf7\u6c42\u7f51\u7edc\u3002';
  @override String get faqQ9 => '省电模式是如何工作的？';
  @override String get faqA9 => '省电模式会减少应用的活动以节省电量：关闭倾斜视差效果，将屏幕刷新率限制在约 60 Hz，降低后台更新频率，并暂停动态封面和徽章光泽。图片、导出内容和分享卡片仍保持完整画质。\n\n您可以让它始终开启，也可以跟随手机自带的省电模式，或在电量低于您设定的值时自动开启。可在“设置”>“省电模式”中找到。';
  @override String get faqQ10 => '如何备份或恢复我的数据？';
  @override String get faqA10 => '前往“设置”>“备份”。您可以导出备份文件（可选择是否包含 Last.fm 密钥或 ListenBrainz 令牌），之后可在本机或其他设备上导入。';
  @override String get faqQ11 => '应用可以离线使用吗？';
  @override String get faqA11 => '可以，在一定程度上。已加载的统计数据会通过本地缓存离线保留，但获取新的 scrobble 仍需要联网。';
  @override String get faqQ12 => '我可以切换账户或服务吗？';
  @override String get faqA12 => '可以。在“设置”>“账户”中退出登录，然后用其他用户名重新登录，或在登录界面选择另一项服务（Last.fm 或 ListenBrainz）。本地缓存会自动重置，以免数据混杂。';
  @override String get faqQ13 => '如何设置通知？';
  @override String get faqA13 => '在设置 > 通知中，您可以开启同步完成时的提醒、选择提醒出现的频率，也可以完全关闭通知。';
  @override String get faqQ14 => '图片缺失或一直加载怎么办？';
  @override String get faqA14 => '先在应用内清除缓存（设置 > 缓存），再在 Android 中清除（设置 > 应用 > LastStats > 存储 > 清除缓存）。如果仍无图片，请先备份数据（设置 > 备份），卸载并重新安装应用，然后恢复备份。';
  @override String get settingsPlatformDisabledByShowAll => '已停用：已显示全部链接。';
  @override String get commonInDevelopment => '开发中';
  @override String get commonSeeLess => '收起';
  @override String get commonShare => '分享';
  @override String get newsCustomDate => '自定义日期';
  @override String get aboutShortcuts => '键盘快捷键';
  @override String get aboutShortcutsSub => '适用于电脑 / 大屏幕';
  @override String get shortcutSwitchTabs => '切换标签页';
  @override String get shortcutSearch => '搜索';
  @override String get shortcutClose => '关闭面板';
  @override String get shortcutRefresh => '刷新';
  @override String get aboutDiscord => '加入 Discord';
  @override String get aboutDiscordSub => '交流、建议和实时公告';
  @override String get achvTitle => '成就';
  @override String achvUnlocked(int unlocked, int total) => '已解锁 $unlocked / $total';
  @override String get achvCatListening => '收听';
  @override String get achvCatArtists => '艺术家';
  @override String get achvCatAlbums => '专辑';
  @override String get achvCatLoyalty => '忠诚度';
  @override String get achvDescListening => '所有艺术家的累计播放次数（scrobbles）。';
  @override String get achvDescArtists => '至少收听过一次的不同艺术家数量。';
  @override String get achvDescAlbums => '至少收听过一次的不同专辑数量。';
  @override String get achvDescLoyalty => DataSource.lb ? 'ListenBrainz 账号的注册时长。' : 'Last.fm 账号的注册时长。';
  @override String get achvCatTracks => '曲目';
  @override String get achvDescTracks => '收听过的不同曲目数量。';
  @override String get achvCatPace => '节奏';
  @override String get achvDescPace => '每周平均播放次数。';
  @override String get achvCatStreak => '连续打卡';
  @override String get achvDescStreak => '连续有播放记录的最长天数。';
  @override String get achvCatMarathon => '马拉松';
  @override String get achvDescMarathon => '单日最多播放次数。';
  @override String get achvCatSocial => '社交';
  @override String get achvDescSocial => '已添加的好友或个人资料数量。';
  @override String get achvCatComparisons => '对比';
  @override String get achvDescComparisons => '已进行的音乐品味对比次数。';
  @override String get achvUnlockedBadge => '已解锁';
  @override String get achvLockedBadge => '未解锁';
  @override String get dashRecap => '回顾';
  @override String get recapDay => '今天';
  @override String get recapWeek => '本周';
  @override String get recapMonth => '本月';
  @override String get recapScrobbles => '播放次数';
  @override String get recapArtists => '艺术家';
  @override String get recapTracks => '歌曲';
  @override String get recapTopArtist => '艺术家';
  @override String get recapTopTrack => '歌曲';
  @override String get recapTopAlbum => '专辑';
  @override String get recapAvgDay => '日均';
  @override String get recapNoData => '此时段暂无播放记录。';
  @override String get recapSeeFull => '查看完整回顾';
  @override String get recapTop10 => '前10名';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => '最有用的筛选排在最前';
  @override String get discoverSmartSub => '根据时间、日期和您最常用的内容排序';
  @override String get discoverForYou => '为您推荐';
  @override String get discoverGlobalTrends => '全球趋势';
  @override String get discoverSrcForyou => '您的混合推荐';
  @override String get discoverSrcOnthisday => '历史上的今天';
  @override String get discoverSrcFresh => '本月';
  @override String get discoverSrcGenre => '您的音乐类型';
  @override String get discoverSrcDeeper => '冷门佳作';
  @override String get discoverSrcForgotten => '被遗忘的歌';
  @override String get discoverSrcAlbums => '专辑';
  @override String get discoverSrcCountry => '您的国家';
  @override String get discoverTracks => '歌曲';
  @override String get discoverArtists => '艺术家';
  @override String get discoverWeek => '周';
  @override String get discoverMonth => '月';
  @override String get discoverYear => '年';
  @override String get discoverNothing => '暂时没有内容';
  @override String discoverLike(String names) => '类似 $names';
  @override String get dashReorderSections => '调整版块顺序';
  @override String get dashInfiniteTitle => '无限滚动';
  @override String get dashInfiniteSub => '「发现」会循环播放，不断给您新推荐';
  @override String get dashDiscoverTitle => '发现';
  @override String get dashDiscoverSub => '左右滑动，发现新音乐';
  @override String get dashSortButton => '排序';
  @override String get dashSortDone => '完成';
  @override String get dashSortHint => '拖动即可调整顺序';
  @override String get dashSortSmartNote => '已开启智能排序，所以顺序可能会随时间变化。';
  @override String get dashSeparateRow => '单独占一行';
  @override String dashFiltersOf(String group) => '「$group」的筛选';
  @override String get apShapeSingle => '只用一种形状';
  @override String get mvSource => '视频来源';
  @override String get mvSrcAuto => '自动（先 Apple Music，后 YouTube）';
  @override String get mvSrcApple => '仅 Apple Music';
  @override String get mvSrcYt => '仅 YouTube（歌曲）';
  @override String get mvQualityT => '视频画质';
  @override String get mvQAuto => '自动';
  @override String get mvQLow => '节省流量 (360p)';
  @override String get mvTypesT => '在以下内容显示视频';
  @override String get mvTracks => '歌曲';
  @override String get mvAlbums => '专辑';
  @override String get mvArtists => '艺术家';
  @override String get mvModeT => '模式';
  @override String get mvModeBest => '推荐';
  @override String get mvModeSaver => '省流量';
  @override String get mvModeMax => '最高画质';
  @override String get mvModeCustom => '自定义';
  @override String get mvSrcYtFirst => '先 YouTube，后 Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => '使用的服务、配额与消耗';
  @override String get apiSumToday => '今日请求数';
  @override String get apiSumErrors => '错误';
  @override String get apiSumLimited => '被限流';
  @override String get apiIntro => '计数仅针对此设备。服务商按 IP 地址执行限制,因此同一网络中的其他应用也会计入。应用会自动放慢或跳过请求,以保持在限制之内。';
  @override String get apiCatListening => '收听数据';
  @override String get apiCatMetadata => '音乐元数据';
  @override String get apiCatArtwork => '封面';
  @override String get apiCatLyrics => '歌词';
  @override String get apiCatTranslate => '翻译';
  @override String get apiCatUpdates => '更新与资讯';
  @override String get apiCatOther => '图片下载';
  @override String get apiStatusIdle => '尚未使用';
  @override String get apiStatusOk => '正常';
  @override String get apiStatusNear => '接近上限';
  @override String get apiStatusPaused => '已暂停';
  @override String get apiProviderLimit => '服务商限制';
  @override String get apiNoLimit => '未公布';
  @override String get apiAppCeiling => '应用上限';
  @override String apiLimitPer(int n, String win) => '$n 次请求 / $win';
  @override String get apiWinSecond => '秒';
  @override String get apiWinMinute => '分钟';
  @override String get apiWinHour => '小时';
  @override String apiWinSeconds(int s) => '$s 秒';
  @override String get apiWindowUsage => '当前窗口';
  @override String get apiRemaining => '剩余';
  @override String apiResetsIn(String t) => '$t 后重置';
  @override String apiPausedFor(String t) => '因触发限流,已暂停 $t';
  @override String get apiToday => '今天';
  @override String get apiLastHour => '过去一小时';
  @override String get apiTotal => '总计';
  @override String get apiRateLimited => '限流响应';
  @override String get apiSkipped => '被应用跳过';
  @override String get apiLastCall => '最近调用';
  @override String get apiNever => '从未';
  @override String get apiNoKey => '无需 API 密钥';
  @override String get apiSharedKey => '共享的公开测试密钥(免费档)';
  @override String get apiUnofficial => '非官方接口:不保证配额,可能随时变更或被封锁。';
  @override String get apiKeyInUse => '使用中的密钥';
  @override String get apiOwnKey => '您自己的 Last.fm 密钥';
  @override String apiBuiltinKey(int n, int total) => '内置密钥 $n / $total';
  @override String get apiBackupOn => '备用密钥:开';
  @override String get apiBackupOff => '备用密钥:关';
  @override String get apiPerKey => '每个密钥的请求数(今日 / 总计)';
  @override String get apiLastfmNote => 'Last.fm 未公布具体数字:当某个 IP 请求过多时返回错误 29,其条款禁止规避。通常以每个 IP 每秒约 5 次请求为准,应用保持在 4 次以下。';
  @override String get apiStorageTitle => DataSource.lb ? '已存储的 ListenBrainz 数据' : '已存储的 Last.fm 数据';
  @override String apiStorageValue(String used, String cap) => '允许的 $cap 中已用 $used';
  @override String get apiStorageOver => DataSource.lb ? '已超过 ListenBrainz API 条款规定的 100 MB 上限。请在“存储”中清除 scrobble 历史记录以符合要求。' : '已超过 Last.fm API 条款规定的 100 MB 上限。请在“存储”中清除 scrobble 历史记录以符合要求。';
  @override String get apiReset => '重置计数';
  @override String get apiLimiter => '限制请求';
  @override String get apiLimiterSub => '放慢请求以避免超出 API 限额。关闭 = 更快，无需等待。';
  @override String get apiResetBody => '所有请求计数将归零。';
  @override String get apiResetDone => '计数已重置';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (zh) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxZh = {
  'st_notif_on': '通知已开启',
  'st_notif_off': '通知已关闭',
  'st_notif_count': '已启用 {n} 种',
  'st_notif_perm': '需要系统授权',
  'st_notif_none': '未选择任何通知类型',
  'st_sync_on': '自动同步已开启',
  'st_sync_off': '自动同步已关闭',
  'st_sync_on_s': '数据会自动更新。',
  'st_sync_off_s': '数据仅在您手动操作时更新。',
  'st_bkp_on': '自动备份已开启',
  'st_bkp_off': '自动备份已关闭',
  'st_bkp_on_s': '设置会自动备份。',
  'st_bkp_off_s': '开启后不会丢失设置。',
  'st_bkp_next': '下次备份：{d}',
  'cmp_breakdown': '您二位的共同点',
  'cmp_by_artists': '艺术家',
  'cmp_by_genres': '风格',
  'cmp_by_tracks': '曲目',
  'cmp_by_albums': '专辑',
  'eco_on': '省电已开启',
  'eco_off': '省电已关闭',
  'eco_why_manual': '由您设为始终开启',
  'eco_why_system': '设备的省电模式已开启',
  'eco_why_battery': '电量为 {n}%',
  'eco_off_hint': '在下方选择何时开启',
  'eco_trig': '何时开启',
  'eco_sys_t': '设备省电模式开启时',
  'eco_sys_s': '跟随手机自带的省电模式，并随其关闭而关闭。',
  'eco_sys_na': '此设备不可用（未检测到系统省电模式）。',
  'eco_chg': '会有哪些变化',
  'eco_chg1': '关闭倾斜视差',
  'eco_chg2': '屏幕刷新率限制在约 60 Hz',
  'eco_chg3': '后台更新频率降低',
  'eco_chg4': '动态封面和徽章光效暂停',
  'eco_chg_note': '其他一切保持完整品质：图片、导出和分享卡片。',
  'lib_section': '资料库',
  'lib_merge_t': '合并同一曲目的不同版本',
  'lib_merge_s': '重制版、单曲、(feat. …)、豪华版会算作同一首曲目或专辑,播放次数合并。混音、现场和纯音乐版本仍单独计算。',
  'lib_split_t': '拆分合作艺人',
  'lib_split_s': '“Gims & Damso”会分别计入 Gims 和 Damso,而不是单独的艺人。像“Simon & Garfunkel”这样的乐队保持完整。',
  'lib_step_t': '您的资料库',
  'lib_step_s': '选择应用如何归并您的播放记录。您可以随时在设置中更改。',
  'bk_dash_t': '仪表盘与启动',
  'bk_dash_s': '板块、头图、统计卡片、发现、启动标签页',
  'bk_notif_t': '通知',
  'bk_notif_s': '回顾、里程碑、资讯和角标',
  'bk_lib_t': '资料库选项',
  'bk_lib_s': '合并版本、拆分合作艺人',
  'bk_prof_t': '收藏的资料',
  'bk_prof_s': '您加星标的 Last.fm 用户',
  'about_legal_t': '法律信息',
  'about_legal_site_t': '法律声明与隐私',
  'about_legal_site_s': '发布者、处理的数据、第三方服务、您的权利',
  'about_licenses_t': '开源许可证',
  'about_licenses_s': 'Flutter 及所有使用的软件包',
  'about_legal_editor': '由独立开发者 Sano Bld 发布。欢迎通过 Discord 或 GitHub issues 联系我们。',
  'about_legal_privacy': '您的数据保存在您的设备上，我们不保留任何副本。应用会直接连接此处列出的服务，每个服务至少会收到您的 IP 地址和请求内容（例如艺术家名称）。相机仅用于扫描二维码。未经父母同意，本应用不面向 15 岁以下儿童。',
  'about_legal_marks': 'LastStats 是独立项目，与 Last.fm、Spotify、YouTube、Apple、Deezer、TheAudioDB、MusicBrainz、Wikipedia 和 GitHub 均无关联，也未获其认可。名称和标志归其各自所有者所有，封面和元数据亦然。Wikipedia 文本采用 CC BY-SA 许可。',
  'about_readme_t': 'README 与项目动态',
  'about_readme_s': '阅读 README、最新提交、工作流、版本、下载量',
  'fold_show': '显示 ({n})',
  'fold_hide': '收起',
  'readme_sub': '项目及其动态',
  'readme_version': '版本',
  'readme_downloads': '下载量',
  'readme_stars': '星标',
  'readme_license': '许可证',
  'readme_commits': '最新提交',
  'readme_workflows': '最新工作流',
  'readme_retry': '重试',
  'readme_github': '在 GitHub 打开',
  'readme_failed': '无法加载(离线或已达 GitHub 频率限制)。',
  'ago_min': '{n} 分钟前',
  'ago_h': '{n} 小时前',
  'ago_d': '{n} 天前',
  'load_restored': '已恢复 {n} 条 scrobble',
  'load_ready': '准备导入',
  'load_connecting': '正在连接 Last.fm…',
  'load_done': '导入完成',
  'txt_sec': '文字',
  'txt_size': '文字大小',
  'txt_font': '字体',
  'txt_font_def': '默认（Android）',
  'font_import': '导入字体',
  'font_import_s': '.ttf 或 .otf 文件（最大 3 MB）',
  'font_remove': '删除已导入的字体',
  'font_bad': '无法使用此字体：文件无效或超过 3 MB',
  'qs_l8_t': '字体',
  'art_popular': '热门',
  'art_recent': '最新',
  'bio_src_wiki': '来源：维基百科',
  'bio_src_wiki_orig': '原文 · 维基百科',
  'dash_motion_t': '仪表盘动态封面',
  'dash_motion_s': '在播放卡片和顶部栏中播放当前曲目的视频。需要开启视频封面。',
  'onb_cov_t': '封面、图片和动画',
  'onb_cov_s': '选择图片的形状、封面的显示方式以及动画样式。',
  'onb_sync_t': '同步与电池',
  'onb_sync_s': '让统计数据保持最新,同时不过多消耗手机电量。',
  'onb_autosync_t': '自动同步',
  'onb_autosync_s': '应用会定期在后台检查您是否有新的播放记录。',
  'onb_freq': '检查频率',
  'onb_every_h': '每 {h} 小时',
  'onb_every_1h': '每小时',
  'load_backup_note': '检测到备份:只会检查更新的 scrobble。',
  'dash_nowplay': '正在播放',
  'dash_stats': '统计',
  'dash_recent': '最近播放',
  'dash_discover': '发现',
  'dash_friends': '好友',
  'dash_chart': '仪表盘图表',
  'dash_calendar': '日历',
  'dash_monthly': '按月',
  'cache_video_t': '内存中的动态封面',
  'cache_video_s': '视频内存占用:{mem} · {players} 个活动播放器 · 已缓存 {links} 个链接',
  'cache_video_short': '动态封面',
  'cache_video_cleared': '已从内存中释放动态封面视频',
  'cache_memory_section': '内存',
  'cache_storage_section': '存储',
  'lvl': '等级 {n}',
  'lvl_history': '等级历史',
  'set_mblur_t': "动态模糊",
  'menu_copied': "已复制",
  'menu_select': "选择",
  'sel_count': "已选 {n} 项",
  'sel_remove': "从收藏中移除",
  'sel_cancel': "取消",
  'menu_add_folder': "添加到文件夹",
  'menu_copy_title': "复制标题",
  'menu_copy_both': "复制艺人 – 标题",
  'set_mblur_s': "页面切换和内容出现时的柔和模糊",
  'ui_widget_bg': "小组件背景",
  'ui_widget_bg_d': "海报使用主题形状;纯色根据浅色/深色为黑色或白色;无为透明",
  'ui_widget_bg_poster': "海报",
  'ui_widget_bg_plain': "纯色",
  'ui_widget_bg_none': "无",
  'about_insp_podium': "灵感:进入/退出过渡时的柔和模糊",
  'about_insp_metrolist': "灵感:标签页之间的滑动+淡入淡出(Material 3)",
  'about_insp_m3skill': "动效准则:缓动、弹簧、共享轴",
  'ui_beta': "测试版",
  'ui_nothing_red_sub': "红色 #FF2020",
  'ui_nothing_yellow_sub': "+ 黄色 #FFC700",
  'set_living_t': '动态封面效果',
  'set_living_s': '图片会以轻微的缩放和景深效果缓缓移动。',
  'set_motion_t': '视频封面',
  'set_motion_s': '当曲目有动态视频封面时自动播放。',
  'set_achv_t': '成就与等级',
  'set_achv_s': '查看您的目标、徽章和账号等级。',
  'cache_img_limit_t': '照片缓存上限',
  'cache_img_limit_s': '封面、艺术家照片和头像。优先删除最旧的。',
  'cache_vid_limit_t': '视频缓存上限',
  'cache_vid_limit_s': '将动态封面保存在设备上，以便离线播放（Android）。',
  'cache_video_off': '关闭',
  'cache_vid_disk_t': '已保存的动态封面',
  'cache_vid_disk_s': '{size} · 已保存的动态封面',
  'ap_harmony_title': '配色风格',
  'ap_harmony_mono': '单色',
  'ap_harmony_mono_sub': '仅一种色相，强度不同。中性表面保持朴素',
  'ap_harmony_tinted': '着色',
  'ap_harmony_tinted_sub': '仅一种色相，连中性色（背景、边框、文字）也带一点淡淡的色调，不使用纯灰',
  'ap_harmony_classic': '经典',
  'ap_harmony_classic_sub': '标准 Material You，含多种互补色相',
  'ap_harmony_vivid': '鲜明',
  'ap_harmony_vivid_sub': '仅一种色相，饱和度更高、更强烈',
  'ap_harmony_soft': '柔和',
  'ap_harmony_soft_sub': '仅一种色相，更含蓄，接近灰色',
  'gr_night1': '还没睡吗，{name}？',
  'gr_night2': '与音乐相伴的夜晚，{name}',
  'gr_night3': '有音乐的夜晚更动听，{name}',
  'gr_morning1': '早上好，{name}',
  'gr_morning2': '睡得好吗，{name}？',
  'gr_morning3': '美好一天的开始，{name}',
  'gr_afternoon1': '下午好，{name}',
  'gr_afternoon2': '很高兴再见到您，{name}',
  'gr_afternoon3': '您回来了，{name}',
  'gr_evening1': '晚上好，{name}',
  'gr_evening2': '祝您有个美好的夜晚，{name}',
  'gr_evening3': '您回来了，{name}',
  'gr_weekend1': '周末愉快，{name}',
  'gr_weekend2': '享受周末吧，{name}',
  'gr_playing1': '正听得起劲，{name}',
  'gr_playing2': '选得好，{name}',
  'gr_playing3': '音质真不错，{name}',
  'gr_heavy1': '依然是资深乐迷，{name}',
  'gr_heavy2': 'Scrobble 一首接一首，{name}',
  'gr_birthday1': '账号周年快乐，{name}！',
  'gr_birthday2': '已经一起走过 {years} 年了，{name}！',
  'gr_catchup1': '{friend}快追上您了，{name}！',
  'gr_catchup2': '当心，{friend}就在您身后，{name}',
  'gr_christmas1': '圣诞快乐，{name}！',
  'gr_christmas2': '节日快乐，{name}',
  'gr_newyear1': '新年快乐，{name}！',
  'gr_newyear2': '愿新的一年满是音乐，{name}！',
  'gr_easter1': '复活节快乐，{name}！',
  'gr_easter2': '祝您复活节愉快，{name}',
  'gr_spring1': '春天来了，{name}',
  'gr_spring2': '来个春日歌单吧，{name}？',
  'gr_summer1': '夏日气息，{name}',
  'gr_summer2': '享受阳光吧，{name}',
  'gr_autumn1': '秋日氛围，{name}',
  'gr_autumn2': '落叶纷飞，音乐常在，{name}',
  'gr_winter1': '与音乐共度冬天，{name}',
  'gr_winter2': '用音乐取暖吧，{name}',
  'hdr_pick_t': '从设备选择图片',
  'hdr_pick_s': '保存在应用内，优先于链接使用',
  'hdr_pick_set': '正在使用设备图片（替代链接）',
  'hdr_remove_t': '移除设备图片',
  'hdr_too_big': '图片过大（最大 4 MB）',
  'hdr_invalid': '无效图片',
  'cache_confirm_t': '清除此缓存？',
  'cache_confirm_b': '将删除{name}。此操作无法撤销。',
  'cache_api_limit_t': 'API 数据上限',
  'cache_api_limit_s': '已存储 API 数据的最大大小，优先删除最旧的数据。',
  'key_internal_use': '使用应用内置密钥',
  'key_internal_help': '备用选项：此密钥由多个用户共用，可能达到上限或失效，部分功能可能因此出错。请尽量使用您自己的密钥。',
  'key_internal_active': '应用内置密钥',
  'key_fallback_title': '内置密钥作为备用',
  'key_fallback_sub': '会优先使用您自己的密钥。如果 Last.fm 拒绝该密钥，应用会自动改用内置密钥重试。',
  'key_use_own': '使用我自己的 API 密钥',
  'key_change_title': '更换 API 密钥',
  'key_change_sub': '把您的密钥换成另一个，或改用应用内置密钥。',
  'key_change_sub_internal': '您当前使用的是应用的共用密钥。添加您自己的密钥后，就不再受其他用户使用上限的影响。',
  'key_change_intro': '为此账号输入新的 API 密钥，或切换回应用内置密钥。您的用户名和统计数据不会改变。',
  'key_change_intro_internal': '此账号目前使用的是应用内置密钥。请在下方粘贴您自己的 Last.fm API 密钥来替换它。您的用户名和统计数据不会改变。',
  'key_change_hint': 'API 密钥为 32 位字符。您可以在 last.fm/api/accounts 创建或查看自己的密钥。',
  'key_change_invalid_len': 'API 密钥必须正好是 32 位字符，请确认您已完整复制。',
  'key_change_same': '此账号已在使用这个密钥，请输入另一个密钥。',
  'key_change_check_failed': 'Last.fm 未接受此密钥。请检查密钥是否正确以及网络是否正常，然后重试。',
  'key_change_favorites_warn': '收藏连接将被移除，因为它依赖于旧密钥。之后您可以用您的私密密钥重新连接。',
  'key_change_apply': '应用',
  'key_change_success': 'API 密钥已更新。',
  'key_internal_fav_note': '收藏功能需要您自己的 API 密钥和 Last.fm 私密密钥。请在上方添加您自己的密钥后再启用。',
  'faq_q15': '登录后还能更换 API 密钥吗？',
  'faq_a15': '可以。前往设置 > 账号，点按“更换 API 密钥”。您可以把密钥换成另一个，或者在最初选择了内置密钥的情况下添加自己的密钥。您的统计数据不变，只需重新设置收藏连接。',
  'nothing_wip_badge': '改进中',
  'nothing_wip_msg': 'Nothing OS 风格正在改进中，因此暂时无法使用。它可能会在后续版本中开放。',
  'ui_play_preview': '播放试听',
  'ntf_test_title': '🔔 测试通知',
  'ntf_test_body': 'LastStats 通知运行正常！',
  'ui_not_enough_data_yet_sy': '数据还不够，请在设置中同步完整历史记录。',
  'ui_level': '等级 {level}',
  'ui_fetching': '正在获取 {currentYea}…（{yearIndex}/{totalYears}）',
  'ui_which_chart': '选择图表',
  'ui_which_period': '选择时间段',
  'ui_all_time': '全部时间',
  'ui_exporting': '正在导出…',
  'ui_chart_not_available_fo': '所选时间段无法显示此图表',
  'ui_could_not_generate_the': '无法生成图片，请重试。',
  'ui_error': '出了点问题',
  'ui_loading_history': '正在加载历史记录{yearLabel}… {pct}%',
  'ui_charts_will_be_more_ac': '加载完成后图表会更准确。',
  'ui_load_the_full_history_': '加载完整历史记录以查看所有年份。',
  'ui_load': '加载',
  'ui_based_on_scrobbles_all': '基于 {v_hourlyCou} 条听歌记录（所有年份）',
  'ui_all_available_years': '所有可用年份',
  'ui_based_on_scrobbles_fro': '基于 {v_selectedY} 年的 {v_hourlyCou} 条听歌记录',
  'ui_based_on_recent_scrobb': '基于最近 {v_hourlyCou} 条听歌记录',
  'ui_analysing_your_last_20': '正在分析您最近约 200 条听歌记录',
  'ui_all_time_loading': '全部时间（{v_selectedY} 加载中）',
  'ui_all_time_2': '全部时间',
  'ui_export_a_chart': '导出图表',
  'ui_scrobble_progression': 'Scrobble 进度',
  'ui_your_musical_genres': '您的音乐风格',
  'ui_based_on_your_top_arti': '基于您的常听艺术家（全部时间）',
  'ui_listening_habits': '收听习惯',
  'ui_album_distribution': '专辑分布',
  'ui_listening_calendar': '收听日历',
  'ui_daily_activity_to': '每日活动 — {first} 至 {last}',
  'ui_daily_activity_all_yea': '每日活动 — 所有年份',
  'ui_daily_activity': '每日活动 — {v_selectedY}',
  'ui_load_history_to_see': '加载历史记录以查看 {v_selectedY}',
  'ui_daily_activity_last_12': '每日活动 — 最近 12 个月',
  'ui_all_years': '所有年份',
  'ui_listening_streaks': '连续收听',
  'ui_total': '总计',
  'ui_avg_mo': '月均',
  'ui_best_month': '最佳月份',
  'ui_hourly_distribution': '每小时分布',
  'ui_activity_by_day_of_wee': '每周活跃度',
  'ui_current_streak': '当前连续天数',
  'ui_d': '天',
  'ui_best_streak': '最长连续天数',
  'ui_best_streak_started_on': '最长连续记录始于 {bestStart}',
  'ui_no_data_for_this_perio': '该时段无数据',
  'ui_load_history_to_displa': '加载历史记录以显示{what}',
  'ui_less': '少',
  'ui_more': '多',
  'ui_scan_a_profile': '扫描个人资料',
  'ui_lvl': '等级 {level}',
  'ui_qr_code': '二维码？',
  'ui_add_a_qr_code_to_the_s': '要在分享的图片中添加二维码，让看到的人可以扫描您的个人资料吗？',
  'ui_no_qr': '无二维码',
  'ui_to_the_app': '指向应用',
  'ui_to_last_fm': '指向 Last.fm',
  'ui_compare_music_taste': '比较音乐品味',
  'ui_syncing_full_library': '正在同步数据…',
  'ui_see_more': '查看更多',
  'ui_no_achievements_unlock': '还没有解锁任何成就。继续听歌，解锁第一个吧！',
  'ui_no_animated_cover_for_': '此专辑没有动态封面',
  'ui_source': '来源：{source}',
  'ui_view_on_last_fm': '在 Last.fm 上查看',
  'ui_original_text_last_fm_': '原文来自 Last.fm — 翻译来自 Google 翻译',
  'ui_source_last_fm': '来源：Last.fm',
  'ui_dark': '深色',
  'ui_light': '浅色',
  'ui_system': '跟随系统',
  'ui_colored_widgets': '彩色小组件',
  'ui_tint_home_screen_widge': '用强调色为小组件着色',
  'ui_search_settings': '搜索设置…',
  'ui_no_settings_found': '没有与搜索匹配的设置',
  'ui_all': '全部',
  'ui_battery_saver': '省电模式',
  'ui_save_battery_fewer_eff': '省电，减少特效',
  'ui_musical_soulmates': '音乐上的灵魂伴侣',
  'ui_great_compatibility': '非常合拍',
  'ui_some_common_ground': '有些共同点',
  'ui_fairly_different_taste': '口味差异较大',
  'ui_worlds_apart_musically': '音乐品味截然不同',
  'ui_this_is_your_own_profi': '这是您自己的资料！',
  'ui_artists_from_your_hist': '来自您收听记录的 {uniqueArti} 位艺术家 · {targetUser} 的完整曲库',
  'ui_artists_from_your_hist_2': '来自您收听记录的 {uniqueArti} 位艺术家 · {targetUser} 的前 200 名',
  'ui_full_library_api': '完整曲库（API）',
  'ui_top_200_artists_tracks': '前 200 名艺术家与歌曲（API）',
  'ui_could_not_work_out_the': '无法计算兼容度。',
  'ui_music_compatibility': '音乐契合度',
  'ui_analyzing_musical_tast': '正在分析音乐品味…',
  'ui_artist': '{v_totalArti} 位艺术家',
  'ui_track': '{v_totalTrac} 首歌曲',
  'ui_album': '{v_totalAlbu} 张专辑',
  'ui_shared_tracks': '共同歌曲',
  'ui_shared_artists': '共同艺术家',
  'ui_no_shared_artists_foun': '未找到共同的艺术家。',
  'ui_shared_albums': '共同专辑',
  'ui_play_count_unavailable': '其中一方的播放次数不可用。',
  'ui_you_listen_to_this_x_m': '您听这个的次数是 {theirUsern} 的 {x} 倍。',
  'ui_listens_to_this_x_more': '{theirUsern} 听这个的次数是您的 {x} 倍。',
  'ui_you_both_listen_to_thi': '您二位听这个的频率差不多。',
  'ui_plays': '{plays} 次播放',
  'ui_compatibility': '契合度',
  'ui_you_both_love': '您二位都超爱',
  'ui_shared_top_artist': '共同的最爱艺术家',
  'ui_achievements': '成就',
  'ui_qr_not_recognized_not_': '无法识别二维码 — 不是 LastStats/Last.fm 个人资料',
  'ui_scan_a_profile_s_qr_co': '扫描个人资料二维码',
  'ui_favorites': '精选推荐',
  'ui_advanced_youtube_music': '功能强大的 YouTube Music 客户端。',
  'ui_syncs_the_glyphs_of_no': '将 Nothing 手机的 Glyph 灯效与音乐同步。',
  'ui_sources': '来源',
  'ui_official_flutter_docs_': 'Flutter 官方文档。',
  'ui_official_material_3_gu': '面向 Flutter 的 Material 3 官方指南。',
  'ui_flutter_api_reference_': 'Material 3 主题的 Flutter API 参考。',
  'ui_official_flutter_packa': '用于自适应布局的 Flutter 官方包。',
  'ui_android_widgets': 'Android 小组件',
  'ui_applies_the_accent_col': '将强调色应用到主屏幕小组件的背景。关闭时为纯白或纯黑。',
  'ui_turns_off_tilt_paralla': '关闭倾斜视差，限制屏幕刷新率，并降低后台更新频率 — 其他一切保持完整品质（图片、导出、分享卡片）。',
  'ui_always_on': '始终开启',
  'ui_force_eco_mode_on_rega': '无论电量多少都强制开启省电模式。',
  'ui_auto_activate': '自动启用',
  'ui_turn_on_below_a_batter': '电量低时开启省电模式',
  'ui_switches_on_by_itself_': '当电量变低时,省电模式会自动开启。您之后可以在设置中选择具体的电量。',
  'ui_threshold': '阈值',
  'ui_choose_the_tab_display': '选择应用启动时显示的标签页。',
  'ui_the_selected_tab_will_': '所选标签页将在下次启动应用时显示。',
  'ui_friends_sync': '好友同步',
  'ui_sync_frequency': '同步频率',
  'ui_daily': '每天',
  'ui_resync_everyone': '全部重新同步',
  'ui_version_history': '版本历史',
  'ui_could_not_load_release': '无法加载版本历史。请检查网络连接后重试。',
  'ui_installed_dev_build_un': '已安装：开发版本（版本未知）',
  'ui_installed': '已安装：{displayVer}',
  'ui_search_a_version_or_ch': '搜索版本或更新日志…',
  'ui_official': '官方',
  'ui_no_release_matches_you': '没有符合搜索的版本。',
  'ui_latest': '最新',
  'ui_installed_2': '已安装',
  'ui_no_description': '此版本没有说明。',
  'ui_download': '下载',
  'ui_view_release': '查看发布页',
  'ui_details': '详情',
  'ui_all_past_releases_chan': '所有历史版本、更新日志和下载',
  'ui_please_fill_both_field': '请填写两个输入框后再继续。',
  'svc_title': '请选择您的服务',
  'svc_sub': 'LastStats 会从这两个服务之一读取您的播放记录。',
  'svc_lfm_s': '您的 Last.fm 历史记录。注意：Last.fm API 将收费，2026 年 12 月 1 日起 API 密钥需要 Last.fm Pro。',
  'svc_lfm_paid': 'API 收费',
  'svc_lb_s': '免费且开源（MetaBrainz）。使用您的用户令牌即可轻松登录。',
  'svc_free': '免费',
  'svc_back': '更换服务',
  'svc_lfm_note': '自 2026 年 12 月 1 日起，Last.fm API 密钥需要 Last.fm Pro 订阅（针对密钥所有者）。您的账户和历史记录不会改变。',
  'svc_lfm_pro': '查看 Last.fm Pro',
  'lb_title': '登录 ListenBrainz',
  'lb_steps': '1. 创建免费的 ListenBrainz 账户或登录。2. 打开您的 ListenBrainz 设置。3. 复制您的用户令牌并粘贴到此处。',
  'lb_token': '用户令牌',
  'lb_create': '创建 ListenBrainz 账户',
  'lb_get_token': '获取我的令牌',
  'lb_docs': 'API 帮助',
  'lb_connect': '连接',
  'lb_invalid': '令牌无效。请在您的 ListenBrainz 设置中检查。',
  'lb_neterr': '无法连接 ListenBrainz。请检查您的网络连接。',
  'lb_ok': '已连接 ListenBrainz（{name}）。',
  'lb_empty': '请粘贴您的令牌以继续。',
  'sw_title': '发现本地数据',
  'sw_body': '应用中已保存 {n} 条本地播放记录。切换到新服务后要如何处理？',
  'sw_transfer': '转移',
  'sw_transfer_s': '将这些记录发送到 ListenBrainz，并保留在应用中。',
  'sw_merge': '合并',
  'sw_merge_s': '保留旧数据并添加新服务的数据。冲突时以 Last.fm 为准。',
  'sw_fresh': '重新开始',
  'sw_fresh_s': '删除本地数据并从新服务重新加载。',
  'sw_ok': '确定',
  'sw_sending': '正在发送播放记录… {done} / {total}',
  'sw_merging': '正在合并… {year}',
  'sw_fail': '转移失败。您的本地数据已保留。',
  'lfm_create': '创建 Last.fm 账户',
  'conn_lb_desc': '您的播放记录通过用户令牌从 ListenBrainz 读取。不会向 Last.fm 发送任何请求。',
  'acct_lb_token': 'ListenBrainz 令牌',
  'acct_lb_info': '令牌位于您的 ListenBrainz 设置中。请妥善保密：它可访问您的账户。',
  'acct_lb_profile': 'ListenBrainz 个人资料',
  'acct_lb_view': '在 ListenBrainz 查看',
  'acct_switch': '更换服务',
  'acct_switch_s': '在 Last.fm 与 ListenBrainz 之间切换',
  'ui_api_key_must_be_32_cha': 'API 密钥必须正好是 32 个字符。',
  'ui_profile_not_found': '找不到该用户资料。请检查用户名后重试。',
  'ui_chart_monthly': '月度柱状图',
  'ui_chart_cumul': '进度趋势',
  'ui_chart_genres': '音乐风格',
  'ui_chart_habits': '收听习惯',
  'ui_chart_artists': '艺术家分布',
  'ui_chart_albums': '专辑分布',
  'ui_chart_calendar': '收听日历',
  'ui_chart_streaks': '连续收听',
  'ui_band_night': '夜间',
  'ui_band_morning': '上午',
  'ui_band_afternoon': '下午',
  'ui_band_evening': '晚上',
  'qs_t1_t': 'OLED 模式',
  'qs_t1_s': '纯黑背景，可在 OLED 屏幕上省电',
  'qs_t2_t': '省电模式',
  'qs_t2_s': '减少动画和后台更新以节省电量',
  'qs_t3_t': '新闻通知',
  'qs_t3_s': '推送新功能、修复和公告',
  'qs_t4_t': '触觉反馈',
  'qs_t4_s': '点按、选择或滑动时轻微震动',
  'qs_t5_t': '成就',
  'qs_t5_s': '显示已解锁的成就和您的等级',
  'qs_l1_t': '强调色',
  'qs_l2_t': '主题',
  'qs_l3_t': '语言',
  'qs_l4_t': '音乐平台',
  'qs_l5_t': '账户',
  'qs_l6_t': '同步',
  'qs_l7_t': '缓存',
  'img_src_lastfm': '来源：Last.fm',
  'img_src_ytmusic': '来源：YouTube Music',
  'img_src_itunes': '来源：iTunes',
  'img_src_deezer': '来源：Deezer',
  'img_src_audiodb': '来源：TheAudioDB',
  'img_src_musicbrainz': '来源：MusicBrainz',
  'img_src_wikipedia': '来源：维基百科',
  'ds_type_artist': '艺术家',
  'ds_type_album': '专辑',
  'ds_type_track': '歌曲',
  'pf_1': '👤 用户资料',
  'pf_2': '🎤 热门艺术家 — 全部时间',
  'pf_3': '💿 热门专辑 — 全部时间',
  'pf_4': '🎵 热门歌曲 — 全部时间',
  'pf_5': '⏱️ 最近播放',
  'pf_6': '🗓️ 本周',
  'pf_7': '📅 本月',
  'pf_8': '📅 最近 3 个月',
  'pf_9': '📅 最近 6 个月',
  'pf_10': '📅 最近 12 个月',
  'pf_11': '📊 月度历史',
  'pf_12': '❤️ 喜欢的歌曲',
  'pf_13': '🗓️ 热门艺术家 — 本周',
  'pf_14': '🗓️ 专辑和歌曲 — 本周',
  'ds_tier_next': '{n} / {next} 升至下一级',
  'ds_tier_max': '已达到最高等级 🎉',
  'ds_tier_first': '听这首歌来解锁第一个等级（{n} 次播放起）。',
  'sl_import': '正在导入您的数据',
  'sl_done': '已导入！',
  'sl_connect': '正在连接 Last.fm…',
  'sec_chart': '图表/日历',
  'stat_avg_day': '日均',
  'stat_avg_week': '周均',
  'stat_days_active': '活跃天数',
  'stat_scrobbles_week': '本周 scrobbles',
  'accent_purple': '紫色',
  'accent_blue': '蓝色',
  'accent_green': '绿色',
  'accent_red': '红色',
  'accent_orange': '橙色',
  'accent_pink': '粉色',
  'accent_teal': '青绿色',
  'accent_neutral': '中性色',
  'shape_title': '图片形状',
  'shape_covers': '封面、艺术家和专辑',
  'shape_mix': '混合',
  'shape_square': '方形',
  'shape_circle': '圆形',
  'shape_pick_one': '或选择单一形状',
  'friend_listening': '正在收听',
  'friend_offline': '离线',
  'tier_none': '暂无等级',
  'src_title': '来源',
  'src_scrobbles_meta': 'Scrobbles 和元数据',
  'src_artwork': '封面图',
  'src_audio_preview': '音频试听',
  'src_video_artwork': '视频封面',
  'tip_love': '收藏',
  'rail_expand': '展开侧边栏',
  'rail_collapse': '收起侧边栏',
  'a11y_loading': '加载中',
  'bk_pick_folder': '选择自动备份文件夹',
  'bk_save_title': '保存 LastStats 备份',
  'bk_pick_file': '选择 LastStats 备份文件',
  'nch_milestone_d': '达到 scrobble 里程碑时通知您',
  'nch_grand_d': '重大里程碑的特别提醒（1K、10K、100K、1M…）',
  'nch_recap_d': '每日和每周收听摘要',
  'nch_update_d': 'LastStats 有新版本时通知您',
  'nch_news_d': 'LastStats 的新功能、修复和公告',
  'nch_sync_d': '同步完整 scrobble 历史时的进度',
  'ntf_grand_1000000': '一百万次 scrobble，太传奇了。🎸',
  'ntf_grand_500000': '五十万次 scrobble，您从不停歇。🎧',
  'ntf_grand_250000': '{n} 次 scrobble，音乐永不停歇。🎶',
  'ntf_grand_100000': '{n} 次 scrobble！您是真正的音乐迷。🔥',
  'ntf_grand_50000': '{n} 次 scrobble，令人印象深刻。🎵',
  'ntf_grand_25000': '{n} 次 scrobble，依然势头强劲！',
  'ntf_grand_10000': '{n} 次 scrobble，您突破了五位数！🎉',
  'ntf_grand_5000': '{n} 次 scrobble，还在继续！',
  'ntf_grand_1000': '您的前 {n} 次 scrobble，旅程开始了。🎵',
  'ntf_update_title': 'LastStats {v} 现已推出',
  'ntf_update_body': '新版本已可下载。',
  'ntf_milestone_title': '🎵 里程碑：{n} 次 scrobble',
  'ntf_milestone_body': '您刚刚在 Last.fm 上达到了 {n} 次 scrobble 🎶',
  'ntf_daily_title': '📊 每日回顾 · {d}',
  'ntf_weekly_title': '📅 每周回顾 · {w}',
  'ntf_year_title': '👀 您的 {y} 年度回顾已就绪',
  'ntf_year_body': '回顾您的 {y} 年音乐：艺术家、歌曲、专辑等更多内容。',
  'ntf_recap_body': '{n} 次 scrobble · 最多：{a}',
  'ntf_n_today': '今天 {n} 次 scrobble',
  'ntf_n_week': '本周 {n} 次 scrobble',
  'ntf_top_artist': '最常听艺术家：{a}',
  'ntf_update_avail': '🆕 有可用更新',
  'ntf_update_ready': 'LastStats {v} 已就绪，点按查看。',
  'ntf_sync_title': '🔄 正在同步 scrobble…',
  'ntf_sync_done': '✅ Scrobble 已同步',
  'ntf_sync_new': '已添加 {n} 条新 scrobble。',
  'ntf_grand_t': '{v} 次 scrobble！',
  'ntf_year': '{y} 年',
  'ntf_week': '第 {w} 周',
  'reorder': '调整顺序',
  'sp_login_t': '登录 Spotify',
  'sp_login_hint': '请使用您的 Spotify 邮箱和密码登录。登录成功后此窗口会自动关闭。',
  'sp_risk_note': '注意：此功能依赖 Spotify 的非官方调用，而非官方 API。Spotify 可能随时更改或封锁它，它可能停止工作，使用它也可能违反 Spotify 的使用条款，从而可能导致您的 Spotify 账号受到限制。使用风险自负。',
  'sp_perf_note': '性能:查找 Canvas 时会在后台运行一个隐藏的网页播放器,并产生额外的网络请求。这可能会增加电量、流量和内存消耗,并让应用稍微变慢。如果您有所察觉,请把 Spotify 从此列表中移除。',
  'sp_t': 'Spotify (Canvas)',
  'sp_on': '已连接',
  'sp_off': '未连接',
  'sp_off_s': '您已退出 Spotify。重新登录后才能获取 Canvas 动态封面。',
  'mv_ytdash_t': '也用于仪表盘',
  'mv_ytdash_s': '在仪表盘的个人资料背景动画封面中也使用 YouTube（默认关闭）',
  'yr_title': '年度回顾',
  'yr_loading': '您的年度回顾马上就好，稍等片刻…',
  'yr_error': '哎呀，无法加载您的 scrobble，请检查网络连接。',
  'yr_retry': '重试',
  'yr_empty': '{year} 年没有 scrobble……难道是休假年？',
  'yr_intro_h': '您的 {year} 音乐年',
  'yr_scrobbles': '次 scrobble',
  'yr_total_intro': '今年您一共听了足足：',
  'yr_hours': '大约相当于 {h} 小时的音乐。您的耳朵值得一枚奖牌！（估算）',
  'yr_top_artist': '您的本命艺人',
  'yr_top_artists': '热门艺人',
  'yr_top_tracks': '热门歌曲',
  'yr_top_albums': '热门专辑',
  'yr_plays': '{n} 次播放',
  'yr_months_h': '按月回顾您的一年',
  'yr_months': '1月,2月,3月,4月,5月,6月,7月,8月,9月,10月,11月,12月',
  'yr_best_month': '您最活跃的月份是{m}，共 {n} 次 scrobble。那个月热度爆表！',
  'yr_best_day': '您最疯狂的一天是{d}，共 {n} 次 scrobble。耳机都冒烟了！',
  'yr_when_h': '您的收听时间',
  'yr_p_night': '您主要在深夜听歌：妥妥的夜猫子',
  'yr_p_morning': '您主要在早上听歌：咖啡配歌单，黄金搭档',
  'yr_p_day': '您主要在白天听歌：为日常配上原声',
  'yr_p_evening': '您主要在晚上听歌：氛围感才是您的菜',
  'yr_peak': '您的收听高峰在 {h} 点左右，最喜欢的日子是{d}。',
  'yr_streak_h': '您的坚持，堪比节拍器',
  'yr_streak': '天',
  'yr_style': '自定义',
  'yr_flame_h': '连续收听的歌曲',
  'yr_flame_s': '在您连续{n}天期间的播放次数',
  'yr_day_h': '单曲单日纪录',
  'yr_day_s': '一天之内，在{d}。真是热爱！',
  'yr_active': '在 {t} 天中，您有 {n} 天在听音乐。其余的日子呢？静得有点可疑……',
  'yr_disc_h': '新发现',
  'yr_new': '位艺人是今年的新发现。好奇宝宝！',
  'yr_unique': '您一共听了 {a} 位不同的艺人和 {t} 首不同的歌曲。口味真丰富！',
  'yr_card_hours': '小时（估算）',
  'yr_card_streak': '天连续',
  'yr_friends_h': '您和好友对比',
  'yr_rank': '您在 {n} 人中排名第 {r}',
  'yr_you': '您',
  'yr_twin_h': '您的音乐知己',
  'yr_twin_s': '你们有 {n} 位共同喜爱的艺人。英雄所见略同！',
  'yr_top_track': '您的年度单曲',
  'yr_top_album': '您的心头好专辑',
  'yr_line_h': '累计的一年',
  'yr_cal_h': '日历中的一年',
  'yr_share_h': '播放都去哪了',
  'yr_share_err': '哎呀，无法生成图片，请重试。',
  'yr_share_profile': '使用头像作为背景',
  'yr_months_full': '1月,2月,3月,4月,5月,6月,7月,8月,9月,10月,11月,12月',
  'yr_months_gen': '1月,2月,3月,4月,5月,6月,7月,8月,9月,10月,11月,12月',
  'yr_day_fmt': '{m}{d}日',
  'yr_weekdays_full': '星期一,星期二,星期三,星期四,星期五,星期六,星期日',
  'sp_need': 'Spotify 需要登录：个人资料 > 连接页面。',
  'conn_title': '连接',
  'conn_btn_t': '连接页面',
  'conn_btn_s': 'Last.fm、Spotify 和 API 密钥',
  'conn_sp_desc': '用于视频封面（Canvas）。需要 Spotify 账户。',
  'conn_connect': '连接',
  'conn_disconnect': '断开连接',
  'conn_keys': 'API 密钥',
  'conn_manage': '管理账户',
  'conn_test': '测试 Spotify',
  'conn_testing': '测试中…',
  'conn_q_note': 'Spotify Canvas 只有一种画质。画质设置仅适用于 Apple Music 和 YouTube。',
  'conn_lfm_desc': '您的 Last.fm 历史记录通过您自己的 API 密钥读取（2026 年 12 月 1 日起需要 Last.fm Pro）。',
  'conn_lfm_web': '使用 Last.fm 登录',
  'lfm_login_t': '登录 Last.fm',
  'lfm_login_hint': '请在 Last.fm 网站登录。应用会识别您的用户名，然后关闭此窗口。',
  'lfm_web_sub': '无需 API 密钥:应用会使用其内置的密钥。',
  'lfm_manual_hint': '未能自动识别用户名。登录后请在下方输入。',
  'lfm_manual_label': '用户名',
  'rec': '推荐',
  'not_rec': '不推荐',
  'sm_title': '连接方式',
  'sm_key_t': '我的 API 密钥',
  'sm_key_s': '您拥有独立的使用额度,并且可以使用收藏功能。',
  'sm_builtin_t': '内置密钥',
  'sm_builtin_s': '只需要您的用户名。使用额度与其他用户共享。',
  'wl_title': '欢迎',
  'wl_sub': '请输入您的 Last.fm 用户名和您自己的 API 密钥。',
  'sr_from_recent': '来自您最近的搜索',
  'sr_recent': '最近搜索',
  'sr_suggestions': '搜索建议',
  'sr_recommended': '推荐',
  'sr_best': '最佳结果',
  'cx_best_month': '最佳月份',
  'cx_active_days': '活跃天数',
  'cx_peak_hour': '高峰时段',
  'cx_top_artist': '第一艺术家',
  'cx_top_artists': '热门艺术家',
  'cx_by_month': '按月',
  'cx_cumulative': '累计',
  'cx_clock': '收听时钟',
  'cx_others': '其他',
  'cx_artist_distribution': '艺人分布',
  'cx_daypart': '时段分布',
  'cx_night': '凌晨',
  'cx_morning': '早晨',
  'cx_afternoon': '下午',
  'cx_evening': '晚上',
  'cx_intensity': '每日强度',
  'cx_days': '天',
  'cx_busiest': '听歌最多的日子',
  'cx_weekend': '工作日与周末',
  'up_title': '更新',
  'up_downloading': '正在下载…',
  'up_perm_title': '需要授权',
  'up_perm_body': '请在 Android 设置中允许 LastStats 安装应用，然后返回此处点按“重试”。',
  'up_installing': '正在打开安装程序…',
  'up_restart': 'LastStats 将关闭并重新启动。',
  'up_failed': '下载失败',
  'up_failed_body': '请在浏览器中打开链接以安装更新。',
  'up_retry': '重试',
  'up_browser': '在浏览器中打开',
  'up_close': '关闭',
  'up_saved': '已保存到“下载”',
  'up_background': '在后台继续',
  'ntf_dl_section': '下载',
  'ntf_dl_title': '下载通知',
  'ntf_dl_sub': '下载时显示进度条，后台也可用',
  'ntf_dl_ready': '下载完成',
  'ntf_dl_failed': '下载失败',
  'ntf_act_read': '标为已读',
  'ntf_act_read_all': '全部标为已读',
  'ntf_act_install': '安装',
  'ntf_dl_install_hint': '点按以安装更新',
  'up_open_downloads': '打开“下载”',
  'ic_title': '应用图标',
  'ic_note': '离开应用后图标会在应用列表中更换。主屏幕上请重新放置应用，或用下方按钮添加快捷方式。',
  'ic_default': '经典',
  'ic_white': '浅色',
  'ic_nothing_black': 'Nothing 深色',
  'ic_nothing_white': 'Nothing 浅色',
  'ic_blue': '蓝色',
  'ic_red': '红色',
  'ic_pin': '添加到主屏幕',
  'lbl_step1_t': '打开您的令牌页面',
  'lbl_step1_s': '登录 ListenBrainz，然后复制“用户令牌”。',
  'lbl_open': '打开 ListenBrainz',
  'lbl_step2_t': '粘贴令牌',
  'lbl_paste': '粘贴',
  'lbl_detected': '在剪贴板中找到令牌',
  'lbl_use': '使用',
  'lbl_format_ok': '令牌格式有效',
  'lbl_format_bad': '令牌形如 xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
  'lbl_err_format': '这不是令牌。请不要输入用户名：请在 ListenBrainz 设置中复制“用户令牌”。',
  'lbl_err_invalid': 'ListenBrainz 拒绝了此令牌。请检查是否完整，或复制一个新的。',
  'lbl_err_rate': 'ListenBrainz 要求稍等片刻，请几秒后重试。',
  'lbl_err_server': 'ListenBrainz 服务器响应异常，请稍后重试。',
  'lbl_err_net': '无法连接 ListenBrainz，请检查网络。',
  'lbl_err_after': '登录已通过，但打开应用失败：{e}',
  'lbl_options': '选项',
  'lbl_why': '令牌可加快读取历史记录，并支持收藏曲目。',
  'lbl_connected': '已登录为 {u}',
  'svc_recommended': '推荐',
  'lfm_seg_key': '我的密钥',
  'lfm_seg_builtin': '内置密钥',
  'lfm_seg_web': '网站',
  'acct_lb_change': '更换令牌',
  'acct_lb_change_s': '粘贴新的 ListenBrainz 令牌',
  'acct_lb_changed': '令牌已更新',
  'bk_keys_desc_lb': '选择要从此备份恢复的 ListenBrainz 登录信息。',
  'lbl_restore_bad': '此备份不包含可用的登录信息。',
  'lbl_restored': '备份已恢复',
  'lbl_step3_t': '登录',
  'lbl_api_lb': '使用您的 ListenBrainz 令牌。限制：每秒 1 次请求，自动管理。',
  'lbl_key_needed': '公共密钥已停用：请在 设置 › 连接 中添加您自己的 Last.fm API 密钥。',
  'api_img_sec': '图片来源',
  'api_img_sub': '拖动排序。将使用第一个找到图片的已启用来源。',
  'api_vid_sec': '视频来源',
  'api_img_clear': '清除图片缓存（应用新顺序）',
  'api_img_cleared': '图片缓存已清除',
  'api_help': '“今日请求”：自午夜起发送给各服务的调用次数。“错误”：失败的调用（服务宕机、拒绝访问或无网络）。“被限流”：服务返回“请求过多”，该服务会暂停一小段时间。',
  'err_bad_response': '服务器返回了无效的响应。服务可能不可用或正在维护。请稍后重试。',
  'dash_offline_cache': '无法连接到服务器。正在显示此设备上已保存的数据。',
  'news_btn': '公告',
  'news_btn_sub': '故障、维护和各类通知',
  'news_load_failed': '无法加载公告。请检查您的网络连接，然后重试。',
  'news_retry': '重试',
  'faq_lfm_h': 'Last.fm 常见问题',
  'faq_lb_h': 'ListenBrainz 常见问题',
  'ap_cov_section': '封面与成就',
  'faq_lfm_q1': '如何获取 Last.fm API 密钥？',
  'faq_lfm_a1': '登录 Last.fm，打开 last.fm/api/account/create，填写应用名称和简短说明（回调 URL 可以留空），然后复制 last.fm/api/accounts 上显示的“API 密钥”。将它与您的 Last.fm 用户名一起输入 LastStats。密钥属于您本人：LastStats 没有任何共享密钥。',
  'faq_lfm_q2': '2026 年 12 月 1 日会有什么变化？',
  'faq_lfm_a2': 'Last.fm 已宣布，自 2026 年 12 月 1 日起，API 密钥只有在其所属的 Last.fm 账户订阅了 Last.fm Pro 时才能使用。免费账户拥有的密钥将在当天失效。只有密钥的所有者需要付费：您的收听历史和账户不会改变。如果您不想订阅，可以改用免费的 ListenBrainz。',
  'faq_lfm_q3': '如果我的密钥失效了会怎样？',
  'faq_lfm_a3': 'LastStats 会继续显示已保存在您设备上的数据，但无法再加载新数据，并会显示错误提示。订阅 Last.fm Pro（或输入由 Pro 账户拥有的密钥）即可恢复正常，也可以在“设置”>“账户”中切换到 ListenBrainz。',
  'faq_lfm_q4': '我的收听记录如何到达 Last.fm？',
  'faq_lfm_a4': 'LastStats 只显示您的 Scrobble，自身不会记录任何内容。请使用已登录您的 Last.fm 账户的 Scrobble 应用或支持 Last.fm 的播放器（例如 Android 上的 Pano Scrobbler）。',
  'faq_lfm_q5': '为什么看不到我最新的 Scrobble？',
  'faq_lfm_a5': '请先确认您的 Scrobble 工具正常工作：该曲目必须出现在您的 last.fm 个人资料中。然后下拉屏幕刷新 LastStats。Last.fm 会限制应用可发送的请求数量，因此 LastStats 会放慢调用频率：历史记录非常庞大时，首次同步可能需要一些时间。',
  'faq_lb_q1': '在哪里可以找到我的 ListenBrainz 用户令牌？',
  'faq_lb_a1': '登录 listenbrainz.org，打开 listenbrainz.org/settings/，复制“User token”。请妥善保密：它用于识别您的身份。在 LastStats 中输入您的 ListenBrainz 用户名（即 MusicBrainz 用户名）和令牌。令牌仅保存在您的设备上。',
  'faq_lb_q2': 'ListenBrainz 是免费的吗？',
  'faq_lb_a2': '是的。ListenBrainz 是非营利组织 MetaBrainz Foundation 的开源项目，可免费使用。LastStats 只需要您的用户令牌：无需创建 API 密钥。您的收听记录是以 CC0 许可发布的公开数据。',
  'faq_lb_q3': '为什么我的统计是空的或缺失？',
  'faq_lb_a3': 'ListenBrainz 在自己的服务器上计算统计数据，因此新账户、大量导入之后或服务繁忙时可能会延迟。此时 API 只会回复尚未准备好。您的收听记录会先出现，统计数据随后才会出现。请稍后再试。',
  'faq_lb_q4': '如何把我的 Last.fm 历史记录导入 ListenBrainz？',
  'faq_lb_a4': '登录 listenbrainz.org（需要 MusicBrainz 账户），打开 listenbrainz.org/import-data/ 即可导入您的 Last.fm 收听记录。许多人同时导入时可能需要一些时间。切换服务时，LastStats 也会提供转移保存在您设备上的 Scrobble 的选项。',
  'faq_lb_q5': '如何把我的收听记录发送到 ListenBrainz？',
  'faq_lb_a5': 'LastStats 只显示您的收听记录。若要记录，请使用兼容 ListenBrainz 的播放器或 Scrobble 应用，并使用您的令牌登录；支持的应用列表见 listenbrainz.org。请注意，您的收听记录是公开的。',
};
