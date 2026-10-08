// lib/l10n/strings_ru.dart
// ══════════════════════════════════════════════════════════════════════════
//  Russian
// ══════════════════════════════════════════════════════════════════════════

import "app_strings.dart";

class AppStringsRu implements AppStrings {
  const AppStringsRu();

  @override String get period7day => 'Неделя';
  @override String get period1month => 'Месяц';
  @override String get period3month => '3 месяца';
  @override String get period6month => '6 месяцев';
  @override String get period12month => 'Год';
  @override String get periodOverall => 'Всё время';
  @override String get navDashboard => 'Обзор';
  @override String get navSearch => 'Поиск';
  @override String get navRankings => 'Рейтинги';
  @override String get navCharts => 'Графики';
  @override String get navHistory => 'История';
  @override String get navSettings => 'Настройки';
  @override String get cacheTitle => 'Хранилище';
  @override String get cacheUsage => 'Использовано';
  @override String get cacheLimit => 'Лимит хранилища';
  @override String get cacheLimitHint => 'По достижении лимита давно не используемые изображения удаляются автоматически.';
  @override String get cacheClearSection => 'Очистить';
  @override String get cacheImages => 'Изображения';
  @override String get cacheImagesSubtitle => 'Обложки исполнителей, альбомов и треков';
  @override String get cacheApiData => 'Данные API';
  @override String get cacheApiDataSubtitle => 'Топ исполнителей, альбомов, недавние треки…';
  @override String get cacheScrobbles => 'История скробблов';
  @override String get cacheScrobblesSubtitle => 'Все загруженные записи скробблов';
  @override String get cacheClearBtn => 'Очистить';
  @override String get cacheConfirmScrobblesTitle => 'Очистить историю скробблов?';
  @override String get cacheConfirmScrobblesBody => 'Вся история будет удалена и загружена заново при следующем запуске.';
  @override String get cacheConfirmAllTitle => 'Очистить весь кэш?';
  @override String get cacheConfirmAllBody => 'Изображения, данные API и история скробблов будут полностью удалены.';
  @override String get cacheDelete => 'Удалить';
  @override String get commonArtists => 'Исполнители';
  @override String get commonAlbums => 'Альбомы';
  @override String get commonTracks => 'Треки';
  @override String get commonNoResults => 'Нет результатов';
  @override String get commonRetry => 'Повторить';
  @override String get commonCancel => 'Отмена';
  @override String get commonApply => 'Применить';
  @override String get commonPlays => 'прослушиваний';
  @override String get commonListeners => 'слушателей';
  @override String get commonNowPlayingBadge => 'СЕЙЧАС';
  @override String get commonNowPlayingLong => 'Сейчас играет';
  @override String get commonRecentTracks => 'Недавние треки';
  @override String get commonNoRecentTracks => 'Нет недавних треков';
  @override String get commonTopArtists => 'Топ исполнителей';
  @override String get rankingsTitle => 'Рейтинги';
  @override String get rankingsPodium => 'Пьедестал';
  @override String get rankingsContinued => 'Остальная часть рейтинга';
  @override String get rankingsAllYears => 'Все годы';
  @override String get chartsTitle => 'Графики';
  @override String get chartsMonthly => 'Скробблы (12 месяцев)';
  @override String get chartsArtistDist => 'Топ исполнителей (распределение)';
  @override String get chartsMainstreamTitle => 'Мейнстрим и скрытые жемчужины';
  @override String get chartsMainstreamSubtitle => 'Мировая популярность ваших любимых исполнителей.';
  @override String get chartsCompute => 'Рассчитать';
  @override String get chartsRecompute => 'Пересчитать';
  @override String get chartsGem => 'Скрытая жемчужина';
  @override String get chartsMainstream => 'Мейнстрим';
  @override String get historyTitle => 'История';
  @override String get historySubtitle => 'Ваши прослушивания день за днём';
  @override String get historyToday => 'Сегодня';
  @override String get historySelectDate => 'Выберите дату';
  @override String get historyChronological => 'Хронологически';
  @override String get historyList => 'Список';
  @override String get historyStats => 'Статистика';
  @override String get historyNoTracks => 'В этот день прослушиваний не было';
  @override String get historyTopArtists => 'Топ исполнителей';
  @override String get historyTopAlbums => 'Топ альбомов';
  @override String get historyTopTracks => 'Топ треков';
  @override String get historyHourTracks => 'трек';
  @override String get searchTitle => 'Поиск';
  @override String get searchProfiles => 'Профили';
  @override String get searchHintBar => 'Исполнитель, альбом, трек или профиль…';
  @override String get searchHintProfiles => 'Найти пользователя Last.fm';
  @override String get searchHintArtists => 'Найти исполнителя';
  @override String get searchHintAlbums => 'Найти альбом';
  @override String get searchHintTracks => 'Найти песню';
  @override String get searchTypePrompt => 'Введите текст в строке поиска выше';
  @override String get searchAll => 'Все';
  @override String get searchFolders => 'Папки';
  @override String get searchFoldersHint => 'Создайте папку, чтобы сохранять треки, альбомы или исполнителей.';
  @override String get perDay => 'в день';
  @override String get activityDays => 'дней активности';
  @override String get dashStats => 'Статистика';
  @override String get dashTopTracks => 'Топ треков';
  @override String get dashFriends => 'Друзья';
  @override String get dashRefresh => 'Обновить';
  @override String get dashRefreshFriends => 'Обновить друзей';
  @override String get dashScrobbles => 'скробблов';
  @override String get dashScrobblesPerDay => 'в день';
  @override String get dashDaysActive => 'дней активности';
  @override String get dashLastTrack => 'Последний трек';
  @override String get dashArtist1 => 'Исполнитель №1';
  @override String get dashAlbum1 => 'Альбом №1';
  @override String get dashTrack1 => 'Трек №1';
  @override String get dashNoFriends => 'Друзья не найдены';
  @override String get dashResetCache => 'Сбросить кэш';
  @override String get dashResetCacheConfirm => 'Все локально сохранённые данные скробблов будут удалены и загружены заново с Last.fm.';
  @override String get dashFriendsActivity => 'Активность ваших друзей на Last.fm';
  @override String get settingsTitle => 'Настройки';
  @override String get settingsAppearance => 'Внешний вид';
  @override String get settingsTheme => 'Тема';
  @override String get settingsThemeAuto => 'Авто';
  @override String get settingsThemeLight => 'Светлая';
  @override String get settingsThemeDark => 'Тёмная';
  @override String get settingsAccentColor => 'Акцентный цвет';
  @override String get settingsAccentAuto => 'Авто';
  @override String get settingsCustomColor => 'Свой цвет';
  @override String get settingsCustomColorEdit => 'Изменить';
  @override String get settingsDynamicColor => 'Динамический цвет';
  @override String get settingsDayNightAccent          => 'Акцент день/ночь';
  @override String get settingsDayNightAccentToggle    => 'Разные цвета днём и ночью';
  @override String get settingsDayNightAccentToggleSub => 'Использует другой акцентный цвет для тёмной темы.';
  @override String get settingsDayNightAccentDark      => 'Цвет (тёмная тема)';
  @override String get settingsDayNightUseHours        => 'Использовать точное время';
  @override String get settingsDayNightUseHoursSub     => 'Меняет цвет по времени суток, а не по активной теме.';
  @override String get settingsDayNightDayStart        => 'День начинается в';
  @override String get settingsDayNightNightStart      => 'Ночь начинается в';
  @override String get settingsMaterialYou => 'Material You';
  @override String get settingsMaterialYouSub => 'Использовать цвет обоев Android';
  @override String get settingsMusicColor => 'Цвет из музыки';
  @override String get settingsMusicColorSub => 'Извлекает цвет из обложки текущего альбома';
  @override String get settingsMusicColorNote => 'Основной цвет текущей обложки альбома заменяет акцентный цвет.';
  @override String get settingsMusicColorLocked => 'Сначала отключите Material You';
  @override String get settingsStartupPage => 'Начальная страница';
  @override String get settingsStartupTab => 'Вкладка при запуске';
  @override String get settingsDashboardSection => 'Обзор';
  @override String get settingsHeaderImage => 'Изображение заголовка';
  @override String get settingsHeaderImageSub => 'Выбранная обложка отображается как фон главного экрана.';
  @override String get settingsHeaderSource => 'Источник';
  @override String get settingsHeaderPeriod => 'Период';
  @override String get settingsHeaderAnimation => 'Переход';
  @override String get settingsHeaderAnimationSub => 'Анимация при смене обложки.';
  @override String get settingsHeaderBlur => 'Размытие';
  @override String get settingsHeaderBlurNone => 'Нет';
  @override String get settingsHeaderCustomUrl => 'URL изображения';
  @override String get settingsHeaderCustomUrlHint => 'https://example.com/image.jpg';
  @override String get settingsHeaderCustomUrlSub => 'Вставьте прямую ссылку на изображение (jpg, png, webp…).';
  @override String get settingsHeaderApply => 'Применить';
  @override String get settingsHeaderFallback => 'Изображение по умолчанию';
  @override String get settingsHeaderFallbackSub => 'Отображается, когда музыка не играет.';
  @override String get settingsHeaderFallbackUrlLabel => 'URL изображения по умолчанию';
  @override String get settingsVisibleSections => 'Видимые разделы';
  @override String get settingsNowPlayingSection => 'Сейчас играет';
  @override String get settingsStatsSection => 'Статистика';
  @override String get settingsTopArtistsSection => 'Топ исполнителей';
  @override String get settingsTopTracksSection => 'Топ треков';
  @override String get settingsFriendsSection => 'Друзья';
  @override String get settingsFriendsSectionSub => 'Активность ваших друзей на Last.fm';
  @override String get settingsAccount => 'Аккаунт';
  @override String get settingsConnectedProfile => 'Подключённый профиль Last.fm';
  @override String get settingsLogout => 'Выйти';
  @override String get settingsLogoutTitle => 'Выйти из аккаунта?';
  @override String get settingsLogoutContent => 'Ваши учётные данные будут удалены.';
  @override String get settingsLogoutConfirm => 'Выйти';
  @override String get settingsBackup => 'Резервное копирование и восстановление';
  @override String get settingsExport => 'Экспорт настроек';
  @override String get settingsExportSub => 'Копирует JSON в буфер обмена';
  @override String get settingsImport => 'Восстановить резервную копию';
  @override String get settingsImportSub => 'Вставьте ранее экспортированный JSON';
  @override String get settingsBackupInfo => 'Включает: тему, цвета, ключ API, имя пользователя, заголовок, избранное. Совместимо между версиями.';
  @override String get settingsUpdates => 'Обновления';
  @override String get settingsAutoUpdate => 'Автоматическая проверка';
  @override String get settingsAutoUpdateSub => 'Раз в день';
  @override String get settingsCheckNow => 'Проверить сейчас';
  @override String get settingsUpToDate => 'Обновлено';
  @override String get settingsCheckFailed => 'Проверка не удалась.';
  @override String get settingsDownload => 'Скачать';
  @override String get settingsViewRelease => 'Просмотреть';
  @override String get settingsAbout => 'О приложении';
  @override String get settingsVersion => 'Версия';
  @override String get settingsWebVersion => 'Веб-версия';
  @override String get settingsWebVersionSub => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode => 'Исходный код';
  @override String get settingsSourceCodeSub => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage => 'Язык';
  @override String get settingsAboutProjectDesc => 'LastStats, личный проект с открытым исходным кодом. Может содержать ошибки.';
  @override String get settingsAboutSupport => 'Поддержать проект';
  @override String get settingsAboutSupportSub => '⭐ Поставьте звезду на GitHub';
  @override String get settingsFaq => 'Частые вопросы';
  @override String get headerNowPlaying => 'Сейчас играет';
  @override String get headerTopTrack => 'Трек №1';
  @override String get headerTopAlbum => 'Альбом №1';
  @override String get headerTopArtist => 'Исполнитель №1';
  @override String get headerCustomImage => 'Своё изображение';
  @override String get headerThemeColor => 'Цвет темы';
  @override String get headerAnimNone => 'Нет';
  @override String get headerAnimFade => 'Затухание';
  @override String get headerAnimSlide => 'Сдвиг';
  @override String get headerAnimZoom => 'Масштаб';
  @override String get headerPeriodWeek => 'Неделя';
  @override String get headerPeriodMonth => 'Месяц';
  @override String get headerPeriodAllTime => 'Всё время';
  @override String get colorPickerTitle => 'Свой цвет';
  @override String get colorPickerHue => 'Оттенок';
  @override String get colorPickerSaturation => 'Насыщенность';
  @override String get colorPickerBrightness => 'Яркость';
  @override String get colorPickerQuickColors => 'Быстрые цвета';
  @override String get colorPickerInvalid => 'Неверный формат';
  @override String get colorCustomTooltip => 'Свой';
  @override String get exportTitle => 'Экспорт настроек';
  @override String get exportFilename => 'Имя файла';
  @override String get exportJsonContent => 'Содержимое JSON';
  @override String get exportInfo => 'Скопируйте этот JSON, вставьте в текстовый файл и назовите его с расширением .json';
  @override String get exportCopy => 'Копировать JSON';
  @override String get exportCopied => 'Скопировано!';
  @override String get importTitle => 'Восстановить резервную копию';
  @override String get importHintLabel => 'Вставьте сюда резервную копию LastStats.';
  @override String get importEmpty => 'Поле пусто.';
  @override String get importInvalidJson => 'Неверный JSON.';
  @override String get importUnknownFile => 'Файл не распознан.';
  @override String get importInvalidFormat => 'Неверный формат.';
  @override String get importSuccess => 'Настройки успешно восстановлены ✓';
  @override String get importRestore => 'Восстановить';
  @override String get setupImportJson => 'Импортировать JSON';
  @override String get setupImportHintLabel => 'Вставьте ниже содержимое файла JSON.';
  @override String get setupImportNote => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields => 'Неверный JSON: отсутствуют поля "username" или "api_key".';
  @override String get detailTracklist => 'Треки';
  @override String get detailAlbumLabel => 'Альбом';
  @override String get detailDuration => 'Длительность';
  @override String get detailTopTracks => 'Популярные треки';
  @override String get detailTopAlbums => 'Популярные альбомы';
  @override String get detailBioReadMore => 'Читать далее';
  @override String get detailBioReadLess => 'Свернуть';
  @override String get detailUserPlays => 'ваши прослушивания';
  @override String get detailGlobalPlays => 'всего прослушиваний';
  @override String get detailUserRank => 'место';
  @override String get detailUserRankNA => 'Н/Д';
  @override String get detailGlobalListeners => 'слушателей';
  @override String get detailPeriod => 'Период';
  @override String get detailBiography => 'Биография';
  @override String get detailGlobalListenersLabel => 'Слушатели';
  @override String get detailTranslate => 'Перевести';
  @override String get detailShowOriginal => 'Показать оригинал';
  @override String get detailLyrics => 'Текст песни';
  @override String get detailLyricsNotFound => 'Текст песни недоступен';
  @override String get detailCopyLyrics => 'Копировать текст';
  @override String get detailLyricsCopied => 'Текст скопирован';

