#!/bin/bash

OUTPUT_DIR=/x509

# ROOT_CA_NAME=root-ca
# ROOT_PW=rootpass
# SIGNING_CA_NAME=signing-ca
# SIGNING_PW=signingpass
# DAYS=1

EXAMPLECOM_SUBDOMAIN=example
EXAMPLECOM_KEY=certs/example.com.key
EXAMPLECOM_CSR=certs/example.com.csr
EXAMPLECOM_CERT=certs/example.com.crt

# Save the args, minus the command.
ARGS=("$@")

function usage()
{
  echo ""
  echo "  Options:"
  echo ""
  echo "    --root-ca              The name of the root CA"
  echo "    --root-ca-password     Password for the root CA"
  echo "    --signing-ca           The name of the signing CA"
  echo "    --signing-ca-password  Password for the signing CA"
  echo "    --days                 Number of days the CAs are valid for"
  echo ""
  echo "  Example:"
  echo ""
  echo "    --root-ca              root-ca"
  echo "    --root-ca-password     rootpass"
  echo "    --signing-ca           signing-ca"
  echo "    --signing-ca-password  signingpass"
  echo "    --days                 1"
}

# Check if a variable is present, and error if it is not.
# $1 is the variable containing the argument ${CA_KEY_NAME}
# $2 is the argument name. e.g. --ca-key
function check_mandatory_arg
{
  if [ -z "${1}" ]
  then
    if [ -z "${MISSING_ARG}" ]; then echo ""; fi
    echo "Missing argument: ${2}"
    MISSING_ARG="true"
  fi
}

function process_args
{

  local n=${#ARGS[@]}

  if (( ${n} > 0 ))
  then

    i=$((0))
    while [ ${i} -lt ${n} ];
    do
      PARAM=${ARGS[${i}]}

      case ${PARAM} in
        -h | --help)
          usage
          exit 0
          ;;
        --root-ca)
          i=$((i+1)); ROOT_CA_NAME=${ARGS[${i}]}
          ;;
        --root-ca-password)
          i=$((i+1)); ROOT_PW=${ARGS[${i}]}
          ;;
        --signing-ca)
          i=$((i+1)); SIGNING_CA_NAME=${ARGS[${i}]}
          ;;
        --signing-ca-password)
          i=$((i+1)); SIGNING_PW=${ARGS[${i}]}
          ;;
        --days)
          i=$((i+1)); DAYS=${ARGS[${i}]}
          ;;
        *)
          echo "ERROR: unknown parameter \"${PARAM}\""
          usage
          exit 1
          ;;
      esac

      i=$((i+1))
    done

  else

    usage
    exit 0

  fi

  check_mandatory_arg "${ROOT_CA_NAME}"     "--root-ca"
  check_mandatory_arg "${ROOT_PW}"          "--root-ca-password"
  check_mandatory_arg "${SIGNING_CA_NAME}"  "--signing-ca"
  check_mandatory_arg "${SIGNING_PW}"       "--signing-ca-password"
  check_mandatory_arg "${DAYS}"             "--days"

  # By exiting here, it will show all error messages, rather than one at a time.
  if [ "${MISSING_ARG}" ]
  then
    usage
    exit 1
  fi

}

function print_settings()
{
  echo -e "  Command:     ${COMMAND}"
  echo -e "  Output dir:  ${OUTPUT_DIR}"
  echo -e "  CA:"
  echo -e "    Key:       ${CA_KEY}\t[Password: ${CA_PW}]"
  echo -e "    Cert:      ${CA_CERT}\t[Valid for: ${CA_DAYS} days]"
  echo -e "    Subject:   ${CA_SUBJECT}"
  echo -e "  Server:"
  echo -e "    Key:       ${KEY}"
  echo -e "    Cert:      ${CERT}\t[Valid for: ${SERVER_DAYS} days]"
  echo -e "    Subject:   ${SERVER_SUBJECT}"
  echo -e "    SAN:       ${SAN}"
  echo -e "  Keystore:    ${KEYSTORE}\t[Password: ${KEYSTORE_PW}, Alias: ${SERVER_HOSTNAME}]"
  echo -e "  Truststore:  ${TRUSTSTORE}\t[Password: ${TRUSTSTORE_PW}, Alias: ${TRUST_CA_ALIAS}]"
}

