// lib/l10n/strings_pt.dart
// ══════════════════════════════════════════════════════════════════════════
//  Portuguese
// ══════════════════════════════════════════════════════════════════════════

import "app_strings.dart";

class AppStringsPt implements AppStrings {
  const AppStringsPt();

  @override String get period7day     => 'Semana';
  @override String get period1month   => 'Mês';
  @override String get period3month   => '3 meses';
  @override String get period6month   => '6 meses';
  @override String get period12month  => 'Ano';
  @override String get periodOverall  => 'Tudo';

  @override String get navDashboard => 'Painel';
  @override String get navSearch    => 'Buscar';
  @override String get navRankings  => 'Rankings';
  @override String get navCharts    => 'Gráficos';
  @override String get navHistory   => 'Histórico';
  @override String get navSettings  => 'Configurações';

  @override String get cacheTitle                  => 'Armazenamento';
  @override String get cacheUsage                  => 'Uso';
  @override String get cacheLimit                  => 'Limite de armazenamento';
  @override String get cacheLimitHint              => 'Ao atingir o limite, as imagens menos recentes são excluídas automaticamente.';
  @override String get cacheClearSection           => 'Limpar';
  @override String get cacheImages                 => 'Imagens';
  @override String get cacheImagesSubtitle         => 'Capas de artistas, álbuns e faixas';
  @override String get cacheApiData                => 'Dados da API';
  @override String get cacheApiDataSubtitle        => 'Top artistas, álbuns, faixas recentes…';
  @override String get cacheScrobbles              => 'Histórico de scrobbles';
  @override String get cacheScrobblesSubtitle      => 'Todas as escutas baixadas';
  @override String get cacheClearBtn               => 'Limpar';
  @override String get cacheConfirmScrobblesTitle  => 'Excluir o histórico?';
  @override String get cacheConfirmScrobblesBody   => 'Todo o histórico será excluído e baixado novamente no próximo início.';
  @override String get cacheConfirmAllTitle        => 'Limpar todo o cache?';
  @override String get cacheConfirmAllBody         => 'Imagens, dados da API e histórico serão excluídos.';
  @override String get cacheDelete                 => 'Excluir';

  @override String get commonArtists          => 'Artistas';
  @override String get commonAlbums           => 'Álbuns';
  @override String get commonTracks           => 'Faixas';
  @override String get commonNoResults        => 'Nenhum resultado';
  @override String get commonRetry            => 'Tentar novamente';
  @override String get commonCancel           => 'Cancelar';
  @override String get commonApply            => 'Aplicar';
  @override String get commonPlays            => 'reproduções';
  @override String get commonListeners        => 'ouvintes';
  @override String get commonNowPlayingBadge  => 'AO VIVO';
  @override String get commonNowPlayingLong   => 'Tocando agora';
  @override String get commonRecentTracks     => 'Faixas recentes';
  @override String get commonNoRecentTracks   => 'Nenhuma faixa recente';
  @override String get commonTopArtists       => 'Top Artistas';

  @override String get rankingsTitle     => 'Rankings';
  @override String get rankingsPodium    => 'Pódio';
  @override String get rankingsContinued => 'Restante do ranking';
  @override String get rankingsAllYears  => 'Todos os anos';

  @override String get chartsTitle              => 'Gráficos';
  @override String get chartsMonthly            => 'Scrobbles (12 meses)';
  @override String get chartsArtistDist         => 'Top artistas (distribuição)';
  @override String get chartsMainstreamTitle    => 'Mainstream vs Joias raras';
  @override String get chartsMainstreamSubtitle => 'Popularidade mundial dos seus artistas favoritos.';
  @override String get chartsCompute            => 'Calcular';
  @override String get chartsRecompute          => 'Recalcular';
  @override String get chartsGem                => 'Joia rara';
  @override String get chartsMainstream         => 'Mainstream';
  @override String globalListeners(String count) => '$count ouvintes no mundo';

