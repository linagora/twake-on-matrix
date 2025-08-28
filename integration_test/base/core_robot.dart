import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart';
import 'package:patrol/patrol.dart';

abstract class CoreRobot {
  final PatrolIntegrationTester $;

  CoreRobot(this.$);

  dynamic ignoreException() => $.tester.takeException();

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
        'Neither widget became visible within ${timeout.inSeconds} seconds',);
  }

  Future<HttpClient> initialRedirectRequest() async {
    // Step 1: Initial redirect request (NO REDIRECT FOLLOW)
    final client = HttpClient();
    client.autoUncompress = true;
    return client;
  }

  Future<List<dynamic>> loginByAPI(HttpClient client) async {
    // Step 1: Prepare the first request (no redirect)
    final uri = Uri.https(
      'matrix.linagora.com',
      '/_matrix/client/r0/login/sso/redirect/oidc-twake',
      {
        'redirectUrl':
            'https://chat.linagora.com/web/auth.html?homeserver=https://matrix.linagora.com',
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
      ..set(HttpHeaders.hostHeader, 'matrix.linagora.com')
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
    // Lấy cookie đầu tiên chứa "oidc_session="
    final oidcCookie = allCookies!.firstWhere(
      (cookie) => cookie.contains('oidc_session='),
      orElse: () => '',
    );
    final match = RegExp(r'oidc_session=([^&;]+)').firstMatch(oidcCookie);
    oidcSession = match?.group(1);

    // Step 3: Second request to SSO authorize
    final secondUri = Uri.https('sso.linagora.com', '/oauth2/authorize', {
      'response_type': responseType,
      'client_id': clientId,
      'redirect_uri': redirectUriValue,
      'scope': scope,
      'state': state,
      'nonce': nonce,
      'code_challenge_method': codeChallengeMethod,
      'code_challenge': codeChallenge,
    });

    final secondRequest = await client.getUrl(secondUri);
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
      ..set(HttpHeaders.hostHeader, 'matrix.linagora.com')
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
    final thirdUri = Uri.https('sso.linagora.com', '/oauth2/authorize', {
      'response_type': 'code',
      'client_id': 'matrix1',
      'redirect_uri':
          'https://matrix.linagora.com/_synapse/client/oidc/callback',
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
          'https://sso.linagora.com/oauth2/authorize?response_type=code'
          '&client_id=$clientId'
          '&redirect_uri=$redirectUriValue'
          '&scope=$scope'
          '&state=$state'
          '&nonce=$nonce'
          '&code_challenge_method=$codeChallengeMethod'
          '&code_challenge=$codeChallenge')
      ..set('Sec-Fetch-Site', 'same-origin')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set('Origin', 'https://sso.linagora.com')
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
      'user': 'thhoang@linagora.com',
      'password': 'lynic123',
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
    final fourthUri =
        Uri.https('matrix.linagora.com', '/_synapse/client/oidc/callback', {
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
      ..set(HttpHeaders.refererHeader, 'https://sso.linagora.com/')
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
    final fifthUri =
        Uri.https('matrix.linagora.com', '/_matrix/client/v3/login');
    final fifthRequest = await client.postUrl(fifthUri);
    fifthRequest.followRedirects = false;
    fifthRequest.headers
      ..set('Sec-Fetch-Mode', 'cors')
      ..set(HttpHeaders.refererHeader, 'https://chat.linagora.com/')
      ..set('Sec-Fetch-Site', 'same-site')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set('Origin', 'https://chat.linagora.com')
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
        "initial_device_display_name": "chat.linagora.com: Chrome on Web",
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

  Future<void> openGroupChatByAPI(HttpClient client, String groupID) async {}

  Future<String> getAllSentMessage(
      HttpClient client, String accessToken,) async {
    // 👇 Query parameters
    final syncUri =
        Uri.https('matrix.linagora.com', '/_matrix/client/v3/sync', {
      'filter': '0',
      'set_presence': 'unavailable',
      'timeout': '30000',
      // 'since':
      //     's563561_40005126_16900_645237_332605_1132109_848590_5456623_0_1363',
    });

    final request = await client.getUrl(syncUri);
    request.followRedirects = false;

    // 👇 Headers
    request.headers
      ..set(HttpHeaders.connectionHeader, 'close')
      ..set('Sec-Fetch-Mode', 'cors')
      ..set(HttpHeaders.refererHeader, 'https://chat.linagora.com/')
      ..set('Sec-Fetch-Site', 'same-site')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set('Origin', 'https://chat.linagora.com')
      ..set(HttpHeaders.acceptHeader, '*/*')
      ..set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      )
      ..set(
        'sec-ch-ua',
        '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
      )
      ..set('sec-ch-ua-mobile', '?0')
      ..set('sec-ch-ua-platform', '"macOS"')
      ..set(HttpHeaders.hostHeader, 'matrix.linagora.com')
      ..set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate, br, zstd')
      ..set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      )
      ..set('Sec-Fetch-Dest', 'empty');

    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    return body;
  }

  Future<void> sendMessageByAPI(HttpClient client, String accessToken,
      String lemonldap, String groupID, String message,) async {
    final sixthUri = Uri.https(
      'matrix.linagora.com',
      '/_matrix/client/v3/rooms/$groupID:linagora.com/send/m.room.message/chat.linagora.com%3A%20Chrome%20on%20Web%20-9-${DateTime.now().millisecondsSinceEpoch}',
    );
    final sixthRequest = await client.putUrl(sixthUri);
    sixthRequest.followRedirects = false;
    sixthRequest.headers
      ..set(HttpHeaders.connectionHeader, 'keep-alive')
      ..set('Sec-Fetch-Mode', 'cors')
      ..set(HttpHeaders.refererHeader, 'https://chat.linagora.com/')
      ..set('Sec-Fetch-Site', 'same-site')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9,vi;q=0.8')
      ..set('Origin', 'https://chat.linagora.com')
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

  Future<void> closeClient(HttpClient client) async {
    client.close(force: true);
  }

  Future<void> execute() async {
    final client = await initialRedirectRequest();
    final list = await loginByAPI(client);
    await sendMessageByAPI(list[0], list[1], list[2], "", "");
  }
}
