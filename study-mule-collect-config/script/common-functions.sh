#!/bin/bash
funcGetAccessToken() {
    local logNum=$((gLogNum++))
    local responseBodyFile="${gLogDir}/${logNum}_response-body.json"
    # https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/access-management-api/minor/1.0/console/method/%2314086/
    curl -s -X POST "https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token" \
        "${gCurlOpts[@]}" \
        -o "$responseBodyFile" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data "client_id=${ANYPOINT_CLIENT_ID}" \
        --data "client_secret=${ANYPOINT_CLIENT_SECRET}" \
        --data "grant_type=client_credentials"
    gAnypointAccessToken=$(jq -r '.access_token' "$responseBodyFile")
    ## rm -f "$responseBodyFile"
}

funcCreateLogDir() {
    local logDirSuffix="${1:-}"
    gLogDir="$(dirname "$0")/../log/$(date +%Y%m%d-%H%M%S)_${logDirSuffix}"
    gLogNum=1
    mkdir -p "$gLogDir"
    gLogDir=$(realpath "$gLogDir")
}
