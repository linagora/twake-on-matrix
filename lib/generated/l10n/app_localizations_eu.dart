// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Basque (`eu`).
class L10nEu extends L10n {
  L10nEu([String locale = 'eu']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Pasahitzak ez datoz bat!';

  @override
  String get pleaseEnterValidEmail => 'Sartu baliozko ePosta helbide bat.';

  @override
  String get repeatPassword => 'Idatzi berriro pasahitza';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Aukeratu gutxienez $min karaktere.';
  }

  @override
  String get about => 'Honi buruz';

  @override
  String get updateAvailable => 'FluffyChaten eguneraketa bat dago';

  @override
  String get updateNow => 'Abiarazi eguneraketa atzeko planoan';

  @override
  String get accept => 'Ados';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username-(e)k gonbidapena onartu du';
  }

  @override
  String get account => 'Kontua';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username(e)k puntuz puntuko zifraketa gaitu du';
  }

  @override
  String get addEmail => 'Gehitu eposta';

  @override
  String get confirmMatrixId => 'Baieztatu zure Matrix IDa kontua ezabatzeko.';

  @override
  String supposedMxid(Object mxid) {
    return 'Hau $mxid izan behar da';
  }

  @override
  String get addGroupDescription => 'Gehitu taldearen deskribapena';

  @override
  String get addToSpace => 'Gehitu gunera';

  @override
  String get admin => 'Administratzailea';

  @override
  String get alias => 'ezizena';

  @override
  String get all => 'Guztia';

  @override
  String get allChats => 'Txat guztiak';

  @override
  String get commandHint_googly => 'Send some googly eyes';

  @override
  String get commandHint_cuddle => 'Send a cuddle';

  @override
  String get commandHint_hug => 'Bidali besarkada';

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
    return '$senderName(e)k besarkatu zaitu';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName(e)k deia erantzun du';
  }

  @override
  String get anyoneCanJoin => 'Edonork egin dezake bat';

  @override
  String get appLock => 'Blokeatu aplikazioa';

  @override
  String get archive => 'Artxibatu';

  @override
  String get archivedRoom => 'Artxibatutako gela';

  @override
  String get areGuestsAllowedToJoin =>
      'Ba al dute gonbidatutako erabiltzaileek bat egiteko baimenik?';

  @override
  String get areYouSure => 'Ziur al zaude?';

  @override
  String get areYouSureYouWantToLogout =>
      'Ziur zaude saioa amaitu nahi duzula?';

  @override
  String get askSSSSSign =>
      'Beste pertsona ziurtatzeko, sartu zure biltegiratze segururako pasaesaldia edo berreskuratze gakoa.';

  @override
  String askVerificationRequest(Object username) {
    return '$username(r)en egiaztatze eskaera onartu?';
  }

  @override
  String get autoplayImages =>
      'Automatikoki abiarazi sticker eta emote animatuak';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Zerbitzariak ondorengo aukerak ditu saioa hasteko:\n$serverVersions\nBaina aplikazioak hauek onartzen ditu:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Bidali enter sakatuz';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Zerbitzariak ondorengo ezaugarriak onartzen ditu:\n$serverVersions\nBaina aplikazioak hauek baino ez: $supportedVersions';
  }

  @override
  String get banFromChat => 'Berriketa debekatu';

  @override
  String get banned => 'Debekatuta';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username(e)k $targetName debekatu du';
  }

  @override
  String get blockDevice => 'Blokeatu gailua';

  @override
  String get blocked => 'Blokeatuta';

  @override
  String get botMessages => 'Boten mezuak';

  @override
  String get bubbleSize => 'Puxiken tamaina';

  @override
  String get cancel => 'Utzi';

  @override
  String cantOpenUri(Object uri) {
    return 'Ezin da $uri URIa ireki';
  }

  @override
  String get changeDeviceName => 'Aldatu gailuaren izena';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username(e)k berriketako abatarra aldatu du';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username(e)k txataren deskribapena aldatu du: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username(e)k berriketaren izena \'$chatname\'-(e)ra aldatu du';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username(e)k berriketaren baimenak aldatu ditu';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username(e)k bere izena aldatu du. Aurrerantzean \'$displayname\' izango da';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username(e)k gonbidatuen sarbide-arauak aldatu ditu';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username(e)k gonbidatuen arauak aldatu ditu: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username(e)k historiaren ikusgarritasuna aldatu du';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username(e)k historiaren ikusgarritasuna $rules-(e)ra aldatu du';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username(e)k batze arauak aldatu ditu';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username(e)k batzeko arauak $joinRules-(e)ra aldatu ditu';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username(e)k profileko abatarra aldatu du';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username(e)k gelaren ezizena aldatu du';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username(e)k gonbidapen esteka aldatu du';
  }

  @override
  String get changePassword => 'Aldatu pasahitza';

  @override
  String get changeTheHomeserver => 'Aldatu zerbitzaria';

  @override
  String get changeTheme => 'Aldatu itxura';

  @override
  String get changeTheNameOfTheGroup => 'Aldatu taldearen izena';

  @override
  String get changeWallpaper => 'Aldatu atzekaldea';

  @override
  String get changeYourAvatar => 'Aldatu abatarra';

  @override
  String get channelCorruptedDecryptError => 'Zifraketa hondatu egin da';

  @override
  String get chat => 'Berriketa';

  @override
  String get yourUserId => 'Zure erabiltzaile IDa:';

  @override
  String get yourChatBackupHasBeenSetUp => 'Txaten babeskopiak ezarri dira.';

  @override
  String get chatBackup => 'Txataren babeskopia';

  @override
  String get chatBackupDescription =>
      'Txat zaharrak berreskuratze-gako batekin daude babestuta. Ez galdu gako hori.';

  @override
  String get chatDetails => 'Berriketaren xehetasunak';

  @override
  String get chatHasBeenAddedToThisSpace => 'Berriketa gune honetara gehitu da';

  @override
  String get chats => 'Berriketak';

  @override
  String get chooseAStrongPassword => 'Aukeratu pasahitz sendo bat';

  @override
  String get chooseAUsername => 'Aukeratu erabiltzaile izen bat';

  @override
  String get clearArchive => 'Ezabatu artxiboa';

  @override
  String get close => 'Itxi';

  @override
  String get commandHint_markasdm => 'Markatu mezu-zuzen gela bezala';

  @override
  String get commandHint_markasgroup => 'Markatu talde bezala';

  @override
  String get commandHint_ban => 'Debekatu erabiltzailea gela honetan';

  @override
  String get commandHint_clearcache => 'Ezabatu cachea';

  @override
  String get commandHint_create =>
      'Sortu taldeko-gela huts bat\nErabili --no-encyption zifratzea desgaitzeko';

  @override
  String get commandHint_discardsession => 'Baztertu saioa';

  @override
  String get commandHint_dm =>
      'Hasi berriketa bat\nErabili --no-encryption zifratzea desgaitu nahi baduzu';

  @override
  String get commandHint_html => 'Bidali testua HTML formatuan';

  @override
  String get commandHint_invite => 'Gonbidatu erabiltzailea gela honetara';

  @override
  String get commandHint_join => 'Batu gela horretara';

  @override
  String get commandHint_kick => 'Kendu erabiltzaile hori gela honetatik';

  @override
  String get commandHint_leave => 'Utzi gela hau';

  @override
  String get commandHint_me => 'Deskribatu zure burua';

  @override
  String get commandHint_myroomavatar =>
      'Ezarri zure irudia gela honetarako (mxc-uri bidez)';

  @override
  String get commandHint_myroomnick => 'Ezarri zure izengoitia gela honetarako';

  @override
  String get commandHint_op =>
      'Zehaztu erabiltzaile honen botere-maila (lehenetsia: 50)';

  @override
  String get commandHint_plain => 'Bidali formaturik gabeko testua';

  @override
  String get commandHint_react => 'Bidali erantzuna erreakzioa bailitzan';

  @override
  String get commandHint_send => 'Bidali testua';

  @override
  String get commandHint_unban => 'Baimendu erabiltzailea gela honetan';

  @override
  String get commandInvalid => 'Komandoa ez da baliozkoa';

  @override
  String commandMissing(Object command) {
    return '$command ez da komandoa.';
  }

  @override
  String get compareEmojiMatch =>
      'Konparatu eta egiaztatu ondorengo emojiak beste gailukoarekin bat datozela:';

  @override
  String get compareNumbersMatch =>
      'Konparatu eta egiaztatu ondorengo zenbakiak beste gailukoarekin bat datozela:';

  @override
  String get configureChat => 'Konfiguratu berriketa';

  @override
  String get confirm => 'Baieztatu';

  @override
  String get connect => 'Konektatu';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'Kontaktua taldera gonbidatua izan da';

  @override
  String get containsDisplayName => 'Pantaila-izena dauka';

  @override
  String get containsUserName => 'Erabiltzaile izena dauka';

  @override
  String get contentHasBeenReported =>
      'Edukia zerbitzariko administrariei jakinarazi zaie';

  @override
  String get copiedToClipboard => 'Arbelera kopiatua';

  @override
  String get copy => 'Kopiatu';

  @override
  String get copyToClipboard => 'Kopiatu arbelera';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Ezin izan da mezua deszifratu: $error';
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
  String get create => 'Sortu';

  @override
  String createdTheChat(Object username) {
    return '💬 $username(e)k berriketa sortu du';
  }

  @override
  String get createNewGroup => 'Sortu talde berria';

  @override
  String get createNewSpace => 'Gune berria';

  @override
  String get crossSigningEnabled => 'Zeharkako sinadura gaituta dago';

  @override
  String get currentlyActive => 'Unean aktibo';

  @override
  String get darkTheme => 'Iluna';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$month/$day';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$year/$month/$day';
  }

  @override
  String get deactivateAccountWarning =>
      'Honek zure kontua desaktibatuko du. Ezin da desegin! Ziur zaude?';

  @override
  String get defaultPermissionLevel => 'Defektuzko botere-maila';

  @override
  String get delete => 'Ezabatu';

  @override
  String get deleteAccount => 'Ezabatu kontua';

  @override
  String get deleteMessage => 'Ezabatu mezua';

  @override
  String get deny => 'Ukatu';

  @override
  String get device => 'Gailua';

  @override
  String get deviceId => 'Gailuaren IDa';

  @override
  String get devices => 'Gailuak';

  @override
  String get directChats => 'Berriketa zuzenak';

  @override
  String get discover => 'Deskubritu';

  @override
  String get displaynameHasBeenChanged => 'Pantaila-izena aldatu da';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Editatu';

  @override
  String get editBlockedServers => 'Editatu blokeatutako zerbitzariak';

  @override
  String get editChatPermissions => 'Editatu berriketa-baimenak';

  @override
  String get editDisplayname => 'Editatu ezizena';

  @override
  String get editRoomAliases => 'Editatu gelako goitizenak';

  @override
  String get editRoomAvatar => 'Editatu gelaren abatarra';

  @override
  String get emoteExists => 'Emotea badago lehendik ere!';

  @override
  String get emoteInvalid => 'Emotearen laburdura ez da baliozkoa!';

  @override
  String get emotePacks => 'Emote sortak gelarako';

  @override
  String get emoteSettings => 'Emote ezarpenak';

  @override
  String get emoteShortcode => 'Emote laburdurak';

  @override
  String get emoteWarnNeedToPick =>
      'Emote laburdura eta irudi bat aukeratu behar dituzu!';

  @override
  String get emptyChat => 'Hutsik dago';

  @override
  String get enableEmotesGlobally => 'Gaitu emote sorta berriketa guztietarako';

  @override
  String get enableEncryption => 'Gaitu zifraketa';

  @override
  String get enableEncryptionWarning =>
      'Ezingo duzu zifraketa desgaitu. Ziur zaude?';

  @override
  String get encrypted => 'Zifratuta';

  @override
  String get encryption => 'Zifraketa';

  @override
  String get encryptionNotEnabled => 'Zifraketa ez dago gaituta';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName(e)k deia amaitu du';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Sartu helbide elektroniko bat';

  @override
  String get enterASpacepName => 'Sartu gunerako izena';

  @override
  String get homeserver => 'Zerbitzaria';

  @override
  String get enterYourHomeserver => 'Sartu zure zerbitzaria';

  @override
  String errorObtainingLocation(Object error) {
    return 'Errorea kokapena lortzerakoan: $error';
  }

  @override
  String get everythingReady => 'Dena prest!';

  @override
  String get extremeOffensive => 'Izugarri iraingarria';

  @override
  String get fileName => 'Fitxategiaren izena';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Letraren tamaina';

  @override
  String get forward => 'Berbidali';

  @override
  String get friday => 'Ostirala';

  @override
  String get fromJoining => 'sartzeaz';

  @override
  String get fromTheInvitation => 'gonbidapenaz';

  @override
  String get goToTheNewRoom => 'Joan gela berrira';

  @override
  String get group => 'Taldea';

  @override
  String get groupDescription => 'Taldearen deskribapena';

  @override
  String get groupDescriptionHasBeenChanged =>
      'Taldearen deskribapena aldatu da';

  @override
  String get groupIsPublic => 'Taldea publikoa da';

  @override
  String get groups => 'Taldeak';

  @override
  String groupWith(Object displayname) {
    return '$displayname duen taldea';
  }

  @override
  String get guestsAreForbidden => 'Gonbidatuak debekatuta daude';

  @override
  String get guestsCanJoin => 'Gonbidatuak batu daitezke';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username(e)k $targetName(r)en gonbidapena baliogabetu du';
  }

  @override
  String get help => 'Laguntza';

  @override
  String get hideRedactedEvents => 'Izkutatu ezabatutako gertaerak';

  @override
  String get hideUnknownEvents => 'Izkutatu gertaera ezezagunak';

  @override
  String get howOffensiveIsThisContent =>
      'Zenbaterainoko iraingarria da eduki hau?';

  @override
  String get id => 'IDa';

  @override
  String get identity => 'Nortasuna';

  @override
  String get ignore => 'Ezikusi';

  @override
  String get ignoredUsers => 'Ez ikusia egindako erabiltzaileak';

  @override
  String get ignoreListDescription =>
      'Molestatzen zaituzten erabiltzaileak ezikusi ditzakezu. Ez duzu ezikusitako pertsonen zerrendan daudenen mezurik edota gonbidapenik jasoko.';

  @override
  String get ignoreUsername => 'Ezikusi erabiltzailea';

  @override
  String get iHaveClickedOnLink => 'Estekan sakatu dut';

  @override
  String get incorrectPassphraseOrKey =>
      'Pasaesaldi edo segurtasun gakoa ez da zuzena';

  @override
  String get inoffensive => 'Ez da iraingarria';

  @override
  String get inviteContact => 'Gonbidatu kontaktua';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Gonbidatu kontaktua $groupName(e)ra';
  }

  @override
  String get invited => 'Gonbidatuta';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username(e)k $targetName gonbidatu du';
  }

  @override
  String get invitedUsersOnly => 'Gonbidatutako erabiltzaileak solik';

  @override
  String get inviteForMe => 'Niretzako gonbidapenak';

  @override
  String inviteText(Object username, Object link) {
    return '$username(e)k FluffyChatera gonbidatu zaitu.\n1. Instalatu FluffyChat: https://fluffychat.im\n2. Eman izena edo hasi saioa\n3. Ireki gonbidapen esteka: $link';
  }

  @override
  String get isTyping => 'idazten ari da';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username berriketara batu da';
  }

  @override
  String get joinRoom => 'Batu gelara';

  @override
  String get keysCached => 'Gakoak katxean daude';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username(e)k $targetName kaleratu du';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username(e)k $targetName kaleratu eta debekua ezarri dio';
  }

  @override
  String get kickFromChat => 'Kaleratu berriketatik';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Azkenekoz aktibo: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Duela denbora luze';

  @override
  String get leave => 'Irten';

  @override
  String get leftTheChat => 'Berriketatik irten da';

  @override
  String get license => 'Lizentzia';

  @override
  String get lightTheme => 'Argia';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Kargatu $count partehartzaile gehiago';
  }

  @override
  String get dehydrate => 'Esportatu saioa eta ezabatu gailua';

  @override
  String get dehydrateWarning =>
      'Ekintza hau ezin da desegin. Egiaztatu babeskopia toki seguruan gorde duzula.';

  @override
  String get dehydrateShare =>
      'Hau zure FluffyChaten esportazio pribatua da. Ez galdu eta ez partekatu inorekin.';

  @override
  String get dehydrateTor => 'TOR Erabiltzaileak: Esportatu saioa';

  @override
  String get dehydrateTorLong =>
      'TOR erabiltzaileentzat gomendioa leihoa itxi baino lehen saioa esportatzea da.';

  @override
  String get hydrateTor => 'TOR Erabiltzaileak: Inportatu esportatutako saioa';

  @override
  String get hydrateTorLong =>
      'Esportatu al zenuen zure saioa TOR erabili zenuen azken aldian? Inportatu segidan eta jarraitu txateatzen.';

  @override
  String get hydrate => 'Berreskuratu babeskopia bat erabiliz';

  @override
  String get loadingPleaseWait => 'Kargatzen… itxaron.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Kargatu gehiago…';

  @override
  String get locationDisabledNotice =>
      'Kokapen zerbitzuak ez daude gaituta. Gaitu zure kokapena partekatu ahal izateko.';

  @override
  String get locationPermissionDeniedNotice =>
      'Kokapen baimena ukatu da. Eman ezazu zure kokapena partekatzeko baimena.';

  @override
  String get login => 'Hasi saioa';

  @override
  String logInTo(Object homeserver) {
    return 'Hasi saioa $homeserver(e)n';
  }

  @override
  String get loginWithOneClick => 'Hasi saioa klik bakarrarekin';

  @override
  String get logout => 'Amaitu saioa';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Egiaztatu identifikazioa baliozkoa dela';

  @override
  String get memberChanges => 'Kideen aldaketak';

  @override
  String get mention => 'Aipamena';

  @override
  String get messages => 'Mezuak';

  @override
  String get messageWillBeRemovedWarning =>
      'Mezua partehartzaile guztientzat ezabatuko da';

  @override
  String get noSearchResult => 'Ez da emaitzarik aurkitu.';

  @override
  String get moderator => 'Moderatzailea';

  @override
  String get monday => 'Astelehena';

  @override
  String get muteChat => 'Mututu berriketa';

  @override
  String get needPantalaimonWarning =>
      'Kontuan izan oraingoz Pantalaimon behar duzula puntuz puntuko zifraketarako.';

  @override
  String get newChat => 'Berriketa berria';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Egiaztaketa eskaera berria!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Hurrengoa';

  @override
  String get no => 'Ez';

  @override
  String get noConnectionToTheServer => 'Ez dago konexiorik zerbitzariarekin';

  @override
  String get noEmotesFound => 'Ez da emoterik aurkitu. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Zifraketa aktiba dezakezu soilik gela publikoa ez bada.';

  @override
  String get noGoogleServicesWarning =>
      'Dirudienez ez daukazu Googleren zerbitzurik zure mugikorrean. Primerako erabakia zure pribatutasunerako! FluffyChaten jakinarazpenak jasotzeko https://microg.org/ edo https://unifiedpush.org/ erabiltzea gomendatzen dugu.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 ez da matrix zerbitzari bat, $server2 erabili nahi duzu haren ordez?';
  }

  @override
  String get shareYourInviteLink => 'Partekatu gonbidapen esteka';

  @override
  String get typeInInviteLinkManually => 'Idatzi eskuz gonbidapen esteka…';

  @override
  String get scanQrCode => 'Eskaneatu QR kodea';

  @override
  String get none => 'Bat ere ez';

  @override
  String get noPasswordRecoveryDescription =>
      'Oraindik ez duzu pasahitza berreskuratzeko modurik gehitu.';

  @override
  String get noPermission => 'Baimenik ez';

  @override
  String get noRoomsFound => 'Ez da gelarik aurkitu…';

  @override
  String get notifications => 'Jakinarazpenak';

  @override
  String numUsersTyping(Object count) {
    return '$count erabiltzaile idazten ari dira';
  }

  @override
  String get obtainingLocation => 'Kokapena atzitzen…';

  @override
  String get offensive => 'Iraingarria';

  @override
  String get offline => 'Lineaz kanpo';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'Ados';

  @override
  String get online => 'Linean';

  @override
  String get onlineKeyBackupEnabled => 'Gakoen online babeskopia gaituta dago';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Hara! Zoritxarrez, errore bat gertatu da jakinarazpenak ezartzerakoan.';

  @override
  String get oopsSomethingWentWrong => 'Hara, zerbaitek huts egin du…';

  @override
  String get openAppToReadMessages => 'Ireki aplikazioa mezuak irakurtzeko';

  @override
  String get openCamera => 'Ireki kamera';

  @override
  String get openVideoCamera => 'Ireki kamera bideorako';

  @override
  String get oneClientLoggedOut => 'Zure gailuetako batek saioa itxi du';

  @override
  String get addAccount => 'Gehitu kontua';

  @override
  String get editBundlesForAccount => 'Moldatu kontu honetarako sortak';

  @override
  String get addToBundle => 'Gehitu sortara';

  @override
  String get removeFromBundle => 'Kendu sorta honetatik';

  @override
  String get bundleName => 'Sortaren izena';

  @override
  String get enableMultiAccounts =>
      '(BETA) Gaitu kontu bat baino gehiago gailu honetan';

  @override
  String get openInMaps => 'Ireki mapen aplikazioan';

  @override
  String get link => 'Esteka';

  @override
  String get serverRequiresEmail =>
      'Zerbitzari honek zure posta elektronikoa egiaztatu behar du izena eman dezazun.';

  @override
  String get optionalGroupName => '(Hautazkoa) Taldearen izena';

  @override
  String get or => 'Edo';

  @override
  String get participant => 'Partehartzailea';

  @override
  String get passphraseOrKey => 'pasaesaldia edo berreskuratzeko gakoa';

  @override
  String get password => 'Pasahitza';

  @override
  String get passwordForgotten => 'Ahaztu zait pasahitza';

  @override
  String get passwordHasBeenChanged => 'Pasahitza aldatu da';

  @override
  String get passwordRecovery => 'Pasahitzaren berreskurapena';

  @override
  String get people => 'Jendea';

  @override
  String get pickImage => 'Aukeratu irudi bat';

  @override
  String get pin => 'Iltzatu';

  @override
  String play(Object fileName) {
    return 'Abiarazi $fileName';
  }

  @override
  String get pleaseChoose => 'Aukeratu';

  @override
  String get pleaseChooseAPasscode => 'Aukeratu kode bat';

  @override
  String get pleaseChooseAUsername => 'Aukeratu erabiltzaile-izen bat';

  @override
  String get pleaseClickOnLink =>
      'Sakatu epostako estekan eta ondoren jarraitu.';

  @override
  String get pleaseEnter4Digits =>
      'Sartu lau zenbaki edo utzi hutsik aplikazioa babestu nahi ez baduzu.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Sartu Matrix ID bat.';

  @override
  String get pleaseEnterRecoveryKey => 'Idatzi berreskuratze-gakoa:';

  @override
  String get pleaseEnterYourPassword => 'Sartu zure pasahitza';

  @override
  String get pleaseEnterYourPin => 'Sartu zure zenbakia';

  @override
  String get pleaseEnterYourUsername => 'Sartu zure erabiltzaile-izena';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Jarrai itzazu webguneko argibideak eta sakatu \'Hurrengoa\'.';

  @override
  String get privacy => 'Pribatutasuna';

  @override
  String get publicRooms => 'Gela publikoak';

  @override
  String get pushRules => 'Push arauak';

  @override
  String get reason => 'Zergatia';

  @override
  String get recording => 'Grabatzen';

  @override
  String redactedAnEvent(Object username) {
    return '$username(e)k gertaera bat izkutatu du';
  }

  @override
  String get redactMessage => 'Izkutatu mezua';

  @override
  String get register => 'Eman izena';

  @override
  String get reject => 'Baztertu';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username(e)k gonbidapena baztertu du';
  }

  @override
  String get rejoin => 'Batu berriro';

  @override
  String get remove => 'Kendu';

  @override
  String get removeAllOtherDevices => 'Kendu gainerako gailu guztiak';

  @override
  String removedBy(Object username) {
    return '$username(e)k kendu du';
  }

  @override
  String get removeDevice => 'Kendu gailua';

  @override
  String get unbanFromChat => 'Baimendu berriketan';

  @override
  String get removeYourAvatar => 'Kendu zure abatarra';

  @override
  String get renderRichContent => 'Kargatu mezu aberatseko edukia';

  @override
  String get replaceRoomWithNewerVersion =>
      'Ordezkatu gela bertsio berriago batekin';

  @override
  String get reply => 'Erantzun';

  @override
  String get reportMessage => 'Salatu mezua';

  @override
  String get requestPermission => 'Eskatu baimena';

  @override
  String get roomHasBeenUpgraded => 'Gela bertsio-berritu da';

  @override
  String get roomVersion => 'Gelaren bertsioa';

  @override
  String get saturday => 'Larunbata';

  @override
  String get saveFile => 'Gorde fitxategia';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Segurtasuna';

  @override
  String get recoveryKey => 'Berreskuratze-gakoa';

  @override
  String get recoveryKeyLost => 'Berreskuratze-gakoa galdu al duzu?';

  @override
  String seenByUser(Object username) {
    return '$username(e)k ikusi du';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$username(e)k eta beste $count(e)k ikusi dute',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return '$username(e)k eta $username2(e)k ikusi dute';
  }

  @override
  String get send => 'Bidali';

  @override
  String get sendAMessage => 'Bidali mezua';

  @override
  String get sendAsText => 'Bidali testu bezala';

  @override
  String get sendAudio => 'Bidali audioa';

  @override
  String get sendFile => 'Bidali fitxategia';

  @override
  String get sendImage => 'Bidali irudia';

  @override
  String get sendMessages => 'Bidali mezuak';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Bidali jatorrizkoa';

  @override
  String get sendSticker => 'Bidali stickerra';

  @override
  String get sendVideo => 'Bidali bideoa';

  @override
  String sentAFile(Object username) {
    return '📁 $username(e)k fitxategia bidali du';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username(e)k audioa bidali du';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username(e)k irudia bidali du';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username(e)k stickerra bidali du';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username(e)k bideoa bidali du';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName(e)k deiaren informazioa bidali du';
  }

  @override
  String get separateChatTypes => 'Bereizi zuzeneko mezuak eta taldeak';

  @override
  String get setAsCanonicalAlias => 'Ezarri goitizen nagusi bezala';

  @override
  String get setCustomEmotes => 'Ezarri neurrira egindako emoteak';

  @override
  String get setGroupDescription => 'Ezarri taldeko deskribapena';

  @override
  String get setInvitationLink => 'Ezarri gonbidapen esteka';

  @override
  String get setPermissionsLevel => 'Ezarri baimen maila';

  @override
  String get setStatus => 'Ezarri egoera';

  @override
  String get settings => 'Ezarpenak';

  @override
  String get share => 'Partekatu';

  @override
  String sharedTheLocation(Object username) {
    return '$username(e)k kokapena partekatu du';
  }

  @override
  String get shareLocation => 'Partekatu kokapena';

  @override
  String get showDirectChatsInSpaces =>
      'Erakutsi zerikusia duten Mezu Zuzenak guneetan';

  @override
  String get showPassword => 'Erakutsi pasahitza';

  @override
  String get signUp => 'Eman izena';

  @override
  String get singlesignon => 'Single Sign on';

  @override
  String get skip => 'Saltatu';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Iturburu kodea';

  @override
  String get spaceIsPublic => 'Gunea publikoa da';

  @override
  String get spaceName => 'Gunearen izena';

  @override
  String startedACall(Object senderName) {
    return '$senderName(e)k deia hasi du';
  }

  @override
  String get startFirstChat => 'Hasi zure lehen txata';

  @override
  String get status => 'Egoera';

  @override
  String get statusExampleMessage => 'Zer moduz zaude gaur?';

  @override
  String get submit => 'Bidali';

  @override
  String get sunday => 'Igandea';

  @override
  String get synchronizingPleaseWait => 'Sinkronizatzen… itxaron.';

  @override
  String get systemTheme => 'Sistemak darabilena';

  @override
  String get theyDontMatch => 'Ez datoz bat';

  @override
  String get theyMatch => 'Bat datoz';

  @override
  String get thisRoomHasBeenArchived => 'Gela hau artxibatu da.';

  @override
  String get thursday => 'Osteguna';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Ikusi / Ezkutatu gogokoak';

  @override
  String get toggleMuted => 'Ikusi / Ezkutatu mutututakoak';

  @override
  String get toggleUnread => 'Markatu irakurrita / irakurri gabe gisa';

  @override
  String get tooManyRequestsWarning =>
      'Eskaera gehiegi. Saiatu berriro geroago!';

  @override
  String get transferFromAnotherDevice => 'Beste gailu batetik transferitu';

  @override
  String get tryToSendAgain => 'Saiatu berriro bidaltzen';

  @override
  String get tuesday => 'Asteartea';

  @override
  String get unavailable => 'Ez dago eskuragai';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username(e)k $targetName baimendu du';
  }

  @override
  String get unblockDevice => 'Desblokeatu gailua';

  @override
  String get unknownDevice => 'Gailu ezezaguna';

  @override
  String get unknownEncryptionAlgorithm => 'Zifraketa-algoritmo ezezaguna';

  @override
  String unknownEvent(Object type, Object tipo) {
    return '\'$type\' gertaera ezezaguna';
  }

  @override
  String get unmuteChat => 'Utzi txata mututzeari';

  @override
  String get unpin => 'Kendu iltzea';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount txat irakurri gabe',
      one: 'irakurri gabeko txat 1',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username eta beste $count idazten ari dira';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username eta $username2 idazten ari dira';
  }

  @override
  String userIsTyping(Object username) {
    return '$username idazten ari da…';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username berriketatik irten da';
  }

  @override
  String get username => 'Erabiltzaile-izena';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username(e)k $type gertaera bat bidali du';
  }

  @override
  String get unverified => 'Egiaztatu gabe';

  @override
  String get verified => 'Egiaztatuta';

  @override
  String get verify => 'Egiaztatu';

  @override
  String get verifyStart => 'Abiarazi egiaztaketa';

  @override
  String get verifySuccess => 'Ondo egiaztatu duzu!';

  @override
  String get verifyTitle => 'Beste kontua egiaztatzen';

  @override
  String get videoCall => 'Bideo-deia';

  @override
  String get visibilityOfTheChatHistory =>
      'Berriketa-historiaren ikusgarritasuna';

  @override
  String get visibleForAllParticipants => 'Partehartzaile guztientzat ikusgai';

  @override
  String get visibleForEveryone => 'Edonorentzat ikusgai';

  @override
  String get voiceMessage => 'Ahozko mezua';

  @override
  String get waitingPartnerAcceptRequest =>
      'Bikotearen zain eskaera onartu dezan…';

  @override
  String get waitingPartnerEmoji => 'Bikotearen zain emojia onartu dezan…';

  @override
  String get waitingPartnerNumbers =>
      'Bikotearen zain zenbakiak onartu ditzan…';

  @override
  String get wallpaper => 'Horma-irudia';

  @override
  String get warning => 'Kontuz!';

  @override
  String get wednesday => 'Asteazkena';

  @override
  String get weSentYouAnEmail => 'ePosta bat bidali dizugu';

  @override
  String get whoCanPerformWhichAction => 'Nork egin dezakeen zer';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Nork duen baimena talde honetara batzeko';

  @override
  String get whyDoYouWantToReportThis => 'Zergatik salatu nahi duzu?';

  @override
  String get wipeChatBackup =>
      'Ezabatu txataren babeskopia berreskuratze-gako berria sortzeko?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Helbide hauekin pasahitza berreskuratu dezakezu.';

  @override
  String get writeAMessage => 'Idatzi mezua…';

  @override
  String get yes => 'Bai';

  @override
  String get you => 'Zeu';

  @override
  String get youAreInvitedToThisChat => 'Berriketa honetara gonbidatu zaituzte';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Ez duzu berriketa honetan parte hartzen honezkero';

  @override
  String get youCannotInviteYourself => 'Ezin duzu zure burua gonbidatu';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Berriketa honetan debekatu zaituzte';

  @override
  String get yourPublicKey => 'Zure gako publikoa';

  @override
  String get messageInfo => 'Mezuaren xehetasunak';

  @override
  String get time => 'Ordua';

  @override
  String get messageType => 'Mezu mota';

  @override
  String get sender => 'Igorlea';

  @override
  String get openGallery => 'Ireki galeria';

  @override
  String get removeFromSpace => 'Kendu gunetik';

  @override
  String get addToSpaceDescription =>
      'Aukeratu gune bat berriketa hau gehitzeko.';

  @override
  String get start => 'Hasi';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Mezu zaharrak ikusi ahal izateko, sartu aurreko saioan sortu zen berreskuratze-gakoa. Berreskuratze-gakoa EZ da zure pasahitza.';

  @override
  String get addToStory => 'Gehitu storyra';

  @override
  String get publish => 'Argitaratu';

  @override
  String get whoCanSeeMyStories => 'Nork ikus ditzazke nire storyak?';

  @override
  String get unsubscribeStories => 'Storyak jasotzeari utzi';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Erabiltzaile honek oraindik ez du ezer argitaratu bere storyetan';

  @override
  String get yourStory => 'Zure storya';

  @override
  String get replyHasBeenSent => 'Erantzuna bidali da';

  @override
  String videoWithSize(Object size) {
    return 'Bideoa ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return '${date}ko storya:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Kontuan izan jendeak bata bestea ikusi eta harremanetan jar daitekeela zure storyan.';

  @override
  String get whatIsGoingOn => 'Zertan zabiltza?';

  @override
  String get addDescription => 'Gehitu deskribapena';

  @override
  String get storyPrivacyWarning =>
      'Kontuan izan jendeak bata bestea ikus dezakeela eta bata bestearekin harremanetan jar daitekeela. Zure storya 24 orduz egongo da ikusgai baina ezin da ziurtatu gailu eta zerbitzari guztietatik ezabatuko denik denbora pasatakoan.';

  @override
  String get iUnderstand => 'Ulertzen dut';

  @override
  String get openChat => 'Ireki berriketa';

  @override
  String get markAsRead => 'Markatu irakurrita gisa';

  @override
  String get reportUser => 'Salatu erabiltzailea';

  @override
  String get dismiss => 'Baztertu';

  @override
  String get matrixWidgets => 'Matrixen widgetak';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender(e)k $reaction(r)ekin erreakzionatu du';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin =>
      'Ziur zaude gertaerari iltzea kendu nahi diozula?';

  @override
  String get emojis => 'Emojiak';

  @override
  String get placeCall => 'Egin deia';

  @override
  String get voiceCall => 'Ahozko deia';

  @override
  String get unsupportedAndroidVersion => 'Android bertsioa ez da bateragarria';

  @override
  String get unsupportedAndroidVersionLong =>
      'Funtzio honek Android bertsio berriago bat behar du. Egiaztatu eguneraketak ote dauden edo begiratu Lineage OS-ek zure gailuarentzat aukerarik eskaintzen duen.';

  @override
  String get videoCallsBetaWarning =>
      'Kontuan izan bideo deiak beta fasean daudela. Litekeena da behar bezala erabili ezin izatea —erabili ahal badira—.';

  @override
  String get experimentalVideoCalls => 'Bideo-dei esperimentalak';

  @override
  String get emailOrUsername => 'ePosta edo erabiltzaile-izena';

  @override
  String get indexedDbErrorTitle => 'Modu pribatuaren arazoak';

  @override
  String get indexedDbErrorLong =>
      'Mezuen artxibatzea ez dago defektuz gaituta modu pribatua erabiltzean.\nGaitzeko:\n - about:config\n - dom.indexedDB.privateBrowsing.enabled aukerak true erakutsi dezala\nBestela ezin da FluffyChat erabili.';

  @override
  String switchToAccount(Object number) {
    return 'Aldatu $number kontura';
  }

  @override
  String get nextAccount => 'Hurrengo kontua';

  @override
  String get previousAccount => 'Aurreko kontua';

  @override
  String get editWidgets => 'Editatu widgetak';

  @override
  String get addWidget => 'Gehitu widgeta';

  @override
  String get widgetVideo => 'Bideoa';

  @override
  String get widgetEtherpad => 'Testu-oharra';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Neurrira egindakoa';

  @override
  String get widgetName => 'Izena';

  @override
  String get widgetUrlError => 'Ez da baliozko URL bat.';

  @override
  String get widgetNameError => 'Zehaztu goitizen bat.';

  @override
  String get errorAddingWidget => 'Errorea widgeta gehitzerakoan.';

  @override
  String get youRejectedTheInvitation => 'Gonbidapena baztertu duzu';

  @override
  String get youJoinedTheChat => 'Berriketara batu zara';

  @override
  String get youAcceptedTheInvitation => '👍 Gonbidapena onartu duzu';

  @override
  String youBannedUser(Object user) {
    return '$user(r)i debekua ezarri diozu';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return '$user(r)i luzatutako gonbidapena baliogabetu duzu';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 $user(e)k gonbidatu zaitu';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 $user gonbidatu duzu';
  }

  @override
  String youKicked(Object user) {
    return '👞 $user kanporatu duzu';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 $user kanporatu eta debekua ezarri diozu';
  }

  @override
  String youUnbannedUser(Object user) {
    return '$user(r)i debekua kendu diozu';
  }

  @override
  String get noEmailWarning =>
      'Sartu baliozko posta helbide bat. Bestela ezingo duzu pasahitza berrezarri. Hala ere nahi ez baduzu, sakatu berriro botoia aurrera egiteko.';

  @override
  String get stories => 'Storyak';

  @override
  String get users => 'Erabiltzaileak';

  @override
  String get enableAutoBackups => 'Gaitu babeskopia automatikoak';

  @override
  String get unlockOldMessages => 'Desblokeatu mezu zaharrak';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription =>
      'Gorde berreskuratze-gakoa gailu honetako biltegiratze seguruan.';

  @override
  String get saveKeyManuallyDescription =>
      'Gorde eskuz gako hau gailuko partekatze-menua edo arbela erabiliz.';

  @override
  String get storeInAndroidKeystore => 'Gorde Android KeyStore-n';

  @override
  String get storeInAppleKeyChain => 'Gorde Apple KeyChain-en';

  @override
  String get storeSecurlyOnThisDevice => 'Gorde gailu honetan modu seguruan';

  @override
  String countFiles(Object count) {
    return '$count fitxategi';
  }

  @override
  String get user => 'Erabiltzailea';

  @override
  String get custom => 'Neurrira egindakoa';

  @override
  String get foregroundServiceRunning =>
      'Jakinarazpen hau zerbitzua martxan dagoenean agertzen da.';

  @override
  String get screenSharingTitle => 'pantaila partekatzen';

  @override
  String get screenSharingDetail =>
      'Pantaila FluffyChaten partekatzen ari zara';

  @override
  String get callingPermissions => 'Deiak egiteko baimenak';

  @override
  String get callingAccount => 'Deia egiteko kontua';

  @override
  String get callingAccountDetails =>
      'Baimendu FluffyCaht Android gailuko telefono markagailua erabiltzea.';

  @override
  String get appearOnTop => 'Gainean erakutsi';

  @override
  String get appearOnTopDetails =>
      'Aplikazioa goikaldean agertzea baimentzen du (ez da beharrezkoa FluffyChat dei egiteko kontua bezala ezarri baduzu)';

  @override
  String get otherCallingPermissions =>
      'Mikrofono, kamera eta FluffyChaten beste baimen batzuk';

  @override
  String get whyIsThisMessageEncrypted => 'Zergatik ezin da mezu hau irakurri?';

  @override
  String get noKeyForThisMessage =>
      'Mezua gailu honetan saioa hasi baino lehen bidali bazen gertatu daiteke.\n\nBeste aukera bat igorleak zure gailua blokeatu izana da, edo zerbaitek huts egin izana interneteko konexioan.\n\nMezua beste saio batean irakur dezakezu? Hala bada, mezua transferitu dezakezu! Zoaz Ezrpenetara > Gailuak eta baieztatu zure gailuek bata bestea egiaztatu dutela. Gela irakiko duzun hurrengo aldian eta bi saioak aurreko planoan irekita daudenean, gakoak automatikoki partekatuko dira.\n\nEz duzu gakorik galdu nahi saioa amaitu edo gailuak aldatzen dituzunean? Baieztatu ezarpenetan berriketen babeskopiak gaituta dituzula.';

  @override
  String get newGroup => 'Talde berria';

  @override
  String get newSpace => 'Gune berria';

  @override
  String get enterSpace => 'Batu gunera';

  @override
  String get enterRoom => 'Batu gelara';

  @override
  String get allSpaces => 'Gune guztiak';

  @override
  String numChats(Object number) {
    return '$number berriketa';
  }

  @override
  String get hideUnimportantStateEvents =>
      'Izkutatu garrantzirik gabeko gertaerak';

  @override
  String get doNotShowAgain => 'Ez erakutsi berriro';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return 'Txata hutsik dago ($oldDisplayName zen lehen)';
  }

  @override
  String get newSpaceDescription =>
      'Guneek txatak taldekatzea ahalbidetzen dute eta komunitate pribatu edo publikoak osatzea.';

  @override
  String get encryptThisChat => 'Zifratu txata';

  @override
  String get endToEndEncryption => 'Puntuz puntuko zifraketa';

  @override
  String get disableEncryptionWarning =>
      'Segurtasun arrazoiak direla-eta, ezin duzu lehendik zifratuta zegoen txat bateko zifraketa ezgaitu.';

  @override
  String get sorryThatsNotPossible => 'Barka… hori ez da posible';

  @override
  String get deviceKeys => 'Gailuaren gakoak:';

  @override
  String get letsStart => 'Has gaitezen';

  @override
  String get enterInviteLinkOrMatrixId =>
      'Sartu gonbidapen-esteka edo Matrix IDa…';

  @override
  String get reopenChat => 'Ireki txata berriro';

  @override
  String get noBackupWarning =>
      'Adi! Txataren babeskopia gaitzen ez baduzu, ezingo dituzu zifratutako txatak atzitu. Oso gomendagarria da txaten babeskopia gaitzea saioa amaitu baino lehen.';

  @override
  String get noOtherDevicesFound => 'Ez da beste gailurik aurkitu';

  @override
  String get fileIsTooBigForServer =>
      'Zerbitzariak dio fitxategia handiegia dela bidali ahal izateko.';

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
  String get search => 'Bilatu';

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
