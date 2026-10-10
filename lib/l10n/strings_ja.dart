// lib/l10n/strings_ja.dart
// ══════════════════════════════════════════════════════════════════════════
//  Japanese
// ══════════════════════════════════════════════════════════════════════════

import "app_strings.dart";

class AppStringsJa implements AppStrings {
  const AppStringsJa();

  @override String get period7day => '週間';
  @override String get period1month => '月間';
  @override String get period3month => '3ヶ月';
  @override String get period6month => '6ヶ月';
  @override String get period12month => '年間';
  @override String get periodOverall => '全期間';
  @override String get navDashboard => 'ダッシュボード';
  @override String get navSearch => '検索';
  @override String get navRankings => 'ランキング';
  @override String get navCharts => 'チャート';
  @override String get navHistory => '履歴';
  @override String get navSettings => '設定';
  @override String get cacheTitle => 'ストレージ';
  @override String get cacheUsage => '使用量';
  @override String get cacheLimit => 'ストレージ上限';
  @override String get cacheLimitHint => '上限に達すると、最も使われていない画像が自動的に削除されます。';
  @override String get cacheClearSection => '消去';
  @override String get cacheImages => '画像';
  @override String get cacheImagesSubtitle => 'アーティスト・アルバム・トラックのアートワーク';
  @override String get cacheApiData => 'APIデータ';
  @override String get cacheApiDataSubtitle => 'トップアーティスト、アルバム、最近のトラックなど';
  @override String get cacheScrobbles => 'スクロブル履歴';
  @override String get cacheScrobblesSubtitle => 'ダウンロード済みの全スクロブル記録';
  @override String get cacheClearBtn => '消去';
  @override String get cacheConfirmScrobblesTitle => 'スクロブル履歴を消去しますか？';
  @override String get cacheConfirmScrobblesBody => '履歴全体が削除され、次回起動時に再ダウンロードされます。';
  @override String get cacheConfirmAllTitle => 'すべてのキャッシュを消去しますか？';
  @override String get cacheConfirmAllBody => '画像、APIデータ、スクロブル履歴がすべて削除されます。';
  @override String get cacheDelete => '削除';
  @override String get commonArtists => 'アーティスト';
  @override String get commonAlbums => 'アルバム';
  @override String get commonTracks => 'トラック';
  @override String get commonNoResults => '結果がありません';
  @override String get commonRetry => '再試行';
  @override String get commonCancel => 'キャンセル';
  @override String get commonApply => '適用';
  @override String get commonPlays => '再生回数';
  @override String get commonListeners => 'リスナー';
  @override String get commonNowPlayingBadge => '再生中';
  @override String get commonNowPlayingLong => '再生中';
  @override String get commonRecentTracks => '最近のトラック';
  @override String get commonNoRecentTracks => '最近のトラックはありません';
  @override String get commonTopArtists => 'トップアーティスト';
  @override String get rankingsTitle => 'ランキング';
  @override String get rankingsPodium => '表彰台';
  @override String get rankingsContinued => 'ランキングの続き';
  @override String get rankingsAllYears => '全期間';
  @override String get chartsTitle => 'チャート';
  @override String get chartsMonthly => 'スクロブル数（過去12ヶ月）';
  @override String get chartsArtistDist => 'トップアーティストの内訳';
  @override String get chartsMainstreamTitle => 'メジャー系 vs 発掘アーティスト';
  @override String get chartsMainstreamSubtitle => 'お気に入りアーティストの世界的な人気度。';
  @override String get chartsCompute => '計算';
  @override String get chartsRecompute => '再計算';
  @override String get chartsGem => '隠れた名アーティスト';
  @override String get chartsMainstream => 'メジャー系';
  @override String get historyTitle => '履歴';
  @override String get historySubtitle => '日ごとの再生履歴';
  @override String get historyToday => '今日';
  @override String get historySelectDate => '日付を選択';
  @override String get historyChronological => '時系列';
  @override String get historyList => 'リスト';
  @override String get historyStats => '統計';
  @override String get historyNoTracks => 'この日は再生履歴がありません';
  @override String get historyTopArtists => 'トップアーティスト';
  @override String get historyTopAlbums => 'トップアルバム';
  @override String get historyTopTracks => 'トップトラック';
  @override String get historyHourTracks => '曲';
  @override String get searchTitle => '検索';
  @override String get searchProfiles => 'プロフィール';
  @override String get searchHintBar => 'アーティスト、アルバム、トラック、プロフィールを検索…';
  @override String get searchHintProfiles => 'Last.fmユーザーを検索';
  @override String get searchHintArtists => 'アーティストを検索';
  @override String get searchHintAlbums => 'アルバムを検索';
  @override String get searchHintTracks => '曲を検索';
  @override String get searchTypePrompt => '上の検索バーに入力してください';
  @override String get searchAll => 'すべて';
  @override String get searchFolders => 'フォルダ';
  @override String get searchFoldersHint => 'フォルダを作成して曲・アルバム・アーティストを保存';
  @override String get perDay => '1日あたり';
  @override String get activityDays => 'アクティブ日数';
  @override String get dashStats => '統計';
  @override String get dashTopTracks => 'トップトラック';
  @override String get dashFriends => 'フレンド';
  @override String get dashRefresh => '更新';
  @override String get dashRefreshFriends => 'フレンドを更新';
  @override String get dashScrobbles => 'スクロブル数';
  @override String get dashScrobblesPerDay => '1日あたり';
  @override String get dashDaysActive => 'アクティブ日数';
  @override String get dashLastTrack => '最後に再生した曲';
  @override String get dashArtist1 => 'アーティスト1位';
  @override String get dashAlbum1 => 'アルバム1位';
  @override String get dashTrack1 => 'トラック1位';
  @override String get dashNoFriends => 'フレンドが見つかりません';
  @override String get dashResetCache => 'キャッシュをリセット';
  @override String get dashResetCacheConfirm => 'ローカルに保存されたスクロブルデータがすべて削除され、Last.fmから再ダウンロードされます。';
  @override String get dashFriendsActivity => 'Last.fmフレンドのアクティビティ';
  @override String get settingsTitle => '設定';
  @override String get settingsAppearance => '外観';
  @override String get settingsTheme => 'テーマ';
  @override String get settingsThemeAuto => '自動';
  @override String get settingsThemeLight => 'ライト';
  @override String get settingsThemeDark => 'ダーク';
  @override String get settingsAccentColor => 'アクセントカラー';
  @override String get settingsAccentAuto => '自動';
  @override String get settingsCustomColor => 'カスタム';
  @override String get settingsCustomColorEdit => '編集';
  @override String get settingsDynamicColor => 'ダイナミックカラー';
  @override String get settingsDayNightAccent          => '昼夜のアクセントカラー';
  @override String get settingsDayNightAccentToggle    => '昼と夜で別の色を使う';
  @override String get settingsDayNightAccentToggleSub => 'ダークテーマに別のアクセントカラーを使用します。';
  @override String get settingsDayNightAccentDark      => '色（ダークテーマ）';
  @override String get settingsDayNightUseHours        => '指定した時間を使う';
  @override String get settingsDayNightUseHoursSub     => '現在のテーマではなく時刻で色を切り替えます。';
  @override String get settingsDayNightDayStart        => '昼の開始時刻';
  @override String get settingsDayNightNightStart      => '夜の開始時刻';
  @override String get settingsMaterialYou => 'Material You';
  @override String get settingsMaterialYouSub => 'Androidの壁紙の色を使用';
  @override String get settingsMusicColor => '楽曲から色を取得';
  @override String get settingsMusicColorSub => '再生中のアルバムアートから色を抽出';
  @override String get settingsMusicColorNote => '再生中のアルバムアートの主要色がアクセントカラーになります。';
  @override String get settingsMusicColorLocked => '先にMaterial Youを無効にしてください';
  @override String get settingsStartupPage => '起動ページ';
  @override String get settingsStartupTab => '起動時のタブ';
  @override String get settingsDashboardSection => 'ダッシュボード';
  @override String get settingsHeaderImage => 'ヘッダー画像';
  @override String get settingsHeaderImageSub => '選択したアートワークがホーム画面の背景として表示されます。';
  @override String get settingsHeaderSource => 'ソース';
  @override String get settingsHeaderPeriod => '期間';
  @override String get settingsHeaderAnimation => 'トランジション';
  @override String get settingsHeaderAnimationSub => 'アートワークが切り替わる際のアニメーション。';
  @override String get settingsHeaderBlur => 'ぼかし';
  @override String get settingsHeaderBlurNone => 'なし';
  @override String get settingsHeaderCustomUrl => '画像URL';
  @override String get settingsHeaderCustomUrlHint => 'https://example.com/image.jpg';
  @override String get settingsHeaderCustomUrlSub => '画像の直接URLを貼り付けてください（jpg、png、webpなど）。';
  @override String get settingsHeaderApply => '適用';
  @override String get settingsHeaderFallback => 'デフォルト画像';
  @override String get settingsHeaderFallbackSub => '音楽が再生されていないときに表示されます。';
  @override String get settingsHeaderFallbackUrlLabel => 'デフォルト画像URL';
  @override String get settingsVisibleSections => '表示するセクション';
  @override String get settingsNowPlayingSection => '再生中';
  @override String get settingsStatsSection => '統計';
  @override String get settingsTopArtistsSection => 'トップアーティスト';
  @override String get settingsTopTracksSection => 'トップトラック';
  @override String get settingsFriendsSection => 'フレンド';
  @override String get settingsFriendsSectionSub => 'Last.fmフレンドのアクティビティ';
  @override String get settingsAccount => 'アカウント';
  @override String get settingsConnectedProfile => '連携中のLast.fmプロフィール';
  @override String get settingsLogout => 'サインアウト';
  @override String get settingsLogoutTitle => 'サインアウトしますか？';
  @override String get settingsLogoutContent => '認証情報は削除されます。';
  @override String get settingsLogoutConfirm => 'サインアウト';
  @override String get settingsBackup => 'バックアップと復元';
  @override String get settingsExport => '設定をエクスポート';
  @override String get settingsExportSub => 'JSONをクリップボードにコピー';
  @override String get settingsImport => 'バックアップを復元';
  @override String get settingsImportSub => '以前エクスポートしたJSONを貼り付け';
  @override String get settingsBackupInfo => '含まれる内容：テーマ、色、APIキー、ユーザー名、ヘッダー、お気に入り。バージョン間で互換性があります。';
  @override String get settingsUpdates => 'アップデート';
  @override String get settingsAutoUpdate => '自動チェック';
  @override String get settingsAutoUpdateSub => '1日1回';
  @override String get settingsCheckNow => '今すぐ確認';
  @override String get settingsUpToDate => '最新です';
  @override String get settingsCheckFailed => '確認に失敗しました。';
  @override String get settingsDownload => 'ダウンロード';
  @override String get settingsViewRelease => '表示';
  @override String get settingsAbout => 'アプリ情報';
  @override String get settingsVersion => 'バージョン';
  @override String get settingsWebVersion => 'Web版';
  @override String get settingsWebVersionSub => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode => 'ソースコード';
  @override String get settingsSourceCodeSub => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage => '言語';
  @override String get settingsAboutProjectDesc => 'LastStatsは個人のオープンソースプロジェクトです。不具合が含まれる場合があります。';
  @override String get settingsAboutSupport => 'プロジェクトを応援する';
  @override String get settingsAboutSupportSub => '⭐ GitHubでスターを付ける';
  @override String get settingsFaq => 'よくある質問';
  @override String get headerNowPlaying => '再生中';
  @override String get headerTopTrack => 'トラック1位';
  @override String get headerTopAlbum => 'アルバム1位';
  @override String get headerTopArtist => 'アーティスト1位';
  @override String get headerCustomImage => 'カスタム画像';
  @override String get headerThemeColor => 'テーマカラー';
  @override String get headerAnimNone => 'なし';
  @override String get headerAnimFade => 'フェード';
  @override String get headerAnimSlide => 'スライド';
  @override String get headerAnimZoom => 'ズーム';
  @override String get headerPeriodWeek => '週間';
  @override String get headerPeriodMonth => '月間';
  @override String get headerPeriodAllTime => '全期間';
  @override String get colorPickerTitle => 'カスタムカラー';
  @override String get colorPickerHue => '色相';
  @override String get colorPickerSaturation => '彩度';
  @override String get colorPickerBrightness => '明度';
  @override String get colorPickerQuickColors => 'クイックカラー';
  @override String get colorPickerInvalid => '無効な形式です';
  @override String get colorCustomTooltip => 'カスタム';
  @override String get exportTitle => '設定をエクスポート';
  @override String get exportFilename => 'ファイル名';
  @override String get exportJsonContent => 'JSONの内容';
  @override String get exportInfo => 'このJSONをコピーし、テキストファイルに貼り付けて.jsonという名前で保存してください';
  @override String get exportCopy => 'JSONをコピー';
  @override String get exportCopied => 'コピーしました！';
  @override String get importTitle => 'バックアップを復元';
  @override String get importHintLabel => 'LastStatsのバックアップをここに貼り付けてください。';
  @override String get importEmpty => '入力欄が空です。';
  @override String get importInvalidJson => '無効なJSONです。';
  @override String get importUnknownFile => '認識できないファイルです。';
  @override String get importInvalidFormat => '無効な形式です。';
  @override String get importSuccess => '設定が正常に復元されました ✓';
  @override String get importRestore => '復元';
  @override String get setupImportJson => 'JSONをインポート';
  @override String get setupImportHintLabel => 'JSONファイルの内容を下に貼り付けてください。';
  @override String get setupImportNote => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields => '無効なJSONです："username"または"api_key"フィールドがありません。';
  @override String get detailTracklist => 'トラック';
  @override String get detailAlbumLabel => 'アルバム';
  @override String get detailDuration => '再生時間';
  @override String get detailTopTracks => '人気のトラック';
  @override String get detailTopAlbums => '人気のアルバム';
  @override String get detailBioReadMore => '続きを読む';
  @override String get detailBioReadLess => '閉じる';
  @override String get detailUserPlays => 'あなたの再生回数';
  @override String get detailGlobalPlays => '総再生回数';
  @override String get detailUserRank => '順位';
  @override String get detailUserRankNA => '該当なし';
  @override String get detailGlobalListeners => 'リスナー';
  @override String get detailPeriod => '期間';
  @override String get detailBiography => 'バイオグラフィー';
  @override String get detailGlobalListenersLabel => 'リスナー数';
  @override String get detailTranslate => '翻訳';
  @override String get detailShowOriginal => '原文を表示';
  @override String get detailLyrics => '歌詞';
  @override String get detailLyricsNotFound => '歌詞が見つかりません';
  @override String get detailCopyLyrics => '歌詞をコピー';
  @override String get detailLyricsCopied => '歌詞をコピーしました';

