#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050"

# export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')
# export ACTION_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[] | select(.name == "dragark_2::systems::actions::actions" ).address')
export WORLD_ADDRESS="0xabcd"
export ACTION_ADDRESS="0xabcd"

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo action : $ACTION_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> models authorizations

# enable system -> component authorizations
MODELS=("Combat" "Game" "Movement" "Ship" "TreasureTrip")
ACTIONS=($ACTION_ADDRESS)

command="sozo auth grant --world $WORLD_ADDRESS --wait writer "
for model in "${MODELS[@]}"; do
    for action in "${ACTIONS[@]}"; do
        command+="$model,$action "
    done
done
eval "$command"

echo "Default authorizations have been successfully set."