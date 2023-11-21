# 11. Workaround for iOS force user re-login

Date: 2023-11-21

## Status

Accepted

## Context

When received a lot of notification in iOS (native notification), sometimes, user can not access the app anymore, need to re-login again.

Root cause: Flutter Secure Storage store Hive-encryption key in KeyChain (iOS), but the accession to KeyChain is not follow the standard way of iOS, missing accessibility flag, not throw the exception, ...

## Decision

Workaround solution: Not use Hive encryption for iOS also

## Consequences

Hive database is not encrypted in iOS
