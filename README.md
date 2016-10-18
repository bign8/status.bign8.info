# [Matrix Service Monitor](http://status.bign8.info)

[![License MIT](https://img.shields.io/npm/l/express.svg)](http://opensource.org/licenses/MIT)
[![Go Report Card](https://goreportcard.com/badge/github.com/bign8/status.bign8.info)](https://goreportcard.com/report/github.com/bign8/status.bign8.info)
[![GoDoc](http://godoc.org/github.com/bign8/status.bign8.info?status.png)](http://godoc.org/github.com/bign8/status.bign8.info)
[![GitHub release](http://img.shields.io/github/release/bign8/status.bign8.info.svg)](https://github.com/bign8/status.bign8.info/releases)


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
# Production (:8081)
$ go generate
$ go build
$ ./main

# Development (:8080)
$ pub serve
$ go run main.go static.go
```
