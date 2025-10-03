// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class L10nHe extends L10n {
  L10nHe([String locale = 'he']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'הסיסמאות לא תואמות!';

  @override
  String get pleaseEnterValidEmail => 'אנא כתוב כתובת אימייל תקינה.';

  @override
  String get repeatPassword => 'כתוב שוב את הסיסמה';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'אנא כתוב לפחות $min תווים';
  }

  @override
  String get about => 'אודות';

  @override
  String get updateAvailable => 'עדכון FluffyChat זמין';

  @override
  String get updateNow => 'התחל עדכון ברקע';

  @override
  String get accept => 'קבל';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username קיבל את ההזמנה';
  }

  @override
  String get account => 'חשבון';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username הפעיל הצפנה מקצה לקצה';
  }

  @override
  String get addEmail => 'הוסף מייל';

  @override
  String get confirmMatrixId => 'אנא אשר את ה ID שלך על מנת למחוק את המתשמש.';

  @override
  String supposedMxid(Object mxid) {
    return 'זה צריך להיות $mxid';
  }

  @override
  String get addGroupDescription => 'הוספת תיאור קבוצה';

  @override
  String get addToSpace => 'הוסף לחלל';

  @override
  String get admin => 'מנהל';

  @override
  String get alias => 'כינוי';

  @override
  String get all => 'הכל';

  @override
  String get allChats => 'כל הצ\'אטים';

  @override
  String get commandHint_googly => 'Send some googly eyes';

  @override
  String get commandHint_cuddle => 'שלח כרבול';

  @override
  String get commandHint_hug => 'שלח חיבוק';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName שלח לך עיניים';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName מחבק אותך';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName מחבק אותך.';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName ענה לשיחה';
  }

  @override
  String get anyoneCanJoin => 'כל אחד יכול להצטרף';

  @override
  String get appLock => 'נעילת אפליקציה';

  @override
  String get archive => 'ארכיון';

  @override
  String get archivedRoom => 'חדר בארכיון';

  @override
  String get areGuestsAllowedToJoin => 'האם משתמשים אורחים מורשים להצטרף';

  @override
  String get areYouSure => 'האם אתה בטוח?';

  @override
  String get areYouSureYouWantToLogout => 'האם אתה בטוח שברצונך לצאת?';

  @override
  String get askSSSSSign =>
      'כדי שתוכל לחתום על משתמש אחר , הזן את הסיסמה שלך או את מפתח השחזור.';

  @override
  String askVerificationRequest(Object username) {
    return 'לקבל בקשת אימות זו מ- $username?';
  }

  @override
  String get autoplayImages => 'הפעל אוטומטית מדבקות ואנימציות מונפשים';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'שרת הבית תומך בסוגי הכניסה:\n$serverVersions\nאבל אפליקציה זו תומכת רק ב:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'שלח בכניסה';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'שרת הבית תומך בגרסאות:\n$serverVersions\nאבל האפליקציה הזו תומכת רק ב-$supportedVersions';
  }

  @override
  String get banFromChat => 'צאט חסום';

  @override
  String get banned => 'חסום';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username חסם את $targetName';
  }

  @override
  String get blockDevice => 'חסום מכשיר';

  @override
  String get blocked => 'חסום';

  @override
  String get botMessages => 'הודעות בוט';

  @override
  String get bubbleSize => 'גודל בועות';

  @override
  String get cancel => 'ביטול';

  @override
  String cantOpenUri(Object uri) {
    return 'לא ניתן לפתוח את ה-URI $uri';
  }

  @override
  String get changeDeviceName => 'שנה את שם המכשיר';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username שינה את האווטאר של הצ\'אט';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username שינה את תיאור הצ\'אט ל: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username שינה את שם הצ\'אט ל: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username שינה את הרשאות הצ\'אט';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username שינה את שם התצוגה שלו ל: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username שינה את כללי הגישה לאורחים';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username שינה את כללי הגישה לאורחים ל: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username שינה את נראות ההיסטוריה';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username שינה את נראות ההיסטוריה ל: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username שינה את כללי ההצטרפות';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username שינה את כללי ההצטרפות ל: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username שינה את האווטאר שלו';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username שינה את כינוי החדר';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username שינה את קישור ההזמנה';
  }

  @override
  String get changePassword => 'שנה סיסמא';

  @override
  String get changeTheHomeserver => 'שנה את שרת הבית';

  @override
  String get changeTheme => 'שנה את הסגנון שלך';

  @override
  String get changeTheNameOfTheGroup => 'שנה את שם הקבוצה';

  @override
  String get changeWallpaper => 'שנה טפט';

  @override
  String get changeYourAvatar => 'שינוי האווטאר שלך';

  @override
  String get channelCorruptedDecryptError => 'ההצפנה נפגמה';

  @override
  String get chat => 'צ׳אט';

  @override
  String get yourUserId => 'מזהה המשתמש שלך:';

  @override
  String get yourChatBackupHasBeenSetUp => 'גיבוי הצ\'אט שלך הוגדר.';

  @override
  String get chatBackup => 'גיבוי צ\'אט';

  @override
  String get chatBackupDescription =>
      'גיבוי הצ\'אט שלך מאובטח באמצעות מפתח אבטחה. אנא וודא שאתה לא מאבד אותו.';

  @override
  String get chatDetails => 'פרטי צ\'אט';

  @override
  String get chatHasBeenAddedToThisSpace => 'צ\'אט נוסף למרחב הזה';

  @override
  String get chats => 'צ\'אטים';

  @override
  String get chooseAStrongPassword => 'בחר סיסמה חזקה';

  @override
  String get chooseAUsername => 'בחר שם משתמש';

  @override
  String get clearArchive => 'נקה ארכיון';

  @override
  String get close => 'סגור';

  @override
  String get commandHint_markasdm => 'סמן כצ׳אט ישיר';

  @override
  String get commandHint_markasgroup => 'סמן כצ׳אט';

  @override
  String get commandHint_ban => 'חסום את המשתמש הנתון מהחדר הזה';

  @override
  String get commandHint_clearcache => 'נקה מטמון';

  @override
  String get commandHint_create =>
      'צור צ\'אט קבוצתי ריק\nהשתמש ב--no-encryption כדי להשבית את ההצפנה';

  @override
  String get commandHint_discardsession => 'התעלם מהסשן';

  @override
  String get commandHint_dm =>
      'התחל צ\'אט ישיר\nהשתמש ב--no-encryption כדי להשבית את ההצפנה';

  @override
  String get commandHint_html => 'שלח טקסט בתבנית HTML';

  @override
  String get commandHint_invite => 'הזמן את המשתמש הנתון לחדר זה';

  @override
  String get commandHint_join => 'הצטרף לחדר הנתון';

  @override
  String get commandHint_kick => 'הסר את המשתמש הנתון מהחדר הזה';

  @override
  String get commandHint_leave => 'עזוב את החדר הזה';

  @override
  String get commandHint_me => 'תאר את עצמך';

  @override
  String get commandHint_myroomavatar =>
      'הגדר את התמונה שלך לחדר זה (על ידי mxc-uri)';

  @override
  String get commandHint_myroomnick => 'הגדר את שם התצוגה שלך עבור חדר זה';

  @override
  String get commandHint_op =>
      'הגדרת רמת צריכת החשמל של המשתמש הנתון (ברירת מחדל: 50)';

  @override
  String get commandHint_plain => 'שלח טקסט לא מעוצב';

  @override
  String get commandHint_react => 'שלח תשובה כתגובה';

  @override
  String get commandHint_send => 'שלח טקסט';

  @override
  String get commandHint_unban => 'בטל את החסימה של המשתמש הנתון מהחדר הזה';

  @override
  String get commandInvalid => 'הפקודה אינה חוקית';

  @override
  String commandMissing(Object command) {
    return '$command אינו פקודה.';
  }

  @override
  String get compareEmojiMatch =>
      'השווה וודא שהאימוג\'י הבאים תואמים לאלו של המכשיר השני:';

  @override
  String get compareNumbersMatch =>
      'השווה וודא שהמספרים הבאים תואמים לאלה של המכשיר השני:';

  @override
  String get configureChat => 'קביעת תצורה של צ\'אט';

  @override
  String get confirm => 'לאשר';

  @override
  String get connect => 'התחבר';

  @override
  String get contactHasBeenInvitedToTheGroup => 'איש הקשר הוזמן לקבוצה';

  @override
  String get containsDisplayName => 'מכיל שם תצוגה';

  @override
  String get containsUserName => 'מכיל שם משתמש';

  @override
  String get contentHasBeenReported => 'התוכן דווח למנהלי השרת';

  @override
  String get copiedToClipboard => 'הועתק ללוח הגזירים';

  @override
  String get copy => 'העתק';

  @override
  String get copyToClipboard => 'העתק ללוח';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'לא ניתן לפענח הודעה: $error';
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
  String get create => 'צור';

  @override
  String createdTheChat(Object username) {
    return '$username יצר את הצ\'אט';
  }

  @override
  String get createNewGroup => 'צור קבוצה חדשה';

  @override
  String get createNewSpace => 'חלל חדש';

  @override
  String get crossSigningEnabled => 'חתימה צולבת על';

  @override
  String get currentlyActive => 'פעיל כעת';

  @override
  String get darkTheme => 'כהה';

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
      'פעולה זו תשבית את חשבון המשתמש שלך. אי אפשר לבטל את זה! האם אתה בטוח?';

  @override
  String get defaultPermissionLevel => 'רמת הרשאת ברירת מחדל';

  @override
  String get delete => 'מחיקה';

  @override
  String get deleteAccount => 'מחק חשבון';

  @override
  String get deleteMessage => 'מחק הודעה';

  @override
  String get deny => 'דחה';

  @override
  String get device => 'מכשיר';

  @override
  String get deviceId => 'מזהה מכשיר';

  @override
  String get devices => 'התקנים';

  @override
  String get directChats => 'צ\'אטים ישירים';

  @override
  String get discover => 'לגלות';

  @override
  String get displaynameHasBeenChanged => 'שם התצוגה השתנה';

  @override
  String get download => 'Download';

  @override
  String get edit => 'ערוך';

  @override
  String get editBlockedServers => 'ערוך שרתים חסומים';

  @override
  String get editChatPermissions => 'ערוך הרשאות צ\'אט';

  @override
  String get editDisplayname => 'ערוך את שם התצוגה';

  @override
  String get editRoomAliases => 'ערוך כינויים לחדר';

  @override
  String get editRoomAvatar => 'עריכת אווטאר של חדר';

  @override
  String get emoteExists => 'אימוט כבר קיים!';

  @override
  String get emoteInvalid => 'Invalid emote shortcode!';

  @override
  String get emotePacks => 'Emote packs for chat';

  @override
  String get emoteSettings => 'Emote Settings';

  @override
  String get emoteShortcode => 'Emote shortcode';

  @override
  String get emoteWarnNeedToPick =>
      'You need to pick an emote shortcode and an image!';

  @override
  String get emptyChat => 'צ\'אט ריק';

  @override
  String get enableEmotesGlobally => 'Enable emote pack globally';

  @override
  String get enableEncryption => 'אפשר הצפנה';

  @override
  String get enableEncryptionWarning =>
      'לא תוכל לבטל את ההצפנה יותר. האם אתה בטוח?';

  @override
  String get encrypted => 'מוצפן';

  @override
  String get encryption => 'הצפנה';

  @override
  String get encryptionNotEnabled => 'ההצפנה אינה מופעלת';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName סיים את השיחה';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'הזן כתובת דואר אלקטרוני';

  @override
  String get enterASpacepName => 'הזן שם חלל';

  @override
  String get homeserver => 'שרת בית';

  @override
  String get enterYourHomeserver => 'הזן את שרת הבית שלך';

  @override
  String errorObtainingLocation(Object error) {
    return 'שגיאה בהשגת מיקום: $error';
  }

  @override
  String get everythingReady => 'הכל מוכן!';

  @override
  String get extremeOffensive => 'פוגעני ביותר';

  @override
  String get fileName => 'שם קובץ';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'גודל גופן';

  @override
  String get forward => 'העבר';

  @override
  String get friday => 'יום שישי';

  @override
  String get fromJoining => 'מהצטרפות';

  @override
  String get fromTheInvitation => 'מההזמנה';

  @override
  String get goToTheNewRoom => 'עבור לחדר החדש';

  @override
  String get group => 'קבוצה';

  @override
  String get groupDescription => 'תיאור קבוצה';

  @override
  String get groupDescriptionHasBeenChanged => 'תיאור הקבוצה השתנה';

  @override
  String get groupIsPublic => 'הקבוצה ציבורית';

  @override
  String get groups => 'קבוצות';

  @override
  String groupWith(Object displayname) {
    return 'קבוצה עם $displayname';
  }

  @override
  String get guestsAreForbidden => 'אורחים אסורים';

  @override
  String get guestsCanJoin => 'אורחים יכולים להצטרף';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username ביטל את ההזמנה עבור $targetName';
  }

  @override
  String get help => 'עזרה';

  @override
  String get hideRedactedEvents => 'הסתר אירועים מצונזרים';

  @override
  String get hideUnknownEvents => 'הסתר אירועים לא ידועים';

  @override
  String get howOffensiveIsThisContent => 'עד כמה התוכן הזה פוגעני?';

  @override
  String get id => 'מזהה';

  @override
  String get identity => 'זהות';

  @override
  String get ignore => 'התעלם';

  @override
  String get ignoredUsers => 'משתמשים שהתעלמו מהם';

  @override
  String get ignoreListDescription =>
      'באפשרותך להתעלם ממשתמשים שמפריעים לך. לא תוכל לקבל הודעות או הזמנות לחדר מהמשתמשים ברשימת ההתעלם האישית שלך.';

  @override
  String get ignoreUsername => 'התעלם משם משתמש';

  @override
  String get iHaveClickedOnLink => 'לחצתי על הקישור';

  @override
  String get incorrectPassphraseOrKey => 'ביטוי סיסמה או מפתח שחזור שגויים';

  @override
  String get inoffensive => 'לֹא פּוֹגֵעַ';

  @override
  String get inviteContact => 'הזמן איש קשר';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'הזמן איש קשר אל $groupName';
  }

  @override
  String get invited => 'הזמין';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username הזמין את $targetName';
  }

  @override
  String get invitedUsersOnly => 'משתמשים מוזמנים בלבד';

  @override
  String get inviteForMe => 'הזמנה בשבילי';

  @override
  String inviteText(Object username, Object link) {
    return '$username הזמין אותך ל-FluffyChat.\n1. התקן את FluffyChat: https://fluffychat.im\n2. הירשם או היכנס\n3. פתח את קישור ההזמנה: $link';
  }

  @override
  String get isTyping => 'מקליד/ה';

  @override
  String joinedTheChat(Object username) {
    return '$username הצטרף לצ\'אט';
  }

  @override
  String get joinRoom => 'הצטרף לחדר';

  @override
  String get keysCached => 'המפתחות נשמרים במטמון';

  @override
  String kicked(Object username, Object targetName) {
    return '$username בעט ב $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username בעט וחסם $targetName';
  }

  @override
  String get kickFromChat => 'בעיטה מהצ\'אט';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'פעילות אחרונה: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'נראה לפני זמן רב';

  @override
  String get leave => 'לעזוב';

  @override
  String get leftTheChat => 'עזב את הצ\'אט';

  @override
  String get license => 'רשיון';

  @override
  String get lightTheme => 'בהיר';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'טען $count משתתפים נוספים';
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
  String get loadingPleaseWait => 'טוען אנא המתן.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'טען עוד…';

  @override
  String get locationDisabledNotice =>
      'שירותי המיקום מושבתים. אנא הפעל אותם כדי לשתף את המיקום שלך.';

  @override
  String get locationPermissionDeniedNotice =>
      'הרשאת המיקום נדחתה. אנא אפשר את היכולת לשתף את מיקומך.';

  @override
  String get login => 'כניסה';

  @override
  String logInTo(Object homeserver) {
    return 'היכנס אל $homeserver';
  }

  @override
  String get loginWithOneClick => 'היכנס בלחיצה אחת';

  @override
  String get logout => 'יציאה';

  @override
  String get makeSureTheIdentifierIsValid => 'ודא שהמזהה חוקי';

  @override
  String get memberChanges => 'שינויים בחבר';

  @override
  String get mention => 'הזכיר';

  @override
  String get messages => 'הודעות';

  @override
  String get messageWillBeRemovedWarning => 'ההודעה תוסר עבור כל המשתתפים';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'מנחה';

  @override
  String get monday => 'יום שני';

  @override
  String get muteChat => 'השתקת הצ\'אט';

  @override
  String get needPantalaimonWarning =>
      'שים לב שאתה צריך Pantalaimon כדי להשתמש בהצפנה מקצה לקצה לעת עתה.';

  @override
  String get newChat => 'צ\'אט חדש';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'בקשת אימות חדשה!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'הבא';

  @override
  String get no => 'לא';

  @override
  String get noConnectionToTheServer => 'אין חיבור לשרת';

  @override
  String get noEmotesFound => 'No emotes found. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'אתה יכול להפעיל הצפנה רק כשהחדר כבר לא נגיש לציבור.';

  @override
  String get noGoogleServicesWarning =>
      'נראה שאין לך שירותי גוגל בטלפון שלך. זו החלטה טובה לפרטיות שלך! כדי לקבל התרעות ב- FluffyChat אנו ממליצים להשתמש https://microg.org/ או https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 אינו שרת מטריקס, השתמש ב-$server2 במקום זאת?';
  }

  @override
  String get shareYourInviteLink => 'שתף את קישור ההזמנה שלך';

  @override
  String get typeInInviteLinkManually => 'הקלד את קישור ההזמנה באופן ידני...';

  @override
  String get scanQrCode => 'סרוק קוד QR';

  @override
  String get none => 'ללא';

  @override
  String get noPasswordRecoveryDescription =>
      'עדיין לא הוספת דרך לשחזר את הסיסמה שלך.';

  @override
  String get noPermission => 'אין הרשאה';

  @override
  String get noRoomsFound => 'לא נמצאו חדרים…';

  @override
  String get notifications => 'התראות';

  @override
  String numUsersTyping(Object count) {
    return '$count משתמשים מקלידים';
  }

  @override
  String get obtainingLocation => 'משיג מיקום…';

  @override
  String get offensive => 'פוגעני';

  @override
  String get offline => 'לא מקוון';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'Ok';

  @override
  String get online => 'מחובר/ת';

  @override
  String get onlineKeyBackupEnabled => 'גיבוי מפתח מקוון מופעל';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError => 'אופס! למרבה הצער, אירעה שגיאה בעת הגדרת התראות.';

  @override
  String get oopsSomethingWentWrong => 'אופס, משהו השתבש…';

  @override
  String get openAppToReadMessages => 'פתח את האפליקציה לקריאת הודעות';

  @override
  String get openCamera => 'פתח מצלמה';

  @override
  String get openVideoCamera => 'פתח את המצלמה לסרטון';

  @override
  String get oneClientLoggedOut => 'אחד מהמכשירים שלך התנתק';

  @override
  String get addAccount => 'הוסף חשבון';

  @override
  String get editBundlesForAccount => 'ערוך חבילות עבור חשבון זה';

  @override
  String get addToBundle => 'הוסף לחבילה';

  @override
  String get removeFromBundle => 'הסר מחבילה זו';

  @override
  String get bundleName => 'שם החבילה';

  @override
  String get enableMultiAccounts => '(בטא) אפשר ריבוי חשבונות במכשיר זה';

  @override
  String get openInMaps => 'פתיחה במפות';

  @override
  String get link => 'קישור';

  @override
  String get serverRequiresEmail =>
      'שרת זה צריך לאמת את כתובת הדואר האלקטרוני שלך לרישום.';

  @override
  String get optionalGroupName => '(אופציונלי) שם קבוצה';

  @override
  String get or => 'או';

  @override
  String get participant => 'משתתף';

  @override
  String get passphraseOrKey => 'ביטוי סיסמה או מפתח שחזור';

  @override
  String get password => 'סיסמה';

  @override
  String get passwordForgotten => 'שכחתי סיסמה';

  @override
  String get passwordHasBeenChanged => 'הסיסמה שונתה';

  @override
  String get passwordRecovery => 'שחזור סיסמה';

  @override
  String get people => 'אנשים';

  @override
  String get pickImage => 'בחר תמונה';

  @override
  String get pin => 'קוד pin';

  @override
  String play(Object fileName) {
    return 'הפעל $fileName';
  }

  @override
  String get pleaseChoose => 'אנא בחר';

  @override
  String get pleaseChooseAPasscode => 'אנא בחר קוד גישה';

  @override
  String get pleaseChooseAUsername => 'אנא בחר שם משתמש';

  @override
  String get pleaseClickOnLink => 'אנא לחץ על הקישור במייל ולאחר מכן המשך.';

  @override
  String get pleaseEnter4Digits =>
      'אנא הזן 4 ספרות או השאר ריק כדי להשבית את נעילת האפליקציה.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'אנא הזן Matrix ID.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => 'נא הזן את הסיסמה שלך';

  @override
  String get pleaseEnterYourPin => 'אנא הזן את קוד הpin שלך';

  @override
  String get pleaseEnterYourUsername => 'אנא הזן שם משתמש';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Please follow the instructions on the website and tap on next.';

  @override
  String get privacy => 'Privacy';

  @override
  String get publicRooms => 'Public chats';

  @override
  String get pushRules => 'Push rules';

  @override
  String get reason => 'Reason';

  @override
  String get recording => 'Recording';

  @override
  String redactedAnEvent(Object username) {
    return '$username has deleted a message';
  }

  @override
  String get redactMessage => 'Redact message';

  @override
  String get register => 'Register';

  @override
  String get reject => 'Reject';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username rejected the invitation';
  }

  @override
  String get rejoin => 'Rejoin';

  @override
  String get remove => 'Remove';

  @override
  String get removeAllOtherDevices => 'Remove all other devices';

  @override
  String removedBy(Object username) {
    return 'Removed by $username';
  }

  @override
  String get removeDevice => 'Remove device';

  @override
  String get unbanFromChat => 'Unban from chat';

  @override
  String get removeYourAvatar => 'Remove your avatar';

  @override
  String get renderRichContent => 'Render rich message content';

  @override
  String get replaceRoomWithNewerVersion => 'Replace chat with newer version';

  @override
  String get reply => 'Reply';

  @override
  String get reportMessage => 'Report message';

  @override
  String get requestPermission => 'Request permission';

  @override
  String get roomHasBeenUpgraded => 'Group chat has been upgraded';

  @override
  String get roomVersion => 'Group chat version';

  @override
  String get saturday => 'Sat';

  @override
  String get saveFile => 'Save file';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Security';

  @override
  String get recoveryKey => 'Recovery key';

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
  String get send => 'Send';

  @override
  String get sendAMessage => 'Send a message';

  @override
  String get sendAsText => 'Send as text';

  @override
  String get sendAudio => 'Send audio';

  @override
  String get sendFile => 'Send file';

  @override
  String get sendImage => 'Send image';

  @override
  String get sendMessages => 'Send messages';

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
  String get setStatus => 'Set status';

  @override
  String get settings => 'Settings';

  @override
  String get share => 'Share';

  @override
  String sharedTheLocation(Object username) {
    return '$username shared their location';
  }

  @override
  String get shareLocation => 'Share location';

  @override
  String get showDirectChatsInSpaces => 'Show related Direct Chats in Spaces';

  @override
  String get showPassword => 'Show password';

  @override
  String get signUp => 'Sign up';

  @override
  String get singlesignon => 'Single Sign on';

  @override
  String get skip => 'Skip';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Source code';

  @override
  String get spaceIsPublic => 'Space is public';

  @override
  String get spaceName => 'Space name';

  @override
  String startedACall(Object senderName) {
    return '$senderName started a call';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Status';

  @override
  String get statusExampleMessage => 'How are you today?';

  @override
  String get submit => 'Submit';

  @override
  String get sunday => 'Sun';

  @override
  String get synchronizingPleaseWait => 'Synchronizing… Please wait.';

  @override
  String get systemTheme => 'System';

  @override
  String get theyDontMatch => 'They Don\'t Match';

  @override
  String get theyMatch => 'They Match';

  @override
  String get thisRoomHasBeenArchived => 'This chat has been archived.';

  @override
  String get thursday => 'Thu';

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
  String get tryToSendAgain => 'Try to send again';

  @override
  String get tuesday => 'Tue';

  @override
  String get unavailable => 'Unavailable';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username unbanned $targetName';
  }

  @override
  String get unblockDevice => 'Unblock Device';

  @override
  String get unknownDevice => 'Unknown device';

  @override
  String get unknownEncryptionAlgorithm => 'Unknown encryption algorithm';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Unknown event \'$type\'';
  }

  @override
  String get unmuteChat => 'Unmute chat';

  @override
  String get unpin => 'Unpin';

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
  String get username => 'Username';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username sent a $type event';
  }

  @override
  String get unverified => 'Unverified';

  @override
  String get verified => 'Verified';

  @override
  String get verify => 'Verify';

  @override
  String get verifyStart => 'Start Verification';

  @override
  String get verifySuccess => 'You successfully verified!';

  @override
  String get verifyTitle => 'Verifying other account';

  @override
  String get videoCall => 'Video call';

  @override
  String get visibilityOfTheChatHistory => 'Visibility of the chat history';

  @override
  String get visibleForAllParticipants => 'Visible for all participants';

  @override
  String get visibleForEveryone => 'Visible for everyone';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get waitingPartnerAcceptRequest =>
      'Waiting for partner to accept the request…';

  @override
  String get waitingPartnerEmoji => 'Waiting for partner to accept the emoji…';

  @override
  String get waitingPartnerNumbers =>
      'Waiting for partner to accept the numbers…';

  @override
  String get wallpaper => 'Wallpaper';

  @override
  String get warning => 'Warning!';

  @override
  String get wednesday => 'Wed';

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
  String get you => 'You';

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
  String get search => 'Search';

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
