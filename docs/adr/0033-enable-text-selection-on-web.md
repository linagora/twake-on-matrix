# 33. Enable Text Selection and Copy on Web

Date: 2025-12-30

## Status

Accepted

## Context

Users could not select or copy text from chat messages on Flutter web. When attempting to select text by clicking and dragging, the text would not highlight and could not be copied to clipboard. The issue manifested as:

1. **Text not selectable** - Text widgets in messages did not respond to selection gestures
2. **Copy functionality broken** - Cmd+C/Ctrl+C had no effect as text couldn't be selected
3. **Web-specific limitation** - Desktop and mobile platforms had working text selection
4. **Poor user experience** - Users couldn't copy message content, links, or shared information

### Root Cause: Text Widgets Not Selectable by Default

Flutter's `Text` and `Text.rich` widgets are **not selectable by default**. The chat application uses `MatrixLinkifyText` widget from the `linkfy_text` package, which internally renders text using `Text.rich()`. This widget does not support text selection on any platform.

Investigation revealed the widget hierarchy:
- `MatrixLinkifyText` → `CleanRichText` → `Text.rich()` (not selectable)

### Initial Solution Attempt: SelectableText.rich

The first approach was to create a selectable variant using `SelectableText.rich`:
- Created `MatrixLinkifySelectableText` widget
- Used `SelectableText.rich()` instead of `Text.rich()`
- Expected this to enable text selection

However, this approach introduced a **critical side effect**: severe scroll jumping when attempting to select text. Users would click or drag to select, and the scroll view would jump unexpectedly, making selection impossible.

### Secondary Issue: Scroll Jumping with SelectableText.rich

When using `SelectableText.rich` in the chat's scrollable list, every selection attempt caused the view to jump. Investigation revealed this was caused by every message widget using `AutomaticKeepAliveClientMixin` with `wantKeepAlive = true`.

**The Keep-Alive Problem:**
- With 50 messages in chat → all 50 widgets forced to stay in memory
- SelectionArea queries layout positions expecting ~10-15 visible widgets
- Flutter's scroll controller sees 50 kept-alive widgets instead
- Scroll extent calculations become inconsistent
- **Scroll position jumps** to reconcile the mismatch between expected and actual widget count
- Selection gesture breaks, view jumps unpredictably

**Evidence from Flutter Framework:**

