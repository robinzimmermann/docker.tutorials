FROM openjdk:8-jdk-alpine

# Install bash and openssl
RUN apk add --update --no-cache bash openssl && rm -rf /var/cache/apk/*

COPY entrypoint.sh \
     create-certs-server.sh \
     create-certs-enterprise-shield.sh \
     /
RUN chmod u+x /*.sh && mkdir /x509 /conf
COPY conf/* /conf/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
