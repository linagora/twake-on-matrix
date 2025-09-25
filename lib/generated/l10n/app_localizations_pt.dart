// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class L10nPt extends L10n {
  L10nPt([String locale = 'pt']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'As palavras-passe não correspondem!';

  @override
  String get pleaseEnterValidEmail =>
      'Por favor, insere um endereço de correio eletrónico válido.';

  @override
  String get repeatPassword => 'Repete a palavra-passe';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Por favor, usa no mínimo $min caracteres.';
  }

  @override
  String get about => 'Acerca de';

  @override
  String get updateAvailable => 'Twake Chat update available';

  @override
  String get updateNow => 'Iniciar atualização em segundo plano';

  @override
  String get accept => 'Aceitar';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username aceitou o convite';
  }

  @override
  String get account => 'Conta';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username ativou encriptação ponta-a-ponta';
  }

  @override
  String get addEmail => 'Adicionar correio eletrónico';

  @override
  String get confirmMatrixId =>
      'Por favor, confirme o seu ID Matrix para apagar a sua conta.';

  @override
  String supposedMxid(Object mxid) {
    return 'Isto deveria ser $mxid';
  }

  @override
  String get addGroupDescription => 'Adicionar descrição de grupo';

  @override
  String get addToSpace => 'Adicionar ao espaço';

  @override
  String get admin => 'Admin';

  @override
  String get alias => 'alcunha';

  @override
  String get all => 'Todos(as)';

  @override
  String get allChats => 'Todas as conversas';

  @override
  String get commandHint_googly => 'Enviar olhos grilidos';

  @override
  String get commandHint_cuddle => 'Enviar um afago';

  @override
  String get commandHint_hug => 'Enviar um abraço';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName enviou olhos grilidos';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName afagou-o';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName abraçou-o';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName atendeu a chamada';
  }

  @override
  String get anyoneCanJoin => 'Qualquer pessoa pode entrar';

  @override
  String get appLock => 'Bloqueio da aplicação';

  @override
  String get archive => 'Arquivo';

  @override
  String get archivedRoom => 'Sala arquivada';

  @override
  String get areGuestsAllowedToJoin => 'Todos os visitantes podem entrar';

  @override
  String get areYouSure => 'Tens a certeza?';

  @override
  String get areYouSureYouWantToLogout => 'Tens a certeza que queres sair?';

  @override
  String get askSSSSSign =>
      'Para poderes assinar a outra pessoa, por favor, insere a tua palavra-passe de armazenamento seguro ou a chave de recuperação.';

  @override
  String askVerificationRequest(Object username) {
    return 'Aceitar este pedido de verificação de $username?';
  }

  @override
  String get autoplayImages =>
      'Automaticamente reproduzir autocolantes e emotes animados';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'The homeserver supports the login types:\n$serverVersions\nBut this app supports only:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Enviar com Enter';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'The homeserver supports the Spec versions:\n$serverVersions\nBut this app supports only $supportedVersions';
  }

  @override
  String get banFromChat => 'Banir da conversa';

  @override
  String get banned => 'Banido(a)';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username baniu $targetName';
  }

  @override
  String get blockDevice => 'Bloquear dispositivo';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get botMessages => 'Mensagens de robôs';

  @override
  String get bubbleSize => 'Tamanho da bolha';

  @override
  String get cancel => 'Cancelar';

  @override
  String cantOpenUri(Object uri) {
    return 'Não é possível abrir o URI $uri';
  }

  @override
  String get changeDeviceName => 'Alterar nome do dispositivo';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username alterou o avatar da conversa';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username alterou a descrição da conversa para: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username alterou o nome da conversa para: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username alterou as permissões da conversa';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username alterou o seu nome para: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username alterou as regras de acesso de visitantes';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username alterou as regras de acesso de visitantes para: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username alterou a visibilidade do histórico';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username alterou a visibilidade do histórico para: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username alterou as regras de entrada';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username alterou as regras de entrada para: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username alterou o seu avatar';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username alterou as alcunhas da sala';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username alterou a ligação de convite';
  }

  @override
  String get changePassword => 'Alterar palavra-passe';

  @override
  String get changeTheHomeserver => 'Alterar o servidor';

  @override
  String get changeTheme => 'Alterar o teu estilo';

  @override
  String get changeTheNameOfTheGroup => 'Alterar o nome do grupo';

  @override
  String get changeWallpaper => 'Alterar o fundo';

  @override
  String get changeYourAvatar => 'Alterar o teu avatar';

  @override
  String get channelCorruptedDecryptError => 'A encriptação foi corrompida';

  @override
  String get chat => 'Conversa';

  @override
  String get yourUserId => 'O teu ID de utilizador:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'A cópia de segurança foi configurada.';

  @override
  String get chatBackup => 'Cópia de segurança de conversas';

  @override
  String get chatBackupDescription =>
      'A tuas mensagens antigas estão protegidas com uma chave de recuperação. Por favor, certifica-te que não a perdes.';

  @override
  String get chatDetails => 'Pormenores de conversa';

  @override
  String get chatHasBeenAddedToThisSpace =>
      'A conversa foi adicionada a este espaço';

  @override
  String get chats => 'Chats';

  @override
  String get chooseAStrongPassword => 'Escolhe uma palavra-passe forte';

  @override
  String get chooseAUsername => 'Escolhe um nome de utilizador';

  @override
  String get clearArchive => 'Limpar arquivo';

  @override
  String get close => 'Fechar';

  @override
  String get commandHint_markasdm => 'Marcar como conversa direta';

  @override
  String get commandHint_markasgroup => 'Marcar como grupo';

  @override
  String get commandHint_ban => 'Banir o utilizador dado desta sala';

  @override
  String get commandHint_clearcache => 'Limpar cache';

  @override
  String get commandHint_create =>
      'Criar uma conversa de grupo vazia\nUsa --no-encryption para desativar a encriptação';

  @override
  String get commandHint_discardsession => 'Descartar sessão';

  @override
  String get commandHint_dm =>
      'Iniciar uma conversa direta\nUsa --no-encryption para desativar a encriptação';

  @override
  String get commandHint_html => 'Enviar texto formatado com HTML';

  @override
  String get commandHint_invite => 'Convidar o utilizador dado a esta sala';

  @override
  String get commandHint_join => 'Entrar na sala dada';

  @override
  String get commandHint_kick => 'Remover o utilizador dado desta sala';

  @override
  String get commandHint_leave => 'Sair desta sala';

  @override
  String get commandHint_me => 'Descreve-te';

  @override
  String get commandHint_myroomavatar =>
      'Definir a tua imagem para esta sala (por mxc-uri)';

  @override
  String get commandHint_myroomnick => 'Definir o teu nome para esta sala';

  @override
  String get commandHint_op =>
      'Definir o nível de poder do utilizador dado (por omissão: 50)';

  @override
  String get commandHint_plain => 'Enviar texto não formatado';

  @override
  String get commandHint_react => 'Enviar respostas como reações';

  @override
  String get commandHint_send => 'Enviar texto';

  @override
  String get commandHint_unban => 'Perdoar o utilizador dado';

  @override
  String get commandInvalid => 'Comando inválido';

  @override
  String commandMissing(Object command) {
    return '$command não é um comando.';
  }

  @override
  String get compareEmojiMatch => 'Please compare the emojis';

  @override
  String get compareNumbersMatch => 'Please compare the numbers';

  @override
  String get configureChat => 'Configurar conversa';

  @override
  String get confirm => 'Confirmar';

  @override
  String get connect => 'Connect';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'O contacto foi convidado para o grupo';

  @override
  String get containsDisplayName => 'Contém nome de exibição';

  @override
  String get containsUserName => 'Contém nome de utilizador';

  @override
  String get contentHasBeenReported =>
      'O conteúdo foi denunciado aos admins do servidor';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get copy => 'Copiar';

  @override
  String get copyToClipboard => 'Copiar para a área de transferência';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Não foi possível desencriptar mensagem: $error';
  }

  @override
  String countMembers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'no members',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Criar';

  @override
  String createdTheChat(Object username) {
    return '$username criou a conversa';
  }

  @override
  String get createNewGroup => 'Criar grupo';

  @override
  String get createNewSpace => 'Novo espaço';

  @override
  String get crossSigningEnabled => 'Assinatura cruzada ativada';

  @override
  String get currentlyActive => 'Ativo(a) agora';

  @override
  String get darkTheme => 'Escuro';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date às $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$day-$month';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$day-$month-$year';
  }

  @override
  String get deactivateAccountWarning =>
      'Isto irá desativar a tua conta. Não é reversível! Tens a certeza?';

  @override
  String get defaultPermissionLevel => 'Nível de permissão normal';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteMessage => 'Eliminar mensagem';

  @override
  String get deny => 'Recusar';

  @override
  String get device => 'Dispositivo';

  @override
  String get deviceId => 'ID de dispositivo';

  @override
  String get devices => 'Dispositivos';

  @override
  String get directChats => 'Conversas diretas';

  @override
  String get discover => 'Descobrir';

  @override
  String get displaynameHasBeenChanged => 'Nome de exibição alterado';

  @override
  String get download => 'Descarregar';

  @override
  String get edit => 'Editar';

  @override
  String get editBlockedServers => 'Editar servidores bloqueados';

  @override
  String get editChatPermissions => 'Editar permissões de conversa';

  @override
  String get editDisplayname => 'Editar nome de exibição';

  @override
  String get editRoomAliases => 'Editar alcunhas da sala';

  @override
  String get editRoomAvatar => 'Editar avatar da sala';

  @override
  String get emoteExists => 'Emote já existente!';

  @override
  String get emoteInvalid => 'Código de emote inválido!';

  @override
  String get emotePacks => 'Pacotes de emotes da sala';

  @override
  String get emoteSettings => 'Configurações de emotes';

  @override
  String get emoteShortcode => 'Código do emote';

  @override
  String get emoteWarnNeedToPick =>
      'Precisas de escolher um código de emote e uma imagem!';

  @override
  String get emptyChat => 'Conversa vazia';

  @override
  String get enableEmotesGlobally => 'Ativar pacote de emotes globalmente';

  @override
  String get enableEncryption => 'Enable end-to-end encryption';

  @override
  String get enableEncryptionWarning =>
      'Nunca mais poderás desativar a encriptação. Tens a certeza?';

  @override
  String get encrypted => 'Encriptada';

  @override
  String get encryption => 'Encriptação';

  @override
  String get encryptionNotEnabled => 'A encriptação não está ativada';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName terminou a chamada';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Insere um endereço de correio eletrónico';

  @override
  String get enterASpacepName => 'Insere o nome do espaço';

  @override
  String get homeserver => 'Servidor';

  @override
  String get enterYourHomeserver => 'Insere o teu servidor';

  @override
  String errorObtainingLocation(Object error) {
    return 'Erro ao obter localização: $error';
  }

  @override
  String get everythingReady => 'Tudo a postos!';

  @override
  String get extremeOffensive => 'Extremamente ofensivo';

  @override
  String get fileName => 'Nome do ficheiro';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Tamanho da letra';

  @override
  String get forward => 'Reencaminhar';

  @override
  String get friday => 'sexta-feira';

  @override
  String get fromJoining => 'Desde que entrou';

  @override
  String get fromTheInvitation => 'Desde o convite';

  @override
  String get goToTheNewRoom => 'Ir para a nova sala';

  @override
  String get group => 'Grupo';

  @override
  String get groupDescription => 'Group chat description';

  @override
  String get groupDescriptionHasBeenChanged => 'Group chat description changed';

  @override
  String get groupIsPublic => 'Group chat is public';

  @override
  String get groups => 'Group chats';

  @override
  String groupWith(Object displayname) {
    return 'Group chat with $displayname';
  }

  @override
  String get guestsAreForbidden => 'São proibidos visitantes';

  @override
  String get guestsCanJoin => 'Podem entrar visitantes';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username revogou o convite para $targetName';
  }

  @override
  String get help => 'Ajuda';

  @override
  String get hideRedactedEvents => 'Esconder eventos eliminados';

  @override
  String get hideUnknownEvents => 'Esconder eventos desconhecidos';

  @override
  String get howOffensiveIsThisContent => 'Quão ofensivo é este conteúdo?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identidade';

  @override
  String get ignore => 'Ignorar';

  @override
  String get ignoredUsers => 'Utilizadores ignorados';

  @override
  String get ignoreListDescription =>
      'Podes ignorar utilizadores que te incomodem. Não irás poder receber quaisquer mensagens ou convites para salas de utilizadores na tua lista pessoal de ignorados.';

  @override
  String get ignoreUsername => 'Nome do utilizador a ignorar';

  @override
  String get iHaveClickedOnLink => 'Cliquei na ligação';

  @override
  String get incorrectPassphraseOrKey =>
      'Palavra-passe ou chave de recuperação incorretos';

  @override
  String get inoffensive => 'Inofensivo';

  @override
  String get inviteContact => 'Convidar contacto';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Convidar contacto para $groupName';
  }

  @override
  String get invited => 'Convidado(a)';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username convidou $targetName';
  }

  @override
  String get invitedUsersOnly => 'Utilizadores(as) convidados(as) apenas';

  @override
  String get inviteForMe => 'Convite para mim';

  @override
  String inviteText(Object username, Object link) {
    return '$username convidou-te para o FluffyChat.\n1. Instala o FluffyChat: https://fluffychat.im\n2. Regista-te ou inicia sessão.\n3. Abre a ligação de convite: $link';
  }

  @override
  String get isTyping => 'está a escrever';

  @override
  String joinedTheChat(Object username) {
    return '$username entrou na conversa';
  }

  @override
  String get joinRoom => 'Entrar na sala';

  @override
  String get keysCached => 'Chaves estão armazenadas em cache';

  @override
  String kicked(Object username, Object targetName) {
    return '$username expulsou $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username expulsou e baniu $targetName';
  }

  @override
  String get kickFromChat => 'Expulsar da conversa';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Ativo(a) pela última vez: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Visto(a) há muito tempo';

  @override
  String get leave => 'Sair';

  @override
  String get leftTheChat => 'Saiu da conversa';

  @override
  String get license => 'Licença';

  @override
  String get lightTheme => 'Claro';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Carregar mais $count participantes';
  }

  @override
  String get dehydrate => 'Exportar sessão e limpar dispositivo';

  @override
  String get dehydrateWarning =>
      'Esta ação não pode ser revertida. Assegura-te que guardas bem a cópia de segurança.';

  @override
  String get dehydrateShare =>
      'Esta é a tua exportação privada do FluffyChat. Assegura-te que não a perdes e que a manténs privada.';

  @override
  String get dehydrateTor => 'Utilizadores do TOR: Exportar sessão';

  @override
  String get dehydrateTorLong =>
      'Para utilizadores do TOR, é recomendado exportar a sessão antes de fechar a janela.';

  @override
  String get hydrateTor => 'Utilizadores do TOR: Importar sessão';

  @override
  String get hydrateTorLong =>
      'Exportaste a tua sessão na última vez que estiveste no TOR? Importa-a rapidamente e continua a conversar.';

  @override
  String get hydrate => 'Restaurar a partir de cópia de segurança';

  @override
  String get loadingPleaseWait => 'A carregar... Por favor aguarde.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Carregar mais…';

  @override
  String get locationDisabledNotice =>
      'Os serviços de localização estão desativados. Por favor, ativa-os para poder partilhar a sua localização.';

  @override
  String get locationPermissionDeniedNotice =>
      'Permissão de localização recusada. Por favor, concede permissão para poderes partilhar a tua posição.';

  @override
  String get login => 'Entrar';

  @override
  String logInTo(Object homeserver) {
    return 'Entrar em $homeserver';
  }

  @override
  String get loginWithOneClick => 'Entrar com um clique';

  @override
  String get logout => 'Sair';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Certifica-te que o identificador é válido';

  @override
  String get memberChanges => 'Alterações de membros';

  @override
  String get mention => 'Mencionar';

  @override
  String get messages => 'Mensagens';

  @override
  String get messageWillBeRemovedWarning =>
      'A mensagem será eliminada para todos os participantes';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'Moderador';

  @override
  String get monday => 'segunda-feira';

  @override
  String get muteChat => 'Silenciar conversa';

  @override
  String get needPantalaimonWarning =>
      'Please be aware that you need Pantalaimon to use end-to-end encryption for now.';

  @override
  String get newChat => 'Nova conversa';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Novo pedido de verificação!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Próximo';

  @override
  String get no => 'Não';

  @override
  String get noConnectionToTheServer => 'Nenhuma ligação ao servidor';

  @override
  String get noEmotesFound => 'Nenhuns emotes encontrados. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Só podes ativar a encriptação quando a sala não for publicamente acessível.';

  @override
  String get noGoogleServicesWarning =>
      'Parece que não tens nenhuns serviços da Google no teu telemóvel. É uma boa decisão para a tua privacidade! Para receber notificações instantâneas no FluffyChat, recomendamos que uses https://microg.org/ ou https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 não é um servidor Matrix, usar $server2?';
  }

  @override
  String get shareYourInviteLink => 'Partilhar a ligação de convite';

  @override
  String get typeInInviteLinkManually =>
      'Escrever a ligação de convite manualmente...';

  @override
  String get scanQrCode => 'Escanear o código QR';

  @override
  String get none => 'Nenhum';

  @override
  String get noPasswordRecoveryDescription =>
      'Ainda não adicionaste uma forma de recuperar a tua palavra-passe.';

  @override
  String get noPermission => 'Sem permissão';

  @override
  String get noRoomsFound => 'Não foram encontradas nenhumas salas…';

  @override
  String get notifications => 'Notificações';

  @override
  String numUsersTyping(Object count) {
    return 'Estão $count utilizadores(as) a escrever';
  }

  @override
  String get obtainingLocation => 'A obter localização…';

  @override
  String get offensive => 'Offensivo';

  @override
  String get offline => 'Offline';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'ok';

  @override
  String get online => 'Online';

  @override
  String get onlineKeyBackupEnabled =>
      'A cópia de segurança online de chaves está ativada';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Ups! Infelizmente, ocorreu um erro ao configurar as notificações instantâneas.';

  @override
  String get oopsSomethingWentWrong => 'Ups, algo correu mal…';

  @override
  String get openAppToReadMessages => 'Abrir aplicação para ler mensagens';

  @override
  String get openCamera => 'Abrir câmara';

  @override
  String get openVideoCamera => 'Abra a câmara para um vídeo';

  @override
  String get oneClientLoggedOut => 'Um dos teus clientes terminou sessão';

  @override
  String get addAccount => 'Adicionar conta';

  @override
  String get editBundlesForAccount => 'Editar pacotes para esta conta';

  @override
  String get addToBundle => 'Adicionar ao pacote';

  @override
  String get removeFromBundle => 'Remover deste pacote';

  @override
  String get bundleName => 'Nome do pacote';

  @override
  String get enableMultiAccounts =>
      '(BETA) Ativar múltiplas contas neste dispositivo';

  @override
  String get openInMaps => 'Abrir nos mapas';

  @override
  String get link => 'Ligação';

  @override
  String get serverRequiresEmail =>
      'Este servidor precisa de validar o teu endereço de correio eletrónico para o registo.';

  @override
  String get optionalGroupName => '(Opcional) Nome do grupo';

  @override
  String get or => 'Ou';

  @override
  String get participant => 'Participante';

  @override
  String get passphraseOrKey => 'palavra-passe ou chave de recuperação';

  @override
  String get password => 'Palavra-passe';

  @override
  String get passwordForgotten => 'Palavra-passe esquecida';

  @override
  String get passwordHasBeenChanged => 'A palavra-passe foi alterada';

  @override
  String get passwordRecovery => 'Recuperação de palavra-passe';

  @override
  String get people => 'Pessoas';

  @override
  String get pickImage => 'Escolher uma imagem';

  @override
  String get pin => 'Afixar';

  @override
  String play(Object fileName) {
    return 'Reproduzir $fileName';
  }

  @override
  String get pleaseChoose => 'Por favor, escolhe';

  @override
  String get pleaseChooseAPasscode => 'Por favor, escolhe um código-passe';

  @override
  String get pleaseChooseAUsername =>
      'Por favor, escolhe um nome de utilizador';

  @override
  String get pleaseClickOnLink =>
      'Por favor, clica na ligação no correio eletrónico e depois continua.';

  @override
  String get pleaseEnter4Digits =>
      'Por favor, insere 4 dígitos ou deixa vazio para desativar o bloqueio da aplicação.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Por favor, insere um ID Matrix.';

  @override
  String get pleaseEnterRecoveryKey =>
      'Por favor, insira a sua chave de recuperação:';

  @override
  String get pleaseEnterYourPassword => 'Por favor, insere a tua palavra-passe';

  @override
  String get pleaseEnterYourPin => 'Por favor, insere o teu código';

  @override
  String get pleaseEnterYourUsername =>
      'Por favor, insere o teu nome de utilizador';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Por favor, segue as instruções no website e clica em \"Seguinte\".';

  @override
  String get privacy => 'Privacidade';

  @override
  String get publicRooms => 'Salas públicas';

  @override
  String get pushRules => 'Regras de notificação';

  @override
  String get reason => 'Razão';

  @override
  String get recording => 'A gravar';

  @override
  String redactedAnEvent(Object username) {
    return '$username eliminou um evento';
  }

  @override
  String get redactMessage => 'Eliminar mensagem';

  @override
  String get register => 'Registar';

  @override
  String get reject => 'Rejeitar';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username rejeitou o convite';
  }

  @override
  String get rejoin => 'Reentrar';

  @override
  String get remove => 'Remover';

  @override
  String get removeAllOtherDevices => 'Remover todos os outros dispositivos';

  @override
  String removedBy(Object username) {
    return 'Removido por $username';
  }

  @override
  String get removeDevice => 'Remover dispositivo';

  @override
  String get unbanFromChat => 'Perdoar nesta conversa';

  @override
  String get removeYourAvatar => 'Remover o teu avatar';

  @override
  String get renderRichContent => 'Exibir conteúdo de mensagem rico';

  @override
  String get replaceRoomWithNewerVersion =>
      'Substituir sala com versão mais recente';

  @override
  String get reply => 'Responder';

  @override
  String get reportMessage => 'Reportar mensagem';

  @override
  String get requestPermission => 'Pedir permissão';

  @override
  String get roomHasBeenUpgraded => 'A sala foi atualizada';

  @override
  String get roomVersion => 'Versão da sala';

  @override
  String get saturday => 'sábado';

  @override
  String get saveFile => 'Guardar ficheiro';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Segurança';

  @override
  String get recoveryKey => 'Chave de recuperação';

  @override
  String get recoveryKeyLost => 'Perdeu a chave de recuperação?';

  @override
  String seenByUser(Object username) {
    return 'Visto por $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visto por $username e mais $count pessoas',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Visto por $username e por $username2';
  }

  @override
  String get send => 'Enviar';

  @override
  String get sendAMessage => 'Enviar a mensagem';

  @override
  String get sendAsText => 'Enviar como texto';

  @override
  String get sendAudio => 'Enviar áudio';

  @override
  String get sendFile => 'Enviar ficheiro';

  @override
  String get sendImage => 'Enviar imagem';

  @override
  String get sendMessages => 'Enviar mensagens';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Enviar original';

  @override
  String get sendSticker => 'Enviar autocolante';

  @override
  String get sendVideo => 'Enviar vídeo';

  @override
  String sentAFile(Object username) {
    return '$username enviar um ficheiro';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username enviar um áudio';
  }

  @override
  String sentAPicture(Object username) {
    return '$username enviar uma imagem';
  }

  @override
  String sentASticker(Object username) {
    return '$username enviou um autocolante';
  }

  @override
  String sentAVideo(Object username) {
    return '$username enviou um vídeo';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName enviou informações de chamada';
  }

  @override
  String get separateChatTypes => 'Separar Conversas Diretas e Grupos';

  @override
  String get setAsCanonicalAlias => 'Fixar como cognome principal';

  @override
  String get setCustomEmotes => 'Implantar emojis personalizados';

  @override
  String get setGroupDescription => 'Fixar uma descrição do grupo';

  @override
  String get setInvitationLink => 'Enviar ligação de convite';

  @override
  String get setPermissionsLevel => 'Determinar níveis de permissão';

  @override
  String get setStatus => 'Alterar o estado';

  @override
  String get settings => 'Configurações';

  @override
  String get share => 'Partilhar';

  @override
  String sharedTheLocation(Object username) {
    return '$username partilhou a localização deles';
  }

  @override
  String get shareLocation => 'Partilhar localização';

  @override
  String get showDirectChatsInSpaces =>
      'Mostrar Conversas Diretas relacionadas nos Espaços';

  @override
  String get showPassword => 'Mostrar palavra-passe';

  @override
  String get signUp => 'Registar';

  @override
  String get singlesignon => 'Identidade Única';

  @override
  String get skip => 'Pular';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Código fonte';

  @override
  String get spaceIsPublic => 'Espaço é público';

  @override
  String get spaceName => 'Nome do espaço';

  @override
  String startedACall(Object senderName) {
    return '$senderName iniciou uma chamada';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Estado';

  @override
  String get statusExampleMessage => 'Como está?';

  @override
  String get submit => 'Submeter';

  @override
  String get sunday => 'domingo';

  @override
  String get synchronizingPleaseWait => 'A sincronizar… Por favor, aguarde.';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theyDontMatch => 'Não correspondem';

  @override
  String get theyMatch => 'Correspondem';

  @override
  String get thisRoomHasBeenArchived => 'Esta sala foi arquivada.';

  @override
  String get thursday => 'quinta-feira';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Alternar favorito';

  @override
  String get toggleMuted => 'Alternar Silenciado';

  @override
  String get toggleUnread => 'Marcar lido/não lido';

  @override
  String get tooManyRequestsWarning =>
      'Demasiadas requisições. Por favor, tente novamente mais tarde!';

  @override
  String get transferFromAnotherDevice => 'Transferir de outro dispositivo';

  @override
  String get tryToSendAgain => 'Tente enviar novamente';

  @override
  String get tuesday => 'terça-feira';

  @override
  String get unavailable => 'Indisponível';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username revogou o banimento de $targetName';
  }

  @override
  String get unblockDevice => 'Desbloquear dispositivo';

  @override
  String get unknownDevice => 'Dispositivo desconhecido';

  @override
  String get unknownEncryptionAlgorithm =>
      'Algoritmo de criptografia desconhecido';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Evento desconhecido \'$type\'';
  }

  @override
  String get unmuteChat => 'Cancelar silenciamento';

  @override
  String get unpin => 'Desalfinetar';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount conversas não lidas',
      one: '1 conversa não lida',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username e mais $count pessoas estão digitando';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username e $username2 estão digitando';
  }

  @override
  String userIsTyping(Object username) {
    return '$username está a digitar';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username saiu da conversa';
  }

  @override
  String get username => 'Nome de utilizador';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username enviou um evento $type';
  }

  @override
  String get unverified => 'Não verificado';

  @override
  String get verified => 'Verificado';

  @override
  String get verify => 'Verificar';

  @override
  String get verifyStart => 'Iniciar verificação';

  @override
  String get verifySuccess => 'Verificação efetivada!';

  @override
  String get verifyTitle => 'A verificar a outra conta';

  @override
  String get videoCall => 'Vídeochamada';

  @override
  String get visibilityOfTheChatHistory =>
      'Visibilidade do histórico da conversa';

  @override
  String get visibleForAllParticipants => 'Visível aos participantes';

  @override
  String get visibleForEveryone => 'Visível a qualquer pessoa';

  @override
  String get voiceMessage => 'Mensagem de voz';

  @override
  String get waitingPartnerAcceptRequest =>
      'À espera que a outra pessoa aceite a solicitação…';

  @override
  String get waitingPartnerEmoji =>
      'À espera que a outra pessoa aceite os emoji…';

  @override
  String get waitingPartnerNumbers =>
      'À espera que a outra pessoa aceita os números…';

  @override
  String get wallpaper => 'Pano de fundo';

  @override
  String get warning => 'Atenção!';

  @override
  String get wednesday => 'quarta-feira';

  @override
  String get weSentYouAnEmail => 'Enviamos-lhe um e-mail';

  @override
  String get whoCanPerformWhichAction => 'Quem pode desempenhar quais ações';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Quais pessoas são permitidas participar deste grupo';

  @override
  String get whyDoYouWantToReportThis => 'Por que quer denunciar isto?';

  @override
  String get wipeChatBackup =>
      'Limpar o backup da conversa para criar uma nova chave de recuperação?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Pode recuperar a sua palavra-passe com estes endereços.';

  @override
  String get writeAMessage => 'Escreva uma mensagem…';

  @override
  String get yes => 'Sim';

  @override
  String get you => 'Você';

  @override
  String get youAreInvitedToThisChat => 'Foi convidada(o) a esta conversa';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Ja não está a participar nesta conversa';

  @override
  String get youCannotInviteYourself => 'Não se pode autoconvidar';

  @override
  String get youHaveBeenBannedFromThisChat => 'Foi banido desta conversa';

  @override
  String get yourPublicKey => 'A sua chave pública';

  @override
  String get messageInfo => 'Informações da mensagem';

  @override
  String get time => 'Hora';

  @override
  String get messageType => 'Tipo da mensagem';

  @override
  String get sender => 'Remetente';

  @override
  String get openGallery => 'Abrir galeria';

  @override
  String get removeFromSpace => 'Remover do espaço';

  @override
  String get addToSpaceDescription =>
      'Selecione um espaço para adicionar esta conversa.';

  @override
  String get start => 'Começar';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Para destrancar as suas mensagens antigas, por favor, insira a sua chave de recuperação gerada numa sessão prévia. A sua chave de recuperação NÃO é a sua palavra-passe.';

  @override
  String get addToStory => 'Adicionar ao painel';

  @override
  String get publish => 'Publicar';

  @override
  String get whoCanSeeMyStories => 'Quem pode ver o meu painel?';

  @override
  String get unsubscribeStories => 'Desinscrever de painéis';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Este(a) utilizador(a) ainda não postou no seu painel';

  @override
  String get yourStory => 'O seu painel';

  @override
  String get replyHasBeenSent => 'Resposta enviada';

  @override
  String videoWithSize(Object size) {
    return 'Vídeo ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Painel de $date:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Por favor, note que pessoas podem ver e contactar umas às outras no seu painel.';

  @override
  String get whatIsGoingOn => 'O que está a acontecer?';

  @override
  String get addDescription => 'Adicionar descrição';

  @override
  String get storyPrivacyWarning =>
      'Por favor, note que pessoas podem ver e contactar umas às outras no seu painel. Ele ficará visível por apenas 24 horas, mas não há garantias de que será apagado por todos dispositivos e servidores.';

  @override
  String get iUnderstand => 'Compreendo';

  @override
  String get openChat => 'Abrir conversa';

  @override
  String get markAsRead => 'Marcar como lido';

  @override
  String get reportUser => 'Delatar utilizador';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get matrixWidgets => 'Ferramentas Matrix';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reagiu com $reaction';
  }

  @override
  String get pinChat => 'Alfinetar';

  @override
  String get confirmEventUnpin =>
      'Tem certeza que quer desafixar o evento permanentemente?';

  @override
  String get emojis => 'Emojis';

  @override
  String get placeCall => 'Chamar';

  @override
  String get voiceCall => 'Chamada de voz';

  @override
  String get unsupportedAndroidVersion => 'Versão Android não suportada';

  @override
  String get unsupportedAndroidVersionLong =>
      'Esta funcionalidade requer uma versão mais nova do Android. Por favor, busque atualizações ou apoio para o Lineage OS.';

  @override
  String get videoCallsBetaWarning =>
      'Por favor, note que chamadas de vídeo estão atualmente em teste. Podem não funcionar como esperado ou sequer funcionar em algumas plataformas.';

  @override
  String get experimentalVideoCalls => 'Vídeo chamadas experimentais';

  @override
  String get emailOrUsername => 'Email ou nome de utilizador';

  @override
  String get indexedDbErrorTitle => 'Problemas no modo privado';

  @override
  String get indexedDbErrorLong =>
      'Infelizmente, o armazenamento de mensagens não é ativado por padrão no modo privado.\nPor favor, visite\n- about:config\n- atribua \"true\" a \"dom.indexedDB.privateBrowsing.enabled\"\nDe outro modo, não será possível executar o FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'Alternar para a conta $number';
  }

  @override
  String get nextAccount => 'Próxima conta';

  @override
  String get previousAccount => 'Conta anterior';

  @override
  String get editWidgets => 'Editar ferramentas';

  @override
  String get addWidget => 'Adicionar ferramenta';

  @override
  String get widgetVideo => 'Vídeo';

  @override
  String get widgetEtherpad => 'Anotação';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Personalizado';

  @override
  String get widgetName => 'Nome';

  @override
  String get widgetUrlError => 'Isto não é uma URL válida.';

  @override
  String get widgetNameError => 'Por favor, forneça um nome de exibição.';

  @override
  String get errorAddingWidget => 'Erro ao adicionar a ferramenta.';

  @override
  String get youRejectedTheInvitation => 'Rejeitou o convite';

  @override
  String get youJoinedTheChat => 'Entrou na conversa';

  @override
  String get youAcceptedTheInvitation => '👍 Aceitou o convite';

  @override
  String youBannedUser(Object user) {
    return 'Baniu $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Revogou o convite para $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 Foi convidado por $user';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 Convidou $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 Expulsou $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 Expulsou e baniu $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Revogou o banimento de $user';
  }

  @override
  String get noEmailWarning =>
      'Por favor, insira um e-mail válido. De outro modo, não conseguirá recuperar a sua palavra-passe. Caso prefira assim, toque novamente no botão para continuar.';

  @override
  String get stories => 'Stories';

  @override
  String get users => 'Utilizadores';

  @override
  String get enableAutoBackups => 'Ativar backups automáticos';

  @override
  String get unlockOldMessages => 'Destrancar mensagens antigas';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription =>
      'Guardar a chave de recuperação no armazenamento seguro deste dispositivo.';

  @override
  String get saveKeyManuallyDescription =>
      'Grave esta chave manualmente via partilhamento do sistema ou área de transferência.';

  @override
  String get storeInAndroidKeystore => 'Guardar no mealheiro do Android';

  @override
  String get storeInAppleKeyChain => 'Guardar no chaveiro da Apple';

  @override
  String get storeSecurlyOnThisDevice =>
      'Guardar de modo seguro neste dispositivo';

  @override
  String countFiles(Object count) {
    return '$count ficheiros';
  }

  @override
  String get user => 'Utilizador';

  @override
  String get custom => 'Personalizado';

  @override
  String get foregroundServiceRunning =>
      'Esta notificação aparece quando um serviço está a funcionar.';

  @override
  String get screenSharingTitle => 'Partilhar ecrã';

  @override
  String get screenSharingDetail => 'Está a partilhar o seu ecrã no FluffyChat';

  @override
  String get callingPermissions => 'Permissões de chamada';

  @override
  String get callingAccount => 'Conta para chamadas';

  @override
  String get callingAccountDetails =>
      'Permitir que o FluffyChat use o app de chamadas nativo do Android.';

  @override
  String get appearOnTop => 'Aparecer no topo';

  @override
  String get appearOnTopDetails =>
      'Permitir que o app apareça no topo (desnecessário caso FluffyChat já esteja configurado como conta para chamadas)';

  @override
  String get otherCallingPermissions =>
      'Microfone, câmara e outras permissões do FluffyChat';

  @override
  String get whyIsThisMessageEncrypted =>
      'Por que esta mensagem está ilegível?';

  @override
  String get noKeyForThisMessage =>
      'Isto pode ocorrer caso a mensagem tenha sido enviada antes da entrada na sua conta com este dispositivo.\n\nTambém é possível que o remetente tenha bloqueado o seu dispositivo ou ocorreu algum problema com a conexão.\n\nConsegue ler as mensagens em outra sessão? Então, pode transferir as mensagens de lá! Vá em Configurações > Dispositivos e confira se os dispositivos verificaram um ao outro. Quando abrir a conversa da próxima vez e ambas as sessões estiverem abertas, as chaves serão transmitidas automaticamente.\n\nNão gostaria de perder as suas chaves quando sair ou trocar de dispositivos? Certifique-se que o backup de conversas esteja ativado nas configurações.';

  @override
  String get newGroup => 'Novo grupo';

  @override
  String get newSpace => 'Novo espaço';

  @override
  String get enterSpace => 'Entrar no espaço';

  @override
  String get enterRoom => 'Entrar na conversa';

  @override
  String get allSpaces => 'Todos espaços';

  @override
  String numChats(Object number) {
    return '$number conversas';
  }

  @override
  String get hideUnimportantStateEvents => 'Ocultar eventos desimportantes';

  @override
  String get doNotShowAgain => 'Não mostrar novamente';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return 'Empty chat (was $oldDisplayName)';
  }

  @override
  String get newSpaceDescription =>
      'Spaces allows you to consolidate your chats and build private or public communities.';

  @override
  String get encryptThisChat => 'Encrypt this chat';

  @override
  String get endToEndEncryption => 'End to end encryption';

  @override
  String get disableEncryptionWarning =>
      'For security reasons you can not disable encryption in a chat, where it has been enabled before.';

  @override
  String get sorryThatsNotPossible => 'Sorry... that is not possible';

  @override
  String get deviceKeys => 'Device keys:';

  @override
  String get letsStart => 'Let\'s start';

  @override
  String get enterInviteLinkOrMatrixId => 'Enter invite link or Matrix ID...';

  @override
  String get reopenChat => 'Reopen chat';

  @override
  String get noBackupWarning =>
      'Warning! Without enabling chat backup, you will lose access to your encrypted messages. It is highly recommended to enable the chat backup first before logging out.';

  @override
  String get noOtherDevicesFound => 'No other devices found';

  @override
  String get fileIsTooBigForServer =>
      'The server reports that the file is too large to be sent.';

  @override
  String get onlineStatus => 'online';

  @override
  String onlineMinAgo(Object min) {
    return 'online ${min}m ago';
  }

  @override
  String onlineHourAgo(Object hour) {
    return 'online ${hour}h ago';
  }

  @override
  String onlineDayAgo(Object day) {
    return 'online ${day}d ago';
  }

  @override
  String get noMessageHereYet => 'No message here yet...';

  @override
  String get sendMessageGuide => 'Send a message or tap on the greeting below.';

  @override
  String get youCreatedGroupChat => 'You created a Group chat';

  @override
  String get chatCanHave => 'Chat can have:';

  @override
  String get upTo100000Members => 'Up to 100.000 members';

  @override
  String get persistentChatHistory => 'Persistent Chat history';

  @override
  String get addMember => 'Adicionar membros';

  @override
  String get profile => 'Perfil';

  @override
  String get channels => 'Canais';

  @override
  String get chatMessage => 'Nova mensagem';

  @override
  String welcomeToTwake(Object user) {
    return 'Welcome to Twake, $user';
  }

  @override
  String get startNewChatMessage =>
      'It\'s nice having a chat with your friends and collaborating with your teams.\nLet\'s start a chat, create a group chat, or join an existing one.';

  @override
  String get statusDot => '⬤';

  @override
  String get active => 'Ativado';

  @override
  String get inactive => 'Not-activated';

  @override
  String get newGroupChat => 'New Group Chat';

  @override
  String get twakeUsers => 'Twake users';

  @override
  String get expand => 'Expand';

  @override
  String get shrink => 'Shrink';

  @override
  String noResultForKeyword(Object keyword) {
    return 'No results for \"$keyword\"';
  }

  @override
  String get searchResultNotFound1 =>
      '• Make sure there are no typos in your search.\n';

  @override
  String get searchResultNotFound2 =>
      '• You might not have the user in your address book.\n';

  @override
  String get searchResultNotFound3 =>
      '• Check the contact access permission, the user might be in your contact list.\n';

  @override
  String get searchResultNotFound4 => '• If the reason is not listed above, ';

  @override
  String get searchResultNotFound5 => 'seek helps.';

  @override
  String get more => 'Mais';

  @override
  String get whoWouldYouLikeToAdd => 'Who would you like to add?';

  @override
  String get addAPhoto => 'Add a photo';

  @override
  String maxImageSize(Object max) {
    return 'Maximum file size: ${max}MB';
  }

  @override
  String get owner => 'Owner';

  @override
  String participantsCount(Object count) {
    return 'Participants ($count)';
  }

  @override
  String get back => 'Back';

  @override
  String get wrongServerName => 'Wrong server name';

  @override
  String get serverNameWrongExplain =>
      'Server address was sent to you by company admin. Check the invitation email.';

  @override
  String get contacts => 'Contacts';

  @override
  String get searchForContacts => 'Search for contacts';

  @override
  String get soonThereHaveContacts => 'Soon there will be contacts';

  @override
  String get searchSuggestion =>
      'For now, search by typing a person’s name or public server address';

  @override
  String get loadingContacts => 'Loading contacts...';

  @override
  String get recentChat => 'RECENT CHAT';

  @override
  String get selectChat => 'Select chat';

  @override
  String get search => 'Procurar';

  @override
  String get forwardTo => 'Forward to...';

  @override
  String get noConnection => 'No connection';

  @override
  String photoSelectedCounter(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0 selected';
  }

  @override
  String get addACaption => 'Add a caption...';

  @override
  String get noImagesFound => 'No Images found';

  @override
  String get captionForImagesIsNotSupportYet =>
      'Caption for images is not support yet.';

  @override
  String get tapToAllowAccessToYourGallery => 'Tap to allow gallery access';

  @override
  String get tapToAllowAccessToYourCamera =>
      'You can enable camera access in the Settings app to make video calls in';

  @override
  String get twake => 'Twake Chat';

  @override
  String get permissionAccess => 'Permission access';

  @override
  String get allow => 'Permitir';

  @override
  String get explainStoragePermission =>
      'Twake need access to your storage to preview file';

  @override
  String get explainGoToStorageSetting =>
      'Twake need access to your storage to preview file, go to settings to allow this permission';

  @override
  String get gallery => 'Gallery';

  @override
  String get documents => 'Documentos';

  @override
  String get location => 'Localização';

  @override
  String get contact => 'Contacto';

  @override
  String get file => 'Ficheiro';

  @override
  String get recent => 'Recente';

  @override
  String get chatsAndContacts => 'Chats and Contacts';

  @override
  String get externalContactTitle => 'Convidar novos utilizadores';

  @override
  String get externalContactMessage =>
      'Some of the users you want to add are not in your contacts. Do you want to invite them?';

  @override
  String get clear => 'Limpar';

  @override
  String get keyboard => 'Teclado';

  @override
  String get changeChatAvatar => 'Change the Chat avatar';

  @override
  String get roomAvatarMaxFileSize => 'The avatar size is too large';

  @override
  String roomAvatarMaxFileSizeLong(Object max) {
    return 'The avatar size must be less than $max';
  }

  @override
  String get continueProcess => 'Continuar';

  @override
  String get youAreUploadingPhotosDoYouWantToCancelOrContinue =>
      'Image upload error! Do you still want to continue creating group chat?';

  @override
  String hasCreatedAGroupChat(Object groupName) {
    return 'created a group chat “$groupName”';
  }

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get acceptInvite => 'Yes please, join';

  @override
  String get askToInvite => ' wants you to join this chat. What do you say?';

  @override
  String get select => 'Escolher';

  @override
  String get copyMessageText => 'Copy';

  @override
  String get pinThisChat => 'Pin this chat';

  @override
  String get unpinThisChat => 'Unpin this chat';

  @override
  String get add => 'Adicionar';

  @override
  String get addMembers => 'Adicionar membros';

  @override
  String get chatInfo => 'Chat info';

  @override
  String get mute => 'Mute';

  @override
  String membersInfo(Object count) {
    return 'Members ($count)';
  }

  @override
  String get members => 'Membros';

  @override
  String get media => 'Media';

  @override
  String get files => 'Ficheiros';

  @override
  String get links => 'Ligações';

  @override
  String get downloads => 'Descargas';

  @override
  String get downloadImageSuccess => 'Image saved to Pictures';

  @override
  String get downloadImageError => 'Error saving image';

  @override
  String downloadFileInWeb(Object directory) {
    return 'File saved to $directory';
  }

  @override
  String get notInAChatYet => 'You\'re not in a chat yet';

  @override
  String get blankChatTitle => 'Choose a chat or hit #EditIcon# to make one.';

  @override
  String get errorPageTitle => 'Something\'s not right';

  @override
  String get errorPageDescription => 'That page doesn\'t exist.';

  @override
  String get errorPageButton => 'Back to chat';

  @override
  String get playVideo => 'Play';

  @override
  String get done => 'Done';

  @override
  String get markThisChatAsRead => 'Mark this chat as read';

  @override
  String get markThisChatAsUnRead => 'Mark this chat as unread';

  @override
  String get muteThisChat => 'Mute this chat';

  @override
  String get unmuteThisChat => 'Unmute this chat';

  @override
  String get read => 'Read';

  @override
  String get unread => 'Unread';

  @override
  String get unmute => 'Unmute';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get notificationAndSounds => 'Notification & Sounds';

  @override
  String get appLanguage => 'App Language';

  @override
  String get chatFolders => 'Chat Folders';

  @override
  String get displayName => 'Display Name';

  @override
  String get bio => 'Bio (optional)';

  @override
  String get matrixId => 'Matrix ID';

  @override
  String get email => 'Email';

  @override
  String get company => 'Company';

  @override
  String get basicInfo => 'BASIC INFO';

  @override
  String get editProfileDescriptions =>
      'Update your profile with a new name, picture and a short introduction.';

  @override
  String get workIdentitiesInfo => 'WORK IDENTITIES INFO';

  @override
  String get editWorkIdentitiesDescriptions =>
      'Edit your work identity settings such as Matrix ID, email or company name.';

  @override
  String get copiedMatrixIdToClipboard => 'Copied Matrix ID to clipboard.';

  @override
  String get changeProfileAvatar => 'Change profile avatar';

  @override
  String countPinChat(Object countPinChat) {
    return 'PINNED CHATS ($countPinChat)';
  }

  @override
  String countAllChat(Object countAllChat) {
    return 'ALL CHATS ($countAllChat)';
  }

  @override
  String get thisMessageHasBeenEncrypted => 'This message has been encrypted';

  @override
  String get roomCreationFailed => 'Room creation failed';

  @override
  String get errorGettingPdf => 'Error getting PDF';

  @override
  String get errorPreviewingFile => 'Error previewing file';

  @override
  String get paste => 'Paste';

  @override
  String get cut => 'Cut';

  @override
  String get pasteImageFailed => 'Paste image failed';

  @override
  String get copyImageFailed => 'Copy image failed';

  @override
  String get fileFormatNotSupported => 'File format not supported';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get encryptionMessage =>
      'This feature protects your messages from being read by others, but also prevents them from being backed up on our servers. You can\'t disable this later.';

  @override
  String get encryptionWarning =>
      'You might lose your messages if you access Twake app on the another device.';

  @override
  String get selectedUsers => 'Selected users';

  @override
  String get clearAllSelected => 'Clear all selected';

  @override
  String get newDirectMessage => 'New direct message';

  @override
  String get contactInfo => 'Contact info';

  @override
  String countPinnedMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pinned Message #$count',
      zero: 'Pinned Message',
    );
    return '$_temp0';
  }

  @override
  String pinnedMessages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pinned Messages',
      one: '1 Pinned Message',
    );
    return '$_temp0';
  }

  @override
  String get copyImageSuccess => 'Image copied to clipboard';

  @override
  String get youNeedToAcceptTheInvitation =>
      'You need to accept the invitation to start chatting';

  @override
  String get hasInvitedYouToAChat =>
      ' has invited you to a chat. Accept or reject and delete the conversation?';

  @override
  String get declineTheInvitation => 'Decline the invitation?';

  @override
  String get doYouReallyWantToDeclineThisInvitation =>
      'Do you really want to decline this invitation and remove the chat? You won\'t be able to undo this action.';

  @override
  String get declineAndRemove => 'Decline and remove';

  @override
  String get notNow => 'Not now';

  @override
  String get contactsWarningBannerTitle =>
      'To ensure you can connect with all your friends, please allow Twake to access your device’s contacts. We appreciate your understanding.';

  @override
  String contactsCount(Object count) {
    return 'Contacts ($count)';
  }

  @override
  String linagoraContactsCount(Object count) {
    return 'Linagora contacts ($count)';
  }

  @override
  String fetchingPhonebookContacts(Object progress) {
    return 'Fetching contacts from device...($progress% completed)';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Vietnamese';

  @override
  String get languageFrench => 'French';

  @override
  String get languageRussian => 'Russian';

  @override
  String get settingsLanguageDescription =>
      'Set the language you use on Twake Chat';

  @override
  String sendImages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count images',
      one: 'Send 1 image',
    );
    return '$_temp0';
  }

  @override
  String get enterCaption => 'Add a caption...';

  @override
  String get failToSend => 'Failed to send, please try again';

  @override
  String get showLess => 'Show Less';

  @override
  String get showMore => 'Show More';

  @override
  String get unreadMessages => 'Unread messages';

  @override
  String get groupInformation => 'Group information';

  @override
  String get linkInvite => 'Link invite';

  @override
  String get noDescription => 'No description';

  @override
  String get description => 'Description';

  @override
  String get groupName => 'Group name';

  @override
  String get descriptionHelper =>
      'You can provide an optional description for your group.';

  @override
  String get groupNameCannotBeEmpty => 'Group name cannot be empty';

  @override
  String get unpinAllMessages => 'Unpin all messages';

  @override
  String get pinnedMessagesTooltip => 'Pinned messages';

  @override
  String get jumpToMessage => 'Jump to message';

  @override
  String get failedToUnpin => 'Failed to unpin message';

  @override
  String get welcomeTo => 'Welcome to';

  @override
  String get descriptionWelcomeTo =>
      'an open source messenger based on\nthe matrix protocol, which allows you to\nencrypt your data';

  @override
  String get startMessaging => 'Start messaging';

  @override
  String get signIn => 'Sign in';

  @override
  String get createTwakeId => 'Create Twake ID';

  @override
  String get useYourCompanyServer => 'Use your company server';

  @override
  String get descriptionTwakeId =>
      'An open source messenger encrypt\nyour data with matrix protocol';

  @override
  String countFilesSendPerDialog(Object count) {
    return 'The maximum files when sending is $count.';
  }

  @override
  String sendFiles(Object count) {
    return 'Send $count files';
  }

  @override
  String get addAnotherAccount => 'Add another account';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get failedToSendFiles => 'Failed to send files';

  @override
  String get noResults => 'No Results';

  @override
  String get isSingleAccountOnHomeserver =>
      'We do not yet support multiple accounts on a single homeserver';

  @override
  String messageSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Messages',
      one: '1 Message',
      zero: 'No Messages',
    );
    return '$_temp0 selected';
  }

  @override
  String draftChatHookPhrase(String user) {
    return 'Hi $user! I would like to chat with you.';
  }

  @override
  String get twakeChatUser => 'Twake Chat User';

  @override
  String get sharedMediaAndLinks => 'Shared media and links';

  @override
  String get errorSendingFiles =>
      'Some files aren’t sendable due to size, format restrictions, or unexpected errors. They’ll be omitted.';

  @override
  String get removeFileBeforeSend => 'Remove error files before send';

  @override
  String get unselect => 'Unselect';

  @override
  String get searchContacts => 'Search contacts';

  @override
  String get tapToAllowAccessToYourMicrophone =>
      'You can enable microphone access in the Settings app to make voice in';

  @override
  String get showInChat => 'Show in chat';

  @override
  String get phone => 'Phone';

  @override
  String get viewProfile => 'View profile';

  @override
  String get profileInfo => 'Profile informations';

  @override
  String get saveToDownloads => 'Save to Downloads';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get fileSavedToDownloads => 'File saved to Downloads';

  @override
  String get saveFileToDownloadsError => 'Failed to save file to Downloads';

  @override
  String explainPermissionToDownloadFiles(String appName) {
    return 'To continue, please allow $appName to access storage permission. This permission is essential for saving file to Downloads folder.';
  }

  @override
  String get explainPermissionToAccessContacts =>
      'Twake Chat DOES NOT collect your contacts. Twake Chat sends only contact hashes to the Twake Chat servers to understand who from your friends already joined Twake Chat, enabling connection with them. Your contacts ARE NOT synchronized with our server.';

  @override
  String get explainPermissionToAccessMedias =>
      'Twake Chat does not synchronize data between your device and our servers. We only store media that you have sent to the chat room. All media files sent to chat are encrypted and stored securely. Go to Settings > Permissions and activate the Storage: Photos and Videos permission. You can also deny access to your media library at any time.';

  @override
  String get explainPermissionToAccessPhotos =>
      'Twake Chat does not synchronize data between your device and our servers. We only store media that you have sent to the chat room. All media files sent to chat are encrypted and stored securely. Go to Settings > Permissions and activate the Storage: Photos permission. You can also deny access to your media library at any time.';

  @override
  String get explainPermissionToAccessVideos =>
      'Twake Chat does not synchronize data between your device and our servers. We only store media that you have sent to the chat room. All media files sent to chat are encrypted and stored securely. Go to Settings > Permissions and activate the Storage: Videos permission. You can also deny access to your media library at any time.';

  @override
  String get downloading => 'Downloading';

  @override
  String get settingUpYourTwake =>
      'Setting up your Twake\nIt could take a while';

  @override
  String get performingAutomaticalLogin =>
      'Performing automatical login  via SSO';

  @override
  String get backingUpYourMessage =>
      'Preparing server environment for backing up your messages';

  @override
  String get recoveringYourEncryptedChats => 'Recovering your encrypted chats';

  @override
  String get configureDataEncryption => 'Configure data encryption';

  @override
  String get configurationNotFound => 'The configuration data not found';

  @override
  String get fileSavedToGallery => 'File saved to Gallery';

  @override
  String get saveFileToGalleryError => 'Failed to save file to Gallery';

  @override
  String explainPermissionToGallery(String appName) {
    return 'To continue, please allow $appName to access photo permission. This permission is essential for saving file to gallery.';
  }

  @override
  String get tokenNotFound => 'The login token not found';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get leaveGroupSubtitle =>
      'This group will still remain after you left';

  @override
  String get leaveChatFailed => 'Failed to leave the chat';

  @override
  String get invalidLoginToken => 'Invalid login token';

  @override
  String get copiedPublicKeyToClipboard => 'Copied public key to clipboard.';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get removeUser => 'Remove User';

  @override
  String removeReason(Object user) {
    return 'Remove $user from the group';
  }

  @override
  String get switchAccounts => 'Switch accounts';

  @override
  String get selectAccount => 'Select account';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get byContinuingYourAgreeingToOur =>
      'By continuing, you\'re agreeing to our';

  @override
  String get youDontHaveAnyContactsYet => 'You dont have any contacts yet.';

  @override
  String get loading => 'Loading...';

  @override
  String get errorDialogTitle => 'Oops, something went wrong';

  @override
  String get shootingTips => 'Tap to take photo.';

  @override
  String get shootingWithRecordingTips =>
      'Tap to take photo. Long press to record video.';

  @override
  String get shootingOnlyRecordingTips => 'Long press to record video.';

  @override
  String get shootingTapRecordingTips => 'Tap to record video.';

  @override
  String get loadFailed => 'Load failed';

  @override
  String get saving => 'Saving...';

  @override
  String get sActionManuallyFocusHint => 'Manually focus';

  @override
  String get sActionPreviewHint => 'Preview';

  @override
  String get sActionRecordHint => 'Record';

  @override
  String get sActionShootHint => 'Take picture';

  @override
  String get sActionShootingButtonTooltip => 'Shooting button';

  @override
  String get sActionStopRecordingHint => 'Stop recording';

  @override
  String sCameraLensDirectionLabel(Object value) {
    return 'Camera lens direction: $value';
  }

  @override
  String sCameraPreviewLabel(Object value) {
    return 'Camera preview: $value';
  }

  @override
  String sFlashModeLabel(Object mode) {
    return 'Flash mode: $mode';
  }

  @override
  String sSwitchCameraLensDirectionLabel(Object value) {
    return 'Switch to the $value camera';
  }

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get message => 'Message';

  @override
  String fileTooBig(int maxSize) {
    return 'The selected file is too large. Please choose a file smaller than $maxSize MB.';
  }

  @override
  String get enable_notifications => 'Enable notifications';

  @override
  String get disable_notifications => 'Disable notifications';

  @override
  String get logoutDialogWarning =>
      'You will lose access to encrypted messages. We recommend that you enable chat backups before logging out';

  @override
  String get copyNumber => 'Copy number';

  @override
  String get callViaCarrier => 'Call via Carrier';

  @override
  String get scanQrCodeToJoin =>
      'Installation of the mobile application will allow you to contact people from your phone\'s address book, your chats will be synchronised between devices';

  @override
  String get thisFieldCannotBeBlank => 'This field cannot be blank';

  @override
  String get phoneNumberCopiedToClipboard => 'Phone number copied to clipboard';

  @override
  String get deleteAccountMessage =>
      'Groups chats that you have created will remain unadministered unless you have given another user administrator rights. Users will still have a history of messages with you. Deleting the account won\'t help.';

  @override
  String get deleteLater => 'Delete later';

  @override
  String get areYouSureYouWantToDeleteAccount =>
      'Are you sure you want to delete account?';

  @override
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get selectAnEmailOrPhoneYouWantSendTheInvitationTo =>
      'Select an email or phone you want send the invitation to';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get sendInvitation => 'Send invitation';

  @override
  String get verifyWithAnotherDevice => 'Verify with another device';

  @override
  String get contactLookupFailed => 'Contact lookup failed.';

  @override
  String get invitationHasBeenSuccessfullySent =>
      'Invitation has been successfully sent!';

  @override
  String get failedToSendInvitation => 'Failed to send invitation.';

  @override
  String get invalidPhoneNumber => 'Invalid phone number';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get shareInvitationLink => 'Share invitation link';

  @override
  String get failedToGenerateInvitationLink =>
      'Failed to generate invitation link.';

  @override
  String get youAlreadySentAnInvitationToThisContact =>
      'You already sent an invitation to this contact';

  @override
  String get selectedEmailWillReceiveAnInvitationLinkAndInstructions =>
      'Selected email will receive an invitation link and instructions.';

  @override
  String get selectedNumberWillGetAnSMSWithAnInvitationLinkAndInstructions =>
      'Selected number will get an SMS with an invitation link and instructions.';

  @override
  String get reaction => 'Reaction';

  @override
  String get noChatPermissionMessage =>
      'You do not have permission to send messages in this chat.';

  @override
  String get administration => 'Administration';

  @override
  String get yourDataIsEncryptedForSecurity =>
      'Your data is encrypted for security';

  @override
  String get failedToDeleteMessage => 'Failed to delete message.';

  @override
  String get noDeletePermissionMessage =>
      'You don\'t have permission to delete this message.';

  @override
  String get edited => 'edited';

  @override
  String get editMessage => 'Edit message';

  @override
  String get assignRoles => 'Assign roles';

  @override
  String get permissions => 'Permissions';

  @override
  String adminsOfTheGroup(Object number) {
    return 'ADMINS OF THE GROUP ($number)';
  }

  @override
  String get addAdminsOrModerators => 'Add Admins/moderators';

  @override
  String get member => 'Member';

  @override
  String get guest => 'Guest';

  @override
  String get exceptions => 'Exceptions';

  @override
  String get readOnly => 'Read only';

  @override
  String readOnlyCount(Object number) {
    return 'READ ONLY ($number)';
  }

  @override
  String get removedUsers => 'Removed Users';

  @override
  String bannedUsersCount(Object number) {
    return 'BANNED USERS ($number)';
  }

  @override
  String get downgradeToReadOnly => 'Downgrade to read only';

  @override
  String memberOfTheGroup(Object number) {
    return 'MEMBERS OF THE GROUP ($number)';
  }

  @override
  String get selectRole => 'Select role';

  @override
  String get canReadMessages => 'Can read messages';

  @override
  String get canWriteMessagesSendReacts => 'Can write messages, send reacts...';

  @override
  String get canRemoveUsersDeleteMessages =>
      'Can remove users, delete messages...';

  @override
  String get canAccessAllFeaturesAndSettings =>
      'Can access all features and settings';

  @override
  String get invitePeopleToTheRoom => 'Invite people to the room';

  @override
  String get sendReactions => 'Send reactions';

  @override
  String get deleteMessagesSentByMe => 'Delete messages sent by me';

  @override
  String get notifyEveryoneUsingRoom => 'Notify everyone using @room';

  @override
  String get joinCall => 'Join Call';

  @override
  String get removeMembers => 'Remove a members';

  @override
  String get deleteMessagesSentByOthers => 'Delete messages sent by others';

  @override
  String get pinMessageForEveryone => 'Pin a message (for everyone)';

  @override
  String get startCall => 'Start Call';

  @override
  String get changeGroupName => 'Change group name';

  @override
  String get changeGroupDescription => 'Change group description';

  @override
  String get changeGroupAvatar => 'Change group avatar';

  @override
  String get changeGroupHistoryVisibility => 'Change group history visibility';

  @override
  String get searchGroupMembers => 'Search group members';

  @override
  String get permissionErrorChangeRole =>
      'You don’t have the rights to change roles. Please reach out to your admin for help';

  @override
  String get demoteAdminsModerators => 'Demote Admins/Moderators';

  @override
  String get deleteMessageConfirmationTitle =>
      'Are you sure you want to delete this message?';

  @override
  String get permissionErrorBanUser =>
      'You don’t have the rights to ban users. Please reach out to your admin for help';

  @override
  String get removeMember => 'Remove member';

  @override
  String get removeMemberSelectionError =>
      'You cannot delete a member with a role equal to or greater than yours.';

  @override
  String get downgrade => 'Downgrade';

  @override
  String get deletedMessage => 'Deleted message';

  @override
  String get unban => 'Unban';

  @override
  String get permissionErrorUnbanUser =>
      'You don’t have the rights to unban users. Please reach out to your admin for help';

  @override
  String get transferOwnership => 'Transfer ownership';

  @override
  String confirmTransferOwnership(Object name) {
    return 'Are you sure you want to transfer ownership of this group to $name?';
  }

  @override
  String get transferOwnershipDescription =>
      'This user will gain full control over the group and you will no longer have total management rights. This action is irreversible.';

  @override
  String get confirmTransfer => 'Confirm Transfer';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get blockUser => 'Block User';

  @override
  String get permissionErrorUnblockUser =>
      'You don’t have the rights to unblock user.';

  @override
  String get permissionErrorBlockUser =>
      'You don’t have the rights to block user.';

  @override
  String userIsNotAValidMxid(Object mxid) {
    return '$mxid is not a valid Matrix ID';
  }

  @override
  String userNotFoundInIgnoreList(Object mxid) {
    return '$mxid is not found in your ignore list';
  }

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String unblockUsername(Object name) {
    return 'Unblock $name';
  }

  @override
  String get unblock => 'Unblock';

  @override
  String get unblockDescriptionDialog =>
      'This person will be able to message you and see when you\'re online. They won\'t be notified that you unblocked them.';

  @override
  String get report => 'Report';

  @override
  String get reportDesc => 'What’s the issue with this message?';

  @override
  String get sendReport => 'Send Report';

  @override
  String get addComment => 'Add comment';

  @override
  String get spam => 'Spam';

  @override
  String get violence => 'Violence';

  @override
  String get childAbuse => 'Child abuse';

  @override
  String get pornography => 'Pornography';

  @override
  String get copyrightInfringement => 'Copyright infringement';

  @override
  String get terrorism => 'Terrorism';

  @override
  String get other => 'Other';

  @override
  String get enableRightAndLeftMessageAlignment =>
      'Enable right/left message alignment';

  @override
  String get holdToRecordAudio => 'Hold to record audio.';

  @override
  String get explainPermissionToAccessMicrophone =>
      'To send voice messages, allow Twake Chat to access the microphone.';

  @override
  String get allowMicrophoneAccess => 'Allow microphone access';

  @override
  String get later => 'Later';

  @override
  String get couldNotPlayAudioFile => 'Could not play audio file';

  @override
  String get slideToCancel => 'Slide to cancel';

  @override
  String get recordingInProgress => 'Recording in progress';

  @override
  String get pleaseFinishOrStopTheRecording =>
      'Please finish or stop the recording before performing other actions.';

  @override
  String get audioMessageFailedToSend => 'Audio message failed to send.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class L10nPtBr extends L10nPt {
  L10nPtBr() : super('pt_BR');

  @override
  String get passwordsDoNotMatch => 'Senhas diferentes!';

  @override
  String get pleaseEnterValidEmail => 'Por favor, insira um email válido.';

  @override
  String get repeatPassword => 'Repita a senha';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Por favor, use ao menos $min caracteres.';
  }

  @override
  String get about => 'Sobre';

  @override
  String get updateAvailable => 'Atualização do FluffyChat disponível';

  @override
  String get updateNow => 'Iniciar atualização nos bastidores';

  @override
  String get accept => 'Aceitar';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username aceitou o convite';
  }

  @override
  String get account => 'Conta';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username ativou a criptografia ponta-a-ponta';
  }

  @override
  String get addEmail => 'Adicionar email';

  @override
  String get confirmMatrixId =>
      'Por favor, confirme seu ID Matrix para apagar sua conta.';

  @override
  String supposedMxid(Object mxid) {
    return 'Isto deveria ser $mxid';
  }

  @override
  String get addGroupDescription => 'Adicionar uma descrição para o grupo';

  @override
  String get addToSpace => 'Adicionar ao espaço';

  @override
  String get admin => 'Admin';

  @override
  String get alias => 'cognome';

  @override
  String get all => 'Todas';

  @override
  String get allChats => 'Todas as conversas';

  @override
  String get commandHint_googly => 'Enviar olhos arregalados';

  @override
  String get commandHint_cuddle => 'Enviar um afago';

  @override
  String get commandHint_hug => 'Enviar um abraço';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName enviou olhos arregalados';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName afagou você';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName abraçou você';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName atendeu à chamada';
  }

  @override
  String get anyoneCanJoin => 'Qualquer pessoa pode participar';

  @override
  String get appLock => 'Trava do aplicativo';

  @override
  String get archive => 'Arquivo';

  @override
  String get archivedRoom => 'Sala arquivada';

  @override
  String get areGuestsAllowedToJoin => 'Usuários convidados podem participar';

  @override
  String get areYouSure => 'Tem certeza?';

  @override
  String get areYouSureYouWantToLogout =>
      'Tem certeza que deseja encerrar a sessão?';

  @override
  String get askSSSSSign =>
      'Para poder validar a outra pessoa, por favor, insira sua frase secreta ou chave de recuperação.';

  @override
  String askVerificationRequest(Object username) {
    return 'Aceitar esta solicitação de verificação de $username?';
  }

  @override
  String get autoplayImages =>
      'Reproduzir automaticamente figurinhas animadas e emojis';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'O servidor matriz suporta os tipos de login:\n$serverVersions\nMas este app suporta apenas:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Enviar ao pressionar enter';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'O servidor matriz suporta as versões Spec:\n$serverVersions\nMas este app suporta apenas $supportedVersions';
  }

  @override
  String get banFromChat => 'Banir da conversa';

  @override
  String get banned => 'Banido';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username baniu $targetName';
  }

  @override
  String get blockDevice => 'Bloquear dispositivo';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get botMessages => 'Mensagens de robôs';

  @override
  String get bubbleSize => 'Tamanho do balão';

  @override
  String get cancel => 'Cancelar';

  @override
  String cantOpenUri(Object uri) {
    return 'Não foi possível abrir a URI $uri';
  }

  @override
  String get changeDeviceName => 'Alterar o nome do dispositivo';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username alterou o avatar da conversa';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username alterou a descrição da conversa para: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username alterou o nome da conversa para: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username alterou as permissões na conversa';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username mudou o seu nome de exibição para: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username alterou as regras de acesso dos convidados';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username alterou as regras de acesso dos convidados para: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username alterou a visibilidade do histórico';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username alterou a visibilidade do histórico para: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username alterou as regras para participação';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username alterou as regras para participação para: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username alterou seu avatar';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username alterou os cognomes da sala';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username alterou o link de convite';
  }

  @override
  String get changePassword => 'Alterar a senha';

  @override
  String get changeTheHomeserver => 'Alterar o servidor matriz';

  @override
  String get changeTheme => 'Alterar o tema';

  @override
  String get changeTheNameOfTheGroup => 'Alterar o nome do grupo';

  @override
  String get changeWallpaper => 'Alterar o pano de fundo';

  @override
  String get changeYourAvatar => 'Alterar seu avatar';

  @override
  String get channelCorruptedDecryptError => 'A criptografia foi corrompida';

  @override
  String get chat => 'Conversas';

  @override
  String get yourUserId => 'Seu ID de usuário:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'Seu backup de conversas foi configurado.';

  @override
  String get chatBackup => 'Backup da conversa';

  @override
  String get chatBackupDescription =>
      'Suas mensagens antigas são protegidas com sua chave de recuperação. Por favor, evite perdê-la.';

  @override
  String get chatDetails => 'Detalhes da conversa';

  @override
  String get chatHasBeenAddedToThisSpace =>
      'A conversa foi adicionada a este espaço';

  @override
  String get chats => 'Conversas';

  @override
  String get chooseAStrongPassword => 'Escolha uma senha forte';

  @override
  String get chooseAUsername => 'Escolha um nome de usuário';

  @override
  String get clearArchive => 'Limpar arquivo';

  @override
  String get close => 'Fechar';

  @override
  String get commandHint_markasdm => 'Marcar como conversa direta';

  @override
  String get commandHint_markasgroup => 'Marcar como grupo';

  @override
  String get commandHint_ban => 'Banir um(a) usuário(a) desta sala';

  @override
  String get commandHint_clearcache => 'Limpar dados temporários';

  @override
  String get commandHint_create =>
      'Criar uma sala vazia.\nUse --no-encryption para desabilitar a criptografia';

  @override
  String get commandHint_discardsession => 'Descartar sessão';

  @override
  String get commandHint_dm =>
      'Iniciar uma conversa direta\nUse --no-encryption para desabilitar a criptografia';

  @override
  String get commandHint_html => 'Enviar mensagem formatada em HTML';

  @override
  String get commandHint_invite => 'Convidar um(a) usuário(a) para esta sala';

  @override
  String get commandHint_join => 'Entrar numa sala';

  @override
  String get commandHint_kick => 'Remover um(a) usuário(a) desta sala';

  @override
  String get commandHint_leave => 'Sair desta sala';

  @override
  String get commandHint_me => 'Descrever você mesmo';

  @override
  String get commandHint_myroomavatar =>
      'Determinar sua imagem para esta sala (via mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Determinar seu nome de exibição para esta sala';

  @override
  String get commandHint_op =>
      'Determinar o grau de poderes de um(a) usuário(a) (padrão: 50)';

  @override
  String get commandHint_plain => 'Enviar mensagem sem formatação';

  @override
  String get commandHint_react => 'Enviar uma resposta como reação';

  @override
  String get commandHint_send => 'Enviar mensagem';

  @override
  String get commandHint_unban =>
      'Revogar o banimento de um(a) usuário(a) desta sala';

  @override
  String get commandInvalid => 'Comando inválido';

  @override
  String commandMissing(Object command) {
    return '$command não é um comando.';
  }

  @override
  String get compareEmojiMatch =>
      'Compare e certifique-se que os seguintes emojis batem com os do outro dispositivo:';

  @override
  String get compareNumbersMatch =>
      'Compare e certifique-se de que os seguintes números batem com os do outro dispositivo:';

  @override
  String get configureChat => 'Configurar conversa';

  @override
  String get confirm => 'Confirma';

  @override
  String get connect => 'Conectar';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'O contato foi convidado ao grupo';

  @override
  String get containsDisplayName => 'Contém nome de exibição';

  @override
  String get containsUserName => 'Contém nome de usuário';

  @override
  String get contentHasBeenReported =>
      'O conteúdo foi denunciado para quem administra o servidor';

  @override
  String get copiedToClipboard => 'Copiado para área de transferência';

  @override
  String get copy => 'Copiar';

  @override
  String get copyToClipboard => 'Copiar para a área de transferência';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Não foi possível decriptar a mensagem: $error';
  }

  @override
  String get create => 'Criar';

  @override
  String createdTheChat(Object username) {
    return '💬 $username criou a conversa';
  }

  @override
  String get createNewGroup => 'Novo grupo';

  @override
  String get createNewSpace => 'Novo espaço';

  @override
  String get crossSigningEnabled => 'Assinatura cruzada ativada';

  @override
  String get currentlyActive => 'Ativo';

  @override
  String get darkTheme => 'Escuro';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$day/$month';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$day/$month/$year';
  }

  @override
  String get deactivateAccountWarning =>
      'Isto desativará a conta do usuário. É irreversível! Tem certeza?';

  @override
  String get defaultPermissionLevel => 'Nível de permissão padrão';

  @override
  String get delete => 'Apagar';

  @override
  String get deleteAccount => 'Apagar conta';

  @override
  String get deleteMessage => 'Apagar mensagem';

  @override
  String get deny => 'Rejeitar';

  @override
  String get device => 'Dispositivo';

  @override
  String get deviceId => 'ID do dispositivo';

  @override
  String get devices => 'Dispositivos';

  @override
  String get directChats => 'Conversas diretas';

  @override
  String get discover => 'Desvendar';

  @override
  String get displaynameHasBeenChanged => 'O nome de exibição foi alterado';

  @override
  String get edit => 'Editar';

  @override
  String get editBlockedServers => 'Editar servidores bloqueados';

  @override
  String get editChatPermissions => 'Editar permissões da conversa';

  @override
  String get editDisplayname => 'Editar nome de exibição';

  @override
  String get editRoomAliases => 'Editar cognome da sala';

  @override
  String get editRoomAvatar => 'Editar o avatar da sala';

  @override
  String get emoteExists => 'Emoji já existe!';

  @override
  String get emoteInvalid => 'Código emoji inválido!';

  @override
  String get emotePacks => 'Pacote de emoji para a sala';

  @override
  String get emoteSettings => 'Configuração dos Emoji';

  @override
  String get emoteShortcode => 'Código Emoji';

  @override
  String get emoteWarnNeedToPick =>
      'Você tem que escolher um código emoji e uma imagem!';

  @override
  String get emptyChat => 'Conversa vazia';

  @override
  String get enableEmotesGlobally => 'Habilitar globalmente o pacote de emoji';

  @override
  String get enableEncryption => 'Habilitar criptografia';

  @override
  String get enableEncryptionWarning =>
      'Você não poderá desabilitar a criptografia posteriormente. Tem certeza?';

  @override
  String get encrypted => 'Criptografado';

  @override
  String get encryption => 'Criptografia';

  @override
  String get encryptionNotEnabled => 'A criptografia não está habilitada';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName finalizou a chamada';
  }

  @override
  String get enterAnEmailAddress => 'Inserir endereço de e-mail';

  @override
  String get enterASpacepName => 'Insira um nome pro espaço';

  @override
  String get homeserver => 'Servidor matriz';

  @override
  String get enterYourHomeserver => 'Insira um servidor matriz';

  @override
  String errorObtainingLocation(Object error) {
    return 'Erro ao obter local: $error';
  }

  @override
  String get everythingReady => 'Tudo pronto!';

  @override
  String get extremeOffensive => 'Extremamente ofensivo';

  @override
  String get fileName => 'Nome do arquivo';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Tamanho da fonte';

  @override
  String get forward => 'Encaminhar';

  @override
  String get friday => 'Sexta-feira';

  @override
  String get fromJoining => 'Desde que entrou';

  @override
  String get fromTheInvitation => 'Desde o convite';

  @override
  String get goToTheNewRoom => 'Ir para a sala nova';

  @override
  String get group => 'Grupo';

  @override
  String get groupDescription => 'Descrição do grupo';

  @override
  String get groupDescriptionHasBeenChanged => 'Descrição do grupo alterada';

  @override
  String get groupIsPublic => 'Grupo público';

  @override
  String get groups => 'Grupos';

  @override
  String groupWith(Object displayname) {
    return 'Grupo com $displayname';
  }

  @override
  String get guestsAreForbidden => 'Convidados estão proibidos';

  @override
  String get guestsCanJoin => 'Convidados podem participar';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username revogou o convite para $targetName';
  }

  @override
  String get help => 'Ajuda';

  @override
  String get hideRedactedEvents => 'Ocultar eventos removidos';

  @override
  String get hideUnknownEvents => 'Ocultar eventos desconhecidos';

  @override
  String get howOffensiveIsThisContent => 'O quão ofensivo é este conteúdo?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identidade';

  @override
  String get ignore => 'Ignorar';

  @override
  String get ignoredUsers => 'Usuários ignorados';

  @override
  String get ignoreListDescription =>
      'Você pode ignorar usuários que estão lhe pertubando. Não será possível receber mensagens ou convites de usuários na sua lista pessoal de ignorados.';

  @override
  String get ignoreUsername => 'Ignorar usuário';

  @override
  String get iHaveClickedOnLink => 'Eu cliquei no link';

  @override
  String get incorrectPassphraseOrKey =>
      'Frase secreta ou chave de recuperação incorreta';

  @override
  String get inoffensive => 'Inofensivo';

  @override
  String get inviteContact => 'Convidar contato';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Convidar contato para $groupName';
  }

  @override
  String get invited => 'Foi convidado';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username convidou $targetName';
  }

  @override
  String get invitedUsersOnly => 'Apenas usuários convidados';

  @override
  String get inviteForMe => 'Convite para mim';

  @override
  String inviteText(Object username, Object link) {
    return '$username convidou você para o FluffyChat. \n1. Instale o FluffyChat: https://fluffychat.im \n2. Entre ou crie uma conta \n3. Abra o link do convite: $link';
  }

  @override
  String get isTyping => 'está escrevendo';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username entrou na conversa';
  }

  @override
  String get joinRoom => 'Entrar na sala';

  @override
  String get keysCached => 'Chaves guardadas';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username enxotou $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username expulsou e baniu $targetName';
  }

  @override
  String get kickFromChat => 'Expulso da conversa';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Última vez ativo: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Visto há muito tempo atrás';

  @override
  String get leave => 'Sair';

  @override
  String get leftTheChat => 'Sair da conversa';

  @override
  String get license => 'Licença';

  @override
  String get lightTheme => 'Claro';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Carregue $count mais participantes';
  }

  @override
  String get dehydrate => 'Exportar sessão e limpar dispositivo';

  @override
  String get dehydrateWarning =>
      'Esta ação não pode ser desfeita. Certifique-se de que o arquivo backup está guardado e seguro.';

  @override
  String get dehydrateShare =>
      'Este é seu extrato FluffyChat. Cuidado para não perdê-lo e o mantenha privado.';

  @override
  String get dehydrateTor => 'Usuários TOR: Exportar sessão';

  @override
  String get dehydrateTorLong =>
      'Para usuários TOR, é recomendado exportar a sessão antes de fechar a janela.';

  @override
  String get hydrateTor => 'Usuários TOR: Importar sessão';

  @override
  String get hydrateTorLong =>
      'Você exportou sua última sessão no TOR? Importe ela rapidamente e continue conversando.';

  @override
  String get hydrate => 'Restaurar a partir de arquivo backup';

  @override
  String get loadingPleaseWait => 'Carregando... Aguarde.';

  @override
  String get loadMore => 'Carregando mais…';

  @override
  String get locationDisabledNotice =>
      'O serviço de localização está desabilitado. Por favor, habilite-o para compartilhar sua localização.';

  @override
  String get locationPermissionDeniedNotice =>
      'Permissão de localização negada. Conceda as permissões para habilitar o compartilhamento de localização.';

  @override
  String get login => 'Iniciar sessão';

  @override
  String logInTo(Object homeserver) {
    return 'Conectar a $homeserver';
  }

  @override
  String get loginWithOneClick => 'Entrar com um clique';

  @override
  String get logout => 'Encerrar sessão';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Certifique-se de que a identificação é válida';

  @override
  String get memberChanges => 'Alterações de membros';

  @override
  String get mention => 'Mencionar';

  @override
  String get messages => 'Mensagens';

  @override
  String get messageWillBeRemovedWarning =>
      'Mensagem será removida para todos os participantes';

  @override
  String get moderator => 'Moderador';

  @override
  String get monday => 'Segunda-feira';

  @override
  String get muteChat => 'Silenciar';

  @override
  String get needPantalaimonWarning =>
      'Por favor, observe que, por enquanto, você precisa do Pantalaimon para usar criptografia ponta-a-ponta.';

  @override
  String get newChat => 'Nova conversa';

  @override
  String get newVerificationRequest => 'Nova solicitação de verificação!';

  @override
  String get next => 'Próximo';

  @override
  String get no => 'Não';

  @override
  String get noConnectionToTheServer => 'Sem conexão com o servidor';

  @override
  String get noEmotesFound => 'Nenhum emoji encontrado. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Você só pode ativar criptografia quando a sala não for mais publicamente acessível.';

  @override
  String get noGoogleServicesWarning =>
      'Aparentemente você não tem serviços Google no seu celular. Boa decisão para a sua privacidade! Para receber notificações no FluffyChat, recomendamos usar https://microg.org/ ou https://unifiedpush.org.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 não é um servidor matrix, usar $server2 talvez?';
  }

  @override
  String get shareYourInviteLink => 'Compartilhar o link do convite';

  @override
  String get typeInInviteLinkManually =>
      'Digitar o link do convite manualmente...';

  @override
  String get scanQrCode => 'Escanear o código QR';

  @override
  String get none => 'Nenhum';

  @override
  String get noPasswordRecoveryDescription =>
      'Você ainda não adicionou uma forma de recuparar sua senha.';

  @override
  String get noPermission => 'Sem permissão';

  @override
  String get noRoomsFound => 'Nenhuma sala encontrada…';

  @override
  String get notifications => 'Notificações';

  @override
  String numUsersTyping(Object count) {
    return '$count usuários estão digitando';
  }

  @override
  String get obtainingLocation => 'Obtendo localização…';

  @override
  String get offensive => 'Ofensivo';

  @override
  String get offline => 'Desconectado';

  @override
  String get ok => 'Ok';

  @override
  String get online => 'Disponível';

  @override
  String get onlineKeyBackupEnabled => 'Backup de chaves está ativado';

  @override
  String get oopsPushError =>
      'Opa! Infelizmente, um erro ocorreu ao configurar as notificações.';

  @override
  String get oopsSomethingWentWrong => 'Opa, algo deu errado…';

  @override
  String get openAppToReadMessages => 'Abra o app para ler as mensagens';

  @override
  String get openCamera => 'Abra a câmera';

  @override
  String get openVideoCamera => 'Abra a câmera para um vídeo';

  @override
  String get oneClientLoggedOut => 'Um dos seus clientes foi desvinculado';

  @override
  String get addAccount => 'Adicionar conta';

  @override
  String get editBundlesForAccount => 'Editar coleções para esta conta';

  @override
  String get addToBundle => 'Adicionar à coleção';

  @override
  String get removeFromBundle => 'Remover desta coleção';

  @override
  String get bundleName => 'Nome da coleção';

  @override
  String get enableMultiAccounts =>
      '(BETA) Habilitar múltiplas contas neste dispositivo';

  @override
  String get openInMaps => 'Abrir no mapas';

  @override
  String get link => 'Link';

  @override
  String get serverRequiresEmail =>
      'Este servidor precisa validar seu email para efetuar o registro.';

  @override
  String get optionalGroupName => '(Opcional) Nome do Grupo';

  @override
  String get or => 'Ou';

  @override
  String get participant => 'Participante';

  @override
  String get passphraseOrKey => 'frase secreta ou chave de recuperação';

  @override
  String get password => 'Senha';

  @override
  String get passwordForgotten => 'Esqueci a senha';

  @override
  String get passwordHasBeenChanged => 'Senha foi alterada';

  @override
  String get passwordRecovery => 'Recuperação de senha';

  @override
  String get people => 'Pessoas';

  @override
  String get pickImage => 'Escolha uma imagem';

  @override
  String get pin => 'Alfinetar';

  @override
  String play(Object fileName) {
    return 'Tocar $fileName';
  }

  @override
  String get pleaseChoose => 'Por favor, selecione';

  @override
  String get pleaseChooseAPasscode => 'Por favor, escolha um código';

  @override
  String get pleaseChooseAUsername => 'Por favor, escolha um nome de usuário';

  @override
  String get pleaseClickOnLink =>
      'Por favor, clique a ligação no e-mail para prosseguir.';

  @override
  String get pleaseEnter4Digits =>
      'Por favor, insira 4 dígitos ou deixe em branco para desativar a trava do aplicativo.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Por favor, insira o ID Matrix.';

  @override
  String get pleaseEnterRecoveryKey =>
      'Por favor, insira sua chave de recuperação:';

  @override
  String get pleaseEnterYourPassword => 'Por favor, insira sua senha';

  @override
  String get pleaseEnterYourPin => 'Por favor, insira seu PIN';

  @override
  String get pleaseEnterYourUsername => 'Por favor, insira seu nome de usuário';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Por favor, siga as instruções no site e toque em próximo.';

  @override
  String get privacy => 'Privacidade';

  @override
  String get publicRooms => 'Salas públicas';

  @override
  String get pushRules => 'Regras de notificação';

  @override
  String get reason => 'Motivo';

  @override
  String get recording => 'Gravando';

  @override
  String redactedAnEvent(Object username) {
    return '$username removeu um evento';
  }

  @override
  String get redactMessage => 'Retratar mensagem';

  @override
  String get register => 'Registrar';

  @override
  String get reject => 'Recusar';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username recusou o convite';
  }

  @override
  String get rejoin => 'Retornar';

  @override
  String get remove => 'Remover';

  @override
  String get removeAllOtherDevices => 'Remover todos os outros dispositivos';

  @override
  String removedBy(Object username) {
    return 'Removido por $username';
  }

  @override
  String get removeDevice => 'Remover dispositivo';

  @override
  String get unbanFromChat => 'Revogar banimento';

  @override
  String get removeYourAvatar => 'Remover seu avatar';

  @override
  String get renderRichContent => 'Exibir conteúdo formatado';

  @override
  String get replaceRoomWithNewerVersion =>
      'Substituir sala por uma nova versão';

  @override
  String get reply => 'Responder';

  @override
  String get reportMessage => 'Denunciar mensagem';

  @override
  String get requestPermission => 'Solicitar permissão';

  @override
  String get roomHasBeenUpgraded => 'Sala foi atualizada';

  @override
  String get roomVersion => 'Versão da sala';

  @override
  String get saturday => 'Sábado';

  @override
  String get saveFile => 'Salvar arquivo';

  @override
  String get security => 'Segurança';

  @override
  String get recoveryKey => 'Chave de recuperação';

  @override
  String get recoveryKeyLost => 'Perdeu a chave de recuperação?';

  @override
  String seenByUser(Object username) {
    return 'Visto por $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visto por $username e mais $count pessoas',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Visto por $username e $username2';
  }

  @override
  String get send => 'Enviar';

  @override
  String get sendAMessage => 'Enviar mensagem';

  @override
  String get sendAsText => 'Enviar como texto';

  @override
  String get sendAudio => 'Enviar audio';

  @override
  String get sendFile => 'Enviar arquivo';

  @override
  String get sendImage => 'Enviar imagem';

  @override
  String get sendMessages => 'Enviar mensagens';

  @override
  String get sendOriginal => 'Enviar original';

  @override
  String get sendSticker => 'Enviar figurinha';

  @override
  String get sendVideo => 'Enviar vídeo';

  @override
  String sentAFile(Object username) {
    return '📁 $username enviou um arquivo';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username enviou um audio';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username enviou uma imagem';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username enviou uma figurinha';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username enviou um vídeo';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName enviou informações de chamada';
  }

  @override
  String get separateChatTypes => 'Separar Conversas Diretas e Grupos';

  @override
  String get setAsCanonicalAlias => 'Fixar como cognome principal';

  @override
  String get setCustomEmotes => 'Implantar emojis personalizados';

  @override
  String get setGroupDescription => 'Fixar uma descrição do grupo';

  @override
  String get setInvitationLink => 'Enviar link de convite';

  @override
  String get setPermissionsLevel => 'Determinar níveis de permissão';

  @override
  String get setStatus => 'Alterar o status';

  @override
  String get settings => 'Configurações';

  @override
  String get share => 'Compartilhar';

  @override
  String sharedTheLocation(Object username) {
    return '$username compartilhou sua localização';
  }

  @override
  String get shareLocation => 'Compartilhar localização';

  @override
  String get showDirectChatsInSpaces =>
      'Mostrar Conversas Diretas relacionadas nos Espaços';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get signUp => 'Registrar';

  @override
  String get singlesignon => 'Identidade Única';

  @override
  String get skip => 'Pular';

  @override
  String get sourceCode => 'Código fonte';

  @override
  String get spaceIsPublic => 'Espaço é público';

  @override
  String get spaceName => 'Nome do espaço';

  @override
  String startedACall(Object senderName) {
    return '$senderName iniciou uma chamada';
  }

  @override
  String get status => 'Status';

  @override
  String get statusExampleMessage => 'Como vai você?';

  @override
  String get submit => 'Submeter';

  @override
  String get sunday => 'Domingo';

  @override
  String get synchronizingPleaseWait => 'Sincronizando… Por favor, aguarde.';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theyDontMatch => 'Não correspondem';

  @override
  String get theyMatch => 'Correspondem';

  @override
  String get thisRoomHasBeenArchived => 'Esta sala foi arquivada.';

  @override
  String get thursday => 'Quinta-feira';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Alternar favorito';

  @override
  String get toggleMuted => 'Alternar Silenciado';

  @override
  String get toggleUnread => 'Marcar lido/não lido';

  @override
  String get tooManyRequestsWarning =>
      'Demasiadas requisições. Por favor, tente novamente mais tarde!';

  @override
  String get transferFromAnotherDevice => 'Transferir de outro dispositivo';

  @override
  String get tryToSendAgain => 'Tente enviar novamente';

  @override
  String get tuesday => 'Terça-feira';

  @override
  String get unavailable => 'Indisponível';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username revogou o banimento de $targetName';
  }

  @override
  String get unblockDevice => 'Desbloquear dispositivo';

  @override
  String get unknownDevice => 'Dispositivo desconhecido';

  @override
  String get unknownEncryptionAlgorithm =>
      'Algoritmo de criptografia desconhecido';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Evento desconhecido \'$type\'';
  }

  @override
  String get unmuteChat => 'Cancelar silenciamento';

  @override
  String get unpin => 'Desalfinetar';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount conversas não lidas',
      one: '1 conversa não lida',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username e mais $count pessoas estão digitando';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username e $username2 estão digitando';
  }

  @override
  String userIsTyping(Object username) {
    return '$username está digitando';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username saiu da conversa';
  }

  @override
  String get username => 'Nome de usuário';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username enviou um evento $type';
  }

  @override
  String get unverified => 'Não verificado';

  @override
  String get verified => 'Verificado';

  @override
  String get verify => 'Verificar';

  @override
  String get verifyStart => 'Iniciar verificação';

  @override
  String get verifySuccess => 'Verificação efetivada!';

  @override
  String get verifyTitle => 'Verificando outra conta';

  @override
  String get videoCall => 'Vídeochamada';

  @override
  String get visibilityOfTheChatHistory =>
      'Visibilidade do histórico da conversa';

  @override
  String get visibleForAllParticipants => 'Visível aos participantes';

  @override
  String get visibleForEveryone => 'Visível a qualquer pessoa';

  @override
  String get voiceMessage => 'Mensagem de voz';

  @override
  String get waitingPartnerAcceptRequest =>
      'Esperando que a outra pessoa aceite a solicitação…';

  @override
  String get waitingPartnerEmoji =>
      'Esperando que a outra pessoa aceite os emoji…';

  @override
  String get waitingPartnerNumbers =>
      'Aguardando a outra pessoa aceitar os números…';

  @override
  String get wallpaper => 'Pano de fundo';

  @override
  String get warning => 'Atenção!';

  @override
  String get wednesday => 'Quarta-feira';

  @override
  String get weSentYouAnEmail => 'Enviamos um e-mail para você';

  @override
  String get whoCanPerformWhichAction => 'Quem pode desempenhar quais ações';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Quais pessoas são permitidas participar deste grupo';

  @override
  String get whyDoYouWantToReportThis => 'Por que você quer denunciar isto?';

  @override
  String get wipeChatBackup =>
      'Limpar o backup da conversa para criar uma nova chave de recuperação?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Você pode recuperar a sua senha com estes endereços.';

  @override
  String get writeAMessage => 'Escreva uma mensagem…';

  @override
  String get yes => 'Sim';

  @override
  String get you => 'Você';

  @override
  String get youAreInvitedToThisChat => 'Você foi convidada(o) a esta conversa';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Você não está mais participando desta conversa';

  @override
  String get youCannotInviteYourself => 'Você não pode se autoconvidar';

  @override
  String get youHaveBeenBannedFromThisChat => 'Você foi banido desta conversa';

  @override
  String get yourPublicKey => 'Sua chave pública';

  @override
  String get messageInfo => 'Informações da mensagem';

  @override
  String get time => 'Hora';

  @override
  String get messageType => 'Tipo da mensagem';

  @override
  String get sender => 'Remetente';

  @override
  String get openGallery => 'Abrir galeria';

  @override
  String get removeFromSpace => 'Remover do espaço';

  @override
  String get addToSpaceDescription =>
      'Selecione um espaço para adicionar esta conversa.';

  @override
  String get start => 'Começar';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Para destrancar suas mensagens antigas, por favor, insira sua chave de recuperação gerada numa sessão prévia. Suas chave de recuperação NÃO é sua senha.';

  @override
  String get addToStory => 'Adicionar ao painel';

  @override
  String get publish => 'Publicar';

  @override
  String get whoCanSeeMyStories => 'Quem pode ver meu painel?';

  @override
  String get unsubscribeStories => 'Desinscrever de painéis';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Este(a) usuário(a) ainda não postou no seu painel';

  @override
  String get yourStory => 'Seu painel';

  @override
  String get replyHasBeenSent => 'Resposta enviada';

  @override
  String videoWithSize(Object size) {
    return 'Vídeo ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Painel de $date:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Por favor, note que pessoas podem ver e contactar umas às outras no seu painel.';

  @override
  String get whatIsGoingOn => 'O que está acontecendo?';

  @override
  String get addDescription => 'Adicionar descrição';

  @override
  String get storyPrivacyWarning =>
      'Por favor, note que pessoas podem ver e contactar umas às outras no seu painel. Ele ficará visível por apenas 24 horas, mas não há garantias de que será apagado por todos dispositivos e servidores.';

  @override
  String get iUnderstand => 'Eu compreendo';

  @override
  String get openChat => 'Abrir conversa';

  @override
  String get markAsRead => 'Marcar como lido';

  @override
  String get reportUser => 'Delatar usuário';

  @override
  String get dismiss => 'Descartar';

  @override
  String get matrixWidgets => 'Ferramentas Matrix';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reagiu com $reaction';
  }

  @override
  String get confirmEventUnpin =>
      'Tem certeza que quer desafixar o evento permanentemente?';

  @override
  String get emojis => 'Emojis';

  @override
  String get placeCall => 'Chamar';

  @override
  String get voiceCall => 'Chamada de voz';

  @override
  String get unsupportedAndroidVersion => 'Versão Android não suportada';

  @override
  String get unsupportedAndroidVersionLong =>
      'Esta funcionalidade requer uma versão mais nova do Android. Por favor, busque atualizações ou suporte ao Lineage OS.';

  @override
  String get videoCallsBetaWarning =>
      'Por favor, note que chamadas de vídeo estão atualmente em teste. Podem não funcionar como esperado ou sequer funcionar em algumas plataformas.';

  @override
  String get experimentalVideoCalls => 'Vídeo chamadas experimentais';

  @override
  String get emailOrUsername => 'Email ou nome de usuário';

  @override
  String get indexedDbErrorTitle => 'Problemas no modo privado';

  @override
  String get indexedDbErrorLong =>
      'Infelizmente, o armazenamento de mensagens não é habilitado por padrão no modo privado.\nPor favor, visite\n- about:config\n- atribua \"true\" a \"dom.indexedDB.privateBrowsing.enabled\"\nDe outro modo, não será possível executar o FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'Alternar para a conta $number';
  }

  @override
  String get nextAccount => 'Próxima conta';

  @override
  String get previousAccount => 'Conta anterior';

  @override
  String get editWidgets => 'Editar ferramentas';

  @override
  String get addWidget => 'Adicionar ferramenta';

  @override
  String get widgetVideo => 'Vídeo';

  @override
  String get widgetEtherpad => 'Anotação';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Personalizado';

  @override
  String get widgetName => 'Nome';

  @override
  String get widgetUrlError => 'Isto não é uma URL válida.';

  @override
  String get widgetNameError => 'Por favor, forneça um nome de exibição.';

  @override
  String get errorAddingWidget => 'Erro ao adicionar a ferramenta.';

  @override
  String get youRejectedTheInvitation => 'Você rejeitou o convite';

  @override
  String get youJoinedTheChat => 'Você entrou na conversa';

  @override
  String get youAcceptedTheInvitation => '👍 Você aceitou o convite';

  @override
  String youBannedUser(Object user) {
    return 'Você baniu $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Você revogou o convite para $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 Você foi convidado por $user';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 Você convidou $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 Você expulsou $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 Você expulsou e baniu $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Você revogou o banimento de $user';
  }

  @override
  String get noEmailWarning =>
      'Por favor, insira um e-mail válido. De outro modo, você não conseguirá recuperar sua senha. Caso prefira assim, toque novamente no botão para continuar.';

  @override
  String get stories => 'Stories';

  @override
  String get users => 'Usuários';

  @override
  String get enableAutoBackups => 'Habilitar backups automáticos';

  @override
  String get unlockOldMessages => 'Destrancar mensagens antigas';

  @override
  String get storeInSecureStorageDescription =>
      'Guardar a chave de recuperação no armazenamento seguro deste dispositivo.';

  @override
  String get saveKeyManuallyDescription =>
      'Salvar esta chave manualmente via compartilhamento do sistema ou área de transferência.';

  @override
  String get storeInAndroidKeystore => 'Guardar no cofre do Android';

  @override
  String get storeInAppleKeyChain => 'Guardar no chaveiro da Apple';

  @override
  String get storeSecurlyOnThisDevice =>
      'Guardar de modo seguro neste dispositivo';

  @override
  String countFiles(Object count) {
    return '$count arquivos';
  }

  @override
  String get user => 'Usuário';

  @override
  String get custom => 'Personalizado';

  @override
  String get foregroundServiceRunning =>
      'Esta notificação aparece quando um serviço está executando.';

  @override
  String get screenSharingTitle => 'Compartilhar tela';

  @override
  String get screenSharingDetail =>
      'Você está compartilhando sua tela no FluffyChat';

  @override
  String get callingPermissions => 'Permissões de chamada';

  @override
  String get callingAccount => 'Conta para chamadas';

  @override
  String get callingAccountDetails =>
      'Permitir que o FluffyChat use o app de chamadas nativo do Android.';

  @override
  String get appearOnTop => 'Aparecer no topo';

  @override
  String get appearOnTopDetails =>
      'Permitir que o app apareça no topo (desnecessário caso FluffyChat já esteja configurado como conta para chamadas)';

  @override
  String get otherCallingPermissions =>
      'Microfone, câmera e outras permissões do FluffyChat';

  @override
  String get whyIsThisMessageEncrypted =>
      'Por que esta mensagem está ilegível?';

  @override
  String get noKeyForThisMessage =>
      'Isto pode ocorrer caso a mensagem tenha sido enviada antes da entrada na sua conta com este dispositivo.\n\nTambém é possível que o remetente tenha bloqueado o seu dispositivo ou ocorreu algum problema com a conexão.\n\nVocê consegue ler as mensagens em outra sessão? Então, pode transferir as mensagens de lá! Vá em Configurações > Dispositivos e confira se os dispositivos verificaram um ao outro. Quando abrir a conversa da próxima vez e ambas as sessões estiverem abertas, as chaves serão transmitidas automaticamente.\n\nNão gostaria de perder suas chaves quando sair ou trocar de dispositivos? Certifique-se que o backup de conversas esteja habilitado nas configurações.';

  @override
  String get newGroup => 'Novo grupo';

  @override
  String get newSpace => 'Novo espaço';

  @override
  String get enterSpace => 'Entrar no espaço';

  @override
  String get enterRoom => 'Entrar na conversa';

  @override
  String get allSpaces => 'Todos espaços';

  @override
  String numChats(Object number) {
    return '$number conversas';
  }

  @override
  String get hideUnimportantStateEvents => 'Ocultar eventos desimportantes';

  @override
  String get doNotShowAgain => 'Não mostrar novamente';

  @override
  String get search => 'Buscar';
}

