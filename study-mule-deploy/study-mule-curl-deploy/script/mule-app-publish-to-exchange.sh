#!/bin/bash
# MuleアプリケーションをExchangeへPublishするスクリプト
# 引数
#   orgId
#   assetId
#   asserVersion
#   asserFile
# 環境変数
#   ANYPOINT_CONN_APP_ID
#   ANYPOINT_CONN_APP_SECRET
set -Ceuo pipefail

funcMain() {
    funcParseCommandLine "$@"
    funcGetAccessToken
    funcPublish
    funcRevokeAccessToken
}

funcParseCommandLine() {
    if [ $# -ne 4 ]; then
        printf '[ERROR] 引数の個数が不正です: 期待値=4 実際=%s\n' $#
        exit 1
    fi
    gOrgId=$1
    gAssetId=$2
    gAssetVersion=$1
    gAssetFile=$2
}

funcPublish() {
    local groupId=$gOrgId
    local responseHeaderFile=./ayaya-response-header.txt
    local responseBodyFile=./ayaya-response-body.json
    local assetClassifier=mule-application
    local assetPackaging=jar
    curl "https://anypoint.mulesoft.com/exchange/api/v2/organizations/${gOrgId}/assets/${groupId}/${gAssetId}/${gAssetVersion}" \
        -H "Authorization: Bearer ${gAccessToken}" \
        -H "x-sync-publication: true" \
        -F "name=${gAssetId}" \
        -F "files.${assetClassifier}.${assetPackaging}=@${gAssetFile}" \
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

# 
# 以下は、共通的な処理
#

funcGetAccessToken() {
    if [ -v gAccessToken ]; then
        printf '[INFO] funcGetAccessToken: skip'
        gDoNotRevokeAccessToken=""
        return
    fi
    local responseHeaderFile=./ayaya-response-header.txt
    local responseBodyFile=./ayaya-response-body.json

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

funcRevokeAccessToken () {
    if [ -v gDoNotRevokeAccessToken ]; then
        printf '[INFO] funcRevokeAccessToken: skip'
        return
    fi
    local responseHeaderFile=./ayaya-response-header.txt
    local responseBodyFile=./ayaya-response-body.json
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
        printf '[INFO] curl rc=%s\n' "%rc"
    else
        printf '[ERROR] curl rc=%s\n' "%rc"
    fi
}

funcMain "$@"
