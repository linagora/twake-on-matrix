## [2.10.3+2330] - 2025-07-22
### Added
- Add unban user functionality with interactor and UI integration

## [2.10.2+2330] - 2025-07-21
### Fixed
- Enable forced syn contacts

## [2.10.1+2330] - 2025-07-20
### Fixed
- Hot fix for unifiedPush dependency

## [2.10.0+2330] - 2025-07-18
### Added
- #2460 Features assign roles

### Updated
- Display contact status
- #2384 Impl Exceptions tab
- #2454 Upgrade Android API 35

### Fixed:
- #2060 Fix unable to select text in message bubble with mouse on web

## [2.9.8+2330] - 2025-06-25
### Added
- Translation en, ru, fr, vi

### Fixed
- Text selection in web app

## [2.9.7+2330] - 2025-06-20
### Added
- #2411 New splash screens

## [2.9.6+2330] - 2025-06-18
### Fixed
- Update fastlane to build iOS

## [2.9.5+2330] - 2025-06-18
### Added
- #2361 Handle actions in chat base on Permission
- #2348 Recent category for emoji picker
- #2366 Only Admin can Edit group chat
- #2349 Delete message
- #2350 Edit message
- #2367 Asign role list
- #2384 Exception list
- #2393 Removed list
- Translation

### Fixed
- #2735 Violet heart
- #2432 Prevent add the same account in app 
- #2374 Darker in blur screen
- #2377 Filter not support emojies
- #2353 Unifying context menu
- #2345 share media from gallery
- #2357 Mark as read for mute and unmute room
- #2401 Click on internal contact
- #2402 Prevent automatically jump in search message

## [2.9.4+2330] - 2025-05-28
### Fixed
- #2314 Improve generate and share link invitation
- Remove background in avatar

## [2.9.3+2330] - 2025-05-27
### Fixed
- #2314 Only change invitation status when send by mail or phone number

## [2.9.3+2330] - 2025-05-23
### Fixed
- #2356 Add download action in context menu mobile
- #2053 Fix redirect after create chat in mobile
- #2322 Bigger in emoji message
- Translation

## [2.9.2+2330] - 2025-05-20
### Fixed
- Hot fix position of message bubble on mobile

## [2.9.1+2330] - 2025-05-19

### Added

- #2325 Show full emoji picker
- #2329 Display emoji reaction for message
- #2332 Emoji picker for message compose
- #2338 Improve context menu in tablet

### Changed

- Upgrade xcode to v16
- Update dependencies to build with iOS 18
- Update xcode 16 in github work flow
- Upgrade dependencies: remove web rtc, wakelock, http, inappwebview

### Fixed

- #2327 Disable/Enable invitation base on well-known properties
- Prevent rebuild when listen new event
- #2333 Try to logout in mobile in case of Bad URL
- #2334 Remove soft logout logic for mobile
- #2337 Fix SSO logout for web
- #2331 Fix crash when video display in chat with wrong thumbnail information

## [2.9.0+2330] - 2025-05-05
### Added
- Integrate with Cozy

## [2.8.2+2330] - 2025-04-25
### Fixed
- (Mobile) Normalize phone number #2308 #2310
- Generating invitation link not depend on phone number or email
- Changing toast: bottom with close button

### Added
- Emoji picker

## [2.8.1+2330] - 2025-04-18
### Fixed
- Style for Invitation layout
- Hanlde click for contact item

## [2.8.0+2330] - 2025-04-18
### Added
- #2270, #2271, #2272 Invitation

### Fixed
- Delegate cache to browser
- Add gzip and etag headers
- Change client name for web
- Enable device verification
- Fix cache problem make wrong API baseUrl

## [2.7.5+2330] - 2025-03-26
### Fixed
- Disable invitation button 

## [2.7.4+2330] - 2025-03-24
### Fixed 
- Contact synchronization for multiple accounts

## [2.7.2+2330] - 2025-03-21
### Fixed
- Auto refresh in web-app when new addressBook updated
- Resync contacts when new mobile app version upgrade

## [2.7.1+2330] - 2025-03-19
### Fixed
- Add unit tests for ContactManager

## [2.7.0+2330] - 2025-03-19
### Added
- Add default value for Sygnal
- Configurable push gateway with `PUSH_NOTIFICATIONS_GATEWAY_URL`
- Synchronize contact v2
- Integration Vault contact

## [2.6.25+2330] - 2025-02-25
### Fixed
- Translation vi, fr, ru

## [2.6.24+2330] - 2025-02-22
### Fixed
- Update matrix dependency to make sure message keys were uploaded on sync event

## [2.6.23+2330] - 2025-02-21
### Fixed
- Fix build iOS release with new provision profile

## [2.6.18+2330] - 2025-02-19
### Fixed
- [Encryption] Fix timeout for first sync
- [Encryption] Change log level to verbose when enable log
- [Encryption] Remove timeout for loading dialog
- #2215 Fix cannot preview share media

## [2.6.17+2330] - 2025-01-24
### Fixed
- #1139 Toast when copy message
- #2215 Fix can not download file 
- #2214 Navigate when sharing file from 3rd party app

## [2.6.16+2330] - 2025-01-07
### Fixed
- Hotfix: Missing state when deleting avatar in chat details edit

### Changed
- Downgrade ruby to fix building mobile app

## [2.6.15+2330] - 2025-01-03
### Fixed
- #2152 Fix full-word search for unencrypted messages isn't performed until you put a space after the word
- #2111 Fix replies do not appear in search results.
- #2112 Fix bug Remove profile picture / avatar doesn't work
- #2106 Fix duplicate result when adding member with mxid
- #2165 Improve tag suggestion in chat

