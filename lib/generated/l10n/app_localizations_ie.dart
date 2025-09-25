// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Interlingue Occidental (`ie`).
class L10nIe extends L10n {
  L10nIe([String locale = 'ie']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Passwords do not match!';

  @override
  String get pleaseEnterValidEmail =>
      'Ples provider un valid adresse de e-post.';

  @override
  String get repeatPassword => 'Repetir li contrasigne';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Ples usar adminim $min caracteres.';
  }

  @override
  String get about => 'Pri';

  @override
  String get updateAvailable => 'Un actualisament de FluffyChat es disponibil';

  @override
  String get updateNow => 'Actualisar in li funde';

  @override
  String get accept => 'Acceptar';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username ha acceptat li invitation';
  }

  @override
  String get account => 'Conto';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username activated end to end encryption';
  }

  @override
  String get addEmail => 'Adjunter e-post';

  @override
  String get confirmMatrixId =>
      'Ples confirmar vor Matrix ID por destructer vor conto.';

  @override
  String supposedMxid(Object mxid) {
    return 'To deve esser $mxid';
  }

  @override
  String get addGroupDescription => 'Adjunter un descrition de gruppe';

  @override
  String get addToSpace => 'Adjunter al spacie';

  @override
  String get admin => 'Administrator';

  @override
  String get alias => 'pseudonim';

  @override
  String get all => 'Omni';

  @override
  String get allChats => 'Omni conversationes';

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
    return '$senderName answered the call';
  }

  @override
  String get anyoneCanJoin => 'Alquí posse adherer se';

  @override
  String get appLock => 'App lock';

  @override
  String get archive => 'Archive';

  @override
  String get archivedRoom => 'Archivat chambre';

  @override
  String get areGuestsAllowedToJoin => 'Are guest users allowed to join';

  @override
  String get areYouSure => 'Esque vu es cert?';

  @override
  String get areYouSureYouWantToLogout => 'Esque vu vole cluder li session?';

  @override
  String get askSSSSSign =>
      'To be able to sign the other person, please enter your secure store passphrase or recovery key.';

  @override
  String askVerificationRequest(Object username) {
    return 'Esque acceptar ti demanda de verification de $username?';
  }

  @override
  String get autoplayImages => 'Automaticmen reproducter animat images';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Li hem-servitor supporta ti tipes de autentication:\n$serverVersions\nMa ti-ci application supporta solmen:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Inviar per Enter';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Li hem-servitor supporta ti versiones de specification:\n$serverVersions\nMa ti-ci application supporta solmen $supportedVersions';
  }

  @override
  String get banFromChat => 'Bannir del conversation';

  @override
  String get banned => 'Bannit';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username ha bannit $targetName';
  }

  @override
  String get blockDevice => 'Blocar li aparate';

  @override
  String get blocked => 'Blocat';

  @override
  String get botMessages => 'Missages de robots';

  @override
  String get bubbleSize => 'Dimension de parlada-bul';

  @override
  String get cancel => 'Anullar';

  @override
  String cantOpenUri(Object uri) {
    return 'Ne successat aperter li adresse $uri';
  }

  @override
  String get changeDeviceName => 'Cambiar li nómine de aparate';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username changed the chat avatar';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username changed the chat description to: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username changed the chat name to: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username changed the chat permissions';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username changed their displayname to: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username changed the guest access rules';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username changed the guest access rules to: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username changed the history visibility';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username changed the history visibility to: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username changed the join rules';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username changed the join rules to: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username changed their avatar';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username changed the chat aliases';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username changed the invitation link';
  }

  @override
  String get changePassword => 'Cambiar li contrasigne';

  @override
  String get changeTheHomeserver => 'Cambiar li hem-servitor';

  @override
  String get changeTheme => 'Cambiar li stil';

  @override
  String get changeTheNameOfTheGroup => 'Change the name of the chat';

  @override
  String get changeWallpaper => 'Cambiar li tapete';

  @override
  String get changeYourAvatar => 'Cambiar vor avatar';

  @override
  String get channelCorruptedDecryptError =>
      'The encryption has been corrupted';

  @override
  String get chat => 'Conversation';

  @override
  String get yourUserId => 'Vor ID de usator:';

  @override
  String get yourChatBackupHasBeenSetUp => 'Your chat backup has been set up.';

  @override
  String get chatBackup => 'Archive de conversation';

  @override
  String get chatBackupDescription =>
      'Your old messages are secured with a recovery key. Please make sure you don\'t lose it.';

  @override
  String get chatDetails => 'Detallies del conversation';

  @override
  String get chatHasBeenAddedToThisSpace => 'Chat has been added to this space';

  @override
  String get chats => 'Conversationes';

  @override
  String get chooseAStrongPassword => 'Choose a strong password';

  @override
  String get chooseAUsername => 'Selecte un nómine de usator';

  @override
  String get clearArchive => 'Vacuar li archive';

  @override
  String get close => 'Cluder';

  @override
  String get commandHint_markasdm => 'Mark as direct chat';

  @override
  String get commandHint_markasgroup => 'Marcar quam gruppe';

  @override
  String get commandHint_ban => 'Ban the given user from this chat';

  @override
  String get commandHint_clearcache => 'Vacuar li cache';

  @override
  String get commandHint_create =>
      'Create an empty chat\nUse --no-encryption to disable encryption';

  @override
  String get commandHint_discardsession => 'Discard session';

  @override
  String get commandHint_dm =>
      'Start a direct chat\nUse --no-encryption to disable encryption';

  @override
  String get commandHint_html => 'Inviar contenete HTML';

  @override
  String get commandHint_invite => 'Invite the given user to this chat';

  @override
  String get commandHint_join => 'Join the given chat';

  @override
  String get commandHint_kick => 'Remove the given user from this chat';

  @override
  String get commandHint_leave => 'Forlassar ti chambre';

  @override
  String get commandHint_me => 'Ples descrir vos';

  @override
  String get commandHint_myroomavatar =>
      'Set your picture for this chat (by mxc-uri)';

  @override
  String get commandHint_myroomnick => 'Set your display name for this chat';

  @override
  String get commandHint_op =>
      'Set the given user\'s power level (default: 50)';

  @override
  String get commandHint_plain => 'Inviar textu sin formate';

  @override
  String get commandHint_react => 'Send reply as a reaction';

  @override
  String get commandHint_send => 'Inviar li textu';

  @override
  String get commandHint_unban => 'Unban the given user from this chat';

  @override
  String get commandInvalid => 'Comande es ínvalid';

  @override
  String commandMissing(Object command) {
    return '$command is not a command.';
  }

  @override
  String get compareEmojiMatch => 'Please compare the emojis';

  @override
  String get compareNumbersMatch => 'Please compare the numbers';

  @override
  String get configureChat => 'Configurar li conversation';

  @override
  String get confirm => 'Confirmar';

  @override
  String get connect => 'Conexer';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'Contact has been invited to the chat';

  @override
  String get containsDisplayName => 'Contene li visibil nómine';

  @override
  String get containsUserName => 'Contene li nómine';

  @override
  String get contentHasBeenReported =>
      'The content has been reported to the server admins';

  @override
  String get copiedToClipboard => 'Copiat al Paperiere';

  @override
  String get copy => 'Copiar';

  @override
  String get copyToClipboard => 'Copiar al Paperiere';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Could not decrypt message: $error';
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
    return '💬 $username created the chat';
  }

  @override
  String get createNewGroup => 'Crear un nov gruppe';

  @override
  String get createNewSpace => 'Crear un spacie';

  @override
  String get crossSigningEnabled => 'Cross-signing on';

  @override
  String get currentlyActive => 'Activ actualmen';

  @override
  String get darkTheme => 'Obscur';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$day.$month';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$day.$month.$year';
  }

  @override
  String get deactivateAccountWarning =>
      'This will deactivate your user account. This can not be undone! Are you sure?';

  @override
  String get defaultPermissionLevel => 'Default permission level';

  @override
  String get delete => 'Remover';

  @override
  String get deleteAccount => 'Destructer li conto';

  @override
  String get deleteMessage => 'Remover li missage';

  @override
  String get deny => 'Refusar';

  @override
  String get device => 'Aparate';

  @override
  String get deviceId => 'ID de aparate';

  @override
  String get devices => 'Aparates';

  @override
  String get directChats => 'Direct conversationes';

  @override
  String get discover => 'Decovrir';

  @override
  String get displaynameHasBeenChanged => 'Displayname has been changed';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Redacter';

  @override
  String get editBlockedServers => 'Modificar blocat servitores';

  @override
  String get editChatPermissions => 'Edit chat permissions';

  @override
  String get editDisplayname => 'Redacter li visibil nómine';

  @override
  String get editRoomAliases => 'Modificar pseudonimos del chambre';

  @override
  String get editRoomAvatar => 'Modificar li avatar del chambre';

  @override
  String get emoteExists => 'Emotion ja existe!';

  @override
  String get emoteInvalid => 'Invalid emote shortcode!';

  @override
  String get emotePacks => 'Emote packs for chat';

  @override
  String get emoteSettings => 'Parametres de emotiones';

  @override
  String get emoteShortcode => 'Curt-code de emotion';

  @override
  String get emoteWarnNeedToPick =>
      'You need to pick an emote shortcode and an image!';

  @override
  String get emptyChat => 'Vacui conversation';

  @override
  String get enableEmotesGlobally => 'Enable emote pack globally';

  @override
  String get enableEncryption => 'Activar li ciffration';

  @override
  String get enableEncryptionWarning =>
      'You won\'t be able to disable the encryption anymore. Are you sure?';

  @override
  String get encrypted => 'Ciffrat';

  @override
  String get encryption => 'Ciffration';

  @override
  String get encryptionNotEnabled => 'Encryption is not enabled';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName ended the call';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Enter an email address';

  @override
  String get enterASpacepName => 'Enter a space name';

  @override
  String get homeserver => 'Hem-servitor';

  @override
  String get enterYourHomeserver => 'Provide vor hem-servitor';

  @override
  String errorObtainingLocation(Object error) {
    return 'Error obtaining location: $error';
  }

  @override
  String get everythingReady => 'Omni es pret!';

  @override
  String get extremeOffensive => 'Extremmen offensiv';

  @override
  String get fileName => 'Nómine de file';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Dimension de fonde';

  @override
  String get forward => 'Avan';

  @override
  String get friday => 'Venerdí';

  @override
  String get fromJoining => 'Pro adhesion';

  @override
  String get fromTheInvitation => 'Pro invitation';

  @override
  String get goToTheNewRoom => 'Go to the new chat';

  @override
  String get group => 'Gruppe';

  @override
  String get groupDescription => 'Descrition del gruppe';

  @override
  String get groupDescriptionHasBeenChanged => 'Group chat description changed';

  @override
  String get groupIsPublic => 'Gruppe es public';

  @override
  String get groups => 'Gruppes';

  @override
  String groupWith(Object displayname) {
    return 'Gruppe con $displayname';
  }

  @override
  String get guestsAreForbidden => 'Guests are forbidden';

  @override
  String get guestsCanJoin => 'Guests can join';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username has withdrawn the invitation for $targetName';
  }

  @override
  String get help => 'Auxilie';

  @override
  String get hideRedactedEvents => 'Hide deleted messages';

  @override
  String get hideUnknownEvents => 'Celar ínconosset evenimentes';

  @override
  String get howOffensiveIsThisContent => 'How offensive is this content?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identitá';

  @override
  String get ignore => 'Ignorar';

  @override
  String get ignoredUsers => 'Ignorat usatores';

  @override
  String get ignoreListDescription =>
      'You can ignore users who are disturbing you. You won\'t be able to receive any messages or chat invites from the users on your personal ignore list.';

  @override
  String get ignoreUsername => 'Ignorar un nómine';

  @override
  String get iHaveClickedOnLink => 'I have clicked on the link';

  @override
  String get incorrectPassphraseOrKey => 'Incorrect passphrase or recovery key';

  @override
  String get inoffensive => 'Ínoffensiv';

  @override
  String get inviteContact => 'Invitar un contacte';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Invite contact to $groupName';
  }

  @override
  String get invited => 'Invitat';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username invitat $targetName';
  }

  @override
  String get invitedUsersOnly => 'Solmen invitat usatores';

  @override
  String get inviteForMe => 'Invitationes por me';

  @override
  String inviteText(Object username, Object link) {
    return '$username invited you to FluffyChat. \n1. Install FluffyChat: https://fluffychat.im \n2. Sign up or sign in \n3. Open the invite link: $link';
  }

  @override
  String get isTyping => 'tippa';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username joined the chat';
  }

  @override
  String get joinRoom => 'Adherer al chambre';

  @override
  String get keysCached => 'Claves es in cache';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username kicked $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username kicked and banned $targetName';
  }

  @override
  String get kickFromChat => 'Kick from chat';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Ultim activité: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Seen a long time ago';

  @override
  String get leave => 'Forlassar';

  @override
  String get leftTheChat => 'Surtit ex li conversation';

  @override
  String get license => 'Licentie';

  @override
  String get lightTheme => 'Lucid';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Load $count more participants';
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
  String get loadingPleaseWait => 'Cargante... ples atender.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Cargar plu…';

  @override
  String get locationDisabledNotice =>
      'Location services are disabled. Please enable them to be able to share your location.';

  @override
  String get locationPermissionDeniedNotice =>
      'Location permission denied. Please grant them to be able to share your location.';

  @override
  String get login => 'Aperter li session';

  @override
  String logInTo(Object homeserver) {
    return 'Log in to $homeserver';
  }

  @override
  String get loginWithOneClick => 'Sign in with one click';

  @override
  String get logout => 'Cluder li session';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Make sure the identifier is valid';

  @override
  String get memberChanges => 'Cambios inter membres';

  @override
  String get mention => 'Mentionar';

  @override
  String get messages => 'Missages';

  @override
  String get messageWillBeRemovedWarning =>
      'Message will be removed for all participants';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'Moderator';

  @override
  String get monday => 'Lunedí';

  @override
  String get muteChat => 'Assurdar li conversation';

  @override
  String get needPantalaimonWarning =>
      'Please be aware that you need Pantalaimon to use end-to-end encryption for now.';

  @override
  String get newChat => 'Crear un conversation';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Nov demanda de verification!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Sequent';

  @override
  String get no => 'No';

  @override
  String get noConnectionToTheServer => 'No connection to the server';

  @override
  String get noEmotesFound => 'No emotes found. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'You can only activate encryption as soon as the chat is no longer publicly accessible.';

  @override
  String get noGoogleServicesWarning =>
      'It seems that you have no google services on your phone. That\'s a good decision for your privacy! To receive push notifications in FluffyChat we recommend using https://microg.org/ or https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 is no matrix server, use $server2 instead?';
  }

  @override
  String get shareYourInviteLink => 'Share your invite link';

  @override
  String get typeInInviteLinkManually => 'Type in invite link manually...';

  @override
  String get scanQrCode => 'Scannar un code QR';

  @override
  String get none => 'Null';

  @override
  String get noPasswordRecoveryDescription =>
      'You have not added a way to recover your password yet.';

  @override
  String get noPermission => 'Sin permission';

  @override
  String get noRoomsFound => 'Null chambres trovat…';

  @override
  String get notifications => 'Notificationes';

  @override
  String numUsersTyping(Object count) {
    return '$count users are typing';
  }

  @override
  String get obtainingLocation => 'Obtenente li localisation…';

  @override
  String get offensive => 'Offensiv';

  @override
  String get offline => 'For del rete';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'OK';

  @override
  String get online => 'In li rete';

  @override
  String get onlineKeyBackupEnabled => 'Online Key Backup is enabled';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Oops! Unfortunately, an error occurred when setting up the push notifications.';

  @override
  String get oopsSomethingWentWrong => 'Oops, something went wrong…';

  @override
  String get openAppToReadMessages => 'Open app to read messages';

  @override
  String get openCamera => 'Aperter li cámera';

  @override
  String get openVideoCamera => 'Open camera for a video';

  @override
  String get oneClientLoggedOut => 'One of your clients has been logged out';

  @override
  String get addAccount => 'Adjunter un conto';

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
  String get openInMaps => 'Aperter in mappas';

  @override
  String get link => 'Ligament';

  @override
  String get serverRequiresEmail =>
      'This server needs to validate your email address for registration.';

  @override
  String get optionalGroupName => '(Facultativ) Nómine de gruppe';

  @override
  String get or => 'O';

  @override
  String get participant => 'Participante';

  @override
  String get passphraseOrKey => 'passphrase or recovery key';

  @override
  String get password => 'Contrasigne';

  @override
  String get passwordForgotten => 'Li contrasigne esset obliviat';

  @override
  String get passwordHasBeenChanged => 'Password has been changed';

  @override
  String get passwordRecovery => 'Reganiar li contrasigne';

  @override
  String get people => 'Homes';

  @override
  String get pickImage => 'Pick an image';

  @override
  String get pin => 'Fixar';

  @override
  String play(Object fileName) {
    return 'Reproducter $fileName';
  }

  @override
  String get pleaseChoose => 'Ples selecter';

  @override
  String get pleaseChooseAPasscode => 'Please choose a pass code';

  @override
  String get pleaseChooseAUsername => 'Please choose a username';

  @override
  String get pleaseClickOnLink =>
      'Please click on the link in the email and then proceed.';

  @override
  String get pleaseEnter4Digits =>
      'Please enter 4 digits or leave empty to disable app lock.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Please enter a Matrix ID.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get pleaseEnterYourPin => 'Please enter your pin';

  @override
  String get pleaseEnterYourUsername => 'Please enter your username';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Please follow the instructions on the website and tap on next.';

  @override
  String get privacy => 'Privatie';

  @override
  String get publicRooms => 'Public chambres';

  @override
  String get pushRules => 'Regules de push-notificationes';

  @override
  String get reason => 'Cause';

  @override
  String get recording => 'Registrante';

  @override
  String redactedAnEvent(Object username) {
    return '$username has deleted a message';
  }

  @override
  String get redactMessage => 'Redacter li missage';

  @override
  String get register => 'Inregistrar se';

  @override
  String get reject => 'Refuser';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username rejected the invitation';
  }

  @override
  String get rejoin => 'Re-adherer';

  @override
  String get remove => 'Remover';

  @override
  String get removeAllOtherDevices => 'Remove all other devices';

  @override
  String removedBy(Object username) {
    return 'Removed by $username';
  }

  @override
  String get removeDevice => 'Remover li aparate';

  @override
  String get unbanFromChat => 'Unban from chat';

  @override
  String get removeYourAvatar => 'Remove your avatar';

  @override
  String get renderRichContent => 'Render rich message content';

  @override
  String get replaceRoomWithNewerVersion => 'Replace chat with newer version';

  @override
  String get reply => 'Responder';

  @override
  String get reportMessage => 'Raportar li missage';

  @override
  String get requestPermission => 'Demandar li permission';

  @override
  String get roomHasBeenUpgraded => 'Group chat has been upgraded';

  @override
  String get roomVersion => 'Version del chambre';

  @override
  String get saturday => 'Saturdí';

  @override
  String get saveFile => 'Gardar li file';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Securitá';

  @override
  String get recoveryKey => 'Clave de regania';

  @override
  String get recoveryKeyLost => 'Recovery key lost?';

  @override
  String seenByUser(Object username) {
    return 'Seen by $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seen by $username and $count others',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Seen by $username and $username2';
  }

  @override
  String get send => 'Inviar';

  @override
  String get sendAMessage => 'Send a message';

  @override
  String get sendAsText => 'Send as text';

  @override
  String get sendAudio => 'Inviar audio';

  @override
  String get sendFile => 'Inviar un file';

  @override
  String get sendImage => 'Inviar un image';

  @override
  String get sendMessages => 'Inviar missages';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Inviar li originale';

  @override
  String get sendSticker => 'Inviar un nota adhesiv';

  @override
  String get sendVideo => 'Inviar video';

  @override
  String sentAFile(Object username) {
    return '📁 $username sent a file';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username sent an audio';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username sent a picture';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username sent a sticker';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username sent a video';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName sent call information';
  }

  @override
  String get separateChatTypes => 'Separate Direct Chats and Groups';

  @override
  String get setAsCanonicalAlias => 'Set as main alias';

  @override
  String get setCustomEmotes => 'Set custom emotes';

  @override
  String get setGroupDescription => 'Set description';

  @override
  String get setInvitationLink => 'Set invitation link';

  @override
  String get setPermissionsLevel => 'Set permissions level';

  @override
  String get setStatus => 'Assignar li statu';

  @override
  String get settings => 'Parametres';

  @override
  String get share => 'Partir';

  @override
  String sharedTheLocation(Object username) {
    return '$username shared their location';
  }

  @override
  String get shareLocation => 'Partir un localisation';

  @override
  String get showDirectChatsInSpaces => 'Show related Direct Chats in Spaces';

  @override
  String get showPassword => 'Monstrar li contrasigne';

  @override
  String get signUp => 'Inregistrar se';

  @override
  String get singlesignon => 'Single Sign on';

  @override
  String get skip => 'Omisser';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Code de fonte';

  @override
  String get spaceIsPublic => 'Space is public';

  @override
  String get spaceName => 'Nómine de spacie';

  @override
  String startedACall(Object senderName) {
    return '$senderName started a call';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Statu';

  @override
  String get statusExampleMessage => 'How are you today?';

  @override
  String get submit => 'Inviar';

  @override
  String get sunday => 'Soledí';

  @override
  String get synchronizingPleaseWait => 'Synchronizing… Please wait.';

  @override
  String get systemTheme => 'Del sistema';

  @override
  String get theyDontMatch => 'They Don\'t Match';

  @override
  String get theyMatch => 'Corresponde';

  @override
  String get thisRoomHasBeenArchived => 'This chat has been archived.';

  @override
  String get thursday => 'Jovedí';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Toggle Favorite';

  @override
  String get toggleMuted => 'Toggle Muted';

  @override
  String get toggleUnread => 'Marcar quam (ín)leet';

  @override
  String get tooManyRequestsWarning =>
      'Too many requests. Please try again later!';

  @override
  String get transferFromAnotherDevice => 'Transfer from another device';

  @override
  String get tryToSendAgain => 'Try to send again';

  @override
  String get tuesday => 'Mardí';

  @override
  String get unavailable => 'Índisponibil';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username unbanned $targetName';
  }

  @override
  String get unblockDevice => 'Deblocar li aparate';

  @override
  String get unknownDevice => 'Ínconosset aparate';

  @override
  String get unknownEncryptionAlgorithm => 'Unknown encryption algorithm';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Unknown event \'$type\'';
  }

  @override
  String get unmuteChat => 'Unmute chat';

  @override
  String get unpin => 'Defixar';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount unread chats',
      one: '1 unread chat',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username and $count others are typing';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username and $username2 are typing';
  }

  @override
  String userIsTyping(Object username) {
    return '$username is typing';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username left the chat';
  }

  @override
  String get username => 'Nómine de usator';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username sent a $type event';
  }

  @override
  String get unverified => 'Ínverificat';

  @override
  String get verified => 'Verificat';

  @override
  String get verify => 'Verificar';

  @override
  String get verifyStart => 'Iniciar li verification';

  @override
  String get verifySuccess => 'You successfully verified!';

  @override
  String get verifyTitle => 'Verifying other account';

  @override
  String get videoCall => 'Videotelefonada';

  @override
  String get visibilityOfTheChatHistory => 'Visibility of the chat history';

  @override
  String get visibleForAllParticipants => 'Visible for all participants';

  @override
  String get visibleForEveryone => 'Visible for everyone';

  @override
  String get voiceMessage => 'Voce-missage';

  @override
  String get waitingPartnerAcceptRequest =>
      'Waiting for partner to accept the request…';

  @override
  String get waitingPartnerEmoji => 'Waiting for partner to accept the emoji…';

  @override
  String get waitingPartnerNumbers =>
      'Waiting for partner to accept the numbers…';

  @override
  String get wallpaper => 'Tapete';

  @override
  String get warning => 'Avise!';

  @override
  String get wednesday => 'Mercurdí';

  @override
  String get weSentYouAnEmail => 'We sent you an email';

  @override
  String get whoCanPerformWhichAction => 'Who can perform which action';

  @override
  String get whoIsAllowedToJoinThisGroup => 'Who is allowed to join this chat';

  @override
  String get whyDoYouWantToReportThis => 'Why do you want to report this?';

  @override
  String get wipeChatBackup =>
      'Wipe your chat backup to create a new recovery key?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'With these addresses you can recover your password.';

  @override
  String get writeAMessage => 'Write a message…';

  @override
  String get yes => 'Yes';

  @override
  String get you => 'Vu';

  @override
  String get youAreInvitedToThisChat => 'You are invited to this chat';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'You are no longer participating in this chat';

  @override
  String get youCannotInviteYourself => 'You cannot invite yourself';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'You have been banned from this chat';

  @override
  String get yourPublicKey => 'Your public key';

  @override
  String get messageInfo => 'Information pri li missage';

  @override
  String get time => 'Hora';

  @override
  String get messageType => 'Tip de missage';

  @override
  String get sender => 'Autor';

  @override
  String get openGallery => 'Aperter li galerie';

  @override
  String get removeFromSpace => 'Remove from space';

  @override
  String get addToSpaceDescription => 'Select a space to add this chat to it.';

  @override
  String get start => 'Iniciar';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'To unlock your old messages, please enter your recovery key that has been generated in a previous session. Your recovery key is NOT your password.';

  @override
  String get addToStory => 'Add to story';

  @override
  String get publish => 'Publicar';

  @override
  String get whoCanSeeMyStories => 'Who can see my stories?';

  @override
  String get unsubscribeStories => 'Desabonnar racontas';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'This user has not posted anything in their story yet';

  @override
  String get yourStory => 'Vor raconte';

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
  String get addDescription => 'Adjunter un descrition';

  @override
  String get storyPrivacyWarning =>
      'Please note that people can see and contact each other in your story. Your stories will be visible for 24 hours but there is no guarantee that they will be deleted from all devices and servers.';

  @override
  String get iUnderstand => 'Yo comprende';

  @override
  String get openChat => 'Aperter li conversation';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get reportUser => 'Raportar li usator';

  @override
  String get dismiss => 'Demisser';

  @override
  String get matrixWidgets => 'Widgets de Matrix';

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
  String get emojis => 'Emoji';

  @override
  String get placeCall => 'Place call';

  @override
  String get voiceCall => 'Telefonada';

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
  String get nextAccount => 'Sequent conto';

  @override
  String get previousAccount => 'Precedent conto';

  @override
  String get editWidgets => 'Modificar li widgets';

  @override
  String get addWidget => 'Adjunter un widget';

  @override
  String get widgetVideo => 'Video';

  @override
  String get widgetEtherpad => 'Textual nota';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Personalisat';

  @override
  String get widgetName => 'Nómine';

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
  String get stories => 'Racontas';

  @override
  String get users => 'Usatores';

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
  String get user => 'Usator';

  @override
  String get custom => 'Personalisat';

  @override
  String get foregroundServiceRunning =>
      'This notification appears when the foreground service is running.';

  @override
  String get screenSharingTitle => 'partir li ecran';

  @override
  String get screenSharingDetail => 'You are sharing your screen in FuffyChat';

  @override
  String get callingPermissions => 'Permissiones de telefonada';

  @override
  String get callingAccount => 'Conto telefonante';

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
  String get newGroup => 'Crear un gruppe';

  @override
  String get newSpace => 'Crear un spacie';

  @override
  String get enterSpace => 'Intrar li spacie';

  @override
  String get enterRoom => 'Intrar li chambre';

  @override
  String get allSpaces => 'Omni spacies';

  @override
  String numChats(Object number) {
    return '$number conversationes';
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
  String get search => 'Sercha';

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
