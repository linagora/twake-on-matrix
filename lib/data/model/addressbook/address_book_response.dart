import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:json_annotation/json_annotation.dart';

part 'address_book_response.g.dart';

@JsonSerializable()
class AddressbookResponse with EquatableMixin {
  @JsonKey(name: "id")
  final String? id;
  @JsonKey(name: "owner")
  final String? owner;
  @JsonKey(name: "contacts")
  final List<AddressBook>? addressBooks;

  AddressbookResponse({this.id, this.owner, this.addressBooks});

  factory AddressbookResponse.fromJson(Map<String, dynamic> json) =>
      _$AddressbookResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddressbookResponseToJson(this);

  @override
  List<Object?> get props => [id, owner, addressBooks];
}
