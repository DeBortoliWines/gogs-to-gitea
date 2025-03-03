#!/bin/bash

# Copyright (C) 2025 "Bernard Gray <bernard.gray@gmail.com>"

set -x

. $(dirname $0)/env || (echo "$(dirname ${0})/env missing, please see $(dirname ${0})/env.ex"; exit 1)

JSON_CACHE_REPO=/tmp/migrate-gitea-repo-${RANDOM}
touch ${JSON_CACHE_REPO}
JSON_CACHE_ORG=/tmp/migrate-gitea-org-${RANDOM}
touch ${JSON_CACHE_ORG}

# retrieve all orgs
curl -sH 'Accept:application/json' -X GET "https://${GOGS_HOST}/api/v1/user/orgs?token=${GOGS_TOKEN}"  | jq > ${JSON_CACHE_ORG}

GET_ORGS=$(jq -r '.[] | .username' ${JSON_CACHE_ORG})
# in case of a subset that need to be migrated
#GET_ORGS=("pentaho" "archive")
#for ORG_NAME in ${GET_ORGS[@]}; do

for ORG_NAME in ${GET_ORGS}; do
    ORG_DETAIL_CACHE=/tmp/migrate-gitea-${ORG_NAME}-${RANDOM}
    touch ${ORG_DETAIL_CACHE}
    curl -sH 'Accept:application/json' -X GET "https://${GOGS_HOST}/api/v1/orgs/${ORG_NAME}?token=${GOGS_TOKEN}"  | jq > ${ORG_DETAIL_CACHE}

    # create org in gitea
    curl -sX POST "https://${GITEA_HOST}/api/v1/orgs" -u ${GITEA_USERNAME}:${GITEA_TOKEN} -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \
        \"email\": \"\", \
        \"username\": \"$(jq -r '.username' ${ORG_DETAIL_CACHE})\", \
        \"full_name\": \"$(jq -r '.full_name' ${ORG_DETAIL_CACHE})\", \
        \"description\": \"$(jq -r '.description' ${ORG_DETAIL_CACHE})\", \
        \"visibility\": \"public\", \
        \"repo_admin_change_team_access\": true, \
        \"website\": \"$(jq -r '.website' ${ORG_DETAIL_CACHE})\"}"

    GOGS_ORGANISATION=$(jq -r '.username' ${ORG_DETAIL_CACHE})
    GITEA_REPO_OWNER=${GOGS_ORGANISATION}
    
    # retrieve all repos in org
    GET_REPOS=$(curl -sH 'Accept: application/json' -u ${GOGS_USERNAME}:${GOGS_TOKEN} -s "https://${GOGS_HOST}/api/v1/orgs/${GOGS_ORGANISATION}/repos?token=${GOGS_TOKEN}" | jq -r '.[] | .name')
    
    for REPO_NAME in ${GET_REPOS}; do
    
        curl -sH 'Accept: application/json' -s "https://${GOGS_HOST}/api/v1/repos/${GOGS_ORGANISATION}/${REPO_NAME}?token=${GOGS_TOKEN}" > ${JSON_CACHE_REPO}
        URL=$(jq -r '.clone_url' ${JSON_CACHE_REPO})
        DESC=$(jq -r '.description' ${JSON_CACHE_REPO})
    
        echo "Found ${REPO_NAME} : ${URL}, importing..."
    
        curl -sX POST "https://${GITEA_HOST}/api/v1/repos/migrate" -u ${GITEA_USERNAME}:${GITEA_TOKEN} -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \
        \"auth_username\": \"${GOGS_USERNAME}\", \
        \"auth_token\": \"${GOGS_TOKEN}\", \
        \"description\": \"${DESC}\", \
        \"clone_addr\": \"${URL}\", \
        \"mirror\": false, \
        \"private\": true, \
        \"repo_name\": \"${REPO_NAME}\", \
        \"repo_owner\": \"${GITEA_REPO_OWNER}\", \
        \"service\": \"gogs\", \
        \"uid\": 0, \
        \"issues\": false, \
        \"labels\": false, \
        \"lfs\": false, \
        \"milestones\": false, \
        \"releases\": false, \
        \"pull_requests\": false, \
        \"wiki\": true}"
    done    
done

