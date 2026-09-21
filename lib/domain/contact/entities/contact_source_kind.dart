/// Identifies where a contact value comes from.
///
/// The order of the enum is not a priority order: priority is owned by
/// [ContactResolutionPolicy].
enum ContactSourceKind {
  /// TOM UserInfo API (`/_twake/v1/user_info`): canonical LDAP/directory profile.
  tomUserInfo,

  /// TOM AddressBook API (`/_twake/addressbook`): organisational contacts.
  tomAddressBook,

  /// Device phonebook (via `flutter_contacts`): the user's local alias.
  phonebook,

  /// Matrix profile API (`getProfileFromUserId`): homeserver profile.
  matrixProfile,

  /// Matrix room members: profile derived from joined rooms.
  matrixRoomMember,
}