  @override String get detailShoutbox => 'Обсуждение на Last.fm';
  @override String get detailShoutboxReply => 'Ответить';  @override String get dashPerWeek => 'в неделю';
  @override String get onboardSkip => 'Пропустить';
  @override String get onboardNext => 'Далее';
  @override String get onboardFinish => 'Готово';
  @override String get onboardBack => 'Назад';
  @override String get onboardAppearanceTitle => 'Настройте свой стиль';
  @override String get onboardAppearanceSub => 'Тема, акцентный цвет и Material You.';
  @override String get onboardNotifTitle => 'Будьте в курсе';
  @override String get onboardNotifSub => 'Уведомления и вибрация.';
  @override String get onboardFavTitle => 'Ваши избранные профили';
  @override String get onboardFavSub => 'Добавьте друзей с Last.fm, чтобы быстро их находить.';
  @override String get onboardFavHint => 'Имя пользователя Last.fm';
  @override String get onboardFavAdd => 'Добавить';
  @override String get onboardFavEmpty => 'Пока нет избранного';
  @override String get onboardFavSearchHint => 'Поиск профиля Last.fm…';
  @override String get onboardFavNoResults => 'Профиль не найден';
  @override String get onboardFavFriendsTitle => 'Ваши друзья на Last.fm';
  @override String get onboardFavNoFriends => 'На этом аккаунте друзья не найдены';
  @override String get onboardFavSelected => 'Выбранное избранное';
  @override String get onboardDashTitle => 'Ваш обзор';
  @override String get onboardDashSub => 'Выберите, какие разделы показывать.';
  @override String get onboardStartupTitle => 'Экран запуска';
  @override String get onboardStartupSub => 'Какую вкладку вы хотите видеть первой?';
  @override String get onboardPlatformTitle => 'На чём вы слушаете музыку?';
  @override String get onboardPlatformSub => 'Это отображает только полезные ссылки на страницах треков/исполнителей/альбомов.';
  @override String get platformLastfm => 'Last.fm';
  @override String get platformSpotify => 'Spotify';
  @override String get platformYtMusic => 'YouTube Music';
  @override String get platformOther => 'Другое / показать всё';
  @override String get settingsMusicPlatform => 'Музыкальная платформа';
  @override String get settingsMusicPlatformSub => 'Фильтрует ссылки, показанные на страницах деталей';
  @override String get settingsShowAllPlatformLinks => 'Всегда показывать всё';
  @override String get settingsShowAllPlatformLinksSub => 'Игнорировать фильтр и показывать все ссылки (Last.fm, Spotify, YT Music, Web)';
  @override String get onboardUpdatesTitle => 'Обновления';
  @override String get onboardUpdatesSub => 'Автоматическая проверка новых версий.';
  @override String get onboardStyle => 'Стиль';
  @override String get onboardStyleMaterialYou => 'Material You';
  @override String get onboardStyleNothing => 'Nothing OS';
  @override String get onboardPreview => 'Предпросмотр';
  @override String get onboardPreviewButton => 'Кнопка';
  @override String get onboardPreviewOutline => 'Контур';
  @override String get onboardPreviewText => 'Пример текста';
  @override String get onboardPreviewBubble => 'Пузырь';
  @override String get onboardAccentTint => 'Оттенок акцента';
  @override String get onboardNothingRedOnly => 'Только красный';
  @override String get onboardNothingRedYellow => 'Красный + жёлтый';
  @override String get onboardDisplay => 'Экран';
  @override String get onboardOledTitle => 'Настоящий чёрный OLED';
  @override String get onboardOledSub => 'Абсолютно чёрный фон в тёмном режиме';
  @override String get onboardArtworkColorTitle => 'Цвет из обложки';
  @override String get onboardArtworkColorSub => 'Подстраивает акцентный цвет под текущую обложку';
  @override String get onboardNewsTitle => 'Уведомления о новостях';
  @override String get onboardNewsSub => 'Получайте уведомления о новых функциях и исправлениях';
  @override String get onboardNewsBadgeTitle => 'Значок новостей';
  @override String get onboardNewsBadgeSub => 'Красная точка на колокольчике, когда есть новости';
  @override String get onboardHapticTitle => 'Тактильная отдача';
  @override String get onboardHapticSub => 'Лёгкая вибрация при ключевых действиях';
  @override String get onboardRecaps => 'Сводки';
  @override String get onboardDailyRecapTitle => 'Дневная сводка';
  @override String get onboardDailyRecapSub => 'Краткий обзор вашего дня прослушивания';
  @override String get onboardWeeklyRecapTitle => 'Недельная сводка';
  @override String get onboardWeeklyRecapSub => 'Ваши топ исполнители, альбомы и треки недели';
  @override String get onboardMilestonesSection => 'Рубежи по скробблам';
  @override String get onboardMilestonesTitle => 'Рубежи';
  @override String get onboardMilestonesSub => 'Отмечайте круглые числа скробблов';
  @override String get onboardGrandMilestonesTitle => 'Крупные рубежи';
  @override String get onboardGrandMilestonesSub => 'Особое празднование крупных рубежей';
  @override String get onboardDynamicColorSub => 'Использовать цвета из обоев (Android 12+)';
  @override String get onboardBetaTitle => 'Бета-обновления';
  @override String get onboardBetaSub => 'Ранний доступ к предварительным версиям';
  @override String get notifDetailTitle => 'Уведомление';
  @override String get notifDetailOpenLink => 'Открыть ссылку';
  @override String get settingsCheckingUpdates => 'Проверка обновлений…';
  @override String get settingsTapToDownload => 'Нажмите, чтобы скачать';
  @override String get detailLookingForPreview => 'Поиск превью…';
  @override String get detailPreview30Sec => 'Превью · 30 сек';
  @override String get setupTagline => 'Ваша статистика Last.fm, переосмысленная.';
  @override String get setupAnalyseProfile => 'Проанализировать профиль';
  @override String get setupConnecting => 'Подключение…';
  @override String get setupStartAnalysis => 'Начать анализ';
  @override String get setupOr => 'или';
  @override String get setupUsernameLabel => 'Имя пользователя Last.fm';
  @override String get setupApiKeyLabel => 'Ключ API Last.fm';
  @override String get setupApiKeyHint => '16-ричный ключ из 32 символов';
  @override String get setupApiKeyPrivacyNote => 'Хранится локально. Никогда не передаётся третьим лицам.';
  @override String get setupRememberMe => 'Запомнить меня';
  @override String get setupGetApiKey => 'Получить бесплатный ключ API';
  @override String get setupWelcomeBanner => 'Добро пожаловать в LastStats!';
  @override String get setupOneTimeImportNote => 'Разовый импорт, следующие запуски будут мгновенными.';
  @override String get dashTapToDownload => 'Нажмите, чтобы скачать.';
  @override String get dashWeekLabel => 'ЭТА НЕДЕЛЯ';
  @override String get dashMonthLabel => 'ЭТОТ МЕСЯЦ';
  @override String get dashYearLabel => 'ЭТОТ ГОД';
  @override String get dashTopArtistLabel => 'Топ исполнитель';
  @override String get dashTopTrackLabel => 'Топ трек';
  @override String get dashScrobblesLabel => 'Скробблы';
  @override String get newsTypeFeatures => 'Функции';
  @override String get newsTypeFixes => 'Исправления';
  @override String get newsTypeUpdates => 'Обновления';
  @override String get newsTypeAlerts => 'Оповещения';
  @override String get newsTypeInfo => 'Информация';
  @override String get newsWhatsNew => 'Что нового';
  @override String get newsFilters => 'Фильтры';
  @override String get newsAll => 'Все';
  @override String get newsAnyDate => 'Любая дата';
  @override String get newsNoNewsYet => 'Пока нет новостей';
  @override String get settingsNotifications => 'Уведомления';
  @override String get settingsCache => 'Кэш';
  @override String get settingsCardAppearanceSub => 'Тема, акцент, макет, Material You';
  @override String get settingsCardDashboardSub => 'Изображение заголовка, видимые разделы, карточки статистики';
  @override String get settingsCardStartupSub => 'Вкладка при запуске приложения';
  @override String get settingsCardNotificationsSub => 'Рубежи, дневные и недельные сводки';
  @override String get settingsSync => 'Синхронизация';
  @override String get settingsCardSyncSub => 'Автоматическая фоновая синхронизация скробблов';
  @override String get settingsCardAccountSub => 'Подключённый профиль Last.fm, выход';
  @override String get settingsCardCacheSub => 'История, изображения, данные API';
  @override String get settingsCardBackupSub => 'Экспорт и восстановление настроек';
  @override String get settingsCardUpdatesSub => 'Проверка новых версий';
  @override String get settingsCardAboutSub => 'Версия, исходный код, авторы';
  @override String get settingsCardFaqSub => 'Скробблинг, платформы, открытый исходный код';
  @override String get settingsRestartNotice => 'Некоторые настройки требуют перезапуска приложения для полного вступления в силу.';
  @override String get syncPageTitle => 'Синхронизация скробблов';
  @override String get syncAutoTitle => 'Автоматическая синхронизация';
  @override String get syncAutoSubtitle => 'Синхронизирует вашу историю в фоне через регулярные интервалы';
  @override String get syncFrequencyLabel => 'Частота';
  @override String get syncFrequencyDaily => 'Раз в день';
  @override String get syncManualTitle => 'Ручная синхронизация';
  @override String get syncNowButton => 'Синхронизировать сейчас';
  @override String get syncInProgress => 'Синхронизация…';
  @override String get syncLastSyncLabel => 'Последняя синхронизация';
  @override String get syncNeverLabel => 'Никогда';
  @override String get syncTotalScrobblesLabel => 'Скробблов в кэше';
  @override String get syncUpToDateMsg => 'История актуальна';
  @override String get syncNotifNote => 'Во время полной синхронизации появляется уведомление о ходе выполнения.';
  @override String get pcModeLayout => 'Макет';
  @override String get pcModeNavLayout => 'Макет навигации';
  @override String get pcModeAuto => 'Авто';
  @override String get pcModeSideRail => 'Боковая панель';
  @override String get pcModeBottomBar => 'Нижняя панель';
  @override String get pcModeHintAuto => 'Боковая панель на широких экранах (≥ 720 dp), нижняя панель на узких.';
  @override String get pcModeHintOn => 'Всегда использовать боковую панель навигации, независимо от размера экрана.';
  @override String get pcModeHintOff => 'Всегда использовать нижнюю панель навигации, независимо от размера экрана.';
  @override String get aboutTagline => 'Ваш спутник по статистике Last.fm';
  @override String get aboutAppInfo => 'Информация о приложении';
  @override String get aboutScrobbleDownloader => 'Загрузчик скробблов';
  @override String get aboutScrobbleDownloaderSub => 'Экспортируйте все ваши скробблы в файл';
  @override String get aboutPoweredBy => 'Работает на';
  @override String get aboutImageDisclaimer => 'Изображения исполнителей, альбомов и треков автоматически загружаются из этих источников и иногда могут быть неверными или не соответствовать содержимому.';
  @override String get aboutFooter => 'Сделано с ❤️ · Не связано с Last.fm / CBS';
  @override String get updatesCurrentVersion => 'Текущая версия';
  @override String get updatesBetaTitle => 'Бета-обновления';
  @override String get updatesBetaSub => 'Ранний доступ к предварительным версиям';
  @override String get backupWhatsIncluded => 'Что включено';
  @override String get backupDownloadFile => 'Скачивает файл .json';
  @override String get backupChooseFile => 'Выбрать файл резервной копии';
  @override String get backupFileSaved => 'Резервная копия сохранена';
  @override String get backupFileSaveFailed => 'Не удалось сохранить файл';
  @override String get setupRestoreBackup => 'Восстановить резервную копию';
  @override String get setupRestoreBackupSub => 'Восстановите аккаунт и настройки из файла резервной копии .json';
  @override String get backupRestoreKeysTitle => 'Восстановить ключи API';
  @override String get backupRestoreKeysDesc => 'Выберите, какие ключи Last.fm восстановить из этой резервной копии.';
  @override String get backupRestoreApiKeyLabel => 'Ключ API';
  @override String get backupRestoreSecretKeyLabel => 'Секретный ключ';
  @override String get backupIncludeFoldersLabel => 'Включить папки';
  @override String get backupIncludeFoldersDesc => 'Сохраняет ваши папки с треками и их содержимое.';
  @override String get backupIncludeKeysDesc => 'Включить ключи в экспортируемый файл';

