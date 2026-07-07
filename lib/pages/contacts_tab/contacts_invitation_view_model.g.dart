// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts_invitation_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContactsInvitationViewModel)
const contactsInvitationViewModelProvider =
    ContactsInvitationViewModelProvider._();

final class ContactsInvitationViewModelProvider
    extends
        $NotifierProvider<
          ContactsInvitationViewModel,
          ContactsInvitationState
        > {
  const ContactsInvitationViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsInvitationViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsInvitationViewModelHash();

  @$internal
  @override
  ContactsInvitationViewModel create() => ContactsInvitationViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactsInvitationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactsInvitationState>(value),
    );
  }
}

String _$contactsInvitationViewModelHash() =>
    r'1f6efad6ae4bcd070f66f0d44dc6227959fb5940';

abstract class _$ContactsInvitationViewModel
    extends $Notifier<ContactsInvitationState> {
  ContactsInvitationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<ContactsInvitationState, ContactsInvitationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ContactsInvitationState, ContactsInvitationState>,
              ContactsInvitationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
