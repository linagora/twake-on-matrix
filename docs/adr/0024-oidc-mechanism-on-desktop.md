# 24. OIDC mechanism on desktop

Date: 2024-05-13

## Status

Accepted

## Context

Currently OIDC is handled for web and mobile versions of the application. For web `FlutterWebAuth2` uses an `iframe` to watch the result of the log in process wether it's a success, or a timeout. For the case of mobile app, the app registered a url scheme which looks like `myapp://auth`. This scheme is where the OIDC server will send its result which will be retrieved by the app like a deeplink.

But we can't use an `iframe` or register a custom url on desktop applications (at least for linux and windows). So we have to find an other solution to catch the result from the browser where the user log in.

## Decision

To achieve that the app (via `FlutterWebAuth2`) sets a light webserver on the user's device. This server's URI, which looks like `http://localhost:port`, uses on a random open port and is sent to OIDC server as form url encoded content. This port is found using this method:

```dart
  Future<int> findFreePort() async {
    // launch a local light web server
    // to find a random open open, we set port as 0 
    final tmpServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = tmpServer.port;
    // when an open port as been found tmp server is closed and port is returned
    await tmpServer.close();
    return port;
  }
```

The app listens to this server, looking for a result. If log in succeed, the OIDC server `POST` the access token to this server which send it to the app. 
As soon as the log in process is done (wether it's successful or not), the webserver is closed.

More details: 
- https://github.com/ThexXTURBOXx/flutter_web_auth_2/blob/b48b6f5c866b8c1018cc138b2b11acb3b6188e0b/flutter_web_auth_2/lib/src/server.dart 
- https://blog.logto.io/redirect-uri-in-authorization-code-flow/ 
- https://openid.net/developers/how-connect-works/ 
