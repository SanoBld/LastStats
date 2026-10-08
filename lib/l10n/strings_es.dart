// lib/l10n/strings_es.dart
// ══════════════════════════════════════════════════════════════════════════
//  Spanish
// ══════════════════════════════════════════════════════════════════════════

import "app_strings.dart";

class AppStringsEs implements AppStrings {
  const AppStringsEs();

  @override String get period7day     => 'Semana';
  @override String get period1month   => 'Mes';
  @override String get period3month   => '3 meses';
  @override String get period6month   => '6 meses';
  @override String get period12month  => 'Año';
  @override String get periodOverall  => 'Todo';

  @override String get navDashboard => 'Panel';
  @override String get navSearch    => 'Buscar';
  @override String get navRankings  => 'Clasificación';
  @override String get navCharts    => 'Gráficos';
  @override String get navHistory   => 'Historial';
  @override String get navSettings  => 'Ajustes';

  @override String get cacheTitle                  => 'Almacenamiento';
  @override String get cacheUsage                  => 'Uso';
  @override String get cacheLimit                  => 'Límite de almacenamiento';
  @override String get cacheLimitHint              => 'Cuando se alcanza el límite, las imágenes menos recientes se eliminan automáticamente.';
  @override String get cacheClearSection           => 'Limpiar';
  @override String get cacheImages                 => 'Imágenes';
  @override String get cacheImagesSubtitle         => 'Portadas de artistas, álbumes y canciones';
  @override String get cacheApiData                => 'Datos de la API';
  @override String get cacheApiDataSubtitle        => 'Top artistas, álbumes, escuchas recientes…';
  @override String get cacheScrobbles              => 'Historial de scrobbles';
  @override String get cacheScrobblesSubtitle      => 'Todas las escuchas descargadas';
  @override String get cacheClearBtn               => 'Vaciar';
  @override String get cacheConfirmScrobblesTitle  => '¿Eliminar el historial?';
  @override String get cacheConfirmScrobblesBody   => 'Se eliminará todo el historial. Se volverá a descargar en el próximo inicio.';
  @override String get cacheConfirmAllTitle        => '¿Vaciar todo el caché?';
  @override String get cacheConfirmAllBody         => 'Se eliminarán las imágenes, los datos de la API y el historial.';
  @override String get cacheDelete                 => 'Eliminar';

  @override String get commonArtists          => 'Artistas';
  @override String get commonAlbums           => 'Álbumes';
  @override String get commonTracks           => 'Canciones';
  @override String get commonNoResults        => 'Sin resultados';
  @override String get commonRetry            => 'Reintentar';
  @override String get commonCancel           => 'Cancelar';
  @override String get commonApply            => 'Aplicar';
  @override String get commonPlays            => 'reproducciones';
  @override String get commonListeners        => 'oyentes';
  @override String get commonNowPlayingBadge  => 'EN VIVO';
  @override String get commonNowPlayingLong   => 'Reproduciendo ahora';
  @override String get commonRecentTracks     => 'Canciones recientes';
  @override String get commonNoRecentTracks   => 'Sin canciones recientes';
  @override String get commonTopArtists       => 'Top Artistas';

  @override String get rankingsTitle     => 'Clasificación';
  @override String get rankingsPodium    => 'Podio';
  @override String get rankingsContinued => 'Resto de la clasificación';
  @override String get rankingsAllYears  => 'Todos los años';

  @override String get chartsTitle              => 'Gráficos';
  @override String get chartsMonthly            => 'Scrobbles (12 meses)';
  @override String get chartsArtistDist         => 'Top artistas (distribución)';
  @override String get chartsMainstreamTitle    => 'Mainstream vs Joyas ocultas';
  @override String get chartsMainstreamSubtitle => 'Popularidad mundial de sus artistas favoritos.';
  @override String get chartsCompute            => 'Calcular';
  @override String get chartsRecompute          => 'Recalcular';
  @override String get chartsGem                => 'Joya oculta';
  @override String get chartsMainstream         => 'Mainstream';
  @override String globalListeners(String count) => '$count oyentes mundiales';

