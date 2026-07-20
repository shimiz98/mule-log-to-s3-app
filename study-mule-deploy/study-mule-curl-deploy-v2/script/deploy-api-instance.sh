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
  funcCheckAnypointPlatform
  funcGetApiInstanceIdList 'before-deploy'
  local deployStatus=0
  if [ "$gDryRun" -ne 1 ]; then
    local tmpFile
    tmpFile=$(mktemp)
    local indexNumber
    for indexNumber in "${!gConfigFileList[@]}"; do
      # MEMO: 何かエラーが発生しても処理を継続するために、丸括弧で括ってサブシェルの中で実行する。    
      (funcDeployApiInstance "${gConfigFileList[indexNumber]}" "${gApiInstanceIdList[indexNumber]}") 3>| "$tmpFile" && true
      # WARN: ここにコマンドを書くと、ステータス「$?」が上書きされてしまうので、何か処理を追加する際は「rc=$?」の後に追加すること。
      rc=$?

      if [ $rc -ne 0 ]; then
        echo "Error deploying API instance for config: ${gConfigFileList[$indexNumber]}" >&2
        deployStatus=$rc
        break
      fi
      echo "Deployed API instance ID: $(cat "$tmpFile")" >&2
    done
  fi
  funcGetApiInstanceList 'after-deploy'
  funcPrintApiInstanceBeforeAfter
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
  :
}

funcCheckAnypointPlatform() {
  :
}

funcGetApiInstanceList() {
  local dirName="$1"
  mkdir -p "$gLogDir/$dirName"
  local outputFile="$gLogDir/$dirName/api-instance-list.json"
  # WARN: 100件以上のAPIインスタンスが存在する場合、全件取得できない。そんなに多く作らないので、本ツールでは何も対処しないこととする。
  local url="${gAnypointBaseUrl}/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis?limit=100"
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
      apiInstanceId='<new>'
    fi
    # TODO: 既存のAPIインスタンスが複数件存在する場合、どれを更新対象にするかの判断が必要。現状は、複数使おうとしてエラーになる想定。
    gApiInstanceIdList+=("$apiInstanceId")
  done
}

funcDeployApiInstance() {
  local configFile="$1"
  local apiInstanceId="$2"
  
  local url="${gAnypointBaseUrl}/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis"
  if [ "$apiInstanceId" = '<new>' ]; then
    echo "Creating new API instance from config: $configFile"
    local httpMethod="POST"
  else
    echo "Updating existing API instance ($apiInstanceId) with config: $configFile"
    url="${url}/${apiInstanceId}"
    local httpMethod="PATCH"
    # TODO: POSTではリクエストボディの`.spec.version`に対して、PATCHでは直下の`.assetVersion`に値の詰め替えが必要という仕様の違いがあるので、configファイルの内容を変換する処理を追加する必要がある。
  fi

  funcCurl -- \
    --request "$httpMethod"\
    --header "Authorization: Bearer $gAnypointAccessToken" \
    --header "Content-Type: application/json" \
    --data-binary "@$configFile" \
    "$url"
  
  local resBodyFile="$gLogDir/${gLogSeq}_curl-res-body.json"
  if [ "$apiInstanceId" = '<new>' ]; then
    apiInstanceId=$(jq --raw-output '.id // empty' "$resBodyFile")
    if [ -z "$apiInstanceId" ]; then
      echo "Error: Failed to get API instance ID from response body: $resBodyFile" >&2
      return 1
    fi
  else
    # MEMO: 構成ドリフト防止のため、既存のupstreamがあれば削除する
    url="${gAnypointBaseUrl}/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis/${apiInstanceId}/upstreams"
    funcCurl -- \
      --header "Authorization: Bearer $gAnypointAccessToken" \
      "$url"

    # MEMO: gLogSeqが増えるので、ここで resBodyFileを再定義する必要あり
    local resBodyFile="$gLogDir/${gLogSeq}_curl-res-body.json"
    while read -r upstreamId; do
      if [ -z "$upstreamId" ]; then
        continue
      fi
      url="${gAnypointBaseUrl}/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis/${apiInstanceId}/upstreams/${upstreamId}"
      funcCurl -- \
        --request "DELETE" \
        --header "Authorization: Bearer $gAnypointAccessToken" \
        "$url"
    done < <(jq --raw-output '.upstreams[] | .id // empty' "$resBodyFile")
  fi
  
  echo "$apiInstanceId" >&3
}

funcPrintApiInstanceBeforeAfter() {
  local beforeTmpFile
  local afterTmpFile
  beforeTmpFile=$(mktemp)
  afterTmpFile=$(mktemp)

  # MEMO: lastActiveDeltaは、毎回差分が出るため、比較対象から除外する
  jq '(.assets[]?.apis[]?.lastActiveDelta) = "***"' "$gLogDir/before-deploy/api-instance-list.json" >| "$beforeTmpFile"
  jq '(.assets[]?.apis[]?.lastActiveDelta) = "***"' "$gLogDir/after-deploy/api-instance-list.json" >| "$afterTmpFile"

  diff -u --label="Before Deploy" --label="After Deploy" \
    "$beforeTmpFile" \
    "$afterTmpFile" && true
}

# このファイルが、単体試験にて source コマンドで読み込みまれた場合は、funcMain() を実行しないようにする
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  funcMain "$@"
fi
