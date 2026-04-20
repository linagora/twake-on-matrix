# Snippets — Riverpod migration: Invitation module

Concrete migration examples, layer by layer.
Standalone Dart package — sources are in `lib/`, generated files in `snippets_generated/`.

## Generate the files

```bash
cd docs/migration/snippets
dart pub get
dart run build_runner build --output=../snippets_generated
```

The `.freezed.dart` and `.g.dart` files land in `snippets_generated/lib/` without polluting the sources.

## Structure

```
snippets/
  pubspec.yaml
  lib/
    00_legacy.dart                         # Current code — before migration

    # Domain — pure Dart, zero framework dependency
    01_invitation_link.dart                # InvitationLink entity (@freezed)
    02_invitation_status.dart              # InvitationStatus entity (@freezed)
    03_invitation_exception.dart           # Typed exceptions (replaces Either)
    07_invitation_repository.dart          # Repository interface (domain/)
    09_generate_invitation_link_usecase.dart
    10_get_invitation_status_usecase.dart
    11_send_invitation_usecase.dart
    12_invitation_service.dart             # UseCase orchestration

    # Data — implementations
    04_invitation_api_datasource.dart      # API DataSource interface (data/)
    05_invitation_local_datasource.dart    # Local DataSource interface (data/)
    06_invitation_api_datasource_impl.dart # API DataSource impl (data/)
    08_invitation_repository_impl.dart     # Repository impl (data/)

    # Presentation
    13_invitation_state.dart               # State (@freezed sealed class)
    14_invitation_controller.dart          # AsyncNotifier — Riverpod Controller
    16_invitation_page.dart                # ConsumerWidget — Page

    # DI
    15_invitation_providers.dart           # Complete provider chain

    # Tests
    17_invitation_fakes.dart               # Fakes (in-memory DataSource)
    18_invitation_test.dart                # Tests with ProviderContainer

snippets_generated/       ← gitignored, produced by build_runner
  lib/
    01_invitation_link.freezed.dart
    02_invitation_status.freezed.dart
    13_invitation_state.freezed.dart
    14_invitation_controller.g.dart
    15_invitation_providers.g.dart
    ...
```

## Full flow

```
Page (ConsumerWidget)
  └── ref.watch(invitationControllerProvider)    → InvitationState
  └── ref.read(...notifier).generateLink()
        └── InvitationController (AsyncNotifier)
              └── InvitationService (pure Dart)
                    ├── GenerateInvitationLinkUseCase
                    ├── GetInvitationStatusUseCase
                    └── SendInvitationUseCase
                          └── InvitationRepository (domain/ interface)
                                └── InvitationRepositoryImpl (data/)
                                      ├── InvitationApiDataSource
                                      └── InvitationLocalDataSource
```
