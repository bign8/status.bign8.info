# SASS builder
# Builds SASS files and deletes blank lines from output
# - https://sass-lang.com/libsass
# - https://github.com/sass/libsass
# - https://github.com/xzyfer/docker-libsass
FROM xzyfer/docker-libsass:3.2.5 as sass
ADD /web/style.sass /
RUN sassc --style compact style.sass > style.css
RUN sed '/^$/d' -i style.css

# TODO: bake style.css into index.html

# TODO: build static assets into go file stuff

# Golang builder
# - https://medium.com/@kelseyhightower/b5696e26eb07
FROM golang:1.10-alpine as go
WORKDIR /go/src/github.com/bign8/status.bign8.info/
ADD /main.go .
ADD /build/static.go build/
RUN CGO_ENABLED=0 go build -o status -ldflags="-s -w" -v

# TODO: use upx to compress output binary
# https://blog.filippo.io/shrink-your-go-binaries-with-this-one-weird-trick/

# Distributed Container
# Pulls components from previous build phases to create final container
FROM scratch
EXPOSE 8081
COPY --from=go /go/src/github.com/bign8/status.bign8.info/status /
ENTRYPOINT ["/status"]
