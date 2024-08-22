
FROM alpine

COPY ./app/ .
RUN chmod +x /*
RUN ls -la /

CMD ["/connect.sh"]