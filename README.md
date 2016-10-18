# [Matrix Service Monitor](http://status.bign8.info)

This service allows users to monitor a grid of services to ensure overall system health.

[![Page](/img/page.png)](http://status.bign8.info)

## Settings

The Default Settings take the following form.

```json
{
 "envz": {
  "Google": "www.google.com",
  "Twitter": "www.twitter.com",
  "Facebook": "www.facebook.com",
  "Github": "github.com",
  "Snapchat": "www.snapchat.com",
  "Instagram": "www.instagram.com"
 },
 "svcz": {
  "Robots": "https://$/robots.txt",
  "Humans": "https://$/humans.txt",
  "service-1": "@/rand#demo-only",
  "service-2": "@/rand#demo-only",
  "service-3": "@/rand#demo-only"
 },
 "skip": [
  "Instagram-Humans",
  "Snapchat-Humans",
  "Twitter-Humans"
 ]
}
```

Both `envz` and `svcz` are a map from the displayed name to the environment and service target respectively.  The `$` character in `svcz` is replaced with each environment from `envz`.  The demo only `@` character is replaced with the host of the host server ([http://status.bign8.info](http://status.bign8.info) in this case).

The configuration is persisted in browser local-storage and should be restored upon re-visiting the site.

## Build

This project is based on both `Dart` and `Go` languages; Ensure that you have both development environments properly configured before building this project.

```sh
$ go generate
$ go run main.go static.go
```