  @override String get historyTitle           => 'Histórico';
  @override String get historySubtitle        => 'Suas escutas, dia a dia';
  @override String get historyToday           => 'Hoje';
  @override String get historySelectDate      => 'Selecionar uma data';
  @override String get historyChronological   => 'Cronológico';
  @override String get historyList            => 'Lista';
  @override String get historyStats           => 'Estatísticas';
  @override String get historyNoTracks        => 'Nenhuma escuta nesse dia';
  @override String historyScrobbles(int n)    => '$n scrobbles';
  @override String historyArtistsCount(int n) => '$n artistas';
  @override String historyAlbumsCount(int n)  => '$n álbuns';
  @override String get historyTopArtists      => 'Top artistas';
  @override String get historyTopAlbums       => 'Top álbuns';
  @override String get historyTopTracks       => 'Top faixas';
  @override String get historyHourTracks      => 'faixa';
  @override List<String> get months => const [
    '', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
  @override String dayLabel(DateTime d) {
    const dias  = ['segunda-feira','terça-feira','quarta-feira','quinta-feira','sexta-feira','sábado','domingo'];
    const meses = ['','janeiro','fevereiro','março','abril','maio','junho',
        'julho','agosto','setembro','outubro','novembro','dezembro'];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month]} de ${d.year}';
  }

  @override String get searchTitle        => 'Buscar';
  @override String get searchProfiles     => 'Perfis';
  @override String get searchHintBar      => 'Artista, álbum, faixa ou perfil…';
  @override String get searchHintProfiles => 'Buscar um usuário do Last.fm';
  @override String get searchHintArtists  => 'Buscar um artista';
  @override String get searchHintAlbums   => 'Buscar um álbum';
  @override String get searchHintTracks   => 'Buscar uma música';
  @override String get searchTypePrompt   => 'Digite na barra acima';
  @override String get searchAll          => 'Tudo';
  @override String get searchFolders => 'Pastas';
  @override String get searchFoldersHint => 'Crie uma pasta para guardar músicas, álbuns ou artistas.';
  @override String memberSince(String date) => 'Desde $date';
  @override String get perDay             => 'por dia';
  @override String get activityDays       => 'de atividade';

  @override String get dashStats           => 'Estatísticas';
  @override String get dashTopTracks       => 'Top Faixas';
  @override String get dashFriends         => 'Amigos';
  @override String get dashRefresh         => 'Atualizar';
  @override String get dashRefreshFriends  => 'Atualizar amigos';
  @override String get dashScrobbles       => 'scrobbles';
  @override String get dashScrobblesPerDay => 'por dia';
  @override String get dashDaysActive      => 'de atividade';
  @override String get dashLastTrack       => 'Última tocada';
  @override String get dashArtist1         => 'Artista #1';
  @override String get dashAlbum1          => 'Álbum #1';
  @override String get dashTrack1          => 'Faixa #1';
  @override String get dashNoFriends       => 'Nenhum amigo encontrado';
  @override String get dashResetCache      => 'Redefinir cache';
  @override String get dashResetCacheConfirm => 'Todos os dados de scrobbles em cache serão excluídos e baixados novamente do Last.fm.';

  @override String get dashFriendsActivity => 'Atividade dos seus amigos do Last.fm';

  @override String get settingsTitle             => 'Configurações';
  @override String get settingsAppearance        => 'Aparência';
  @override String get settingsTheme             => 'Tema';
  @override String get settingsThemeAuto         => 'Automático';
  @override String get settingsThemeLight        => 'Claro';
  @override String get settingsThemeDark         => 'Escuro';
  @override String get settingsAccentColor       => 'Cor de destaque';
  @override String get settingsAccentAuto        => 'Automático';
  @override String get settingsCustomColor       => 'Personalizado';
  @override String get settingsCustomColorEdit   => 'Editar';
  @override String get settingsDynamicColor      => 'Cor dinâmica';
  @override String get settingsDayNightAccent          => 'Acento dia/noite';
  @override String get settingsDayNightAccentToggle    => 'Cores diferentes para dia/noite';
  @override String get settingsDayNightAccentToggleSub => 'Usa uma cor de acento diferente para o tema escuro.';
  @override String get settingsDayNightAccentDark      => 'Cor (tema escuro)';
  @override String get settingsDayNightUseHours        => 'Usar horários específicos';
  @override String get settingsDayNightUseHoursSub     => 'Muda de cor pelo horário em vez do tema ativo.';
  @override String get settingsDayNightDayStart        => 'O dia começa às';
  @override String get settingsDayNightNightStart      => 'A noite começa às';
  @override String get settingsMaterialYou       => 'Material You';
  @override String get settingsMaterialYouSub    => 'Usa a cor do papel de parede do Android';
  @override String get settingsMusicColor        => 'Cor a partir da música';
  @override String get settingsMusicColorSub     => 'Extrai a cor da capa atual';
  @override String get settingsMusicColorNote    => 'A cor dominante da capa atual substitui o destaque.';
  @override String get settingsMusicColorLocked  => 'Desative o Material You primeiro';
  @override String get settingsStartupPage       => 'Página inicial';
  @override String get settingsStartupTab        => 'Aba ao abrir';
  @override String get settingsDashboardSection  => 'Painel';
  @override String get settingsHeaderImage       => 'Imagem de cabeçalho';
  @override String get settingsHeaderImageSub    => 'A capa escolhida aparece como fundo da tela inicial.';
  @override String get settingsHeaderSource      => 'Fonte';
  @override String get settingsHeaderPeriod      => 'Período';
  @override String get settingsHeaderAnimation   => 'Transição';
  @override String get settingsHeaderAnimationSub => 'Animação ao trocar de capa.';
  @override String get settingsHeaderBlur        => 'Desfoque';
  @override String get settingsHeaderBlurNone    => 'Nenhum';
  @override String get settingsHeaderCustomUrl   => 'URL da imagem';
  @override String get settingsHeaderCustomUrlHint => 'https://exemplo.com/imagem.jpg';
  @override String get settingsHeaderCustomUrlSub  => 'Cole a URL direta de uma imagem (jpg, png, webp…).';
  @override String get settingsHeaderApply       => 'Aplicar';
  @override String get settingsHeaderFallback    => 'Imagem padrão';
  @override String get settingsHeaderFallbackSub => 'Exibida quando nenhuma música está tocando.';
  @override String get settingsHeaderFallbackUrlLabel => 'URL da imagem padrão';
  @override String get settingsVisibleSections   => 'Seções visíveis';
  @override String get settingsNowPlayingSection => 'Tocando agora';
  @override String get settingsStatsSection      => 'Estatísticas';
  @override String get settingsTopArtistsSection => 'Top Artistas';
  @override String get settingsTopTracksSection  => 'Top Faixas';
  @override String get settingsFriendsSection    => 'Amigos';
  @override String get settingsFriendsSectionSub => 'Atividade dos seus amigos do Last.fm';
  @override String get settingsAccount           => 'Conta';
  @override String get settingsConnectedProfile  => 'Perfil do Last.fm conectado';
  @override String get settingsLogout            => 'Sair';
  @override String get settingsLogoutTitle       => 'Sair da conta?';
  @override String get settingsLogoutContent     => 'Suas credenciais serão excluídas.';
  @override String get settingsLogoutConfirm     => 'Sair';
  @override String get settingsBackup            => 'Backup e restauração';
  @override String get settingsExport            => 'Exportar configurações';
  @override String get settingsExportSub         => 'Copia um JSON para a área de transferência';
  @override String get settingsImport            => 'Restaurar um backup';
  @override String get settingsImportSub         => 'Cole um JSON exportado anteriormente';
  @override String get settingsBackupInfo        => 'Inclui: tema, cores, chave de API, usuário, cabeçalho, favoritos. Compatível entre versões.';
  @override String get settingsUpdates           => 'Atualizações';
  @override String get settingsAutoUpdate        => 'Verificação automática';
  @override String get settingsAutoUpdateSub     => 'Uma vez por dia';
  @override String get settingsCheckNow          => 'Verificar agora';
  @override String get settingsUpToDate          => 'Atualizado';
  @override String settingsUpdateAvailable(String v) => 'v$v disponível';
  @override String get settingsCheckFailed       => 'Falha na verificação.';
  @override String settingsUpdateBanner(String v) => 'Atualização v$v';
  @override String get settingsDownload          => 'Baixar';
  @override String get settingsViewRelease       => 'Ver';
  @override String get settingsAbout             => 'Sobre';
  @override String get settingsVersion           => 'Versão';
  @override String get settingsWebVersion        => 'Versão web';
  @override String get settingsWebVersionSub     => 'sanobld.github.io/LastStats';
  @override String get settingsSourceCode        => 'Código-fonte';
  @override String get settingsSourceCodeSub     => 'github.com/SanoBld/LastStats-App';
  @override String get settingsLanguage          => 'Idioma';
  @override String get settingsAboutProjectDesc  => 'LastStats é um projeto pessoal de código aberto. Pode conter bugs.';
  @override String get settingsAboutSupport      => 'Apoie o projeto';
  @override String get settingsAboutSupportSub   => '⭐ Deixe uma estrela no GitHub';
  @override String get settingsFaq               => 'Perguntas frequentes';

  @override String get headerNowPlaying  => 'Tocando agora';
  @override String get headerTopTrack    => 'Faixa #1';
  @override String get headerTopAlbum    => 'Álbum #1';
  @override String get headerTopArtist   => 'Artista #1';
  @override String get headerCustomImage => 'Imagem personalizada';
  @override String get headerThemeColor  => 'Cor do tema';
  @override String get headerAnimNone    => 'Nenhuma';
  @override String get headerAnimFade    => 'Fade';
  @override String get headerAnimSlide   => 'Deslizar';
  @override String get headerAnimZoom    => 'Zoom';
  @override String get headerPeriodWeek  => 'Semana';
  @override String get headerPeriodMonth => 'Mês';
  @override String get headerPeriodAllTime => 'Todo período';

  @override String get colorPickerTitle       => 'Cor personalizada';
  @override String get colorPickerHue         => 'Matiz';
  @override String get colorPickerSaturation  => 'Saturação';
  @override String get colorPickerBrightness  => 'Brilho';
  @override String get colorPickerQuickColors => 'Cores rápidas';
  @override String get colorPickerInvalid     => 'Formato inválido';
  @override String get colorCustomTooltip     => 'Personalizado';

  @override String get exportTitle      => 'Exportar configurações';
  @override String get exportFilename   => 'Nome do arquivo';
  @override String get exportJsonContent => 'Conteúdo JSON';
  @override String get exportInfo       => 'Copie este JSON, cole em um arquivo de texto e nomeie com .json';
  @override String get exportCopy       => 'Copiar JSON';
  @override String get exportCopied     => 'Copiado!';
  @override String get importTitle      => 'Restaurar um backup';
  @override String get importHintLabel  => 'Cole aqui seu backup do LastStats.';
  @override String get importEmpty      => 'Campo vazio.';
  @override String get importInvalidJson  => 'JSON inválido.';
  @override String get importUnknownFile  => 'Arquivo não reconhecido.';
  @override String get importInvalidFormat => 'Formato inválido.';
  @override String get importSuccess    => 'Configurações restauradas com sucesso ✓';
  @override String get importRestore    => 'Restaurar';

  @override String get setupImportJson      => 'Importar JSON';
  @override String get setupImportHintLabel => 'Cole o conteúdo do seu arquivo JSON abaixo.';
  @override String get setupImportNote      => '{ "username": "…", "api_key": "…" }';
  @override String get setupImportFormat    => '{ "username": "...", "api_key": "..." }';
  @override String get setupInvalidFields   => 'JSON inválido: faltam os campos "username" ou "api_key".';

  @override String get detailTracklist       => 'Faixas';
  @override String get detailAlbumLabel      => 'Álbum';
  @override String get detailDuration        => 'Duração';
  @override String get detailTopTracks       => 'Faixas populares';
  @override String get detailTopAlbums       => 'Álbuns populares';
  @override String get detailBioReadMore     => 'Ler mais';
  @override String get detailBioReadLess     => 'Ler menos';
  @override String get detailUserPlays       => 'suas reproduções';
  @override String get detailGlobalPlays       => 'reproduções totais';
  @override String get detailUserRank        => 'posição';
  @override String get detailUserRankNA      => 'N/D';
  @override String get detailGlobalListeners => 'ouvintes';
  @override String get detailPeriod          => 'Período';
  @override String get detailBiography       => 'Biografia';
  @override String get detailGlobalListenersLabel => 'Ouvintes';
  @override String get detailTranslate       => 'Traduzir';
  @override String get detailShowOriginal    => 'Ver original';
  @override String get detailLyrics          => 'Letra';
  @override String get detailLyricsNotFound  => 'Letra não disponível';
  @override String get detailCopyLyrics      => 'Copiar letra';
  @override String get detailLyricsCopied    => 'Letra copiada';

  @override String get detailShoutbox => 'Shoutbox do Last.fm';
  @override String get detailShoutboxReply => 'Responder';  @override String get dashPerWeek           => 'por semana';

  @override String get onboardSkip             => 'Pular';
  @override String get onboardNext             => 'Próximo';
  @override String get onboardFinish           => 'Concluir';
  @override String get onboardBack             => 'Voltar';
  @override String get onboardAppearanceTitle  => 'Personalize seu estilo';
  @override String get onboardAppearanceSub    => 'Tema, cor de destaque e Material You.';
  @override String get onboardNotifTitle       => 'Fique por dentro';
  @override String get onboardNotifSub         => 'Notificações e vibrações.';
  @override String get onboardFavTitle         => 'Seus perfis favoritos';
  @override String get onboardFavSub           => 'Adicione amigos do Last.fm para encontrá-los rapidamente.';
  @override String get onboardFavHint          => 'Usuário do Last.fm';
  @override String get onboardFavAdd           => 'Adicionar';
  @override String get onboardFavEmpty         => 'Nenhum favorito ainda';
  @override String get onboardFavSearchHint    => 'Buscar um perfil do Last.fm…';
  @override String get onboardFavNoResults     => 'Nenhum perfil encontrado';
  @override String get onboardFavFriendsTitle  => 'Seus amigos do Last.fm';
  @override String get onboardFavNoFriends     => 'Nenhum amigo encontrado nessa conta';
  @override String get onboardFavSelected      => 'Favoritos selecionados';
  @override String get onboardDashTitle        => 'Seu painel';
  @override String get onboardDashSub          => 'Escolha quais seções mostrar.';
  @override String get onboardStartupTitle     => 'Tela inicial';
  @override String get onboardStartupSub       => 'Qual aba você quer ver primeiro?';
  @override String get onboardPlatformTitle    => 'Onde você ouve música?';
  @override String get onboardPlatformSub      => 'Assim só aparecem os links úteis nas fichas de faixa/artista/álbum.';
  @override String get platformLastfm          => 'Last.fm';
  @override String get platformSpotify         => 'Spotify';
  @override String get platformYtMusic         => 'YouTube Music';
  @override String get platformOther           => 'Outra / mostrar tudo';
  @override String get settingsMusicPlatform          => 'Plataforma musical';
  @override String get settingsMusicPlatformSub       => 'Filtra os links mostrados nas fichas de detalhe';
  @override String get settingsShowAllPlatformLinks    => 'Sempre mostrar tudo';
  @override String get settingsShowAllPlatformLinksSub => 'Ignora o filtro e mostra todos os links (Last.fm, Spotify, YT Music, Web)';
  @override String get onboardUpdatesTitle     => 'Atualizações';
  @override String get onboardUpdatesSub       => 'Verificação automática de novas versões.';
  @override String get onboardStyle              => 'Estilo';
  @override String get onboardStyleMaterialYou    => 'Material You';
  @override String get onboardStyleNothing        => 'Nothing OS';
  @override String get onboardPreview             => 'Prévia';
  @override String get onboardPreviewButton       => 'Botão';
  @override String get onboardPreviewOutline      => 'Contorno';
  @override String get onboardPreviewText         => 'Texto de exemplo';
  @override String get onboardPreviewBubble       => 'Bolha';
  @override String get onboardAccentTint          => 'Tom de destaque';
  @override String get onboardNothingRedOnly      => 'Só vermelho';
  @override String get onboardNothingRedYellow    => 'Vermelho + amarelo';
  @override String get onboardDisplay             => 'Tela';
  @override String get onboardOledTitle           => 'Preto OLED';
  @override String get onboardOledSub             => 'Fundo preto puro no modo escuro';
  @override String get onboardArtworkColorTitle   => 'Cor a partir da capa';
  @override String get onboardArtworkColorSub     => 'Combina a cor de destaque com a capa em reprodução';
  @override String get onboardNewsTitle           => 'Notificações de novidades';
  @override String get onboardNewsSub             => 'Seja avisado sobre novos recursos e correções';
  @override String get onboardNewsBadgeTitle      => 'Ponto de novidades';
  @override String get onboardNewsBadgeSub        => 'Ponto vermelho no sino do painel quando há novidades';
  @override String get onboardHapticTitle         => 'Feedback tátil';
  @override String get onboardHapticSub           => 'Sinta vibrações sutis em interações importantes';
  @override String get onboardRecaps              => 'Resumos';
  @override String get onboardDailyRecapTitle     => 'Resumo diário';
  @override String get onboardDailyRecapSub       => 'Um resumo rápido da sua escuta do dia';
  @override String get onboardWeeklyRecapTitle    => 'Resumo semanal';
  @override String get onboardWeeklyRecapSub      => 'Seus tops de artistas, álbuns e faixas da semana';
  @override String get onboardMilestonesSection   => 'Marcos de scrobbles';
  @override String get onboardMilestonesTitle     => 'Marcos';
  @override String get onboardMilestonesSub       => 'Celebre números redondos de scrobbles';
  @override String get onboardGrandMilestonesTitle => 'Grandes marcos';
  @override String get onboardGrandMilestonesSub   => 'Comemoração especial para grandes marcos';
  @override String get onboardDynamicColorSub      => 'Usar as cores do seu papel de parede (Android 12+)';
  @override String get onboardBetaTitle            => 'Atualizações beta';
  @override String get onboardBetaSub              => 'Acesso antecipado a pré-lançamentos';

  @override String get notifDetailTitle            => 'Notificação';
  @override String get notifDetailOpenLink         => 'Abrir link';

  @override String get settingsCheckingUpdates     => 'Verificando atualizações…';
  @override String get settingsTapToDownload       => 'Toque para baixar';

  @override String get detailLookingForPreview     => 'Procurando uma prévia…';
  @override String get detailPreview30Sec          => 'Prévia · 30 seg';

  @override String get setupTagline                => 'Suas estatísticas do Last.fm, reinventadas.';
  @override String get setupAnalyseProfile         => 'Analisar um perfil';
  @override String get setupConnecting             => 'Conectando…';
  @override String get setupStartAnalysis          => 'Iniciar análise';
  @override String get setupOr                     => 'ou';
  @override String setupWelcome(String username)   => 'Bem-vindo, $username!';
  @override String get setupUsernameLabel          => 'Usuário do Last.fm';
  @override String get setupApiKeyLabel            => 'Chave de API do Last.fm';
  @override String get setupApiKeyHint             => 'Chave hexadecimal de 32 caracteres';
  @override String get setupApiKeyPrivacyNote      => 'Armazenada localmente. Nunca enviada a terceiros.';
  @override String get setupRememberMe             => 'Lembrar de mim';
  @override String get setupGetApiKey              => 'Obter uma chave de API grátis';
  @override String setupScrobblesToImport(String c) => '$c scrobbles para importar';
  @override String get setupWelcomeBanner          => 'Bem-vindo ao LastStats!';
  @override String get setupOneTimeImportNote      => 'Importação única, as próximas aberturas serão instantâneas.';

  @override String get dashTapToDownload           => 'Toque para baixar.';
  @override String dashUpdateTitle(String version, bool isBeta) =>
      '${isBeta ? "Beta" : "Nova"} atualização: v$version';
  @override String get dashWeekLabel               => 'ESTA SEMANA';
  @override String get dashMonthLabel              => 'ESTE MÊS';
  @override String get dashYearLabel               => 'ESTE ANO';
  @override String get dashTopArtistLabel          => 'Artista top';
  @override String get dashTopTrackLabel           => 'Faixa top';
  @override String get dashScrobblesLabel          => 'Scrobbles';
  @override String get newsTypeFeatures            => 'Novidades';
  @override String get newsTypeFixes               => 'Correções';
  @override String get newsTypeUpdates             => 'Atualizações';
  @override String get newsTypeAlerts              => 'Alertas';
  @override String get newsTypeInfo                => 'Info';
  @override String get newsWhatsNew                => 'Novidades';
  @override String newsItemsCount(int n)           => '$n ${n > 1 ? "itens" : "item"}';
  @override String get newsFilters                 => 'Filtros';
  @override String get newsAll                     => 'Tudo';
  @override String get newsAnyDate                 => 'Qualquer data';
  @override String get newsNoNewsYet               => 'Nenhuma novidade ainda';
  @override String get settingsNotifications        => 'Notificações';
  @override String get settingsCache                 => 'Cache';
  @override String get settingsCardAppearanceSub     => 'Tema, destaque, layout, Material You';
  @override String get settingsCardDashboardSub      => 'Imagem de cabeçalho, seções visíveis, cartões de estatísticas';
  @override String get settingsCardStartupSub        => 'Aba exibida ao abrir o app';
  @override String get settingsCardNotificationsSub  => 'Marcos, resumos diários e semanais';
  @override String get settingsSync                  => 'Sincronização';
  @override String get settingsCardSyncSub           => 'Sincronização automática em segundo plano';
  @override String get settingsCardAccountSub        => 'Perfil do Last.fm conectado, sair';
  @override String get settingsCardCacheSub          => 'Histórico, imagens, dados da API';
  @override String get settingsCardBackupSub         => 'Exportar e restaurar suas configurações';
  @override String get settingsCardUpdatesSub        => 'Verificar novas versões';
  @override String get settingsCardAboutSub          => 'Versão, código-fonte, créditos';
  @override String get settingsCardFaqSub            => 'Scrobbling, plataformas, código aberto';
  @override String get settingsRestartNotice => 'Algumas configurações exigem reiniciar o app para ter efeito completo.';
  @override String get syncPageTitle           => 'Sincronização de scrobbles';
  @override String get syncAutoTitle           => 'Sincronização automática';
  @override String get syncAutoSubtitle        => 'Sincroniza seu histórico em segundo plano em intervalos regulares';
  @override String get syncFrequencyLabel      => 'Frequência';
  @override String syncFrequencyHours(int h)   => 'A cada ${h}h';
  @override String get syncFrequencyDaily      => 'Uma vez por dia';
  @override String get syncManualTitle         => 'Sincronização manual';
  @override String get syncNowButton           => 'Sincronizar agora';
  @override String get syncInProgress          => 'Sincronizando…';
  @override String get syncLastSyncLabel       => 'Última sincronização';
  @override String get syncNeverLabel          => 'Nunca';
  @override String get syncTotalScrobblesLabel => 'Scrobbles em cache';
  @override String syncNewScrobblesFound(int n) => n == 0 ? 'Nenhum scrobble novo' : '$n scrobble(s) novo(s) encontrado(s)';
  @override String get syncUpToDateMsg         => 'Histórico atualizado';
  @override String get syncNotifNote           => 'Uma notificação com progresso aparece durante uma sincronização completa.';
  @override String get pcModeLayout      => 'Layout';
  @override String get pcModeNavLayout   => 'Layout de navegação';
  @override String get pcModeAuto        => 'Automático';
  @override String get pcModeSideRail    => 'Barra lateral';
  @override String get pcModeBottomBar   => 'Barra inferior';
  @override String get pcModeHintAuto    => 'Barra lateral em telas largas (≥ 720 dp), barra inferior em telas estreitas.';
  @override String get pcModeHintOn      => 'Sempre usar a barra de navegação lateral, independente do tamanho da tela.';
  @override String get pcModeHintOff     => 'Sempre usar a barra de navegação inferior, independente do tamanho da tela.';
  @override String get aboutTagline               => 'Seu companheiro de estatísticas do Last.fm';
  @override String get aboutAppInfo                => 'Info do app';
  @override String get aboutScrobbleDownloader     => 'Baixador de scrobbles';
  @override String get aboutScrobbleDownloaderSub  => 'Exporte todos os seus scrobbles para um arquivo';
  @override String get aboutPoweredBy              => 'Com tecnologia de';
  @override String get aboutImageDisclaimer        => 'As imagens de artistas, álbuns e faixas são obtidas automaticamente dessas fontes e às vezes podem estar incorretas ou não corresponder ao conteúdo real.';
  @override String get aboutFooter                 => 'Feito com ❤️ · Sem afiliação com Last.fm / CBS';

  @override String updatesPublishedOn(String date) => 'Publicado em $date';
  @override String get updatesCurrentVersion       => 'Versão atual';
  @override String get updatesBetaTitle            => 'Atualizações beta';
  @override String get updatesBetaSub              => 'Tenha acesso antecipado às versões pré-lançadas';

  @override String get backupWhatsIncluded         => 'O que está incluído';
  @override String get backupDownloadFile          => 'Baixe um arquivo .json';
  @override String get backupChooseFile            => 'Escolher um arquivo de backup';
  @override String get backupFileSaved             => 'Backup salvo';
  @override String get backupFileSaveFailed        => 'Falha ao salvar o arquivo';
  @override String get setupRestoreBackup          => 'Restaurar um backup';
  @override String get setupRestoreBackupSub       => 'Recupere sua conta e configurações a partir de um arquivo .json de backup';
  @override String get backupRestoreKeysTitle => 'Restaurar chaves de API';
  @override String get backupRestoreKeysDesc => 'Escolha quais chaves do Last.fm restaurar a partir deste backup.';
  @override String get backupRestoreApiKeyLabel => 'Chave de API';
  @override String get backupRestoreSecretKeyLabel => 'Chave secreta';
  @override String get backupIncludeFoldersLabel => 'Incluir pastas';
  @override String get backupIncludeFoldersDesc => 'Inclui as suas pastas de músicas e o respetivo conteúdo.';
  @override String get backupIncludeKeysDesc => 'Incluir as chaves no arquivo exportado';

  @override String get backupIncludeThemesLabel => 'Exportar temas';
  @override String get backupIncludeThemesDesc => 'Permite compartilhar apenas a aparência (cores, estilo) com outra pessoa.';

  @override String get backupAutoTitle => 'Backup automático';
  @override String get backupAutoEnableLabel => 'Ativar backup automático';
  @override String get backupAutoEnableDesc => 'Salva um backup sozinho, no intervalo escolhido abaixo.';
  @override String get backupAutoFreqLabel => 'Frequência';
  @override String get backupAutoFreqDaily => 'Todos os dias';
  @override String get backupAutoFreqWeekly => 'Todas as semanas';
  @override String get backupAutoFreqMonthly => 'Todos os meses';
  @override String get backupAutoFreqYearly => 'Todos os anos';
  @override String get backupAutoFolderLabel => 'Pasta de backup';
  @override String get backupAutoFolderDefault => 'Pasta padrão do aplicativo';
  @override String backupAutoNextLabel(String date) => 'Próximo backup: $date';  @override String get backupIncludeScrobblesLabel => 'Incluir todo o histórico';
  @override String get backupIncludeScrobblesDesc => 'Adiciona todas as músicas ouvidas desde o início (pode ser grande).';

  @override String get backupScrobblesSlowWarning => 'Isso pode demorar um pouco e é mais lento que um backup normal.';  @override String backupExportedOn(String date) => 'Backup de $date';
  @override String get backupScrobblesErrorTitle => 'Erro no histórico';
  @override String get backupScrobblesErrorDesc => 'Alguns anos do histórico parecem estar corrompidos neste arquivo. O que deseja fazer?';
  @override String get backupScrobblesKeepAnyway => 'Continuar mesmo assim';
  @override String get backupScrobblesCancel => 'Cancelar histórico';
  @override String get backupScrobblesSkipRefetch => 'Ignorar e baixar novamente online';  @override String get settingsCrashLog => 'Registro de erros';
  @override String get backupCrashLogDesc => 'Registra os erros encontrados pelo app, útil para reportar um bug.';
  @override String get backupCrashLogShare => 'Compartilhar registro';
  @override String get backupCrashLogClear => 'Limpar registro';
  @override String get backupCrashLogEmpty => 'Nenhum erro registrado';
  @override String get backupCrashLogCleared => 'Registro limpo';
  @override String get backupCrashLogClearConfirm => 'Limpar o registro de erros?';

  @override String get faqSectionLabel             => 'Perguntas frequentes';
  @override String get backupOverwriteWarning => 'Restaurar um backup substituirá suas configurações atuais.';
  @override String get faqOpenSourceBadge => 'LastStats é um projeto gratuito e de código aberto feito com ❤️ por SanoBld.';
  @override String get cacheUnlimited     => 'Ilimitado';
  @override String get cacheTotalUsed     => 'Total usado';
  @override String get cacheScrobblesShort => 'Histórico';
  @override String get restartHintFeatures => 'Alguns recursos podem exigir reiniciar o app para ter efeito.';
  @override String get reorderCardsTitle   => 'Reordenar cartões';
  @override String get commonSave          => 'Salvar';
  @override String get dashFallbackWhenNoMusic   => 'Quando nenhuma música está tocando';
  @override String get dashFallbackChooseDisplay => 'Escolha o que mostrar como fundo em vez disso';
  @override String get dashFallbackPeriodLabel   => 'Período de reserva';
  @override String get fallbackPeriod1Week       => '1 semana';
  @override String get fallbackPeriod1Month      => '1 mês';
  @override String get fallbackPeriodAllTime     => 'Todo período';
  @override String get fallbackTypeNothing       => 'Nada';
  @override String get fallbackTypeTopTrack      => 'Faixa #1';
  @override String get fallbackTypeTopAlbum      => 'Álbum #1';
  @override String get fallbackTypeTopArtist     => 'Artista #1';
  @override String get fallbackTypeCustomImage   => 'Imagem personalizada';
  @override String fallbackWillShow(String detail) => 'Mostrará: $detail';
  @override String get fallbackWillShowCustomUrl => 'Mostrará: URL de imagem personalizada';

  @override String get dashAnimationBlurSection  => 'Animação e desfoque';
  @override String get dashMusicAnimationTitle   => 'Animação de música';
  @override String get dashMusicAnimationSub     => 'Quando uma música toca, a imagem desfoca e se move suavemente, como no Apple Music.';
  @override String get dashMusicAnimationInfo    => 'O desfoque é aplicado automaticamente neste modo. O controle de desfoque acima não tem efeito enquanto a música toca.';

  @override String get settingsTopAlbumsSection  => 'Top Álbuns';
  @override String get dashRecentPlaysLabel      => 'Reproduções recentes';
  @override String get dashStatCardsSectionLabel => 'Cartões de estatísticas';
  @override String get dashStatCardsHeading      => 'Cartões de stats';
  @override String get dashStatCardsSub          => 'Escolha e reordene os cartões mostrados no bloco de estatísticas.';
  @override String get settingsDashboardChartSection => 'Gráfico do painel';
  @override String get dashChartCalendarLabel => 'Calendário de escuta';
  @override String get dashChartMonthlyLabel => 'Barras mensais';
  @override String get settingsDisplayNameSection => 'Nome personalizado';
  @override String get settingsDisplayNameLabel => 'Como devemos chamar você?';
  @override String get settingsDisplayNameHint => 'Ex. Sano Bld — deixe vazio para usar o nome da conta';
  @override String get newsSearchHint => 'Pesquisar nas novidades…';
  @override String get aboutOpenSourceLibs => 'Bibliotecas de código aberto';
  @override String get aboutOpenSourceLibsSub => 'Todos os pacotes Flutter usados para criar o app.';
  @override String get aboutLicenseSection => 'Licença';
  @override String get aboutLicenseText => 'Este projeto é publicado sob a licença MIT: fique à vontade para usar, modificar, duplicar ou redistribuir, só me cite.';
  @override String get aboutLicenseLink => 'Ver licença completa';
  @override String get languageAiNote => 'As traduções foram geradas por IA e podem conter imprecisões.';
  @override String get aboutAiDevNote => 'A IA também foi usada para desenvolver este app.';
  @override String get notifWorkManagerInfo => 'As notificações são executadas em segundo plano via WorkManager. O app não precisa estar aberto. É necessária conexão com a internet.';
  @override String get notifIntervalTitle       => 'A cada X scrobbles';
  @override String get notifIntervalSubtitle    => 'Receba avisos em intervalos regulares';
  @override String get notifRecapsSection       => 'Resumos de escuta';
  @override String get notifDailyRecapSubtitle  => 'Total de scrobbles + artista favorito do dia';
  @override String get notifWeeklyRecapSubtitle => 'Total de scrobbles + artista favorito da semana';
  @override String get notifNewsSection         => 'Novidades';
  @override String get notifSyncSection         => 'Sincronização';
  @override String get notifSyncTitle           => 'Notificações de sincronização';
  @override String get notifSyncSubtitle        => 'Avisa quando uma sincronização do histórico termina';
  @override String get notifSyncDetailTitle     => 'Detalhe do progresso';
  @override String get notifSyncDetailSubtitle  => 'Mostrar o andamento (ano atual, contador) durante a sincronização';
  @override String get notifNewsSubtitle        => 'Receba avisos de novos recursos, correções e anúncios';
  @override String get notifBadgeOnDashboard    => 'Emblema no painel';
  @override String get notifBadgeSubtitle       => 'Mostrar o ponto de não lido no sino de novidades';
  @override String get notifTestLabel           => 'Teste';
  @override String get notifPermissionDisabledTitle => 'Notificações desativadas';
  @override String get notifPermissionDisabledBody  => 'Conceda a permissão para que o LastStats possa enviar avisos.';
  @override String get notifGrantPermission     => 'Conceder permissão';
  @override String get notifThresholdIntro      => 'Você receberá uma notificação especial em cada um destes marcos:';
  @override List<String> get notifThresholdMessages => const [
    'Seus primeiros 1.000 scrobbles. A jornada começa. 🎵',
    'Você chegou a cinco dígitos! 🎉',
    'Você é um verdadeiro viciado em música. 🔥',
    'Um milhão de scrobbles. Isso é lendário. 🎸',
  ];
  @override String get notifIntervalDescription => 'Enviar uma notificação a cada X scrobbles';
  @override String get notifCustomValueLabel    => 'Valor personalizado';
  @override String get notifTimeNotifyAt        => 'Notificar às';
  @override String get notifDayOfWeek           => 'Dia da semana';
  @override List<String> get weekdaysShort => const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  @override List<String> get weekdaysNarrow => const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  @override String get weekAbbrev => 'S';
  @override String get notifSendTest            => 'Enviar uma notificação de teste';
  @override String get notifSentCheckBar        => 'Confira sua barra de notificações!';
  @override String get notifMakeSureWorks       => 'Verifique se tudo funciona.';
  @override String get notifSentBang            => 'Enviado!';
  @override String get notifSendButton          => 'Enviar';
  @override String get apVisualStyle             => 'Estilo visual';
  @override String get apStyleDefault            => 'Padrão';
  @override String get apNothingAccentLabel      => 'Destaque';
  @override String get apNothingClassic          => 'Clássico';
  @override String get apRedOnlyDesc             => 'Somente vermelho';
  @override String get apNothingMixed            => 'Misto';
  @override String get apRedYellowDesc           => 'Vermelho + toques de amarelo';
  @override String get apNothingActiveBanner     => 'Estilo Nothing OS ativo. Destaque, cor dinâmica e cor da música estão desativados.';
  @override String get apNothingOledInherent     => 'O modo escuro do Nothing já é preto OLED por natureza. A opção OLED não é necessária.';
  @override String get apOledTitle               => 'Tema preto OLED';
  @override String get apOledBuiltIntoNothing    => 'Integrado ao modo escuro do Nothing';
  @override String get apOledPureBlack           => 'Fundos pretos puros quando o modo escuro está ativo';
  @override String get apCustomColorTooltip      => 'Cor personalizada';
  @override String get apColorWhenNothingPlays   => 'Cor quando nada está tocando';
  @override String get apColorWhenNothingPlaysSub => 'Destaque usado quando nenhuma faixa está tocando';
  @override String get apKeepLastArtworkTitle    => 'Manter a última cor da capa';
  @override String get apKeepLastArtworkSub      => 'Manter a última cor da capa em vez de redefinir quando nada está tocando';
  @override String get apDetailPagesSection      => 'Páginas de detalhes';
  @override String get apArtworkColorTheme       => 'Tema de cor da capa';
  @override String get apBeta                    => 'BETA';
  @override String get apArtworkColorThemeSub    => 'As páginas de detalhes adaptam suas cores à cor dominante da capa';
  @override String get apNavBarSection           => 'Barra de navegação';
  @override String get apShowTabLabels           => 'Mostrar rótulos das abas';
  @override String get apShowTabLabelsSub        => 'Exibir os nomes das abas abaixo dos ícones';
  @override String get apInteractionsSection     => 'Interações';
  @override String get apHapticFeedbackSub       => 'Vibrações em toques, seleções e gestos';
  @override String get acctRemoveTitle          => 'Remover conta?';
  @override String acctRemoveBody(String username) => 'Remover @$username das suas contas?';
  @override String get acctRemoveAction         => 'Remover';
  @override String get acctAlreadyAddedOrFull   => 'Essa conta já foi adicionada ou a lista está cheia.';
  @override String acctAddedSuccess(String username) => '@$username adicionado com sucesso.';
  @override String get acctLogoutAllBody        => 'Todas as contas serão removidas. Você voltará para a tela de configuração.';
  @override String acctMyAccounts(int count, int max) => 'Minhas contas ($count/$max)';
  @override String get acctActive               => 'Ativa';
  @override String get acctTapSwitchToActivate  => 'Toque em "Trocar" para ativar';
  @override String get acctSwitch               => 'Trocar';
  @override String get acctAddAnAccount         => 'Adicionar uma conta';
  @override String acctSlotsRemaining(int n)    => '$n vaga(s) restante(s)';
  @override String acctMaxReached(int max)      => 'Máximo de $max contas atingido.';
  @override String get acctApiKeyInfo           => 'Cada conta pode usar uma chave de API diferente ou a mesma. Você encontra sua chave de API em last.fm/api/accounts.';
  @override String get acctLastfmProfileSection => 'Perfil do Last.fm';
  @override String get acctViewOnLastfm         => 'Ver no Last.fm';
  @override String get acctDangerZone           => 'Zona de perigo';
  @override String get acctLogoutAllSub         => 'Remover todas as contas e voltar para a configuração.';
  @override String get acctUsernameRequired     => 'O nome de usuário é obrigatório.';
  @override String get acctApiKeyRequired       => 'A chave de API é obrigatória.';
  @override String get acctUsernameLabel        => 'Usuário do Last.fm';
  @override String get acctSameApiKey           => 'Mesma chave de API da conta ativa';
  @override String get acctApiKeyLabel          => 'Chave de API';
  @override String get acctAdd                  => 'Adicionar';
  @override String get languageChangeNote => 'O idioma muda imediatamente em todo o app.';
  @override String get dashTotalScrobblesLabel  => 'Total de scrobbles';
  @override String get dashMemberSinceLabel     => 'Membro desde';
  @override String get dashCountryLabel         => 'País';
  @override String get dashArtistWeekLabel      => 'Artista #1 (semana)';
  @override String get dashAlbumWeekLabel       => 'Álbum #1 (semana)';
  @override String get dashTrackWeekLabel       => 'Faixa #1 (semana)';
  @override String get dashUniqueArtistsLabel   => 'Artistas únicos';
  @override String get dashUniqueTracksLabel    => 'Faixas únicas';
  @override String get dashUniqueAlbumsLabel    => 'Álbuns únicos';
  @override String get dashThisWeekLabel        => 'Esta semana';
  @override String get dashDayUnitShort         => 'd';
  @override String get setupEnableFavorites      => 'Ativar favoritos (opcional)';
  @override String get setupFavoritesExplain     => 'Sua chave secreta permite curtir (ou descurtir) faixas diretamente no Last.fm.';
  @override String get setupSecretKeyLabel       => 'Chave secreta do Last.fm';
  @override String get favConnectInvalidSecret   => 'A chave secreta deve ter 32 caracteres.';
  @override String get favConnectDialogTitle     => 'Autorizar favoritos';
  @override String get favConnectDialogBody      => 'Autorize o app na página do Last.fm aberta no navegador e depois volte aqui para confirmar.';
  @override String get favConnectDialogConfirm   => 'Já autorizei';
  @override String get favConnectSuccess         => 'Favoritos ativados com sucesso!';
  @override String get favConnectError           => 'Não foi possível ativar os favoritos. Verifique sua chave secreta.';
  @override String get acctApiKeysSection        => 'Chaves de API';
  @override String get acctSecretKeyLabel        => 'Chave secreta';
  @override String get acctSecretKeyNotSet       => 'Não definida';
  @override String get acctFavoritesExplain      => 'A chave secreta permite curtir (ou descurtir) faixas diretamente no Last.fm.';
  @override String get acctConnectFavorites      => 'Ativar favoritos';
  @override String get acctDisconnectFavorites   => 'Desativar favoritos';
  @override String get settingsFavoritesSection    => 'Favoritos';
  @override String get settingsFavoritesSectionSub => 'Mostra o número de favoritos nas estatísticas';
  @override String get settingsFavoritesNeedsKey   => 'Adicione sua chave secreta em Conta para ativar';
  @override String get favSectionTitle           => 'Favoritos';
  @override String get commonSeeMore             => 'Ver mais';
  @override String get favPageTitle              => 'Meus favoritos';
  @override String get favSearchHint             => 'Buscar uma faixa ou artista';
  @override String get favEmpty                  => 'Nenhum favorito ainda.';
  @override String get settingsLovedBadgeTitle => 'Selo de coração discreto';
  @override String get settingsLovedBadgeSub   => 'Mostra um pequeno coração nas faixas favoritas nas reproduções recentes, histórico e busca';
  @override String get favSortRecent   => 'Recentes';
  @override String get favSortOldest   => 'Antigos';
  @override String get favSortArtistAz => 'Artista A-Z';
  @override String get favSortTitleAz  => 'Título A-Z';
  @override String get favFolderSortCustom => 'Manual';
  @override String get favFoldersAll => 'Todos';
  @override String get favFolderNew => 'Nova pasta';
  @override String get favFolderNamePlaceholder => 'Nome da pasta';
  @override String get favFolderCustomEmojiTitle => 'Escolha um emoji';
  @override String get favFolderCustomEmojiHelper => 'Apenas um emoji, sem texto.';
  @override String get favFolderDescPlaceholder => 'Descrição (opcional)';
  @override String get favFolderRecentlyPlayed => 'Ouvidas recentemente';
  @override String get favFolderCreate => 'Criar';
  @override String get favFolderEdit => 'Editar pasta';
  @override String get favFolderDelete => 'Excluir';
  @override String get favFolderDeleteConfirm => 'Excluir esta pasta? As músicas não ficarão mais organizadas nela.';
  @override String get favFolderAssignTitle => 'Adicionar a uma pasta';
  @override String get favFolderEmoji => 'Emoji';
  @override String get favFolderColor => 'Cor';
  @override String get favFolderSave => 'Salvar';
  @override String get favFolderEmpty => 'Nenhuma música nesta pasta';
  @override String get rankingsWholeYear       => 'Ano inteiro';
  @override String get chartsExportGeneratedOn => 'gerado em';
  @override String get faqQ1 => 'O LastStats faz scrobble da minha música?';
  @override String get faqA1 => 'Não. O LastStats é um aplicativo de visualização: ele exibe os scrobbles já registrados na sua conta do Last.fm, mas não registra nenhum por conta própria.\n\nPara fazer scrobble automático da sua música, use um app dedicado como o Pano Scrobbler (disponível para Android).';
  @override String get faqQ2 => 'Está prevista uma versão para iOS?';
  @override String get faqA2 => 'Não. Por enquanto não há uma versão para iOS prevista.';
  @override String get faqQ3 => 'O app funciona no macOS ou em outras plataformas?';
  @override String get faqA3 => 'O LastStats é desenvolvido e testado no Android. O funcionamento em outras plataformas (macOS, Windows, Linux…) não é verificado, podem ocorrer bugs ou comportamentos inesperados.';
  @override String get faqQ4 => 'O LastStats é open source?';
  @override String get faqA4 => 'Sim! O código-fonte está disponível livremente no GitHub. O projeto é independente, feito com paixão por SanoBld. Sinta-se à vontade para contribuir, reportar bugs ou deixar uma estrela ⭐.';
  @override String get faqQ5 => 'Onde meus dados são armazenados?';
  @override String get faqA5 => 'Apenas no seu dispositivo. O LastStats não tem servidor: seus scrobbles ficam em cache local para acesso rápido, e suas credenciais do Last.fm também ficam armazenadas localmente. Nada é enviado além da API oficial do Last.fm.';
  @override String get faqQ6 => 'Como ativo os favoritos?';
  @override String get faqA6 => 'Acesse Configurações > Conta e informe sua chave secreta do Last.fm. Uma vez conectada, você poderá favoritar faixas diretamente pelo app.';
  @override String get faqQ7 => 'O que \u00e9 um \'scrobble\'?';
  @override String get faqA7 => 'Um scrobble \u00e9 uma faixa registrada como ouvida na sua conta do Last.fm \u2014 \u00e9 o termo oficial do Last.fm para \'uma escuta contabilizada\'. Todos os seus totais (artistas mais ouvidos, estat\u00edsticas etc.) s\u00e3o baseados nisso.';
  @override String get faqQ8 => 'Como funcionam os n\u00edveis e conquistas?';
  @override String get faqA8 => 'Seu n\u00edvel de conta cresce com o total de scrobbles (n\u00e3o h\u00e1 n\u00edvel m\u00e1ximo). Os cart\u00f5es tamb\u00e9m ganham uma borda (bronze \u2192 iridescente) de acordo com quantas vezes aquele artista/faixa/\u00e1lbum foi tocado. Tudo \u00e9 calculado automaticamente a partir das estat\u00edsticas j\u00e1 em cache local, sem chamadas de rede extras.';
  @override String get faqQ9 => 'Como funciona o modo de economia de energia?';
  @override String get faqA9 => 'O modo de economia de energia espaça as sincronizações automáticas para economizar bateria. Ele pode ficar sempre ativo, acompanhar o modo de economia do telefone ou ligar abaixo de um nível de bateria que você escolher, em Ajustes > Geral.';
  @override String get faqQ10 => 'Como faço backup ou restauro meus dados?';
  @override String get faqA10 => 'Acesse Configurações > Backup. Você pode exportar um arquivo de backup (com ou sem sua chave do Last.fm) e reimportá-lo depois ou em outro aparelho.';
  @override String get faqQ11 => 'O aplicativo funciona offline?';
  @override String get faqA11 => 'Sim, até certo ponto. As estatísticas já carregadas continuam disponíveis offline graças ao cache local, mas é preciso conexão para buscar novos scrobbles.';
  @override String get faqQ12 => 'Posso trocar de conta do Last.fm?';
  @override String get faqA12 => 'Sim. Em Configurações > Conta, saia e entre novamente com outro nome de usuário. O cache local é limpo automaticamente para evitar misturar dados.';
  @override String get faqQ13 => 'Como configuro as notificações?';
  @override String get faqA13 => 'Em Configurações > Notificações, você pode ativar avisos de sincronização concluída, escolher a frequência ou desativá-los por completo.';
  @override String get faqQ14 => 'Faltam imagens ou carregam sem parar. O que fazer?';
  @override String get faqA14 => 'Limpe a cache na app (Definições > Cache) e depois no Android (Definições > Aplicações > LastStats > Armazenamento > Limpar cache). Se continuarem a faltar imagens, faça uma cópia de segurança (Definições > Cópia de segurança), desinstale e reinstale a app e restaure a cópia.';
  @override String get settingsPlatformDisabledByShowAll => 'Desativado: todos os links já estão sendo exibidos.';
  @override String get commonInDevelopment => 'Em desenvolvimento';
  @override String get commonSeeLess => 'Ver menos';
  @override String get commonShare => 'Compartilhar';
  @override String get newsCustomDate => 'Data personalizada';
  @override String get aboutShortcuts => 'Atalhos de teclado';
  @override String get aboutShortcutsSub => 'Disponíveis no PC / tela grande';
  @override String get shortcutSwitchTabs => 'Trocar de aba';
  @override String get shortcutSearch => 'Pesquisar';
  @override String get shortcutClose => 'Fechar uma ficha';
  @override String get shortcutRefresh => 'Atualizar';
  @override String get aboutDiscord => 'Entrar no Discord';
  @override String get aboutDiscordSub => 'Bate-papo, sugestões e anúncios ao vivo';
  @override String get achvTitle => 'Conquistas';
  @override String achvUnlocked(int unlocked, int total) => '$unlocked / $total desbloqueadas';
  @override String get achvCatListening => 'Audição';
  @override String get achvCatArtists => 'Artistas';
  @override String get achvCatAlbums => 'Álbuns';
  @override String get achvCatLoyalty => 'Fidelidade';
  @override String get achvDescListening => 'Total de faixas ouvidas (scrobbles), de todos os artistas.';
  @override String get achvDescArtists => 'Número de artistas diferentes ouvidos pelo menos uma vez.';
  @override String get achvDescAlbums => 'Número de álbuns diferentes ouvidos pelo menos uma vez.';
  @override String get achvDescLoyalty => 'Tempo de conta no Last.fm.';
  @override String get achvCatTracks => 'Faixas';
  @override String get achvDescTracks => 'Número de faixas diferentes ouvidas.';
  @override String get achvCatPace => 'Ritmo';
  @override String get achvDescPace => 'Média de scrobbles por semana.';
  @override String get achvCatStreak => 'Sequência';
  @override String get achvDescStreak => 'A sequência mais longa de dias consecutivos com pelo menos uma audição.';
  @override String get achvCatMarathon => 'Maratona';
  @override String get achvDescMarathon => 'O maior número de audições em um único dia.';
  @override String get achvCatSocial => 'Social';
  @override String get achvDescSocial => 'O número de amigos ou perfis adicionados.';
  @override String get achvCatComparisons => 'Comparações';
  @override String get achvDescComparisons => 'O número de comparações de gosto musical feitas.';
  @override String get achvUnlockedBadge => 'Desbloqueado';
  @override String get achvLockedBadge => 'Bloqueado';
  @override String get dashRecap => 'Resumo';
  @override String get recapDay => 'Hoje';
  @override String get recapWeek => 'Esta semana';
  @override String get recapMonth => 'Este mês';
  @override String get recapScrobbles => 'faixas ouvidas';
  @override String get recapArtists => 'Artistas';
  @override String get recapTracks => 'Faixas';
  @override String get recapTopArtist => 'Artista top';
  @override String get recapTopTrack => 'Faixa top';
  @override String get recapTopAlbum => 'Álbum top';
  @override String get recapAvgDay => 'Média/dia';
  @override String get recapNoData => 'Sem escutas neste período.';
  @override String get recapSeeFull => 'Ver resumo completo';
  @override String get recapTop10 => 'Top 10';

  // ── Discover filters ─────────────────────────────────────────────────────
  @override String get discoverSmartTitle => 'O filtro mais útil primeiro';
  @override String get discoverSmartSub => 'Conforme a hora, o dia e o que você mais usa';
  @override String get discoverForYou => 'Para você';
  @override String get discoverGlobalTrends => 'Tendências globais';
  @override String get discoverSrcForyou => 'Seu mix';
  @override String get discoverSrcOnthisday => 'Neste dia';
  @override String get discoverSrcFresh => 'Este mês';
  @override String get discoverSrcGenre => 'Seus gêneros';
  @override String get discoverSrcDeeper => 'Faixas escondidas';
  @override String get discoverSrcForgotten => 'Esquecidas';
  @override String get discoverSrcAlbums => 'Álbuns';
  @override String get discoverSrcCountry => 'Seu país';
  @override String get discoverTracks => 'Faixas';
  @override String get discoverArtists => 'Artistas';
  @override String get discoverWeek => 'semana';
  @override String get discoverMonth => 'mês';
  @override String get discoverYear => 'ano';
  @override String get discoverNothing => 'Ainda não há nada para mostrar';
  @override String discoverLike(String names) => 'Como $names';
  @override String get dashReorderSections => 'Mudar a ordem das seções';
  @override String get dashInfiniteTitle => 'Rolagem infinita';
  @override String get dashInfiniteSub => 'O Descobrir se repete e continua sugerindo mais';
  @override String get dashDiscoverTitle => 'Descobrir';
  @override String get dashDiscoverSub => 'Ideias de música para deslizar';
  @override String get dashSortButton => 'Ordenar';
  @override String get dashSortDone => 'Concluído';
  @override String get dashSortHint => 'Arraste para mudar a ordem';
  @override String get dashSortSmartNote => 'A ordem inteligente está ligada e pode mudar essa ordem conforme o momento.';
  @override String get dashSeparateRow => 'Em uma linha só dele';
  @override String dashFiltersOf(String group) => 'Filtros de “$group”';
  @override String get apShapeSingle => 'Uma só forma';
  @override String get mvSource => 'Fonte do vídeo';
  @override String get mvSrcAuto => 'Auto (Apple Music e depois YouTube)';
  @override String get mvSrcApple => 'Apenas Apple Music';
  @override String get mvSrcYt => 'Apenas YouTube (faixas)';
  @override String get mvQualityT => 'Qualidade do vídeo';
  @override String get mvQAuto => 'Auto';
  @override String get mvQLow => 'Economia (360p)';
  @override String get mvTypesT => 'Mostrar vídeo para';
  @override String get mvTracks => 'Faixas';
  @override String get mvAlbums => 'Álbuns';
  @override String get mvArtists => 'Artistas';
  @override String get mvModeT => 'Modo';
  @override String get mvModeBest => 'Recomendado';
  @override String get mvModeSaver => 'Economia';
  @override String get mvModeMax => 'Qualidade máxima';
  @override String get mvModeCustom => 'Personalizado';
  @override String get mvSrcYtFirst => 'YouTube e depois Apple Music';

  // ── API tab ──
  @override String get apiTitle => 'API';
  @override String get apiCardSub => 'Serviços usados, cotas e consumo';
  @override String get apiSumToday => 'Pedidos hoje';
  @override String get apiSumErrors => 'Erros';
  @override String get apiSumLimited => 'Limitados';
  @override String get apiIntro => 'Os contadores cobrem apenas este dispositivo. Os fornecedores aplicam os limites por endereço IP, por isso outras apps na mesma rede também contam. A app abranda ou ignora pedidos automaticamente para os respeitar.';
  @override String get apiCatListening => 'Dados de audição';
  @override String get apiCatMetadata => 'Metadados musicais';
  @override String get apiCatArtwork => 'Capas';
  @override String get apiCatLyrics => 'Letras';
  @override String get apiCatTranslate => 'Tradução';
  @override String get apiCatUpdates => 'Atualizações e novidades';
  @override String get apiCatOther => 'Transferências de imagens';
  @override String get apiStatusIdle => 'Ainda não usada';
  @override String get apiStatusOk => 'OK';
  @override String get apiStatusNear => 'Perto do limite';
  @override String get apiStatusPaused => 'Em pausa';
  @override String get apiProviderLimit => 'Limite do fornecedor';
  @override String get apiNoLimit => 'Nenhum publicado';
  @override String get apiAppCeiling => 'Teto da app';
  @override String apiLimitPer(int n, String win) => '$n pedidos / $win';
  @override String get apiWinSecond => 'segundo';
  @override String get apiWinMinute => 'minuto';
  @override String get apiWinHour => 'hora';
  @override String apiWinSeconds(int s) => '$s segundos';
  @override String get apiWindowUsage => 'Janela atual';
  @override String get apiRemaining => 'Restantes';
  @override String apiResetsIn(String t) => 'Reinicia em $t';
  @override String apiPausedFor(String t) => 'Em pausa durante $t após uma resposta de limite atingido';
  @override String get apiToday => 'Hoje';
  @override String get apiLastHour => 'Última hora';
  @override String get apiTotal => 'Total';
  @override String get apiRateLimited => 'Respostas de limite atingido';
  @override String get apiSkipped => 'Ignorados pela app';
  @override String get apiLastCall => 'Última chamada';
  @override String get apiNever => 'Nunca';
  @override String get apiNoKey => 'Não requer chave API';
  @override String get apiSharedKey => 'Chave de teste pública partilhada (plano gratuito)';
  @override String get apiUnofficial => 'Ponto de acesso não oficial: sem cota garantida, pode mudar ou ser bloqueado sem aviso.';
  @override String get apiKeyInUse => 'Chave em uso';
  @override String get apiOwnKey => 'A sua própria chave Last.fm';
  @override String apiBuiltinKey(int n, int total) => 'Chave integrada $n de $total';
  @override String get apiBackupOn => 'Chave de reserva: ativada';
  @override String get apiBackupOff => 'Chave de reserva: desativada';
  @override String get apiPerKey => 'Pedidos por chave (hoje / total)';
  @override String get apiLastfmNote => 'O Last.fm não publica nenhum valor: devolve o erro 29 quando um IP envia demasiados pedidos, e os seus termos proíbem contorná-lo. Cerca de 5 pedidos por segundo por IP é a orientação habitual; a app fica abaixo de 4.';
  @override String get apiStorageTitle => 'Dados Last.fm armazenados';
  @override String apiStorageValue(String used, String cap) => '$used de $cap permitidos';
  @override String get apiStorageOver => 'Acima do limite de 100 MB definido pelos termos da API do Last.fm. Limpe o histórico de scrobbles em Armazenamento para cumprir.';
  @override String get apiReset => 'Repor contadores';
  @override String get apiLimiter => 'Limitar pedidos';
  @override String get apiLimiterSub => 'Abranda os pedidos para respeitar os limites das APIs. Desligado = mais rápido, sem esperas.';
  @override String get apiResetBody => 'Todos os contadores de pedidos serão repostos a zero.';
  @override String get apiResetDone => 'Contadores repostos';
}

