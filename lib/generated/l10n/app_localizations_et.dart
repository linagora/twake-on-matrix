// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class L10nEt extends L10n {
  L10nEt([String locale = 'et']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Salasõnad ei klapi omavahel!';

  @override
  String get pleaseEnterValidEmail => 'Palun sisesta kehtiv e-posti aadress.';

  @override
  String get repeatPassword => 'Korda salasõna';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Palun vali pikkuseks vähemalt $min tähemärki.';
  }

  @override
  String get about => 'Rakenduse teave';

  @override
  String get updateAvailable => 'On olemas FluffyChat\'i uuendus';

  @override
  String get updateNow => 'Alusta uuendamist taustal';

  @override
  String get accept => 'Nõustu';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username võttis kutse vastu';
  }

  @override
  String get account => 'Kasutajakonto';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐$username võttis kasutusele läbiva krüptimise';
  }

  @override
  String get addEmail => 'Lisa e-posti aadress';

  @override
  String get confirmMatrixId =>
      'Konto kustutamiseks palun kinnitage oma Matrix\'i ID.';

  @override
  String supposedMxid(Object mxid) {
    return 'See peaks olema $mxid';
  }

  @override
  String get addGroupDescription => 'Lisa vestlusrühma kirjeldus';

  @override
  String get addToSpace => 'Lisa kogukonda';

  @override
  String get admin => 'Peakasutaja';

  @override
  String get alias => 'alias';

  @override
  String get all => 'Kõik';

  @override
  String get allChats => 'Kõik vestlused';

  @override
  String get commandHint_googly => 'Saada ühed otsivad silmad';

  @override
  String get commandHint_cuddle => 'Saada üks kaisutus';

  @override
  String get commandHint_hug => 'Saada üks kallistus';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName saatis sulle otsivad silmad';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName kaisutab sind';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName kallistab sind';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName vastas kõnele';
  }

  @override
  String get anyoneCanJoin => 'Kõik võivad liituda';

  @override
  String get appLock => 'Rakenduse lukustus';

  @override
  String get archive => 'Arhiiv';

  @override
  String get archivedRoom => 'Arhiveeritud jututuba';

  @override
  String get areGuestsAllowedToJoin => 'Kas külalised võivad liituda';

  @override
  String get areYouSure => 'Kas sa oled kindel?';

  @override
  String get areYouSureYouWantToLogout =>
      'Kas sa oled kindel, et soovid välja logida?';

  @override
  String get askSSSSSign =>
      'Selleks, et teist osapoolt identifitseerivat allkirja anda, palun sisesta oma turvahoidla paroolifraas või taastevõti.';

  @override
  String askVerificationRequest(Object username) {
    return 'Kas võtad vastu selle verifitseerimispalve kasutajalt $username?';
  }

  @override
  String get autoplayImages =>
      'Esita liikuvad kleepse ja emotikone automaatselt';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'See koduserver toetab Matrixi võrku sisselogimiseks:\n$serverVersions\nAga see rakendus toetab vaid järgmisi võimalusi:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Saada sõnum sisestusklahvi vajutusel';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'See koduserver toetab Matrixi spetsifikatsioonist järgmisi versioone:\n$serverVersions\nAga see rakendus toetab vaid järgmisi versioone: $supportedVersions';
  }

  @override
  String get banFromChat => 'Keela ligipääs vestlusele';

  @override
  String get banned => 'Ligipääs vestlusele on keelatud';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username keelas ligipääsu kasutajale $targetName';
  }

  @override
  String get blockDevice => 'Blokeeri seade';

  @override
  String get blocked => 'Blokeeritud';

  @override
  String get botMessages => 'Robotite sõnumid';

  @override
  String get bubbleSize => 'Jutumulli suurus';

  @override
  String get cancel => 'Katkesta';

  @override
  String cantOpenUri(Object uri) {
    return '$uri aadressi avamine ei õnnestu';
  }

  @override
  String get changeDeviceName => 'Muuda seadme nime';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username muutis vestluse tunnuspilti';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username muutis vestluse uueks kirjelduseks „$description“';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username muutis oma uueks kuvatavaks nimeks „$chatname“';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username muutis vestlusega seotud õigusi';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username muutis uueks kuvatavaks nimeks: $displayname';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username muutis külaliste ligipääsureegleid';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username muutis külaliste ligipääsureegleid järgnevalt: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username muutis sõnumite ajaloo nähtavust';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username muutis sõnumite ajaloo nähtavust järgnevalt: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username muutis liitumise reegleid';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username muutis liitumise reegleid järgnevalt: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username muutis oma tunnuspilti';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username muutis jututoa aliast';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username muutis kutse linki';
  }

  @override
  String get changePassword => 'Muuda salasõna';

  @override
  String get changeTheHomeserver => 'Muuda koduserverit';

  @override
  String get changeTheme => 'Muuda oma stiili';

  @override
  String get changeTheNameOfTheGroup => 'Muuda vestlusrühma nime';

  @override
  String get changeWallpaper => 'Muuda taustapilti';

  @override
  String get changeYourAvatar => 'Muuda oma tunnuspilti';

  @override
  String get channelCorruptedDecryptError => 'Kasutatud krüptimine on vigane';

  @override
  String get chat => 'Vestlus';

  @override
  String get yourUserId => 'Sinu kasutajatunnus:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'Sinu vestluste varundus on seadistatud.';

  @override
  String get chatBackup => 'Varunda vestlus';

  @override
  String get chatBackupDescription =>
      'Sinu vestluste varukoopia on krüptitud taastamiseks mõeldud turvavõtmega. Palun vaata, et sa seda ei kaota.';

  @override
  String get chatDetails => 'Vestluse teave';

  @override
  String get chatHasBeenAddedToThisSpace => 'Lisasime vestluse kogukonda';

  @override
  String get chats => 'Vestlused';

  @override
  String get chooseAStrongPassword => 'Vali korralik salasõna';

  @override
  String get chooseAUsername => 'Vali kasutajanimi';

  @override
  String get clearArchive => 'Kustuta arhiiv';

  @override
  String get close => 'Sulge';

  @override
  String get commandHint_markasdm => 'Märgi otsevestusluseks';

  @override
  String get commandHint_markasgroup => 'Märgi vestlusrühmaks';

  @override
  String get commandHint_ban =>
      'Sea sellele kasutajale antud jututoas suhtluskeeld';

  @override
  String get commandHint_clearcache => 'Tühjenda vahemälu';

  @override
  String get commandHint_create =>
      'Loo tühi vestlusrühm\nKrüptimise keelamiseks kasuta --no-encryption võtit';

  @override
  String get commandHint_discardsession => 'Loobu sessioonist';

  @override
  String get commandHint_dm =>
      'Alusta otsevestlust\nKrüptimise keelamiseks kasuta --no-encryption võtit';

  @override
  String get commandHint_html => 'Saada HTML-vormingus tekst';

  @override
  String get commandHint_invite => 'Kutsu see kasutaja antud jututuppa';

  @override
  String get commandHint_join => 'Liitu selle jututoaga';

  @override
  String get commandHint_kick => 'Eemalda antud kasutaja sellest jututoast';

  @override
  String get commandHint_leave => 'Lahku sellest jututoast';

  @override
  String get commandHint_me => 'Kirjelda ennast';

  @override
  String get commandHint_myroomavatar =>
      'Määra selles jututoas oma tunnuspilt (mxc-uri vahendusel)';

  @override
  String get commandHint_myroomnick => 'Määra selles jututoas oma kuvatav nimi';

  @override
  String get commandHint_op => 'Seadista selle kasutaja õigusi (vaikimisi: 50)';

  @override
  String get commandHint_plain => 'Saada vormindamata tekst';

  @override
  String get commandHint_react => 'Saada vastus reaktsioonina';

  @override
  String get commandHint_send => 'Saada sõnum';

  @override
  String get commandHint_unban =>
      'Eemalda sellelt kasutajalt antud jututoas suhtluskeeld';

  @override
  String get commandInvalid => 'Vigane käsk';

  @override
  String commandMissing(Object command) {
    return '$command ei ole käsk.';
  }

  @override
  String get compareEmojiMatch => 'Palun võrdle emotikone';

  @override
  String get compareNumbersMatch => 'Palun võrdle numbreid';

  @override
  String get configureChat => 'Seadista vestlust';

  @override
  String get confirm => 'Kinnita';

  @override
  String get connect => 'Ühenda';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'Sinu kontakt on kutsutud liituma vestlusrühma';

  @override
  String get containsDisplayName => 'Sisaldab kuvatavat nime';

  @override
  String get containsUserName => 'Sisaldab kasutajanime';

  @override
  String get contentHasBeenReported =>
      'Saatsime selle sisu kohta teate koduserveri haldajate';

  @override
  String get copiedToClipboard => 'Kopeerisin lõikelauale';

  @override
  String get copy => 'Kopeeri';

  @override
  String get copyToClipboard => 'Kopeeri lõikelauale';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Sõnumi dekrüptimine ei õnnestunud: $error';
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
  String get create => 'Loo';

  @override
  String createdTheChat(Object username) {
    return '💬 $username algatas vestluse';
  }

  @override
  String get createNewGroup => 'Loo uus vestlusrühm';

  @override
  String get createNewSpace => 'Uus kogukond';

  @override
  String get crossSigningEnabled => 'Risttunnustamine on kasutusel';

  @override
  String get currentlyActive => 'Hetkel aktiivne';

  @override
  String get darkTheme => 'Tume';

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
    return '$year.$month.$day';
  }

  @override
  String get deactivateAccountWarning =>
      'Järgnevaga eemaldatakse sinu konto kasutusest. Seda tegevust ei saa tagasi pöörata! Kas sa ikka oled kindel?';

  @override
  String get defaultPermissionLevel => 'Vaikimisi õigused';

  @override
  String get delete => 'Kustuta';

  @override
  String get deleteAccount => 'Kustuta kasutajakonto';

  @override
  String get deleteMessage => 'Kustuta sõnum';

  @override
  String get deny => 'Keela';

  @override
  String get device => 'Seade';

  @override
  String get deviceId => 'Seadme tunnus';

  @override
  String get devices => 'Seadmed';

  @override
  String get directChats => 'Otsevestlused';

  @override
  String get discover => 'Avasta';

  @override
  String get displaynameHasBeenChanged => 'Kuvatav nimi on muudetud';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Muuda';

  @override
  String get editBlockedServers => 'Muuda blokeeritud serverite loendit';

  @override
  String get editChatPermissions => 'Muuda vestluse õigusi';

  @override
  String get editDisplayname => 'Muuda kuvatavat nime';

  @override
  String get editRoomAliases => 'Muuda jututoa aliast';

  @override
  String get editRoomAvatar => 'Muuda jututoa tunnuspilti';

  @override
  String get emoteExists => 'Selline emotsioonitegevus on juba olemas!';

  @override
  String get emoteInvalid => 'Vigane emotsioonitegevuse lühikood!';

  @override
  String get emotePacks => 'Emotsioonitegevuste pakid jututoa jaoks';

  @override
  String get emoteSettings => 'Emotsioonitegevuste seadistused';

  @override
  String get emoteShortcode => 'Emotsioonitegevuse lühikood';

  @override
  String get emoteWarnNeedToPick =>
      'Sa pead valima emotsioonitegevuse lühikoodi ja pildi!';

  @override
  String get emptyChat => 'Vestlust pole olnud';

  @override
  String get enableEmotesGlobally =>
      'Võta emotsioonitegevuste pakid läbivalt kasutusele';

  @override
  String get enableEncryption => 'Kasuta krüptimist';

  @override
  String get enableEncryptionWarning =>
      'Sa ei saa hiljem enam krüptimist välja lülitada. Kas oled kindel?';

  @override
  String get encrypted => 'Krüptitud';

  @override
  String get encryption => 'Krüptimine';

  @override
  String get encryptionNotEnabled => 'Krüptimine ei ole kasutusel';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName lõpetas kõne';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Sisesta e-posti aadress';

  @override
  String get enterASpacepName => 'Sisesta kogukonna nimi';

  @override
  String get homeserver => 'Koduserver';

  @override
  String get enterYourHomeserver => 'Sisesta oma koduserveri aadress';

  @override
  String errorObtainingLocation(Object error) {
    return 'Viga asukoha tuvastamisel: $error';
  }

  @override
  String get everythingReady => 'Kõik on valmis!';

  @override
  String get extremeOffensive => 'Äärmiselt solvav';

  @override
  String get fileName => 'Faili nimi';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Fondi suurus';

  @override
  String get forward => 'Edasta';

  @override
  String get friday => 'Reede';

  @override
  String get fromJoining => 'Alates liitumise hetkest';

  @override
  String get fromTheInvitation => 'Kutse saamisest';

  @override
  String get goToTheNewRoom => 'Hakka kasutama uut jututuba';

  @override
  String get group => 'Vestlusrühm';

  @override
  String get groupDescription => 'Vestlusrühma kirjeldus';

  @override
  String get groupDescriptionHasBeenChanged =>
      'Vestlusrühma kirjeldus on muutunud';

  @override
  String get groupIsPublic => 'Vestlusrühm on avalik';

  @override
  String get groups => 'Vestlusrühmad';

  @override
  String groupWith(Object displayname) {
    return 'Vestlusrühm $displayname kasutajanimega';
  }

  @override
  String get guestsAreForbidden => 'Külalised ei ole lubatud';

  @override
  String get guestsCanJoin => 'Külalised võivad liituda';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username on võtnud tagasi $targetName kutse';
  }

  @override
  String get help => 'Abiteave';

  @override
  String get hideRedactedEvents => 'Peida muudetud sündmused';

  @override
  String get hideUnknownEvents => 'Peida tundmatud sündmused';

  @override
  String get howOffensiveIsThisContent => 'Kui solvav see sisu on?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identiteet';

  @override
  String get ignore => 'Eira';

  @override
  String get ignoredUsers => 'Eiratud kasutajad';

  @override
  String get ignoreListDescription =>
      'Sul on võimalik eirata neid kasutajaid, kes sind segavad. Oma isiklikku eiramisloendisse lisatud kasutajad ei saa sulle saata sõnumeid ega kutseid.';

  @override
  String get ignoreUsername => 'Eira kasutajanime';

  @override
  String get iHaveClickedOnLink => 'Ma olen klõpsinud saadetud linki';

  @override
  String get incorrectPassphraseOrKey => 'Vigane paroolifraas või taastevõti';

  @override
  String get inoffensive => 'Kahjutu';

  @override
  String get inviteContact => 'Kutsu sõpru ja tuttavaid';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Kutsu sõpru ja tuttavaid $groupName liikmeks';
  }

  @override
  String get invited => 'Kutsutud';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username saatis kutse kasutajale $targetName';
  }

  @override
  String get invitedUsersOnly => 'Ainult kutsutud kasutajatele';

  @override
  String get inviteForMe => 'Kutse minu jaoks';

  @override
  String inviteText(Object username, Object link) {
    return '$username kutsus sind kasutama Matrix\'i-põhist suhtlusrakendust FluffyChat. \n1. Paigalda FluffyChat: https://fluffychat.im \n2. Liitu kasutajaks või logi sisse olemasoleva Matrix\'i kasutajakontoga\n3. Ava kutse link: $link';
  }

  @override
  String get isTyping => 'kirjutab';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username liitus vestlusega';
  }

  @override
  String get joinRoom => 'Liitu jututoaga';

  @override
  String get keysCached => 'Krüptovõtmed on puhverdatud';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username müksas kasutaja $targetName välja';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅$username müksas kasutaja $targetName välja ning seadis talle suhtluskeelu';
  }

  @override
  String get kickFromChat => 'Müksa vestlusest välja';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Viimati nähtud: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Nähtud ammu aega tagasi';

  @override
  String get leave => 'Lahku';

  @override
  String get leftTheChat => 'Lahkus vestlusest';

  @override
  String get license => 'Litsents';

  @override
  String get lightTheme => 'Hele';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Lisa veel $count osalejat';
  }

  @override
  String get dehydrate =>
      'Ekspordi sessiooni teave ja kustuta nutiseadmest rakenduse andmed';

  @override
  String get dehydrateWarning =>
      'Seda tegevust ei saa tagasi pöörata. Palun kontrolli, et sa oled varukoopia turvaliselt salvestanud.';

  @override
  String get dehydrateShare =>
      'See on sinu FluffyChat\'i privaatsete andmete eksport. Palun hoia teda turvaliselt ja vaata, et sa seda ei kaotaks.';

  @override
  String get dehydrateTor => 'TOR\'i kasutajad: Ekspordi sessioon';

  @override
  String get dehydrateTorLong =>
      'Kui oled TOR\'i võrgu kasutaja, siis enne akna sulgemist palun ekspordi viimase sessiooni andmed.';

  @override
  String get hydrateTor =>
      'TOR\'i kasutajatele: impordi viimati eksporditud sessiooni andmed';

  @override
  String get hydrateTorLong =>
      'Kui viimati TOR\'i võrku kasutasid, siis kas sa eksportisid oma sessiooni andmed? Kui jah, siis impordi nad mugavasti ja jätka suhtlemist.';

  @override
  String get hydrate => 'Taasta varundatud failist';

  @override
  String get loadingPleaseWait => 'Laadin andmeid… Palun oota.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Laadi veel…';

  @override
  String get locationDisabledNotice =>
      'Asukohateenused on seadmes väljalülitatud. Asukoha jagamiseks palun lülita nad sisse.';

  @override
  String get locationPermissionDeniedNotice =>
      'Puudub luba asukohateenuste kasutamiseks. Asukoha jagamiseks palun anna rakendusele vastavad õigused.';

  @override
  String get login => 'Logi sisse';

  @override
  String logInTo(Object homeserver) {
    return 'Logi sisse $homeserver serverisse';
  }

  @override
  String get loginWithOneClick => 'Logi sisse ühe klõpsuga';

  @override
  String get logout => 'Logi välja';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Kontrolli, et see tunnus oleks õige';

  @override
  String get memberChanges => 'Muudatused liikmeskonnas';

  @override
  String get mention => 'Märgi ära';

  @override
  String get messages => 'Sõnumid';

  @override
  String get messageWillBeRemovedWarning =>
      'Sõnum eemaldatakse kõikidelt kasutajatelt';

  @override
  String get noSearchResult => 'Sobivaid otsingutulemusi ei leidu.';

  @override
  String get moderator => 'Moderaator';

  @override
  String get monday => 'Esmaspäev';

  @override
  String get muteChat => 'Summuta vestlus';

  @override
  String get needPantalaimonWarning =>
      'Palun arvesta, et sa saad hetkel kasutada läbivat krüptimist vaid siis, kui koduserver kasutab Pantalaimon\'it.';

  @override
  String get newChat => 'Uus vestlus';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Uus verifitseerimispäring!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Edasi';

  @override
  String get no => 'Ei';

  @override
  String get noConnectionToTheServer => 'Puudub ühendus koduserveriga';

  @override
  String get noEmotesFound => 'Ühtegi emotsioonitegevust ei leidunud. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Sa võid krüptimise kasutusele võtta niipea, kui jututuba pole enam avalik.';

  @override
  String get noGoogleServicesWarning =>
      'Tundub, et sinu nutiseadmes pole Google teenuseid. Sinu privaatsuse mõttes on see kindlasti hea otsus! Kui sa soovid FluffyChat\'is näha tõuketeavitusi, siis soovitame, et selle jaoks kasutad https://microg.org või https://unifiedpush.org liidestust.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 pole Matrix\'i server, kas kasutame selle asemel $server2 serverit?';
  }

  @override
  String get shareYourInviteLink => 'Jaga oma kutselinki';

  @override
  String get typeInInviteLinkManually => 'Sisesta kutse link käsitsi...';

  @override
  String get scanQrCode => 'Skaneeri QR-koodi';

  @override
  String get none => 'Mitte midagi';

  @override
  String get noPasswordRecoveryDescription =>
      'Sa pole veel lisanud võimalust salasõna taastamiseks.';

  @override
  String get noPermission => 'Õigused puuduvad';

  @override
  String get noRoomsFound => 'Jututubasid ei leidunud…';

  @override
  String get notifications => 'Teavitused';

  @override
  String numUsersTyping(Object count) {
    return '$count kasutajat kirjutavad';
  }

  @override
  String get obtainingLocation => 'Tuvastan asukohta…';

  @override
  String get offensive => 'Solvav';

  @override
  String get offline => 'Väljas';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'sobib';

  @override
  String get online => 'Saadaval';

  @override
  String get onlineKeyBackupEnabled =>
      'Krüptovõtmete veebipõhine varundus on kasutusel';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Hopsti! Kahjuks tekkis tõuketeavituste seadistamisel viga.';

  @override
  String get oopsSomethingWentWrong => 'Hopsti! Midagi läks nüüd viltu…';

  @override
  String get openAppToReadMessages => 'Sõnumite lugemiseks ava rakendus';

  @override
  String get openCamera => 'Ava kaamera';

  @override
  String get openVideoCamera => 'Video salvestamiseks ava kaamera';

  @override
  String get oneClientLoggedOut =>
      'Üks sinu klientrakendustest on Matrix\'i võrgust välja loginud';

  @override
  String get addAccount => 'Lisa kasutajakonto';

  @override
  String get editBundlesForAccount => 'Muuda selle kasutajakonto köiteid';

  @override
  String get addToBundle => 'Lisa köitesse';

  @override
  String get removeFromBundle => 'Eemalda sellest köitest';

  @override
  String get bundleName => 'Köite nimi';

  @override
  String get enableMultiAccounts =>
      '(KATSELINE) Pruugi selles seadmes mitut Matrix\'i kasutajakontot';

  @override
  String get openInMaps => 'Ava kaardirakendusega';

  @override
  String get link => 'Link';

  @override
  String get serverRequiresEmail =>
      'See koduserver eeldab registreerimisel kasutatava e-postiaadressi kinnitamist.';

  @override
  String get optionalGroupName => '(Kui soovid) Vestlusrühma nimi';

  @override
  String get or => 'või';

  @override
  String get participant => 'Osaleja';

  @override
  String get passphraseOrKey => 'paroolifraas või taastevõti';

  @override
  String get password => 'Salasõna';

  @override
  String get passwordForgotten => 'Salasõna on ununenud';

  @override
  String get passwordHasBeenChanged => 'Salasõna on muudetud';

  @override
  String get passwordRecovery => 'Salasõna taastamine';

  @override
  String get people => 'Inimesed';

  @override
  String get pickImage => 'Vali pilt';

  @override
  String get pin => 'Klammerda';

  @override
  String play(Object fileName) {
    return 'Esita $fileName';
  }

  @override
  String get pleaseChoose => 'Palun vali';

  @override
  String get pleaseChooseAPasscode => 'Palun vali rakenduse PIN-kood';

  @override
  String get pleaseChooseAUsername => 'Palun vali kasutajanimi';

  @override
  String get pleaseClickOnLink =>
      'Jätkamiseks palun klõpsi sulle saadetud e-kirjas leiduvat linki.';

  @override
  String get pleaseEnter4Digits =>
      'Rakenduse luku jaoks sisesta 4 numbrit või kui sa sellist võimalust ei soovi kasutada, siis jäta nad tühjaks.';

  @override
  String get pleaseEnterAMatrixIdentifier =>
      'Palun sisesta Matrix\'i kasutajatunnus.';

  @override
  String get pleaseEnterRecoveryKey => 'Palun sisesta oma taastevõti:';

  @override
  String get pleaseEnterYourPassword => 'Palun sisesta oma salasõna';

  @override
  String get pleaseEnterYourPin => 'Palun sisesta oma PIN-kood';

  @override
  String get pleaseEnterYourUsername => 'Palun sisesta oma kasutajanimi';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Palun järgi veebilehel olevaid juhiseid ja klõpsi nuppu Edasi.';

  @override
  String get privacy => 'Privaatsus';

  @override
  String get publicRooms => 'Avalikud jututoad';

  @override
  String get pushRules => 'Tõukereeglid';

  @override
  String get reason => 'Põhjus';

  @override
  String get recording => 'Salvestan';

  @override
  String redactedAnEvent(Object username) {
    return '$username muutis sündmust';
  }

  @override
  String get redactMessage => 'Muuda sõnumit';

  @override
  String get register => 'Registreeru';

  @override
  String get reject => 'Lükka tagasi';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username lükkas kutse tagasi';
  }

  @override
  String get rejoin => 'Liitu uuesti';

  @override
  String get remove => 'Eemalda';

  @override
  String get removeAllOtherDevices => 'Eemalda kõik muud seadmed';

  @override
  String removedBy(Object username) {
    return '$username eemaldas sündmuse';
  }

  @override
  String get removeDevice => 'Eemalda seade';

  @override
  String get unbanFromChat => 'Eemalda suhtluskeeld';

  @override
  String get removeYourAvatar => 'Kustuta oma tunnuspilt';

  @override
  String get renderRichContent => 'Visualiseeri vormindatud sõnumite sisu';

  @override
  String get replaceRoomWithNewerVersion =>
      'Asenda jututoa senine versioon uuega';

  @override
  String get reply => 'Vasta';

  @override
  String get reportMessage => 'Teata sõnumist';

  @override
  String get requestPermission => 'Palu õigusi';

  @override
  String get roomHasBeenUpgraded => 'Jututoa vesrioon on uuendatud';

  @override
  String get roomVersion => 'Jututoa versioon';

  @override
  String get saturday => 'Laupäev';

  @override
  String get saveFile => 'Salvesta fail';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Turvalisus';

  @override
  String get recoveryKey => 'Taastevõti';

  @override
  String get recoveryKeyLost => 'Kas taasetvõti on kadunud?';

  @override
  String seenByUser(Object username) {
    return 'Sõnumit nägi $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sõnumit nägid $username ja veel $count kasutajat',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Sõnumit nägid $username ja $username2';
  }

  @override
  String get send => 'Saada';

  @override
  String get sendAMessage => 'Saada sõnum';

  @override
  String get sendAsText => 'Saada tekstisõnumina';

  @override
  String get sendAudio => 'Saada helifail';

  @override
  String get sendFile => 'Saada fail';

  @override
  String get sendImage => 'Saada pilt';

  @override
  String get sendMessages => 'Saada sõnumeid';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Saada fail muutmata kujul';

  @override
  String get sendSticker => 'Saada kleeps';

  @override
  String get sendVideo => 'Saada videofail';

  @override
  String sentAFile(Object username) {
    return '📁 $username saatis faili';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username saatis helifaili';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username saatis pildi';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username saatis kleepsu';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username saatis video';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName saatis teavet kõne kohta';
  }

  @override
  String get separateChatTypes => 'Eraldi vestlused ja jututoad';

  @override
  String get setAsCanonicalAlias => 'Määra põhinimeks';

  @override
  String get setCustomEmotes => 'Kohanda emotsioonitegevusi';

  @override
  String get setGroupDescription => 'Seadista vestlusrühma kirjeldus';

  @override
  String get setInvitationLink => 'Tee kutselink';

  @override
  String get setPermissionsLevel => 'Seadista õigusi';

  @override
  String get setStatus => 'Määra olek';

  @override
  String get settings => 'Seadistused';

  @override
  String get share => 'Jaga';

  @override
  String sharedTheLocation(Object username) {
    return '$username jagas oma asukohta';
  }

  @override
  String get shareLocation => 'Jaga asukohta';

  @override
  String get showDirectChatsInSpaces =>
      'Näita kogukonnasga seotud otsevestlusi';

  @override
  String get showPassword => 'Näita salasõna';

  @override
  String get signUp => 'Liitu';

  @override
  String get singlesignon => 'Ühekordne sisselogimine';

  @override
  String get skip => 'Jäta vahele';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Lähtekood';

  @override
  String get spaceIsPublic => 'Kogukond on avalik';

  @override
  String get spaceName => 'Kogukonna nimi';

  @override
  String startedACall(Object senderName) {
    return '$senderName alustas kõnet';
  }

  @override
  String get startFirstChat => 'Alusta oma esimest vestlust';

  @override
  String get status => 'Olek';

  @override
  String get statusExampleMessage => 'Kuidas sul täna läheb?';

  @override
  String get submit => 'Saada';

  @override
  String get sunday => 'Pühapäev';

  @override
  String get synchronizingPleaseWait => 'Sünkroniseerin andmeid… Palun oota.';

  @override
  String get systemTheme => 'Süsteem';

  @override
  String get theyDontMatch => 'Nad ei klapi omavahel';

  @override
  String get theyMatch => 'Nad klapivad omavahel';

  @override
  String get thisRoomHasBeenArchived => 'See jututuba on arhiveeritud.';

  @override
  String get thursday => 'Neljapäev';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Muuda olekut lemmikuna';

  @override
  String get toggleMuted => 'Lülita summutamine sisse või välja';

  @override
  String get toggleUnread => 'Märgi loetuks / lugemata';

  @override
  String get tooManyRequestsWarning =>
      'Liiga palju päringuid. Palun proovi hiljem uuesti!';

  @override
  String get transferFromAnotherDevice => 'Tõsta teisest seadmest';

  @override
  String get tryToSendAgain => 'Proovi uuesti saata';

  @override
  String get tuesday => 'Teisipäev';

  @override
  String get unavailable => 'Eemal';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username eemaldas ligipääsukeelu kasutajalt $targetName';
  }

  @override
  String get unblockDevice => 'Eemalda seadmelt blokeering';

  @override
  String get unknownDevice => 'Tundmatu seade';

  @override
  String get unknownEncryptionAlgorithm => 'Tundmatu krüptoalgoritm';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Tundmatu sündmuse tüüp „$type“';
  }

  @override
  String get unmuteChat => 'Lõpeta vestluse vaigistamine';

  @override
  String get unpin => 'Eemalda klammerdus';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount lugemata vestlust',
      one: '1 lugemata vestlus',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username ja $count muud kirjutavad';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username ja $username2 kirjutavad';
  }

  @override
  String userIsTyping(Object username) {
    return '$username kirjutab';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪$username lahkus vestlusest';
  }

  @override
  String get username => 'Kasutajanimi';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username saatis $type sündmuse';
  }

  @override
  String get unverified => 'Verifitseerimata';

  @override
  String get verified => 'Verifitseeritud';

  @override
  String get verify => 'Verifitseeri';

  @override
  String get verifyStart => 'Alusta verifitseerimist';

  @override
  String get verifySuccess => 'Sinu verifitseerimine õnnestus!';

  @override
  String get verifyTitle => 'Verifitseerin teist kasutajakontot';

  @override
  String get videoCall => 'Videokõne';

  @override
  String get visibilityOfTheChatHistory => 'Vestluse ajaloo nähtavus';

  @override
  String get visibleForAllParticipants => 'Nähtav kõikidele osalejatele';

  @override
  String get visibleForEveryone => 'Nähtav kõikidele';

  @override
  String get voiceMessage => 'Häälsõnum';

  @override
  String get waitingPartnerAcceptRequest =>
      'Ootan, et teine osapool nõustuks päringuga…';

  @override
  String get waitingPartnerEmoji =>
      'Ootan teise osapoole kinnitust, et tegemist on samade emojidega…';

  @override
  String get waitingPartnerNumbers =>
      'Ootan teise osapoole kinnitust, et tegemist on samade numbritega…';

  @override
  String get wallpaper => 'Taustapilt';

  @override
  String get warning => 'Hoiatus!';

  @override
  String get wednesday => 'Kolmapäev';

  @override
  String get weSentYouAnEmail => 'Me saatsime sulle e-kirja';

  @override
  String get whoCanPerformWhichAction =>
      'Erinevatele kasutajatele lubatud toimingud';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Kes võivad selle vestlusrühmaga liituda';

  @override
  String get whyDoYouWantToReportThis => 'Miks sa soovid sellest teatada?';

  @override
  String get wipeChatBackup =>
      'Kas kustutame sinu vestluste varukoopia ja loome uue taastamiseks mõeldud krüptovõtme?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Nende e-posti aadresside abil saad taastada oma salasõna.';

  @override
  String get writeAMessage => 'Kirjuta üks sõnum…';

  @override
  String get yes => 'Jah';

  @override
  String get you => 'Sina';

  @override
  String get youAreInvitedToThisChat =>
      'Sa oled kutsutud osalema selles vestluses';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Sa enam ei osale selles vestluses';

  @override
  String get youCannotInviteYourself => 'Sa ei saa endale kutset saata';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Sinule on selles vestluses seatud suhtluskeeld';

  @override
  String get yourPublicKey => 'Sinu avalik võti';

  @override
  String get messageInfo => 'Sõnumi teave';

  @override
  String get time => 'Kellaaeg';

  @override
  String get messageType => 'Sõnumi tüüp';

  @override
  String get sender => 'Saatja';

  @override
  String get openGallery => 'Ava galerii';

  @override
  String get removeFromSpace => 'Eemalda kogukonnast';

  @override
  String get addToSpaceDescription =>
      'Vali kogukond, kuhu soovid seda vestlust lisada.';

  @override
  String get start => 'Alusta';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Vanade sõnumite lugemiseks palun siseta oma varasemas sessioonis loodud taastevõti. Taastamiseks mõeldud krüptovõti EI OLE sinu salasõna.';

  @override
  String get addToStory => 'Lisa jutustusele';

  @override
  String get publish => 'Avalda';

  @override
  String get whoCanSeeMyStories => 'Kes näeb minu jutustusi?';

  @override
  String get unsubscribeStories => 'Loobu jutustuste tellimusest';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'See kasutaja pole ühtegi jutustust veel avaldanud';

  @override
  String get yourStory => 'Sinu jutustused';

  @override
  String get replyHasBeenSent => 'Vastus on saadetud';

  @override
  String videoWithSize(Object size) {
    return 'Video ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Lugu $date:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Palun arvesta, et sinu jutustuste lugejad näevad üksteist ning saavad üksteisega suhelda.';

  @override
  String get whatIsGoingOn => 'Mis toimub?';

  @override
  String get addDescription => 'Lisa kirjeldus';

  @override
  String get storyPrivacyWarning =>
      'Palun arvesta, et sinu jutustuste lugejad näevad üksteist ning saavad üksteisega suhelda. Lood ise on loetavad vaid 24 tunni jooksul, kuid mitte miski ei taga, et nad kustutatakse kõikidest seadmetest ja serveritest.';

  @override
  String get iUnderstand => 'Ma mõistan';

  @override
  String get openChat => 'Ava vestlus';

  @override
  String get markAsRead => 'Märgi loetuks';

  @override
  String get reportUser => 'Teata kasutajast';

  @override
  String get dismiss => 'Loobu';

  @override
  String get matrixWidgets => 'Matrix\'i vidinad';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reageeris nii $reaction';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin =>
      'Kas sa oled kindel, et tahad klammerdatud sündmuse eemaldada?';

  @override
  String get emojis => 'Emotikonid';

  @override
  String get placeCall => 'Helista';

  @override
  String get voiceCall => 'Häälkõne';

  @override
  String get unsupportedAndroidVersion =>
      'See Androidi versioon ei ole toetatud';

  @override
  String get unsupportedAndroidVersionLong =>
      'See funktsionaalsus eeldab uuemat Androidi versiooni. Palun kontrolli, kas sinu nutiseadmele leidub süsteemiuuendusi või saaks seal Lineage OS\'i kasutada.';

  @override
  String get videoCallsBetaWarning =>
      'Palun arvesta, et videokõned on veel beetajärgus. Nad ei pruugi veel toimida kõikidel platvormidel korrektselt.';

  @override
  String get experimentalVideoCalls => 'Katselised videokõned';

  @override
  String get emailOrUsername => 'E-posti aadress või kasutajanimi';

  @override
  String get indexedDbErrorTitle =>
      'Brauseri privaatse akna kasutamisega seotud asjaolud';

  @override
  String get indexedDbErrorLong =>
      'Privaatse akna puhul andmete salvestamine vaikimisi pole kasutusel.\nPalun toimi alljärgnevalt:\n- ava about:config\n- määra dom.indexedDB.privateBrowsing.enabled väärtuseks true\nVastasel juhul sa ei saa FluffyChat\'i kasutada.';

  @override
  String switchToAccount(Object number) {
    return 'Pruugi kasutajakontot # $number';
  }

  @override
  String get nextAccount => 'Järgmine kasutajakonto';

  @override
  String get previousAccount => 'Eelmine kasutajakonto';

  @override
  String get editWidgets => 'Muuda vidinaid';

  @override
  String get addWidget => 'Lisa vidin';

  @override
  String get widgetVideo => 'Video';

  @override
  String get widgetEtherpad => 'Märkmed ja tekstid';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Kohandatud';

  @override
  String get widgetName => 'Nimi';

  @override
  String get widgetUrlError => 'See pole korrektne URL.';

  @override
  String get widgetNameError => 'Palun sisesta kuvatav nimi.';

  @override
  String get errorAddingWidget => 'Vidina lisamisel tekkis viga.';

  @override
  String get youRejectedTheInvitation => 'Sa lükkasid kutse tagasi';

  @override
  String get youJoinedTheChat => 'Sa liitusid vestlusega';

  @override
  String get youAcceptedTheInvitation => '👍 Sa võtsid kutse vastu';

  @override
  String youBannedUser(Object user) {
    return 'Sa seadsid suhtluskeelu kasutajale $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Sa oled tühistanud kutse kasutajale $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 $user saatis sulle kutse';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 Sa saatsid kutse kasutajale $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 Sa müksasid kasutaja $user välja';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅Sa müksasid kasutaja $user välja ning seadsid talle suhtluskeelu';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Sa eemaldasid suhtluskeelu kasutajalt $user';
  }

  @override
  String get noEmailWarning =>
      'Palun sisesta korrektne e-posti aadress. Vastasel juhul ei saa te oma salasõna taastada. Kui te seda ei soovi, siis jätkamiseks klõpsige nuppu uuesti.';

  @override
  String get stories => 'Jutustused';

  @override
  String get users => 'Kasutajad';

  @override
  String get enableAutoBackups => 'Võta kasutusele automaatne varundus';

  @override
  String get unlockOldMessages => 'Muuda vanad sõnumid loetavaks';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription =>
      'Salvesta taastevõti selle seadme turvahoidlas.';

  @override
  String get saveKeyManuallyDescription =>
      'Salvesta see krüptovõti kasutades selle süsteemi jagamisvalikuid või lõikelauda.';

  @override
  String get storeInAndroidKeystore => 'Vali salvestuskohaks Android KeyStore';

  @override
  String get storeInAppleKeyChain => 'Vali salvestuskohaks Apple KeyChain';

  @override
  String get storeSecurlyOnThisDevice => 'Salvesta turvaliselt selles seadmes';

  @override
  String countFiles(Object count) {
    return '$count faili';
  }

  @override
  String get user => 'Kasutaja';

  @override
  String get custom => 'Kohandatud';

  @override
  String get foregroundServiceRunning =>
      'See teavitus toimib siis, kui esiplaaniteenus töötab.';

  @override
  String get screenSharingTitle => 'ekraani jagamine';

  @override
  String get screenSharingDetail =>
      'Sa jagad oma ekraani FuffyChat\'i vahendusel';

  @override
  String get callingPermissions => 'Helistamise õigused';

  @override
  String get callingAccount => 'Helistamiskonto';

  @override
  String get callingAccountDetails =>
      'Võimaldab FluffyChat\'il kasutada Androidi helistamisrakendust.';

  @override
  String get appearOnTop => 'Luba pealmise rakendusena';

  @override
  String get appearOnTopDetails =>
      'Sellega lubad rakendust avada kõige pealmisena (pole vajalik, kui Fluffychat on juba seadistatud toimima helistamiskontoga)';

  @override
  String get otherCallingPermissions =>
      'Mikrofoni, kaamera ja muud FluffyChat\'i õigused';

  @override
  String get whyIsThisMessageEncrypted => 'Miks see sõnum pole loetav?';

  @override
  String get noKeyForThisMessage =>
      'See võib juhtuda, kui sõnum oli saadetud enne, kui siin seadmes oma kontoga sisse logisid.\n\nSamuti võib juhtuda siis, kui saatja on lugemises selles seadmes blokeerinud või on tekkinud tõrkeid veebiühenduses.\n\nAga mõnes teises seadmes saad seda sõnumit lugeda? Siis sa võid sõnumi sealt üle tõsta. Ava Seadistused -> Seadmed ning kontrolli, et kõik sinu seadmed on omavahel verifitseeritud. Kui avad selle vestluse või jututoa ning mõlemad sessioonid on avatud, siis vajalikud krüptovõtmed saadetakse automaatset.\n\nKas sa soovid vältida krüptovõtmete kadumist väljalogimisel ja seadmete vahetusel? Siis palun kontrolli, et seadistuses on krüptovõtmete varundus sisse lülitatud.';

  @override
  String get newGroup => 'Uus jututuba';

  @override
  String get newSpace => 'Uus kogukond';

  @override
  String get enterSpace => 'Sisene kogukonda';

  @override
  String get enterRoom => 'Ava jututuba';

  @override
  String get allSpaces => 'Kõik kogukonnad';

  @override
  String numChats(Object number) {
    return '$number vestlust';
  }

  @override
  String get hideUnimportantStateEvents => 'Peida väheolulised olekuteated';

  @override
  String get doNotShowAgain => 'Ära näita uuesti';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return 'Sõnumiteta vestlus (vana nimega $oldDisplayName)';
  }

  @override
  String get newSpaceDescription =>
      'Kogukonnad võimaldavad sul koondada erinevaid vestlusi ning korraldada avalikku või privaatset ühistegevust.';

  @override
  String get encryptThisChat => 'Krüpti see vestlus';

  @override
  String get endToEndEncryption => 'Läbiv krüptimine';

  @override
  String get disableEncryptionWarning =>
      'Kui vestluses on krüptimine kasutusele võetud, siis turvalisuse huvides ei saa seda hiljem välja lülitada.';

  @override
  String get sorryThatsNotPossible => 'Vabandust... see ei ole võimalik';

  @override
  String get deviceKeys => 'Seadme võtmed:';

  @override
  String get letsStart => 'Sõidame!';

  @override
  String get enterInviteLinkOrMatrixId => 'Sisesta kutse link või Matrix ID...';

  @override
  String get reopenChat => 'Alusta vestlust uuesti';

  @override
  String get noBackupWarning =>
      'Hoiatus! Kui sa ei lülita sisse vestluse varundust, siis sul puudub hiljem ligipääs krüptitud sõnumitele. Me tungivalt soovitame, et palun lülita vestluse varundamine sisse enne väljalogimist.';

  @override
  String get noOtherDevicesFound => 'Muid seadmeid ei leidu';

  @override
  String get fileIsTooBigForServer =>
      'Serveri seadistuste alusel on see fail saatmiseks liiga suur.';

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
  String get search => 'Otsi';

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
