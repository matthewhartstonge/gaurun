FROM golang:1.12 as build-env
ADD . /usr/local/go/src/github.com/mercari/gaurun
RUN curl https://glide.sh/get | sh; \
    cd /usr/local/go/src/github.com/mercari/gaurun &&\
    glide install &&\
    cd /usr/local/go/src/github.com/mercari/gaurun/cmd/gaurun &&\
    go build -tags=internal -a -ldflags="-s -w -linkmode external -extldflags -static" -v  &&\
    cd /usr/local/go/src/github.com/mercari/gaurun/cmd/gaurun_recover &&\
    go build -tags=internal -a -ldflags="-s -w -linkmode external -extldflags -static" -v

FROM alpine:latest
RUN apk add --no-cache ca-certificates tzdata &&\
    addgroup -g 1000 -S gaurun &&\
    adduser -u 1000 -S gaurun -G gaurun
COPY --from=build-env /usr/local/go/src/github.com/mercari/gaurun/cmd/gaurun/gaurun /app/
COPY --from=build-env /usr/local/go/src/github.com/mercari/gaurun/cmd/gaurun_recover/gaurun_recover /app/
COPY ./conf/gaurun.toml /app/conf/gaurun.toml
USER gaurun
WORKDIR /app
EXPOSE 1056
CMD ["./gaurun", "-c", "conf/gaurun.toml"]
