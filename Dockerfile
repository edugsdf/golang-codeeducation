#----------------------------------------------------------------
# 1) Criar imagem (gorda) com todas as dependencias
FROM golang@sha256:244a736db4a1d2611d257e7403c729663ce2eb08d4628868f9d9ef2735496659 as builder

# Instalar pacotes de dependencias do git. E CA para os endpoints HTTPS
RUN apk update && apk add --no-cache git ca-certificates tzdata && update-ca-certificates

# Criar o usuário do container
ENV USER=appuser
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"
WORKDIR $GOPATH/src/edugsdf/codeeducation/
COPY ./main.go .

# dependencies ((essa parte não entendi bem))
RUN go get -d -v

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -ldflags='-w -s -extldflags "-static"' -a \
      -o /go/bin/main .


#----------------------------------------------------------------
# 2) Criar imagem magra, só o necessário
FROM scratch

# Copiar da imagem builder para scratch
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copia o executavel apenas
COPY --from=builder /go/bin/main /go/bin/main

# usuário com poucos privilegios
USER appuser:appuser

# Fogo no parquinhos!!!
ENTRYPOINT ["/go/bin/main"]

#---------Imagem grande, primeira versão
# FROM golang:alpine 
# WORKDIR /app
# ADD . /app
# RUN cd /app && go build -o main.go
# ENTRYPOINT ./main.go