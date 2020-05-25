FROM golang:alpine as builder

WORKDIR /go/src/app
COPY ./main.go .

RUN go get -d -v ./...
RUN go install -v ./...

CMD ["app"]

