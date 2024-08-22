
FROM alpine

COPY ./app/ .
RUN chmod +x /app/*
RUN ls -la /

CMD ["/app/connect.sh"]