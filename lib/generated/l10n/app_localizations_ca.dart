// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class L10nCa extends L10n {
  L10nCa([String locale = 'ca']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Les contrasenyes no coincideixen!';

  @override
  String get pleaseEnterValidEmail =>
      'Introduïu una adreça electrònica vàlida.';

  @override
  String get repeatPassword => 'Repetiu la contrasenya';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Seleccioneu almenys $min caràcters.';
  }

  @override
  String get about => 'Quant a';

  @override
  String get updateAvailable => 'Twake Chat update available';

  @override
  String get updateNow => 'Start update in background';

  @override
  String get accept => 'Accepta';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username ha acceptat la invitació';
  }

  @override
  String get account => 'Compte';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username ha activat el xifratge d’extrem a extrem';
  }

  @override
  String get addEmail => 'Afegeix una adreça electrònica';

  @override
  String get confirmMatrixId =>
      'Please confirm your Matrix ID in order to delete your account.';

  @override
  String supposedMxid(Object mxid) {
    return 'This should be $mxid';
  }

  @override
  String get addGroupDescription => 'Afegeix descripció de grup';

  @override
  String get addToSpace => 'Afegeix a un espai';

  @override
  String get admin => 'Administració';

  @override
  String get alias => 'àlies';

  @override
  String get all => 'Tot';

  @override
  String get allChats => 'Tots els xats';

  @override
  String get commandHint_googly => 'Send some googly eyes';

  @override
  String get commandHint_cuddle => 'Send a cuddle';

  @override
  String get commandHint_hug => 'Send a hug';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName sends you googly eyes';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName cuddles you';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName hugs you';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName ha respost a la trucada';
  }

  @override
  String get anyoneCanJoin => 'Qualsevol pot unir-se';

  @override
  String get appLock => 'Blocatge de l’aplicació';

  @override
  String get archive => 'Arxiu';

  @override
  String get archivedRoom => 'Sala arxivada';

  @override
  String get areGuestsAllowedToJoin => 'Accés dels usuaris convidats';

  @override
  String get areYouSure => 'N’esteu segur?';

  @override
  String get areYouSureYouWantToLogout =>
      'Segur que voleu finalitzar la sessió?';

  @override
  String get askSSSSSign =>
      'Per a poder donar accés a l’altra persona, introduïu la frase de seguretat o clau de recuperació.';

  @override
  String askVerificationRequest(Object username) {
    return 'Voleu acceptar aquesta sol·licitud de verificació de: $username?';
  }

  @override
  String get autoplayImages =>
      'Reprodueix automàticament enganxines i emoticones animades';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'El servidor admet els inicis de sessió:\n$serverVersions\nPerò l\'aplicació només admet:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Envia en prémer Retorn';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'The homeserver supports the Spec versions:\n$serverVersions\nBut this app supports only $supportedVersions';
  }

  @override
  String get banFromChat => 'Veta del xat';

  @override
  String get banned => 'Vetat';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username ha vetat a $targetName';
  }

  @override
  String get blockDevice => 'Bloca el dispositiu';

  @override
  String get blocked => 'Blocat';

  @override
  String get botMessages => 'Missatges del bot';

  @override
  String get bubbleSize => 'Mida de la bombolla';

  @override
  String get cancel => 'Cancel·la';

  @override
  String cantOpenUri(Object uri) {
    return 'No es pot obrir l’URI $uri';
  }

  @override
  String get changeDeviceName => 'Canvia el nom del dispositiu';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username ha canviat la imatge del xat';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username ha canviat la descripció del xat a: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username ha canviat el nom del xat a: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username ha canviat els permisos del xat';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username ha canviat el seu àlies a: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username ha canviat les normes d’accés dels convidats';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username ha canviat les normes d’accés dels convidats a: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username ha canviat la visibilitat de l’historial';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username ha canviat la visibilitat de l’historial a: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username ha canviat les normes d’unió';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username ha canviat les normes d’unió a: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username ha canviat la seva imatge de perfil';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username ha canviat l’àlies de la sala';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username ha canviat l’enllaç per a convidar';
  }

  @override
  String get changePassword => 'Canvia la contrasenya';

  @override
  String get changeTheHomeserver => 'Canvia el servidor';

  @override
  String get changeTheme => 'Canvia l’estil';

  @override
  String get changeTheNameOfTheGroup => 'Canvia el nom del grup';

  @override
  String get changeWallpaper => 'Canvia el fons';

  @override
  String get changeYourAvatar => 'Canvia l’avatar';

  @override
  String get channelCorruptedDecryptError => 'El xifratge s’ha corromput';

  @override
  String get chat => 'Xat';

  @override
  String get yourUserId => 'El vostre id. d’usuari:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'S’ha configurat la còpia de seguretat del xat.';

  @override
  String get chatBackup => 'Còpia de seguretat del xat';

  @override
  String get chatBackupDescription =>
      'La còpia de seguretat dels xats és protegida amb una clau. Assegureu-vos de no perdre-la.';

  @override
  String get chatDetails => 'Detalls del xat';

  @override
  String get chatHasBeenAddedToThisSpace => 'El xat s’ha afegit a aquest espai';

  @override
  String get chats => 'Xats';

  @override
  String get chooseAStrongPassword => 'Trieu una contrasenya forta';

  @override
  String get chooseAUsername => 'Trieu un nom d’usuari';

  @override
  String get clearArchive => 'Neteja l’arxiu';

  @override
  String get close => 'Tanca';

  @override
  String get commandHint_markasdm => 'Mark as direct chat';

  @override
  String get commandHint_markasgroup => 'Mark as chat';

  @override
  String get commandHint_ban => 'Prohibeix l\'usuari indicat d\'aquesta sala';

  @override
  String get commandHint_clearcache => 'Neteja la memòria cau';

  @override
  String get commandHint_create =>
      'Crea un xat de grup buit\nUsa --no-encryption per desactivar l\'encriptatge';

  @override
  String get commandHint_discardsession => 'Descarta la sessió';

  @override
  String get commandHint_dm =>
      'Inicia un xat directe\nUsa --no-encryption per desactivar l\'encriptatge';

  @override
  String get commandHint_html => 'Envia text en format HTML';

  @override
  String get commandHint_invite => 'Convida l\'usuari indicat a aquesta sala';

  @override
  String get commandHint_join => 'Uneix-te a la sala';

  @override
  String get commandHint_kick => 'Elimina l\'usuari indicat d\'aquesta sala';

  @override
  String get commandHint_leave => 'Abandona aquesta sala';

  @override
  String get commandHint_me => 'Descriviu-vos';

  @override
  String get commandHint_myroomavatar =>
      'Establiu la imatge per a aquesta sala (per mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Estableix el teu àlies per a aquesta sala';

  @override
  String get commandHint_op =>
      'Estableix el nivell d\'autoritat de l\'usuari (per defecte: 50)';

  @override
  String get commandHint_plain => 'Envia text sense format';

  @override
  String get commandHint_react => 'Envia una resposta com a reacció';

  @override
  String get commandHint_send => 'Envia text';

  @override
  String get commandHint_unban => 'Unban the given user from this chat';

  @override
  String get commandInvalid => 'L’ordre no és vàlida';

  @override
  String commandMissing(Object command) {
    return '$command no és una ordre.';
  }

  @override
  String get compareEmojiMatch =>
      'Compareu i assegureu-vos que els emojis següents coincideixen amb els de l’altre dispositiu:';

  @override
  String get compareNumbersMatch =>
      'Compareu i assegureu-vos que els nombres següents coincideixen amb els de l’altre dispositiu:';

  @override
  String get configureChat => 'Configura el xat';

  @override
  String get confirm => 'Confirma';

  @override
  String get connect => 'Connecta';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'El contacte ha estat convidat al grup';

  @override
  String get containsDisplayName => 'Conté l\'àlies';

  @override
  String get containsUserName => 'Conté el nom d’usuari';

  @override
  String get contentHasBeenReported =>
      'El contingut s’ha denunciat als administradors del servidor';

  @override
  String get copiedToClipboard => 'S’ha copiat al porta-retalls';

  @override
  String get copy => 'Copia';

  @override
  String get copyToClipboard => 'Copia al porta-retalls';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'No s\'ha pogut desxifrar el missatge: $error';
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
  String get create => 'Crea';

  @override
  String createdTheChat(Object username) {
    return '$username ha creat el xat';
  }

  @override
  String get createNewGroup => 'Crea un grup nou';

  @override
  String get createNewSpace => 'Espai nou';

  @override
  String get crossSigningEnabled => 'Signatura creuada activada';

  @override
  String get currentlyActive => 'Actiu actualment';

  @override
  String get darkTheme => 'Fosc';

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
      'Es desactivarà el vostre compte d’usuari. Això no es pot desfer! Esteu segur de fer-ho?';

  @override
  String get defaultPermissionLevel => 'Nivell de permisos per defecte';

  @override
  String get delete => 'Suprimeix';

  @override
  String get deleteAccount => 'Suprimeix el compte';

  @override
  String get deleteMessage => 'Suprimeix el missatge';

  @override
  String get deny => 'Denega';

  @override
  String get device => 'Dispositiu';

  @override
  String get deviceId => 'Id. de dispositiu';

  @override
  String get devices => 'Dispositius';

  @override
  String get directChats => 'Xats directes';

  @override
  String get discover => 'Descobreix';

  @override
  String get displaynameHasBeenChanged => 'Ha canviat l\'àlies';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Edita';

  @override
  String get editBlockedServers => 'Edita els servidors bloquejats';

  @override
  String get editChatPermissions => 'Edita els permisos del xat';

  @override
  String get editDisplayname => 'Edita l\'àlies';

  @override
  String get editRoomAliases => 'Edit chat aliases';

  @override
  String get editRoomAvatar => 'Edit chat avatar';

  @override
  String get emoteExists => 'L\'emoticona ja existeix!';

  @override
  String get emoteInvalid => 'Codi d\'emoticona invàlid!';

  @override
  String get emotePacks => 'Paquet d\'emoticones de la sala';

  @override
  String get emoteSettings => 'Paràmetres de les emoticones';

  @override
  String get emoteShortcode => 'Codi d\'emoticona';

  @override
  String get emoteWarnNeedToPick =>
      'Has de seleccionar un codi d\'emoticona i una imatge!';

  @override
  String get emptyChat => 'Xat buit';

  @override
  String get enableEmotesGlobally => 'Activa el paquet d\'emoticones global';

  @override
  String get enableEncryption => 'Activa el xifratge';

  @override
  String get enableEncryptionWarning =>
      'No podreu desactivar el xifratge mai més. N’esteu segur?';

  @override
  String get encrypted => 'Xifrat';

  @override
  String get encryption => 'Xifratge';

  @override
  String get encryptionNotEnabled => 'El xifratge no s’ha activat';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName ha finalitzat la trucada';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Introduïu una adreça electrònica';

  @override
  String get enterASpacepName => 'Introduïu un nom d’espai';

  @override
  String get homeserver => 'Homeserver';

  @override
  String get enterYourHomeserver => 'Introdueix el teu servidor';

  @override
  String errorObtainingLocation(Object error) {
    return 'S’ha produït un error en obtenir la ubicació: $error';
  }

  @override
  String get everythingReady => 'Tot és a punt!';

  @override
  String get extremeOffensive => 'Extremadament ofensiu';

  @override
  String get fileName => 'Nom del fitxer';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Mida de la lletra';

  @override
  String get forward => 'Reenvia';

  @override
  String get friday => 'divendres';

  @override
  String get fromJoining => 'Des de la unió';

  @override
  String get fromTheInvitation => 'Des de la invitació';

  @override
  String get goToTheNewRoom => 'Ves a la sala nova';

  @override
  String get group => 'Grup';

  @override
  String get groupDescription => 'Descripció de grup';

  @override
  String get groupDescriptionHasBeenChanged => 'Descripció de grup canviada';

  @override
  String get groupIsPublic => 'El grup és públic';

  @override
  String get groups => 'Grups';

  @override
  String groupWith(Object displayname) {
    return 'Grup amb $displayname';
  }

  @override
  String get guestsAreForbidden => 'Els convidats no poden unir-se';

  @override
  String get guestsCanJoin => 'Els convidats es poden unir';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username ha retirat la invitació de $targetName';
  }

  @override
  String get help => 'Ajuda';

  @override
  String get hideRedactedEvents => 'Amaga els esdeveniments velats';

  @override
  String get hideUnknownEvents => 'Amaga els esdeveniments desconeguts';

  @override
  String get howOffensiveIsThisContent => 'Com d’ofensiu és aquest contingut?';

  @override
  String get id => 'Id.';

  @override
  String get identity => 'Identitat';

  @override
  String get ignore => 'Ignora';

  @override
  String get ignoredUsers => 'Usuaris ignorats';

  @override
  String get ignoreListDescription =>
      'Pots ignorar els usuaris que et molestin. No rebràs els missatges ni les invitacions dels usuaris que es trobin a la teva llista personal d\'ignorats.';

  @override
  String get ignoreUsername => 'Ignora nom d\'usuari';

  @override
  String get iHaveClickedOnLink => 'He fet clic a l\'enllaç';

  @override
  String get incorrectPassphraseOrKey =>
      'Frase de seguretat o clau de recuperació incorrecta';

  @override
  String get inoffensive => 'Inoffensive';

  @override
  String get inviteContact => 'Convida contacte';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Convida contacte a $groupName';
  }

  @override
  String get invited => 'Convidat';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username ha convidat a $targetName';
  }

  @override
  String get invitedUsersOnly => 'Només usuaris convidats';

  @override
  String get inviteForMe => 'Invitació per a mi';

  @override
  String inviteText(Object username, Object link) {
    return '$username t\'ha convidat a FluffyChat.\n1. Instal·la FluffyChat: https://fluffychat.im\n2. Registra\'t o inicia sessió\n3. Obre l\'enllaç d\'invitació: $link';
  }

  @override
  String get isTyping => 'escrivint';

  @override
  String joinedTheChat(Object username) {
    return '$username s\'ha unit al xat';
  }

  @override
  String get joinRoom => 'Uneix-te a la sala';

  @override
  String get keysCached => 'Les claus estan desades a la memòria cau';

  @override
  String kicked(Object username, Object targetName) {
    return '$username ha expulsat a $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username ha expulsat i vetat a $targetName';
  }

  @override
  String get kickFromChat => 'Expulsa del xat';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Actiu per última vegada: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Vist va molt de temps';

  @override
  String get leave => 'Abandona';

  @override
  String get leftTheChat => 'Ha marxat del xat';

  @override
  String get license => 'Llicència';

  @override
  String get lightTheme => 'Clar';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Carrega $count participants més';
  }

  @override
  String get dehydrate => 'Export session and wipe device';

  @override
  String get dehydrateWarning =>
      'This action cannot be undone. Ensure you safely store the backup file.';

  @override
  String get dehydrateShare =>
      'This is your private FluffyChat export. Ensure you don\'t lose it and keep it private.';

  @override
  String get dehydrateTor => 'TOR Users: Export session';

  @override
  String get dehydrateTorLong =>
      'For TOR users, it is recommended to export the session before closing the window.';

  @override
  String get hydrateTor => 'TOR Users: Import session export';

  @override
  String get hydrateTorLong =>
      'Did you export your session last time on TOR? Quickly import it and continue chatting.';

  @override
  String get hydrate => 'Restore from backup file';

  @override
  String get loadingPleaseWait => 'S’està carregant… Espereu.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Carrega’n més…';

  @override
  String get locationDisabledNotice =>
      'S’han desactivat els serveis d’ubicació. Activeu-los per a compartir la vostra ubicació.';

  @override
  String get locationPermissionDeniedNotice =>
      'S’ha rebutjat el permís d’ubicació. Atorgueu-lo per a poder compartir la vostra ubicació.';

  @override
  String get login => 'Inicia la sessió';

  @override
  String logInTo(Object homeserver) {
    return 'Inicia sessió a $homeserver';
  }

  @override
  String get loginWithOneClick => 'Sign in with one click';

  @override
  String get logout => 'Finalitza la sessió';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Assegura\'t que l\'identificador sigui vàlid';

  @override
  String get memberChanges => 'Canvis de participants';

  @override
  String get mention => 'Menciona';

  @override
  String get messages => 'Missatges';

  @override
  String get messageWillBeRemovedWarning =>
      'El missatge s\'eliminarà per a tots els participants';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'Moderador';

  @override
  String get monday => 'dilluns';

  @override
  String get muteChat => 'Silencia el xat';

  @override
  String get needPantalaimonWarning =>
      'Tingueu en compte que, ara per ara, us cal el Pantalaimon per a poder utilitzar el xifratge d’extrem a extrem.';

  @override
  String get newChat => 'Xat nou';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Nova sol·licitud de verificació!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Següent';

  @override
  String get no => 'No';

  @override
  String get noConnectionToTheServer => 'Sense connexió al servidor';

  @override
  String get noEmotesFound => 'No s’ha trobat cap emoticona. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Només podreu activar el xifratge quan la sala ja no sigui accessible públicament.';

  @override
  String get noGoogleServicesWarning =>
      'Sembla que no teniu els Serveis de Google al telèfon. Això és una bona decisió respecte a la vostra privadesa! Per a rebre notificacions automàtiques del FluffyChat, us recomanem utilitzar https://microg.org/ o https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 is no matrix server, use $server2 instead?';
  }

  @override
  String get shareYourInviteLink => 'Share your invite link';

  @override
  String get typeInInviteLinkManually => 'Type in invite link manually...';

  @override
  String get scanQrCode => 'Escaneja un codi QR';

  @override
  String get none => 'Cap';

  @override
  String get noPasswordRecoveryDescription =>
      'Encara no heu afegit cap mètode per a poder recuperar la contrasenya.';

  @override
  String get noPermission => 'Sense permís';

  @override
  String get noRoomsFound => 'No s’ha trobat cap sala…';

  @override
  String get notifications => 'Notificacions';

  @override
  String numUsersTyping(Object count) {
    return '$count usuaris escrivint';
  }

  @override
  String get obtainingLocation => 'S’està obtenint la ubicació…';

  @override
  String get offensive => 'Offensive';

  @override
  String get offline => 'Fora de línia';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'D\'acord';

  @override
  String get online => 'En línia';

  @override
  String get onlineKeyBackupEnabled =>
      'La còpia de seguretat de claus en línia està activada';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Oops! Unfortunately, an error occurred when setting up the push notifications.';

  @override
  String get oopsSomethingWentWrong => 'Alguna cosa ha anat malament…';

  @override
  String get openAppToReadMessages =>
      'Obre l\'aplicació per llegir els missatges';

  @override
  String get openCamera => 'Obre la càmera';

  @override
  String get openVideoCamera => 'Open camera for a video';

  @override
  String get oneClientLoggedOut => 'One of your clients has been logged out';

  @override
  String get addAccount => 'Afegeix un compte';

  @override
  String get editBundlesForAccount => 'Edit bundles for this account';

  @override
  String get addToBundle => 'Add to bundle';

  @override
  String get removeFromBundle => 'Remove from this bundle';

  @override
  String get bundleName => 'Bundle name';

  @override
  String get enableMultiAccounts =>
      '(BETA) Enable multi accounts on this device';

  @override
  String get openInMaps => 'Open in maps';

  @override
  String get link => 'Enllaç';

  @override
  String get serverRequiresEmail =>
      'This server needs to validate your email address for registration.';

  @override
  String get optionalGroupName => '(Opcional) Nom del grup';

  @override
  String get or => 'O';

  @override
  String get participant => 'Participant';

  @override
  String get passphraseOrKey => 'contrasenya o clau de recuperació';

  @override
  String get password => 'Contrasenya';

  @override
  String get passwordForgotten => 'Contrasenya oblidada';

  @override
  String get passwordHasBeenChanged => 'La contrasenya ha canviat';

  @override
  String get passwordRecovery => 'Recuperació de contrassenya';

  @override
  String get people => 'Gent';

  @override
  String get pickImage => 'Selecciona una imatge';

  @override
  String get pin => 'Fixa';

  @override
  String play(Object fileName) {
    return 'Reproduir $fileName';
  }

  @override
  String get pleaseChoose => 'Please choose';

  @override
  String get pleaseChooseAPasscode => 'Tria un codi d\'accés';

  @override
  String get pleaseChooseAUsername => 'Tria un nom d\'usuari';

  @override
  String get pleaseClickOnLink =>
      'Fes clic a l\'enllaç del correu i, després, segueix.';

  @override
  String get pleaseEnter4Digits =>
      'Introdueix 4 dígits o deixa-ho buit per desactivar el bloqueig.';

  @override
  String get pleaseEnterAMatrixIdentifier =>
      'Introdueix un identificador de Matrix.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => 'Introdueix la teva contrasenya';

  @override
  String get pleaseEnterYourPin => 'Please enter your pin';

  @override
  String get pleaseEnterYourUsername => 'Introdueix el teu nom d\'usuari';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Seguiu les instruccions al lloc web i toqueu «Següent».';

  @override
  String get privacy => 'Privadesa';

  @override
  String get publicRooms => 'Sales públiques';

  @override
  String get pushRules => 'Regles push';

  @override
  String get reason => 'Raó';

  @override
  String get recording => 'Enregistrant';

  @override
  String redactedAnEvent(Object username) {
    return '$username ha velat un esdeveniment';
  }

  @override
  String get redactMessage => 'Vela el missatge';

  @override
  String get register => 'Register';

  @override
  String get reject => 'Rebutja';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username ha rebutjat la invitació';
  }

  @override
  String get rejoin => 'Torna-t\'hi a unir';

  @override
  String get remove => 'Elimina';

  @override
  String get removeAllOtherDevices => 'Elimina tots els altres dispositius';

  @override
  String removedBy(Object username) {
    return 'Eliminat per $username';
  }

  @override
  String get removeDevice => 'Elimina dispositiu';

  @override
  String get unbanFromChat => 'Desfés l\'expulsió';

  @override
  String get removeYourAvatar => 'Remove your avatar';

  @override
  String get renderRichContent => 'Mostra el contingut enriquit dels missatges';

  @override
  String get replaceRoomWithNewerVersion => 'Replace chat with newer version';

  @override
  String get reply => 'Respon';

  @override
  String get reportMessage => 'Denuncia el missatge';

  @override
  String get requestPermission => 'Sol·licita permís';

  @override
  String get roomHasBeenUpgraded => 'La sala s\'ha actualitzat';

  @override
  String get roomVersion => 'Versió de la sala';

  @override
  String get saturday => 'dissabte';

  @override
  String get saveFile => 'Desa el fitxer';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Seguretat';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyLost => 'Recovery key lost?';

  @override
  String seenByUser(Object username) {
    return 'Vist per $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vist per $username i $count més',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Vist per $username i $username2';
  }

  @override
  String get send => 'Envia';

  @override
  String get sendAMessage => 'Envia un missatge';

  @override
  String get sendAsText => 'Envia com a text';

  @override
  String get sendAudio => 'Envia un àudio';

  @override
  String get sendFile => 'Envia un fitxer';

  @override
  String get sendImage => 'Envia una imatge';

  @override
  String get sendMessages => 'Envia missatges';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Envia l’original';

  @override
  String get sendSticker => 'Envia adhesiu';

  @override
  String get sendVideo => 'Envia un vídeo';

  @override
  String sentAFile(Object username) {
    return '$username ha enviat un fitxer';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username ha enviat un àudio';
  }

  @override
  String sentAPicture(Object username) {
    return '$username ha enviat una imatge';
  }

  @override
  String sentASticker(Object username) {
    return '$username ha enviat un adhesiu';
  }

  @override
  String sentAVideo(Object username) {
    return '$username ha enviat un vídeo';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName ha enviat informació de trucada';
  }

  @override
  String get separateChatTypes => 'Separate Direct Chats and Groups';

  @override
  String get setAsCanonicalAlias => 'Defineix com a àlies principal';

  @override
  String get setCustomEmotes => 'Defineix emoticones personalitzades';

  @override
  String get setGroupDescription => 'Defineix la descripció del grup';

  @override
  String get setInvitationLink => 'Defineix l’enllaç per a convidar';

  @override
  String get setPermissionsLevel => 'Defineix el nivell de permisos';

  @override
  String get setStatus => 'Defineix l’estat';

  @override
  String get settings => 'Paràmetres';

  @override
  String get share => 'Comparteix';

  @override
  String sharedTheLocation(Object username) {
    return '$username n’ha compartit la ubicació';
  }

  @override
  String get shareLocation => 'Comparteix la ubicació';

  @override
  String get showDirectChatsInSpaces => 'Show related Direct Chats in Spaces';

  @override
  String get showPassword => 'Mostra la contrasenya';

  @override
  String get signUp => 'Registre';

  @override
  String get singlesignon => 'Autenticació única';

  @override
  String get skip => 'Omet';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Codi font';

  @override
  String get spaceIsPublic => 'L’espai és públic';

  @override
  String get spaceName => 'Nom de l’espai';

  @override
  String startedACall(Object senderName) {
    return '$senderName ha iniciat una trucada';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Estat';

  @override
  String get statusExampleMessage => 'Com us sentiu avui?';

  @override
  String get submit => 'Envia';

  @override
  String get sunday => 'diumenge';

  @override
  String get synchronizingPleaseWait => 'S’està sincronitzant… Espereu.';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theyDontMatch => 'No coincideixen';

  @override
  String get theyMatch => 'Coincideixen';

  @override
  String get thisRoomHasBeenArchived => 'Aquesta sala ha estat arxivada.';

  @override
  String get thursday => 'dijous';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Commuta l’estat «preferit»';

  @override
  String get toggleMuted => 'Commuta l’estat «silenci»';

  @override
  String get toggleUnread => 'Marca com a llegit/sense llegir';

  @override
  String get tooManyRequestsWarning =>
      'Massa sol·licituds. Torna-ho a provar més tard!';

  @override
  String get transferFromAnotherDevice =>
      'Transfereix des d’un altre dispositiu';

  @override
  String get tryToSendAgain => 'Intenta tornar a enviar';

  @override
  String get tuesday => 'dimarts';

  @override
  String get unavailable => 'No disponible';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username ha tret el veto a $targetName';
  }

  @override
  String get unblockDevice => 'Desbloqueja dispositiu';

  @override
  String get unknownDevice => 'Dispositiu desconegut';

  @override
  String get unknownEncryptionAlgorithm =>
      'L’algorisme de xifratge és desconegut';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Esdeveniment desconegut \'$type\'';
  }

  @override
  String get unmuteChat => 'Deixa de silenciar el xat';

  @override
  String get unpin => 'Deixa de fixar';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount xats no llegits',
      one: '1 xat no llegit',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username i $count més estan escrivint';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username i $username2 estan escrivint';
  }

  @override
  String userIsTyping(Object username) {
    return '$username està escrivint';
  }

  @override
  String userLeftTheChat(Object username) {
    return '$username ha marxat del xat';
  }

  @override
  String get username => 'Nom d’usuari';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username ha enviat un esdeveniment $type';
  }

  @override
  String get unverified => 'No verificat';

  @override
  String get verified => 'Verificat';

  @override
  String get verify => 'Verifica';

  @override
  String get verifyStart => 'Inicia la verificació';

  @override
  String get verifySuccess => 'T\'has verificat correctament!';

  @override
  String get verifyTitle => 'Verificant un altre compte';

  @override
  String get videoCall => 'Videotrucada';

  @override
  String get visibilityOfTheChatHistory => 'Visibilitat de l’historial del xat';

  @override
  String get visibleForAllParticipants => 'Visible per a tots els participants';

  @override
  String get visibleForEveryone => 'Visible per a tothom';

  @override
  String get voiceMessage => 'Missatge de veu';

  @override
  String get waitingPartnerAcceptRequest =>
      'S’està esperant que l’altre accepti la sol·licitud…';

  @override
  String get waitingPartnerEmoji =>
      'S’està esperant que l’altre accepti l’emoji…';

  @override
  String get waitingPartnerNumbers =>
      'S’està esperant que l’altre accepti els nombres…';

  @override
  String get wallpaper => 'Fons';

  @override
  String get warning => 'Atenció!';

  @override
  String get wednesday => 'dimecres';

  @override
  String get weSentYouAnEmail =>
      'Us hem enviat un missatge de correu electrònic';

  @override
  String get whoCanPerformWhichAction => 'Qui pot efectuar quina acció';

  @override
  String get whoIsAllowedToJoinThisGroup => 'Qui pot unir-se a aquest grup';

  @override
  String get whyDoYouWantToReportThis => 'Per què voleu denunciar això?';

  @override
  String get wipeChatBackup =>
      'Voleu suprimir la còpia de seguretat dels xats per a crear una clau de seguretat nova?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Amb aquestes adreces, si ho necessiteu, podeu recuperar la vostra contrasenya.';

  @override
  String get writeAMessage => 'Escriviu un missatge…';

  @override
  String get yes => 'Sí';

  @override
  String get you => 'Vós';

  @override
  String get youAreInvitedToThisChat => 'Us han convidat a aquest xat';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Ja no participeu en aquest xat';

  @override
  String get youCannotInviteYourself => 'No us podeu convidar a vós mateix';

  @override
  String get youHaveBeenBannedFromThisChat => 'Has estat vetat d\'aquest xat';

  @override
  String get yourPublicKey => 'La vostra clau pública';

  @override
  String get messageInfo => 'Message info';

  @override
  String get time => 'Time';

  @override
  String get messageType => 'Message Type';

  @override
  String get sender => 'Sender';

  @override
  String get openGallery => 'Open gallery';

  @override
  String get removeFromSpace => 'Remove from space';

  @override
  String get addToSpaceDescription => 'Select a space to add this chat to it.';

  @override
  String get start => 'Start';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'To unlock your old messages, please enter your recovery key that has been generated in a previous session. Your recovery key is NOT your password.';

  @override
  String get addToStory => 'Add to story';

  @override
  String get publish => 'Publish';

  @override
  String get whoCanSeeMyStories => 'Who can see my stories?';

  @override
  String get unsubscribeStories => 'Unsubscribe stories';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'This user has not posted anything in their story yet';

  @override
  String get yourStory => 'Your story';

  @override
  String get replyHasBeenSent => 'Reply has been sent';

  @override
  String videoWithSize(Object size) {
    return 'Video ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Story from $date: \n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Please note that people can see and contact each other in your story.';

  @override
  String get whatIsGoingOn => 'What is going on?';

  @override
  String get addDescription => 'Add description';

  @override
  String get storyPrivacyWarning =>
      'Please note that people can see and contact each other in your story. Your stories will be visible for 24 hours but there is no guarantee that they will be deleted from all devices and servers.';

  @override
  String get iUnderstand => 'I understand';

  @override
  String get openChat => 'Open Chat';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get reportUser => 'Report user';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get matrixWidgets => 'Matrix Widgets';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reacted with $reaction';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin =>
      'Are you sure to permanently unpin the message?';

  @override
  String get emojis => 'Emojis';

  @override
  String get placeCall => 'Place call';

  @override
  String get voiceCall => 'Voice call';

  @override
  String get unsupportedAndroidVersion => 'Unsupported Android version';

  @override
  String get unsupportedAndroidVersionLong =>
      'This feature requires a newer Android version. Please check for updates or Lineage OS support.';

  @override
  String get videoCallsBetaWarning =>
      'Please note that video calls are currently in beta. They might not work as expected or work at all on all platforms.';

  @override
  String get experimentalVideoCalls => 'Experimental video calls';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get indexedDbErrorTitle => 'Private mode issues';

  @override
  String get indexedDbErrorLong =>
      'The message storage is unfortunately not enabled in private mode by default.\nPlease visit\n - about:config\n - set dom.indexedDB.privateBrowsing.enabled to true\nOtherwise, it is not possible to run FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'Switch to account $number';
  }

  @override
  String get nextAccount => 'Next account';

  @override
  String get previousAccount => 'Previous account';

  @override
  String get editWidgets => 'Edit widgets';

  @override
  String get addWidget => 'Add widget';

  @override
  String get widgetVideo => 'Video';

  @override
  String get widgetEtherpad => 'Text note';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Custom';

  @override
  String get widgetName => 'Name';

  @override
  String get widgetUrlError => 'This is not a valid URL.';

  @override
  String get widgetNameError => 'Please provide a display name.';

  @override
  String get errorAddingWidget => 'Error adding the widget.';

  @override
  String get youRejectedTheInvitation => 'You rejected the invitation';

  @override
  String get youJoinedTheChat => 'You joined the chat';

  @override
  String get youAcceptedTheInvitation => '👍 You accepted the invitation';

  @override
  String youBannedUser(Object user) {
    return 'You banned $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'You have withdrawn the invitation for $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 You have been invited by $user';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 You invited $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 You kicked $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 You kicked and banned $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'You unbanned $user';
  }

  @override
  String get noEmailWarning =>
      'Please enter a valid email address. Otherwise you won\'t be able to reset your password. If you don\'t want to, tap again on the button to continue.';

  @override
  String get stories => 'Stories';

  @override
  String get users => 'Users';

  @override
  String get enableAutoBackups => 'Enable auto backups';

  @override
  String get unlockOldMessages => 'Unlock old messages';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription =>
      'Store the recovery key in the secure storage of this device.';

  @override
  String get saveKeyManuallyDescription =>
      'Save this key manually by triggering the system share dialog or clipboard.';

  @override
  String get storeInAndroidKeystore => 'Store in Android KeyStore';

  @override
  String get storeInAppleKeyChain => 'Store in Apple KeyChain';

  @override
  String get storeSecurlyOnThisDevice => 'Store securely on this device';

  @override
  String countFiles(Object count) {
    return '$count files';
  }

  @override
  String get user => 'User';

  @override
  String get custom => 'Custom';

  @override
  String get foregroundServiceRunning =>
      'This notification appears when the foreground service is running.';

  @override
  String get screenSharingTitle => 'screen sharing';

  @override
  String get screenSharingDetail => 'You are sharing your screen in FuffyChat';

  @override
  String get callingPermissions => 'Calling permissions';

  @override
  String get callingAccount => 'Calling account';

  @override
  String get callingAccountDetails =>
      'Allows FluffyChat to use the native android dialer app.';

  @override
  String get appearOnTop => 'Appear on top';

  @override
  String get appearOnTopDetails =>
      'Allows the app to appear on top (not needed if you already have Fluffychat setup as a calling account)';

  @override
  String get otherCallingPermissions =>
      'Microphone, camera and other FluffyChat permissions';

  @override
  String get whyIsThisMessageEncrypted => 'Why is this message unreadable?';

  @override
  String get noKeyForThisMessage =>
      'This can happen if the message was sent before you have signed in to your account at this device.\n\nIt is also possible that the sender has blocked your device or something went wrong with the internet connection.\n\nAre you able to read the message on another session? Then you can transfer the message from it! Go to Settings > Devices and make sure that your devices have verified each other. When you open the room the next time and both sessions are in the foreground, the keys will be transmitted automatically.\n\nDo you not want to loose the keys when logging out or switching devices? Make sure that you have enabled the chat backup in the settings.';

  @override
  String get newGroup => 'New chat';

  @override
  String get newSpace => 'New space';

  @override
  String get enterSpace => 'Enter space';

  @override
  String get enterRoom => 'Enter room';

  @override
  String get allSpaces => 'All spaces';

  @override
  String numChats(Object number) {
    return '$number chats';
  }

  @override
  String get hideUnimportantStateEvents => 'Hide unimportant state events';

  @override
  String get doNotShowAgain => 'Do not show again';

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
  String get search => 'Cerca';

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
