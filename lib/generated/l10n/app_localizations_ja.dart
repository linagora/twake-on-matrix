// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class L10nJa extends L10n {
  L10nJa([String locale = 'ja']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません!';

  @override
  String get pleaseEnterValidEmail => '正しいメールアドレスを入力してください。';

  @override
  String get repeatPassword => 'パスワードを繰り返そ';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return '少なくとも$min文字を選択してください。';
  }

  @override
  String get about => 'このアプリについて';

  @override
  String get updateAvailable => 'FluffyChatのアップデートが利用可能';

  @override
  String get updateNow => 'バックグラウンドでアップデートを開始';

  @override
  String get accept => '承諾する';

  @override
  String acceptedTheInvitation(Object username) {
    return '👍$usernameが招待を承諾しました';
  }

  @override
  String get account => 'アカウント';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '🔐$usernameがエンドツーエンド暗号化を有効にしました';
  }

  @override
  String get addEmail => 'Eメールを追加';

  @override
  String get confirmMatrixId => 'アカウントを削除するには、Matrix IDを確認してください。';

  @override
  String supposedMxid(Object mxid) {
    return 'This should be $mxid';
  }

  @override
  String get addGroupDescription => 'グループの説明を追加する';

  @override
  String get addToSpace => 'スペースに追加';

  @override
  String get admin => '管理者';

  @override
  String get alias => 'エイリアス';

  @override
  String get all => 'すべて';

  @override
  String get allChats => 'すべて会話';

  @override
  String get commandHint_googly => 'ぎょろ目を送る';

  @override
  String get commandHint_cuddle => 'Send a cuddle';

  @override
  String get commandHint_hug => 'ハグを送る';

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
    return '$senderNameは通話に出ました';
  }

  @override
  String get anyoneCanJoin => '誰でも参加できる';

  @override
  String get appLock => 'アプリのロック';

  @override
  String get archive => 'アーカイブ';

  @override
  String get archivedRoom => 'アーカイブされた部屋';

  @override
  String get areGuestsAllowedToJoin => 'ゲストユーザーの参加を許可する';

  @override
  String get areYouSure => 'これでよろしいですか？';

  @override
  String get areYouSureYouWantToLogout => 'ログアウトしてよろしいですか？';

  @override
  String get askSSSSSign => '他の人を署名するためにはパスフレーズやリカバリーキーを入力してください。';

  @override
  String askVerificationRequest(Object username) {
    return '$usernameの検証リクエストを承認しますか？';
  }

  @override
  String get autoplayImages => 'GIFを自動的に再生する';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'ホームサーバーでサポートされているログインタイプ：\n$serverVersions\nアプリがサポートしているログインタイプ：\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Enterで送信';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'ホームサーバーでサポートされているバージョン：\n$serverVersions\nアプリでは$supportedVersionsしかサポートされていません';
  }

  @override
  String get banFromChat => 'チャットからBANする';

  @override
  String get banned => 'BANされています';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$usernameが$targetNameをBANしました';
  }

  @override
  String get blockDevice => 'デバイスをブロックする';

  @override
  String get blocked => 'ブロックしました';

  @override
  String get botMessages => 'ボットメッセージ';

  @override
  String get bubbleSize => 'ふきだしの大きさ';

  @override
  String get cancel => 'キャンセル';

  @override
  String cantOpenUri(Object uri) {
    return 'URIが開けません $uri';
  }

  @override
  String get changeDeviceName => 'デバイス名を変更';

  @override
  String changedTheChatAvatar(Object username) {
    return '$usernameがチャットアバターを変更しました';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$usernameがチャットの説明を「$description」に変更しました';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$usernameがチャットの名前を「$chatname」に変更しました';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$usernameがチャットの権限を変更しました';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$usernameが表示名を「$displayname」に変更しました';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$usernameがゲストのアクセスルールを変更しました';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$usernameがゲストのアクセスルールを$rulesに変更しました';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$usernameが履歴の表示設定を変更しました';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$usernameが履歴の表示設定を$rulesに変更しました';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$usernameが参加ルールを変更しました';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$usernameが参加ルールを$joinRulesに変更しました';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$usernameがアバターを変更しました';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$usernameが部屋のエイリアスを変更しました';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$usernameが招待リンクを変更しました';
  }

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String get changeTheHomeserver => 'ホームサーバーの変更';

  @override
  String get changeTheme => 'スタイルを変更する';

  @override
  String get changeTheNameOfTheGroup => 'グループの名前を変更する';

  @override
  String get changeWallpaper => '壁紙を変更する';

  @override
  String get changeYourAvatar => 'アバタるを変化しする';

  @override
  String get channelCorruptedDecryptError => '暗号が破損しています';

  @override
  String get chat => 'チャット';

  @override
  String get yourUserId => 'あなたのユーザーID:';

  @override
  String get yourChatBackupHasBeenSetUp => 'チャットバックアップを設定ました。';

  @override
  String get chatBackup => 'チャットのバックアップ';

  @override
  String get chatBackupDescription => '古いメッセージはリカバリーキーで保護されます。紛失しないようにご注意ください。';

  @override
  String get chatDetails => 'チャットの詳細';

  @override
  String get chatHasBeenAddedToThisSpace => 'このスペースにチャットが追加されました';

  @override
  String get chats => 'チャット';

  @override
  String get chooseAStrongPassword => '強いパスワードを選択してください';

  @override
  String get chooseAUsername => 'ユーザー名を選択してください';

  @override
  String get clearArchive => 'アーカイブを消去';

  @override
  String get close => '閉じる';

  @override
  String get commandHint_markasdm => 'ダイレクトメッセージの部屋としてマークする';

  @override
  String get commandHint_markasgroup => 'グループとしてマーク';

  @override
  String get commandHint_ban => 'このユーザーを禁止する';

  @override
  String get commandHint_clearcache => 'キャッシュをクリアする';

  @override
  String get commandHint_create =>
      '空のグループチャットを作成\n暗号化を無効にするには、--no-encryption を使用';

  @override
  String get commandHint_discardsession => 'セッションを破棄';

  @override
  String get commandHint_dm =>
      'ダイレクトチャットを開始する\n暗号化を無効にするには、--no-encryptionを使用してください';

  @override
  String get commandHint_html => 'HTML形式のテキストを送信';

  @override
  String get commandHint_invite => '指定したユーザーをこの部屋に招待';

  @override
  String get commandHint_join => '指定した部屋に参加';

  @override
  String get commandHint_kick => 'Remove the given user from this chat';

  @override
  String get commandHint_leave => 'この部屋を退出';

  @override
  String get commandHint_me => 'Describe yourself';

  @override
  String get commandHint_myroomavatar => 'この部屋の写真を設定する (mxc-uriで)';

  @override
  String get commandHint_myroomnick => 'この部屋の表示名を設定する';

  @override
  String get commandHint_op =>
      'Set the given user\'s power level (default: 50)';

  @override
  String get commandHint_plain => '書式設定されていないテキストを送信する';

  @override
  String get commandHint_react => 'リアクションとして返信を送信する';

  @override
  String get commandHint_send => 'テキストを送信';

  @override
  String get commandHint_unban => 'Unban the given user from this chat';

  @override
  String get commandInvalid => 'コマンドが無効';

  @override
  String commandMissing(Object command) {
    return '$command はコマンドではありません。';
  }

  @override
  String get compareEmojiMatch => '表示されている絵文字が他のデバイスで表示されているものと一致するか確認してください:';

  @override
  String get compareNumbersMatch => '表示されている数字が他のデバイスで表示されているものと一致するか確認してください:';

  @override
  String get configureChat => 'チャットの設定';

  @override
  String get confirm => '確認';

  @override
  String get connect => '接続';

  @override
  String get contactHasBeenInvitedToTheGroup => '連絡先に登録された人が招待されました';

  @override
  String get containsDisplayName => '表示名を含んでいます';

  @override
  String get containsUserName => 'ユーザー名を含んでいます';

  @override
  String get contentHasBeenReported => 'サーバー管理者に通報されました';

  @override
  String get copiedToClipboard => 'クリップボードにコピーされました';

  @override
  String get copy => 'コピー';

  @override
  String get copyToClipboard => 'クリップボードにコピー';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'メッセージを解読できませんでした: $error';
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
  String get create => '作成';

  @override
  String createdTheChat(Object username) {
    return '💬 $usernameがチャットを作成しました';
  }

  @override
  String get createNewGroup => 'グループを作成する';

  @override
  String get createNewSpace => '新しいスペース';

  @override
  String get crossSigningEnabled => '相互署名ON';

  @override
  String get currentlyActive => '現在アクティブです';

  @override
  String get darkTheme => 'ダーク';

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
    return '$year/$month/$day';
  }

  @override
  String get deactivateAccountWarning =>
      'あなたのアカウントを無効化します。この操作は元に戻せません！よろしいですか？';

  @override
  String get defaultPermissionLevel => 'デフォルトの権限レベル';

  @override
  String get delete => '削除';

  @override
  String get deleteAccount => 'アカウントの削除';

  @override
  String get deleteMessage => 'メッセージの削除';

  @override
  String get deny => '拒否';

  @override
  String get device => 'デバイス';

  @override
  String get deviceId => 'デバイスID';

  @override
  String get devices => 'デバイス';

  @override
  String get directChats => 'ダイレクトチャット';

  @override
  String get discover => '発見する';

  @override
  String get displaynameHasBeenChanged => '表示名が変更されました';

  @override
  String get download => 'Download';

  @override
  String get edit => '編集';

  @override
  String get editBlockedServers => 'ブロックしたサーバーを編集';

  @override
  String get editChatPermissions => 'チャット権限の変更';

  @override
  String get editDisplayname => '表示名を編集';

  @override
  String get editRoomAliases => 'ルームエイリアスを編集';

  @override
  String get editRoomAvatar => '部屋のアバターを編集する';

  @override
  String get emoteExists => 'Emoteはすでに存在します！';

  @override
  String get emoteInvalid => '不正なEmoteショートコード！';

  @override
  String get emotePacks => '部屋のEmoteパック';

  @override
  String get emoteSettings => 'Emote設定';

  @override
  String get emoteShortcode => 'Emoteショートコード';

  @override
  String get emoteWarnNeedToPick => 'Emoteショートコードと画像を選択してください！';

  @override
  String get emptyChat => '空のチャット';

  @override
  String get enableEmotesGlobally => 'emoteをグローバルに有効にする';

  @override
  String get enableEncryption => '暗号化を有効にする';

  @override
  String get enableEncryptionWarning => '一度暗号化を有効にするともとに戻せません。よろしいですか？';

  @override
  String get encrypted => '暗号化';

  @override
  String get encryption => '暗号化';

  @override
  String get encryptionNotEnabled => '暗号化されていません';

  @override
  String endedTheCall(Object senderName) {
    return '$senderNameは通話を切断しました';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'メールアドレスを入力してください';

  @override
  String get enterASpacepName => 'スペース名を入力してください';

  @override
  String get homeserver => 'ホームサーバー';

  @override
  String get enterYourHomeserver => 'ホームサーバーを入力してください';

  @override
  String errorObtainingLocation(Object error) {
    return '位置情報の取得中にエラーが発生しました: $error';
  }

  @override
  String get everythingReady => 'すべての準備は完了しました！';

  @override
  String get extremeOffensive => 'とても攻撃的';

  @override
  String get fileName => 'ファイル名';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'フォントサイズ';

  @override
  String get forward => '進む';

  @override
  String get friday => '金曜日';

  @override
  String get fromJoining => '参加時点から閲覧可能';

  @override
  String get fromTheInvitation => '招待時点から閲覧可能';

  @override
  String get goToTheNewRoom => '新規ルームへ';

  @override
  String get group => 'グループ';

  @override
  String get groupDescription => 'グループの説明';

  @override
  String get groupDescriptionHasBeenChanged => 'グループの説明が変更されました';

  @override
  String get groupIsPublic => 'グループは公開されています';

  @override
  String get groups => 'グループ';

  @override
  String groupWith(Object displayname) {
    return '$displaynameとグループを作成する';
  }

  @override
  String get guestsAreForbidden => 'ゲストは許可されていません';

  @override
  String get guestsCanJoin => 'ゲストが許可されています';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$targetNameの招待を$usernameが取り下げました';
  }

  @override
  String get help => 'ヘルプ';

  @override
  String get hideRedactedEvents => '編集済みイベントを非表示にする';

  @override
  String get hideUnknownEvents => '不明なイベントを非表示にする';

  @override
  String get howOffensiveIsThisContent => 'どのくらい攻撃的でしたか？';

  @override
  String get id => 'ID';

  @override
  String get identity => 'アイデンティティ';

  @override
  String get ignore => '無視する';

  @override
  String get ignoredUsers => '無視されたユーザー';

  @override
  String get ignoreListDescription =>
      'ユーザーは無視することができます。無視したユーザーからのメッセージやルームの招待は受け取れません。';

  @override
  String get ignoreUsername => 'ユーザー名を無視する';

  @override
  String get iHaveClickedOnLink => 'リンクをクリックしました';

  @override
  String get incorrectPassphraseOrKey => 'パスフレーズかリカバリーキーが間違っています';

  @override
  String get inoffensive => '非攻撃的';

  @override
  String get inviteContact => '連絡先から招待する';

  @override
  String inviteContactToGroup(Object groupName) {
    return '連絡先から$groupNameに招待する';
  }

  @override
  String get invited => '招待されました';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩 $username が $targetName を招待しました';
  }

  @override
  String get invitedUsersOnly => '招待されたユーザーのみ';

  @override
  String get inviteForMe => '自分への招待';

  @override
  String inviteText(Object username, Object link) {
    return '$usernameがFluffyChatにあなたを招待しました. \n1. FluffyChatをインストールしてください: https://fluffychat.im \n2. 新しくアカウントを作成するかサインインしてください\n3. 招待リンクを開いてください: $link';
  }

  @override
  String get isTyping => 'が入力しています';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username がチャットに参加しました';
  }

  @override
  String get joinRoom => '部屋に参加';

  @override
  String get keysCached => '鍵はキャッシュされたいます';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username は $targetName をキックしました';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username が $targetName をキックしブロックしました';
  }

  @override
  String get kickFromChat => 'チャットからキックする';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return '最終アクティブ: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'ずいぶん前';

  @override
  String get leave => '退室する';

  @override
  String get leftTheChat => '退室しました';

  @override
  String get license => 'ライセンス';

  @override
  String get lightTheme => 'ライト';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'あと$count名参加者を読み込む';
  }

  @override
  String get dehydrate => 'セッションのエクスポートとデバイスの消去';

  @override
  String get dehydrateWarning => 'この操作は元に戻せません。バックアップファイルを安全に保存してください。';

  @override
  String get dehydrateShare =>
      'これはあなたの非公開の FluffyChat エクスポートです。なくさないようにして、公開せず保管してください。';

  @override
  String get dehydrateTor => 'TOR ユーザー: セッションをエクスポート';

  @override
  String get dehydrateTorLong =>
      'TOR ユーザーの場合、ウィンドウを閉じる前にセッションをエクスポートすることをお勧めします。';

  @override
  String get hydrateTor => 'TOR ユーザー: セッションのエクスポートをインポート';

  @override
  String get hydrateTorLong =>
      '前回、TOR でセッションをエクスポートしましたか？すぐにインポートしてチャットを続けましょう。';

  @override
  String get hydrate => 'バックアップファイルから復元';

  @override
  String get loadingPleaseWait => '読み込み中…お待ちください。';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => '更に読み込む…';

  @override
  String get locationDisabledNotice =>
      '位置情報サービスが無効になっています。位置情報を共有できるようにするには、位置情報サービスを有効にしてください。';

  @override
  String get locationPermissionDeniedNotice =>
      '位置情報の権限が拒否されました。位置情報を共有できるように許可してください。';

  @override
  String get login => 'ログイン';

  @override
  String logInTo(Object homeserver) {
    return '$homeserverにログインする';
  }

  @override
  String get loginWithOneClick => 'ワンクリックでサインイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get makeSureTheIdentifierIsValid => '識別子が正しいか確認してください';

  @override
  String get memberChanges => 'メンバーの変更';

  @override
  String get mention => 'メンション';

  @override
  String get messages => 'メッセージ';

  @override
  String get messageWillBeRemovedWarning => 'メッセージはすべての参加者から消去されます';

  @override
  String get noSearchResult => '一致する検索結果がありません。';

  @override
  String get moderator => 'モデレータ';

  @override
  String get monday => '月曜日';

  @override
  String get muteChat => 'チャットのミュート';

  @override
  String get needPantalaimonWarning =>
      '現時点では、エンドツーエンドの暗号化を使用するにはPantalaimonが必要であることに注意してください。';

  @override
  String get newChat => '新規チャット';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => '認証リクエスト！';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => '次へ';

  @override
  String get no => 'いいえ';

  @override
  String get noConnectionToTheServer => 'サーバーに接続できません';

  @override
  String get noEmotesFound => 'Emoteは見つかりませんでした😕';

  @override
  String get noEncryptionForPublicRooms => 'ルームを非公開にした後暗号化を有効にできます。';

  @override
  String get noGoogleServicesWarning =>
      'あなたのスマホにはGoogleサービスがないようですね。プライバシーを保護するための良い選択です！プッシュ通知を受け取るには https://microg.org/ または https://unifiedpush.org/ を使うことをお勧めします。';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 はMatrixのサーバーではありません。代わりに $server2 を使用しますか?';
  }

  @override
  String get shareYourInviteLink => '招待リンクを共有する';

  @override
  String get typeInInviteLinkManually => '招待リンクを手動で入力...';

  @override
  String get scanQrCode => 'QRコードをスキャン';

  @override
  String get none => 'なし';

  @override
  String get noPasswordRecoveryDescription => 'パスワードを回復する方法をまだ追加していません。';

  @override
  String get noPermission => '権限がありません';

  @override
  String get noRoomsFound => '部屋は見つかりませんでした…';

  @override
  String get notifications => '通知';

  @override
  String numUsersTyping(Object count) {
    return '$count人が入力中';
  }

  @override
  String get obtainingLocation => '位置情報を取得しています…';

  @override
  String get offensive => '攻撃的';

  @override
  String get offline => 'オフライン';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'OK';

  @override
  String get online => 'オンライン';

  @override
  String get onlineKeyBackupEnabled => 'オンライン鍵バックアップは使用されています';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError => 'おっと！残念ながら、プッシュ通知の設定中にエラーが発生しました。';

  @override
  String get oopsSomethingWentWrong => 'おっと、何かがうまくいきませんでした…';

  @override
  String get openAppToReadMessages => 'アプリを開いてメッセージを確認してください';

  @override
  String get openCamera => 'カメラを開く';

  @override
  String get openVideoCamera => 'ビデオ用にカメラを開く';

  @override
  String get oneClientLoggedOut => 'クライアントの 1つがログアウトしました';

  @override
  String get addAccount => 'アカウントを追加';

  @override
  String get editBundlesForAccount => 'このアカウントのバンドルを編集';

  @override
  String get addToBundle => 'バンドルに追加';

  @override
  String get removeFromBundle => 'このバンドルから削除';

  @override
  String get bundleName => 'バンドル名';

  @override
  String get enableMultiAccounts => '(ベータ版) このデバイスで複数のアカウントを有効にする';

  @override
  String get openInMaps => 'Open in maps';

  @override
  String get link => 'リンク';

  @override
  String get serverRequiresEmail => 'このサーバーは、登録のためにメールアドレスを検証する必要があります。';

  @override
  String get optionalGroupName => '(任意)グループ名';

  @override
  String get or => 'または';

  @override
  String get participant => '参加者';

  @override
  String get passphraseOrKey => 'パスフレーズかリカバリーキー';

  @override
  String get password => 'パスワード';

  @override
  String get passwordForgotten => 'パスワードを忘れた';

  @override
  String get passwordHasBeenChanged => 'パスワードが変更されました';

  @override
  String get passwordRecovery => 'パスワードリカバリー';

  @override
  String get people => '人々';

  @override
  String get pickImage => '画像を選択してください';

  @override
  String get pin => 'ピン';

  @override
  String play(Object fileName) {
    return '$fileNameを再生する';
  }

  @override
  String get pleaseChoose => '選択してください';

  @override
  String get pleaseChooseAPasscode => 'パスコードを選んでください';

  @override
  String get pleaseChooseAUsername => 'ユーザー名を選択してください';

  @override
  String get pleaseClickOnLink => 'メールのリンクから進めてください。';

  @override
  String get pleaseEnter4Digits => 'アプリのロック用に4桁の数字を入力してください。空欄の場合は無効になります。';

  @override
  String get pleaseEnterAMatrixIdentifier => 'マトリックスIDを入力してください。';

  @override
  String get pleaseEnterRecoveryKey => 'リカバリーキーを入力してください。';

  @override
  String get pleaseEnterYourPassword => 'パスワードを入力してください';

  @override
  String get pleaseEnterYourPin => 'PINを入力してください';

  @override
  String get pleaseEnterYourUsername => 'ユーザー名を入力してください';

  @override
  String get pleaseFollowInstructionsOnWeb => 'ウェブサイトにあるやり方を見てから次をタップしてください。';

  @override
  String get privacy => 'プライバシー';

  @override
  String get publicRooms => '公開された部屋';

  @override
  String get pushRules => 'ルールを追加する';

  @override
  String get reason => '理由';

  @override
  String get recording => '録音中';

  @override
  String redactedAnEvent(Object username) {
    return '$usernameがイベントを編集しました';
  }

  @override
  String get redactMessage => 'メッセージを書く';

  @override
  String get register => '登録';

  @override
  String get reject => '拒否';

  @override
  String rejectedTheInvitation(Object username) {
    return '$usernameは招待を拒否しました';
  }

  @override
  String get rejoin => '再参加';

  @override
  String get remove => '消去';

  @override
  String get removeAllOtherDevices => '他のデバイスをすべて削除';

  @override
  String removedBy(Object username) {
    return '$usernameによって削除されました';
  }

  @override
  String get removeDevice => 'デバイスの削除';

  @override
  String get unbanFromChat => 'チャットからのブロックを解除する';

  @override
  String get removeYourAvatar => 'アバターを削除する';

  @override
  String get renderRichContent => 'リッチメッセージをレンダリングする';

  @override
  String get replaceRoomWithNewerVersion => '部屋を新しいバージョンに変更する';

  @override
  String get reply => '返信';

  @override
  String get reportMessage => 'メッセージを通報';

  @override
  String get requestPermission => '権限を要求する';

  @override
  String get roomHasBeenUpgraded => '部屋はアップグレードされました';

  @override
  String get roomVersion => 'ルームバージョン';

  @override
  String get saturday => '土曜日';

  @override
  String get saveFile => 'ファイルを保存';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'セキュリティ';

  @override
  String get recoveryKey => 'リカバリーキー';

  @override
  String get recoveryKeyLost => 'リカバリーキーを紛失した場合';

  @override
  String seenByUser(Object username) {
    return '$usernameが既読';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$usernameと他$count名が既読',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return '$usernameと$username2が既読';
  }

  @override
  String get send => '送信';

  @override
  String get sendAMessage => 'メッセージを送信';

  @override
  String get sendAsText => 'テキストとして送信';

  @override
  String get sendAudio => '音声の送信';

  @override
  String get sendFile => 'ファイルを送信';

  @override
  String get sendImage => '画像の送信';

  @override
  String get sendMessages => 'メッセージを送る';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'オリジナルの送信';

  @override
  String get sendSticker => 'ステッカーを送る';

  @override
  String get sendVideo => '動画を送信';

  @override
  String sentAFile(Object username) {
    return '📁 $usernameはファイルを送信しました';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $usernameは音声を送信しました';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $usernameは画像を送信しました';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $usernameはステッカーを送信しました';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $usernameは動画を送信しました';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderNameは通話情報を送信しました';
  }

  @override
  String get separateChatTypes => 'Separate Direct Chats and Groups';

  @override
  String get setAsCanonicalAlias => 'メインエイリアスに設定';

  @override
  String get setCustomEmotes => 'カスタムエモートの設定';

  @override
  String get setGroupDescription => 'グループの説明を設定する';

  @override
  String get setInvitationLink => '招待リンクを設定する';

  @override
  String get setPermissionsLevel => '権限レベルをセット';

  @override
  String get setStatus => 'ステータスの設定';

  @override
  String get settings => '設定';

  @override
  String get share => '共有';

  @override
  String sharedTheLocation(Object username) {
    return '$usernameは現在地を共有しました';
  }

  @override
  String get shareLocation => '位置情報の共有';

  @override
  String get showDirectChatsInSpaces => '関連するダイレクトチャットをスペースに表示する';

  @override
  String get showPassword => 'パスワードを表示';

  @override
  String get signUp => 'サインアップ';

  @override
  String get singlesignon => 'シングルサインオン';

  @override
  String get skip => 'スキップ';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get spaceIsPublic => 'スペースは公開されています';

  @override
  String get spaceName => 'スペース名';

  @override
  String startedACall(Object senderName) {
    return '$senderNameは通話を開始しました';
  }

  @override
  String get startFirstChat => '最初のチャットを開始する';

  @override
  String get status => 'ステータス';

  @override
  String get statusExampleMessage => 'お元気ですか？';

  @override
  String get submit => '送信';

  @override
  String get sunday => '日曜日';

  @override
  String get synchronizingPleaseWait => '同期中...お待ちください。';

  @override
  String get systemTheme => 'システム';

  @override
  String get theyDontMatch => '違います';

  @override
  String get theyMatch => '一致しています';

  @override
  String get thisRoomHasBeenArchived => 'この部屋はアーカイブされています。';

  @override
  String get thursday => '木曜日';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'お気に入り切り替え';

  @override
  String get toggleMuted => 'ミュート切り替え';

  @override
  String get toggleUnread => '既読/未読にマーク';

  @override
  String get tooManyRequestsWarning => 'リクエストが多すぎます。また後で試してみてください！';

  @override
  String get transferFromAnotherDevice => '違うデバイスから移行する';

  @override
  String get tryToSendAgain => '送信し直してみる';

  @override
  String get tuesday => '火曜日';

  @override
  String get unavailable => '不在';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$usernameが$targetNameのBANを解除しました';
  }

  @override
  String get unblockDevice => 'デバイスをブロック解除する';

  @override
  String get unknownDevice => '未知デバイス';

  @override
  String get unknownEncryptionAlgorithm => '未知の暗号化アルゴリズム';

  @override
  String unknownEvent(Object type, Object tipo) {
    return '未知のイベント\'$type\'';
  }

  @override
  String get unmuteChat => 'チャットをミュート解除する';

  @override
  String get unpin => 'ピンを外す';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount件の未読メッセージ',
      one: '1件の未読メッセージ',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$usernameと他$count名が入力しています';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$usernameと$username2が入力しています';
  }

  @override
  String userIsTyping(Object username) {
    return '$usernameが入力しています';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $usernameはチャットから退室しました';
  }

  @override
  String get username => 'ユーザー名';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$usernameは$typeイベントを送信しました';
  }

  @override
  String get unverified => '未検証';

  @override
  String get verified => '検証済み';

  @override
  String get verify => '確認';

  @override
  String get verifyStart => '確認を始める';

  @override
  String get verifySuccess => '確認が完了しました！';

  @override
  String get verifyTitle => '他のアカウントを確認中';

  @override
  String get videoCall => '音声通話';

  @override
  String get visibilityOfTheChatHistory => 'チャット履歴の表示';

  @override
  String get visibleForAllParticipants => 'すべての参加者が閲覧可能';

  @override
  String get visibleForEveryone => 'すべての人が閲覧可能';

  @override
  String get voiceMessage => 'ボイスメッセージ';

  @override
  String get waitingPartnerAcceptRequest => 'パートナーのリクエスト承諾待ちです...';

  @override
  String get waitingPartnerEmoji => 'パートナーの絵文字承諾待ちです...';

  @override
  String get waitingPartnerNumbers => 'パートナーの数字承諾待ちです…';

  @override
  String get wallpaper => '壁紙';

  @override
  String get warning => '警告！';

  @override
  String get wednesday => '水曜日';

  @override
  String get weSentYouAnEmail => 'あなたにメールを送信しました';

  @override
  String get whoCanPerformWhichAction => '誰がどの操作を実行できるか';

  @override
  String get whoIsAllowedToJoinThisGroup => '誰がこのチャットに入れますか';

  @override
  String get whyDoYouWantToReportThis => 'これを通報する理由';

  @override
  String get wipeChatBackup => 'チャットのバックアップを消去して、新しいリカバリーキーを作りますか？';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'これらのアドレスを使用すると、パスワードを回復することができます。';

  @override
  String get writeAMessage => 'メッセージを入力してください…';

  @override
  String get yes => 'はい';

  @override
  String get you => 'あなた';

  @override
  String get youAreInvitedToThisChat => 'チャットに招待されています';

  @override
  String get youAreNoLongerParticipatingInThisChat => 'あなたはもうこのチャットの参加者ではありません';

  @override
  String get youCannotInviteYourself => '自分自身を招待することはできません';

  @override
  String get youHaveBeenBannedFromThisChat => 'チャットからBANされてしまいました';

  @override
  String get yourPublicKey => 'あなたの公開鍵';

  @override
  String get messageInfo => 'メッセージの情報';

  @override
  String get time => '時間';

  @override
  String get messageType => 'メッセージの種類';

  @override
  String get sender => '送信者';

  @override
  String get openGallery => 'ギャラリーを開く';

  @override
  String get removeFromSpace => 'スペースから削除';

  @override
  String get addToSpaceDescription => 'このチャットを追加するスペースを選択してください。';

  @override
  String get start => '開始';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      '古いメッセージを解除するには、以前のセッションで生成されたリカバリーキーを入力してください。リカバリーキーはパスワードではありません。';

  @override
  String get addToStory => 'ストーリーに追加';

  @override
  String get publish => '公開';

  @override
  String get whoCanSeeMyStories => 'Who can see my stories?';

  @override
  String get unsubscribeStories => 'ストーリーの購読を解除する';

  @override
  String get thisUserHasNotPostedAnythingYet => 'このユーザーはまだストーリーに何も投稿していません';

  @override
  String get yourStory => 'あなたのストーリー';

  @override
  String get replyHasBeenSent => '返信が送信されました';

  @override
  String videoWithSize(Object size) {
    return 'ビデオ ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return '$dateからのストーリー:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'あなたのストーリーでは、人々がお互いを見て連絡を取ることができることに注意してください。';

  @override
  String get whatIsGoingOn => 'What is going on?';

  @override
  String get addDescription => '説明を追加';

  @override
  String get storyPrivacyWarning =>
      'あなたのストーリーでは、人々がお互いを見て連絡を取ることができることに注意してください。ストーリーは24時間表示されますが、すべてのデバイスとサーバーから削除されるという保証はありません。';

  @override
  String get iUnderstand => 'わかりました';

  @override
  String get openChat => 'チャットを開く';

  @override
  String get markAsRead => '既読にする';

  @override
  String get reportUser => 'ユーザーを報告';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get matrixWidgets => 'Matrixのウィジェット';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender が $reaction で反応しました';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin => 'イベントの固定を完全に解除してもよろしいですか？';

  @override
  String get emojis => '絵文字';

  @override
  String get placeCall => '電話をかける';

  @override
  String get voiceCall => '音声通話';

  @override
  String get unsupportedAndroidVersion => 'サポートされていないAndroidのバージョン';

  @override
  String get unsupportedAndroidVersionLong =>
      'この機能を利用するには、より新しいAndroidのバージョンが必要です。アップデートまたはLineage OSのサポートをご確認ください。';

  @override
  String get videoCallsBetaWarning =>
      'ビデオ通話は、現在ベータ版であることにご注意ください。すべてのプラットフォームで期待通りに動作しない、あるいはまったく動作しない可能性があります。';

  @override
  String get experimentalVideoCalls => '実験的なビデオ通話';

  @override
  String get emailOrUsername => 'メールアドレスまたはユーザー名';

  @override
  String get indexedDbErrorTitle => 'プライベートモードに関する問題';

  @override
  String get indexedDbErrorLong =>
      'The message storage is unfortunately not enabled in private mode by default.\nPlease visit\n - about:config\n - set dom.indexedDB.privateBrowsing.enabled to true\nOtherwise, it is not possible to run FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'アカウント $number に切り替える';
  }

  @override
  String get nextAccount => '次のアカウント';

  @override
  String get previousAccount => '前のアカウント';

  @override
  String get editWidgets => 'ウィジェットを編集';

  @override
  String get addWidget => 'ウィジェットを追加';

  @override
  String get widgetVideo => '動画';

  @override
  String get widgetEtherpad => 'Text note';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'カスタム';

  @override
  String get widgetName => '名称';

  @override
  String get widgetUrlError => '有効なURLではありません。';

  @override
  String get widgetNameError => '表示名を入力してください。';

  @override
  String get errorAddingWidget => 'ウィジェットの追加中にエラーが発生しました。';

  @override
  String get youRejectedTheInvitation => '招待を拒否しました';

  @override
  String get youJoinedTheChat => 'チャットに参加しました';

  @override
  String get youAcceptedTheInvitation => '👍 招待を承諾しました';

  @override
  String youBannedUser(Object user) {
    return '$user を禁止しました';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return '$user への招待を取り下げました';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 $user から招待されました';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 $user を招待しました';
  }

  @override
  String youKicked(Object user) {
    return '👞 $user をキックしました';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 $user をキックしてブロックしました';
  }

  @override
  String youUnbannedUser(Object user) {
    return '$user の禁止を解除しました';
  }

  @override
  String get noEmailWarning =>
      '有効なメールアドレスを入力してください。入力しないと、パスワードをリセットすることができなくなります。不要な場合は、もう一度ボタンをタップして続けてください。';

  @override
  String get stories => 'ストーリー';

  @override
  String get users => 'ユーザー';

  @override
  String get enableAutoBackups => '自動バックアップを有効にする';

  @override
  String get unlockOldMessages => '古いメッセージのロックを解除する';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription => 'このデバイスの安全なストレージにリカバリーキーを保存。';

  @override
  String get saveKeyManuallyDescription =>
      'Save this key manually by triggering the system share dialog or clipboard.';

  @override
  String get storeInAndroidKeystore => 'Android KeyStoreに保存する';

  @override
  String get storeInAppleKeyChain => 'Apple KeyChainに保存';

  @override
  String get storeSecurlyOnThisDevice => 'このデバイスに安全に保管する';

  @override
  String countFiles(Object count) {
    return '$count個のファイル';
  }

  @override
  String get user => 'ユーザー';

  @override
  String get custom => 'カスタム';

  @override
  String get foregroundServiceRunning => 'この通知は、フォアグラウンド サービスの実行中に表示されます。';

  @override
  String get screenSharingTitle => '画面共有';

  @override
  String get screenSharingDetail => 'FuffyChatで画面を共有しています';

  @override
  String get callingPermissions => '通話の権限';

  @override
  String get callingAccount => '通話アカウント';

  @override
  String get callingAccountDetails =>
      'Allows FluffyChat to use the native android dialer app.';

  @override
  String get appearOnTop => 'Appear on top';

  @override
  String get appearOnTopDetails =>
      'アプリをトップに表示できるようにする（すでに通話アカウントとしてFluffychatを設定している場合は必要ありません）';

  @override
  String get otherCallingPermissions => 'マイク、カメラ、その他FluffyChatの権限';

  @override
  String get whyIsThisMessageEncrypted => 'このメッセージが読めない理由';

  @override
  String get noKeyForThisMessage =>
      'This can happen if the message was sent before you have signed in to your account at this device.\n\nIt is also possible that the sender has blocked your device or something went wrong with the internet connection.\n\nAre you able to read the message on another session? Then you can transfer the message from it! Go to Settings > Devices and make sure that your devices have verified each other. When you open the room the next time and both sessions are in the foreground, the keys will be transmitted automatically.\n\nDo you not want to loose the keys when logging out or switching devices? Make sure that you have enabled the chat backup in the settings.';

  @override
  String get newGroup => '新しいグループ';

  @override
  String get newSpace => '新しいスペース';

  @override
  String get enterSpace => 'スペースに入る';

  @override
  String get enterRoom => '部屋に入る';

  @override
  String get allSpaces => 'すべてのスペース';

  @override
  String numChats(Object number) {
    return '$number チャット';
  }

  @override
  String get hideUnimportantStateEvents => '重要でない状態イベントを非表示にする';

  @override
  String get doNotShowAgain => '今後表示しない';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return '空のチャット (以前は $oldDisplayName)';
  }

  @override
  String get newSpaceDescription =>
      'Spaces allows you to consolidate your chats and build private or public communities.';

  @override
  String get encryptThisChat => 'このチャットを暗号化する';

  @override
  String get endToEndEncryption => 'エンドツーエンド暗号化';

  @override
  String get disableEncryptionWarning =>
      'セキュリティ上の理由から、以前は暗号化が有効だったチャットで暗号化を無効にすることはできません。';

  @override
  String get sorryThatsNotPossible => '申し訳ありません...それは不可能です';

  @override
  String get deviceKeys => 'デバイスキー:';

  @override
  String get letsStart => '始めましょう';

  @override
  String get enterInviteLinkOrMatrixId => '招待リンクまたはMatrixのIDを入力してください...';

  @override
  String get reopenChat => 'チャットを再開する';

  @override
  String get noBackupWarning =>
      '警告！チャットのバックアップを有効にしないと、暗号化されたメッセージにアクセスできなくなります。ログアウトする前に、まずチャットのバックアップを有効にすることを強くお勧めします。';

  @override
  String get noOtherDevicesFound => '他のデバイスが見つかりません';

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
  String get search => '検索';

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
