#!/bin/bash
set -Cueo pipefail

funcClone() {
	local dstDir=$1
	cp --parents -t "$dstDir" ./src/main/mule/global.xml
	cp --parents -t "$dstDir" ./src/main/resources/*.properties
}

shFile=$(realpath "$0")
cd ${shFile%/*}/..
pwd
funcClone ../study-mule-opentelemetry-02-app
funcClone ../study-mule-opentelemetry-03-app
funcClone ../study-mule-opentelemetry-04-app