  @override String get historyTitle           => 'Historial';
  @override String get historySubtitle        => 'Sus escuchas, día a día';
  @override String get historyToday           => 'Hoy';
  @override String get historySelectDate      => 'Seleccionar una fecha';
  @override String get historyChronological   => 'Cronológico';
  @override String get historyList            => 'Lista';
  @override String get historyStats           => 'Estadísticas';
  @override String get historyNoTracks        => 'Sin escuchas ese día';
  @override String historyScrobbles(int n)    => '$n scrobbles';
  @override String historyArtistsCount(int n) => '$n artistas';
  @override String historyAlbumsCount(int n)  => '$n álbumes';
  @override String get historyTopArtists      => 'Top artistas';
  @override String get historyTopAlbums       => 'Top álbumes';
  @override String get historyTopTracks       => 'Top canciones';
  @override String get historyHourTracks      => 'canción';
  @override List<String> get months => const [
    '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  @override String dayLabel(DateTime d) {
    const dias  = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
    const meses = ['','enero','febrero','marzo','abril','mayo','junio',
        'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month]} de ${d.year}';
  }

  @override String get searchTitle        => 'Buscar';
  @override String get searchProfiles     => 'Perfiles';
  @override String get searchHintBar      => 'Artista, álbum, canción o perfil…';
  @override String get searchHintProfiles => 'Busque un usuario de Last.fm';
  @override String get searchHintArtists  => 'Busque un artista';
  @override String get searchHintAlbums   => 'Busque un álbum';
  @override String get searchHintTracks   => 'Busque una canción';
  @override String get searchTypePrompt   => 'Escriba en la barra de arriba';
  @override String get searchAll          => 'Todo';
  @override String get searchFolders => 'Carpetas';
  @override String get searchFoldersHint => 'Cree una carpeta para guardar canciones, álbumes o artistas.';
  @override String memberSince(String date) => 'Desde $date';
  @override String get perDay             => 'por día';
  @override String get activityDays       => 'días activos';

  @override String get dashStats           => 'Estadísticas';
  @override String get dashTopTracks       => 'Top Canciones';
  @override String get dashFriends         => 'Amigos';
  @override String get dashRefresh         => 'Actualizar';
  @override String get dashRefreshFriends  => 'Actualizar amigos';
  @override String get dashScrobbles       => 'scrobbles';
  @override String get dashScrobblesPerDay => 'por día';
  @override String get dashDaysActive      => 'días activos';
  @override String get dashLastTrack       => 'Última escucha';
  @override String get dashArtist1         => 'Artista #1';
  @override String get dashAlbum1          => 'Álbum #1';
  @override String get dashTrack1          => 'Canción #1';
  @override String get dashNoFriends       => 'No se encontraron amigos';
  @override String get dashResetCache      => 'Restablecer caché';
  @override String get dashResetCacheConfirm => 'Todos los datos de scrobbles en caché se eliminarán y se volverán a descargar desde Last.fm.';

  @override String get dashFriendsActivity => 'Actividad de sus amigos de Last.fm';

  @override String get settingsTitle             => 'Ajustes';
  @override String get settingsAppearance        => 'Apariencia';
  @override String get settingsTheme             => 'Tema';
  @override String get settingsThemeAuto         => 'Auto';
  @override String get settingsThemeLight        => 'Claro';
  @override String get settingsThemeDark         => 'Oscuro';
  @override String get settingsAccentColor       => 'Color de acento';
  @override String get settingsAccentAuto        => 'Auto';
  @override String get settingsCustomColor       => 'Personalizado';
  @override String get settingsCustomColorEdit   => 'Editar';
  @override String get settingsDynamicColor      => 'Color dinámico';
  @override String get settingsDayNightAccent          => 'Acento día/noche';
  @override String get settingsDayNightAccentToggle    => 'Colores diferentes de día y de noche';
  @override String get settingsDayNightAccentToggleSub => 'Usa un color de acento diferente para el tema oscuro.';
  @override String get settingsDayNightAccentDark      => 'Color (tema oscuro)';
  @override String get settingsDayNightUseHours        => 'Usar horas específicas';
  @override String get settingsDayNightUseHoursSub     => 'Cambia de color según la hora en lugar del tema activo.';
  @override String get settingsDayNightDayStart        => 'El día empieza a las';
  @override String get settingsDayNightNightStart      => 'La noche empieza a las';
  @override String get settingsMaterialYou       => 'Material You';
  @override String get settingsMaterialYouSub    => 'Usa el color del fondo de pantalla de Android';
  @override String get settingsMusicColor        => 'Color desde la música';
  @override String get settingsMusicColorSub     => 'Extrae el color de la carátula actual';
  @override String get settingsMusicColorNote    => 'El color dominante de la carátula actual reemplaza el acento.';
  @override String get settingsMusicColorLocked  => 'Desactive Material You primero';
  @override String get settingsStartupPage       => 'Página de inicio';
  @override String get settingsStartupTab        => 'Pestaña al abrir';
  @override String get settingsDashboardSection  => 'Panel';
  @override String get settingsHeaderImage       => 'Imagen de cabecera';
  @override String get settingsHeaderImageSub    => 'La carátula elegida se muestra como fondo de inicio.';
  @override String get settingsHeaderSource      => 'Fuente';
  @override String get settingsHeaderPeriod      => 'Período';
  @override String get settingsHeaderAnimation   => 'Transición';
  @override String get settingsHeaderAnimationSub => 'Animación al cambiar de carátula.';
  @override String get settingsHeaderBlur        => 'Desenfoque';
  @override String get settingsHeaderBlurNone    => 'Ninguno';
  @override String get settingsHeaderCustomUrl   => 'URL de la imagen';
  @override String get settingsHeaderCustomUrlHint => 'https://ejemplo.com/imagen.jpg';
  @override String get settingsHeaderCustomUrlSub  => 'Pegue la URL directa de una imagen (jpg, png, webp…).';
  @override String get settingsHeaderApply       => 'Aplicar';
  @override String get settingsHeaderFallback    => 'Imagen predeterminada';
  @override String get settingsHeaderFallbackSub => 'Se muestra cuando no hay música sonando.';
  @override String get settingsHeaderFallbackUrlLabel => 'URL de la imagen predeterminada';
  @override String get settingsVisibleSections   => 'Secciones visibles';
  @override String get settingsNowPlayingSection => 'Reproduciendo ahora';
  @override String get settingsStatsSection      => 'Estadísticas';
  @override String get settingsTopArtistsSection => 'Top Artistas';
  @override String get settingsTopTracksSection  => 'Top Canciones';
  @override String get settingsFriendsSection    => 'Amigos';
  @override String get settingsFriendsSectionSub => 'Actividad de sus amigos de Last.fm';
  @override String get settingsAccount           => 'Cuenta';
  @override String get settingsConnectedProfile  => 'Perfil de Last.fm conectado';
  @override String get settingsLogout            => 'Cerrar sesión';
  @override String get settingsLogoutTitle       => '¿Cerrar sesión?';
  @override String get settingsLogoutContent     => 'Sus credenciales se eliminarán.';
  @override String get settingsLogoutConfirm     => 'Cerrar sesión';
  @override String get settingsBackup            => 'Copia de seguridad y restauración';
  @override String get settingsExport            => 'Exportar ajustes';
  @override String get settingsExportSub         => 'Copia un JSON al portapapeles';
  @override String get settingsImport            => 'Restaurar una copia de seguridad';
  @override String get settingsImportSub         => 'Pegue un JSON exportado anteriormente';
  @override String get settingsBackupInfo        => 'Incluye: tema, colores, clave API, usuario, cabecera, favoritos. Compatible entre versiones.';
  @override String get settingsUpdates           => 'Actualizaciones';
  @override String get settingsAutoUpdate        => 'Verificación automática';
  @override String get settingsAutoUpdateSub     => 'Una vez al día';
  @override String get settingsCheckNow          => 'Verificar ahora';
  @override String get settingsUpToDate          => 'Actualizado';
  @override String settingsUpdateAvailable(String v) => 'v$v disponible';
  @override String get settingsCheckFailed       => 'No se pudo verificar.';
  @override String settingsUpdateBanner(String v) => 'Actualización v$v';
  @override String get settingsDownload          => 'Descargar';
  @override String get settingsViewRelease       => 'Ver';
  @override String get settingsAbout             => 'Acerca de';
  @override String get settingsVersion           => 'Versión';
  @override String get settingsWebVersion        => 'Versión web';
  @override String get settingsWebVersionSub     => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode        => 'Código fuente';
  @override String get settingsSourceCodeSub     => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage          => 'Idioma';
  @override String get settingsAboutProjectDesc  => 'LastStats es un proyecto personal de código abierto. Puede contener errores.';
  @override String get settingsAboutSupport      => 'Apoye el proyecto';
  @override String get settingsAboutSupportSub   => '⭐ Deje una estrella en GitHub';
  @override String get settingsFaq               => 'Preguntas frecuentes';

  @override String get headerNowPlaying  => 'Reproduciendo ahora';
  @override String get headerTopTrack    => 'Canción #1';
  @override String get headerTopAlbum    => 'Álbum #1';
  @override String get headerTopArtist   => 'Artista #1';
  @override String get headerCustomImage => 'Imagen personalizada';
  @override String get headerThemeColor  => 'Color del tema';
  @override String get headerAnimNone    => 'Ninguna';
  @override String get headerAnimFade    => 'Desvanecer';
  @override String get headerAnimSlide   => 'Deslizar';
  @override String get headerAnimZoom    => 'Zoom';
  @override String get headerPeriodWeek  => 'Semana';
  @override String get headerPeriodMonth => 'Mes';
  @override String get headerPeriodAllTime => 'Todo el tiempo';

  @override String get colorPickerTitle       => 'Color personalizado';
  @override String get colorPickerHue         => 'Tono';
  @override String get colorPickerSaturation  => 'Saturación';
  @override String get colorPickerBrightness  => 'Brillo';
  @override String get colorPickerQuickColors => 'Colores rápidos';
  @override String get colorPickerInvalid     => 'Formato inválido';
  @override String get colorCustomTooltip     => 'Personalizado';

  @override String get exportTitle      => 'Exportar ajustes';
  @override String get exportFilename   => 'Nombre del archivo';
  @override String get exportJsonContent => 'Contenido JSON';
  @override String get exportInfo       => 'Copie este JSON, péguelo en un archivo de texto y nómbrelo con .json';
  @override String get exportCopy       => 'Copiar JSON';
  @override String get exportCopied     => '¡Copiado!';
  @override String get importTitle      => 'Restaurar una copia de seguridad';
  @override String get importHintLabel  => 'Pegue aquí su copia de seguridad de LastStats.';
  @override String get importEmpty      => 'Campo vacío.';
  @override String get importInvalidJson  => 'JSON inválido.';
  @override String get importUnknownFile  => 'Archivo no reconocido.';
  @override String get importInvalidFormat => 'Formato inválido.';
  @override String get importSuccess    => 'Ajustes restaurados con éxito ✓';
  @override String get importRestore    => 'Restaurar';

  @override String get setupImportJson      => 'Importar JSON';
  @override String get setupImportHintLabel => 'Pegue el contenido de su archivo JSON abajo.';
  @override String get setupImportNote      => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat    => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields   => 'JSON inválido: faltan los campos "username" o "api_key".';

  @override String get detailTracklist       => 'Canciones';
  @override String get detailAlbumLabel      => 'Álbum';
  @override String get detailDuration        => 'Duración';
  @override String get detailTopTracks       => 'Canciones populares';
  @override String get detailTopAlbums       => 'Álbumes populares';
  @override String get detailBioReadMore     => 'Leer más';
  @override String get detailBioReadLess     => 'Leer menos';
  @override String get detailUserPlays       => 'sus reproducciones';
  @override String get detailGlobalPlays       => 'reproducciones totales';
  @override String get detailUserRank        => 'posición';
  @override String get detailUserRankNA      => 'N/D';
  @override String get detailGlobalListeners => 'oyentes';
  @override String get detailPeriod          => 'Período';
  @override String get detailBiography       => 'Biografía';
  @override String get detailGlobalListenersLabel => 'Oyentes';
  @override String get detailTranslate       => 'Traducir';
  @override String get detailShowOriginal    => 'Ver original';
  @override String get detailLyrics          => 'Letra';
  @override String get detailLyricsNotFound  => 'Letra no disponible';
  @override String get detailCopyLyrics      => 'Copiar letra';
  @override String get detailLyricsCopied    => 'Letra copiada';

  @override String get detailShoutbox => 'Chat de Last.fm';
  @override String get detailShoutboxReply => 'Responder';  @override String get dashPerWeek           => 'por semana';

  @override String get onboardSkip             => 'Omitir';
  @override String get onboardNext             => 'Siguiente';
  @override String get onboardFinish           => 'Finalizar';
  @override String get onboardBack             => 'Atrás';
  @override String get onboardAppearanceTitle  => 'Personalice su estilo';
  @override String get onboardAppearanceSub    => 'Tema, color de acento y Material You.';
  @override String get onboardNotifTitle       => 'Mantente informado';
  @override String get onboardNotifSub         => 'Notificaciones y vibraciones.';
  @override String get onboardFavTitle         => 'Sus perfiles favoritos';
  @override String get onboardFavSub           => 'Añada amigos de Last.fm para encontrarlos rápidamente.';
  @override String get onboardFavHint          => 'Usuario de Last.fm';
  @override String get onboardFavAdd           => 'Añadir';
  @override String get onboardFavEmpty         => 'Sin favoritos por ahora';
  @override String get onboardFavSearchHint    => 'Buscar un perfil de Last.fm…';
  @override String get onboardFavNoResults     => 'No se encontró ningún perfil';
  @override String get onboardFavFriendsTitle  => 'Sus amigos de Last.fm';
  @override String get onboardFavNoFriends     => 'No se encontraron amigos en esta cuenta';
  @override String get onboardFavSelected      => 'Favoritos seleccionados';
  @override String get onboardDashTitle        => 'Su panel';
  @override String get onboardDashSub          => 'Elija qué secciones mostrar.';
  @override String get onboardStartupTitle     => 'Pantalla de inicio';
  @override String get onboardStartupSub       => '¿Qué pestaña quiere ver primero?';
  @override String get onboardPlatformTitle    => '¿Dónde escucha música?';
  @override String get onboardPlatformSub      => 'Así solo se muestran los enlaces útiles en las fichas de canción/artista/álbum.';
  @override String get platformLastfm          => 'Last.fm';
  @override String get platformSpotify         => 'Spotify';
  @override String get platformYtMusic         => 'YouTube Music';
  @override String get platformOther           => 'Otra / mostrar todo';
  @override String get settingsMusicPlatform          => 'Plataforma musical';
  @override String get settingsMusicPlatformSub       => 'Filtra los enlaces mostrados en las fichas de detalle';
  @override String get settingsShowAllPlatformLinks    => 'Mostrar siempre todo';
  @override String get settingsShowAllPlatformLinksSub => 'Ignora el filtro y muestra todos los enlaces (Last.fm, Spotify, YT Music, Web)';
  @override String get onboardUpdatesTitle     => 'Actualizaciones';
  @override String get onboardUpdatesSub       => 'Verificación automática de nuevas versiones.';
  @override String get onboardStyle              => 'Estilo';
  @override String get onboardStyleMaterialYou    => 'Material You';
  @override String get onboardStyleNothing        => 'Nothing OS';
  @override String get onboardPreview             => 'Vista previa';
  @override String get onboardPreviewButton       => 'Botón';
  @override String get onboardPreviewOutline      => 'Contorno';
  @override String get onboardPreviewText         => 'Texto de ejemplo';
  @override String get onboardPreviewBubble       => 'Burbuja';
  @override String get onboardAccentTint          => 'Tono de acento';
  @override String get onboardNothingRedOnly      => 'Solo rojo';
  @override String get onboardNothingRedYellow    => 'Rojo + amarillo';
  @override String get onboardDisplay             => 'Pantalla';
  @override String get onboardOledTitle           => 'Negro OLED';
  @override String get onboardOledSub             => 'Fondo negro puro en modo oscuro';
  @override String get onboardArtworkColorTitle   => 'Color desde la carátula';
  @override String get onboardArtworkColorSub     => 'Adapta el color de acento a la carátula en reproducción';
  @override String get onboardNewsTitle           => 'Notificaciones de novedades';
  @override String get onboardNewsSub             => 'Reciba avisos de nuevas funciones y correcciones';
  @override String get onboardNewsBadgeTitle      => 'Punto de novedades';
  @override String get onboardNewsBadgeSub        => 'Punto rojo en la campana del panel cuando hay novedades';
  @override String get onboardHapticTitle         => 'Retroalimentación háptica';
  @override String get onboardHapticSub           => 'Sienta ligeras vibraciones en interacciones clave';
  @override String get onboardRecaps              => 'Resúmenes';
  @override String get onboardDailyRecapTitle     => 'Resumen diario';
  @override String get onboardDailyRecapSub       => 'Un resumen rápido de su escucha del día';
  @override String get onboardWeeklyRecapTitle    => 'Resumen semanal';
  @override String get onboardWeeklyRecapSub      => 'Sus tops de artistas, álbumes y canciones de la semana';
  @override String get onboardMilestonesSection   => 'Hitos de scrobbles';
  @override String get onboardMilestonesTitle     => 'Hitos';
  @override String get onboardMilestonesSub       => 'Celebra cifras redondas de scrobbles';
  @override String get onboardGrandMilestonesTitle => 'Grandes hitos';
  @override String get onboardGrandMilestonesSub   => 'Celebración especial para los grandes hitos';
  @override String get onboardDynamicColorSub      => 'Usa los colores de su fondo de pantalla (Android 12+)';
  @override String get onboardBetaTitle            => 'Actualizaciones beta';
  @override String get onboardBetaSub              => 'Acceso anticipado a preversiones';

  @override String get notifDetailTitle            => 'Notificación';
  @override String get notifDetailOpenLink         => 'Abrir enlace';

  @override String get settingsCheckingUpdates     => 'Buscando actualizaciones…';
  @override String get settingsTapToDownload       => 'Toque para descargar';

  @override String get detailLookingForPreview     => 'Buscando un adelanto…';
  @override String get detailPreview30Sec          => 'Adelanto · 30 seg';

  @override String get setupTagline                => 'Sus estadísticas de Last.fm, reinventadas.';
  @override String get setupAnalyseProfile         => 'Analizar un perfil';
  @override String get setupConnecting             => 'Conectando…';
  @override String get setupStartAnalysis          => 'Iniciar análisis';
  @override String get setupOr                     => 'o';
  @override String setupWelcome(String username)   => '¡Bienvenido, $username!';
  @override String get setupUsernameLabel          => 'Usuario de Last.fm';
  @override String get setupApiKeyLabel            => 'Clave API de Last.fm';
  @override String get setupApiKeyHint             => 'Clave hexadecimal de 32 caracteres';
  @override String get setupApiKeyPrivacyNote      => 'Guardada localmente. Nunca enviada a terceros.';
  @override String get setupRememberMe             => 'Recordarme';
  @override String get setupGetApiKey              => 'Obtener una clave API gratis';
  @override String setupScrobblesToImport(String c) => '$c scrobbles por importar';
  @override String get setupWelcomeBanner          => '¡Bienvenido a LastStats!';
  @override String get setupOneTimeImportNote      => 'Importación única, los próximos inicios serán instantáneos.';

  @override String get dashTapToDownload           => 'Toque para descargar.';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      '${isBeta ? "Beta" : "Nueva"} actualización: v$version';
  @override String get dashWeekLabel               => 'ESTA SEMANA';
  @override String get dashMonthLabel              => 'ESTE MES';
  @override String get dashYearLabel               => 'ESTE AÑO';
  @override String get dashTopArtistLabel          => 'Artista top';
  @override String get dashTopTrackLabel           => 'Canción top';
  @override String get dashScrobblesLabel          => 'Scrobbles';
  @override String get newsTypeFeatures            => 'Funciones';
  @override String get newsTypeFixes               => 'Correcciones';
  @override String get newsTypeUpdates             => 'Actualizaciones';
  @override String get newsTypeAlerts              => 'Alertas';
  @override String get newsTypeInfo                => 'Info';
  @override String get newsWhatsNew                => 'Novedades';
  @override String newsItemsCount(int n)           => '$n ${n > 1 ? "elementos" : "elemento"}';
  @override String get newsFilters                 => 'Filtros';
  @override String get newsAll                     => 'Todo';
  @override String get newsAnyDate                 => 'Cualquier fecha';
  @override String get newsNoNewsYet               => 'Sin novedades por ahora';
  @override String get settingsNotifications        => 'Notificaciones';
  @override String get settingsCache                 => 'Caché';
  @override String get settingsCardAppearanceSub     => 'Tema, acento, diseño, Material You';
  @override String get settingsCardDashboardSub      => 'Imagen de cabecera, secciones visibles, tarjetas de estadísticas';
  @override String get settingsCardStartupSub        => 'Pestaña mostrada al iniciar la app';
  @override String get settingsCardNotificationsSub  => 'Hitos, resúmenes diarios y semanales';
  @override String get settingsSync                  => 'Sincronización';
  @override String get settingsCardSyncSub           => 'Sincronización automática en segundo plano';
  @override String get settingsCardAccountSub        => 'Perfil de Last.fm conectado, cerrar sesión';
  @override String get settingsCardCacheSub          => 'Historial, imágenes, datos de la API';
  @override String get settingsCardBackupSub         => 'Exportar y restaurar sus ajustes';
  @override String get settingsCardUpdatesSub        => 'Buscar nuevas versiones';
  @override String get settingsCardAboutSub          => 'Versión, código fuente, créditos';
  @override String get settingsCardFaqSub            => 'Scrobbling, plataformas, código abierto';
  @override String get settingsRestartNotice => 'Algunos ajustes requieren reiniciar la app para aplicarse por completo.';
  @override String get syncPageTitle           => 'Sincronización de scrobbles';
  @override String get syncAutoTitle           => 'Sincronización automática';
  @override String get syncAutoSubtitle        => 'Sincroniza su historial en segundo plano a intervalos regulares';
  @override String get syncFrequencyLabel      => 'Frecuencia';
  @override String syncFrequencyHours(int h)   => 'Cada ${h}h';
  @override String get syncFrequencyDaily      => 'Una vez al día';
  @override String get syncManualTitle         => 'Sincronización manual';
  @override String get syncNowButton           => 'Sincronizar ahora';
  @override String get syncInProgress          => 'Sincronizando…';
  @override String get syncLastSyncLabel       => 'Última sincronización';
  @override String get syncNeverLabel          => 'Nunca';
  @override String get syncTotalScrobblesLabel => 'Scrobbles en caché';
  @override String syncNewScrobblesFound(int n) => n == 0 ? 'Sin scrobbles nuevos' : '$n scrobble(s) nuevo(s) encontrado(s)';
  @override String get syncUpToDateMsg         => 'Historial actualizado';
  @override String get syncNotifNote           => 'Durante una sincronización completa aparece una notificación con progreso.';
  @override String get pcModeLayout      => 'Diseño';
  @override String get pcModeNavLayout   => 'Diseño de navegación';
  @override String get pcModeAuto        => 'Auto';
  @override String get pcModeSideRail    => 'Barra lateral';
  @override String get pcModeBottomBar   => 'Barra inferior';
  @override String get pcModeHintAuto    => 'Barra lateral en pantallas anchas (≥ 720 dp), barra inferior en pantallas estrechas.';
  @override String get pcModeHintOn      => 'Usar siempre la barra de navegación lateral, sin importar el tamaño de pantalla.';
  @override String get pcModeHintOff     => 'Usar siempre la barra de navegación inferior, sin importar el tamaño de pantalla.';
  @override String get aboutTagline               => 'Su compañero de estadísticas de Last.fm';
  @override String get aboutAppInfo                => 'Info de la app';
  @override String get aboutScrobbleDownloader     => 'Descargador de scrobbles';
  @override String get aboutScrobbleDownloaderSub  => 'Exporte todos sus scrobbles a un archivo';
  @override String get aboutPoweredBy              => 'Con la ayuda de';
  @override String get aboutImageDisclaimer        => 'Las imágenes de artistas, álbumes y canciones se obtienen automáticamente de estas fuentes y a veces pueden ser incorrectas o no coincidir con el contenido real.';
  @override String get aboutFooter                 => 'Hecho con ❤️ · Sin afiliación con Last.fm / CBS';

  @override String updatesPublishedOn(String date) => 'Publicado el $date';
  @override String get updatesCurrentVersion       => 'Versión actual';
  @override String get updatesBetaTitle            => 'Actualizaciones beta';
  @override String get updatesBetaSub              => 'Reciba acceso anticipado a las versiones preliminares';

  @override String get backupWhatsIncluded         => 'Qué incluye';
  @override String get backupDownloadFile          => 'Descargue un archivo .json';
  @override String get backupChooseFile            => 'Elegir un archivo de copia de seguridad';
  @override String get backupFileSaved             => 'Copia de seguridad guardada';
  @override String get backupFileSaveFailed        => 'No se pudo guardar el archivo';
  @override String get setupRestoreBackup          => 'Restaurar una copia de seguridad';
  @override String get setupRestoreBackupSub       => 'Recupere su cuenta y ajustes desde un archivo .json de copia de seguridad';
  @override String get backupRestoreKeysTitle => 'Restaurar claves de API';
  @override String get backupRestoreKeysDesc => 'Elija qué claves de Last.fm restaurar desde esta copia de seguridad.';
  @override String get backupRestoreApiKeyLabel => 'Clave de API';
  @override String get backupRestoreSecretKeyLabel => 'Clave secreta';
  @override String get backupIncludeFoldersLabel => 'Incluir carpetas';
  @override String get backupIncludeFoldersDesc => 'Incluye sus carpetas de canciones y su contenido.';
  @override String get backupIncludeKeysDesc => 'Incluir las claves en el archivo exportado';

  @override String get backupIncludeThemesLabel => 'Exportar temas';
  @override String get backupIncludeThemesDesc => 'Le permite compartir solo el aspecto (colores, estilo) con otra persona.';

  @override String get backupAutoTitle => 'Copia de seguridad automática';
  @override String get backupAutoEnableLabel => 'Activar copia de seguridad automática';
  @override String get backupAutoEnableDesc => 'Guarda una copia de seguridad sola, en el intervalo elegido abajo.';
  @override String get backupAutoFreqLabel => 'Frecuencia';
  @override String get backupAutoFreqDaily => 'Cada día';
  @override String get backupAutoFreqWeekly => 'Cada semana';
  @override String get backupAutoFreqMonthly => 'Cada mes';
  @override String get backupAutoFreqYearly => 'Cada año';
  @override String get backupAutoFolderLabel => 'Carpeta de copia de seguridad';
  @override String get backupAutoFolderDefault => 'Carpeta predeterminada de la app';
  @override String backupAutoNextLabel(String date) => 'Próxima copia: $date';  @override String get backupIncludeScrobblesLabel => 'Incluir todo el historial';
  @override String get backupIncludeScrobblesDesc => 'Añade todas las canciones escuchadas desde el principio (puede ser grande).';

  @override String get backupScrobblesSlowWarning => 'Esto puede tardar un poco y es más lento que una copia de seguridad normal.';  @override String backupExportedOn(String date) => 'Copia de seguridad del $date';
  @override String get backupScrobblesErrorTitle => 'Error en el historial';
  @override String get backupScrobblesErrorDesc => 'Algunos años del historial parecen estar dañados en este archivo. ¿Qué quiere hacer?';
  @override String get backupScrobblesKeepAnyway => 'Continuar de todos modos';
  @override String get backupScrobblesCancel => 'Cancelar historial';
  @override String get backupScrobblesSkipRefetch => 'Omitir y volver a descargar en línea';  @override String get settingsCrashLog => 'Registro de errores';
  @override String get backupCrashLogDesc => 'Guarda los errores que encuentra la app, útil para reportar un fallo.';
  @override String get backupCrashLogShare => 'Compartir registro';
  @override String get backupCrashLogClear => 'Vaciar registro';
  @override String get backupCrashLogEmpty => 'No hay errores registrados';
  @override String get backupCrashLogCleared => 'Registro vaciado';
  @override String get backupCrashLogClearConfirm => '¿Vaciar el registro de errores?';

  @override String get faqSectionLabel             => 'Preguntas frecuentes';
  @override String get backupOverwriteWarning => 'Restaurar una copia de seguridad sobrescribirá sus ajustes actuales.';
  @override String get faqOpenSourceBadge => 'LastStats es un proyecto gratuito y de código abierto hecho con ❤️ por SanoBld.';
  @override String get cacheUnlimited     => 'Ilimitado';
  @override String get cacheTotalUsed     => 'Total usado';
  @override String get cacheScrobblesShort => 'Historial';
  @override String get restartHintFeatures => 'Algunas funciones pueden requerir reiniciar la app para surtir efecto.';
  @override String get reorderCardsTitle   => 'Reordenar tarjetas';
  @override String get commonSave          => 'Guardar';
  @override String get dashFallbackWhenNoMusic   => 'Cuando no hay música sonando';
  @override String get dashFallbackChooseDisplay => 'Elija qué mostrar de fondo en su lugar';
  @override String get dashFallbackPeriodLabel   => 'Período de respaldo';
  @override String get fallbackPeriod1Week       => '1 semana';
  @override String get fallbackPeriod1Month      => '1 mes';
  @override String get fallbackPeriodAllTime     => 'Todo el tiempo';
  @override String get fallbackTypeNothing       => 'Nada';
  @override String get fallbackTypeTopTrack      => 'Canción #1';
  @override String get fallbackTypeTopAlbum      => 'Álbum #1';
  @override String get fallbackTypeTopArtist     => 'Artista #1';
  @override String get fallbackTypeCustomImage   => 'Imagen personalizada';
  @override String fallbackWillShow(String detail) => 'Mostrará: $detail';
  @override String get fallbackWillShowCustomUrl => 'Mostrará: URL de imagen personalizada';

  @override String get dashAnimationBlurSection  => 'Animación y desenfoque';
  @override String get dashMusicAnimationTitle   => 'Animación de música';
  @override String get dashMusicAnimationSub     => 'Cuando suena música, la imagen se desenfoca y se mueve suavemente, como en Apple Music.';
  @override String get dashMusicAnimationInfo    => 'El desenfoque se aplica automáticamente en este modo. El control de desenfoque de arriba no tiene efecto mientras suena música.';

  @override String get settingsTopAlbumsSection  => 'Top Álbumes';
  @override String get dashRecentPlaysLabel      => 'Reproducciones recientes';
  @override String get dashStatCardsSectionLabel => 'Tarjetas de estadísticas';
  @override String get dashStatCardsHeading      => 'Tarjetas de stats';
  @override String get dashStatCardsSub          => 'Elija y reordene las tarjetas mostradas en el bloque de estadísticas.';
  @override String get settingsDashboardChartSection => 'Gráfico del panel';
  @override String get dashChartCalendarLabel => 'Calendario de escucha';
  @override String get dashChartMonthlyLabel => 'Barras mensuales';
  @override String get settingsDisplayNameSection => 'Nombre personalizado';
  @override String get settingsDisplayNameLabel => '¿Cómo quiere que le llamemos?';
  @override String get settingsDisplayNameHint => 'Ej. Sano Bld — déjelo vacío para usar el nombre de su cuenta';
  @override String get newsSearchHint => 'Buscar en las noticias…';
  @override String get aboutOpenSourceLibs => 'Bibliotecas de código abierto';
  @override String get aboutOpenSourceLibsSub => 'Todos los paquetes de Flutter usados para crear la app.';
  @override String get aboutLicenseSection => 'Licencia';
  @override String get aboutLicenseText => 'Este proyecto se publica bajo la licencia MIT: es libre de usarlo, modificarlo, duplicarlo o redistribuirlo, solo cíteme.';
  @override String get aboutLicenseLink => 'Ver licencia completa';
  @override String get languageAiNote => 'Las traducciones fueron generadas por IA y pueden contener imprecisiones.';
  @override String get aboutAiDevNote => 'La IA también se usó para desarrollar esta app.';
  @override String get notifWorkManagerInfo => 'Las notificaciones se ejecutan en segundo plano mediante WorkManager. La app no necesita estar abierta. Se requiere conexión a internet.';
  @override String get notifIntervalTitle       => 'Cada X scrobbles';
  @override String get notifIntervalSubtitle    => 'Reciba avisos a intervalos regulares';
  @override String get notifRecapsSection       => 'Resúmenes de escucha';
  @override String get notifDailyRecapSubtitle  => 'Total de scrobbles + artista favorito del día';
  @override String get notifWeeklyRecapSubtitle => 'Total de scrobbles + artista favorito de la semana';
  @override String get notifNewsSection         => 'Actualidad';
  @override String get notifSyncSection         => 'Sincronización';
  @override String get notifSyncTitle           => 'Notificaciones de sincronización';
  @override String get notifSyncSubtitle        => 'Avisa cuando termina una sincronización del historial';
  @override String get notifSyncDetailTitle     => 'Detalle del progreso';
  @override String get notifSyncDetailSubtitle  => 'Mostrar el avance (año actual, contador) durante la sincronización';
  @override String get notifNewsSubtitle        => 'Reciba avisos de nuevas funciones, correcciones y anuncios';
  @override String get notifBadgeOnDashboard    => 'Insignia en el panel';
  @override String get notifBadgeSubtitle       => 'Mostrar el punto rojo en la campana de novedades';
  @override String get notifTestLabel           => 'Prueba';
  @override String get notifPermissionDisabledTitle => 'Notificaciones desactivadas';
  @override String get notifPermissionDisabledBody  => 'Conceda el permiso para que LastStats pueda enviarle avisos.';
  @override String get notifGrantPermission     => 'Conceder permiso';
  @override String get notifThresholdIntro      => 'Recibirá una notificación especial en cada uno de estos hitos:';
  @override List<String> get notifThresholdMessages => const [
    'Sus primeros 1000 scrobbles. La aventura comienza. 🎵',
    '¡Ha llegado a cinco cifras! 🎉',
    'Es un verdadero adicto a la música. 🔥',
    'Un millón de scrobbles. Eso es legendario. 🎸',
  ];
  @override String get notifIntervalDescription => 'Enviar una notificación cada X scrobbles';
  @override String get notifCustomValueLabel    => 'Valor personalizado';
  @override String get notifTimeNotifyAt        => 'Notificar a';
  @override String get notifDayOfWeek           => 'Día de la semana';
  @override List<String> get weekdaysShort => const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  @override List<String> get weekdaysNarrow => const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  @override String get weekAbbrev => 'S';
  @override String get notifSendTest            => 'Enviar una notificación de prueba';
  @override String get notifSentCheckBar        => '¡Revise su barra de notificaciones!';
  @override String get notifMakeSureWorks       => 'Verifique que todo funcione.';
  @override String get notifSentBang            => '¡Enviado!';
  @override String get notifSendButton          => 'Enviar';
  @override String get apVisualStyle             => 'Estilo visual';
  @override String get apStyleDefault            => 'Predeterminado';
  @override String get apNothingAccentLabel      => 'Acento';
  @override String get apNothingClassic          => 'Clásico';
  @override String get apRedOnlyDesc             => 'Solo rojo';
  @override String get apNothingMixed            => 'Mixto';
  @override String get apRedYellowDesc           => 'Rojo + toques amarillos';
  @override String get apNothingActiveBanner     => 'Estilo Nothing OS activo. El acento, el color dinámico y el color de la música están desactivados.';
  @override String get apNothingOledInherent     => 'El modo oscuro de Nothing es negro OLED de forma nativa. No hace falta activar OLED.';
  @override String get apOledTitle               => 'Tema negro OLED';
  @override String get apOledBuiltIntoNothing    => 'Integrado en el modo oscuro de Nothing';
  @override String get apOledPureBlack           => 'Fondos negros puros cuando el modo oscuro está activo';
  @override String get apCustomColorTooltip      => 'Color personalizado';
  @override String get apColorWhenNothingPlays   => 'Color cuando no suena nada';
  @override String get apColorWhenNothingPlaysSub => 'Acento usado cuando no hay ninguna pista sonando';
  @override String get apKeepLastArtworkTitle    => 'Mantener el último color de portada';
  @override String get apKeepLastArtworkSub      => 'Mantener el último color de portada en lugar de restablecerlo cuando no suena nada';
  @override String get apDetailPagesSection      => 'Páginas de detalle';
  @override String get apArtworkColorTheme       => 'Tema de color de la portada';
  @override String get apBeta                    => 'BETA';
  @override String get apArtworkColorThemeSub    => 'Las páginas de detalle adaptan sus colores al color dominante de la portada';
  @override String get apNavBarSection           => 'Barra de navegación';
  @override String get apShowTabLabels           => 'Mostrar etiquetas de pestañas';
  @override String get apShowTabLabelsSub        => 'Mostrar los nombres de las pestañas debajo de los iconos';
  @override String get apInteractionsSection     => 'Interacciones';
  @override String get apHapticFeedbackSub       => 'Vibraciones en toques, selecciones y gestos';
  @override String get acctRemoveTitle          => '¿Eliminar cuenta?';
  @override String acctRemoveBody(String username) => '¿Eliminar @$username de sus cuentas?';
  @override String get acctRemoveAction         => 'Eliminar';
  @override String get acctAlreadyAddedOrFull   => 'Esta cuenta ya está añadida o la lista está llena.';
  @override String acctAddedSuccess(String username) => '@$username añadido correctamente.';
  @override String get acctLogoutAllBody        => 'Se eliminarán todas las cuentas. Volverá a la pantalla de configuración.';
  @override String acctMyAccounts(int count, int max) => 'Mis cuentas ($count/$max)';
  @override String get acctActive               => 'Activa';
  @override String get acctTapSwitchToActivate  => 'Toque "Cambiar" para activar';
  @override String get acctSwitch               => 'Cambiar';
  @override String get acctAddAnAccount         => 'Añadir una cuenta';
  @override String acctSlotsRemaining(int n)    => '$n espacio(s) restante(s)';
  @override String acctMaxReached(int max)      => 'Se alcanzó el máximo de $max cuentas.';
  @override String get acctApiKeyInfo           => 'Cada cuenta puede usar una clave API distinta o la misma. Puede encontrar su clave API en last.fm/api/accounts.';
  @override String get acctLastfmProfileSection => 'Perfil de Last.fm';
  @override String get acctViewOnLastfm         => 'Ver en Last.fm';
  @override String get acctDangerZone           => 'Zona de peligro';
  @override String get acctLogoutAllSub         => 'Eliminar todas las cuentas y volver a la configuración.';
  @override String get acctUsernameRequired     => 'El nombre de usuario es obligatorio.';
  @override String get acctApiKeyRequired       => 'La clave API es obligatoria.';
  @override String get acctUsernameLabel        => 'Usuario de Last.fm';
  @override String get acctSameApiKey           => 'Misma clave API que la cuenta activa';
  @override String get acctApiKeyLabel          => 'Clave API';
  @override String get acctAdd                  => 'Añadir';
  @override String get languageChangeNote => 'El idioma cambia de inmediato en toda la app.';
  @override String get dashTotalScrobblesLabel  => 'Total de scrobbles';
  @override String get dashMemberSinceLabel     => 'Miembro desde';
  @override String get dashCountryLabel         => 'País';
  @override String get dashArtistWeekLabel      => 'Artista #1 (semana)';
  @override String get dashAlbumWeekLabel       => 'Álbum #1 (semana)';
  @override String get dashTrackWeekLabel       => 'Canción #1 (semana)';
  @override String get dashUniqueArtistsLabel   => 'Artistas únicos';
  @override String get dashUniqueTracksLabel    => 'Canciones únicas';
  @override String get dashUniqueAlbumsLabel    => 'Álbumes únicos';
  @override String get dashThisWeekLabel        => 'Esta semana';
  @override String get dashDayUnitShort         => 'd';
  @override String get setupEnableFavorites      => 'Activar favoritos (opcional)';
  @override String get setupFavoritesExplain     => 'Su clave secreta permite marcar (o quitar) canciones como favoritas directamente en Last.fm.';
  @override String get setupSecretKeyLabel       => 'Clave secreta de Last.fm';
  @override String get favConnectInvalidSecret   => 'La clave secreta debe tener 32 caracteres.';
  @override String get favConnectDialogTitle     => 'Autorizar favoritos';
  @override String get favConnectDialogBody      => 'Autorice la app en la página de Last.fm abierta en su navegador y luego vuelva aquí para confirmar.';
  @override String get favConnectDialogConfirm   => 'Ya autoricé';
  @override String get favConnectSuccess         => '¡Favoritos activados con éxito!';
  @override String get favConnectError           => 'No se pudieron activar los favoritos. Revise su clave secreta.';
  @override String get acctApiKeysSection        => 'Claves API';
  @override String get acctSecretKeyLabel        => 'Clave secreta';
  @override String get acctSecretKeyNotSet       => 'No configurada';
  @override String get acctFavoritesExplain      => 'La clave secreta permite marcar (o quitar) canciones como favoritas directamente en Last.fm.';
  @override String get acctConnectFavorites      => 'Activar favoritos';
  @override String get acctDisconnectFavorites   => 'Desactivar favoritos';
  @override String get settingsFavoritesSection    => 'Favoritos';
  @override String get settingsFavoritesSectionSub => 'Muestra el número de favoritos en las estadísticas';
  @override String get settingsFavoritesNeedsKey   => 'Añada su clave secreta en Cuenta para activar';
  @override String get favSectionTitle           => 'Favoritos';
  @override String get commonSeeMore             => 'Ver más';
  @override String get favPageTitle              => 'Mis favoritos';
  @override String get favSearchHint             => 'Buscar una canción o artista';
  @override String get favEmpty                  => 'Aún no hay favoritos.';
  @override String get settingsLovedBadgeTitle => 'Insignia de corazón discreta';
  @override String get settingsLovedBadgeSub   => 'Muestra un pequeño corazón en las canciones favoritas en reproducciones recientes, historial y búsqueda';
  @override String get favSortRecent   => 'Recientes';
  @override String get favSortOldest   => 'Antiguos';
  @override String get favSortArtistAz => 'Artista A-Z';
  @override String get favSortTitleAz  => 'Título A-Z';
  @override String get favFolderSortCustom => 'Manual';
  @override String get favFoldersAll => 'Todos';
  @override String get favFolderNew => 'Nueva carpeta';
  @override String get favFolderNamePlaceholder => 'Nombre de la carpeta';
  @override String get favFolderCustomEmojiTitle => 'Elija un emoji';
  @override String get favFolderCustomEmojiHelper => 'Solo un emoji, sin texto.';
  @override String get favFolderDescPlaceholder => 'Descripción (opcional)';
  @override String get favFolderRecentlyPlayed => 'Escuchado recientemente';
  @override String get favFolderCreate => 'Crear';
  @override String get favFolderEdit => 'Editar carpeta';
  @override String get favFolderDelete => 'Eliminar';
  @override String get favFolderDeleteConfirm => '¿Eliminar esta carpeta? Las canciones dejarán de estar organizadas en ella.';
  @override String get favFolderAssignTitle => 'Añadir a una carpeta';
  @override String get favFolderEmoji => 'Emoji';
  @override String get favFolderColor => 'Color';
  @override String get favFolderSave => 'Guardar';
  @override String get favFolderEmpty => 'No hay canciones en esta carpeta';
  @override String get rankingsWholeYear       => 'Todo el año';
  @override String get chartsExportGeneratedOn => 'generado el';
  @override String get faqQ1 => '¿LastStats hace scrobble de mi música?';
  @override String get faqA1 => 'No. LastStats es una aplicación de visualización: muestra los scrobbles ya registrados en su cuenta de Last.fm, pero no registra ninguno por sí misma.\n\nPara hacer scrobble automáticamente de su música, use una app dedicada como Pano Scrobbler (disponible en Android).';
  @override String get faqQ2 => '¿Está prevista una versión para iOS?';
  @override String get faqA2 => 'No. Por ahora no hay una versión para iOS prevista.';
  @override String get faqQ3 => '¿La app funciona en macOS u otras plataformas?';
  @override String get faqA3 => 'LastStats se desarrolla y prueba en Android. El funcionamiento en otras plataformas (macOS, Windows, Linux…) no está verificado, pueden producirse errores o comportamientos inesperados.';
  @override String get faqQ4 => '¿LastStats es de código abierto?';
  @override String get faqA4 => '¡Sí! El código fuente está disponible libremente en GitHub. El proyecto es independiente, hecho con pasión por SanoBld. Puede contribuir, reportar errores o simplemente dejar una estrella ⭐.';
  @override String get faqQ5 => '¿Dónde se almacenan mis datos?';
  @override String get faqA5 => 'Solo en su dispositivo. LastStats no tiene servidor: sus scrobbles se guardan en caché localmente para un acceso rápido, y sus credenciales de Last.fm también se almacenan localmente. No se envía nada excepto a la API oficial de Last.fm.';
  @override String get faqQ6 => '¿Cómo activo los favoritos?';
  @override String get faqA6 => 'Vaya a Ajustes > Cuenta e introduzca su clave secreta de Last.fm. Una vez conectada, podrá marcar canciones como favoritas directamente desde la app.';
  @override String get faqQ7 => '\u00bfQu\u00e9 es un \'scrobble\'?';
  @override String get faqA7 => 'Un scrobble es una canci\u00f3n registrada como escuchada en su cuenta de Last.fm; es el t\u00e9rmino propio de Last.fm para \'una escucha contada\'. Todos sus totales (artistas top, estad\u00edsticas, etc.) se basan en ello.';
  @override String get faqQ8 => '\u00bfC\u00f3mo funcionan los niveles y los logros?';
  @override String get faqA8 => 'Su nivel de cuenta crece con su total de scrobbles (no hay nivel m\u00e1ximo). Las tarjetas tambi\u00e9n muestran un borde (bronce \u2192 iridiscente) seg\u00fan las veces que se ha escuchado ese artista/canci\u00f3n/\u00e1lbum. Todo se calcula autom\u00e1ticamente a partir de estad\u00edsticas ya guardadas en cach\u00e9, sin llamadas de red adicionales.';
  @override String get faqQ9 => '¿Cómo funciona el modo de ahorro de energía?';
  @override String get faqA9 => 'El modo de ahorro de energía espacia las sincronizaciones automáticas para ahorrar batería. Puede estar siempre activo, seguir el modo de ahorro del teléfono o activarse por debajo de un nivel de batería que elijas, desde Ajustes > General.';
  @override String get faqQ10 => '¿Cómo hago una copia de seguridad o la restauro?';
  @override String get faqA10 => 'Vaya a Ajustes > Copia de seguridad. Puede exportar un archivo de copia (con o sin su clave de Last.fm) y volver a importarlo más tarde o en otro dispositivo.';
  @override String get faqQ11 => '¿Funciona la app sin conexión?';
  @override String get faqA11 => 'Sí, hasta cierto punto. Las estadísticas ya cargadas siguen disponibles sin conexión gracias a la caché local, pero se necesita conexión para obtener nuevos scrobbles.';
  @override String get faqQ12 => '¿Puedo cambiar de cuenta de Last.fm?';
  @override String get faqA12 => 'Sí. Desde Ajustes > Cuenta, cierre sesión y vuelva a iniciarla con otro nombre de usuario. La caché local se reinicia automáticamente para evitar mezclar datos.';
  @override String get faqQ13 => '¿Cómo configuro las notificaciones?';
  @override String get faqA13 => 'Desde Ajustes > Notificaciones, puede activar los avisos de sincronización completada, elegir su frecuencia o desactivarlos por completo.';
  @override String get faqQ14 => 'Faltan imágenes o cargan sin fin. ¿Qué hago?';
  @override String get faqA14 => 'Vacía la caché en la app (Ajustes > Caché) y luego en Android (Ajustes > Aplicaciones > LastStats > Almacenamiento > Borrar caché). Si siguen faltando imágenes, haz una copia de seguridad (Ajustes > Copia de seguridad), desinstala y reinstala la app y restaura la copia.';
  @override String get settingsPlatformDisabledByShowAll => 'Desactivado: ya se muestran todos los enlaces.';
  @override String get commonInDevelopment => 'En desarrollo';
  @override String get commonSeeLess => 'Ver menos';
  @override String get commonShare => 'Compartir';
  @override String get newsCustomDate => 'Fecha personalizada';
  @override String get aboutShortcuts => 'Atajos de teclado';
  @override String get aboutShortcutsSub => 'Disponibles en PC / pantalla grande';
  @override String get shortcutSwitchTabs => 'Cambiar de pestaña';
  @override String get shortcutSearch => 'Buscar';
  @override String get shortcutClose => 'Cerrar una ficha';
  @override String get shortcutRefresh => 'Actualizar';
  @override String get aboutDiscord => 'Unirse al Discord';
  @override String get aboutDiscordSub => 'Chat, sugerencias y anuncios en directo';
  @override String get achvTitle => 'Logros';
  @override String achvUnlocked(int unlocked, int total) => '$unlocked / $total desbloqueados';
  @override String get achvCatListening => 'Escucha';
  @override String get achvCatArtists => 'Artistas';
  @override String get achvCatAlbums => 'Álbumes';
  @override String get achvCatLoyalty => 'Fidelidad';
  @override String get achvDescListening => 'Total de canciones escuchadas (scrobbles), todos los artistas.';
  @override String get achvDescArtists => 'Número de artistas distintos escuchados al menos una vez.';
  @override String get achvDescAlbums => 'Número de álbumes distintos escuchados al menos una vez.';
  @override String get achvDescLoyalty => 'Antigüedad de la cuenta de Last.fm.';
  @override String get achvCatTracks => 'Canciones';
  @override String get achvDescTracks => 'Número de canciones distintas escuchadas.';
  @override String get achvCatPace => 'Ritmo';
  @override String get achvDescPace => 'Promedio de scrobbles por semana.';
  @override String get achvCatStreak => 'Racha';
  @override String get achvDescStreak => 'La racha más larga de días consecutivos con al menos una escucha.';
  @override String get achvCatMarathon => 'Maratón';
  @override String get achvDescMarathon => 'El mayor número de escuchas en un solo día.';
  @override String get achvCatSocial => 'Social';
  @override String get achvDescSocial => 'El número de amigos o perfiles añadidos.';
  @override String get achvCatComparisons => 'Comparaciones';
  @override String get achvDescComparisons => 'El número de comparaciones de gustos musicales realizadas.';
  @override String get achvUnlockedBadge => 'Desbloqueado';
  @override String get achvLockedBadge => 'Bloqueado';
  @override String get dashRecap => 'Resumen';
  @override String get recapDay => 'Hoy';
  @override String get recapWeek => 'Esta semana';
  @override String get recapMonth => 'Este mes';
  @override String get recapScrobbles => 'escuchas';
  @override String get recapArtists => 'Artistas';
  @override String get recapTracks => 'Canciones';
  @override String get recapTopArtist => 'Artista top';
  @override String get recapTopTrack => 'Canción top';
  @override String get recapTopAlbum => 'Álbum top';
  @override String get recapAvgDay => 'Prom/día';
  @override String get recapNoData => 'Sin escuchas en este período.';
  @override String get recapSeeFull => 'Ver resumen completo';
  @override String get recapTop10 => 'Top 10';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => 'El filtro más útil primero';
  @override String get discoverSmartSub => 'Según la hora, el día y lo que más usa';
  @override String get discoverForYou => 'Para usted';
  @override String get discoverGlobalTrends => 'Tendencias globales';
  @override String get discoverSrcForyou => 'Su mix';
  @override String get discoverSrcOnthisday => 'Un día como hoy';
  @override String get discoverSrcFresh => 'Este mes';
  @override String get discoverSrcGenre => 'Sus géneros';
  @override String get discoverSrcDeeper => 'Joyas ocultas';
  @override String get discoverSrcForgotten => 'Olvidadas';
  @override String get discoverSrcAlbums => 'Álbumes';
  @override String get discoverSrcCountry => 'Su país';
  @override String get discoverTracks => 'Canciones';
  @override String get discoverArtists => 'Artistas';
  @override String get discoverWeek => 'semana';
  @override String get discoverMonth => 'mes';
  @override String get discoverYear => 'año';
  @override String get discoverNothing => 'Aún no hay nada que mostrar';
  @override String discoverLike(String names) => 'Como $names';
  @override String get dashReorderSections => 'Cambiar el orden de las secciones';
  @override String get dashInfiniteTitle => 'Desplazamiento infinito';
  @override String get dashInfiniteSub => 'Descubrir se repite y sigue sugiriendo más';
  @override String get dashDiscoverTitle => 'Descubrir';
  @override String get dashDiscoverSub => 'Ideas de música para deslizar';
  @override String get dashSortButton => 'Ordenar';
  @override String get dashSortDone => 'Listo';
  @override String get dashSortHint => 'Arrastre para cambiar el orden';
  @override String get dashSortSmartNote => 'El orden inteligente está activado, así que puede cambiar este orden según el momento.';
  @override String get dashSeparateRow => 'En su propia fila';
  @override String dashFiltersOf(String group) => 'Filtros de «$group»';
  @override String get apShapeSingle => 'Una sola forma';
  @override String get mvSource => 'Fuente del vídeo';
  @override String get mvSrcAuto => 'Auto (Apple Music y luego YouTube)';
  @override String get mvSrcApple => 'Solo Apple Music';
  @override String get mvSrcYt => 'Solo YouTube (canciones)';
  @override String get mvQualityT => 'Calidad del vídeo';
  @override String get mvQAuto => 'Auto';
  @override String get mvQLow => 'Ahorro (360p)';
  @override String get mvTypesT => 'Mostrar vídeo para';
  @override String get mvTracks => 'Canciones';
  @override String get mvAlbums => 'Álbumes';
  @override String get mvArtists => 'Artistas';
  @override String get mvModeT => 'Modo';
  @override String get mvModeBest => 'Recomendado';
  @override String get mvModeSaver => 'Ahorro';
  @override String get mvModeMax => 'Calidad máxima';
  @override String get mvModeCustom => 'Personalizado';
  @override String get mvSrcYtFirst => 'YouTube y luego Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => 'Servicios usados, cuotas y consumo';
  @override String get apiSumToday => 'Solicitudes hoy';
  @override String get apiSumErrors => 'Errores';
  @override String get apiSumLimited => 'Limitadas';
  @override String get apiIntro => 'Los contadores solo cubren este dispositivo. Los proveedores aplican sus límites por dirección IP, así que otras apps de la misma red también cuentan. La app reduce o omite solicitudes automáticamente para respetarlos.';
  @override String get apiCatListening => 'Datos de escucha';
  @override String get apiCatMetadata => 'Metadatos musicales';
  @override String get apiCatArtwork => 'Carátulas';
  @override String get apiCatLyrics => 'Letras';
  @override String get apiCatTranslate => 'Traducción';
  @override String get apiCatUpdates => 'Actualizaciones y novedades';
  @override String get apiCatOther => 'Descargas de imágenes';
  @override String get apiStatusIdle => 'Aún sin usar';
  @override String get apiStatusOk => 'OK';
  @override String get apiStatusNear => 'Cerca del límite';
  @override String get apiStatusPaused => 'En pausa';
  @override String get apiProviderLimit => 'Límite del proveedor';
  @override String get apiNoLimit => 'Ninguno publicado';
  @override String get apiAppCeiling => 'Tope de la app';
  @override String apiLimitPer(int n, String win) => '$n solicitudes / $win';
  @override String get apiWinSecond => 'segundo';
  @override String get apiWinMinute => 'minuto';
  @override String get apiWinHour => 'hora';
  @override String apiWinSeconds(int s) => '$s segundos';
  @override String get apiWindowUsage => 'Ventana actual';
  @override String get apiRemaining => 'Restantes';
  @override String apiResetsIn(String t) => 'Se reinicia en $t';
  @override String apiPausedFor(String t) => 'En pausa durante $t tras una respuesta de límite alcanzado';
  @override String get apiToday => 'Hoy';
  @override String get apiLastHour => 'Última hora';
  @override String get apiTotal => 'Total';
  @override String get apiRateLimited => 'Respuestas de límite alcanzado';
  @override String get apiSkipped => 'Omitidas por la app';
  @override String get apiLastCall => 'Última llamada';
  @override String get apiNever => 'Nunca';
  @override String get apiNoKey => 'No requiere clave API';
  @override String get apiSharedKey => 'Clave de prueba pública compartida (plan gratuito)';
  @override String get apiUnofficial => 'Punto de acceso no oficial: sin cuota garantizada, puede cambiar o bloquearse sin aviso.';
  @override String get apiKeyInUse => 'Clave en uso';
  @override String get apiOwnKey => 'Tu propia clave de Last.fm';
  @override String apiBuiltinKey(int n, int total) => 'Clave integrada $n de $total';
  @override String get apiBackupOn => 'Clave de respaldo: activada';
  @override String get apiBackupOff => 'Clave de respaldo: desactivada';
  @override String get apiPerKey => 'Solicitudes por clave (hoy / total)';
  @override String get apiLastfmNote => 'Last.fm no publica ninguna cifra: devuelve el error 29 cuando una IP envía demasiadas solicitudes, y sus términos prohíben eludirlo. Unas 5 solicitudes por segundo por IP es la pauta habitual; la app se mantiene por debajo de 4.';
  @override String get apiStorageTitle => 'Datos de Last.fm almacenados';
  @override String apiStorageValue(String used, String cap) => '$used de $cap permitidos';
  @override String get apiStorageOver => 'Supera el límite de 100 MB fijado por los términos de la API de Last.fm. Borra el historial de scrobbles en Almacenamiento para cumplirlo.';
  @override String get apiReset => 'Restablecer contadores';
  @override String get apiLimiter => 'Limitar solicitudes';
  @override String get apiLimiterSub => 'Ralentiza las solicitudes para respetar los límites de las API. Desactivado = más rápido, sin esperas.';
  @override String get apiResetBody => 'Todos los contadores de solicitudes volverán a cero.';
  @override String get apiResetDone => 'Contadores restablecidos';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (es) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxEs = {
  'st_notif_on': 'Notificaciones activadas',
  'st_notif_off': 'Notificaciones desactivadas',
  'st_notif_count': '{n} tipos activos',
  'st_notif_perm': 'Se necesita el permiso del sistema',
  'st_notif_none': 'Ningún tipo de notificación elegido',
  'st_sync_on': 'Sincronización automática activada',
  'st_sync_off': 'Sincronización automática desactivada',
  'st_sync_on_s': 'Sus datos se actualizan solos.',
  'st_sync_off_s': 'Los datos solo se actualizan cuando lo pide.',
  'st_bkp_on': 'Copia de seguridad automática activada',
  'st_bkp_off': 'Copia de seguridad automática desactivada',
  'st_bkp_on_s': 'Sus ajustes se guardan automáticamente.',
  'st_bkp_off_s': 'Actívela para no perder nunca sus ajustes.',
  'st_bkp_next': 'Próxima copia: {d}',
  'cmp_breakdown': 'Lo que les une',
  'cmp_by_artists': 'Artistas',
  'cmp_by_genres': 'Géneros',
  'cmp_by_tracks': 'Canciones',
  'cmp_by_albums': 'Álbumes',
  'eco_on': 'Ahorro de energía activado',
  'eco_off': 'Ahorro de energía desactivado',
  'eco_why_manual': 'Siempre activado, por usted',
  'eco_why_system': 'El ahorro de batería de su dispositivo está activado',
  'eco_why_battery': 'La batería está al {n} %',
  'eco_off_hint': 'Elija abajo cuándo activarlo',
  'eco_trig': 'Cuándo activarlo',
  'eco_sys_t': 'Cuando el ahorro de batería del dispositivo esté activado',
  'eco_sys_s': 'Sigue el modo de ahorro de energía integrado del teléfono y se desactiva con él.',
  'eco_sys_na': 'No disponible en este dispositivo.',
  'eco_chg': 'Qué cambia',
  'eco_chg1': 'El paralaje al mover el móvil se desactiva',
  'eco_chg2': 'La frecuencia de la pantalla se limita a unos 60 Hz',
  'eco_chg3': 'Las actualizaciones en segundo plano son menos frecuentes',
  'eco_chg4': 'Las carátulas animadas y el brillo de las insignias se pausan',
  'eco_chg_note': 'Todo lo demás mantiene la calidad completa: imágenes, exportaciones y tarjetas para compartir.',
  'lib_section': 'Biblioteca',
  'lib_merge_t': 'Unir versiones de una misma canción',
  'lib_merge_s': 'Remasters, sencillos, (feat. …) y ediciones deluxe cuentan como una sola canción o álbum y sus reproducciones se suman. Los remixes, directos e instrumentales siguen separados.',
  'lib_split_t': 'Separar colaboraciones',
  'lib_split_s': '«Gims & Damso» cuenta para Gims y para Damso en lugar de ser un artista aparte. Grupos como «Simon & Garfunkel» se mantienen enteros.',
  'lib_step_t': 'Su biblioteca',
  'lib_step_s': 'Elija cómo se agrupan sus reproducciones. Puede cambiarlo cuando quiera en los ajustes.',
  'bk_dash_t': 'Panel e inicio',
  'bk_dash_s': 'Secciones, cabecera, tarjetas de estadísticas, descubrir, pestaña de inicio',
  'bk_notif_t': 'Notificaciones',
  'bk_notif_s': 'Resúmenes, hitos, noticias e insignias',
  'bk_lib_t': 'Opciones de biblioteca',
  'bk_lib_s': 'Unir versiones, separar colaboraciones',
  'bk_prof_t': 'Perfiles favoritos',
  'bk_prof_s': 'Los perfiles de Last.fm que marcó',
  'about_readme_t': 'README y actividad del proyecto',
  'about_readme_s': 'Leer el README, últimos commits, workflows, versión, descargas',
  'fold_show': 'Mostrar ({n})',
  'fold_hide': 'Contraer',
  'readme_sub': 'El proyecto y su actividad',
  'readme_version': 'Versión',
  'readme_downloads': 'Descargas',
  'readme_stars': 'Estrellas',
  'readme_license': 'Licencia',
  'readme_commits': 'Últimos commits',
  'readme_workflows': 'Últimos workflows',
  'readme_retry': 'Reintentar',
  'readme_github': 'Abrir en GitHub',
  'readme_failed': 'No se pudo cargar (sin conexión o límite de GitHub alcanzado).',
  'ago_min': 'hace {n} min',
  'ago_h': 'hace {n} h',
  'ago_d': 'hace {n} d',
  'load_restored': '{n} scrobbles restaurados',
  'load_ready': 'Listo para importar',
  'load_connecting': 'Conectando con Last.fm…',
  'load_done': 'Importación completada',
  'load_backup_note': 'Copia de seguridad detectada: solo se comprobarán los scrobbles más recientes.',
  'dash_nowplay': 'Reproduciendo ahora',
  'dash_stats': 'Estadísticas',
  'dash_recent': 'Reproducciones recientes',
  'dash_discover': 'Descubrir',
  'dash_friends': 'Amigos',
  'dash_chart': 'Gráfico del panel',
  'dash_calendar': 'Calendario',
  'dash_monthly': 'Mensual',
  'cache_video_t': 'Portadas animadas (Apple Music)',
  'cache_video_s': 'Memoria de vídeo en uso: {mem} · {players} reproductor(es) activo(s) · {links} enlace(s) en caché',
  'cache_video_short': 'Portadas animadas',
  'cache_video_cleared': 'Memoria de vídeo liberada',
  'cache_memory_section': 'Memoria',
  'cache_storage_section': 'Almacenamiento',
  'lvl': 'Nivel {n}',
  'lvl_history': 'Historial de niveles',
  'set_living_t': 'Portadas animadas',
  'set_living_s': 'Zoom suave y efecto de profundidad en las imágenes',
  'set_motion_t': 'Portadas en vídeo',
  'set_motion_s': 'Reproduce la portada animada cuando existe',
  'set_achv_t': 'Logros y niveles',
  'set_achv_s': 'Niveles, insignias y nivel de cuenta',
  'cache_img_limit_t': 'Límite de caché de fotos',
  'cache_img_limit_s': 'Portadas, fotos de artistas y avatares. Se borran primero las más antiguas.',
  'cache_vid_limit_t': 'Límite de caché de vídeo',
  'cache_vid_limit_s': 'Portadas animadas de Apple Music guardadas en disco para verlas sin conexión (Android).',
  'cache_video_off': 'Desactivado',
  'cache_vid_disk_t': 'Vídeos de Apple Music',
  'cache_vid_disk_s': '{size} · Portadas animadas guardadas',
  'cache_no_limit_note': 'Los scrobbles y los datos de la API nunca se limitan.',
  'key_internal_use': 'Usar la clave integrada de la app',
  'key_internal_help': 'Opción de respaldo: esta clave se comparte entre usuarios. Puede alcanzar su límite o dejar de funcionar y algunas funciones podrían fallar. Use su propia clave siempre que pueda.',
  'key_internal_active': 'Clave integrada de la app',
  'key_fallback_title': 'Clave integrada como respaldo',
  'key_fallback_sub': 'Prueba su clave primero y la integrada si falla',
  'ui_play_preview': 'Reproducir vista previa',
  'ntf_test_title': '🔔 Notificación de prueba',
  'ntf_test_body': '¡Las notificaciones de LastStats funcionan!',
  'ui_not_enough_data_yet_sy': 'Aún no hay suficientes datos: sincronice su historial completo en los ajustes.',
  'ui_level': 'Nivel {level}',
  'ui_fetching': 'Obteniendo {currentYea}… ({yearIndex}/{totalYears})',
  'ui_which_chart': '¿Qué gráfico?',
  'ui_which_period': '¿Qué período?',
  'ui_all_time': 'Todo el tiempo',
  'ui_exporting': 'Exportando…',
  'ui_chart_not_available_fo': 'Gráfico no disponible para este período',
  'ui_could_not_generate_the': 'No se pudo generar la imagen',
  'ui_error': 'Error',
  'ui_loading_history': 'Cargando historial{yearLabel}… {pct} %',
  'ui_charts_will_be_more_ac': 'Los gráficos serán más precisos una vez cargado.',
  'ui_load_the_full_history_': 'Cargue el historial completo para acceder a todos los años.',
  'ui_load': 'Cargar',
  'ui_based_on_scrobbles_all': 'Basado en {v_hourlyCou} scrobbles (todos los años)',
  'ui_all_available_years': 'Todos los años disponibles',
  'ui_based_on_scrobbles_fro': 'Basado en {v_hourlyCou} scrobbles de {v_selectedY}',
  'ui_based_on_recent_scrobb': 'Basado en {v_hourlyCou} scrobbles recientes',
  'ui_analysing_your_last_20': 'Analizando sus últimos ~200 scrobbles',
  'ui_all_time_loading': 'Todo el tiempo (datos de {v_selectedY} cargando)',
  'ui_all_time_2': 'Todo el tiempo',
  'ui_export_a_chart': 'Exportar un gráfico',
  'ui_scrobble_progression': 'Progresión de scrobbles',
  'ui_your_musical_genres': 'Sus géneros musicales',
  'ui_based_on_your_top_arti': 'Basado en sus artistas favoritos (todo el tiempo)',
  'ui_listening_habits': 'Hábitos de escucha',
  'ui_album_distribution': 'Distribución por álbum',
  'ui_listening_calendar': 'Calendario de escucha',
  'ui_daily_activity_to': 'Actividad diaria — {first} a {last}',
  'ui_daily_activity_all_yea': 'Actividad diaria — todos los años',
  'ui_daily_activity': 'Actividad diaria — {v_selectedY}',
  'ui_load_history_to_see': 'Cargue el historial para ver {v_selectedY}',
  'ui_daily_activity_last_12': 'Actividad diaria — últimos 12 meses',
  'ui_all_years': 'todos los años',
  'ui_listening_streaks': 'Rachas de escucha',
  'ui_total': 'Total',
  'ui_avg_mo': 'Prom./mes',
  'ui_best_month': 'Mejor mes',
  'ui_hourly_distribution': 'Distribución horaria',
  'ui_activity_by_day_of_wee': 'Actividad por día de la semana',
  'ui_current_streak': 'Racha actual',
  'ui_d': 'd',
  'ui_best_streak': 'Mejor racha',
  'ui_best_streak_started_on': 'Mejor racha desde el {bestStart}',
  'ui_no_data_for_this_perio': 'Sin datos para este período',
  'ui_load_history_to_displa': 'Cargue el historial para mostrar {what}',
  'ui_less': 'Menos',
  'ui_more': 'Más',
  'ui_scan_a_profile': 'Escanear un perfil',
  'ui_lvl': 'Niv. {level}',
  'ui_qr_code': '¿Código QR?',
  'ui_add_a_qr_code_to_the_s': '¿Añadir un código QR a la imagen compartida para que quien la vea pueda escanear su perfil?',
  'ui_no_qr': 'Sin QR',
  'ui_to_the_app': 'A la app',
  'ui_to_last_fm': 'A Last.fm',
  'ui_compare_music_taste': 'Comparar gustos musicales',
  'ui_syncing_full_library': 'Sincronizando datos…',
  'ui_see_more': 'Ver más',
  'ui_no_achievements_unlock': 'Aún no ha desbloqueado ningún logro',
  'ui_no_animated_cover_for_': 'No hay portada animada para este álbum',
  'ui_source': 'Fuente: {source}',
  'ui_view_on_last_fm': 'Ver en Last.fm',
  'ui_original_text_last_fm_': 'Texto original: Last.fm — Traducción: Google Translate',
  'ui_source_last_fm': 'Fuente: Last.fm',
  'ui_dark': 'Oscuro',
  'ui_light': 'Claro',
  'ui_system': 'Sistema',
  'ui_colored_widgets': 'Widgets con color',
  'ui_tint_home_screen_widge': 'Aplica el color de acento a los widgets',
  'ui_search_settings': 'Buscar un ajuste…',
  'ui_no_settings_found': 'No se encontraron ajustes',
  'ui_all': 'Todas',
  'ui_battery_saver': 'Ahorro de batería',
  'ui_save_battery_fewer_eff': 'Ahorra batería, menos efectos',
  'ui_musical_soulmates': 'Almas gemelas musicales',
  'ui_great_compatibility': 'Muy buena compatibilidad',
  'ui_some_common_ground': 'Algunos puntos en común',
  'ui_fairly_different_taste': 'Gustos bastante diferentes',
  'ui_worlds_apart_musically': 'Universos musicales opuestos',
  'ui_this_is_your_own_profi': '¡Este es su propio perfil!',
  'ui_artists_from_your_hist': '{uniqueArti} artistas de su historial · biblioteca completa de {targetUser}',
  'ui_artists_from_your_hist_2': '{uniqueArti} artistas de su historial · top 200 de {targetUser}',
  'ui_full_library_api': 'Biblioteca completa (API)',
  'ui_top_200_artists_tracks': 'Top 200 artistas y canciones (API)',
  'ui_could_not_work_out_the': 'No se pudo calcular la compatibilidad.',
  'ui_music_compatibility': 'Compatibilidad musical',
  'ui_analyzing_musical_tast': 'Analizando gustos musicales…',
  'ui_artist': '{v_totalArti} artista{v_totalArti2}',
  'ui_track': '{v_totalTrac} canción{v_totalTrac2}',
  'ui_album': '{v_totalAlbu} álbum{v_totalAlbu2}',
  'ui_shared_tracks': 'Canciones en común',
  'ui_shared_artists': 'Artistas en común',
  'ui_no_shared_artists_foun': 'No se encontraron artistas en común.',
  'ui_shared_albums': 'Álbumes en común',
  'ui_play_count_unavailable': 'Recuento de reproducciones no disponible para uno de los dos.',
  'ui_you_listen_to_this_x_m': 'Escucha esto {x}x más que {theirUsern}.',
  'ui_listens_to_this_x_more': '{theirUsern} escucha esto {x}x más que usted.',
  'ui_you_both_listen_to_thi': 'Ambos escuchan esto casi por igual.',
  'ui_plays': '{plays} reproducciones',
  'ui_compatibility': 'compatibilidad',
  'ui_you_both_love': 'A AMBOS LES ENCANTA',
  'ui_shared_top_artist': 'ARTISTA FAVORITO EN COMÚN',
  'ui_achievements': 'Logros',
  'ui_qr_not_recognized_not_': 'QR no reconocido: no es un perfil de LastStats/Last.fm',
  'ui_scan_a_profile_s_qr_co': 'Escanee el código QR de un perfil',
  'ui_favorites': 'Favoritos',
  'ui_advanced_youtube_music': 'Cliente avanzado de YouTube Music.',
  'ui_syncs_the_glyphs_of_no': 'Sincroniza los Glyphs de los Nothing phones con la música.',
  'ui_sources': 'Fuentes',
  'ui_official_flutter_docs_': 'Documentación oficial de Flutter.',
  'ui_official_material_3_gu': 'Guía oficial de Material 3 para Flutter.',
  'ui_flutter_api_reference_': 'Referencia de la API de Flutter para Material 3.',
  'ui_official_flutter_packa': 'Paquete oficial de Flutter para layouts adaptativos.',
  'ui_android_widgets': 'Widgets de Android',
  'ui_applies_the_accent_col': 'Aplica el color de acento al fondo de los widgets de la pantalla de inicio. Desactivado: blanco o negro puro.',
  'ui_turns_off_tilt_paralla': 'Desactiva el paralaje al mover el móvil, limita la frecuencia de actualización de la pantalla y ralentiza las actualizaciones en segundo plano; todo lo demás mantiene la calidad completa (imágenes, exportaciones, tarjetas para compartir).',
  'ui_always_on': 'Siempre activado',
  'ui_force_eco_mode_on_rega': 'Fuerza el modo ahorro, sea cual sea el nivel de batería.',
  'ui_auto_activate': 'Activación automática',
  'ui_turn_on_below_a_batter': 'Activar por debajo de un % de batería',
  'ui_switches_on_by_itself_': 'Se activa sola cuando la batería baja al nivel indicado abajo.',
  'ui_threshold': 'Umbral',
  'ui_choose_the_tab_display': 'Elija la pestaña que se muestra al iniciar la app.',
  'ui_the_selected_tab_will_': 'La pestaña seleccionada aparecerá en el próximo inicio de la app.',
  'ui_friends_sync': 'Sincronización de amigos',
  'ui_sync_frequency': 'Frecuencia de sincronización',
  'ui_daily': 'Cada día',
  'ui_resync_everyone': 'Resincronizar todo',
  'ui_version_history': 'Historial de versiones',
  'ui_could_not_load_release': 'No se pudo cargar el historial.',
  'ui_installed_dev_build_un': 'Instalada: build de desarrollo (versión desconocida)',
  'ui_installed': 'Instalada: {displayVer}',
  'ui_search_a_version_or_ch': 'Buscar una versión o un changelog…',
  'ui_official': 'Oficial',
  'ui_no_release_matches_you': 'Ninguna versión coincide con su búsqueda.',
  'ui_latest': 'ÚLTIMA',
  'ui_installed_2': 'INSTALADA',
  'ui_no_description': 'Sin descripción.',
  'ui_download': 'Descargar',
  'ui_view_release': 'Ver versión',
  'ui_details': 'Detalles',
  'ui_all_past_releases_chan': 'Todas las versiones anteriores, changelogs y descargas',
  'ui_please_fill_both_field': 'Rellene los dos campos.',
  'ui_api_key_must_be_32_cha': 'La clave API debe tener 32 caracteres.',
  'ui_profile_not_found': 'Perfil no encontrado.',
  'ui_chart_monthly': 'Barras mensuales',
  'ui_chart_cumul': 'Progresión',
  'ui_chart_genres': 'Géneros musicales',
  'ui_chart_habits': 'Hábitos de escucha',
  'ui_chart_artists': 'Distribución de artistas',
  'ui_chart_albums': 'Distribución de álbumes',
  'ui_chart_calendar': 'Calendario de escucha',
  'ui_chart_streaks': 'Rachas de escucha',
  'ui_band_night': 'Noche',
  'ui_band_morning': 'Mañana',
  'ui_band_afternoon': 'Tarde',
  'ui_band_evening': 'Noche',
  'qs_t1_t': 'Modo OLED',
  'qs_t1_s': 'Fondo negro puro',
  'qs_t2_t': 'Modo de ahorro de energía',
  'qs_t2_s': 'Reduce el uso de batería',
  'qs_t3_t': 'Notificaciones de noticias',
  'qs_t3_s': 'Alertas sobre novedades de Last.fm',
  'qs_t4_t': 'Retroalimentación háptica',
  'qs_t4_s': 'Vibraciones al interactuar',
  'qs_t5_t': 'Logros',
  'qs_t5_s': 'Muestra los logros desbloqueados',
  'qs_l1_t': 'Color de acento',
  'qs_l2_t': 'Tema',
  'qs_l3_t': 'Idioma',
  'qs_l4_t': 'Plataforma musical',
  'qs_l5_t': 'Cuenta',
  'qs_l6_t': 'Sincronización',
  'qs_l7_t': 'Caché',
  'img_src_lastfm': 'Fuente: Last.fm',
  'img_src_ytmusic': 'Fuente: YouTube Music',
  'img_src_itunes': 'Fuente: iTunes',
  'img_src_deezer': 'Fuente: Deezer',
  'img_src_audiodb': 'Fuente: TheAudioDB',
  'img_src_musicbrainz': 'Fuente: MusicBrainz',
  'img_src_wikipedia': 'Fuente: Wikipedia',
  'ds_type_artist': 'Artista',
  'ds_type_album': 'Álbum',
  'ds_type_track': 'Canción',
  'pf_1': '👤 Perfil de usuario',
  'pf_2': '🎤 Top artistas — Global',
  'pf_3': '💿 Top álbumes — Global',
  'pf_4': '🎵 Top canciones — Global',
  'pf_5': '⏱️ Reproducciones recientes',
  'pf_6': '🗓️ Esta semana',
  'pf_7': '📅 Este mes',
  'pf_8': '📅 Últimos 3 meses',
  'pf_9': '📅 Últimos 6 meses',
  'pf_10': '📅 Últimos 12 meses',
  'pf_11': '📊 Historial mensual',
  'pf_12': '❤️ Canciones favoritas',
  'pf_13': '🗓️ Top artistas — Semana',
  'pf_14': '🗓️ Álbumes y canciones — Semana',
  'ds_tier_next': '{n} / {next} para el siguiente nivel',
  'ds_tier_max': 'Nivel máximo alcanzado 🎉',
  'ds_tier_first': 'Escuche este tema para desbloquear un primer nivel (desde {n} reproducciones).',
  'sl_import': 'Importando sus datos',
  'sl_done': '¡Importado!',
  'sl_connect': 'Conectando con Last.fm…',
  'sec_chart': 'Gráfico / calendario',
  'stat_avg_day': 'Prom. / día',
  'stat_avg_week': 'Prom. / semana',
  'stat_days_active': 'Días activos',
  'stat_scrobbles_week': 'Scrobbles (semana)',
  'accent_purple': 'Morado',
  'accent_blue': 'Azul',
  'accent_green': 'Verde',
  'accent_red': 'Rojo',
  'accent_orange': 'Naranja',
  'accent_pink': 'Rosa',
  'accent_teal': 'Verde azulado',
  'accent_neutral': 'Neutro',
  'shape_title': 'Formas de imágenes',
  'shape_covers': 'Portadas, artistas y álbumes',
  'shape_mix': 'Mezcla',
  'shape_square': 'Cuadrado',
  'shape_circle': 'Círculo',
  'shape_pick_one': 'O elija una sola forma',
  'friend_listening': 'Escuchando',
  'friend_offline': 'Sin conexión',
  'tier_none': 'Sin nivel',
  'src_title': 'Fuentes',
  'src_scrobbles_meta': 'Scrobbles y metadatos',
  'src_artwork': 'Carátula',
  'src_audio_preview': 'Vista previa de audio',
  'src_video_artwork': 'Carátula en vídeo',
  'tip_love': 'Añadir a favoritos',
  'rail_expand': 'Expandir barra lateral',
  'rail_collapse': 'Contraer barra lateral',
  'a11y_loading': 'Cargando',
  'bk_pick_folder': 'Elegir carpeta de copia automática',
  'bk_save_title': 'Guardar copia de LastStats',
  'bk_pick_file': 'Elegir un archivo de copia de LastStats',
  'nch_milestone_d': 'Avisa cuando alcanzas un hito de scrobbles',
  'nch_grand_d': 'Alertas especiales para grandes hitos (1K, 10K, 100K, 1M…)',
  'nch_recap_d': 'Resúmenes de escucha diarios y semanales',
  'nch_update_d': 'Avisa cuando hay una nueva versión de LastStats',
  'nch_news_d': 'Novedades, correcciones y anuncios sobre LastStats',
  'nch_sync_d': 'Progreso al sincronizar todo tu historial de scrobbles',
  'ntf_grand_1000000': 'Un millón de scrobbles. Es legendario. 🎸',
  'ntf_grand_500000': 'Medio millón de scrobbles. No paras nunca. 🎧',
  'ntf_grand_250000': '{n} scrobbles: la música nunca termina. 🎶',
  'ntf_grand_100000': '¡{n} scrobbles! Eres un verdadero adicto a la música. 🔥',
  'ntf_grand_50000': '{n} scrobbles. Realmente impresionante. 🎵',
  'ntf_grand_25000': '¡{n} scrobbles y sigues a tope!',
  'ntf_grand_10000': '{n} scrobbles: ¡has llegado a cinco cifras! 🎉',
  'ntf_grand_5000': '¡{n} scrobbles y contando!',
  'ntf_grand_1000': 'Tus primeros {n} scrobbles. Empieza el viaje. 🎵',
  'ntf_update_title': 'LastStats {v} disponible',
  'ntf_update_body': 'Hay una nueva versión lista para descargar.',
  'ntf_milestone_title': '🎵 Hito: {n} scrobbles',
  'ntf_milestone_body': 'Acabas de alcanzar {n} scrobbles en Last.fm 🎶',
  'ntf_daily_title': '📊 Resumen del día · {d}',
  'ntf_weekly_title': '📅 Resumen semanal · {w}',
  'ntf_recap_body': '{n} scrobbles · Top: {a}',
  'ntf_n_today': '{n} scrobbles hoy',
  'ntf_n_week': '{n} scrobbles esta semana',
  'ntf_top_artist': 'Artista top: {a}',
  'ntf_update_avail': '🆕 Actualización disponible',
  'ntf_update_ready': 'LastStats {v} está lista: toca para verla.',
  'ntf_sync_title': '🔄 Sincronizando scrobbles…',
  'ntf_sync_done': '✅ Scrobbles sincronizados',
  'ntf_sync_new': '{n} scrobble(s) nuevo(s) añadido(s).',
  'ntf_grand_t': '¡{v} scrobbles!',
  'ntf_year': 'Año {y}',
  'ntf_week': 'Semana {w}',
  'reorder': 'Reordenar',
};