// ══════════════════════════════════════════════════════════════════════════
//  Keyed strings (pt) — read through tx('key') / tx('key', {'n': '3'}).
//  Placeholders like {n} are replaced by tx(). Keys must exist in all 10
//  strings_xx.dart files (a missing one falls back to English, then French).
// ══════════════════════════════════════════════════════════════════════════
const Map<String, String> kTxPt = {
  'st_notif_on': 'Notificações ativadas',
  'st_notif_off': 'Notificações desativadas',
  'st_notif_count': '{n} tipos ativos',
  'st_notif_perm': 'Permissão do sistema necessária',
  'st_notif_none': 'Nenhum tipo de notificação escolhido',
  'st_sync_on': 'Sincronização automática ativada',
  'st_sync_off': 'Sincronização automática desativada',
  'st_sync_on_s': 'Seus dados se atualizam sozinhos.',
  'st_sync_off_s': 'Os dados só são atualizados quando você pede.',
  'st_bkp_on': 'Backup automático ativado',
  'st_bkp_off': 'Backup automático desativado',
  'st_bkp_on_s': 'Suas configurações são salvas automaticamente.',
  'st_bkp_off_s': 'Ative para nunca perder suas configurações.',
  'st_bkp_next': 'Próximo backup: {d}',
  'cmp_breakdown': 'O que aproxima vocês',
  'cmp_by_artists': 'Artistas',
  'cmp_by_genres': 'Gêneros',
  'cmp_by_tracks': 'Faixas',
  'cmp_by_albums': 'Álbuns',
  'eco_on': 'Economia de energia ativada',
  'eco_off': 'Economia de energia desativada',
  'eco_why_manual': 'Sempre ativada, por você',
  'eco_why_system': 'A economia de bateria do seu dispositivo está ativada',
  'eco_why_battery': 'A bateria está em {n}%',
  'eco_off_hint': 'Escolha abaixo quando ativar',
  'eco_trig': 'Quando ativar',
  'eco_sys_t': 'Quando a economia de bateria do dispositivo estiver ativada',
  'eco_sys_s': 'Acompanha o modo de economia de energia nativo do telefone e desativa junto com ele.',
  'eco_sys_na': 'Indisponível neste dispositivo.',
  'eco_chg': 'O que muda',
  'eco_chg1': 'O paralaxe de movimento é desativado',
  'eco_chg2': 'A taxa de atualização da tela é limitada a cerca de 60 Hz',
  'eco_chg3': 'As atualizações em segundo plano ficam menos frequentes',
  'eco_chg4': 'As capas animadas e o brilho dos emblemas ficam em pausa',
  'eco_chg_note': 'Todo o resto mantém a qualidade total: imagens, exportações e cartões de compartilhamento.',
  'lib_section': 'Biblioteca',
  'lib_merge_t': 'Unir versões da mesma faixa',
  'lib_merge_s': 'Remasters, singles, (feat. …) e edições deluxe contam como uma só faixa ou álbum, com as reproduções somadas. Remixes, ao vivo e instrumentais continuam separados.',
  'lib_split_t': 'Separar colaborações',
  'lib_split_s': '"Gims & Damso" conta para Gims e para Damso em vez de ser um artista à parte. Bandas como "Simon & Garfunkel" continuam inteiras.',
  'lib_step_t': 'Sua biblioteca',
  'lib_step_s': 'Escolha como agrupar suas reproduções. Você pode mudar isso a qualquer momento nas configurações.',
  'bk_dash_t': 'Painel e inicialização',
  'bk_dash_s': 'Seções, cabeçalho, cartões de estatísticas, descobrir, aba inicial',
  'bk_notif_t': 'Notificações',
  'bk_notif_s': 'Resumos, marcos, novidades e selos',
  'bk_lib_t': 'Opções da biblioteca',
  'bk_lib_s': 'Unir versões, separar colaborações',
  'bk_prof_t': 'Perfis favoritos',
  'bk_prof_s': 'Os perfis do Last.fm que você favoritou',
  'about_readme_t': 'README e atividade do projeto',
  'about_readme_s': 'Ler o README, últimos commits, workflows, versão, downloads',
  'fold_show': 'Mostrar ({n})',
  'fold_hide': 'Recolher',
  'readme_sub': 'O projeto e sua atividade',
  'readme_version': 'Versão',
  'readme_downloads': 'Downloads',
  'readme_stars': 'Estrelas',
  'readme_license': 'Licença',
  'readme_commits': 'Últimos commits',
  'readme_workflows': 'Últimos workflows',
  'readme_retry': 'Tentar novamente',
  'readme_github': 'Abrir no GitHub',
  'readme_failed': 'Não foi possível carregar (offline ou limite do GitHub atingido).',
  'ago_min': 'há {n} min',
  'ago_h': 'há {n} h',
  'ago_d': 'há {n} d',
  'load_restored': '{n} scrobbles restaurados',
  'load_ready': 'Pronto para importar',
  'load_connecting': 'Conectando ao Last.fm…',
  'load_done': 'Importação concluída',
  'load_backup_note': 'Backup detectado: só os scrobbles mais recentes serão verificados.',
  'dash_nowplay': 'Tocando agora',
  'dash_stats': 'Estatísticas',
  'dash_recent': 'Reproduções recentes',
  'dash_discover': 'Descobrir',
  'dash_friends': 'Amigos',
  'dash_chart': 'Gráfico do painel',
  'dash_calendar': 'Calendário',
  'dash_monthly': 'Mensal',
  'cache_video_t': 'Capas animadas (Apple Music)',
  'cache_video_s': 'Memória de vídeo em uso: {mem} · {players} player(s) ativo(s) · {links} link(s) em cache',
  'cache_video_short': 'Capas animadas',
  'cache_video_cleared': 'Memória de vídeo liberada',
  'cache_memory_section': 'Memória',
  'cache_storage_section': 'Armazenamento',
  'lvl': 'Nível {n}',
  'lvl_history': 'Histórico de níveis',
  'set_living_t': 'Capas animadas',
  'set_living_s': 'Zoom suave e efeito de profundidade nas imagens',
  'set_motion_t': 'Capas em vídeo',
  'set_motion_s': 'Reproduz a capa animada quando existir',
  'set_achv_t': 'Conquistas e níveis',
  'set_achv_s': 'Níveis, selos e nível da conta',
  'cache_img_limit_t': 'Limite do cache de fotos',
  'cache_img_limit_s': 'Capas, fotos de artistas e avatares. As mais antigas são removidas primeiro.',
  'cache_vid_limit_t': 'Limite do cache de vídeo',
  'cache_vid_limit_s': 'Capas animadas do Apple Music guardadas no disco para rever offline (Android).',
  'cache_video_off': 'Desativado',
  'cache_vid_disk_t': 'Vídeos do Apple Music',
  'cache_vid_disk_s': '{size} · Capas animadas guardadas',
  'cache_no_limit_note': 'Scrobbles e dados da API nunca são limitados.',
  'key_internal_use': 'Usar a chave interna do app',
  'key_internal_help': 'Opção de reserva: esta chave é partilhada entre utilizadores. Pode atingir o limite ou deixar de funcionar, e algumas funções podem falhar. Prefere a tua própria chave sempre que possível.',
  'key_internal_active': 'Chave interna do app',
  'key_fallback_title': 'Chave interna como reserva',
  'key_fallback_sub': 'Tenta a sua chave primeiro e a interna se falhar',
  'ui_play_preview': 'Reproduzir prévia',
  'ntf_test_title': '🔔 Notificação de teste',
  'ntf_test_body': 'As notificações do LastStats estão funcionando!',
  'ui_not_enough_data_yet_sy': 'Ainda não há dados suficientes — sincronize o histórico completo nas configurações.',
  'ui_level': 'Nível {level}',
  'ui_fetching': 'Buscando {currentYea}… ({yearIndex}/{totalYears})',
  'ui_which_chart': 'Qual gráfico?',
  'ui_which_period': 'Qual período?',
  'ui_all_time': 'Todo período',
  'ui_exporting': 'Exportando…',
  'ui_chart_not_available_fo': 'Gráfico indisponível para este período',
  'ui_could_not_generate_the': 'Não foi possível gerar a imagem',
  'ui_error': 'Erro',
  'ui_loading_history': 'Carregando histórico{yearLabel}… {pct}%',
  'ui_charts_will_be_more_ac': 'Os gráficos ficarão mais precisos depois de carregado.',
  'ui_load_the_full_history_': 'Carregue o histórico completo para acessar todos os anos.',
  'ui_load': 'Carregar',
  'ui_based_on_scrobbles_all': 'Baseado em {v_hourlyCou} scrobbles (todos os anos)',
  'ui_all_available_years': 'Todos os anos disponíveis',
  'ui_based_on_scrobbles_fro': 'Baseado em {v_hourlyCou} scrobbles de {v_selectedY}',
  'ui_based_on_recent_scrobb': 'Baseado em {v_hourlyCou} scrobbles recentes',
  'ui_analysing_your_last_20': 'Analisando seus últimos ~200 scrobbles',
  'ui_all_time_loading': 'Todo o período (dados de {v_selectedY} carregando)',
  'ui_all_time_2': 'Todo o período',
  'ui_export_a_chart': 'Exportar um gráfico',
  'ui_scrobble_progression': 'Progressão de scrobbles',
  'ui_your_musical_genres': 'Seus gêneros musicais',
  'ui_based_on_your_top_arti': 'Baseado nos seus artistas favoritos (todo o período)',
  'ui_listening_habits': 'Hábitos de escuta',
  'ui_album_distribution': 'Distribuição por álbum',
  'ui_listening_calendar': 'Calendário de escuta',
  'ui_daily_activity_to': 'Atividade diária — {first} a {last}',
  'ui_daily_activity_all_yea': 'Atividade diária — todos os anos',
  'ui_daily_activity': 'Atividade diária — {v_selectedY}',
  'ui_load_history_to_see': 'Carregue o histórico para ver {v_selectedY}',
  'ui_daily_activity_last_12': 'Atividade diária — últimos 12 meses',
  'ui_all_years': 'todos os anos',
  'ui_listening_streaks': 'Sequências de escuta',
  'ui_total': 'Total',
  'ui_avg_mo': 'Média/mês',
  'ui_best_month': 'Melhor mês',
  'ui_hourly_distribution': 'Distribuição por hora',
  'ui_activity_by_day_of_wee': 'Atividade por dia da semana',
  'ui_current_streak': 'Sequência atual',
  'ui_d': 'd',
  'ui_best_streak': 'Melhor sequência',
  'ui_best_streak_started_on': 'Melhor sequência desde {bestStart}',
  'ui_no_data_for_this_perio': 'Sem dados para este período',
  'ui_load_history_to_displa': 'Carregue o histórico para exibir {what}',
  'ui_less': 'Menos',
  'ui_more': 'Mais',
  'ui_scan_a_profile': 'Escanear um perfil',
  'ui_lvl': 'Nív. {level}',
  'ui_qr_code': 'Código QR?',
  'ui_add_a_qr_code_to_the_s': 'Adicionar um código QR à imagem compartilhada, para que quem a vir possa escanear seu perfil?',
  'ui_no_qr': 'Sem QR',
  'ui_to_the_app': 'Para o app',
  'ui_to_last_fm': 'Para o Last.fm',
  'ui_compare_music_taste': 'Comparar gostos musicais',
  'ui_syncing_full_library': 'Sincronizando dados…',
  'ui_see_more': 'Ver mais',
  'ui_no_achievements_unlock': 'Nenhuma conquista desbloqueada ainda',
  'ui_no_animated_cover_for_': 'Não há capa animada para este álbum',
  'ui_source': 'Fonte: {source}',
  'ui_view_on_last_fm': 'Ver no Last.fm',
  'ui_original_text_last_fm_': 'Texto original: Last.fm — Tradução: Google Translate',
  'ui_source_last_fm': 'Fonte: Last.fm',
  'ui_dark': 'Escuro',
  'ui_light': 'Claro',
  'ui_system': 'Sistema',
  'ui_colored_widgets': 'Widgets coloridos',
  'ui_tint_home_screen_widge': 'Aplica a cor de destaque aos widgets',
  'ui_search_settings': 'Pesquisar configuração…',
  'ui_no_settings_found': 'Nenhuma configuração encontrada',
  'ui_all': 'Todas',
  'ui_battery_saver': 'Economia de bateria',
  'ui_save_battery_fewer_eff': 'Economize bateria, menos efeitos',
  'ui_musical_soulmates': 'Almas musicais gêmeas',
  'ui_great_compatibility': 'Ótima compatibilidade',
  'ui_some_common_ground': 'Alguns pontos em comum',
  'ui_fairly_different_taste': 'Gostos bem diferentes',
  'ui_worlds_apart_musically': 'Universos musicais opostos',
  'ui_this_is_your_own_profi': 'Este é o seu próprio perfil!',
  'ui_artists_from_your_hist': '{uniqueArti} artistas do seu histórico · biblioteca completa de {targetUser}',
  'ui_artists_from_your_hist_2': '{uniqueArti} artistas do seu histórico · top 200 de {targetUser}',
  'ui_full_library_api': 'Biblioteca completa (API)',
  'ui_top_200_artists_tracks': 'Top 200 artistas e faixas (API)',
  'ui_could_not_work_out_the': 'Não foi possível calcular a compatibilidade.',
  'ui_music_compatibility': 'Compatibilidade musical',
  'ui_analyzing_musical_tast': 'Analisando gostos musicais…',
  'ui_artist': '{v_totalArti} artista{v_totalArti2}',
  'ui_track': '{v_totalTrac} faixa{v_totalTrac2}',
  'ui_album': '{v_totalAlbu} álbum{v_totalAlbu2}',
  'ui_shared_tracks': 'Faixas em comum',
  'ui_shared_artists': 'Artistas em comum',
  'ui_no_shared_artists_foun': 'Nenhum artista em comum encontrado.',
  'ui_shared_albums': 'Álbuns em comum',
  'ui_play_count_unavailable': 'Contagem de reproduções indisponível para um dos dois.',
  'ui_you_listen_to_this_x_m': 'Você escuta isso {x}x mais que {theirUsern}.',
  'ui_listens_to_this_x_more': '{theirUsern} escuta isso {x}x mais que você.',
  'ui_you_both_listen_to_thi': 'Vocês dois escutam isso quase igualmente.',
  'ui_plays': '{plays} reproduções',
  'ui_compatibility': 'compatibilidade',
  'ui_you_both_love': 'VOCÊS DOIS AMAM',
  'ui_shared_top_artist': 'ARTISTA FAVORITO EM COMUM',
  'ui_achievements': 'Conquistas',
  'ui_qr_not_recognized_not_': 'QR não reconhecido — não é um perfil do LastStats/Last.fm',
  'ui_scan_a_profile_s_qr_co': 'Escaneie o código QR de um perfil',
  'ui_favorites': 'Favoritos',
  'ui_advanced_youtube_music': 'Cliente avançado do YouTube Music.',
  'ui_syncs_the_glyphs_of_no': 'Sincroniza os Glyphs dos telefones Nothing com a música.',
  'ui_sources': 'Fontes',
  'ui_official_flutter_docs_': 'Documentação oficial do Flutter.',
  'ui_official_material_3_gu': 'Guia oficial do Material 3 para Flutter.',
  'ui_flutter_api_reference_': 'Referência da API Flutter para o Material 3.',
  'ui_official_flutter_packa': 'Pacote oficial do Flutter para layouts adaptativos.',
  'ui_android_widgets': 'Widgets do Android',
  'ui_applies_the_accent_col': 'Aplica a cor de destaque ao fundo dos widgets da tela inicial. Desativado: branco ou preto puro.',
  'ui_turns_off_tilt_paralla': 'Desativa o paralaxe de movimento, limita a taxa de atualização da tela e desacelera as atualizações em segundo plano — o resto mantém a qualidade total (imagens, exportações, cartões de compartilhamento).',
  'ui_always_on': 'Sempre ativado',
  'ui_force_eco_mode_on_rega': 'Força o modo de economia, independentemente do nível da bateria.',
  'ui_auto_activate': 'Ativação automática',
  'ui_turn_on_below_a_batter': 'Ativar abaixo de um % de bateria',
  'ui_switches_on_by_itself_': 'Ativa sozinho quando a bateria cair até o nível abaixo.',
  'ui_threshold': 'Limite',
  'ui_choose_the_tab_display': 'Escolha a aba exibida ao iniciar o app.',
  'ui_the_selected_tab_will_': 'A aba selecionada aparecerá na próxima vez que o app for iniciado.',
  'ui_friends_sync': 'Sincronização de amigos',
  'ui_sync_frequency': 'Frequência de sincronização',
  'ui_daily': 'Todos os dias',
  'ui_resync_everyone': 'Ressincronizar tudo',
  'ui_version_history': 'Histórico de versões',
  'ui_could_not_load_release': 'Não foi possível carregar o histórico.',
  'ui_installed_dev_build_un': 'Instalada: build de desenvolvimento (versão desconhecida)',
  'ui_installed': 'Instalada: {displayVer}',
  'ui_search_a_version_or_ch': 'Buscar uma versão ou changelog…',
  'ui_official': 'Oficial',
  'ui_no_release_matches_you': 'Nenhuma versão corresponde à sua busca.',
  'ui_latest': 'ÚLTIMA',
  'ui_installed_2': 'INSTALADA',
  'ui_no_description': 'Sem descrição.',
  'ui_download': 'Baixar',
  'ui_view_release': 'Ver release',
  'ui_details': 'Detalhes',
  'ui_all_past_releases_chan': 'Todas as versões anteriores, changelogs e downloads',
  'ui_please_fill_both_field': 'Preencha os dois campos.',
  'ui_api_key_must_be_32_cha': 'A chave da API deve ter 32 caracteres.',
  'ui_profile_not_found': 'Perfil não encontrado.',
  'ui_chart_monthly': 'Barras mensais',
  'ui_chart_cumul': 'Progressão',
  'ui_chart_genres': 'Gêneros musicais',
  'ui_chart_habits': 'Hábitos de escuta',
  'ui_chart_artists': 'Distribuição de artistas',
  'ui_chart_albums': 'Distribuição de álbuns',
  'ui_chart_calendar': 'Calendário de escuta',
  'ui_chart_streaks': 'Sequências de escuta',
  'ui_band_night': 'Noite',
  'ui_band_morning': 'Manhã',
  'ui_band_afternoon': 'Tarde',
  'ui_band_evening': 'Noite',
  'qs_t1_t': 'Modo OLED',
  'qs_t1_s': 'Fundo preto puro',
  'qs_t2_t': 'Modo de economia de energia',
  'qs_t2_s': 'Reduz o uso da bateria',
  'qs_t3_t': 'Notificações de notícias',
  'qs_t3_s': 'Alertas sobre novidades do Last.fm',
  'qs_t4_t': 'Feedback tátil',
  'qs_t4_s': 'Vibrações nas interações',
  'qs_t5_t': 'Conquistas',
  'qs_t5_s': 'Mostra as conquistas desbloqueadas',
  'qs_l1_t': 'Cor de destaque',
  'qs_l2_t': 'Tema',
  'qs_l3_t': 'Idioma',
  'qs_l4_t': 'Plataforma musical',
  'qs_l5_t': 'Conta',
  'qs_l6_t': 'Sincronização',
  'qs_l7_t': 'Cache',
  'img_src_lastfm': 'Fonte: Last.fm',
  'img_src_ytmusic': 'Fonte: YouTube Music',
  'img_src_itunes': 'Fonte: iTunes',
  'img_src_deezer': 'Fonte: Deezer',
  'img_src_audiodb': 'Fonte: TheAudioDB',
  'img_src_musicbrainz': 'Fonte: MusicBrainz',
  'img_src_wikipedia': 'Fonte: Wikipedia',
  'ds_type_artist': 'Artista',
  'ds_type_album': 'Álbum',
  'ds_type_track': 'Faixa',
  'pf_1': '👤 Perfil do usuário',
  'pf_2': '🎤 Top artistas — Geral',
  'pf_3': '💿 Top álbuns — Geral',
  'pf_4': '🎵 Top faixas — Geral',
  'pf_5': '⏱️ Reproduções recentes',
  'pf_6': '🗓️ Esta semana',
  'pf_7': '📅 Este mês',
  'pf_8': '📅 Últimos 3 meses',
  'pf_9': '📅 Últimos 6 meses',
  'pf_10': '📅 Últimos 12 meses',
  'pf_11': '📊 Histórico mensal',
  'pf_12': '❤️ Faixas curtidas',
  'pf_13': '🗓️ Top artistas — Semana',
  'pf_14': '🗓️ Álbuns e faixas — Semana',
  'ds_tier_next': '{n} / {next} para o próximo nível',
  'ds_tier_max': 'Nível máximo atingido 🎉',
  'ds_tier_first': 'Ouça esta faixa para desbloquear um primeiro nível (a partir de {n} reproduções).',
  'sl_import': 'Importando seus dados',
  'sl_done': 'Importado!',
  'sl_connect': 'Conectando ao Last.fm…',
};