/// The translations for Portuguese, as used in Portugal (`pt_PT`).
class L10nPtPt extends L10nPt {
  L10nPtPt() : super('pt_PT');

  @override
  String get passwordsDoNotMatch => 'As palavras-passe não correspondem!';

  @override
  String get pleaseEnterValidEmail =>
      'Por favor, insere um endereço de correio eletrónico válido.';

  @override
  String get repeatPassword => 'Repete a palavra-passe';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Por favor, usa no mínimo $min caracteres.';
  }

  @override
  String get about => 'Acerca de';

  @override
  String get updateAvailable => 'Atualização do FluffyChat disponível';

  @override
  String get updateNow => 'Iniciar atualização me segundo plano';

  @override
  String get accept => 'Aceitar';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username aceitou o convite';
  }

  @override
  String get account => 'Conta';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username ativou encriptação ponta-a-ponta';
  }

  @override
  String get addEmail => 'Adicionar correio eletrónico';

  @override
  String get confirmMatrixId =>
      'Por favor, confirme o seu ID Matrix para apagar a sua conta.';

  @override
  String supposedMxid(Object mxid) {
    return 'Isto deveria ser $mxid';
  }

  @override
  String get addGroupDescription => 'Adicionar descrição de grupo';

  @override
  String get addToSpace => 'Adicionar ao espaço';

  @override
  String get admin => 'Admin';

  @override
  String get alias => 'alcunha';

  @override
  String get all => 'Todos(as)';

  @override
  String get allChats => 'Todas as conversas';

  @override
  String get commandHint_googly => 'Enviar olhos grilidos';

  @override
  String get commandHint_cuddle => 'Enviar um afago';

  @override
  String get commandHint_hug => 'Enviar um abraço';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName enviou olhos grilidos';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName afagou-o';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName abraçou-o';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName atendeu a chamada';
  }

  @override
  String get anyoneCanJoin => 'Qualquer pessoa pode entrar';

  @override
  String get appLock => 'Bloqueio da aplicação';

  @override
  String get archive => 'Arquivo';

  @override
  String get archivedRoom => 'Sala arquivada';

  @override
  String get areGuestsAllowedToJoin => 'Todos os visitantes podem entrar';

  @override
  String get areYouSure => 'Tens a certeza?';

  @override
  String get areYouSureYouWantToLogout => 'Tens a certeza que queres sair?';

  @override
  String get askSSSSSign =>
      'Para poderes assinar a outra pessoa, por favor, insere a tua senha de armazenamento seguro ou a chave de recuperação.';

  @override
  String askVerificationRequest(Object username) {
    return 'Aceitar este pedido de verificação de $username?';
  }

  @override
  String get autoplayImages =>
      'Automaticamente reproduzir autocolantes e emotes animados';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'O servidor suporta os tipos de início de sessão:\n$serverVersions\nMas esta aplicação apenas suporta:\n$suportedVersions';
  }

  @override
  String get sendOnEnter => 'Enviar com Enter';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'O servidor suporta as versões Spec:\n$serverVersions\nMas esta aplicação apenas suporta $suportedVersions';
  }

  @override
  String get banFromChat => 'Banir da conversa';

  @override
  String get banned => 'Banido(a)';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username baniu $targetName';
  }

  @override
  String get blockDevice => 'Bloquear dispositivo';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get botMessages => 'Mensagens de robôs';

  @override
  String get bubbleSize => 'Tamanho da bolha';

  @override
  String get cancel => 'Cancelar';

  @override
  String cantOpenUri(Object uri) {
    return 'Não é possível abrir o URI $uri';
  }

  @override
  String get changeDeviceName => 'Alterar nome do dispositivo';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username alterou o avatar da conversa';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username alterou a descrição da conversa para: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username alterou o nome da conversa para: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username alterou as permissões da conversa';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username alterou o seu nome para: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username alterou as regras de acesso de visitantes';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username alterou as regras de acesso de visitantes para: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username alterou a visibilidade do histórico';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username alterou a visibilidade do histórico para: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username alterou as regras de entrada';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username alterou as regras de entrada para: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username alterou o seu avatar';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username alterou as alcunhas da sala';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username alterou a ligação de convite';
  }

  @override
  String get changePassword => 'Alterar palavra-passe';

  @override
  String get changeTheHomeserver => 'Alterar o servidor';

  @override
  String get changeTheme => 'Alterar o teu estilo';

  @override
  String get changeTheNameOfTheGroup => 'Alterar o nome do grupo';

  @override
  String get changeWallpaper => 'Alterar o fundo';

  @override
  String get changeYourAvatar => 'Alterar o teu avatar';

  @override
  String get channelCorruptedDecryptError => 'A encriptação foi corrompida';

  @override
  String get chat => 'Conversa';

  @override
  String get yourUserId => 'O teu ID de utilizador:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'A cópia de segurança foi configurada.';

  @override
  String get chatBackup => 'Cópia de segurança de conversas';

  @override
  String get chatBackupDescription =>
      'A tuas mensagens antigas estão protegidas com uma chave de recuperação. Por favor, certifica-te que não a perdes.';

  @override
  String get chatDetails => 'Detalhes de conversa';

  @override
  String get chatHasBeenAddedToThisSpace =>
      'A conversa foi adicionada a este espaço';

  @override
  String get chats => 'Conversas';

  @override
  String get chooseAStrongPassword => 'Escolhe uma palavra-passe forte';

  @override
  String get chooseAUsername => 'Escolhe um nome de utilizador';

  @override
  String get clearArchive => 'Limpar arquivo';

  @override
  String get close => 'Fechar';

  @override
  String get commandHint_markasdm => 'Marcar como conversa direta';

  @override
  String get commandHint_markasgroup => 'Marcar como grupo';

  @override
  String get commandHint_ban => 'Banir o utilizador dado desta sala';

  @override
  String get commandHint_clearcache => 'Limpar cache';

  @override
  String get commandHint_create =>
      'Criar uma conversa de grupo vazia\nUsa --no-encryption para desativar a encriptação';

  @override
  String get commandHint_discardsession => 'Descartar sessão';

  @override
  String get commandHint_dm =>
      'Iniciar uma conversa direta\nUsa --no-encryption para desativar a encriptação';

  @override
  String get commandHint_html => 'Enviar texto formatado com HTML';

  @override
  String get commandHint_invite => 'Convidar o utilizador dado a esta sala';

  @override
  String get commandHint_join => 'Entrar na sala dada';

  @override
  String get commandHint_kick => 'Remover o utilizador dado desta sala';

  @override
  String get commandHint_leave => 'Sair desta sala';

  @override
  String get commandHint_me => 'Descreve-te';

  @override
  String get commandHint_myroomavatar =>
      'Definir a tua imagem para esta sala (por mxc-uri)';

  @override
  String get commandHint_myroomnick => 'Definir o teu nome para esta sala';

  @override
  String get commandHint_op =>
      'Definir o nível de poder do utilizador dado (por omissão: 50)';

  @override
  String get commandHint_plain => 'Enviar texto não formatado';

  @override
  String get commandHint_react => 'Enviar respostas como reações';

  @override
  String get commandHint_send => 'Enviar texto';

  @override
  String get commandHint_unban => 'Perdoar o utilizador dado';

  @override
  String get commandInvalid => 'Comando inválido';

  @override
  String commandMissing(Object command) {
    return '$command não é um comando.';
  }

  @override
  String get compareEmojiMatch =>
      'Compara e certifica-te que os emojis que se seguem correspondem aos do outro dispositivo:';

  @override
  String get compareNumbersMatch =>
      'Compara e certifica-te que os números que se seguem correspondem aos do outro dispositivo:';

  @override
  String get configureChat => 'Configurar conversa';

  @override
  String get confirm => 'Confirmar';

  @override
  String get connect => 'Ligar';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'O contacto foi convidado para o grupo';

  @override
  String get containsDisplayName => 'Contém nome de exibição';

  @override
  String get containsUserName => 'Contém nome de utilizador';

  @override
  String get contentHasBeenReported =>
      'O conteúdo foi denunciado aos admins do servidor';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get copy => 'Copiar';

  @override
  String get copyToClipboard => 'Copiar para a área de transferência';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Não foi possível desencriptar mensagem: $error';
  }

  @override
  String get create => 'Criar';

  @override
  String createdTheChat(Object username) {
    return '$username criou a conversa';
  }

  @override
  String get createNewGroup => 'Criar novo grupo';

  @override
  String get createNewSpace => 'Novo espaço';

  @override
  String get crossSigningEnabled => 'Assinatura cruzada ativada';

  @override
  String get currentlyActive => 'Ativo(a) agora';

  @override
  String get darkTheme => 'Escuro';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date às $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$day-$month';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$day-$month-$year';
  }

  @override
  String get deactivateAccountWarning =>
      'Isto irá desativar a tua conta. Não é reversível! Tens a certeza?';

  @override
  String get defaultPermissionLevel => 'Nível de permissão normal';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAccount => 'Eliminar conta';

  @override
  String get deleteMessage => 'Eliminar mensagem';

  @override
  String get deny => 'Recusar';

  @override
  String get device => 'Dispositivo';

  @override
  String get deviceId => 'ID de dispositivo';

  @override
  String get devices => 'Dispositivos';

  @override
  String get directChats => 'Conversas diretas';

  @override
  String get discover => 'Descobrir';

  @override
  String get displaynameHasBeenChanged => 'Nome de exibição alterado';

  @override
  String get download => 'Descarregar';

  @override
  String get edit => 'Editar';

  @override
  String get editBlockedServers => 'Editar servidores bloqueados';

  @override
  String get editChatPermissions => 'Editar permissões de conversa';

  @override
  String get editDisplayname => 'Editar nome de exibição';

  @override
  String get editRoomAliases => 'Editar alcunhas da sala';

  @override
  String get editRoomAvatar => 'Editar avatar da sala';

  @override
  String get emoteExists => 'Emote já existente!';

  @override
  String get emoteInvalid => 'Código de emote inválido!';

  @override
  String get emotePacks => 'Pacotes de emotes da sala';

  @override
  String get emoteSettings => 'Configurações de emotes';

  @override
  String get emoteShortcode => 'Código do emote';

  @override
  String get emoteWarnNeedToPick =>
      'Precisas de escolher um código de emote e uma imagem!';

  @override
  String get emptyChat => 'Conversa vazia';

  @override
  String get enableEmotesGlobally => 'Ativar pacote de emotes globalmente';

  @override
  String get enableEncryption => 'Ativar encriptação';

  @override
  String get enableEncryptionWarning =>
      'Nunca mais poderás desativar a encriptação. Tens a certeza?';

  @override
  String get encrypted => 'Encriptada';

  @override
  String get encryption => 'Encriptação';

  @override
  String get encryptionNotEnabled => 'A encriptação não está ativada';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName terminou a chamada';
  }

  @override
  String get enterAnEmailAddress => 'Insere um endereço de correio eletrónico';

  @override
  String get enterASpacepName => 'Insere o nome do espaço';

  @override
  String get homeserver => 'Servidor';

  @override
  String get enterYourHomeserver => 'Insere o teu servidor';

  @override
  String errorObtainingLocation(Object error) {
    return 'Erro ao obter localização: $error';
  }

  @override
  String get everythingReady => 'Tudo a postos!';

  @override
  String get extremeOffensive => 'Extremamente ofensivo';

  @override
  String get fileName => 'Nome do ficheiro';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Tamanho da letra';

  @override
  String get forward => 'Reencaminhar';

  @override
  String get friday => 'Sexta-feira';

  @override
  String get fromJoining => 'Desde que entrou';

  @override
  String get fromTheInvitation => 'Desde o convite';

  @override
  String get goToTheNewRoom => 'Ir para a nova sala';

  @override
  String get group => 'Grupo';

  @override
  String get groupDescription => 'Descrição do grupo';

  @override
  String get groupDescriptionHasBeenChanged => 'Descrição do grupo alterada';

  @override
  String get groupIsPublic => 'O grupo é público';

  @override
  String get groups => 'Grupos';

  @override
  String groupWith(Object displayname) {
    return 'Grupo com $displayname';
  }

  @override
  String get guestsAreForbidden => 'São proibidos visitantes';

  @override
  String get guestsCanJoin => 'Podem entrar visitantes';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username revogou o convite para $targetName';
  }

  @override
  String get help => 'Ajuda';

  @override
  String get hideRedactedEvents => 'Esconder eventos eliminados';

  @override
  String get hideUnknownEvents => 'Esconder eventos desconhecidos';

  @override
  String get howOffensiveIsThisContent => 'Quão ofensivo é este conteúdo?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identidade';

  @override
  String get ignore => 'Ignorar';

  @override
  String get ignoredUsers => 'Utilizadores ignorados';

  @override
  String get ignoreListDescription =>
      'Podes ignorar utilizadores que te incomodem. Não irás poder receber quaisquer mensagens ou convites para salas de utilizadores na tua lista pessoal de ignorados.';

  @override
  String get ignoreUsername => 'Nome do utilizador a ignorar';

  @override
  String get iHaveClickedOnLink => 'Eu cliquei na ligação';

  @override
  String get incorrectPassphraseOrKey =>
      'Senha ou chave de recuperação incorretos';

  @override
  String get inoffensive => 'Inofensivo';

  @override
  String get inviteContact => 'Convidar contacto';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Convidar contacto para $groupName';
  }

  @override
  String get invited => 'Convidado(a)';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username convidou $targetName';
  }

  @override
  String get invitedUsersOnly => 'Utilizadores(as) convidados(as) apenas';

  @override
  String get inviteForMe => 'Convite para mim';

  @override
  String inviteText(Object username, Object link) {
    return '$username convidou-te para o FluffyChat.\n1. Instala o FluffyChat: https://fluffychat.im\n2. Regista-te ou inicia sessão.\n3. Abre a ligação de convite: $link';
  }

  @override
  String get isTyping => 'está a escrever';

  @override
  String joinedTheChat(Object username) {
    return '$username entrou na conversa';
  }

  @override
  String get joinRoom => 'Entrar na sala';

  @override
  String get keysCached => 'Chaves estão armazenadas em cache';

  @override
  String kicked(Object username, Object targetName) {
    return '$username expulsou $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username expulsou e baniu $targetName';
  }

  @override
  String get kickFromChat => 'Expulsar da conversa';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Ativo(a) pela última vez: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Visto(a) há muito tempo';

  @override
  String get leave => 'Sair';

  @override
  String get leftTheChat => 'Saiu da conversa';

  @override
  String get license => 'Licença';

  @override
  String get lightTheme => 'Claro';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Carregar mais $count participantes';
  }

  @override
  String get dehydrate => 'Exportar sessão e limpar dispositivo';

  @override
  String get dehydrateWarning =>
      'Esta ação não pode ser revertida. Assegura-te que guardas bem a cópia de segurança.';

  @override
  String get dehydrateShare =>
      'Esta é a tua exportação privada do FluffyChat. Assegura-te que não a perdes e que a manténs privada.';

  @override
  String get dehydrateTor => 'Utilizadores do TOR: Exportar sessão';

  @override
  String get dehydrateTorLong =>
      'Para utilizadores do TOR, é recomendado exportar a sessão antes de fechar a janela.';

  @override
  String get hydrateTor => 'Utilizadores do TOR: Importar sessão';

  @override
  String get hydrateTorLong =>
      'Exportaste a tua sessão na última vez que estiveste no TOR? Importa-a rapidamente e continua a conversar.';

  @override
  String get hydrate => 'Restaurar a partir de cópia de segurança';

  @override
  String get loadingPleaseWait => 'A carregar... Por favor aguarde.';

  @override
  String get loadMore => 'Carregar mais…';

  @override
  String get locationDisabledNotice =>
      'Os serviços de localização estão desativados. Por favor, ativa-os para poder partilhar a sua localização.';

  @override
  String get locationPermissionDeniedNotice =>
      'Permissão de localização recusada. Por favor, concede permissão para poderes partilhar a tua posição.';

  @override
  String get login => 'Entrar';

  @override
  String logInTo(Object homeserver) {
    return 'Entrar em $homeserver';
  }

  @override
  String get loginWithOneClick => 'Entrar com um clique';

  @override
  String get logout => 'Sair';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Certifica-te que o identificador é válido';

  @override
  String get memberChanges => 'Alterações de membros';

  @override
  String get mention => 'Mencionar';

  @override
  String get messages => 'Mensagens';

  @override
  String get messageWillBeRemovedWarning =>
      'A mensagem será eliminada para todos os participantes';

  @override
  String get moderator => 'Moderador';

  @override
  String get monday => 'Segunda-feira';

  @override
  String get muteChat => 'Silenciar conversa';

  @override
  String get needPantalaimonWarning => 'Por favor,';

  @override
  String get newChat => 'Nova conversa';

  @override
  String get newVerificationRequest => 'Novo pedido de verificação!';

  @override
  String get next => 'Próximo';

  @override
  String get no => 'Não';

  @override
  String get noConnectionToTheServer => 'Nenhuma ligação ao servidor';

  @override
  String get noEmotesFound => 'Nenhuns emotes encontrados. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Só podes ativar a encriptação quando a sala não for publicamente acessível.';

  @override
  String get noGoogleServicesWarning =>
      'Parece que não tens nenhuns serviços da Google no seu telemóvel. É uma boa decisão para a sua privacidade! Para receber notificações instantâneas no FluffyChat, recomendamos que uses https://microg.org/ ou https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 não é um servidor Matrix, usar $server2?';
  }

  @override
  String get shareYourInviteLink => 'Partilhar a ligação de convite';

  @override
  String get typeInInviteLinkManually =>
      'Escrever a ligação de convite manualmente...';

  @override
  String get scanQrCode => 'Escanear o código QR';

  @override
  String get none => 'Nenhum';

  @override
  String get noPasswordRecoveryDescription =>
      'Ainda não adicionaste uma forma de recuperar a tua palavra-passe.';

  @override
  String get noPermission => 'Sem permissão';

  @override
  String get noRoomsFound => 'Não foram encontradas nenhumas salas…';

  @override
  String get notifications => 'Notificações';

  @override
  String numUsersTyping(Object count) {
    return 'Estão $count utilizadores(as) a escrever';
  }

  @override
  String get obtainingLocation => 'A obter localização…';

  @override
  String get offensive => 'Offensivo';

  @override
  String get offline => 'Offline';

  @override
  String get ok => 'ok';

  @override
  String get online => 'Online';

  @override
  String get onlineKeyBackupEnabled =>
      'A cópia de segurança online de chaves está ativada';

  @override
  String get oopsPushError =>
      'Ups! Infelizmente, ocorreu um erro ao configurar as notificações instantâneas.';

  @override
  String get oopsSomethingWentWrong => 'Ups, algo correu mal…';

  @override
  String get openAppToReadMessages => 'Abrir aplicação para ler mensagens';

  @override
  String get openCamera => 'Abrir câmara';

  @override
  String get openVideoCamera => 'Abra a câmara para um vídeo';

  @override
  String get oneClientLoggedOut => 'Um dos teus clientes terminou sessão';

  @override
  String get addAccount => 'Adicionar conta';

  @override
  String get editBundlesForAccount => 'Editar pacotes para esta conta';

  @override
  String get addToBundle => 'Adicionar ao pacote';

  @override
  String get removeFromBundle => 'Remover deste pacote';

  @override
  String get bundleName => 'Nome do pacote';

  @override
  String get enableMultiAccounts =>
      '(BETA) Ativar múltiplas contas neste dispositivo';

  @override
  String get openInMaps => 'Abrir nos mapas';

  @override
  String get link => 'Ligação';

  @override
  String get serverRequiresEmail =>
      'Este servidor precisa de validar o teu endereço de correio eletrónico para o registo.';

  @override
  String get optionalGroupName => '(Opcional) Nome do grupo';

  @override
  String get or => 'Ou';

  @override
  String get participant => 'Participante';

  @override
  String get passphraseOrKey => 'senha ou chave de recuperação';

  @override
  String get password => 'Palavra-passe';

  @override
  String get passwordForgotten => 'Palavra-passe esquecida';

  @override
  String get passwordHasBeenChanged => 'A palavra-passe foi alterada';

  @override
  String get passwordRecovery => 'Recuperação de palavra-passe';

  @override
  String get people => 'Pessoas';

  @override
  String get pickImage => 'Escolher uma imagem';

  @override
  String get pin => 'Afixar';

  @override
  String play(Object fileName) {
    return 'Reproduzir $fileName';
  }

  @override
  String get pleaseChoose => 'Por favor, escolhe';

  @override
  String get pleaseChooseAPasscode => 'Por favor, escolhe um código-passe';

  @override
  String get pleaseChooseAUsername =>
      'Por favor, escolhe um nome de utilizador';

  @override
  String get pleaseClickOnLink =>
      'Por favor, clica na ligação no correio eletrónico e depois continua.';

  @override
  String get pleaseEnter4Digits =>
      'Por favor, insere 4 dígitos ou deixa vazio para desativar o bloqueio da aplicação.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Por favor, insere um ID Matrix.';

  @override
  String get pleaseEnterRecoveryKey =>
      'Por favor, insira a sua chave de recuperação:';

  @override
  String get pleaseEnterYourPassword => 'Por favor, insere a tua palavra-passe';

  @override
  String get pleaseEnterYourPin => 'Por favor, insere o teu código';

  @override
  String get pleaseEnterYourUsername =>
      'Por favor, insere o teu nome de utilizador';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Por favor, segue as instruções no website e clica em \"Seguinte\".';

  @override
  String get privacy => 'Privacidade';

  @override
  String get publicRooms => 'Salas públicas';

  @override
  String get pushRules => 'Regras de notificação';

  @override
  String get reason => 'Razão';

  @override
  String get recording => 'A gravar';

  @override
  String redactedAnEvent(Object username) {
    return '$username eliminou um evento';
  }

  @override
  String get redactMessage => 'Eliminar mensagem';

  @override
  String get register => 'Registar';

  @override
  String get reject => 'Rejeitar';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username rejeitou o convite';
  }

  @override
  String get rejoin => 'Reentrar';

  @override
  String get remove => 'Remover';

  @override
  String get removeAllOtherDevices => 'Remover todos os outros dispositivos';

  @override
  String removedBy(Object username) {
    return 'Removido por $username';
  }

  @override
  String get removeDevice => 'Remover dispositivo';

  @override
  String get unbanFromChat => 'Perdoar nesta conversa';

  @override
  String get removeYourAvatar => 'Remover o teu avatar';

  @override
  String get renderRichContent => 'Exibir conteúdo de mensagem rico';

  @override
  String get replaceRoomWithNewerVersion =>
      'Substituir sala com versão mais recente';

  @override
  String get reply => 'Responder';

  @override
  String get reportMessage => 'Reportar mensagem';

  @override
  String get requestPermission => 'Pedir permissão';

  @override
  String get roomHasBeenUpgraded => 'A sala foi atualizada';

  @override
  String get roomVersion => 'Versão da sala';

  @override
  String get saturday => 'Sábado';

  @override
  String get saveFile => 'Guardar ficheiro';

  @override
  String get security => 'Segurança';

  @override
  String get recoveryKey => 'Chave de recuperação';

  @override
  String get recoveryKeyLost => 'Perdeu a chave de recuperação?';

  @override
  String seenByUser(Object username) {
    return 'Visto por $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visto por $username e mais $count pessoas',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Visto por $username e por $username2';
  }

  @override
  String get send => 'Enviar';

  @override
  String get sendAMessage => 'Enviar a mensagem';

  @override
  String get sendAsText => 'Enviar como texto';

  @override
  String get sendAudio => 'Enviar áudio';

  @override
  String get sendFile => 'Enviar ficheiro';

  @override
  String get sendImage => 'Enviar imagem';

  @override
  String get sendMessages => 'Enviar mensagens';

  @override
  String get sendOriginal => 'Enviar original';

  @override
  String get sendSticker => 'Enviar autocolante';

  @override
  String get sendVideo => 'Enviar vídeo';

  @override
  String sentAFile(Object username) {
    return '$username enviar um ficheiro';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username enviar um áudio';
  }

  @override
  String sentAPicture(Object username) {
    return '$username enviar uma imagem';
  }

  @override
  String sentASticker(Object username) {
    return '$username enviou um autocolante';
  }

  @override
  String sentAVideo(Object username) {
    return '$username enviou um vídeo';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName enviou informações de chamada';
  }

  @override
  String get separateChatTypes => 'Separar Conversas Diretas e Grupos';

  @override
  String get setAsCanonicalAlias => 'Fixar como cognome principal';

  @override
  String get setCustomEmotes => 'Implantar emojis personalizados';

  @override
  String get setGroupDescription => 'Fixar uma descrição do grupo';

  @override
  String get setInvitationLink => 'Enviar ligação de convite';

  @override
  String get setPermissionsLevel => 'Determinar níveis de permissão';

  @override
  String get setStatus => 'Alterar o estado';

  @override
  String get settings => 'Configurações';

  @override
  String get share => 'Partilhar';

  @override
  String sharedTheLocation(Object username) {
    return '$username partilhou a localização deles';
  }

  @override
  String get shareLocation => 'Partilhar localização';

  @override
  String get showDirectChatsInSpaces =>
      'Mostrar Conversas Diretas relacionadas nos Espaços';

  @override
  String get showPassword => 'Mostrar palavra-passe';

  @override
  String get signUp => 'Registar';

  @override
  String get singlesignon => 'Identidade Única';

  @override
  String get skip => 'Pular';

  @override
  String get sourceCode => 'Código fonte';

  @override
  String get spaceIsPublic => 'Espaço é público';

  @override
  String get spaceName => 'Nome do espaço';

  @override
  String startedACall(Object senderName) {
    return '$senderName iniciou uma chamada';
  }

  @override
  String get status => 'Estado';

  @override
  String get statusExampleMessage => 'Como está?';

  @override
  String get submit => 'Submeter';

  @override
  String get sunday => 'Domingo';

  @override
  String get synchronizingPleaseWait => 'A sincronizar… Por favor, aguarde.';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theyDontMatch => 'Não correspondem';

  @override
  String get theyMatch => 'Correspondem';

  @override
  String get thisRoomHasBeenArchived => 'Esta sala foi arquivada.';

  @override
  String get thursday => 'Quinta-feira';

  @override
  String get toggleFavorite => 'Alternar favorito';

  @override
  String get toggleMuted => 'Alternar Silenciado';

  @override
  String get toggleUnread => 'Marcar lido/não lido';

  @override
  String get tooManyRequestsWarning =>
      'Demasiadas requisições. Por favor, tente novamente mais tarde!';

  @override
  String get transferFromAnotherDevice => 'Transferir de outro dispositivo';

  @override
  String get tryToSendAgain => 'Tente enviar novamente';

  @override
  String get tuesday => 'Terça-feira';

  @override
  String get unavailable => 'Indisponível';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username revogou o banimento de $targetName';
  }

  @override
  String get unblockDevice => 'Desbloquear dispositivo';

  @override
  String get unknownDevice => 'Dispositivo desconhecido';

  @override
  String get unknownEncryptionAlgorithm =>
      'Algoritmo de criptografia desconhecido';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Evento desconhecido \'$type\'';
  }

  @override
  String get unmuteChat => 'Cancelar silenciamento';

  @override
  String get unpin => 'Desalfinetar';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount conversas não lidas',
      one: '1 conversa não lida',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username e mais $count pessoas estão digitando';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username e $username2 estão digitando';
  }

  @override
  String userIsTyping(Object username) {
    return '$username está a digitar';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username saiu da conversa';
  }

  @override
  String get username => 'Nome de utilizador';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username enviou um evento $type';
  }

  @override
  String get unverified => 'Não verificado';

  @override
  String get verified => 'Verificado';

  @override
  String get verify => 'Verificar';

  @override
  String get verifyStart => 'Iniciar verificação';

  @override
  String get verifySuccess => 'Verificação efetivada!';

  @override
  String get verifyTitle => 'A verificar a outra conta';

  @override
  String get videoCall => 'Vídeochamada';

  @override
  String get visibilityOfTheChatHistory =>
      'Visibilidade do histórico da conversa';

  @override
  String get visibleForAllParticipants => 'Visível aos participantes';

  @override
  String get visibleForEveryone => 'Visível a qualquer pessoa';

  @override
  String get voiceMessage => 'Mensagem de voz';

  @override
  String get waitingPartnerAcceptRequest =>
      'À espera que a outra pessoa aceite a solicitação…';

  @override
  String get waitingPartnerEmoji =>
      'À espera que a outra pessoa aceite os emoji…';

  @override
  String get waitingPartnerNumbers =>
      'À espera que a outra pessoa aceita os números…';

  @override
  String get wallpaper => 'Pano de fundo';

  @override
  String get warning => 'Atenção!';

  @override
  String get wednesday => 'Quarta-feira';

  @override
  String get weSentYouAnEmail => 'Enviamos-lhe um e-mail';

  @override
  String get whoCanPerformWhichAction => 'Quem pode desempenhar quais ações';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Quais pessoas são permitidas participar deste grupo';

  @override
  String get whyDoYouWantToReportThis => 'Por que quer denunciar isto?';

  @override
  String get wipeChatBackup =>
      'Limpar o backup da conversa para criar uma nova chave de recuperação?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Pode recuperar a sua palavra-passe com estes endereços.';

  @override
  String get writeAMessage => 'Escreva uma mensagem…';

  @override
  String get yes => 'Sim';

  @override
  String get you => 'Você';

  @override
  String get youAreInvitedToThisChat => 'Foi convidada(o) a esta conversa';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Ja não está a participar nesta conversa';

  @override
  String get youCannotInviteYourself => 'Não se pode autoconvidar';

  @override
  String get youHaveBeenBannedFromThisChat => 'Foi banido desta conversa';

  @override
  String get yourPublicKey => 'A sua chave pública';

  @override
  String get messageInfo => 'Informações da mensagem';

  @override
  String get time => 'Hora';

  @override
  String get messageType => 'Tipo da mensagem';

  @override
  String get sender => 'Remetente';

  @override
  String get openGallery => 'Abrir galeria';

  @override
  String get removeFromSpace => 'Remover do espaço';

  @override
  String get addToSpaceDescription =>
      'Selecione um espaço para adicionar esta conversa.';

  @override
  String get start => 'Começar';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Para destrancar as suas mensagens antigas, por favor, insira a sua chave de recuperação gerada numa sessão prévia. A sua chave de recuperação NÃO é a sua palavra-passe.';

  @override
  String get addToStory => 'Adicionar ao painel';

  @override
  String get publish => 'Publicar';

  @override
  String get whoCanSeeMyStories => 'Quem pode ver o meu painel?';

  @override
  String get unsubscribeStories => 'Desinscrever de painéis';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Este(a) utilizador(a) ainda não postou no seu painel';

  @override
  String get yourStory => 'O seu painel';

  @override
  String get replyHasBeenSent => 'Resposta enviada';

  @override
  String videoWithSize(Object size) {
    return 'Vídeo ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Painel de $date:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Por favor, note que pessoas podem ver e contactar umas às outras no seu painel.';

  @override
  String get whatIsGoingOn => 'O que está a acontecer?';

  @override
  String get addDescription => 'Adicionar descrição';

  @override
  String get storyPrivacyWarning =>
      'Por favor, note que pessoas podem ver e contactar umas às outras no seu painel. Ele ficará visível por apenas 24 horas, mas não há garantias de que será apagado por todos dispositivos e servidores.';

  @override
  String get iUnderstand => 'Compreendo';

  @override
  String get openChat => 'Abrir conversa';

  @override
  String get markAsRead => 'Marcar como lido';

  @override
  String get reportUser => 'Delatar utilizador';

  @override
  String get matrixWidgets => 'Ferramentas Matrix';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reagiu com $reaction';
  }

  @override
  String get pinChat => 'Alfinetar';

  @override
  String get confirmEventUnpin =>
      'Tem certeza que quer desafixar o evento permanentemente?';

  @override
  String get placeCall => 'Chamar';

  @override
  String get voiceCall => 'Chamada de voz';

  @override
  String get unsupportedAndroidVersion => 'Versão Android não suportada';

  @override
  String get unsupportedAndroidVersionLong =>
      'Esta funcionalidade requer uma versão mais nova do Android. Por favor, busque atualizações ou suporte ao Lineage OS.';

  @override
  String get videoCallsBetaWarning =>
      'Por favor, note que chamadas de vídeo estão atualmente em teste. Podem não funcionar como esperado ou sequer funcionar em algumas plataformas.';

  @override
  String get experimentalVideoCalls => 'Vídeo chamadas experimentais';

  @override
  String get emailOrUsername => 'Email ou nome de utilizador';

  @override
  String get indexedDbErrorTitle => 'Problemas no modo privado';

  @override
  String get indexedDbErrorLong =>
      'Infelizmente, o armazenamento de mensagens não é ativado por padrão no modo privado.\nPor favor, visite\n- about:config\n- atribua \"true\" a \"dom.indexedDB.privateBrowsing.enabled\"\nDe outro modo, não será possível executar o FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'Alternar para a conta $number';
  }

  @override
  String get nextAccount => 'Próxima conta';

  @override
  String get previousAccount => 'Conta anterior';

  @override
  String get editWidgets => 'Editar ferramentas';

  @override
  String get addWidget => 'Adicionar ferramenta';

  @override
  String get widgetVideo => 'Vídeo';

  @override
  String get widgetEtherpad => 'Anotação';

  @override
  String get widgetCustom => 'Personalizado';

  @override
  String get widgetName => 'Nome';

  @override
  String get widgetUrlError => 'Isto não é uma URL válida.';

  @override
  String get widgetNameError => 'Por favor, forneça um nome de exibição.';

  @override
  String get errorAddingWidget => 'Erro ao adicionar a ferramenta.';

  @override
  String get youRejectedTheInvitation => 'Rejeitou o convite';

  @override
  String get youJoinedTheChat => 'Entrou na conversa';

  @override
  String get youAcceptedTheInvitation => '👍 Aceitou o convite';

  @override
  String youBannedUser(Object user) {
    return 'Baniu $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Revogou o convite para $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 Foi convidado por $user';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 Convidou $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 Expulsou $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 Expulsou e baniu $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Revogou o banimento de $user';
  }

  @override
  String get noEmailWarning =>
      'Por favor, insira um e-mail válido. De outro modo, não conseguirá recuperar a sua palavra-passe. Caso prefira assim, toque novamente no botão para continuar.';

  @override
  String get users => 'Utilizadores';

  @override
  String get enableAutoBackups => 'Ativar backups automáticos';

  @override
  String get unlockOldMessages => 'Destrancar mensagens antigas';

  @override
  String get storeInSecureStorageDescription =>
      'Guardar a chave de recuperação no armazenamento seguro deste dispositivo.';

  @override
  String get saveKeyManuallyDescription =>
      'Grave esta chave manualmente via partilhamento do sistema ou área de transferência.';

  @override
  String get storeInAndroidKeystore => 'Guardar no mealheiro do Android';

  @override
  String get storeInAppleKeyChain => 'Guardar no chaveiro da Apple';

  @override
  String get storeSecurlyOnThisDevice =>
      'Guardar de modo seguro neste dispositivo';

  @override
  String countFiles(Object count) {
    return '$count ficheiros';
  }

  @override
  String get user => 'Utilizador';

  @override
  String get custom => 'Personalizado';

  @override
  String get foregroundServiceRunning =>
      'Esta notificação aparece quando um serviço está a funcionar.';

  @override
  String get screenSharingTitle => 'Partilhar ecrã';

  @override
  String get screenSharingDetail => 'Está a partilhar o seu ecrã no FluffyChat';

  @override
  String get callingPermissions => 'Permissões de chamada';

  @override
  String get callingAccount => 'Conta para chamadas';

  @override
  String get callingAccountDetails =>
      'Permitir que o FluffyChat use o app de chamadas nativo do Android.';

  @override
  String get appearOnTop => 'Aparecer no topo';

  @override
  String get appearOnTopDetails =>
      'Permitir que o app apareça no topo (desnecessário caso FluffyChat já esteja configurado como conta para chamadas)';

  @override
  String get otherCallingPermissions =>
      'Microfone, câmara e outras permissões do FluffyChat';

  @override
  String get whyIsThisMessageEncrypted =>
      'Por que esta mensagem está ilegível?';

  @override
  String get noKeyForThisMessage =>
      'Isto pode ocorrer caso a mensagem tenha sido enviada antes da entrada na sua conta com este dispositivo.\n\nTambém é possível que o remetente tenha bloqueado o seu dispositivo ou ocorreu algum problema com a conexão.\n\nConsegue ler as mensagens em outra sessão? Então, pode transferir as mensagens de lá! Vá em Configurações > Dispositivos e confira se os dispositivos verificaram um ao outro. Quando abrir a conversa da próxima vez e ambas as sessões estiverem abertas, as chaves serão transmitidas automaticamente.\n\nNão gostaria de perder as suas chaves quando sair ou trocar de dispositivos? Certifique-se que o backup de conversas esteja ativado nas configurações.';

  @override
  String get newGroup => 'Novo grupo';

  @override
  String get newSpace => 'Novo espaço';

  @override
  String get enterSpace => 'Entrar no espaço';

  @override
  String get enterRoom => 'Entrar na conversa';

  @override
  String get allSpaces => 'Todos espaços';

  @override
  String numChats(Object number) {
    return '$number conversas';
  }

  @override
  String get hideUnimportantStateEvents => 'Ocultar eventos desimportantes';

  @override
  String get doNotShowAgain => 'Não mostrar novamente';

  @override
  String get addMember => 'Adicionar membros';

  @override
  String get profile => 'Perfil';

  @override
  String get channels => 'Canais';

  @override
  String get chatMessage => 'Nova mensagem';

  @override
  String get active => 'Ativado';

  @override
  String get more => 'Mais';

  @override
  String get search => 'Procurar';

  @override
  String get allow => 'Permitir';

  @override
  String get documents => 'Documentos';

  @override
  String get location => 'Localização';

  @override
  String get contact => 'Contacto';

  @override
  String get file => 'Ficheiro';

  @override
  String get recent => 'Recente';

  @override
  String get externalContactTitle => 'Convidar novos utilizadores';

  @override
  String get clear => 'Limpar';

  @override
  String get keyboard => 'Teclado';

  @override
  String get continueProcess => 'Continuar';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get select => 'Escolher';

  @override
  String get add => 'Adicionar';

  @override
  String get addMembers => 'Adicionar membros';

  @override
  String get members => 'Membros';

  @override
  String get files => 'Ficheiros';

  @override
  String get links => 'Ligações';

  @override
  String get downloads => 'Descargas';
}
