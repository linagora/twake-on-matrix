// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class L10nRu extends L10n {
  L10nRu([String locale = 'ru']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают!';

  @override
  String get pleaseEnterValidEmail =>
      'Пожалуйста, введите действительный адрес электронной почты.';

  @override
  String get repeatPassword => 'Повторите пароль';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Пожалуйста, введите не менее $min символов.';
  }

  @override
  String get about => 'О проекте';

  @override
  String get updateAvailable => 'Доступно обновление для Twake Chat';

  @override
  String get updateNow => 'Обновить в фоновом режиме';

  @override
  String get accept => 'Принять';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username принял(а) приглашение';
  }

  @override
  String get account => 'Учётная запись';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username активировал(а) сквозное шифрование';
  }

  @override
  String get addEmail => 'Добавить электронную почту';

  @override
  String get confirmMatrixId =>
      'Пожалуйста, подтвердите Matrix ID, чтобы удалить свою учётную запись.';

  @override
  String supposedMxid(Object mxid) {
    return 'Это должно быть $mxid';
  }

  @override
  String get addGroupDescription => 'Добавить описание чата';

  @override
  String get addToSpace => 'Добавить в пространство';

  @override
  String get admin => 'Администратор';

  @override
  String get alias => 'псевдоним';

  @override
  String get all => 'Все';

  @override
  String get allChats => 'Все чаты';

  @override
  String get commandHint_googly => 'Оправить эмоджи глаз';

  @override
  String get commandHint_cuddle => 'Крепко обнять';

  @override
  String get commandHint_hug => 'Отправить обнимашки';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName строит вам глазки';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName крепко вас обнимает';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName отправил вам обнимашки';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName ответил(а) на звонок';
  }

  @override
  String get anyoneCanJoin => 'Каждый может присоединиться';

  @override
  String get appLock => 'Блокировка приложения';

  @override
  String get archive => 'Архив';

  @override
  String get archivedRoom => 'Архивированная комната';

  @override
  String get areGuestsAllowedToJoin => 'Разрешено ли гостям присоединяться';

  @override
  String get areYouSure => 'Вы уверены?';

  @override
  String get areYouSureYouWantToLogout => 'Вы действительно хотите выйти?';

  @override
  String get askSSSSSign =>
      'Для подписи ключа другого пользователя, пожалуйста, введите вашу парольную фразу или ключ восстановления.';

  @override
  String askVerificationRequest(Object username) {
    return 'Принять этот запрос подтверждения от $username?';
  }

  @override
  String get autoplayImages =>
      'Автоматически воспроизводить анимированные стикеры и эмодзи';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Домашний сервер поддерживает следующие типы входа в систему:\n$serverVersions\nНо это приложение поддерживает только:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Отправлять по Enter';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Домашний сервер поддерживает следующие версии спецификации:\n$serverVersions\nНо это приложение поддерживает только $supportedVersions';
  }

  @override
  String get banFromChat => 'Заблокировать в чате';

  @override
  String get banned => 'Заблокирован(а)';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username заблокировал(а) $targetName';
  }

  @override
  String get blockDevice => 'Заблокировать устройство';

  @override
  String get blocked => 'Заблокировано';

  @override
  String get botMessages => 'Сообщения ботов';

  @override
  String get bubbleSize => 'Размер пузыря';

  @override
  String get cancel => 'Отмена';

  @override
  String cantOpenUri(Object uri) {
    return 'Не удается открыть URI $uri';
  }

  @override
  String get changeDeviceName => 'Изменить имя устройства';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username изменил(а) аватар чата';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username изменил(а) описание чата на: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username изменил(а) имя чата на: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username изменил(а) права доступа к чату';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username изменил(а) отображаемое имя на: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username изменил(а) правила гостевого доступа';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username изменил(а) правила гостевого доступа на: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username изменил(а) видимость истории';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username изменил(а) видимость истории на: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username изменил(а) правила присоединения';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username изменил(а) правила присоединения на: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username изменил(а) аватар';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username изменил(а) псевдонимы комнаты';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username изменил(а) ссылку для приглашения';
  }

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String get changeTheHomeserver => 'Изменить сервер Matrix';

  @override
  String get changeTheme => 'Тема';

  @override
  String get changeTheNameOfTheGroup => 'Изменить название чата';

  @override
  String get changeWallpaper => 'Изменить фон чатов';

  @override
  String get changeYourAvatar => 'Изменить свой аватар';

  @override
  String get channelCorruptedDecryptError => 'Шифрование было повреждено';

  @override
  String get chat => 'Чат';

  @override
  String get yourUserId => 'Ваш ID пользователя:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'Резервное копирование чата настроено.';

  @override
  String get chatBackup => 'Резервное копирование чата';

  @override
  String get chatBackupDescription =>
      'Старые сообщения защищены ключом восстановления. Пожалуйста, не потеряйте его.';

  @override
  String get chatDetails => 'Детали чата';

  @override
  String get chatHasBeenAddedToThisSpace =>
      'Чат был добавлен в это пространство';

  @override
  String get chats => 'Чаты';

  @override
  String get chooseAStrongPassword => 'Выберите надёжный пароль';

  @override
  String get chooseAUsername => 'Выберите имя пользователя';

  @override
  String get clearArchive => 'Очистить архив';

  @override
  String get close => 'Закрыть';

  @override
  String get commandHint_markasdm => 'Пометить как комнату личных сообщений';

  @override
  String get commandHint_markasgroup => 'Пометить как групповой чат';

  @override
  String get commandHint_ban =>
      'Заблокировать данного пользователя в этой комнате';

  @override
  String get commandHint_clearcache => 'Очистить кэш';

  @override
  String get commandHint_create =>
      'Создайте пустой групповой чат\nИспользуйте --no-encryption, чтобы отключить шифрование';

  @override
  String get commandHint_discardsession => 'Удалить сеанс';

  @override
  String get commandHint_dm =>
      'Начните личный чат\nИспользуйте --no-encryption, чтобы отключить шифрование';

  @override
  String get commandHint_html => 'Отправить текст формата HTML';

  @override
  String get commandHint_invite =>
      'Пригласить данного пользователя в эту комнату';

  @override
  String get commandHint_join => 'Присоединиться к данной комнате';

  @override
  String get commandHint_kick => 'Удалить данного пользователя из этой комнаты';

  @override
  String get commandHint_leave => 'Покинуть эту комнату';

  @override
  String get commandHint_me => 'Опишите себя';

  @override
  String get commandHint_myroomavatar =>
      'Установите свою фотографию для этой комнаты (автор: mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Задайте отображаемое имя для этой комнаты';

  @override
  String get commandHint_op =>
      'Установить уровень прав данного пользователя (по умолчанию: 50)';

  @override
  String get commandHint_plain => 'Отправить неотформатированный текст';

  @override
  String get commandHint_react => 'Отправить ответ как реакцию';

  @override
  String get commandHint_send => 'Отправить текст';

  @override
  String get commandHint_unban =>
      'Разблокировать данного пользователя в этой комнате';

  @override
  String get commandInvalid => 'Недопустимая команда';

  @override
  String commandMissing(Object command) {
    return '$command не является командой.';
  }

  @override
  String get compareEmojiMatch => 'Пожалуйста, сравните эмодзи';

  @override
  String get compareNumbersMatch => 'Пожалуйста, сравните числа';

  @override
  String get configureChat => 'Настроить чат';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get connect => 'Присоединиться';

  @override
  String get contactHasBeenInvitedToTheGroup => 'Контакт был приглашен в чат';

  @override
  String get containsDisplayName => 'Содержит отображаемое имя';

  @override
  String get containsUserName => 'Содержит имя пользователя';

  @override
  String get contentHasBeenReported =>
      'Жалоба отправлена администраторам сервера';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get copy => 'Копировать';

  @override
  String get copyToClipboard => 'Скопировать в буфер обмена';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Не удалось расшифровать сообщение: $error';
  }

  @override
  String countMembers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участников',
      one: '1 участник',
      zero: 'нет участников',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Создать';

  @override
  String createdTheChat(Object username) {
    return '$username создал(а) чат';
  }

  @override
  String get createNewGroup => 'Создать новый чат';

  @override
  String get createNewSpace => 'Новое пространство';

  @override
  String get crossSigningEnabled => 'Кросс-подпись включена';

  @override
  String get currentlyActive => 'В настоящее время активен(а)';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$timeOfDay, $date';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$day-$month';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$day-$month-$year';
  }

  @override
  String get deactivateAccountWarning =>
      'Это действие деактивирует вашу учётную запись. Оно не может быть отменено! Вы уверены?';

  @override
  String get defaultPermissionLevel => 'Уровень разрешений по умолчанию';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteMessage => 'Удалить сообщение';

  @override
  String get deny => 'Отклонить';

  @override
  String get device => 'Устройство';

  @override
  String get deviceId => 'Идентификатор устройства';

  @override
  String get devices => 'Устройства';

  @override
  String get directChats => 'Личные чаты';

  @override
  String get discover => 'Обзор';

  @override
  String get displaynameHasBeenChanged => 'Отображаемое имя было изменено';

  @override
  String get download => 'Скачать';

  @override
  String get edit => 'Править';

  @override
  String get editBlockedServers => 'Редактировать заблокированные серверы';

  @override
  String get editChatPermissions => 'Изменить разрешения чата';

  @override
  String get editDisplayname => 'Отображаемое имя';

  @override
  String get editRoomAliases => 'Редактировать псевдонимы комнаты';

  @override
  String get editRoomAvatar => 'Изменить аватар чата';

  @override
  String get emoteExists => 'Эмодзи уже существует!';

  @override
  String get emoteInvalid => 'Недопустимый краткий код эмодзи!';

  @override
  String get emotePacks => 'Наборы эмодзи для комнаты';

  @override
  String get emoteSettings => 'Настройки эмодзи';

  @override
  String get emoteShortcode => 'Краткий код для эмодзи';

  @override
  String get emoteWarnNeedToPick =>
      'Вам нужно задать код эмодзи и изображение!';

  @override
  String get emptyChat => 'Пустой чат';

  @override
  String get enableEmotesGlobally => 'Включить набор эмодзи глобально';

  @override
  String get enableEncryption => 'Включить сквозное шифрование';

  @override
  String get enableEncryptionWarning =>
      'Вы больше не сможете отключить шифрование. Вы уверены?';

  @override
  String get encrypted => 'Зашифровано';

  @override
  String get encryption => 'Шифрование';

  @override
  String get encryptionNotEnabled => 'Шифрование не включено';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName завершил(а) звонок';
  }

  @override
  String get enterGroupName => 'Введите название чата';

  @override
  String get enterAnEmailAddress => 'Введите адрес электронной почты';

  @override
  String get enterASpacepName => 'Введите название пространства';

  @override
  String get homeserver => 'Сервер Matrix';

  @override
  String get enterYourHomeserver => 'Введите адрес вашего сервера Matrix';

  @override
  String errorObtainingLocation(Object error) {
    return 'Ошибка получения местоположения: $error';
  }

  @override
  String get everythingReady => 'Всё готово!';

  @override
  String get extremeOffensive => 'Крайне оскорбительный';

  @override
  String get fileName => 'Имя файла';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Размер шрифта';

  @override
  String get forward => 'Переслать';

  @override
  String get friday => 'Пт';

  @override
  String get fromJoining => 'С момента присоединения';

  @override
  String get fromTheInvitation => 'С момента приглашения';

  @override
  String get goToTheNewRoom => 'В новую комнату';

  @override
  String get group => 'Чат';

  @override
  String get groupDescription => 'Описание группового чата';

  @override
  String get groupDescriptionHasBeenChanged =>
      'Описание группового чата изменено';

  @override
  String get groupIsPublic => 'Публичный групповой чат';

  @override
  String get groups => 'Групповые чаты';

  @override
  String groupWith(Object displayname) {
    return 'Групповой чат с $displayname';
  }

  @override
  String get guestsAreForbidden => 'Гости не могут присоединиться';

  @override
  String get guestsCanJoin => 'Гости могут присоединиться';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username отозвал(а) приглашение для $targetName';
  }

  @override
  String get help => 'Помощь';

  @override
  String get hideRedactedEvents => 'Скрыть удаленные сообщения';

  @override
  String get hideUnknownEvents => 'Скрыть неизвестные события';

  @override
  String get howOffensiveIsThisContent =>
      'Насколько оскорбительным является это сообщение?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Идентификация';

  @override
  String get ignore => 'Заблокировать';

  @override
  String get ignoredUsers => 'Черный список';

  @override
  String get ignoreListDescription =>
      'Вы можете заблокировать пользователей, которые вам мешают. Вы не сможете получать сообщения или приглашения в чаты от пользователей из вашего черного списка.';

  @override
  String get ignoreUsername => 'Заблокировать пользователя';

  @override
  String get iHaveClickedOnLink => 'Я перешёл по ссылке';

  @override
  String get incorrectPassphraseOrKey =>
      'Неверный пароль или ключ восстановления';

  @override
  String get inoffensive => 'Безобидный';

  @override
  String get inviteContact => 'Пригласить контакт';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Пригласить контакт в $groupName';
  }

  @override
  String get invited => 'Приглашён';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username пригласил(а) $targetName';
  }

  @override
  String get invitedUsersOnly => 'Только приглашённым пользователям';

  @override
  String get inviteForMe => 'Приглашение для меня';

  @override
  String inviteText(Object username, Object link) {
    return '$username пригласил(а) вас в FluffyChat. \n1. Установите FluffyChat: https://fluffychat.im \n2. Зарегистрируйтесь или войдите \n3. Откройте ссылку приглашения: $link';
  }

  @override
  String get isTyping => 'печатает…';

  @override
  String joinedTheChat(Object username) {
    return '$username присоединился(ась) к чату';
  }

  @override
  String get joinRoom => 'Присоединиться к комнате';

  @override
  String get keysCached => 'Ключи сохранены в кэше';

  @override
  String kicked(Object username, Object targetName) {
    return '$username исключил(а) $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username исключил(а) и заблокировал(а) $targetName';
  }

  @override
  String get kickFromChat => 'Исключить из чата';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Последнее посещение: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'был(а) в сети давно';

  @override
  String get leave => 'Покинуть';

  @override
  String get leftTheChat => 'Покинуть чат';

  @override
  String get license => 'Лицензия';

  @override
  String get lightTheme => 'Светлая';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Загрузить еще $count участника(ов)';
  }

  @override
  String get dehydrate => 'Экспорт сеанса и очистка устройства';

  @override
  String get dehydrateWarning =>
      'Это действие не может быть отменено. Убедитесь, что вы сохранили файл резервной копии.';

  @override
  String get dehydrateShare =>
      'Это ваш личный экспорт FluffyChat. Убедитесь, что вы не потеряете его и держите его в тайне.';

  @override
  String get dehydrateTor => 'Пользователи TOR: Экспорт сеанса';

  @override
  String get dehydrateTorLong =>
      'Для пользователей TOR рекомендуется экспортировать сессию перед закрытием окна.';

  @override
  String get hydrateTor => 'Пользователи TOR: Импорт экспорта сессии';

  @override
  String get hydrateTorLong =>
      'В прошлый раз вы экспортировали сессию в TOR? Импортируйте ее и продолжайте общение.';

  @override
  String get hydrate => 'Восстановить из файла резервной копии';

  @override
  String get loadingPleaseWait => 'Загрузка... Пожалуйста, подождите.';

  @override
  String get loadingStatus => 'Загрузка статуса...';

  @override
  String get loadMore => 'Загрузить больше…';

  @override
  String get locationDisabledNotice =>
      'Службы определения местоположения отключены. Включите их, чтобы иметь возможность обмениваться информацией о своем местоположении.';

  @override
  String get locationPermissionDeniedNotice =>
      'Разрешение на определение местоположения отклонено. Пожалуйста, предоставьте это разрешение, чтобы иметь возможность делиться своим местоположением.';

  @override
  String get login => 'Войти';

  @override
  String logInTo(Object homeserver) {
    return 'Войти в $homeserver';
  }

  @override
  String get loginWithOneClick => 'Вход одним нажатием';

  @override
  String get logout => 'Выйти';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Убедитесь, что идентификатор действителен';

  @override
  String get memberChanges => 'Изменения участников';

  @override
  String get mention => 'Упомянуть';

  @override
  String get messages => 'Сообщения';

  @override
  String get messageWillBeRemovedWarning =>
      'Сообщение будет удалено для всех участников';

  @override
  String get noSearchResult => 'Нет подходящих результатов поиска.';

  @override
  String get moderator => 'Модератор';

  @override
  String get monday => 'Пн';

  @override
  String get muteChat => 'Отключить уведомления';

  @override
  String get needPantalaimonWarning =>
      'Помните, что вам нужен Pantalaimon для использования сквозного шифрования.';

  @override
  String get newChat => 'Новый чат';

  @override
  String get newMessageInTwake => 'У вас одно зашифрованное сообщение';

  @override
  String get newVerificationRequest => 'Новый запрос на подтверждение!';

  @override
  String get noMoreResult => 'Больше нет результатов';

  @override
  String get previous => 'Назад';

  @override
  String get next => 'Далее';

  @override
  String get no => 'Нет';

  @override
  String get noConnectionToTheServer => 'Нет соединения с сервером';

  @override
  String get noEmotesFound => 'Эмодзи не найдены 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Вы можете активировать шифрование только тогда, когда комната перестает быть общедоступной.';

  @override
  String get noGoogleServicesWarning =>
      'Похоже, у вас нет служб Google на вашем телефоне. Это хорошее решение для вашей конфиденциальности! Для получения push-уведомлений во FluffyChat мы рекомендуем использовать https://microg.org/ или https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 не является matrix-сервером, использовать $server2 вместо него?';
  }

  @override
  String get shareYourInviteLink => 'Поделиться ссылкой приглашения';

  @override
  String get typeInInviteLinkManually => 'Введите ссылку приглашения...';

  @override
  String get scanQrCode => 'Сканировать QR-код';

  @override
  String get none => 'Нет';

  @override
  String get noPasswordRecoveryDescription =>
      'Вы ещё не добавили способ восстановления пароля.';

  @override
  String get noPermission => 'Нет прав доступа';

  @override
  String get noRoomsFound => 'Комнаты не найдены…';

  @override
  String get notifications => 'Уведомления';

  @override
  String numUsersTyping(Object count) {
    return '$count пользователей печатают';
  }

  @override
  String get obtainingLocation => 'Получение местоположения…';

  @override
  String get offensive => 'Оскорбительный';

  @override
  String get offline => 'Не в сети';

  @override
  String get aWhileAgo => 'некоторое время назад';

  @override
  String get ok => 'Ок';

  @override
  String get online => 'В сети';

  @override
  String get onlineKeyBackupEnabled =>
      'Резервное копирование ключей на сервере включено';

  @override
  String get cannotEnableKeyBackup =>
      'Невозможно включить резервное копирование. Попробуйте еще раз в настройках.';

  @override
  String get cannotUploadKey => 'Невозможно сохранить резервную копию ключа.';

  @override
  String get oopsPushError =>
      'Ой! К сожалению, при настройке push-уведомлений произошла ошибка.';

  @override
  String get oopsSomethingWentWrong => 'Ой! Что-то пошло не так…';

  @override
  String get openAppToReadMessages => 'Открыть приложение для чтения сообщений';

  @override
  String get openCamera => 'Открыть камеру';

  @override
  String get openVideoCamera => 'Открыть камеру для видео';

  @override
  String get oneClientLoggedOut => 'Один из ваших клиентов вышел';

  @override
  String get addAccount => 'Добавить учетную запись';

  @override
  String get editBundlesForAccount => 'Изменить пакеты для этой учетной записи';

  @override
  String get addToBundle => 'Добавить в пакет';

  @override
  String get removeFromBundle => 'Удалить из этого пакета';

  @override
  String get bundleName => 'Название пакета';

  @override
  String get enableMultiAccounts =>
      '(БЕТА) Включить несколько учетных записей на этом устройстве';

  @override
  String get openInMaps => 'Открыть на картах';

  @override
  String get link => 'Ссылка';

  @override
  String get serverRequiresEmail =>
      'Для регистрации этот сервер должен подтвердить ваш адрес электронной почты.';

  @override
  String get optionalGroupName => '(Необязательно) Название чата';

  @override
  String get or => 'Или';

  @override
  String get participant => 'Участник';

  @override
  String get passphraseOrKey => 'пароль или ключ восстановления';

  @override
  String get password => 'Пароль';

  @override
  String get passwordForgotten => 'Забыли пароль';

  @override
  String get passwordHasBeenChanged => 'Пароль был изменён';

  @override
  String get passwordRecovery => 'Восстановление пароля';

  @override
  String get people => 'Люди';

  @override
  String get pickImage => 'Выбрать изображение';

  @override
  String get pin => 'Закрепить';

  @override
  String play(Object fileName) {
    return 'Проиграть $fileName';
  }

  @override
  String get pleaseChoose => 'Пожалуйста, выберите';

  @override
  String get pleaseChooseAPasscode => 'Пожалуйста, выберите код доступа';

  @override
  String get pleaseChooseAUsername => 'Пожалуйста, выберите имя пользователя';

  @override
  String get pleaseClickOnLink =>
      'Пожалуйста, нажмите на ссылку в письме, чтобы продолжить.';

  @override
  String get pleaseEnter4Digits =>
      'Введите 4 цифры или оставьте поле пустым, чтобы отключить блокировку приложения.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Пожалуйста, введите Matrix ID.';

  @override
  String get pleaseEnterRecoveryKey => 'Введите ключ восстановления:';

  @override
  String get pleaseEnterYourPassword => 'Пожалуйста, введите ваш пароль';

  @override
  String get pleaseEnterYourPin => 'Пожалуйста, введите свой пин-код';

  @override
  String get pleaseEnterYourUsername => 'Пожалуйста, введите имя пользователя';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Следуйте инструкциям на сайте и нажмите «Далее».';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get publicRooms => 'Публичные комнаты';

  @override
  String get pushRules => 'Правила push';

  @override
  String get reason => 'Причина';

  @override
  String get recording => 'Запись';

  @override
  String redactedAnEvent(Object username) {
    return '$username удалил сообщение';
  }

  @override
  String get redactMessage => 'Отредактировать сообщение';

  @override
  String get register => 'Зарегистрироваться';

  @override
  String get reject => 'Отклонить';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username отклонил(а) приглашение';
  }

  @override
  String get rejoin => 'Зайти повторно';

  @override
  String get remove => 'Удалить';

  @override
  String get removeAllOtherDevices => 'Удалить остальные устройства';

  @override
  String removedBy(Object username) {
    return 'Удалено пользователем $username';
  }

  @override
  String get removeDevice => 'Удалить устройство';

  @override
  String get unbanFromChat => 'Разблокировать в чате';

  @override
  String get removeYourAvatar => 'Удалить аватар';

  @override
  String get renderRichContent => 'Показывать текст с форматированием';

  @override
  String get replaceRoomWithNewerVersion =>
      'Заменить комнату более новой версией';

  @override
  String get reply => 'Ответить';

  @override
  String get reportMessage => 'Пожаловаться на сообщение';

  @override
  String get requestPermission => 'Запросить разрешение';

  @override
  String get roomHasBeenUpgraded => 'Комната обновлена';

  @override
  String get roomVersion => 'Версия комнаты';

  @override
  String get saturday => 'Сб';

  @override
  String get saveFile => 'Сохранить файл';

  @override
  String get searchForPeopleAndChannels => 'Искать людей и каналы';

  @override
  String get security => 'Безопасность';

  @override
  String get recoveryKey => 'Ключ восстановления';

  @override
  String get recoveryKeyLost => 'Ключ восстановления утерян?';

  @override
  String seenByUser(Object username) {
    return 'Просмотрено пользователем $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Просмотрено пользователями $username и $count другими',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Просмотрено пользователями $username и $username2';
  }

  @override
  String get send => 'Отправить';

  @override
  String get sendAMessage => 'Отправить сообщение';

  @override
  String get sendAsText => 'Отправить как текст';

  @override
  String get sendAudio => 'Отправить аудио';

  @override
  String get sendFile => 'Отправить файл';

  @override
  String get sendImage => 'Отправить изображение';

  @override
  String get sendMessages => 'Отправить сообщения';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String get sendOriginal => 'Отправить оригинал';

  @override
  String get sendSticker => 'Отправить стикер';

  @override
  String get sendVideo => 'Отправить видео';

  @override
  String sentAFile(Object username) {
    return '📁 $username отправил(а) файл';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username отправил(а) аудио';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username отправил(а) изображение';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username отправил(а) стикер';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username отправил(а) видео';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName отправил(а) информацию о звонке';
  }

  @override
  String get separateChatTypes => 'Разделять личные и групповые чаты';

  @override
  String get setAsCanonicalAlias => 'Установить как основной псевдоним';

  @override
  String get setCustomEmotes => 'Установить пользовательские эмодзи';

  @override
  String get setGroupDescription => 'Задать описание чата';

  @override
  String get setInvitationLink => 'Установить ссылку для приглашения';

  @override
  String get setPermissionsLevel => 'Установить уровень разрешений';

  @override
  String get setStatus => 'Задать статус';

  @override
  String get settings => 'Настройки';

  @override
  String get share => 'Поделиться';

  @override
  String sharedTheLocation(Object username) {
    return '$username поделился(ась) местоположением';
  }

  @override
  String get shareLocation => 'Поделиться местоположением';

  @override
  String get showDirectChatsInSpaces =>
      'Показывать связанные Личные чаты в Пространствах';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get signUp => 'Зарегистрироваться';

  @override
  String get singlesignon => 'Единая точка входа';

  @override
  String get skip => 'Пропустить';

  @override
  String get invite => 'Пригласить';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get spaceIsPublic => 'Публичное пространство';

  @override
  String get spaceName => 'Название пространства';

  @override
  String startedACall(Object senderName) {
    return '$senderName начал(а) звонок';
  }

  @override
  String get startFirstChat => 'Создайте свой первый чат';

  @override
  String get status => 'Статус';

  @override
  String get statusExampleMessage => 'Как у вас сегодня дела?';

  @override
  String get submit => 'Отправить';

  @override
  String get sunday => 'Вс';

  @override
  String get synchronizingPleaseWait => 'Синхронизация… Пожалуйста, подождите.';

  @override
  String get systemTheme => 'Системная';

  @override
  String get theyDontMatch => 'Они не совпадают';

  @override
  String get theyMatch => 'Они совпадают';

  @override
  String get thisRoomHasBeenArchived => 'Эта комната была заархивирована.';

  @override
  String get thursday => 'Чт';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Переключить избранное';

  @override
  String get toggleMuted => 'Переключить без звука';

  @override
  String get toggleUnread => 'Отметить как прочитанное/непрочитанное';

  @override
  String get tooManyRequestsWarning =>
      'Слишком много запросов. Пожалуйста, повторите попытку позже!';

  @override
  String get transferFromAnotherDevice => 'Перенос с другого устройства';

  @override
  String get tryToSendAgain => 'Попробуйте отправить ещё раз';

  @override
  String get tuesday => 'Вт';

  @override
  String get unavailable => 'Недоступен';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username разблокировал(а) $targetName';
  }

  @override
  String get unblockDevice => 'Разблокировать устройство';

  @override
  String get unknownDevice => 'Неизвестное устройство';

  @override
  String get unknownEncryptionAlgorithm => 'Неизвестный алгоритм шифрования';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Неизвестное событие \'$type\'';
  }

  @override
  String get unmuteChat => 'Включить уведомления';

  @override
  String get unpin => 'Открепить';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount непрочитанных чата(ов)',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username и $count других участников печатают';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username и $username2 печатают';
  }

  @override
  String userIsTyping(Object username) {
    return '$username печатает';
  }

  @override
  String userLeftTheChat(Object username) {
    return '$username покинул(а) чат';
  }

  @override
  String get username => 'Имя пользователя';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username отправил(а) событие типа \"$type\"';
  }

  @override
  String get unverified => 'Не проверено';

  @override
  String get verified => 'Проверено';

  @override
  String get verify => 'Проверить';

  @override
  String get verifyStart => 'Начать проверку';

  @override
  String get verifySuccess => 'Вы успешно проверены!';

  @override
  String get verifyTitle => 'Проверка другой учётной записи';

  @override
  String get videoCall => 'Видеозвонок';

  @override
  String get visibilityOfTheChatHistory => 'Видимость истории чата';

  @override
  String get visibleForAllParticipants => 'Видима для всех участников';

  @override
  String get visibleForEveryone => 'Видима для всех';

  @override
  String get voiceMessage => 'Отправить голосовое сообщение';

  @override
  String get waitingPartnerAcceptRequest =>
      'Ждем, когда партнер примет запроc…';

  @override
  String get waitingPartnerEmoji => 'Ждем, когда партнер примет эмодзи…';

  @override
  String get waitingPartnerNumbers => 'Ждем, когда партнер примет числа…';

  @override
  String get wallpaper => 'Обои';

  @override
  String get warning => 'Предупреждение!';

  @override
  String get wednesday => 'Ср';

  @override
  String get weSentYouAnEmail => 'Мы отправили вам электронное письмо';

  @override
  String get whoCanPerformWhichAction => 'Кто и какое действие может выполнять';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Кому разрешено вступать в этот чат';

  @override
  String get whyDoYouWantToReportThis => 'Почему вы хотите сообщить об этом?';

  @override
  String get wipeChatBackup =>
      'Удалить резервную копию чата, чтобы создать новый ключ восстановления?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'По этим адресам вы можете восстановить свой пароль.';

  @override
  String get writeAMessage => 'Напишите сообщение…';

  @override
  String get yes => 'Да';

  @override
  String get you => 'Вы';

  @override
  String get youAreInvitedToThisChat => 'Вы приглашены в этот чат';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Вы больше не состоите в этом чате';

  @override
  String get youCannotInviteYourself => 'Вы не можете пригласить себя';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Вы были заблокированы в этом чате';

  @override
  String get yourPublicKey => 'Ваш открытый ключ';

  @override
  String get messageInfo => 'Информация о сообщении';

  @override
  String get time => 'Время';

  @override
  String get messageType => 'Тип сообщения';

  @override
  String get sender => 'Отправитель';

  @override
  String get openGallery => 'Открыть галерею';

  @override
  String get removeFromSpace => 'Удалить из пространства';

  @override
  String get addToSpaceDescription =>
      'Выберите пространство, чтобы добавить к нему этот чат.';

  @override
  String get start => 'Начать';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Чтобы разблокировать старые сообщения, введите ключ восстановления, сгенерированный в предыдущем сеансе. Ваш ключ восстановления НЕ является вашим паролем.';

  @override
  String get addToStory => 'Добавить в историю';

  @override
  String get publish => 'Опубликовать';

  @override
  String get whoCanSeeMyStories => 'Кто может видеть мои истории?';

  @override
  String get unsubscribeStories => 'Отписаться от историй';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Этот пользователь еще ничего не опубликовал в своей истории';

  @override
  String get yourStory => 'Ваша история';

  @override
  String get replyHasBeenSent => 'Ответ отправлен';

  @override
  String videoWithSize(Object size) {
    return 'Видео ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'История за $date:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Обратите внимание, что люди могут видеть и связываться друг с другом в вашей истории.';

  @override
  String get whatIsGoingOn => 'Что происходит?';

  @override
  String get addDescription => 'Добавить описание';

  @override
  String get storyPrivacyWarning =>
      'Обратите внимание, что люди могут видеть и связываться друг с другом в вашей истории. Ваши истории будут видны в течение 24 часов, но нет гарантии, что они будут удалены со всех устройств и серверов.';

  @override
  String get iUnderstand => 'Я понимаю';

  @override
  String get openChat => 'Открыть чат';

  @override
  String get markAsRead => 'Отметить как прочитанное';

  @override
  String get reportUser => 'Сообщить о пользователе';

  @override
  String get dismiss => 'Отклонить';

  @override
  String get matrixWidgets => 'Виджеты Matrix';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender оставил(а) реакцию $reaction';
  }

  @override
  String get pinChat => 'Закрепить';

  @override
  String get confirmEventUnpin =>
      'Вы уверены, что хотите навсегда открепить сообщение?';

  @override
  String get emojis => 'Эмодзи';

  @override
  String get placeCall => 'Совершить звонок';

  @override
  String get voiceCall => 'Голосовой звонок';

  @override
  String get unsupportedAndroidVersion => 'Неподдерживаемая версия Android';

  @override
  String get unsupportedAndroidVersionLong =>
      'Для этой функции требуется более новая версия Android. Проверьте наличие обновлений или обратитесь в поддержку Lineage OS.';

  @override
  String get videoCallsBetaWarning =>
      'Обратите внимание, что видеозвонки в настоящее время находятся в бета-версии. На всех платформах они могут работать не так, как ожидалось, или вообще не работать.';

  @override
  String get experimentalVideoCalls => 'Экспериментальные видеозвонки';

  @override
  String get emailOrUsername => 'Адрес электронной почты или имя пользователя';

  @override
  String get indexedDbErrorTitle => 'Проблемы с приватным режимом';

  @override
  String get indexedDbErrorLong =>
      'К сожалению, по умолчанию хранилище сообщений не включено в приватном режиме.\nПожалуйста, посетите\n  - about:config\n  - установите для dom.indexedDB.privateBrowsing.enabled значение true\nВ противном случае запуск FluffyChat будет невозможен.';

  @override
  String switchToAccount(Object number) {
    return 'Переключиться на учётную запись $number';
  }

  @override
  String get nextAccount => 'Следующая учётная запись';

  @override
  String get previousAccount => 'Предыдущая учётная запись';

  @override
  String get editWidgets => 'Редактировать виджеты';

  @override
  String get addWidget => 'Добавить виджет';

  @override
  String get widgetVideo => 'Видео';

  @override
  String get widgetEtherpad => 'Текстовая записка';

  @override
  String get widgetJitsi => 'Конференция Jitsi';

  @override
  String get widgetCustom => 'Пользовательский';

  @override
  String get widgetName => 'Имя';

  @override
  String get widgetUrlError => 'Этот URL не действителен.';

  @override
  String get widgetNameError => 'Пожалуйста, укажите отображаемое имя.';

  @override
  String get errorAddingWidget => 'Ошибка при добавлении виджета.';

  @override
  String get youRejectedTheInvitation => 'Вы отклонили приглашение';

  @override
  String get youJoinedTheChat => 'Вы присоединились к чату';

  @override
  String get youAcceptedTheInvitation => 'Вы приняли приглашение';

  @override
  String youBannedUser(Object user) {
    return 'Вы заблокировали $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Вы отозвали приглашение для $user';
  }

  @override
  String youInvitedBy(Object user) {
    return 'Вы были приглашены $user';
  }

  @override
  String youInvitedUser(Object user) {
    return 'Вы пригласили $user';
  }

  @override
  String youKicked(Object user) {
    return 'Вы исключили $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return 'Вы исключили и заблокировали $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Вы разблокировали $user';
  }

  @override
  String get noEmailWarning =>
      'Пожалуйста, введите действительный адрес электронной почты. В противном случае вы не сможете сбросить пароль. Если вы не хотите этого делать, нажмите еще раз на кнопку, чтобы продолжить.';

  @override
  String get stories => 'Истории';

  @override
  String get users => 'Пользователи';

  @override
  String get enableAutoBackups =>
      'Включить автоматическое резервное копирование';

  @override
  String get unlockOldMessages => 'Разблокировать старые сообщения';

  @override
  String get cannotUnlockBackupKey =>
      'Невозможно разблокировать резервную копию ключа.';

  @override
  String get storeInSecureStorageDescription =>
      'Сохраните ключ восстановления в безопасном хранилище этого устройства.';

  @override
  String get saveKeyManuallyDescription =>
      'Сохраните этот ключ вручную, вызвав диалог общего доступа системы или буфера обмена.';

  @override
  String get storeInAndroidKeystore => 'Сохранить в Android KeyStore';

  @override
  String get storeInAppleKeyChain => 'Сохранить в Apple KeyChain';

  @override
  String get storeSecurlyOnThisDevice => 'Сохранить на этом устройстве';

  @override
  String countFiles(Object count) {
    return '$count файлов';
  }

  @override
  String get user => 'Пользователь';

  @override
  String get custom => 'Пользовательское';

  @override
  String get foregroundServiceRunning =>
      'Это уведомление появляется, когда запущена основная служба.';

  @override
  String get screenSharingTitle => 'общий доступ к экрану';

  @override
  String get screenSharingDetail => 'Вы делитесь своим экраном в FuffyChat';

  @override
  String get callingPermissions => 'Разрешения на звонки';

  @override
  String get callingAccount => 'Аккаунт для звонков';

  @override
  String get callingAccountDetails =>
      'Позволяет FluffyChat использовать родное android приложение для звонков.';

  @override
  String get appearOnTop => 'Появляться сверху';

  @override
  String get appearOnTopDetails =>
      'Позволяет приложению отображаться сверху (не требуется, если у вас уже настроен Fluffychat как аккаунт для звонков)';

  @override
  String get otherCallingPermissions =>
      'Микрофон, камера и другие разрешения FluffyChat';

  @override
  String get whyIsThisMessageEncrypted =>
      'Почему это сообщение нельзя прочитать?';

  @override
  String get noKeyForThisMessage =>
      'Это может произойти, если сообщение было отправлено до того, как вы вошли в свою учетную запись на данном устройстве.\n\nТакже возможно, что отправитель заблокировал ваше устройство или что-то пошло не так с интернет-соединением.\n\nВы можете прочитать сообщение на другом устройстве? Тогда вы можете перенести сообщение с него! Перейдите в Настройки > Устройства и убедитесь, что ваши устройства проверили друг друга. Когда вы откроете комнату в следующий раз и обе сессии будут открыты, ключи будут переданы автоматически.\n\nВы не хотите потерять ключи при выходе из системы или переключении устройств? Убедитесь, что вы включили резервное копирование чата в настройках.';

  @override
  String get newGroup => 'Новый чат';

  @override
  String get newSpace => 'Новое пространство';

  @override
  String get enterSpace => 'Войти в пространство';

  @override
  String get enterRoom => 'Войти в комнату';

  @override
  String get allSpaces => 'Все пространства';

  @override
  String numChats(Object number) {
    return '$number чатов';
  }

  @override
  String get hideUnimportantStateEvents => 'Скрыть неважные события';

  @override
  String get doNotShowAgain => 'Больше не показывать';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return 'Пустой чат (раньше – $oldDisplayName)';
  }

  @override
  String get newSpaceDescription =>
      'Пространства позволяют объединять ваши чаты и создавать частные или публичные сообщества.';

  @override
  String get encryptThisChat => 'Зашифровать этот чат';

  @override
  String get endToEndEncryption => 'Сквозное шифрование';

  @override
  String get disableEncryptionWarning =>
      'В целях безопасности вы не можете отключить шифрование в чате, где оно было включено ранее.';

  @override
  String get sorryThatsNotPossible => 'Нам жаль... Это невозможно';

  @override
  String get deviceKeys => 'Ключи устройства:';

  @override
  String get letsStart => 'Начнем';

  @override
  String get enterInviteLinkOrMatrixId =>
      'Введите пригласительную ссылку или Matrix ID...';

  @override
  String get reopenChat => 'Открыть чат еще раз';

  @override
  String get noBackupWarning =>
      'Будьте внимательны! Без резервного копирования чата вы потеряете доступ к зашифрованным сообщениям. Мы настоятельно рекомендуем включить резервное копирование чата перед выходом из системы.';

  @override
  String get noOtherDevicesFound => 'Другие устройства не найдены';

  @override
  String get fileIsTooBigForServer =>
      'Ответ сервера: размер файла превышает максимальный.';

  @override
  String get onlineStatus => 'онлайн';

  @override
  String onlineMinAgo(Object min) {
    return 'был(а) в сети $minм. назад';
  }

  @override
  String onlineHourAgo(Object hour) {
    return 'был(а) в сети $hour ч';
  }

  @override
  String onlineDayAgo(Object day) {
    return 'онлайн $dayд назад';
  }

  @override
  String get noMessageHereYet => 'Здесь еще нет сообщений...';

  @override
  String get sendMessageGuide =>
      'Отправьте сообщение или нажмите на приветствие.';

  @override
  String get youCreatedGroupChat => 'Вы создали групповой чат';

  @override
  String get chatCanHave => 'В этом чате:';

  @override
  String get upTo100000Members => 'Не более 100.000 участников';

  @override
  String get persistentChatHistory => 'История чата сохраняется';

  @override
  String get addMember => 'Добавить участников';

  @override
  String get profile => 'Профиль';

  @override
  String get channels => 'Каналы';

  @override
  String get chatMessage => 'Новое сообщение';

  @override
  String welcomeToTwake(Object user) {
    return 'Добро пожаловать в Twake, $user';
  }

  @override
  String get startNewChatMessage =>
      'Всегда приятно пообщаться с друзьями или коллегами.\nНапишите им в личные сообщения, создайте групповой чат или получите приглашение в уже существующий.';

  @override
  String get statusDot => '⬤';

  @override
  String get active => 'Активирован';

  @override
  String get inactive => 'Не активирован';

  @override
  String get newGroupChat => 'Новый групповой чат';

  @override
  String get twakeUsers => 'Пользователи Twake';

  @override
  String get expand => 'Развернуть';

  @override
  String get shrink => 'Свернуть';

  @override
  String noResultForKeyword(Object keyword) {
    return 'Нет результатов по запросу \"$keyword\"';
  }

  @override
  String get searchResultNotFound1 =>
      '• Убедитесь, что в вашем запросе нет опечаток.\n';

  @override
  String get searchResultNotFound2 =>
      '• Этого пользователя может не быть в вашей адресной книге.\n';

  @override
  String get searchResultNotFound3 =>
      '• Проверьте разрешение на доступ к контактам, пользователь может быть в вашей адресной книге.\n';

  @override
  String get searchResultNotFound4 => '• Если причина не указана выше, ';

  @override
  String get searchResultNotFound5 => 'обратитесь за помощью.';

  @override
  String get more => 'Больше';

  @override
  String get whoWouldYouLikeToAdd => 'Кого бы вы хотели добавить?';

  @override
  String get addAPhoto => 'Добавить фото';

  @override
  String maxImageSize(Object max) {
    return 'Максимальный размер файла: ${max}MB';
  }

  @override
  String get owner => 'Владелец';

  @override
  String participantsCount(Object count) {
    return 'Участники ($count)';
  }

  @override
  String get back => 'Назад';

  @override
  String get wrongServerName => 'Неверное имя сервера';

  @override
  String get serverNameWrongExplain =>
      'Адрес сервера был отправлен вам администратором компании. Проверьте адрес электронной почты приглашения.';

  @override
  String get contacts => 'Контакты';

  @override
  String get searchForContacts => 'Поиск контактов';

  @override
  String get soonThereHaveContacts => 'Скоро будут контакты';

  @override
  String get searchSuggestion =>
      'Вы можете искать пользователей по имени или публичному адресу сервера';

  @override
  String get loadingContacts => 'Загрузка контактов...';

  @override
  String get recentChat => 'ПОСЛЕДНИЕ ЧАТЫ';

  @override
  String get selectChat => 'Выбрать чат';

  @override
  String get search => 'Поиск';

  @override
  String get forwardTo => 'Переслать...';

  @override
  String get noConnection => 'Нет связи';

  @override
  String photoSelectedCounter(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фотографии',
      one: '1 фотография',
    );
    return 'Выбрано $_temp0';
  }

  @override
  String get addACaption => 'Добавьте подпись...';

  @override
  String get noImagesFound => 'Изображения не найдены';

  @override
  String get captionForImagesIsNotSupportYet =>
      'Подписи к изображениям пока не поддерживаются.';

  @override
  String get tapToAllowAccessToYourGallery =>
      'Нажмите, чтобы разрешить доступ к вашей галерее';

  @override
  String get tapToAllowAccessToYourCamera =>
      'Вы можете включить доступ к камере в приложении \"Настройки\", чтобы совершать видеозвонки в';

  @override
  String get twake => 'Twake Chat';

  @override
  String get permissionAccess => 'Разрешение на доступ';

  @override
  String get allow => 'Разрешить';

  @override
  String get explainStoragePermission =>
      'Для предварительного просмотра файлов Twake требуется доступ к вашему хранилищу';

  @override
  String get explainGoToStorageSetting =>
      'Вам нужен доступ к вашему хранилищу для предварительного просмотра файла, перейдите в настройки, чтобы разрешить это разрешение';

  @override
  String get gallery => 'Галерея';

  @override
  String get documents => 'Документы';

  @override
  String get location => 'Местоположение';

  @override
  String get contact => 'Контакт';

  @override
  String get file => 'Файл';

  @override
  String get recent => 'Последние';

  @override
  String get chatsAndContacts => 'Чаты и контакты';

  @override
  String get externalContactTitle => 'Пригласить новых пользователей';

  @override
  String get externalContactMessage =>
      'Некоторых пользователей, которых вы хотите добавить, нет в ваших контактах. Пригласить их?';

  @override
  String get clear => 'Очистить';

  @override
  String get keyboard => 'Клавиатура';

  @override
  String get changeChatAvatar => 'Измените аватар в чате';

  @override
  String get roomAvatarMaxFileSize => 'Размер аватара слишком большой';

  @override
  String roomAvatarMaxFileSizeLong(Object max) {
    return 'Размер аватара должен быть меньше $max';
  }

  @override
  String get continueProcess => 'Продолжить';

  @override
  String get youAreUploadingPhotosDoYouWantToCancelOrContinue =>
      'Не удалось загрузить изображение! Продолжить создание группового чата?';

  @override
  String hasCreatedAGroupChat(Object groupName) {
    return 'создал групповой чат “$groupName”';
  }

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get adminPanel => 'Панель администратора';

  @override
  String get acceptInvite => 'Да, пожалуйста, присоединяйтесь';

  @override
  String get askToInvite =>
      ' хочет, чтобы вы присоединились к этому чату. Что скажешь?';

  @override
  String get select => 'Выбрать';

  @override
  String get copyMessageText => 'Скопировать';

  @override
  String get pinThisChat => 'Закрепить чат';

  @override
  String get unpinThisChat => 'Открепить чат';

  @override
  String get add => 'Добавить';

  @override
  String get addMembers => 'Добавить участников';

  @override
  String get chatInfo => 'Информация';

  @override
  String get mute => 'Отключить уведомления';

  @override
  String membersInfo(Object count) {
    return 'Участники ($count)';
  }

  @override
  String get members => 'Участники';

  @override
  String get media => 'Медиа';

  @override
  String get files => 'Файлы';

  @override
  String get links => 'Ссылки';

  @override
  String get downloads => 'Загрузки';

  @override
  String get downloadImageSuccess => 'Изображение сохранено';

  @override
  String get downloadImageError => 'Не удалось сохранить';

  @override
  String downloadFileInWeb(Object directory) {
    return 'Файл сохранен в $directory';
  }

  @override
  String get notInAChatYet => 'У вас еще нет чатов';

  @override
  String get blankChatTitle =>
      'Выберите чат или нажмите на #EditIcon#, чтобы создать его.';

  @override
  String get errorPageTitle => 'Что-то пошло не так';

  @override
  String get errorPageDescription => 'Этой страницы не существует.';

  @override
  String get errorPageButton => 'Назад к чату';

  @override
  String get playVideo => 'Проиграть';

  @override
  String get done => 'Готово';

  @override
  String get markThisChatAsRead => 'Пометить как прочитанный';

  @override
  String get markThisChatAsUnRead => 'Пометить как непрочитанный';

  @override
  String get muteThisChat => 'Отключить уведомления';

  @override
  String get unmuteThisChat => 'Включить уведомления';

  @override
  String get read => 'Читать';

  @override
  String get unread => 'Не прочтено';

  @override
  String get unmute => 'Включить уведомления';

  @override
  String get privacyAndSecurity => 'Конфиденциальность и безопасность';

  @override
  String get notificationAndSounds => 'Уведомления и звук';

  @override
  String get appLanguage => 'Язык приложения';

  @override
  String get chatFolders => 'Папки';

  @override
  String get displayName => 'Отображаемое имя';

  @override
  String get bio => 'Био (опционально)';

  @override
  String get matrixId => 'Matrix ID';

  @override
  String get email => 'Email';

  @override
  String get company => 'Компания';

  @override
  String get basicInfo => 'ИНФОРМАЦИЯ ПРОФИЛЯ';

  @override
  String get editProfileDescriptions =>
      'Обновляйте профиль – имя, изображение и краткое описание.';

  @override
  String get workIdentitiesInfo => 'ИДЕНТИФИКАТОРЫ';

  @override
  String get editWorkIdentitiesDescriptions =>
      'Просматривайте ваш профиль: идентификатор Matrix, адрес электронной почты и название компании.';

  @override
  String get copiedMatrixIdToClipboard =>
      'Matrix ID скопирован в буфер обмена.';

  @override
  String get changeProfileAvatar => 'Изменить аватар';

  @override
  String countPinChat(Object countPinChat) {
    return 'ЗАКРЕПЛЕННЫЕ ЧАТЫ ($countPinChat)';
  }

  @override
  String countAllChat(Object countAllChat) {
    return 'ВСЕ ЧАТЫ ($countAllChat)';
  }

  @override
  String get thisMessageHasBeenEncrypted => 'Это сообщение зашифровано';

  @override
  String get roomCreationFailed => 'Не удалось создать комнату';

  @override
  String get errorGettingPdf => 'Не удалось загрузить PDF';

  @override
  String get errorPreviewingFile => 'Предварительный просмотр недоступен';

  @override
  String get paste => 'Вставить';

  @override
  String get cut => 'Вырезать';

  @override
  String get pasteImageFailed => 'Не удалось вставить изображение';

  @override
  String get copyImageFailed => 'Не удалось скопировать изображение';

  @override
  String get fileFormatNotSupported => 'Формат файла не поддерживается';

  @override
  String get noResultsFound => 'Результаты не найдены';

  @override
  String get encryptionMessage =>
      'Эта функция защищает ваши сообщения от прочтения другими людьми, а также не позволяет нам копировать их на наших серверах. Вы не сможете отключить ее позже.';

  @override
  String get encryptionWarning =>
      'Вы можете потерять свои сообщения, если зайдете в приложение Twake на другом устройстве.';

  @override
  String get selectedUsers => 'Выбранные пользователи';

  @override
  String get clearAllSelected => 'Удалить выбранные';

  @override
  String get newDirectMessage => 'Новые личные сообщения';

  @override
  String get contactInfo => 'О контакте';

  @override
  String countPinnedMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Закрепленное сообщение #$count',
      zero: 'Закрепленное сообщение',
    );
    return '$_temp0';
  }

  @override
  String pinnedMessages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count закрепленных сообщения',
      one: '1 закрепленное сообщение',
    );
    return '$_temp0';
  }

  @override
  String get copyImageSuccess => 'Изображение скопировано';

  @override
  String get youNeedToAcceptTheInvitation =>
      'Примите приглашение, чтобы начать общение';

  @override
  String get hasInvitedYouToAChat =>
      ' пригласил(-а) вас в чат. Принять или отклонить и удалить беседу?';

  @override
  String get declineTheInvitation => 'Отклонить приглашение?';

  @override
  String get doYouReallyWantToDeclineThisInvitation =>
      'Вы действительно хотите отклонить это приглашение и удалить чат? Это действие нельзя отменить.';

  @override
  String get declineAndRemove => 'Отклонить и удалить';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get contactsWarningBannerTitle =>
      'Чтобы общаться со всеми своими друзьями, предоставьте Twake доступ к вышей контактной книге. Спасибо за понимание.';

  @override
  String contactsCount(Object count) {
    return 'Контакты ($count)';
  }

  @override
  String linagoraContactsCount(Object count) {
    return 'Контакты Linagora ($count)';
  }

  @override
  String fetchingPhonebookContacts(Object progress) {
    return 'Получение контактов с устройства...($progress% выполнено)';
  }

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageVietnamese => 'Вьетнамский';

  @override
  String get languageFrench => 'Французский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get settingsLanguageDescription => 'Выберите язык Twake Chat';

  @override
  String sendImages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отправлены $count изображений',
      one: 'Отправлено 1 изображение',
    );
    return '$_temp0';
  }

  @override
  String get enterCaption => 'Добавить описание...';

  @override
  String get failToSend => 'Отправить не удалось, повторите попытку';

  @override
  String get showLess => 'Свернуть';

  @override
  String get showMore => 'Развернуть';

  @override
  String get unreadMessages => 'Непрочитанные сообщения';

  @override
  String get groupInformation => 'Подробнее о чате';

  @override
  String get linkInvite => 'Приглашение по ссылке';

  @override
  String get noDescription => 'Описания нет';

  @override
  String get description => 'Описание';

  @override
  String get groupName => 'Название чата';

  @override
  String get descriptionHelper =>
      'Вы можете добавить описание чата (необязательно).';

  @override
  String get groupNameCannotBeEmpty => 'Добавьте название чата';

  @override
  String get unpinAllMessages => 'Открепить все сообщения';

  @override
  String get pinnedMessagesTooltip => 'Закрепленные сообщения';

  @override
  String get jumpToMessage => 'Перейти к сообщению';

  @override
  String get failedToUnpin => 'Не удалось открепить';

  @override
  String get welcomeTo => 'Добро пожаловать в';

  @override
  String get descriptionWelcomeTo =>
      'мессенджер с открытым исходным кодом\nна Matrix-протоколе, который позволяет\nшифровать ваши данные';

  @override
  String get startMessaging => 'Начать общение';

  @override
  String get signIn => 'Войти';

  @override
  String get createTwakeId => 'Создать Twake ID';

  @override
  String get useYourCompanyServer => 'Корпоративный сервер';

  @override
  String get descriptionTwakeId =>
      'Open Source мессенджер, который шифрует\nваши данные с помощью протокола Matrix';

  @override
  String countFilesSendPerDialog(Object count) {
    return 'Максимальный размер файла: $count.';
  }

  @override
  String sendFiles(Object count) {
    return 'Отправить $count файлов';
  }

  @override
  String get addAnotherAccount => 'Добавить аккаунт';

  @override
  String get accountSettings => 'Настройки аккаунта';

  @override
  String get failedToSendFiles => 'Ошибка отправки файлов';

  @override
  String get noResults => 'Нет результатов';

  @override
  String get isSingleAccountOnHomeserver =>
      'Мы еще не поддерживаем несколько акаунтов на одном домашнем сервере';

  @override
  String messageSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщений',
      one: '1 сообщение',
      zero: 'Сообщения не',
    );
    return '$_temp0 выбрано(-ы)';
  }

  @override
  String draftChatHookPhrase(String user) {
    return 'Привет, $user! Предлагаю пообщаться.';
  }

  @override
  String get twakeChatUser => 'Пользователь Twake Chat';

  @override
  String get sharedMediaAndLinks => 'Общие медиа и ссылки';

  @override
  String get errorSendingFiles =>
      'Некоторые файлы невозможно отправить из-за размера, ограничений формата или непредвиденных ошибок. Мы пропустим их.';

  @override
  String get removeFileBeforeSend => 'Удалить файлы с ошибками перед отправкой';

  @override
  String get unselect => 'Отменить выбор';

  @override
  String get searchContacts => 'Поиск контактов';

  @override
  String get tapToAllowAccessToYourMicrophone =>
      'Предоставьте доступ к микрофону в «Настройках», чтобы записывать голос';

  @override
  String get showInChat => 'Показать в чате';

  @override
  String get phone => 'Телефон';

  @override
  String get viewProfile => 'Показать профиль';

  @override
  String get profileInfo => 'Информация профиля';

  @override
  String get saveToDownloads => 'Сохранить в \"Загрузки\"';

  @override
  String get saveToGallery => 'Сохранить в \"Галерею\"';

  @override
  String get fileSavedToDownloads => 'Файл сохранен в \"Загрузки\"';

  @override
  String get saveFileToDownloadsError =>
      'Не удалось сохранить файл в \"Загрузки\"';

  @override
  String explainPermissionToDownloadFiles(String appName) {
    return 'Чтобы продолжить, предоставьте $appName доступ к хранилищу. Это разрешение необходимо, чтобы сохранить файл в папке «Загрузки».';
  }

  @override
  String get explainPermissionToAccessContacts =>
      'Twake Chat не сохраняет ваши контакты.Приложение отправляет только зашифрованные хэши номеров, чтобы проверить, кто из друзей уже пользуется сервисом. Сами контакты на сервер не передаются и не синхронизируются.';

  @override
  String get explainPermissionToAccessMedias =>
      'Twake Chat не синхронизирует данные между вашим устройством и нашими серверами. Мы храним только медиафайлы, которые вы отправили в чат. Все медиафайлы, отправленные в чат, зашифрованы. Перейдите в Настройки > Разрешения и активируйте разрешение Хранилище: Фото и видео. Вы также можете в любое время запретить доступ к своей медиатеке.';

  @override
  String get explainPermissionToAccessPhotos =>
      'Twake Chat не синхронизирует данные между вашим устройством и нашими серверами. Мы храним только медиафайлы, которые вы отправили в чат. Все медиафайлы, отправленные в чат, зашифрованы и надежно хранятся. Перейдите в Настройки > Разрешения и активируйте разрешение Хранилище: Фотографии. Вы также можете в любое время запретить доступ к своей медиатеке.';

  @override
  String get explainPermissionToAccessVideos =>
      'Twake Chat не синхронизирует данные между вашим устройством и нашими серверами. Мы храним только медиафайлы, которые вы отправили в чат. Все медиафайлы, отправленные в чат, зашифрованы и надежно хранятся. Перейдите в Настройки > Разрешения и активируйте разрешение Хранилище: Видео. Вы также можете в любое время запретить доступ к своей медиатеке.';

  @override
  String get downloading => 'Загрузка';

  @override
  String get settingUpYourTwake =>
      'Настройка аккаунта\nЭто может занять некоторое время';

  @override
  String get performingAutomaticalLogin =>
      'Выполнение автоматического входа   через SSO';

  @override
  String get backingUpYourMessage =>
      'Подготовка серверной среды для резервного копирования сообщений';

  @override
  String get recoveringYourEncryptedChats =>
      'Восстановление зашифрованных чатов';

  @override
  String get configureDataEncryption => 'Настройка шифрования данных';

  @override
  String get configurationNotFound => 'Данные конфигурации не найдены';

  @override
  String get fileSavedToGallery => 'Файл сохранен в \"Галерею\"';

  @override
  String get saveFileToGalleryError =>
      'Не удалось сохранить файл в \"Галерею\"';

  @override
  String explainPermissionToGallery(String appName) {
    return 'Чтобы продолжить, разрешите $appName доступ к галерее. Это необходимо, чтобы сохранить файл.';
  }

  @override
  String get tokenNotFound => 'Токен входа не найден';

  @override
  String get dangerZone => 'Будьте внимательны';

  @override
  String get leaveGroupSubtitle =>
      'Этот групповой чат останется после того, как вы его покинете';

  @override
  String get leaveChatFailed => 'Не удалось покинуть чат';

  @override
  String get invalidLoginToken => 'Недействительный токен входа';

  @override
  String get copiedPublicKeyToClipboard =>
      'Открытый ключ скопирован в буфер обмена.';

  @override
  String get removeFromGroup => 'Удалить из группового чата';

  @override
  String get removeUser => 'Удалить пользователя';

  @override
  String removeReason(Object user) {
    return 'Удалить $user из группового чата';
  }

  @override
  String get switchAccounts => 'Сменить аккаунт';

  @override
  String get selectAccount => 'Выбор аккаунта';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get byContinuingYourAgreeingToOur => 'Продолжая, вы принимаете';

  @override
  String get youDontHaveAnyContactsYet => 'У вас еще нет контактов.';

  @override
  String get loading => 'Загрузка...';

  @override
  String get errorDialogTitle => 'Что-то пошло не так';

  @override
  String get shootingTips => 'Нажмите, чтобы сделать фото.';

  @override
  String get shootingWithRecordingTips =>
      'Нажмите, чтобы сделать фото. Удерживайте для записи видео.';

  @override
  String get shootingOnlyRecordingTips => 'Удерживайте для записи видео.';

  @override
  String get shootingTapRecordingTips => 'Нажмите, чтобы записать видео.';

  @override
  String get loadFailed => 'Не удалось загрузить';

  @override
  String get saving => 'Сохранение...';

  @override
  String get sActionManuallyFocusHint => 'ручная фокусировка';

  @override
  String get sActionPreviewHint => 'предпросмотр';

  @override
  String get sActionRecordHint => 'запись';

  @override
  String get sActionShootHint => 'сделать фото';

  @override
  String get sActionShootingButtonTooltip => 'кнопка съемки';

  @override
  String get sActionStopRecordingHint => 'остановить запись';

  @override
  String sCameraLensDirectionLabel(Object value) {
    return 'Направление объектива камеры: $value';
  }

  @override
  String sCameraPreviewLabel(Object value) {
    return 'Предпросмотр камеры: $value';
  }

  @override
  String sFlashModeLabel(Object mode) {
    return 'Режим вспышки: $mode';
  }

  @override
  String sSwitchCameraLensDirectionLabel(Object value) {
    return 'Переключиться на камеру $value';
  }

  @override
  String get photo => 'Фото';

  @override
  String get video => 'Видео';

  @override
  String get message => 'Сообщение';

  @override
  String fileTooBig(int maxSize) {
    return 'Выбранный файл слишком большой. Загрузите файл размером менее $maxSize МБ.';
  }

  @override
  String get enable_notifications => 'Включить уведомления';

  @override
  String get disable_notifications => 'Отключить уведомления';

  @override
  String get logoutDialogWarning =>
      'Вы потеряете доступ к зашифрованным сообщениям. Рекомендуем активировать резервную копию чатов перед выходом';

  @override
  String get copyNumber => 'Скопировать номер';

  @override
  String get callViaCarrier => 'Позвонить через Carrier';

  @override
  String get scanQrCodeToJoin =>
      'Установка мобильного приложения позволит вам связаться с людьми из адресной книги телефона; ваши чаты синхронизируются между устройствами';

  @override
  String get thisFieldCannotBeBlank => 'Это поле не может быть пустым';

  @override
  String get phoneNumberCopiedToClipboard => 'Номер телефона скопирован';

  @override
  String get deleteAccountMessage =>
      'Групповые чаты, которые вы создали, останутся неадминистрируемыми, если вы не предоставите другому пользователю права администратора. У пользователей по-прежнему будет доступ к истории сообщений – даже если вы удалите учетную запись.';

  @override
  String get deleteLater => 'Удалить позже';

  @override
  String get areYouSureYouWantToDeleteAccount =>
      'Вы уверены, что хотите удалить аккаунт?';

  @override
  String get textCopiedToClipboard => 'Текст скопирован';

  @override
  String get selectAnEmailOrPhoneYouWantSendTheInvitationTo =>
      'Выберите email или телефон, на который хотите отправить приглашение';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get sendInvitation => 'Отправить приглашение';

  @override
  String get verifyWithAnotherDevice =>
      'Проверить при помощи другого устройства';

  @override
  String get contactLookupFailed => 'Поиск контактов был прерван';

  @override
  String get invitationHasBeenSuccessfullySent =>
      'Приглашение успешно отправлено!';

  @override
  String get failedToSendInvitation => 'Не удалось отправить приглашение.';

  @override
  String get invalidPhoneNumber => 'Неверный формат номера телефона';

  @override
  String get invalidEmail => 'Неверный формат электронной почты';

  @override
  String get shareInvitationLink => 'Поделиться пригласительной ссылкой';

  @override
  String get failedToGenerateInvitationLink =>
      'Не удалось создать пригласительную ссылку.';

  @override
  String get youAlreadySentAnInvitationToThisContact =>
      'Вы уже отправили приглашение этому контакту';

  @override
  String get selectedEmailWillReceiveAnInvitationLinkAndInstructions =>
      'На выбранный адрес электронной почты будет отправлена пригласительная ссылка и инструкции.';

  @override
  String get selectedNumberWillGetAnSMSWithAnInvitationLinkAndInstructions =>
      'На выбранный номер будет отправлено SMS с пригласительной ссылкой и инструкциями.';

  @override
  String get reaction => 'Реакция';

  @override
  String get noChatPermissionMessage =>
      'У вас не хватает прав, чтобы отправлять сообщения в этом чате.';

  @override
  String get administration => 'Администрирование';

  @override
  String get yourDataIsEncryptedForSecurity =>
      'Ваши данные зашифрованы для безопасности';

  @override
  String get failedToDeleteMessage => 'Не удалось удалить сообщение.';

  @override
  String get noDeletePermissionMessage =>
      'У вас нет разрешения на удаление этого сообщения.';

  @override
  String get edited => 'изменено';

  @override
  String get editMessage => 'Изменить сообщение';

  @override
  String get assignRoles => 'Назначить роли';

  @override
  String get permissions => 'Разрешения';

  @override
  String adminsOfTheGroup(Object number) {
    return 'АДМИНИСТРАТОРЫ ГРУППЫ ($number)';
  }

  @override
  String get addAdminsOrModerators => 'Добавить администраторов/модераторов';

  @override
  String get member => 'Участник';

  @override
  String get guest => 'Гость';

  @override
  String get exceptions => 'Исключения';

  @override
  String get readOnly => 'Только чтение';

  @override
  String readOnlyCount(Object number) {
    return 'ТОЛЬКО ЧТЕНИЕ ($number)';
  }

  @override
  String get removedUsers => 'Удаленные пользователи';

  @override
  String bannedUsersCount(Object number) {
    return 'ЧЕРНЫЙ СПИСОК ($number)';
  }

  @override
  String get downgradeToReadOnly => 'Понизить до уровня «Только чтение»';

  @override
  String memberOfTheGroup(Object number) {
    return 'УЧАСТНИКИ ЧАТА ($number)';
  }

  @override
  String get selectRole => 'Выбрать роль';

  @override
  String get canReadMessages => 'Может читать сообщения';

  @override
  String get canWriteMessagesSendReacts =>
      'Может писать сообщения, отправлять реакции...';

  @override
  String get canRemoveUsersDeleteMessages =>
      'Может удалять пользователей, удалять сообщения...';

  @override
  String get canAccessAllFeaturesAndSettings =>
      'Имеет доступ ко всем функциям и настройкам';

  @override
  String get invitePeopleToTheRoom => 'Приглашать людей в чат';

  @override
  String get sendReactions => 'Отправлять реакции';

  @override
  String get deleteMessagesSentByMe => 'Удалять отправленные мной сообщения';

  @override
  String get notifyEveryoneUsingRoom => 'Уведомлять всех, используя @room';

  @override
  String get joinCall => 'Присоединяться к звонку';

  @override
  String get removeMembers => 'Удалять пользователей';

  @override
  String get deleteMessagesSentByOthers =>
      'Удалять сообщения, отправленные другими';

  @override
  String get pinMessageForEveryone => 'Закреплять сообщения (для всех)';

  @override
  String get startCall => 'Начинать звонок';

  @override
  String get changeGroupName => 'Изменять имя группы';

  @override
  String get changeGroupDescription => 'Изменять описание группы';

  @override
  String get changeGroupAvatar => 'Изменять аватар группы';

  @override
  String get changeGroupHistoryVisibility =>
      'Изменять видимость истории группы';

  @override
  String get searchGroupMembers => 'Искать участников группы';

  @override
  String get permissionErrorChangeRole =>
      'У вас недостаточно прав, чтобы изменять роли. Обратитесь за помощью к администратору';

  @override
  String get demoteAdminsModerators => 'Понизить администраторов/модераторов';

  @override
  String get deleteMessageConfirmationTitle =>
      'Вы уверены, что хотите удалить это сообщение?';

  @override
  String get permissionErrorBanUser =>
      'У вас недостаточно прав, чтобы банить пользователей. Обратитесь за помощью к администратору';

  @override
  String get removeMember => 'Удалить участника';

  @override
  String get removeMemberSelectionError =>
      'Вы не можете удалить участника, чья роль равна или выше вашей.';

  @override
  String get downgrade => 'Понизить';

  @override
  String get deletedMessage => 'Удаленное сообщение';

  @override
  String get unban => 'Разбанить';

  @override
  String get permissionErrorUnbanUser =>
      'У вас недостаточно прав, чтобы разблокировать пользователей. Обратитесь за помощью к администратору';

  @override
  String get transferOwnership => 'Передача права собственности';

  @override
  String confirmTransferOwnership(Object name) {
    return 'Вы уверены, что хотите передать право собственности на этот чат $name?';
  }

  @override
  String get transferOwnershipDescription =>
      'Этот пользователь получит полный контроль над чатом, и у вас больше не будет прав полного управления. Это действие необратимо.';

  @override
  String get confirmTransfer => 'Подтвердить перенос';

  @override
  String get unblockUser => 'Разблокировать пользователя';

  @override
  String get blockUser => 'Заблокировать пользователя';

  @override
  String get permissionErrorUnblockUser =>
      'У вас недостаточно прав, чтобы разблокировать пользователя.';

  @override
  String get permissionErrorBlockUser =>
      'У вас недостаточно прав, чтобы заблокировать пользователя.';

  @override
  String userIsNotAValidMxid(Object mxid) {
    return '$mxid не является допустимым Matrix ID';
  }

  @override
  String userNotFoundInIgnoreList(Object mxid) {
    return '$mxid не найден в вашем черном списке';
  }

  @override
  String get blockedUsers => 'Заблокированные пользователи';

  @override
  String unblockUsername(Object name) {
    return 'Разблокировать $name';
  }

  @override
  String get unblock => 'Разблокировать';

  @override
  String get unblockDescriptionDialog =>
      'Этот человек сможет писать вам сообщения и видеть, когда вы онлайн. Он не получит уведомление о том, что вы его разблокировали.';

  @override
  String get report => 'Пожаловаться';

  @override
  String get reportDesc => 'Что не так с этим сообщением?';

  @override
  String get sendReport => 'Отправить жалобу';

  @override
  String get addComment => 'Добавить комментарий';

  @override
  String get spam => 'Спам';

  @override
  String get violence => 'Жестокость';

  @override
  String get childAbuse => 'Насилие над детьми';

  @override
  String get pornography => 'Порнография';

  @override
  String get copyrightInfringement => 'Нарушение авторского права';

  @override
  String get terrorism => 'Терроризм';

  @override
  String get other => 'Другое';

  @override
  String get enableRightAndLeftMessageAlignment =>
      'Включить выравнивание сообщений по правому/левому краю';

  @override
  String get holdToRecordAudio => 'Удерживайте для записи.';

  @override
  String get explainPermissionToAccessMicrophone =>
      'Для отправки голосовых сообщений разрешите Twake Chat доступ к микрофону.';

  @override
  String get allowMicrophoneAccess => 'Разрешить доступ к микрофону';

  @override
  String get later => 'Позже';

  @override
  String get couldNotPlayAudioFile => 'Не удалось воспроизвести аудиофайл';

  @override
  String get slideToCancel => 'Смахните, чтобы отменить';

  @override
  String get recordingInProgress => 'Идет запись';

  @override
  String get pleaseFinishOrStopTheRecording =>
      'Завершите или остановите запись, прежде чем выполнять другие действия.';

  @override
  String get audioMessageFailedToSend => 'Не удалось отправить аудиосообщение.';
}
