// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class L10nLt extends L10n {
  L10nLt([String locale = 'lt']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Slaptažodžiai nesutampa!';

  @override
  String get pleaseEnterValidEmail => 'Įveskite teisingą el. pašto adresą.';

  @override
  String get repeatPassword => 'Pakartokite slaptažodį';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Pasirinkite bent $min simbolius.';
  }

  @override
  String get about => 'Apie';

  @override
  String get updateAvailable => 'Galimas FluffyChat atnaujinimas';

  @override
  String get updateNow => 'Pradėti atnaujinimą fone';

  @override
  String get accept => 'Sutinku';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username priėmė kvietimą';
  }

  @override
  String get account => 'Paskyra';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username aktyvavo visapusį šifravimą';
  }

  @override
  String get addEmail => 'Pridėti el. paštą';

  @override
  String get confirmMatrixId =>
      'Norėdami ištrinti savo paskyrą, patvirtinkite savo Matrix ID.';

  @override
  String supposedMxid(Object mxid) {
    return 'Tai turėtų būti $mxid';
  }

  @override
  String get addGroupDescription => 'Pridėkite grupės aprašymą';

  @override
  String get addToSpace => 'Pridėti į erdvę';

  @override
  String get admin => 'Administratorius';

  @override
  String get alias => 'slapyvardis';

  @override
  String get all => 'Visi';

  @override
  String get allChats => 'Visi pokalbiai';

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
    return '$senderName atsiliepė į skambutį';
  }

  @override
  String get anyoneCanJoin => 'Bet kas gali prisijungti';

  @override
  String get appLock => 'Programos užraktas';

  @override
  String get archive => 'Archyvas';

  @override
  String get archivedRoom => 'Archyvuotas kambarys';

  @override
  String get areGuestsAllowedToJoin => 'Ar svečiams leidžiama prisijungti';

  @override
  String get areYouSure => 'Ar esate tikri?';

  @override
  String get areYouSureYouWantToLogout => 'Ar tikrai norite atsijungti?';

  @override
  String get askSSSSSign =>
      'Kad galėtumėte prijungti kitą asmenį, įveskite savo saugyklos slaptafrazę arba atkūrimo raktą.';

  @override
  String askVerificationRequest(Object username) {
    return 'Priimti šią patvirtinimo užklausą iš $username?';
  }

  @override
  String get autoplayImages =>
      'Automatiškai leisti animuotus lipdukus ir jaustukus';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Namų serveris palaiko šiuos prisijungimo tipus:\n$serverVersions\nTačiau ši programa palaiko tik:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Išsiųsti paspaudus Enter';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Namų serveris palaiko spec. versijas:\n$serverVersions\nTačiau ši programa palaiko tik $supportedVersions';
  }

  @override
  String get banFromChat => 'Užblokuoti iš pokalbio';

  @override
  String get banned => 'Užblokuotas';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username užblokavo $targetName';
  }

  @override
  String get blockDevice => 'Blokuoti įrenginį';

  @override
  String get blocked => 'Užblokuotas';

  @override
  String get botMessages => 'Botų žinutės';

  @override
  String get bubbleSize => 'Burbulo dydis';

  @override
  String get cancel => 'Atšaukti';

  @override
  String cantOpenUri(Object uri) {
    return 'Nepavyksta atidaryti URI $uri';
  }

  @override
  String get changeDeviceName => 'Pakeisti įrenginio vardą';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username pakeitė pokalbio avatarą';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username pakeitė pokalbio aprašymą į: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username pakeitė pokalbio pavadinimą į: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username pakeitė pokalbių leidimus';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username pakeitė rodomą vardą į: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username pakeitė svečio prieigos taisykles';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username pakeitė svečio prieigos taisykles į: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username pakeitė istorijos matomumą';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username pakeitė istorijos matomumą į: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username pakeitė prisijungimo taisykles';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username pakeitė prisijungimo taisykles į: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username pakeitė savo avatarą';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username pakeitė kambario pseudonimus';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username pakeitė pakvietimo nuorodą';
  }

  @override
  String get changePassword => 'Keisti slaptažodį';

  @override
  String get changeTheHomeserver => 'Pakeisti namų serverį';

  @override
  String get changeTheme => 'Keisti savo stilių';

  @override
  String get changeTheNameOfTheGroup => 'Keisti grupės pavadinimą';

  @override
  String get changeWallpaper => 'Keisti ekrano užsklandą';

  @override
  String get changeYourAvatar => 'Keisti savo avatarą';

  @override
  String get channelCorruptedDecryptError => 'Šifravimas buvo sugadintas';

  @override
  String get chat => 'Pokalbis';

  @override
  String get yourUserId => 'Tavo vartotojo ID:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'Jūsų pokalbio atsarginė kopija buvo nustatyta.';

  @override
  String get chatBackup => 'Pokalbio atsargine kopija';

  @override
  String get chatBackupDescription =>
      'Jūsų senos žinutės yra apsaugotos atkūrimo raktu. Pasirūpinkite, kad jo neprarastumėte.';

  @override
  String get chatDetails => 'Pokalbio detalės';

  @override
  String get chatHasBeenAddedToThisSpace =>
      'Pokalbis buvo pridėtas prie šios erdvės';

  @override
  String get chats => 'Pokalbiai';

  @override
  String get chooseAStrongPassword => 'Pasirinkite saugų slaptažodį';

  @override
  String get chooseAUsername => 'Pasirinkite vartotojo vardą';

  @override
  String get clearArchive => 'Išvalyti archyvą';

  @override
  String get close => 'Uždaryti';

  @override
  String get commandHint_markasdm =>
      'Pažymėti kaip tiesioginio pokalbio kambarį';

  @override
  String get commandHint_markasgroup => 'Pažymėti kaip grupę';

  @override
  String get commandHint_ban => 'Užblokuoti vartotoją šiame kambaryje';

  @override
  String get commandHint_clearcache => 'Išvalyti laikiną talpyklą';

  @override
  String get commandHint_create =>
      'Sukurti tuščią grupinį pokalbį\nNaudokite --no-encryption kad išjungti šifravimą';

  @override
  String get commandHint_discardsession => 'Atmesti sesiją';

  @override
  String get commandHint_dm =>
      'Pradėti tiesioginį pokalbį\nNaudokite --no-encryption kad išjungti šifravimą';

  @override
  String get commandHint_html => 'Siųsti tekstą HTML formatu';

  @override
  String get commandHint_invite => 'Pakviesti vartotoją į šitą kambarį';

  @override
  String get commandHint_join => 'Prisijungti prie nurodyto kambario';

  @override
  String get commandHint_kick => 'Pašalinti vartotoja iš šito kambario';

  @override
  String get commandHint_leave => 'Palikti pokalbių kambarį';

  @override
  String get commandHint_me => 'Apibūdinkite save';

  @override
  String get commandHint_myroomavatar =>
      'Nustatyti savo nuotrauką šiame kambaryje (su mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Nustatyti savo rodomą vardą šiame kambaryje';

  @override
  String get commandHint_op =>
      'Nustatyti naudotojo galios lygį (numatytasis: 50)';

  @override
  String get commandHint_plain => 'Siųsti neformatuotą tekstą';

  @override
  String get commandHint_react => 'Siųsti atsakymą kaip reakciją';

  @override
  String get commandHint_send => 'Siųsti tekstą';

  @override
  String get commandHint_unban => 'Atblokuoti vartotoją šiame kambaryje';

  @override
  String get commandInvalid => 'Neteisinga komanda';

  @override
  String commandMissing(Object command) {
    return '$command nėra komanda.';
  }

  @override
  String get compareEmojiMatch => 'Palyginkite jaustukus';

  @override
  String get compareNumbersMatch => 'Palyginkite skaičius';

  @override
  String get configureChat => 'Konfigūruoti pokalbį';

  @override
  String get confirm => 'Patvirtinti';

  @override
  String get connect => 'Prisijungti';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'Kontaktas buvo pakviestas į grupę';

  @override
  String get containsDisplayName => 'Turi rodomą vardą';

  @override
  String get containsUserName => 'Turi vartotojo vardą';

  @override
  String get contentHasBeenReported =>
      'Apie turinį pranešta serverio administratoriams';

  @override
  String get copiedToClipboard => 'Nukopijuota į iškarpinę';

  @override
  String get copy => 'Kopijuoti';

  @override
  String get copyToClipboard => 'Koipjuoti į iškarpinę';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Nepavyko iššifruoti pranešimo: $error';
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
  String get create => 'Sukurti';

  @override
  String createdTheChat(Object username) {
    return '💬 $username sukūrė pokalbį';
  }

  @override
  String get createNewGroup => 'Sukurti naują grupę';

  @override
  String get createNewSpace => 'Nauja erdvė';

  @override
  String get crossSigningEnabled => 'Kryžminis pasirašymas įjungtas';

  @override
  String get currentlyActive => 'Šiuo metu aktyvus';

  @override
  String get darkTheme => 'Tamsi';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$month-$day';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$year-$month-$day';
  }

  @override
  String get deactivateAccountWarning =>
      'Tai deaktyvuos jūsų vartotojo paskyrą. Tai negali būti atšaukta! Ar jūs tuo tikri?';

  @override
  String get defaultPermissionLevel => 'Numatytasis teisių lygis';

  @override
  String get delete => 'Ištrinti';

  @override
  String get deleteAccount => 'Panaikinti paskyra';

  @override
  String get deleteMessage => 'Ištrinti žinutę';

  @override
  String get deny => 'Atmesti';

  @override
  String get device => 'Įrenginys';

  @override
  String get deviceId => 'Įrenginio ID';

  @override
  String get devices => 'Įrenginiai';

  @override
  String get directChats => 'Tiesioginiai pokalbiai';

  @override
  String get discover => 'Rasti';

  @override
  String get displaynameHasBeenChanged => 'Rodomas vardas buvo pakeistas';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Redaguoti';

  @override
  String get editBlockedServers => 'Redaguoti blokuotus serverius';

  @override
  String get editChatPermissions => 'Redaguoti pokalbio leidimus';

  @override
  String get editDisplayname => 'Redaguoti rodomą vardą';

  @override
  String get editRoomAliases => 'Redaguoti kambario pseudonimus';

  @override
  String get editRoomAvatar => 'Redaguoti kambario avatarą';

  @override
  String get emoteExists => 'Jaustukas jau egzistuoja!';

  @override
  String get emoteInvalid => 'Neteisingas jaustuko trumpasis kodas!';

  @override
  String get emotePacks => 'Jaustukų paketai kambariui';

  @override
  String get emoteSettings => 'Jaustukų nustatymai';

  @override
  String get emoteShortcode => 'Jaustuko trumpasis kodas';

  @override
  String get emoteWarnNeedToPick =>
      'Turite pasirinkti jaustuko trumpąjį kodą ir paveiksliuką!';

  @override
  String get emptyChat => 'Tuščias pokalbis';

  @override
  String get enableEmotesGlobally => 'Įgalinti jaustukų paketą visur';

  @override
  String get enableEncryption => 'Aktyvuoti šifravimą';

  @override
  String get enableEncryptionWarning =>
      'Šifravimo nebegalėsite išjungti. Ar jūs tuo tikri?';

  @override
  String get encrypted => 'Užšifruotas';

  @override
  String get encryption => 'Šifravimas';

  @override
  String get encryptionNotEnabled => 'Šifravimas aktyvuotas';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName baigė skambutį';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Įveskite el. pašto adresą';

  @override
  String get enterASpacepName => 'Įveskite erdvės vardą';

  @override
  String get homeserver => 'Namų serveris';

  @override
  String get enterYourHomeserver => 'Įveskite namų serverį';

  @override
  String errorObtainingLocation(Object error) {
    return 'Klaida nustatant vietą: $error';
  }

  @override
  String get everythingReady => 'Viskas paruošta!';

  @override
  String get extremeOffensive => 'Itin įžeidžiantis';

  @override
  String get fileName => 'Failo vardas';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Šrifto dydis';

  @override
  String get forward => 'Toliau';

  @override
  String get friday => 'Penktadienis';

  @override
  String get fromJoining => 'Nuo prisijungimo';

  @override
  String get fromTheInvitation => 'Nuo pakvietimo';

  @override
  String get goToTheNewRoom => 'Eiti į naują kambarį';

  @override
  String get group => 'Grupė';

  @override
  String get groupDescription => 'Grupės aprašymas';

  @override
  String get groupDescriptionHasBeenChanged => 'Grupės aprašymas pakeistas';

  @override
  String get groupIsPublic => 'Grupė yra vieša';

  @override
  String get groups => 'Grupės';

  @override
  String groupWith(Object displayname) {
    return 'Grupė su $displayname';
  }

  @override
  String get guestsAreForbidden => 'Svečiams draudžiama';

  @override
  String get guestsCanJoin => 'Svečiai gali prisijungti';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username atšaukė $targetName kvietimą';
  }

  @override
  String get help => 'Pagalba';

  @override
  String get hideRedactedEvents => 'Slėpti pašalintus įvykius';

  @override
  String get hideUnknownEvents => 'Slėpti nežinomus įvykius';

  @override
  String get howOffensiveIsThisContent => 'Kiek įžeižiantis šis turinys?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Tapatybė';

  @override
  String get ignore => 'Ignoruoti';

  @override
  String get ignoredUsers => 'Ignoruoti vartotojai';

  @override
  String get ignoreListDescription =>
      'Galite ignoruoti vartotojus, kurie jums trukdo. Negalėsite gauti jokių pranešimų ar kvietimų į kambarį iš vartotojų, įtrauktų į asmeninį ignoruojamųjų sąrašą.';

  @override
  String get ignoreUsername => 'Ignoruoti vartotoją';

  @override
  String get iHaveClickedOnLink => 'Aš paspaudžiau nuorodą';

  @override
  String get incorrectPassphraseOrKey =>
      'Neteisinga slaptafrazė arba atkūrimo raktas';

  @override
  String get inoffensive => 'Neįžeidžiantis';

  @override
  String get inviteContact => 'Pakviesti kontaktą';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Pakviesti kontaktą į $groupName';
  }

  @override
  String get invited => 'Pakviestas';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username pakvietė $targetName';
  }

  @override
  String get invitedUsersOnly => 'Tik pakviesti vartotojai';

  @override
  String get inviteForMe => 'Pakvietimas man';

  @override
  String inviteText(Object username, Object link) {
    return '$username pakvietė jus prisijungti prie FluffyChat. \n1. Įdiekite FluffyChat: https://fluffychat.im \n2. Prisiregistruokite arba prisijunkite \n3. Atidarykite pakvietimo nuorodą: $link';
  }

  @override
  String get isTyping => 'rašo';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username prisijungė prie pokalbio';
  }

  @override
  String get joinRoom => 'Prisijungti prie kambario';

  @override
  String get keysCached => 'Raktai talpinami į atmintinę';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username išmetė $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username išmetė ir užblokavo $targetName';
  }

  @override
  String get kickFromChat => 'Išmesti iš pokalbio';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Paskutinis aktyvumas: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Seniai matytas';

  @override
  String get leave => 'Palikti';

  @override
  String get leftTheChat => 'Paliko pokalbį';

  @override
  String get license => 'Licencija';

  @override
  String get lightTheme => 'Šviesi';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Įkelti dar $count dalyvius';
  }

  @override
  String get dehydrate => 'Eksportuoti sesiją ir išvalyti įrenginį';

  @override
  String get dehydrateWarning =>
      'Šio veiksmo negalima atšaukti. Įsitikinkite, kad saugiai saugote atsarginę kopiją.';

  @override
  String get dehydrateShare =>
      'Tai jūsų privatus FluffyChat eksportas. Pasirūpinkite, kad jo neprarastumėte ir išsaugotumėte privatumą.';

  @override
  String get dehydrateTor => 'TOR Naudotojai: Eksportuoti sesiją';

  @override
  String get dehydrateTorLong =>
      'TOR naudotojams rekomenduojama eksportuoti sesiją prieš uždarant langą.';

  @override
  String get hydrateTor => 'TOR Naudotojai: Importuoti sesijos eksportą';

  @override
  String get hydrateTorLong =>
      'Ar paskutinį kartą eksportavote savo sesiją naudodami TOR? Greitai ją importuokite ir tęskite pokalbį.';

  @override
  String get hydrate => 'Atkurti iš atsarginės kopijos failo';

  @override
  String get loadingPleaseWait => 'Kraunama… Prašome palaukti.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Rodyti daugiau…';

  @override
  String get locationDisabledNotice =>
      'Vietos nustatymo paslaugos yra išjungtos. Kad galėtumėte bendrinti savo buvimo vietą, įjunkite jas.';

  @override
  String get locationPermissionDeniedNotice =>
      'Vietos leidimas atmestas. Suteikite leidimą kad galėtumėte bendrinti savo vietą.';

  @override
  String get login => 'Prisijungti';

  @override
  String logInTo(Object homeserver) {
    return 'Prisijungti prie $homeserver';
  }

  @override
  String get loginWithOneClick => 'Prisijungti vienu paspaudimu';

  @override
  String get logout => 'Atsijungti';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Įsitikinkite, kad indentifikatorius galiojantis';

  @override
  String get memberChanges => 'Narių pokyčiai';

  @override
  String get mention => 'Paminėti';

  @override
  String get messages => 'Žinutės';

  @override
  String get messageWillBeRemovedWarning =>
      'Žinutė bus pašalinta visiem dalyviams';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'Moderatorius';

  @override
  String get monday => 'Pirmadienis';

  @override
  String get muteChat => 'Nutildyti pokalbį';

  @override
  String get needPantalaimonWarning =>
      'Atminkite, kad norint naudoti end-to-end šifravimą, reikalingas Pantalaimon.';

  @override
  String get newChat => 'Naujas pokalbis';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Nauja patvirtinimo užklausa!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Toliau';

  @override
  String get no => 'Ne';

  @override
  String get noConnectionToTheServer => 'Nėra ryšio su serveriu';

  @override
  String get noEmotesFound => 'Nerasta jaustukų. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Šifravimą galite suaktyvinti tik tada, kai kambarys nebebus viešai pasiekiamas.';

  @override
  String get noGoogleServicesWarning =>
      'Atrodo, kad jūsų telefone nėra Google Services. Tai geras sprendimas jūsų privatumui! Norėdami gauti tiesioginius pranešimus FluffyChat, rekomenduojame naudoti https://microg.org/ arba https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 nėra Matrix serveris, ar vietoj jo naudoti $server2?';
  }

  @override
  String get shareYourInviteLink => 'Bendrinti savo pakvietimo nuorodą';

  @override
  String get typeInInviteLinkManually =>
      'Įvesti pakvietimo nuorodą rankiniu būdu...';

  @override
  String get scanQrCode => 'Nuskanuokite QR kodą';

  @override
  String get none => 'Nė vienas';

  @override
  String get noPasswordRecoveryDescription =>
      'Dar nepridėjote slaptažodžio atkūrimo būdo.';

  @override
  String get noPermission => 'Nėra leidimo';

  @override
  String get noRoomsFound => 'Nerasta kambarių…';

  @override
  String get notifications => 'Pranešimai';

  @override
  String numUsersTyping(Object count) {
    return '$count vartotojai rašo';
  }

  @override
  String get obtainingLocation => 'Gaunama vieta…';

  @override
  String get offensive => 'Agresyvus';

  @override
  String get offline => 'Neprisijungta';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'OK';

  @override
  String get online => 'Prisijungta';

  @override
  String get onlineKeyBackupEnabled =>
      'Internetinė atsarginė raktų kopija įjungta';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Oi! Deja, nustatant tiesioginius pranešimus įvyko klaida.';

  @override
  String get oopsSomethingWentWrong => 'Oi, kažkas nutiko ne taip…';

  @override
  String get openAppToReadMessages =>
      'Atidarykite programėlę, kad perskaityti žinutes';

  @override
  String get openCamera => 'Atidarykite kamerą';

  @override
  String get openVideoCamera => 'Atidarykite kamerą vaizdo įrašui';

  @override
  String get oneClientLoggedOut => 'Vienas iš jūsų klientų atsijungė';

  @override
  String get addAccount => 'Pridėti paskyrą';

  @override
  String get editBundlesForAccount => 'Redaguoti šios paskyros paketus';

  @override
  String get addToBundle => 'Pridėti prie paketų';

  @override
  String get removeFromBundle => 'Pašalinkite iš šio paketo';

  @override
  String get bundleName => 'Paketo vardas';

  @override
  String get enableMultiAccounts =>
      '(BETA) Įgalinkite kelias paskyras šiame įrenginyje';

  @override
  String get openInMaps => 'Atidaryti žemėlapiuose';

  @override
  String get link => 'Nuoroda';

  @override
  String get serverRequiresEmail =>
      'Šis serveris turi patvirtinti jūsų el. pašto adresą registracijai.';

  @override
  String get optionalGroupName => '(Nebūtina) Grupės pavadinimas';

  @override
  String get or => 'Arba';

  @override
  String get participant => 'Dalyvis';

  @override
  String get passphraseOrKey => 'Slapta frazė arba atkūrimo raktas';

  @override
  String get password => 'Slaptažodis';

  @override
  String get passwordForgotten => 'Slaptažodis užmirštas';

  @override
  String get passwordHasBeenChanged => 'Slaptažodis pakeistas';

  @override
  String get passwordRecovery => 'Slaptažodžio atkūrimas';

  @override
  String get people => 'Žmonės';

  @override
  String get pickImage => 'Pasirinkite paveiksliuką';

  @override
  String get pin => 'Prisegti';

  @override
  String play(Object fileName) {
    return 'Groti $fileName';
  }

  @override
  String get pleaseChoose => 'Prašome pasirinkti';

  @override
  String get pleaseChooseAPasscode => 'Pasirinkite slaptą kodą';

  @override
  String get pleaseChooseAUsername => 'Pasirinkite vartotojo vardą';

  @override
  String get pleaseClickOnLink =>
      'Paspauskite nuorodą el. pašte ir tęskite toliau.';

  @override
  String get pleaseEnter4Digits =>
      'Įveskite 4 skaitmenis arba palikite tuščią, jei norite išjungti programėlės užraktą.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Įveskite Matrix ID.';

  @override
  String get pleaseEnterRecoveryKey => 'Įveskite savo atkūrimo raktą:';

  @override
  String get pleaseEnterYourPassword => 'Įveskite savo slaptažodį';

  @override
  String get pleaseEnterYourPin => 'Įveskite savo PIN kodą';

  @override
  String get pleaseEnterYourUsername => 'Įveskite savo vartotojo vardą';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Vadovaukitės svetainėje pateiktais nurodymais ir bakstelėkite Toliau.';

  @override
  String get privacy => 'Privatumas';

  @override
  String get publicRooms => 'Vieši kambariai';

  @override
  String get pushRules => 'Tiesioginių pranešimų taisyklės';

  @override
  String get reason => 'Priežastis';

  @override
  String get recording => 'Įrašymas';

  @override
  String redactedAnEvent(Object username) {
    return '$username pašalino įvykį';
  }

  @override
  String get redactMessage => 'Pašalinti žinutę';

  @override
  String get register => 'Registruotis';

  @override
  String get reject => 'Atmesti';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username atmetė kvietimą';
  }

  @override
  String get rejoin => 'Vėl prisijungti';

  @override
  String get remove => 'Pašalinti';

  @override
  String get removeAllOtherDevices => 'Pašalinti visus kitus įrenginius';

  @override
  String removedBy(Object username) {
    return 'Pašalino vartotojas $username';
  }

  @override
  String get removeDevice => 'Pašalinti įrenginį';

  @override
  String get unbanFromChat => 'Atblokuoti pokalbyje';

  @override
  String get removeYourAvatar => 'Pašalinti savo avatarą';

  @override
  String get renderRichContent => 'Atvaizduoti turtingą žinutės turinį';

  @override
  String get replaceRoomWithNewerVersion => 'Pakeisti kambarį naujesne versija';

  @override
  String get reply => 'Atsakyti';

  @override
  String get reportMessage => 'Pranešti apie žinutę';

  @override
  String get requestPermission => 'Prašyti leidimo';

  @override
  String get roomHasBeenUpgraded => 'Kambarys buvo atnaujintas';

  @override
  String get roomVersion => 'Kambario versija';

  @override
  String get saturday => 'Šeštadienis';

  @override
  String get saveFile => 'Išsaugoti failą';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Apsauga';

  @override
  String get recoveryKey => 'Atkūrimo raktas';

  @override
  String get recoveryKeyLost => 'Pamestas atkūrimo raktas?';

  @override
  String seenByUser(Object username) {
    return 'Matė $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Matė $username ir $count kiti',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Matė $username ir $username2';
  }

  @override
  String get send => 'Siųsti';

  @override
  String get sendAMessage => 'Siųsti žinutę';

  @override
  String get sendAsText => 'Siųsti kaip tekstą';

  @override
  String get sendAudio => 'Siųsti garso įrašą';

  @override
  String get sendFile => 'Sųsti bylą';

  @override
  String get sendImage => 'Siųsti paveiksliuką';

  @override
  String get sendMessages => 'Siųsti žinutes';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Siųsti originalą';

  @override
  String get sendSticker => 'Siųsti lipduką';

  @override
  String get sendVideo => 'Siųsti video';

  @override
  String sentAFile(Object username) {
    return '📁 $username atsiuntė failą';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username atsiuntė garso įrašą';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username atsiuntė nuotrauką';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username atsiuntė lipduką';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username atsiuntė vaizdo įrašą';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName išsiuntė skambučio informaciją';
  }

  @override
  String get separateChatTypes => 'Atskirti tiesioginius pokalbius ir grupes';

  @override
  String get setAsCanonicalAlias => 'Nustatyti kaip pagrindinį slapyvardį';

  @override
  String get setCustomEmotes => 'Nustatyti pasirinktinius jaustukus';

  @override
  String get setGroupDescription => 'Nustatyti grupės aprašymą';

  @override
  String get setInvitationLink => 'Nustatyti pakvietimo nuorodą';

  @override
  String get setPermissionsLevel => 'Nustatyti leidimų lygį';

  @override
  String get setStatus => 'Nustatyti būseną';

  @override
  String get settings => 'Nustatytmai';

  @override
  String get share => 'Bendrinti';

  @override
  String sharedTheLocation(Object username) {
    return '$username bendrino savo vietą';
  }

  @override
  String get shareLocation => 'Bendrinti vietą';

  @override
  String get showDirectChatsInSpaces =>
      'Rodyti susijusius tiesioginius pokalbius erdvėse';

  @override
  String get showPassword => 'Rodyti slaptažodį';

  @override
  String get signUp => 'Registruotis';

  @override
  String get singlesignon => 'Vienkartinis prisijungimas';

  @override
  String get skip => 'Praleisti';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Programinis kodas';

  @override
  String get spaceIsPublic => 'Erdvė yra vieša';

  @override
  String get spaceName => 'Erdvės pavadinimas';

  @override
  String startedACall(Object senderName) {
    return '$senderName pradėjo skambutį';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Būsena';

  @override
  String get statusExampleMessage => 'Kaip sekasi šiandien?';

  @override
  String get submit => 'Pateikti';

  @override
  String get sunday => 'Sekmadienis';

  @override
  String get synchronizingPleaseWait => 'Sinchronizuojama… Prašome palaukti.';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theyDontMatch => 'Jie nesutampa';

  @override
  String get theyMatch => 'Jie sutampa';

  @override
  String get thisRoomHasBeenArchived => 'Šis kambarys buvo suarchyvuotas.';

  @override
  String get thursday => 'Ketvirtadienis';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Perjungti parankinius';

  @override
  String get toggleMuted => 'Perjungti nutildytą';

  @override
  String get toggleUnread => 'Pažymėti kaip skaitytą/neskaitytą';

  @override
  String get tooManyRequestsWarning =>
      'Per daug užklausų. Pabandykite dar kartą vėliau!';

  @override
  String get transferFromAnotherDevice => 'Perkėlimas iš kito įrenginio';

  @override
  String get tryToSendAgain => 'Pabandykite išsiųsti dar kartą';

  @override
  String get tuesday => 'Antradienis';

  @override
  String get unavailable => 'Nepasiekiamas';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username atblokavo $targetName';
  }

  @override
  String get unblockDevice => 'Atblokuoti įrenginį';

  @override
  String get unknownDevice => 'Nežinomas įrenginys';

  @override
  String get unknownEncryptionAlgorithm => 'Nežinomas šifravimo algoritmas';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Nežinomas įvykis \'$type\'';
  }

  @override
  String get unmuteChat => 'Įjungti pokalbio garsą';

  @override
  String get unpin => 'Atsegti';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount neperskaityti pokalbiai',
      one: '1 unread chat',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username ir dar $count kiti rašo';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username ir $username2 rašo';
  }

  @override
  String userIsTyping(Object username) {
    return '$username rašo';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username paliko pokalbį';
  }

  @override
  String get username => 'Vartotojo vardas';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username išsiuntė $type įvykį';
  }

  @override
  String get unverified => 'Nepatvirtinta';

  @override
  String get verified => 'Patvirtinta';

  @override
  String get verify => 'Patvirtinti';

  @override
  String get verifyStart => 'Pradėti patvirtinimą';

  @override
  String get verifySuccess => 'Jūs sėkmingai patvirtinote!';

  @override
  String get verifyTitle => 'Patvirtinama kita paskyra';

  @override
  String get videoCall => 'Vaizdo skambutis';

  @override
  String get visibilityOfTheChatHistory => 'Pokalbių istorijos matomumas';

  @override
  String get visibleForAllParticipants => 'Matoma visiems dalyviams';

  @override
  String get visibleForEveryone => 'Matoma visiems';

  @override
  String get voiceMessage => 'Balso žinutė';

  @override
  String get waitingPartnerAcceptRequest =>
      'Laukiama, kol dalyvis priims užklausą…';

  @override
  String get waitingPartnerEmoji => 'Laukiama, kol dalyvis priims jaustukus…';

  @override
  String get waitingPartnerNumbers => 'Laukiama, kol dalyvis priims skaičius…';

  @override
  String get wallpaper => 'Užsklanda';

  @override
  String get warning => 'Įspėjimas!';

  @override
  String get wednesday => 'Trečiadienis';

  @override
  String get weSentYouAnEmail => 'Išsiuntėme jums el. laišką';

  @override
  String get whoCanPerformWhichAction => 'Kas gali atlikti kokį veiksmą';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Kam leidžiama prisijungti prie šios grupės';

  @override
  String get whyDoYouWantToReportThis => 'Kodėl norite apie tai pranešti?';

  @override
  String get wipeChatBackup =>
      'Ištrinti atsarginę pokalbių kopiją, kad sukurti naują atkūrimo raktą?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Naudodami šiuos adresus galite atkurti savo slaptažodį.';

  @override
  String get writeAMessage => 'Rašyti žinutę…';

  @override
  String get yes => 'Taip';

  @override
  String get you => 'Jūs';

  @override
  String get youAreInvitedToThisChat => 'Esate pakviesti į šį pokalbį';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Jūs nebedalyvaujate šiame pokalbyje';

  @override
  String get youCannotInviteYourself => 'Jūs negalite pakviesti savęs';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Jums buvo uždrausta dalyvauti šiame pokalbyje';

  @override
  String get yourPublicKey => 'Jūsų viešasis raktas';

  @override
  String get messageInfo => 'Žinutės informacija';

  @override
  String get time => 'Laikas';

  @override
  String get messageType => 'Žinutės tipas';

  @override
  String get sender => 'Siuntėjas';

  @override
  String get openGallery => 'Atverti galeriją';

  @override
  String get removeFromSpace => 'Pašalinti iš erdvės';

  @override
  String get addToSpaceDescription =>
      'Pasirinkite erdvę, kad prie jos pridėtumėte šį pokalbį.';

  @override
  String get start => 'Pradžia';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Norėdami atrakinti senas žinutes, įveskite atkūrimo raktą, kuris buvo sukurtas ankstesnės sesijos metu. Atkūrimo raktas NĖRA jūsų slaptažodis.';

  @override
  String get addToStory => 'Pridėti prie istorijos';

  @override
  String get publish => 'Paskelbti';

  @override
  String get whoCanSeeMyStories => 'Kas gali matyti mano istorijas?';

  @override
  String get unsubscribeStories => 'Atsisakyti istorijų prenumeratos';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Šis vartotojas dar nieko nepaskelbė savo istorijoje';

  @override
  String get yourStory => 'Tavo istorija';

  @override
  String get replyHasBeenSent => 'Atsakymas išsiųstas';

  @override
  String videoWithSize(Object size) {
    return 'Vaizdo įrašas ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Istorija nuo $date: \n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Atminkite, kad žmonės gali matyti vienas kitą ir susisiekti tarpusavyje jūsų istorijoje.';

  @override
  String get whatIsGoingOn => 'Kas vyksta?';

  @override
  String get addDescription => 'Pridėti aprašymą';

  @override
  String get storyPrivacyWarning =>
      'Atminkite, kad žmonės gali matyti vienas kitą ir susisiekti tarpusavyje jūsų istorijoje. Jūsų istorijos bus matomos 24 valandas, tačiau nėra garantijos, kad jos bus ištrintos iš visų įrenginių ir serverių.';

  @override
  String get iUnderstand => 'Aš suprantu';

  @override
  String get openChat => 'Atverti pokalbį';

  @override
  String get markAsRead => 'Žymėti kaip skaitytą';

  @override
  String get reportUser => 'Pranešti apie vartotoją';

  @override
  String get dismiss => 'Atsisakyti';

  @override
  String get matrixWidgets => 'Matrix valdikliai';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender sureagavo su $reaction';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin =>
      'Ar tikrai norite visam laikui atsegti įvykį?';

  @override
  String get emojis => 'Jaustukai';

  @override
  String get placeCall => 'Skambinti';

  @override
  String get voiceCall => 'Balso skambutis';

  @override
  String get unsupportedAndroidVersion => 'Nepalaikoma Android versija';

  @override
  String get unsupportedAndroidVersionLong =>
      'Šiai funkcijai reikalinga naujesnė Android versija. Patikrinkite, ar nėra naujinimų arba Lineage OS palaikymo.';

  @override
  String get videoCallsBetaWarning =>
      'Atminkite, kad vaizdo skambučiai šiuo metu yra beta versijos. Jie gali neveikti taip kaip tikėtasi, arba iš viso neveikti visose platformose.';

  @override
  String get experimentalVideoCalls => 'Eksperimentiniai vaizdo skambučiai';

  @override
  String get emailOrUsername => 'El. paštas arba vartotojo vardas';

  @override
  String get indexedDbErrorTitle => 'Privataus režimo problemos';

  @override
  String get indexedDbErrorLong =>
      'Deja, pagal numatytuosius nustatymus žinučių saugojimas privačiame režime nėra įjungtas.\nPrašome apsilankyti\n - about:config\n - nustatykite dom.indexedDB.privateBrowsing.enabled į true\nPriešingu atveju FluffyChat paleisti neįmanoma.';

  @override
  String switchToAccount(Object number) {
    return 'Perjungti paskyrą į $number';
  }

  @override
  String get nextAccount => 'Kita paskyra';

  @override
  String get previousAccount => 'Ankstesnė paskyra';

  @override
  String get editWidgets => 'Redaguoti programėles';

  @override
  String get addWidget => 'Pridėti programėlę';

  @override
  String get widgetVideo => 'Video';

  @override
  String get widgetEtherpad => 'Teksto pastaba';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Pasirinktinis';

  @override
  String get widgetName => 'Vardas';

  @override
  String get widgetUrlError => 'Netinkamas URL.';

  @override
  String get widgetNameError => 'Pateikite rodomą vardą.';

  @override
  String get errorAddingWidget => 'Pridedant valdiklį įvyko klaida.';

  @override
  String get youRejectedTheInvitation => 'Jūs atmetėte kvietimą';

  @override
  String get youJoinedTheChat => 'Jūs prisijungėte prie pokalbio';

  @override
  String get youAcceptedTheInvitation => '👍 Jūs priėmėte kvietimą';

  @override
  String youBannedUser(Object user) {
    return 'Jūs užblokavote $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Jūs atšaukėte kvietimą $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 Jus pakvietė $user';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 Pakvietėte $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 Jūs išmetėte $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 Jūs išmetėte ir užblokavote $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Jūs atblokavote $user';
  }

  @override
  String get noEmailWarning =>
      'Įveskite galiojantį el. pašto adresą. Priešingu atveju negalėsite iš naujo nustatyti slaptažodžio. Jei nenorite, dar kartą bakstelėkite mygtuką, kad galėtumėte tęsti.';

  @override
  String get stories => 'Istorijos';

  @override
  String get users => 'Vartotojai';

  @override
  String get enableAutoBackups => 'Įjungti automatines atsargines kopijas';

  @override
  String get unlockOldMessages => 'Atrakinti senas žinutes';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription =>
      'Atkūrimo raktą laikyti saugioje šio prietaiso saugykloje.';

  @override
  String get saveKeyManuallyDescription =>
      'Įrašykite šį raktą rankiniu būdu, įjungę sistemos bendrinimo dialogo langą arba iškarpinę.';

  @override
  String get storeInAndroidKeystore => 'Saugoti Android raktų saugykloje';

  @override
  String get storeInAppleKeyChain => 'Saugoti Apple raktų grandinėje';

  @override
  String get storeSecurlyOnThisDevice => 'Saugiai laikyti šiame prietaise';

  @override
  String countFiles(Object count) {
    return '$count failai';
  }

  @override
  String get user => 'Vartotojas';

  @override
  String get custom => 'Pasirinktinis';

  @override
  String get foregroundServiceRunning =>
      'Šis pranešimas rodomas, kai veikia pirmojo plano paslauga.';

  @override
  String get screenSharingTitle => 'ekrano bendrinimas';

  @override
  String get screenSharingDetail => 'Bendrinate savo ekraną per FuffyChat';

  @override
  String get callingPermissions => 'Skambinimo leidimai';

  @override
  String get callingAccount => 'Skambinimo paskyra';

  @override
  String get callingAccountDetails =>
      'Leidžia FluffyChat naudoti vietinę Android rinkiklio programą.';

  @override
  String get appearOnTop => 'Rodyti viršuje';

  @override
  String get appearOnTopDetails =>
      'Leidžia programėlę rodyti viršuje (nebūtina, jei jau esate nustatę Fluffychat kaip skambinimo paskyrą)';

  @override
  String get otherCallingPermissions =>
      'Mikrofonas, kamera ir kiti FluffyChat leidimai';

  @override
  String get whyIsThisMessageEncrypted => 'Kodėl ši žinutė neperskaitoma?';

  @override
  String get noKeyForThisMessage =>
      'Taip gali atsitikti, jei žinutė buvo išsiųsta prieš prisijungiant prie paskyros šiame prietaise.\n\nTaip pat gali būti, kad siuntėjas užblokavo jūsų prietaisą arba kažkas sutriko su interneto ryšiu.\n\nAr galite perskaityti žinutę kitoje sesijoje? Tada galite perkelti žinutę iš jos! Eikite į Nustatymai > Prietaisai ir įsitikinkite, kad jūsų prietaisai patvirtino vienas kitą. Kai kitą kartą atidarysite kambarį ir abi sesijos bus pirmame plane, raktai bus perduoti automatiškai.\n\nNenorite prarasti raktų atsijungdami arba keisdami įrenginius? Įsitikinkite, kad nustatymuose įjungėte pokalbių atsarginę kopiją.';

  @override
  String get newGroup => 'Nauja grupė';

  @override
  String get newSpace => 'Nauja erdvė';

  @override
  String get enterSpace => 'Įeiti į erdvę';

  @override
  String get enterRoom => 'Įeiti į kambarį';

  @override
  String get allSpaces => 'Visos erdvės';

  @override
  String numChats(Object number) {
    return '$number pokalbiai';
  }

  @override
  String get hideUnimportantStateEvents => 'Slėpti nesvarbius būsenos įvykius';

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
  String get search => 'Ieškoti';

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