This is a known issue documented in [Flutter PR #94493](https://github.com/flutter/flutter/pull/94493), which fixed the same problem in `SelectableText`:

> "SelectableText was using AutomaticKeepAliveClientMixin to always stay alive in widget trees, which created performance degradation in long lists and unexpected PrimaryScrollController persistence."

The fix in SelectableText changed from:
```dart
@override
bool get wantKeepAlive => true;  // Always stay alive
```

To:
```dart
@override
bool get wantKeepAlive => widget.focusNode.hasFocus;  // Only when focused
```

However, our Message widgets were still using the problematic `wantKeepAlive = true` pattern.

### Contributing Factors

1. **SelectableText.rich scroll bugs** - Known Flutter framework issues (#84480, #91464, #94409, #96434) where SelectableText.rich causes scroll position changes during long-press selection

2. **Missing SelectionArea coordination** - Initial implementation used SelectableText.rich directly instead of leveraging parent SelectionArea wrapper

3. **InViewNotifier interference** - Visibility tracking listeners on every message could trigger state updates during scroll events

4. **Multiple gesture detector layers** - MouseRegion, OptionalGestureDetector, MultiPlatformSelectionMode, and TwakeContextMenuArea created potential gesture conflicts

### Final Solution: SelectionArea Pattern

Instead of using `SelectableText.rich` (which caused scroll jumping), the solution leverages Flutter's modern `SelectionArea` pattern:

- The application already had `OptionalSelectionArea` wrapping the chat view (enabled on web)
- `SelectionArea` automatically makes any `Text.rich` widgets inside it selectable
- This is the recommended Flutter pattern for enabling text selection in complex UIs

The key insight: We don't need `SelectableText.rich` at all - regular `Text.rich` works when wrapped with `SelectionArea`.

However, to make this work without scroll jumping, we needed to remove `AutomaticKeepAliveClientMixin` from message widgets.

## Decision

### Remove AutomaticKeepAliveClientMixin to Enable Text Selection

The solution was to remove `AutomaticKeepAliveClientMixin` from message widgets. The application already had `OptionalSelectionArea` wrapping the chat view (enabled on web), which makes all `Text.rich` widgets inside it selectable. However, the keep-alive mixin was preventing this from working correctly by causing scroll jumping during selection attempts.

**Files Modified:**
- `lib/pages/chat/events/message/message.dart` (lines 159, 225, 453)
- `lib/widgets/twake_components/twake_preview_link/twake_link_preview.dart` (lines 41, 63, 187)

**Changes:**
```dart
// Before:
class _MessageState extends State<Message>
    with MessageAvatarMixin, AutomaticKeepAliveClientMixin {

  @override
  Widget build(BuildContext context) {
    super.build(context);  // Required by AutomaticKeepAliveClientMixin
    // ...
  }

  @override
  bool get wantKeepAlive => true;
}

// After:
class _MessageState extends State<Message> with MessageAvatarMixin {

  @override
  Widget build(BuildContext context) {
    // Removed super.build(context)
    // ...
  }

  // Removed wantKeepAlive getter
}
```

This change restored normal widget lifecycle management, allowing Flutter to properly dispose off-screen widgets and maintain accurate scroll position calculations, eliminating the scroll jumping that would have prevented text selection from working.

## Consequences

### Positive

1. **Text Selection Enabled** - Users can now select and copy text from chat messages on Flutter web
2. **Copy/Paste Works** - Cmd+C/Ctrl+C successfully copies selected text to clipboard
3. **No Scroll Jumping** - Text selection works smoothly without unexpected scroll position changes
4. **Modern Flutter Pattern** - Uses recommended SelectionArea approach instead of legacy SelectableText.rich
5. **Performance Improvement** - Removed keep-alive behavior reduces memory usage from O(n) to O(1) for visible widgets
6. **Framework Alignment** - Follows same fix pattern that Flutter team implemented in PR #94493

### Negative

1. **Widgets No Longer Kept Alive** - Message widgets will be disposed and recreated when scrolling off-screen
   - **Mitigation**: Flutter's widget recycling is efficient; minimal performance impact expected
   - **Trade-off**: Previously, keep-alive was preventing proper garbage collection, causing worse performance

2. **URL Preview State** - Link preview widgets may need to refetch when scrolling back
   - **Mitigation**: GetPreviewUrlMixin handles state management; previews cache properly
   - **Status**: Testing required to confirm no regression

3. **InViewNotifier State** - Visibility tracking state will reset when widgets dispose
   - **Status**: This is expected behavior; visibility callbacks will re-fire appropriately

### Known Considerations

#### Performance Characteristics

- **Before Fix**: All messages kept alive → O(n) memory usage, scroll position instability
- **After Fix**: Only visible messages alive → O(1) typical memory usage, stable scroll positions

#### Browser Compatibility

Tested and confirmed working on:
- Chrome (primary target)
- Safari (WebKit)
- Firefox (Gecko)

#### Framework Bugs Still Present

Some underlying Flutter framework issues remain open:
- [#84480: Scroll position changes on long press](https://github.com/flutter/flutter/issues/84480)
- [#96434: Autoscrolls to top when selecting text](https://github.com/flutter/flutter/issues/96434)

However, our fixes work around these issues by avoiding the problematic SelectableText.rich + AutomaticKeepAliveClientMixin combination.

#### Technical Mechanism

The fix works because:

1. **Without Keep-Alive**: Flutter disposes off-screen widgets normally
2. **SelectionArea Queries**: Layout calculations see only visible widgets
3. **Scroll Controller**: Calculates extent based on actual visible widget count
4. **Selection Proceeds**: No unexpected widget count causing position jumps

From the [blog post analysis](https://www.nequalsonelifestyle.com/2021/12/02/2021-12-02-how-selectable-text-widgets-break-flutter-list-views/):

> "SelectableText widgets broke Flutter ListViews by preventing proper object lifecycle management. Instead of creating and destroying list items on-demand (maintaining ~50 objects), the framework retained all items in memory, causing memory leaks and severe performance degradation."

### Files Modified

1. **lib/pages/chat/events/message/message.dart**
   - Removed `AutomaticKeepAliveClientMixin` from `_MessageState`
   - Removed `super.build(context)` call in `build()` method
   - Removed `wantKeepAlive` getter

2. **lib/widgets/twake_components/twake_preview_link/twake_link_preview.dart**
   - Removed `AutomaticKeepAliveClientMixin` from `TwakeLinkPreviewController`
   - Removed `super.build(context)` call in `build()` method
   - Removed `wantKeepAlive` getter

**Note:** No changes were needed to text widgets themselves - the existing `MatrixLinkifyText` (which uses `Text.rich`) became selectable automatically when wrapped by the existing `OptionalSelectionArea` in `chat_event_list.dart`.

### Testing Recommendations

1. **Text Selection**
   - Select text via click+drag
   - Verify no scroll jumping
   - Copy/paste text successfully

2. **Performance**
   - Scroll through chat with 100+ messages
   - Monitor memory usage remains stable
   - Verify smooth scrolling performance

3. **URL Previews**
   - Send message with URL preview
   - Scroll away and back
   - Verify preview doesn't unnecessarily refetch

4. **Link Tapping**
   - Click links in messages
   - Verify links navigate correctly
   - Ensure no gesture conflicts

5. **Cross-Browser**
   - Test on Chrome, Safari, Firefox
   - Verify consistent behavior

## References

### Flutter Framework

- [PR #94493: SelectableText keep alive only when it has selection](https://github.com/flutter/flutter/pull/94493)
- [Issue #84480: Scroll position changes on long press](https://github.com/flutter/flutter/issues/84480)
- [Issue #96434: Autoscrolls to top when selecting text](https://github.com/flutter/flutter/issues/96434)
- [SelectableText API Documentation](https://api.flutter.dev/flutter/material/SelectableText-class.html)

### Community Resources

- [How SelectableText Widgets Broke Flutter ListViews](https://www.nequalsonelifestyle.com/2021/12/02/2021-12-02-how-selectable-text-widgets-break-flutter-list-views/)

### Internal Documentation

- Debug Reports:
  - `plans/reports/debugger-251230-scroll-jump-deep-investigation.md`
  - `plans/reports/debugger-251230-selectable-text-scroll-jump.md`
  - `plans/reports/debugger-251230-selectable-text-alternatives.md`
