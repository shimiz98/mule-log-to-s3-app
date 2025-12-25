#!/bin/bash
# MuleアプリケーションをCloudHub2へDeployするスクリプト
# 引数
#   orgId
#   envId
#   assetGroupId
#   assetId
#   asserVersion
#   configFile
# 環境変数
#   ANYPOINT_CONN_APP_ID
#   ANYPOINT_CONN_APP_SECRET
set -Ceuo pipefail

funcMain() {
    readonly gLogDirPrefix=''
    funcParseCommandLine "$@"
    funcCreateLogDir
    funcCreateDeployConfigFile
    funcGetAccessToken
    funcDeploy
    funcWaitDeployComplete
    funcRevokeAccessToken
}

funcParseCommandLine() {
    if [ $# -ne 6 ]; then
        printf '[ERROR] 引数の個数が不正です: 期待値=6 実際=%s\n' $#
        exit 1
    fi
    gOrgId=$1
    gEnvId=$2
    gAssetGroupId=${3:-$gOrgId} # 空欄の場合はOrgIdと同じ値を使う
    gAssetId=$4
    gAssetVersion=$5
    gAppTemplateFile=$6
}

funcCreateLogDir() {
    gLogDir="./${gLogDirPrefix}$(date +%Y%m%d-%H%M%S)"
    gLogFileNum=00
    mkdir "$gLogDir"
}

funcCreateDeployConfigFile() {
    gDeployConfigFile=${gLogDir}/mule-app-deploy.json
    jq \
        --arg groupId "$gAssetGroupId" \
        --arg artifactId "$gAssetId" \
        --arg version "$gAssetVersion" \
        '.application.ref.groupId=$groupId | .application.ref.artifactId=$artifactId | .application.ref.version=$version' "$gAppTemplateFile" > "$gDeployConfigFile"
}

funcDeploy() {
    local appName
    appName=$(jq --raw-output '.name' "$gDeployConfigFile")

    gLogFileNum=$(printf '%02d' $(( (10#$gLogFileNum) + 1 )) )
    local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
    local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
    curl "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${gOrgId}/environments/${gEnvId}/deployments" \
        -H "Authorization: Bearer ${gAccessToken}" \
        --fail-with-body \
        --dump-header "$responseHeaderFile" \
        --output "$responseBodyFile" \
        && true
    local rc=$?

    funcCheckCurlResult "$rc" "$responseHeaderFile" "$responseBodyFile"
    gDeploymentId=$(jq --arg x "$appName" --raw-output '.items[] | select(.name == $ARGS.named["x"]) | .id' "$responseBodyFile")

    if [ "$gDeploymentId" = "" ]; then
        gLogFileNum=$(printf '%02d' $(( (10#$gLogFileNum) + 1 )) )
        local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
        local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
        curl "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${gOrgId}/environments/${gEnvId}/deployments" \
            -H "Authorization: Bearer ${gAccessToken}" \
            -H 'Content-Type: application/json' \
            --data "@${gDeployConfigFile}" \
            --fail-with-body \
            --dump-header "$responseHeaderFile" \
            --output "$responseBodyFile" \
            && true
        local rc=$?

        funcCheckCurlResult "$rc" "$responseHeaderFile" "$responseBodyFile"

        gDeploymentId=$(jq '.id' "$responseBodyFile")

    else
        gLogFileNum=$(printf '%02d' $(( (10#$gLogFileNum) + 1 )) )
        local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
        local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
        curl "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${gOrgId}/environments/${gEnvId}/deployments/${gDeploymentId}" \
            -H "Authorization: Bearer ${gAccessToken}" \
            --fail-with-body \
            --dump-header "$responseHeaderFile" \
            --output "$responseBodyFile" \
            && true
        local rc=$?

        funcCheckCurlResult "$rc" "$responseHeaderFile" "$responseBodyFile"
        local beforeDeployStatusFile=$responseBodyFile

        gLogFileNum=$(printf '%02d' $(( (10#$gLogFileNum) + 1 )) )
        local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
        local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
        curl "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${gOrgId}/environments/${gEnvId}/deployments/${gDeploymentId}" \
            -H "Authorization: Bearer ${gAccessToken}" \
            -X PATCH \
            -H 'Content-Type: application/json' \
            --data "@${gDeployConfigFile}" \
            --fail-with-body \
            --dump-header "$responseHeaderFile" \
            --output "$responseBodyFile" \
            && true
        local rc=$?

        funcCheckCurlResult "$rc" "$responseHeaderFile" "$responseBodyFile"
        local afterDeployStatusFile=$responseBodyFile

        diff <(jq . "$beforeDeployStatusFile") <(jq . "$afterDeployStatusFile") > "${gLogDir}/mule-app-detail.diff" && true
        rc=$?
        if [ "$rc" -ne 0 ] && [ "$rc" -ne 1 ]; then
            exit "$rc"
        fi
    fi

}

funcWaitDeployComplete() {
    local -r statusCheckInterval=3
    local -r statusCheckMax=40
    for (( i=1; i < statusCheckMax; i++ )); do
        gLogFileNum=$(printf '%02d' $(( (10#$gLogFileNum) + 1 )) )
        local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
        local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
        curl "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${gOrgId}/environments/${gEnvId}/deployments/${gDeploymentId}" \
            -H "Authorization: Bearer ${gAccessToken}" \
            --fail-with-body \
            --dump-header "$responseHeaderFile" \
            --output "$responseBodyFile" \
            && true
        local rc=$?
        funcCheckCurlResult "$rc" "$responseHeaderFile" "$responseBodyFile"

        local status1 status2
        status1=$(jq --raw-output .status "$responseBodyFile")
        status2=$(jq --raw-output .application.status "$responseBodyFile")
        printf '[INFO] %s %s\n' "$status1" "$status2"
        echo "$(date '+%Y%m%d %H%M%S')" "$status1" "$status2" >> "${gLogDir}/mule-app-status.txt"
        if [ "$status1" = 'APPLIED' ] && [ "$status2" = 'RUNNING' ]; then
            printf '[INFO] デプロイ後の起動が完了しました。\n'
            break
        fi
        sleep "$statusCheckInterval"
    done
}

# 
# 以下は、共通的な処理
#

funcGetAccessToken() {
    if [ -v gAccessToken ]; then
        printf '[INFO] funcGetAccessToken: skip'
        gDoNotRevokeAccessToken=""
        return
    fi
    gLogFileNum=$(printf '%02d' $(( (10#$gLogFileNum) + 1 )) )
    local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
    local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json

    # https://help.salesforce.com/s/articleView?id=001117108&type=1
    # https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/access-management-api/minor/1.0/pages/Connected%20App%20Examples/
    curl https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token \
        --data-urlencode "client_id=${ANYPOINT_CONN_APP_ID}" \
        --data-urlencode "client_secret=${ANYPOINT_CONN_APP_SECRET}" \
        --data-urlencode grant_type=client_credentials \
        --fail-with-body \
        --dump-header "$responseHeaderFile" \
        --output "$responseBodyFile" \
        && true
    local rc=$?

    funcCheckCurlResult "$rc" "$responseHeaderFile" "$responseBodyFile" skipBodyOnSuccess
    gAccessToken=$(jq --raw-output '.access_token' "$responseBodyFile")
}

funcCheckAccessToken() {
    gLogFileNum=$(printf '%02d' $(( (10#$gLogFileNum) + 1 )) )
    local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
    local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
    curl https://anypoint.mulesoft.com/accounts/api/me \
        -H "Authorization: Bearer ${gAccessToken}" \
        --fail-with-body \
        --dump-header "$responseHeaderFile" \
        --output "$responseBodyFile" \
        && true
    local rc=$?

    funcCheckCurlResult "$rc" "$responseHeaderFile" "$responseBodyFile"
}

funcRevokeAccessToken () {
    if [ -v gDoNotRevokeAccessToken ]; then
        printf '[INFO] funcRevokeAccessToken: skip'
        return
    fi

    gLogFileNum=$(printf '%02d' $(( (10#$gLogFileNum) + 1 )) )
    local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
    local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
    curl https://anypoint.mulesoft.com/accounts/api/v2/oauth2/revoke \
        --data-urlencode "token=${gAccessToken}" \
        --data-urlencode "token_type_hint=access_token" \
        --fail-with-body \
        --dump-header "$responseHeaderFile" \
        --output "$responseBodyFile" \
        && true
    local rc=$?

    funcCheckCurlResult "$rc" "$responseHeaderFile" "$responseBodyFile"
}

funcCheckCurlResult() {
    local rc=$1
    local headerFile=$2
    local bodyFile=$3
    if [ $# -eq 4 ]; then
        local skipBodyOnSuccess=""
    fi
    if [ "$rc" -eq 0 ]; then
        printf '[INFO] HTTPステータス\n'
        head -n1 "$headerFile" # 正常終了の場合は、簡潔に出力
    else
        printf '[INFO] HTTPレスポンスヘッダー\n'
        cat "$headerFile" # 異常終了の場合は、冗長に出力
    fi
    if [ -v skipBodyOnSuccess ]; then
        printf '[INFO] HTTPレスポンスボディは出力省略\n'
    else
        printf '[INFO] HTTPレスポンスボディ\n'
        cat "$bodyFile"
        printf '\n'
    fi

    if [ "$rc" -eq 0 ]; then
        printf '[INFO] curl rc=%s\n' "$rc"
    else
        printf '[ERROR] curl rc=%s\n' "$rc"
        exit "$rc"
    fi
}

funcMain "$@"
