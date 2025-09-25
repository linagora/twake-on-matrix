// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class L10nNb extends L10n {
  L10nNb([String locale = 'nb']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Passordet samsvarer ikke!';

  @override
  String get pleaseEnterValidEmail => 'Skriv inn en gyldig e-postadresse.';

  @override
  String get repeatPassword => 'Gjenta passord';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Vennligst velg minst $min tegn.';
  }

  @override
  String get about => 'Om';

  @override
  String get updateAvailable => 'Twake Chat update available';

  @override
  String get updateNow => 'Start update in background';

  @override
  String get accept => 'Godta';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username godtok invitasjonen';
  }

  @override
  String get account => 'Konto';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username skrudde på ende-til-ende -kryptering';
  }

  @override
  String get addEmail => 'Legg til e-post';

  @override
  String get confirmMatrixId =>
      'Please confirm your Matrix ID in order to delete your account.';

  @override
  String supposedMxid(Object mxid) {
    return 'This should be $mxid';
  }

  @override
  String get addGroupDescription => 'Legg til gruppebeskrivelse';

  @override
  String get addToSpace => 'Legg til space';

  @override
  String get admin => 'Administrator';

  @override
  String get alias => 'alias';

  @override
  String get all => 'Alle';

  @override
  String get allChats => 'Alle samtaler';

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
    return '$senderName besvarte anropet';
  }

  @override
  String get anyoneCanJoin => 'Hvem som helst kan delta';

  @override
  String get appLock => 'Programlås';

  @override
  String get archive => 'Arkiv';

  @override
  String get archivedRoom => 'Arkivert rom';

  @override
  String get areGuestsAllowedToJoin => 'Skal gjester tillates å ta del';

  @override
  String get areYouSure => 'Er du sikker?';

  @override
  String get areYouSureYouWantToLogout => 'Er du sikker på at du vil logge ut?';

  @override
  String get askSSSSSign =>
      'For å kunne signere den andre personen, skriv inn ditt sikre lagerpassord eller gjenopprettingsnøkkel.';

  @override
  String askVerificationRequest(Object username) {
    return 'Godta denne bekreftelsesforespørselen fra $username?';
  }

  @override
  String get autoplayImages =>
      'Automatisk spill av animerte stickers og emojis';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Denne hjemme serveren støtter følgende innloggings-typer:\n$serverVersions\nMen denne applikasjonen støtter kun:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Trykk på enter for å sende';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Denne hjemme serveren støtter følgene Spec-versjoner:\n$serverVersions\nMen denne applikasjonen støtter kun $supportedVersions';
  }

  @override
  String get banFromChat => 'Bannlys fra sludring';

  @override
  String get banned => 'Bannlyst';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username bannlyste $targetName';
  }

  @override
  String get blockDevice => 'Blokker enhet';

  @override
  String get blocked => 'Blokkert';

  @override
  String get botMessages => 'Bot-meldinger';

  @override
  String get bubbleSize => 'Bubble size';

  @override
  String get cancel => 'Avbryt';

  @override
  String cantOpenUri(Object uri) {
    return 'Kan ikke åpne URI $uri';
  }

  @override
  String get changeDeviceName => 'Endre enhetsnavn';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username endret sludreavatar';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username endret sludrebeskrivelse til: «$description»';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username endret sludringsnavn til: «$chatname»';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username endret sludretilgangene';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username endret visningsnavn til: $displayname';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username endret gjestetilgangsreglene';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username endret gjestetilgangsregler til: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username endret historikksynlighet';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username endret historikksynlighet til: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username endret tilgangsreglene';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username endret tilgangsreglene til: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username endret avataren sin';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username endret rom-aliasene';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username endret invitasjonslenken';
  }

  @override
  String get changePassword => 'Endre passord';

  @override
  String get changeTheHomeserver => 'Endre hjemmetjener';

  @override
  String get changeTheme => 'Endre din stil';

  @override
  String get changeTheNameOfTheGroup => 'Endre gruppens navn';

  @override
  String get changeWallpaper => 'Endre bakgrunnsbilde';

  @override
  String get changeYourAvatar => 'Bytt profilbilde';

  @override
  String get channelCorruptedDecryptError => 'Krypteringen er skadet';

  @override
  String get chat => 'Sludring';

  @override
  String get yourUserId => 'Din bruker ID:';

  @override
  String get yourChatBackupHasBeenSetUp => 'Your chat backup has been set up.';

  @override
  String get chatBackup => 'Sludringssikkerhetskopi';

  @override
  String get chatBackupDescription =>
      'Din sludringssikkerhetskopi er sikret med en sikkerhetsnøkkel. Ikke mist den.';

  @override
  String get chatDetails => 'Sludringsdetaljer';

  @override
  String get chatHasBeenAddedToThisSpace => 'Chat has been added to this space';

  @override
  String get chats => 'Chats';

  @override
  String get chooseAStrongPassword => 'Velg et sterkt passord';

  @override
  String get chooseAUsername => 'Velg et brukernavn';

  @override
  String get clearArchive => 'Clear archive';

  @override
  String get close => 'Lukk';

  @override
  String get commandHint_markasdm => 'Mark as direct chat';

  @override
  String get commandHint_markasgroup => 'Mark as chat';

  @override
  String get commandHint_ban => 'Ban the given user from this chat';

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
  String get commandHint_html => 'Send HTML-formatted text';

  @override
  String get commandHint_invite => 'Invite the given user to this chat';

  @override
  String get commandHint_join => 'Join the given chat';

  @override
  String get commandHint_kick => 'Remove the given user from this chat';

  @override
  String get commandHint_leave => 'Leave this chat';

  @override
  String get commandHint_me => 'Describe yourself';

  @override
  String get commandHint_myroomavatar =>
      'Set your picture for this chat (by mxc-uri)';

  @override
  String get commandHint_myroomnick => 'Set your display name for this chat';

  @override
  String get commandHint_op =>
      'Set the given user\'s power level (default: 50)';

  @override
  String get commandHint_plain => 'Send unformatted text';

  @override
  String get commandHint_react => 'Send reply as a reaction';

  @override
  String get commandHint_send => 'Send text';

  @override
  String get commandHint_unban => 'Unban the given user from this chat';

  @override
  String get commandInvalid => 'Command invalid';

  @override
  String commandMissing(Object command) {
    return '$command is not a command.';
  }

  @override
  String get compareEmojiMatch =>
      'Sammenlign og forsikre at følgende smilefjes samsvarer med de på den andre enheten:';

  @override
  String get compareNumbersMatch =>
      'Sammenlign og forsikre at følgende tall samsvarer med de på den andre enheten:';

  @override
  String get configureChat => 'Sett opp sludring';

  @override
  String get confirm => 'Bekreft';

  @override
  String get connect => 'Koble til';

  @override
  String get contactHasBeenInvitedToTheGroup => 'Kontakt invitert til gruppen';

  @override
  String get containsDisplayName => 'Inneholder visningsnavn';

  @override
  String get containsUserName => 'Inneholder brukernavn';

  @override
  String get contentHasBeenReported =>
      'Innholdet har blitt rapportert til tjeneradministratorene';

  @override
  String get copiedToClipboard => 'Kopiert til utklippstavle';

  @override
  String get copy => 'Kopier';

  @override
  String get copyToClipboard => 'Kopier til utklippstavle';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Kunne ikke dekryptere melding: $error';
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
  String get create => 'Opprett';

  @override
  String createdTheChat(Object username) {
    return '$username opprettet sludringen';
  }

  @override
  String get createNewGroup => 'Opprett ny gruppe';

  @override
  String get createNewSpace => 'New space';

  @override
  String get crossSigningEnabled => 'Videreformidling av tillit på';

  @override
  String get currentlyActive => 'Aktiv nå';

  @override
  String get darkTheme => 'Mørk';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$timeOfDay, $date';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$day $month';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$day $month $year';
  }

  @override
  String get deactivateAccountWarning =>
      'Dette vil skru av din brukerkonto for godt, og kan ikke angres! Er du sikker?';

  @override
  String get defaultPermissionLevel => 'Forvalgt tilgangsnivå';

  @override
  String get delete => 'Slett';

  @override
  String get deleteAccount => 'Slett konto';

  @override
  String get deleteMessage => 'Slett melding';

  @override
  String get deny => 'Nekt';

  @override
  String get device => 'Enhet';

  @override
  String get deviceId => 'Enhets-ID';

  @override
  String get devices => 'Enheter';

  @override
  String get directChats => 'Direktesludringer';

  @override
  String get discover => 'Oppdag';

  @override
  String get displaynameHasBeenChanged => 'Visningsnavn endret';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Rediger';

  @override
  String get editBlockedServers => 'Rediger blokkerte tjenere';

  @override
  String get editChatPermissions => 'Rediger sludringstilganger';

  @override
  String get editDisplayname => 'Rediger visningsnavn';

  @override
  String get editRoomAliases => 'Edit chat aliases';

  @override
  String get editRoomAvatar => 'Rediger romavatar';

  @override
  String get emoteExists => 'Smilefjeset finnes allerede!';

  @override
  String get emoteInvalid => 'Ugyldig smilefjes-kode!';

  @override
  String get emotePacks => 'Smilefjespakker for rommet';

  @override
  String get emoteSettings => 'Smilefjes-innstillinger';

  @override
  String get emoteShortcode => 'Smilefjes-kode';

  @override
  String get emoteWarnNeedToPick =>
      'Du må velge en smilefjes-kode og et bilde!';

  @override
  String get emptyChat => 'Tom sludring';

  @override
  String get enableEmotesGlobally =>
      'Skru på smilefjespakke for hele programmet';

  @override
  String get enableEncryption => 'Skru på kryptering';

  @override
  String get enableEncryptionWarning =>
      'Du vil ikke kunne skru av kryptering lenger. Er du sikker?';

  @override
  String get encrypted => 'Kryptert';

  @override
  String get encryption => 'Kryptering';

  @override
  String get encryptionNotEnabled => 'Kryptering er ikke påskrudd';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName avsluttet samtalen';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Skriv inn en e-postadresse';

  @override
  String get enterASpacepName => 'Enter a space name';

  @override
  String get homeserver => 'Homeserver';

  @override
  String get enterYourHomeserver => 'Skriv inn din hjemmetjener';

  @override
  String errorObtainingLocation(Object error) {
    return 'Error obtaining location: $error';
  }

  @override
  String get everythingReady => 'Alt er klart!';

  @override
  String get extremeOffensive => 'Veldig';

  @override
  String get fileName => 'Filnavn';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Skriftstørrelse';

  @override
  String get forward => 'Videre';

  @override
  String get friday => 'Fredag';

  @override
  String get fromJoining => 'Fra å ta del';

  @override
  String get fromTheInvitation => 'Fra invitasjonen';

  @override
  String get goToTheNewRoom => 'Go to the new chat';

  @override
  String get group => 'Gruppe';

  @override
  String get groupDescription => 'Gruppebeskrivelse';

  @override
  String get groupDescriptionHasBeenChanged => 'Gruppebeskrivelse endret';

  @override
  String get groupIsPublic => 'Gruppen er offentlig';

  @override
  String get groups => 'Grupper';

  @override
  String groupWith(Object displayname) {
    return 'Gruppe med $displayname';
  }

  @override
  String get guestsAreForbidden => 'Gjester forbudt';

  @override
  String get guestsCanJoin => 'Gjester kan ta del';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username har trukket tilbake invitasjonen til $targetName';
  }

  @override
  String get help => 'Hjelp';

  @override
  String get hideRedactedEvents => 'Skjul tilbaketrukne hendelser';

  @override
  String get hideUnknownEvents => 'Skjul ukjente hendelser';

  @override
  String get howOffensiveIsThisContent => 'Hvor støtende er innholdet?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identitet';

  @override
  String get ignore => 'Ignorer';

  @override
  String get ignoredUsers => 'Ignorerte brukere';

  @override
  String get ignoreListDescription =>
      'Du kan ignorere brukere som forstyrrer deg. Du vil ikke lenger kunne motta meldinger eller rominvitasjoner fra brukere på din personlige ignoreringsliste.';

  @override
  String get ignoreUsername => 'Ignorer brukernavn';

  @override
  String get iHaveClickedOnLink => 'Jeg har klikket på lenken';

  @override
  String get incorrectPassphraseOrKey =>
      'Feilaktig passord eller gjenopprettingsnøkkel';

  @override
  String get inoffensive => 'Harmløst';

  @override
  String get inviteContact => 'Inviter kontakt';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Inviter kontakt til $groupName';
  }

  @override
  String get invited => 'Invitert';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username inviterte $targetName';
  }

  @override
  String get invitedUsersOnly => 'Kun inviterte brukere';

  @override
  String get inviteForMe => 'Invitasjon for meg';

  @override
  String inviteText(Object username, Object link) {
    return '$username har invitert deg til FluffyChat. \n1. Installer FluffyChat: https://fluffychat.im \n2. Registrer deg eller logg inn \n3. Åpne invitasjonslenken: $link';
  }

  @override
  String get isTyping => 'skriver';

  @override
  String joinedTheChat(Object username) {
    return '${username}ble med i samtalen';
  }

  @override
  String get joinRoom => 'Ta del i rom';

  @override
  String get keysCached => 'Nøkler hurtiglagret';

  @override
  String kicked(Object username, Object targetName) {
    return '$username kastet ut $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username kastet ut og bannlyste $targetName';
  }

  @override
  String get kickFromChat => 'Kast ut av sludringen';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Sist aktiv: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Sett for lenge siden';

  @override
  String get leave => 'Forlat';

  @override
  String get leftTheChat => 'Forlat sludringen';

  @override
  String get license => 'Lisens';

  @override
  String get lightTheme => 'Lys';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Last inn $count deltagere til';
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
  String get loadingPleaseWait => 'Laster inn… Vent.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Last inn mer…';

  @override
  String get locationDisabledNotice =>
      'Location services are disabled. Please enable them to be able to share your location.';

  @override
  String get locationPermissionDeniedNotice =>
      'Location permission denied. Please grant them to be able to share your location.';

  @override
  String get login => 'Logg inn';

  @override
  String logInTo(Object homeserver) {
    return 'Logg inn på $homeserver';
  }

  @override
  String get loginWithOneClick => 'Sign in with one click';

  @override
  String get logout => 'Logg ut';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Forsikre deg om at identifikatoren er gyldig';

  @override
  String get memberChanges => 'Medlemsendringer';

  @override
  String get mention => 'Nevn';

  @override
  String get messages => 'Meldinger';

  @override
  String get messageWillBeRemovedWarning =>
      'Meldingen vil bli fjernet for alle deltagere';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'Moderator';

  @override
  String get monday => 'Mandag';

  @override
  String get muteChat => 'Forstum sludring';

  @override
  String get needPantalaimonWarning =>
      'Merk at du trenger Pantalaimon for å bruke ende-til-ende -kryptering inntil videre.';

  @override
  String get newChat => 'Ny sludring';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Ny bekreftelsesforespørsel!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Neste';

  @override
  String get no => 'Nei';

  @override
  String get noConnectionToTheServer => 'Ingen tilkobling til tjeneren';

  @override
  String get noEmotesFound => 'Fant ingen smilefjes. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'You can only activate encryption as soon as the chat is no longer publicly accessible.';

  @override
  String get noGoogleServicesWarning =>
      'Bruk https://microg.org/ for å få Google-tjenester (uten at det går ut over personvernet) for å få push-merknader i FluffyChat:';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 is no matrix server, use $server2 instead?';
  }

  @override
  String get shareYourInviteLink => 'Share your invite link';

  @override
  String get typeInInviteLinkManually => 'Type in invite link manually...';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String get none => 'Ingen';

  @override
  String get noPasswordRecoveryDescription =>
      'Du har ikke lagt til en måte å gjenopprette passordet ditt på.';

  @override
  String get noPermission => 'Ingen tilgang';

  @override
  String get noRoomsFound => 'Fant ingen rom …';

  @override
  String get notifications => 'Merknader';

  @override
  String numUsersTyping(Object count) {
    return '$count brukere skriver';
  }

  @override
  String get obtainingLocation => 'Obtaining location…';

  @override
  String get offensive => 'Støtende';

  @override
  String get offline => 'Frakoblet';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'OK';

  @override
  String get online => 'Pålogget';

  @override
  String get onlineKeyBackupEnabled =>
      'Nettbasert sikkerhetskopiering av nøkler på';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Oops! Unfortunately, an error occurred when setting up the push notifications.';

  @override
  String get oopsSomethingWentWrong => 'Oida, noe gikk galt …';

  @override
  String get openAppToReadMessages => 'Åpne programmet for å lese meldinger';

  @override
  String get openCamera => 'Åpne kamera';

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
  String get optionalGroupName => 'Gruppenavn (valgfritt)';

  @override
  String get or => 'Or';

  @override
  String get participant => 'Deltager';

  @override
  String get passphraseOrKey => 'Passord eller gjenopprettingsnøkkel';

  @override
  String get password => 'Passord';

  @override
  String get passwordForgotten => 'Passord glemt';

  @override
  String get passwordHasBeenChanged => 'Passord endret';

  @override
  String get passwordRecovery => 'Passordgjenoppretting';

  @override
  String get people => 'People';

  @override
  String get pickImage => 'Velg bilde';

  @override
  String get pin => 'Fest';

  @override
  String play(Object fileName) {
    return 'Spill av $fileName';
  }

  @override
  String get pleaseChoose => 'Please choose';

  @override
  String get pleaseChooseAPasscode => 'Please choose a pass code';

  @override
  String get pleaseChooseAUsername => 'Velg et brukernavn';

  @override
  String get pleaseClickOnLink => 'Klikk på lenken i e-posten og fortsett.';

  @override
  String get pleaseEnter4Digits =>
      'Please enter 4 digits or leave empty to disable app lock.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Skriv inn en Matrix-ID.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => 'Skriv inn passordet ditt';

  @override
  String get pleaseEnterYourPin => 'Please enter your pin';

  @override
  String get pleaseEnterYourUsername => 'Skriv inn brukernavnet ditt';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Følg instruksen på nettsiden og trykk på «Neste».';

  @override
  String get privacy => 'Personvern';

  @override
  String get publicRooms => 'Offentlige rom';

  @override
  String get pushRules => 'Dyttingsregler';

  @override
  String get reason => 'Grunn';

  @override
  String get recording => 'Opptak';

  @override
  String redactedAnEvent(Object username) {
    return '$username har trukket tilbake en hendelse';
  }

  @override
  String get redactMessage => 'Redact message';

  @override
  String get register => 'Register';

  @override
  String get reject => 'Avslå';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username avslo invitasjonen';
  }

  @override
  String get rejoin => 'Ta del igjen';

  @override
  String get remove => 'Fjern';

  @override
  String get removeAllOtherDevices => 'Fjern alle andre enheter';

  @override
  String removedBy(Object username) {
    return 'Fjernet av $username';
  }

  @override
  String get removeDevice => 'Fjern enhet';

  @override
  String get unbanFromChat => 'Opphev bannlysning';

  @override
  String get removeYourAvatar => 'Remove your avatar';

  @override
  String get renderRichContent => 'Tegn rikt meldingsinnhold';

  @override
  String get replaceRoomWithNewerVersion => 'Erstatt rom med nyere versjon';

  @override
  String get reply => 'Svar';

  @override
  String get reportMessage => 'Rapporter melding';

  @override
  String get requestPermission => 'Forespør tilgang';

  @override
  String get roomHasBeenUpgraded => 'Rommet har blitt oppgradert';

  @override
  String get roomVersion => 'Group chat version';

  @override
  String get saturday => 'Lørdag';

  @override
  String get saveFile => 'Save file';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Sikkerhet';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyLost => 'Recovery key lost?';

  @override
  String seenByUser(Object username) {
    return 'Sett av $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sett av $username og $count andre',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Sett av $username og $username2';
  }

  @override
  String get send => 'Send';

  @override
  String get sendAMessage => 'Send en melding';

  @override
  String get sendAsText => 'Send as text';

  @override
  String get sendAudio => 'Send lyd';

  @override
  String get sendFile => 'Send fil';

  @override
  String get sendImage => 'Send bilde';

  @override
  String get sendMessages => 'Send meldinger';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Send original';

  @override
  String get sendSticker => 'Send sticker';

  @override
  String get sendVideo => 'Send video';

  @override
  String sentAFile(Object username) {
    return '$username sendte en fil';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username sendte lyd';
  }

  @override
  String sentAPicture(Object username) {
    return '$username sendte et bilde';
  }

  @override
  String sentASticker(Object username) {
    return '$username sendte et klistremerke';
  }

  @override
  String sentAVideo(Object username) {
    return '$username sendte en video';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName sendte anropsinfo';
  }

  @override
  String get separateChatTypes => 'Separate Direct Chats and Groups';

  @override
  String get setAsCanonicalAlias => 'Set as main alias';

  @override
  String get setCustomEmotes => 'Sett tilpassede smilefjes';

  @override
  String get setGroupDescription => 'Sett gruppebeskrivelse';

  @override
  String get setInvitationLink => 'Sett invitasjonslenke';

  @override
  String get setPermissionsLevel => 'Sett tilgangsnivå';

  @override
  String get setStatus => 'Angi status';

  @override
  String get settings => 'Innstilinger';

  @override
  String get share => 'Del';

  @override
  String sharedTheLocation(Object username) {
    return '$username delte posisjonen';
  }

  @override
  String get shareLocation => 'Share location';

  @override
  String get showDirectChatsInSpaces => 'Show related Direct Chats in Spaces';

  @override
  String get showPassword => 'Show password';

  @override
  String get signUp => 'Registrer deg';

  @override
  String get singlesignon => 'Single Sign on';

  @override
  String get skip => 'Hopp over';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Kildekode';

  @override
  String get spaceIsPublic => 'Space is public';

  @override
  String get spaceName => 'Space name';

  @override
  String startedACall(Object senderName) {
    return '$senderName startet en samtale';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Status';

  @override
  String get statusExampleMessage => 'Hvordan har du det i dag?';

  @override
  String get submit => 'Send inn';

  @override
  String get sunday => 'Søndag';

  @override
  String get synchronizingPleaseWait => 'Synchronizing… Please wait.';

  @override
  String get systemTheme => 'System';

  @override
  String get theyDontMatch => 'Samsvarer ikke';

  @override
  String get theyMatch => 'Samsvarer';

  @override
  String get thisRoomHasBeenArchived => 'Dette rommet har blitt arkivert.';

  @override
  String get thursday => 'Torsdag';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Veksle favorittmerking';

  @override
  String get toggleMuted => 'Veksle forstumming';

  @override
  String get toggleUnread => 'Marker som lest/ulest';

  @override
  String get tooManyRequestsWarning =>
      'For mange forespørsler. Prøv igjen senere!';

  @override
  String get transferFromAnotherDevice => 'Overfør fra en annen enhet';

  @override
  String get tryToSendAgain => 'Prøv å sende igjen';

  @override
  String get tuesday => 'Tirsdag';

  @override
  String get unavailable => 'Utilgjengelig';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username opphevet bannlysning av $targetName';
  }

  @override
  String get unblockDevice => 'Opphev blokkering av enhet';

  @override
  String get unknownDevice => 'Ukjent enhet';

  @override
  String get unknownEncryptionAlgorithm => 'Ukjent krypteringsalgoritme';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Ukjent hendelse «$type»';
  }

  @override
  String get unmuteChat => 'Opphev forstumming av sludring';

  @override
  String get unpin => 'Løsne';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount uleste sludringer',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username og $count andre skriver';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username og $username2 skriver';
  }

  @override
  String userIsTyping(Object username) {
    return '$username skriver';
  }

  @override
  String userLeftTheChat(Object username) {
    return '$username har forlatt sludringen';
  }

  @override
  String get username => 'Brukernavn';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username sendte en $type-hendelse';
  }

  @override
  String get unverified => 'Unverified';

  @override
  String get verified => 'Verified';

  @override
  String get verify => 'Bekreft';

  @override
  String get verifyStart => 'Start bekreftelse';

  @override
  String get verifySuccess => 'Du har bekreftet!';

  @override
  String get verifyTitle => 'Bekrefter annen konto';

  @override
  String get videoCall => 'Videosamtale';

  @override
  String get visibilityOfTheChatHistory => 'Sludrehistorikkens synlighet';

  @override
  String get visibleForAllParticipants => 'Synlig for alle deltagere';

  @override
  String get visibleForEveryone => 'Synlig for alle';

  @override
  String get voiceMessage => 'Lydmelding';

  @override
  String get waitingPartnerAcceptRequest =>
      'Waiting for partner to accept the request…';

  @override
  String get waitingPartnerEmoji => 'Waiting for partner to accept the emoji…';

  @override
  String get waitingPartnerNumbers =>
      'Venter på at samtalepartner skal godta tallene …';

  @override
  String get wallpaper => 'Bakgrunnsbilde';

  @override
  String get warning => 'Advarsel!';

  @override
  String get wednesday => 'Onsdag';

  @override
  String get weSentYouAnEmail => 'Du har fått en e-post';

  @override
  String get whoCanPerformWhichAction => 'Hvem kan utføre hvilken handling';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Hvem tillates å ta del i denne gruppen';

  @override
  String get whyDoYouWantToReportThis =>
      'Hvorfor ønsker du å rapportere dette?';

  @override
  String get wipeChatBackup =>
      'Wipe your chat backup to create a new recovery key?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Med disse adressene kan du gjenopprette passordet ditt hvis du trenger det.';

  @override
  String get writeAMessage => 'Skriv en melding …';

  @override
  String get yes => 'Ja';

  @override
  String get you => 'Deg';

  @override
  String get youAreInvitedToThisChat => 'Du er invitert til denne sludringen';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Du deltar ikke lenger i denne sludringen';

  @override
  String get youCannotInviteYourself => 'Du kan ikke invitere deg selv';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Du har blitt bannlyst fra denne sludringen';

  @override
  String get yourPublicKey => 'Din offentlige nøkkel';

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
  String get search => 'Søk';

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
