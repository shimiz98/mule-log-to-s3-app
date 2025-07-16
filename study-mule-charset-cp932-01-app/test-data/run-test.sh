#!/bin/bash
set -Ceuo pipefail

funcSingleTest() {
    local inputFile=$1
    local urlPath=$2
    local charset=$3
    local outputFile
    outputFile=$outputDir/$(basename "$inputFile")_${urlPath}_${charset}.json
    logFile=$outputDir/$(basename "$inputFile")_${urlPath}_${charset}.log
    local curlOpts=(-v --no-progress-meter --trace /dev/stdout)
    curl "${curlOpts[@]}" -H "content-type: application/json; charset=${charset}" -d "@${inputFile}" "http://localhost:8081/${urlPath}" -o "$outputFile" > "$logFile" 2>&1
}

outputDir=./$(date +%Y-%m-%dT%H-%M-%S)
mkdir "$outputDir"

funcSingleTest sjis-8740-①-unicode-2460.txt 01-default-charset shift-jis
funcSingleTest sjis-8740-①-unicode-2460.txt 01-default-charset windows-31j
funcSingleTest sjis-8740-①-unicode-2460.txt 01-default-charset utf-8

funcSingleTest sjis-8740-①-unicode-2460.txt 02-fixed-charset shift-jis
funcSingleTest sjis-8740-①-unicode-2460.txt 02-fixed-charset windows-31j
funcSingleTest sjis-8740-①-unicode-2460.txt 02-fixed-charset utf-8

funcSingleTest sjis-8740-①-unicode-2460.txt 03-validate-charset shift-jis
funcSingleTest sjis-8740-①-unicode-2460.txt 03-validate-charset windows-31j
funcSingleTest sjis-8740-①-unicode-2460.txt 03-validate-charset utf-8
