#!/usr/bin/env bash
set -Ceuo pipefail

funcMain() {
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$script_dir/common-function.sh"

  funcParseArgs "$@"
  funcCreateLogDir
  funcGetAnypointAccessToken
  funcGetOrgIdAndName "$gOrgIdOrName"
  funcGetEnvIdAndName "$gEnvIdOrName"

  funcParseArgs "$@"
  funcCheckInputFile
  funcGetApiInstanceList 'before-deploy'
  funcGetApiPolicyList 'before-deploy'
  funcCheckAnypointPlatform
  funcSortConfigFileList 'before-deploy'
  funcGetApiInstanceIdList 'before-deploy'
  funcGetApiPolicyIdList 'before-deploy'
  local deployStatus=0
  local tmpFile
  tmpFile=$(mktemp)
  local indexNumber
  for indexNumber in "${!gConfigFileList[@]}"; do
    echo "Info deploying API policy for config: ${gConfigFileList[indexNumber]} instanceId=${gApiInstanceIdList[indexNumber]}" policyId="${gApiPolicyIdList[indexNumber]}" >&2
    if [ "$gDryRun" -eq 1 ]; then
      echo "Dry run mode: Skipping deployment for config: ${gConfigFileList[$indexNumber]}" >&2
      rc=0
    else
      # MEMO: 何かエラーが発生しても処理を継続するために、丸括弧で括ってサブシェルの中で実行する。    
      (funcDeployApiPolicy "${gConfigFileList[indexNumber]}" "${gApiInstanceIdList[indexNumber]}" "${gApiPolicyIdList[indexNumber]}") 3>| "$tmpFile" && true
      # WARN: ここにコマンドを書くと、ステータス「$?」が上書きされてしまうので、何か処理を追加する際は「rc=$?」の後に追加すること。
      rc=$?
    fi
    if [ $rc -ne 0 ]; then
      echo "Error deploying API policy for config: ${gConfigFileList[indexNumber]}" >&2
      deployStatus=$rc
      break
    fi
    echo "Deployed API policy ID: $(cat "$tmpFile")" >&2
  done
  funcGetApiInstanceList 'after-deploy'
  funcGetApiPolicyIdList 'after-deploy'
  funcDiffBeforeAfter
  exit "$deployStatus"
}

funcParseArgs() {
  gDryRun=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --org) gOrgIdOrName="$2"; shift 2 ;;
      --env) gEnvIdOrName="$2"; shift 2 ;;
      --dry-run) gDryRun=1; shift ;;
      --) shift; break ;;
      -*) echo "error: unknown option: $1" >&2; exit 1 ;;
      *) break ;;
    esac
  done
  if [ ! -v gOrgIdOrName ]; then
    echo "error: コマンドライン引数 --org が不足しています" >&2
    exit 1
  fi
  if [ ! -v gEnvIdOrName ]; then
    echo "error: コマンドライン引数 --env が不足しています" >&2
    exit 1
  fi
  gConfigFileList=("$@")
}

funcCheckInputFile() {
  : # TODO: 入力ファイルの存在チェックや、JSON形式のチェックを追加する
}

funcCheckAnypointPlatform() {
  : # TODO: Anypoint Platformのクラウドから取得したデータと、入力ファイルとの相関チェックを追加する
}

funcGetApiInstanceList() {
  local dirName="$1"
  mkdir -p "$gLogDir/$dirName"
  local outputFile="$gLogDir/$dirName/api-instance-list.json"
  # WARN: 100件以上のAPIインスタンスが存在する場合、全件取得できない。そんなに多く作らないので、本ツールでは何も対処しないこととする。
  # 呼び出すAPI: APIインスタンスの一覧を取得するAPI
  # API仕様のURL: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236239/
  local url="${gAnypointBaseUrl}/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis?limit=100"
  funcCurl -- \
    --header "Authorization: Bearer $gAnypointAccessToken" \
    "$url"
  cp -p  "$gLogDir/${gLogSeq}_curl-res-body.json" "$outputFile"
}

funcGetApiPolicyList() {
  local dirName="$1"
  local apiInstanceAssetIdAndVersion="$2"
  local apiInstanceId="$3"
  local outputFile="$gLogDir/$dirName/api-policy-list_${apiInstanceAssetIdAndVersion}.json"
  # 呼び出すAPI: APIポリシーの一覧を取得するAPI
  # API仕様のURL: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236419/
  local url="${gAnypointBaseUrl}/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis/${apiInstanceId}/policies"
  funcCurl -- \
    --header "Authorization: Bearer $gAnypointAccessToken" \
    "$url"
  cp -p  "$gLogDir/${gLogSeq}_curl-res-body.json" "$outputFile"
}

