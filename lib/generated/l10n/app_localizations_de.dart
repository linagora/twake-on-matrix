// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class L10nDe extends L10n {
  L10nDe([String locale = 'de']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein!';

  @override
  String get pleaseEnterValidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get repeatPassword => 'Passwort wiederholen';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Bitte wähle mindestens $min Zeichen.';
  }

  @override
  String get about => 'Über';

  @override
  String get updateAvailable => 'Twake-Chat-Aktualisierung verfügbar';

  @override
  String get updateNow => 'Update im Hintergrund starten';

  @override
  String get accept => 'Annehmen';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username hat die Einladung angenommen';
  }

  @override
  String get account => 'Konto';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username hat Ende-zu-Ende Verschlüsselung aktiviert';
  }

  @override
  String get addEmail => 'E-Mail hinzufügen';

  @override
  String get confirmMatrixId =>
      'Bitte bestätigen deine Matrix-ID, um dein Konto zu löschen.';

  @override
  String supposedMxid(Object mxid) {
    return 'das sollte sein $mxid';
  }

  @override
  String get addGroupDescription =>
      'Eine Beschreibung für die Gruppe hinzufügen';

  @override
  String get addToSpace => 'Zum Space hinzufügen';

  @override
  String get admin => 'Admin';

  @override
  String get alias => 'Alias';

  @override
  String get all => 'Alle';

  @override
  String get allChats => 'Alle Chats';

  @override
  String get commandHint_googly => 'Googly Eyes senden';

  @override
  String get commandHint_cuddle => 'Umarmung senden';

  @override
  String get commandHint_hug => 'Umarmung senden';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName hat dir Googly Eyes gesendet';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName knuddelt dich';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName umarmt dich';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName hat den Anruf angenommen';
  }

  @override
  String get anyoneCanJoin => 'Jeder darf beitreten';

  @override
  String get appLock => 'Anwendungssperre';

  @override
  String get archive => 'Archiv';

  @override
  String get archivedRoom => 'Archivierter Raum';

  @override
  String get areGuestsAllowedToJoin => 'Dürfen Gäste beitreten';

  @override
  String get areYouSure => 'Bist du sicher?';

  @override
  String get areYouSureYouWantToLogout => 'Willst du dich wirklich abmelden?';

  @override
  String get askSSSSSign =>
      'Bitte gib, um die andere Person signieren zu können, dein Sicherheitsschlüssel oder Wiederherstellungsschlüssel ein.';

  @override
  String askVerificationRequest(Object username) {
    return 'Diese Bestätigungsanfrage von $username annehmen?';
  }

  @override
  String get autoplayImages =>
      'Animierte Sticker und Emotes automatisch abspielen';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Der Homeserver unterstützt diese Anmelde-Typen:\n$serverVersions\nAber diese App unterstützt nur:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Senden mit Enter';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Der Homeserver unterstützt die Spec-Versionen:\n$serverVersions\nAber diese App unterstützt nur:\n$supportedVersions';
  }

  @override
  String get banFromChat => 'Aus dem Chat verbannen';

  @override
  String get banned => 'Verbannt';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username hat $targetName verbannt';
  }

  @override
  String get blockDevice => 'Blockiere Gerät';

  @override
  String get blocked => 'Blockiert';

  @override
  String get botMessages => 'Bot-Nachrichten';

  @override
  String get bubbleSize => 'Sprechblasengröße';

  @override
  String get cancel => 'Abbrechen';

  @override
  String cantOpenUri(Object uri) {
    return 'Die URI $uri kann nicht geöffnet werden';
  }

  @override
  String get changeDeviceName => 'Gerätenamen ändern';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username hat den Chat-Avatar geändert';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username hat die Chat-Beschreibung geändert zu: „$description“';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username hat den Chat-Namen geändert zu: „$chatname“';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username hat die Chat-Berechtigungen geändert';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username hat den Nicknamen geändert zu: „$displayname“';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username hat die Zugangsregeln für Gäste geändert';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username hat die Zugangsregeln für Gäste geändert zu: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username hat die Sichtbarkeit des Chat-Verlaufs geändert';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username hat die Sichtbarkeit des Chat-Verlaufs geändert zu: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username hat die Zugangsregeln geändert';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username hat die Zugangsregeln geändert zu: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username hat das Profilbild geändert';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username hat die Raum-Aliasse geändert';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username hat den Einladungslink geändert';
  }

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get changeTheHomeserver => 'Anderen Homeserver verwenden';

  @override
  String get changeTheme => 'Ändere Deinen Style';

  @override
  String get changeTheNameOfTheGroup => 'Gruppenname ändern';

  @override
  String get changeWallpaper => 'Hintergrund ändern';

  @override
  String get changeYourAvatar => 'Deinen Avatar ändern';

  @override
  String get channelCorruptedDecryptError =>
      'Die Verschlüsselung wurde korrumpiert';

  @override
  String get chat => 'Chat';

  @override
  String get yourUserId => 'Deine Benutzer-ID:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'Dein Chat-Backup wurde eingerichtet.';

  @override
  String get chatBackup => 'Chat-Backup';

  @override
  String get chatBackupDescription =>
      'Deine alten Nachrichten sind mit einem Wiederherstellungsschlüssel gesichert. Bitte stellen sicher, dass du ihn nicht verlierst.';

  @override
  String get chatDetails => 'Gruppeninfo';

  @override
  String get chatHasBeenAddedToThisSpace => 'Chat wurde zum Space hinzugefügt';

  @override
  String get chats => 'Chats';

  @override
  String get chooseAStrongPassword => 'Wähle ein sicheres Passwort';

  @override
  String get chooseAUsername => 'Wähle einen Benutzernamen';

  @override
  String get clearArchive => 'Archiv leeren';

  @override
  String get close => 'Schließen';

  @override
  String get commandHint_markasdm => 'Als Direktnachrichtenraum markieren';

  @override
  String get commandHint_markasgroup => 'Als Gruppe markieren';

  @override
  String get commandHint_ban =>
      'Verbanne den übergebenen Benutzer aus diesen Raum';

  @override
  String get commandHint_clearcache => 'Zwischenspeicher löschen';

  @override
  String get commandHint_create =>
      'Erstelle ein leeren Gruppenchat\nBenutze --no-encryption um die Verschlüsselung auszuschalten';

  @override
  String get commandHint_discardsession => 'Sitzung verwerfen';

  @override
  String get commandHint_dm =>
      'Starte einen direkten Chat\nBenutze --no-encryption um die Verschlüsselung auszuschalten';

  @override
  String get commandHint_html => 'Sende HTML-formatierten Text';

  @override
  String get commandHint_invite => 'Lade den Benutzer in diesen Raum ein';

  @override
  String get commandHint_join => 'Betrete den übergebenen Raum';

  @override
  String get commandHint_kick =>
      'Entferne den übergebenen Benutzer aus diesem Raum';

  @override
  String get commandHint_leave => 'Diesen Raum verlassen';

  @override
  String get commandHint_me => 'Beschreibe dich selbst';

  @override
  String get commandHint_myroomavatar =>
      'Setze dein Profilbild nur für diesen Raum (MXC-Uri)';

  @override
  String get commandHint_myroomnick =>
      'Setze deinen Anzeigenamen nur für diesen Raum';

  @override
  String get commandHint_op =>
      'Setze den übergeben Powerlevel des Benutzers (Standard: 50)';

  @override
  String get commandHint_plain => 'Sende unformatierten Text';

  @override
  String get commandHint_react => 'Sende die Antwort als Reaction';

  @override
  String get commandHint_send => 'Text senden';

  @override
  String get commandHint_unban =>
      'Hebe die Verbannung dieses Benutzers in diesem Raum auf';

  @override
  String get commandInvalid => 'Befehl ungültig';

  @override
  String commandMissing(Object command) {
    return '$command ist kein Befehl.';
  }

  @override
  String get compareEmojiMatch =>
      'Vergleiche und stelle sicher, dass die folgenden Emoji mit denen des anderen Gerätes übereinstimmen:';

  @override
  String get compareNumbersMatch =>
      'Vergleiche und stelle sicher, dass die folgenden Zahlen mit denen des anderen Gerätes übereinstimmen:';

  @override
  String get configureChat => 'Chat konfigurieren';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get connect => 'Verbinden';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'Kontakt wurde in die Gruppe eingeladen';

  @override
  String get containsDisplayName => 'Enthält Anzeigenamen';

  @override
  String get containsUserName => 'Enthält Benutzernamen';

  @override
  String get contentHasBeenReported =>
      'Der Inhalt wurde den Serveradministratoren gemeldet';

  @override
  String get copiedToClipboard => 'Wurde in die Zwischenablage kopiert';

  @override
  String get copy => 'Kopieren';

  @override
  String get copyToClipboard => 'In Zwischenablage kopieren';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Nachricht konnte nicht entschlüsselt werden: $error';
  }

  @override
  String countMembers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
      zero: 'keine Mitglieder',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Erstellen';

  @override
  String createdTheChat(Object username) {
    return '💬 $username hat den Chat erstellt';
  }

  @override
  String get createNewGroup => 'Neue Gruppe';

  @override
  String get createNewSpace => 'Neuer Space';

  @override
  String get crossSigningEnabled => 'Cross-Signing ist aktiviert';

  @override
  String get currentlyActive => 'Jetzt gerade online';

  @override
  String get darkTheme => 'Dunkel';

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
      'Dies deaktiviert dein Konto. Es kann nicht rückgängig gemacht werden! Bist du sicher?';

  @override
  String get defaultPermissionLevel => 'Standardberechtigungsstufe';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteMessage => 'Nachricht löschen';

  @override
  String get deny => 'Ablehnen';

  @override
  String get device => 'Gerät';

  @override
  String get deviceId => 'Geräte-ID';

  @override
  String get devices => 'Geräte';

  @override
  String get directChats => 'Direkte Chats';

  @override
  String get discover => 'Entdecken';

  @override
  String get displaynameHasBeenChanged => 'Anzeigename wurde geändert';

  @override
  String get download => 'Herunterladen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editBlockedServers => 'Blockierte Server einstellen';

  @override
  String get editChatPermissions => 'Chatberechtigungen bearbeiten';

  @override
  String get editDisplayname => 'Anzeigename ändern';

  @override
  String get editRoomAliases => 'Raum-Aliase bearbeiten';

  @override
  String get editRoomAvatar => 'Raumavatar bearbeiten';

  @override
  String get emoteExists => 'Emoticon existiert bereits!';

  @override
  String get emoteInvalid => 'Ungültiges Emoticon-Kürzel!';

  @override
  String get emotePacks => 'Emoticon-Bündel für Raum';

  @override
  String get emoteSettings => 'Emoticon-Optionen';

  @override
  String get emoteShortcode => 'Emoticon-Kürzel';

  @override
  String get emoteWarnNeedToPick => 'Wähle ein Emoticon-Kürzel und ein Bild!';

  @override
  String get emptyChat => 'Leerer Chat';

  @override
  String get enableEmotesGlobally => 'Aktiviere Emoticon-Bündel global';

  @override
  String get enableEncryption => 'Verschlüsselung anschalten';

  @override
  String get enableEncryptionWarning =>
      'Du wirst die Verschlüsselung nicht mehr ausstellen können. Bist Du sicher?';

  @override
  String get encrypted => 'Verschlüsselt';

  @override
  String get encryption => 'Verschlüsselung';

  @override
  String get encryptionNotEnabled => 'Verschlüsselung ist nicht aktiviert';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName hat den Anruf beendet';
  }

  @override
  String get enterGroupName => 'Chatname eingeben';

  @override
  String get enterAnEmailAddress => 'Gib eine E-Mail-Adresse ein';

  @override
  String get enterASpacepName => 'Namen für den Space eingeben';

  @override
  String get homeserver => 'Homeserver';

  @override
  String get enterYourHomeserver => 'Gib Deinen Homeserver ein';

  @override
  String errorObtainingLocation(Object error) {
    return 'Fehler beim Suchen des Standortes: $error';
  }

  @override
  String get everythingReady => 'Alles fertig!';

  @override
  String get extremeOffensive => 'Extrem beleidigend';

  @override
  String get fileName => 'Dateiname';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Schriftgröße';

  @override
  String get forward => 'Weiterleiten';

  @override
  String get friday => 'Fr';

  @override
  String get fromJoining => 'Ab dem Beitritt';

  @override
  String get fromTheInvitation => 'Ab der Einladung';

  @override
  String get goToTheNewRoom => 'Zum neuen Raum wechseln';

  @override
  String get group => 'Gruppe';

  @override
  String get groupDescription => 'Gruppenchatbeschreibung';

  @override
  String get groupDescriptionHasBeenChanged =>
      'Gruppenchatbeschreibung geändert';

  @override
  String get groupIsPublic => 'Gruppenchat ist öffentlich';

  @override
  String get groups => 'Gruppenchats';

  @override
  String groupWith(Object displayname) {
    return 'Gruppenchat mit $displayname';
  }

  @override
  String get guestsAreForbidden => 'Gäste sind verboten';

  @override
  String get guestsCanJoin => 'Gäste dürfen beitreten';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username hat die Einladung für $targetName zurückgezogen';
  }

  @override
  String get help => 'Hilfe';

  @override
  String get hideRedactedEvents => 'Gelöschte Nachrichten ausblenden';

  @override
  String get hideUnknownEvents => 'Unbekannte Ereignisse ausblenden';

  @override
  String get howOffensiveIsThisContent => 'Wie beleidigend ist dieser Inhalt?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Identität';

  @override
  String get ignore => 'Ignorieren';

  @override
  String get ignoredUsers => 'Ignorierte Personen';

  @override
  String get ignoreListDescription =>
      'Du kannst störende Personen ignorieren. Du bist dann nicht mehr in der Lage, Nachrichten oder Raumeinladungen von diesen zu erhalten.';

  @override
  String get ignoreUsername => 'Ignoriere Benutzername';

  @override
  String get iHaveClickedOnLink => 'Ich habe den Link angeklickt';

  @override
  String get incorrectPassphraseOrKey =>
      'Falsches Passwort oder Wiederherstellungsschlüssel';

  @override
  String get inoffensive => 'Harmlos';

  @override
  String get inviteContact => 'Kontakt einladen';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Kontakt in die Gruppe $groupName einladen';
  }

  @override
  String get invited => 'Eingeladen';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username hat $targetName eingeladen';
  }

  @override
  String get invitedUsersOnly => 'Nur eingeladene Mitglieder';

  @override
  String get inviteForMe => 'Einladung für mich';

  @override
  String inviteText(Object username, Object link) {
    return '$username hat Dich zu FluffyChat eingeladen. \n1. Installiere FluffyChat: https://fluffychat.im \n2. Melde Dich in der App an \n3. Öffne den Einladungslink: $link';
  }

  @override
  String get isTyping => 'schreibt';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username ist dem Chat beigetreten';
  }

  @override
  String get joinRoom => 'Raum beitreten';

  @override
  String get keysCached => 'Keys sind gecached';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username hat $targetName hinausgeworfen';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username hat $targetName hinausgeworfen und verbannt';
  }

  @override
  String get kickFromChat => 'Aus dem Chat hinauswerfen';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Zuletzt aktiv: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Vor sehr langer Zeit gesehen';

  @override
  String get leave => 'Verlassen';

  @override
  String get leftTheChat => 'Hat den Chat verlassen';

  @override
  String get license => 'Lizenz';

  @override
  String get lightTheme => 'Hell';

  @override
  String loadCountMoreParticipants(Object count) {
    return '$count weitere Mitglieder laden';
  }

  @override
  String get dehydrate => 'Sitzung exportieren und Gerät löschen';

  @override
  String get dehydrateWarning =>
      'Diese Aktion kann nicht rückgängig gemacht werden. Stelle sicher, dass du die Sicherungsdatei sicher aufbewahrst.';

  @override
  String get dehydrateShare =>
      'Dies ist dein privater FluffyChat-Export. Stelle sicher, dass du ihn nicht verlierst und bewahre ihn privat auf.';

  @override
  String get dehydrateTor => 'TOR-Benutzer: Sitzung exportieren';

  @override
  String get dehydrateTorLong =>
      'Für TOR-Benutzer wird empfohlen, die Sitzung zu exportieren, bevor das Fenster geschlossen wird.';

  @override
  String get hydrateTor => 'TOR-Benutzer: Session-Export importieren';

  @override
  String get hydrateTorLong =>
      'Hast du deine Sitzung das letzte Mal auf TOR exportiert? Importiere sie schnell und chatte weiter.';

  @override
  String get hydrate => 'Aus Sicherungsdatei wiederherstellen';

  @override
  String get loadingPleaseWait => 'Lade … Bitte warten.';

  @override
  String get loadingStatus => 'Status wird geladen ...';

  @override
  String get loadMore => 'Mehr laden …';

  @override
  String get locationDisabledNotice =>
      'Standort ist deaktiviert. Bitte aktivieren, um den Standort teilen zu können.';

  @override
  String get locationPermissionDeniedNotice =>
      'Standort-Berechtigung wurde abgelehnt. Bitte akzeptieren, um den Standort teilen zu können.';

  @override
  String get login => 'Anmelden';

  @override
  String logInTo(Object homeserver) {
    return 'Bei $homeserver anmelden';
  }

  @override
  String get loginWithOneClick => 'Anmelden mit einem Klick';

  @override
  String get logout => 'Abmelden';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Gib bitte einen richtigen Benutzernamen ein';

  @override
  String get memberChanges => 'Änderungen der Mitglieder';

  @override
  String get mention => 'Erwähnen';

  @override
  String get messages => 'Nachrichten';

  @override
  String get messageWillBeRemovedWarning =>
      'Nachricht wird für alle Mitglieder entfernt';

  @override
  String get noSearchResult => 'Keine Suchergebnisse.';

  @override
  String get moderator => 'Moderator';

  @override
  String get monday => 'Mo';

  @override
  String get muteChat => 'Stummschalten';

  @override
  String get needPantalaimonWarning =>
      'Bitte beachte, dass du Pantalaimon brauchst, um Ende-zu-Ende-Verschlüsselung benutzen zu können.';

  @override
  String get newChat => 'Neuer Chat';

  @override
  String get newMessageInTwake => 'Sie haben 1 verschlüsselte Nachricht';

  @override
  String get newVerificationRequest => 'Neue Verifikationsanfrage!';

  @override
  String get noMoreResult => 'Kein weiteres Ergebnis!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Weiter';

  @override
  String get no => 'Nein';

  @override
  String get noConnectionToTheServer => 'Keine Verbindung zum Server';

  @override
  String get noEmotesFound => 'Keine Emoticons gefunden. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Du kannst die Verschlüsselung erst aktivieren, sobald dieser Raum nicht mehr öffentlich zugänglich ist.';

  @override
  String get noGoogleServicesWarning =>
      'Es sieht so aus, als hättest du keine Google-Dienste auf deinem Gerät. Das ist eine gute Entscheidung für deine Privatsphäre! Um Push-Benachrichtigungen in FluffyChat zu erhalten, empfehlen wir die Verwendung von microG https://microg.org/ oder Unified Push https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 ist kein Matrix-Server, stattdessen $server2 benutzen?';
  }

  @override
  String get shareYourInviteLink => 'Teile deinen Einladungslink';

  @override
  String get typeInInviteLinkManually => 'Einladungslink manuell eingeben ...';

  @override
  String get scanQrCode => 'QR-Code scannen';

  @override
  String get none => 'Keiner';

  @override
  String get noPasswordRecoveryDescription =>
      'Du hast bisher keine Möglichkeit hinzugefügt, um dein Passwort zurückzusetzen.';

  @override
  String get noPermission => 'Keine Berechtigung';

  @override
  String get noRoomsFound => 'Keine Räume gefunden …';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String numUsersTyping(Object count) {
    return '$count Mitglieder schreiben';
  }

  @override
  String get obtainingLocation => 'Standort wird ermittelt';

  @override
  String get offensive => 'Beleidigend';

  @override
  String get offline => 'Offline';

  @override
  String get aWhileAgo => 'vor einiger Zeit';

  @override
  String get ok => 'Ok';

  @override
  String get online => 'Online';

  @override
  String get onlineKeyBackupEnabled =>
      'Online-Schlüsselsicherung ist aktiviert';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Hoppla! Leider ist beim Einrichten der Push-Benachrichtigungen ein Fehler aufgetreten.';

  @override
  String get oopsSomethingWentWrong => 'Hoppla! Etwas ist schiefgelaufen …';

  @override
  String get openAppToReadMessages => 'App öffnen, um Nachrichten zu lesen';

  @override
  String get openCamera => 'Kamera öffnen';

  @override
  String get openVideoCamera => 'Video aufnehmen';

  @override
  String get oneClientLoggedOut => 'Einer deiner Clients wurde abgemeldet';

  @override
  String get addAccount => 'Konto hinzufügen';

  @override
  String get editBundlesForAccount => 'Bundles für dieses Konto bearbeiten';

  @override
  String get addToBundle => 'Zu einem Bundle hinzufügen';

  @override
  String get removeFromBundle => 'Von diesem Bundle entfernen';

  @override
  String get bundleName => 'Name des Bundles';

  @override
  String get enableMultiAccounts =>
      '(BETA) Aktiviere Multi-Accounts für dieses Gerät';

  @override
  String get openInMaps => 'In Maps öffnen';

  @override
  String get link => 'Link';

  @override
  String get serverRequiresEmail =>
      'Dieser Server muss deine E-Mail-Adresse für die Registrierung überprüfen.';

  @override
  String get optionalGroupName => '(Optional) Gruppenname';

  @override
  String get or => 'Oder';

  @override
  String get participant => 'Mitglieder';

  @override
  String get passphraseOrKey => 'Passwort oder Wiederherstellungsschlüssel';

  @override
  String get password => 'Passwort';

  @override
  String get passwordForgotten => 'Passwort vergessen';

  @override
  String get passwordHasBeenChanged => 'Passwort wurde geändert';

  @override
  String get passwordRecovery => 'Passwort wiederherstellen';

  @override
  String get people => 'Personen';

  @override
  String get pickImage => 'Bild wählen';

  @override
  String get pin => 'Anpinnen';

  @override
  String play(Object fileName) {
    return '$fileName abspielen';
  }

  @override
  String get pleaseChoose => 'Bitte wählen';

  @override
  String get pleaseChooseAPasscode => 'Bitte einen Code festlegen';

  @override
  String get pleaseChooseAUsername => 'Bitte wähle einen Benutzernamen';

  @override
  String get pleaseClickOnLink =>
      'Bitte auf den Link in der E-Mail klicken und dann fortfahren.';

  @override
  String get pleaseEnter4Digits =>
      'Bitte 4 Ziffern eingeben oder leer lassen, um die Anwendungssperre zu deaktivieren.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Bitte eine Matrix-ID eingeben.';

  @override
  String get pleaseEnterRecoveryKey =>
      'Bitte gebe deinen Wiederherstellungsschlüssel ein:';

  @override
  String get pleaseEnterYourPassword => 'Bitte dein Passwort eingeben';

  @override
  String get pleaseEnterYourPin => 'Bitte gib deine Pin ein';

  @override
  String get pleaseEnterYourUsername => 'Bitte deinen Benutzernamen eingeben';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Bitte folge den Anweisungen auf der Website und tippe auf Weiter.';

  @override
  String get privacy => 'Privatsphäre';

  @override
  String get publicRooms => 'Öffentliche Räume';

  @override
  String get pushRules => 'Push-Regeln';

  @override
  String get reason => 'Grund';

  @override
  String get recording => 'Aufnahme';

  @override
  String redactedAnEvent(Object username) {
    return '$username hat ein Ereignis entfernt';
  }

  @override
  String get redactMessage => 'Nachricht löschen';

  @override
  String get register => 'Registrieren';

  @override
  String get reject => 'Ablehnen';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username hat die Einladung abgelehnt';
  }

  @override
  String get rejoin => 'Wieder beitreten';

  @override
  String get remove => 'Entfernen';

  @override
  String get removeAllOtherDevices => 'Alle anderen Geräte entfernen';

  @override
  String removedBy(Object username) {
    return 'Entfernt von $username';
  }

  @override
  String get removeDevice => 'Gerät entfernen';

  @override
  String get unbanFromChat => 'Verbannung aufheben';

  @override
  String get removeYourAvatar => 'Deinen Avatar löschen';

  @override
  String get renderRichContent => 'Zeige Nachrichtenformatierungen an';

  @override
  String get replaceRoomWithNewerVersion => 'Raum mit neuer Version ersetzen';

  @override
  String get reply => 'Antworten';

  @override
  String get reportMessage => 'Nachricht melden';

  @override
  String get requestPermission => 'Berechtigung anfragen';

  @override
  String get roomHasBeenUpgraded => 'Der Raum wurde ge-upgraded';

  @override
  String get roomVersion => 'Raumversion';

  @override
  String get saturday => 'Samstag';

  @override
  String get saveFile => 'Datei speichern';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Sicherheit';

  @override
  String get recoveryKey => 'Wiederherstellungs-Schlüssel';

  @override
  String get recoveryKeyLost => 'Wiederherstellungsschlüssel verloren?';

  @override
  String seenByUser(Object username) {
    return 'Gelesen von $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gelesen von $username und $count anderen',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Gelesen von $username und $username2';
  }

  @override
  String get send => 'Senden';

  @override
  String get sendAMessage => 'Nachricht schreiben';

  @override
  String get sendAsText => 'Sende als Text';

  @override
  String get sendAudio => 'Sende Audiodatei';

  @override
  String get sendFile => 'Datei senden';

  @override
  String get sendImage => 'Bild senden';

  @override
  String get sendMessages => 'Nachrichten senden';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Sende Original';

  @override
  String get sendSticker => 'Sticker senden';

  @override
  String get sendVideo => 'Sende Video';

  @override
  String sentAFile(Object username) {
    return '📁 $username hat eine Datei gesendet';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username hat eine Audio-Datei gesendet';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username hat ein Bild gesendet';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username hat einen Sticker gesendet';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username hat ein Video gesendet';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName hat Anrufinformationen geschickt';
  }

  @override
  String get separateChatTypes => 'Separate Direktchats und Gruppen';

  @override
  String get setAsCanonicalAlias => 'Als Haupt-Alias festlegen';

  @override
  String get setCustomEmotes => 'Eigene Emoticons einstellen';

  @override
  String get setGroupDescription => 'Gruppenbeschreibung festlegen';

  @override
  String get setInvitationLink => 'Einladungslink festlegen';

  @override
  String get setPermissionsLevel => 'Berechtigungsstufe einstellen';

  @override
  String get setStatus => 'Status ändern';

  @override
  String get settings => 'Optionen';

  @override
  String get share => 'Teilen';

  @override
  String sharedTheLocation(Object username) {
    return '$username hat den Standort geteilt';
  }

  @override
  String get shareLocation => 'Standort teilen';

  @override
  String get showDirectChatsInSpaces =>
      'Zugehörige Direkt-Chats in Spaces anzeigen';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get signUp => 'Registrieren';

  @override
  String get singlesignon => 'Einmalige Anmeldung';

  @override
  String get skip => 'Überspringe';

  @override
  String get invite => 'Einladen';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get spaceIsPublic => 'Space ist öffentlich';

  @override
  String get spaceName => 'Space-Name';

  @override
  String startedACall(Object senderName) {
    return '$senderName hat einen Anruf getätigt';
  }

  @override
  String get startFirstChat => 'Starte deinen ersten Chat';

  @override
  String get status => 'Status';

  @override
  String get statusExampleMessage => 'Wie geht es dir heute?';

  @override
  String get submit => 'Absenden';

  @override
  String get sunday => 'Sonntag';

  @override
  String get synchronizingPleaseWait => 'Synchronisiere... Bitte warten.';

  @override
  String get systemTheme => 'System';

  @override
  String get theyDontMatch => 'Stimmen nicht überein';

  @override
  String get theyMatch => 'Stimmen überein';

  @override
  String get thisRoomHasBeenArchived => 'Dieser Raum wurde archiviert.';

  @override
  String get thursday => 'Donnerstag';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Favorite umschalten';

  @override
  String get toggleMuted => 'Stummgeschaltete umschalten';

  @override
  String get toggleUnread => 'Markieren als gelesen/ungelesen';

  @override
  String get tooManyRequestsWarning =>
      'Zu viele Anfragen. Bitte versuche es später noch einmal!';

  @override
  String get transferFromAnotherDevice => 'Von anderem Gerät übertragen';

  @override
  String get tryToSendAgain => 'Nochmal versuchen zu senden';

  @override
  String get tuesday => 'Dienstag';

  @override
  String get unavailable => 'Nicht verfügbar';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username hat die Verbannung von $targetName aufgehoben';
  }

  @override
  String get unblockDevice => 'Geräteblockierung aufheben';

  @override
  String get unknownDevice => 'Unbekanntes Gerät';

  @override
  String get unknownEncryptionAlgorithm =>
      'Unbekannter Verschlüsselungsalgorithmus';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Unbekanntes Ereignis „$type“';
  }

  @override
  String get unmuteChat => 'Stumm aus';

  @override
  String get unpin => 'loslösen';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount ungelesene Unterhaltungen',
      one: '1 ungelesene Unterhaltung',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username und $count andere schreiben';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username und $username2 schreiben';
  }

  @override
  String userIsTyping(Object username) {
    return '$username schreibt';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username hat den Chat verlassen';
  }

  @override
  String get username => 'Benutzername';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username hat ein $type-Ereignis gesendet';
  }

  @override
  String get unverified => 'Unverifiziert';

  @override
  String get verified => 'Verifiziert';

  @override
  String get verify => 'Bestätigen';

  @override
  String get verifyStart => 'Starte Verifikation';

  @override
  String get verifySuccess => 'Erfolgreich verifiziert!';

  @override
  String get verifyTitle => 'Anderes Konto wird verifiziert';

  @override
  String get videoCall => 'Videoanruf';

  @override
  String get visibilityOfTheChatHistory => 'Sichtbarkeit des Chat-Verlaufs';

  @override
  String get visibleForAllParticipants => 'Sichtbar für alle Mitglieder';

  @override
  String get visibleForEveryone => 'Für jeden sichtbar';

  @override
  String get voiceMessage => 'Sprachnachricht';

  @override
  String get waitingPartnerAcceptRequest =>
      'Warte darauf, dass der Partner die Anfrage annimmt …';

  @override
  String get waitingPartnerEmoji =>
      'Warte darauf, dass der Partner die Emoji annimmt …';

  @override
  String get waitingPartnerNumbers =>
      'Warten, dass der Partner die Zahlen annimmt …';

  @override
  String get wallpaper => 'Hintergrund';

  @override
  String get warning => 'Achtung!';

  @override
  String get wednesday => 'Mittwoch';

  @override
  String get weSentYouAnEmail => 'Wir haben dir eine E-Mail gesendet';

  @override
  String get whoCanPerformWhichAction => 'Wer kann welche Aktion ausführen';

  @override
  String get whoIsAllowedToJoinThisGroup => 'Wer darf der Gruppe beitreten';

  @override
  String get whyDoYouWantToReportThis => 'Warum willst du dies melden?';

  @override
  String get wipeChatBackup =>
      'Den Chat-Backup löschen, um einen neuen Wiederherstellungsschlüssel zu erstellen?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Mit diesen Adressen kannst du dein Passwort wiederherstellen, wenn du es vergessen hast.';

  @override
  String get writeAMessage => 'Schreibe eine Nachricht …';

  @override
  String get yes => 'Ja';

  @override
  String get you => 'Du';

  @override
  String get youAreInvitedToThisChat => 'Du wurdest in diesen Chat eingeladen';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Du bist kein Mitglied mehr in diesem Chat';

  @override
  String get youCannotInviteYourself => 'Du kannst dich nicht selbst einladen';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Du wurdest aus dem Chat verbannt';

  @override
  String get yourPublicKey => 'Dein öffentlicher Schlüssel';

  @override
  String get messageInfo => 'Nachrichten-Info';

  @override
  String get time => 'Zeit';

  @override
  String get messageType => 'Nachrichtentyp';

  @override
  String get sender => 'Absender:in';

  @override
  String get openGallery => 'Galerie öffnen';

  @override
  String get removeFromSpace => 'Aus dem Space entfernen';

  @override
  String get addToSpaceDescription =>
      'Wähle einen Space aus, um diesen Chat hinzuzufügen.';

  @override
  String get start => 'Start';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Um deine alten Nachrichten zu entsperren, gib bitte den Wiederherstellungsschlüssel ein, der in einer früheren Sitzung generiert wurde. Dein Wiederherstellungsschlüssel ist NICHT dein Passwort.';

  @override
  String get addToStory => 'Story hinzufügen';

  @override
  String get publish => 'Veröffentlichen';

  @override
  String get whoCanSeeMyStories => 'Wer kann meine Storys sehen?';

  @override
  String get unsubscribeStories => 'Story deabbonieren';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Dieses Mitglied hat noch keine Story gepostet';

  @override
  String get yourStory => 'Deine Story';

  @override
  String get replyHasBeenSent => 'Antwort wurde gesendet';

  @override
  String videoWithSize(Object size) {
    return 'Video ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Story von $date: \n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Bitte beachte, dass sich Leute in deiner Story sehen und kontaktieren können.';

  @override
  String get whatIsGoingOn => 'Was gibt es neues?';

  @override
  String get addDescription => 'Beschreibung hinzufügen';

  @override
  String get storyPrivacyWarning =>
      'Bitte beachte, dass sich die Leute in deiner Story sehen und kontaktieren können. Ihre Stories sind 24 Stunden lang sichtbar, aber es gibt keine Garantie dafür, dass sie von allen Geräten und Servern gelöscht werden.';

  @override
  String get iUnderstand => 'Ich habe verstanden';

  @override
  String get openChat => 'Chat öffnen';

  @override
  String get markAsRead => 'Als gelesen markiert';

  @override
  String get reportUser => 'Benutzer melden';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get matrixWidgets => 'Matrix-Widgets';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reagierte mit $reaction';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin =>
      'Möchtest du das Ereignis wirklich dauerhaft lösen?';

  @override
  String get emojis => 'Emojis';

  @override
  String get placeCall => 'Anruf tätigen';

  @override
  String get voiceCall => 'Sprachanruf';

  @override
  String get unsupportedAndroidVersion => 'Nicht unterstützte Android-Version';

  @override
  String get unsupportedAndroidVersionLong =>
      'Diese Funktion erfordert eine neuere Android-Version. Bitte suche nach Updates oder Lineage OS-Unterstützung.';

  @override
  String get videoCallsBetaWarning =>
      'Bitte beachte, dass sich Videoanrufe derzeit in der Beta-Phase befinden. Sie funktionieren möglicherweise nicht wie erwartet oder überhaupt nicht auf allen Plattformen.';

  @override
  String get experimentalVideoCalls => 'Experimentelle Videoanrufe';

  @override
  String get emailOrUsername => 'E-Mail oder Benutzername';

  @override
  String get indexedDbErrorTitle => 'Probleme im Privatmodus';

  @override
  String get indexedDbErrorLong =>
      'Die Nachrichtenspeicherung ist im privaten Modus standardmäßig leider nicht aktiviert.\nBitte besuche\n- about:config\n- Setze dom.indexedDB.privateBrowsing.enabled auf true\nAndernfalls ist es nicht möglich, FluffyChat auszuführen.';

  @override
  String switchToAccount(Object number) {
    return 'Zu Konto $number wechseln';
  }

  @override
  String get nextAccount => 'Nächstes Konto';

  @override
  String get previousAccount => 'Vorheriges Konto';

  @override
  String get editWidgets => 'Widgets bearbeiten';

  @override
  String get addWidget => 'Widget hinzufügen';

  @override
  String get widgetVideo => 'Video';

  @override
  String get widgetEtherpad => 'Textnotiz';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Angepasst';

  @override
  String get widgetName => 'Name';

  @override
  String get widgetUrlError => 'Das ist keine gültige URL.';

  @override
  String get widgetNameError => 'Bitte gib einen Anzeigenamen an.';

  @override
  String get errorAddingWidget => 'Fehler beim Hinzufügen des Widgets.';

  @override
  String get youRejectedTheInvitation => 'Du hast die Einladung abgelehnt';

  @override
  String get youJoinedTheChat => 'Du bist dem Chat beigetreten';

  @override
  String get youAcceptedTheInvitation => '👍 Du hast die Einladung angenommen';

  @override
  String youBannedUser(Object user) {
    return 'Du hast den $user verbannt';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Du hast die Einladung für $user zurückgezogen';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 Du wurdest von $user eingeladen';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 Du hast $user eingeladen';
  }

  @override
  String youKicked(Object user) {
    return '👞 Du hast $user rausgeworfen';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 Du hast $user rausgeworfen und verbannt';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Du hast die Verbannung von $user rückgängig gemacht';
  }

  @override
  String get noEmailWarning =>
      'Bitte gib eine gültige E-Mail-Adresse ein. Andernfalls kannst du dein Passwort nicht zurücksetzen. Wenn du das nicht möchtest, tippe erneut auf die Schaltfläche, um fortzufahren.';

  @override
  String get stories => 'Status';

  @override
  String get users => 'Benutzer';

  @override
  String get enableAutoBackups => 'Aktiviere automatische Sicherungen';

  @override
  String get unlockOldMessages => 'Entsperre alte Nachrichten';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription =>
      'Speicher den Wiederherstellungsschlüssel im sicheren Speicher dieses Geräts.';

  @override
  String get saveKeyManuallyDescription =>
      'Speicher diesen Schlüssel manuell, indem du den Systemfreigabedialog oder die Zwischenablage auslöst.';

  @override
  String get storeInAndroidKeystore => 'Im Android KeyStore speichern';

  @override
  String get storeInAppleKeyChain => 'Im Apple KeyChain speichern';

  @override
  String get storeSecurlyOnThisDevice => 'Auf diesem Gerät sicher speichern';

  @override
  String countFiles(Object count) {
    return '$count Dateien';
  }

  @override
  String get user => 'Benutzer';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get foregroundServiceRunning =>
      'Diese Benachrichtigung wird angezeigt, wenn der Vordergrunddienst ausgeführt wird.';

  @override
  String get screenSharingTitle => 'Bildschirm teilen';

  @override
  String get screenSharingDetail => 'Du teilst deinen Bildschirm in FuffyChat';

  @override
  String get callingPermissions => 'Anrufberechtigungen';

  @override
  String get callingAccount => 'Anrufkonto';

  @override
  String get callingAccountDetails =>
      'Ermöglicht FluffyChat, die native Android-Dialer-App zu verwenden.';

  @override
  String get appearOnTop => 'Oben erscheinen';

  @override
  String get appearOnTopDetails =>
      'Ermöglicht, dass die App oben angezeigt wird (nicht erforderlich, wenn Sie Fluffychat bereits als Anrufkonto eingerichtet haben)';

  @override
  String get otherCallingPermissions =>
      'Mikrofon, Kamera und andere FluffyChat-Berechtigungen';

  @override
  String get whyIsThisMessageEncrypted =>
      'Warum ist diese Nachricht nicht lesbar?';

  @override
  String get noKeyForThisMessage =>
      'Dies kann passieren, wenn die Nachricht gesendet wurde, bevor du dich auf diesem Gerät bei deinem Konto angemeldet hast.\n\nEs ist auch möglich, dass der Absender dein Gerät blockiert hat oder etwas mit der Internetverbindung schief gelaufen ist.\n\nKannst du die Nachricht in einer anderen Sitzung lesen? Dann kannst du die Nachricht davon übertragen! Gehe zu den Optionen > Geräte und vergewissere dich, dass sich deine Geräte gegenseitig verifiziert haben. Wenn du den Raum das nächste Mal öffnest und beide Sitzungen im Vordergrund sind, werden die Schlüssel automatisch übertragen.\n\nDu möchtest die Schlüssel beim Abmelden oder Gerätewechsel nicht verlieren? Stelle sicher, dass du das Chat-Backup in den Optionen aktiviert hast.';

  @override
  String get newGroup => 'Neue Gruppe';

  @override
  String get newSpace => 'Neuer Raum';

  @override
  String get enterSpace => 'Raum betreten';

  @override
  String get enterRoom => 'Raum betreten';

  @override
  String get allSpaces => 'Alle Spaces';

  @override
  String numChats(Object number) {
    return '$number Chats';
  }

  @override
  String get hideUnimportantStateEvents =>
      'Blende unwichtige Zustandsereignisse aus';

  @override
  String get doNotShowAgain => 'Nicht mehr anzeigen';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return 'Leerer Chat (was $oldDisplayName';
  }

  @override
  String get newSpaceDescription =>
      'Mit Spaces kannst du deine Chats zusammenfassen und private oder öffentliche Communities aufbauen.';

  @override
  String get encryptThisChat => 'Diesen Chat verschlüsseln';

  @override
  String get endToEndEncryption => 'Ende-zu-Ende-Verschlüsselung';

  @override
  String get disableEncryptionWarning =>
      'Aus Sicherheitsgründen können Sie die Verschlüsselung in einem Chat nicht deaktivieren, wo sie zuvor aktiviert wurde.';

  @override
  String get sorryThatsNotPossible => 'Sorry ... das ist nicht möglich';

  @override
  String get deviceKeys => 'Geräteschlüssel:';

  @override
  String get letsStart => 'Los geht\'s';

  @override
  String get enterInviteLinkOrMatrixId =>
      'Einladungslink oder Matrix-ID eingeben …';

  @override
  String get reopenChat => 'Chat wieder eröffnen';

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
  String get search => 'Suchen';

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
  String get clear => 'Leeren';

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
  String get matrixId => 'Matrix-ID';

  @override
  String get email => 'E-Mail';

  @override
  String get company => 'Unternehmen';

  @override
  String get basicInfo => 'GRUNDLEGENDE INFORMATIONEN';

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
