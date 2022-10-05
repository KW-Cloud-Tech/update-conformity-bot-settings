#!/bin/bash
# requires jq

# This is a sample script for updating the Conformity Bot settings in bulk
# the script is currently configured to only look at Azure accounts, however the jq filters can be adjusted if needed

# EDIT HERE to update the bot settings configuration according to: 
# https://cloudone.trendmicro.com/docs/conformity/api-reference/tag/Accounts#paths/~1accounts~1{id}~1settings~1bot/patch
botUpdatePayload='{
  "data": {
    "type": "accounts",
    "attributes": {
      "settings": {
        "bot": {
          "disabled": false
        }
      }
    }
  }
}'

printf "Select which version of Conformity (Cloud One or Standalone) \n (Default: Standalone)\nS - Standalone\nC1 - Cloud One\nselection:"
read -r version

echo "Which region is your Conformity environment hosted in? e.g. For standalone it might be us-west-2. For Cloud One it might be us-1"
read -r region

echo "Enter your api key: "
read -r apiKey

# construct base URL depending on region and version
if [ "$version" == "C1" ]
then 
    baseURL="https://conformity.$region.cloudone.trendmicro.com/api"
else
    baseURL="https://$region-api.cloudconformity.com/v1"
fi

# function to retrieve conformity accounts for Azure subscriptions
# Note: update the jq filter as needed to retrieve the relevant accounts
azureConformityData=$(curl -L -X GET \
    "$baseURL/accounts" \
    -H "Content-Type: application/vnd.api+json" \
    -H "Authorization: ApiKey $apiKey" | jq -r '[.data[] | select(.attributes."cloud-type" | contains("azure"))]'
    ) 

# Prompt user whether they would like to see a list of accounts first?
read -r -p "Do you wish to display a list of possible Azure accounts in your environment? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        export conformityAzureAccounts=(`echo $azureConformityData | jq -r '. | map(.id) | join(" ")'`)
        echo "List of available Conformity Azure accounts:"
        for i in "${conformityAzureAccounts[@]}"
        do
            echo "$i"
        done
        ;;
    *)
        echo "proceeding..."
        ;;
esac
echo

# arguments are used to select which Conformity Azure accounts to run against
# if no arguments set, script will run against the entire set of Azure accounts
if [ "$#" -eq  "0" ]
then
    echo "No accountId arguments specified. Script will update all Azure accounts"
    export accountIdList=(`echo $azureConformityData | jq -r '. | map(.id) | join(" ")'`)

else #run against only specified accountids in argument
    echo "Arguments detected. Script will run update against select accounts"
    export arguments=$1
    IFS=',' read -r -a accountIdList <<< "$arguments"
fi

echo
echo "The new Conformity Bot configuration will be applied to the following accounts:"
    for i in "${accountIdList[@]}"
    do
        echo "[ $i ]"
    done
echo
read -n 1 -s -r -p "press any key"
echo

echo "The following account bot settings will be applied:"
echo $botUpdatePayload | jq
echo

# Confirm and apply settings
read -r -p "Would you like to proceed? (y/N) " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        for i in "${accountIdList[@]}"
            do
                conformityAccountId=$i
                echo "updating bot for $i..."
                tempURL="$baseURL/accounts/$conformityAccountId/settings/bot"
                echo $tempURL
                curl -X PATCH \
                    -H "Content-Type: application/vnd.api+json" \
                    -H "Authorization: ApiKey $apiKey" \
                    -d "$botUpdatePayload" \
                    "$tempURL" | jq
            done
        ;;
    *)
        echo "cancelling..."
        ;;
esac
