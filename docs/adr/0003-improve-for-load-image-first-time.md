# 3. Improve for load image first time and keep image when scrolling

Date: 2023-06-27

## Status

- Issue: [#220](https://github.com/linagora/twake-on-matrix/issues/220)

## Context

```
GIVE chat has photos sent
WHEN Open chat first time
AND User can scroll to see all photos
THEN the image is loaded and is blinking continuously
```

Inside the `MxcImage` widget, it is intended to display an image. When we use it, it first checks some cases like this:
1. If you have cached image data, the show will call the image from the local side to display it.
2. If you haven't cached image data, you will call the API

Via func `downloadAndDecryptAttachment`

```
Downloads (and decrypts if necessary) the attachment of this
event and returns it as a [MatrixFile]. If this event doesn't
contain an attachment, this throws an error. Set [getThumbnail] to
true to download the thumbnail instead.
```

## Root cause

1. When getting image data it will take an indefinite amount of time. The placeholder and processing icon will first be displayed. 
After we get the image data, we will rebuild the Widget. Currently using setState to rebuild. So during that rebuild, it will be blinking blinking.
2. When we scroll, the image will be rebuilt. So it will be blinking blinking
```
* Reason: 
- In the provided ListView.custom code snippet, the individual child widgets returned by the SliverChildBuilderDelegate will be rebuilt as the user scrolls up or down.
This is because the builder function of SliverChildBuilderDelegate is called to build the child widgets dynamically based on the current scroll position.

- The ListView.custom widget creates a scrollable list view with a custom list of children using the SliverChildBuilderDelegate.
This delegate takes a builder function that is called to build each child widget in the list.

- As the user scrolls, the ListView.custom widget will request new child widgets from the builder function to populate the visible area of the list view. 
The builder function is called repeatedly to create and provide the necessary child widgets based on the current scroll position.

- Therefore, the child widgets in the ListView.custom will be rebuilt dynamically as the user scrolls up or down.
This allows the list view to display the appropriate content based on the current visible area and ensures a smooth scrolling experience.
```

## Decision

1. By using AnimatedSwitcher, you can add visual effects to the transition between different widgets, such as fading, sliding, or scaling animations. 
This can enhance the user experience and provide a more engaging and polished interface. 
In summary, AnimatedSwitcher is used in code to animate the transition between different child widgets based on the value of widget.animated, allowing for a visually appealing and smooth transition effect.

2. By setting wantKeepAlive to true for specific items in the list, you ensure that their state is preserved, allowing them to maintain their data, input values, or any other state-related information. This can be particularly useful for preserving user input, avoiding data loss, or maintaining a continuous user experience.
In summary, when you have scrollable lists or grids and want to preserve the state of specific items even when they are scrolled out of view, using wantKeepAlive can be a good approach to maintain the desired behavior and user experience.

```
However, it's important to use wantKeepAlive judiciously and only for the items that truly require it, as keeping unnecessary items' state alive can impact memory usage. It's recommended to assess the specific needs of your application and carefully choose which items should have their state preserved when scrolling.
```
## Consequences

1. The image will not blink when loading the image for the first time. So behavior is better and smoother
2. When scrolling, the image will loading one time and keep image when scrolling. So behavior is better and smoother