  @override String get detailShoutbox => 'Last.fmのシャウトボックス';
  @override String get detailShoutboxReply => '返信';  @override String get dashPerWeek => '週あたり';
  @override String get onboardSkip => 'スキップ';
  @override String get onboardNext => '次へ';
  @override String get onboardFinish => '完了';
  @override String get onboardBack => '戻る';
  @override String get onboardAppearanceTitle => 'スタイルをカスタマイズ';
  @override String get onboardAppearanceSub => 'テーマ、アクセントカラー、Material You。';
  @override String get onboardNotifTitle => '最新情報をチェック';
  @override String get onboardNotifSub => '通知とバイブレーション。';
  @override String get onboardFavTitle => 'お気に入りのプロフィール';
  @override String get onboardFavSub => 'Last.fmフレンドを追加してすぐに見つけられるようにします。';
  @override String get onboardFavHint => 'Last.fmユーザー名';
  @override String get onboardFavAdd => '追加';
  @override String get onboardFavEmpty => 'お気に入りはまだありません';
  @override String get onboardFavSearchHint => 'Last.fmプロフィールを検索…';
  @override String get onboardFavNoResults => 'プロフィールが見つかりません';
  @override String get onboardFavFriendsTitle => 'あなたのLast.fmフレンド';
  @override String get onboardFavNoFriends => 'このアカウントにはフレンドがいません';
  @override String get onboardFavSelected => '選択中のお気に入り';
  @override String get onboardDashTitle => 'あなたのダッシュボード';
  @override String get onboardDashSub => '表示するセクションを選択してください。';
  @override String get onboardStartupTitle => '起動画面';
  @override String get onboardStartupSub => '最初に表示するタブはどれですか？';
  @override String get onboardPlatformTitle => '何で音楽を聴いていますか？';
  @override String get onboardPlatformSub => 'トラック・アーティスト・アルバムページで役立つリンクのみを表示します。';
  @override String get platformLastfm => 'Last.fm';
  @override String get platformSpotify => 'Spotify';
  @override String get platformYtMusic => 'YouTube Music';
  @override String get platformOther => 'その他 / すべて表示';
  @override String get settingsMusicPlatform => '音楽プラットフォーム';
  @override String get settingsMusicPlatformSub => '詳細ページに表示するリンクをフィルタリングします';
  @override String get settingsShowAllPlatformLinks => '常にすべて表示';
  @override String get settingsShowAllPlatformLinksSub => 'フィルターを無視してすべてのリンクを表示（Last.fm、Spotify、YT Music、Web）';
  @override String get onboardUpdatesTitle => 'アップデート';
  @override String get onboardUpdatesSub => '新しいバージョンを自動でチェックします。';
  @override String get onboardStyle => 'スタイル';
  @override String get onboardStyleMaterialYou => 'Material You';
  @override String get onboardStyleNothing => 'Nothing OS';
  @override String get onboardPreview => 'プレビュー';
  @override String get onboardPreviewButton => 'ボタン';
  @override String get onboardPreviewOutline => 'アウトライン';
  @override String get onboardPreviewText => 'サンプルテキスト';
  @override String get onboardPreviewBubble => '吹き出し';
  @override String get onboardAccentTint => 'アクセントの色合い';
  @override String get onboardNothingRedOnly => 'レッドのみ';
  @override String get onboardNothingRedYellow => 'レッド＋イエロー';
  @override String get onboardDisplay => '表示';
  @override String get onboardOledTitle => 'OLED純黒';
  @override String get onboardOledSub => 'ダークモード時に完全な黒背景を使用';
  @override String get onboardArtworkColorTitle => 'アートワークから色を取得';
  @override String get onboardArtworkColorSub => '再生中のジャケット写真にアクセントカラーを合わせます';
  @override String get onboardNewsTitle => 'お知らせ通知';
  @override String get onboardNewsSub => '新機能や修正についての通知を受け取ります';
  @override String get onboardNewsBadgeTitle => 'お知らせバッジ';
  @override String get onboardNewsBadgeSub => '新着情報があるときにベルアイコンに赤い点を表示';
  @override String get onboardHapticTitle => '触覚フィードバック';
  @override String get onboardHapticSub => '主要な操作時に軽い振動を感じられます';
  @override String get onboardRecaps => 'まとめ';
  @override String get onboardDailyRecapTitle => 'デイリーまとめ';
  @override String get onboardDailyRecapSub => 'その日のリスニングの簡単なサマリー';
  @override String get onboardWeeklyRecapTitle => 'ウィークリーまとめ';
  @override String get onboardWeeklyRecapSub => 'その週のトップアーティスト、アルバム、トラック';
  @override String get onboardMilestonesSection => 'スクロブルの節目';
  @override String get onboardMilestonesTitle => 'マイルストーン';
  @override String get onboardMilestonesSub => 'キリのいいスクロブル数をお祝いします';
  @override String get onboardGrandMilestonesTitle => '大きな節目';
  @override String get onboardGrandMilestonesSub => '大きなマイルストーン達成時に特別なお祝いを表示';
  @override String get onboardDynamicColorSub => '壁紙から色を取得します（Android 12以降）';
  @override String get onboardBetaTitle => 'ベータアップデート';
  @override String get onboardBetaSub => '先行リリース版への早期アクセス';
  @override String get notifDetailTitle => '通知';
  @override String get notifDetailOpenLink => 'リンクを開く';
  @override String get settingsCheckingUpdates => 'アップデートを確認中…';
  @override String get settingsTapToDownload => 'タップしてダウンロード';
  @override String get detailLookingForPreview => 'プレビューを検索中…';
  @override String get detailPreview30Sec => 'プレビュー・30秒';
  @override String get setupTagline => 'あなたのLast.fm統計、生まれ変わりました。';
  @override String get setupAnalyseProfile => 'プロフィールを分析';
  @override String get setupConnecting => '接続中…';
  @override String get setupStartAnalysis => '分析を開始';
  @override String get setupOr => 'または';
  @override String get setupUsernameLabel => 'Last.fmユーザー名';
  @override String get setupApiKeyLabel => 'Last.fm APIキー';
  @override String get setupApiKeyHint => '32文字の16進数キー';
  @override String get setupApiKeyPrivacyNote => 'ローカルに保存され、第三者に送信されることはありません。';
  @override String get setupRememberMe => 'ログイン情報を保存';
  @override String get setupGetApiKey => '無料でAPIキーを取得';
  @override String get setupWelcomeBanner => 'LastStatsへようこそ！';
  @override String get setupOneTimeImportNote => '初回のみのインポートです。次回以降の起動は瞬時に完了します。';
  @override String get dashTapToDownload => 'タップしてダウンロード。';
  @override String get dashWeekLabel => '今週';
  @override String get dashMonthLabel => '今月';
  @override String get dashYearLabel => '今年';
  @override String get dashTopArtistLabel => 'トップアーティスト';
  @override String get dashTopTrackLabel => 'トップトラック';
  @override String get dashScrobblesLabel => 'スクロブル数';
  @override String get newsTypeFeatures => '新機能';
  @override String get newsTypeFixes => '修正';
  @override String get newsTypeUpdates => 'アップデート';
  @override String get newsTypeAlerts => 'お知らせ';
  @override String get newsTypeInfo => '情報';
  @override String get newsWhatsNew => '新着情報';
  @override String get newsFilters => 'フィルター';
  @override String get newsAll => 'すべて';
  @override String get newsAnyDate => 'すべての日付';
  @override String get newsNoNewsYet => 'まだニュースはありません';
  @override String get settingsNotifications => '通知';
  @override String get settingsCache => 'キャッシュ';
  @override String get settingsCardAppearanceSub => 'テーマ、アクセント、レイアウト、Material You';
  @override String get settingsCardDashboardSub => 'ヘッダー画像、表示セクション、統計カード';
  @override String get settingsCardStartupSub => 'アプリ起動時に表示するタブ';
  @override String get settingsCardNotificationsSub => 'マイルストーン、デイリー・ウィークリーまとめ';
  @override String get settingsSync => '同期';
  @override String get settingsCardSyncSub => 'バックグラウンドでのスクロブル自動同期';
  @override String get settingsCardAccountSub => '連携中のLast.fmプロフィール、サインアウト';
  @override String get settingsCardCacheSub => '履歴、画像、APIデータ';
  @override String get settingsCardBackupSub => '設定のエクスポートと復元';
  @override String get settingsCardUpdatesSub => '新しいバージョンを確認';
  @override String get settingsCardAboutSub => 'バージョン、ソースコード、クレジット';
  @override String get settingsCardFaqSub => 'スクロブリング、プラットフォーム、オープンソース';
  @override String get settingsRestartNotice => '一部の設定は、完全に反映させるためにアプリの再起動が必要です。';
  @override String get syncPageTitle => 'スクロブル同期';
  @override String get syncAutoTitle => '自動同期';
  @override String get syncAutoSubtitle => '一定間隔でバックグラウンドで履歴を同期します';
  @override String get syncFrequencyLabel => '頻度';
  @override String get syncFrequencyDaily => '1日1回';
  @override String get syncManualTitle => '手動同期';
  @override String get syncNowButton => '今すぐ同期';
  @override String get syncInProgress => '同期中…';
  @override String get syncLastSyncLabel => '前回の同期';
  @override String get syncNeverLabel => 'なし';
  @override String get syncTotalScrobblesLabel => 'キャッシュ済みスクロブル数';
  @override String get syncUpToDateMsg => '履歴は最新です';
  @override String get syncNotifNote => '完全同期中は進捗通知が表示されます。';
  @override String get pcModeLayout => 'レイアウト';
  @override String get pcModeNavLayout => 'ナビゲーションレイアウト';
  @override String get pcModeAuto => '自動';
  @override String get pcModeSideRail => 'サイドレール';
  @override String get pcModeBottomBar => 'ボトムバー';
  @override String get pcModeHintAuto => '広い画面（720dp以上）ではサイドレール、狭い画面ではボトムバーを使用します。';
  @override String get pcModeHintOn => '画面サイズにかかわらず、常にサイドナビゲーションレールを使用します。';
  @override String get pcModeHintOff => '画面サイズにかかわらず、常にボトムナビゲーションバーを使用します。';
  @override String get aboutTagline => 'あなたのLast.fm統計パートナー';
  @override String get aboutAppInfo => 'アプリ情報';
  @override String get aboutScrobbleDownloader => 'スクロブルダウンローダー';
  @override String get aboutScrobbleDownloaderSub => 'すべてのスクロブルをファイルにエクスポート';
  @override String get aboutPoweredBy => '提供元';
  @override String get aboutImageDisclaimer => 'アーティスト、アルバム、トラックの画像はこれらのソースから自動的に取得されており、実際の内容と一致しない場合があります。';
  @override String get aboutFooter => '❤️を込めて制作 · Last.fm / CBSとは提携していません';
  @override String get updatesCurrentVersion => '現在のバージョン';
  @override String get updatesBetaTitle => 'ベータアップデート';
  @override String get updatesBetaSub => '先行リリース版への早期アクセス';
  @override String get backupWhatsIncluded => '含まれる内容';
  @override String get backupDownloadFile => '.jsonファイルをダウンロードします';
  @override String get backupChooseFile => 'バックアップファイルを選択';
  @override String get backupFileSaved => 'バックアップを保存しました';
  @override String get backupFileSaveFailed => 'ファイルの保存に失敗しました';
  @override String get setupRestoreBackup => 'バックアップを復元';
  @override String get setupRestoreBackupSub => '.jsonバックアップファイルからアカウントと設定を復元します';
  @override String get backupRestoreKeysTitle => 'APIキーを復元';
  @override String get backupRestoreKeysDesc => 'このバックアップから復元するLast.fmのキーを選んでください。';
  @override String get backupRestoreApiKeyLabel => 'APIキー';
  @override String get backupRestoreSecretKeyLabel => 'シークレットキー';
  @override String get backupIncludeFoldersLabel => 'フォルダを含める';
  @override String get backupIncludeFoldersDesc => '曲のフォルダとその中身を含めます';
  @override String get backupIncludeKeysDesc => 'エクスポートするファイルにキーを含める';

