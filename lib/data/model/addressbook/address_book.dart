import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'address_book.g.dart';

/// Represents a contact entry from the address book server.
///
/// This model contains comprehensive contact information including:
/// - Identity: [id], [addressbookId], [uid]
/// - Matrix integration: [mxid] (Matrix ID)
/// - Display information: [displayName]
/// - Name components: [firstName], [lastName], [givenName], [sn] (surname)
/// - Email: [emails] list and single [mail] field
/// - Phone: [phones] list and single [mobile] field
/// - Status: [active] flag indicating if the contact is active
///
/// The model supports JSON serialization/deserialization for API communication.
@JsonSerializable()
class AddressBook with EquatableMixin {
  /// Unique identifier for this address book entry.
  @JsonKey(name: "id")
  final String? id;

  /// Alternative identifier from the address book system.
  @JsonKey(name: "addressbook_id")
  final String? addressbookId;

  /// Matrix ID associated with this contact (e.g., @user:server.com).
  @JsonKey(name: "mxid")
  final String? mxid;

  /// Display name for the contact.
  @JsonKey(name: "display_name")
  final String? displayName;

  /// Whether this contact is currently active in the address book.
  @JsonKey(name: "active")
  final bool? active;

  /// User identifier, typically used in LDAP/directory systems.
  @JsonKey(name: "uid")
  final String? uid;

  /// Surname (last name) field, often used in directory systems.
  @JsonKey(name: "sn")
  final String? sn;

  /// Last name of the contact.
  @JsonKey(name: "last_name")
  final String? lastName;

  /// Given name (first name) of the contact.
  @JsonKey(name: "givenName")
  final String? givenName;

  /// First name of the contact.
  @JsonKey(name: "first_name")
  final String? firstName;

  /// List of email addresses associated with this contact.
  @JsonKey(name: "emails")
  final List<String>? emails;

  /// List of phone numbers associated with this contact.
  @JsonKey(name: "phones")
  final List<String>? phones;

  /// Primary email address for this contact.
  @JsonKey(name: "mail")
  final String? mail;

  /// Primary mobile phone number for this contact.
  @JsonKey(name: "mobile")
  final String? mobile;

  AddressBook({
    this.id,
    this.addressbookId,
    this.mxid,
    this.displayName,
    this.active,
    this.uid,
    this.sn,
    this.lastName,
    this.givenName,
    this.firstName,
    this.emails,
    this.phones,
    this.mail,
    this.mobile,
  });

  /// Checks if this address book entry is currently active.
  ///
  /// Returns true if the [active] flag is explicitly set to true,
  /// false otherwise (including null cases).
  bool addressBookIsActive() {
    return active == true;
  }

  factory AddressBook.fromJson(Map<String, dynamic> json) =>
      _$AddressBookFromJson(json);

  Map<String, dynamic> toJson() => _$AddressBookToJson(this);

  @override
  List<Object?> get props => [
    id,
    addressbookId,
    mxid,
    displayName,
    active,
    uid,
    sn,
    lastName,
    givenName,
    firstName,
    emails,
    phones,
    mail,
    mobile,
  ];
}
