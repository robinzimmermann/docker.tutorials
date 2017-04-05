FROM openjdk:8-jdk-alpine

# Install bash and openssl
RUN apk add --update --no-cache bash openssl && rm -rf /var/cache/apk/*

COPY entrypoint.sh \
     create-certs-server.sh \
     create-certs-enterprise-shield.sh \
     /
RUN chmod u+x /*.sh && mkdir /x509 /conf
COPY conf/* /conf/

#CMD echo "Sleeping" && sleep 300

ENTRYPOINT ["/entrypoint.sh"]
# CMD ["--help"]
CMD [ \
  "server", \
  "--root-ca",             "root-ca", \
  "--root-ca-password",    "rootpass", \
  "--signing-ca",          "signing-ca", \
  "--signing-ca-password", "signingpass", \
  "--days",                "10" \
]

# CMD ["server", "--root-ca", "root-ca", "--root-ca-password", "rootpass", "--signing-ca", "signing-ca", "--signing-ca-password", "signingpass"]

# ENTRYPOINT ["/entrypoint-ca2.sh"]
# CMD ["--command",     "create-ca", \
#      "--ca-key",      "rootca.example.com.key.pem", \
#      "--ca-cert",     "rootca.example.com.cert.pem", \
#      "--ca-password", "capass", \
#      "--days",        "10", \
#      "--country",     "US", \
#      "--state",       "California", \
#      "--org",         "Kaazing", \
#      "--org-unit",    "Kaazing Demo Certificate Authority", \
#      "--common-name", "Kaazing Demo Root CA", \
#      "--overwrite",   "false" \
# ]

# ENTRYPOINT ["/entrypoint-ca2.sh"]
# CMD ["--command",           "create-ca", \
#      "--ca-key",            "rootca.key.pem", \
#      "--ca-cert",           "rootca.cert.pem", \
#      "--ca-password",       "capass", \
#      "--ca-days",           "1", \
#      "--ca-subject-dn",     "/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Root CA", \
#      "--server-hostname",   "example.com", \
#      "--server-days",       "7", \
#      "--server-subject-dn", "/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.example.com", \
#      "--keystore",          "keystore.jceks", \
#      "--keystore-pw",       "ab987c", \
#      "--truststore",        "truststore.jceks", \
#      "--truststore-pw",     "changeit", \
#      "--trust-ca-alias",    "kaazingdemoca" \
# ]