### Change
- Upgrade gradle to `Xmx4096m`
- #2100 Update image type supported when picking new avatar
- #2151 Support enable/disable context menu Browser
- #2144 Update search result list item
- Update new link support page - [TWP-217](https://github.com/linagora/twake-workplace-private/issues/217) 

### Added
- #2169 Added avatar and name for sender messages in web
- Added widget test for message_avatar_mixin
- #2151 Add a toast message when copying a phone number

## [2.6.14+2330] - 2024-12-06
### Fixed
- [Apple rejection] Add Delete Account button in settings
- [Apple rejection] Remove `Deny` button in permission explaination dialog

## [2.6.13+2330] - 2024-12-06
### Fixed
- Loading dialog when signing in/signing up TWP
- Use appropriate text for permission message

## [2.6.12+2330] - 2024-11-28
### Changed
- Enable log for webapp via environment variable

## [2.6.11+2330] - 2024-11-27
### Fixed
- Fixed issue when packaging linux
- Update width button dialog
- Update input bar for draft chat and chat
- Update send button for draft chat
- #2150 Fix confirm button not displaying when changing group avatar
- #2157 Fix can't mark a chat as unread
- #2154 Fix no counter of unread messages for muted chats
### Changed
- #1927 Change animation for Search screen for mobile


## [2.6.10+2330] - 2024-11-20
### Fixed
- Handle default QR code link

## [2.6.9+2330] - 2024-11-20
### Fixed

- #2099 Fix design review v2.6.7
- #2018 Changed power levels in group chats
- #2122 Fix group information disappeared
- #2113 Fix text message overlaps time stamp in message bubble
- #2124 Fixed wrong url when using logout
- #1849 Fix bug weird grey counter sometimes appears
- #2068 Fix can't see message after accept invitation
- #2065 Remove save to gallery button in web

### Added

- #2014 Display phone number as a clickable in message bubble
- #2128 Implement QR code to download app
- #2088 Systemize app bar
- Improve style for error dialog (#2136)
- #2046 Add Group name validation

## [2.6.8+2330] - 2024-11-13
### Changed

- Integrate with TWP production

## [2.6.7+2330] - 2024-10-18
### Fixed

- Fix redirect path in web app

## [2.6.6+2330] - 2024-10-16
### Fixed

- Fix cancel button in forward screen on web
- #2075 Fix upload avatar on web
- #2067 Fix location path on web
- Fix wrong highlight message when open chat

### Added

- #2039 Update readme with customized homeserver
- #2077 Update markdown when send message in chat
- #2057 Update contacts screen ui
- #2086 Change texts in settings screen
- #2082 Update composer UI
- Added support for nginx port customization
- Added support for base href customization
- #2040 Update settings UI

## [2.6.5+2330] - 2024-09-19
### Fixed
- 2 types of Chat: Chat and Group Chat

## [2.6.4+2330] - 2024-09-18

### Added

- #1817 Added french and russian translation in camera screen
- Set uploaded appbundles status to completed
- #1813 Change event description for pinned files
- #1980 Convert HEIC files to jpg file
- #1886 Update chat list UI part 1
- #1972 Update logic for cancel upload files with captions
- #1968 Break UI when search with keyword
- #1542 make message highlight brighter
- Translate ru, fr, vi

### Fixed

- #1878 Fix can't open notification when open Media in chat details
- #1918 Fixed typo error in externalContactMessage
- #1994 Fix load more for chat search
- #1844 Fix distorted images when using camera in android phone
- #2001 No previews for video
- #1974 Fix cannot jump to reply
- #1982 Fix can't create direct chat when search in contact tab
- #1936 Fix the share screen don't show up when sharing an image
- #1926 Permission is always asked when paste in iOS
- #1963 Update search keyword matching
- #1878 Fix can't open notification when open Media in chat details

## [2.6.3+2330] - 2024-09-17

### Fixed

- #2022 Change explain text in permission dialog

## [2.6.2+2330] - 2024-08-27

### Fixed

- #2002 Remove unused deeplink
- #2002 Upgrade flutter_local_notifications to fix USE_FULL_SCREEN_INTENT permission

## [2.6.1+2330] - 2024-07-25

### Fixed

- #1959 Spelling errors
- #1966 Hotfix: can't get contact on web
- #1976 Hotfix: prominent disclosure update
- #1971 Fix navigation problem in forward pages
- #1979 Crash app when open play video mobile
- #1967 Support send multiple file in draft chat

## [2.6.0+2330] - 2024-07-18

### Fixed

- #1879 Fix online status is not updated correctly
- #1892 Handle error recovery key lost
- #1898 Fix memory leak in file picker
- #1897 Fix profile image is not updated in multiple account
- #1903 Check dialog status before sending file
- #1911 Fix can't open chat when search exact Matrix ID
- #1921 Fix iOS is forced to log out many times
- #1910 Remove x when searchbar is empty 
- #1938 Fix wrong responsive when size of screen is small
- #1930 Improve search exact Matrix ID inside Contact tab
- #1948 Fix jump exactly to message in the notification on Mobile
- #1946 Fix 500,404 error in POST request when login

### Added

- #1940 Upload feature
- #1890 Renamed artifact to describe the OS
- #1880 Standarlize Appbar and Appgrid popup
- #1889 Change style loading dialog
- #1894 Change message info dialog close button
- #1905 Update online status based on design
- #1937 Improve style for backup dialog
- #1951 Integration dynamic link on android mobile
- #1944 Update quick actions
- #1956 Create permission dialogs for contacts and media

## [2.5.8+2330] - 2024-05-25
- #1781 Upgrade to Flutter SDK 3.22.0

## [2.5.5+2330] - 2024-05-25

### Fixed
- #1526 cannot unmute more than 2 chats
- #1785 Improve logout for multiple accounts

### Added
- #1722 Recents contacts for contact/search/create group chat screen
- #1735 Search external contact in search screen
- #1780 add parameter `app=chat` when connect with TWP platform

## [2.5.3+2330] - 2024-05-19

### Fixed
- #1650: Memory leak problems: Web and Mobile app
- #1696: Change app icon 
- Change log format
- Update new push gateway service 
- #1768 Integrate SaaS for mobile app

## [2.5.2+2330] - 2024-05-03

### Fixed

- #1573 Save media to gallery
- #1461 Update app language setting subtitles
- #1666 Fix Filename does not resize and time overlapping
- #1693 Delete the encrypted file after downloading it
- #1719 Fix can't tag name on mobile
- #1702 DownloadErrorPresentationState added handle errors
- #1727 Update login with `matrix.org` homeserver
- #1728 Fix can't logout on registration site
- #1658 Fix small bugs
- #1711 Handle deep link from registration platform
- #1734 Fix bugs pre-prod

### Added

- #1584 Sent files in room
- #1695 Leave group

## [2.5.0+2330] - 2024-04-15

### Fixed
- #1435 Remove Big dot in message notification
- #1453 Error handling update profile failed
- #1565 Icon for avi, wmv
- unpin icon in context menu
- #1124 Profile Info view for Direct Chat (avatar)
- #1564 improve video player
- #1453 video player for web
- unpin icon for app bar
- Pin bottom sheet in mobile
- #1567 Prevent show hover, actions in sending or error message
- #1543 Fix cannot attach file
- #1380 updat AppLifeCycle for Twake Web
- #1544 Prevent create direct multiple times
- remove colorFilter of TwakeIconButton
- #1581 preview unknown file
- Highlight tag with link in message bubble
- Handle multiple download for web
- #1456 change profile info UI in member list of Group info
- #1589 Search with link content
- #1578 swipe to back in search screen (mobile)
- #1656 fix user can not mark as read/unread some chat
- Fix can not get fix on web
- #1662 Fix can not send video/picture by camera
- #1497 Filter chat in forward list
- #1523 Chat setting align in view
- #1678 Prevent blink blink in preview link
- Save to files (mobile)
- #1675 Online status is not stable
- #1621 Improve forward screen (mobile/web)

### Added
- Integrate registration (mobile/web)
- Multiple accounts support
- Improve Download with queue
- Cancel downloading

## [2.4.21+2330] - 2024-03-18

### Fixed

- Prevent infinite loading when open chat

## [2.4.20+2330] - 2024-03-15

### Fixed

- \#1480 Try to request more history when open room first time
- \#1400 some permission is applied to all member in group chat
- \#1503 Update time format for same week
- \#1469 Cursor for composer when reply message
- \#1498 Improve preview to make jump to chat exactly
- \#1442 Consistent Context menu style
- \#1519 Automatically synchronize pin/unpin
- \#1439 Change avatar size for group information
- \#1499 Add Download option to video player
- \#1406 Go back in Search inside chat
- \#1551 Remove Duplicated contact base on the format
- \#1414 Do SSO in the same window of the app, prevent show popup
- \#984 App Grid
- \#1504 prevent show notification in web if chat is muted
- \#1524 Remove hover in timestamp/time block in chat
- \#1539 Condition to prevent show no result when still have result in search
- \#1545 Dismiss keyboard in multiple screen have focus
- \#1421 Update texts term in UI
- \#1553 Remove content\_related when forwarding
- \#1527 Can not jump to the bottom after jump from shared media or links
- \#1369 Bottom action menu for Pin screen in mobile
- \#1380 Try to sync when web app get focus
- \#1543 Can not attach file in iOS
- Translate French, German, Russuan, Vietnamese

## [2.4.19+2330] - 2024-02-27
### Fixed
- \#1457 Handle predictive back
- \#1308 handle pop scope for back button
- \#1492 handle performance in rebuilding in Chat list
- \#1269 Play video in safari
- \#1455 handle Micro permission for iOS and Android in Image Picker
- \#1472 Prevent select video in change avatar
- \#1425 Update title position
- \#713 Jump from media list to chat
- \#1153 Prevent duplicated phone number

## [2.4.18+2330] - 2024-02-19

### Fixed

- Translated using Weblate (French)
- Translated using Weblate (Vietnamese)
- \#1152: Support can search by email on chat list
- Update code owner for project
- \#1450: fix greating popup input text sync
- \#1031: Improve Emoji Picker
- hot-fix: reenable context menu in mobile and other devices
- \#1271: Update UI for dialog invitation
- \#1240: Use try catch for `ValueNotifier`
- \#1423: Update padding for reply content
- \#1314: Change format date time from MM/dd/yy to dd/MM/yy
- \#1196: Update display pill with display name
- \#1394: Add Slidable Chat List Item - Mute/Unmute
- improve perf: change MediaQuery.of to sizeOf to reduce rebuild
- \#217: update new UX for share and forward screen
- \#344: Using visibility_detector for detect message in chat and display sticky timestamp
- \#1429: change Clipboard to TwakeClipboard
- \#1442: Harmonize Context Menu Styles across the app
- \#1371: Improve selection message behavior
- \#1360: Add Slidable Chat List Item - Read/Unread
- \#1402: cannot tag user in safari
- \#1381: Improve send_file_dialog component
- Update background color for all app
- \#1437: Update bottom navigator bar
- \#1418: Sort languages in alphabetical order and start them with a capital letter
- \#1412: Change naming in other users' profile information
- \#1437: Remove extra text in for profile information
- \#1437: Disable More button when select message in chat list
- \#1437: Remove emote settings
- \#1437: Remove chat folders button in settings
- \#1437: Disable location and contact button
- \#382: remove auto fill chat group name
- hot-fix: hover at link only
- \#1297: Improve for hide/show btn delete avatar in edit group
- \#1383: Update position of context menu in edit group
- \#888: Add unit test for `ContactsManager`
- \#1411: Update padding for no search result in selection members
- \#1411: Improve for search no result in create chat
- fix: invitation text after getting new room events
- \#1359: Add Slidable Chat List Item - Pin/Unpin
- fix: clear selection bottom bar after done on mobile

## [2.4.16+2330] - 2024-01-31

### Added

- Add test widget for Twake Preview Link

### Fixed

- Padding in new group chat
- Padding in inviation member screen
- Update Members list when have changes in Chat
- \#1283 Handle refresh pinned list
- handle hover to link, mention tag
- \#1328 Change bullet point size
- \#1165 Change the way of marking read
- \#1351 Draft Chat catch pharse
- \#1354 handle arrow keyboard in composer and suggestion in web app
- \#1358 remove unnecessary selection
- \#1358 fix thumbnail size
- \#1349 auto focus in composer
- comeback to the original solution of break line

## [2.4.15+2330] - 2024-01-16
### Fixed
- Change date format to dd/mm/yy
- Create chat in blank page
- Cancel file picker in web
- Fixed crashed when reject invitation
- \[web\] Open current chat when stay in profile
- fixed width of chat along side with width of composer
- Remove back button in some screen in web only
- Fix Shift + Enter
- Hide event join of author in chat
- Added no result in search
- Fix new group and invitation padding
- Group info style
- Fix navigation in mobile

## [2.4.14+2330] - 2024-01-07
### Fixed
- Hide tag suggestion in Direct Chat

## [2.4.12+2330] - 2024-01-05
### Added
- upgrade flutter 3.16.5
- paste multiple images to web platform

### Fixed
- change solution to copy/paste in composer
- handle receive login token in direct URL

### Removed
- location, geolocator related functions
- microphone usage

## [2.4.10+2330] - 2023-12-27

### Added

- jump to unread message in chat
- new group information
- show list of pinned message
- Load more and jump to message in server side search
- New starting page
- Share multiple files from external apps
- Send multiple file
- Send multiple file with thumbnail

### Changed

- Change iOS target to 12

### Fixed

- Remove unuse event in htmlMessage
- overflow in height in reply container
- image not change when changing reply image message
- go to direct chat when click on avatar
- centering logo in homepicker
- increase video player hit box

## [2.4.6+2330] - 2023-12-12
### Fixed
- Context menu in Chat screen
- build NSE with new Xcode

## [2.4.5+2330] - 2023-12-11

### Added

- Create unencrypted Direct Message
- Preview image before sending
- Search for unencrypted message
- Add NSE to get plain notification
- profile info

### Changed

- new app id
- Jump to message
- Refactor Message widget
- Update correct style for app

### Fixed

- thumbnail image in preview link

## [2.4.2+2330] - 2023-11-28

### Added

- Change language
- Quoted image

### Fixed

- Fix select text

## [2.4.1+2330] - 2023-11-28

### Added

- Translation

### Fixed

- Force re-login again and again in iOS
- Change the same term of profile page
- Remove trying to load thumbnail again and again
- Use Active instead of Online
- Fixing cannot play sending video
- Remove hero animation
- Change color of Active status
- Search in forward to screen

## [2.4.0+2330] - 2023-11-20
### Added
- Translation
- Profile Information
- Synchronize phonebook contact with the app

### Changed
- new App icon
- New tag in chat
- Aplly new M3

### Fixed
- Popup with wrong context
- Select text with mouse in web app
- Click notification in web to open room
- Fix cut and paste button in composer

## [2.3.7+2330] - 2023-11-09
### Changed
- Download file in mobile/desktop base on file stream
- upgrade matrix sdk to 0.22.6
- New design for pin message

### Fixed
- Twake dialog
- Remove avatar

## [2.3.6+2330] - 2023-11-03
### Added
- Translate Fr,En,Ru
- Create Chat without encryption

### Changed
- upgrade flutter to 3.13.7
- use google font
- upgrade android 34
- New preview\_link widget
- Search inside Chat

### Fixed
- fix inline markdown code
- scroll full screen GroupInfo
- fix search with case sensitive
- close custom tab after login

## [2.3.3+2330] - 2023-10-18
### Added
- enable emoji in web
- styling for Chat List
- new selection in chat list
- copy/paste in Chat
- update avatar in responsive screen
- Shift+Enter

### Fixed
- keyboard handling when scrolling chat
- click on notification redirect to exact message

## [2.3.2+2330] - 2023-10-06
### Added
- New Settings screeen
- Load more error

### Fixed
- blink when scrolling chat
- UI chat wrong
- error in clear DB when logout in web
- drag n drop in web
- gesture to back

## [2.3.1+2330] - 2023-09-29
### Fixed
- loading in search inside app
- chat list selection
- video player
- focus in connect page
- upload thumbnail and calculate blur hash

## [2.3.0+2330] - 2023-09-25
### Added
- Download file in all platform
- Context menu for web
- Search insie App
- New group chat info
- New selection for Chat List
- New video player

### Changed
- Filter event in Chat
- Change preview link based on Matrix API

### Fixed
- Show/Hide emoji picker
- Navigator context
- Update Thumbnail with correct size
- Fix Delivery status
- Improve backup process for not only mobile but also web

## [2.2.4+2330] - 2023-09-08
### Added
- Chat with external contact
- Translation for Fr/Ru

### Changed
- Support exactly image picker for user
- Change the logic of path and navigation in web app
- sendOnEnter by default in web
- Change logic of deliver status
- New UI for Chat Details

### Fixed

- Prepare for debug web
- Show error message at exactly position
- Dismiss keyboard base on the behavior
- Reduce unnecessary API request to Profile API
- Fix the placeholder for image to reduce memory consumption

## v2.2.3 - 2023-08-21

### Added

- Search for Chats and Contacts

### Changed

- Change and fix UI issue

## v2.2.0 - 2023-08-08

### Fixed

- Notification for iOS in terminated/background/foreground state

### Added

- Uploading encrypted file on stream instead of on memory

### Changed

- Change navigator library: Go\_route
- Support new mechanism in Desktop Layout
- Change and fix UI issue

## v2.1.6 - 2023-07-23

### Fixed

- ImagePicker's bottom sheet issue

### Added

- Load more contacts in ToM service
- Link preview in message bubble
- Integrate with new Sygnal instance
- Open contact instead of Create Chat when click on a contact
- Handle upload Chat icon when creating new Chat

### Changed

- Handle permission for Camera and update send image
- Relative time stamp in message bubble
- Preview image
- Change and fix UI issue

## v2.1.4 - 2023-06-27

### Added

- Create new Chat
- Create Direct Chat
- Integrate with ToM recovery Vault
- Sending multiple media files with new Image Picker

### Changed

- Change and fix UI issue

## v2.1.1 - 2023-06-27

### Added

- Add ImagePicker to select image from gallery or camera
- Destination picker for Forwarding message

### Changed

- Change and fix UI issue
- Push notification configuration

## v2.0.2 - 2023-05-23

### Added

- Dependency Injection with GetIt
- Support Linagora Design System
- Integrate with ToM service

### Changed

- Time in Message bubble
- Change the App bar in Chat List
- Change the UI of Chat List and Chat screens
- Update Kotlin version

## v1.10.0 - 2023-02-25

- Added translation using Weblate (Thai) (Wphaoka)
- Added translation using Weblate (Tibetan) (Nathan Freitas)
- Default hardcoded message when l10n is not available (fabienli)
- Fix: The stable repo fingerprint (TODO the qr-code should be updated) (machiav3lli)
- Translated using Weblate (Basque) (xabirequejo)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (French) (Anne Onyme 017)
- Translated using Weblate (Galician) (josé m)
- Translated using Weblate (Galician) (josé m)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Japanese) (Suguru Hirahara)
- Translated using Weblate (Persian) (Farooq Karimi Zadeh)
- Translated using Weblate (Swedish) (Joaquim Homrighausen)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- chore: Disable stable for web until script is fixed (Krille)
- chore: Display warning when logout without backup (Krille)
- chore: Downgrade flutter CI version (Krille)
- chore: Follow up audioplayer on linux (Krille)
- chore: Follow up chat encryption desgin (Krille)
- chore: Follow up fix audioplayer on android (Christian Pauly)
- chore: Follow up formatting (Christian Pauly)
- chore: Follow up formatting (Krille)
- chore: Follow up remove hero animation (Krille)
- chore: Follow up secrity settings design (Krille)
- chore: Follow up settings page (Krille)
- chore: Follow up settings page design (Christian Pauly)
- chore: Follow up style adjustments (Krille)
- chore: Lookup l10n in pushhelper if null (Krille)
- chore: Update matrix package to 0.17.0 (Krille)
- chore: Update to Flutter 3.7.1 (Krille)
- docs/qr-stable.svg: update the QR code (Aminda Suomalainen)
- feat: Enable audioplayer for web and linux (Christian Pauly)
- fix: Display error when user tries to send too large file (Christian Pauly)
- refactor: Do only instantiate AudioPlayer() object when in use (Christian Pauly)
- refactor: Remove syncstatus verbose logs (Christian Pauly)
- refactor: Store cached files in tmp directory so OS will clear file cache from time to time (
  Krille)
- style: Adjust key verification dialog (Christian Pauly)
- style: Bootstrap design adjustments (Christian Pauly)
- style: Encryption page adjustments (Christian Pauly)
- style: Enhance user device settings design (Krille)
- style: Enhanced chat details design (Krille)
- style: Give chat list list tiles rounded corners (Krille)
- style: Link underline color (Christian Pauly)
- style: Make adaptive bottom sheets scrollable by default (Krille)
- style: Make invite page more pretty (Krille)
- style: New settings design (Krille)
- style: Nicer chips in encryption settings and icons showing device status (Krille)
- style: Use emojis on web as well (Christian Pauly)
- style: Use robotomono to display device keys (Christian Pauly)
- utils/url\_launcher: force opening http(s) links in external browser (Marcus Hoffmann)

## v1.9.0 - 2023-01-29

- Translated using Weblate (Czech) (Michal Bedáň)
- Translated using Weblate (Czech) (grreby)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Galician) (josé m)
- Translated using Weblate (German) (Christian)
- Translated using Weblate (German) (Vri 🌈)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Korean) (Youngbin Han)
- Translated using Weblate (Polish) (Wiktor)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- chore: Change invite link textfield label (Krille)
- chore: Remove unused dependency (Krille)
- chore: Remove unused translations (Krille)
- chore: Update Matrix SDK and refactor (Krille)
- chore: Update dependencies (Krille)
- chore: Update flutter\_map (Krille)
- chore: add integration tests (TheOneWithTheBraid)
- chore: add integration tests for spaces (TheOneWithTheBraid)
- design: More clear chat background and rounded popup menu (Krille)
- design: Nicer navigationrail (Krille)
- design: Upgrade to Flutter 3.7
- feat: Bring back disabling the header bar on Linux desktop (q234rty)
- feat: Nicer design for abandonded DM rooms (Christian Pauly)
- fix: Archive (Krille)
- fix: Shared preferences package for flutter 3.7 (Christian Pauly)
- fix: permission of web builds (TheOneWithTheBraid)
- fix: Notification Settings (Krille)
- refactor: Migrate to Flutter 3.7.0 (Christian Pauly)
- refactor: Same animations everywhere in app (Krille)
- refactor: Stories header with futurebuilder (Krille)
- refactor: disable some redundant tests (TheOneWithTheBraid)
- style: Animate in out search results (Krille)
- style: New modal bottom sheets (Krille)
- style: Redesign public room bottomsheets (Krille)

