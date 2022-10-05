# update-conformity-bot-settings
A sample bash script to apply conformity bot settings in bulk

Requires jq

## Usage
Script can be run with arguments for specific accountIds, or can left to apply to all accounts gathered by the script's query.

Before running script, update the payload depending on the action desired. Currently it is set to a simple 'enable' of the Conformity bot. Details of options for the update payload can be found here: https://cloudone.trendmicro.com/docs/conformity/api-reference/tag/Accounts#paths/~1accounts~1{id}~1settings~1bot/patch 

### Note
Please note this is a sample script only. Trend Micro accepts no liability
