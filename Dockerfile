# SASS builder
# Builds SASS files and deletes blank lines from output
# - https://sass-lang.com/libsass
# - https://github.com/sass/libsass
# - https://github.com/xzyfer/docker-libsass
FROM xzyfer/docker-libsass:3.2.5 as sass
WORKDIR /
ADD /web/style.sass /
RUN sassc --style compact style.sass > style.css
RUN sed '/^$/d' -i style.css

# TODO: bake style.css into index.html

# Dart builder
# - https://hub.docker.com/r/google/dart/
FROM google/dart:1 as dart
WORKDIR /app
ADD pubspec.* /app/
RUN pub get
ADD web/ /app/web/
RUN pub get --offline
RUN pub build

# Golang builder
# Builds static assets, bundles them with go-bindata and compiles go application
# - https://medium.com/@kelseyhightower/b5696e26eb07
FROM golang:1.10-alpine as go
WORKDIR /go/src/github.com/bign8/status.bign8.info/
RUN apk add --no-cache git
RUN go get github.com/jteeuwen/go-bindata/...
COPY --from=sass /style.css build/web/
COPY --from=dart /app/build/web/ build/web/
RUN go-bindata -o build/static.go -pkg build -prefix build/web build/web
ADD /main.go .
RUN CGO_ENABLED=0 go build -o status -ldflags="-s -w" -v

# TODO: use upx to compress output binary
# https://blog.filippo.io/shrink-your-go-binaries-with-this-one-weird-trick/

# Distributed Container
# Pulls components from previous build phases to create final container
FROM scratch
EXPOSE 8081
COPY --from=go /go/src/github.com/bign8/status.bign8.info/status /
ENTRYPOINT ["/status"]