## v1.8.0 2022-12-30

- Added translation using Weblate (Yue (yue\_HK)) (Raatty)
- Translated using Weblate (Chinese (Simplified)) (Mike Evans)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (French) (Anne Onyme 017)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- design: New encryption page (Krille Fear)
- feat: Add audio message support to linux (Krille Fear)
- feat: Use Android system accent color (Krille Fear)
- feat: include olm to Windows builds (TheOneWithTheBraid)
- feat: Store drafts (Krille)
- fix: Android push notification follow-up (TheOneWithTheBraid)
- fix: Content banner (Krille Fear)
- fix: Correct redacted by username (Krille Fear)
- fix: Do not setup push on every app resume (Krille Fear)
- fix: Encryption button is orange in public rooms (Krille Fear)
- fix: File event design (Krille Fear)
- fix: Hide google services warning after marked (Krille Fear)
- fix: Improve story page appearance (Reinhart Previano Koentjoro)
- fix: Libhandy windows (Krille Fear)
- fix: Monochromatic icon rendering for Android 13+ (Reinhart Previano Koentjoro)
- fix: homeserver error text not visible in app bar (TheOneWithTheBraid)
- fix: minor issues in room list (TheOneWithTheBraid)

## v1.7.2 2022-12-19

Update dependencies and translations.

## v1.7.1 2022-11-23

Minor bugfix release to retrigger build for FlatPak and Android. Fixes some style bugs and updates
some translations

## v1.7.0 2022-11-17

FluffyChat 1.7.0 features a new way to work with spaces via a bottom navigation bar. A lot of work
has also been done under the hood to make the app faster and more stable. The main color has
slightly changed and the design got some finetuning.

- chore: Add keys to roomlist and stories header (Christian Pauly)
- chore: Add unread badge to navigation rail and adjust design (Christian Pauly)
- chore: Adjust colors (Christian Pauly)
- chore: Better design chat list items (Christian Pauly)
- chore: Better load first client (Christian Pauly)
- design: Hide unimportant state events instead of folding (Christian Pauly)
- design: Improve login design (Krille Fear)
- design: Nicer display notification short texts (Christian Pauly)
- feat: background and terminated calls \[android\] (td)
- feat: New navigation design (Christian Pauly)
- fix: Hide password at login page (Krille Fear)
- fix: Import session on iOS (Christian Pauly)
- fix: incorrect setState inside setState in ChatListController (td)
- fix: Password not obscure for a second when submitting login textfield (Christian Pauly)
- fix: Popup menu without elevation (Christian Pauly)
- fix: Push error message (Christian Pauly)
- fix: Remove emoji picker workaround (Christian Pauly)
- fix: Set theme after start app (Christian Pauly)
- fix: Settings profile picture (Christian Pauly)
- fix: Share files (Christian Pauly)
- fix: UIA request handler (Christian Pauly)
- fix: Update emoji picker for web and desktop (Christian Pauly)
- improved (most) icons/image scaling, including avatar scaling (Mg138)
- Mention Element instead of Riot (Has been renamed about a year ago) (jooooscha)
- refactor: Chat list body code (Christian Pauly)
- refactor: Minor chatlist refactoring (Christian Pauly)
- refactor: No longer need selected of chat list tile (Christian Pauly)
- refactor: Remove unused dependencies (Krille Fear)
- Added translation using Weblate (Hindi) (Hemish)
- Added translation using Weblate (Occidental) (OIS)
- Translated using Weblate (Basque) (xabirequejo)
- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Chinese (Simplified)) (Raatty)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (English) (Raatty)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Estonian) (Raatty)
- Translated using Weblate (Finnish) (Aminda Suomalainen)
- Translated using Weblate (Finnish) (Raatty)
- Translated using Weblate (French) (Anne Onyme 017)
- Translated using Weblate (Galician) (Xosé M)
- Translated using Weblate (German) (Jana)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Lithuanian) (Anonimas)
- Translated using Weblate (Occidental) (OIS)
- Translated using Weblate (Persian) (Anastázius Darián)
- Translated using Weblate (Persian) (Anastázius Kaejatídarján)
- Translated using Weblate (Persian) (Seyedmahdi Moosavyan)
- Translated using Weblate (Russian) (Nikita Epifanov)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Turkish) (Raatty)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- Translated using Weblate (Ukrainian) (Raatty)

## v1.6.4 - 2022-09-08

- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Galician) (Xosé M)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Slovak) (Marek Ľach)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- chore: Adjust bubble color in dark mode (Christian Pauly)
- chore: Update matrix sdk (Christian Pauly)
- chore: Update to flutter 3.3.0 (Christian Pauly)
- feat: Automatic key requests and better key error dialog (Christian Pauly)
- fix: Styling and notification settings (Christian Pauly)
- fix: add missing command localizations (Christian Pauly)

## v1.6.3 - 2022-08-25

- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Finnish) (Aminda Suomalainen)
- Translated using Weblate (Russian) (Sergey Shavin)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- chore: Migrate back to flutter hive collections (Christian Pauly)
- chore: Update provider package and remove dep override (Christian Pauly)
- fix: Do not display push events for unknown event types (Christian Pauly)
- refactor: App widget (Christian Pauly)

## v1.6.0 - 2022-07-31

FluffyChat 1.6.0 features a lot of bug fixes and improvements. The code base has been
simplified and the drawer on the chat list page got a come-back. Some new features like
the space hierarchy and session dump have been implemented.

