#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

WORKSPACE_NAME=
REGION=
IMPORT_ADDR=
IMPORT_ID=
ACCOUNT_LEVEL=
PLAN=

SAVED="$@"
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--region)
      REGION="$2"
      shift # past argument
      shift # past value
      ;;
    -al|--account-level)
      ACCOUNT_LEVEL="true"
      shift # past argument
      ;;
    -plan|--plan)
      PLAN=true
      shift # past argument
      ;;
    -import)
      IMPORT_ADDR="$2"
      shift # past argument
      IMPORT_ID="$2"
      shift # past value
      shift # past value
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

ACCOUNT_NAME="$(grep databricks_account_name secrets.tfvars | cut -d'=' -f2 | tr -d '"')---account---level"

if [[ -z "$IMPORT_ADDR" || ( -n "$ACCOUNT_LEVEL" && "$ACCOUNT_LEVEL" = "true" )]]; then
  $DIR/configure_tf_workspace.sh $ACCOUNT_NAME
  CONFIGURE=($DIR/provision/configure.sh --account-level -dir "$DIR/provision/log-delivery/" -vf secrets.tfvars) # initial command
  CONFIGURE+=( -w $ACCOUNT_NAME)
  if [ -n "$REGION" ]; then
    CONFIGURE+=( -r $REGION)
  fi
  if [ -n "$IMPORT_ADDR" ]; then
    CONFIGURE+=( -import "$IMPORT_ADDR" "$IMPORT_ID")
  fi
  if [ -n "$PLAN" ]; then
    CONFIGURE+=( -plan)
  fi

  "${CONFIGURE[@]}"
fi

if [[ -z "$IMPORT_ADDR" || ( -z "$ACCOUNT_LEVEL" || "$ACCOUNT_LEVEL" != "true" ) ]]; then
  $DIR/configure_tf_workspace.sh $WORKSPACE_NAME
  CONFIGURE=($DIR/provision/configure.sh -vf secrets.tfvars) # initial command
  CONFIGURE+=( ${SAVED} )
  "${CONFIGURE[@]}"
fi
