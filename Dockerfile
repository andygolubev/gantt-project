
FROM alpine
RUN apk add --no-cache postgresql-client
COPY ./app/ .
RUN chmod +x /connect.sh

CMD ["sh", "-c", "/connect.sh"]