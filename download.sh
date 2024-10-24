#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

client_id="YOUR-CLIENT-ID-GOES-HERE"
client_secret="YOUR-APP-SECRET-VALUE-GOES-HERE"
tenant_id="YOUR-TENANT-ID-GOES-HERE"
site_name="MySite" # The name of your site
sharepoint_url="example.sharepoint.com"
file_name="filename.txt"
destination="/tmp/" # Where to save the file

echo Fetch access token
response_access=$(curl -s -X POST \
    "https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token" \
    -F grant_type=client_credentials \
    -F client_id=$client_id \
    -F client_secret=$client_secret \
    -F scope=https://graph.microsoft.com/.default)

access_token=$(echo $response_access | jq -r '.access_token')

echo Fetch site id
response_site=$(curl -s -X GET \
    "https://graph.microsoft.com/v1.0/sites/$sharepoint_url:/sites/$site_name" \
    -H "Authorization: Bearer $access_token")

site_id=$(echo $response_site | jq -r '.id')

echo Fetch drive id
response_drive=$(curl -s -X GET \
    "https://graph.microsoft.com/v1.0/sites/$site_id/drives" \
    -H "Authorization: Bearer $access_token")

drive_id="$(echo $response_drive | jq -r '.value[] | select(.name=="Documents") | .id')"

echo Fetch folder id
response_folder=$(curl -s -X GET \
    "https://graph.microsoft.com/v1.0/sites/$site_id/drives/$drive_id/root/children" \
    -H "Authorization: Bearer $access_token")

folder_id=$(echo $response_folder | jq -r '.value[] | select(.name=="General") | .id')

echo Fetch item id
response_item=$(curl -s -X GET \
    "https://graph.microsoft.com/v1.0/sites/$site_id/drives/$drive_id/items/$folder_id/children" \
    -H "Authorization: Bearer $access_token")

item_id=$(echo $response_item | jq -r '.value[] | select(.name=="'$file_name'") | .id')

echo Downloading...
wget --quiet --continue \
    --header="Authorization: Bearer $access_token" \
    "https://graph.microsoft.com/v1.0/sites/$site_id/drives/$drive_id/items/$item_id/content" \
    -O "$destination$file_name"


