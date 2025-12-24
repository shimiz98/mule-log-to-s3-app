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
    funcRevokeAccessToken
}

funcParseCommandLine() {
    if [ $# -ne 6 ]; then
        printf '[ERROR] 引数の個数が不正です: 期待値=6 実際=%s\n' $#
        exit 1
    fi
    gOrgId=$1
    gEnvId=$2
    gAssetGroupId=$3
    [ "$gAssetGroupId" = "" ] && gAssetGroupId="$gOrgId"
    gAssetId=$4
    gAssetVersion=$5
    gAppTemplateFile=$6
}

funcCreateLogDir() {
    gLogDir="./${gLogDirPrefix}$(date +%Y%m%d-%H%M%S)"
    gLogFileNum=0
    mkdir "$gLogDir"
}

funcDeploy() {
    local appName
    appName=$(jq --raw-output '.name' "$gDeployConfigFile")

    gLogFileNum=$(( gLogFileNum + 1 ))
    local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
    local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
    curl "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${gOrgId}/environments/${gEnvId}/deployments" \
        -H "Authorization: Bearer ${gAccessToken}" \
        --fail-with-body \
        --dump-header "$responseHeaderFile" \
        --output "$responseBodyFile" \
        && true
    local rc=$?

    funcPrintHttpResponse "$rc" "$responseHeaderFile" "$responseBodyFile"
    if [ "$rc" -ne 0 ]; then
        exit "$rc"
    fi
    deploymentId=$(jq --arg x "$appName" --raw-output '.items[] | select(.name == $ARGS.named["x"]) | .id' "$responseBodyFile")

    if [ "$deploymentId" = "" ]; then
        gLogFileNum=$(( gLogFileNum + 1 ))
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

        funcPrintHttpResponse "$rc" "$responseHeaderFile" "$responseBodyFile"
        if [ "$rc" -ne 0 ]; then
            exit "$rc"
        fi
    else
        gLogFileNum=$(( gLogFileNum + 1 ))
        local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
        local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
        curl "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${gOrgId}/environments/${gEnvId}/deployments/${deploymentId}" \
            -H "Authorization: Bearer ${gAccessToken}" \
            --fail-with-body \
            --dump-header "$responseHeaderFile" \
            --output "$responseBodyFile" \
            && true
        local rc=$?

        funcPrintHttpResponse "$rc" "$responseHeaderFile" "$responseBodyFile"
        if [ "$rc" -ne 0 ]; then
            exit "$rc"
        fi
        local beforeDeployStatusFile=$responseBodyFile

        gLogFileNum=$(( gLogFileNum + 1 ))
        local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
        local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
        curl "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${gOrgId}/environments/${gEnvId}/deployments/${deploymentId}" \
            -H "Authorization: Bearer ${gAccessToken}" \
            -X PATCH \
            -H 'Content-Type: application/json' \
            --data "@${gDeployConfigFile}" \
            --fail-with-body \
            --dump-header "$responseHeaderFile" \
            --output "$responseBodyFile" \
            && true
        local rc=$?

        funcPrintHttpResponse "$rc" "$responseHeaderFile" "$responseBodyFile"
        if [ "$rc" -ne 0 ]; then
            exit "$rc"
        fi
        local afterDeployStatusFile=$responseBodyFile

        diff <(jq . "$beforeDeployStatusFile") <(jq . "$afterDeployStatusFile") && true
        rc=$?
        if [ "$rc" -ne 0 ] && [ "$rc" -ne 1 ]; then
            exit "$rc"
        fi
    fi 
}

funcCreateDeployConfigFile() {
    gDeployConfigFile=${gLogDir}/mule-app-deploy.json
    jq \
        --arg groupId "$gAssetGroupId" \
        --arg artifactId "$gAssetId" \
        --arg version "$gAssetVersion" \
        '.application.ref.groupId=$groupId | .application.ref.artifactId=$artifactId | .application.ref.version=$version' "$gAppTemplateFile" > "$gDeployConfigFile"
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
    gLogFileNum=$(( gLogFileNum + 1 ))
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

    funcPrintHttpResponse "$rc" "$responseHeaderFile" "$responseBodyFile" skipBodyOnSuccess
    if [ "$rc" -ne 0 ]; then
        exit "$rc"
    fi
    gAccessToken=$(jq --raw-output '.access_token' "$responseBodyFile")
}

funcCheckAccessToken() {
    gLogFileNum=$(( gLogFileNum + 1 ))
    local responseHeaderFile=${gLogDir}/${gLogFileNum}_response-header.txt
    local responseBodyFile=${gLogDir}/${gLogFileNum}_response-body.json
    curl https://anypoint.mulesoft.com/accounts/api/me \
        -H "Authorization: Bearer ${gAccessToken}" \
        --fail-with-body \
        --dump-header "$responseHeaderFile" \
        --output "$responseBodyFile" \
        && true
    local rc=$?

    funcPrintHttpResponse "$rc" "$responseHeaderFile" "$responseBodyFile"
    if [ "$rc" -ne 0 ]; then
        exit "$rc"
    fi
}

funcRevokeAccessToken () {
    if [ -v gDoNotRevokeAccessToken ]; then
        printf '[INFO] funcRevokeAccessToken: skip'
        return
    fi

    gLogFileNum=$(( gLogFileNum + 1 ))
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

    funcPrintHttpResponse "$rc" "$responseHeaderFile" "$responseBodyFile"
    if [ "$rc" -ne 0 ]; then
        exit "$rc"
    fi
}

funcPrintHttpResponse() {
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
    fi
}

funcMain "$@"