- feat: Added monochrome entry for themed icon support in Android 13 (James Reilly)
- feat: Display timeline of messages in android notification (Christian Pauly)
- feat: Emoji related fixes (TheOneWithTheBraid)
- feat: Implement deleting pushers in app (Christian Pauly)
- feat: New material 3 design (Christian Pauly)
- feat: Redesign bootsstrap and offer secure storage support (Christian Pauly)
- feat: Send multiple images at once (Christian Pauly)
- feat: implement session dump (TheOneWithTheBraid)
- feat: implement space hierarchy (TheOneWithTheBraid)
- feat: introduce extended integration tests (TheOneWithTheBraid)
- feat: libhandy integration (TheOneWithTheBraid)
- fix: Clearing push triggered when only one room got seen (Christian Pauly)
- fix: Dont display loading dialog when adding reaction (Christian Pauly)
- fix: Follow up for spaces hierarchy (TheOneWithTheBraid)
- fix: Missing null checks in chat details view (Christian Pauly)
- fix: Non FCM Android builds crash on start (Christian Pauly)
- fix: Permission chooser dialog on iOS (Christian Pauly)
- fix: Set avatar on only single action available (Christian Pauly)
- fix: Sharing on iOS and iPad (Christian Pauly)
- fix: Unread bubble is invisible in dark mode (Christian Pauly)
- fix: appimage builds (TheOneWithTheBraid)
- fix: only use custom http client on android (Jayesh Nirve)
- fix: pass isrg cert to http client (Jayesh Nirve)
- refactor: Chat view (Christian Pauly)
- refactor: Encryption button (Christian Pauly)
- refactor: Remove duplicated imports (Christian Pauly)
- refactor: Remove legacy store (Christian Pauly)
- refactor: Remove presence status feature (Christian Pauly)
- refactor: Simplify MxcImage and replace CachedNetworkImage (Christian Pauly)
- refactor: Switch to Hive Collections DB (Christian Pauly)
- refactor: move start chat FAB to implementation file (TheOneWithTheBraid)
- Translated using Weblate (Catalan) (Alfonso Montero López)
- Translated using Weblate (Catalan) (Auri B.P)
- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Croatian) (Milo Ivir)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (English) (Raatty)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Finnish) (Aminda Suomalainen)
- Translated using Weblate (Galician) (Xosé M)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Persian) (Amir Hossein Maher)
- Translated using Weblate (Polish) (Przemysław Romanik)
- Translated using Weblate (Russian) (Nikita Epifanov)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- chore: Add border to avatars (Christian Pauly)
- chore: Add fancy hero animations (Christian Pauly)
- chore: Adjust appbar design (Christian Pauly)
- chore: Adjust design (Christian Pauly)
- chore: Adjust search bar design (Christian Pauly)
- chore: Always display header elevation in chat (Christian Pauly)
- chore: Design follow up fixes (Christian Pauly)
- chore: Design follow up fixes (Christian Pauly)
- chore: Disable integration tests without runners (Krille Fear)
- chore: Enhance invitiation UX (Christian Pauly)
- chore: Make push helper more fail safe (Christian Pauly)
- chore: Make push helper more stable (Christian Pauly)
- chore: Minor design improvements (Christian Pauly)
- chore: Pinned events design (Christian Pauly)
- chore: Remove permission handler dependency and increase compileSdkVersion (Christian Pauly)
- chore: Switch to flutter 3.0.5 (Krille Fear)
- chore: Update SDK (Christian Pauly)
- chore: remove snapping sheet (TheOneWithTheBraid)

## v1.5.0 - 2022-06-03

- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- feat: Better sign up UX and allow signup without password (Christian Pauly)
- feat: Initial material you support (Christian Pauly)
- feat: include Synapse into integration test (TheOneWithTheBraid)
- fix: Broken dynamic color palette (Christian Pauly)
- fix: Build on iOS emulator (Christian Pauly)
- fix: Missing bottom padding in text only stories (Christian Pauly)
- fix: Send sticker without blocking the UI (Christian Pauly)
- fix: Sentry switch being broken (Sorunome)
- fix: add new Play patch (TheOneWithTheBraid)
- fix: handle matrix.to prefix when starting chat (TheOneWithTheBraid)
- fix: minor design bugs (TheOneWithTheBraid)
- fix: privacy in sign up (TheOneWithTheBraid)
- fix: properly set app title in embedder (TheOneWithTheBraid)
- fix: proprietory classes included into build (TheOneWithTheBraid)
- fix: remove proprietary classes from build (TheOneWithTheBraid)
- refactor: Sharing intent (Christian Pauly)
- refactor: Stories header (Christian Pauly)
- refactor: Update Matrix SDK (Christian Pauly)
- refactor: Upgrade to Flutter 3.0.0 (Christian Pauly)
- Translated using Weblate (Basque) (—X—)
- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Croatian) (Milo Ivir)
- Translated using Weblate (Czech) (Milan Korecky)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Galician) (Xosé M)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Lithuanian) (Mind)
- Translated using Weblate (Portuguese (Brazil)) (Hermógenes Oliveira)
- Translated using Weblate (Portuguese (Brazil)) (mmagian)
- Translated using Weblate (Russian) (Nikita Epifanov)
- Translated using Weblate (Turkish) (Oğuz Ersen)

## v1.4.0 - 2022-04-23

- design: Display icon for failed sent messages (Krille Fear)
- design: Display own stories at first place and combine with new stories button (Krille Fear)
- feat: Add "Show related DMs in spaces" settings (20kdc)
- feat: Better image sending experience (Krille Fear)
- feat: Display event timestamp if selected (Krille Fear)
- feat: Faster image resizing (Krille Fear)
- feat: Groups and Direct Chats virtual spaces option (20kdc)
- feat: New onboarding design (Krille Fear)
- feat: Onboarding with dynamic homeservers from joinmatrix.org (Krille Fear)
- feat: Play audio messages in stories (Krille Fear)
- feat: Use native imaging for much faster thumbnail calc on mobile (Krille Fear)
- feat: add Dockerfile for nginx/web builds (TheOneWithTheBraid)
- feat: allow to create widgets (TheOneWithTheBraid)
- feat: remove diacritics (henri2h)
- feat: irish language support (Graeme Power)
- feat: Enable screensharing on Mobile
- feat: support AppImage builds
- feat: Improve spaces design
- fix: Android theme is not auto updating when system theme changes (Krille Fear)
- fix: Chat view becomes gray for a second on sending reaction (Krille Fear)
- fix: Don't request new thumbnail resolution on every window resize (Samuel Mezger)
- fix: Dont display own failed-to-send events in stories (Krille Fear)
- fix: Hide markdown in chat list preview and local notifications (Krille Fear)
- fix: Hide pinned events if event is not accessable or loading (Krille Fear)
- fix: Image sending (Krille Fear)
- fix: Make audioplayer waveforms thinner and better clickable (Krille Fear)
- fix: Some story layout bugs (Krille Fear)
- fix: Widgets dialog crashes (Krille Fear)
- fix: login form supports switching fields via tab (Philip Molares)
- Added translation using Weblate (Lithuanian) (Mind)
- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Croatian) (Milo Ivir)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Finnish) (Aminda Suomalainen)
- Translated using Weblate (French) (Anne Onyme 017)
- Translated using Weblate (Galician) (Xosé M)
- Translated using Weblate (German) (Krille)
- Translated using Weblate (German) (qwerty287)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Japanese) (Krille)
- Translated using Weblate (Lithuanian) (Mind)
- Translated using Weblate (Portuguese (Brazil)) (Hermógenes Oliveira)
- Translated using Weblate (Russian) (Arbo\_Leet)
- Translated using Weblate (Russian) (Nikita Epifanov)
- Translated using Weblate (Russian) (alekseishaklov)
- Translated using Weblate (Swedish) (Joaquim Homrighausen)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- Update TRANSLATORS\_GUIDE.md to have improved punctuation, capitalization (Scott Anecito)
- chore: Add initial integration tests (Krille Fear)
- refactor: New push (Krille Fear)

## v1.3.1 - 2022-03-20

- Allow app to be moved to external storage (Marcel)
- Translated using Weblate (Arabic) (Mads Louis)
- Translated using Weblate (Basque) (Sorunome)
- Translated using Weblate (Basque) (—X—)
- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Czech) (Sorunome)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (English) (Raatty)
- Translated using Weblate (French) (Anne Onyme 017)
- Translated using Weblate (Galician) (Xosé M)
- Translated using Weblate (German) (Maciej Krüger)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Irish) (Graeme Power)
- Translated using Weblate (Persian) (Anastázius Darián)
- Translated using Weblate (Russian) (Nikita Epifanov)
- Translated using Weblate (Swedish) (Joaquim Homrighausen)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- Update proguard rules to a more modern setup (MTRNord)
- chore: Minor story viewer fixes (Krille Fear)
- chore: Remove story line count and make answering to stories online (Krille Fear)
- chore: Update dependencies (Dependency Update Bot)
- design: Make pinned events use less vertical space (Krille Fear)
- feat: Extended stories (Krille Fear)
- feat: Restrict map zoom to tile server capabilities (Marcel)
- feat: implement keyboard shortcuts (TheOneWithTheBraid)
- fix: Build on macOS (Krille Fear)
- fix: Emojipicker issues (Krille Fear)
- fix: Hide redacted stories (Krille Fear)
- fix: Mark story as read (Krille Fear)
- fix: Open room from notification click produces errors (Krille Fear)
- fix: SSO on Android 12 (Krille Fear)
- fix: Send read receipts on all taps (Krille Fear)
- fix: make fluffy usable at 720 px wide (Raatty)
- fix: Add forgotten sendOnEnter (Krille Fear)
- refactor: Switch to just audio for playing sounds (Krille Fear)

## v1.3.0 - 2022-02-12

FluffyChat 1.3.0 makes it possible to report offensive users to server admins (not only messages).
It fixes
the video player, improves Linux desktop notifications, and the stories design.

The button to create a new story is now in the app bar of the main page so that users who don't want
to use
this feature no longer have a whole list item pinned at the top of the chat list.

FluffyChat 1.3.0 is the first release with full null safe dart code. While this is a huge change
under the
hood, it should improve the stability and performance of the app. It also builds now with Flutter
2.10.

Thanks to all contributors and translators!! <3

- Translated using Weblate (Arabic) (abidin toumi)
- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Croatian) (Milo Ivir)
- Translated using Weblate (Czech) (Milan Korecky)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (French) (Anne Onyme 017)
- Translated using Weblate (Galician) (Xosé M)
- Translated using Weblate (German) (Krille)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Russian) (Nikita Epifanov)
- Translated using Weblate (Swedish) (Joaquim Homrighausen)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)
- chore: Add missing link (Krille Fear)
- chore: Hide FAB story buttons on focus (Krille Fear)
- chore: Set compileSdkVersion to 31 (Krille Fear)
- chore: Update SDK (Krille Fear)
- chore: Update dependencies (Dependency Update Bot)
- chore: Update privacy (Krille Fear)
- chore: Upgrade to Flutter 2.10 (Krille Fear)
- ci: Update olm download link (Krille Fear)
- design: Improve create story page design (Krille Fear)
- design: Improve story header design (Krille Fear)
- design: Use IconButton instead of listTile for first story (Krille Fear)
- feat: Add button to report offensive users to server admins (Krille Fear)
- feat: Open chat button from Linux notification (Krille Fear)
- feat: implement retreiving widgets (TheOneWithTheBraid)
- fix: Set image width and height (Krille Fear)
- fix: Videoplayer filenames (Krille Fear)
- fix: cast error in html messages (Jayesh Nirve)
- fix: linux snap notification avatar (Krille Fear)
- fix: suggestions menu and use empty map in html messages null return (Jayesh Nirve)
- refactor: Migrate to null safety (Krille Fear)

## v1.2.0 - 2022-01-27

FluffyChat 1.2.0 brings a new stories feature, a lot of bug fixes and improved
voice messages.

