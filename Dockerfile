FROM golang:1.10-alpine as go
WORKDIR /go/src/github.com/bign8/status.bign8.info/
ADD /main.go .
ADD /build/static.go build/
RUN go build -o status -ldflags="-s -w" -v

# TODO: use upx to compress output binary

FROM alpine
EXPOSE 8081
COPY --from=go /go/src/github.com/bign8/status.bign8.info/status /
ENTRYPOINT ["/status"]
