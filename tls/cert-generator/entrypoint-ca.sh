#!/bin/bash

# Where all the stuff goes.
OUTPUT_DIR=/x509

# Defaults
CA_PASSWORD="capass"
DAYS=7

# Default subject attributes
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
  echo ""
  echo "entrypoint.sh"
  echo "    -h |--help        Show this usage"
  echo "    --command         The operation to perform. Values: create-ca|create-cert"
  echo "    --ca-key          Certificate authority keypair filename"
  echo "    --ca-cert         Certificate authority cert filename"
  echo "    --ca-password     Password for keypair and cert"
  echo "    --key             Server certificate keypair filename"
  echo "    --cert            Server certificate filename"
  echo "    --days            Number of cert is valid for"
  echo "    -c |--country     Country field of the subject"
  echo "    -st|--state       State or Province field of the subject"
  echo "    -o |--org         Organization field of the subject"
  echo "    -ou|--org-unit    Organizational Unit field of the subject"
  echo "    -cn|--common-name Common Name field of the subject"
  echo "    --alt-names       Subject Alternative Name (SAN) for a server certificate"
  echo "    --overwrite       Set to \"true\" to proceed if a key or cert file already exists"
  echo ""
  echo "Example: entrypoint.sh"
  echo "           --command     create-ca"
  echo "           --ca-key      ca.key.perm"
  echo "           --ca-cert     ca.cert.perm"
  echo "           --ca-password capass"
  echo "           --days        7"
  echo "           --country     US"
  echo "           --state       California"
  echo "           --org         Kaazing"
  echo "           --org-unit    \"Kaazing Demo Certificate Authority\""
  echo "           --common-name \"Kaazing Demo Root CA\""
  echo ""
  echo "Example: entrypoint.sh"
  echo "           --command     create-cert"
  echo "           --ca-key      ca.key.perm"
  echo "           --ca-cert     ca.cert.perm"
  echo "           --ca-password capass"
  echo "           --key         gateway.example.com.key.pem"
  echo "           --cert        gateway.example.com.cert.pem"
  echo "           --days        7"
  echo "           --country     US"
  echo "           --state       California"
  echo "           --org         Kaazing"
  echo "           --org-unit    \"Kaazing Demo\""
  echo "           --common-name \"*.gateway.example.com\""
  echo "           --alt-names   \"DNS:gateway.example.com,DNS:*.gateway.example.com\""
  echo "           --overwrite    true"
}

# Check if a variable is present, and error if it is not.
# $1 is the variable containing the argument ${CA_KEY_NAME}
# $2 is the argument name. e.g. --ca-key
function check_mandatory_arg
{
  if [ -z "${1}" ]
  then
    echo ""
    echo "Missing argument: ${2}"
    usage
    exit 1
  fi
}

function process_args
{
  # Get the number of arguments passed to this script.
  # (The BASH_ARGV array does not include $0.)
  # (The BASH_ARGV arrary is reversed, with the last argument in first position.)
  local n=${#BASH_ARGV[@]}

  if (( $n > 0 ))
  then
      # Get the last index of the args in BASH_ARGV.
      local n_index=$(( $n - 1 ))

      # Loop through the indexes from largest to smallest.
      for i in $(seq ${n_index} -2 0)
      do
        PARAM=${BASH_ARGV[$i]}
        VALUE=${BASH_ARGV[$i-1]}

        case ${PARAM} in
            -h | --help)
                usage
                exit
                ;;
            --command)
                COMMAND=${VALUE}
                ;;
            --output-dir)
                OUTPUT_DIR=${VALUE}
                ;;
            --ca-key)
                CA_KEY_NAME=${VALUE}
                ;;
            --ca-cert)
                CA_CERT_NAME=${VALUE}
                ;;
            --ca-password)
                CA_PASSWORD=${VALUE}
                ;;
            --key)
                KEY_NAME=${VALUE}
                ;;
            --cert)
                CERT_NAME=${VALUE}
                ;;
            --days)
                DAYS=${VALUE}
                ;;
            --country)
                C=${VALUE}
                ;;
            --state)
                ST=${VALUE}
                ;;
            --org)
                O=${VALUE}
                ;;
            --org-unit)
                OU=${VALUE}
                ;;
            --common-name)
                CN=${VALUE}
                ;;
            --alt-names)
                SAN=${VALUE}
                ;;
            --overwrite)
                OVERWRITE=${VALUE}
                ;;
            *)
                echo "ERROR: unknown parameter \"${PARAM}\""
                usage
                exit 1
                ;;
        esac

      done

  fi

  if [ "${COMMAND}" != "create-ca" ] && [ "${COMMAND}" != "create-cert" ]
  then
    echo ""
    echo "Invalid or missing command. Must be one of: create-ca|create-cert"
    usage
    exit 1
  fi

  check_mandatory_arg "${CA_KEY_NAME}" "--ca-key"
  check_mandatory_arg "${CA_CERT_NAME}" "--ca-cert"
  check_mandatory_arg "${CA_PASSWORD}" "--ca-password"
  check_mandatory_arg "${DAYS}" "--days"
  check_mandatory_arg "${C}" "--country"
  check_mandatory_arg "${ST}" "--state"
  check_mandatory_arg "${O}" "--org"
  check_mandatory_arg "${OU}" "--org-unit"
  check_mandatory_arg "${CN}" "--common-name"

  if [ "${COMMAND}" == "create-cert" ]
  then
    check_mandatory_arg "${KEY_NAME}" "--key"
    check_mandatory_arg "${CERT_NAME}" "--cert"
    check_mandatory_arg "${SAN}" "--alt-names"
  fi
}

