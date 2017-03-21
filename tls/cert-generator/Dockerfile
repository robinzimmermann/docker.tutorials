#FROM alpine:latest
FROM openjdk:8-jdk-alpine

# Install bash and openssl
RUN apk add --update --no-cache bash openssl inotify-tools && rm -rf /var/cache/apk/*

COPY entrypoint-ca2.sh openssl*.cnf alt-names.txt /
RUN mkdir /x509 && chmod +x /entrypoint-ca2.sh

#CMD echo "Sleeping" && sleep 300

ENTRYPOINT ["/entrypoint-ca2.sh"]
CMD ["--help"]

# ENTRYPOINT ["/entrypoint-ca2.sh"]
# CMD ["--command",     "create-ca", \
#      "--ca-key",      "ca.example.com.key.pem", \
#      "--ca-cert",     "ca.example.com.cert.pem", \
#      "--ca-password", "capass", \
#      "--days",        "10", \
#      "--country",     "US", \
#      "--state",       "California", \
#      "--org",         "Kaazing", \
#      "--org-unit",    "Kaazing Demo Certificate Authority", \
#      "--common-name", "Kaazing Demo Root CA", \
#      "--overwrite",   "false" \
# ]

ENTRYPOINT ["/entrypoint-ca2.sh"]
CMD ["--command",           "create-ca", \
     "--ca-key",            "ca.key.pem", \
     "--ca-cert",           "ca.cert.pem", \
     "--ca-password",       "capass", \
     "--ca-days",           "1", \
     "--ca-subject-dn",     "/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Root CA", \
     "--server-hostname",   "gateway.example.com", \
     "--server-days",       "7", \
     "--server-subject-dn", "/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.gateway.example.com", \
     "--keystore",          "keystore.jceks", \
     "--keystore-pw",       "ab987c", \
     "--truststore",        "truststore.jceks", \
     "--truststore-pw",     "changeit", \
     "--trust-ca-alias",    "kaazingdemoca" \
]