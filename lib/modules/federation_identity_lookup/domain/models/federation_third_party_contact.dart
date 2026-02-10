import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/utils/string_extension.dart';

abstract class FederationThirdPartyContact extends ThirdPartyContact {
  FederationThirdPartyContact({
    super.matrixId,
    required super.thirdPartyIdType,
    required super.thirdPartyId,
    super.thirdPartyIdToHashMap,
  });

  @override
  List<Object?> get props => [
    matrixId,
    thirdPartyIdType,
    thirdPartyId,
    thirdPartyIdToHashMap,
  ];
}

class FederationPhone extends FederationThirdPartyContact {
  final String number;

  FederationPhone({
    required this.number,
    super.matrixId,
    super.thirdPartyIdToHashMap,
  }) : super(
         thirdPartyIdType: ThirdPartyIdType.msisdn,
         thirdPartyId: number.msisdnSanitizer(),
       );

  @override
  List<Object?> get props => [
    matrixId,
    number,
    thirdPartyIdType,
    thirdPartyIdToHashMap,
  ];

  FederationPhone copyWith({
    String? matrixId,
    Map<String, List<String>>? thirdPartyIdToHashMap,
  }) {
    return FederationPhone(
      matrixId: matrixId ?? this.matrixId,
      number: number,
      thirdPartyIdToHashMap:
          thirdPartyIdToHashMap ?? this.thirdPartyIdToHashMap,
    );
  }
}

class FederationEmail extends FederationThirdPartyContact {
  final String address;

  FederationEmail({
    super.matrixId,
    required this.address,
    super.thirdPartyIdToHashMap,
  }) : super(thirdPartyIdType: ThirdPartyIdType.email, thirdPartyId: address);

  @override
  List<Object?> get props => [
    address,
    matrixId,
    thirdPartyIdType,
    thirdPartyIdToHashMap,
  ];

  FederationEmail copyWith({
    String? matrixId,
    Map<String, List<String>>? thirdPartyIdToHashMap,
  }) {
    return FederationEmail(
      matrixId: matrixId ?? this.matrixId,
      address: address,
      thirdPartyIdToHashMap:
          thirdPartyIdToHashMap ?? this.thirdPartyIdToHashMap,
    );
  }
}