- change: Set client ID in invite action link (Krille Fear)
- design: Improved animations in chat view when changing account (The one with the Braid)
- design: Remove redundant voice message button (S1m)
- design: Use more adaptive elements (Krille Fear)
- feat: Add button to record a video on Android (S1m)
- feat: Add static + button to pick reaction (S1m)
- feat: Better in app video player (Krille Fear)
- feat: Enable compression and thumbnails for videos (Krille Fear)
- feat: Nicer file event design (Krille Fear)
- feat: Recording dialog with displaying amplitude (Krille Fear)
- feat: Remember homeserver on search page (Krille Fear)
- feat: Save files images and videos (Krille Fear)
- feat: Settings for stories (Krille Fear)
- feat: Share to story (Krille Fear)
- feat: Stories (Krille Fear)
- fix: Add missing routes (Krille Fear)
- fix: Better thumbnails (Krille Fear)
- fix: Do not setup UP if init from an UP action (S1m)
- fix: linux notifications (Raatty)
- fix: Play video without thumbnail if none (S1m)
- fix: Show message bubble on download only video attachments (Drews Clausen)
- fix: Show scrollDownButton only if selectedEvents is empty (S1m)
- fix: Snapcraft image (Krille Fear)
- fix: Snapcraft.yaml (Krille Fear)
- fix: Use system fonts except for desktop (Krille Fear)
- fix: Video playback on iOS (John Francis Sukamto)
- fix: Videoplayer (Krille Fear)
- followup: Improve stories (Krille Fear)
- Improve website SEO tagging (Marcel)
- Increase font size granularity (S1m)
- refactor: /command hints add tooltips, test for missing hints, script to generate glue code, hints
  for dm, create, clearcache, discardsession (Steef Hegeman)
- refactor: Make more files null safe (Krille Fear)
- refactor: Make style settings null safe (Krille Fear)
- systemNavigationBarColor ← appBar.backgroundColor (Steef Hegeman)
- Translated using Weblate (Chinese (Simplified)) (Eric)
- Translated using Weblate (Chinese (Simplified)) (Lynn Nakanishi Lin（林中西）)
- Translated using Weblate (Chinese (Traditional)) (Lynn Nakanishi Lin（林中西）)
- Translated using Weblate (Croatian) (Milo Ivir)
- Translated using Weblate (Czech) (Milan Korecky)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Finnish) (Aminda Suomalainen)
- Translated using Weblate (French) (Anne Onyme 017)
- Translated using Weblate (Galician) (Xosé M)
- Translated using Weblate (German) (Krille)
- Translated using Weblate (German) (Jana)
- Translated using Weblate (German) (TeemoCell)
- Translated using Weblate (Hebrew) (MusiCode1)
- Translated using Weblate (Hebrew) (y batvinik)
- Translated using Weblate (Hungarian) (Balázs Meskó)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Korean) (Kim Tae Kyeong)
- Translated using Weblate (Polish) (KSP Atlas)
- Translated using Weblate (Russian) (Nikita Epifanov)
- Translated using Weblate (Slovenian) (John Jazbec)
- Translated using Weblate (Spanish) (Valentino)
- Translated using Weblate (Turkish) (Oğuz Ersen)
- Translated using Weblate (Ukrainian) (Ihor Hordiichuk)

## v1.1.0 - 2021-12-08

- CI: Add candidate release pipeline (Krille Fear)
- Translated using Weblate (Dutch) (Jelv)
- Translated using Weblate (Estonian) (Priit Jõerüüt)
- Translated using Weblate (Finnish) (Mikaela Suomalainen)
- Translated using Weblate (Finnish) (Mikaela Suomalainen)
- Translated using Weblate (Indonesian) (Linerly)
- Translated using Weblate (Korean) (Kim Tae Kyeong)
- Translated using Weblate (Norwegian Bokmål) (Gigaa)
- Translated using Weblate (Norwegian Bokmål) (Raatty)
- change: Do not compress very small images (Krille Fear)
- chore: Update Matrix SDK (Krille Fear)
- design: Make not joined participants transparent in list (Krille Fear)
- docs: Fix screenshots on website (Krille Fear)
- fix: Update dependencies with flutter pub upgrade (Krille Fear)
- fix: Well known lookup at login (Krille Fear)
- refactor: Make most of the utils null safe (Krille Fear)
- refactor: Make send file dialog null safe (Krille Fear)
- refactor: Make user device list item null safe (Krille Fear)

## v1.0.0 - 2021-11-29

- design: Chat backup dialog as a banner
- design: Encrypted by design, all users valid is normal not green
- design: Move video call button to menu
- design: Display edit marker in new bubbles
- design: Floating input bar
- design: Minor color changes
- design: Move device ID to menu
- design: Place share button under qr code
- design: Redesign and simplify bootstrap
- design: Remove cupertino icons
- feat: Display typing indicators with gif
- feat: Fancy chat list loading animation
- feat: New database backend with FluffyBox
- feat: Make the main color editable for users
- feat: Move styles one settings level up
- feat: Multiple mute, pin and mark unread
- feat: New chat design
- feat: New chat details design
- feat: New Public room bottom sheet
- feat: New settings design
- feat: Nicer images, stickers and videos
- feat: nicer loading bar
- feat: Open im.fluffychat uris
- feat: Redesign multiaccounts and spaces
- feat: Redesign start page
- feat: Send reactions to multiple events
- feat: Speed up app start
- feat: Use SalomonBottomBar
- feat: Drag&Drop to send multiple files on desktop and web
- fix: Adjust color
- fix: Automatic key requests
- fix: Bootstrap loop
- fix: Chat background
- fix: Chat list flickering
- fix: Contrast in dark mode
- fix: Crash when there is no prev message
- fix: Do display error image widget
- fix: Do not display bottombar in selectmode
- fix: Dont enable encryption with bots
- fix: Dont loose selected events
- fix: Dont rerun server checks
- fix: download path for saving files
- fix: Hide FAB in new chat page if textfield has focus
- fix: Let bottom space bar scroll
- fix: Load spaces on app start
- fix: Only mark unread if actually marked
- fix: Public room design
- fix: Remove avatar from room
- fix: Remove broken docker job
- fix: Report sync status error
- fix: Self sign while bootstrap
- fix: Sender name prefix in DM rooms
- fix: Set room avatar
- fix: Various multiaccount fixes
- fix: Wrong version in snap packages

## v0.42.2 - 2021-11-04

Minor bugfix release which fixes signing up on matrix.org and make FluffyChats voice messages
playable in Element.

- feat: Nicer registration form
- feat: Nicer audio message design and send duration
- fix: Signup on matrix.org
- fix: Mark voice messages with msc3245
- fix: Play response voice messages
- fix: Crash on logout

## v0.42.1 - 2021-10-26

Minor bugfix release.

- feat: Ignore users directly from bottom sheet
- fix: Open an existing direct chat via invite link/QR scanning
- fix: Small fix for uia request
- fix: Enable E2EE by default in all start chat cases
- update: Translations - Thanks to all translators <3
- design: Make homepicker page nicer

## v0.42.0 - 2021-10-14

This release fixes several bugs and makes E2EE enabled by default.

- feat: Enable E2EE by default for new rooms
- feat: Display all private rooms without encryption as red
- feat: New design for bootstrap
- feat: New design for emoji verification
- feat: Display own MXID in the settings
- feat: More finetuning for font sizes
- chore: Updated translations (Thanks to all translators!)
- fix: App crash on logout
- fix: Temporary disable sign-up for matrix.org (Currently gives "500: Internal Server Error" while
  FluffyChat **should** send the same requests like Element)
- fix: Implement Roboto font to fix font issues on Linux Desktop and mobile
- fix: QR Code scanning

## v0.41.3 - 2021-10-08

Minor bugfix release.

- fix: Last space is not visible
- chore: Google services disabled by default for F-Droid

## v0.41.1 - 2021-09-15

Minor bugfix release.

- fix: Start up time waits for first sync
- fix: Registration -> matrix.org responses with 500
- fix: Wellknown look up for multi accounts

And some other minor bugs.

## v0.41.0 - 2021-09-14

This release features a lot of bug fixes and the new multi account feature which also include
account bundles.

- feat: Multiple accounts
- feat: New splash screen
- fix: Password reset
- fix: Dark text in cupertinodialogs
- fix: Voice messages on iOS
- fix: Emote settings
- chore: update flutter\_matrix\_html, Matrix Dart SDK and other libraries
- chore: Update to Flutter 2.5.1
- chore: Updated translations

## v0.40.1 - 2021-09-14

Minor bug fixes.

## v0.40.0 - 2021-09-13

This release contains a security fix. Red more about it
here: https://matrix.org/blog/2021/09/13/vulnerability-disclosure-key-sharing

- New in-app registration
- Design improvements
- Minor fixes

## v0.39.0 - 2021-08-30

- Hotfix a bug which produces problems in downloading files and playing audios
- Hotfix a bug which breaks device management

## v0.39.0 - 2021-08-28

This release fixes a bug which makes it impossible to send images in unencrypted rooms. It also
implements a complete new designed new chat page which now uses a QR code based workflow to start a
new chat.

- feat: Dismiss keyboard on scroll in iOS
- feat: Implement QR code scanner
- feat: New design for new chat page
- feat: Use the stripped body for notifications and room previews
- feat: Send on enter configuration for mobile devices
- fix: Prefix of notification text
- fix: Display space as room if it contains unread events in timeline
- fix: missing null check
- fix: Open matrix.to urls
- fix: Padding and colors
- fix: Sharing invite link
- fix: Unread bubbles on iOS
- fix: Sending images in unencrypted rooms

## v0.38.0 - 2021-08-22

This release adds more functionality for spaces, enhances the html viewer, adds a brand new video
player and brings some improvements for voice messages. Thanks to everyone involved!

### All changes:

- change: Nicer design for selecting items
- change: Placeholder at username login field should be just username
- chore: cleanup no longer used translation strings
- chore: switch image\_picker back to upstream
- chore: update flutter\_matrix\_html
- chore: Update matrix sdk to 0.3.1
- feat: Add option to not autoplay stickers and emotes
- feat: Add remove rooms to and from spaces
- feat: Add video player
- feat: Cupertino style record dialog
- feat: Display amplitude
- feat: Implement official emoji translations for emoji verification
- feat: Nicer displaying of verification requests in the timeline
- fix: Allow fallback to previous url if there is no homeserver on the mxid domain
- fix: Correctly size the unread bubble in the room list
- fix: Design of invite rooms
- fix: Disable autocorrect for the homeserver url field
- fix: Disable broken audioplayer for web
- fix: Display loading dialog on start DM
- fix: Dont add/remove DMs to space
- fix: Empty timelines crashing the room view
- fix: excessive CPU usage on Windows, as described
  in https://github.com/flutter/flutter/issues/78517#issuecomment-846436695
- fix: Joining room aliases not published into the room directory
- fix: Keep display alive while recording
- fix: Load space members to display DM rooms
- fix: Make translations use plural forms
- fix: Re-add login fixes with the new SDK
- fix: Reply with voice messages
- fix: Report content localizations
- fix: Requirements when to display report event button
- fix: too long file names
- fix: Try different directories on all kind of errors thrown for hive store
- fix: Use plural string in translation
- fix: use vrouter.toSegments
- fix: Wait for sync before enter a room a user has got invited
- fix: wallpaper on linux
- fix: Wrap login form into `AutofillGroup`

## v0.37.0 - 2021-08-06

- Implement location sharing
- Updated translations
- Improved spaces support
- Minor bug fixes

## v0.36.2 - 2021-08-03

Hotfix a routing problem on web and desktop

## v0.36.1 - 2021-08-03

