#!/bin/bash

OUTPUT_DIR=/x509

CMD_NAME=$(basename $0)

# Save the args, minus the command.
ARGS=("$@")

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
  echo "usage: ${CMD_NAME} SCENARIO [<options>]"

  echo ""
  echo "where SCENARIO=server..."
  ./create-certs-server.sh --help

  echo ""
  echo "where SCENARIO=enterprise-shield..."
  ./create-certs-enterprise-shield.sh --help
}

function process_args
{
  local n=${#ARGS[@]}

  if (( ${n} > 0 ))
  then

    PARAM=${ARGS[$((0))]}

    case ${PARAM} in
      -h | --help)
        usage
        exit 0
        ;;
      server | es)
        COMMAND=${PARAM}
        ;;
      *)
        echo ""
        echo "ERROR: unknown scenario \"${PARAM}\""
        usage
        exit 1
        ;;
    esac

  else

    usage
    exit 0

  fi
}

function main()
{
  process_args

  echo ""
  echo "Everything will be logged to: ${LOG_FILE}"

  # Remove the first item from the args list, which is the command.
  unset 'ARGS[0]'

  case ${COMMAND} in
    server)
      ./create-certs-server.sh "${ARGS[@]}"
      ;;
    es)
      ./create-certs-enterprise-shield.sh "${ARGS[@]}"
      ;;
  esac
}

mkdir -p ${LOG_DIR}
main 2>&1 | tee -a ${LOG_FILE}
