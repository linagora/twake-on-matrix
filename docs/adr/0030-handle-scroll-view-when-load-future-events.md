# 30. Handle scroll view when load future events

Date: 2025-11-07

## Status

Accepted

## Context

- When adding items to top of a list in a scroll view, the scroll view tries to maintain the scroll position. Hence, users feel a scroll jump.

## Decision

- Use CustomScrollView with center key and 2 SliverList that grow in different direction
- When loading past events, bottom list is appended
- When loading future events, top list is prepended

## Consequences

- When loading future events, the old events' positions are kept.
