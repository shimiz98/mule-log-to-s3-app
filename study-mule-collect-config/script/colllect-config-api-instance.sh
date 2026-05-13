#!/bin/bash
set -Ceuo pipefail

funcMain() {
    # TODO: コマンドライン引数と環境変数で指定するように書き換える。
    gOrgId=18db15cf-f32f-493b-a481-d62e685c174f
    gEnvId=8e0caa2a-0a29-423e-a4d1-f7435e6f799f
    gCurlOpts=()

    source "$(dirname "$0")/common-funcs.sh"
    funcCreateLogDir "$(basename "$0" .sh)"
    gOutputBaseDir="${gLogDir}/output"
    mkdir -p "$gOutputBaseDir"
    funcGetAccessToken

    funcGetApiInstanceList
    while IFS=$'\t' read -r apiInstanceId apiAssetId apiProductVersion; do
        echo "API Instance: ${apiAssetId} (${apiInstanceId})"
        funcGetApiInstanceDetail "$apiInstanceId" "$apiAssetId" "$apiProductVersion"
        funcGetApiPolicyList "$apiInstanceId" "$apiAssetId" "$apiProductVersion"
        while IFS=$'\t' read -r policyOrder policyId policyGroupId policyAssetId policyAssetVersion; do
            echo "  API Policy: ${policyAssetId} (${policyId})"
            funcGetApiPolicyDetail "$apiInstanceId" "$policyId" "$retApiInstanceOutputDir" "$policyAssetId"
        done < "$retApiPolicyListFile"
        rm "$retApiPolicyListFile"
        unset retApiPolicyListFile
    done < "$retApiInstanceListFile"
}

funcGetApiInstanceList() {
    local logNum=$((gLogNum++))
    local responseBodyFile="${gLogDir}/${logNum}_response-body.json"
    # https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236239/
    curl "https://anypoint.mulesoft.com/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis" \
        -H "Authorization: Bearer ${gAnypointAccessToken}"\
        -o "$responseBodyFile"

    retApiInstanceListFile="${gLogDir}/${logNum}_api-instance-list.tsv"
    jq -r '.assets[].apis[] | [.id, .assetId, .productVersion] | @tsv' "$responseBodyFile" | tr -d '\r' > "$retApiInstanceListFile"

    jq '.' "$responseBodyFile" | tr -d '\r' > "${gOutputBaseDir}/api-instance-list.json"
}

funcGetApiInstanceDetail() {
    local apiInstanceId="$1"
    local apiAssetId="$2"
    local apiProductVersion="$3"

    local logNum=$((gLogNum++))
    local responseBodyFile="${gLogDir}/${logNum}_response-body.json"
    # https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236312/
    curl "https://anypoint.mulesoft.com/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis/${apiInstanceId}" \
        -H "Authorization: Bearer ${gAnypointAccessToken}"\
        -o "$responseBodyFile"

    outputDir="${gOutputBaseDir}/${apiAssetId}_${apiProductVersion}"
    # 1つのAssetIDに対して、複数のAPI Instanceが存在する場合にディレクトリ名の重複を回避する
    if [ -d "$outputDir" ]; then
        outputDir="${outputDir}_${apiInstanceId}"
    fi
    mkdir -p "$outputDir"
    jq '.' "$responseBodyFile" | tr -d '\r' > "${outputDir}/api-instance-detail.json"
    # 一時的にグローバル変数に代入して、戻り値として返却する
    retApiInstanceOutputDir="$outputDir"
}

funcGetApiPolicyList() {
    local apiInstanceId="$1"

    local logNum=$((gLogNum++))
    local responseBodyFile="${gLogDir}/${logNum}_response-body.json"
    # https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236419/
    curl "https://anypoint.mulesoft.com/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis/${apiInstanceId}/policies" \
        -H "Authorization: Bearer ${gAnypointAccessToken}"\
        -o "$responseBodyFile"

    retApiPolicyListFile="${gLogDir}/${logNum}_api-policy-list.tsv"
    jq -r '.policies[] | [.order, .policyId, .template.groupId, .template.assetId, .template.assetVersion] | @tsv' "$responseBodyFile" | tr -d '\r' > "$retApiPolicyListFile"
}

funcGetApiPolicyDetail() {
    local apiInstanceId="$1"
    local policyId="$2"
    local apiInstanceOutputDir="$3"
    local policyAssetId="$4"

    local logNum=$((gLogNum++))
    local responseBodyFile="${gLogDir}/${logNum}_response-body.json"
    # https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236470/
    curl "https://anypoint.mulesoft.com/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis/${apiInstanceId}/policies/${policyId}" \
        -H "Authorization: Bearer ${gAnypointAccessToken}"\
        -o "$responseBodyFile"

    jq '.' "$responseBodyFile" | tr -d '\r' > "${apiInstanceOutputDir}/api-policy-detail_${policyAssetId}.json"
}

funcMain "$@"
