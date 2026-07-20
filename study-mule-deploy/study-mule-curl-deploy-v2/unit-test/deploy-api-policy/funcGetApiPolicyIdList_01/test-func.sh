#!/bin/bash
unitTestDir="$(dirname "${BASH_SOURCE[0]}")"
source "${unitTestDir}/../../../script/deploy-api-policy.sh"

gLogDir="${unitTestDir}/log"
gConfigFileList=(
    "${unitTestDir}/config/exp-aaa-api_v1/api-policy_ip-blocklist_0.json" \
    "${unitTestDir}/config/exp-aaa-api_v1/api-policy_ip-allowlist_0.json" \
    "${unitTestDir}/config/exp-aaa-api_v1/api-policy_client-id-enforcement_0.json" \
    "${unitTestDir}/config/exp-aaa-api_v2/api-policy_ip-allowlist_0.json" \
    "${unitTestDir}/config/exp-bbb-api_v1/api-policy_ip-allowlist_0.json" \
)
gApiInstanceIdList=(111 111 111 222 333)
funcGetApiPolicyIdList before-deploy

echo "${gApiPolicyIdList[*]}"
