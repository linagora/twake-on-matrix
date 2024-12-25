## Configuration for config.json

### Context

- Twake Chat need to config env for Twake Chat service on web version
- Now only support to web

### How to config

1.Add environment
in [config.sample.json](https://github.com/linagora/twake-on-matrix/blob/main/config.sample.json)

- Env for Twake Chat service:

```
{
  "application_name": "Twake Chat",
  "application_welcome_message": "Welcome to Twake Chat!",
  "default_homeserver": "matrix.linagora.com",
  "privacy_url": "https://twake.app/en/privacy/",
  "render_html": true,
  "hide_redacted_events": false,
  "hide_unknown_events": false,
  "issue_id": "",
  "registration_url": "https://example.com/",
  "twake_workplace_homeserver": "https://example.com/",
  "app_grid_dashboard_available": true,
  "homeserver": "https://example.com/",
  "platform": "platform"
  "default_max_upload_avatar_size_in_bytes": 1000000,
  "dev_mode": false,
  "qr_code_download_url": "https://example.com/",
  "enable_logs": true,
  "support_url": "https://example.com/"
}
```

- `application_name`: The name will be showed in App Grid
- `application_welcome_message`: The welcome message will be showed in App Grid
- `default_homeserver`: The default homeserver
- `privacy_url`: The privacy policy URL
- `render_html`: Render HTML in messages
- `hide_redacted_events`: Hide redacted events
- `hide_unknown_events`: Hide unknown events
- `issue_id`: Issue ID
- `registration_url`: Registration URL for public platform
- `twake_workplace_homeserver`: Twake workplace homeserver
- `app_grid_dashboard_available`: Enable App Grid
- `homeserver`: Homeserver
- `platform`: Platform, `saas` for the case of public platform
- `default_max_upload_avatar_size_in_bytes`: Default max upload avatar size
- `dev_mode`: Enable to run app in IDE,
- `qr_code_download_url`: URL generate QR code to download app
- `enable_logs`: Enable logs
- `support_url`: Enable/Disable if you want to show support button with the URL. Default is `https://twake.app/support`

If you want to disable it, please change the value or remove this from `config.sample.json`