# $1 is the path and filename of the cert. e.g. certs/example.com.cert.pem
function print_cert()
{
  CERT=$1
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Printing certificate ${CERT}"
  echo "------------------------------------------------------------------------------"
  openssl x509 -noout -text -in ${CERT}
}

# $1 is the path and filename of the crl. e.g. x509/crl/root-ca.crl
# More info: https://langui.sh/2010/01/10/parsing-a-crl-with-openssl/
function print_crl()
{
  CRL=$1
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Printing CRL ${CRL}"
  echo "------------------------------------------------------------------------------"
  openssl crl -text -noout -in ${CRL}
}

# $1 is the path and filename of the ca cert. e.g. private/rootca.cert.pem
# $2 is the path and filename of the server cert. e.g. certs/example.com.cert.pem
function verify_chain_of_trust()
{
  CA_CERT=$1
  SERVER_CERT=$2
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Verifying chain of trust for ${SERVER_CERT} using ${CA_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl verify -verbose -purpose sslserver -policy_check -CAfile ${CA_CERT} ${SERVER_CERT}
}

function create_root_ca()
{

  # This environment variable is referenced in the conf file
  export ROOT_CA=$1

  ROOT_KEY=ca/${ROOT_CA}/private/${ROOT_CA}.key
  ROOT_CSR=ca/${ROOT_CA}.csr
  ROOT_CERT=ca/${ROOT_CA}.crt
  ROOT_CRL=crl/${ROOT_CA}.crl
  ROOT_DER=ca/${ROOT_CA}.der

  # Create directories"
  mkdir -p ca/${ROOT_CA}/private ca/${ROOT_CA}/db crl certs
  # chmod 700 ca/${ROOT_CA}/private

  # Create database"
  cp /dev/null ca/${ROOT_CA}/db/${ROOT_CA}.db
  cp /dev/null ca/${ROOT_CA}/db/${ROOT_CA}.db.attr
  echo 01 > ca/${ROOT_CA}/db/${ROOT_CA}.crt.srl
  echo 01 > ca/${ROOT_CA}/db/${ROOT_CA}.crl.srl

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Generating key and creating request: ${ROOT_CSR}"
  echo "------------------------------------------------------------------------------"
  openssl req -new \
      -config ../conf/root-ca.conf \
      -keyout ${ROOT_KEY} \
      -passout pass:${ROOT_PW} \
      -out ${ROOT_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating certificate: ${ROOT_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca -selfsign \
      -config ../conf/root-ca.conf \
      -extensions root_ca_ext \
      -days ${DAYS}  \
      -in ${ROOT_CSR} \
      -passin pass:${ROOT_PW} -batch \
      -out ${ROOT_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_cert ${ROOT_CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating initial CRL: ${ROOT_CRL}"
  echo "------------------------------------------------------------------------------"
  openssl ca -gencrl \
      -config ../conf/root-ca.conf \
      -passin pass:${ROOT_PW} \
      -out ${ROOT_CRL}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_crl ${ROOT_CRL}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating DER certificate for publishing: ${ROOT_CRL}"
  echo "------------------------------------------------------------------------------"
  # All published certificates must be in DER format. MIME type: application/pkix-cert. [RFC 2585#section-4.1]
  openssl x509 \
      -in ${ROOT_CERT} \
      -out ${ROOT_DER} \
      -outform der

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

}

function create_signing_ca()
{

  # This environment variable is referenced in the conf file
  export SIGNING_CA=$1

  SIGNING_KEY=ca/${SIGNING_CA}/private/${SIGNING_CA}.key
  SIGNING_CSR=ca/${SIGNING_CA}.csr
  SIGNING_CERT=ca/${SIGNING_CA}.crt
  SIGNING_CRL=crl/${SIGNING_CA}.crl
  SIGNING_DER=ca/${SIGNING_CA}.der

  SIGNING_CHAIN=ca/${SIGNING_CA}-chain.pem

  # Create directories"
  mkdir -p ca/${SIGNING_CA}/private ca/${SIGNING_CA}/db crl certs
  # chmod 700 ca/${SIGNING_CA}/private

  # Create database"
  cp /dev/null ca/${SIGNING_CA}/db/${SIGNING_CA}.db
  cp /dev/null ca/${SIGNING_CA}/db/${SIGNING_CA}.db.attr
  echo 01 > ca/${SIGNING_CA}/db/${SIGNING_CA}.crt.srl
  echo 01 > ca/${SIGNING_CA}/db/${SIGNING_CA}.crl.srl

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Generating key and creating request: ${SIGNING_CSR}"
  echo "------------------------------------------------------------------------------"
  openssl req -new \
      -config ../conf/signing-ca.conf \
      -keyout ${SIGNING_KEY} \
      -passout pass:${SIGNING_PW} \
      -out ${SIGNING_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Signing CSR with root CA: ${SIGNING_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca \
      -config ../conf/root-ca.conf \
      -extensions signing_ca_ext \
      -days ${DAYS}  \
      -in ${SIGNING_CSR} \
      -passin pass:${ROOT_PW} -batch \
      -out ${SIGNING_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_cert ${SIGNING_CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Creating initial CRL: ${SIGNING_CRL}"
  echo "------------------------------------------------------------------------------"
  openssl ca -gencrl \
      -config ../conf/signing-ca.conf \
      -out ${SIGNING_CRL} \
      -passin pass:${SIGNING_PW}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_crl ${ROOT_CRL}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Create certificate chain: ${SIGNING_CHAIN}"
  echo "------------------------------------------------------------------------------"
  cat ${SIGNING_CERT} ${ROOT_CERT} > ${SIGNING_CHAIN}

}

function create_examplecom_cert()
{

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "example.com cert: Creating certificate signing request: ${SIGNING_CHAIN}"
  echo "------------------------------------------------------------------------------"
  export SAN="DNS:${EXAMPLECOM_SUBDOMAIN}.com,DNS:*.${EXAMPLECOM_SUBDOMAIN}.com,DNS:${EXAMPLECOM_SUBDOMAIN}.net,DNS:*.${EXAMPLECOM_SUBDOMAIN}.net,DNS:${EXAMPLECOM_SUBDOMAIN}.org,DNS:*.${EXAMPLECOM_SUBDOMAIN}.org"
  openssl req -new \
      -config ../conf/server.conf \
      -out ${EXAMPLECOM_CSR} \
      -keyout ${EXAMPLECOM_KEY} \
      -subj "/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.${EXAMPLECOM_SUBDOMAIN}.com"

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "example.com cert: Signing CSR with signing CA: ${SIGNING_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca \
      -config ../conf/signing-ca.conf \
      -extensions server_ext \
      -days ${DAYS}  \
      -passin pass:${SIGNING_PW} -batch \
      -in ${EXAMPLECOM_CSR} \
      -out ${EXAMPLECOM_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_cert ${EXAMPLECOM_CERT}

  verify_chain_of_trust ${SIGNING_CHAIN} ${EXAMPLECOM_CERT}

}

function main()
{

  cd ${OUTPUT_DIR}

  process_args

  create_root_ca ${ROOT_CA_NAME}
  create_signing_ca ${SIGNING_CA_NAME}
  create_examplecom_cert

  echo ""
  echo "Done."

}

main 2>&1