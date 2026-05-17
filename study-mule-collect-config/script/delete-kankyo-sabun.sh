#!/bin/bash
set -Ceuo pipefail

funcMain() {
    source "$(dirname "$0")/common-functions.sh"
    funcCreateLogDir "$(basename "$0" .sh)"
    funcParseCommandLineArgs "$@"

    gInputDir=$1
    teigiFile="./kesikomi-teigi.tsv"

    mkdir -p "${gLogDir}/output"
    local targetDir="${gLogDir}/output/ver3"
    cp -r "$gInputDir" "$targetDir"
    time funcKesikomiJsonVer3 "$teigiFile" "$targetDir"
}

funcParseCommandLineArgs() {
    :
}

funcKesikomiJsonVer3() {
    local teigiFile=$1
    local targetDir=$2

    # 連想配列変数を定義
    declare -A deleteJqKeyMap=()
    while IFS=$'\t' read -r pathPattern jqKey commentText; do
        if [ "$pathPattern" == "*" ] || [ "$pathPattern" == '@' ]; then
            # shell script の文法の都合で、指定できないパターンをエラーにする
            echo "[ERROR] pathPattern '$pathPattern' can not use '*' or '@'." >&2
            exit 1
        fi
        if [ "${jqKey:0:1}" != "." ]; then
            echo "[ERROR] jqKey '$jqKey' does not start with a dot for pathPattern '$pathPattern'." >&2
            exit 1
        fi
        if [ ! -z "$commentText" ]; then
            echo "[ERROR] commentText is empty for pathPattern '$pathPattern' and jqKey '$jqKey'." >&2
            exit 1
        fi
        if [ -v "deleteJqKeyMap[$pathPattern]" ]; then
            # 連想配列変数にjqのフィルターをパイプ記号で追加
            x="${deleteJqKeyMap[$pathPattern]} |"
        else
            # 連想配列変数にキーが存在しない場合は初期化
            x=''
        fi
        x="$x del($jqKey)"
        deleteJqKeyMap[$pathPattern]="$x"
    done < "$teigiFile"

    for pathPattern in "${!deleteJqKeyMap[@]}"; do
        local jqFilter="${deleteJqKeyMap[$pathPattern]}"
        echo "Path Pattern: $pathPattern"
        echo "  jq Filter: $jqFilter"

        local tmpFile
        local processingCount=0
        targetDir="${targetDir%/}"
        while read -r jsonFile; do
            echo "  Processing file: ${jsonFile#"${targetDir}/"}"
            tmpFile=$(mktemp -p "${jsonFile%/*}" "${jsonFile##*/}.tmp.XXXXXX")
            jq "$jqFilter" "$jsonFile" | tr -d '\r' >| "$tmpFile"
            mv "$tmpFile" "$jsonFile"
            processingCount=$(("$processingCount" + 1))
        done < <(find "$targetDir" -type f -path "$pathPattern")

        if [ "$processingCount" -eq 0 ]; then
            echo "[ERROR]  No files matched the path pattern. $pathPattern" >&2
            exit 1
        else
            echo "  Processed $processingCount files."
        fi
    done
}

funcMain "$@"
