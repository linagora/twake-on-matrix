# 28. Improve tag suggestion and display members in group chat detail

**Date:** 2024-12-30

## Status

**Accepted**

## Context

- Issue: [#2165](https://github.com/linagora/twake-on-matrix/issues/2165)
- Not all of the members are displayed in the drop-down list when using the tag suggestion feature.
- Can't load more members in the drop-down list when the user scrolls down.

## Decision

1.1 **Improve tag suggestion feature**
- When the user go to the group chat, call the func to get the members from server of the group chat.
More details about this logic can be found in the [ADR #0005](https://github.com/linagora/matrix-dart-sdk/blob/cb37032f466004500c98949739720b3b4457cc73/doc/adr/0005-support-store-members-in-hive.md).

```dart
 Future<void> _requestParticipants() async {
    if (room == null) return;
    try {
      await room!.requestParticipants(
        at: room!.prev_batch,
        notMembership: Membership.leave,
      );
    } catch (e) {
      Logs()
          .e('Chat::_requestParticipants(): Failed to request participants', e);
    }
  }
```
- Next time when user go to the group chat, the members will be stored in the hive db and get the members from the hive db to display in the drop-down list.
- When the user types the `@` character, the tag suggestion feature will be triggered.

1.2 **Display members in the group chat detail**
- When the user clicks on the group chat, how to display the members?
  1. Display members with a maximum size defined by the `_membersPerPage` variable defined in `chat_details_tab_mixin.dart`.
      ```dart
         static const _membersPerPage = 30;
      ```
  2. If more members can be loaded, display the Load more button at the end of the list.
  3. When the user clicks on the Load more button, call the function to get more members from the Hive database.
      ```dart
        void _requestMoreMembersAction() async {
        final currentMembersCount = _displayMembersNotifier.value?.length ?? 0;
        _currentMembersCount += _membersPerPage;
        
            final members = _membersNotifier.value;
            if (members != null && currentMembersCount < members.length) {
              final endIndex = _currentMembersCount > members.length
                  ? members.length
                  : _currentMembersCount;
              final newMembers = members.sublist(currentMembersCount, endIndex);
              _displayMembersNotifier.value = [
                ...?_displayMembersNotifier.value,
                ...newMembers,
              ];
            } else {
              _displayMembersNotifier.value = [
                ...?_displayMembersNotifier.value,
                ...?members,
              ];
            }
        }
      ```
  4. Each call only takes a maximum of 30 members according to variable `maxMembers`   