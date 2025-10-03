// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class L10nCs extends L10n {
  L10nCs([String locale = 'cs']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Hesla se neshodují!';

  @override
  String get pleaseEnterValidEmail =>
      'Prosím zadejte platnou emailovou adresu.';

  @override
  String get repeatPassword => 'Zopakujte heslo';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Vyberte prosím alespoň $min znaků.';
  }

  @override
  String get about => 'O aplikaci';

  @override
  String get updateAvailable => 'K dispozici aktualizace FluffyChat';

  @override
  String get updateNow => 'Spustit aktualizaci na pozadí';

  @override
  String get accept => 'Přijmout';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username přijal/a pozvání';
  }

  @override
  String get account => 'Účet';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username aktivoval/a koncové šifrování';
  }

  @override
  String get addEmail => 'Přidat e-mail';

  @override
  String get confirmMatrixId =>
      'Prosím, potvrďte vaše Matrix ID, abyste mohli smazat váš účet.';

  @override
  String supposedMxid(Object mxid) {
    return 'This should be $mxid';
  }

  @override
  String get addGroupDescription => 'Přidat popis skupiny';

  @override
  String get addToSpace => 'Přidat do prostoru';

  @override
  String get admin => 'Správce';

  @override
  String get alias => 'alias';

  @override
  String get all => 'Vše';

  @override
  String get allChats => 'Všechny chaty';

  @override
  String get commandHint_googly => 'Poslat kroutící se očička';

  @override
  String get commandHint_cuddle => 'Poslat mazlení';

  @override
  String get commandHint_hug => 'Poslat obejmutí';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName vám posílá kroutící se očička';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName se s vámi mazlí';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName vás objímá';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName odpověděl na hovor';
  }

  @override
  String get anyoneCanJoin => 'Kdokoliv se může připojit';

  @override
  String get appLock => 'Zámek aplikace';

  @override
  String get archive => 'Archivovat';

  @override
  String get archivedRoom => 'Archivovaná místnost';

  @override
  String get areGuestsAllowedToJoin => 'Mohou se připojit hosté';

  @override
  String get areYouSure => 'Jste si jistý?';

  @override
  String get areYouSureYouWantToLogout => 'Opravdu se chcete odhlásit?';

  @override
  String get askSSSSSign =>
      'Pro ověření této osoby zadejte prosím přístupovou frázi k „bezpečnému úložišti“ anebo „klíč pro obnovu“.';

  @override
  String askVerificationRequest(Object username) {
    return 'Přijmout žádost o ověření od $username?';
  }

  @override
  String get autoplayImages =>
      'Automaticky přehrajte animované nálepky a emoce';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Homeserver podporuje přihlášení typu:\n$serverVersions\nAle tato aplikace podporuje pouze:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Odeslat při vstupu';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Homeserver podporuje specifikaci verzí:\n$serverVersions\nAle tato aplikace podporuje pouze verze $supportedVersions';
  }

  @override
  String get banFromChat => 'Zakázat chat';

  @override
  String get banned => 'Zakázán';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username zakázal $targetName';
  }

  @override
  String get blockDevice => 'Blokovat zařízení';

  @override
  String get blocked => 'Zakázán';

  @override
  String get botMessages => 'Zprávy od bota';

  @override
  String get bubbleSize => 'Velikost bubliny';

  @override
  String get cancel => 'Zrušit';

  @override
  String cantOpenUri(Object uri) {
    return 'Nelze otevřít URI $uri';
  }

  @override
  String get changeDeviceName => 'Změnit název zařízení';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username změnil avatar chatu';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username změnil popis chatu na: „$description“';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username změnil jméno chatu na: „$chatname“';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username změnili nastavení oprávnění v chatu';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username změnili svoji přezdívku na: $displayname';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username změnili přístupová práva pro hosty';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username změnili přístupová práva pro hosty na: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username změnili nastavení viditelnosti historie diskuze';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username změnili nastavení viditelnosti historie diskuze na: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username změnili nastavení pravidel připojení';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username změnili nastavení pravidel připojení na: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username změnili svůj avatar';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username změnili nastavení aliasů místnosti';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username změnili odkaz k pozvání do místnosti';
  }

  @override
  String get changePassword => 'Změnit heslo';

  @override
  String get changeTheHomeserver => 'Změnit domovský server';

  @override
  String get changeTheme => 'Změňte svůj styl';

  @override
  String get changeTheNameOfTheGroup => 'Změnit název skupiny';

  @override
  String get changeWallpaper => 'Změnit pozadí';

  @override
  String get changeYourAvatar => 'Změňte svůj avatar';

  @override
  String get channelCorruptedDecryptError => 'Šifrování bylo poškozeno';

  @override
  String get chat => 'Chat';

  @override
  String get yourUserId => 'Vaše uživatelské ID:';

  @override
  String get yourChatBackupHasBeenSetUp => 'Vaše záloha chatu byla nastavena.';

  @override
  String get chatBackup => 'Záloha chatu';

  @override
  String get chatBackupDescription =>
      'Záloha chatu je zabezpečena bezpečnostním klíčem. Ujistěte se, prosím, že klíč neztratíte.';

  @override
  String get chatDetails => 'Bližší údaje o chatu';

  @override
  String get chatHasBeenAddedToThisSpace =>
      'Do tohoto prostoru byl přidán chat';

  @override
  String get chats => 'Chaty';

  @override
  String get chooseAStrongPassword => 'Vyberte silné heslo';

  @override
  String get chooseAUsername => 'Vyberte uživatelské jméno';

  @override
  String get clearArchive => 'Vymazat archiv';

  @override
  String get close => 'Zavřít';

  @override
  String get commandHint_markasdm => 'Mark as direct chat';

  @override
  String get commandHint_markasgroup => 'Mark as chat';

  @override
  String get commandHint_ban =>
      'Zakázat danému uživateli přístup do této místnosti';

  @override
  String get commandHint_clearcache => 'Vymazat mezipamět';

  @override
  String get commandHint_create =>
      'Vytvořte prázdný skupinový chat\n K deaktivaci šifrování použijte --no-encryption';

  @override
  String get commandHint_discardsession => 'Zahodit relaci';

  @override
  String get commandHint_dm =>
      'Zahajte přímý chat\nK deaktivaci šifrování použijte --no-encryption';

  @override
  String get commandHint_html => 'Odeslat text ve formátu HTML';

  @override
  String get commandHint_invite => 'Pozvěte daného uživatele do této místnosti';

  @override
  String get commandHint_join => 'Připojte se k dané místnosti';

  @override
  String get commandHint_kick => 'Odeberte daného uživatele z této místnosti';

  @override
  String get commandHint_leave => 'Opusťte tuto místnost';

  @override
  String get commandHint_me => 'Představ se';

  @override
  String get commandHint_myroomavatar =>
      'Nastavte si obrázek pro tuto místnost (autor mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Nastavte si váš zobrazovaný název pro tuto místnost';

  @override
  String get commandHint_op =>
      'Nastavit úroveň práv daného uživatele (výchozí: 50)';

  @override
  String get commandHint_plain => 'Odeslat neformátovaný text';

  @override
  String get commandHint_react => 'Odeslat odpověď jako reakci';

  @override
  String get commandHint_send => 'Poslat zprávu';

  @override
  String get commandHint_unban =>
      'Zrušte zákaz přístupu daného uživatele do této místnosti';

  @override
  String get commandInvalid => 'Příkaz je neplatný';

  @override
  String commandMissing(Object command) {
    return '$command není příkaz.';
  }

  @override
  String get compareEmojiMatch =>
      'Porovnejte a přesvědčete se, že následující emotikony se shodují na obou zařízeních:';

  @override
  String get compareNumbersMatch =>
      'Porovnejte a přesvědčete se, že následující čísla se shodují na obou zařízeních:';

  @override
  String get configureChat => 'Nastavení chatu';

  @override
  String get confirm => 'Potvrdit';

  @override
  String get connect => 'Připojit';

  @override
  String get contactHasBeenInvitedToTheGroup => 'Kontakt byl pozván do skupiny';

  @override
  String get containsDisplayName => 'Obsahuje zobrazovaný název';

  @override
  String get containsUserName => 'Obsahuje uživatelské jméno';

  @override
  String get contentHasBeenReported => 'Obsah byl nahlášen správcům serveru';

  @override
  String get copiedToClipboard => 'Zkopírováno do schránky';

  @override
  String get copy => 'Kopírovat';

  @override
  String get copyToClipboard => 'Zkopírovat do schránky';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Nebylo možné dešifrovat zprávu: $error';
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
  String get create => 'Vytvořit';

  @override
  String createdTheChat(Object username) {
    return '💬 $username založil/a chat';
  }

  @override
  String get createNewGroup => 'Založit novou skupinu';

  @override
  String get createNewSpace => 'Nový prostor';

  @override
  String get crossSigningEnabled => 'Křížové ověření je zapnuté';

  @override
  String get currentlyActive => 'Aktuálně aktivní';

  @override
  String get darkTheme => 'Tmavé';

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
    return '$day. $month. $year';
  }

  @override
  String get deactivateAccountWarning =>
      'Tímto krokem se deaktivuje váš uživatelský účet. Akci nelze vrátit zpět! Jste si jistí?';

  @override
  String get defaultPermissionLevel => 'Výchozí úroveň oprávnění';

  @override
  String get delete => 'Smazat';

  @override
  String get deleteAccount => 'Smazat účet';

  @override
  String get deleteMessage => 'Smazat zprávu';

  @override
  String get deny => 'Odmítnout';

  @override
  String get device => 'Zařízení';

  @override
  String get deviceId => 'ID zařízení';

  @override
  String get devices => 'Zařízení';

  @override
  String get directChats => 'Přímé chatování';

  @override
  String get discover => 'Objevit';

  @override
  String get displaynameHasBeenChanged => 'Přezdívka byla změněna';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Upravit';

  @override
  String get editBlockedServers => 'Upravit zakázané servery';

  @override
  String get editChatPermissions => 'Upravit oprávnění chatu';

  @override
  String get editDisplayname => 'Změnit přezdívku';

  @override
  String get editRoomAliases => 'Upravit aliasy místností';

  @override
  String get editRoomAvatar => 'Upravit avatara místnosti';

  @override
  String get emoteExists => 'Emotikona již existuje!';

  @override
  String get emoteInvalid => 'Neplatný kód emotikony!';

  @override
  String get emotePacks => 'Balíček emotikonů pro místnost';

  @override
  String get emoteSettings => 'Nastavení emotikonů';

  @override
  String get emoteShortcode => 'Klávesová zkratka emotikonu';

  @override
  String get emoteWarnNeedToPick =>
      'Musíte si vybrat klávesovou zkratku emotikonu a obrázek!';

  @override
  String get emptyChat => 'Prázdný chat';

  @override
  String get enableEmotesGlobally => 'Povolit balíček emotikon všude';

  @override
  String get enableEncryption => 'Povolit šifrování';

  @override
  String get enableEncryptionWarning =>
      'Šifrování již nebude možné vypnout. Jste si tím jisti?';

  @override
  String get encrypted => 'Šifrováno';

  @override
  String get encryption => 'Šifrování';

  @override
  String get encryptionNotEnabled => 'Šifrování není aktivní';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName ukončil hovor';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Zadejte e-mailovou adresu';

  @override
  String get enterASpacepName => 'Zadejte název prostoru';

  @override
  String get homeserver => 'Domácí server';

  @override
  String get enterYourHomeserver => 'Zadejte svůj domovský server';

  @override
  String errorObtainingLocation(Object error) {
    return 'Chyba při získávání polohy: $error';
  }

  @override
  String get everythingReady => 'Vše připraveno!';

  @override
  String get extremeOffensive => 'Extrémně urážlivé';

  @override
  String get fileName => 'Název souboru';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Velikost písma';

  @override
  String get forward => 'Přeposlat';

  @override
  String get friday => 'Pátek';

  @override
  String get fromJoining => 'Od vstupu';

  @override
  String get fromTheInvitation => 'Od pozvání';

  @override
  String get goToTheNewRoom => 'Přejít do nové místnost';

  @override
  String get group => 'Skupina';

  @override
  String get groupDescription => 'Popis skupiny';

  @override
  String get groupDescriptionHasBeenChanged => 'Popis skupiny byl změněn';

  @override
  String get groupIsPublic => 'Skupina je veřejná';

  @override
  String get groups => 'Skupiny';

  @override
  String groupWith(Object displayname) {
    return 'Skupina s $displayname';
  }

  @override
  String get guestsAreForbidden => 'Hosté jsou zakázáni';

  @override
  String get guestsCanJoin => 'Hosté se mohou připojit';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username stáhl pozvánku pro $targetName';
  }

  @override
  String get help => 'Pomoc';

  @override
  String get hideRedactedEvents => 'Skrýt redigované události';

  @override
  String get hideUnknownEvents => 'Skrýt neznámé události';

  @override
  String get howOffensiveIsThisContent => 'Jak urážlivý je tento obsah?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identita';

  @override
  String get ignore => 'Ignorovat';

  @override
  String get ignoredUsers => 'Ignorovaní uživatelé';

  @override
  String get ignoreListDescription =>
      'Můžete ignorovat uživatele, kteří vás znepokojují. Nebudete moci přijímat žádné zprávy nebo pozvánky od uživatelů na vašem osobním seznamu ignorovaných.';

  @override
  String get ignoreUsername => 'Ignorovat uživatelské jméno';

  @override
  String get iHaveClickedOnLink => 'Klikl jsem na odkaz';

  @override
  String get incorrectPassphraseOrKey =>
      'Nesprávné přístupové heslo anebo klíč pro obnovu';

  @override
  String get inoffensive => 'Neškodný';

  @override
  String get inviteContact => 'Pozvat kontakt';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Pozvat kontakt do $groupName';
  }

  @override
  String get invited => 'Pozvaný';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username pozval/a $targetName';
  }

  @override
  String get invitedUsersOnly => 'Pouze pozvaní uživatelé';

  @override
  String get inviteForMe => 'Pozvěte mě';

  @override
  String inviteText(Object username, Object link) {
    return '$username vás pozval na FluffyChat.\n1. Nainstalujte si FluffyChat: https://fluffychat.im\n2. Zaregistrujte se anebo se přihlašte\n3. Otevřete odkaz na pozvánce: $link';
  }

  @override
  String get isTyping => 'píše';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username se připojil/a k chatu';
  }

  @override
  String get joinRoom => 'Připojte se k místnosti';

  @override
  String get keysCached => 'Klíče jsou uloženy v mezipaměti';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username vyhodil/a $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username vyhodili a zakázali $targetName';
  }

  @override
  String get kickFromChat => 'Vyhodit z chatu';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Naposledy aktivní: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Viděn velmi dávno';

  @override
  String get leave => 'Opustit';

  @override
  String get leftTheChat => 'Opustil chat';

  @override
  String get license => 'Licence';

  @override
  String get lightTheme => 'Světlé';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Načíst dalších $count účastníků';
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
  String get loadingPleaseWait => 'Načítání… Prosíme vyčkejte.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Načíst další…';

  @override
  String get locationDisabledNotice =>
      'Služby určování polohy jsou deaktivovány. Povolte jim, aby mohli sdílet vaši polohu.';

  @override
  String get locationPermissionDeniedNotice =>
      'Oprávnění k poloze odepřeno. Udělte jim prosím možnost sdílet vaši polohu.';

  @override
  String get login => 'Přihlásit se';

  @override
  String logInTo(Object homeserver) {
    return 'Přihlášení k $homeserver';
  }

  @override
  String get loginWithOneClick => 'Přihlaste se jedním kliknutím';

  @override
  String get logout => 'Odhlásit';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Ujistěte se, že je identifikátor validní';

  @override
  String get memberChanges => 'Změny členů';

  @override
  String get mention => 'Zmínit se';

  @override
  String get messages => 'Zprávy';

  @override
  String get messageWillBeRemovedWarning =>
      'Zpráva bude odstraněna pro všechny účastníky';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'Moderátor';

  @override
  String get monday => 'Pondělí';

  @override
  String get muteChat => 'Ztlumit chat';

  @override
  String get needPantalaimonWarning =>
      'Prosím vezměte na vědomí, že pro použití koncového šifrování je prozatím potřeba použít Pantalaimon.';

  @override
  String get newChat => 'Nový chat';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Nová žádost o ověření!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Další';

  @override
  String get no => 'Ne';

  @override
  String get noConnectionToTheServer => 'Žádné připojení k serveru';

  @override
  String get noEmotesFound => 'Nebyly nalezeny žádné emotikony. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Můžete aktivovat šifrování jakmile místnost přestane být veřejně dostupná.';

  @override
  String get noGoogleServicesWarning =>
      'Zdá se, že v telefonu nemáte žádné služby Google. To je dobré rozhodnutí pro vaše soukromí! Chcete-li dostávat push oznámení ve FluffyChat, doporučujeme použít: https://microg.org/ nebo https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 není matrixový server, použít místo toho server $server2?';
  }

  @override
  String get shareYourInviteLink => 'Sdílejte váš odkaz na pozvání';

  @override
  String get typeInInviteLinkManually => 'Ručně zadejte odkaz na pozvánku ...';

  @override
  String get scanQrCode => 'Naskenujte QR kód';

  @override
  String get none => 'Žádný';

  @override
  String get noPasswordRecoveryDescription =>
      'Dosud jste nepřidali způsob, jak obnovit své heslo.';

  @override
  String get noPermission => 'Chybí oprávnění';

  @override
  String get noRoomsFound => 'Nebyly nalezeny žádné místnosti…';

  @override
  String get notifications => 'Oznámení';

  @override
  String numUsersTyping(Object count) {
    return '$count uživatelé píší';
  }

  @override
  String get obtainingLocation => 'Získávání polohy…';

  @override
  String get offensive => 'Urážlivé';

  @override
  String get offline => 'Odpojeni';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'Ok';

  @override
  String get online => 'Připojeni';

  @override
  String get onlineKeyBackupEnabled => 'Online záloha kíčů je zapnuta';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Jejda! Při nastavování oznámení push došlo bohužel k chybě.';

  @override
  String get oopsSomethingWentWrong => 'Jejda, něco se pokazilo…';

  @override
  String get openAppToReadMessages => 'Otevřete aplikaci pro přečtení zpráv';

  @override
  String get openCamera => 'Otevřít fotoaparát';

  @override
  String get openVideoCamera => 'Otevřete fotoaparát pro video';

  @override
  String get oneClientLoggedOut => 'Jeden z vašich klientů byl odhlášen';

  @override
  String get addAccount => 'Přidat účet';

  @override
  String get editBundlesForAccount => 'Upravit balíčky pro tento účet';

  @override
  String get addToBundle => 'Přidat do balíčku';

  @override
  String get removeFromBundle => 'Odstranit z tohoto balíčku';

  @override
  String get bundleName => 'Název balíčku';

  @override
  String get enableMultiAccounts =>
      '(BETA) Na tomto zařízení povolte více účtů';

  @override
  String get openInMaps => 'Otevřít v mapách';

  @override
  String get link => 'Odkaz';

  @override
  String get serverRequiresEmail =>
      'Tento server potřebuje k registraci ověřit vaši e -mailovou adresu.';

  @override
  String get optionalGroupName => '(Volitelné) Název skupiny';

  @override
  String get or => 'Nebo';

  @override
  String get participant => 'Účastník';

  @override
  String get passphraseOrKey => 'heslo nebo klíč pro obnovení';

  @override
  String get password => 'Heslo';

  @override
  String get passwordForgotten => 'Zapomenuté heslo';

  @override
  String get passwordHasBeenChanged => 'Heslo bylo změněno';

  @override
  String get passwordRecovery => 'Obnova hesla';

  @override
  String get people => 'Lidé';

  @override
  String get pickImage => 'Zvolit obrázek';

  @override
  String get pin => 'Připnout zprávu';

  @override
  String play(Object fileName) {
    return 'Přehrát $fileName';
  }

  @override
  String get pleaseChoose => 'Prosím vyberte si';

  @override
  String get pleaseChooseAPasscode => 'Vyberte přístupový kód';

  @override
  String get pleaseChooseAUsername => 'Zvolte si prosím uživatelské jméno';

  @override
  String get pleaseClickOnLink => 'Klikněte na odkaz v e-mailu a pokračujte.';

  @override
  String get pleaseEnter4Digits =>
      'Chcete-li deaktivovat zámek aplikace, zadejte 4 číslice nebo nechte prázdné.';

  @override
  String get pleaseEnterAMatrixIdentifier =>
      'Prosím zadejte identifikátor sítě Matrix.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => 'Zadejte prosím své heslo';

  @override
  String get pleaseEnterYourPin => 'Zadejte svůj PIN';

  @override
  String get pleaseEnterYourUsername => 'Zadejte prosím své uživatelské jméno';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Postupujte podle pokynů na webu a klepněte na další.';

  @override
  String get privacy => 'Soukromí';

  @override
  String get publicRooms => 'Veřejné místnosti';

  @override
  String get pushRules => 'Pravidla push';

  @override
  String get reason => 'Důvod';

  @override
  String get recording => 'Nahrávání';

  @override
  String redactedAnEvent(Object username) {
    return '$username opravili událost';
  }

  @override
  String get redactMessage => 'Redigovat zprávu';

  @override
  String get register => 'Registrovat';

  @override
  String get reject => 'Zamítnout';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username odmítli pozvání';
  }

  @override
  String get rejoin => 'Znovu se připojte';

  @override
  String get remove => 'Odstranit';

  @override
  String get removeAllOtherDevices => 'Odstranit všechna další zařízení';

  @override
  String removedBy(Object username) {
    return 'Odstraněno $username';
  }

  @override
  String get removeDevice => 'Odstraňit zařízení';

  @override
  String get unbanFromChat => 'Zrušit zákaz chatu';

  @override
  String get removeYourAvatar => 'Odstraňte svého avatara';

  @override
  String get renderRichContent => 'Zobrazit bohatě vykreslený obsah zpráv';

  @override
  String get replaceRoomWithNewerVersion => 'Nahradit místnost novou verzí';

  @override
  String get reply => 'Odpovědět';

  @override
  String get reportMessage => 'Nahlásit zprávu';

  @override
  String get requestPermission => 'Vyžádat oprávnění';

  @override
  String get roomHasBeenUpgraded => 'Místnost byla upgradována';

  @override
  String get roomVersion => 'Verze místnosti';

  @override
  String get saturday => 'Sobota';

  @override
  String get saveFile => 'Uložit soubor';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Bezpečnostní';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyLost => 'Recovery key lost?';

  @override
  String seenByUser(Object username) {
    return 'Viděno uživatelem $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Viděno uživatelem $username a $count dalšími',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Viděno uživateli $username a $username2';
  }

  @override
  String get send => 'Odeslat';

  @override
  String get sendAMessage => 'Odeslat zprávu';

  @override
  String get sendAsText => 'Odeslat jako text';

  @override
  String get sendAudio => 'Odeslat audio';

  @override
  String get sendFile => 'Odeslat soubor';

  @override
  String get sendImage => 'Odeslat obrázek';

  @override
  String get sendMessages => 'Odeslat zprávy';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Odeslat originál';

  @override
  String get sendSticker => 'Odeslat nálepku';

  @override
  String get sendVideo => 'Odeslat video';

  @override
  String sentAFile(Object username) {
    return '$username poslali soubor';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username poslali zvukovou nahrávku';
  }

  @override
  String sentAPicture(Object username) {
    return '$username poslali obrázek';
  }

  @override
  String sentASticker(Object username) {
    return '$username poslali samolepku';
  }

  @override
  String sentAVideo(Object username) {
    return '$username poslali video';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName odeslal informace o hovoru';
  }

  @override
  String get separateChatTypes => 'Odděĺlit přímé chaty, skupiny a prostory';

  @override
  String get setAsCanonicalAlias => 'Nastavit jako hlavní alias';

  @override
  String get setCustomEmotes => 'Nastavit vlastní emotikony';

  @override
  String get setGroupDescription => 'Nastavit popis skupiny';

  @override
  String get setInvitationLink => 'Nastavit zvací odkaz';

  @override
  String get setPermissionsLevel => 'Nastavit úroveň oprávnění';

  @override
  String get setStatus => 'Nastavit stav';

  @override
  String get settings => 'Nastavení';

  @override
  String get share => 'Sdílet';

  @override
  String sharedTheLocation(Object username) {
    return '$username sdílel jejich polohu';
  }

  @override
  String get shareLocation => 'Sdílet polohu';

  @override
  String get showDirectChatsInSpaces =>
      'Zobrazit související přímé chaty ve službě Spaces';

  @override
  String get showPassword => 'Zobrazit heslo';

  @override
  String get signUp => 'Přihlásit se';

  @override
  String get singlesignon => 'Jedinečné přihlášení';

  @override
  String get skip => 'Přeskočit';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Zdrojové kódy';

  @override
  String get spaceIsPublic => 'Prostor je veřejný';

  @override
  String get spaceName => 'Název prostoru';

  @override
  String startedACall(Object senderName) {
    return '$senderName zahájil hovor';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Stav';

  @override
  String get statusExampleMessage => 'Jak se dneska máš?';

  @override
  String get submit => 'Odeslat';

  @override
  String get sunday => 'Neděle';

  @override
  String get synchronizingPleaseWait => 'Synchronizace ... Čekejte prosím.';

  @override
  String get systemTheme => 'Téma systému';

  @override
  String get theyDontMatch => 'Neshodují se';

  @override
  String get theyMatch => 'Shodují se';

  @override
  String get thisRoomHasBeenArchived => 'Tato místnost byla archivována.';

  @override
  String get thursday => 'Čtvrtek';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Přepnout Oblíbené';

  @override
  String get toggleMuted => 'Přepnout ztlumené';

  @override
  String get toggleUnread => 'Označit jako přečtené/nepřečtené';

  @override
  String get tooManyRequestsWarning =>
      'Příliš mnoho požadavků. Prosím zkuste to znovu později!';

  @override
  String get transferFromAnotherDevice => 'Přenos z jiného zařízení';

  @override
  String get tryToSendAgain => 'Zkuste odeslat znovu';

  @override
  String get tuesday => 'Úterý';

  @override
  String get unavailable => 'Nedostupní';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username zrušili zákaz pro $targetName';
  }

  @override
  String get unblockDevice => 'Odblokovat zařízení';

  @override
  String get unknownDevice => 'Neznámé zařízení';

  @override
  String get unknownEncryptionAlgorithm => 'Neznámý šifrovací algoritmus';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Neznámá událost „$type“';
  }

  @override
  String get unmuteChat => 'Zrušit ztlumení chatu';

  @override
  String get unpin => 'Odepnout zprávu';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount nepřečtené chaty',
      one: '1 nepřečtený chat',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username a $count dalších píší';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username a $username2 píší';
  }

  @override
  String userIsTyping(Object username) {
    return '$username píše';
  }

  @override
  String userLeftTheChat(Object username) {
    return '$username opustili chat';
  }

  @override
  String get username => 'Uživatelské jméno';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username poslali událost $type';
  }

  @override
  String get unverified => 'Neověřeno';

  @override
  String get verified => 'Ověřeno';

  @override
  String get verify => 'Ověřit';

  @override
  String get verifyStart => 'Zahájit ověření';

  @override
  String get verifySuccess => 'Ověření proběhlo úspěšně!';

  @override
  String get verifyTitle => 'Ověřuji druhý účet';

  @override
  String get videoCall => 'Video hovor';

  @override
  String get visibilityOfTheChatHistory => 'Viditelnost historie chatu';

  @override
  String get visibleForAllParticipants => 'Viditelné pro všechny účastnící se';

  @override
  String get visibleForEveryone => 'Viditelné pro všechny';

  @override
  String get voiceMessage => 'Hlasová zpráva';

  @override
  String get waitingPartnerAcceptRequest =>
      'Čeká se na potvrzení žádosti partnerem…';

  @override
  String get waitingPartnerEmoji => 'Čeká se na potvrzení emoji partnerem…';

  @override
  String get waitingPartnerNumbers => 'Čekání na partnera až přijme čísla…';

  @override
  String get wallpaper => 'Pozadí';

  @override
  String get warning => 'Varování!';

  @override
  String get wednesday => 'Středa';

  @override
  String get weSentYouAnEmail => 'Zaslali jsme vám e-mail';

  @override
  String get whoCanPerformWhichAction => 'Kdo může provést jakou akci';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Kdo se může připojit do této skupiny';

  @override
  String get whyDoYouWantToReportThis => 'Proč to chcete nahlásit?';

  @override
  String get wipeChatBackup =>
      'Chcete vymazat zálohu chatu a vytvořit nový bezpečnostní klíč?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'S těmito adresami můžete obnovit své heslo.';

  @override
  String get writeAMessage => 'Napište zprávu…';

  @override
  String get yes => 'Ano';

  @override
  String get you => 'Vy';

  @override
  String get youAreInvitedToThisChat => 'Jste zváni do tohoto chatu';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Tohoto chatu se nadále neúčastníte';

  @override
  String get youCannotInviteYourself => 'Nemůžete pozvat sami sebe';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Byl vám zablokován přístup k tomuto chatu';

  @override
  String get yourPublicKey => 'Váš veřejný klíč';

  @override
  String get messageInfo => 'Informace o zprávě';

  @override
  String get time => 'Čas';

  @override
  String get messageType => 'Typ zprávy';

  @override
  String get sender => 'Odesílatel';

  @override
  String get openGallery => 'Otevřít galerii';

  @override
  String get removeFromSpace => 'Odstranit z tohoto místa';

  @override
  String get addToSpaceDescription =>
      'Vyberte umístění, do kterého chcete tento chat přidat.';

  @override
  String get start => 'Start';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'To unlock your old messages, please enter your recovery key that has been generated in a previous session. Your recovery key is NOT your password.';

  @override
  String get addToStory => 'Přidat do příběhu';

  @override
  String get publish => 'Uveřejnit';

  @override
  String get whoCanSeeMyStories => 'Kdo může vidět moje příběhy?';

  @override
  String get unsubscribeStories => 'Odhlásit příběhy';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Tento uživatel zatím nic ve svém příběhu nezveřejnil';

  @override
  String get yourStory => 'Váš příběh';

  @override
  String get replyHasBeenSent => 'Odpověď byla odeslána';

  @override
  String videoWithSize(Object size) {
    return 'Video ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Příběh z $date:\n $body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Upozorňujeme, že lidé se ve vašem příběhu mohou navzájem vidět a kontaktovat.';

  @override
  String get whatIsGoingOn => 'Co se děje?';

  @override
  String get addDescription => 'Přidat popis';

  @override
  String get storyPrivacyWarning =>
      'Upozorňujeme, že lidé se ve vašem příběhu mohou navzájem vidět a kontaktovat. Vaše příběhy budou viditelné po dobu 24 hodin, ale není zaručeno, že budou smazány ze všech zařízení a serverů.';

  @override
  String get iUnderstand => 'Rozumím';

  @override
  String get openChat => 'Otevřete chat';

  @override
  String get markAsRead => 'Označit jako přečtené';

  @override
  String get reportUser => 'Nahlásit uživatele';

  @override
  String get dismiss => 'Zavrhnout';

  @override
  String get matrixWidgets => 'Matrix widgety';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reagoval s $reaction';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin => 'Opravdu chcete událost trvale odepnout?';

  @override
  String get emojis => 'Emojis';

  @override
  String get placeCall => 'Zavolejte';

  @override
  String get voiceCall => 'Hlasový hovor';

  @override
  String get unsupportedAndroidVersion => 'Nepodporovaná verze Androidu';

  @override
  String get unsupportedAndroidVersionLong =>
      'Tato funkce vyžaduje novější verzi Android. Zkontrolujte prosím aktualizace nebo podporu Lineage OS.';

  @override
  String get videoCallsBetaWarning =>
      'Upozorňujeme, že videohovory jsou aktuálně ve verzi beta. Nemusí fungovat podle očekávání nebo fungovat vůbec na všech platformách.';

  @override
  String get experimentalVideoCalls => 'Experimentální videohovory';

  @override
  String get emailOrUsername => 'E-mail nebo uživatelské jméno';

  @override
  String get indexedDbErrorTitle => 'Private mode issues';

  @override
  String get indexedDbErrorLong =>
      'The message storage is unfortunately not enabled in private mode by default.\nPlease visit\n - about:config\n - set dom.indexedDB.privateBrowsing.enabled to true\nOtherwise, it is not possible to run FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'Přepnout na účet $number';
  }

  @override
  String get nextAccount => 'Další účet';

  @override
  String get previousAccount => 'Předchozí účet';

  @override
  String get editWidgets => 'Upravit widgety';

  @override
  String get addWidget => 'Přidat widget';

  @override
  String get widgetVideo => 'Video';

  @override
  String get widgetEtherpad => 'Textová poznámka';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Vlastní';

  @override
  String get widgetName => 'Jméno';

  @override
  String get widgetUrlError => 'Toto není platná adresa URL.';

  @override
  String get widgetNameError => 'Zadejte jméno pro zobrazení.';

  @override
  String get errorAddingWidget => 'Chyba při přidávání widgetu.';

  @override
  String get youRejectedTheInvitation => 'Odmítli jste pozvání';

  @override
  String get youJoinedTheChat => 'Připojili jste se k chatu';

  @override
  String get youAcceptedTheInvitation => 'Přijal jsi pozvání';

  @override
  String youBannedUser(Object user) {
    return 'Zakázali jste uživatele $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Stáhli jste pozvánku pro uživatele $user';
  }

  @override
  String youInvitedBy(Object user) {
    return 'Byli jste pozváni uživatelem $user';
  }

  @override
  String youInvitedUser(Object user) {
    return 'Pozvali jste uživatele $user';
  }

  @override
  String youKicked(Object user) {
    return 'Vykopli jste uživatele $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return 'Vykopli jste a zakázali jste uživatele $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Zrušili jste zákaz uživateli $user';
  }

  @override
  String get noEmailWarning =>
      'Prosím zadejte platnou emailovou adresu. V opačném případě nebudete moci obnovit heslo. Pokud nechcete, pokračujte dalším klepnutím na tlačítko.';

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
      'Z bezpečnostních důvodů nemůžete vypnout šifrování v chatu, kde již bylo dříve zapnuto.';

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
  String get search => 'Hledat';

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
