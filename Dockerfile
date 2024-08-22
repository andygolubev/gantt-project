
FROM alpine

COPY ./app /app
RUN chmod +x /app/*

CMD ["/app/connect.sh"]