// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class L10nVi extends L10n {
  L10nVi([String locale = 'vi']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không đúng!';

  @override
  String get pleaseEnterValidEmail => 'Vui lòng nhập địa chỉ email hợp lệ.';

  @override
  String get repeatPassword => 'Lặp lại mật khẩu';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Vui lòng chọn tối thiểu $min kí tự.';
  }

  @override
  String get about => 'Giới thiệu';

  @override
  String get updateAvailable => 'Twake Chat có bản cập nhật mới';

  @override
  String get updateNow => 'Bắt đầu cập nhật dưới nền';

  @override
  String get accept => 'Đồng ý';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username đã đồng ý lời mời';
  }

  @override
  String get account => 'Tài khoản';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username đã kích hoạt mã hóa đầu cuối 2 chiều';
  }

  @override
  String get addEmail => 'Thêm email';

  @override
  String get confirmMatrixId =>
      'Vui lòng xác nhận Matrix ID để xóa tài khoản của bạn.';

  @override
  String supposedMxid(Object mxid) {
    return 'Nên là $mxid';
  }

  @override
  String get addGroupDescription => 'Thêm mô tả cho nhóm';

  @override
  String get addToSpace => 'Thêm vào khoảng trống';

  @override
  String get admin => 'Quản trị viên';

  @override
  String get alias => 'bí danh';

  @override
  String get all => 'Tất cả';

  @override
  String get allChats => 'Tất cả cuộc trò chuyện';

  @override
  String get commandHint_googly => 'Gửi đôi mắt ngây thơ';

  @override
  String get commandHint_cuddle => 'Ôm một cái';

  @override
  String get commandHint_hug => 'Ôm một cái';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName gửi bạn đôi mắt ngây thơ';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName ôm bạn';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName ôm bạn';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName đã trả lời cuộc gọi';
  }

  @override
  String get anyoneCanJoin => 'Mọi người đều có thể gia nhập';

  @override
  String get appLock => 'Khóa ứng dụng';

  @override
  String get archive => 'Lưu trữ';

  @override
  String get archivedRoom => 'Phòng hội thảo đã lưu trữ';

  @override
  String get areGuestsAllowedToJoin => 'Khách vãng lai có được tham gia không';

  @override
  String get areYouSure => 'Bạn chắc chứ?';

  @override
  String get areYouSureYouWantToLogout =>
      'Bạn có chắc bạn muốn đăng xuất không?';

  @override
  String get askSSSSSign =>
      'Để có thể ký tên cho người khác, vui lòng nhập mật khẩu bảo mật cửa hàng hoặc khóa khôi phục của bạn.';

  @override
  String askVerificationRequest(Object username) {
    return 'Bạn có đồng ý yêu cầu chứng thực từ $username không?';
  }

  @override
  String get autoplayImages =>
      'Tự động chạy nhãn dán động và biểu tượng cảm xúc';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Máy chủ nhà hỗ trợ kiểu đăng nhập:\n$serverVersions\nNhưng ứng dụng này chỉ hỗ trợ:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Gửi khi nhập';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Máy chủ hỗ trợ Spec phiên bản:\n$serverVerions\nNhưng ứng dụng này chỉ hỗ trợ $supportedVersions';
  }

  @override
  String get banFromChat => 'Cấm khỏi cuộc trò chuyện';

  @override
  String get banned => 'Đã bị cấm';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username đã cấm $targetName';
  }

  @override
  String get blockDevice => 'Thiết bị bị chặn';

  @override
  String get blocked => 'Đã chặn';

  @override
  String get botMessages => 'Tin nhắn tự động';

  @override
  String get bubbleSize => 'Kích cỡ tin nhắn';

  @override
  String get cancel => 'Hủy';

  @override
  String cantOpenUri(Object uri) {
    return 'Không thể mở URI $uri';
  }

  @override
  String get changeDeviceName => 'Thay đổi tên thiết bị';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username đã thay đổi ảnh phòng chat';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username đã thay đổi mô tả phòng chat thành: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username đã thay đổi tên phòng chat thành: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username đã thay đổi quyền trong phòng chat';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username đã thay đổi tên hiển thị thành: \'$displayname\'';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username đã thay đổi quy tắc truy cập đối với khách';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username đã thay đổi quy tắc truy cập đối với khách thành: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username đã thay đổi chế độ hiển thị lịch sử';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username đã thay đổi chế độ hiển thị lịch sử thành: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username đã thay đổi quy tắc tham gia';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username đã thay đổi quy tắc tham gia thành: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username đã thay đổi ảnh đại diện của mình';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username đã đổi địa chỉ phòng chat';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username đã thay đổi đường dẫn mời';
  }

  @override
  String get changePassword => 'Thay đổi mật khẩu';

  @override
  String get changeTheHomeserver => 'Thay đổi máy chủ nhà';

  @override
  String get changeTheme => 'Thay đổi phong cách của bạn';

  @override
  String get changeTheNameOfTheGroup => 'Thay đổi tên nhóm';

  @override
  String get changeWallpaper => 'Thay hình nền';

  @override
  String get changeYourAvatar => 'Thay đổi ảnh đại diện';

  @override
  String get channelCorruptedDecryptError => 'Mã hóa hỏng';

  @override
  String get chat => 'Chat';

  @override
  String get yourUserId => 'ID của bạn:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'Bản sao lưu trò chuyện đã được thiết lập.';

  @override
  String get chatBackup => 'Sao lưu cuộc trò chuyện';

  @override
  String get chatBackupDescription =>
      'Bản sao lưu cuộc trò chuyện của bạn được bảo mật bằng một khoá bảo mật. Bạn đừng làm mất nó.';

  @override
  String get chatDetails => 'Chi tiết cuộc trò chuyện';

  @override
  String get chatHasBeenAddedToThisSpace => 'Cuộc trò chuyện đã được thêm vào';

  @override
  String get chats => 'Tin nhắn';

  @override
  String get chooseAStrongPassword => 'Chọn một mật khẩu mạnh';

  @override
  String get chooseAUsername => 'Chọn tên người dùng';

  @override
  String get clearArchive => 'Dọn dẹp lưu trữ';

  @override
  String get close => 'Đóng';

  @override
  String get commandHint_markasdm => 'Đánh dấu là cuộc trò chuyện trực tiếp';

  @override
  String get commandHint_markasgroup => 'Đánh dấu là cuộc trò chuyện';

  @override
  String get commandHint_ban => 'Cấm người dùng này khỏi cuộc trò chuyện';

  @override
  String get commandHint_clearcache => 'Xóa bộ nhớ đệm';

  @override
  String get commandHint_create =>
      'Tạo cuộc trò chuyện trống\nSử dụng --no-encryption để vô hiệu hóa mã hóa';

  @override
  String get commandHint_discardsession => 'Hủy phiên';

  @override
  String get commandHint_dm =>
      'Bắt đầu cuộc trò chuyện trực tiếp\nSử dụng --no-encryption để vô hiệu hóa mã hóa';

  @override
  String get commandHint_html => 'Gửi văn bản định dạng HTML';

  @override
  String get commandHint_invite => 'Mời người dùng này vào cuộc trò chuyện';

  @override
  String get commandHint_join => 'Tham gia cuộc trò chuyện';

  @override
  String get commandHint_kick => 'Loại bỏ người dùng khỏi cuộc trò chuyện';

  @override
  String get commandHint_leave => 'Rời khỏi cuộc trò chuyện';

  @override
  String get commandHint_me => 'Mô tả bản thân';

  @override
  String get commandHint_myroomavatar =>
      'Đặt ảnh cho cuộc trò chuyện (bởi mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Đặt tên hiển thị cho cuộc trò chuyện này';

  @override
  String get commandHint_op =>
      'Đặt mức năng lượng của người dùng (default: 50)';

  @override
  String get commandHint_plain => 'Gửi văn bản không có định dạng';

  @override
  String get commandHint_react => 'Phản hồi bằng biểu tượng cảm xúc';

  @override
  String get commandHint_send => 'Gửi văn bản';

  @override
  String get commandHint_unban => 'Bỏ cấm người dùng khỏi cuộc trò chuyện';

  @override
  String get commandInvalid => 'Lệnh không hợp lệ';

  @override
  String commandMissing(Object command) {
    return '$command không phải là một lệnh.';
  }

  @override
  String get compareEmojiMatch =>
      'So sánh và đảm bảo các biểu tượng cảm xúc sau đây giống với các biểu tượng trên máy còn lại';

  @override
  String get compareNumbersMatch =>
      'So sánh và đảm bảo các số sau đây giống trên máy còn lại';

  @override
  String get configureChat => 'Cấu hình cuộc trò chuyện';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get connect => 'Kết nối';

  @override
  String get contactHasBeenInvitedToTheGroup => 'Liên hệ đã được mời vào nhóm';

  @override
  String get containsDisplayName => 'Chứa tên hiển thị';

  @override
  String get containsUserName => 'Chứa tên người dùng';

  @override
  String get contentHasBeenReported =>
      'Nội dung đã được báo cáo đến quản trị viên server';

  @override
  String get copiedToClipboard => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String get copy => 'Sao chép';

  @override
  String get copyToClipboard => 'Sao chép vào bộ nhớ tạm';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Không thể giải mã tin nhắn: $error';
  }

  @override
  String countMembers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thành viên',
      one: '1 thành viên',
      zero: 'Không có thành viên',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Tạo';

  @override
  String createdTheChat(Object username) {
    return '$username đã tạo cuộc trò chuyện';
  }

  @override
  String get createNewGroup => 'Tạo một nhóm mới';

  @override
  String get createNewSpace => 'Khoảng trắng mới';

  @override
  String get crossSigningEnabled => 'Kí chéo';

  @override
  String get currentlyActive => 'Đang hoạt động';

  @override
  String get darkTheme => 'Tối';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$day/$month';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$day/$month/$year';
  }

  @override
  String get deactivateAccountWarning =>
      'Việc này sẽ vô hiệu hoá tài khoản của bạn. Điều này không thể đảo ngược được! Bạn chắc là vẫn muốn tiếp tục chứ?';

  @override
  String get defaultPermissionLevel => 'Mức quyền hạn mặc định';

  @override
  String get delete => 'Xoá';

  @override
  String get deleteAccount => 'Xoá tài khoản';

  @override
  String get deleteMessage => 'Xoá tin nhắn';

  @override
  String get deny => 'Từ chối';

  @override
  String get device => 'Thiết bị';

  @override
  String get deviceId => 'Mã xác định thiết bị';

  @override
  String get devices => 'Các thiết bị';

  @override
  String get directChats => 'Cuộc trò chuyện trực tiếp';

  @override
  String get discover => 'Khám phá';

  @override
  String get displaynameHasBeenChanged => 'Tên hiển thị đã được thay đổi';

  @override
  String get download => 'Tải xuống';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get editBlockedServers => 'Chỉnh sửa máy chủ bị chặn';

  @override
  String get editChatPermissions => 'Chỉnh sửa quyền cuộc trò chuyện';

  @override
  String get editDisplayname => 'Sửa tên hiển thị';

  @override
  String get editRoomAliases => 'Chỉnh sửa biệt danh cuộc trò chuyện';

  @override
  String get editRoomAvatar => 'Chỉnh sửa ảnh đại diện cuộc trò chuyện';

  @override
  String get emoteExists => 'Biểu được cảm xúc đã tồn tại!';

  @override
  String get emoteInvalid => 'Mã biểu tượng cảm xúc không hợp lệ!';

  @override
  String get emotePacks => 'Gói biểu tượng cảm xúc cho cuộc trò chuyện';

  @override
  String get emoteSettings => 'Cài đặt biểu tượng cảm xúc';

  @override
  String get emoteShortcode => 'Mã biểu tượng cảm xúc';

  @override
  String get emoteWarnNeedToPick =>
      'Bạn cần chọn một mã biểu tượng cảm xúc và một hình ảnh!';

  @override
  String get emptyChat => 'Cuộc trò chuyện trống';

  @override
  String get enableEmotesGlobally =>
      'Kích hoạt gói biểu tượng cảm xúc trên toàn cầu';

  @override
  String get enableEncryption => 'Kích hoạt mã hóa đầu cuối';

  @override
  String get enableEncryptionWarning =>
      'Bạn sẽ không thể vô hiệu hóa mã hóa nữa. Bạn có chắc không?';

  @override
  String get encrypted => 'Đã mã hóa';

  @override
  String get encryption => 'Mã hóa';

  @override
  String get encryptionNotEnabled => 'Mã hóa không được kích hoạt';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName đã kết thúc cuộc gọi';
  }

  @override
  String get enterGroupName => 'Nhập tên cuộc trò chuyện';

  @override
  String get enterAnEmailAddress => 'Nhập địa chỉ email';

  @override
  String get enterASpacepName => 'Nhập tên khoảng trắng';

  @override
  String get homeserver => 'Máy chủ';

  @override
  String get enterYourHomeserver => 'Nhập máy chủ của bạn';

  @override
  String errorObtainingLocation(Object error) {
    return 'Lỗi lấy vị trí: $error';
  }

  @override
  String get everythingReady => 'Mọi thứ đã sẵn sàng!';

  @override
  String get extremeOffensive => 'Rất phản cảm';

  @override
  String get fileName => 'Tên tệp';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Cỡ chữ';

  @override
  String get forward => 'Chuyển tiếp';

  @override
  String get friday => 'T6';

  @override
  String get fromJoining => 'Từ khi tham gia';

  @override
  String get fromTheInvitation => 'Từ lời mời';

  @override
  String get goToTheNewRoom => 'Đi đến cuộc trò chuyện mới';

  @override
  String get group => 'Cuộc trò chuyện';

  @override
  String get groupDescription => 'Mô tả';

  @override
  String get groupDescriptionHasBeenChanged =>
      'Đã thay đổi mô tả cuộc trò chuyện';

  @override
  String get groupIsPublic => 'Cuộc trò chuyện công khai';

  @override
  String get groups => 'Cuộc trò chuyện';

  @override
  String groupWith(Object displayname) {
    return 'Cuộc trò chuyện với $displayname';
  }

  @override
  String get guestsAreForbidden => 'Khách bị cấm';

  @override
  String get guestsCanJoin => 'Khách có thể tham gia';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username đã thu hồi lời mời về $targetName';
  }

  @override
  String get help => 'Trợ giúp';

  @override
  String get hideRedactedEvents => 'Ẩn tin nhắn đã xoá';

  @override
  String get hideUnknownEvents => 'Ẩn các sự kiện không xác định';

  @override
  String get howOffensiveIsThisContent =>
      'Nội dung này có tính xúc phạm đến mức nào?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Định danh';

  @override
  String get ignore => 'Phớt lờ';

  @override
  String get ignoredUsers => 'Phớt lờ người dùng';

  @override
  String get ignoreListDescription =>
      'Bạn có thể bỏ qua những người dùng đang làm phiền bạn. Bạn sẽ không thể nhận bất kỳ tin nhắn hoặc lời mời trò chuyện nào từ người dùng trong danh sách bỏ qua cá nhân của bạn.';

  @override
  String get ignoreUsername => 'Bỏ qua tên người dùng';

  @override
  String get iHaveClickedOnLink => 'Tôi đã nhấp vào liên kết';

  @override
  String get incorrectPassphraseOrKey =>
      'Mật khẩu hoặc khóa khôi phục không chính xác';

  @override
  String get inoffensive => 'Không xúc phạm';

  @override
  String get inviteContact => 'Mời liên hệ';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Mời liên hệ vào $groupName';
  }

  @override
  String get invited => 'Đã mời';

  @override
  String invitedUser(Object username, Object targetName) {
    return '📩$username đã mời $targetName';
  }

  @override
  String get invitedUsersOnly => 'Chỉ người dùng được mời';

  @override
  String get inviteForMe => 'Lời mời tới tôi';

  @override
  String inviteText(Object username, Object link) {
    return '$username đã mời bạn tham gia FluffyChat.\n1. Cài đặt FluffyChat: https://fluffychat.im\n2. Đăng ký hoặc đăng nhập\n3. Mở link mời: $link';
  }

  @override
  String get isTyping => 'đang nhập';

  @override
  String joinedTheChat(Object username) {
    return '👋 $username đã tham gia cuộc trò chuyện';
  }

  @override
  String get joinRoom => 'Tham gia cuộc trò chuyện';

  @override
  String get keysCached => 'Các khóa đã được lưu trữ';

  @override
  String kicked(Object username, Object targetName) {
    return '👞 $username đã đá $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '🙅 $username đã đá và cấm $targetName';
  }

  @override
  String get kickFromChat => 'Đá khỏi cuộc trò chuyện';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Hoạt động lần cuối: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Đã xem một khoảng thời gian trước';

  @override
  String get leave => 'Rời khỏi';

  @override
  String get leftTheChat => 'Đã rời khỏi cuộc trò chuyện';

  @override
  String get license => 'Giấy phép';

  @override
  String get lightTheme => 'Sáng';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Tải thêm $count người tham gia';
  }

  @override
  String get dehydrate => 'Xuất phiên và xóa thiết bị';

  @override
  String get dehydrateWarning =>
      'Hành động này không thể được hoàn tác. Đảm bảo bạn đã lưu trữ tệp sao lưu một cách an toàn.';

  @override
  String get dehydrateShare =>
      'Đây là bản xuất FluffyChat riêng tư của bạn. Đảm bảo bạn không làm mất nó và giữ nó ở chế độ riêng tư.';

  @override
  String get dehydrateTor => 'Người dùng TOR: Xuất phiên';

  @override
  String get dehydrateTorLong =>
      'Đối với người dùng TOR, khuyến cáo xuất phiên trước khi đóng cửa sổ.';

  @override
  String get hydrateTor => 'Người dùng TOR: Xuất phiên nhập';

  @override
  String get hydrateTorLong =>
      'Lần trước bạn có xuất phiên của mình trên TOR không? Nhanh chóng nhập nó và tiếp tục trò chuyện.';

  @override
  String get hydrate => 'Khôi phục từ tập tin sao lưu';

  @override
  String get loadingPleaseWait => 'Đang tải... Vui lòng chờ.';

  @override
  String get loadingStatus => 'Đang tải ...';

  @override
  String get loadMore => 'Tải thêm…';

  @override
  String get locationDisabledNotice =>
      'Dịch vụ định vị đã bị vô hiệu hóa. Vui lòng cho phép họ chia sẻ vị trí của bạn.';

  @override
  String get locationPermissionDeniedNotice =>
      'Quyền vị trí bị từ chối. Hãy cấp cho họ để chia sẻ vị trí của bạn.';

  @override
  String get login => 'Đăng nhập';

  @override
  String logInTo(Object homeserver) {
    return 'Đăng nhập vào $homeserver';
  }

  @override
  String get loginWithOneClick => 'Đăng nhập với một lần nhấp';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get makeSureTheIdentifierIsValid => 'Đảm bảo mã định danh hợp lệ';

  @override
  String get memberChanges => 'Thay đổi thành viên';

  @override
  String get mention => 'Nhắc đến';

  @override
  String get messages => 'Tin nhắn';

  @override
  String get messageWillBeRemovedWarning =>
      'Tin nhắn sẽ bị xóa đối với tất cả người tham gia';

  @override
  String get noSearchResult => 'Không có kết quả tìm kiếm phù hợp.';

  @override
  String get moderator => 'Người điều hành';

  @override
  String get monday => 'T2';

  @override
  String get muteChat => 'Tắt thông báo trò chuyện';

  @override
  String get needPantalaimonWarning =>
      'Xin lưu ý rằng hiện tại bạn cần có Pantalaimon để sử dụng mã hóa hai đầu.';

  @override
  String get newChat => 'Cuộc trò chuyện mới';

  @override
  String get newMessageInTwake => 'Bạn có tin nhắn mới';

  @override
  String get newVerificationRequest => 'Yêu cầu xác minh mới!';

  @override
  String get noMoreResult => 'Không có kết quả!';

  @override
  String get previous => 'Trước';

  @override
  String get next => 'Tiếp';

  @override
  String get no => 'Không';

  @override
  String get noConnectionToTheServer => 'Không có kết nối với máy chủ';

  @override
  String get noEmotesFound => 'Không tìm thấy biểu tượng cảm xúc. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Bạn chỉ có thể kích hoạt mã hoá khi phòng này không mở';

  @override
  String get noGoogleServicesWarning =>
      'Có vẻ như điện thoại của bạn không có dịch vụ Google. Đó là một quyết định tốt cho sự riêng tư của bạn! Để nhận thông báo đẩy trong FluffyChat, chúng tôi khuyên bạn nên sử dụng https://microg.org/ hoặc https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 không phải là máy chủ ma trận, thay vào đó sử dụng $server2?';
  }

  @override
  String get shareYourInviteLink => 'Chia sẻ liên kết mời của bạn';

  @override
  String get typeInInviteLinkManually => 'Nhập thủ công liên kết lời mời...';

  @override
  String get scanQrCode => 'Quét mã QR';

  @override
  String get none => 'Không có';

  @override
  String get noPasswordRecoveryDescription =>
      'Bạn chưa thêm cách khôi phục mật khẩu của mình.';

  @override
  String get noPermission => 'Không cho phép';

  @override
  String get noRoomsFound => 'Không tìm thấy cuộc trò chuyện nào…';

  @override
  String get notifications => 'Thông báo';

  @override
  String numUsersTyping(Object count) {
    return '$count người dùng đang nhập';
  }

  @override
  String get obtainingLocation => 'Đang lấy vị trí…';

  @override
  String get offensive => 'Xúc phạm';

  @override
  String get offline => 'Ngoại tuyến';

  @override
  String get aWhileAgo => 'một lúc trước';

  @override
  String get ok => 'Ok';

  @override
  String get online => 'Trực tuyến';

  @override
  String get onlineKeyBackupEnabled => 'Sao lưu khóa trực tuyến đã được bật';

  @override
  String get cannotEnableKeyBackup =>
      'Không thể sao lưu hội thoại. Hãy tới Cài đặt để thử lại.';

  @override
  String get cannotUploadKey => 'Không thể lưu trữ khoá Dự phòng.';

  @override
  String get oopsPushError =>
      'Ối! Thật không may, đã xảy ra lỗi khi thiết lập thông báo đẩy.';

  @override
  String get oopsSomethingWentWrong => 'Rất tiếc, đã xảy ra sự cố…';

  @override
  String get openAppToReadMessages => 'Mở ứng dụng để đọc tin nhắn';

  @override
  String get openCamera => 'Mở máy ảnh';

  @override
  String get openVideoCamera => 'Mở camera để quay video';

  @override
  String get oneClientLoggedOut =>
      'Một trong những khách hàng của bạn đã bị đăng xuất';

  @override
  String get addAccount => 'Thêm tài khoản';

  @override
  String get editBundlesForAccount => 'Chỉnh sửa gói cho tài khoản này';

  @override
  String get addToBundle => 'Thêm vào gói';

  @override
  String get removeFromBundle => 'Xóa khỏi gói này';

  @override
  String get bundleName => 'Tên gói';

  @override
  String get enableMultiAccounts =>
      '(BETA) Cho phép nhiều tài khoản trên thiết bị này';

  @override
  String get openInMaps => 'Mở trong bản đồ';

  @override
  String get link => 'Liên kết';

  @override
  String get serverRequiresEmail =>
      'Máy chủ cần xác thực địa chỉ email của bạn để đăng ký.';

  @override
  String get optionalGroupName => '(Tùy chọn) Tên nhóm';

  @override
  String get or => 'Hoặc';

  @override
  String get participant => 'Người tham gia';

  @override
  String get passphraseOrKey => 'mật khẩu hoặc khóa khôi phục';

  @override
  String get password => 'Mật khẩu';

  @override
  String get passwordForgotten => 'Quên mật khẩu';

  @override
  String get passwordHasBeenChanged => 'Mật khẩu đã được thay đổi';

  @override
  String get passwordRecovery => 'Khôi phục mật khẩu';

  @override
  String get people => 'Con người';

  @override
  String get pickImage => 'Chọn một ảnh';

  @override
  String get pin => 'Ghim';

  @override
  String play(Object fileName) {
    return 'Chơi $fileName';
  }

  @override
  String get pleaseChoose => 'Vui lòng chọn';

  @override
  String get pleaseChooseAPasscode => 'Vui lòng chọn một mã mật khẩu';

  @override
  String get pleaseChooseAUsername => 'Vui lòng chọn tên đăng nhập';

  @override
  String get pleaseClickOnLink =>
      'Vui lòng nhấp vào liên kết trong email và tiếp tục.';

  @override
  String get pleaseEnter4Digits =>
      'Vui lòng nhập 4 kí tự hoặc để trống để vô hiệu hóa khóa ứng dụng.';

  @override
  String get pleaseEnterAMatrixIdentifier => 'Vui lòng nhập Matrix ID.';

  @override
  String get pleaseEnterRecoveryKey => 'Vui lòng nhập khóa khôi phục:';

  @override
  String get pleaseEnterYourPassword => 'Vui lòng nhập mật khẩu';

  @override
  String get pleaseEnterYourPin => 'Vui lòng nhập mã pin';

  @override
  String get pleaseEnterYourUsername => 'Vui lòng nhập tên đăng nhập';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Vui lòng làm theo hướng dẫn trên trang web và bấm tiếp';

  @override
  String get privacy => 'Riêng tư';

  @override
  String get publicRooms => 'Cuộc trò chuyện công khai';

  @override
  String get pushRules => 'Quy tắc đẩy';

  @override
  String get reason => 'Lý do';

  @override
  String get recording => 'Đang ghi âm';

  @override
  String redactedAnEvent(Object username) {
    return '$username đã xoá một tin nhắn';
  }

  @override
  String get redactMessage => 'Soạn lại tin nhắn';

  @override
  String get register => 'Đăng ký';

  @override
  String get reject => 'Từ chối';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username đã từ chối lời mời';
  }

  @override
  String get rejoin => 'Tham gia lại';

  @override
  String get remove => 'Loại bỏ';

  @override
  String get removeAllOtherDevices => 'Loại bỏ tất cả các thiết bị khác';

  @override
  String removedBy(Object username) {
    return 'Loại bỏ bởi $username';
  }

  @override
  String get removeDevice => 'Loại bỏ thiết bị';

  @override
  String get unbanFromChat => 'Bỏ cấm khỏi cuộc trò chuyện';

  @override
  String get removeYourAvatar => 'Xóa ảnh đại diện';

  @override
  String get renderRichContent => 'Hiển thị nội dung tin nhắn phong phú';

  @override
  String get replaceRoomWithNewerVersion =>
      'Thay thế cuộc trò chuyện với phiên bản mới hơn';

  @override
  String get reply => 'Trả lời';

  @override
  String get reportMessage => 'Báo cáo tin nhắn';

  @override
  String get requestPermission => 'Yêu cầu quyền';

  @override
  String get roomHasBeenUpgraded => 'Trò chuyện nhóm đã được nâng cấp';

  @override
  String get roomVersion => 'Phiên bản trò chuyện nhóm';

  @override
  String get saturday => 'T7';

  @override
  String get saveFile => 'Lưu tệp';

  @override
  String get searchForPeopleAndChannels => 'Tìm kiếm liên lạc và hội thoại';

  @override
  String get security => 'Bảo mật';

  @override
  String get recoveryKey => 'Khóa khôi phục';

  @override
  String get recoveryKeyLost => 'Mất khóa khôi phục?';

  @override
  String seenByUser(Object username) {
    return 'Đã xem bởi $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã xem bởi $username và $count người khác',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Đã xem bởi $username và $username2';
  }

  @override
  String get send => 'Gửi';

  @override
  String get sendAMessage => 'Gửi tin nhắn';

  @override
  String get sendAsText => 'Gửi dưới dạng văn bản';

  @override
  String get sendAudio => 'Gửi âm thanh';

  @override
  String get sendFile => 'Gửi tệp';

  @override
  String get sendImage => 'Gửi hình ảnh';

  @override
  String get sendMessages => 'Gửi tin nhắn';

  @override
  String get sendMessage => 'Gửi tin nhắn';

  @override
  String get sendOriginal => 'Gửi bản gốc';

  @override
  String get sendSticker => 'Gửi nhãn dán';

  @override
  String get sendVideo => 'Gửi video';

  @override
  String sentAFile(Object username) {
    return '📁 $username gửi tệp';
  }

  @override
  String sentAnAudio(Object username) {
    return '🎤 $username đã gửi 1 đoạn âm thanh';
  }

  @override
  String sentAPicture(Object username) {
    return '🖼️ $username đã gửi một ảnh';
  }

  @override
  String sentASticker(Object username) {
    return '😊 $username đã gửi một nhãn dán';
  }

  @override
  String sentAVideo(Object username) {
    return '🎥 $username đã gửi một video';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName đã gửi thông tin cuộc gọi';
  }

  @override
  String get separateChatTypes => 'Tách các cuộc trò chuyện trực tiếp và nhóm';

  @override
  String get setAsCanonicalAlias => 'Đặt làm biệt danh chính';

  @override
  String get setCustomEmotes => 'Đặt biểu tượng cảm xúc tùy chỉnh';

  @override
  String get setGroupDescription => 'Đặt mô tả';

  @override
  String get setInvitationLink => 'Đặt liên kết lời mời';

  @override
  String get setPermissionsLevel => 'Đặt mức quyền';

  @override
  String get setStatus => 'Đặt trạng thái';

  @override
  String get settings => 'Cài đặt';

  @override
  String get share => 'Chia sẻ';

  @override
  String sharedTheLocation(Object username) {
    return '$username đã chia sẻ vị trí của họ';
  }

  @override
  String get shareLocation => 'Chia sẻ vị trí';

  @override
  String get showDirectChatsInSpaces =>
      'Hiển thị Cuộc trò chuyện trực tiếp có liên quan trong Spaces';

  @override
  String get showPassword => 'Hiển thị mật khẩu';

  @override
  String get signUp => 'Đăng ký';

  @override
  String get singlesignon => 'Dấu hiệu duy nhất trên';

  @override
  String get skip => 'Bỏ qua';

  @override
  String get invite => 'Mời';

  @override
  String get sourceCode => 'Mã nguồn';

  @override
  String get spaceIsPublic => 'Không gian công khai';

  @override
  String get spaceName => 'Tên không gian';

  @override
  String startedACall(Object senderName) {
    return '$senderName đã bắt đầu cuộc gọi';
  }

  @override
  String get startFirstChat => 'Bắt đầu cuộc trò chuyện đầu tiên của bạn';

  @override
  String get status => 'Trạng thái';

  @override
  String get statusExampleMessage => 'Hôm nay bạn thế nào?';

  @override
  String get submit => 'Nộp';

  @override
  String get sunday => 'CN';

  @override
  String get synchronizingPleaseWait => 'Đang đồng bộ... Vui lòng chờ.';

  @override
  String get systemTheme => 'Hệ thống';

  @override
  String get theyDontMatch => 'Chúng không phù hợp';

  @override
  String get theyMatch => 'Chúng phù hợp';

  @override
  String get thisRoomHasBeenArchived => 'Cuộc trò chuyện này đã được lưu trữ.';

  @override
  String get thursday => 'T5';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Chuyển đổi yêu thích';

  @override
  String get toggleMuted => 'Chuyển Tắt tiếng';

  @override
  String get toggleUnread => 'Đánh dấy là đã đọc/chưa đọc';

  @override
  String get tooManyRequestsWarning =>
      'Quá nhiều yêu cầu. Vui lòng thử lại sau!';

  @override
  String get transferFromAnotherDevice => 'Chuyển từ thiết bị khác';

  @override
  String get tryToSendAgain => 'Thử lại';

  @override
  String get tuesday => 'T3';

  @override
  String get unavailable => 'Không khả dụng';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username bỏ cấm $targetName';
  }

  @override
  String get unblockDevice => 'Bỏ chặn thiết bị';

  @override
  String get unknownDevice => 'Thiết bị chưa biết';

  @override
  String get unknownEncryptionAlgorithm => 'Thuật toán mã hóa không xác định';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Sự kiện không xác định \'$type\'';
  }

  @override
  String get unmuteChat => 'Bật tiếng trò chuyện';

  @override
  String get unpin => 'Bỏ ghim';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount tin nhắn chưa đọc',
      one: '1 tin nhắn chưa đọc',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username và $count người khác đang gõ';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username và $username2 đang gõ';
  }

  @override
  String userIsTyping(Object username) {
    return '$username đang gõ';
  }

  @override
  String userLeftTheChat(Object username) {
    return '🚪 $username đã rời khỏi cuộc trò chuyện';
  }

  @override
  String get username => 'Tên đăng nhập';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username đã gửi sự kiện $type';
  }

  @override
  String get unverified => 'Chưa được xác minh';

  @override
  String get verified => 'Đã xác thực';

  @override
  String get verify => 'Xác minh';

  @override
  String get verifyStart => 'Bắt đầu xác minh';

  @override
  String get verifySuccess => 'Bạn đã xác minh thành công!';

  @override
  String get verifyTitle => 'Đang xác minh tài khoản khác';

  @override
  String get videoCall => 'Cuộc gọi Video';

  @override
  String get visibilityOfTheChatHistory =>
      'Khả năng hiển thị lịch sử trò chuyện';

  @override
  String get visibleForAllParticipants => 'Hiển thị với tất cả thành viên';

  @override
  String get visibleForEveryone => 'Hiển thị cho mọi người';

  @override
  String get voiceMessage => 'Tin nhắn thoại';

  @override
  String get waitingPartnerAcceptRequest =>
      'Đang chờ đối phương chấp nhận yêu cầu…';

  @override
  String get waitingPartnerEmoji =>
      'Đang chờ đối phương chấp nhận biểu tượng cảm xúc…';

  @override
  String get waitingPartnerNumbers => 'Đang chờ đối phương chấp nhận số…';

  @override
  String get wallpaper => 'Ảnh nền';

  @override
  String get warning => 'Cảnh báo!';

  @override
  String get wednesday => 'T4';

  @override
  String get weSentYouAnEmail => 'Chúng tôi đã gửi bạn một email';

  @override
  String get whoCanPerformWhichAction => 'Ai có thể thực hiện hành động nào';

  @override
  String get whoIsAllowedToJoinThisGroup =>
      'Ai được phép tham gia cuộc trò chuyện này';

  @override
  String get whyDoYouWantToReportThis => 'Tại sao bạn muốn báo cáo điều này?';

  @override
  String get wipeChatBackup =>
      'Xóa bản sao lưu trò chuyện của bạn để tạo khóa khôi phục mới?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Với những địa chỉ này, bạn có thể khôi phục mật khẩu của mình.';

  @override
  String get writeAMessage => 'Viết tin nhắn…';

  @override
  String get yes => 'Đúng';

  @override
  String get you => 'Bạn';

  @override
  String get youAreInvitedToThisChat =>
      'Bạn được mời tham gia cuộc trò chuyện này';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Bạn không còn tham gia vào cuộc trò chuyện này nữa';

  @override
  String get youCannotInviteYourself => 'Bạn không thể mời chính mình';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Bạn đã bị cấm tham gia cuộc trò chuyện này';

  @override
  String get yourPublicKey => 'Khóa công khai của bạn';

  @override
  String get messageInfo => 'Thông tin tin nhắn';

  @override
  String get time => 'Thời gian';

  @override
  String get messageType => 'Loại tin nhắn';

  @override
  String get sender => 'Người gửi';

  @override
  String get openGallery => 'Mở thư viện';

  @override
  String get removeFromSpace => 'Xóa khỏi không gian';

  @override
  String get addToSpaceDescription =>
      'Chọn một không gian để thêm cuộc trò chuyện này vào đó.';

  @override
  String get start => 'Bắt đầu';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'Để mở khóa các tin nhắn cũ của bạn, vui lòng nhập khóa khôi phục đã được tạo trong phiên trước đó. Khóa khôi phục KHÔNG phải là mật khẩu của bạn.';

  @override
  String get addToStory => 'Thêm vào câu chuyện';

  @override
  String get publish => 'Xuất bản';

  @override
  String get whoCanSeeMyStories => 'Ai có thể xem câu chuyện của tôi?';

  @override
  String get unsubscribeStories => 'Hủy theo dõi câu chuyện';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'Người dùng này chưa đăng bất cứ điều gì trong câu chuyện của họ';

  @override
  String get yourStory => 'Câu chuyện của bạn';

  @override
  String get replyHasBeenSent => 'Trả lời đã được gửi';

  @override
  String videoWithSize(Object size) {
    return 'Video ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Câu chuyện từ $date:\n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Lưu ý rằng mọi người có thể thấy và liên hệ với nhau trong câu chuyện của bạn.';

  @override
  String get whatIsGoingOn => 'Điều gì đang xảy ra ?';

  @override
  String get addDescription => 'Thêm mô tả';

  @override
  String get storyPrivacyWarning =>
      'Xin lưu ý rằng mọi người có thể thấy và liên hệ với nhau trong câu chuyện của bạn. Câu chuyện của bạn sẽ hiển thị trong 24 giờ nhưng không có gì đảm bảo rằng chúng sẽ bị xóa khỏi tất cả các thiết bị và máy chủ.';

  @override
  String get iUnderstand => 'Tôi hiểu';

  @override
  String get openChat => 'Mở cuộc trò chuyện';

  @override
  String get markAsRead => 'Đánh dấu là đã đọc';

  @override
  String get reportUser => 'Báo cáo người dùng';

  @override
  String get dismiss => 'Bỏ qua';

  @override
  String get matrixWidgets => 'Tiện ích Matrix';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender bày tỏ cảm xúc với $reaction';
  }

  @override
  String get pinChat => 'Ghim';

  @override
  String get confirmEventUnpin => 'Bạn có chắc chắn bỏ ghim tin nhắn này?';

  @override
  String get emojis => 'Biểu tượng cảm xúc';

  @override
  String get placeCall => 'Đặt cuộc gọi';

  @override
  String get voiceCall => 'Cuộc gọi thoại';

  @override
  String get unsupportedAndroidVersion => 'Phiên bản Android không được hỗ trợ';

  @override
  String get unsupportedAndroidVersionLong =>
      'Tính năng này yêu cầu phiên bản Android mới hơn. Vui lòng kiểm tra các bản cập nhật hoặc đội ngũ hỗ trợ Lineage OS.';

  @override
  String get videoCallsBetaWarning =>
      'Xin lưu ý rằng cuộc gọi điện video hiện đang ở giai đoạn thử nghiệm. Chúng có thể không hoạt động như mong đợi hoặc không hoạt động trên tất cả các nền tảng.';

  @override
  String get experimentalVideoCalls => 'Cuộc gọi video thử nghiệm';

  @override
  String get emailOrUsername => 'Email hoặc tên người dùng';

  @override
  String get indexedDbErrorTitle => 'Vấn đề về chế độ riêng tư';

  @override
  String get indexedDbErrorLong =>
      'Rất tiếc, tính năng lưu trữ tin nhắn không được bật ở chế độ riêng tư theo mặc định.\nVui lòng truy cập\n  - về: cấu hình\n  - đặt dom.indexedDB.privateBrowsing.enabled thành true\nNếu không, bạn không thể chạy FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'Chuyển sang tài khoản $number';
  }

  @override
  String get nextAccount => 'Tài khoản tiếp theo';

  @override
  String get previousAccount => 'Tài khoản trước';

  @override
  String get editWidgets => 'Chỉnh sửa tiện ích';

  @override
  String get addWidget => 'Thêm tiện ích';

  @override
  String get widgetVideo => 'Video';

  @override
  String get widgetEtherpad => 'Ghi chú văn bản';

  @override
  String get widgetJitsi => 'Cuộc gọi Jitsi';

  @override
  String get widgetCustom => 'Cá nhân hóa';

  @override
  String get widgetName => 'Tên';

  @override
  String get widgetUrlError => 'Đây không phải URL hợp lệ.';

  @override
  String get widgetNameError => 'Vui lòng cung cấp tên hiển thị.';

  @override
  String get errorAddingWidget => 'Lỗi khi thêm tiện ích.';

  @override
  String get youRejectedTheInvitation => 'Bạn đã từ chối lời mời';

  @override
  String get youJoinedTheChat => 'Bạn đã tham gia cuộc trò chuyện';

  @override
  String get youAcceptedTheInvitation => '👍 Bạn đã chấp nhận lời mời';

  @override
  String youBannedUser(Object user) {
    return 'Bạn đã cấm $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'Bạn đã thu hồi lời mời dành cho $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 Bạn đã được mời bởi $user';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 Bạn đã mời $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 Bạn đã đá $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 Bạn đã đá và cấm $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'Bạn đã bỏ cấm $user';
  }

  @override
  String get noEmailWarning =>
      'Vui lòng nhập địa chỉ email hợp lệ. Nếu không, bạn sẽ không thể đặt lại mật khẩu của mình. Nếu bạn không muốn, hãy nhấn lại vào nút để tiếp tục.';

  @override
  String get stories => 'Câu chuyện';

  @override
  String get users => 'Người dùng';

  @override
  String get enableAutoBackups => 'Bật sao lưu tự động';

  @override
  String get unlockOldMessages => 'Mở khóa tin nhắn cũ';

  @override
  String get cannotUnlockBackupKey => 'Không thể mở khoá Dự phòng.';

  @override
  String get storeInSecureStorageDescription =>
      'Lưu trữ khóa khôi phục trong bộ lưu trữ an toàn của thiết bị này.';

  @override
  String get saveKeyManuallyDescription =>
      'Lưu khóa này thủ công bằng cách kích hoạt hộp thoại chia sẻ hệ thống hoặc bảng nhớ tạm.';

  @override
  String get storeInAndroidKeystore => 'Lưu trữ trong Android KeyStore';

  @override
  String get storeInAppleKeyChain => 'Lưu trữ trong Apple KeyChain';

  @override
  String get storeSecurlyOnThisDevice => 'Lưu trữ an toàn trên thiết bị này';

  @override
  String countFiles(Object count) {
    return '$count tệp';
  }

  @override
  String get user => 'Người dùng';

  @override
  String get custom => 'Cá nhân hóa';

  @override
  String get foregroundServiceRunning =>
      'Thông báo này xuất hiện khi dịch vụ nền trước đang chạy.';

  @override
  String get screenSharingTitle => 'Chia sẻ màn hình';

  @override
  String get screenSharingDetail => 'Bạn đang chia sẻ màn hình trong FuffyChat';

  @override
  String get callingPermissions => 'Quyền gọi điện';

  @override
  String get callingAccount => 'Tài khoản gọi điện';

  @override
  String get callingAccountDetails =>
      'Cho phép FluffyChat sử dụng ứng dụng quay số Android gốc.';

  @override
  String get appearOnTop => 'Xuất hiện trên cùng';

  @override
  String get appearOnTopDetails =>
      'Cho phép ứng dụng xuất hiện trên cùng (không cần thiết nếu bạn đã thiết lập Fluffychat làm tài khoản gọi điện)';

  @override
  String get otherCallingPermissions =>
      'Micro, máy ảnh và các quyền FluffyChat khác';

  @override
  String get whyIsThisMessageEncrypted =>
      'Tại sao tin nhắn này không thể đọc được?';

  @override
  String get noKeyForThisMessage =>
      'Điều này có thể xảy ra nếu tin nhắn được gửi trước khi bạn đăng nhập vào tài khoản của mình trên thiết bị này.\n\nCũng có thể người gửi đã chặn thiết bị của bạn hoặc đã xảy ra sự cố với kết nối internet.\n\nBạn có thể đọc tin nhắn trên một phiên khác không? Sau đó, bạn có thể chuyển tin nhắn từ nó! Đi tới Cài đặt > Thiết bị và đảm bảo rằng các thiết bị của bạn đã xác minh lẫn nhau. Khi bạn mở phòng vào lần tiếp theo và cả hai phiên đều ở phía trước, chìa khóa sẽ được truyền tự động.\n\nBạn không muốn bị mất chìa khóa khi đăng xuất hoặc chuyển đổi thiết bị? Đảm bảo rằng bạn đã bật tính năng sao lưu trò chuyện trong cài đặt.';

  @override
  String get newGroup => 'Cuộc trò chuyện mới';

  @override
  String get newSpace => 'Khoảng trắng mới';

  @override
  String get enterSpace => 'Nhập khoảng trắng';

  @override
  String get enterRoom => 'Vào phòng';

  @override
  String get allSpaces => 'Tất cả khoảng trắng';

  @override
  String numChats(Object number) {
    return '$number cuộc trò chuyện';
  }

  @override
  String get hideUnimportantStateEvents =>
      'Ẩn các sự kiện trạng thái không quan trọng';

  @override
  String get doNotShowAgain => 'Không hiển thị lại';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return 'Cuộc trò chuyện trống (trước đây là $oldDisplayName)';
  }

  @override
  String get newSpaceDescription =>
      'Spaces cho phép bạn hợp nhất các cuộc trò chuyện của mình và xây dựng cộng đồng riêng tư hoặc công khai.';

  @override
  String get encryptThisChat => 'Mã hóa cuộc trò chuyện này';

  @override
  String get endToEndEncryption => 'Mã hóa đầu cuối';

  @override
  String get disableEncryptionWarning =>
      'Vì lý do bảo mật, bạn không thể tắt tính năng mã hóa trong cuộc trò chuyện, nơi tính năng này đã được bật trước đó.';

  @override
  String get sorryThatsNotPossible => 'Xin lỗi... điều đó là không thể';

  @override
  String get deviceKeys => 'Khóa thiết bị:';

  @override
  String get letsStart => 'Bắt đầu';

  @override
  String get enterInviteLinkOrMatrixId => 'Nhập liên kết mời hoặc Matrix ID...';

  @override
  String get reopenChat => 'Mở lại cuộc trò chuyện';

  @override
  String get noBackupWarning =>
      'Cảnh báo! Nếu không bật sao lưu trò chuyện, bạn sẽ mất quyền truy cập vào tin nhắn được mã hóa của mình. Chúng tôi khuyên bạn nên bật sao lưu trò chuyện trước khi đăng xuất.';

  @override
  String get noOtherDevicesFound => 'Không tìm thấy thiết bị khác';

  @override
  String get fileIsTooBigForServer =>
      'Máy chủ báo cáo rằng tệp quá lớn để gửi.';

  @override
  String get onlineStatus => 'trực tuyến';

  @override
  String onlineMinAgo(Object min) {
    return 'trực tuyến $min phút trước';
  }

  @override
  String onlineHourAgo(Object hour) {
    return 'trực truyến $hour giờ trước';
  }

  @override
  String onlineDayAgo(Object day) {
    return 'trực tuyến $day trước';
  }

  @override
  String get noMessageHereYet => 'Không có tin nhắn...';

  @override
  String get sendMessageGuide =>
      'Gửi tin nhắn hoặc nhấn vào lời chào bên dưới.';

  @override
  String get youCreatedGroupChat => 'Bạn đã tạo một cuộc trò chuyện';

  @override
  String get chatCanHave => 'Trò chuyện có thể có:';

  @override
  String get upTo100000Members => 'Lên tới 100.000 thành viên';

  @override
  String get persistentChatHistory => 'Lịch sử trò chuyện liên tục';

  @override
  String get addMember => 'Thêm thành viên';

  @override
  String get profile => 'Trang cá nhân';

  @override
  String get channels => 'Kênh';

  @override
  String get chatMessage => 'Tin nhắn mới';

  @override
  String welcomeToTwake(Object user) {
    return 'Chào mừng đến Twake, $user';
  }

  @override
  String get startNewChatMessage =>
      'Thật vui khi được trò chuyện với bạn bè và cộng tác với nhóm của bạn.\nHãy bắt đầu hội thoại, tạo cuộc trò chuyện hoặc tham gia cuộc trò chuyện hiện có.';

  @override
  String get statusDot => '⬤';

  @override
  String get active => 'Đã kích hoạt';

  @override
  String get inactive => 'Chưa kích hoạt';

  @override
  String get newGroupChat => 'Nhóm trò chuyện mới';

  @override
  String get twakeUsers => 'Người dùng Twake';

  @override
  String get expand => 'Mở rộng';

  @override
  String get shrink => 'Thu nhỏ';

  @override
  String noResultForKeyword(Object keyword) {
    return 'Không có kết quả cho \"$keyword\"';
  }

  @override
  String get searchResultNotFound1 =>
      '• Đảm bảo không có lỗi chính tả trong tìm kiếm của bạn.\n';

  @override
  String get searchResultNotFound2 =>
      '• Bạn có thể không có người dùng này trong danh bạ của mình.\n';

  @override
  String get searchResultNotFound3 =>
      '• Kiểm tra quyền truy cập liên hệ, người dùng có thể có trong danh sách liên hệ của bạn.\n';

  @override
  String get searchResultNotFound4 => '• Nếu lý do không được liệt kê ở trên, ';

  @override
  String get searchResultNotFound5 => 'tìm kiếm sự giúp đỡ.';

  @override
  String get more => 'Thêm';

  @override
  String get whoWouldYouLikeToAdd => 'Bạn muốn thêm ai?';

  @override
  String get addAPhoto => 'Thêm ảnh';

  @override
  String maxImageSize(Object max) {
    return 'Kích thước tệp tối đa: ${max}MB';
  }

  @override
  String get owner => 'Chủ sở hữu';

  @override
  String participantsCount(Object count) {
    return 'Người tham gia ($count)';
  }

  @override
  String get back => 'Quay lại';

  @override
  String get wrongServerName => 'Tên máy chủ sai';

  @override
  String get serverNameWrongExplain =>
      'Địa chỉ máy chủ đã được quản trị viên gửi cho bạn. Vui lòng kiểm tra email mời.';

  @override
  String get contacts => 'Liên hệ';

  @override
  String get searchForContacts => 'Tìm kiếm liên hệ';

  @override
  String get soonThereHaveContacts => 'Sẽ sớm có liên hệ';

  @override
  String get searchSuggestion =>
      'Hiện tại, tìm kiếm bằng cách nhập tên của một người hoặc địa chỉ máy chủ công cộng';

  @override
  String get loadingContacts => 'Tải liên hệ...';

  @override
  String get recentChat => 'Gần đây';

  @override
  String get selectChat => 'Chọn';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get forwardTo => 'Chuyển tiếp tới...';

  @override
  String get noConnection => 'Không có kết nối';

  @override
  String photoSelectedCounter(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0 đã được chọn';
  }

  @override
  String get addACaption => 'Thêm chú thích...';

  @override
  String get noImagesFound => 'Không tìm thấy ảnh';

  @override
  String get captionForImagesIsNotSupportYet =>
      'Chú thích cho hình ảnh chưa được hỗ trợ.';

  @override
  String get tapToAllowAccessToYourGallery =>
      'Nhấn để cho phép truy cập vào Thư viện của bạn';

  @override
  String get tapToAllowAccessToYourCamera =>
      'Bạn có thể bật quyền truy cập camera trong ứng dụng Cài đặt để thực hiện cuộc gọi điện video trong';

  @override
  String get twake => 'Twake Chat';

  @override
  String get permissionAccess => 'Quyền truy cập';

  @override
  String get allow => 'Cho phép';

  @override
  String get explainStoragePermission =>
      'Twake cần quyền truy cập vào bộ nhớ của bạn để xem trước tệp';

  @override
  String get explainGoToStorageSetting =>
      'Twake cần quyền truy cập vào bộ nhớ của bạn để xem trước tệp, hãy chuyển tới cài đặt để cấp quyền này';

  @override
  String get gallery => 'Thư viện';

  @override
  String get documents => 'Tài liệu';

  @override
  String get location => 'Vị trí';

  @override
  String get contact => 'Liên hệ';

  @override
  String get file => 'Tệp';

  @override
  String get recent => 'Gần đây';

  @override
  String get chatsAndContacts => 'Trò chuyện và Danh bạ';

  @override
  String get externalContactTitle => 'Mời người dùng mới';

  @override
  String get externalContactMessage =>
      'Một số người dùng bạn muốn thêm không có trong danh bạ của bạn. Bạn có muốn mời họ không?';

  @override
  String get clear => 'Xóa';

  @override
  String get keyboard => 'Bàn phím';

  @override
  String get changeChatAvatar => 'Thay đổi ảnh đại diện cuộc trò chuyện';

  @override
  String get roomAvatarMaxFileSize => 'Kích cỡ ảnh đại diện quá lớn';

  @override
  String roomAvatarMaxFileSizeLong(Object max) {
    return 'Kích cỡ ảnh đại diện cần bé hơn $max';
  }

  @override
  String get continueProcess => 'Tiếp tục';

  @override
  String get youAreUploadingPhotosDoYouWantToCancelOrContinue =>
      'Lỗi tải ảnh! Bạn vẫn muốn tiếp tục tạo trò chuyện?';

  @override
  String hasCreatedAGroupChat(Object groupName) {
    return 'tạo cuộc trò chuyện \"$groupName\"';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get adminPanel => 'Bảng quản trị';

  @override
  String get acceptInvite => 'Đúng, tham gia';

  @override
  String get askToInvite =>
      ' muốn bạn tham gia cuộc trò chuyện này. Bạn nghĩ sao?';

  @override
  String get select => 'Chọn';

  @override
  String get copyMessageText => 'Sao chép';

  @override
  String get pinThisChat => 'Ghim cuộc trò chuyện này';

  @override
  String get unpinThisChat => 'Bỏ ghim cuộc trò chuyện này';

  @override
  String get add => 'Thêm';

  @override
  String get addMembers => 'Thêm thành viên';

  @override
  String get chatInfo => 'Thông tin hội thoại';

  @override
  String get mute => 'Tắt tiếng';

  @override
  String membersInfo(Object count) {
    return 'Thành viên ($count)';
  }

  @override
  String get members => 'Thành viên';

  @override
  String get media => 'Đa phương tiện';

  @override
  String get files => 'Tệp';

  @override
  String get links => 'Liên kết';

  @override
  String get downloads => 'Tải xuống';

  @override
  String get downloadImageSuccess => 'Lưu trữ hình ảnh';

  @override
  String get downloadImageError => 'Lỗi lưu ảnh';

  @override
  String downloadFileInWeb(Object directory) {
    return 'Tệp được lưu tại $directory';
  }

  @override
  String get notInAChatYet => 'Bạn không ở trong cuộc hội thoại';

  @override
  String get blankChatTitle =>
      'Chọn một cuộc trò chuyện hoặc nhấn #EditIcon# để tạo mới.';

  @override
  String get errorPageTitle => 'Có lỗi xảy ra';

  @override
  String get errorPageDescription => 'Trang không tồn tại.';

  @override
  String get errorPageButton => 'Trờ lại';

  @override
  String get playVideo => 'Bật';

  @override
  String get done => 'Kết thúc';

  @override
  String get markThisChatAsRead => 'Đánh dấu là đã đọc';

  @override
  String get markThisChatAsUnRead => 'Đánh dấu là chưa đọc';

  @override
  String get muteThisChat => 'Tắt tiếng cuộc trò chuyện này';

  @override
  String get unmuteThisChat => 'Bật tiếng trò chuyện này';

  @override
  String get read => 'Đọc';

  @override
  String get unread => 'Chưa đọc';

  @override
  String get unmute => 'Bật tiếng';

  @override
  String get privacyAndSecurity => 'Riêng tư và Bảo mật';

  @override
  String get notificationAndSounds => 'Thông báo';

  @override
  String get appLanguage => 'Ngôn ngữ';

  @override
  String get chatFolders => 'Thư mục';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get bio => 'Thông tin (tuỳ chọn)';

  @override
  String get matrixId => 'Matrix ID';

  @override
  String get email => 'Email';

  @override
  String get company => 'Công ty';

  @override
  String get basicInfo => 'Thông tin';

  @override
  String get editProfileDescriptions => 'Chỉnh sửa thông tin cá nhân.';

  @override
  String get workIdentitiesInfo => 'Thông tin công việc';

  @override
  String get editWorkIdentitiesDescriptions =>
      'Chỉnh sửa các cài đặt về danh tính của bạn như Matrix ID, email hoặc tên công ty.';

  @override
  String get copiedMatrixIdToClipboard => 'Sao chép vào bộ nhớ tạm.';

  @override
  String get changeProfileAvatar => 'Thay đổi hình đại diện của hồ sơ';

  @override
  String countPinChat(Object countPinChat) {
    return 'Ghim hội thoại ($countPinChat)';
  }

  @override
  String countAllChat(Object countAllChat) {
    return 'Tất cả ($countAllChat)';
  }

  @override
  String get thisMessageHasBeenEncrypted => 'Tin nhắn đã được mã hoá';

  @override
  String get roomCreationFailed => 'Tạo hội thoại lỗi';

  @override
  String get errorGettingPdf => 'Không thể tải tệp PDF';

  @override
  String get errorPreviewingFile => 'Lỗi xem trước tệp';

  @override
  String get paste => 'Dán';

  @override
  String get cut => 'Cắt';

  @override
  String get pasteImageFailed => 'Lỗi dán ảnh';

  @override
  String get copyImageFailed => 'Lỗi sao chép ảnh';

  @override
  String get fileFormatNotSupported => 'Tệp không được hỗ trợ';

  @override
  String get noResultsFound => 'Không tìm thấy kết quả';

  @override
  String get encryptionMessage =>
      'Tính năng này bảo vệ tin nhắn của bạn không bị người khác đọc nhưng cũng ngăn không cho chúng được sao lưu trên máy chủ của chúng tôi. Bạn không thể tắt tính năng này sau.';

  @override
  String get encryptionWarning =>
      'Bạn có thể mất tin nhắn nếu truy cập ứng dụng Twake trên thiết bị khác.';

  @override
  String get selectedUsers => 'Những người dùng được chọn';

  @override
  String get clearAllSelected => 'Xóa tất cả các lựa chọn';

  @override
  String get newDirectMessage => 'Tin nhắn trực tiếp mới';

  @override
  String get contactInfo => 'Thông tin liên hệ(';

  @override
  String countPinnedMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tin nhắn được ghim #$count',
      zero: 'Tin nhắn được ghim',
    );
    return '$_temp0';
  }

  @override
  String pinnedMessages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tin nhắn được ghim',
      one: '1 Tin nhắn được ghim',
    );
    return '$_temp0';
  }

  @override
  String get copyImageSuccess => 'Ảnh đã được sao chép vào bộ nhớ tạm';

  @override
  String get youNeedToAcceptTheInvitation =>
      'Bạn cần chấp nhận lời mời để bắt đầu trò chuyện';

  @override
  String get hasInvitedYouToAChat =>
      ' đã mời bạn trò chuyện. Chấp nhận hay từ chối và xóa cuộc trò chuyện?';

  @override
  String get declineTheInvitation => 'Từ chối lời mời?';

  @override
  String get doYouReallyWantToDeclineThisInvitation =>
      'Bạn có thực sự muốn từ chối lời mời này và xóa cuộc trò chuyện không? Bạn sẽ không thể hoàn tác hành động này.';

  @override
  String get declineAndRemove => 'Từ chối và xóa';

  @override
  String get notNow => 'Không phải bây giờ';

  @override
  String get contactsWarningBannerTitle =>
      'Để đảm bảo bạn có thể kết nối với tất cả bạn bè của mình, vui lòng cho phép Twake truy cập danh bạ trên thiết bị của bạn. Chúng tôi đánh giá cao sự thông cảm của bạn.';

  @override
  String contactsCount(Object count) {
    return 'Danh bạ ($count)';
  }

  @override
  String linagoraContactsCount(Object count) {
    return 'Danh bạ Linagora ($count)';
  }

  @override
  String fetchingPhonebookContacts(Object progress) {
    return 'Đang tìm nạp danh bạ từ thiết bị...(đã hoàn thành $progress%)';
  }

  @override
  String get languageEnglish => 'Tiếng Anh';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageFrench => 'Tiếng Pháp';

  @override
  String get languageRussian => 'tiếng Nga';

  @override
  String get settingsLanguageDescription =>
      'Cài đặt ngôn ngữ bạn sử dụng trên Twake Chat';

  @override
  String sendImages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gửi $count ảnh',
      one: 'Gửi 1 ảnh',
    );
    return '$_temp0';
  }

  @override
  String get enterCaption => 'Nhập chú thích...';

  @override
  String get failToSend => 'Không gửi được, vui lòng thử lại';

  @override
  String get showLess => 'Ẩn bớt';

  @override
  String get showMore => 'Hiển thị thêm';

  @override
  String get unreadMessages => 'Tin nhắn chưa đọc';

  @override
  String get groupInformation => 'Thông tin nhóm';

  @override
  String get linkInvite => 'Đường dẫn lời mời';

  @override
  String get noDescription => 'Không có mô tả';

  @override
  String get description => 'Sự mô tả';

  @override
  String get groupName => 'Tên nhóm';

  @override
  String get descriptionHelper =>
      'Bạn có thể cung cấp mô tả tùy chọn cho nhóm của mình.';

  @override
  String get groupNameCannotBeEmpty => 'Tên nhóm không được để trống';

  @override
  String get unpinAllMessages => 'Bỏ ghim tất cả tin nhắn';

  @override
  String get pinnedMessagesTooltip => 'Tin nhắn được ghim';

  @override
  String get jumpToMessage => 'Đi đến tin nhắn';

  @override
  String get failedToUnpin => 'Không thể bỏ ghim tin nhắn';

  @override
  String get welcomeTo => 'Chào mừng đến với';

  @override
  String get descriptionWelcomeTo =>
      'Một ứng dụng nhắn tin mã nguồn mở dựa trên\ngiao thức ma trận, cho phép bạn\nmã hóa dữ liệu của bạn';

  @override
  String get startMessaging => 'Bắt đầu nhắn tin';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get createTwakeId => 'Tạo Twake ID';

  @override
  String get useYourCompanyServer => 'Sử dụng máy chủ công ty của bạn';

  @override
  String get descriptionTwakeId =>
      'Một ứng dụng tin nhắn nguồn mở mã hóa\ndữ liệu của bạn với giao thức ma trận';

  @override
  String countFilesSendPerDialog(Object count) {
    return 'Số tệp tối đa khi gửi là $count.';
  }

  @override
  String sendFiles(Object count) {
    return 'Gửi ${count}tệp';
  }

  @override
  String get addAnotherAccount => 'Thêm tài khoản khác';

  @override
  String get accountSettings => 'Cài đặt tài khoản';

  @override
  String get failedToSendFiles => 'Không gửi được tập tin';

  @override
  String get noResults => 'Không tìm thấy kết quả';

  @override
  String get isSingleAccountOnHomeserver =>
      'Chúng tôi chưa hỗ trợ nhiều tài khoản trên một máy chủ';

  @override
  String messageSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tin nhắn',
      one: '1 Tin nhắn',
      zero: 'Không có tin nhắn',
    );
    return '$_temp0';
  }

  @override
  String draftChatHookPhrase(String user) {
    return 'Xin chào $user! Tôi muốn trò chuyện với bạn.';
  }

  @override
  String get twakeChatUser => 'Người dùng Twake Chat';

  @override
  String get sharedMediaAndLinks => 'Phương tiện và liên kết chia sẻ';

  @override
  String get errorSendingFiles =>
      'Một số tệp không thể gửi do hạn chế về kích thước, định dạng hoặc các lỗi không mong đợi. Những tệp này sẽ không được bao gồm trong quá trình gửi.';

  @override
  String get removeFileBeforeSend => 'Loại bỏ các tệp lỗi trước khi gửi';

  @override
  String get unselect => 'Bỏ chọn';

  @override
  String get searchContacts => 'Tìm kiếm liên hệ';

  @override
  String get tapToAllowAccessToYourMicrophone =>
      'Bạn có thể bật quyền truy cập micrô trong ứng dụng Cài đặt để tạo giọng nói';

  @override
  String get showInChat => 'Hiển thị trong cuộc trò chuyện';

  @override
  String get phone => 'Điện thoại';

  @override
  String get viewProfile => 'Xem hồ sơ';

  @override
  String get profileInfo => 'Thông tin hồ sơ';

  @override
  String get saveToDownloads => 'Lưu vào phần tải xuống';

  @override
  String get saveToGallery => 'Lưu vào bộ sưu tập';

  @override
  String get fileSavedToDownloads => 'Tệp đã được lưu vào thư mục Tải xuống';

  @override
  String get saveFileToDownloadsError =>
      'Không lưu được tệp vào thư mục Tải xuống';

  @override
  String explainPermissionToDownloadFiles(String appName) {
    return 'Để tiếp tục, vui lòng cho phép $appName truy cập quyền lưu trữ. Quyền này rất cần thiết để lưu tệp vào thư mục Tải xuống.';
  }

  @override
  String get explainPermissionToAccessContacts =>
      'Twake Chat KHÔNG thu thập danh bạ của bạn. Twake Chat chỉ gửi các mã băm (hash) của danh bạ đến máy chủ của Twake Chat để xác định ai trong số bạn bè của bạn đã tham gia Twake Chat, giúp bạn kết nối với họ. Danh bạ của bạn KHÔNG được đồng bộ hóa với máy chủ của chúng tôi.';

  @override
  String get explainPermissionToAccessMedias =>
      'Twake Chat không đồng bộ dữ liệu giữa thiết bị của bạn và máy chủ của chúng tôi. Chúng tôi chỉ lưu trữ các tệp phương tiện mà bạn đã gửi vào phòng chat. Tất cả các tệp phương tiện được gửi trong chat đều được mã hóa và lưu trữ an toàn. Vào Cài đặt > Quyền và kích hoạt quyền Lưu trữ: Ảnh và Video. Bạn cũng có thể từ chối quyền truy cập vào thư viện phương tiện của mình bất cứ lúc nào.';

  @override
  String get explainPermissionToAccessPhotos =>
      'Twake Chat không đồng bộ dữ liệu giữa thiết bị của bạn và máy chủ của chúng tôi. Chúng tôi chỉ lưu trữ các tệp phương tiện mà bạn đã gửi vào phòng chat. Tất cả các tệp phương tiện được gửi trong chat đều được mã hóa và lưu trữ an toàn. Vào Cài đặt > Quyền và kích hoạt quyền Lưu trữ: Ảnh. Bạn cũng có thể từ chối quyền truy cập vào thư viện phương tiện của mình bất cứ lúc nào.';

  @override
  String get explainPermissionToAccessVideos =>
      'Twake Chat không đồng bộ dữ liệu giữa thiết bị của bạn và máy chủ của chúng tôi. Chúng tôi chỉ lưu trữ các tệp phương tiện mà bạn đã gửi vào phòng chat. Tất cả các tệp phương tiện được gửi trong chat đều được mã hóa và lưu trữ an toàn. Vào Cài đặt > Quyền và kích hoạt quyền Lưu trữ: Video. Bạn cũng có thể từ chối quyền truy cập vào thư viện phương tiện của mình bất cứ lúc nào.';

  @override
  String get downloading => 'Đang tải';

  @override
  String get settingUpYourTwake =>
      'Đang thiết lập Twake của bạn\nNó có thể mất một thời gian';

  @override
  String get performingAutomaticalLogin =>
      'Thực hiện đăng nhập tự động qua SSO';

  @override
  String get backingUpYourMessage =>
      'Chuẩn bị môi trường máy chủ để sao lưu tin nhắn của bạn';

  @override
  String get recoveringYourEncryptedChats =>
      'Khôi phục các cuộc trò chuyện được mã hóa của bạn';

  @override
  String get configureDataEncryption => 'Cấu hình mã hóa dữ liệu';

  @override
  String get configurationNotFound => 'Không tìm thấy dữ liệu cấu hình';

  @override
  String get fileSavedToGallery => 'Đã lưu tệp vào Thư viện';

  @override
  String get saveFileToGalleryError => 'Không lưu được tệp vào Thư viện';

  @override
  String explainPermissionToGallery(String appName) {
    return 'Để tiếp tục, vui lòng cho phép $appName có quyền truy cập ảnh. Quyền này cần thiết để lưu tập tin vào thư viện.';
  }

  @override
  String get tokenNotFound => 'Không tìm thấy mã đăng nhập';

  @override
  String get dangerZone => 'Khu vực nguy hiểm';

  @override
  String get leaveGroupSubtitle => 'Nhóm này sẽ vẫn còn sau khi bạn rời đi';

  @override
  String get leaveChatFailed => 'Không thể rời khỏi cuộc trò chuyện';

  @override
  String get invalidLoginToken => 'Mã đăng nhập không hợp lệ';

  @override
  String get copiedPublicKeyToClipboard =>
      'Đã sao chép khóa công khai vào bảng nhớ tạm.';

  @override
  String get removeFromGroup => 'Loại bỏ khỏi nhóm';

  @override
  String get removeUser => 'Xóa người dùng';

  @override
  String removeReason(Object user) {
    return 'Xóa $user khỏi nhóm';
  }

  @override
  String get switchAccounts => 'Chuyển đổi tài khoản';

  @override
  String get selectAccount => 'Chọn tài khoản';

  @override
  String get privacyPolicy => 'Chính sách bảo mật';

  @override
  String get byContinuingYourAgreeingToOur =>
      'Bằng cách tiếp tục, bạn đồng ý với chúng tôi';

  @override
  String get youDontHaveAnyContactsYet => 'Bạn chưa có bất kỳ liên hệ nào.';

  @override
  String get loading => 'Đang tải...';

  @override
  String get errorDialogTitle => 'Rất tiếc, đã xảy ra lỗi';

  @override
  String get shootingTips => 'Nhấn để chụp ảnh.';

  @override
  String get shootingWithRecordingTips =>
      'Nhấn để chụp ảnh. Nhấn và giữ để quay hình.';

  @override
  String get shootingOnlyRecordingTips => 'Nhấn và giữ để ghi hình.';

  @override
  String get shootingTapRecordingTips => 'Nhấn và giữ để quay hình.';

  @override
  String get loadFailed => 'Tải thất bại';

  @override
  String get saving => 'Đang lưu...';

  @override
  String get sActionManuallyFocusHint => 'Lấy nét thủ công';

  @override
  String get sActionPreviewHint => 'Xem trước';

  @override
  String get sActionRecordHint => 'Ghi hình';

  @override
  String get sActionShootHint => 'Chụp ảnh';

  @override
  String get sActionShootingButtonTooltip => 'Nút chụp';

  @override
  String get sActionStopRecordingHint => 'Dừng quay';

  @override
  String sCameraLensDirectionLabel(Object value) {
    return 'Hướng ống kính camera: $value';
  }

  @override
  String sCameraPreviewLabel(Object value) {
    return 'Xem trước máy ảnh:$value';
  }

  @override
  String sFlashModeLabel(Object mode) {
    return 'Chế độ đèn nháy: $mode';
  }

  @override
  String sSwitchCameraLensDirectionLabel(Object value) {
    return 'Chuyển sang máy ảnh $value';
  }

  @override
  String get photo => 'Ảnh';

  @override
  String get video => 'Băng hình';

  @override
  String get message => 'Tin nhắn';

  @override
  String fileTooBig(int maxSize) {
    return 'Tệp quá lớn. Hãy chọn tệp có kích thước nhỏ hơn $maxSize MB.';
  }

  @override
  String get enable_notifications => 'Bật thông báo';

  @override
  String get disable_notifications => 'Tắt thông báo';

  @override
  String get logoutDialogWarning =>
      'Bạn sẽ không thể truy cập vào những tin nhắn mã hoá. Hãy bật sao lưu dữ liệu trước khi thực hiện đăng xuất';

  @override
  String get copyNumber => 'Sao chép số';

  @override
  String get callViaCarrier => 'Gọi qua Nhà mạng';

  @override
  String get scanQrCodeToJoin =>
      'Cài đặt ứng dụng di động sẽ cho phép bạn liên lạc với mọi người từ sổ địa chỉ trên điện thoại của bạn, các cuộc trò chuyện của bạn sẽ được đồng bộ hóa giữa các thiết bị';

  @override
  String get thisFieldCannotBeBlank => 'Bắt buộc';

  @override
  String get phoneNumberCopiedToClipboard => 'Số điện thoại đã được sao chép';

  @override
  String get deleteAccountMessage =>
      'Các nhóm chat mà bạn đã tạo sẽ không có quản trị viên trừ khi bạn đã cấp quyền quản trị cho người khác. Người dùng vẫn sẽ có lịch sử tin nhắn với bạn. Xóa tài khoản sẽ không giải quyết được vấn đề.';

  @override
  String get deleteLater => 'Xoá sau';

  @override
  String get areYouSureYouWantToDeleteAccount =>
      'Bạn có chắc chắn muốn xóa tài khoản không?';

  @override
  String get textCopiedToClipboard => 'Văn bản đã được sao chép';

  @override
  String get selectAnEmailOrPhoneYouWantSendTheInvitationTo =>
      'Chọn một địa chỉ email hoặc một số điện thoại để gửi lời mời';

  @override
  String get phoneNumber => 'Số điện thoại';

  @override
  String get sendInvitation => 'Gửi';

  @override
  String get verifyWithAnotherDevice => 'Xác thực với thiết bị khác';

  @override
  String get contactLookupFailed => 'Tìm kiếm liên hệ không thành công.';

  @override
  String get invitationHasBeenSuccessfullySent =>
      'Lời mời đã được gửi thành công!';

  @override
  String get failedToSendInvitation => 'Không gửi được lời mời.';

  @override
  String get invalidPhoneNumber => 'Số điện thoại không hợp lệ';

  @override
  String get invalidEmail => 'Email không hợp lệ';

  @override
  String get shareInvitationLink => 'Chia sẻ liên kết lời mời';

  @override
  String get failedToGenerateInvitationLink => 'Không tạo được liên kết mời.';

  @override
  String get youAlreadySentAnInvitationToThisContact =>
      'Bạn đã gửi lời mời đến liên hệ này';

  @override
  String get selectedEmailWillReceiveAnInvitationLinkAndInstructions =>
      'Email đã chọn sẽ nhận được liên kết lời mời và hướng dẫn.';

  @override
  String get selectedNumberWillGetAnSMSWithAnInvitationLinkAndInstructions =>
      'Số điện thoại đã chọn sẽ nhận được tin nhắn SMS với liên kết lời mời và hướng dẫn.';

  @override
  String get reaction => 'Biểu cảm';

  @override
  String get noChatPermissionMessage => 'Bạn không có quyền gửi tin nhắn.';

  @override
  String get administration => 'Quản trị viên';

  @override
  String get yourDataIsEncryptedForSecurity =>
      'Tin nhắn của bạn đã được mã hoá';

  @override
  String get failedToDeleteMessage => 'Xoá tin nhắn thất bại.';

  @override
  String get noDeletePermissionMessage =>
      'Bạn không có quyền xoá tin nhắn này.';

  @override
  String get edited => 'đã sửa';

  @override
  String get editMessage => 'Sửa tin nhắn';

  @override
  String get assignRoles => 'Phân quyền';

  @override
  String get permissions => 'Quyền';

  @override
  String adminsOfTheGroup(Object number) {
    return 'QUẢN TRỊ VIÊN CỦA NHÓM ($number)';
  }

  @override
  String get addAdminsOrModerators => 'Thêm Quản trị viên/Người điều hành';

  @override
  String get member => 'Thành viên';

  @override
  String get guest => 'Khách';

  @override
  String get exceptions => 'Ngoại lệ';

  @override
  String get readOnly => 'Chỉ đọc';

  @override
  String readOnlyCount(Object number) {
    return 'Chỉ đọc ($number)';
  }

  @override
  String get removedUsers => 'Người dùng bị cấm';

  @override
  String bannedUsersCount(Object number) {
    return 'NGƯỜI DÙNG BỊ CẤM ($number)';
  }

  @override
  String get downgradeToReadOnly => 'Chuyển sang chế độ chỉ đọc';

  @override
  String memberOfTheGroup(Object number) {
    return 'THÀNH VIÊN TRONG NHÓM ($number)';
  }

  @override
  String get selectRole => 'Chọn vai trò';

  @override
  String get canReadMessages => 'Có quyền đọc tin nhắn';

  @override
  String get canWriteMessagesSendReacts =>
      'Có thể viết tin nhắn, gửi biểu cảm...';

  @override
  String get canRemoveUsersDeleteMessages =>
      'Có thể xóa thành viên, xóa tin nhắn...';

  @override
  String get canAccessAllFeaturesAndSettings =>
      'Có thể truy cập tất cả tính năng và cài đặt';

  @override
  String get invitePeopleToTheRoom => 'Mời người vào phòng';

  @override
  String get sendReactions => 'Gửi biểu cảm';

  @override
  String get deleteMessagesSentByMe => 'Xóa tin nhắn của tôi';

  @override
  String get notifyEveryoneUsingRoom => 'Thông báo cho tất cả @room';

  @override
  String get joinCall => 'Tham gia cuộc gọi';

  @override
  String get removeMembers => 'Xóa thành viên';

  @override
  String get deleteMessagesSentByOthers => 'Xóa tin nhắn do người khác gửi';

  @override
  String get pinMessageForEveryone => 'Ghim tin nhắn (cho mọi người)';

  @override
  String get startCall => 'Bắt đầu cuộc gọi';

  @override
  String get changeGroupName => 'Đổi tên nhóm';

  @override
  String get changeGroupDescription => 'Đổi mô tả nhóm';

  @override
  String get changeGroupAvatar => 'Đổi ảnh đại diện nhóm';

  @override
  String get changeGroupHistoryVisibility => 'Đổi quyền hiển thị lịch sử nhóm';

  @override
  String get searchGroupMembers => 'Tìm kiếm thành viên nhóm';

  @override
  String get permissionErrorChangeRole =>
      'Bạn không có quyền thay đổi vai trò. Vui lòng liên hệ quản trị viên để được hỗ trợ';

  @override
  String get demoteAdminsModerators =>
      'Giảm quyền Quản trị viên/Điều hành viên';

  @override
  String get deleteMessageConfirmationTitle =>
      'Bạn có chắc muốn xóa tin nhắn này?';

  @override
  String get permissionErrorBanUser =>
      'Bạn không có quyền cấm người dùng. Vui lòng liên hệ quản trị viên để được hỗ trợ';

  @override
  String get removeMember => 'Xóa thành viên';

  @override
  String get removeMemberSelectionError =>
      'Bạn không thể xóa thành viên có vai trò ngang hoặc cao hơn bạn.';

  @override
  String get downgrade => 'Hạ quyền';

  @override
  String get deletedMessage => 'Tin nhắn đã bị xóa';

  @override
  String get unban => 'Bỏ cấm';

  @override
  String get permissionErrorUnbanUser =>
      'Bạn không có quyền bỏ cấm người dùng. Vui lòng liên hệ quản trị viên để được hỗ trợ';

  @override
  String get transferOwnership => 'Chuyển quyền sở hữu';

  @override
  String confirmTransferOwnership(Object name) {
    return 'Bạn có chắc muốn chuyển quyền sở hữu nhóm này cho $name?';
  }

  @override
  String get transferOwnershipDescription =>
      'Người này sẽ có toàn quyền kiểm soát nhóm và bạn sẽ không còn toàn quyền quản lý. Hành động này không thể hoàn tác.';

  @override
  String get confirmTransfer => 'Xác nhận chuyển';

  @override
  String get unblockUser => 'Bỏ chặn người dùng';

  @override
  String get blockUser => 'Chặn người dùng';

  @override
  String get permissionErrorUnblockUser =>
      'Bạn không có quyền bỏ chặn người dùng.';

  @override
  String get permissionErrorBlockUser => 'Bạn không có quyền chặn người dùng.';

  @override
  String userIsNotAValidMxid(Object mxid) {
    return '$mxid không phải là Matrix ID hợp lệ';
  }

  @override
  String userNotFoundInIgnoreList(Object mxid) {
    return '$mxid không có trong danh sách bỏ qua của bạn';
  }

  @override
  String get blockedUsers => 'Người dùng bị chặn';

  @override
  String unblockUsername(Object name) {
    return 'Bỏ chặn $name';
  }

  @override
  String get unblock => 'Bỏ chặn';

  @override
  String get unblockDescriptionDialog =>
      'Người này sẽ có thể nhắn tin cho bạn và thấy khi bạn đang trực tuyến. Họ sẽ không được thông báo rằng bạn đã bỏ chặn họ.';

  @override
  String get report => 'Báo cáo';

  @override
  String get reportDesc => 'Có vấn đề gì với tin nhắn này?';

  @override
  String get sendReport => 'Gửi Báo cáo';

  @override
  String get addComment => 'Thêm thông tin';

  @override
  String get spam => 'Spam';

  @override
  String get violence => 'Bạo lực';

  @override
  String get childAbuse => 'Lạm dụng trẻ em';

  @override
  String get pornography => 'Nội dung khiêu dâm';

  @override
  String get copyrightInfringement => 'Vi phạm bản quyền';

  @override
  String get terrorism => 'Khủng bố';

  @override
  String get other => 'Khác';

  @override
  String get enableRightAndLeftMessageAlignment =>
      'Bật căn chỉnh tin nhắn trái/phải';

  @override
  String get holdToRecordAudio => 'Giữ để ghi âm.';

  @override
  String get explainPermissionToAccessMicrophone =>
      'Để gửi tin nhắn thoại, hãy cho phép Twake Chat truy cập micrô.';

  @override
  String get allowMicrophoneAccess => 'Cho phép truy cập micrô';

  @override
  String get later => 'Sau';

  @override
  String get couldNotPlayAudioFile => 'Không thể phát tệp âm thanh';

  @override
  String get slideToCancel => 'Trượt để hủy';

  @override
  String get recordingInProgress => 'Đang ghi âm';

  @override
  String get pleaseFinishOrStopTheRecording =>
      'Vui lòng hoàn tất hoặc dừng ghi âm trước khi thực hiện các hành động khác.';

  @override
  String get audioMessageFailedToSend => 'Không gửi được tin nhắn âm thanh.';
}
