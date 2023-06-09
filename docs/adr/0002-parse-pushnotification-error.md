# 2. Parse PushNotification Error

Date: 2023-06-09

## Status

Accepted

## Context

- Twake deployed a Push Gateway base on [Sygnal](https://github.com/matrix-org/sygnal
- FluffyChat based on a Customized Push Gateway https://gitlab.com/famedly/company/backend/services/famedly-push-gateway
- So code base does not have the exactly parsing the payload from Push Gateway

## Decision

- Create an other parser for PushNotification base on the common payload

## Consequences

- Twake can show notification