- Hotfix uploading to many OTKs
- Implement initial spaces UI

## v0.36.0 - 2021-07-31

Minor design improvements and bug fixes.

### All changes:

- design: Make unread listtiles more visible
- design: Move pinned icon in title
- feat: Rate limit streams so that large accounts have a smoother UI
- feat: Display the room name in room pills
- feat: Increase the amount of suggestions for the input bar
- feat: Tapping on stickers shows the sticker body
- fix: Windows
- fix: Disable vrouter logs in release mode
- fix: No longer hide google services key file
- fix: Tests

## v0.35.0 - 2021-07-24

This release introduces stickers and a lot of minor bug fixes and improvements.

### All changes:

### Feature

- Add sticker picker \[205d7e8\]
- Also suggest username completions based on their slugs \[3d980df\]
- Nicer mentions \[99bc819\]
- Render stickers nicer \[35523a5\]
- Add download button to audio messages \[bbb2f43\]
- Android SSO in webview \[befd8e1\]

### Fixes

- Reset bootstrap on bad ssss \[b78b654\]
- Hide stickers button when there is not sticker pack \[b71dd4b\]
- Download files on iOS \[a8201c4\]
- Record voice messages on iOS \[4c2e690\]
- cropped sticker \[a4ec2a0\]
- busy loop due to CircularProgressIndicator \[15856e1\]
- Crash on timeline \[a206f23\]
- typo on webiste \[00a693e\]
- Make sure the aspect ratio of image bubbles stays the same \[a4579a5\]
- Linux failing on attempting to open hive \[76e476e\]
- Secure storage \[0a52496\]
- Make sure the textfield is unfocused before opening the camera \[6821a42\]
- Close safariviewcontroller on SSO \[ba685b7\]

### Refactor

- Rename store and allow storing custom values \[b1c35e5\]

## v0.34.1 - 2021-07-14

Bugfix image picker on Android 11

## v0.34.0 - 2021-07-13

Mostly bugfixes and one new feature: Lottie file rendering.

### All changes:

- feat: Add rendering of lottie files
- fix: Check for jitsi server in well-known lookup also on login screen
- fix: show thumbnails in timeline on desktop
- feat: Add a proper file saver
- feat: Better detect the device type from the device name
- fix: Workaround for iOS not removing the app badge
- fix: Keyboard hides imagePicker buttons on iOS
- feat: Add rendering of lottie files
- fix: Don't allow backup of the android app

## v0.33.3 - 2021-07-11

Another bugfixing release to solve some problems and republish the app on iOS.

### Changes

- Redesign SSO buttons
- Update dependencies
- Remove moor database (no migration from here possible)
- fix: Keyboard hides imagePicker buttons on iOS

## v0.33.2 - 2021-06-29

- Fix Linux Flatpak persistent storing of data

## v0.33.0 - 2021-06-26

Just a more minor bugfixing release with some design changes in the settings, updated missing
translations and for rebuilding the arm64 Linux Flatpak.

### Features

- redesigned settings
- Updated translations - thanks to all translators
- display progress bar in first sync
- changed Linux window default size
- update some dependencies

### Fixes

- Favicon on web
- Database not storing files correctly
- Linux builds for arm64
- a lot of minor bugs

## v0.32.2 - 2021-06-20

- fix: Broken hive keys

## v0.32.1 - 2021-06-17

- fix: Hive breaks if room IDs contain emojis (yes there are users with hacked synapses out there
  who needs this)
- feat: Also migrate inbound group sessions

## v0.32.0 - 2021-06-16

FluffyChat 0.32.0 targets improved stability and a new onboarding flow where single sign on is now
the more prominent way to get new users into the app. This release also introduces a complete
rewritten database under the hood based on the key value store Hive instead of sqlite. This should
improve the overall stability and the performance of the web version.

### Feat

- Long-press reactions to see who sent this
- New login UI
- Shift+Enter makes a new line on web and desktop
- Updated translations - Thanks to all translators
- Brand new database backend
- Updated dependencies
- Minor design tweaks

### Fixes

- Single sign on on iOS and web
- Database corruptions
- Minor fixes

## v0.31.3 - 2021-05-28

### Fixes

- Build Linux
- Multiline keyboard on web and desktop

## v0.31.2 - 2021-05-28

### Fixes

- Setting up push was broken

## v0.31.0 - 2021-05-26

### Chore

- Format iOS stuff \[584c873\]
- LibOlm has been updated to 3.2.3

### Feature

- Cute animation for hiding the + button in inputbar \[37c40a2\]
- Improved chat bubble design and splash animations \[0b3734f\]
- Zoom page transition on Android and Fuchsia \[e6c20dd\]

### Fixes

- "Pick an image" button in emote settings doesn't do anything \[e6be684\]
- Formatting and style \[2540a6c\]
- Emoji picker \[e1bd4e1\]
- Systemuioverlaystyle \[c0d446b\]
- Status bar and system navigation bar theme \[d986986\]
- Open URIs \[6d7c52c\]
- Status bar color \[f347edd\]
- add missing purpose string \[3830b4b\]
- Workaround for iOS not clearing notifications with fcm\_shared\_isolate \[88a7e8d\]
- Minor glitch in bootstrap \[107a3aa\]
- Send read markers \[08dd2d7\]

### Docs

- Update code style \[3e7269d\]

### Refactor

- Structure files in more directories \[ebc598a\]
- Rename UI to Views \[e44de26\]
- rename UI to View and MVC login page \[cc113bb\]
- Rename views to pages \[a93165e\]
- Move widgets to lib \[56a2455\]
- Move translations to assets \[0526e66\]
- Update SDK \[4f13473\]
- Use default systemUiOverlayStyle \[8292ee7\]

## v0.30.2 - 2021-05-13

### Feature

- Implement registration with email \[19616f3\]

### Fixes

- Android input after sending message \[4488520\]

### Changes

- Switch to tchncs.de as default homeserver

### Refactor

- UIA registering \[48bf116\]

## v0.30.1 - 2021-05-07

### Chore

- Update translations

### Fixes

- Record audio on iOS \[cd1e9ae\]

## v0.30.0 - 2021-05-01

In this release we have mostly focused on bugfixing and stability. We have switched to the new
Flutter 2 framework and have done a lot of refactoring under the hood. The annoying freezing bug
should now be fixed. Voice messages now have a new backend which should improve the sound quality
and stability. There is now a more professional UI for editing aliases of a room. Users can now see
a list of all aliases, add new aliases, delete them and mark one alias as the canonical (or main)
alias. Some minor design changes and design fixes should improve the overall UX of the app
exspecially on tablets.

Version 0.30.0 will be the first version with arm64 support. You can download binaries from the CI
and we will try to publish it on Flathub. Together with the new Linux Desktop Notifications feature,
this might be interesting for the Librem 5 or the PinePhone. Sadly I don't own one of these very
interesting devices. If you have one, I would very like to see some screenshots of it! :-)

### Chore

- Update UP and automatically re-register UP on startup \[aa3348e\]

### Feature

- Desktop notifications on Linux Desktop \[25e76f0\]
- Much better alias managing \[642db67\]
- Archive with clean up \[f366ab6\]

### Fixes

- Lock screen \[f8ba7bd\]
- Freeze bug \[15c3178\]
- UserBottomSheet \[dbb0464\]
- Message bubble wrong height \[2b9bd9c\]
- Low height layout \[0d6b43d\]
- Behaviour of homeserver textfield \[2c8a8a4\]
- Build Linux \[d867a56\]
- EmojiPicker background \[0a5270b\]
- e2ee files \[ccd7964\]
- Remove the goddamn package from hell circular checkbox!!! Shame on you! SHAME! \[81c6906\]
- Missing null check \[586c248\]
- Chat UI doesnt load \[4f20ea4\]

### Refactor

- Remove unused variable \[b9f5c94\]
- Remove flutter\_sound \[334d4c0\]
- Switch to record package \[2cf4f47\]
- Sort dependencies \[f2295f7\]
- Widget file structure and MVC user bottom sheet \[bd53745\]
- Dialogs as views \[69deae3\]
- MVC Settings page \[bc5e973\]
- MVC Settings Notifications \[c291b08\]
- MVC multiple emote settings \[a64ada5\]
- MVC settings ignore list \[f23fdcc\]
- MVC emote settings \[1f9f3f4\]
- Null safe dependencies \[ca82a46\]
- MVC settings style \[c6083b6\]
- MVC settings 3pid \[6bfe7b2\]
- MVC search \[b008d56\]
- Folder structure and MVC chat ui \[fb61824\]
- Move some views to widgets \[1fe5b78\]
- MVC device settings view \[15731b9\]
- New private chat view \[453d4f3\]
- MVC chat permission settings \[001e0ee\]
- MVC chat list view \[7658425\]
- MVC chat encryption settings \[576e840\]
- MVC chat details \[28ed394\]
- Enable more lints \[6a56ec4\]
- MVC new group view \[3f889e2\]
- MVC invitation selection \[c12e815\]

## v0.29.1 - 2021-04-13

### Chore

- Bump version \[215f3c8\]

### Fixes

- Save file \[3f854d6\]
- Routing broken in chat details \[f1166b2\]
- Tests \[e75a5a0\]
- Minor sentry crashes \[9aa7d52\]
- nogooglewarning \[7619941\]

### Refactor

- MVC archive \[c2cbad7\]
- MVC sign up password view \[fa0162a\]
- MVC sign up view \[db19b37\]
- Controllers \[f5f02c6\]

## v0.29.0 - 2021-04-09

### Chore

- Clean up repo \[ef7ccef\]
- Bump version \[81a4c26\]
- Nicer FAB icon \[3eeb9a9\]
- Archive button in main menu \[da3dc80\]
- turn renderHtml and hideUnknownEvents on \[29f8e05\]
- Remove unused dependencies \[c505c50\]

### Feature

- Experimental support for room upgrades \[a3af5a9\]

### Fixes

- Room upgrade again \[1d40705\]
- Better padding \[c79562f\]
- Room upgrade \[dac26dd\]
- iOS \[3a6b329\]
- React if not allowed \[0146767\]
- iPad dividerwidth \[a154db0\]
- Playstore release job \[47c9180\]
- Remove blur \[ebf73bf\]
- Support for email registration \[7e5eae5\]
- Typo \[6250fd0\]
- \#323 \[56e5c81\]
- Typo \[b38b0e4\]
- Buggy routing \[62bf380\]
- barrierDismissible: true, \[de9e373\]
- UserBottomSheet SafeArea \[0e172c7\]
- Add normal mode again to OnePageCard \[c057d31\]
- ScrollController in chatlist \[93477d3\]
- SafeArea on iPad \[8911e64\]
- Missing null check \[7cb0dc4\]
- Overflow in chat app bar \[5bf5483\]
- Select room version \[2f5a73f\]

### Docs

- Add code style \[035ad96\]

### Refactor

- Move app\_config to /configs \[8b9f4a4\]
- homeserver picker view \[8e828d8\]
- widgets dir \[c9ab69a\]

## v0.28.1 - 2021-03-28

### Chore

- Update version \[518634a\]

### Feature

- Implement new search view design \[e42dd4b\]

### Fixes

- Share on iOS \[ea31991\]
- Permission to send video call \[4de6d16\]
- Unread badge color \[49d5f86\]
- Push on iOS \[cb6217c\]
- Add Podfile to gitignore \[dd4b4c5\]
- Own user in people list \[ce047b7\]
- Start chat \[92ff960\]
- Set status missing \[17a3311\]

### Refactor

- push stuff \[b6eaf5b\]

