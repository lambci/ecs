FROM alpine:3.4

WORKDIR /src

RUN apk add --no-cache bash curl git docker nodejs

ADD . .

CMD ./main.sh

