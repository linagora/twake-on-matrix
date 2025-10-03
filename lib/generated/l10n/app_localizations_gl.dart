// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Galician (`gl`).
class L10nGl extends L10n {
  L10nGl([String locale = 'gl']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Os contrasinais non concordan!';

  @override
  String get pleaseEnterValidEmail => 'Escribe un enderezo de email válido.';

  @override
  String get repeatPassword => 'Repite o contrasinal';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Escribe polo menos $min caracteres.';
  }

  @override
  String get about => 'Acerca de';

  @override
  String get updateAvailable => 'Actualización dispoñible para FluffyChat';

  @override
  String get updateNow => 'Iniciar actualización en segundo plano';

  @override
  String get accept => 'Aceptar';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username aceptou o convite';
  }

  @override
  String get account => 'Conta';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username activou o cifrado extremo-a-extremo';
  }

  @override
  String get addEmail => 'Engadir email';

  @override
  String get confirmMatrixId =>
      'Confirma o teu ID Matrix para poder eliminar a conta.';

  @override
  String supposedMxid(Object mxid) {
    return 'Debería ser $mxid';
  }

  @override
  String get addGroupDescription => 'Engade a descrición do grupo';

  @override
  String get addToSpace => 'Engadir ao espazo';

  @override
  String get admin => 'Admin';

  @override
  String get alias => 'alias';

  @override
  String get all => 'Todos';

  @override
  String get allChats => 'Tódolos chats';

  @override
  String get commandHint_googly => 'Envía uns ollos desos grandes';

  @override
  String get commandHint_cuddle => 'Envía un agarimo';

  @override
  String get commandHint_hug => 'Envía un abrazo';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName enviouche uns ollos grandes';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName mándache un achuche';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName abrázate';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName respondeu á chamada';
  }

  @override
  String get anyoneCanJoin => 'Calquera pode unirse';

  @override
  String get appLock => 'Bloqueo da app';

  @override
  String get archive => 'Arquivo';

  @override
  String get archivedRoom => 'Sala arquivada';

  @override
  String get areGuestsAllowedToJoin => 'Permitir o acceso de convidadas';

  @override
  String get areYouSure => 'Tes a certeza?';

  @override
  String get areYouSureYouWantToLogout => 'Tes a certeza de querer saír?';

  @override
  String get askSSSSSign =>
      'Para poder asinar a outra persoa, escribe a túa frase de paso ou chave de recuperación.';

  @override
  String askVerificationRequest(Object username) {
    return 'Aceptar a solicitude de verificación de $username?';
  }

  @override
  String get autoplayImages => 'Reproducir automáticamente adhesivos e emotes';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'O servidor soporta as seguintes formas de conexión:\n$serverVersions\nPero esta app só soporta:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Enter para enviar';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'O servidor soporta as seguintes características:\n$serverVersions\nPero esta app só soporta $supportedVersions';
  }

  @override
  String get banFromChat => 'Vetar na conversa';

  @override
  String get banned => 'Vetada';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username vetou a $targetName';
  }

  @override
  String get blockDevice => 'Bloquear dispositivo';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get botMessages => 'Mensaxes de Bot';

  @override
  String get bubbleSize => 'Tamaño da burbulla';

  @override
  String get cancel => 'Cancelar';

  @override
  String cantOpenUri(Object uri) {
    return 'Non se pode abrir o URI $uri';
  }

  @override
  String get changeDeviceName => 'Cambiar nome do dispositivo';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username cambiou o avatar do chat';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username mudou a descrición da conversa a: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username mudou o nome da conversa a: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username mudou os permisos da conversa';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username cambiou o nome público a: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username mudou as regras de acceso para convidadas';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username mudou as regras de acceso para convidadas a: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username mudou a visibilidade do historial';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username mudou a visibilidade do historial a: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username mudou as regras de acceso';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username mudou as regras de acceso a: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username mudou o avatar';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username mudou os alias da sala';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username mudou a ligazón de convite';
  }

  @override
  String get changePassword => 'Mudar contrasinal';

  @override
  String get changeTheHomeserver => 'Mudar de servidor de inicio';

  @override
  String get changeTheme => 'Cambiar o estilo';

  @override
  String get changeTheNameOfTheGroup => 'Mudar o nome do grupo';

  @override
  String get changeWallpaper => 'Mudar fondo do chat';

  @override
  String get changeYourAvatar => 'Cambia o avatar';

  @override
  String get channelCorruptedDecryptError => 'O cifrado está corrompido';

  @override
  String get chat => 'Chat';

  @override
  String get yourUserId => 'O teu ID:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'Configurouse a copia de apoio do chat.';

  @override
  String get chatBackup => 'Copia de apoio do chat';

  @override
  String get chatBackupDescription =>
      'As mensaxes antigas están protexidas cunha chave de recuperación. Pon coidado e non a perdas.';

  @override
  String get chatDetails => 'Detalles do chat';

  @override
  String get chatHasBeenAddedToThisSpace => 'O chat foi engadido a este espazo';

  @override
  String get chats => 'Chats';

  @override
  String get chooseAStrongPassword => 'Escolle un contrasinal forte';

  @override
  String get chooseAUsername => 'Escolle un nome de usuaria';

  @override
  String get clearArchive => 'Baleirar arquivo';

  @override
  String get close => 'Pechar';

  @override
  String get commandHint_markasdm => 'Marcar como sala de mensaxe directa';

  @override
  String get commandHint_markasgroup => 'Marcar como grupo';

  @override
  String get commandHint_ban => 'Vetar a usuaria indicada desta sala';

  @override
  String get commandHint_clearcache => 'Baleirar caché';

  @override
  String get commandHint_create =>
      'Crear un grupo de conversa baleiro\nUsa --no-encryption para desactivar o cifrado';

  @override
  String get commandHint_discardsession => 'Descartar sesión';

  @override
  String get commandHint_dm =>
      'Iniciar un chat directo\nUsa --no-encryption para desactivar o cifrado';

  @override
  String get commandHint_html => 'Enviar texto con formato HTML';

  @override
  String get commandHint_invite => 'Convidar á usuaria a esta sala';

  @override
  String get commandHint_join => 'Unirte á sala indicada';

  @override
  String get commandHint_kick => 'Eliminar a usuaria indicada desta sala';

  @override
  String get commandHint_leave => 'Saír desta sala';

  @override
  String get commandHint_me => 'Conta algo sobre ti';

  @override
  String get commandHint_myroomavatar =>
      'Establece a túa imaxe para esta sala (por mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Establece o teu nome público para esta sala';

  @override
  String get commandHint_op =>
      'Establecer o nivel de responsabilidade da usuaria (por defecto: 50)';

  @override
  String get commandHint_plain => 'Enviar texto sen formato';

  @override
  String get commandHint_react => 'Enviar resposta como reacción';

  @override
  String get commandHint_send => 'Enviar texto';

  @override
  String get commandHint_unban => 'Retirar veto á usuaria para esta sala';

  @override
  String get commandInvalid => 'Comando non válido';

  @override
  String commandMissing(Object command) {
    return '$command non é un comando.';
  }

  @override
  String get compareEmojiMatch => 'Compara estes emojis';

  @override
  String get compareNumbersMatch => 'Compara estes números';

  @override
  String get configureChat => 'Configurar chat';

  @override
  String get confirm => 'Confirmar';

  @override
  String get connect => 'Acceder';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'O contacto foi convidado ao grupo';

  @override
  String get containsDisplayName => 'Contén nome público';

  @override
  String get containsUserName => 'Contén nome de usuaria';

  @override
  String get contentHasBeenReported =>
      'O contido foi denunciado á administración do servidor';

  @override
  String get copiedToClipboard => 'Copiado ao portapapeis';

  @override
  String get copy => 'Copiar';

  @override
  String get copyToClipboard => 'Copiar ao portapapeis';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Non se descifrou a mensaxe: $error';
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
  String get create => 'Crear';

  @override
  String createdTheChat(Object username) {
    return '💬 $username creou a conversa';
  }

  @override
  String get createNewGroup => 'Crear novo grupo';

  @override
  String get createNewSpace => 'Novo espazo';

  @override
  String get crossSigningEnabled => 'Sinatura-Cruzada activada';

  @override
  String get currentlyActive => 'Actualmente activo';

  @override
  String get darkTheme => 'Escuro';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
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
      'Esto desactivará a conta. Esto non ten volta atrás. Estás segura?';

  @override
  String get defaultPermissionLevel => 'Nivel de permisos por omisión';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAccount => 'Eliminar conta';

  @override
  String get deleteMessage => 'Eliminar mensaxe';

  @override
  String get deny => 'Denegar';

  @override
  String get device => 'Dispositivo';

  @override
  String get deviceId => 'ID do dispositivo';

  @override
  String get devices => 'Dispositivos';

  @override
  String get directChats => 'Chats Directos';

  @override
  String get discover => 'Descubrir';

  @override
  String get displaynameHasBeenChanged => 'O nome público mudou';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Editar';

  @override
  String get editBlockedServers => 'Editar servidores bloqueados';

  @override
  String get editChatPermissions => 'Editar permisos do chat';

  @override
  String get editDisplayname => 'Editar nome público';

  @override
  String get editRoomAliases => 'Editar alias da sala';

  @override
  String get editRoomAvatar => 'Editar avatar da sala';

  @override
  String get emoteExists => 'Xa existe ese emote!';

  @override
  String get emoteInvalid => 'Atallo do emote non é válido!';

  @override
  String get emotePacks => 'Paquetes de Emotes para a sala';

  @override
  String get emoteSettings => 'Axustes de Emote';

  @override
  String get emoteShortcode => 'Atallo de Emote';

  @override
  String get emoteWarnNeedToPick => 'Escribe un atallo e asocialle unha imaxe!';

  @override
  String get emptyChat => 'Chat baleiro';

  @override
  String get enableEmotesGlobally => 'Activar paquete emote globalmente';

  @override
  String get enableEncryption => 'Activar cifrado';

  @override
  String get enableEncryptionWarning =>
      'Non poderás desactivar o cifrado posteriormente, tes certeza?';

  @override
  String get encrypted => 'Cifrado';

  @override
  String get encryption => 'Cifrado';

  @override
  String get encryptionNotEnabled => 'O cifrado non está activado';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName rematou a chamada';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Escribe un enderezo de email';

  @override
  String get enterASpacepName => 'Escribe o nome para o espazo';

  @override
  String get homeserver => 'Servidor de inicio';

  @override
  String get enterYourHomeserver => 'Escribe o teu servidor de inicio';

  @override
  String errorObtainingLocation(Object error) {
    return 'Erro ao obter a localización: $error';
  }

  @override
  String get everythingReady => 'Todo preparado!';

  @override
  String get extremeOffensive => 'Extremadamente ofensivo';

  @override
  String get fileName => 'Nome do ficheiro';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Tamaño da letra';

  @override
  String get forward => 'Reenviar';

  @override
  String get friday => 'Venres';

  @override
  String get fromJoining => 'Desde que se una';

  @override
  String get fromTheInvitation => 'Desde o convite';

  @override
  String get goToTheNewRoom => 'Ir á nova sala';

  @override
  String get group => 'Grupo';

  @override
  String get groupDescription => 'Descrición do grupo';

  @override
  String get groupDescriptionHasBeenChanged =>
      'Cambiouse a descrición do grupo';

  @override
  String get groupIsPublic => 'O grupo é público';

  @override
  String get groups => 'Grupos';

  @override
  String groupWith(Object displayname) {
    return 'Grupo con $displayname';
  }

  @override
  String get guestsAreForbidden => 'Non se permiten convidadas';

  @override
  String get guestsCanJoin => 'Permítense convidadas';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username retirou o convite para $targetName';
  }

  @override
  String get help => 'Axuda';

  @override
  String get hideRedactedEvents => 'Agochar eventos editados';

  @override
  String get hideUnknownEvents => 'Agochar eventos descoñecidos';

  @override
  String get howOffensiveIsThisContent => 'É moi ofensivo este contido?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identidade';

  @override
  String get ignore => 'Ignorar';

  @override
  String get ignoredUsers => 'Usuarias ignoradas';

  @override
  String get ignoreListDescription =>
      'Podes ignorar usuarias molestas. Non recibirás ningunha mensaxe nin convites a salas da túa lista personal de usuarias ignoradas.';

  @override
  String get ignoreUsername => 'Ignorar nome de usuaria';

  @override
  String get iHaveClickedOnLink => 'Premín na ligazón';

  @override
  String get incorrectPassphraseOrKey =>
      'Frase de paso ou chave de recuperación incorrecta';

  @override
  String get inoffensive => 'Inofensivo';

  @override
  String get inviteContact => 'Convidar contacto';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Convidar contacto a $groupName';
  }

  @override
  String get invited => 'Convidado';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username convidou a $targetName';
  }

  @override
  String get invitedUsersOnly => 'Só usuarias convidadas';

  @override
  String get inviteForMe => 'Convite para min';

  @override
  String inviteText(Object username, Object link) {
    return '$username convidoute a FluffyChat.\n1. instala FluffyChat: https://fluffychat.im \n2. Rexístrate ou conéctate\n3. Abre a ligazón do convite: $link';
  }

  @override
  String get isTyping => 'está escribindo';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username uníuse ao chat';
  }

  @override
  String get joinRoom => 'Entrar na sala';

  @override
  String get keysCached => 'Chaves almacenadas';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username expulsou a $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username expulsou e vetou a $targetName';
  }

  @override
  String get kickFromChat => 'Expulsar da conversa';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Última actividade: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Hai moito que non aparece';

  @override
  String get leave => 'Saír';

  @override
  String get leftTheChat => 'Deixar a conversa';

  @override
  String get license => 'Licenza';

  @override
  String get lightTheme => 'Claro';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Cargar $count participantes máis';
  }

  @override
  String get dehydrate => 'Exportar sesión e eliminar dispositivo';

  @override
  String get dehydrateWarning =>
      'Esta acción non é reversible. Pon coidado en gardar o ficheiro de apoio.';

  @override
  String get dehydrateShare =>
      'Esta é a copia de apoio privada de FluffyChat. Pon coidado en non perdela e mantela segura.';

  @override
  String get dehydrateTor => 'Usuarias TOR: Exportar sesión';

  @override
  String get dehydrateTorLong =>
      'Para usuarias de TOR, é recomendable exportar a sesión antes de pechar a ventál.';

  @override
  String get hydrateTor => 'Usuarias TOR: Importar a sesión exportada';

  @override
  String get hydrateTorLong =>
      'Exportaches a túa sesión a última vez en TOR? Importaa rápidamente e continúa cos teus chats.';

  @override
  String get hydrate => 'Restablecer desde copia de apoio';

  @override
  String get loadingPleaseWait => 'Cargando... Agarda.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Cargar máis…';

  @override
  String get locationDisabledNotice =>
      'Os servizos de localización están desactivados. Actívaos para poder compartir a localización.';

  @override
  String get locationPermissionDeniedNotice =>
      'Permiso de localización denegado. Concede este permiso para poder compartir a localización.';

  @override
  String get login => 'Acceder';

  @override
  String logInTo(Object homeserver) {
    return 'Entrar en $homeserver';
  }

  @override
  String get loginWithOneClick => 'Conéctate cun click';

  @override
  String get logout => 'Saír';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Asegúrate de que o identificador é válido';

  @override
  String get memberChanges => 'Cambios de participantes';

  @override
  String get mention => 'Mención';

  @override
  String get messages => 'Mensaxes';

  @override
  String get messageWillBeRemovedWarning =>
      'Vai ser eliminada a mensaxe para todas as participantes';

  @override
  String get noSearchResult => 'Non hai resultados para a busca.';

  @override
  String get moderator => 'Moderadora';

  @override
  String get monday => 'Luns';

  @override
  String get muteChat => 'Acalar chat';

  @override
  String get needPantalaimonWarning =>
      'Ten en conta que polo de agora precisas Pantalaimon para o cifrado extremo-a-extremo.';

  @override
  String get newChat => 'Novo chat';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Nova solicitude de verificación!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Seguinte';

  @override
  String get no => 'Non';

  @override
  String get noConnectionToTheServer => 'Sen conexión co servidor';

  @override
  String get noEmotesFound => 'Non hai emotes. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Só podes activar o cifrado tan pronto como a sala non sexa públicamente accesible.';

  @override
  String get noGoogleServicesWarning =>
      'Semella que non tes os servizos de google no teu dispositivo. Ben feito! a túa privacidade agradécecho! Para recibir notificacións push en FluffyChat recomendamos usar https://microg.org/ ou https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 non é un servidor matrix, usar $server2 no seu lugar?';
  }

  @override
  String get shareYourInviteLink => 'Comparte a túa ligazón de convite';

  @override
  String get typeInInviteLinkManually =>
      'Escribe manualmente a ligazón do convite...';

  @override
  String get scanQrCode => 'Escanear código QR';

  @override
  String get none => 'Ningún';

  @override
  String get noPasswordRecoveryDescription =>
      'Aínda non engaiches ningún xeito de recuperar o contrasinal.';

  @override
  String get noPermission => 'Sen permiso';

  @override
  String get noRoomsFound => 'Non se atoparon salas…';

  @override
  String get notifications => 'Notificacións';

  @override
  String numUsersTyping(Object count) {
    return '$count usuarias están escribindo';
  }

  @override
  String get obtainingLocation => 'Obtendo a localización…';

  @override
  String get offensive => 'Ofensivo';

  @override
  String get offline => 'Desconectada';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'Ok';

  @override
  String get online => 'En liña';

  @override
  String get onlineKeyBackupEnabled =>
      'Copia de Apoio en liña das Chaves activada';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Vaites! Desgraciadamente algo fallou ao configurar as notificacións push.';

  @override
  String get oopsSomethingWentWrong => 'Ooooi, algo fallou…';

  @override
  String get openAppToReadMessages => 'Abrir a app e ler mensaxes';

  @override
  String get openCamera => 'Abrir cámara';

  @override
  String get openVideoCamera => 'Abrir a cámara para un vídeo';

  @override
  String get oneClientLoggedOut => 'Un dos teus clientes foi desconectado';

  @override
  String get addAccount => 'Engadir conta';

  @override
  String get editBundlesForAccount => 'Editar os feixes desta conta';

  @override
  String get addToBundle => 'Engadir ao feixe';

  @override
  String get removeFromBundle => 'Eliminar deste feixe';

  @override
  String get bundleName => 'Nome do feixe';

  @override
  String get enableMultiAccounts =>
      '(BETA) Activar varias contas neste dispositivo';

  @override
  String get openInMaps => 'Abrir en mapas';

  @override
  String get link => 'Ligazón';

  @override
  String get serverRequiresEmail =>
      'O servidor precisa validar o teu enderezo de email para rexistrarte.';

  @override
  String get optionalGroupName => '(Optativo) Nome do grupo';

  @override
  String get or => 'Ou';

  @override
  String get participant => 'Participante';

  @override
  String get passphraseOrKey => 'frase de paso ou chave de recuperación';

  @override
  String get password => 'Contrasinal';

  @override
  String get passwordForgotten => 'Contrasinal esquecido';

  @override
  String get passwordHasBeenChanged => 'Cambiouse o contrasinal';

  @override
  String get passwordRecovery => 'Recuperación do contrasinal';

  @override
  String get people => 'Persoas';

  @override
  String get pickImage => 'Elixe unha imaxe';

  @override
  String get pin => 'Fixar';

  @override
  String play(Object fileName) {
    return 'Reproducir $fileName';
  }

  @override
  String get pleaseChoose => 'Por favor elixe';

  @override
  String get pleaseChooseAPasscode => 'Escolle un código de acceso';

  @override
  String get pleaseChooseAUsername => 'Escolle un nome de usuaria';

  @override
  String get pleaseClickOnLink =>
      'Preme na ligazón do email e segue as instrucións.';

  @override
  String get pleaseEnter4Digits =>
      'Escribe 4 díxitos ou deíxao baleiro para non activar o bloqueo.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Escribe un ID Matrix.';

  @override
  String get pleaseEnterRecoveryKey => 'Escribe a túa chave de recuperación:';

  @override
  String get pleaseEnterYourPassword => 'Escribe o teu contrasinal';

  @override
  String get pleaseEnterYourPin => 'Escribe o teu pin';

  @override
  String get pleaseEnterYourUsername => 'Escribe o teu nome de usuaria';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Segue as instruccións do sitio web e toca en seguinte.';

  @override
  String get privacy => 'Privacidade';

  @override
  String get publicRooms => 'Salas públicas';

  @override
  String get pushRules => 'Regras de envío';

  @override
  String get reason => 'Razón';

  @override
  String get recording => 'Gravando';

  @override
  String redactedAnEvent(Object username) {
    return '$username editou un evento';
  }

  @override
  String get redactMessage => 'Eliminar mensaxe';

  @override
  String get register => 'Crear conta';

  @override
  String get reject => 'Rexeitar';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username rexeitou o convite';
  }

  @override
  String get rejoin => 'Volta a unirte';

  @override
  String get remove => 'Eliminar';

  @override
  String get removeAllOtherDevices => 'Quitar todos os outros dispositivos';

  @override
  String removedBy(Object username) {
    return 'Eliminado por $username';
  }

  @override
  String get removeDevice => 'Quitar dispositivo';

  @override
  String get unbanFromChat => 'Retirar veto no chat';

  @override
  String get removeYourAvatar => 'Elimina o avatar';

  @override
  String get renderRichContent => 'Mostrar contido enriquecido da mensaxe';

  @override
  String get replaceRoomWithNewerVersion => 'Substituír sala pola nova versión';

  @override
  String get reply => 'Responder';

  @override
  String get reportMessage => 'Denunciar mensaxe';

  @override
  String get requestPermission => 'Solicitar permiso';

  @override
  String get roomHasBeenUpgraded => 'A sala foi actualizada';

  @override
  String get roomVersion => 'Versión da sala';

  @override
  String get saturday => 'Sábado';

  @override
  String get saveFile => 'Gardar ficheiro';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Seguridade';

  @override
  String get recoveryKey => 'Chave de recuperación';

  @override
  String get recoveryKeyLost => 'Perdeches a chave de recuperación?';

  @override
  String seenByUser(Object username) {
    return 'Visto por $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visto por $username e $count outras',
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
  String get sendAMessage => 'Enviar unha mensaxe';

  @override
  String get sendAsText => 'Enviar como texto';

  @override
  String get sendAudio => 'Enviar audio';

  @override
  String get sendFile => 'Enviar ficheiro';

  @override
  String get sendImage => 'Enviar imaxe';

  @override
  String get sendMessages => 'Enviar mensaxes';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Enviar orixinal';

  @override
  String get sendSticker => 'Enviar adhesivo';

  @override
  String get sendVideo => 'Enviar vídeo';

  @override
  String sentAFile(Object username) {
    return '📁 $username enviou un ficheiro';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username enviou un audio';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username enviou unha imaxe';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username enviou un adhesivo';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username enviou un vídeo';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName enviou información da chamada';
  }

  @override
  String get separateChatTypes => 'Separar Conversas directas e Grupos';

  @override
  String get setAsCanonicalAlias => 'Establecer como alias principal';

  @override
  String get setCustomEmotes => 'Establecer emotes personalizados';

  @override
  String get setGroupDescription => 'Establecer descrición do grupo';

  @override
  String get setInvitationLink => 'Establecer ligazón do convite';

  @override
  String get setPermissionsLevel => 'Establecer nivel de permisos';

  @override
  String get setStatus => 'Establecer estado';

  @override
  String get settings => 'Axustes';

  @override
  String get share => 'Compartir';

  @override
  String sharedTheLocation(Object username) {
    return '$username compartiu a súa localización';
  }

  @override
  String get shareLocation => 'Compartir localización';

  @override
  String get showDirectChatsInSpaces => 'Mostrar os Chats Directos nos Espazos';

  @override
  String get showPassword => 'Amosar contrasinal';

  @override
  String get signUp => 'Rexistro';

  @override
  String get singlesignon => 'Conexión Unificada SSO';

  @override
  String get skip => 'Saltar';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Código fonte';

  @override
  String get spaceIsPublic => 'O Espazo é público';

  @override
  String get spaceName => 'Nome do Espazo';

  @override
  String startedACall(Object senderName) {
    return '$senderName iniciou unha chamada';
  }

  @override
  String get startFirstChat => 'Abre a túa primeira conversa';

  @override
  String get status => 'Estado';

  @override
  String get statusExampleMessage => '¿Que tal estás hoxe?';

  @override
  String get submit => 'Enviar';

  @override
  String get sunday => 'Domingo';

  @override
  String get synchronizingPleaseWait => 'Sincronizando... Agarda.';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theyDontMatch => 'Non concordan';

  @override
  String get theyMatch => 'Concordan';

  @override
  String get thisRoomHasBeenArchived => 'A sala foi arquivada.';

  @override
  String get thursday => 'Xoves';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Marcar Favorito';

  @override
  String get toggleMuted => 'Cambia Noificacións';

  @override
  String get toggleUnread => 'Marcar como Lido/Non lido';

  @override
  String get tooManyRequestsWarning =>
      'Demasiadas solicitudes. Inténtao máis tarde!';

  @override
  String get transferFromAnotherDevice => 'Transferir desde outro dispositivo';

  @override
  String get tryToSendAgain => 'Inténtao outra vez';

  @override
  String get tuesday => 'Martes';

  @override
  String get unavailable => 'Non dispoñible';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username retirou o veto a $targetName';
  }

  @override
  String get unblockDevice => 'Desbloquear dispositivo';

  @override
  String get unknownDevice => 'Dispositivo descoñecido';

  @override
  String get unknownEncryptionAlgorithm => 'Algoritmo de cifrado descoñecido';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Evento descoñecido \'$type\'';
  }

  @override
  String get unmuteChat => 'Reactivar notificacións';

  @override
  String get unpin => 'Desafixar';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount chats non lidos',
      one: '1 chat non lido',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username e $count máis están escribindo';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username e $username2 están escribindo';
  }

  @override
  String userIsTyping(Object username) {
    return '$username está escribindo';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username deixou a conversa';
  }

  @override
  String get username => 'Nome de usuaria';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username enviou un evento $type';
  }

  @override
  String get unverified => 'Sen verificar';

  @override
  String get verified => 'Verificado';

  @override
  String get verify => 'Verificar';

  @override
  String get verifyStart => 'Comezar verificación';

  @override
  String get verifySuccess => 'Verificaches correctamente!';

  @override
  String get verifyTitle => 'Verificando a outra conta';

  @override
  String get videoCall => 'Chamada de vídeo';

  @override
  String get visibilityOfTheChatHistory =>
      'Visibilidade do historial da conversa';

  @override
  String get visibleForAllParticipants => 'Visible para todas as participantes';

  @override
  String get visibleForEveryone => 'Visible para todas';

  @override
  String get voiceMessage => 'Mensaxe de voz';

  @override
  String get waitingPartnerAcceptRequest =>
      'Agardando a que a outra parte acepte a solicitude…';

  @override
  String get waitingPartnerEmoji =>
      'Agardando a que a outra parte acepte as emoticonas…';

  @override
  String get waitingPartnerNumbers =>
      'Agardando a que a outra parte acepte os números…';

  @override
  String get wallpaper => 'Fondo da conversa';

  @override
  String get warning => 'Aviso!';

  @override
  String get wednesday => 'Mércores';

  @override
  String get weSentYouAnEmail => 'Enviamosche un email';

  @override
  String get whoCanPerformWhichAction =>
      'Quen pode realizar determinada acción';

  @override
  String get whoIsAllowedToJoinThisGroup => 'Quen se pode unir a este grupo';

  @override
  String get whyDoYouWantToReportThis => 'Por que queres denunciar esto?';

  @override
  String get wipeChatBackup =>
      'Eliminar a copia de apoio do chat e crear unha nova chave de recuperación?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Con estos enderezos podes recuperar o contrasinal.';

  @override
  String get writeAMessage => 'Escribe unha mensaxe…';

  @override
  String get yes => 'Si';

  @override
  String get you => 'Ti';

  @override
  String get youAreInvitedToThisChat => 'Estás convidada a este chat';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Xa non participas desta conversa';

  @override
  String get youCannotInviteYourself => 'Non podes autoconvidarte';

  @override
  String get youHaveBeenBannedFromThisChat => 'Foches vetada nesta conversa';

  @override
  String get yourPublicKey => 'A túa chave pública';

  @override
  String get messageInfo => 'Info da mensaxe';

  @override
  String get time => 'Hora';

  @override
  String get messageType => 'Tipo de mensaxe';

  @override
  String get sender => 'Remitente';

  @override
  String get openGallery => 'Galería pública';

  @override
  String get removeFromSpace => 'Retirar do espazo';

  @override
  String get addToSpaceDescription =>
      'Elixe un espazo ao que engadir este chat.';

  @override
  String get start => 'Comezar';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Para desbloquear as mensaxes antigas, escribe a chave de recuperación creada nunha sesión existente. A chave de recuperación NON é o teu contrasinal.';

  @override
  String get addToStory => 'Engadir a historia';

  @override
  String get publish => 'Publicar';

  @override
  String get whoCanSeeMyStories => 'Quen pode ver as miñas historias?';

  @override
  String get unsubscribeStories => 'Retirar subscrición das historias';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'A usuaria non publicou aínda ningunha historia';

  @override
  String get yourStory => 'A túa Historia';

  @override
  String get replyHasBeenSent => 'Enviouse a resposta';

  @override
  String videoWithSize(Object size) {
    return 'Vídeo ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Historia do $date:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Ten en conta que as usuarias poden verse e contactar unhas coas outras na túa historia.';

  @override
  String get whatIsGoingOn => 'Que acontece?';

  @override
  String get addDescription => 'Engadir descrición';

  @override
  String get storyPrivacyWarning =>
      'Ten en conta que outras persoas poden verse en contactar entre elas na túa historia. As historias son visibles durante 24 horas pero non hai garantía de que sexan eliminadas en tódolos dispositivos e servidores.';

  @override
  String get iUnderstand => 'Comprendo';

  @override
  String get openChat => 'Abrir Chat';

  @override
  String get markAsRead => 'Marcar como lido';

  @override
  String get reportUser => 'Denunciar usuaria';

  @override
  String get dismiss => 'Desbotar';

  @override
  String get matrixWidgets => 'Widgets de Matrix';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reaccionou con $reaction';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin => 'Tes a certeza de querer desafixar o evento?';

  @override
  String get emojis => 'Emojis';

  @override
  String get placeCall => 'Chamar';

  @override
  String get voiceCall => 'Chamada de voz';

  @override
  String get unsupportedAndroidVersion => 'Version de Android non soportada';

  @override
  String get unsupportedAndroidVersionLong =>
      'Esta característica require unha vesión máis recente de Android. Mira se hai actualizacións ou soporte de LineageOS.';

  @override
  String get videoCallsBetaWarning =>
      'Ten en conta que as chamadas de vídeo están en fase beta. Poderían non funcionar correctamente ou non funcionar nalgunhas plataformas.';

  @override
  String get experimentalVideoCalls => 'Chamadas de vídeo en probas';

  @override
  String get emailOrUsername => 'Email ou nome de usuaria';

  @override
  String get indexedDbErrorTitle => 'Problemas no modo privado';

  @override
  String get indexedDbErrorLong =>
      'A almacenaxe de mensaxes non está activada por defecto no modo privado.\nMira en\n- about:config\n- establece dom.indexedDB.privateBrowsing.enabled como true\nSe non, non é posible executar FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'Cambiar á conta $number';
  }

  @override
  String get nextAccount => 'Conta seguinte';

  @override
  String get previousAccount => 'Conta anterior';

  @override
  String get editWidgets => 'Editar widgets';

  @override
  String get addWidget => 'Engadir widget';

  @override
  String get widgetVideo => 'Vídeo';

  @override
  String get widgetEtherpad => 'Nota de texto';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Personalizado';

  @override
  String get widgetName => 'Nome';

  @override
  String get widgetUrlError => 'Non é un URL válido.';

  @override
  String get widgetNameError => 'Escribe un nome público.';

  @override
  String get errorAddingWidget => 'Erro ao engadir o widget.';

  @override
  String get youRejectedTheInvitation => 'Rexeitaches o convite';

  @override
  String get youJoinedTheChat => 'Unícheste á conversa';

  @override
  String get youAcceptedTheInvitation => '👍 Aceptaches o convite';

  @override
  String youBannedUser(Object user) {
    return 'Vetaches a $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Retiraches o convite para $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 $user convidoute';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 Convidaches a $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 Expulsaches a $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 Expulsaches e vetaches a $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Retiraches o veto a $user';
  }

  @override
  String get noEmailWarning =>
      'Escribe un enderezo de email válido. Doutro xeito non poderás restablecer o contrasinal. Se non queres, toca outra vez no botón para continuar.';

  @override
  String get stories => 'Historias';

  @override
  String get users => 'Usuarias';

  @override
  String get enableAutoBackups => 'Activar copia automática';

  @override
  String get unlockOldMessages => 'Desbloquear mensaxes antigas';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription =>
      'Gardar a chave de recuperación na almacenaxe segura deste dispositivo.';

  @override
  String get saveKeyManuallyDescription =>
      'Garda esta chave manualmente usando o sistema para compartir do dispositivo ou portapapeis.';

  @override
  String get storeInAndroidKeystore => 'Gardar en Android KeyStore';

  @override
  String get storeInAppleKeyChain => 'Gardar en Apple KeyChain';

  @override
  String get storeSecurlyOnThisDevice =>
      'Gardar de xeito seguro no dispositivo';

  @override
  String countFiles(Object count) {
    return '$count ficheiros';
  }

  @override
  String get user => 'Usuaria';

  @override
  String get custom => 'Personal';

  @override
  String get foregroundServiceRunning =>
      'Esta notificación aparece cando se está a executar o servizo en segundo plano.';

  @override
  String get screenSharingTitle => 'compartición da pantalla';

  @override
  String get screenSharingDetail =>
      'Estás compartindo a túa pantalla en FluffyChat';

  @override
  String get callingPermissions => 'Permisos de chamada';

  @override
  String get callingAccount => 'Conta que chama';

  @override
  String get callingAccountDetails =>
      'Permite a FluffyChat usar a app marcador nativa de android.';

  @override
  String get appearOnTop => 'Aparecer arriba';

  @override
  String get appearOnTopDetails =>
      'Permítelle á app aparecer por enrriba (non é preciso se xa configuraches FluffyChat como unha conta para chamadas)';

  @override
  String get otherCallingPermissions =>
      'Micrófono, cámara e outros permisos para FluffyChat';

  @override
  String get whyIsThisMessageEncrypted => 'Por que non podo ler esta mensaxe?';

  @override
  String get noKeyForThisMessage =>
      'Pode ser que a mensaxe fose enviada antes de que ti accedeses á túa conta neste dispositivo.\n\nTamén é posible que a remitente non validase o teu dispositivo ou tamén que algo fallase na conexión a internet.\n\nPodes ler a mensaxe noutro dispositivo? Entón podes transferila desde el! Vai a Axustes > Dispositivos e comproba que tes tódolos dispositivos verificados. Entón cando abras a sala a próxima vez a sincronización realizarase e as chaves transmitiranse automáticamente.\n\nNon desexas perder as chaves cando pechas sesión ou cambias de dispositivo? Comproba nos axustes que activaches a copia de apoio das conversas.';

  @override
  String get newGroup => 'Novo grupo';

  @override
  String get newSpace => 'Novo espazo';

  @override
  String get enterSpace => 'Entrar no espazo';

  @override
  String get enterRoom => 'Entrar na sala';

  @override
  String get allSpaces => 'Tódolos espazos';

  @override
  String numChats(Object number) {
    return '$number chats';
  }

  @override
  String get hideUnimportantStateEvents =>
      'Agochar os eventos de menor relevancia';

  @override
  String get doNotShowAgain => 'Non mostrar outra vez';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return 'Conversa baleira (era $oldDisplayName)';
  }

  @override
  String get newSpaceDescription =>
      'Os Espazos permítenche fortalecer as túas conversas e construir comunidades públicas ou privadas.';

  @override
  String get encryptThisChat => 'Cifrar esta conversa';

  @override
  String get endToEndEncryption => 'Cifrado de extremo a extremo';

  @override
  String get disableEncryptionWarning =>
      'Por razóns de seguridade non podes desactivar o cifrado dunha conversa onde foi activado previamente.';

  @override
  String get sorryThatsNotPossible => 'Lamentámolo... iso non é posible';

  @override
  String get deviceKeys => 'Chaves do dispositivo:';

  @override
  String get letsStart => 'Imos alá';

  @override
  String get enterInviteLinkOrMatrixId =>
      'Escribe a ligazón de convite ou ID Matrix...';

  @override
  String get reopenChat => 'Reabrir conversa';

  @override
  String get noBackupWarning =>
      'Aviso! Se non activas a copia de apoio do chat, perderás o acceso ás túas mensaxes cifradas. É totalmente recomendable activar a copia de apoio do chat antes de pechar a sesión.';

  @override
  String get noOtherDevicesFound => 'Non se atopan outros dispositivos';

  @override
  String get fileIsTooBigForServer =>
      'O servidor informa de que o ficheiro é demasiado grande para envialo.';

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
  String get addMember => 'Add members';

  @override
  String get profile => 'Profile';

  @override
  String get channels => 'Channels';

  @override
  String get chatMessage => 'New message';

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
  String get active => 'Activated';

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
  String get more => 'More';

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
  String get search => 'Buscar';

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
  String get allow => 'Allow';

  @override
  String get explainStoragePermission =>
      'Twake need access to your storage to preview file';

  @override
  String get explainGoToStorageSetting =>
      'Twake need access to your storage to preview file, go to settings to allow this permission';

  @override
  String get gallery => 'Gallery';

  @override
  String get documents => 'Documents';

  @override
  String get location => 'Location';

  @override
  String get contact => 'Contact';

  @override
  String get file => 'File';

  @override
  String get recent => 'Recent';

  @override
  String get chatsAndContacts => 'Chats and Contacts';

  @override
  String get externalContactTitle => 'Invite new users';

  @override
  String get externalContactMessage =>
      'Some of the users you want to add are not in your contacts. Do you want to invite them?';

  @override
  String get clear => 'Clear';

  @override
  String get keyboard => 'Keyboard';

  @override
  String get changeChatAvatar => 'Change the Chat avatar';

  @override
  String get roomAvatarMaxFileSize => 'The avatar size is too large';

  @override
  String roomAvatarMaxFileSizeLong(Object max) {
    return 'The avatar size must be less than $max';
  }

  @override
  String get continueProcess => 'Continue';

  @override
  String get youAreUploadingPhotosDoYouWantToCancelOrContinue =>
      'Image upload error! Do you still want to continue creating group chat?';

  @override
  String hasCreatedAGroupChat(Object groupName) {
    return 'created a group chat “$groupName”';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get acceptInvite => 'Yes please, join';

  @override
  String get askToInvite => ' wants you to join this chat. What do you say?';

  @override
  String get select => 'Select';

  @override
  String get copyMessageText => 'Copy';

  @override
  String get pinThisChat => 'Pin this chat';

  @override
  String get unpinThisChat => 'Unpin this chat';

  @override
  String get add => 'Add';

  @override
  String get addMembers => 'Add members';

  @override
  String get chatInfo => 'Chat info';

  @override
  String get mute => 'Mute';

  @override
  String membersInfo(Object count) {
    return 'Members ($count)';
  }

  @override
  String get members => 'Members';

  @override
  String get media => 'Media';

  @override
  String get files => 'Files';

  @override
  String get links => 'Links';

  @override
  String get downloads => 'Downloads';

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
