#!/bin/bash -ex
cd $HOME
rm -rf $REPO_NAME
git clone $REPO_URL
cd $REPO_NAME
git checkout $REVISION

sed -i -e "/host/c\      \"host\": \"http://${RESOURCE_NAME}.${RESOURCE_NAMESPACE}.example.com/es\"," book.js
sed -i -e "/index/c\      \"index\": \"${RESOURCE_NAME}-${REVISION}\"," book.js

pnpm config set registry https://npm.flatt.tech/
pnpm install --frozen-lockfile
pnpm run build

INDEX_URL=${SEARCH_HOST}/${RESOURCE_NAME}-${REVISION}
curl -sS -X DELETE "${INDEX_URL}?ignore_unavailable=true"
curl -sSf -X PUT "${INDEX_URL}" -H 'Content-Type: application/json' -d @mappings.json
RESULT=$(curl -sSf -X POST "${INDEX_URL}/_bulk?refresh=true" -H 'Content-Type: application/json' --data-binary @_book/search_index.json)
if echo "${RESULT}" | grep -q '"errors":true'; then
  echo "${RESULT}"
  exit 1
fi
