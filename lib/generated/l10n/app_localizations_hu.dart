// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class L10nHu extends L10n {
  L10nHu([String locale = 'hu']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'A jelszavak nem egyeznek.';

  @override
  String get pleaseEnterValidEmail => 'Adjon meg egy érvényes e-mail-címet.';

  @override
  String get repeatPassword => 'Jelszó megismétlése';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Válasszon legalább $min karaktert.';
  }

  @override
  String get about => 'Névjegy';

  @override
  String get updateAvailable => 'FluffyChat-frissítés elérhető';

  @override
  String get updateNow => 'Frissítés elindítása a háttérben';

  @override
  String get accept => 'Elfogadás';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username elfogadta a meghívást';
  }

  @override
  String get account => 'Fiók';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username aktiválta a végpontok közötti titkosítást';
  }

  @override
  String get addEmail => 'E-mail-cím hozzáadása';

  @override
  String get confirmMatrixId => 'A fiók törléséhez adja meg a Matrix ID-t.';

  @override
  String supposedMxid(Object mxid) {
    return 'This should be $mxid';
  }

  @override
  String get addGroupDescription => 'Csoportleírás hozzáadása';

  @override
  String get addToSpace => 'Hozzáadás térhez';

  @override
  String get admin => 'Admin';

  @override
  String get alias => 'álnév';

  @override
  String get all => 'Összes';

  @override
  String get allChats => 'Összes csevegés';

  @override
  String get commandHint_googly => 'Gülüszemek küldése';

  @override
  String get commandHint_cuddle => 'Ölelés küldése';

  @override
  String get commandHint_hug => 'Ölelés küldése';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName gülüszemeket küld';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName megölelt';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName hugs you';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName megválaszolta a hívást';
  }

  @override
  String get anyoneCanJoin => 'Bárki csatlakozhat';

  @override
  String get appLock => 'Alkalmazászár';

  @override
  String get archive => 'Archívum';

  @override
  String get archivedRoom => 'Archivált szoba';

  @override
  String get areGuestsAllowedToJoin => 'Csatlakozhatnak-e vendégek';

  @override
  String get areYouSure => 'Biztos vagy benne?';

  @override
  String get areYouSureYouWantToLogout => 'Biztos, hogy kijelentkezel?';

  @override
  String get askSSSSSign =>
      'A másik fél igazolásához meg kell adni a biztonságos tároló jelmondatát vagy a visszaállítási kulcsot.';

  @override
  String askVerificationRequest(Object username) {
    return 'Elfogadod $username hitelesítési kérelmét?';
  }

  @override
  String get autoplayImages =>
      'Animált matricák és hangulatjelek automatikus lejátszása';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'A Matrix-kiszolgáló a következő bejelentkezéseket támogatja:\n$serverVersions\nDe ez az alkalmazást csak ezeket támogatja:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Küldés Enterrel';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'A Matrix szerver ezeket a specifikáció verziókat támogatja:\n$serverVersions\nAzonban ez az app csak ezeket: $supportedVersions';
  }

  @override
  String get banFromChat => 'Kitiltás a csevegésből';

  @override
  String get banned => 'Kitiltva';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username kitiltotta: $targetName';
  }

  @override
  String get blockDevice => 'Eszköz blokkolása';

  @override
  String get blocked => 'Blokkolva';

  @override
  String get botMessages => 'Bot üzenetek';

  @override
  String get bubbleSize => 'Buborék méret';

  @override
  String get cancel => 'Mégse';

  @override
  String cantOpenUri(Object uri) {
    return 'Nem sikerült az URI megnyitása: $uri';
  }

  @override
  String get changeDeviceName => 'Eszköznév módosítása';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username módosította a csevegési profilképét';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username módosította a csevegés leírását erre: „$description”';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username módosította a csevegés nevét erre: „$chatname”';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username módosította a csevegési engedélyeket';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username módosította a megjenelítési nevét erre: $displayname';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username módosította a vendégek hozzáférési szabályait';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username módosította a vendégek hozzáférési szabályait, így: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username módosította az előzmények láthatóságát';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username módosította az előzmények láthatóságát, így: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username módosított a csatlakozási szabályokat';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username módosította a csatlakozási szabályokat, így: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username módosította a profilképét';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username módosította a szoba címeit';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username módosította a meghívó hivatkozást';
  }

  @override
  String get changePassword => 'Jelszó módosítása';

  @override
  String get changeTheHomeserver => 'Matrix-kiszolgáló váltása';

  @override
  String get changeTheme => 'Stílus módosítása';

  @override
  String get changeTheNameOfTheGroup => 'Csoport nevének módosítása';

  @override
  String get changeWallpaper => 'Háttér módosítása';

  @override
  String get changeYourAvatar => 'Profilkép módosítása';

  @override
  String get channelCorruptedDecryptError => 'A titkosítás megsérült';

  @override
  String get chat => 'Csevegés';

  @override
  String get yourUserId => 'Saját Matrix címed:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'A beszélgetések mentése be lett állítva.';

  @override
  String get chatBackup => 'Beszélgetések mentése';

  @override
  String get chatBackupDescription =>
      'A régebbi beszélgetéseid egy biztonsági kulccsal vanak védve. Bizonyosodj meg róla, hogy nem fogod elveszíteni.';

  @override
  String get chatDetails => 'Csevegés részletei';

  @override
  String get chatHasBeenAddedToThisSpace =>
      'A beszélgetés hozzá lett adva ehhez a térhez';

  @override
  String get chats => 'Beszélgetések';

  @override
  String get chooseAStrongPassword => 'Válassz erős jelszót';

  @override
  String get chooseAUsername => 'Válassz felhasználónevet';

  @override
  String get clearArchive => 'Archívum törlése';

  @override
  String get close => 'Bezárás';

  @override
  String get commandHint_markasdm => 'Mark as direct chat';

  @override
  String get commandHint_markasgroup => 'Csoportnak jelölés';

  @override
  String get commandHint_ban => 'Felhasználó kitiltása ebből a szobából';

  @override
  String get commandHint_clearcache => 'Gyorsítótár törlése';

  @override
  String get commandHint_create =>
      'Egy üres csoport létrehozása\nA --no-encryption kapcsolóval titkosítatlan szoba hozható létre';

  @override
  String get commandHint_discardsession => 'Munkamenet elvetése';

  @override
  String get commandHint_dm =>
      'Közvetlen beszélgetés indítása\nA --no-encryption kapcsolóval titkosítatlan beszélgetés lesz létrehozva';

  @override
  String get commandHint_html => 'HTML formázott üzenet küldése';

  @override
  String get commandHint_invite => 'Felhasználó meghívása ebbe a szobába';

  @override
  String get commandHint_join => 'Csatlakozás a megadott szobához';

  @override
  String get commandHint_kick => 'A megadott felhasználó kirúgása a szobából';

  @override
  String get commandHint_leave => 'Ennek a szobának az elhagyása';

  @override
  String get commandHint_me => 'Mit csinálsz épp';

  @override
  String get commandHint_myroomavatar =>
      'Az ebben a szobában megjelenített profilképed megváltoztatása (mxc URI-t kell megadni)';

  @override
  String get commandHint_myroomnick =>
      'Az ebben a szobában megjelenített beceneved megváltoztatása';

  @override
  String get commandHint_op =>
      'Az adott felhasználó hozzáférési szintjét változtatja (alapértelmezett: 50)';

  @override
  String get commandHint_plain => 'Formázatlan szöveg küldése';

  @override
  String get commandHint_react => 'Válasz küldése reakcióként';

  @override
  String get commandHint_send => 'Szöveg küldése';

  @override
  String get commandHint_unban =>
      'Az adott felhasználó visszaengedése ebbe a szobába';

  @override
  String get commandInvalid => 'Érvénytelen parancs';

  @override
  String commandMissing(Object command) {
    return '$command nem egy parancs.';
  }

  @override
  String get compareEmojiMatch =>
      'Hasonlítsd össze az emodzsikat a másik eszközön lévőkkel, és bizonyosodj meg róla, hogy egyeznek:';

  @override
  String get compareNumbersMatch =>
      'Hasonlítsd össze a számokat a másik eszközön lévőkkel, és bizonyosodj meg arról, hogy egyeznek:';

  @override
  String get configureChat => 'Beszélgetés beállítása';

  @override
  String get confirm => 'Megerősítés';

  @override
  String get connect => 'Csatlakozás';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'Meghívtad az ismerősödet a csoportba';

  @override
  String get containsDisplayName => 'Tartalmazza a megjelenített becenevet';

  @override
  String get containsUserName => 'Tartalmazza a felhasználónevet';

  @override
  String get contentHasBeenReported =>
      'A tartalom jelentve lett a szerver üzemeltetőinek';

  @override
  String get copiedToClipboard => 'Vágólapra másolva';

  @override
  String get copy => 'Másolás';

  @override
  String get copyToClipboard => 'Vágólapra másolás';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Nem sikerült visszafejteni a titkosított üzenetet: $error';
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
  String get create => 'Létrehozás';

  @override
  String createdTheChat(Object username) {
    return '💬  $username létrehozta a csevegést';
  }

  @override
  String get createNewGroup => 'Új csoport létrehozása';

  @override
  String get createNewSpace => 'Új tér';

  @override
  String get crossSigningEnabled => 'Eszközök közti aláírás bekapcsolva';

  @override
  String get currentlyActive => 'Jelenleg aktív';

  @override
  String get darkTheme => 'Sötét';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$month. $day.';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$year. $month. $day.';
  }

  @override
  String get deactivateAccountWarning =>
      'Ez deaktiválja a felhasználói fiókodat. Ez nem vonható vissza! Biztos vagy benne?';

  @override
  String get defaultPermissionLevel => 'Alapértelmezett hozzáférési szint';

  @override
  String get delete => 'Törlés';

  @override
  String get deleteAccount => 'Fiók törlése';

  @override
  String get deleteMessage => 'Üzenet törlése';

  @override
  String get deny => 'Elutasítás';

  @override
  String get device => 'Eszköz';

  @override
  String get deviceId => 'Eszköz ID';

  @override
  String get devices => 'Eszközök';

  @override
  String get directChats => 'Közvetlen beszélgetés';

  @override
  String get discover => 'Felfedezés';

  @override
  String get displaynameHasBeenChanged => 'Megjelenítési név megváltozott';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Szerkeszt';

  @override
  String get editBlockedServers => 'Blokkolt szerverek szerkesztése';

  @override
  String get editChatPermissions => 'Beszélgetés engedélyek szerkesztése';

  @override
  String get editDisplayname => 'Megjelenítési név módosítása';

  @override
  String get editRoomAliases => 'Szoba címeinek szerkesztése';

  @override
  String get editRoomAvatar => 'Szoba profilképének szerkesztése';

  @override
  String get emoteExists => 'A hangulatjel már létezik!';

  @override
  String get emoteInvalid => 'Érvénytelen hangulatjel rövid kód!';

  @override
  String get emotePacks => 'Hangulatjel-csomagok a szobához';

  @override
  String get emoteSettings => 'Hangulatjel-beállítások';

  @override
  String get emoteShortcode => 'Rövid kód a hangulatjelhez';

  @override
  String get emoteWarnNeedToPick =>
      'A hangulatjelhez egy képet és egy rövid kódot kell választani!';

  @override
  String get emptyChat => 'Üres csevegés';

  @override
  String get enableEmotesGlobally =>
      'Hangulatjel-csomag engedélyezése globálisan';

  @override
  String get enableEncryption => 'Titkosítás bekapcsolása';

  @override
  String get enableEncryptionWarning =>
      'Többé nem fogod tudni kikapcsolni a titkosítást. Biztos vagy benne?';

  @override
  String get encrypted => 'Titkosított';

  @override
  String get encryption => 'Titkosítás';

  @override
  String get encryptionNotEnabled => 'Titkosítás nincs engedélyezve';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName befejezte a hívást';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Adj meg egy email címet';

  @override
  String get enterASpacepName => 'Add meg a tér nevét';

  @override
  String get homeserver => 'Matrix szerver';

  @override
  String get enterYourHomeserver => 'Add meg a Matrix-kiszolgálód';

  @override
  String errorObtainingLocation(Object error) {
    return 'Hiba a tartózkodási hely lekérése közben: $error';
  }

  @override
  String get everythingReady => 'Minden kész!';

  @override
  String get extremeOffensive => 'Extrém sértő';

  @override
  String get fileName => 'Fájlnév';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Betűméret';

  @override
  String get forward => 'Továbbítás';

  @override
  String get friday => 'Péntek';

  @override
  String get fromJoining => 'Csatlakozás óta';

  @override
  String get fromTheInvitation => 'Meghívás óta';

  @override
  String get goToTheNewRoom => 'Új szoba megnyitása';

  @override
  String get group => 'Csoport';

  @override
  String get groupDescription => 'Csoport leírása';

  @override
  String get groupDescriptionHasBeenChanged => 'A csoport leírása megváltozott';

  @override
  String get groupIsPublic => 'A csoport nyilvános';

  @override
  String get groups => 'Csoportok';

  @override
  String groupWith(Object displayname) {
    return 'Csoport vele: $displayname';
  }

  @override
  String get guestsAreForbidden => 'Nem lehetnek vendégek';

  @override
  String get guestsCanJoin => 'Csatlakozhatnak vendégek';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username visszavonta $targetName meghívását';
  }

  @override
  String get help => 'Súgó';

  @override
  String get hideRedactedEvents => 'Visszavont események elrejtése';

  @override
  String get hideUnknownEvents => 'Ismeretlen események elrejtése';

  @override
  String get howOffensiveIsThisContent => 'Mennyire sértő ez a tartalom?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Azonosító';

  @override
  String get ignore => 'Figyelmen kívül hagyás';

  @override
  String get ignoredUsers => 'Figyelmen kívül hagyott felhasználók';

  @override
  String get ignoreListDescription =>
      'Figyelmen kívül hagyhatja azon felhasználókat, akik zavarják. Nem fog üzeneteket vagy szobameghívókat kapni a személyes listáján szereplő felhasználóktól.';

  @override
  String get ignoreUsername => 'Felhasználó figyelmen kívül hagyása';

  @override
  String get iHaveClickedOnLink => 'Rákattintottam a linkre';

  @override
  String get incorrectPassphraseOrKey =>
      'Hibás jelmondat vagy visszaállítási kulcs';

  @override
  String get inoffensive => 'Nem sértő';

  @override
  String get inviteContact => 'Ismerős meghívása';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Ismerős meghívása a(z) $groupName csoportba';
  }

  @override
  String get invited => 'Meghívott';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username meghívta $targetName-t';
  }

  @override
  String get invitedUsersOnly => 'Csak meghívottak';

  @override
  String get inviteForMe => 'Meghívás nekem';

  @override
  String inviteText(Object username, Object link) {
    return '$username meghívott a FluffyChat alkalmazásba. \n1. Telepítsd a FluffyChat appot: https://fluffychat.im \n2. Regisztrálj, vagy jelentkezz be. \n3. Nyisd meg a meghívó hivatkozást: $link';
  }

  @override
  String get isTyping => 'gépel';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username csatlakozott a csevegéshez';
  }

  @override
  String get joinRoom => 'Csatlakozás a szobához';

  @override
  String get keysCached => 'Kulcsok gyorsítótárazva';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username kirúgta $targetName-t';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username kirúgta és kitiltotta $targetName-t';
  }

  @override
  String get kickFromChat => 'Kirúgás a csevegésből';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Utoljára aktív: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Már régen látta';

  @override
  String get leave => 'Csevegés elhagyása';

  @override
  String get leftTheChat => 'Elhagyta a csevegést';

  @override
  String get license => 'Licenc';

  @override
  String get lightTheme => 'Világos';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'További $count résztvevő betöltése';
  }

  @override
  String get dehydrate => 'Munkamenet exportálásssa és az eszköz törlése';

  @override
  String get dehydrateWarning =>
      'Ez nem visszavonható. Bizonyosodj meg róla, hogy biztonságos helyen tárolod a mentett fájlt.';

  @override
  String get dehydrateShare =>
      'Ez egy privát FluffyChat-export. Tartsa biztonságban, és ne vessze el.';

  @override
  String get dehydrateTor => 'Tor felhasználók: munkamenet dehidratálása';

  @override
  String get dehydrateTorLong =>
      'Tor felhasználóknak ajánlott a munkamenet dehidratálása az ablak bezárása előtt.';

  @override
  String get hydrateTor => 'Tor felhasználók: hidratált munkamenet importálása';

  @override
  String get hydrateTorLong =>
      'Did you export your session last time on TOR? Quickly import it and continue chatting.';

  @override
  String get hydrate => 'Visszaállítás fájlból';

  @override
  String get loadingPleaseWait => 'Betöltés… Kérlek, várj.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Továbbiak betöltése…';

  @override
  String get locationDisabledNotice =>
      'A helymeghatározás ki van kapcsolva. Kérlek, kapcsold be, hogy meg tudd osztani a helyzeted.';

  @override
  String get locationPermissionDeniedNotice =>
      'A helymeghatározás nincs engedélyezve az alkalmazásnak. Kérlek engedélyezd, hogy meg tudd osztani a helyzeted.';

  @override
  String get login => 'Bejelentkezés';

  @override
  String logInTo(Object homeserver) {
    return 'Bejelentkezés a(z) $homeserver Matrix-kiszolgálóra';
  }

  @override
  String get loginWithOneClick => 'Bejelentkezés egy kattintással';

  @override
  String get logout => 'Kijelentkezés';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Bizonyosodj meg az azonosító helyességéről';

  @override
  String get memberChanges => 'Tagság változások';

  @override
  String get mention => 'Megemlítés';

  @override
  String get messages => 'Üzenetek';

  @override
  String get messageWillBeRemovedWarning =>
      'Az üzenet minden résztvevő számára törlődni fog';

  @override
  String get noSearchResult => 'Nincs megfelelő találat.';

  @override
  String get moderator => 'Moderátor';

  @override
  String get monday => 'Hétfő';

  @override
  String get muteChat => 'Csevegés némítása';

  @override
  String get needPantalaimonWarning =>
      'Jelenleg a Pantalaimon szükséges a végpontok közötti titkosítás használatához.';

  @override
  String get newChat => 'Új beszélgetés';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Új hitelesítési kérelem!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Következő';

  @override
  String get no => 'Nem';

  @override
  String get noConnectionToTheServer => 'Nem elérhető a szerver';

  @override
  String get noEmotesFound => 'Nincsenek hangulatjelek. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Csak akkor kapcsolható be a titkosítás, ha a szoba nem nyilvánosan hozzáférhető.';

  @override
  String get noGoogleServicesWarning =>
      'Úgy tűnik, hogy nincsenek Google szolgáltatások a telefonodon. Ez adatvédelmi szempontból jó döntés! Ahhoz, hogy push értesítéseket fogadhass a FluffyChat alkalmazásban, a microG használatát javasoljuk: https://microg.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 nem egy Matrix szerver, használjam a $server2 szervert inkább?';
  }

  @override
  String get shareYourInviteLink => 'Meghívási link küldése';

  @override
  String get typeInInviteLinkManually => 'Meghívási link beírása...';

  @override
  String get scanQrCode => 'QR kód beolvasása';

  @override
  String get none => 'Nincs';

  @override
  String get noPasswordRecoveryDescription =>
      'Még nem adtál meg semmilyen módot a jelszavad visszaállítására';

  @override
  String get noPermission => 'Nincsenek engedélyek';

  @override
  String get noRoomsFound => 'Nem találhatók szobák…';

  @override
  String get notifications => 'Értesítések';

  @override
  String numUsersTyping(Object count) {
    return '$count felhasználó gépel';
  }

  @override
  String get obtainingLocation => 'Tartózkodási hely lekérése…';

  @override
  String get offensive => 'Sértő';

  @override
  String get offline => 'Offline';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'OK';

  @override
  String get online => 'Online';

  @override
  String get onlineKeyBackupEnabled => 'Online kulcsmentés engedélyezve';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Oops! Sajnos hiba történt a push értesítések beállításakor.';

  @override
  String get oopsSomethingWentWrong => 'Hoppá, valami baj történt…';

  @override
  String get openAppToReadMessages =>
      'Alkalmazás megnyitása az üzenetek elolvasásához';

  @override
  String get openCamera => 'Kamera megnyitása';

  @override
  String get openVideoCamera => 'Kamera megnyitása videóhoz';

  @override
  String get oneClientLoggedOut => 'One of your clients has been logged out';

  @override
  String get addAccount => 'Fiók hozzáadása';

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
  String get openInMaps => 'Megnyitás térképen';

  @override
  String get link => 'Hivatkozás';

  @override
  String get serverRequiresEmail =>
      'This server needs to validate your email address for registration.';

  @override
  String get optionalGroupName => 'Csoportnév (nem kötelező)';

  @override
  String get or => 'Vagy';

  @override
  String get participant => 'Résztvevő';

  @override
  String get passphraseOrKey => 'Jelmondat vagy visszaállítási kulcs';

  @override
  String get password => 'Jelszó';

  @override
  String get passwordForgotten => 'Elfelejtett jelszó';

  @override
  String get passwordHasBeenChanged => 'A jelszó módosítva';

  @override
  String get passwordRecovery => 'Jelszó visszaállítás';

  @override
  String get people => 'Emberek';

  @override
  String get pickImage => 'Kép választása';

  @override
  String get pin => 'Rögzítés';

  @override
  String play(Object fileName) {
    return '$fileName lejátszása';
  }

  @override
  String get pleaseChoose => 'Kérjük válasszon';

  @override
  String get pleaseChooseAPasscode => 'Please choose a pass code';

  @override
  String get pleaseChooseAUsername => 'Válassz egy felhasználónevet';

  @override
  String get pleaseClickOnLink =>
      'Please click on the link in the email and then proceed.';

  @override
  String get pleaseEnter4Digits =>
      'Írjon be 4 számjegyet, vagy hagyja üresen a zár kikapcsolásához.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Írj be egy Matrix-azonosítót.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => 'Add meg a jelszavad';

  @override
  String get pleaseEnterYourPin => 'Írja be a PIN-kódot';

  @override
  String get pleaseEnterYourUsername => 'Add meg a felhasználónevedet';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Please follow the instructions on the website and tap on next.';

  @override
  String get privacy => 'Adatvédelem';

  @override
  String get publicRooms => 'Nyilvános szobák';

  @override
  String get pushRules => 'Push rules';

  @override
  String get reason => 'Ok';

  @override
  String get recording => 'Felvétel';

  @override
  String redactedAnEvent(Object username) {
    return '$username visszavont egy eseményt';
  }

  @override
  String get redactMessage => 'Üzenet visszavonása';

  @override
  String get register => 'Regisztrálás';

  @override
  String get reject => 'Elutasítás';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username elutasította a meghívást';
  }

  @override
  String get rejoin => 'Újracsatlakozás';

  @override
  String get remove => 'Eltávolítás';

  @override
  String get removeAllOtherDevices => 'Minden más eszköz eltávolítása';

  @override
  String removedBy(Object username) {
    return '$username törölte';
  }

  @override
  String get removeDevice => 'Eszköz eltávolítása';

  @override
  String get unbanFromChat => 'Kitiltás feloldása';

  @override
  String get removeYourAvatar => 'Remove your avatar';

  @override
  String get renderRichContent => 'Formázott üzenetek megjelenítése';

  @override
  String get replaceRoomWithNewerVersion => 'Replace chat with newer version';

  @override
  String get reply => 'Válasz';

  @override
  String get reportMessage => 'Üzenet jelentése';

  @override
  String get requestPermission => 'Jogosultság igénylése';

  @override
  String get roomHasBeenUpgraded => 'A szoba frissítve lett';

  @override
  String get roomVersion => 'Szobaverzió';

  @override
  String get saturday => 'Szombat';

  @override
  String get saveFile => 'Fájl mentése';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Biztonság';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyLost => 'Recovery key lost?';

  @override
  String seenByUser(Object username) {
    return '$username látta';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$username és $count másik résztvevő látta',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return '$username és $username2 látta';
  }

  @override
  String get send => 'Küldés';

  @override
  String get sendAMessage => 'Üzenet küldése';

  @override
  String get sendAsText => 'Send as text';

  @override
  String get sendAudio => 'Hangüzenet küldése';

  @override
  String get sendFile => 'Fájl küldése';

  @override
  String get sendImage => 'Kép küldése';

  @override
  String get sendMessages => 'Üzenetek küldése';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Eredeti küldése';

  @override
  String get sendSticker => 'Matrica küldése';

  @override
  String get sendVideo => 'Videó küldése';

  @override
  String sentAFile(Object username) {
    return '📁 $username fájlt küldött';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username hangüzenetet küldött';
  }

  @override
  String sentAPicture(Object username) {
    return '$username képet küldött';
  }

  @override
  String sentASticker(Object username) {
    return '$username matricát küldött';
  }

  @override
  String sentAVideo(Object username) {
    return '$username videót küldött';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName hívásinformációt küldött';
  }

  @override
  String get separateChatTypes => 'Separate Direct Chats and Groups';

  @override
  String get setAsCanonicalAlias => 'Set as main alias';

  @override
  String get setCustomEmotes => 'Set custom emotes';

  @override
  String get setGroupDescription => 'Csoportleírás beállítása';

  @override
  String get setInvitationLink => 'Meghívó hivatkozás beállítása';

  @override
  String get setPermissionsLevel => 'Set permissions level';

  @override
  String get setStatus => 'Állapot beállítása';

  @override
  String get settings => 'Beállítások';

  @override
  String get share => 'Megosztás';

  @override
  String sharedTheLocation(Object username) {
    return '$username megosztotta a pozícióját';
  }

  @override
  String get shareLocation => 'Share location';

  @override
  String get showDirectChatsInSpaces => 'Show related Direct Chats in Spaces';

  @override
  String get showPassword => 'Show password';

  @override
  String get signUp => 'Regisztráció';

  @override
  String get singlesignon => 'Single Sign on';

  @override
  String get skip => 'Kihagyás';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Forráskód';

  @override
  String get spaceIsPublic => 'Space is public';

  @override
  String get spaceName => 'Space name';

  @override
  String startedACall(Object senderName) {
    return '$senderName hívást indított';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Status';

  @override
  String get statusExampleMessage => 'Hogy vagy?';

  @override
  String get submit => 'Beküldés';

  @override
  String get sunday => 'Vasárnap';

  @override
  String get synchronizingPleaseWait => 'Synchronizing… Please wait.';

  @override
  String get systemTheme => 'Rendszer';

  @override
  String get theyDontMatch => 'Nem egyeznek';

  @override
  String get theyMatch => 'Egyeznek';

  @override
  String get thisRoomHasBeenArchived => 'Ez a szoba archiválva lett.';

  @override
  String get thursday => 'Csütörtök';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Toggle Favorite';

  @override
  String get toggleMuted => 'Toggle Muted';

  @override
  String get toggleUnread => 'Mark Read/Unread';

  @override
  String get tooManyRequestsWarning =>
      'Too many requests. Please try again later!';

  @override
  String get transferFromAnotherDevice => 'Transfer from another device';

  @override
  String get tryToSendAgain => 'Újraküldés megpróbálása';

  @override
  String get tuesday => 'Kedd';

  @override
  String get unavailable => 'Nem érhető el';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username feloldotta $targetName kitiltását';
  }

  @override
  String get unblockDevice => 'Eszköz blokkolásának megszüntetése';

  @override
  String get unknownDevice => 'Ismeretlen eszköz';

  @override
  String get unknownEncryptionAlgorithm => 'Ismeretlen titkosítási algoritmus';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Ismeretlen esemény: „$type”';
  }

  @override
  String get unmuteChat => 'Csevegés némításának megszüntetése';

  @override
  String get unpin => 'Rögzítés megszüntetése';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount olvasatlan csevegés',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username és $count másik résztvevő gépel';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username és $username2 gépel';
  }

  @override
  String userIsTyping(Object username) {
    return '$username gépel';
  }

  @override
  String userLeftTheChat(Object username) {
    return '$username elhagyta a csevegést';
  }

  @override
  String get username => 'Felhasználónév';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username $type eseményt küldött';
  }

  @override
  String get unverified => 'Unverified';

  @override
  String get verified => 'Verified';

  @override
  String get verify => 'Hitelesítés';

  @override
  String get verifyStart => 'Hitelesítés megkezdése';

  @override
  String get verifySuccess => 'Sikeres hitelesítés!';

  @override
  String get verifyTitle => 'Másik fiók hitelesítése';

  @override
  String get videoCall => 'Videóhívás';

  @override
  String get visibilityOfTheChatHistory => 'Csevegési előzmény láthatósága';

  @override
  String get visibleForAllParticipants => 'Minden résztvevő számára látható';

  @override
  String get visibleForEveryone => 'Bárki számára látható';

  @override
  String get voiceMessage => 'Hangüzenet';

  @override
  String get waitingPartnerAcceptRequest =>
      'Várakozás partnerre, amíg elfogadja a kérést…';

  @override
  String get waitingPartnerEmoji =>
      'Várakozás partnerre, hogy elfogadja a hangulatjeleket…';

  @override
  String get waitingPartnerNumbers =>
      'Várakozás a partnerre, hogy elfogadja a számokat…';

  @override
  String get wallpaper => 'Háttér';

  @override
  String get warning => 'Figyelmeztetés!';

  @override
  String get wednesday => 'Szerda';

  @override
  String get weSentYouAnEmail => 'Küldtünk neked egy emailt';

  @override
  String get whoCanPerformWhichAction => 'Who can perform which action';

  @override
  String get whoIsAllowedToJoinThisGroup => 'Ki csatlakozhat a csoporthoz';

  @override
  String get whyDoYouWantToReportThis => 'Why do you want to report this?';

  @override
  String get wipeChatBackup =>
      'Wipe your chat backup to create a new recovery key?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Ezzekkel a címekkel vissza tudod állítani a jelszavad, ha szükséges';

  @override
  String get writeAMessage => 'Írj egy üzenetet…';

  @override
  String get yes => 'Igen';

  @override
  String get you => 'Te';

  @override
  String get youAreInvitedToThisChat => 'Meghívtak ebbe a csevegésbe';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Nem veszel részt ebben a csevegésben';

  @override
  String get youCannotInviteYourself => 'Nem tudod meghívni magadat';

  @override
  String get youHaveBeenBannedFromThisChat => 'Kitiltottak ebből a csevegésből';

  @override
  String get yourPublicKey => 'Your public key';

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
  String get search => 'Keresés';

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
