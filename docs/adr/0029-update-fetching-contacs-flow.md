# 29. Update fetching contacts flow

Date: 2025-08-12

## Status

Accepted

## Context

- ToM `/lookup/match` has been updated, and now provides a merged list of contacts from User Registry + Synced Address Book.
- Hence, application must update/verify its flow of getting the contact list to avoid duplication:
1. Get list from `lookup/match`
2. Get list from local phone book
3. If an entry from ‘2.’ duplicates one from ‘1.’ (same matrixId)
    - Remove item in tom contacts list
    - Keep the item in phone book list and display name is the name in local address book

## Decision

- Remove UI relate to address book
- Keep the logic of fetching contacts from ToM sources for both mobile and web
- After synchronizing with phonebook, remove duplicated contacts in tom contacts

## Consequences

- Fix the problem of duplicated contact in ToM contacts list
- Fix the problem of wrong display name in phonebook contact