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
#CMD ["--help"]
CMD [ \
  "server", \
  "--root-ca-subject",    "/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Root CA", \
  "--signing-ca-subject", "/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Signing CA", \
  "--server-ca-subject",  "/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.example.com" \
]

# CMD [ \
#   "server", \
#   "--root-ca",              "root-ca", \
#   "--root-ca-password",     "rootpass", \
#   "--signing-ca",           "signing-ca", \
#   "--signing-ca-password",  "signingpass", \
#   "--days",                 "1" \
# ]