## v0.28.0 - 2021-03-16

### Chore

- Bump version \[f8ee682\]
- Change push gateway url \[078aefa\]
- Update file picker cross dependency \[91c6912\]
- Update snapcraft.yaml but still not working \[1072379\]
- Update changelog \[a05f2f0\]
- Change call icon \[7403ac7\]
- Update famedlySdk \[ec64cf6\]

### Feature

- Cache and resend status message \[c8a7031\]
- New experimental design \[94aa9a3\]
- Better verification design \[9bcd6b2\]
- Verify and block devices in devices list \[8ebacfe\]

### Fixes

- substring in reply key respects unicode runes \[5695342\]
- Resend status message \[05cd699\]
- Remove test push \[a838d90\]
- Email validation \[c8e487c\]
- CI \[2e60322\]
- CI \[7275837\]
- CI \[1a8dc50\]
- CI \[c012081\]
- CI \[380732d\]
- CI \[06c31c0\]
- CI \[4d1a171\]
- CI \[597ceab\]
- snapcraft CI \[fee0eb9\]
- Bootstrap in columnview \[bcd2a03\]
- Remove unnecessary snapcraft dependencies \[3a816d1\]
- Snapcraft and it builds now :-) \[eb0eca4\]
- flutter\_matrix\_html crash and flutter\_maths stuffs \[3caac92\]
- Minor bugs \[9fbfca6\]
- add mail \[53fc634\]
- 3pid \[887f3b1\]
- Bootstrap hint \[8651b37\]
- Bootstrap hint \[1331b10\]
- Own presence at top of the list \[ac6fcd1\]
- Analyzer \[e1ddfc8\]
- Trim username on registration \[61a8eb5\]
- Password success banner if not succeeded \[5150563\]
- Status color \[42d9bf5\]
- Routes \[6faa60e\]
- Dialog using wrong Navigator \[9458ab3\]
- sso on web \[aa396ac\]
- Missing localizations in dialogs \[9b1d7ec\]
- Tap on notification to open room in (hopefully) all cases \[57560ff\]
- Allow screenshots again \[6258b6a\]
- Missing tooltips in IconButtons \[57a021f\]
- empty horizontal stories list \[b1f6209\]
- Line color \[3d59d9a\]
- Dont show random users in top bar \[54e268b\]
- Localize ok cancel alert dialogs \[9f9b833\]
- Use single-isolate push \[949771d\]

### Docs

- Update readme and contributing \[449e46d\]
- Update Turkish translation for website \[4a664eb\]

### Refactor

- Update SDK and enable login with email and phone \[864b665\]
- Migrate to flutter 2 \[bb97b1b\]
- Switch to TextButton \[55803d1\]

## v0.27.0 - 2021-02-17

### Chore

- Switch to experimental new hedwig \[30a1fb0\]
- update sdk & remove selfSign \[26f7cb3\]
- Update sdk \[cde8a30\]
- Update unified push \[e73f5d5\]
- Change push gateway port \[8f36140\]

### Feature

- localize bootstrap \[395e62e\]
- Add more bootstrap features \[e4db84a\]
- Add some tooltipps \[b9eb8d1\]
- Get jitsi instance from wellknown \[bd24387\]
- Make font size configurable \[ea1bb89\]
- Allow manual verification of other peoples devices \[ad3c89b\]
- Simplified bootstrap \[d9984da\]
- new design \[33dd1d2\]
- Implement reporting of events \[d553685\]
- Implement experimental new design \[10cf8da\]
- Deprecated authwebview and use platform browser \[d7aae3a\]
- Implement autofillhints \[41a2457\]

### Fixes

- Website \[080a909\]
- docs \_site dir \[875d652\]
- Bootstrap dialog \[c72da0a\]
- Bootstrap wipe \[774f674\]
- MetaRow fontsize \[a13e673\]
- Stories displayname cropping \[6f06c6a\]
- Update read receipt display \[de6e495\]
- Bottom padding of chat list \[aa5ce56\]
- Hard to read titles in chat details \[df90136\]
- Website urls \[295c113\]
- applock enter non digits \[5726c4f\]
- Update contact list \[d870ec3\]
- Better error in discover \[0c1864c\]
- Minor fixes \[c058d39\]
- Share view \[2bd00e6\]
- Endless bootstrap loading \[65d5f9a\]
- More minor fixes \[4c10ef5\]
- Default offline state \[72604c6\]
- Remove old code \[14f633b\]
- Inputborder \[6960618\]
- Unlock the mutex \[5789a86\]
- Wrong fab action \[5429697\]
- SecureStorage sometimes reading wrong / bad values \[d94f0d7\]
- Wrong urls \[29076db\]
- Start chat with yourself from status \[f3b3584\]
- BottomNavigationbar colors \[08f24d7\]
- Emote settings and discovery fallback \[8f8b8d8\]
- reportEvent uses positive int \[408c810\]
- Autofillhints on readonly \[baafebb\]
- Bring back proper emote settings \[6b01a83\]
- Build ios \[f5b1ae8\]
- iOS bundle id \[6a70830\]
- iOS push \[2bf184a\]
- iOS push \[c01bdf7\]

### Docs

- Fix qr-codes \[c7f0a74\]
- grammar fixes \[c4d569b\]

### Refactor

- Theme colors \[fe13778\]
- border radius \[ddd10d1\]

## v0.26.1 - 2021-01-26

### Chore

- Update SDK \[e9df6bf\]
- Bump version \[d79b356\]
- Update dependencies \[6159f99\]

### Feature

- Add unified push as push provider \[124a5ee\]

### Fixes

- Link color \[16d6623\]

## v0.26.0 - 2021-01-25

### Chore

- Redesign textfields \[aef8090\]
- Simplify bootstrap \[2df4a78\]
- Update audio player icons \[3f14d5e\]
- Redesign homepicker page \[e402a02\]
- Remove unused dependency \[2089e62\]
- Update SDK \[a05215f\]
- Update readme \[19f1df7\]
- Change startpage design \[4b8ad1b\]
- Log warning if firebase token problem \[90867e6\]
- Update dependencies \[a56f939\]
- Redesign homeserver picker page \[3c71351\]
- Increase max size of message bubbles \[8477385\]
- Use correct paths on new server \[2f00007\]

### Feature

- emoji working on desktop \[c3feb65\]
- Implement sso \[d1d470d\]
- Implement app lock \[77ee2ef\]
- Dismiss keyboard on view scroll. \[70f96bf\]
- Display version number in app \[e1e60c4\]

### Fixes

- Dark mode fixes \[36746c8\]
- Dark theme \[0bd0e58\]
- clean up iOS dir \[6ae59a8\]
- Homeserver readonly if conifg wants it \[c81158a\]
- Search mxid for private chat \[b6dca5b\]
- Remove unnecessary padding \[5f54057\]
- Foreground push again \[1d6c9cf\]
- Foreground push \[ea1cefa\]
- embedding all fonts to fix the font error \[55c6379\]
- Minor desktop fixes \[c224993\]
- fonts in a standard path \[bfa5601\]
- Make tapping on pills join if remote directory is private \[8ffb3db\]
- key verification dialog button order \[c5adfc2\]
- Allow joining of unpublished aliases again \[ed570a6\]
- Make tap on pills and matrix.to links work again \[48ad322\]
- Load settings on startup \[6906832\]
- Persistent settings \[03b00b7\]
- Voice message recording dialog \[d273b2a\]
- UserBottomSheet \[38e8e1b\]
- Dialogs \[5f0ce49\]
- no exception if token is just null \[db349a5\]
- Load config.json only on web \[a04c3ab\]
- App lock \[8d6642c\]
- cross file picker \[d47f855\]
- Send file \[fde2f8b\]
- APL \[913f3cf\]
- app lock \[6d12168\]
- mxid validation \[25da65f\]
- Startpage textfield padding \[81e706a\]
- Provider in user bottom sheet \[48d6fbd\]
- Readme \[dda0925\]

### Docs

- Make howtofork.md less misunderstandable \[96de54a\]
- Add howtofork.md \[f091469\]
- Mention emoji font \[bb53714\]
- Add famedly contact link \[7f2d61e\]
- Update fdroid button \[ea7e20b\]

### Refactor

- Theme and iOS stuff \[189f65a\]
- Upgrade to latest flutter\_sound\_lite \[2f7dece\]

## v0.25.1 - 2021-01-17

### Chore

- Bump version \[c881424\]

### Fixes

- Change size \[83e2385\]

### Refactor

- remove deprecated approute \[be08de5\]

## v0.25.0 - 2021-01-16

### Chore

- Minor design improvements \[d4dbe83\]
- Minor design tweaks \[06581e2\]
- Bump version \[7f51f7f\]
- redesign start first chat \[e13a732\]
- Better authwebview \[d76df0a\]

### Fixes

- Share files \[d018a4b\]
- Typing update \[9b5a3ca\]
- Status \[d27dbe0\]
- Set status \[7063b34\]
- Column width \[a35c4d0\]
- Dont send only whitespaces \[c0958c6\]
- BuildContext in key verification dialog \[c4866c7\]
- Ignore list \[0458064\]
- Archive route \[5e62267\]
- Remove popup menu item \[5945bcc\]
- chat padding \[079c35e\]
- Remove logs \[8910772\]
- Video calls \[672eca6\]
- loading history \[a5e9553\]
- Missing divider \[cf07eed\]
- loading dialog configs \[de2796e\]
- Display current theme mode \[41483dd\]
- Better authwebview \[5a1085a\]
- authwebview \[2f7749a\]
- Minor apl bugs \[05b9551\]

### Docs

- Update fdroid logo \[31d16a0\]

### Refactor

- Use APL \[cbcfa15\]
- Use Provider \[880f9cc\]
- Use adaptive\_theme \[5d52c26\]

## v0.24.3 - 2021-01-15

### Chore

- Bump version \[46c8386\]
- Update SDK \[ba0726c\]
- Update fdroid domain \[f130681\]
- Update dependencies \[611e5e3\]

### Feature

- Add Turkish translations for website \[817c7dd\]
- Handle matrix: URIs as per MSC2312 \[1da643f\]

### Fixes

- Format \[84b2ac9\]
- Push gateway url \[ed2fbf7\]

## v0.24.2 - 2021-01-08

### Chore

- Update linux version \[ef9369c\]
- Update SDK \[4a006c9\]

### Feature

- Regulate when thumbnails are animated as per MSC2705 \[f5e11c2\]

### Fixes

- Don't allow an empty ssss passphrase in key verification \[3a0ce79\]
- reactions \[92684da\]
- Reply fallback sometimes being stripped incorrectly \[e9ec699\]
- Don't show loading dialog on request history \[e4b6e10\]
- Properly handle url encoding in matrix.to URLs \[baccd0a\]

### Refactor

- Switch to loading dialog \[e84bc25\]

## v0.24.1 - 2020-12-24

### Chore

- Update linux build \[a91407f\]
- Add website to main repo \[4df33a1\]
- Update dependencies \[0d9f418\]
- Change main docs \[56d97f6\]
- Update SDK and logviewer \[45b9c4f\]
- Context icon improvements \[6381cea\]
- Update SDK \[e802593\]

### Feature

- Better invite search bar \[3c4a29b\]
- Open alias in discover page \[f0d1f5a\]
- Implement logger \[714c7b4\]

### Fixes

