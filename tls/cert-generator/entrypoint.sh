#!/bin/bash

# TODO: Revoking:
# http://stackoverflow.com/questions/9496698/how-to-revoke-an-openssl-certificate-when-you-dont-have-the-certificate

if [ "$1" == "sleep" ]
then
  echo "Going to sleep"
  sleep 300
  exit 0
fi

# Where all the stuff goes.
OUTPUT_DIR=/certs

WORK_DIR=_work

CSR_DIR=${WORK_DIR}/csr

KEYS_DIR=private
CERTS_DIR=certs

EXAMPLE_COM_ROOT_KEY=${KEYS_DIR}/ca.example.com.key.pem
EXAMPLE_COM_ROOT_CERT=${CERTS_DIR}/ca.example.com.cert.pem

GATEWAY_EXAMPLE_COM_SERVER_KEY=${KEYS_DIR}/gateway.example.com.key.pem
GATEWAY_EXAMPLE_COM_SERVER_CERT=${CERTS_DIR}/gateway.example.com.cert.pem
GATEWAY_EXAMPLE_COM_CSR=${CSR_DIR}/gateway.example.com.csr.pem

EXAMPLE_NET_ROOT_KEY=${KEYS_DIR}/ca.example.net.key.pem
EXAMPLE_NET_ROOT_CERT=${CERTS_DIR}/ca.example.net.cert.pem

GATEWAY_EXAMPLE_NET_SERVER_KEY=${KEYS_DIR}/gateway.example.net.key.pem
GATEWAY_EXAMPLE_NET_SERVER_CERT=${CERTS_DIR}/gateway.example.net.cert.pem
GATEWAY_EXAMPLE_NET_CSR=${CSR_DIR}/gateway.example.net.csr.pem

CA_PASSWORD="capass"

DAYS=7

# Subject attributes
C=US
ST=California
O=Kaazing
OU="Kaazing Demo Certificate Authority"
CN="Kaazing Demo Root CA"

# Used for logging.
DATE=`date +"%Y-%m-%d %T"`

