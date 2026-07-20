import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/invitation/generate_invitation_link_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/send_invitation_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/store_invitation_status_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contacts_invitation_providers.g.dart';

@riverpod
SendInvitationInteractor sendInvitationInteractor(Ref ref) =>
    getIt.get<SendInvitationInteractor>();

@riverpod
GenerateInvitationLinkInteractor generateInvitationLinkInteractor(Ref ref) =>
    getIt.get<GenerateInvitationLinkInteractor>();

@riverpod
StoreInvitationStatusInteractor storeInvitationStatusInteractor(Ref ref) =>
    getIt.get<StoreInvitationStatusInteractor>();
