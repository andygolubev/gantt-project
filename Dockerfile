
FROM alpine

COPY ./app/ .
RUN chmod +x /connect.sh

CMD ["sh", "-c", "/connect.sh"]