  @override String get backupIncludeThemesLabel => 'テーマをエクスポート';
  @override String get backupIncludeThemesDesc => '見た目(色やスタイル)だけを他の人と共有できます。';

  @override String get backupAutoTitle => '自動バックアップ';
  @override String get backupAutoEnableLabel => '自動バックアップを有効にする';
  @override String get backupAutoEnableDesc => '下で選んだ間隔で自動的にバックアップを保存します。';
  @override String get backupAutoFreqLabel => '頻度';
  @override String get backupAutoFreqDaily => '毎日';
  @override String get backupAutoFreqWeekly => '毎週';
  @override String get backupAutoFreqMonthly => '毎月';
  @override String get backupAutoFreqYearly => '毎年';
  @override String get backupAutoFolderLabel => 'バックアップフォルダ';
  @override String get backupAutoFolderDefault => 'アプリの既定フォルダ';
  @override String backupAutoNextLabel(String date) => '次回のバックアップ: $date';  @override String get backupIncludeScrobblesLabel => '履歴をすべて含める';
  @override String get backupIncludeScrobblesDesc => 'これまで再生したすべての曲を追加します(容量が大きくなる場合があります)。';

  @override String get backupScrobblesSlowWarning => '時間がかかる場合があり、通常のバックアップより遅くなります。';  @override String backupExportedOn(String date) => '$date のバックアップ';
  @override String get backupScrobblesErrorTitle => '履歴にエラーがあります';
  @override String get backupScrobblesErrorDesc => 'このファイル内の履歴の一部の年が壊れているようです。どうしますか?';
  @override String get backupScrobblesKeepAnyway => 'そのまま続ける';
  @override String get backupScrobblesCancel => '履歴をキャンセル';
  @override String get backupScrobblesSkipRefetch => 'スキップしてオンラインで再取得';  @override String get settingsCrashLog => 'エラーログ';
  @override String get backupCrashLogDesc => 'アプリで発生したエラーを記録します。不具合報告に役立ちます。';
  @override String get backupCrashLogShare => 'ログを共有';
  @override String get backupCrashLogClear => 'ログを消去';
  @override String get backupCrashLogEmpty => '記録されたエラーはありません';
  @override String get backupCrashLogCleared => 'ログを消去しました';
  @override String get backupCrashLogClearConfirm => 'エラーログを消去しますか？';
  @override String get faqSectionLabel => 'よくある質問';
  @override String get backupOverwriteWarning => 'バックアップを復元すると、現在の設定は上書きされます。';
  @override String get faqOpenSourceBadge => 'LastStatsはSanoBldが❤️を込めて作った無料のオープンソースプロジェクトです。';
  @override String get cacheUnlimited => '無制限';
  @override String get cacheTotalUsed => '使用合計';
  @override String get cacheScrobblesShort => 'スクロブル';
  @override String get restartHintFeatures => '一部の機能は、反映のためにアプリの再起動が必要な場合があります。';
  @override String get reorderCardsTitle => 'カードを並べ替え';
  @override String get commonSave => '保存';
  @override String get dashFallbackWhenNoMusic => '音楽が再生されていないとき';
  @override String get dashFallbackChooseDisplay => '代わりに背景として表示する内容を選択してください';
  @override String get dashFallbackPeriodLabel => '代替期間';
  @override String get fallbackPeriod1Week => '1週間';
  @override String get fallbackPeriod1Month => '1ヶ月';
  @override String get fallbackPeriodAllTime => '全期間';
  @override String get fallbackTypeNothing => 'なし';
  @override String get fallbackTypeTopTrack => 'トップトラック';
  @override String get fallbackTypeTopAlbum => 'トップアルバム';
  @override String get fallbackTypeTopArtist => 'トップアーティスト';
  @override String get fallbackTypeCustomImage => 'カスタム画像';
  @override String get fallbackWillShowCustomUrl => '表示内容：カスタム画像URL';
  @override String get dashAnimationBlurSection => 'アニメーションとぼかし';
  @override String get dashMusicAnimationTitle => '音楽アニメーション';
  @override String get dashMusicAnimationSub => '音楽が再生されているとき、ヘッダー画像がApple Musicのようにゆっくりとぼやけて動きます。';
  @override String get dashMusicAnimationInfo => 'このモードが有効な間、ぼかしは自動的に設定されます。上のぼかしスライダーは音楽再生中は効果がありません。';
  @override String get settingsTopAlbumsSection => 'トップアルバム';
  @override String get dashRecentPlaysLabel => '最近の再生';
  @override String get dashStatCardsSectionLabel => '統計カード';
  @override String get dashStatCardsHeading => '統計カード';
  @override String get dashStatCardsSub => '統計ブロックに表示するカードを選択・並べ替えます。';
  @override String get settingsDashboardChartSection => 'ダッシュボードのグラフ';
  @override String get dashChartCalendarLabel => '再生カレンダー';
  @override String get dashChartMonthlyLabel => '月別バー';
  @override String get settingsDisplayNameSection => '表示名';
  @override String get settingsDisplayNameLabel => '何と呼べばいい？';
  @override String get settingsDisplayNameHint => '例: Sano Bld — 空欄の場合はアカウント名を使用します';
  @override String get newsSearchHint => 'お知らせを検索…';
  @override String get aboutOpenSourceLibs => 'オープンソースライブラリ';
  @override String get aboutOpenSourceLibsSub => 'このアプリの構築に使用したすべての Flutter パッケージ。';
  @override String get aboutLicenseSection => 'ライセンス';
  @override String get aboutLicenseText => 'このプロジェクトは MIT ライセンスの下で公開されています。自由に使用、改変、複製、再配布できますが、私の名前を記載してください。';
  @override String get aboutLicenseLink => 'ライセンス全文を見る';
  @override String get languageAiNote => '翻訳は AI によって生成されており、不正確な場合があります。';
  @override String get aboutAiDevNote => 'このアプリの開発にも AI が使用されています。';
  @override String get notifWorkManagerInfo => '通知はWorkManagerによりバックグラウンドで動作します。アプリを開いておく必要はありません。インターネット接続が必要です。';
  @override String get notifIntervalTitle => 'スクロブルX回ごと';
  @override String get notifIntervalSubtitle => '一定間隔で通知を受け取ります';
  @override String get notifRecapsSection => 'リスニングまとめ';
  @override String get notifDailyRecapSubtitle => 'その日のスクロブル数とトップアーティスト';
  @override String get notifWeeklyRecapSubtitle => 'その週のスクロブル数とトップアーティスト';
  @override String get notifNewsSection => 'お知らせ';
  @override String get notifSyncSection => '同期';
  @override String get notifSyncTitle => '同期通知';
  @override String get notifSyncSubtitle => '履歴の同期が完了したときに通知します';
  @override String get notifSyncDetailTitle => '進捗の詳細';
  @override String get notifSyncDetailSubtitle => '同期中にライブ進捗（現在の年、カウンター）を表示します';
  @override String get notifNewsSubtitle => '新機能、修正、お知らせについて通知を受け取ります';
  @override String get notifBadgeOnDashboard => 'ダッシュボードのバッジ';
  @override String get notifBadgeSubtitle => 'お知らせベルアイコンに未読の点を表示します';
  @override String get notifTestLabel => 'テスト';
  @override String get notifPermissionDisabledTitle => '通知が無効です';
  @override String get notifPermissionDisabledBody => 'LastStatsが通知を送信できるように権限を許可してください。';
  @override String get notifGrantPermission => '権限を許可';
  @override String get notifThresholdIntro => '次の節目ごとに特別な通知を受け取ります：';
  @override String get notifIntervalDescription => 'スクロブルX回ごとに通知を送信します';
  @override String get notifCustomValueLabel => 'カスタム値';
  @override String get notifTimeNotifyAt => '通知時刻';
  @override String get notifDayOfWeek => '曜日';
  @override String get notifSendTest => 'テスト通知を送信';
  @override String get notifSentCheckBar => '通知バーを確認してください！';
  @override String get notifMakeSureWorks => '正しく動作するか確認してください。';
  @override String get notifSentBang => '送信しました！';
  @override String get notifSendButton => '送信';
  @override String get apVisualStyle => 'ビジュアルスタイル';
  @override String get apStyleDefault => 'デフォルト';
  @override String get apNothingAccentLabel => 'アクセント';
  @override String get apNothingClassic => 'クラシック';
  @override String get apRedOnlyDesc => 'レッドのみ';
  @override String get apNothingMixed => 'ミックス';
  @override String get apRedYellowDesc => 'レッド＋イエローのアクセント';
  @override String get apNothingActiveBanner => 'Nothing OSスタイルが有効です。アクセント、ダイナミックカラー、音楽から色を取得する機能は無効になります。';
  @override String get apNothingOledInherent => 'Nothingのダークモードは元々OLED純黒です。OLEDのトグルは不要です。';
  @override String get apOledTitle => 'OLED純黒テーマ';
  @override String get apOledBuiltIntoNothing => 'Nothingダークモードに組み込み済み';
  @override String get apOledPureBlack => 'ダークモード時に完全な黒背景を使用';
  @override String get apCustomColorTooltip => 'カスタムカラー';
  @override String get apColorWhenNothingPlays => '何も再生していないときの色';
  @override String get apColorWhenNothingPlaysSub => '曲がスクロブルされていないときに使用するアクセント';
  @override String get apKeepLastArtworkTitle => '最後のアートワークカラーを保持';
  @override String get apKeepLastArtworkSub => '何も再生していないときにリセットせず最後のアートワークカラーを保持します';
  @override String get apDetailPagesSection => '詳細ページ';
  @override String get apArtworkColorTheme => 'アートワークカラーテーマ';
  @override String get apBeta => 'ベータ';
  @override String get apArtworkColorThemeSub => '詳細ページの色がアートワークの主要色に合わせて変化します';
  @override String get apNavBarSection => 'ナビゲーションバー';
  @override String get apShowTabLabels => 'タブラベルを表示';
  @override String get apShowTabLabelsSub => 'ボトムバーのアイコンの下にタブ名を表示します';
  @override String get apInteractionsSection => '操作';
  @override String get apHapticFeedbackSub => 'タップ、選択、ジェスチャー時の振動';
  @override String get acctRemoveTitle => 'アカウントを削除しますか？';
  @override String get acctRemoveAction => '削除';
  @override String get acctAlreadyAddedOrFull => 'このアカウントはすでに追加されているか、リストが上限に達しています。';
  @override String get acctLogoutAllBody => 'すべてのアカウントが削除されます。セットアップ画面に戻ります。';
  @override String get acctActive => '有効';
  @override String get acctTapSwitchToActivate => '「切り替え」をタップして有効化';
  @override String get acctSwitch => '切り替え';
  @override String get acctAddAnAccount => 'アカウントを追加';
  @override String get acctApiKeyInfo => '各アカウントは異なるAPIキーまたは同じAPIキーを使用できます。APIキーはlast.fm/api/accountsで確認できます。';
  @override String get acctLastfmProfileSection => 'Last.fmプロフィール';
  @override String get acctViewOnLastfm => 'Last.fmで表示';
  @override String get acctDangerZone => '危険な操作';
  @override String get acctLogoutAllSub => 'すべてのアカウントを削除してセットアップ画面に戻ります。';
  @override String get acctUsernameRequired => 'ユーザー名は必須です。';
  @override String get acctApiKeyRequired => 'APIキーは必須です。';
  @override String get acctUsernameLabel => 'Last.fmユーザー名';
  @override String get acctSameApiKey => '有効なアカウントと同じAPIキーを使用';
  @override String get acctApiKeyLabel => 'APIキー';
  @override String get acctAdd => '追加';
  @override String get languageChangeNote => '言語はアプリ全体で即座に変更されます。';
  @override String get dashTotalScrobblesLabel => '総スクロブル数';
  @override String get dashMemberSinceLabel => '登録日';
  @override String get dashCountryLabel => '国';
  @override String get dashArtistWeekLabel => 'アーティスト1位（週間）';
  @override String get dashAlbumWeekLabel => 'アルバム1位（週間）';
  @override String get dashTrackWeekLabel => 'トラック1位（週間）';
  @override String get dashUniqueArtistsLabel => 'ユニークアーティスト数';
  @override String get dashUniqueTracksLabel => 'ユニークトラック数';
  @override String get dashUniqueAlbumsLabel => 'ユニークアルバム数';
  @override String get dashThisWeekLabel => '今週';
  @override String get dashDayUnitShort => '日';
  @override String get setupEnableFavorites      => 'お気に入りを有効にする（任意）';
  @override String get setupFavoritesExplain     => 'シークレットキーを使うと、Last.fm上で直接曲をお気に入り登録・解除できます。';
  @override String get setupSecretKeyLabel       => 'Last.fm シークレットキー';
  @override String get favConnectInvalidSecret   => 'シークレットキーは32文字である必要があります。';
  @override String get favConnectDialogTitle     => 'お気に入り機能を許可';
  @override String get favConnectDialogBody      => 'ブラウザで開いたLast.fmのページでアプリを許可してから、ここに戻って確認してください。';
  @override String get favConnectDialogConfirm   => '許可しました';
  @override String get favConnectSuccess         => 'お気に入り機能が有効になりました！';
  @override String get favConnectError           => 'お気に入り機能を有効にできませんでした。シークレットキーを確認してください。';
  @override String get acctApiKeysSection        => 'APIキー';
  @override String get acctSecretKeyLabel        => 'シークレットキー';
  @override String get acctSecretKeyNotSet       => '未設定';
  @override String get acctFavoritesExplain      => 'シークレットキーを使うと、Last.fm上で直接曲をお気に入り登録・解除できます。';
  @override String get acctConnectFavorites      => 'お気に入りを有効にする';
  @override String get acctDisconnectFavorites   => 'お気に入りを無効にする';
  @override String get settingsFavoritesSection    => 'お気に入り';
  @override String get settingsFavoritesSectionSub => '統計にお気に入りの数を表示します';
  @override String get settingsFavoritesNeedsKey   => '有効にするにはアカウントでシークレットキーを追加してください';
  @override String get favSectionTitle           => 'お気に入り';
  @override String get commonSeeMore             => 'もっと見る';
  @override String get favPageTitle              => 'マイお気に入り';
  @override String get favSearchHint             => '曲名やアーティストを検索';
  @override String get favEmpty                  => 'お気に入りはまだありません。';
  @override String get settingsLovedBadgeTitle => '控えめなハートバッジ';
  @override String get settingsLovedBadgeSub   => '最近の再生履歴、履歴、検索でお気に入りの曲に小さなハートを表示します';
  @override String get favSortRecent   => '最近';
  @override String get favSortOldest   => '古い順';
  @override String get favSortArtistAz => 'アーティスト A-Z';
  @override String get favSortTitleAz  => 'タイトル A-Z';
  @override String get favFolderSortCustom => '手動';
  @override String get favFoldersAll => 'すべて';
  @override String get favFolderNew => '新しいフォルダ';
  @override String get favFolderNamePlaceholder => 'フォルダ名';
  @override String get favFolderCustomEmojiTitle => '絵文字を選ぶ';
  @override String get favFolderCustomEmojiHelper => '絵文字は1つだけ、テキストは不可';
  @override String get favFolderDescPlaceholder => '説明（任意）';
  @override String get favFolderRecentlyPlayed => '最近再生した曲';
  @override String get favFolderCreate => '作成';
  @override String get favFolderEdit => 'フォルダを編集';
  @override String get favFolderDelete => '削除';
  @override String get favFolderDeleteConfirm => 'このフォルダを削除しますか？曲は整理されなくなります。';
  @override String get favFolderAssignTitle => 'フォルダに追加';
  @override String get favFolderEmoji => '絵文字';
  @override String get favFolderColor => '色';
  @override String get favFolderSave => '保存';
  @override String get favFolderEmpty => 'このフォルダに曲はありません';
  @override String get rankingsWholeYear       => '通年';
  @override String get chartsExportGeneratedOn => '生成日';
  @override String get faqQ1 => 'LastStatsは自分の音楽をスクロブリングしますか？';
  @override String get faqA1 => 'いいえ。LastStatsは可視化アプリで、すでにLast.fmアカウントに記録されているスクロブルを表示するだけで、自分では記録しません。\n\n音楽を自動でスクロブリングするには、Pano Scrobbler（Android用）などの専用アプリを使用してください。';
  @override String get faqQ3 => 'macOSや他のプラットフォームでも動作しますか？';
  @override String get faqA3 => 'LastStatsはAndroidで開発・テストされています。他のプラットフォーム（macOS、Windows、Linuxなど）での動作は検証されておらず、不具合や予期しない動作が発生する可能性があります。';
  @override String get faqQ4 => 'LastStatsはオープンソースですか？';
  @override String get faqA4 => 'はい！ソースコードはGitHubで自由に公開されています。このプロジェクトはSanoBldが情熱を持って開発した独立プロジェクトです。ひ売貢献したり、不具合を報告したり、⭐を付けてください。';
  @override String get faqQ5 => 'データはどこに保存されますか？';
  @override String get faqA5 => 'お使いの端末のみです。LastStatsにはサーバーがなく、スクロブルは高速アクセスのためにローカルにキャッシュされ、Last.fmの認証情報もローカルに保存されます。公式Last.fm API以外にデータが送信されることはありません。';
  @override String get faqQ6 => 'お気に入りを有効にするには？';
  @override String get faqA6 => '設定 > アカウントを開き、Last.fmのシークレットキー（last.fm/api/accounts のAPIキーの隣にあります）を入力して、画面の案内に従ってください。接続後は、アプリから直接曲をお気に入りに登録できます。アプリ内蔵キーでは、この機能は使えません。';
  @override String get faqQ7 => '\u300cscrobble\uff08\u30b9\u30af\u30ed\u30d6\u30eb\uff09\u300d\u3068\u306f\uff1f';
  @override String get faqA7 => '\u300cscrobble\u300d\u3068\u306f\u3001Last.fm\u30a2\u30ab\u30a6\u30f3\u30c8\u306b\u518d\u751f\u3068\u3057\u3066\u8a18\u9332\u3055\u308c\u305f\u697d\u66f2\u3092\u6307\u3057\u3001Last.fm\u56fa\u6709\u306e\u7528\u8a9e\u3067\u300c1\u56de\u306e\u30ab\u30a6\u30f3\u30c8\u3055\u308c\u305f\u518d\u751f\u300d\u3092\u610f\u5473\u3057\u307e\u3059\u3002\u3059\u3079\u3066\u306e\u5408\u8a08\uff08\u30c8\u30c3\u30d7\u30a2\u30fc\u30c6\u30a3\u30b9\u30c8\u3084\u7d71\u8a08\u306a\u3069\uff09\u306f\u3053\u308c\u306b\u57fa\u3065\u3044\u3066\u3044\u307e\u3059\u3002';
  @override String get faqQ8 => '\u30ec\u30d9\u30eb\u3068\u5b9f\u7e3e\u306e\u4ed5\u7d44\u307f\u306f\uff1f';
  @override String get faqA8 => '\u30a2\u30ab\u30a6\u30f3\u30c8\u30ec\u30d9\u30eb\u306f\u7dcf scrobble \u6570\u306b\u5fdc\u3058\u3066\u4e0a\u304c\u308a\u3001\u4e0a\u9650\u306f\u3042\u308a\u307e\u305b\u3093\u3002\u30ab\u30fc\u30c9\u306b\u306f\u305d\u306e\u30a2\u30fc\u30c6\u30a3\u30b9\u30c8/\u697d\u66f2/\u30a2\u30eb\u30d0\u30e0\u306e\u518d\u751f\u56de\u6570\u306b\u5fdc\u3058\u305f\u679a\u679a(\u30d6\u30ed\u30f3\u30ba\u2192\u865a\u5f69)\u304c\u4ed8\u304d\u307e\u3059\u3002\u3059\u3079\u3066\u30ed\u30fc\u30ab\u30eb\u306b\u30ad\u30e3\u30c3\u30b7\u30e5\u6e08\u307f\u306e\u7d71\u8a08\u304b\u3089\u81ea\u52d5\u8a08\u7b97\u3055\u308c\u3001\u8ffd\u52a0\u306e\u901a\u4fe1\u306f\u767a\u751f\u3057\u307e\u305b\u3093\u3002';
  @override String get faqQ9 => '省電力モードはどのように機能しますか？';
  @override String get faqA9 => '省電力モードは自動同期の間隔を広げてバッテリーを節約します。常にオンにする、スマートフォン標準の省電力モードに連動させる、選んだバッテリー残量を下回ったらオンにする、のいずれかを設定 > 一般から選べます。';
  @override String get faqQ10 => 'データのバックアップや復元はどうすればいいですか？';
  @override String get faqA10 => '設定 > バックアップを開くと、バックアップファイルを書き出せます。Last.fmキーを含めるかどうかは選べます。後からこの端末や別の端末に読み込めば、設定を元に戻せます。';
  @override String get faqQ11 => 'オフラインでも使えますか？';
  @override String get faqA11 => 'ある程度は可能です。読み込み済みの統計はローカルキャッシュのおかげでオフラインでも見られますが、新しいスクロブルの取得には通信が必要です。';
  @override String get faqQ12 => 'Last.fmアカウントを切り替えられますか？';
  @override String get faqA12 => 'はい、Last.fmアカウントは最大3つまで登録できます。設定 > アカウントで「アカウントを追加」をタップし、好きなときに切り替えてください。切り替えるとローカルキャッシュは自動的にリセットされるので、2つのアカウントのデータが混ざることはありません。';
  @override String get faqQ13 => '通知はどう設定しますか？';
  @override String get faqA13 => '設定 > 通知から、同期が終わったときの通知をオンにしたり、通知の頻度を選んだり、通知をすべてオフにしたりできます。';
  @override String get faqQ14 => '画像が表示されない／読み込みが終わらない場合は？';
  @override String get faqA14 => 'アプリ内のキャッシュを消去し（設定 > キャッシュ）、次に Android 側でも消去してください（設定 > アプリ > LastStats > ストレージ > キャッシュを消去）。それでも表示されない場合は、データをバックアップ（設定 > バックアップ）し、アプリを再インストールして復元してください。';
  @override String get settingsPlatformDisabledByShowAll => '無効：すでにすべてのリンクが表示されています。';
  @override String get commonInDevelopment => '開発中';
  @override String get commonSeeLess => '閉じる';
  @override String get commonShare => '共有';
  @override String get newsCustomDate => 'カスタム日付';
  @override String get aboutShortcuts => 'キーボードショートカット';
  @override String get aboutShortcutsSub => 'PC・大画面で利用可能';
  @override String get shortcutSwitchTabs => 'タブを切り替え';
  @override String get shortcutSearch => '検索';
  @override String get shortcutClose => 'シートを閉じる';
  @override String get shortcutRefresh => '更新';
  @override String get aboutDiscord => 'Discordに参加';
  @override String get aboutDiscordSub => 'チャット、提案、ライブ告知';