# Format date so it can be used as a filename.
DATE_SANITIZED=${DATE//:/-}
DATE_SANITIZED=${DATE_SANITIZED// /_}

LOG_DIR=${OUTPUT_DIR}/log
LOG_FILE=${LOG_DIR}/${DATE_SANITIZED}.log

function usage()
{
    echo "if this was a real script you would see something useful here"
    echo ""
    echo "entrypoint.sh"
    echo "    -h |--help        Show this usage"
    echo "    --root-key        Root keypair filename. Default: ${ROOT_KEY}"
    echo "    --root-cert       Root cert filename. Default: ${ROOT_CERT}"
    echo "    --ca-password     Password for keypair and cert. Default: ${CA_PASSWORD}"
    echo "    --days            Number of cert is valid for. Default: ${DAYS}"
    echo "    -c |--country     Country field of the subject. Default: ${C}"
    echo "    -st|--state       State or Province field of the subject. Default: ${ST}"
    echo "    -o |--org         Organization field of the subject. Default: ${O}"
    echo "    -ou|--org-unit    Organizational Unit field of the subject. Default: ${OU}"
    echo "    -cn|--common-name Common Name field of the subject. Default: ${CN}"
    echo ""
    echo "Example: entrypoint.sh \\"
    echo "           --root-key    ${ROOT_KEY} \\"
    echo "           --root-cert   ${ROOT_CERT} \\"
    echo "           --ca-password ${CA_PASSWORD} \\"
    echo "           --days        ${DAYS} \\"
    echo "           --country     ${C} \\"
    echo "           --state       ${ST} \\"
    echo "           --org         ${O} \\"
    echo "           --org-unit    ${OU} \\"
    echo "           --common-name ${CN}"
}

# $1 is the path and filename of the cert. e.g. certs/gateway.example.com.cert.pem
function print_cert()
{
  CERT=$1
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Printing certificate ${CERT}"
  echo "------------------------------------------------------------------------------"
  openssl x509 -noout -text -in ${CERT}
}

# $1 is the path and filename of the ca cert. e.g. private/ca.cert.pem
# $2 is the path and filename of the server cert. e.g. certs/gateway.example.com.cert.pem
function verify_chain_of_trust()
{
  CA_CERT=$1
  SERVER_CERT=$2
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Verifying that there is a chain of trust between ${CA_CERT} and ${SERVER_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl verify -purpose sslserver -CAfile ${CA_CERT} ${SERVER_CERT}
}

function print_settings()
{
  echo -e "  Root key:    ${ROOT_KEY}\t[Password: ${CA_PASSWORD}]"
  echo -e "  Root cert:   ${ROOT_CERT}\t[Valid for: ${DAYS} days]"
  echo -e "  C:           ${C}"
  echo -e "  ST:          ${ST}"
  echo -e "  O:           ${O}"
  echo -e "  OU:          ${OU}"
  echo -e "  CN:          ${CN}"
}

function main()
{

  echo ""
  echo "Let's create some certs!"
  echo "Everything logged to: ${LOG_FILE}"

  # ROOT_KEY=${KEYS_DIR}/${EXAMPLE_COM_ROOT_KEY}
  # ROOT_CERT=${CERTS_DIR}/${EXAMPLE_COM_ROOT_CERT}

  # echo ""
  # echo "Settings:"
  # print_settings

  mkdir -p certs private log

  mkdir -p _work/csr _work/newcerts
  rm -rf _work/index.txt
  touch _work/index.txt
  echo 1000 > _work/serial

  export SAN="DNS:gateway.example.com, DNS:*.gateway.example.com"

  # echo ""
  # echo "------------------------------------------------------------------------------"
  # echo "Creating the root keypair: private/ca.example.com.key.pem"
  # echo "------------------------------------------------------------------------------"
  # openssl genrsa -aes256 -passout pass:${CA_PASSWORD} -out private/ca.example.com.key.pem 4096

  # echo ""
  # echo "------------------------------------------------------------------------------"
  # echo "Creating the root certificate: certs/ca.example.com.cert.pem"
  # echo "------------------------------------------------------------------------------"
  # openssl req -config /openssl.cnf -passin pass:${CA_PASSWORD} \
  #       -key private/ca.example.com.key.pem \
  #       -new -x509 -days 10 -sha256 -extensions v3_ca \
  #       -out certs/ca.example.com.cert.pem \
  #       -subj "/C=${C}/ST=${ST}/O=${O}/OU=${OU}/CN=${CN}"

  # print_cert certs/ca.example.com.cert.pem

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the server keypair: private/gateway.example.com.key.pem"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -out private/gateway.example.com.key.pem 2048

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the server certificate signing request: _work/csr/gateway.example.com.csr.pem"
  echo "------------------------------------------------------------------------------"
  openssl req -config /openssl.cnf \
        -key private/gateway.example.com.key.pem \
        -new -sha256 -out _work/csr/gateway.example.com.csr.pem \
        -subj "/C=${C}/ST=${ST}/O=${O}/OU=Kaazing Demo/CN=*.gateway.example.com"

  rm -rf certs/gateway.example.com.cert.pem
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing the CSR with the CA: certs/gateway.example.com.cert.pem"
  echo "------------------------------------------------------------------------------"
  openssl ca -config /openssl.cnf -passin pass:${CA_PASSWORD} -batch \
        -extensions server_cert -days 3650 -notext -md sha256 \
        -keyfile private/ca.example.com.key.pem -cert certs/ca.example.com.cert.pem \
        -in _work/csr/gateway.example.com.csr.pem \
        -out certs/gateway.example.com.cert.pem
  chmod 444 certs/gateway.example.com.cert.pem

  print_cert certs/gateway.example.com.cert.pem

  echo ""
  echo "=============================================================================="
  echo "Starting example.net"
  echo "=============================================================================="

  export SAN="DNS:gateway.example.net, DNS:*.gateway.example.net"

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the server keypair: private/gateway.example.net.key.pem"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -out private/gateway.example.net.key.pem 2048

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the server certificate signing request: _work/csr/gateway.example.net.csr.pem"
  echo "------------------------------------------------------------------------------"
  openssl req -config /openssl.cnf \
        -key private/gateway.example.net.key.pem \
        -new -sha256 -out _work/csr/gateway.example.net.csr.pem \
        -subj "/C=${C}/ST=${ST}/O=${O}/OU=Kaazing Demo/CN=*.gateway.example.net"

  rm -rf certs/gateway.example.net.cert.pem
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing the CSR with the CA: certs/gateway.example.net.cert.pem"
  echo "------------------------------------------------------------------------------"
  openssl ca -config /openssl.cnf -passin pass:${CA_PASSWORD} -batch \
        -extensions server_cert -days 3650 -notext -md sha256 \
        -keyfile private/ca.example.com.key.pem -cert certs/ca.example.com.cert.pem \
        -in _work/csr/gateway.example.net.csr.pem \
        -out certs/gateway.example.net.cert.pem
  chmod 444 certs/gateway.example.net.cert.pem

  print_cert certs/gateway.example.net.cert.pem

  verify_chain_of_trust certs/ca.example.com.cert.pem certs/gateway.example.com.cert.pem
  verify_chain_of_trust certs/ca.example.com.cert.pem certs/gateway.example.net.cert.pem


  # export SAN="DNS:gateway.example.net, DNS:*.gateway.example.net"
  # create_ca_keypair ${EXAMPLE_NET_ROOT_KEY}
  # create_ca_cert ${EXAMPLE_NET_ROOT_KEY} ${EXAMPLE_NET_ROOT_CERT} "/C=${C}/ST=${ST}/O=${O}/OU=${OU}/CN=Kaazing example.net root CA"
  # create_server_keypair ${GATEWAY_EXAMPLE_NET_SERVER_KEY}
  # create_server_csr ${GATEWAY_EXAMPLE_NET_SERVER_KEY} ${GATEWAY_EXAMPLE_NET_CSR} "/C=${C}/ST=${ST}/O=${O}/OU=Kaazing Demo/CN=*.gateway.example.net"
  # sign_csr ${EXAMPLE_NET_ROOT_KEY} ${EXAMPLE_NET_ROOT_CERT} ${GATEWAY_EXAMPLE_NET_CSR} ${GATEWAY_EXAMPLE_NET_SERVER_CERT} "DNS:gateway.example.net, DNS:*.gateway.example.net"
  # print_cert ${GATEWAY_EXAMPLE_NET_SERVER_CERT}

  # export SAN="DNS:gateway.example.net, DNS:*.gateway.example.net"
  # create_server_keypair ${GATEWAY_EXAMPLE_NET_SERVER_KEY}
  # create_server_csr ${GATEWAY_EXAMPLE_NET_SERVER_KEY} ${GATEWAY_EXAMPLE_NET_CSR} "/C=${C}/ST=${ST}/O=${O}/OU=Kaazing Demo/CN=*.gateway.example.net"
  # sign_csr ${EXAMPLE_COM_ROOT_KEY} ${EXAMPLE_COM_ROOT_CERT} ${GATEWAY_EXAMPLE_NET_CSR} ${GATEWAY_EXAMPLE_NET_SERVER_CERT}
  # print_cert ${GATEWAY_EXAMPLE_NET_SERVER_CERT}


  # verify_chain_of_trust ${EXAMPLE_COM_ROOT_CERT} ${GATEWAY_EXAMPLE_COM_SERVER_CERT}
#  verify_chain_of_trust ${EXAMPLE_NET_ROOT_CERT} ${GATEWAY_EXAMPLE_NET_SERVER_CERT}

  # verify_chain_of_trust ${EXAMPLE_COM_ROOT_CERT} ${GATEWAY_EXAMPLE_NET_SERVER_CERT}

  echo ""
  echo "Done."

}

# Parse the command line arguments
while [ "$1" != "" ]; do
    PARAM=$1
    VALUE=$2
    # echo "PARAM=${PARAM}"
    # echo "VALUE=${VALUE}"
    case $PARAM in
        -h | --help)
            usage $0
            exit
            ;;
        --output-dir)
            OUTPUT_DIR=$VALUE
            ;;
        --root-key)
            ROOT_KEY=$VALUE
            ;;
        --root-cert)
            ROOT_CERT=$VALUE
            ;;
        --ca-password)
            CA_PASSWORD=$VALUE
            ;;
        --days)
            DAYS=$VALUE
            ;;
        --country)
            C=$VALUE
            ;;
        --state)
            ST=$VALUE
            ;;
        --org)
            O=$VALUE
            ;;
        --org-unit)
            OU=$VALUE
            ;;
        --common-name)
            CN=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage $0
            exit 1
            ;;
    esac
    shift 2
done

mkdir -p ${OUTPUT_DIR} ${LOG_DIR}
cd ${OUTPUT_DIR}
main 2>&1 | tee -a ${LOG_FILE}

  # if [ ! -z "${EMAIL// }" ]
  # then
  #   SUBJECT="${SUBJECT}/emailAddress=${EMAIL}"
  # fi
