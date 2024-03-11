# 19. Change the way log in SSO in web

Date: 2024-03-07

## Status

Accepted

## Context

- Previously, our SSO login process involved opening a popup window to authenticate users. After successful login, users were redirected back to the home screen. While this flow worked seamlessly on Chrome, it encountered issues on Firefox and Safari, where users needed to grant permission for the popup to open. This requirement could disrupt the user experience. To address this concern and ensure a smoother login process across all browsers, we've updated our authentication flow.

## Consequences

- To enhance the user experience across different browsers, we've updated the Single Sign-On (SSO) authentication process. Previously, the process involved opening a popup for authentication, which worked seamlessly in Chrome but encountered permission issues in Firefox and Safari. To address this, the authentication flow has been revised as follows:

- The SSO authentication page will now take the place of the homepage temporarily. After successful SSO authentication, users are redirected to `/onAuthRedirect`. This redirection facilitates the continuation of the login process using a loginToken and a homeserver address, both of which are retrieved from query parameters. This information is used during the `/onAuthRedirect` page to complete the SSO login process. This approach ensures a smoother and more consistent user experience across all browsers.
