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
  @override String get cacheScrobblesSubtitle      => 'Todo tu historial de escucha descargado de Last.fm';
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
  @override String get settingsMaterialYouSub    => 'Usa los colores del fondo de pantalla de Android (Android 12 o posterior)';
  @override String get settingsMusicColor        => 'Color desde la música';
  @override String get settingsMusicColorSub     => 'Toma el color de acento de la portada de la canción que suena';
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
  @override String get settingsHeaderFallbackSub => 'Imagen que se muestra en la cabecera cuando no suena música.';
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
  @override String get settingsExportSub         => 'Copia tus ajustes en formato JSON al portapapeles, para guardarlos o compartirlos';
  @override String get settingsImport            => 'Restaurar una copia de seguridad';
  @override String get settingsImportSub         => 'Restaura tus ajustes a partir de un JSON exportado antes';
  @override String get settingsBackupInfo        => 'Incluye: tema, colores, clave API, usuario, cabecera, favoritos. Compatible entre versiones.';
  @override String get settingsUpdates           => 'Actualizaciones';
  @override String get settingsAutoUpdate        => 'Verificación automática';
  @override String get settingsAutoUpdateSub     => 'Busca una versión nueva en segundo plano, una vez al día.';
  @override String get settingsCheckNow          => 'Verificar ahora';
  @override String get settingsUpToDate          => 'Actualizado';
  @override String settingsUpdateAvailable(String v) => 'v$v disponible';
  @override String get settingsCheckFailed       => 'No se pudo comprobar si hay actualizaciones. Revisa tu conexión a internet e inténtalo de nuevo.';
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
  @override String get importEmpty      => 'No hay nada que importar: el campo está vacío. Pega el JSON que exportaste desde LastStats.';
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
  @override String get onboardAppearanceSub    => 'Elija el tema claro u oscuro, el color de acento y el estilo visual de la aplicación.';
  @override String get onboardNotifTitle       => 'Mantente informado';
  @override String get onboardNotifSub         => 'Elija qué notificaciones desea recibir y si el teléfono debe vibrar.';
  @override String get onboardFavTitle         => 'Sus perfiles favoritos';
  @override String get onboardFavSub           => 'Añada amigos de Last.fm para encontrar rápidamente sus perfiles desde la aplicación.';
  @override String get onboardFavHint          => 'Usuario de Last.fm';
  @override String get onboardFavAdd           => 'Añadir';
  @override String get onboardFavEmpty         => 'Sin favoritos por ahora';
  @override String get onboardFavSearchHint    => 'Buscar un perfil de Last.fm…';
  @override String get onboardFavNoResults     => 'No se encontró ningún perfil';
  @override String get onboardFavFriendsTitle  => 'Sus amigos de Last.fm';
  @override String get onboardFavNoFriends     => 'No se encontraron amigos en esta cuenta';
  @override String get onboardFavSelected      => 'Favoritos seleccionados';
  @override String get onboardDashTitle        => 'Su panel';
  @override String get onboardDashSub          => 'Elija qué secciones mostrar en la pantalla de inicio. Podrá cambiarlas más tarde en los ajustes.';
  @override String get onboardStartupTitle     => 'Pantalla de inicio';
  @override String get onboardStartupSub       => 'Elija qué pestaña se abre primero al iniciar la aplicación.';
  @override String get onboardPlatformTitle    => '¿Dónde escucha música?';
  @override String get onboardPlatformSub      => 'Indique dónde escucha música. La aplicación mostrará solo los enlaces útiles en las páginas de canciones, artistas y álbumes.';
  @override String get platformLastfm          => 'Last.fm';
  @override String get platformSpotify         => 'Spotify';
  @override String get platformYtMusic         => 'YouTube Music';
  @override String get platformOther           => 'Otra / mostrar todo';
  @override String get settingsMusicPlatform          => 'Plataforma musical';
  @override String get settingsMusicPlatformSub       => 'Solo muestra los enlaces de tu servicio de música en las páginas de artista, álbum y canción';
  @override String get settingsShowAllPlatformLinks    => 'Mostrar siempre todo';
  @override String get settingsShowAllPlatformLinksSub => 'Ignora el filtro y muestra todos los enlaces (Last.fm, Spotify, YT Music, Web)';
  @override String get onboardUpdatesTitle     => 'Actualizaciones';
  @override String get onboardUpdatesSub       => 'La aplicación comprueba automáticamente si hay una versión nueva disponible.';
  @override String get onboardStyle              => 'Estilo';
  @override String get onboardStyleMaterialYou    => 'Material You';
  @override String get onboardStyleNothing        => 'Nothing OS';
  @override String get onboardPreview             => 'Vista previa';
  @override String get onboardPreviewButton       => 'Botón';
  @override String get onboardPreviewOutline      => 'Botón principal';
  @override String get onboardPreviewText         => 'Texto de ejemplo';
  @override String get onboardPreviewBubble       => 'Burbuja';
  @override String get onboardAccentTint          => 'Tono de acento';
  @override String get onboardNothingRedOnly      => 'Solo rojo';
  @override String get onboardNothingRedYellow    => 'Rojo + amarillo';
  @override String get onboardDisplay             => 'Pantalla';
  @override String get onboardOledTitle           => 'Negro OLED';
  @override String get onboardOledSub             => 'El fondo se vuelve completamente negro en el modo oscuro, lo que ahorra batería en las pantallas OLED.';
  @override String get onboardArtworkColorTitle   => 'Color desde la carátula';
  @override String get onboardArtworkColorSub     => 'El color de acento de la aplicación se adapta automáticamente a la portada de la canción que se está reproduciendo.';
  @override String get onboardNewsTitle           => 'Notificaciones de novedades';
  @override String get onboardNewsSub             => 'Se le avisa cuando se añade una función nueva o se corrige un problema.';
  @override String get onboardNewsBadgeTitle      => 'Punto de novedades';
  @override String get onboardNewsBadgeSub        => 'Aparece un punto en la campana de la pantalla de inicio cuando hay algo nuevo por leer.';
  @override String get onboardHapticTitle         => 'Retroalimentación háptica';
  @override String get onboardHapticSub           => 'El teléfono vibra ligeramente cuando toca los botones y los elementos importantes.';
  @override String get onboardRecaps              => 'Resúmenes';
  @override String get onboardDailyRecapTitle     => 'Resumen diario';
  @override String get onboardDailyRecapSub       => 'Cada día, reciba un resumen de lo que ha escuchado.';
  @override String get onboardWeeklyRecapTitle    => 'Resumen semanal';
  @override String get onboardWeeklyRecapSub      => 'Cada semana, reciba la lista de sus artistas, álbumes y canciones más escuchados.';
  @override String get onboardMilestonesSection   => 'Hitos de scrobbles';
  @override String get onboardMilestonesTitle     => 'Hitos';
  @override String get onboardMilestonesSub       => 'Una notificación le felicita cuando su número de reproducciones llega a una cifra redonda.';
  @override String get onboardGrandMilestonesTitle => 'Grandes hitos';
  @override String get onboardGrandMilestonesSub   => 'Aparece una celebración especial cuando alcanza un número muy grande de reproducciones.';
  @override String get onboardDynamicColorSub      => 'La aplicación usa los colores de su fondo de pantalla. Esta opción está disponible a partir de Android 12.';
  @override String get onboardBetaTitle            => 'Actualizaciones beta';
  @override String get onboardBetaSub              => 'Reciba las versiones de prueba antes que nadie. Pueden contener errores.';

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
  @override String get setupApiKeyPrivacyNote      => 'Su clave se guarda únicamente en este dispositivo y nunca se envía a terceros.';
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
  @override String get dashTopArtistLabel          => 'Artista más escuchado';
  @override String get dashTopTrackLabel           => 'Canción más escuchada';
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
  @override String get syncUpToDateMsg         => 'Historial al día: no hay scrobbles nuevos que descargar';
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
  @override String get aboutAppInfo                => 'Información de la app';
  @override String get aboutScrobbleDownloader     => 'Descargador de scrobbles';
  @override String get aboutScrobbleDownloaderSub  => 'Descarga todo tu historial de scrobbles y guárdalo en un archivo';
  @override String get aboutPoweredBy              => 'Con la ayuda de';
  @override String get aboutImageDisclaimer        => 'Las imágenes de artistas, álbumes y canciones se obtienen automáticamente de estas fuentes y a veces pueden ser incorrectas o no coincidir con el contenido real.';
  @override String get aboutFooter                 => 'Hecho con ❤️ · Sin afiliación con Last.fm';

  @override String updatesPublishedOn(String date) => 'Publicado el $date';
  @override String get updatesCurrentVersion       => 'Versión actual';
  @override String get updatesBetaTitle            => 'Actualizaciones beta';
  @override String get updatesBetaSub              => 'Reciba acceso anticipado a las versiones preliminares';

  @override String get backupWhatsIncluded         => 'Qué incluye';
  @override String get backupDownloadFile          => 'Descargue un archivo .json';
  @override String get backupChooseFile            => 'Elegir un archivo de copia de seguridad';
  @override String get backupFileSaved             => 'Copia de seguridad guardada';
  @override String get backupFileSaveFailed        => 'No se pudo guardar el archivo de copia de seguridad. Comprueba que hay espacio libre y que la app puede escribir en la carpeta, y vuelve a intentarlo.';
  @override String get setupRestoreBackup          => 'Restaurar una copia de seguridad';
  @override String get setupRestoreBackupSub       => 'Recupere su cuenta y sus ajustes desde un archivo de copia de seguridad en formato .json.';
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
  @override String get notifIntervalSubtitle    => 'Recibe un aviso cada vez que sumes un número fijo de scrobbles';
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
  @override String get notifBadgeSubtitle       => 'Muestra un punto en la campana de novedades cuando hay anuncios sin leer';
  @override String get notifTestLabel           => 'Prueba';
  @override String get notifPermissionDisabledTitle => 'Notificaciones desactivadas';
  @override String get notifPermissionDisabledBody  => 'Activa las notificaciones en los ajustes del sistema para que LastStats pueda enviarte resúmenes, hitos y novedades.';
  @override String get notifGrantPermission     => 'Conceder permiso';
  @override String get notifThresholdIntro      => 'Recibirá una notificación especial en cada uno de estos hitos:';
  @override List<String> get notifThresholdMessages => const [
    'Sus primeros 1000 scrobbles. La aventura comienza. 🎵',
    '¡Ha llegado a cinco cifras! 🎉',
    'Es un verdadero adicto a la música. 🔥',
    'Un millón de scrobbles. Eso es legendario. 🎸',
  ];
  @override String get notifIntervalDescription => 'Recibirás un aviso cada vez que alcances X scrobbles nuevos';
  @override String get notifCustomValueLabel    => 'Valor personalizado';
  @override String get notifTimeNotifyAt        => 'Notificar a';
  @override String get notifDayOfWeek           => 'Día de la semana';
  @override List<String> get weekdaysShort => const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  @override List<String> get weekdaysNarrow => const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  @override String get weekAbbrev => 'S';
  @override String get notifSendTest            => 'Enviar una notificación de prueba';
  @override String get notifSentCheckBar        => '¡Revise su barra de notificaciones!';
  @override String get notifMakeSureWorks       => 'Comprueba que las notificaciones funcionan bien en tu teléfono.';
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
  @override String get setupFavoritesExplain     => 'Su clave secreta permite a la aplicación añadir una canción a sus favoritos, o quitarla, directamente en su cuenta de Last.fm.';
  @override String get setupSecretKeyLabel       => 'Clave secreta de Last.fm';
  @override String get favConnectInvalidSecret   => 'La clave secreta debe tener 32 caracteres.';
  @override String get favConnectDialogTitle     => 'Autorizar favoritos';
  @override String get favConnectDialogBody      => 'Autorice la app en la página de Last.fm abierta en su navegador y luego vuelva aquí para confirmar.';
  @override String get favConnectDialogConfirm   => 'Ya autoricé';
  @override String get favConnectSuccess         => '¡Favoritos activados con éxito!';
  @override String get favConnectError           => 'No se pudieron activar los favoritos. Comprueba que tu clave secreta es correcta y que has autorizado LastStats en Last.fm, y vuelve a intentarlo.';
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
  @override String get favEmpty                  => 'Aún no tienes favoritos. Toca el corazón de una canción para añadirla.';
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
  @override String get favFolderEmpty => 'Esta carpeta está vacía. Mantén pulsado el corazón de una canción para añadirla aquí.';
  @override String get rankingsWholeYear       => 'Todo el año';
  @override String get chartsExportGeneratedOn => 'generado el';
  @override String get faqQ1 => '¿LastStats hace scrobble de mi música?';
  @override String get faqA1 => 'No. LastStats es una aplicación de visualización: muestra los scrobbles ya registrados en su cuenta de Last.fm, pero no registra ninguno por sí misma.\n\nPara hacer scrobble automáticamente de su música, use una app dedicada como Pano Scrobbler (disponible en Android).';
  @override String get faqQ3 => '¿La app funciona en macOS u otras plataformas?';
  @override String get faqA3 => 'LastStats se desarrolla y prueba en Android. El funcionamiento en otras plataformas (macOS, Windows, Linux…) no está verificado, pueden producirse errores o comportamientos inesperados.';
  @override String get faqQ4 => '¿LastStats es de código abierto?';
  @override String get faqA4 => '¡Sí! El código fuente está disponible libremente en GitHub. El proyecto es independiente, hecho con pasión por SanoBld. Puede contribuir, reportar errores o simplemente dejar una estrella ⭐.';
  @override String get faqQ5 => '¿Dónde se almacenan mis datos?';
  @override String get faqA5 => 'Solo en su dispositivo. LastStats no tiene servidor: sus scrobbles se guardan en caché localmente para un acceso rápido, y sus credenciales de Last.fm también se almacenan localmente. No se envía nada excepto a la API oficial de Last.fm.';
  @override String get faqQ6 => '¿Cómo activo los favoritos?';
  @override String get faqA6 => 'Vaya a Ajustes > Cuenta e introduzca su clave secreta de Last.fm (la encontrará junto a su clave API en last.fm/api/accounts) y siga los pasos en pantalla. Una vez conectada, podrá marcar canciones como favoritas directamente desde la app. Esta opción no está disponible con la clave integrada de la app.';
  @override String get faqQ7 => '\u00bfQu\u00e9 es un \'scrobble\'?';
  @override String get faqA7 => 'Un scrobble es una canci\u00f3n registrada como escuchada en su cuenta de Last.fm; es el t\u00e9rmino propio de Last.fm para \'una escucha contada\'. Todos sus totales (artistas top, estad\u00edsticas, etc.) se basan en ello.';
  @override String get faqQ8 => '\u00bfC\u00f3mo funcionan los niveles y los logros?';
  @override String get faqA8 => 'Su nivel de cuenta crece con su total de scrobbles (no hay nivel m\u00e1ximo). Las tarjetas tambi\u00e9n muestran un borde (bronce \u2192 iridiscente) seg\u00fan las veces que se ha escuchado ese artista/canci\u00f3n/\u00e1lbum. Todo se calcula autom\u00e1ticamente a partir de estad\u00edsticas ya guardadas en cach\u00e9, sin llamadas de red adicionales.';
  @override String get faqQ9 => '¿Cómo funciona el modo de ahorro de energía?';
  @override String get faqA9 => 'El modo de ahorro de energía reduce la actividad de la app para cuidar la batería: se desactiva el efecto de paralaje al inclinar el móvil, la frecuencia de actualización de pantalla se limita a unos 60 Hz, las actualizaciones en segundo plano son menos frecuentes, y las portadas animadas y el brillo de las insignias se pausan. Las imágenes, las exportaciones y las tarjetas para compartir mantienen la calidad completa.\n\nPuedes dejarlo siempre activado, hacer que siga el ahorro de batería de tu teléfono o que se active por debajo de un nivel de batería que elijas. Lo encontrarás en Ajustes > Ahorro de batería.';
  @override String get faqQ10 => '¿Cómo hago una copia de seguridad o la restauro?';
  @override String get faqA10 => 'Vaya a Ajustes > Copia de seguridad. Puede exportar un archivo de copia, con o sin su clave de Last.fm según prefiera, e importarlo más tarde en este teléfono o en otro dispositivo para recuperar sus ajustes.';
  @override String get faqQ11 => '¿Funciona la app sin conexión?';
  @override String get faqA11 => 'Sí, hasta cierto punto. Las estadísticas ya cargadas siguen disponibles sin conexión gracias a la caché local, pero se necesita conexión para obtener nuevos scrobbles.';
  @override String get faqQ12 => '¿Puedo cambiar de cuenta de Last.fm?';
  @override String get faqA12 => 'Sí, puede guardar hasta 3 cuentas de Last.fm. Desde Ajustes > Cuenta, toque «Añadir una cuenta» y cambie de una a otra cuando quiera. La caché local se reinicia automáticamente al cambiar, para que los datos de dos cuentas nunca se mezclen.';
  @override String get faqQ13 => '¿Cómo configuro las notificaciones?';
  @override String get faqA13 => 'Desde Ajustes > Notificaciones, puede activar un aviso cuando termine una sincronización, elegir con qué frecuencia aparecen los avisos o desactivar las notificaciones por completo si lo prefiere.';
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
  @override String get recapTopArtist => 'Artista';
  @override String get recapTopTrack => 'Canción';
  @override String get recapTopAlbum => 'Álbum';
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
  'eco_sys_na': 'No disponible en este dispositivo (no se detecta un ahorro de batería del sistema).',
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
  'lib_step_s': 'Elija cómo agrupa la aplicación sus reproducciones. Podrá cambiarlo en cualquier momento en los ajustes.',
  'bk_dash_t': 'Panel e inicio',
  'bk_dash_s': 'Secciones, cabecera, tarjetas de estadísticas, descubrir, pestaña de inicio',
  'bk_notif_t': 'Notificaciones',
  'bk_notif_s': 'Resúmenes, hitos, noticias e insignias',
  'bk_lib_t': 'Opciones de biblioteca',
  'bk_lib_s': 'Unir versiones, separar colaboraciones',
  'bk_prof_t': 'Perfiles favoritos',
  'bk_prof_s': 'Los perfiles de Last.fm que marcó',
  'about_legal_t': 'Aviso legal',
  'about_legal_site_t': 'Aviso legal y privacidad',
  'about_legal_site_s': 'Editor, datos tratados, servicios de terceros, tus derechos',
  'about_licenses_t': 'Licencias de código abierto',
  'about_licenses_s': 'Flutter y todos los paquetes usados',
  'about_legal_editor': 'Publicada por Sano Bld, desarrollador independiente. Contáctanos en Discord o en los issues de GitHub.',
  'about_legal_privacy': 'Tus datos se quedan en tu dispositivo y no guardamos ninguna copia. La app contacta directamente con los servicios indicados aquí, y cada uno recibe como mínimo tu dirección IP y la solicitud (por ejemplo, el nombre de un artista). La cámara solo se usa para escanear códigos QR. No está pensada para menores de 15 años sin el consentimiento de un progenitor.',
  'about_legal_marks': 'LastStats es independiente y no está afiliada ni respaldada por Last.fm, Spotify, YouTube, Apple, Deezer, TheAudioDB, MusicBrainz, Wikipedia ni GitHub. Los nombres y logotipos pertenecen a sus propietarios, al igual que las carátulas y los metadatos. Los textos de Wikipedia están bajo licencia CC BY-SA.',
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
  'txt_sec': 'Texto',
  'txt_size': 'Tamaño del texto',
  'txt_font': 'Fuente',
  'txt_font_def': 'Predeterminada (Android)',
  'font_import': 'Importar una fuente',
  'font_import_s': 'Archivo .ttf u .otf (3 MB máx.)',
  'font_remove': 'Eliminar la fuente importada',
  'font_bad': 'No se puede usar esta fuente: el archivo no es válido o supera los 3 MB',
  'qs_l8_t': 'Fuente',
  'art_popular': 'Populares',
  'art_recent': 'Recientes',
  'bio_src_wiki': 'Fuente: Wikipedia',
  'bio_src_wiki_orig': 'Texto original · Wikipedia',
  'dash_motion_t': 'Portada animada en el panel',
  'dash_motion_s': 'Reproduce el vídeo de la canción actual en la tarjeta de reproducción y en la cabecera. Requiere las portadas de vídeo.',
  'onb_cov_t': 'Portadas e imágenes',
  'onb_cov_s': 'Elija la forma de las imágenes y cómo se muestran las portadas.',
  'onb_sync_t': 'Sincronización y batería',
  'onb_sync_s': 'Mantenga sus estadísticas al día sin consumir demasiada batería del teléfono.',
  'onb_autosync_t': 'Sincronización automática',
  'onb_autosync_s': 'La aplicación comprueba con regularidad, en segundo plano, si tiene nuevas reproducciones.',
  'onb_freq': 'Frecuencia de comprobación',
  'onb_every_h': 'Cada {h} horas',
  'onb_every_1h': 'Cada hora',
  'load_backup_note': 'Copia de seguridad detectada: solo se comprobarán los scrobbles más recientes.',
  'dash_nowplay': 'Reproduciendo ahora',
  'dash_stats': 'Estadísticas',
  'dash_recent': 'Reproducciones recientes',
  'dash_discover': 'Descubrir',
  'dash_friends': 'Amigos',
  'dash_chart': 'Gráfico del panel',
  'dash_calendar': 'Calendario',
  'dash_monthly': 'Mensual',
  'cache_video_t': 'Portadas animadas en memoria',
  'cache_video_s': 'Memoria de vídeo en uso: {mem} · {players} reproductor(es) activo(s) · {links} enlace(s) en caché',
  'cache_video_short': 'Portadas animadas',
  'cache_video_cleared': 'Vídeos de portadas animadas liberados de la memoria',
  'cache_memory_section': 'Memoria',
  'cache_storage_section': 'Almacenamiento',
  'lvl': 'Nivel {n}',
  'lvl_history': 'Historial de niveles',
  'set_living_t': 'Portadas animadas',
  'set_living_s': 'Las imágenes se mueven suavemente con un ligero efecto de zoom y profundidad.',
  'set_motion_t': 'Portadas en vídeo',
  'set_motion_s': 'Reproduce la portada animada en vídeo cuando existe para la canción.',
  'set_achv_t': 'Logros y niveles',
  'set_achv_s': 'Siga sus objetivos, sus insignias y el nivel de su cuenta.',
  'cache_img_limit_t': 'Límite de caché de fotos',
  'cache_img_limit_s': 'Portadas, fotos de artistas y avatares. Se borran primero las más antiguas.',
  'cache_vid_limit_t': 'Límite de caché de vídeo',
  'cache_vid_limit_s': 'Portadas animadas guardadas en el dispositivo para verlas sin conexión (Android).',
  'cache_video_off': 'Desactivado',
  'cache_vid_disk_t': 'Portadas animadas en disco',
  'cache_vid_disk_s': '{size} · Portadas animadas guardadas',
  'cache_no_limit_note': 'Los scrobbles y los datos de la API nunca se limitan.',
  'key_internal_use': 'Usar la clave integrada de la app',
  'key_internal_help': 'Opción de respaldo: esta clave se comparte entre usuarios. Puede alcanzar su límite o dejar de funcionar y algunas funciones podrían fallar. Use su propia clave siempre que pueda.',
  'key_internal_active': 'Clave integrada de la app',
  'key_fallback_title': 'Clave integrada como respaldo',
  'key_fallback_sub': 'Se usa primero su clave. Si Last.fm la rechaza, la app lo intenta de nuevo automáticamente con la clave integrada.',
  'key_use_own': 'Usar mi propia clave API',
  'key_change_title': 'Cambiar la clave API',
  'key_change_sub': 'Sustituya su clave por otra, o pase a la clave integrada de la app.',
  'key_change_sub_internal': 'Está usando la clave compartida de la app. Añada su propia clave para no depender de los límites de otros usuarios.',
  'key_change_intro': 'Introduzca una nueva clave API para esta cuenta, o vuelva a la clave integrada de la app. Su nombre de usuario y sus estadísticas no cambian.',
  'key_change_intro_internal': 'Esta cuenta usa ahora la clave integrada de la app. Pegue abajo su propia clave API de Last.fm para sustituirla. Su nombre de usuario y sus estadísticas no cambian.',
  'key_change_hint': 'Una clave API tiene 32 caracteres. Puede crearla o encontrarla en last.fm/api/accounts.',
  'key_change_invalid_len': 'Una clave API debe tener exactamente 32 caracteres. Compruebe que la ha copiado completa.',
  'key_change_same': 'Esta cuenta ya usa esta clave. Introduzca una diferente.',
  'key_change_check_failed': 'Last.fm no ha aceptado esta clave. Compruebe que es correcta y que tiene conexión a Internet, e inténtelo de nuevo.',
  'key_change_favorites_warn': 'Se quitará la conexión de favoritos, porque depende de la clave anterior. Después podrá volver a conectarla con su clave secreta.',
  'key_change_apply': 'Aplicar',
  'key_change_success': 'La clave API se ha actualizado.',
  'key_internal_fav_note': 'Los favoritos necesitan su propia clave API y su clave secreta de Last.fm. Añada su clave arriba para poder activarlos.',
  'faq_q15': '¿Puedo cambiar mi clave API después de iniciar sesión?',
  'faq_a15': 'Sí. Vaya a Ajustes > Cuenta y toque «Cambiar la clave API». Puede sustituir su clave por otra, o añadir la suya si al principio eligió la clave integrada. Sus estadísticas no cambian; solo hay que volver a configurar la conexión de favoritos.',
  'nothing_wip_badge': 'En mejora',
  'nothing_wip_msg': 'El estilo Nothing OS se está mejorando, por lo que no está disponible por ahora. Podrá activarse en una versión futura.',
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
  'ui_chart_not_available_fo': 'Este gráfico no está disponible para el período seleccionado',
  'ui_could_not_generate_the': 'No se pudo generar la imagen. Inténtalo de nuevo.',
  'ui_error': 'Algo salió mal',
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
  'ui_best_streak_started_on': 'Mejor racha iniciada el {bestStart}',
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
  'ui_no_achievements_unlock': 'Aún no has desbloqueado logros. ¡Sigue escuchando para conseguir el primero!',
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
  'ui_no_settings_found': 'Ningún ajuste coincide con tu búsqueda',
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
  'ui_turn_on_below_a_batter': 'Activar el ahorro de energía cuando la batería esté baja',
  'ui_switches_on_by_itself_': 'El ahorro de energía se activa solo cuando el nivel de batería baja. Podrá elegir el nivel exacto más tarde en los ajustes.',
  'ui_threshold': 'Umbral',
  'ui_choose_the_tab_display': 'Elija la pestaña que se muestra al iniciar la app.',
  'ui_the_selected_tab_will_': 'La pestaña seleccionada aparecerá en el próximo inicio de la app.',
  'ui_friends_sync': 'Sincronización de amigos',
  'ui_sync_frequency': 'Frecuencia de sincronización',
  'ui_daily': 'Cada día',
  'ui_resync_everyone': 'Resincronizar todo',
  'ui_version_history': 'Historial de versiones',
  'ui_could_not_load_release': 'No se pudo cargar el historial de versiones. Revisa tu conexión e inténtalo de nuevo.',
  'ui_installed_dev_build_un': 'Instalada: build de desarrollo (versión desconocida)',
  'ui_installed': 'Instalada: {displayVer}',
  'ui_search_a_version_or_ch': 'Buscar una versión o un changelog…',
  'ui_official': 'Oficial',
  'ui_no_release_matches_you': 'Ninguna versión coincide con su búsqueda.',
  'ui_latest': 'ÚLTIMA',
  'ui_installed_2': 'INSTALADA',
  'ui_no_description': 'Esta versión no incluye descripción.',
  'ui_download': 'Descargar',
  'ui_view_release': 'Ver versión',
  'ui_details': 'Detalles',
  'ui_all_past_releases_chan': 'Todas las versiones anteriores, changelogs y descargas',
  'ui_please_fill_both_field': 'Rellena los dos campos para continuar.',
  'ui_api_key_must_be_32_cha': 'La clave API debe tener exactamente 32 caracteres.',
  'ui_profile_not_found': 'Perfil no encontrado. Revisa el nombre de usuario e inténtalo de nuevo.',
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
  'qs_t1_s': 'Fondo negro puro, ahorra energía en pantallas OLED',
  'qs_t2_t': 'Modo de ahorro de energía',
  'qs_t2_s': 'Menos animaciones y actualizaciones en segundo plano para ahorrar batería',
  'qs_t3_t': 'Notificaciones de noticias',
  'qs_t3_s': 'Avisos de novedades, correcciones y anuncios',
  'qs_t4_t': 'Retroalimentación háptica',
  'qs_t4_s': 'Vibraciones breves al tocar, seleccionar o deslizar',
  'qs_t5_t': 'Logros',
  'qs_t5_s': 'Muestra los logros desbloqueados y tu nivel',
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
  'ntf_top_artist': 'Artista más escuchado: {a}',
  'ntf_update_avail': '🆕 Actualización disponible',
  'ntf_update_ready': 'LastStats {v} está lista: toca para verla.',
  'ntf_sync_title': '🔄 Sincronizando scrobbles…',
  'ntf_sync_done': '✅ Scrobbles sincronizados',
  'ntf_sync_new': '{n} scrobble(s) nuevo(s) añadido(s).',
  'ntf_grand_t': '¡{v} scrobbles!',
  'ntf_year': 'Año {y}',
  'ntf_week': 'Semana {w}',
  'reorder': 'Reordenar',
  'sp_login_t': 'Inicio de sesión en Spotify',
  'sp_login_hint': 'Inicie sesión con su correo y su contraseña de Spotify. La ventana se cierra sola al terminar.',
  'sp_risk_note': 'Atención: esta función se basa en llamadas no oficiales de Spotify, no en una API oficial. Spotify puede cambiarla o bloquearla en cualquier momento, puede dejar de funcionar, y su uso puede ir en contra de las condiciones de uso de Spotify, lo que podría provocar restricciones en tu cuenta de Spotify. Úsala bajo tu propia responsabilidad.',
  'sp_t': 'Spotify (Canvas)',
  'sp_on': 'Conectado',
  'sp_off': 'No conectado',
  'sp_off_s': 'Has cerrado sesión en Spotify. Vuelve a iniciarla para obtener las portadas animadas de Canvas.',
  'mv_ytdash_t': 'También en el panel',
  'mv_ytdash_s': 'Usar YouTube para la portada animada de fondo del perfil en el panel (desactivado por defecto)',
  'yr_title': 'Resumen del año',
  'yr_loading': 'Preparando tu resumen…',
  'yr_error': 'No se pudieron cargar tus scrobbles. Comprueba tu conexión.',
  'yr_retry': 'Reintentar',
  'yr_empty': 'No hay scrobbles para {year}.',
  'yr_intro_h': 'Tu {year} en música',
  'yr_scrobbles': 'scrobbles',
  'yr_hours': '≈ {h} horas de música (estimación)',
  'yr_top_artist': 'Tu artista n.º 1',
  'yr_top_artists': 'Top artistas',
  'yr_top_tracks': 'Top canciones',
  'yr_top_albums': 'Top álbumes',
  'yr_plays': '{n} reproducciones',
  'yr_months_h': 'Tu año, mes a mes',
  'yr_months': 'Ene,Feb,Mar,Abr,May,Jun,Jul,Ago,Sep,Oct,Nov,Dic',
  'yr_best_month': 'Mes más activo: {m} ({n} scrobbles)',
  'yr_best_day': 'Día más intenso: {d} con {n} scrobbles',
  'yr_when_h': 'Cuándo escuchas',
  'yr_p_night': 'Ave nocturna',
  'yr_p_morning': 'Madrugador',
  'yr_p_day': 'Oyente de día',
  'yr_p_evening': 'Oyente de tarde-noche',
  'yr_peak': 'Pico hacia las {h}:00 · día favorito: {d}',
  'yr_streak_h': 'Tu constancia',
  'yr_streak': 'días',
  'yr_active': '{n} días activos de {t}',
  'yr_disc_h': 'Descubrimientos',
  'yr_new': 'artistas nuevos descubiertos',
  'yr_unique': '{a} artistas · {t} canciones',
  'yr_card_hours': 'horas (est.)',
  'yr_card_streak': 'mejor racha (días)',
  'yr_friends_h': 'Tú contra tus amigos',
  'yr_rank': 'Eres el n.º {r} de {n}',
  'yr_you': 'Tú',
  'yr_twin_h': 'Tu gemelo musical',
  'yr_twin_s': '{n} de tus artistas favoritos en común',
  'yr_top_track': 'Tu canción n.º 1',
  'yr_top_album': 'Tu álbum n.º 1',
  'sp_need': 'Spotify necesita iniciar sesión: Perfil > Página de conexión.',
  'conn_title': 'Conexiones',
  'conn_btn_t': 'Página de conexión',
  'conn_btn_s': 'Last.fm, Spotify y claves API',
  'conn_sp_desc': 'Se usa para los vídeos de portada (Canvas). Es necesaria una cuenta de Spotify.',
  'conn_connect': 'Conectar',
  'conn_disconnect': 'Desconectar',
  'conn_keys': 'Claves API',
  'conn_manage': 'Gestionar cuenta',
  'conn_test': 'Probar Spotify',
  'conn_testing': 'Probando…',
  'conn_q_note': 'Spotify Canvas tiene una sola calidad. Los ajustes de calidad solo se aplican a Apple Music y YouTube.',
  'conn_lfm_desc': 'Dos métodos: iniciar sesión en el sitio de Last.fm (se usa la clave integrada en la aplicación) o usar su propia clave API.',
  'conn_lfm_web': 'Iniciar sesión con Last.fm',
  'lfm_login_t': 'Inicio de sesión en Last.fm',
  'lfm_login_hint': 'Inicie sesión en el sitio de Last.fm. La aplicación detectará su nombre de usuario y cerrará la ventana.',
  'dg_cookie': 'Cookie de sesión',
  'dg_token': 'Token web',
  'dg_search': 'Búsqueda',
  'dg_ok': 'ok',
  'dg_missing': 'AUSENTE',
  'dg_failed': 'ERROR',
  'dg_found': 'vídeo encontrado',
  'dg_nofound': 'sin vídeo',
  'dg_notpl': 'falta el modelo de búsqueda (inténtelo de nuevo en un momento)',
  'dg_results': 'resultados',
  'lfm_web_sub': 'No se necesita ninguna clave API: la aplicación usa su propia clave integrada.',
  'lfm_manual_hint': 'No se encontró el nombre de usuario automáticamente. Introdúzcalo abajo una vez iniciada la sesión.',
  'lfm_manual_label': 'Nombre de usuario',
  'rec': 'recomendado',
  'not_rec': 'no recomendado',
  'sm_title': 'Método de conexión',
  'sm_key_t': 'Mi clave API',
  'sm_key_s': 'Dispone de su propio límite de uso y los favoritos están disponibles.',
  'sm_builtin_t': 'Clave integrada',
  'sm_builtin_s': 'Solo se necesita su nombre de usuario. El límite de uso se comparte con los demás usuarios.',
  'wl_title': 'Bienvenido',
  'wl_sub': 'Elija cómo desea conectarse a Last.fm.',
  'sr_from_recent': 'Desde tus búsquedas recientes',
  'sr_recent': 'Búsquedas recientes',
  'sr_suggestions': 'Sugerencias',
  'sr_recommended': 'Recomendado',
  'sr_best': 'Mejores resultados',
  'cx_best_month': 'Mejor mes',
  'cx_active_days': 'Días activos',
  'cx_peak_hour': 'Hora pico',
  'cx_top_artist': 'Artista n.º 1',
  'cx_top_artists': 'Top artistas',
  'cx_by_month': 'Por mes',
  'cx_cumulative': 'Acumulado',
  'cx_clock': 'Reloj de escucha',
  'cx_others': 'Otros',
  'cx_artist_distribution': 'Distribución por artista',
  'cx_daypart': 'Momentos del día',
  'cx_night': 'Madrugada',
  'cx_morning': 'Mañana',
  'cx_afternoon': 'Tarde',
  'cx_evening': 'Noche',
  'cx_intensity': 'Intensidad de los días',
  'cx_days': 'días',
  'cx_busiest': 'Días más intensos',
  'cx_weekend': 'Semana vs fin de semana',
  'ap_harmony_title': 'Estilo de color',
  'ap_harmony_mono': 'Monocromo',
  'ap_harmony_mono_sub': 'Un solo tono, con distintas intensidades',
  'ap_harmony_classic': 'Clásico',
  'ap_harmony_classic_sub': 'Material You estándar, con tonos complementarios',
  'ap_harmony_vivid': 'Vivo',
  'ap_harmony_vivid_sub': 'Un solo tono, más saturado',
  'ap_harmony_soft': 'Suave',
  'ap_harmony_soft_sub': 'Un solo tono, más discreto',
};
