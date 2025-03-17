import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'address_book.g.dart';

@JsonSerializable()
class AddressBook with EquatableMixin {
  @JsonKey(name: "id")
  final String? id;
  @JsonKey(name: "addressbook_id")
  final String? addressbookId;
  @JsonKey(name: "mxid")
  final String? mxid;
  @JsonKey(name: "display_name")
  final String? displayName;
  @JsonKey(name: "active")
  final bool? active;

  AddressBook({
    this.id,
    this.addressbookId,
    this.mxid,
    this.displayName,
    this.active,
  });

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
      ];
}
