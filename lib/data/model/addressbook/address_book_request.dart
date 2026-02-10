import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:json_annotation/json_annotation.dart';

part 'address_book_request.g.dart';

@JsonSerializable()
class AddressBookRequest with EquatableMixin {
  @JsonKey(name: "contacts")
  final List<AddressBook>? addressBooks;

  AddressBookRequest({this.addressBooks});

  factory AddressBookRequest.fromJson(Map<String, dynamic> json) =>
      _$AddressBookRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddressBookRequestToJson(this);

  @override
  List<Object?> get props => [addressBooks];
}