  @override String get backupIncludeThemesLabel => 'Экспортировать темы';
  @override String get backupIncludeThemesDesc => 'Позволяет поделиться только внешним видом (цвета, стиль) с кем-то ещё.';

  @override String get backupAutoTitle => 'Автоматическое резервное копирование';
  @override String get backupAutoEnableLabel => 'Включить автоматическое резервное копирование';
  @override String get backupAutoEnableDesc => 'Самостоятельно сохраняет резервную копию с выбранным ниже интервалом.';
  @override String get backupAutoFreqLabel => 'Частота';
  @override String get backupAutoFreqDaily => 'Каждый день';
  @override String get backupAutoFreqWeekly => 'Каждую неделю';
  @override String get backupAutoFreqMonthly => 'Каждый месяц';
  @override String get backupAutoFreqYearly => 'Каждый год';
  @override String get backupAutoFolderLabel => 'Папка для резервных копий';
  @override String get backupAutoFolderDefault => 'Папка приложения по умолчанию';
  @override String backupAutoNextLabel(String date) => 'Следующая копия: $date';  @override String get backupIncludeScrobblesLabel => 'Включить всю историю';
  @override String get backupIncludeScrobblesDesc => 'Добавляет все прослушанные треки с самого начала (может быть большим).';

  @override String get backupScrobblesSlowWarning => 'Это может занять некоторое время и медленнее обычной резервной копии.';  @override String backupExportedOn(String date) => 'Резервная копия от $date';
  @override String get backupScrobblesErrorTitle => 'Ошибка в истории';
  @override String get backupScrobblesErrorDesc => 'Похоже, некоторые годы истории повреждены в этом файле. Что вы хотите сделать?';
  @override String get backupScrobblesKeepAnyway => 'Продолжить в любом случае';
  @override String get backupScrobblesCancel => 'Отменить историю';
  @override String get backupScrobblesSkipRefetch => 'Пропустить и загрузить заново онлайн';  @override String get settingsCrashLog => 'Журнал ошибок';
  @override String get backupCrashLogDesc => 'Записывает ошибки приложения — полезно при сообщении о баге.';
  @override String get backupCrashLogShare => 'Поделиться журналом';
  @override String get backupCrashLogClear => 'Очистить журнал';
  @override String get backupCrashLogEmpty => 'Ошибок не зафиксировано';
  @override String get backupCrashLogCleared => 'Журнал очищен';
  @override String get backupCrashLogClearConfirm => 'Очистить журнал ошибок?';
  @override String get faqSectionLabel => 'Часто задаваемые вопросы';
  @override String get backupOverwriteWarning => 'Восстановление резервной копии перезапишет ваши текущие настройки.';
  @override String get faqOpenSourceBadge => 'LastStats, бесплатный проект с открытым исходным кодом, созданный SanoBld с ❤️.';
  @override String get cacheUnlimited => 'Без ограничений';
  @override String get cacheTotalUsed => 'Всего использовано';
  @override String get cacheScrobblesShort => 'Скробблы';
  @override String get restartHintFeatures => 'Некоторым функциям может потребоваться перезапуск приложения для вступления в силу.';
  @override String get reorderCardsTitle => 'Изменить порядок карточек';
  @override String get commonSave => 'Сохранить';
  @override String get dashFallbackWhenNoMusic => 'Когда музыка не играет';
  @override String get dashFallbackChooseDisplay => 'Выберите, что показывать в качестве фона вместо этого';
  @override String get dashFallbackPeriodLabel => 'Резервный период';
  @override String get fallbackPeriod1Week => '1 неделя';
  @override String get fallbackPeriod1Month => '1 месяц';
  @override String get fallbackPeriodAllTime => 'Всё время';
  @override String get fallbackTypeNothing => 'Ничего';
  @override String get fallbackTypeTopTrack => 'Топ трек';
  @override String get fallbackTypeTopAlbum => 'Топ альбом';
  @override String get fallbackTypeTopArtist => 'Топ исполнитель';
  @override String get fallbackTypeCustomImage => 'Своё изображение';
  @override String get fallbackWillShowCustomUrl => 'Будет показано: URL своего изображения';
  @override String get dashAnimationBlurSection => 'Анимация и размытие';
  @override String get dashMusicAnimationTitle => 'Музыкальная анимация';
  @override String get dashMusicAnimationSub => 'Когда играет музыка, изображение заголовка медленно размывается и смещается, как в Apple Music.';
  @override String get dashMusicAnimationInfo => 'Размытие устанавливается автоматически, когда включён этот режим. Ползунок размытия выше не действует, пока играет музыка.';
  @override String get settingsTopAlbumsSection => 'Топ альбомов';
  @override String get dashRecentPlaysLabel => 'Недавние прослушивания';
  @override String get dashStatCardsSectionLabel => 'Карточки статистики';
  @override String get dashStatCardsHeading => 'Карточки статистики';
  @override String get dashStatCardsSub => 'Выберите и упорядочьте карточки, показанные в блоке статистики.';
  @override String get settingsDashboardChartSection => 'График панели';
  @override String get dashChartCalendarLabel => 'Календарь прослушиваний';
  @override String get dashChartMonthlyLabel => 'Столбцы по месяцам';
  @override String get settingsDisplayNameSection => 'Своё имя';
  @override String get settingsDisplayNameLabel => 'Как вас называть?';
  @override String get settingsDisplayNameHint => 'Например, Sano Bld — оставьте пустым, чтобы использовать имя аккаунта';
  @override String get newsSearchHint => 'Поиск по новостям…';
  @override String get aboutOpenSourceLibs => 'Библиотеки с открытым кодом';
  @override String get aboutOpenSourceLibsSub => 'Все пакеты Flutter, использованные для создания приложения.';
  @override String get aboutLicenseSection => 'Лицензия';
  @override String get aboutLicenseText => 'Этот проект выпущен под лицензией MIT: вы можете свободно использовать, изменять, копировать или распространять его, просто указывайте автора.';
  @override String get aboutLicenseLink => 'Посмотреть полную лицензию';
  @override String get languageAiNote => 'Переводы созданы с помощью ИИ и могут содержать неточности.';
  @override String get aboutAiDevNote => 'ИИ также использовался при разработке этого приложения.';
  @override String get notifWorkManagerInfo => 'Уведомления работают в фоне через WorkManager. Приложение не обязательно должно быть открыто. Требуется подключение к интернету.';
  @override String get notifIntervalTitle => 'Каждые X скробблов';
  @override String get notifIntervalSubtitle => 'Получайте уведомления через регулярные интервалы';
  @override String get notifRecapsSection => 'Сводки прослушивания';
  @override String get notifDailyRecapSubtitle => 'Количество скробблов + топ исполнитель за день';
  @override String get notifWeeklyRecapSubtitle => 'Количество скробблов + топ исполнитель за неделю';
  @override String get notifNewsSection => 'Новости';
  @override String get notifSyncSection => 'Синхронизация';
  @override String get notifSyncTitle => 'Уведомления о синхронизации';
  @override String get notifSyncSubtitle => 'Оповещать по завершении синхронизации истории';
  @override String get notifSyncDetailTitle => 'Детали прогресса';
  @override String get notifSyncDetailSubtitle => 'Показывать прогресс в реальном времени (текущий год, счётчик) во время синхронизации';
  @override String get notifNewsSubtitle => 'Получайте уведомления о новых функциях, исправлениях и анонсах';
  @override String get notifBadgeOnDashboard => 'Значок на обзоре';
  @override String get notifBadgeSubtitle => 'Показывать точку непрочитанного на значке колокольчика новостей';
  @override String get notifTestLabel => 'Тест';
  @override String get notifPermissionDisabledTitle => 'Уведомления отключены';
  @override String get notifPermissionDisabledBody => 'Предоставьте разрешение, чтобы LastStats мог отправлять вам оповещения.';
  @override String get notifGrantPermission => 'Предоставить разрешение';
  @override String get notifThresholdIntro => 'Вы получите особое уведомление на каждом из этих рубежей:';
  @override String get notifIntervalDescription => 'Отправлять уведомление каждые X скробблов';
  @override String get notifCustomValueLabel => 'Своё значение';
  @override String get notifTimeNotifyAt => 'Уведомлять в';
  @override String get notifDayOfWeek => 'День недели';
  @override String get notifSendTest => 'Отправить тестовое уведомление';
  @override String get notifSentCheckBar => 'Проверьте панель уведомлений!';
  @override String get notifMakeSureWorks => 'Убедитесь, что всё работает.';
  @override String get notifSentBang => 'Отправлено!';
  @override String get notifSendButton => 'Отправить';
  @override String get apVisualStyle => 'Визуальный стиль';
  @override String get apStyleDefault => 'По умолчанию';
  @override String get apNothingAccentLabel => 'Акцент';
  @override String get apNothingClassic => 'Классический';
  @override String get apRedOnlyDesc => 'Только красный';
  @override String get apNothingMixed => 'Смешанный';
  @override String get apRedYellowDesc => 'Красный + жёлтые акценты';
  @override String get apNothingActiveBanner => 'Активен стиль Nothing OS. Акцент, динамический цвет и цвет из музыки отключены.';
  @override String get apNothingOledInherent => 'Тёмный режим Nothing уже является настоящим чёрным OLED. Переключатель OLED не нужен.';
  @override String get apOledTitle => 'Тема настоящего чёрного OLED';
  @override String get apOledBuiltIntoNothing => 'Встроено в тёмный режим Nothing';
  @override String get apOledPureBlack => 'Абсолютно чёрный фон при включённом тёмном режиме';
  @override String get apCustomColorTooltip => 'Свой цвет';
  @override String get apColorWhenNothingPlays => 'Цвет, когда ничего не играет';
  @override String get apColorWhenNothingPlaysSub => 'Акцент, используемый пока не скробблится ни один трек';
  @override String get apKeepLastArtworkTitle => 'Сохранять последний цвет обложки';
  @override String get apKeepLastArtworkSub => 'Сохранять последний цвет обложки вместо сброса, когда ничего не играет';
  @override String get apDetailPagesSection => 'Страницы деталей';
  @override String get apArtworkColorTheme => 'Тема цвета обложки';
  @override String get apBeta => 'БЕТА';
  @override String get apArtworkColorThemeSub => 'Страницы деталей подстраивают цвета под основной цвет обложки';
  @override String get apNavBarSection => 'Панель навигации';
  @override String get apShowTabLabels => 'Показывать подписи вкладок';
  @override String get apShowTabLabelsSub => 'Показывать названия вкладок под значками на нижней панели';
  @override String get apInteractionsSection => 'Взаимодействия';
  @override String get apHapticFeedbackSub => 'Вибрация при нажатиях, выборе и жестах';
  @override String get acctRemoveTitle => 'Удалить аккаунт?';
  @override String get acctRemoveAction => 'Удалить';
  @override String get acctAlreadyAddedOrFull => 'Этот аккаунт уже добавлен, или список заполнен.';
  @override String get acctLogoutAllBody => 'Все аккаунты будут удалены. Вы вернётесь на экран настройки.';
  @override String get acctActive => 'Активен';
  @override String get acctTapSwitchToActivate => 'Нажмите «Переключить», чтобы активировать';
  @override String get acctSwitch => 'Переключить';
  @override String get acctAddAnAccount => 'Добавить аккаунт';
  @override String get acctApiKeyInfo => 'Каждый аккаунт может использовать другой ключ API или тот же самый. Найти ключ API можно на last.fm/api/accounts.';
  @override String get acctLastfmProfileSection => 'Профиль Last.fm';
  @override String get acctViewOnLastfm => 'Посмотреть на Last.fm';
  @override String get acctDangerZone => 'Опасная зона';
  @override String get acctLogoutAllSub => 'Удаляет все аккаунты и возвращает на экран настройки.';
  @override String get acctUsernameRequired => 'Требуется имя пользователя.';
  @override String get acctApiKeyRequired => 'Требуется ключ API.';
  @override String get acctUsernameLabel => 'Имя пользователя Last.fm';
  @override String get acctSameApiKey => 'Тот же ключ API, что и у активного аккаунта';
  @override String get acctApiKeyLabel => 'Ключ API';
  @override String get acctAdd => 'Добавить';
  @override String get languageChangeNote => 'Язык меняется мгновенно во всём приложении.';
  @override String get dashTotalScrobblesLabel => 'Всего скробблов';
  @override String get dashMemberSinceLabel => 'Участник с';
  @override String get dashCountryLabel => 'Страна';
  @override String get dashArtistWeekLabel => 'Исполнитель №1 (неделя)';
  @override String get dashAlbumWeekLabel => 'Альбом №1 (неделя)';
  @override String get dashTrackWeekLabel => 'Трек №1 (неделя)';
  @override String get dashUniqueArtistsLabel => 'Уникальных исполнителей';
  @override String get dashUniqueTracksLabel => 'Уникальных треков';
  @override String get dashUniqueAlbumsLabel => 'Уникальных альбомов';
  @override String get dashThisWeekLabel => 'На этой неделе';
  @override String get dashDayUnitShort => 'д';
  @override String get setupEnableFavorites      => 'Включить избранное (необязательно)';
  @override String get setupFavoritesExplain     => 'Секретный ключ позволяет приложению добавлять (или убирать) треки из избранного прямо на Last.fm.';
  @override String get setupSecretKeyLabel       => 'Секретный ключ Last.fm';
  @override String get favConnectInvalidSecret   => 'Секретный ключ должен содержать 32 символа.';
  @override String get favConnectDialogTitle     => 'Авторизовать избранное';
  @override String get favConnectDialogBody      => 'Авторизуйте приложение на странице Last.fm, открытой в браузере, затем вернитесь сюда и подтвердите.';
  @override String get favConnectDialogConfirm   => 'Я авторизовал(а)';
  @override String get favConnectSuccess         => 'Избранное успешно включено!';
  @override String get favConnectError           => 'Не удалось включить избранное. Проверьте секретный ключ.';
  @override String get acctApiKeysSection        => 'Ключи API';
  @override String get acctSecretKeyLabel        => 'Секретный ключ';
  @override String get acctSecretKeyNotSet       => 'Не задан';
  @override String get acctFavoritesExplain      => 'Секретный ключ позволяет добавлять (или убирать) треки из избранного прямо на Last.fm.';
  @override String get acctConnectFavorites      => 'Включить избранное';
  @override String get acctDisconnectFavorites   => 'Отключить избранное';
  @override String get settingsFavoritesSection    => 'Избранное';
  @override String get settingsFavoritesSectionSub => 'Показывает количество избранного в статистике';
  @override String get settingsFavoritesNeedsKey   => 'Добавьте секретный ключ в разделе «Аккаунт», чтобы включить';
  @override String get favSectionTitle           => 'Избранное';
  @override String get commonSeeMore             => 'Показать больше';
  @override String get favPageTitle              => 'Мои избранные';
  @override String get favSearchHint             => 'Поиск трека или исполнителя';
  @override String get favEmpty                  => 'Пока нет избранного.';
  @override String get settingsLovedBadgeTitle => 'Скромный значок сердца';
  @override String get settingsLovedBadgeSub   => 'Показывает маленькое сердце у избранных треков в недавних, истории и поиске';
  @override String get favSortRecent   => 'Недавние';
  @override String get favSortOldest   => 'Старые';
  @override String get favSortArtistAz => 'Исполнитель А-Я';
  @override String get favSortTitleAz  => 'Название А-Я';
  @override String get favFolderSortCustom => 'Вручную';
  @override String get favFoldersAll => 'Все';
  @override String get favFolderNew => 'Новая папка';
  @override String get favFolderNamePlaceholder => 'Название папки';
  @override String get favFolderCustomEmojiTitle => 'Выберите эмодзи';
  @override String get favFolderCustomEmojiHelper => 'Только один эмодзи, без текста.';
  @override String get favFolderDescPlaceholder => 'Описание (необязательно)';
  @override String get favFolderRecentlyPlayed => 'Недавно прослушано';
  @override String get favFolderCreate => 'Создать';
  @override String get favFolderEdit => 'Изменить папку';
  @override String get favFolderDelete => 'Удалить';
  @override String get favFolderDeleteConfirm => 'Удалить эту папку? Треки больше не будут в ней распределены.';
  @override String get favFolderAssignTitle => 'Добавить в папку';
  @override String get favFolderEmoji => 'Эмодзи';
  @override String get favFolderColor => 'Цвет';
  @override String get favFolderSave => 'Сохранить';
  @override String get favFolderEmpty => 'В этой папке нет треков';
  @override String get rankingsWholeYear       => 'Весь год';
  @override String get chartsExportGeneratedOn => 'создано';
  @override String get faqQ1 => 'Скробблит ли LastStats мою музыку?';
  @override String get faqA1 => 'Нет. LastStats, это приложение для визуализации: оно показывает скробблы, уже записанные в вашем аккаунте Last.fm, но само ничего не записывает.\n\nЧтобы автоматически скробблить музыку, используйте специальное приложение, например Pano Scrobbler (доступно на Android).';
  @override String get faqQ2 => 'Планируется ли версия для iOS?';
  @override String get faqA2 => 'Нет, версия для iOS пока не планируется. Если спрос станет достаточно большим, это решение могут пересмотреть.';
  @override String get faqQ3 => 'Работает ли приложение на macOS или других платформах?';
  @override String get faqA3 => 'LastStats разрабатывается и тестируется на Android. Работа на других платформах (macOS, Windows, Linux…) не проверена, возможны ошибки или неожиданное поведение.';
  @override String get faqQ4 => 'Является ли LastStats открытым исходным кодом?';
  @override String get faqA4 => 'Да! Исходный код свободно доступен на GitHub. Проект независимый, сделан с любовью SanoBld. Не стесняйтесь вносить вклад, сообщать об ошибках или просто поставить звездочку ⭐.';
  @override String get faqQ5 => 'Где хранятся мои данные?';
  @override String get faqA5 => 'Только на вашем устройстве. У LastStats нет сервера: скробблы кэшируются локально для быстрого доступа, а данные для входа в Last.fm также хранятся локально. Ничего не отправляется никуда, кроме официального API Last.fm.';
  @override String get faqQ6 => 'Как включить избранное?';
  @override String get faqA6 => 'Откройте Настройки > Аккаунт и введите секретный ключ Last.fm (он находится рядом с API-ключом на last.fm/api/accounts), затем следуйте подсказкам на экране. После подключения вы сможете добавлять треки в избранное прямо из приложения. С встроенным ключом приложения эта функция недоступна.';
  @override String get faqQ7 => '\u0427\u0442\u043e \u0442\u0430\u043a\u043e\u0435 \u00abscrobble\u00bb?';
  @override String get faqA7 => 'Scrobble \u2014 \u044d\u0442\u043e \u0442\u0440\u0435\u043a, \u0437\u0430\u0444\u0438\u043a\u0441\u0438\u0440\u043e\u0432\u0430\u043d\u043d\u044b\u0439 \u043a\u0430\u043a \u043f\u0440\u043e\u0441\u043b\u0443\u0448\u0430\u043d\u043d\u044b\u0439 \u043d\u0430 \u0432\u0430\u0448\u0435\u043c \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0435 Last.fm \u2014 \u044d\u0442\u043e \u0441\u043e\u0431\u0441\u0442\u0432\u0435\u043d\u043d\u044b\u0439 \u0442\u0435\u0440\u043c\u0438\u043d Last.fm \u0434\u043b\u044f \u00ab\u0437\u0430\u0441\u0447\u0438\u0442\u0430\u043d\u043d\u043e\u0433\u043e \u043f\u0440\u043e\u0441\u043b\u0443\u0448\u0438\u0432\u0430\u043d\u0438\u044f\u00bb. \u0412\u0441\u0435 \u0432\u0430\u0448\u0438 \u0438\u0442\u043e\u0433\u0438 (\u0442\u043e\u043f \u0438\u0441\u043f\u043e\u043b\u043d\u0438\u0442\u0435\u043b\u0435\u0439, \u0441\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043a\u0430 \u0438 \u0442.\u0434.) \u043e\u0441\u043d\u043e\u0432\u0430\u043d\u044b \u043d\u0430 \u043d\u0451\u043c.';
  @override String get faqQ8 => '\u041a\u0430\u043a \u0440\u0430\u0431\u043e\u0442\u0430\u044e\u0442 \u0443\u0440\u043e\u0432\u043d\u0438 \u0438 \u0434\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u044f?';
  @override String get faqA8 => '\u0423\u0440\u043e\u0432\u0435\u043d\u044c \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0430 \u0440\u0430\u0441\u0442\u0451\u0442 \u0432\u043c\u0435\u0441\u0442\u0435 \u0441 \u043e\u0431\u0449\u0438\u043c \u0447\u0438\u0441\u043b\u043e\u043c scrobble (\u043c\u0430\u043a\u0441\u0438\u043c\u0430\u043b\u044c\u043d\u043e\u0433\u043e \u0443\u0440\u043e\u0432\u043d\u044f \u043d\u0435\u0442). \u041a\u0430\u0440\u0442\u043e\u0447\u043a\u0438 \u0442\u0430\u043a\u0436\u0435 \u043f\u043e\u043b\u0443\u0447\u0430\u044e\u0442 \u0440\u0430\u043c\u043a\u0443 (\u0431\u0440\u043e\u043d\u0437\u0430 \u2192 \u043f\u0435\u0440\u0435\u043b\u0438\u0432\u0447\u0430\u0442\u0430\u044f) \u0432 \u0437\u0430\u0432\u0438\u0441\u0438\u043c\u043e\u0441\u0442\u0438 \u043e\u0442 \u0447\u0438\u0441\u043b\u0430 \u043f\u0440\u043e\u0441\u043b\u0443\u0448\u0438\u0432\u0430\u043d\u0438\u0439 \u044d\u0442\u043e\u0433\u043e \u0438\u0441\u043f\u043e\u043b\u043d\u0438\u0442\u0435\u043b\u044f/\u0442\u0440\u0435\u043a\u0430/\u0430\u043b\u044c\u0431\u043e\u043c\u0430. \u0412\u0441\u0451 \u0432\u044b\u0447\u0438\u0441\u043b\u044f\u0435\u0442\u0441\u044f \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438 \u0438\u0437 \u0443\u0436\u0435 \u0437\u0430\u043a\u044d\u0448\u0438\u0440\u043e\u0432\u0430\u043d\u043d\u043e\u0439 \u043b\u043e\u043a\u0430\u043b\u044c\u043d\u043e\u0439 \u0441\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043a\u0438, \u0431\u0435\u0437 \u0434\u043e\u043f\u043e\u043b\u043d\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0445 \u0441\u0435\u0442\u0435\u0432\u044b\u0445 \u0437\u0430\u043f\u0440\u043e\u0441\u043e\u0432.';
  @override String get faqQ9 => 'Как работает режим энергосбережения?';
  @override String get faqA9 => 'Режим энергосбережения увеличивает интервалы между автосинхронизациями для экономии заряда. Его можно включить постоянно, привязать к режиму энергосбережения телефона или включать при выбранном уровне заряда: Настройки > Общие.';
  @override String get faqQ10 => 'Как сделать резервную копию или восстановить данные?';
  @override String get faqA10 => 'Откройте Настройки > Резервное копирование. Вы можете экспортировать файл резервной копии с вашим ключом Last.fm или без него, а затем импортировать его на этом телефоне или на другом устройстве, чтобы вернуть свои настройки.';
  @override String get faqQ11 => 'Работает ли приложение офлайн?';
  @override String get faqA11 => 'Да, отчасти. Уже загруженная статистика остаётся доступной офлайн благодаря локальному кешу, но для получения новых скробблов нужно подключение.';
  @override String get faqQ12 => 'Можно ли сменить аккаунт Last.fm?';
  @override String get faqA12 => 'Да, можно сохранить до 3 аккаунтов Last.fm. В разделе Настройки > Аккаунт нажмите «Добавить аккаунт» и переключайтесь между ними, когда захотите. При переключении локальный кэш автоматически сбрасывается, чтобы данные двух аккаунтов никогда не смешивались.';
  @override String get faqQ13 => 'Как настроить уведомления?';
  @override String get faqA13 => 'В разделе Настройки > Уведомления можно включить оповещение о завершении синхронизации, выбрать, как часто оно появляется, или полностью отключить уведомления.';
  @override String get faqQ14 => 'Обложки не появляются или грузятся бесконечно. Что делать?';
  @override String get faqA14 => 'Очистите кэш в приложении (Настройки > Кэш), затем в Android (Настройки > Приложения > LastStats > Хранилище > Очистить кэш). Если изображений всё ещё нет, сделайте резервную копию (Настройки > Резервная копия), удалите и переустановите приложение, затем восстановите копию.';
  @override String get settingsPlatformDisabledByShowAll => 'Отключено: все ссылки уже отображаются.';
  @override String get commonInDevelopment => 'В разработке';
  @override String get commonSeeLess => 'Свернуть';
  @override String get commonShare => 'Поделиться';
  @override String get newsCustomDate => 'Свой период';
  @override String get aboutShortcuts => 'Горячие клавиши';
  @override String get aboutShortcutsSub => 'Доступны на ПК / большом экране';
  @override String get shortcutSwitchTabs => 'Переключение вкладок';
  @override String get shortcutSearch => 'Поиск';
  @override String get shortcutClose => 'Закрыть карточку';
  @override String get shortcutRefresh => 'Обновить';
  @override String get aboutDiscord => 'Присоединиться к Discord';
  @override String get aboutDiscordSub => 'Общение, предложения и анонсы в реальном времени';

