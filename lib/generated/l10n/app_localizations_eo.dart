// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Esperanto (`eo`).
class L10nEo extends L10n {
  L10nEo([String locale = 'eo']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Passwords do not match!';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address.';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Please choose at least $min characters.';
  }

  @override
  String get about => 'Prio';

  @override
  String get updateAvailable => 'Twake Chat update available';

  @override
  String get updateNow => 'Start update in background';

  @override
  String get accept => 'Akcepti';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username akceptis la inviton';
  }

  @override
  String get account => 'Konto';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username aktivigis tutvojan ĉifradon';
  }

  @override
  String get addEmail => 'Aldoni retpoŝtadreson';

  @override
  String get confirmMatrixId =>
      'Please confirm your Matrix ID in order to delete your account.';

  @override
  String supposedMxid(Object mxid) {
    return 'This should be $mxid';
  }

  @override
  String get addGroupDescription => 'Aldoni priskribon de grupo';

  @override
  String get addToSpace => 'Aldoni al aro';

  @override
  String get admin => 'Administranto';

  @override
  String get alias => 'kromnomo';

  @override
  String get all => 'Ĉio';

  @override
  String get allChats => 'Ĉiuj babiloj';

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
    return '$senderName respondis la vokon';
  }

  @override
  String get anyoneCanJoin => 'Ĉiu ajn povas aliĝi';

  @override
  String get appLock => 'Ŝlosado';

  @override
  String get archive => 'Arĥivo';

  @override
  String get archivedRoom => 'Arĥivita ĉambro';

  @override
  String get areGuestsAllowedToJoin => 'Ĉu gastoj rajtas aliĝi';

  @override
  String get areYouSure => 'Ĉu vi certas?';

  @override
  String get areYouSureYouWantToLogout => 'Ĉu vi certe volas adiaŭi?';

  @override
  String get askSSSSSign =>
      'Por ke vi povu kontroli (subskribi) la alian personon, bonvolu enigi pasfrazon de via sekreta deponejo aŭ vian rehavan ŝlosilon.';

  @override
  String askVerificationRequest(Object username) {
    return 'Ĉu akcepti ĉi tiun kontrolpeton de $username?';
  }

  @override
  String get autoplayImages =>
      'Memage ludi movbildajn glumarkojn kaj mienetojn';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'La hejmservilo subtenas la jenajn specojn de salutoj:\n$serverVersions\nSed ĉi tiu aplikaĵo subtenas nur:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Sendi per eniga klavo';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'La hejmservilo subtenas la jenajn version de la specifaĵo:\n$serverVersions\nSed ĉi tiu aplikaĵo subtenas nur $supportedVersions';
  }

  @override
  String get banFromChat => 'Forbari de babilo';

  @override
  String get banned => 'Forbarita';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username forbaris uzanton $targetName';
  }

  @override
  String get blockDevice => 'Bloki aparaton';

  @override
  String get blocked => 'Blokita';

  @override
  String get botMessages => 'Mesaĝoj de robotoj';

  @override
  String get bubbleSize => 'Bubble size';

  @override
  String get cancel => 'Nuligi';

  @override
  String cantOpenUri(Object uri) {
    return 'Ne povis malfermi URI $uri';
  }

  @override
  String get changeDeviceName => 'Ŝanĝi nomon de aparato';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username ŝanĝis bildon de la babilo';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username ŝanĝis priskribon de la babilo al: «$description»';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username ŝanĝis nomon de la babilo al: «$chatname»';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username ŝanĝis permesojn pri la babilo';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username ŝanĝis sian prezentan nomon al: $username';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username ŝanĝis regulojn pri aliro de gastoj';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username ŝanĝis regulojn pri aliro de gastoj al: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username ŝanĝis videblecon de la historio';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username ŝanĝis videblecon de la historio al: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username ŝanĝis regulojn pri aliĝado';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username ŝanĝis regulojn pri aliĝado al: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username ŝanĝis sian profilbildon';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username ŝanĝis la kromnomojn de la ĉambro';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username ŝanĝis la invitan ligilon';
  }

  @override
  String get changePassword => 'Ŝanĝi pasvorton';

  @override
  String get changeTheHomeserver => 'Ŝanĝi hejmservilon';

  @override
  String get changeTheme => 'Ŝanĝu la haŭton';

  @override
  String get changeTheNameOfTheGroup => 'Ŝanĝi nomon de la grupo';

  @override
  String get changeWallpaper => 'Ŝanĝi fonbildon';

  @override
  String get changeYourAvatar => 'Ŝanĝi vian profilbildon';

  @override
  String get channelCorruptedDecryptError => 'La ĉifrado estas difektita';

  @override
  String get chat => 'Babilo';

  @override
  String get yourUserId => 'Your user ID:';

  @override
  String get yourChatBackupHasBeenSetUp => 'Your chat backup has been set up.';

  @override
  String get chatBackup => 'Savkopiado de babilo';

  @override
  String get chatBackupDescription =>
      'Via savkopio de babilo estas sekurigita per sekureca ŝlosilo. Bonvolu certigi, ke vi ne perdos ĝin.';

  @override
  String get chatDetails => 'Detaloj pri babilo';

  @override
  String get chatHasBeenAddedToThisSpace => 'Babilo aldoniĝis al ĉi tiu aro';

  @override
  String get chats => 'Babiloj';

  @override
  String get chooseAStrongPassword => 'Elektu fortan pasvorton';

  @override
  String get chooseAUsername => 'Elektu uzantonomon';

  @override
  String get clearArchive => 'Vakigi arĥivon';

  @override
  String get close => 'Fermi';

  @override
  String get commandHint_markasdm => 'Mark as direct chat';

  @override
  String get commandHint_markasgroup => 'Mark as chat';

  @override
  String get commandHint_ban => 'Forbari la donitan uzanton de ĉi tiu ĉambro';

  @override
  String get commandHint_clearcache => 'Clear cache';

  @override
  String get commandHint_create =>
      'Create an empty chat\nUse --no-encryption to disable encryption';

  @override
  String get commandHint_discardsession => 'Discard session';

  @override
  String get commandHint_dm =>
      'Start a direct chat\nUse --no-encryption to disable encryption';

  @override
  String get commandHint_html => 'Sendi tekston formatan je HTML';

  @override
  String get commandHint_invite => 'Inviti la donitan uzanton al ĉi tiu ĉambro';

  @override
  String get commandHint_join => 'Aliĝi al la donita ĉambro';

  @override
  String get commandHint_kick => 'Forigi la donitan uzanton de ĉi tiu ĉambro';

  @override
  String get commandHint_leave => 'Foriri de ĉi tiu ĉambro';

  @override
  String get commandHint_me => 'Priskribu vian agon';

  @override
  String get commandHint_myroomavatar =>
      'Agordi vian profilbildon por ĉi tiu ĉambro (laŭ mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Agordi vian prezentan nomon en ĉi tiu ĉambro';

  @override
  String get commandHint_op =>
      'Agordi povnivelon de la donita uzanto (implicite: 50)';

  @override
  String get commandHint_plain => 'Sendi senformatan tekston';

  @override
  String get commandHint_react => 'Sendi respondon kiel reagon';

  @override
  String get commandHint_send => 'Sendi tekston';

  @override
  String get commandHint_unban =>
      'Malforbari la donitan uzanton de ĉi tiu ĉambro';

  @override
  String get commandInvalid => 'Nevalida ordono';

  @override
  String commandMissing(Object command) {
    return '$command ne estas ordono.';
  }

  @override
  String get compareEmojiMatch =>
      'Komparu kaj certigu, ke la jenaj bildosignoj samas en ambaŭ aparatoj:';

  @override
  String get compareNumbersMatch =>
      'Komparu kaj certigu, ke la jenaj numeroj samas en ambaŭ aparatoj:';

  @override
  String get configureChat => 'Agordi babilon';

  @override
  String get confirm => 'Konfirmi';

  @override
  String get connect => 'Konektiĝi';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'Kontakto invitiĝis al la grupo';

  @override
  String get containsDisplayName => 'Enhavas prezentan nomon';

  @override
  String get containsUserName => 'Enhavas uzantonomon';

  @override
  String get contentHasBeenReported =>
      'La enhavo raportiĝis al la administrantoj de la servilo';

  @override
  String get copiedToClipboard => 'Kopiite al tondujo';

  @override
  String get copy => 'Kopii';

  @override
  String get copyToClipboard => 'Kopii al tondujo';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Ne povis malĉifri mesaĝon: $error';
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
  String get create => 'Krei';

  @override
  String createdTheChat(Object username) {
    return '$username kreis la babilon';
  }

  @override
  String get createNewGroup => 'Krei novan grupon';

  @override
  String get createNewSpace => 'Nova aro';

  @override
  String get crossSigningEnabled => 'Delegaj subskriboj estas ŝaltitaj';

  @override
  String get currentlyActive => 'Nun aktiva';

  @override
  String get darkTheme => 'Malhela';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '${day}a de la ${month}a';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '${day}a de la ${month}a de $year';
  }

  @override
  String get deactivateAccountWarning =>
      'Ĉi tio malaktivigos vian konton de uzanto. Ne eblas tion malfari! Ĉu certe vi certas?';

  @override
  String get defaultPermissionLevel => 'Norma nivelo de permesoj';

  @override
  String get delete => 'Forigi';

  @override
  String get deleteAccount => 'Forigi konton';

  @override
  String get deleteMessage => 'Forigi mesaĝon';

  @override
  String get deny => 'Malakcepti';

  @override
  String get device => 'Aparato';

  @override
  String get deviceId => 'Identigilo de aparato';

  @override
  String get devices => 'Aparatoj';

  @override
  String get directChats => 'Rektaj babiloj';

  @override
  String get discover => 'Trovi';

  @override
  String get displaynameHasBeenChanged => 'Prezenta nomo ŝanĝiĝis';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Redakti';

  @override
  String get editBlockedServers => 'Redakti blokitajn servilojn';

  @override
  String get editChatPermissions => 'Redakti permesojn de babilo';

  @override
  String get editDisplayname => 'Redakti prezentan nomon';

  @override
  String get editRoomAliases => 'Ŝanĝi kromnomojn de ĉambro';

  @override
  String get editRoomAvatar => 'Redakti bildon de ĉambro';

  @override
  String get emoteExists => 'Mieneto jam ekzistas!';

  @override
  String get emoteInvalid => 'Nevalida mallongigo de mieneto!';

  @override
  String get emotePacks => 'Mienetaroj por la ĉambro';

  @override
  String get emoteSettings => 'Agordoj pri mienetoj';

  @override
  String get emoteShortcode => 'Mallongigo de mieneto';

  @override
  String get emoteWarnNeedToPick =>
      'Vi devas elekti mallongigon de mieneto kaj bildon!';

  @override
  String get emptyChat => 'Malplena babilo';

  @override
  String get enableEmotesGlobally => 'Ŝalti mienetaron ĉie';

  @override
  String get enableEncryption => 'Ŝalti ĉifradon';

  @override
  String get enableEncryptionWarning =>
      'Vi ne povos malŝalti la ĉifradon. Ĉu vi certas?';

  @override
  String get encrypted => 'Ĉifrite';

  @override
  String get encryption => 'Ĉifrado';

  @override
  String get encryptionNotEnabled => 'Ĉifrado ne estas ŝaltita';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName finis la vokon';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Enigu retpoŝtadreson';

  @override
  String get enterASpacepName => 'Enigi nomon de aro';

  @override
  String get homeserver => 'Hejmservilo';

  @override
  String get enterYourHomeserver => 'Enigu vian hejmservilon';

  @override
  String errorObtainingLocation(Object error) {
    return 'Eraris akirado de loko: $error';
  }

  @override
  String get everythingReady => 'Ĉio pretas!';

  @override
  String get extremeOffensive => 'Tre ofenda';

  @override
  String get fileName => 'Dosiernomo';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Grandeco de tiparo';

  @override
  String get forward => 'Plusendi';

  @override
  String get friday => 'Vendredo';

  @override
  String get fromJoining => 'Ekde aliĝo';

  @override
  String get fromTheInvitation => 'Ekde la invito';

  @override
  String get goToTheNewRoom => 'Iri al la nova ĉambro';

  @override
  String get group => 'Grupo';

  @override
  String get groupDescription => 'Priskribo de grupo';

  @override
  String get groupDescriptionHasBeenChanged => 'Priskribo de grupo ŝanĝiĝis';

  @override
  String get groupIsPublic => 'Grupo estas publika';

  @override
  String get groups => 'Grupoj';

  @override
  String groupWith(Object displayname) {
    return 'Grupo kun $displayname';
  }

  @override
  String get guestsAreForbidden => 'Gastoj estas malpermesitaj';

  @override
  String get guestsCanJoin => 'Gastoj povas aliĝi';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username nuligis la inviton por $targetName';
  }

  @override
  String get help => 'Helpo';

  @override
  String get hideRedactedEvents => 'Kaŝi obskurigitajn eventojn';

  @override
  String get hideUnknownEvents => 'Kaŝi nekonatajn eventojn';

  @override
  String get howOffensiveIsThisContent => 'Kiel ofenda estas ĉi tiu enhavo?';

  @override
  String get id => 'Identigilo';

  @override
  String get identity => 'Identeco';

  @override
  String get ignore => 'Malatenti';

  @override
  String get ignoredUsers => 'Malatentitaj uzantoj';

  @override
  String get ignoreListDescription =>
      'Vi povas malatenti uzantojn, kiuj vin ĝenas. Vi ne povos ricevi mesaĝojn nek invitojn al ĉambroj de la uzantoj sur via listo de malatentatoj.';

  @override
  String get ignoreUsername => 'Malatenti uzantonomon';

  @override
  String get iHaveClickedOnLink => 'Mi klakis la ligilon';

  @override
  String get incorrectPassphraseOrKey => 'Neĝusta pasfrazo aŭ rehava ŝlosilo';

  @override
  String get inoffensive => 'Neofenda';

  @override
  String get inviteContact => 'Inviti kontakton';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Inviti kontakton al $groupName';
  }

  @override
  String get invited => 'Invitita';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username invitis uzanton $targetName';
  }

  @override
  String get invitedUsersOnly => 'Nur invititoj';

  @override
  String get inviteForMe => 'Invito por mi';

  @override
  String inviteText(Object username, Object link) {
    return '$username invitis vin al FluffyChat. \n1. Instalu la aplikaĵon FluffyChat: https://fluffychat.im \n2. Registriĝu aŭ salutu \n3. Malfermu la invitan ligilon: $link';
  }

  @override
  String get isTyping => 'tajpas';

  @override
  String joinedTheChat(Object username) {
    return '$username aliĝis al la babilo';
  }

  @override
  String get joinRoom => 'Aliĝi al ĉambro';

  @override
  String get keysCached => 'Ŝlosiloj estas kaŝmemoritaj';

  @override
  String kicked(Object username, Object targetName) {
    return '$username forpelis uzanton $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username forpelis kaj forbaris uzanton $targetName';
  }

  @override
  String get kickFromChat => 'Forpeli de babilo';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Lastafoje aktiva: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Vidita antaŭ longe';

  @override
  String get leave => 'Foriri';

  @override
  String get leftTheChat => 'Foriris de la ĉambro';

  @override
  String get license => 'Permesilo';

  @override
  String get lightTheme => 'Hela';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Enlegi $count pliajn partoprenantojn';
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
  String get loadingPleaseWait => 'Enlegante… bonvolu atendi.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Enlegi pli…';

  @override
  String get locationDisabledNotice =>
      'Location services are disabled. Please enable them to be able to share your location.';

  @override
  String get locationPermissionDeniedNotice =>
      'Location permission denied. Please grant them to be able to share your location.';

  @override
  String get login => 'Saluti';

  @override
  String logInTo(Object homeserver) {
    return 'Saluti servilon $homeserver';
  }

  @override
  String get loginWithOneClick => 'Sign in with one click';

  @override
  String get logout => 'Adiaŭi';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Certigu, ke la identigilo estas valida';

  @override
  String get memberChanges => 'Ŝanĝoj de anoj';

  @override
  String get mention => 'Mencii';

  @override
  String get messages => 'Mesaĝoj';

  @override
  String get messageWillBeRemovedWarning =>
      'Mesaĝo foriĝos por ĉiuj partoprenantoj';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'Reguligisto';

  @override
  String get monday => 'Lundo';

  @override
  String get muteChat => 'Silentigi babilon';

  @override
  String get needPantalaimonWarning =>
      'Bonvolu scii, ke vi ankoraŭ bezonas la programon Pantalaimon por uzi tutvojan ĉifradon.';

  @override
  String get newChat => 'Nova babilo';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Nova kontrolpeto!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Sekva';

  @override
  String get no => 'Ne';

  @override
  String get noConnectionToTheServer => 'Neniu konekto al la servilo';

  @override
  String get noEmotesFound => 'Neniuj mienetoj troviĝis. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Vi nur povas aktivigi ĉifradon kiam la ĉambro ne plu estas publike alirebla.';

  @override
  String get noGoogleServicesWarning =>
      'Ŝajnas, ke via telefono ne havas servojn de Google. Tio estas bona decido por via privateco! Por ricevadi pasivajn sciigojn en FluffyChat, ni rekomendas, ke vi uzu la https://microg.org/ aŭ https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 ne estas matriksa servilo, eble provu anstataŭe servilon $server2?';
  }

  @override
  String get shareYourInviteLink => 'Share your invite link';

  @override
  String get typeInInviteLinkManually => 'Type in invite link manually...';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String get none => 'Neniu';

  @override
  String get noPasswordRecoveryDescription =>
      'Vi ankoraŭ ne aldonis manieron rehavi vian pasvorton.';

  @override
  String get noPermission => 'Neniu permeso';

  @override
  String get noRoomsFound => 'Neniuj ĉambroj troviĝis…';

  @override
  String get notifications => 'Sciigoj';

  @override
  String numUsersTyping(Object count) {
    return '$count uzantoj tajpas';
  }

  @override
  String get obtainingLocation => 'Akirante lokon…';

  @override
  String get offensive => 'Ofenda';

  @override
  String get offline => 'Eksterrete';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'bone';

  @override
  String get online => 'Enrete';

  @override
  String get onlineKeyBackupEnabled =>
      'Enreta savkopiado de ŝlosiloj estas ŝaltita';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Oj! Bedaŭrinde eraris la agordado de pasivaj sciigoj.';

  @override
  String get oopsSomethingWentWrong => 'Oj! Io misokazis…';

  @override
  String get openAppToReadMessages => 'Malfermu la aplikaĵon por legi mesaĝojn';

  @override
  String get openCamera => 'Malfermi fotilon';

  @override
  String get openVideoCamera => 'Open camera for a video';

  @override
  String get oneClientLoggedOut => 'One of your clients has been logged out';

  @override
  String get addAccount => 'Add account';

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
  String get link => 'Link';

  @override
  String get serverRequiresEmail =>
      'This server needs to validate your email address for registration.';

  @override
  String get optionalGroupName => '(Malnepra) Nomo de grupo';

  @override
  String get or => 'Aŭ';

  @override
  String get participant => 'Partoprenanto';

  @override
  String get passphraseOrKey => 'pasfrazo aŭ rehava ŝlosilo';

  @override
  String get password => 'Pasvorto';

  @override
  String get passwordForgotten => 'Forgesita pasvorto';

  @override
  String get passwordHasBeenChanged => 'Pasvorto ŝanĝiĝis';

  @override
  String get passwordRecovery => 'Rehavo de pasvorto';

  @override
  String get people => 'Personoj';

  @override
  String get pickImage => 'Elekti bildon';

  @override
  String get pin => 'Fiksi';

  @override
  String play(Object fileName) {
    return 'Ludi $fileName';
  }

  @override
  String get pleaseChoose => 'Bonvolu elekti';

  @override
  String get pleaseChooseAPasscode => 'Bonvolu elekti paskodon';

  @override
  String get pleaseChooseAUsername => 'Bonvolu elekti uzantonomon';

  @override
  String get pleaseClickOnLink =>
      'Bonvolu klaki la ligilon en la retletero kaj pluiĝi.';

  @override
  String get pleaseEnter4Digits =>
      'Bonvolu enigi 4 ciferojn, aŭ nenion por malŝalti ŝlosadon de la aplikaĵo.';

  @override
  String get pleaseEnterAMatrixIdentifier =>
      'Bonvolu enigi identigilon de Matrix.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => 'Bonvolu enigi vian pasvorton';

  @override
  String get pleaseEnterYourPin =>
      'Bonvolu enigi vian personan identigan numeron';

  @override
  String get pleaseEnterYourUsername => 'Bonvolu enigi vian uzantonomon';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Bonvolu sekvi la instrukciojn de la retejo kaj tuŝetu al «Sekva».';

  @override
  String get privacy => 'Privateco';

  @override
  String get publicRooms => 'Publikaj ĉambroj';

  @override
  String get pushRules => 'Reguloj de pasivaj sciigoj';

  @override
  String get reason => 'Kialo';

  @override
  String get recording => 'Registrante';

  @override
  String redactedAnEvent(Object username) {
    return '$username obskurigis eventon';
  }

  @override
  String get redactMessage => 'Obskurigi mesaĝon';

  @override
  String get register => 'Registriĝi';

  @override
  String get reject => 'Rifuzi';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username rifuzis la inviton';
  }

  @override
  String get rejoin => 'Ree aliĝi';

  @override
  String get remove => 'Forigi';

  @override
  String get removeAllOtherDevices => 'Forigi ĉiujn aliajn aparatojn';

  @override
  String removedBy(Object username) {
    return 'Forigita de $username';
  }

  @override
  String get removeDevice => 'Forigi aparaton';

  @override
  String get unbanFromChat => 'Malforbari';

  @override
  String get removeYourAvatar => 'Forigi vian profilbildon';

  @override
  String get renderRichContent => 'Bildigi riĉforman enhavon de mesaĝoj';

  @override
  String get replaceRoomWithNewerVersion =>
      'Anstataŭigi ĉambron per nova versio';

  @override
  String get reply => 'Respondi';

  @override
  String get reportMessage => 'Raporti mesaĝon';

  @override
  String get requestPermission => 'Peti permeson';

  @override
  String get roomHasBeenUpgraded => 'Ĉambro gradaltiĝis';

  @override
  String get roomVersion => 'Versio de ĉambro';

  @override
  String get saturday => 'Sabato';

  @override
  String get saveFile => 'Konservi dosieron';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Sekureco';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyLost => 'Recovery key lost?';

  @override
  String seenByUser(Object username) {
    return 'Vidita de $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vidita de $username kaj $count aliaj',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Vidita de $username kaj $username2';
  }

  @override
  String get send => 'Sendi';

  @override
  String get sendAMessage => 'Sendi mesaĝon';

  @override
  String get sendAsText => 'Sendi kiel tekston';

  @override
  String get sendAudio => 'Sendi sondosieron';

  @override
  String get sendFile => 'Sendi dosieron';

  @override
  String get sendImage => 'Sendi bildon';

  @override
  String get sendMessages => 'Sendi mesaĝojn';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Sendi originalon';

  @override
  String get sendSticker => 'Sendi glumarkon';

  @override
  String get sendVideo => 'Sendi filmon';

  @override
  String sentAFile(Object username) {
    return '$username sendis dosieron';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username sendis sondosieron';
  }

  @override
  String sentAPicture(Object username) {
    return '$username sendis bildon';
  }

  @override
  String sentASticker(Object username) {
    return '$username sendis glumarkon';
  }

  @override
  String sentAVideo(Object username) {
    return '$username sendis filmon';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName sendis informojn pri voko';
  }

  @override
  String get separateChatTypes => 'Separate Direct Chats and Groups';

  @override
  String get setAsCanonicalAlias => 'Agordi kiel ĉefan kromnomon';

  @override
  String get setCustomEmotes => 'Agordi proprajn mienetojn';

  @override
  String get setGroupDescription => 'Agordi priskribon de grupo';

  @override
  String get setInvitationLink => 'Agordi invitan ligilon';

  @override
  String get setPermissionsLevel => 'Agordi nivelon de permesoj';

  @override
  String get setStatus => 'Agordi staton';

  @override
  String get settings => 'Agordoj';

  @override
  String get share => 'Konigi';

  @override
  String sharedTheLocation(Object username) {
    return '$username konigis sian lokon';
  }

  @override
  String get shareLocation => 'Konigi lokon';

  @override
  String get showDirectChatsInSpaces => 'Show related Direct Chats in Spaces';

  @override
  String get showPassword => 'Montri pasvorton';

  @override
  String get signUp => 'Registriĝi';

  @override
  String get singlesignon => 'Ununura saluto';

  @override
  String get skip => 'Preterpasi';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Fontkodo';

  @override
  String get spaceIsPublic => 'Aro estas publika';

  @override
  String get spaceName => 'Nomo de aro';

  @override
  String startedACall(Object senderName) {
    return '$senderName komencis vokon';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Stato';

  @override
  String get statusExampleMessage => 'Kiel vi fartas?';

  @override
  String get submit => 'Sendi';

  @override
  String get sunday => 'Dimanĉo';

  @override
  String get synchronizingPleaseWait => 'Spegulante… Bonvolu atendi.';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theyDontMatch => 'Ili ne akordas';

  @override
  String get theyMatch => 'Ili akordas';

  @override
  String get thisRoomHasBeenArchived => 'Ĉi tiu ĉambro arĥiviĝis.';

  @override
  String get thursday => 'Ĵaŭdo';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Baskuli elstarigon';

  @override
  String get toggleMuted => 'Basklui silentigon';

  @override
  String get toggleUnread => 'Baskuli legitecon';

  @override
  String get tooManyRequestsWarning =>
      'Tro multaj petoj. Bonvolu reprovi poste!';

  @override
  String get transferFromAnotherDevice => 'Transporti de alia aparato';

  @override
  String get tryToSendAgain => 'Reprovi sendi';

  @override
  String get tuesday => 'Mardo';

  @override
  String get unavailable => 'Nedisponeble';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username malforbaris uzanton $targetName';
  }

  @override
  String get unblockDevice => 'Malbloki aparaton';

  @override
  String get unknownDevice => 'Nekonata aparato';

  @override
  String get unknownEncryptionAlgorithm => 'Nekonata ĉifra algoritmo';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Nekonata evento «$type»';
  }

  @override
  String get unmuteChat => 'Malsilentigi babilon';

  @override
  String get unpin => 'Malfiksi';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount nelegitaj babiloj',
      one: '1 nelegita babilo',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username kaj $count aliaj tajpas';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username kaj $username2 tajpas';
  }

  @override
  String userIsTyping(Object username) {
    return '$username tajpas';
  }

  @override
  String userLeftTheChat(Object username) {
    return '$username foriris de la babilo';
  }

  @override
  String get username => 'Uzantonomo';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username sendis eventon de speco $type';
  }

  @override
  String get unverified => 'Unverified';

  @override
  String get verified => 'Kontrolita';

  @override
  String get verify => 'Kontroli';

  @override
  String get verifyStart => 'Komenci kontrolon';

  @override
  String get verifySuccess => 'Vi sukcese kontrolis!';

  @override
  String get verifyTitle => 'Kontrolante alian konton';

  @override
  String get videoCall => 'Vidvoko';

  @override
  String get visibilityOfTheChatHistory => 'Videbleco de historio de la babilo';

  @override
  String get visibleForAllParticipants => 'Videbla al ĉiuj partoprenantoj';

  @override
  String get visibleForEveryone => 'Videbla al ĉiuj';

  @override
  String get voiceMessage => 'Voĉmesaĝo';

  @override
  String get waitingPartnerAcceptRequest =>
      'Atendante konfirmon de peto de la kunulo…';

  @override
  String get waitingPartnerEmoji =>
      'Atendante akcepton de la bildosignoj de la kunulo…';

  @override
  String get waitingPartnerNumbers =>
      'Atendante akcepton de la numeroj, de la kunulo…';

  @override
  String get wallpaper => 'Fonbildo';

  @override
  String get warning => 'Averto!';

  @override
  String get wednesday => 'Merkredo';

  @override
  String get weSentYouAnEmail => 'Ni sendis retleteron al vi';

  @override
  String get whoCanPerformWhichAction => 'Kiu povas kion';

  @override
  String get whoIsAllowedToJoinThisGroup => 'Kiu rajtas aliĝi al ĉi tiu grupo';

  @override
  String get whyDoYouWantToReportThis => 'Kial vi volas tion ĉi raporti?';

  @override
  String get wipeChatBackup =>
      'Ĉu forviŝi la savkopion de via babilo por krei novan sekurecan ŝlosilon?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Per tiuj ĉi adresoj vi povas rehavi vian pasvorton.';

  @override
  String get writeAMessage => 'Skribi mesaĝon…';

  @override
  String get yes => 'Jes';

  @override
  String get you => 'Vi';

  @override
  String get youAreInvitedToThisChat => 'Vi estas invitita al ĉi tiu babilo';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Vi ne plu partoprenas ĉi tiun babilon';

  @override
  String get youCannotInviteYourself => 'Vi ne povas inviti vin mem';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Vi estas forbarita de ĉi tiu babilo';

  @override
  String get yourPublicKey => 'Via publika ŝlosilo';

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
  String get search => 'Serĉi';

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