function print_settings()
{
  echo -e "  Command:      ${COMMAND}"
  echo -e "  Output dir:   ${OUTPUT_DIR}"
  echo -e "  CA key:       ${CA_KEY}\t[Password: ${CA_PASSWORD}]"
  echo -e "  CA cert:      ${CA_CERT}\t[Valid for: ${DAYS} days]"
  if [ "${COMMAND}" == "create-cert" ]
  then
    echo -e "  Server key:   ${KEY}\t[TODO]"
    echo -e "  Server cert:  ${CERT}\t[Valid for: ${DAYS} days]"
  fi
  echo -e "  Subject:      C=${C}"
  echo -e "                ST=${ST}"
  echo -e "                O=${O}"
  echo -e "                OU=${OU}"
  echo -e "                CN=${CN}"
  echo -e "  Alt name(s):  ${SAN}"
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

# Check if a file exists, and determine whether we shoudl proceed or not.
# $1 is the the file to check. e.g. private/ca.key.pem
function check_if_file_exists()
{
  if [ -f ${1} ]
  then
    echo ""
    echo -n "${1} already exists. "
    if [ "${OVERWRITE}" == "true" ]
    then
      echo "It will be re-created because \"--overwrite\" is set to true. Just thought you should know."
    else
      echo "Stopping. Set \"--overwrite\" to \"true\" to continue when files exist. See usage with \"--help\""
      exit 1
    fi
  fi
}

function create_ca()
{

  echo ""
  echo "Let's make a CA!"

  echo ""
  echo "Settings:"
  print_settings

  check_if_file_exists ${CA_KEY}
  check_if_file_exists ${CA_CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the CA keypair: ${CA_KEY}"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -aes256 -passout pass:${CA_PASSWORD} -out ${CA_KEY} 4096

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the CA certificate: ${CA_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl req -config /openssl.cnf \
        -key ${CA_KEY} -passin pass:${CA_PASSWORD} \
        -new -x509 -days ${DAYS} -sha256 -extensions v3_ca \
        -subj "/C=${C}/ST=${ST}/O=${O}/OU=${OU}/CN=${CN}" \
        -out ${CA_CERT}

  print_cert ${CA_CERT}

  echo ""
  echo "Summary:"
  print_settings
}

function create_cert()
{

  echo ""
  echo "Let's make a cert!"

  KEY=private/${KEY_NAME}
  CERT=certs/${CERT_NAME}

  echo ""
  echo "Settings:"
  print_settings

  # TODO: Check that CA files exist

  check_if_file_exists ${KEY}
  check_if_file_exists ${CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the server keypair: ${KEY}"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -out ${KEY} 2048

  echo ""
  echo "Summary:"
  print_settings

  exit 0

  CSR=_work/csr/

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the server certificate signing request: _work/csr/gateway.example.com.csr.pem"
  echo "------------------------------------------------------------------------------"
  # Note: subjectAltName is set automatically using ${SAN}. See env var. in openssl.cfg file.
  openssl req -config /openssl.cnf \
        -key private/gateway.example.com.key.pem \
        -new -sha256 -out _work/csr/gateway.example.com.csr.pem \
        -subj "/C=${C}/ST=${ST}/O=${O}/OU=${OU}/CN=${CN}"

  rm -rf certs/gateway.example.com.cert.pem
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing the csr with the ca: certs/gateway.example.com.cert.pem"
  echo "------------------------------------------------------------------------------"
  openssl ca -config /openssl.cnf -passin pass:${CA_PASSWORD} -batch \
        -extensions server_cert -days ${DAYS} -notext -md sha256 \
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
}

function main()
{
  echo ""
  echo "Everything will be logged to: ${LOG_FILE}"

  process_args

  mkdir -p ${OUTPUT_DIR}
  cd ${OUTPUT_DIR}

  mkdir -p certs private _work/csr _work/newcerts

  # Clean up in case files are there from a previous run.
  rm -rf _work/index.txt _work/serial
  touch _work/index.txt
  echo 1000 > _work/serial

  CA_KEY=private/${CA_KEY_NAME}
  CA_CERT=certs/${CA_CERT_NAME}

  case ${COMMAND} in
    create-ca)
        create_ca
        ;;
    create-cert)
        create_cert
        ;;
  esac

  echo ""
  echo "Done."

}

mkdir -p ${LOG_DIR}
main 2>&1 | tee -a ${LOG_FILE}
