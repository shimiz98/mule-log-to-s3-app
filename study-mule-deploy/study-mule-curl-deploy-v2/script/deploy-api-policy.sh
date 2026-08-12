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
  funcSortConfigFileList
  funcGetApiInstanceList 'before-deploy'
  funcGetApiInstanceIdList 'before-deploy'
  funcGetApiPolicyList 'before-deploy'
  funcCheckAnypointPlatform
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
  funcGetApiPolicyList 'after-deploy'
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

# 入力ファイルをAPIPolicyの作成順序に並び替える。
# APIPolicyの作成順序は、API InstanceのassetIdの昇順、API PolicyのassetIdの昇順、API Policyのorderの昇順とする。
# TODO: order=1が存在する状態で、order=1のAPI Policyを作成または、order=1に変更した場合に、既存のAPI Policyのorderを自動的に後ろにズレる想定だが、実機で確認する
funcSortConfigFileList() {
  local sortedConfigFileList=()
  local configFile
  local configDirName
  local apiAssetId
  local policyFileName
  local policyAssetId
  local policyOrder

  while IFS=$'\t' read -r _ _ _ configFile; do
    sortedConfigFileList+=("$configFile")
  done < <(
    for configFile in "${gConfigFileList[@]}"; do
      configDirName="$(basename "${configFile%/*}")"
      apiAssetId="${configDirName%_*}"
      policyFileName="${configFile##*/}"
      policyAssetId="${policyFileName#api-policy_}"
      policyAssetId="${policyAssetId%_*}"
      policyOrder="$(jq --raw-output '.order // empty' "$configFile")"
      printf '%s\t%s\t%s\t%s\n' \
        "$apiAssetId" "$policyAssetId" "$policyOrder" "$configFile"
    done | LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3n -k4,4
  )
  gConfigFileList=("${sortedConfigFileList[@]}")
  echo "Info: Sorted config file list: ${gConfigFileList[*]}" >&2
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
  local apiInstanceId
  for apiInstanceId in "${gApiInstanceIdList[@]}"; do
    local outputFile="$gLogDir/$dirName/api-policy-list_${apiInstanceId}.json"
    if [ -f "$outputFile" ]; then
      echo "Info: Skipping API policy list retrieval for API instance ID: $apiInstanceId (file already exists)" >&2
      continue
    fi
    # 呼び出すAPI: APIポリシーの一覧を取得するAPI
    # API仕様のURL: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236419/
    local url="${gAnypointBaseUrl}/apimanager/api/v1/organizations/${gOrgId}/environments/${gEnvId}/apis/${apiInstanceId}/policies"
    funcCurl -- \
      --header "Authorization: Bearer $gAnypointAccessToken" \
      "$url"
    cp -p  "$gLogDir/${gLogSeq}_curl-res-body.json" "$outputFile"
  done
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
      # gApiInstanceIdList+=('<new>') # TODO: depoy-api-instance.sh と処理を共通化を検討する。
      echo "error: API instance not found for assetId=$apiAssetId, version=$apiVersion" >&2
      exit 1
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
      '.policies[] | select(.template.groupId == $groupId and .template.assetId == $assetId) | .policyId // empty' \
      "${gLogDir}/${dirName}/api-policy-list_${apiInstanceId}.json")

    if [ -z "$apiPolicyId" ]; then
      gApiPolicyIdList+=('<new>')
    elif [[ "$apiPolicyId" =~ ^[0-9]{1,10}$ ]]; then
      gApiPolicyIdList+=("$apiPolicyId")
    else
      # TODO: 1つのAPIインスタンスに対して、同じポリシーが複数件存在する場合もこのエラーになってしまうので、処理を追加する
      # TODO: extract-api-policy-id.jq を使って、APIインスタンスのIDを取得するように変更する。
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
    "${gLogDir}/before-deploy" "${gLogDir}/after-deploy" && true
  rc=$?
  # diffコマンドは、差分がある場合は1を返すので、1の場合はエラーではない。
  if [ $rc -gt 1 ]; then
    echo "Error: diff command failed with exit code $rc" >&2
    exit $rc
  fi
}

# このファイルが、単体試験にて source コマンドで読み込みまれた場合は、funcMain() を実行しないようにする
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  funcMain "$@"
fi
