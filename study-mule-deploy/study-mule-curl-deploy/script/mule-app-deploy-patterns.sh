#!/bin/bash
set -Ceuo pipefail

funcMain() {
    local -r templateFile=$1
    local -r patternFile=$2

    funcCreateLogDir
    
    local patternNum=0
    local patternComment=''
    local modifiedFile=''
    while read -r line || [ -n "$line" ]; do
        if [ "$modifiedFile" = '' ]; then
            patternNum=$(printf '%02d' $(( (10#$patternNum) + 1 )) )
            gPatternDir=${gLogDir}/pattern-${patternNum}
            mkdir "${gPatternDir}"
            modifiedFile=${gPatternDir}/deploy-config.json
            cp "$templateFile" "$modifiedFile"
        fi
        if [ "${line:0:1}" = '#' ]; then
            [ "$patternComment" != '' ] && patternComment=$patternComment$'\n'
            patternComment="${patternComment}${line}"
        elif [ "$line" != "" ]; then
            funcModifyFile "$modifiedFile" "$line"
        else
            funcDeploy "$templateFile" "$modifiedFile" "$patternComment"
            patternComment=''
            modifiedFile=''
        fi
    done < "$patternFile"

    # ファイルの末尾にLFが無い場合
    if [ "$modifiedFile" != '' ]; then
        funcDeploy "$templateFile" "$modifiedFile" "$patternComment"
    fi
}

funcCreateLogDir() {
    gLogDir=$(realpath "./log/$(date +%Y%m%d-%H%M%S)" )
    mkdir "$gLogDir"
}

funcModifyFile() {
    local -r modifiedFile=$1
    local -r line=$2

    local jsonPath=${line%% *}
    local jsonValue=${line#* }
    jq --argjson x "$jsonValue" --binary "${jsonPath} = \$x" "$modifiedFile" > "${gLogDir}/tmp.json"
    mv "${gLogDir}/tmp.json" "$modifiedFile"
}

funcDeploy() {
    local -r templateFile=$1
    local -r modifiedFile=$2
    local -r patternComment=$3

    diff <(jq . "$templateFile") <(jq . "$modifiedFile") > "${gPatternDir}/deploy-config.diff" && true
    local rc=$?
    if [ $rc -ne 0 ] && [ $rc -ne 1 ]; then
        exit $rc
    fi

    printf '%s' "$patternComment" > "${gPatternDir}/pattern-comment.txt"

    local -r scriptFile=$(realpath ./script/mule-app-deploy-to-cloudhub2.sh)
    local -r orgId=a81c52fe-cb9e-4acb-8e3a-284b26c4f12e
    local -r envId=a071aaf1-57e2-486f-9919-67e78a97e798
    local -r assetId=study-mule-minmum-01-app
    local -r assetVersion=1.0.0-2
    (cd "$gPatternDir" && sh "$scriptFile" "$orgId" "$envId" '' "$assetId" "$assetVersion" "$modifiedFile" && true) && true
    local rc=$?
    if [ $rc -ne 0 ]; then
        touch "${gPatternDir}/NG.txt"
    fi

    # TODO: cleanup
    local x
    x=$(printf '%s' "${patternComment}" | head -n1 | cut -c -40 | tr '\\/:*?"<>|' '_' | sed 's/^# *//;s/ *$//')
    if [ -n "$x" ]; then
       mv "$gPatternDir" "${gPatternDir}_${x}"
        gPatternDir="${gPatternDir}_${x}" # TODO modifiedFile には未反映。
    fi
}

funcMain "$@"