- auto-dep update \[d9e8c5f\]
- Read receipts and filtered events \[0ae36f0\]
- Don't re-render the lock icon nearly as often \[00a56a7\]
- Format \[e0bc337\]
- Analyzer \[5d8bfa3\]
- logger \[64c5ea9\]
- Have a space after mentions, making it consistent with @-completion \[b18e81a\]
- Display right key in key request dialog \[f8e8e96\]
- Respect hidden events when calculating read receipt message \[702895f\]
- Store emoji picker history and make sure you can't send the same emoji twice \[0066a33\]
- Logger \[0abebdd\]
- Allow key verification to scroll vertically \[accd9b4\]
- Make filter input field auto-lose focus when entering room view \[bdb695e\]
- Update file picker \[6df75d1\]

## v0.24.0 - 2020-12-18

### Chore

- Update dependencies \[550cb4a\]
- Update SDK \[775a33b\]
- Update dependencies \[644433c\]
- Switch to upstream noti settings \[5cc4265\]
- Go back to upstream open noti settings \[6effebe\]
- Update dependencies \[5af4eab\]

### Feature

- Add languages to iOS \[68a5efb\]
- Bring back config.json \[b6a0d37\]
- Implement emojipicker for reactions \[20b3157\]
- Add config hideTypingUsernames \[19c0440\]
- Implement hideAllStateEvents \[721c0b2\]
- Enhanced configuration \[1e7bac3\]
- Implement experimental bootstrapping \[f6945f7\]
- add ability to mark a room as unread \[fe2b391\]
- Try out new firebase \[41a471e\]
- Implement discover groups page \[e728ccc\]
- Add chat permissions settings \[bf4b439\]
- Multiline dialog text field \[8d05a83\]
- Implement rich notification settings \[87a73dd\]

### Fixes

- Update typing \[3d70b1e\]
- Build in dev \[f892a9f\]
- Fix that damn regex \[8961bff\]
- CI \[ebb114d\]
- CI \[0adeb09\]
- Format \[9e5fb70\]
- CI scripts \[46b886f\]
- join public room \[30883e5\]
- CI \[7f44982\]
- open\_noti\_settings \[f4c1202\]
- Missing localization \[cb191e2\]
- Analyzer bug \[be428dd\]
- Set chat avatar on web \[621fcb7\]
- CI \[da5bc56\]

### Refactor

- Update sdk \[32acc21\]

## v0.23.1 - 2020-11-25

### Fixes

- Release CI \[14d8c80\]

## v0.23.0 - 2020-11-25

### Chore

- Update adaptive dialogs \[0061660\]
- Prettier redacted events \[d1e291e\]
- Minor design changes in user viewer \[b4fb283\]
- Minor design changes in chatlist item \[6977112\]
- Implement playstore CD \[4c5760c\]
- Only load google services if needed \[bae779a\]

### Feature

- Next version \[1af048e\]
- Annoy user with dialog to add a recovery method \[d9ec9f6\]
- Implement password recovery \[4b2fef5\]
- Collapse room create states \[fc0c038\]
- Minor design improvements \[0b8cc24\]
- Improved encryption UI \[2516848\]

### Fixes

- Broken dialog \[97bb692\]
- set email dialog \[72e325a\]
- Minor fixes \[11e2dd5\]
- redacted icon color \[d60709b\]
- Unban \[f056e65\]
- Minor design issues \[d9590dd\]
- Buttons in chatlist \[7d08817\]
- Sendername prefix \[a6b60ad\]
- Sendername prefix \[8aaff6f\]
- Minor key request design fix \[0ed29b6\]
- removal of appbundle from the release artifacts \[b1c248f\]
- Copying an event did not obey edits \[0cb262c\]
- Suggest correct rooms \[59ec9de\]

### Refactor

- Make verification in dialogs \[1f9e953\]
- matrix to link prefix \[1aa9c08\]

## v0.22.1 - 2020-11-21

### Fixes

- Input bar not working, making app unusable \[10773b4\]

## v0.22.0 - 2020-11-21

### Chore

- fix CI \[00ed0d6\]
- fix CI \[bb4bb9f\]
- Fix CI variables \[d3822b0\]
- update flutter\_matrix\_html \[ed27bee\]
- update flutter\_matrix\_html \[af36533\]
- Update dependencies \[57256fb\]
- Update dependencies \[40825e1\]
- Switch to adaptive dialogs \[9ea7afc\]
- Switch from bottoast to flushbar \[e219593\]
- Clean up CI \[7e84675\]
- Remove unused dependency \[d12de2d\]

### Feature

- Add svg support and better image handling \[f70bbc3\]
- add config.json \[4b7fb6b\]
- persistent upload of release artifacts \[1b2481b\]
- Option to hide redacted and unknown events \[36315a4\]
- Better encryption / verification \[1ff986e\]

### Fixes

- iOS \[26731ab\]
- resolve some sentry issues \[61f35e8\]
- resolve some sentry issues \[2c3693e\]
- iOS build \[9fee409\]
- Automatic update deps job \[255c05d\]
- Don't re-render message widgets on insertion of new messages, making e.g. audio playing not stop
  \[25b2997\]
- Add missing safearea \[caab868\]
- no pushers enpdoint \[b3942ad\]
- Sentry and small null fix \[5dc22be\]

### Refactor

- CI \[34d7fdd\]
- SDK update \[7e23280\]

## v0.21.1 - 2020-10-28

### Chore

- update version code \[d1dfa9c\]

## v0.21.0 - 2020-10-28

### Chore

- Change compileSdkVersion again \[f93f9c2\]
- Update packages \[b471bd0\]
- Update SDK \[86a385d\]
- New version \[40d00b0\]
- Update flutter\_matrix\_html \[4981cf4\]
- Update sdk \[8773770\]
- Only load google services if needed \[051ec8f\]
- release \[844b4a8\]

### Fixes

- CompileSDKVersion \[bcf75fc\]
- Target sdk \[c3e23b6\]
- File picker issue \[aa191c1\]
- Sentry \[b903ea9\]
- user bottom sheet design \[7876164\]
- Android Download \[8a542bf\]
- Avatar Border Radius \[a8b617e\]
- loading spinner stuck on broken images \[e917879\]
- send file dialog - prevent multiple file sending \[941b211\]
- Multiple related store things \[36405f8\]
- Logo background color \[42a927e\]

## v0.20.0 - 2020-10-23

### Chore

- update dependencies \[427cdc0\]
- upate matrix link text \[0892ca9\]
- Change default linux window size \[719323a\]
- Update changelog \[ef22778\]
- Update matrix\_link\_text \[fc2a0c0\]
- update flutter\_secure\_store \[61c6aec\]
- Minor snap fix \[daf9969\]
- Add privacy informations to app \[e569be7\]
- Make app ready for flutter 1 22 \[e5b23fa\]

### Feature

- Implement mouse select chat list items \[6d41136\]
- Implement linux desktop notifications \[75cd6f1\]
- Implement change device name \[bfd3888\]
- Publish as snap \[46590d7\]
- Enhance emote experience \[cafd639\]
- Implement new status feature \[090795f\]
- More beautiful status \[d9c2d4f\]
- Enhance roomlist context menu \[493b700\]
- Implement basic windows linux support \[7fad316\]
- Enable macOS build \[a845209\]

### Fixes

- return text field to the previous state after editing message \[08e61c0\]
- Web server picker \[4cb19be\]
- Some single-emoji names crashing \[b29ebce\]
- Snapcraft \[c1eebc1\]
- Minor design fix \[a713a2f\]
- Minor design fixes \[e9aa285\]
- Change device displayname \[c5c7ee7\]
- LocalStorage location on desktop \[81e32c5\]
- fixed mxid input method, removed code redundancy \[060156c\]
- overgo issues with flutter\_secure\_store \[6d0f344\]
- resize images in a separate isolate \[56967a9\]
- Build Linux CI \[a941356\]
- Build Linux CI \[2a6b5d8\]
- send images as images, not files \[751dcb7\]
- Show device name in account information correctly \[468c258\]
- Minor fixes \[aee854e\]
- Make theme loading work properly \[f6ab1e0\]
- CI \[6b7d21d\]
- User Status crash \[0413b0c\]
- small desktop fixes \[540ff68\]
- Desktop url launcher \[4dfd0db\]
- Snap \[ec7dd2b\]
- Snap \[4648466\]
- CI \[4345df3\]
- Linux database \[772ff33\]
- TextField \[7ec349b\]
- Inputbar focus \[5e673c6\]
- Desktop file picker \[662e2f1\]
- Desktop images \[5409fe8\]
- Try with select 1 \[6e924cb\]
- More debug logs \[9b572f5\]
- Minor design bugs \[6ffbf16\]
- Minor user status bugs \[f84ac1d\]
- Improve loading dialogs \[41ceb84\]
- Invite left members \[fe649e5\]
- tapping on aliases not always working \[c0390ca\]
- determine 12h/24h time based on settings, not locale \[ca19e9f\]
- fix up translations to use keys and fix arb files \[74b15dd\]

## v0.19.0 - 2020-09-21

### Chore

- Version update & olm-CI \[0f805a2\]
- Update SDK & Changelog \[1825543\]
- Add new language \[c6d67ad\]
- master --> main \[1de3c54\]
- switch to cached\_network\_image \[bbca0c2\]
- update dependencies \[2a62cf8\]
- Add more debugging logs to debug key decrypt issues \[20d3ea9\]
- Update SDK, re-enable transactions on mobile \[1f4c2a1\]
- update languages \[40e9544\]
- Updat changelog \[d1e898c\]
- update sdk \[954eedb\]

### Feature

- Implement send reactions \[6bf25b7\]
- Improve design \[c8a63c6\]
- Display emotes/emojis bigger \[9cccd07\]
- Add scroll-to-event \[8547422\]
- Implement ignore list \[b2fa88c\]
- Add license page \[dcf4c4c\]
- Implement rich push notifications on android \[f4e4b90\]
- Implement sentry \[705ced8\]
- Send image / video / file dialog \[80114df\]
- Blurhashes and better thumbnails \[2321829\]
- open links better \[04cbf0c\]
- Implement web audio player \[0f6b46d\]
- New notification sound \[8a5be21\]

### Fixes

- Last bits for the release \[1db9bdd\]
- Small stuff \[9d3f272\]
- Search bar \[eca25de\]
- font size being too large accidentally in some places \[43dd222\]
- Scroll down button not showing \[8cd8f90\]
- Don't double-confirm sending audio messages \[168b8b0\]
- Hotfix ignore list \[94f8f34\]
- Push on conduit \[e5cd144\]
- Images with an info block but no size crashing \[5f58789\]
- Allow requesting past messages if all events in the current timeline are filtered \[0f9ff4a\]
- annoying notification sound \[739a70c\]
- Status design \[f7930fe\]
- Send read receipt only on focus \[98316f1\]
- Desktop notifications \[b05bfa6\]

This CHANGELOG.md was generated with [**Changelog for
Dart**](https://pub.dartlang.org/packages/changelog)

[2.6.6+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.6.6
[2.6.0+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.6.0
[2.5.2+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.5.2
[2.4.20+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.20
[2.4.19+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.19
[2.4.18+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.18

[2.4.16+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.16
[2.4.15+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.15
[2.4.14+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.14
[2.4.12+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.12
[2.4.10+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.10
[2.4.6+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.6
[2.4.5+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.5
[2.4.2+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.2
[2.4.1+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.1
[2.4.0+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.4.0
[2.3.7+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.3.7
[2.3.6+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.3.6
[2.3.3+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.3.3
[2.3.2+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.3.2
[2.3.1+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.3.1
[2.3.0+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.3.0
[2.2.4+2330]: https://github.com/linagora/twake-on-matrix/releases/tag/2.2.4