  @override String globalListeners(String count) => '$count слушателей во всём мире';
  @override String historyScrobbles(int n) => '$n скробблов';
  @override String historyArtistsCount(int n) => '$n исполнителей';
  @override String historyAlbumsCount(int n) => '$n альбомов';
  @override List<String> get months => const ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
  @override String dayLabel(DateTime d) {
    const days = ['понедельник','вторник','среда','четверг','пятница','суббота','воскресенье'];
    const months = ['','января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
    return '${d.day} ${months[d.month]} ${d.year}, ${days[d.weekday - 1]}';
  }
  @override String memberSince(String date) => 'Участник с $date';
  @override String settingsUpdateAvailable(String v) => 'Доступна v$v';
  @override String settingsUpdateBanner(String v) => 'Обновление v$v';
  @override String setupWelcome(String username) => 'Добро пожаловать, $username!';
  @override String setupScrobblesToImport(String c) => '$c скробблов для импорта';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      '${isBeta ? "Бета-" : "Новое "}обновление: v$version';
  @override String newsItemsCount(int n) => '$n ${n > 1 ? "записей" : "запись"}';
  @override String syncFrequencyHours(int h) => 'Каждые $h ч';
  @override String syncNewScrobblesFound(int n) => n == 0 ? 'Новых скробблов нет' : 'Найдено новых скробблов: $n';
  @override String updatesPublishedOn(String date) => 'Опубликовано $date';
  @override String fallbackWillShow(String detail) => 'Будет показано: $detail';
  @override String acctRemoveBody(String username) => 'Удалить @$username из ваших аккаунтов?';
  @override String acctAddedSuccess(String username) => '@$username успешно добавлен.';
  @override String acctMyAccounts(int count, int max) => 'Мои аккаунты ($count/$max)';
  @override String acctSlotsRemaining(int n) => 'Осталось мест: $n';
  @override String acctMaxReached(int max) => 'Достигнут максимум в $max аккаунтов.';
  @override List<String> get weekdaysShort => const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  @override List<String> get weekdaysNarrow => const ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];
  @override String get weekAbbrev => 'Н';
  @override List<String> get notifThresholdMessages => const [
    'Ваши первые 1000 скробблов. Путешествие начинается. 🎵',
    'Вы достигли пятизначного числа! 🎉',
    'Вы настоящий музыкальный фанат. 🔥',
    'Миллион скробблов. Это легендарно. 🎸',
  ];
  @override String get achvTitle => 'Достижения';
  @override String achvUnlocked(int unlocked, int total) => '$unlocked / $total разблокировано';
  @override String get achvCatListening => 'Прослушивание';
  @override String get achvCatArtists => 'Артисты';
  @override String get achvCatAlbums => 'Альбомы';
  @override String get achvCatLoyalty => 'Верность';
  @override String get achvDescListening => 'Всего прослушанных треков (скроббл), по всем исполнителям.';
  @override String get achvDescArtists => 'Количество разных исполнителей, прослушанных хотя бы раз.';
  @override String get achvDescAlbums => 'Количество разных альбомов, прослушанных хотя бы раз.';
  @override String get achvDescLoyalty => 'Как давно существует аккаунт Last.fm.';
  @override String get achvCatTracks => 'Треки';
  @override String get achvDescTracks => 'Количество разных прослушанных треков.';
  @override String get achvCatPace => 'Темп';
  @override String get achvDescPace => 'Среднее число скробблов в неделю.';
  @override String get achvCatStreak => 'Серия';
  @override String get achvDescStreak => 'Самая длинная серия дней подряд хотя бы с одним прослушиванием.';
  @override String get achvCatMarathon => 'Марафон';
  @override String get achvDescMarathon => 'Наибольшее число прослушиваний за один день.';
  @override String get achvCatSocial => 'Общение';
  @override String get achvDescSocial => 'Количество добавленных друзей или профилей.';
  @override String get achvCatComparisons => 'Сравнения';
  @override String get achvDescComparisons => 'Количество выполненных сравнений музыкальных вкусов.';
  @override String get achvUnlockedBadge => 'Открыто';
  @override String get achvLockedBadge => 'Заблокировано';
  @override String get dashRecap => 'Итоги';
  @override String get recapDay => 'Сегодня';
  @override String get recapWeek => 'На этой неделе';
  @override String get recapMonth => 'В этом месяце';
  @override String get recapScrobbles => 'скробблов';
  @override String get recapArtists => 'Исполнители';
  @override String get recapTracks => 'Треки';
  @override String get recapTopArtist => 'Топ исполнитель';
  @override String get recapTopTrack => 'Топ трек';
  @override String get recapTopAlbum => 'Топ альбом';
  @override String get recapAvgDay => 'Ср/день';
  @override String get recapNoData => 'За этот период прослушиваний нет.';
  @override String get recapSeeFull => 'Смотреть полные итоги';
  @override String get recapTop10 => 'Топ 10';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => 'Сначала самый полезный фильтр';
  @override String get discoverSmartSub => 'С учётом времени, дня и того, чем вы пользуетесь чаще всего';
  @override String get discoverForYou => 'Для вас';
  @override String get discoverGlobalTrends => 'Мировые тренды';
  @override String get discoverSrcForyou => 'Ваш микс';
  @override String get discoverSrcOnthisday => 'В этот день';
  @override String get discoverSrcFresh => 'В этом месяце';
  @override String get discoverSrcGenre => 'Ваши жанры';
  @override String get discoverSrcDeeper => 'Скрытые жемчужины';
  @override String get discoverSrcForgotten => 'Забытые';
  @override String get discoverSrcAlbums => 'Альбомы';
  @override String get discoverSrcCountry => 'Ваша страна';
  @override String get discoverTracks => 'Треки';
  @override String get discoverArtists => 'Исполнители';
  @override String get discoverWeek => 'неделя';
  @override String get discoverMonth => 'месяц';
  @override String get discoverYear => 'год';
  @override String get discoverNothing => 'Пока ничего нет';
  @override String discoverLike(String names) => 'Как $names';
  @override String get dashReorderSections => 'Изменить порядок разделов';
  @override String get dashInfiniteTitle => 'Бесконечная прокрутка';
  @override String get dashInfiniteSub => '«Открытия» идут по кругу и предлагают всё новое';
  @override String get dashDiscoverTitle => 'Открытия';
  @override String get dashDiscoverSub => 'Музыкальные идеи, которые можно листать';
  @override String get dashSortButton => 'Сортировка';
  @override String get dashSortDone => 'Готово';
  @override String get dashSortHint => 'Перетащите, чтобы изменить порядок';
  @override String get dashSortSmartNote => 'Умная сортировка включена, поэтому порядок может меняться в зависимости от момента.';
  @override String get dashSeparateRow => 'Отдельной строкой';
  @override String dashFiltersOf(String group) => 'Фильтры раздела «$group»';
  @override String get apShapeSingle => 'Только одна форма';
  @override String get mvSource => 'Источник видео';
  @override String get mvSrcAuto => 'Авто (сначала Apple Music, затем YouTube)';
  @override String get mvSrcApple => 'Только Apple Music';
  @override String get mvSrcYt => 'Только YouTube (треки)';
  @override String get mvQualityT => 'Качество видео';
  @override String get mvQAuto => 'Авто';
  @override String get mvQLow => 'Экономия (360p)';
  @override String get mvTypesT => 'Показывать видео для';
  @override String get mvTracks => 'Треки';
  @override String get mvAlbums => 'Альбомы';
  @override String get mvArtists => 'Исполнители';
  @override String get mvModeT => 'Режим';
  @override String get mvModeBest => 'Рекомендуется';
  @override String get mvModeSaver => 'Экономия';
  @override String get mvModeMax => 'Макс. качество';
  @override String get mvModeCustom => 'Свой';
  @override String get mvSrcYtFirst => 'Сначала YouTube, затем Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => 'Используемые сервисы, квоты и расход';
  @override String get apiSumToday => 'Запросов сегодня';
  @override String get apiSumErrors => 'Ошибки';
  @override String get apiSumLimited => 'Ограничено';
  @override String get apiIntro => 'Счётчики относятся только к этому устройству. Провайдеры применяют лимиты по IP-адресу, поэтому другие приложения в той же сети тоже учитываются. Приложение автоматически замедляет или пропускает запросы, чтобы не превышать лимиты.';
  @override String get apiCatListening => 'Данные прослушиваний';
  @override String get apiCatMetadata => 'Метаданные музыки';
  @override String get apiCatArtwork => 'Обложки';
  @override String get apiCatLyrics => 'Тексты песен';
  @override String get apiCatTranslate => 'Перевод';
  @override String get apiCatUpdates => 'Обновления и новости';
  @override String get apiCatOther => 'Загрузка изображений';
  @override String get apiStatusIdle => 'Ещё не использовалось';
  @override String get apiStatusOk => 'OK';
  @override String get apiStatusNear => 'Близко к лимиту';
  @override String get apiStatusPaused => 'Пауза';
  @override String get apiProviderLimit => 'Лимит провайдера';
  @override String get apiNoLimit => 'Не опубликован';
  @override String get apiAppCeiling => 'Потолок приложения';
  @override String apiLimitPer(int n, String win) => '$n запросов / $win';
  @override String get apiWinSecond => 'секунда';
  @override String get apiWinMinute => 'минута';
  @override String get apiWinHour => 'час';
  @override String apiWinSeconds(int s) => '$s сек.';
  @override String get apiWindowUsage => 'Текущее окно';
  @override String get apiRemaining => 'Осталось';
  @override String apiResetsIn(String t) => 'Сброс через $t';
  @override String apiPausedFor(String t) => 'Пауза на $t после ответа о превышении лимита';
  @override String get apiToday => 'Сегодня';
  @override String get apiLastHour => 'За последний час';
  @override String get apiTotal => 'Всего';
  @override String get apiRateLimited => 'Ответы о превышении лимита';
  @override String get apiSkipped => 'Пропущено приложением';
  @override String get apiLastCall => 'Последний вызов';
  @override String get apiNever => 'Никогда';
  @override String get apiNoKey => 'API-ключ не нужен';
  @override String get apiSharedKey => 'Общий публичный тестовый ключ (бесплатный тариф)';
  @override String get apiUnofficial => 'Неофициальная точка доступа: квота не гарантирована, может измениться или быть заблокирована без предупреждения.';
  @override String get apiKeyInUse => 'Используемый ключ';
  @override String get apiOwnKey => 'Ваш собственный ключ Last.fm';
  @override String apiBuiltinKey(int n, int total) => 'Встроенный ключ $n из $total';
  @override String get apiBackupOn => 'Резервный ключ: вкл.';
  @override String get apiBackupOff => 'Резервный ключ: выкл.';
  @override String get apiPerKey => 'Запросов на ключ (сегодня / всего)';
  @override String get apiLastfmNote => 'Last.fm не публикует цифр: при слишком частых запросах с IP он возвращает ошибку 29, а условия запрещают обход. Обычно ориентир — около 5 запросов в секунду на IP; приложение держится ниже 4.';
  @override String get apiStorageTitle => 'Сохранённые данные Last.fm';
  @override String apiStorageValue(String used, String cap) => '$used из $cap разрешённых';
  @override String get apiStorageOver => 'Превышен лимит 100 МБ из условий API Last.fm. Очистите историю скробблов в разделе «Хранилище».';
  @override String get apiReset => 'Сбросить счётчики';
  @override String get apiLimiter => 'Ограничивать запросы';
  @override String get apiLimiterSub => 'Замедляет запросы, чтобы не превышать лимиты API. Выкл. = быстрее, без ожидания.';
  @override String get apiResetBody => 'Все счётчики запросов будут обнулены.';
  @override String get apiResetDone => 'Счётчики сброшены';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (ru) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxRu = {
  'st_notif_on': 'Уведомления включены',
  'st_notif_off': 'Уведомления выключены',
  'st_notif_count': 'Включено типов: {n}',
  'st_notif_perm': 'Нужно разрешение системы',
  'st_notif_none': 'Ни один тип уведомлений не выбран',
  'st_sync_on': 'Автосинхронизация включена',
  'st_sync_off': 'Автосинхронизация выключена',
  'st_sync_on_s': 'Данные обновляются сами.',
  'st_sync_off_s': 'Данные обновляются только по запросу.',
  'st_bkp_on': 'Автоматическое резервное копирование включено',
  'st_bkp_off': 'Автоматическое резервное копирование выключено',
  'st_bkp_on_s': 'Настройки сохраняются автоматически.',
  'st_bkp_off_s': 'Включите, чтобы не потерять настройки.',
  'st_bkp_next': 'Следующее копирование: {d}',
  'cmp_breakdown': 'Что вас объединяет',
  'cmp_by_artists': 'Исполнители',
  'cmp_by_genres': 'Жанры',
  'cmp_by_tracks': 'Треки',
  'cmp_by_albums': 'Альбомы',
  'eco_on': 'Энергосбережение включено',
  'eco_off': 'Энергосбережение выключено',
  'eco_why_manual': 'Всегда включено, по вашему выбору',
  'eco_why_system': 'Режим экономии заряда на устройстве включён',
  'eco_why_battery': 'Заряд батареи: {n}%',
  'eco_off_hint': 'Выберите ниже, когда включать',
  'eco_trig': 'Когда включать',
  'eco_sys_t': 'Когда на устройстве включён режим экономии заряда',
  'eco_sys_s': 'Следует встроенному режиму энергосбережения телефона и выключается вместе с ним.',
  'eco_sys_na': 'Недоступно на этом устройстве.',
  'eco_chg': 'Что меняется',
  'eco_chg1': 'Параллакс при наклоне отключается',
  'eco_chg2': 'Частота обновления экрана ограничивается примерно 60 Гц',
  'eco_chg3': 'Фоновые обновления выполняются реже',
  'eco_chg4': 'Анимированные обложки и блеск значков приостанавливаются',
  'eco_chg_note': 'Всё остальное остаётся в полном качестве: изображения, экспорт и карточки для обмена.',
  'lib_section': 'Библиотека',
  'lib_merge_t': 'Объединять версии одного трека',
  'lib_merge_s': 'Ремастеры, синглы, (feat. …) и делюкс-издания считаются одним треком или альбомом, прослушивания суммируются. Ремиксы, концертные и инструментальные версии остаются отдельно.',
  'lib_split_t': 'Разделять коллаборации',
  'lib_split_s': '«Gims & Damso» засчитывается и Gims, и Damso, а не как отдельный артист. Группы вроде «Simon & Garfunkel» остаются целыми.',
  'lib_step_t': 'Ваша библиотека',
  'lib_step_s': 'Выберите, как группировать прослушивания. Это можно изменить в любой момент в настройках.',
  'bk_dash_t': 'Дашборд и запуск',
  'bk_dash_s': 'Разделы, шапка, карточки статистики, обзор, стартовая вкладка',
  'bk_notif_t': 'Уведомления',
  'bk_notif_s': 'Итоги, вехи, новости и значки',
  'bk_lib_t': 'Настройки библиотеки',
  'bk_lib_s': 'Объединение версий, разделение коллабораций',
  'bk_prof_t': 'Избранные профили',
  'bk_prof_s': 'Профили Last.fm, добавленные в избранное',
  'about_readme_t': 'README и активность проекта',
  'about_readme_s': 'README, последние коммиты, workflow, версия, загрузки',
  'fold_show': 'Показать ({n})',
  'fold_hide': 'Свернуть',
  'readme_sub': 'Проект и его активность',
  'readme_version': 'Версия',
  'readme_downloads': 'Загрузки',
  'readme_stars': 'Звёзды',
  'readme_license': 'Лицензия',
  'readme_commits': 'Последние коммиты',
  'readme_workflows': 'Последние workflow',
  'readme_retry': 'Повторить',
  'readme_github': 'Открыть на GitHub',
  'readme_failed': 'Не удалось загрузить (нет сети или лимит GitHub).',
  'ago_min': '{n} мин назад',
  'ago_h': '{n} ч назад',
  'ago_d': '{n} дн. назад',
  'load_restored': 'Восстановлено скробблов: {n}',
  'load_ready': 'Готово к импорту',
  'load_connecting': 'Подключение к Last.fm…',
  'load_done': 'Импорт завершён',
  'load_backup_note': 'Найдена резервная копия: проверяются только новые скробблы.',
  'dash_nowplay': 'Сейчас играет',
  'dash_stats': 'Статистика',
  'dash_recent': 'Недавние прослушивания',
  'dash_discover': 'Обзор',
  'dash_friends': 'Друзья',
  'dash_chart': 'График дашборда',
  'dash_calendar': 'Календарь',
  'dash_monthly': 'По месяцам',
  'cache_video_t': 'Анимированные обложки (Apple Music)',
  'cache_video_s': 'Видеопамять: {mem} · активных плееров: {players} · ссылок в кэше: {links}',
  'cache_video_short': 'Анимации',
  'cache_video_cleared': 'Видеопамять освобождена',
  'cache_memory_section': 'Память',
  'cache_storage_section': 'Хранилище',
  'lvl': 'Уровень {n}',
  'lvl_history': 'История уровней',
  'set_living_t': 'Живые обложки',
  'set_living_s': 'Плавный зум и эффект глубины на изображениях',
  'set_motion_t': 'Видеообложки',
  'set_motion_s': 'Воспроизводит анимированную обложку, если она есть',
  'set_achv_t': 'Достижения и уровни',
  'set_achv_s': 'Ранги, значки и уровень аккаунта',
  'cache_img_limit_t': 'Лимит кэша фото',
  'cache_img_limit_s': 'Обложки, фото артистов и аватары. Сначала удаляются самые старые.',
  'cache_vid_limit_t': 'Лимит кэша видео',
  'cache_vid_limit_s': 'Анимированные обложки Apple Music хранятся на диске для просмотра офлайн (Android).',
  'cache_video_off': 'Выкл.',
  'cache_vid_disk_t': 'Видео Apple Music',
  'cache_vid_disk_s': '{size} · Сохранённые анимированные обложки',
  'cache_no_limit_note': 'Скробблы и данные API никогда не ограничиваются.',
  'key_internal_use': 'Использовать встроенный ключ приложения',
  'key_internal_help': 'Резервный вариант: этот ключ общий для пользователей. Он может исчерпать лимиты или перестать работать, и часть функций тогда не заработает. По возможности используйте свой ключ.',
  'key_internal_active': 'Встроенный ключ приложения',
  'key_fallback_title': 'Встроенный ключ как резерв',
  'key_fallback_sub': 'Сначала используется ваш ключ. Если Last.fm его отклонит, приложение автоматически повторит запрос со встроенным ключом.',
  'key_use_own': 'Использовать мой собственный API-ключ',
  'key_change_title': 'Сменить API-ключ',
  'key_change_sub': 'Замените свой ключ другим или перейдите на встроенный ключ приложения.',
  'key_change_sub_internal': 'Сейчас используется общий ключ приложения. Добавьте свой ключ, чтобы не зависеть от лимитов других пользователей.',
  'key_change_intro': 'Введите новый API-ключ для этого аккаунта или вернитесь к встроенному ключу приложения. Ваше имя пользователя и статистика не изменятся.',
  'key_change_intro_internal': 'Этот аккаунт сейчас использует встроенный ключ приложения. Вставьте ниже свой API-ключ Last.fm, чтобы заменить его. Ваше имя пользователя и статистика не изменятся.',
  'key_change_hint': 'API-ключ состоит из 32 символов. Создать его или найти свой можно на last.fm/api/accounts.',
  'key_change_invalid_len': 'API-ключ должен состоять ровно из 32 символов. Убедитесь, что вы скопировали его целиком.',
  'key_change_same': 'Этот аккаунт уже использует этот ключ. Введите другой.',
  'key_change_check_failed': 'Last.fm не принял этот ключ. Проверьте, что он указан верно и что есть подключение к интернету, и повторите попытку.',
  'key_change_favorites_warn': 'Подключение к избранному будет отключено, так как оно привязано к старому ключу. Позже вы сможете подключить его снова с помощью своего секретного ключа.',
  'key_change_apply': 'Применить',
  'key_change_success': 'API-ключ обновлён.',
  'key_internal_fav_note': 'Для избранного нужны ваш собственный API-ключ и секретный ключ Last.fm. Добавьте свой ключ выше, чтобы включить избранное.',
  'faq_q15': 'Можно ли сменить API-ключ после входа?',
  'faq_a15': 'Да. Откройте Настройки > Аккаунт и нажмите «Сменить API-ключ». Вы можете заменить свой ключ другим или добавить собственный, если вначале выбрали встроенный ключ. Статистика останется прежней, нужно будет только заново подключить избранное.',
  'ui_play_preview': 'Воспроизвести фрагмент',
  'ntf_test_title': '🔔 Тестовое уведомление',
  'ntf_test_body': 'Уведомления LastStats работают!',
  'ui_not_enough_data_yet_sy': 'Пока недостаточно данных — синхронизируйте всю историю в настройках.',
  'ui_level': 'Уровень {level}',
  'ui_fetching': 'Загрузка {currentYea}… ({yearIndex}/{totalYears})',
  'ui_which_chart': 'Какой график?',
  'ui_which_period': 'Какой период?',
  'ui_all_time': 'За всё время',
  'ui_exporting': 'Экспорт…',
  'ui_chart_not_available_fo': 'График недоступен за этот период',
  'ui_could_not_generate_the': 'Не удалось создать изображение',
  'ui_error': 'Ошибка',
  'ui_loading_history': 'Загрузка истории{yearLabel}… {pct}%',
  'ui_charts_will_be_more_ac': 'После загрузки графики станут точнее.',
  'ui_load_the_full_history_': 'Загрузите полную историю, чтобы увидеть все годы.',
  'ui_load': 'Загрузить',
  'ui_based_on_scrobbles_all': 'На основе {v_hourlyCou} скробблов (все годы)',
  'ui_all_available_years': 'Все доступные годы',
  'ui_based_on_scrobbles_fro': 'На основе {v_hourlyCou} скробблов за {v_selectedY}',
  'ui_based_on_recent_scrobb': 'На основе {v_hourlyCou} последних скробблов',
  'ui_analysing_your_last_20': 'Анализ последних ~200 скробблов',
  'ui_all_time_loading': 'За всё время (данные {v_selectedY} загружаются)',
  'ui_all_time_2': 'За всё время',
  'ui_export_a_chart': 'Экспорт графика',
  'ui_scrobble_progression': 'Динамика скробблов',
  'ui_your_musical_genres': 'Ваши музыкальные жанры',
  'ui_based_on_your_top_arti': 'На основе ваших топ-артистов (за всё время)',
  'ui_listening_habits': 'Привычки прослушивания',
  'ui_album_distribution': 'Распределение по альбомам',
  'ui_listening_calendar': 'Музыкальный календарь',
  'ui_daily_activity_to': 'Активность по дням — {first} – {last}',
  'ui_daily_activity_all_yea': 'Активность по дням — все годы',
  'ui_daily_activity': 'Активность по дням — {v_selectedY}',
  'ui_load_history_to_see': 'Загрузите историю, чтобы увидеть {v_selectedY}',
  'ui_daily_activity_last_12': 'Активность по дням — последние 12 месяцев',
  'ui_all_years': 'все годы',
  'ui_listening_streaks': 'Серии прослушиваний',
  'ui_total': 'Всего',
  'ui_avg_mo': 'В среднем/мес.',
  'ui_best_month': 'Лучший месяц',
  'ui_hourly_distribution': 'Распределение по часам',
  'ui_activity_by_day_of_wee': 'Активность по дням недели',
  'ui_current_streak': 'Текущая серия',
  'ui_d': 'д',
  'ui_best_streak': 'Лучшая серия',
  'ui_best_streak_started_on': 'Лучшая серия с {bestStart}',
  'ui_no_data_for_this_perio': 'Нет данных за этот период',
  'ui_load_history_to_displa': 'Загрузите историю, чтобы показать {what}',
  'ui_less': 'Меньше',
  'ui_more': 'Больше',
  'ui_scan_a_profile': 'Сканировать профиль',
  'ui_lvl': 'Ур. {level}',
  'ui_qr_code': 'QR-код?',
  'ui_add_a_qr_code_to_the_s': 'Добавить QR-код на отправляемое изображение, чтобы любой мог отсканировать ваш профиль?',
  'ui_no_qr': 'Без QR',
  'ui_to_the_app': 'В приложение',
  'ui_to_last_fm': 'На Last.fm',
  'ui_compare_music_taste': 'Сравнить музыкальные вкусы',
  'ui_syncing_full_library': 'Синхронизация данных…',
  'ui_see_more': 'Показать ещё',
  'ui_no_achievements_unlock': 'Пока нет открытых достижений',
  'ui_no_animated_cover_for_': 'У этого альбома нет анимированной обложки',
  'ui_source': 'Источник: {source}',
  'ui_view_on_last_fm': 'Смотреть на Last.fm',
  'ui_original_text_last_fm_': 'Исходный текст: Last.fm — Перевод: Google Translate',
  'ui_source_last_fm': 'Источник: Last.fm',
  'ui_dark': 'Тёмная',
  'ui_light': 'Светлая',
  'ui_system': 'Системная',
  'ui_colored_widgets': 'Цветные виджеты',
  'ui_tint_home_screen_widge': 'Окрашивает виджеты акцентным цветом',
  'ui_search_settings': 'Поиск настройки…',
  'ui_no_settings_found': 'Настройки не найдены',
  'ui_all': 'Все',
  'ui_battery_saver': 'Экономия заряда',
  'ui_save_battery_fewer_eff': 'Экономия заряда, меньше эффектов',
  'ui_musical_soulmates': 'Музыкальные родственные души',
  'ui_great_compatibility': 'Отличная совместимость',
  'ui_some_common_ground': 'Есть кое-что общее',
  'ui_fairly_different_taste': 'Вкусы довольно разные',
  'ui_worlds_apart_musically': 'Противоположные музыкальные миры',
  'ui_this_is_your_own_profi': 'Это ваш собственный профиль!',
  'ui_artists_from_your_hist': '{uniqueArti} артистов из вашей истории · вся библиотека {targetUser}',
  'ui_artists_from_your_hist_2': '{uniqueArti} артистов из вашей истории · топ-200 {targetUser}',
  'ui_full_library_api': 'Вся библиотека (API)',
  'ui_top_200_artists_tracks': 'Топ-200 артистов и треков (API)',
  'ui_could_not_work_out_the': 'Не удалось рассчитать совместимость.',
  'ui_music_compatibility': 'Музыкальная совместимость',
  'ui_analyzing_musical_tast': 'Анализ музыкальных вкусов…',
  'ui_artist': 'Артистов: {v_totalArti}',
  'ui_track': 'Треков: {v_totalTrac}',
  'ui_album': 'Альбомов: {v_totalAlbu}',
  'ui_shared_tracks': 'Общие треки',
  'ui_shared_artists': 'Общие артисты',
  'ui_no_shared_artists_foun': 'Общих артистов не найдено.',
  'ui_shared_albums': 'Общие альбомы',
  'ui_play_count_unavailable': 'Число прослушиваний недоступно для одного из вас.',
  'ui_you_listen_to_this_x_m': 'Вы слушаете это в {x} раз чаще, чем {theirUsern}.',
  'ui_listens_to_this_x_more': '{theirUsern} слушает это в {x} раз чаще, чем вы.',
  'ui_you_both_listen_to_thi': 'Вы слушаете это примерно одинаково.',
  'ui_plays': '{plays} прослушиваний',
  'ui_compatibility': 'совместимость',
  'ui_you_both_love': 'ВЫ ОБА ЛЮБИТЕ',
  'ui_shared_top_artist': 'ОБЩИЙ ЛЮБИМЫЙ АРТИСТ',
  'ui_achievements': 'Достижения',
  'ui_qr_not_recognized_not_': 'QR-код не распознан — это не профиль LastStats/Last.fm',
  'ui_scan_a_profile_s_qr_co': 'Отсканируйте QR-код профиля',
  'ui_favorites': 'Избранное',
  'ui_advanced_youtube_music': 'Продвинутый клиент YouTube Music.',
  'ui_syncs_the_glyphs_of_no': 'Синхронизирует Glyph телефонов Nothing с музыкой.',
  'ui_sources': 'Источники',
  'ui_official_flutter_docs_': 'Официальная документация Flutter.',
  'ui_official_material_3_gu': 'Официальное руководство Material 3 для Flutter.',
  'ui_flutter_api_reference_': 'Справочник API Flutter для темы Material 3.',
  'ui_official_flutter_packa': 'Официальный пакет Flutter для адаптивных макетов.',
  'ui_android_widgets': 'Виджеты Android',
  'ui_applies_the_accent_col': 'Применяет акцентный цвет к фону виджетов на главном экране. Выкл: чисто белый или чёрный.',
  'ui_turns_off_tilt_paralla': 'Отключает параллакс при наклоне, ограничивает частоту обновления экрана и замедляет фоновые обновления — всё остальное остаётся в полном качестве (изображения, экспорт, карточки для обмена).',
  'ui_always_on': 'Всегда включено',
  'ui_force_eco_mode_on_rega': 'Принудительно включает режим экономии при любом уровне заряда.',
  'ui_auto_activate': 'Автовключение',
  'ui_turn_on_below_a_batter': 'Включать ниже заданного % заряда',
  'ui_switches_on_by_itself_': 'Включается сама, когда заряд опускается до уровня ниже.',
  'ui_threshold': 'Порог',
  'ui_choose_the_tab_display': 'Выберите вкладку, которая открывается при запуске приложения.',
  'ui_the_selected_tab_will_': 'Выбранная вкладка появится при следующем запуске приложения.',
  'ui_friends_sync': 'Синхронизация друзей',
  'ui_sync_frequency': 'Частота синхронизации',
  'ui_daily': 'Каждый день',
  'ui_resync_everyone': 'Синхронизировать всех заново',
  'ui_version_history': 'История версий',
  'ui_could_not_load_release': 'Не удалось загрузить историю.',
  'ui_installed_dev_build_un': 'Установлена: dev-сборка (версия неизвестна)',
  'ui_installed': 'Установлена: {displayVer}',
  'ui_search_a_version_or_ch': 'Поиск версии или списка изменений…',
  'ui_official': 'Официальные',
  'ui_no_release_matches_you': 'Нет версий, соответствующих поиску.',
  'ui_latest': 'ПОСЛЕДНЯЯ',
  'ui_installed_2': 'УСТАНОВЛЕНА',
  'ui_no_description': 'Нет описания.',
  'ui_download': 'Скачать',
  'ui_view_release': 'Открыть релиз',
  'ui_details': 'Подробнее',
  'ui_all_past_releases_chan': 'Все прошлые версии, списки изменений и загрузки',
  'ui_please_fill_both_field': 'Заполните оба поля.',
  'ui_api_key_must_be_32_cha': 'Ключ API должен содержать 32 символа.',
  'ui_profile_not_found': 'Профиль не найден.',
  'ui_chart_monthly': 'Столбцы по месяцам',
  'ui_chart_cumul': 'Динамика',
  'ui_chart_genres': 'Музыкальные жанры',
  'ui_chart_habits': 'Привычки прослушивания',
  'ui_chart_artists': 'Распределение артистов',
  'ui_chart_albums': 'Распределение альбомов',
  'ui_chart_calendar': 'Календарь прослушиваний',
  'ui_chart_streaks': 'Серии прослушиваний',
  'ui_band_night': 'Ночь',
  'ui_band_morning': 'Утро',
  'ui_band_afternoon': 'День',
  'ui_band_evening': 'Вечер',
  'qs_t1_t': 'Режим OLED',
  'qs_t1_s': 'Чисто чёрный фон',
  'qs_t2_t': 'Режим энергосбережения',
  'qs_t2_s': 'Снижает расход батареи',
  'qs_t3_t': 'Уведомления о новостях',
  'qs_t3_s': 'Оповещения о новостях Last.fm',
  'qs_t4_t': 'Тактильная отдача',
  'qs_t4_s': 'Вибрация при взаимодействии',
  'qs_t5_t': 'Достижения',
  'qs_t5_s': 'Показывает открытые достижения',
  'qs_l1_t': 'Акцентный цвет',
  'qs_l2_t': 'Тема',
  'qs_l3_t': 'Язык',
  'qs_l4_t': 'Музыкальная платформа',
  'qs_l5_t': 'Аккаунт',
  'qs_l6_t': 'Синхронизация',
  'qs_l7_t': 'Кэш',
  'img_src_lastfm': 'Источник: Last.fm',
  'img_src_ytmusic': 'Источник: YouTube Music',
  'img_src_itunes': 'Источник: iTunes',
  'img_src_deezer': 'Источник: Deezer',
  'img_src_audiodb': 'Источник: TheAudioDB',
  'img_src_musicbrainz': 'Источник: MusicBrainz',
  'img_src_wikipedia': 'Источник: Википедия',
  'ds_type_artist': 'Исполнитель',
  'ds_type_album': 'Альбом',
  'ds_type_track': 'Трек',
  'pf_1': '👤 Профиль пользователя',
  'pf_2': '🎤 Топ исполнителей — всё время',
  'pf_3': '💿 Топ альбомов — всё время',
  'pf_4': '🎵 Топ треков — всё время',
  'pf_5': '⏱️ Недавние прослушивания',
  'pf_6': '🗓️ Эта неделя',
  'pf_7': '📅 Этот месяц',
  'pf_8': '📅 Последние 3 месяца',
  'pf_9': '📅 Последние 6 месяцев',
  'pf_10': '📅 Последние 12 месяцев',
  'pf_11': '📊 История по месяцам',
  'pf_12': '❤️ Любимые треки',
  'pf_13': '🗓️ Топ исполнителей — неделя',
  'pf_14': '🗓️ Альбомы и треки — неделя',
  'ds_tier_next': '{n} / {next} до следующего уровня',
  'ds_tier_max': 'Максимальный уровень достигнут 🎉',
  'ds_tier_first': 'Слушайте этот трек, чтобы открыть первый уровень (от {n} прослушиваний).',
  'sl_import': 'Импорт ваших данных',
  'sl_done': 'Импортировано!',
  'sl_connect': 'Подключение к Last.fm…',
  'sec_chart': 'График / календарь',
  'stat_avg_day': 'В среднем / день',
  'stat_avg_week': 'В среднем / неделя',
  'stat_days_active': 'Активные дни',
  'stat_scrobbles_week': 'Скробблы (неделя)',
  'accent_purple': 'Фиолетовый',
  'accent_blue': 'Синий',
  'accent_green': 'Зелёный',
  'accent_red': 'Красный',
  'accent_orange': 'Оранжевый',
  'accent_pink': 'Розовый',
  'accent_teal': 'Бирюзовый',
  'accent_neutral': 'Нейтральный',
  'shape_title': 'Форма изображений',
  'shape_covers': 'Обложки, исполнители и альбомы',
  'shape_mix': 'Микс',
  'shape_square': 'Квадрат',
  'shape_circle': 'Круг',
  'shape_pick_one': 'Или выберите одну форму',
  'friend_listening': 'Слушает',
  'friend_offline': 'Не в сети',
  'tier_none': 'Нет уровня',
  'src_title': 'Источники',
  'src_scrobbles_meta': 'Скробблы и метаданные',
  'src_artwork': 'Обложка',
  'src_audio_preview': 'Аудиоотрывок',
  'src_video_artwork': 'Видеообложка',
  'tip_love': 'Добавить в избранное',
  'rail_expand': 'Развернуть боковую панель',
  'rail_collapse': 'Свернуть боковую панель',
  'a11y_loading': 'Загрузка',
  'bk_pick_folder': 'Выберите папку автоматической копии',
  'bk_save_title': 'Сохранить резервную копию LastStats',
  'bk_pick_file': 'Выберите файл резервной копии LastStats',
  'nch_milestone_d': 'Уведомляет, когда вы достигаете вехи скробблов',
  'nch_grand_d': 'Особые уведомления о крупных вехах (1K, 10K, 100K, 1M…)',
  'nch_recap_d': 'Ежедневные и еженедельные итоги прослушивания',
  'nch_update_d': 'Уведомляет о выходе новой версии LastStats',
  'nch_news_d': 'Новые функции, исправления и объявления о LastStats',
  'nch_sync_d': 'Ход синхронизации всей истории скробблов',
  'ntf_grand_1000000': 'Миллион скробблов. Это легендарно. 🎸',
  'ntf_grand_500000': 'Полмиллиона скробблов. Вы не останавливаетесь. 🎧',
  'ntf_grand_250000': '{n} скробблов — музыка не кончается. 🎶',
  'ntf_grand_100000': '{n} скробблов! Вы настоящий меломан. 🔥',
  'ntf_grand_50000': '{n} скробблов. Действительно впечатляет. 🎵',
  'ntf_grand_25000': '{n} скробблов, и вы всё ещё в ударе!',
  'ntf_grand_10000': '{n} скробблов — вы достигли пятизначного числа! 🎉',
  'ntf_grand_5000': '{n} скробблов, и счёт продолжается!',
  'ntf_grand_1000': 'Ваши первые {n} скробблов. Путешествие начинается. 🎵',
  'ntf_update_title': 'LastStats {v} доступна',
  'ntf_update_body': 'Новая версия готова к загрузке.',
  'ntf_milestone_title': '🎵 Веха: {n} скробблов',
  'ntf_milestone_body': 'Вы только что достигли {n} скробблов на Last.fm 🎶',
  'ntf_daily_title': '📊 Итоги дня · {d}',
  'ntf_weekly_title': '📅 Итоги недели · {w}',
  'ntf_recap_body': '{n} скробблов · Топ: {a}',
  'ntf_n_today': '{n} скробблов сегодня',
  'ntf_n_week': '{n} скробблов за неделю',
  'ntf_top_artist': 'Топ-исполнитель: {a}',
  'ntf_update_avail': '🆕 Доступно обновление',
  'ntf_update_ready': 'LastStats {v} готова — нажмите, чтобы посмотреть.',
  'ntf_sync_title': '🔄 Синхронизация скробблов…',
  'ntf_sync_done': '✅ Скробблы синхронизированы',
  'ntf_sync_new': 'Добавлено новых скробблов: {n}.',
  'ntf_grand_t': '{v} скробблов!',
  'ntf_year': '{y} год',
  'ntf_week': 'Неделя {w}',
  'reorder': 'Изменить порядок',
};
