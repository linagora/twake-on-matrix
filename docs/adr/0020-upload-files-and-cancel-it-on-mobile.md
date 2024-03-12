# 20. Upload images and cancel it on mobile

Date: 2024-03-12

## Status

In review

## Context

- When uploading an image on mobile, when clicking on the cancel button selects the message instead of cancel the upload.

## Decision

- To address this issue and enhance user experience we use a `mediaCancelTokenMapNotifier`. It has image's filename as key and a new `CancelToken` instance as value then pass the list of values to the `SendMediaInteractor` so it can pass the right `CancelToken` to `room.sendFileEvent`.

- The message widget as been updated to use an `onUploadCancel` method which triggers a `_cancelSending` method. This method will cancel the upload using `cancelToken?.cancel()` and then remove the related event.

- Then the map is cleaned when `ChatEventList` is rebuilt if event has the right status

## Consequences

- In the future we can cancel other types of files cancel passing `SendFilesMixin` to `List<CancelToken> cancelTokens` to `sendFileAction`

- `room.sendFileEvent` is no longer awaited in `send_images_interactor.dart` since it would break the multiple send logic