funcGetApiInstanceIdList() {
  local dirName="$1"
  gApiInstanceIdList=()
  for configFile in "${gConfigFileList[@]}"; do
    local configDirName
    configDirName="$(basename "${configFile%/*}")"
    local apiAssetId=${configDirName%_*}
    local apiVersion=${configDirName#*_}
    local apiInstanceId
    apiInstanceId=$(jq --raw-output \
      --arg apiAssetId "$apiAssetId" \
      --arg apiVersion "$apiVersion" \
      '.assets[] | select(.assetId == $apiAssetId) | .apis[] | select(.productVersion == $apiVersion) | .id' \
      "${gLogDir}/${dirName}/api-instance-list.json")

    if [ -z "$apiInstanceId" ]; then
      gApiInstanceIdList+=('<new>')
    elif [[ "$apiInstanceId" =~ ^[0-9]{1,10}$ ]]; then
      gApiInstanceIdList+=("$apiInstanceId")
    else
      # TODO: 既存のAPIインスタンスが複数件存在する場合、どれを更新対象にするかの判断が必要。現状は、複数使おうとしてエラーになる想定。
      echo "error: unexpected apiInstanceId: $apiInstanceId" >&2
      exit 1
    fi
  done
}

funcGetApiPolicyIdList() {
  local dirName="$1"
  gApiPolicyIdList=()
  for indexNumber in "${!gConfigFileList[@]}"; do
    local configFile="${gConfigFileList[indexNumber]}"
    local apiInstanceId="${gApiInstanceIdList[indexNumber]}"
    local groupIdOfApiPolicy
    local assetIdOfApiPolicy
    local apiPolicyId
    groupIdOfApiPolicy=$(jq --raw-output '.groupId // empty' "$configFile")
    assetIdOfApiPolicy=$(jq --raw-output '.assetId // empty' "$configFile")

    apiPolicyId=$(jq --raw-output \
      --arg groupId "$groupIdOfApiPolicy" \
      --arg assetId "$assetIdOfApiPolicy" \
      '.[] | select(.groupId == $groupId and .assetId == $assetId) | .id // empty' \
      "${gLogDir}/${dirName}/api-policy-list_${apiInstanceId}.json")

    if [ -z "$apiPolicyId" ]; then
      gApiPolicyIdList+=('<new>')
    elif [[ "$apiPolicyId" =~ ^[0-9]{1,10}$ ]]; then
      gApiPolicyIdList+=("$apiPolicyId")
    else
      # TODO: 1つのAPIインスタンスに対して、同じポリシーが複数件存在する場合もこのエラーになってしまうので、処理を追加する
      echo "error: unexpected apiPolicyId: $apiPolicyId" >&2
      exit 1
    fi
  done
}

funcDeployApiPolicy() {
  local configFile="$1"
  local apiInstanceId="$2"
  local apiPolicyId="$3"

  # 呼び出すAPI: API Policyを作成するAPI
  # API仕様のURL: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236450/
  # 呼び出すAPI: API Policyを更新するAPI
  # API仕様のURL: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236481/
  local url="${gAnypointBaseUrl}/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis/${apiInstanceId}/policies"
  if [ "$apiPolicyId" = '<new>' ]; then
    echo "Creating new API policy from config: $configFile"
    local httpMethod="POST"
  else
    echo "Updating existing API policy ($apiPolicyId) with config: $configFile"
    url="${url}/${apiPolicyId}"
    local httpMethod="PATCH"
  fi

  funcCurl -- \
    --request "$httpMethod"\
    --header "Authorization: Bearer $gAnypointAccessToken" \
    --header "Content-Type: application/json" \
    --data-binary "@$configFile" \
    "$url"
  
  local resBodyFile="$gLogDir/${gLogSeq}_curl-res-body.json"
  if [ "$apiPolicyId" = '<new>' ]; then
    apiPolicyId=$(jq --raw-output '.id // empty' "$resBodyFile")
    if [ -z "$apiPolicyId" ]; then
      echo "Error: Failed to get API policy ID from response body: $resBodyFile" >&2
      return 1
    fi
  fi
  
  echo "$apiPolicyId" >&3
}

funcDiffBeforeAfter() {
  diff --recursive \
    --new-file \
    --unified \
    "${gLogDir}/before-deploy" "${gLogDir}/after-deploy"
}

# このファイルが、単体試験にて source コマンドで読み込みまれた場合は、funcMain() を実行しないようにする
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  funcMain "$@"
fi
