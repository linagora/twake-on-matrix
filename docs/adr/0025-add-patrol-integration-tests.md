# 25. Add patrol integration tests

Date: 2024-12-24

## Status

**Accepted**

## Context

 - The need for integration tests to handle real scenarios
 - The need to handle interactions with native views in tests such as notification popups or webviews 
 - Mocking matrix's behaviour using mockito causes a lot of unexpected issues 

## Decision

- Add integration tests using Patrol  

## Consequences

 - Setup patrol locally:
    - Run `dart pub global activate patrol_cli` to enable Patrol CLI
 - Run tests locally:
    - to run tests we use `patrol test -t path/to/test --dart-define=arg1='value' `
    - to run tests in dev mode this will enable hot restarting the tests we use : `patrol test -t path/to/test --dart-define=arg1='value' `
  arguments are passed for each test using `dart-define` as shown above