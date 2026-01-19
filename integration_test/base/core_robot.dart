import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';

class CoreRobot {
  final PatrolIntegrationTester $;

  CoreRobot(this.$);

  dynamic ignoreException() => $.tester.takeException();

  String? getBrowserAppId() {
    if (Platform.isAndroid) {
      return 'com.android.chrome';
    }
    return null;
  }

  Future<bool> tapNextOnPermissionDialog() async {
    final dialog = $(PermissionDialog);
    if (!dialog.exists) {
      return false;
    }

    final ctx = $.tester.element(dialog); // BuildContext inside dialog
    final nextLabel = L10n.of(ctx)!.next; // localized label for "Next"

    await $.tester.tap(
      find.descendant(of: dialog, matching: find.text(nextLabel)),
    );
    await $.tester.pumpAndSettle();
    return true;
  }

  Future<void> confirmShareContactInformation() async {
    await tapNextOnPermissionDialog();
  }

  Future<void> confirmAccessContact() async {
    try {
      await $.native.grantPermissionWhenInUse();
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> cancelSynchronizeContact() async {
    final tapped = await tapNextOnPermissionDialog();
    if (!tapped) {
      return;
    }
    await $.native.denyPermission();
  }

  Future<void> grantNotificationPermission() async {
    if (await $.native.isPermissionDialogVisible(
      timeout: const Duration(seconds: 15),
    )) {
      await $.native.grantPermissionWhenInUse();
    }
  }

  Future<void> waitForEitherVisible({
    required PatrolIntegrationTester $,
    required PatrolFinder first,
    required PatrolFinder second,
    required Duration timeout,
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (first.exists || second.exists) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    throw Exception(
      'Neither widget became visible within ${timeout.inSeconds} seconds',
    );
  }

  Future<void> waitUntilAbsent(
    PatrolIntegrationTester $,
    PatrolFinder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.exists) {
      if (DateTime.now().isAfter(end)) {
        throw TimeoutException('Widget $finder still exists after $timeout');
      }
      await $.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> waitNativeGone(
    Selector selector, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    final appId = getBrowserAppId();
    final end = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(end)) {
      final views = await $.native.getNativeViews(
        selector,
        appId: appId,
      );
      if (views.isEmpty) return;

      await Future.delayed(interval);
    }

    throw TimeoutException('Native element still visible: $selector');
  }

  Future<void> waitSnackGone(
    PatrolIntegrationTester $, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final end = DateTime.now().add(timeout);
    while ($(SnackBar).exists || $(CupertinoPopupSurface).exists) {
      if (DateTime.now().isAfter(end)) break;
      await $.pump(const Duration(milliseconds: 150));
    }
  }

  Future<bool> existsOptionalFlutterItems(
    PatrolIntegrationTester $,
    PatrolFinder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await $.pumpAndTrySettle(duration: timeout);
    return finder.exists;
  }

  Future<bool> existsOptionalNativeItems(
    PatrolIntegrationTester $,
    Selector selector, {
    String? appId,
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    try {
      await $.native.waitUntilVisible(selector, appId: appId, timeout: timeout);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> typeSlowlyWithPatrol(
    PatrolIntegrationTester $,
    Finder field,
    String text, {
    Duration perChar = const Duration(milliseconds: 500),
  }) async {
    await $.tap(field);

    final buffer = StringBuffer();
    buffer.write(text.characters.characterAt(0));
    await $.enterText(field, buffer.toString());
    await $.pump();
    await Future.delayed(perChar);
    buffer.write(text.characters.getRange(1, text.characters.length));
    await $.enterText(field, buffer.toString());
    await $.pump();
    await Future.delayed(perChar);
  }

  Future<String?> captureAsyncError(Future<void> Function() body) async {
    Object? err;
    final done = Completer<void>();

    runZonedGuarded(() async {
      try {
        await body();
      } finally {
        done.complete();
      }
    }, (e, _) {
      err ??= e; // store the first error
    });

    await done.future;
    return err?.toString();
  }

  Future<HttpClient> initialRedirectRequest() async {
    // Step 1: Initial redirect request (NO REDIRECT FOLLOW)
    final client = HttpClient();
    client.autoUncompress = true;
    return client;
  }

  Future<List<dynamic>> loginByAPI(HttpClient client) async {
    const chatURL = String.fromEnvironment('CHAT_URL');
    const matrixURL = String.fromEnvironment('MATRIX_URL');
    const ssoURL = String.fromEnvironment('SSO_URL');
    const receiver = String.fromEnvironment('Receiver');
    const passOfReceiver = String.fromEnvironment('ReceiverPass');

    // Step 1: Prepare the first request (no redirect)
    final uri = Uri.https(
      matrixURL,
      '/_matrix/client/r0/login/sso/redirect/oidc-twake',
      {
        'redirectUrl':
            'https://$chatURL/web/auth.html?homeserver=https://$matrixURL',
      },
    );

    final request = await client.getUrl(uri);
    request.followRedirects = false;

    // Headers
    request.headers
      ..set(HttpHeaders.connectionHeader, 'close')
      ..set('Sec-Fetch-Mode', 'navigate')
      ..set('Sec-Fetch-Site', 'same-site')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      )
      ..set(
        'sec-ch-ua',
        '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
      )
      ..set('sec-ch-ua-mobile', '?0')
      ..set('sec-ch-ua-platform', '"macOS"')
      ..set(HttpHeaders.hostHeader, matrixURL)
      ..set('Upgrade-Insecure-Requests', '1')
      ..set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate, br, zstd')
      ..set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      )
      ..set('Sec-Fetch-Dest', 'document');

    final firstResponse = await request.close();

    // Step 2: Extract redirect location and parse query params
    final redirectLocation = firstResponse.headers.value('location');
    if (redirectLocation == null) {
      throw Exception('No redirect location found in first response');
    }

    final redirectUri = Uri.parse(redirectLocation);
    final params = redirectUri.queryParameters;

    final scope = params['scope'];
    final state = params['state'];
    final nonce = params['nonce'];
    final codeChallenge = params['code_challenge'];
    final codeChallengeMethod = params['code_challenge_method'];
    final responseType = params['response_type'];
    final clientId = params['client_id'];
    final redirectUriValue = params['redirect_uri'];

    final allCookies = firstResponse.headers['set-cookie']; // List<String>?
    String? oidcSession;
    // get cookie that contains "oidc_session="
    final oidcCookie = allCookies!.firstWhere(
      (cookie) => cookie.contains('oidc_session='),
      orElse: () => '',
    );
    final match = RegExp(r'oidc_session=([^&;]+)').firstMatch(oidcCookie);
    oidcSession = match?.group(1);

    // Step 3: Second request to SSO authorize
    final requestToSSOAuthorize = Uri.https(ssoURL, '/oauth2/authorize', {
      'response_type': responseType,
      'client_id': clientId,
      'redirect_uri': redirectUriValue,
      'scope': scope,
      'state': state,
      'nonce': nonce,
      'code_challenge_method': codeChallengeMethod,
      'code_challenge': codeChallenge,
    });

    final secondRequest = await client.getUrl(requestToSSOAuthorize);
    secondRequest.followRedirects = false;

    secondRequest.headers
      ..set(HttpHeaders.connectionHeader, 'close')
      ..set('Sec-Fetch-Mode', 'navigate')
      ..set('Sec-Fetch-Site', 'same-site')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      )
      ..set(
        'sec-ch-ua',
        '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
      )
      ..set('sec-ch-ua-mobile', '?0')
      ..set('sec-ch-ua-platform', '"macOS"')
      ..set(HttpHeaders.hostHeader, matrixURL)
      ..set('Upgrade-Insecure-Requests', '1')
      ..set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate, br, zstd')
      ..set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      )
      ..set('Sec-Fetch-Dest', 'document');

    final secondResponse = await secondRequest.close();

    // Step 4: Extract token, url from HTML (token is in a hidden input field)
    final body = await utf8.decoder.bind(secondResponse).join();
    final doc = parse(body);
    final tokenInput = doc.querySelector('input[name=token]');
    final token = tokenInput?.attributes['value'];
    if (token == null) {
      throw Exception('Token not found in HTML form');
    }
    final urlInput = doc.querySelector('input[name=url]');
    final url = urlInput?.attributes['value'];
    if (url == null) {
      throw Exception('url not found in HTML form');
    }

    // Step 5: Submit login form to authorize (third request)
    final thirdUri = Uri.https(ssoURL, '/oauth2/authorize', {
      'response_type': 'code',
      'client_id': 'matrix1',
      'redirect_uri': 'https://$matrixURL/_synapse/client/oidc/callback',
      'scope': 'openid profile email',
      'state': state,
      'nonce': nonce,
      'code_challenge_method': codeChallengeMethod,
      'code_challenge': codeChallenge,
    });

    final thirdRequest = await client.postUrl(thirdUri);
    thirdRequest.followRedirects = false;

    thirdRequest.headers
      ..set('Sec-Fetch-Mode', 'navigate')
      ..set(
          HttpHeaders.refererHeader,
          'https://$ssoURL/oauth2/authorize?response_type=code'
          '&client_id=$clientId'
          '&redirect_uri=$redirectUriValue'
          '&scope=$scope'
          '&state=$state'
          '&nonce=$nonce'
          '&code_challenge_method=$codeChallengeMethod'
          '&code_challenge=$codeChallenge')
      ..set('Sec-Fetch-Site', 'same-origin')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set('Origin', 'https://$ssoURL')
      ..set('Sec-Fetch-User', '?1')
      ..set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      )
      ..set(
        'sec-ch-ua',
        '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
      )
      ..set('sec-ch-ua-mobile', '?0')
      ..set('sec-ch-ua-platform', '"macOS"')
      ..set('Upgrade-Insecure-Requests', '1')
      ..set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded')
      ..set(HttpHeaders.cacheControlHeader, 'max-age=0')
      ..set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate, br, zstd')
      ..set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      )
      ..set('Sec-Fetch-Dest', 'document');

    final thirdBody = {
      'url': url,
      'timezone': '7',
      'skin': 'twake',
      'token': token,
      'user': receiver,
      'password': passOfReceiver,
    };
    thirdRequest.write(Uri(queryParameters: thirdBody).query);

    final thirdResponse = await thirdRequest.close();

    final location = thirdResponse.headers.value('location');
    if (location == null) {
      throw Exception('No redirect found after login POST');
    }
    final thirdRedirectUri = Uri.parse(location);
    final code = thirdRedirectUri.queryParameters['code'];
    final sessionState = thirdRedirectUri.queryParameters['session_state'];

    final allCookiesOfThirdResponse =
        thirdResponse.headers['set-cookie']; // List<String>?
    String? lemonldap;
    final oidcCookieOfThirdResponse = allCookiesOfThirdResponse!.firstWhere(
      (cookie) => cookie.contains('lemonldap='),
      orElse: () => '',
    );
    final matchOfThirdResponse =
        RegExp(r'lemonldap=([^&;]+)').firstMatch(oidcCookieOfThirdResponse);
    lemonldap = matchOfThirdResponse?.group(1);

    // Step 7: Call OIDC callback to get loginToken
    final fourthUri = Uri.https(matrixURL, '/_synapse/client/oidc/callback', {
      'code': code,
      'session_state': sessionState,
      'state': state,
    });
    final fourthRequest = await client.getUrl(fourthUri);
    fourthRequest.followRedirects = false;

    fourthRequest.headers
      ..set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      )
      ..set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      )
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set(HttpHeaders.refererHeader, 'https://$ssoURL/')
      ..set(HttpHeaders.cacheControlHeader, 'max-age=0')
      ..set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate, br, zstd')
      ..set('Sec-Fetch-Mode', 'navigate')
      ..set('Sec-Fetch-Site', 'same-site')
      ..set('Sec-Fetch-User', '?1')
      ..set('Sec-Fetch-Dest', 'document')
      ..set(
        'sec-ch-ua',
        '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
      )
      ..set('sec-ch-ua-mobile', '?0')
      ..set('sec-ch-ua-platform', '"macOS"')
      ..set('Upgrade-Insecure-Requests', '1')
      ..set(
        HttpHeaders.cookieHeader,
        'oidc_session=$oidcSession; oidc_session_no_samesite=$oidcSession; lemonldap=$lemonldap',
      );

    final fourthResponse = await fourthRequest.close();

    final locationIn4Response = fourthResponse.headers.value('location');
    if (locationIn4Response == null) {
      throw Exception('Missing location header in response');
    }

    final uriIn4Location = Uri.parse(locationIn4Response);
    final loginToken = uriIn4Location.queryParameters['loginToken'];

    if (loginToken == null) {
      throw Exception('Missing loginToken in redirect URL');
    }

    // Step 8: Token login
    final fifthUri = Uri.https(matrixURL, '/_matrix/client/v3/login');
    final fifthRequest = await client.postUrl(fifthUri);
    fifthRequest.followRedirects = false;
    fifthRequest.headers
      ..set('Sec-Fetch-Mode', 'cors')
      ..set(HttpHeaders.refererHeader, 'https://$chatURL/')
      ..set('Sec-Fetch-Site', 'same-site')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set('Origin', 'https://$chatURL')
      ..set(HttpHeaders.acceptHeader, '*/*')
      ..set(
        'sec-ch-ua',
        '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
      )
      ..set('sec-ch-ua-mobile', '?0')
      ..set('sec-ch-ua-platform', '"macOS"')
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate, br, zstd')
      ..set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      )
      ..set('Sec-Fetch-Dest', 'empty')
      ..set(
        HttpHeaders.cookieHeader,
        'lemonldap=$lemonldap',
      );

    fifthRequest.write(
      jsonEncode({
        "initial_device_display_name": "$chatURL: Chrome on Web",
        "token": loginToken,
        "type": "m.login.token",
      }),
    );

    final fifthResponse = await fifthRequest.close();
    final fifthBody = await fifthResponse.transform(utf8.decoder).join();
    final loginData = jsonDecode(fifthBody);
    final accessToken = loginData['access_token'];

    return [client, accessToken, lemonldap];
  }

  Future<void> sendMessageByAPI(
    HttpClient client,
    String accessToken,
    String lemonldap,
    String message,
  ) async {
    const chatURL = String.fromEnvironment('CHAT_URL');
    const matrixURL = String.fromEnvironment('MATRIX_URL');
    const groupID = String.fromEnvironment('GroupID');
    final sendMessageEndpoint = Uri.https(
      matrixURL,
      '/_matrix/client/v3/rooms/$groupID:linagora.com/send/m.room.message/$chatURL%3A%20Chrome%20on%20Web%20-9-${DateTime.now().millisecondsSinceEpoch}',
    );
    final sixthRequest = await client.putUrl(sendMessageEndpoint);
    sixthRequest.followRedirects = false;
    sixthRequest.headers
      ..set(HttpHeaders.connectionHeader, 'keep-alive')
      ..set('Sec-Fetch-Mode', 'cors')
      ..set(HttpHeaders.refererHeader, 'https://$chatURL/')
      ..set('Sec-Fetch-Site', 'same-site')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set('Origin', 'https://$chatURL')
      ..set(HttpHeaders.acceptHeader, '*/*')
      ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
      ..set(
        'sec-ch-ua',
        '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
      )
      ..set('sec-ch-ua-mobile', '?0')
      ..set('sec-ch-ua-platform', '"macOS"')
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate, br, zstd')
      ..set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      )
      ..set('Sec-Fetch-Dest', 'empty')
      ..set(
        HttpHeaders.cookieHeader,
        'lemonldap=$lemonldap',
      );

    sixthRequest.write(
      jsonEncode({
        'msgtype': 'm.text',
        'body': message,
      }),
    );

    await sixthRequest.close();
  }

  Future<void> closeHTTPClient(HttpClient client) async {
    client.close(force: true);
  }

  Future<void> scrollToBottom(
    PatrolIntegrationTester $, {
    PatrolFinder? root,
    int maxDrags = 30,
  }) async {
    // Find the Scrollable to act on
    final PatrolFinder scrollable = root == null
        ? $(Scrollable).first
        : $(
            find.descendant(
              of: root.finder,
              matching: find.byType(Scrollable),
            ),
          ).first;

    var lastPixels = -1.0;
    for (var i = 0; i < maxDrags; i++) {
      // drag up a bit
      await $.tester.drag(scrollable, const Offset(0, -400));
      await $.tester.pump(const Duration(milliseconds: 120));

      final s = $.tester.state<ScrollableState>(scrollable);
      final p = s.position.pixels;

      if (p == lastPixels) break; // no more movement → bottom reached
      lastPixels = p;
    }
  }

  Future<void> scrollToTop(
    PatrolIntegrationTester $, {
    PatrolFinder? root,
    int maxDrags = 30,
  }) async {
    // Find the Scrollable to act on
    final PatrolFinder scrollable = root == null
        ? $(Scrollable).first
        : $(
            find.descendant(
              of: root.finder,
              matching: find.byType(Scrollable),
            ),
          ).first;

    for (var i = 0; i < maxDrags; i++) {
      // drag down a bit
      await $.tester.drag(scrollable, const Offset(0, 400));
      await $.tester.pump(const Duration(milliseconds: 120));

      final s = $.tester.state<ScrollableState>(scrollable);
      final p = s.position.pixels;

      if (p <= 0.0) break; // reached top
    }
  }

  Future<void> scrollUntilVisible(
    PatrolIntegrationTester $,
    Finder target, {
    Finder? scrollable,
    int maxSwipes = 10,
  }) async {
    final container = scrollable ?? find.byType(Scrollable);

    for (int i = 0; i < maxSwipes; i++) {
      if ($.tester.any(target)) return;
      await $.tester.drag(container, const Offset(0, -300)); // swipper up
      await $.tester.pumpAndSettle();
    }

    for (int i = 0; i < maxSwipes; i++) {
      if ($.tester.any(target)) return;
      await $.tester.drag(container, const Offset(0, 300)); // swipper down
      await $.tester.pumpAndSettle();
    }

    if (!$.tester.any(target)) {
      throw Exception('can not found widget after scrolling');
    }
  }

  Future<bool> isActuallyScrollable(
    PatrolIntegrationTester $, {
    PatrolFinder? root,
  }) async {
    final scrollableFinder = root == null
        ? $(Scrollable)
        : $(
            find.descendant(
              of: root.finder,
              matching: find.byType(Scrollable),
            ),
          );

    return scrollableFinder.exists;
  }
}
