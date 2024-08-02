#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050"

# export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')
# export ACTION_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[] | select(.name == "dragark_2::systems::actions::actions" ).address')
export WORLD_ADDRESS="0x14257d06fbd345c5d2b4fca7b49a24a7f3f7f2e4fcdd47b3867b6e31af42b38"
export ACTION_ADDRESS="0xd0ff27f41260eead8d84704a14dfb273f2a46f88a6cd71b2e6a33c7bebe095"

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo action : $ACTION_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> models authorizations

# enable system -> component authorizations
MODELS=("Combat" "Game" "Move" "Ship")
ACTIONS=($ACTION_ADDRESS)

command="sozo auth grant --world $WORLD_ADDRESS --wait writer "
for model in "${MODELS[@]}"; do
    for action in "${ACTIONS[@]}"; do
        command+="$model,$action "
    done
done
eval "$command"

echo "Default authorizations have been successfully set."