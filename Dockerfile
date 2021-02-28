# Dart builder
# - https://hub.docker.com/r/google/dart/
FROM google/dart:2 as dart
WORKDIR /app
ADD pubspec.* /app/
RUN pub get
ADD web/ /app/web/
RUN dart pub run build_runner build --release --output build --delete-conflicting-outputs

# Golang builder
# Builds static assets, bundles them with go-bindata and compiles go application
# - https://medium.com/@kelseyhightower/b5696e26eb07
FROM golang:1.16-alpine as go
WORKDIR /go/src
COPY --from=dart /app/build/web build/web/
ADD go.mod main.go ./
RUN CGO_ENABLED=0 go build -o status -ldflags="-s -w" -v

# TODO: use upx to compress output binary
# https://blog.filippo.io/shrink-your-go-binaries-with-this-one-weird-trick/

# Distributed Container
# Pulls components from previous build phases to create final container
FROM scratch
EXPOSE 8081
COPY --from=go /go/src/status /
ENTRYPOINT ["/status"]