  @override String globalListeners(String count) => '世界のリスナー数：$count人';
  @override String historyScrobbles(int n) => '$n回のスクロブル';
  @override String historyArtistsCount(int n) => '$n人のアーティスト';
  @override String historyAlbumsCount(int n) => '$n枚のアルバム';
  @override List<String> get months => const ['', '1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];
  @override String dayLabel(DateTime d) {
    const days = ['月曜日','火曜日','水曜日','木曜日','金曜日','土曜日','日曜日'];
    return '${d.year}年${d.month}月${d.day}日（${days[d.weekday - 1]}）';
  }
  @override String memberSince(String date) => '$date から利用';
  @override String settingsUpdateAvailable(String v) => 'v$v が利用可能';
  @override String settingsUpdateBanner(String v) => 'アップデート v$v';
  @override String setupWelcome(String username) => 'ようこそ、$username さん！';
  @override String setupScrobblesToImport(String c) => 'インポート予定のスクロブル：$c件';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      '${isBeta ? "ベータ" : "新しい"}アップデート：v$version';
  @override String newsItemsCount(int n) => '$n件';
  @override String syncFrequencyHours(int h) => '$h時間ごと';
  @override String syncNewScrobblesFound(int n) => n == 0 ? '新しいスクロブルはありません' : '新しいスクロブルが$n件見つかりました';
  @override String updatesPublishedOn(String date) => '$date に公開';
  @override String fallbackWillShow(String detail) => '表示内容：$detail';
  @override String acctRemoveBody(String username) => 'アカウント一覧から @$username を削除しますか？';
  @override String acctAddedSuccess(String username) => '@$username を追加しました。';
  @override String acctMyAccounts(int count, int max) => 'マイアカウント（$count/$max）';
  @override String acctSlotsRemaining(int n) => '残り$n枠';
  @override String acctMaxReached(int max) => '最大$max件のアカウントに達しました。';
  @override List<String> get weekdaysShort => const ['月','火','水','木','金','土','日'];
  @override List<String> get weekdaysNarrow => const ['月','火','水','木','金','土','日'];
  @override String get weekAbbrev => '週';
  @override List<String> get notifThresholdMessages => const [
    '最初の1,000スクロブル達成。旅の始まりです。🎵',
    '5桁に到達しました！🎉',
    'あなたは真の音楽中毒者です。🔥',
    '100万スクロブル達成。伝説です。🎸',
  ];
  @override String get achvTitle => '実績';
  @override String achvUnlocked(int unlocked, int total) => '解除済み $unlocked / $total';
  @override String get achvCatListening => 'リスニング';
  @override String get achvCatArtists => 'アーティスト';
  @override String get achvCatAlbums => 'アルバム';
  @override String get achvCatLoyalty => '継続';
  @override String get achvDescListening => '全アーティスト合計のスクロブル数。';
  @override String get achvDescArtists => '一度でも聴いたことのある異なるアーティストの数。';
  @override String get achvDescAlbums => '一度でも聴いたことのある異なるアルバムの数。';
  @override String get achvDescLoyalty => 'Last.fmアカウントの利用歴。';
  @override String get achvCatTracks => '楽曲';
  @override String get achvDescTracks => '再生した異なる楽曲の数。';
  @override String get achvCatPace => 'ペース';
  @override String get achvDescPace => '週あたりの平均スクロブル数。';
  @override String get achvCatStreak => '連続記録';
  @override String get achvDescStreak => '1日1回以上再生した連続日数の最長記録。';
  @override String get achvCatMarathon => 'マラソン';
  @override String get achvDescMarathon => '1日の最多再生回数。';
  @override String get achvCatSocial => 'ソーシャル';
  @override String get achvDescSocial => '追加した友達またはプロフィールの数。';
  @override String get achvCatComparisons => '比較';
  @override String get achvDescComparisons => '行った音楽の好み比較の回数。';
  @override String get achvUnlockedBadge => '解除済み';
  @override String get achvLockedBadge => 'ロック中';
  @override String get dashRecap => '振り返り';
  @override String get recapDay => '今日';
  @override String get recapWeek => '今週';
  @override String get recapMonth => '今月';
  @override String get recapScrobbles => '再生数';
  @override String get recapArtists => 'アーティスト';
  @override String get recapTracks => '曲';
  @override String get recapTopArtist => 'トップアーティスト';
  @override String get recapTopTrack => 'トップ曲';
  @override String get recapTopAlbum => 'トップアルバム';
  @override String get recapAvgDay => '1日平均';
  @override String get recapNoData => 'この期間の再生履歴はありません。';
  @override String get recapSeeFull => '振り返りを見る';
  @override String get recapTop10 => 'トップ10';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => 'いちばん役立つフィルターを先頭に';
  @override String get discoverSmartSub => '時間帯や曜日、よく使うものに合わせて並べます';
  @override String get discoverForYou => 'あなたへ';
  @override String get discoverGlobalTrends => '世界のトレンド';
  @override String get discoverSrcForyou => 'あなたのミックス';
  @override String get discoverSrcOnthisday => 'この日に';
  @override String get discoverSrcFresh => '今月';
  @override String get discoverSrcGenre => 'あなたのジャンル';
  @override String get discoverSrcDeeper => '隠れた名曲';
  @override String get discoverSrcForgotten => '忘れていた曲';
  @override String get discoverSrcAlbums => 'アルバム';
  @override String get discoverSrcCountry => 'あなたの国';
  @override String get discoverTracks => 'トラック';
  @override String get discoverArtists => 'アーティスト';
  @override String get discoverWeek => '週';
  @override String get discoverMonth => '月';
  @override String get discoverYear => '年';
  @override String get discoverNothing => 'まだ表示するものがありません';
  @override String discoverLike(String names) => '$names のような';
  @override String get dashReorderSections => 'セクションの順番を変える';
  @override String get dashInfiniteTitle => '無限スクロール';
  @override String get dashInfiniteSub => '「発見」がループして、提案が途切れません';
  @override String get dashDiscoverTitle => '発見';
  @override String get dashDiscoverSub => 'スワイプで音楽のアイデアをチェック';
  @override String get dashSortButton => '並べ替え';
  @override String get dashSortDone => '完了';
  @override String get dashSortHint => 'ドラッグで順番を変更';
  @override String get dashSortSmartNote => 'スマート順序がオンなので、状況によってこの順番が変わることがあります。';
  @override String get dashSeparateRow => '専用の行に表示';
  @override String dashFiltersOf(String group) => '「$group」のフィルター';
  @override String get apShapeSingle => '1つの形だけ';
  @override String get mvSource => '動画ソース';
  @override String get mvSrcAuto => '自動（Apple Music、次に YouTube）';
  @override String get mvSrcApple => 'Apple Music のみ';
  @override String get mvSrcYt => 'YouTube のみ（曲）';
  @override String get mvQualityT => '動画の画質';
  @override String get mvQAuto => '自動';
  @override String get mvQLow => '節約 (360p)';
  @override String get mvTypesT => '動画を表示する対象';
  @override String get mvTracks => '曲';
  @override String get mvAlbums => 'アルバム';
  @override String get mvArtists => 'アーティスト';
  @override String get mvModeT => 'モード';
  @override String get mvModeBest => 'おすすめ';
  @override String get mvModeSaver => '節約';
  @override String get mvModeMax => '最高画質';
  @override String get mvModeCustom => 'カスタム';
  @override String get mvSrcYtFirst => 'YouTube、次に Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => '使用中のサービス、クォータ、消費量';
  @override String get apiSumToday => '今日のリクエスト';
  @override String get apiSumErrors => 'エラー';
  @override String get apiSumLimited => '制限あり';
  @override String get apiIntro => 'カウンターはこの端末のみが対象です。提供元は IP アドレス単位で制限をかけるため、同じネットワーク上の他のアプリも含まれます。アプリは制限内に収まるよう、自動的に間隔を空けたりリクエストを省略します。';
  @override String get apiCatListening => '再生データ';
  @override String get apiCatMetadata => '音楽メタデータ';
  @override String get apiCatArtwork => 'アートワーク';
  @override String get apiCatLyrics => '歌詞';
  @override String get apiCatTranslate => '翻訳';
  @override String get apiCatUpdates => 'アップデートとニュース';
  @override String get apiCatOther => '画像のダウンロード';
  @override String get apiStatusIdle => '未使用';
  @override String get apiStatusOk => 'OK';
  @override String get apiStatusNear => '上限に近い';
  @override String get apiStatusPaused => '一時停止中';
  @override String get apiProviderLimit => '提供元の制限';
  @override String get apiNoLimit => '公開なし';
  @override String get apiAppCeiling => 'アプリの上限';
  @override String apiLimitPer(int n, String win) => '$n リクエスト / $win';
  @override String get apiWinSecond => '秒';
  @override String get apiWinMinute => '分';
  @override String get apiWinHour => '時間';
  @override String apiWinSeconds(int s) => '$s 秒';
  @override String get apiWindowUsage => '現在のウィンドウ';
  @override String get apiRemaining => '残り';
  @override String apiResetsIn(String t) => '$t 後にリセット';
  @override String apiPausedFor(String t) => '制限応答により $t 停止中';
  @override String get apiToday => '今日';
  @override String get apiLastHour => '直近1時間';
  @override String get apiTotal => '合計';
  @override String get apiRateLimited => '制限応答';
  @override String get apiSkipped => 'アプリがスキップ';
  @override String get apiLastCall => '最後の呼び出し';
  @override String get apiNever => 'なし';
  @override String get apiNoKey => 'API キー不要';
  @override String get apiSharedKey => '共有の公開テストキー(無料枠)';
  @override String get apiUnofficial => '非公式エンドポイント:クォータは保証されず、予告なく変更・ブロックされる場合があります。';
  @override String get apiKeyInUse => '使用中のキー';
  @override String get apiOwnKey => '自分の Last.fm キー';
  @override String apiBuiltinKey(int n, int total) => '内蔵キー $n / $total';
  @override String get apiBackupOn => '予備キー:オン';
  @override String get apiBackupOff => '予備キー:オフ';
  @override String get apiPerKey => 'キーごとのリクエスト(今日 / 合計)';
  @override String get apiLastfmNote => 'Last.fm は数値を公開していません。IP からのリクエストが多すぎるとエラー 29 を返し、規約で回避も禁止されています。目安は IP あたり毎秒約 5 リクエストで、アプリは 4 未満に抑えます。';
  @override String get apiStorageTitle => '保存済みの Last.fm データ';
  @override String apiStorageValue(String used, String cap) => '許可された $cap のうち $used';
  @override String get apiStorageOver => 'Last.fm API 規約の 100 MB 上限を超えています。「ストレージ」でスクロブル履歴を消去してください。';
  @override String get apiReset => 'カウンターをリセット';
  @override String get apiLimiter => 'リクエストを制限';
  @override String get apiLimiterSub => 'API の上限を超えないようにリクエストを遅くします。オフ = 待ち時間なしで高速。';
  @override String get apiResetBody => 'すべてのリクエストカウンターが 0 に戻ります。';
  @override String get apiResetDone => 'カウンターをリセットしました';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (ja) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxJa = {
  'st_notif_on': '通知はオンです',
  'st_notif_off': '通知はオフです',
  'st_notif_count': '{n} 種類が有効',
  'st_notif_perm': 'システムの許可が必要です',
  'st_notif_none': '通知の種類が選ばれていません',
  'st_sync_on': '自動同期はオンです',
  'st_sync_off': '自動同期はオフです',
  'st_sync_on_s': 'データは自動的に更新されます。',
  'st_sync_off_s': 'データは手動のときだけ更新されます。',
  'st_bkp_on': '自動バックアップはオンです',
  'st_bkp_off': '自動バックアップはオフです',
  'st_bkp_on_s': '設定は自動でバックアップされます。',
  'st_bkp_off_s': 'オンにすると設定を失いません。',
  'st_bkp_next': '次回のバックアップ：{d}',
  'cmp_breakdown': '共通点の内訳',
  'cmp_by_artists': 'アーティスト',
  'cmp_by_genres': 'ジャンル',
  'cmp_by_tracks': 'トラック',
  'cmp_by_albums': 'アルバム',
  'eco_on': '省電力がオンです',
  'eco_off': '省電力はオフです',
  'eco_why_manual': '常にオン（手動設定）',
  'eco_why_system': '端末のバッテリーセーバーがオンです',
  'eco_why_battery': 'バッテリー残量は {n}% です',
  'eco_off_hint': 'オンにするタイミングを下で選びます',
  'eco_trig': 'オンにするタイミング',
  'eco_sys_t': '端末のバッテリーセーバーがオンのとき',
  'eco_sys_s': 'スマートフォン標準の省電力モードに連動し、解除されると一緒にオフになります。',
  'eco_sys_na': 'この端末では利用できません。',
  'eco_chg': '変わること',
  'eco_chg1': '傾きパララックスをオフにします',
  'eco_chg2': '画面のリフレッシュレートを約 60 Hz に制限します',
  'eco_chg3': 'バックグラウンド更新の頻度を下げます',
  'eco_chg4': '動くアートワークとバッジの輝きを停止します',
  'eco_chg_note': 'それ以外は最高品質のままです：画像、エクスポート、共有カード。',
  'lib_section': 'ライブラリ',
  'lib_merge_t': '同じ曲のバージョンをまとめる',
  'lib_merge_s': 'リマスター、シングル、(feat. …)、デラックス版を1つの曲/アルバムとして数え、再生回数を合算します。リミックス、ライブ、インストは別扱いです。',
  'lib_split_t': 'コラボを分割',
  'lib_split_s': '「Gims & Damso」は独立したアーティストではなく、Gims と Damso の両方にカウントされます。「Simon & Garfunkel」のようなグループはそのままです。',
  'lib_step_t': 'あなたのライブラリ',
  'lib_step_s': '再生履歴のまとめ方を選びます。設定でいつでも変更できます。',
  'bk_dash_t': 'ダッシュボードと起動',
  'bk_dash_s': 'セクション、ヘッダー、統計カード、発見、起動タブ',
  'bk_notif_t': '通知',
  'bk_notif_s': 'まとめ、マイルストーン、ニュース、バッジ',
  'bk_lib_t': 'ライブラリ設定',
  'bk_lib_s': 'バージョンの統合、コラボの分割',
  'bk_prof_t': 'お気に入りプロフィール',
  'bk_prof_s': 'お気に入りにした Last.fm プロフィール',
  'about_readme_t': 'README とプロジェクトの動き',
  'about_readme_s': 'README、最新コミット、ワークフロー、バージョン、ダウンロード数',
  'fold_show': '表示 ({n})',
  'fold_hide': '閉じる',
  'readme_sub': 'プロジェクトとその動き',
  'readme_version': 'バージョン',
  'readme_downloads': 'ダウンロード',
  'readme_stars': 'スター',
  'readme_license': 'ライセンス',
  'readme_commits': '最新のコミット',
  'readme_workflows': '最新のワークフロー',
  'readme_retry': '再試行',
  'readme_github': 'GitHub で開く',
  'readme_failed': '読み込めませんでした(オフライン、または GitHub の制限)。',
  'ago_min': '{n}分前',
  'ago_h': '{n}時間前',
  'ago_d': '{n}日前',
  'load_restored': '{n} 件のスクロブルを復元',
  'load_ready': 'インポート準備完了',
  'load_connecting': 'Last.fm に接続中…',
  'load_done': 'インポート完了',
  'load_backup_note': 'バックアップを検出:新しいスクロブルのみ確認します。',
  'dash_nowplay': '再生中',
  'dash_stats': '統計',
  'dash_recent': '最近の再生',
  'dash_discover': '発見',
  'dash_friends': 'フレンド',
  'dash_chart': 'ダッシュボードのグラフ',
  'dash_calendar': 'カレンダー',
  'dash_monthly': '月別',
  'cache_video_t': 'アニメーションカバー (Apple Music)',
  'cache_video_s': '使用中のビデオメモリ:{mem} · アクティブなプレーヤー {players} · キャッシュ済みリンク {links}',
  'cache_video_short': 'アニメカバー',
  'cache_video_cleared': 'ビデオメモリを解放しました',
  'cache_memory_section': 'メモリ',
  'cache_storage_section': 'ストレージ',
  'lvl': 'レベル {n}',
  'lvl_history': 'レベル履歴',
  'set_living_t': '動くカバー',
  'set_living_s': '画像にやわらかなズームと奥行き効果',
  'set_motion_t': 'ビデオカバー',
  'set_motion_s': 'アニメーションカバーがあれば再生します',
  'set_achv_t': '実績とレベル',
  'set_achv_s': 'ティア、バッジ、アカウントレベル',
  'cache_img_limit_t': '写真キャッシュの上限',
  'cache_img_limit_s': 'ジャケット、アーティスト写真、アバター。古いものから削除されます。',
  'cache_vid_limit_t': '動画キャッシュの上限',
  'cache_vid_limit_s': 'Apple Musicのアニメーションカバーをディスクに保存し、オフラインで再生します（Android）。',
  'cache_video_off': 'オフ',
  'cache_vid_disk_t': 'Apple Music動画',
  'cache_vid_disk_s': '{size} · 保存済みのアニメーションカバー',
  'cache_no_limit_note': 'スクロブルとAPIデータは制限されません。',
  'key_internal_use': 'アプリ内蔵キーを使用',
  'key_internal_help': '予備のオプションです。このキーは複数のユーザーで共有されるため、上限に達したり使えなくなったりして、一部の機能が動作しないことがあります。可能なら自分のキーを使ってください。',
  'key_internal_active': 'アプリ内蔵キー',
  'key_fallback_title': '内蔵キーを予備に使う',
  'key_fallback_sub': 'まず自分のキーを使い、Last.fmに拒否された場合は、アプリが自動的に内蔵キーでもう一度試します。',
  'key_use_own': '自分のAPIキーを使う',
  'key_change_title': 'APIキーを変更',
  'key_change_sub': '現在のキーを別のキーに置き換えるか、アプリ内蔵キーに切り替えられます。',
  'key_change_sub_internal': '現在はアプリの共有キーを使っています。自分のキーを追加すると、他のユーザーの利用上限の影響を受けなくなります。',
  'key_change_intro': 'このアカウント用の新しいAPIキーを入力するか、アプリ内蔵キーに戻してください。ユーザー名や統計は変わりません。',
  'key_change_intro_internal': 'このアカウントは現在、アプリ内蔵キーを使っています。自分のLast.fm APIキーを下に貼り付けると置き換えられます。ユーザー名や統計は変わりません。',
  'key_change_hint': 'APIキーは32文字です。last.fm/api/accounts で作成または確認できます。',
  'key_change_invalid_len': 'APIキーはちょうど32文字である必要があります。最後までコピーできているか確認してください。',
  'key_change_same': 'このアカウントはすでにこのキーを使っています。別のキーを入力してください。',
  'key_change_check_failed': 'Last.fmがこのキーを受け付けませんでした。キーが正しいか、ネットワークに接続しているかを確認して、もう一度お試しください。',
  'key_change_favorites_warn': 'お気に入りの連携は、以前のキーに紐づいているため解除されます。あとでシークレットキーを使って再接続できます。',
  'key_change_apply': '適用',
  'key_change_success': 'APIキーを更新しました。',
  'key_internal_fav_note': 'お気に入りには、自分のAPIキーとLast.fmのシークレットキーが必要です。上で自分のキーを追加すると有効にできます。',
  'faq_q15': 'ログイン後にAPIキーを変更できますか？',
  'faq_a15': 'はい。設定 > アカウントを開き、「APIキーを変更」をタップしてください。キーを別のものに置き換えたり、最初に内蔵キーを選んでいた場合は自分のキーを追加したりできます。統計はそのままで、お気に入りの連携だけ設定し直す必要があります。',
  'nothing_wip_badge': '改善中',
  'nothing_wip_msg': 'Nothing OSスタイルは現在改善中のため、今はご利用いただけません。今後のバージョンで利用できるようになる可能性があります。',
  'ui_play_preview': 'プレビューを再生',
  'ntf_test_title': '🔔 テスト通知',
  'ntf_test_body': 'LastStats の通知は正常に動作しています！',
  'ui_not_enough_data_yet_sy': 'データがまだ足りません。設定で履歴全体を同期してください。',
  'ui_level': 'レベル {level}',
  'ui_fetching': '{currentYea} を取得中…（{yearIndex}/{totalYears}）',
  'ui_which_chart': 'どのグラフ？',
  'ui_which_period': 'どの期間？',
  'ui_all_time': '全期間',
  'ui_exporting': 'エクスポート中…',
  'ui_chart_not_available_fo': 'この期間のグラフは利用できません',
  'ui_could_not_generate_the': '画像を生成できませんでした',
  'ui_error': 'エラー',
  'ui_loading_history': '履歴{yearLabel}を読み込み中… {pct}%',
  'ui_charts_will_be_more_ac': '読み込み後、グラフはより正確になります。',
  'ui_load_the_full_history_': '全期間を見るには完全な履歴を読み込んでください。',
  'ui_load': '読み込む',
  'ui_based_on_scrobbles_all': '{v_hourlyCou} 件のスクロブルに基づく（全期間）',
  'ui_all_available_years': '利用可能な全期間',
  'ui_based_on_scrobbles_fro': '{v_selectedY}年の {v_hourlyCou} 件のスクロブルに基づく',
  'ui_based_on_recent_scrobb': '最近の {v_hourlyCou} 件のスクロブルに基づく',
  'ui_analysing_your_last_20': '直近約200件のスクロブルを分析中',
  'ui_all_time_loading': '全期間（{v_selectedY} 読み込み中）',
  'ui_all_time_2': '全期間',
  'ui_export_a_chart': 'グラフをエクスポート',
  'ui_scrobble_progression': 'スクロブルの推移',
  'ui_your_musical_genres': 'あなたの音楽ジャンル',
  'ui_based_on_your_top_arti': 'よく聴くアーティストに基づく（全期間）',
  'ui_listening_habits': 'リスニング習慣',
  'ui_album_distribution': 'アルバム別の内訳',
  'ui_listening_calendar': 'リスニングカレンダー',
  'ui_daily_activity_to': '日別アクティビティ — {first}〜{last}',
  'ui_daily_activity_all_yea': '日別アクティビティ — 全期間',
  'ui_daily_activity': '日別アクティビティ — {v_selectedY}',
  'ui_load_history_to_see': '{v_selectedY} を見るには履歴を読み込んでください',
  'ui_daily_activity_last_12': '日別アクティビティ — 直近12か月',
  'ui_all_years': '全期間',
  'ui_listening_streaks': '連続リスニング',
  'ui_total': '合計',
  'ui_avg_mo': '月平均',
  'ui_best_month': 'ベストの月',
  'ui_hourly_distribution': '時間帯別の分布',
  'ui_activity_by_day_of_wee': '曜日別アクティビティ',
  'ui_current_streak': '現在の連続記録',
  'ui_d': '日',
  'ui_best_streak': '最長の連続記録',
  'ui_best_streak_started_on': '最長の連続記録は {bestStart} から',
  'ui_no_data_for_this_perio': 'この期間のデータはありません',
  'ui_load_history_to_displa': '{what} を表示するには履歴を読み込んでください',
  'ui_less': '少ない',
  'ui_more': '多い',
  'ui_scan_a_profile': 'プロフィールをスキャン',
  'ui_lvl': 'Lv.{level}',
  'ui_qr_code': 'QRコード？',
  'ui_add_a_qr_code_to_the_s': '共有する画像にQRコードを追加して、見た人があなたのプロフィールをスキャンできるようにしますか？',
  'ui_no_qr': 'QRなし',
  'ui_to_the_app': 'アプリへ',
  'ui_to_last_fm': 'Last.fmへ',
  'ui_compare_music_taste': '音楽の好みを比較',
  'ui_syncing_full_library': 'データを同期中…',
  'ui_see_more': 'もっと見る',
  'ui_no_achievements_unlock': 'まだ実績は解除されていません',
  'ui_no_animated_cover_for_': 'このアルバムにはアニメーションカバーがありません',
  'ui_source': '提供元: {source}',
  'ui_view_on_last_fm': 'Last.fm で見る',
  'ui_original_text_last_fm_': '原文: Last.fm — 翻訳: Google 翻訳',
  'ui_source_last_fm': '提供元: Last.fm',
  'ui_dark': 'ダーク',
  'ui_light': 'ライト',
  'ui_system': 'システム',
  'ui_colored_widgets': 'カラーウィジェット',
  'ui_tint_home_screen_widge': 'ウィジェットにアクセントカラーを適用',
  'ui_search_settings': '設定を検索…',
  'ui_no_settings_found': '設定が見つかりません',
  'ui_all': 'すべて',
  'ui_battery_saver': 'バッテリーセーバー',
  'ui_save_battery_fewer_eff': 'バッテリーを節約、エフェクト控えめ',
  'ui_musical_soulmates': '音楽のソウルメイト',
  'ui_great_compatibility': '非常に高い相性',
  'ui_some_common_ground': 'いくつかの共通点',
  'ui_fairly_different_taste': '好みはかなり違う',
  'ui_worlds_apart_musically': '音楽的に正反対の世界',
  'ui_this_is_your_own_profi': 'これはあなた自身のプロフィールです！',
  'ui_artists_from_your_hist': 'あなたの履歴から{uniqueArti}組のアーティスト · {targetUser}のライブラリ全体',
  'ui_artists_from_your_hist_2': 'あなたの履歴から{uniqueArti}組のアーティスト · {targetUser}のトップ200',
  'ui_full_library_api': 'ライブラリ全体（API）',
  'ui_top_200_artists_tracks': 'トップ200のアーティストと曲（API）',
  'ui_could_not_work_out_the': '相性を計算できませんでした。',
  'ui_music_compatibility': '音楽の相性',
  'ui_analyzing_musical_tast': '音楽の好みを分析中…',
  'ui_artist': '{v_totalArti}組のアーティスト',
  'ui_track': '{v_totalTrac}曲',
  'ui_album': '{v_totalAlbu}枚のアルバム',
  'ui_shared_tracks': '共通の曲',
  'ui_shared_artists': '共通のアーティスト',
  'ui_no_shared_artists_foun': '共通のアーティストは見つかりませんでした。',
  'ui_shared_albums': '共通のアルバム',
  'ui_play_count_unavailable': 'どちらかの再生回数が取得できません。',
  'ui_you_listen_to_this_x_m': 'あなたは{theirUsern}より{x}倍多く聴いています。',
  'ui_listens_to_this_x_more': '{theirUsern}はあなたより{x}倍多く聴いています。',
  'ui_you_both_listen_to_thi': '二人ともほぼ同じ回数聴いています。',
  'ui_plays': '{plays}回再生',
  'ui_compatibility': '相性',
  'ui_you_both_love': '二人とも大好き',
  'ui_shared_top_artist': '共通のお気に入りアーティスト',
  'ui_achievements': '実績',
  'ui_qr_not_recognized_not_': 'QRコードを認識できません — LastStats/Last.fmのプロフィールではありません',
  'ui_scan_a_profile_s_qr_co': 'プロフィールのQRコードをスキャン',
  'ui_favorites': 'お気に入り',
  'ui_advanced_youtube_music': '高機能な YouTube Music クライアント。',
  'ui_syncs_the_glyphs_of_no': 'Nothing フォンの Glyph を音楽に同期させます。',
  'ui_sources': 'ソース',
  'ui_official_flutter_docs_': 'Flutter の公式ドキュメント。',
  'ui_official_material_3_gu': 'Flutter 向け Material 3 公式ガイド。',
  'ui_flutter_api_reference_': 'Material 3 テーマの Flutter API リファレンス。',
  'ui_official_flutter_packa': 'アダプティブレイアウト用の Flutter 公式パッケージ。',
  'ui_android_widgets': 'Android ウィジェット',
  'ui_applies_the_accent_col': 'ホーム画面ウィジェットの背景にアクセントカラーを適用します。オフの場合は純白または純黒になります。',
  'ui_turns_off_tilt_paralla': '傾きによるパララックスを無効にし、画面のリフレッシュレートを制限し、バックグラウンド更新を遅くします。それ以外は最高品質のままです（画像、エクスポート、共有カード）。',
  'ui_always_on': '常にオン',
  'ui_force_eco_mode_on_rega': 'バッテリー残量に関わらず省電力モードを強制的にオンにします。',
  'ui_auto_activate': '自動でオン',
  'ui_turn_on_below_a_batter': 'バッテリー残量が一定％を下回ったらオン',
  'ui_switches_on_by_itself_': 'バッテリー残量が下のレベルまで下がると自動でオンになります。',
  'ui_threshold': 'しきい値',
  'ui_choose_the_tab_display': 'アプリ起動時に表示するタブを選択します。',
  'ui_the_selected_tab_will_': '選択したタブは次回の起動時に表示されます。',
  'ui_friends_sync': 'フレンド同期',
  'ui_sync_frequency': '同期の頻度',
  'ui_daily': '毎日',
  'ui_resync_everyone': 'すべて再同期',
  'ui_version_history': 'バージョン履歴',
  'ui_could_not_load_release': '履歴を読み込めませんでした。',
  'ui_installed_dev_build_un': 'インストール済み：開発ビルド（バージョン不明）',
  'ui_installed': 'インストール済み：{displayVer}',
  'ui_search_a_version_or_ch': 'バージョンまたは変更履歴を検索…',
  'ui_official': '公式',
  'ui_no_release_matches_you': '検索に一致するバージョンはありません。',
  'ui_latest': '最新',
  'ui_installed_2': 'インストール済み',
  'ui_no_description': '説明はありません。',
  'ui_download': 'ダウンロード',
  'ui_view_release': 'リリースを見る',
  'ui_details': '詳細',
  'ui_all_past_releases_chan': '過去のすべてのバージョン、変更履歴、ダウンロード',
  'ui_please_fill_both_field': '両方の欄を入力してください。',
  'ui_api_key_must_be_32_cha': 'APIキーは32文字である必要があります。',
  'ui_profile_not_found': 'プロフィールが見つかりません。',
  'ui_chart_monthly': '月別の棒グラフ',
  'ui_chart_cumul': '推移',
  'ui_chart_genres': '音楽ジャンル',
  'ui_chart_habits': 'リスニング習慣',
  'ui_chart_artists': 'アーティスト分布',
  'ui_chart_albums': 'アルバム分布',
  'ui_chart_calendar': 'リスニングカレンダー',
  'ui_chart_streaks': '連続リスニング',
  'ui_band_night': '夜',
  'ui_band_morning': '朝',
  'ui_band_afternoon': '午後',
  'ui_band_evening': '夜（夕方）',
  'qs_t1_t': 'OLED モード',
  'qs_t1_s': '純黒の背景',
  'qs_t2_t': '省電力モード',
  'qs_t2_s': 'バッテリー消費を抑えます',
  'qs_t3_t': 'ニュース通知',
  'qs_t3_s': 'Last.fm の最新情報の通知',
  'qs_t4_t': '触覚フィードバック',
  'qs_t4_s': '操作時に振動します',
  'qs_t5_t': '実績',
  'qs_t5_s': '解除した実績を表示します',
  'qs_l1_t': 'アクセントカラー',
  'qs_l2_t': 'テーマ',
  'qs_l3_t': '言語',
  'qs_l4_t': '音楽プラットフォーム',
  'qs_l5_t': 'アカウント',
  'qs_l6_t': '同期',
  'qs_l7_t': 'キャッシュ',
  'img_src_lastfm': '提供元: Last.fm',
  'img_src_ytmusic': '提供元: YouTube Music',
  'img_src_itunes': '提供元: iTunes',
  'img_src_deezer': '提供元: Deezer',
  'img_src_audiodb': '提供元: TheAudioDB',
  'img_src_musicbrainz': '提供元: MusicBrainz',
  'img_src_wikipedia': '提供元: Wikipedia',
  'ds_type_artist': 'アーティスト',
  'ds_type_album': 'アルバム',
  'ds_type_track': '曲',
  'pf_1': '👤 ユーザープロフィール',
  'pf_2': '🎤 トップアーティスト — 全期間',
  'pf_3': '💿 トップアルバム — 全期間',
  'pf_4': '🎵 トップトラック — 全期間',
  'pf_5': '⏱️ 最近の再生',
  'pf_6': '🗓️ 今週',
  'pf_7': '📅 今月',
  'pf_8': '📅 過去3か月',
  'pf_9': '📅 過去6か月',
  'pf_10': '📅 過去12か月',
  'pf_11': '📊 月別履歴',
  'pf_12': '❤️ お気に入りの曲',
  'pf_13': '🗓️ トップアーティスト — 今週',
  'pf_14': '🗓️ アルバムとトラック — 今週',
  'ds_tier_next': '{n} / {next} で次のティアへ',
  'ds_tier_max': '最高ティアに到達 🎉',
  'ds_tier_first': 'この曲を聴いて最初のティアを解放しましょう（{n} 回再生から）。',
  'sl_import': 'データをインポート中',
  'sl_done': 'インポート完了！',
  'sl_connect': 'Last.fm に接続中…',
  'sec_chart': 'グラフ / カレンダー',
  'stat_avg_day': '1日平均',
  'stat_avg_week': '週平均',
  'stat_days_active': 'アクティブ日数',
  'stat_scrobbles_week': 'スクロブル（週）',
  'accent_purple': 'パープル',
  'accent_blue': 'ブルー',
  'accent_green': 'グリーン',
  'accent_red': 'レッド',
  'accent_orange': 'オレンジ',
  'accent_pink': 'ピンク',
  'accent_teal': 'ティール',
  'accent_neutral': 'ニュートラル',
  'shape_title': '画像の形',
  'shape_covers': 'ジャケット、アーティスト、アルバム',
  'shape_mix': 'ミックス',
  'shape_square': '四角',
  'shape_circle': '円形',
  'shape_pick_one': 'または1つの形を選択',
  'friend_listening': '再生中',
  'friend_offline': 'オフライン',
  'tier_none': 'ティアなし',
  'src_title': 'ソース',
  'src_scrobbles_meta': 'スクロブルとメタデータ',
  'src_artwork': 'アートワーク',
  'src_audio_preview': '音声プレビュー',
  'src_video_artwork': 'ビデオアートワーク',
  'tip_love': 'お気に入りに追加',
  'rail_expand': 'サイドバーを展開',
  'rail_collapse': 'サイドバーを折りたたむ',
  'a11y_loading': '読み込み中',
  'bk_pick_folder': '自動バックアップのフォルダーを選択',
  'bk_save_title': 'LastStatsのバックアップを保存',
  'bk_pick_file': 'LastStatsのバックアップファイルを選択',
  'nch_milestone_d': 'スクロブルのマイルストーン達成時に通知します',
  'nch_grand_d': '大きなマイルストーン（1K、10K、100K、1M…）の特別通知',
  'nch_recap_d': '日次・週次のリスニングまとめ',
  'nch_update_d': 'LastStatsの新バージョンが利用可能になると通知します',
  'nch_news_d': 'LastStatsの新機能・修正・お知らせ',
  'nch_sync_d': 'スクロブル履歴全体の同期の進行状況',
  'ntf_grand_1000000': '100万スクロブル。まさに伝説です。🎸',
  'ntf_grand_500000': '50万スクロブル。止まりませんね。🎧',
  'ntf_grand_250000': '{n}スクロブル。音楽は終わりません。🎶',
  'ntf_grand_100000': '{n}スクロブル！まさに音楽中毒です。🔥',
  'ntf_grand_50000': '{n}スクロブル。本当にすごい。🎵',
  'ntf_grand_25000': '{n}スクロブル、まだまだ絶好調！',
  'ntf_grand_10000': '{n}スクロブル、5桁に到達！🎉',
  'ntf_grand_5000': '{n}スクロブル、まだ増え続けています！',
  'ntf_grand_1000': '最初の{n}スクロブル。旅の始まりです。🎵',
  'ntf_update_title': 'LastStats {v} が利用可能',
  'ntf_update_body': '新しいバージョンをダウンロードできます。',
  'ntf_milestone_title': '🎵 マイルストーン：{n}スクロブル',
  'ntf_milestone_body': 'Last.fmで{n}スクロブルに到達しました 🎶',
  'ntf_daily_title': '📊 今日のまとめ · {d}',
  'ntf_weekly_title': '📅 週のまとめ · {w}',
  'ntf_recap_body': '{n}スクロブル · トップ：{a}',
  'ntf_n_today': '今日は{n}スクロブル',
  'ntf_n_week': '今週は{n}スクロブル',
  'ntf_top_artist': 'トップアーティスト：{a}',
  'ntf_update_avail': '🆕 アップデートがあります',
  'ntf_update_ready': 'LastStats {v} の準備ができました。タップして確認。',
  'ntf_sync_title': '🔄 スクロブルを同期中…',
  'ntf_sync_done': '✅ スクロブルを同期しました',
  'ntf_sync_new': '新しいスクロブルを{n}件追加しました。',
  'ntf_grand_t': '{v}スクロブル！',
  'ntf_year': '{y}年',
  'ntf_week': '第{w}週',
  'reorder': '並べ替え',
  'sp_login_t': 'Spotify にログイン',
  'sp_login_hint': 'Spotify のメールアドレスとパスワードでログインしてください。ログインが完了すると、この画面は自動的に閉じます。',
  'sp_t': 'Spotify (Canvas)',
  'sp_on': '接続済み',
  'sp_off': '未接続',
  'sp_off_s': 'Spotify からログアウトしました',
  'sp_need': 'Spotify のログインが必要です：プロフィール > 接続ページ。',
  'conn_title': '接続',
  'conn_btn_t': '接続ページ',
  'conn_btn_s': 'Last.fm、Spotify、APIキー',
  'conn_sp_desc': '動画カバー（Canvas）に使用します。Spotify アカウントが必要です。',
  'conn_connect': '接続',
  'conn_disconnect': '切断',
  'conn_keys': 'APIキー',
  'conn_manage': 'アカウント管理',
  'conn_test': 'Spotify をテスト',
  'conn_testing': 'テスト中…',
  'conn_q_note': 'Spotify Canvas の画質は1種類です。画質設定は Apple Music と YouTube にのみ適用されます。',
  'conn_lfm_desc': '方法は2つです：Last.fm のサイトでログインする（アプリ内蔵のキーを使用）か、ご自身の API キーを使用します。',
  'conn_lfm_web': 'Last.fm でログイン',
  'lfm_login_t': 'Last.fm にログイン',
  'lfm_login_hint': 'Last.fm のサイトでログインしてください。アプリがユーザー名を検出し、この画面を閉じます。',
  'dg_cookie': 'ログインCookie',
  'dg_token': 'Webトークン',
  'dg_search': '検索',
  'dg_ok': 'OK',
  'dg_missing': 'なし',
  'dg_failed': '失敗',
  'dg_found': '動画が見つかりました',
  'dg_nofound': '動画なし',
  'dg_notpl': '検索テンプレートがありません（しばらくしてから再試行してください）',
  'dg_results': '件の結果',
  'lfm_web_sub': 'APIキーは不要です：アプリ内蔵のキーを使用します。',
  'lfm_manual_hint': 'ユーザー名を自動で取得できませんでした。ログイン後に下に入力してください。',
  'lfm_manual_label': 'ユーザー名',
  'rec': '推奨',
  'not_rec': '非推奨',
  'sm_title': '接続方法',
  'sm_key_t': '自分のAPIキー',
  'sm_key_s': '専用の利用枠、お気に入りも利用可。',
  'sm_builtin_t': '内蔵キー',
  'sm_builtin_s': 'ユーザー名のみ。利用枠は他のユーザーと共有。',
  'wl_title': 'ようこそ',
  'wl_sub': 'Last.fm への接続方法をお選びください。',
};
