#!/bin/bash

# TODO: Revoking:
# http://stackoverflow.com/questions/9496698/how-to-revoke-an-openssl-certificate-when-you-dont-have-the-certificate

# Where all the stuff goes.
OUTPUT_DIR=/certs

KEYS_DIR=private
CERTS_DIR=certs

ROOT_KEY=ca.key.pem
ROOT_CERT=ca.cert.pem

CA_PASSWORD="capass"

DAYS=365

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

function create_root_keypair()
{
  
}

function main()
{

  echo "Create root CA"
  echo "Logged to: ${LOG_FILE}"

  ROOT_KEY=${KEYS_DIR}/${ROOT_KEY}
  ROOT_CERT=${CERTS_DIR}/${ROOT_CERT}

  echo ""
  echo "Settings:"
  print_settings

  mkdir -p certs private log

  echo ""
  echo "Creating the root keypair: ${ROOT_KEY}"
  openssl genrsa -aes256 -passout pass:${CA_PASSWORD} -out ${ROOT_KEY} 4096

  if [ $? != 0 ]
  then
    echo "Something went wrong. Bailing."
    echo ""
    exit 1
  fi

  echo ""
  echo "Creating the root certificate: ${ROOT_CERT}"
  openssl req -config /openssl.cnf -passin pass:${CA_PASSWORD} \
        -key ${ROOT_KEY} \
        -new -x509 -days ${DAYS} -sha256 -extensions v3_ca \
        -out ${ROOT_CERT} \
        -subj "/C=${C}/ST=${ST}/O=${O}/OU=${OU}/CN=${CN}"

  if [ $? != 0 ]
  then
    echo ""
    echo "Something went wrong. Bailing."
    exit 1
  fi

mkdir -p _work/csr _work/newcerts
rm -rf _work/index.txt
touch _work/index.txt
# echo 1000 > _work/serial

echo ""
echo "Creating the server keypair: private/gateway.example.com.key.pem"
openssl genrsa -out private/gateway.example.com.key.pem 2048
# chmod 400 private/gateway.example.com.key.pem

# echo ""
echo "Creating the server certificate signing request: _work/csr/gateway.example.com.csr.pem"
openssl req -config /openssl.cnf \
      -key private/gateway.example.com.key.pem \
      -new -sha256 -out _work/csr/gateway.example.com.csr.pem \
      -subj "/C=US/ST=CA/O=Kaazing/OU=Kaazing Demo/CN=*.gateway.example.com"

rm -rf certs/gateway.example.com.cert.pem
echo ""
echo "Signing the CSR with the CA: certs/gateway.example.com.cert.pem"
openssl ca -config /openssl.cnf -passin pass:${CA_PASSWORD} -batch \
      -extensions server_cert -days 3650 -notext -md sha256 \
      -in _work/csr/gateway.example.com.csr.pem \
      -out certs/gateway.example.com.cert.pem
chmod 444 certs/gateway.example.com.cert.pem




echo ""
echo "NET-NET-NET Creating the server keypair: private/gateway.example.net.key.pem"
openssl genrsa -out private/gateway.example.net.key.pem 2048
# chmod 400 private/gateway.example.net.key.pem

echo ""
echo "NET-NET-NET Creating the server certificate signing request: _work/csr/gateway.example.net.csr.pem"
openssl req -config /openssl.cnf \
      -key private/gateway.example.net.key.pem \
      -new -sha256 -out _work/csr/gateway.example.net.csr.pem \
      -subj "/C=US/ST=CA/O=Kaazing/OU=Kaazing Demo/CN=*.gateway.example.net"

rm -rf certs/gateway.example.net.cert.pem
echo ""
echo "NET-NET-NET Signing the CSR with the CA: certs/gateway.example.net.cert.pem"
openssl ca -config /openssl.cnf -passin pass:${CA_PASSWORD} -batch \
      -extensions server_cert -days 3650 -notext -md sha256 \
      -in _work/csr/gateway.example.net.csr.pem \
      -out certs/gateway.example.net.cert.pem
chmod 444 certs/gateway.example.net.cert.pem




echo ""
echo "Verifying the certificate: gateway.example.com"
openssl x509 -noout -text -in certs/gateway.example.com.cert.pem

echo ""
echo "Verifying the certificate: gateway.example.net"
openssl x509 -noout -text -in certs/gateway.example.net.cert.pem

echo ""
echo "Verifying that there is a chain of trust to the root CA"
openssl verify -CAfile certs/ca.cert.pem certs/gateway.example.com.cert.pem

echo ""
echo "Verifying that there is a chain of trust to the root CA"
openssl verify -CAfile certs/ca.cert.pem certs/gateway.example.net.cert.pem

  echo ""
  echo "Summary:"
  print_settings

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
