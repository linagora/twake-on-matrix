## Configuration for App Grid

### Context
- Twake Chat is a service inside Twake Workspace which include other services
- User need to access other services from Twake Chat
- Just only support for web version

### How to config

1. Add services to configuration file

- Each service have the information:
```
    {
      "appName": "Twake Chat",
      "icon": "ic_twake_chat.svg",
      "appLink": "https://beta.twake.app/",
    }
```

- All services must be added to the configuration file [configurations\app_dashboard.json](https://github.com/linagora/twake-on-matrix/blob/main/configurations/app_dashboard.json)
  For example:
```
{
  "apps": [
    {
      "appName": "Twake Mail",
      "icon": "ic_twake_mail.svg",
      "appLink": "http://tmail.linagora.com/"
    },
    {
      "appName": "Twake Chat",
      "icon": "ic_twake_chat.svg",
      "appLink": "https://beta.twake.app/"
    },
    ...
  ]
}
```

- `appName`: The name will be showed in App Grid
- `icon`: Name of icon was added in `configurations\icons` folder
- `appLink`: Service URL

2. Enable it in [config.sample.json](https://github.com/linagora/twake-on-matrix/blob/main/config.sample.json)
```
app_grid_dashboard_available=true
```
If you want to disable it, please change the value to `false` or remove this from `config.sample.json`