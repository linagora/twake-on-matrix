// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class L10nKo extends L10n {
  L10nKo([String locale = 'ko']) : super(locale);

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다!';

  @override
  String get pleaseEnterValidEmail => '유효한 이메일 주소를 입력해주세요.';

  @override
  String get repeatPassword => '비밀번호 다시 입력';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return '최소 $min자를 선택하세요.';
  }

  @override
  String get about => '소개';

  @override
  String get updateAvailable => 'FluffyChat 업데이트 이용가능';

  @override
  String get updateNow => '백그라운드에서 업데이트 시작';

  @override
  String get accept => '수락';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍 $username님이 초대를 수락함';
  }

  @override
  String get account => '계정';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐 $username님이 종단간 암호화를 활성화함';
  }

  @override
  String get addEmail => '이메일 추가';

  @override
  String get confirmMatrixId => '계정을 삭제하려면 Matrix ID를 확인해 주세요.';

  @override
  String supposedMxid(Object mxid) {
    return 'This should be $mxid';
  }

  @override
  String get addGroupDescription => '그룹 소개 추가';

  @override
  String get addToSpace => '스페이스에 추가';

  @override
  String get admin => '관리자';

  @override
  String get alias => '별명';

  @override
  String get all => '모두';

  @override
  String get allChats => '모든 채팅';

  @override
  String get commandHint_googly => '왕눈이 눈알 보내기';

  @override
  String get commandHint_cuddle => 'Send a cuddle';

  @override
  String get commandHint_hug => 'Send a hug';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName 님이 왕눈이 눈알을 보냈습니다';
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
    return '$senderName 가 전화에 응답했습니다';
  }

  @override
  String get anyoneCanJoin => '누구나 들어올 수 있음';

  @override
  String get appLock => '앱 잠금';

  @override
  String get archive => '저장';

  @override
  String get archivedRoom => '저장된 방';

  @override
  String get areGuestsAllowedToJoin => '게스트 유저가 참가 여부';

  @override
  String get areYouSure => '확실한가요?';

  @override
  String get areYouSureYouWantToLogout => '로그아웃하고 싶은 것이 확실한가요?';

  @override
  String get askSSSSSign => '다른 사람을 서명하기 위해서, 저장 비밀번호나 복구 키를 입력해주세요.';

  @override
  String askVerificationRequest(Object username) {
    return '$username의 인증 요청을 수락할까요?';
  }

  @override
  String get autoplayImages => '자동으로 움직이는 스티커와 이모트 재생';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return '홈서버가 지원하는 로그인 유형:\n$serverVersions\n하지만 이 앱에서 지원하는 것은:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => '엔터로 보내기';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return '이 홈서버가 지원하는 Spec 버전:\n$serverVersions\n하지만 이 앱은 $supportedVersions만 지원합니다';
  }

  @override
  String get banFromChat => '채팅에서 밴';

  @override
  String get banned => '밴됨';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username이 $targetName 밴함';
  }

  @override
  String get blockDevice => '기기 차단';

  @override
  String get blocked => '차단됨';

  @override
  String get botMessages => '봇 메시지';

  @override
  String get bubbleSize => '버블 크기';

  @override
  String get cancel => '취소';

  @override
  String cantOpenUri(Object uri) {
    return 'URI $uri를 열 수 없습니다';
  }

  @override
  String get changeDeviceName => '기기 이름 바꾸기';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username이 채팅 아바타 바꿈';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username이 채팅 설명을 \'$description\' 으로 변경함';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username이 채팅 이름을 \'$chatname\' 으로 바꿈';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username이 채팅 권한을 바꿈';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username이 닉네임을 \'$displayname\' 으로 바꿈';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username이 게스트 접근 규칙을 변경함';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username이 게스트 접근 규칙을 $rules 로 변경함';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username이 대화 기록 설정을 변경함';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username이 대화 기록 설정을 $rules 로 바꿈';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username이 참가 규칙을 바꿈';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username이 참가 규칙을 $joinRules 로 바꿈';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username이 자신의 아바타를 바꿈';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username이 방 별명을 바꿈';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username이 초대 링크 바꿈';
  }

  @override
  String get changePassword => '비밀번호 바꾸기';

  @override
  String get changeTheHomeserver => '홈서버 바꾸기';

  @override
  String get changeTheme => '스타일 바꾸기';

  @override
  String get changeTheNameOfTheGroup => '그룹의 이름 바꾸기';

  @override
  String get changeWallpaper => '배경 바꾸기';

  @override
  String get changeYourAvatar => '아바타 바꾸기';

  @override
  String get channelCorruptedDecryptError => '암호화가 손상되었습니다';

  @override
  String get chat => '채팅';

  @override
  String get yourUserId => '당신의 유저 ID:';

  @override
  String get yourChatBackupHasBeenSetUp => '당신의 채팅 백업이 설정되었습니다.';

  @override
  String get chatBackup => '채팅 백업';

  @override
  String get chatBackupDescription =>
      '당신의 오래된 메시지는 보안 키로 보호됩니다. 이 키를 잃어버리지 마세요.';

  @override
  String get chatDetails => '채팅 정보';

  @override
  String get chatHasBeenAddedToThisSpace => '이 스페이스에 채팅이 추가되었습니다';

  @override
  String get chats => '채팅';

  @override
  String get chooseAStrongPassword => '안전한 비밀번호를 설정하세요';

  @override
  String get chooseAUsername => '닉네임 고르기';

  @override
  String get clearArchive => '저장 지우기';

  @override
  String get close => '닫기';

  @override
  String get commandHint_markasdm => 'Mark as direct chat';

  @override
  String get commandHint_markasgroup => 'Mark as chat';

  @override
  String get commandHint_ban => '이 룸에서 주어진 유저 밴하기';

  @override
  String get commandHint_clearcache => '캐시 지우기';

  @override
  String get commandHint_create =>
      '빈 그룹 채팅을 생성\t\n--no-encryption을 사용해 암호화를 비활성화';

  @override
  String get commandHint_discardsession => '세션 삭제';

  @override
  String get commandHint_dm => '다이렉트 채팅 시작\t\n--no-encryption을 사용해 암호화 비활성화';

  @override
  String get commandHint_html => 'HTML 형식의 문자 보내기';

  @override
  String get commandHint_invite => '주어진 유저 이 룸에 초대하기';

  @override
  String get commandHint_join => '주어진 방 들어가기';

  @override
  String get commandHint_kick => '주어진 유저 방에서 삭제하기';

  @override
  String get commandHint_leave => '이 룸 나가기';

  @override
  String get commandHint_me => '자신을 소개하세요';

  @override
  String get commandHint_myroomavatar => '이 방의 사진 설정하기 (by mxc-uri)';

  @override
  String get commandHint_myroomnick => '이 방의 표시 이름 설정하기';

  @override
  String get commandHint_op => '주어진 유저의 권한 레벨 설정 (기본:50)';

  @override
  String get commandHint_plain => '형식이 지정되지 않은 문자 보내기';

  @override
  String get commandHint_react => '답장 반응으로 보내기';

  @override
  String get commandHint_send => '문자 보내기';

  @override
  String get commandHint_unban => '주어진 유저 이 룸에서 밴 해제하기';

  @override
  String get commandInvalid => '잘못된 명령어';

  @override
  String commandMissing(Object command) {
    return '$command 는 명령어가 아닙니다.';
  }

  @override
  String get compareEmojiMatch => '다른 기기에서도 아래의 이모지가 일치하는지 비교하세요:';

  @override
  String get compareNumbersMatch => '다른 기기에서도 아래의 숫자가 일치하는지 비교하세요:';

  @override
  String get configureChat => '채팅 설정';

  @override
  String get confirm => '확인';

  @override
  String get connect => '연결';

  @override
  String get contactHasBeenInvitedToTheGroup => '연락처가 그룹에 초대되었습니다';

  @override
  String get containsDisplayName => '표시 이름 포함';

  @override
  String get containsUserName => '유저 이름 포함';

  @override
  String get contentHasBeenReported => '콘텐츠가 서버 운영자에게 신고되었습니다';

  @override
  String get copiedToClipboard => '클립보드에 복사됨';

  @override
  String get copy => '복사';

  @override
  String get copyToClipboard => '클립보드에 복사';

  @override
  String couldNotDecryptMessage(Object error) {
    return '메시지 복호화할 수 없음: $error';
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
  String get create => '생성';

  @override
  String createdTheChat(Object username) {
    return '💬 $username님이 채팅을 생성함';
  }

  @override
  String get createNewGroup => '새로운 그룹';

  @override
  String get createNewSpace => '새로운 스페이스';

  @override
  String get crossSigningEnabled => '교차 서명 켜짐';

  @override
  String get currentlyActive => '현재 활동 중';

  @override
  String get darkTheme => '다크';

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
      '이것은 당신의 계정을 비활성화할 것입니다. 이것은 되돌릴 수 없습니다! 확실한가요?';

  @override
  String get defaultPermissionLevel => '기본 권한 레벨';

  @override
  String get delete => '삭제';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteMessage => '메시지 삭제';

  @override
  String get deny => '거부';

  @override
  String get device => '기기';

  @override
  String get deviceId => '기기 ID';

  @override
  String get devices => '기기';

  @override
  String get directChats => '다이렉트 채팅';

  @override
  String get discover => '발견';

  @override
  String get displaynameHasBeenChanged => '표시 이름이 변경되었습니다';

  @override
  String get download => 'Download';

  @override
  String get edit => '수정';

  @override
  String get editBlockedServers => '차단된 서버 수정';

  @override
  String get editChatPermissions => '채팅 권한 수정';

  @override
  String get editDisplayname => '표시 이름 수정';

  @override
  String get editRoomAliases => '방 별명 수정';

  @override
  String get editRoomAvatar => '방 아바타 수정';

  @override
  String get emoteExists => '이모트가 이미 존재합니다!';

  @override
  String get emoteInvalid => '올바르지 않은 이모트 단축키!';

  @override
  String get emotePacks => '방을 위한 이모트 팩';

  @override
  String get emoteSettings => '이모트 설정';

  @override
  String get emoteShortcode => '이모트 단축키';

  @override
  String get emoteWarnNeedToPick => '이모트 단축키와 이미지를 골라야 합니다!';

  @override
  String get emptyChat => '빈 채팅';

  @override
  String get enableEmotesGlobally => '이모트 팩 항상 사용하기';

  @override
  String get enableEncryption => '암호화 켜기';

  @override
  String get enableEncryptionWarning => '당신은 다시 암호화를 비활성화할 수 없습니다. 확실한가요?';

  @override
  String get encrypted => '암호화됨';

  @override
  String get encryption => '암호화';

  @override
  String get encryptionNotEnabled => '암호화가 비활성화됨';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName 이 통화를 종료했습니다';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => '이메일 주소 입력';

  @override
  String get enterASpacepName => '스페이스 이름 입력';

  @override
  String get homeserver => '홈서버';

  @override
  String get enterYourHomeserver => '당신의 홈서버를 입력하세요';

  @override
  String errorObtainingLocation(Object error) {
    return '위치 얻는 중 오류: $error';
  }

  @override
  String get everythingReady => '모든 것이 준비됐어요!';

  @override
  String get extremeOffensive => '매우 공격적임';

  @override
  String get fileName => '파일 이름';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => '폰트 크기';

  @override
  String get forward => '전달';

  @override
  String get friday => '금요일';

  @override
  String get fromJoining => '들어온 후부터';

  @override
  String get fromTheInvitation => '초대받은 후부터';

  @override
  String get goToTheNewRoom => '새로운 방 가기';

  @override
  String get group => '그룹';

  @override
  String get groupDescription => '그룹 설명';

  @override
  String get groupDescriptionHasBeenChanged => '그룹 설명 바뀜';

  @override
  String get groupIsPublic => '그룸 공개됨';

  @override
  String get groups => '그룹';

  @override
  String groupWith(Object displayname) {
    return '$displayname 과의 그룹';
  }

  @override
  String get guestsAreForbidden => '게스트는 금지되어 있습니다';

  @override
  String get guestsCanJoin => '게스트가 들어올 수 있음';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username이 $targetName에 대한 초대를 철회함';
  }

  @override
  String get help => '도움';

  @override
  String get hideRedactedEvents => '지워진 이벤트 숨기기';

  @override
  String get hideUnknownEvents => '알 수 없는 이벤트 숨기기';

  @override
  String get howOffensiveIsThisContent => '이 콘텐츠가 얼마나 모욕적인가요?';

  @override
  String get id => 'ID';

  @override
  String get identity => '신원';

  @override
  String get ignore => '무시';

  @override
  String get ignoredUsers => '무시된 사용자';

  @override
  String get ignoreListDescription =>
      '당신을 방해하는 사용자들을 무시할 수 있습니다. 당신의 개인 무시 리스트에 있는 사용자들에게서 메시지나 방 초대를 수신할 수 없습니다.';

  @override
  String get ignoreUsername => '유저 이름 무시';

  @override
  String get iHaveClickedOnLink => '링크를 클릭했어요';

  @override
  String get incorrectPassphraseOrKey => '올바르지 않은 복구 키나 비밀번호';

  @override
  String get inoffensive => '모욕적이지 않음';

  @override
  String get inviteContact => '연락처 초대';

  @override
  String inviteContactToGroup(Object groupName) {
    return '연락처 $groupName 에 초대';
  }

  @override
  String get invited => '초대됨';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username님이 $targetName님을 초대함';
  }

  @override
  String get invitedUsersOnly => '초대한 사용자만';

  @override
  String get inviteForMe => '나를 위해 초대';

  @override
  String inviteText(Object username, Object link) {
    return '$username이 당신을 FluffyChat에 초대했습니다.\n1. FluffyChat 설치: https://fluffychat.im\n2. 가입하거나 로그인\n3. 초대 링크 열기: $link';
  }

  @override
  String get isTyping => '가 입력 중';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username님이 채팅에 참가함';
  }

  @override
  String get joinRoom => '방 들어가기';

  @override
  String get keysCached => '키가 캐시됨';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username님이 $targetName님을 추방함';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username님이 $targetName님을 추방하고 차단함';
  }

  @override
  String get kickFromChat => '채팅에서 추방';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return '마지막 활동: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => '오래 전 접속';

  @override
  String get leave => '나가기';

  @override
  String get leftTheChat => '채팅을 나갔습니다';

  @override
  String get license => '라이선스';

  @override
  String get lightTheme => '라이트';

  @override
  String loadCountMoreParticipants(Object count) {
    return '$count명의 참가자 더 표시';
  }

  @override
  String get dehydrate => '세션을 내보내고 기기 초기화 하기';

  @override
  String get dehydrateWarning => '이 동작은 되돌릴 수 없습니다. 백업 파일을 꼭 안전하게 보관하세요.';

  @override
  String get dehydrateShare =>
      'FluffyChat 개인 내보내기 파일입니다. 분실하지 않도록 하시고 비공개로 보관하세요.';

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
  String get loadingPleaseWait => '로딩 중... 기다려 주세요.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => '더 불러오기…';

  @override
  String get locationDisabledNotice => '위치 서비스가 비활성화되었습니다. 위치를 공유하려면 활성화시켜주세요.';

  @override
  String get locationPermissionDeniedNotice =>
      '위치 권한이 거부되었습니다. 위치를 공유하기 위해서 허용해주세요.';

  @override
  String get login => '로그인';

  @override
  String logInTo(Object homeserver) {
    return '$homeserver 에 로그인';
  }

  @override
  String get loginWithOneClick => '클릭 한 번으로 로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get makeSureTheIdentifierIsValid => '식별자가 유효한지 확인하세요';

  @override
  String get memberChanges => '참가자 변경';

  @override
  String get mention => '멘션';

  @override
  String get messages => '메시지';

  @override
  String get messageWillBeRemovedWarning => '모든 참여자에게서 메시지가 지워집니다';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => '관리자';

  @override
  String get monday => '월요일';

  @override
  String get muteChat => '채팅 음소거';

  @override
  String get needPantalaimonWarning =>
      '지금 종단간 암호화를 사용하기 위해서는 Pantalaimon이 필요하다는 것을 알아주세요.';

  @override
  String get newChat => '새로운 채팅';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => '새로운 확인 요청!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => '다음';

  @override
  String get no => '아니요';

  @override
  String get noConnectionToTheServer => '서버에 연결 없음';

  @override
  String get noEmotesFound => '이모트 발견되지 않음. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      '당신은 방이 공개적으로 접근 가능하지 않을 때만 암호화를 켤 수 있습니다.';

  @override
  String get noGoogleServicesWarning =>
      '이 휴대폰에 Google 서비스가 없는 것 같습니다. 프라이버시를 위해 좋은 결정이죠! FluffyChat에서 푸시 알림을 받으려면 https://microg.org/ 이나 https://unifiedpush.org/ 을 사용하는 것을 권장합니다.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1은 matrix 서버가 아닙니다, $server2를 대신 사용할까요?';
  }

  @override
  String get shareYourInviteLink => '당신의 초대 링크 공유';

  @override
  String get typeInInviteLinkManually => '초대 링크 직접 입력...';

  @override
  String get scanQrCode => 'QR 코드 스캔';

  @override
  String get none => '없음';

  @override
  String get noPasswordRecoveryDescription => '당신은 비밀번호를 복구할 방법을 추가하지 않았습니다.';

  @override
  String get noPermission => '권한 없음';

  @override
  String get noRoomsFound => '아무 방도 발견되지 않았어요…';

  @override
  String get notifications => '알림';

  @override
  String numUsersTyping(Object count) {
    return '$count명이 입력 중';
  }

  @override
  String get obtainingLocation => '위치 얻는 중…';

  @override
  String get offensive => '모욕적임';

  @override
  String get offline => '오프라인';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => '확인';

  @override
  String get online => '온라인';

  @override
  String get onlineKeyBackupEnabled => '온라인 키 백업이 활성화됨';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError => '앗! 안타깝게도, 푸시 알림을 설정하는 중 오류가 발생했습니다.';

  @override
  String get oopsSomethingWentWrong => '앗, 무언가가 잘못되었습니다…';

  @override
  String get openAppToReadMessages => '앱을 열어서 메시지를 읽으세요';

  @override
  String get openCamera => '카메라 열기';

  @override
  String get openVideoCamera => '영상용 카메라 열기';

  @override
  String get oneClientLoggedOut => '당신의 클라이언트 중 하나가 로그아웃 됨';

  @override
  String get addAccount => '계정 추가';

  @override
  String get editBundlesForAccount => '이 계정의 번들 수정';

  @override
  String get addToBundle => '번들에 추가';

  @override
  String get removeFromBundle => '이 번들에서 삭제';

  @override
  String get bundleName => '번들 이름';

  @override
  String get enableMultiAccounts => '(베타) 이 기기에서 다중 계정 활성화';

  @override
  String get openInMaps => '지도에서 열기';

  @override
  String get link => '링크';

  @override
  String get serverRequiresEmail => '이 서버는 가입을 위해 당신의 이메일을 확인해야 합니다.';

  @override
  String get optionalGroupName => '(선택) 그룹 이름';

  @override
  String get or => '이나';

  @override
  String get participant => '참여자';

  @override
  String get passphraseOrKey => '비밀번호나 복구 키';

  @override
  String get password => '비밀번호';

  @override
  String get passwordForgotten => '비밀번호 까먹음';

  @override
  String get passwordHasBeenChanged => '비밀번호가 변경됨';

  @override
  String get passwordRecovery => '비밀번호 복구';

  @override
  String get people => '사람들';

  @override
  String get pickImage => '이미지 고르기';

  @override
  String get pin => '고정';

  @override
  String play(Object fileName) {
    return '$fileName 재생';
  }

  @override
  String get pleaseChoose => '선택해주세요';

  @override
  String get pleaseChooseAPasscode => '비밀번호를 골라주세요';

  @override
  String get pleaseChooseAUsername => '유저 이름을 골라주세요';

  @override
  String get pleaseClickOnLink => '이메일의 링크를 클릭하고 진행해주세요.';

  @override
  String get pleaseEnter4Digits => '4자리 숫자를 입력하거나 앱 잠금을 사용하지 않도록 하려면 비워두세요.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Matrix ID를 입력해주세요.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => '비밀번호를 입력해주세요';

  @override
  String get pleaseEnterYourPin => 'PIN을 입력해주세요';

  @override
  String get pleaseEnterYourUsername => '유저 이름을 입력해주세요';

  @override
  String get pleaseFollowInstructionsOnWeb => '웹사이트의 가이드를 따르고 다음 버튼을 눌러주세요.';

  @override
  String get privacy => '프라이버시';

  @override
  String get publicRooms => '공개 방';

  @override
  String get pushRules => '푸시 규칙';

  @override
  String get reason => '이유';

  @override
  String get recording => '녹음';

  @override
  String redactedAnEvent(Object username) {
    return '$username이 이벤트를 지움';
  }

  @override
  String get redactMessage => '메시지 지우기';

  @override
  String get register => '가입';

  @override
  String get reject => '거절';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username이 초대를 거절함';
  }

  @override
  String get rejoin => '다시 가입';

  @override
  String get remove => '지우기';

  @override
  String get removeAllOtherDevices => '모든 다른 기기에서 지우기';

  @override
  String removedBy(Object username) {
    return '$username에 의해 지워짐';
  }

  @override
  String get removeDevice => '기기 삭제';

  @override
  String get unbanFromChat => '채팅에서 밴 해제';

  @override
  String get removeYourAvatar => '아바타 지우기';

  @override
  String get renderRichContent => '풍부한 메시지 콘텐츠 렌더링';

  @override
  String get replaceRoomWithNewerVersion => '방 새로운 버전으로 대체하기';

  @override
  String get reply => '답장';

  @override
  String get reportMessage => '메시지 신고';

  @override
  String get requestPermission => '권한 요청';

  @override
  String get roomHasBeenUpgraded => '방이 업그레이드되었습니다';

  @override
  String get roomVersion => '방 버전';

  @override
  String get saturday => '토요일';

  @override
  String get saveFile => '파일 저장';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => '보안';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyLost => 'Recovery key lost?';

  @override
  String seenByUser(Object username) {
    return '$username이 읽음';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$username과 이외 $count명이 읽음',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return '$username, $username2가 읽음';
  }

  @override
  String get send => '보내기';

  @override
  String get sendAMessage => '메시지 보내기';

  @override
  String get sendAsText => '텍스트로 보내기';

  @override
  String get sendAudio => '오디오 보내기';

  @override
  String get sendFile => '파일 보내기';

  @override
  String get sendImage => '이미지 보내기';

  @override
  String get sendMessages => '메시지 보내기';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => '원본 보내기';

  @override
  String get sendSticker => '스티커 보내기';

  @override
  String get sendVideo => '영상 보내기';

  @override
  String sentAFile(Object username) {
    return '$username이 파일 보냄';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username이 오디오 보냄';
  }

  @override
  String sentAPicture(Object username) {
    return '$username이 사진 보냄';
  }

  @override
  String sentASticker(Object username) {
    return '$username이 스티커 보냄';
  }

  @override
  String sentAVideo(Object username) {
    return '$username이 영상 보냄';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName 이 통화 정보 보냄';
  }

  @override
  String get separateChatTypes => 'Separate Direct Chats and Groups';

  @override
  String get setAsCanonicalAlias => '주 별명으로 설정';

  @override
  String get setCustomEmotes => '맞춤 이모트 설정';

  @override
  String get setGroupDescription => '그룹 설명 설정';

  @override
  String get setInvitationLink => '초대 링크 설정';

  @override
  String get setPermissionsLevel => '권한 레벨 설정';

  @override
  String get setStatus => '상태 설정';

  @override
  String get settings => '설정';

  @override
  String get share => '공유';

  @override
  String sharedTheLocation(Object username) {
    return '$username이 위치 공유함';
  }

  @override
  String get shareLocation => '위치 보내기';

  @override
  String get showDirectChatsInSpaces => 'Show related Direct Chats in Spaces';

  @override
  String get showPassword => '비밀번호 보이기';

  @override
  String get signUp => '가입';

  @override
  String get singlesignon => '단일 계정 로그인(SSO)';

  @override
  String get skip => '스킵';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => '소스 코드';

  @override
  String get spaceIsPublic => '스페이스가 공개됨';

  @override
  String get spaceName => '스페이스 이름';

  @override
  String startedACall(Object senderName) {
    return '$senderName 가 통화 시작함';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => '상태';

  @override
  String get statusExampleMessage => '오늘은 어떤 기분인가요?';

  @override
  String get submit => '제출';

  @override
  String get sunday => '일요일';

  @override
  String get synchronizingPleaseWait => '동기화 중... 기다려주세요.';

  @override
  String get systemTheme => '시스템';

  @override
  String get theyDontMatch => '일치하지 않습니다';

  @override
  String get theyMatch => '일치합니다';

  @override
  String get thisRoomHasBeenArchived => '이 방은 보관되었습니다.';

  @override
  String get thursday => '목요일';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => '즐겨찾기 토글';

  @override
  String get toggleMuted => '음소거 토글';

  @override
  String get toggleUnread => '메시지 안/읽음 으로 표시';

  @override
  String get tooManyRequestsWarning => '너무 많은 요청. 잠시 후에 다시 시도해주세요!';

  @override
  String get transferFromAnotherDevice => '다른 기기에서 가져오기';

  @override
  String get tryToSendAgain => '다시 보내도록 시도';

  @override
  String get tuesday => '화요일';

  @override
  String get unavailable => '사용할 수 없음';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username이 $targetName 밴 해제함';
  }

  @override
  String get unblockDevice => '기기 차단 해제';

  @override
  String get unknownDevice => '알 수 없는 기기';

  @override
  String get unknownEncryptionAlgorithm => '알 수 없는 암호화 알고리즘';

  @override
  String unknownEvent(Object type, Object tipo) {
    return '알 수 없는 이벤트 \'$type\'';
  }

  @override
  String get unmuteChat => '음소거 해제';

  @override
  String get unpin => '고정 해제';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount 개',
      one: '읽지 않은 채팅 1',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username과 $count명이 입력 중';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username과 $username2가 입력 중';
  }

  @override
  String userIsTyping(Object username) {
    return '$username이 입력 중';
  }

  @override
  String userLeftTheChat(Object username) {
    return '$username이 채팅을 나감';
  }

  @override
  String get username => '유저 이름';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username이 $type 이벤트 보냄';
  }

  @override
  String get unverified => '확인되지 않음';

  @override
  String get verified => '확인됨';

  @override
  String get verify => '확인';

  @override
  String get verifyStart => '확인 시작';

  @override
  String get verifySuccess => '성공적으로 확인했어요!';

  @override
  String get verifyTitle => '다른 계정 확인 중';

  @override
  String get videoCall => '영상 통화';

  @override
  String get visibilityOfTheChatHistory => '대화 기록 설정';

  @override
  String get visibleForAllParticipants => '모든 참가자에게 보임';

  @override
  String get visibleForEveryone => '모두에게 보임';

  @override
  String get voiceMessage => '음성 메시지';

  @override
  String get waitingPartnerAcceptRequest => '상대가 요청을 수락하길 기다리는 중…';

  @override
  String get waitingPartnerEmoji => '상대가 이모지를 수락하길 기다리는 중…';

  @override
  String get waitingPartnerNumbers => '상대가 숫자를 수락하길 기다리는 중…';

  @override
  String get wallpaper => '배경';

  @override
  String get warning => '경고!';

  @override
  String get wednesday => '수요일';

  @override
  String get weSentYouAnEmail => '우리가 당신에게 이메일을 보냈습니다';

  @override
  String get whoCanPerformWhichAction => '누가 어떤 행동을 할 수 있는지';

  @override
  String get whoIsAllowedToJoinThisGroup => '누가 이 그룹에 들어오도록 허용할지';

  @override
  String get whyDoYouWantToReportThis => '왜 이것을 신고하려고 하나요?';

  @override
  String get wipeChatBackup => '새로운 보안 키를 생성하기 위해 채팅 백업을 초기화할까요?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      '이 주소로 당신의 비밀번호를 복구할 수 있습니다.';

  @override
  String get writeAMessage => '메시지 작성…';

  @override
  String get yes => '확인';

  @override
  String get you => '당신';

  @override
  String get youAreInvitedToThisChat => '당신은 이 채팅에 초대되었습니다';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      '당신은 더 이상 이 채팅에 참여하지 않습니다';

  @override
  String get youCannotInviteYourself => '자신을 초대할 수 없습니다';

  @override
  String get youHaveBeenBannedFromThisChat => '당신은 이 채팅에서 밴되었습니다';

  @override
  String get yourPublicKey => '당신의 공개 키';

  @override
  String get messageInfo => '메시지 정보';

  @override
  String get time => '시간';

  @override
  String get messageType => '메시지 유형';

  @override
  String get sender => '발신자';

  @override
  String get openGallery => '갤러리 열기';

  @override
  String get removeFromSpace => '스페이스에서 삭제';

  @override
  String get addToSpaceDescription => '이 채팅을 추가할 스페이스를 선택하세요.';

  @override
  String get start => '시작';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'To unlock your old messages, please enter your recovery key that has been generated in a previous session. Your recovery key is NOT your password.';

  @override
  String get addToStory => '스토리에 추가';

  @override
  String get publish => '공개';

  @override
  String get whoCanSeeMyStories => '누가 내 스토리를 볼 수 있나요?';

  @override
  String get unsubscribeStories => '스토리 구독 해제';

  @override
  String get thisUserHasNotPostedAnythingYet => '이 유저는 스토리에 아무것도 올리지 않았습니다';

  @override
  String get yourStory => '내 스토리';

  @override
  String get replyHasBeenSent => '답장을 보냈습니다';

  @override
  String videoWithSize(Object size) {
    return '영상 ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return '$date의 스토리:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc => '스토리에서 사람들이 서로를 보고 연락할 수 있다는 점에 유의하십시오.';

  @override
  String get whatIsGoingOn => '무슨 일이 일어나고 있나요?';

  @override
  String get addDescription => '설명 추가';

  @override
  String get storyPrivacyWarning =>
      '사람들이 서로를 보고 연락할 수 있다는 점에 유의해주세요. 스토리는 24시간 동안 보이지만 모든 기기와 서버에서 삭제된다는 보장은 없습니다.';

  @override
  String get iUnderstand => '동의합니다';

  @override
  String get openChat => '채팅 열기';

  @override
  String get markAsRead => '읽음으로 표시하기';

  @override
  String get reportUser => '사용자 신고';

  @override
  String get dismiss => '닫기';

  @override
  String get matrixWidgets => 'Matrix 위젯';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender가 $reaction로 반응함';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin => '이벤트를 영구적으로 고정 해제할 것이 확실한가요?';

  @override
  String get emojis => '이모지';

  @override
  String get placeCall => '전화 걸기';

  @override
  String get voiceCall => '음성 통화';

  @override
  String get unsupportedAndroidVersion => '지원되지 않는 안드로이드 버전';

  @override
  String get unsupportedAndroidVersionLong =>
      '이 기능은 새로운 안드로이드 버전을 요구합니다. Lineage OS 지원이나 업데이트를 확인해주세요.';

  @override
  String get videoCallsBetaWarning =>
      '영상 통화는 베타임을 확인해주세요. 의도한 대로 작동하지 않거나 모든 플랫폼에서 작동하지 않을 수 있습니다.';

  @override
  String get experimentalVideoCalls => '실험적인 영상 통화';

  @override
  String get emailOrUsername => '이메일이나 유저 이름';

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
  String get search => '검색';

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
