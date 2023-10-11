#!/usr/bin/env bash


ssm_available() {
  if [ -z ${SSM_SERVICE} ] || [ -f ${SSM_ENV} ]  ; then
    return 1
  fi

  return 0
}

get_ssm_params() {
  aws ssm get-parameters-by-path --region $AWS_REGION --path ${SSM_ENV}/${SSM_SERVICE} --with-decryption --query Parameters | sed 's,'"$SSM_ENV\/$SSM_SERVICE/"',,' | \
  jq -r 'map("\(.Name | sub("'${SSM_ENV}/${SSM_SERVICE}'";""))=\(.Value)")| join("\n")'
}

export_ssm_parameters() {
IFS=$(echo -en "\n\b")
  for parameter in `get_ssm_params`; do
    if [ "$APPN" == "identity-app" ]; then
      parameter=$(echo "$parameter" | sed 's/\\n/\n/g; s/\\r/\r/g')
      echo $parameter >> .env
    elif [ "$APPN" == "core-app" ]; then
      parameter=$(echo "$parameter" | sed 's/\\n/\n/g; s/\\r/\r/g')
      echo $parameter >> .env
      export $parameter
    else
      parameter=$(echo "$parameter" | sed 's/\\n/\n/g; s/\\r/\r/g')
      echo "Info: Exporting parameter ${parameter%%=*}"
      export $parameter
    fi
  done
  exec "$@"
}

main() {
  if ssm_available; then
    export_ssm_parameters "$@"
  fi

  exec "$@"
}

main "$@"
