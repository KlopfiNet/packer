#!/bin/bash
# Bootstrap script for proxmox-iso builder
# > Checks if a certain ISO already contains in specified datastore
# > If yes, delete ISO as the builder will not overwrite the file

set -e

SEARCH_STRING="ubuntu-22.04.3-live-server-amd64.iso"
PM_NODE=hv
PM_STORAGE=local

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

# It is expected that certain env vars are set
if [[ -z "${PM_API_TOKEN_ID}" ]]; then
  echo -e "${RED}Must set PM_API_TOKEN_ID${NC}"
  exit 1
fi
if [[ -z "${PM_API_TOKEN_PASS}" ]]; then
  echo -e "${RED}Must set PM_API_TOKEN_PASS${NC}"
  exit 1
fi
if [[ -z "${PM_API_URL}" ]]; then
  echo -e "${RED}Must set PM_API_URL${NC}"
  exit 1
fi

# --------------------------------------
# Remove existing ISO on datastore
echo -e "${CYAN}Retrieving ISOs...${NC}"
AUTH_HEADER="PVEAPIToken=$PM_API_TOKEN_ID=$PM_API_TOKEN_PASS"
DATASTORE_CONTENT=$(curl -s -k "$PM_API_URL/nodes/$PM_NODE/storage/$PM_STORAGE/content" \
  -H "Authorization: $AUTH_HEADER" | jq .data)

if [ "$DATASTORE_CONTENT" == "null" ]; then
  echo -e "${RED}Datastore content could not be retrieved.{NC}"
  exit 1
fi

echo -e "${CYAN}Searching for ISO...${NC}"
ISO_MATCH=$(echo $DATASTORE_CONTENT | jq -r ".[] | select ( .volid | contains(\"$SEARCH_STRING\")) | .volid")
if [[ ! -z "$ISO_MATCH" ]]; then
  echo -e "${YELLOW}Found matching ISO:${NC} $ISO_MATCH"

  # Delete
  URL="$PM_API_URL/nodes/$PM_NODE/storage/$PM_STORAGE/content/$ISO_MATCH"
  VERDICT=$(curl -k -s -o /dev/null -w "%{http_code}" $URL \
    -H "Authorization: $AUTH_HEADER" \
    -X DELETE)

  if [[ ! "$VERDICT" == "200" ]]; then
    echo -e "${RED}Got bad status code ($VERDICT) on '$URL'${NC}"
    exit 1
  else
    echo -e "${GREEN}File was deleted.${NC}"
  fi
else
  echo -e "${GREEN}File was not found.${NC}"
fi

