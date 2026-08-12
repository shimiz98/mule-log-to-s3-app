#!/usr/bin/env bash
set -euo pipefail

funcCreateLogDir() {
  local logDirSuffix="${1:-}"
  gLogDir="$(dirname "$0")/../log/$(date +%Y%m%d-%H%M%S)_${logDirSuffix}"
  gLogSeq=0 # 初回の呼び出しで先頭のゼロ埋めをするため、ここは 0 にしておく
  mkdir -p "$gLogDir"
  gLogDir=$(realpath "$gLogDir")
}

funcIncrementLogSeq() {
  while true; do
    # MEMO: 先頭のゼロがあると8進数として扱われてしまうため、10進数として扱うように「10#」を付与する。
    gLogSeq=$(printf '%03d' "$((10#$gLogSeq + 1))")
    # MEMO: サブシェルの中でこの関数を呼び出した場合は、グローバル変数が更新できないため、ファイルの存在チェックで重複を避ける
    if compgen -G "$gLogDir/${gLogSeq}_*" > /dev/null; then
      continue
    else
      break
    fi
  done
}

funcCurl() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --) shift; break ;;
      -*) echo "error: unknown option: $1" >&2; exit 1 ;;
      *) break ;;
    esac
  done

  funcIncrementLogSeq
  # TODO: curl --write-out の出力先が、なぜか絶対パスだと失敗するので、暫定対処で相対パスにする
  local curlWriteOutFile
  curlWriteOutFile=$(realpath --relative-to=. "$gLogDir/${gLogSeq}_curl-info.log")
  local curlResBodyFile="$gLogDir/${gLogSeq}_curl-res-body.json"
  local curlResHeaderFile="$gLogDir/${gLogSeq}_curl-res-header.log"
  # MEMO: anypointで、一過性かつ原因不明の401エラーが発生する事例があったため、--retry-all-errors でリトライする。
  curl \
    --write-out "%output{${curlWriteOutFile}}%{json}" \
    --dump-header "${curlResHeaderFile}" \
    --output "${curlResBodyFile}" \
    --fail-with-body \
    --retry 3 \
    --retry-all-errors \
    "$@" && true
  local rc=$?

  local tmpFile
  tmpFile=$(mktemp)
  jq . "$curlResBodyFile" >| "$tmpFile" && mv "$tmpFile" "$curlResBodyFile"

  if [ $rc -ne 0 ]; then
    echo "error: curl command failed with exit code $rc" >&2
    echo "See log file: $curlWriteOutFile" >&2
    echo "=== Response Header ===" >&2
    cat "$curlResHeaderFile" >&2
    echo "=== Response Body ===" >&2
    cat "$curlResBodyFile" >&2
    exit $rc
  fi
}

funcGetAnypointAccessToken() {
  # MEMO: 以下の導出元 https://docs.mulesoft.com/hosting-home/#control-plane-hosting-options
  gAnypointBaseUrl="${ANYPOINT_BASE_URL:-https://anypoint.mulesoft.com}"
  gAnypointAccessToken="${ANYPOINT_ACCESS_TOKEN:-}"

  # API仕様: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/access-management-api/minor/1.0/console/method/%235716/
  local url="${gAnypointBaseUrl}/accounts/api/me"
  funcCurl -- \
    --header "Authorization: Bearer $gAnypointAccessToken" \
    "$url"
  local resBodyFile="$gLogDir/${gLogSeq}_curl-res-body.json"
  gRootOrgId=$(jq -r '.user.organizationId // empty' "$resBodyFile")
  if [[ -z "$gRootOrgId" ]]; then
    echo "error: failed to get root orgId from response body: $resBodyFile" >&2
    exit 1
  fi
}

funcGetOrgIdAndName() {
  local orgIdOrName="$1"
  if [[ -z "$orgIdOrName" ]]; then
    echo "error: orgIdOrName が長さ0の文字列です" >&2
    exit 1
  fi
  # MEMO: orgIdOrName が UUID の場合は orgId として扱い、そうでない場合は orgName として扱う。
  if [[ "$orgIdOrName" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    gOrgId="$orgIdOrName"
    gOrgName=""
    echo "error: orgIdを指定する方法は未実装です" >&2
    exit 1
  else
    gOrgName="$orgIdOrName"
    # API仕様: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/access-management-api/minor/1.0/console/method/%238357/
    local url="${gAnypointBaseUrl}/accounts/api/organizations/${gRootOrgId}/hierarchy"
    funcCurl -- \
      --header "Authorization: Bearer $gAnypointAccessToken" \
      "$url"
    local resBodyFile="$gLogDir/${gLogSeq}_curl-res-body.json"
    gOrgId=$(jq -r --arg orgName "$gOrgName" 'recurse(.subOrganizations[]?) | select(.name == $orgName) | .id // empty' "$resBodyFile")
    if [[ -z "$gOrgId" ]]; then
      echo "error: failed to get orgId for orgName: $gOrgName"
      echo "See log file: $resBodyFile" >&2
      exit 1
    fi
  fi
}

funcGetEnvIdAndName() {
  local envIdOrName="$1"
  if [[ -z "$envIdOrName" ]]; then
    echo "error: envIdOrName が長さ0の文字列です" >&2
    exit 1
  fi
  # MEMO: envIdOrName が UUID の場合は envId として扱い、そうでない場合は envName として扱う。
  if [[ "$envIdOrName" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    gEnvId="$envIdOrName"
    gEnvName=""
    echo "error: envIdを指定する方法は未実装です" >&2
    exit 1
  else
    gEnvName="$envIdOrName"
    # API仕様: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/access-management-api/minor/1.0/console/method/%238127/
    local url="${gAnypointBaseUrl}/accounts/api/organizations/${gOrgId}/environments?name=${gEnvName}"
    funcCurl -- \
      --header "Authorization: Bearer $gAnypointAccessToken" \
      "$url"
    local resBodyFile="$gLogDir/${gLogSeq}_curl-res-body.json"
    # MEMO: nameを指定しているため、1個のみ返却を想定している。
    # TODO: nameが部分一致の可能性を考えて、jqで比較する処理を追加する。
    gEnvId=$(jq -r '.data[0].id // empty' "$resBodyFile")
    if [[ -z "$gEnvId" ]]; then
      echo "error: failed to get envId for envName: $gEnvName"
      echo "See log file: $resBodyFile" >&2
      exit 1  
    fi
  fi
}
