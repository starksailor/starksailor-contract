#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050"
export WORLD_ADDRESS=""
export ACTION_ADDRESS=""

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo action : $ACTION_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> models authorizations

# enable system -> component authorizations
MODELS=("Combat" "Game" "Inventory" "Movement" "Nonce" "PlayerGlobal" "Ship" "TreasureTrip" "WeaponCard" "Chest")
ACTIONS=($ACTION_ADDRESS)

command="sozo auth grant --world $WORLD_ADDRESS --wait writer "
for model in "${MODELS[@]}"; do
    for action in "${ACTIONS[@]}"; do
        command+="$model,$action "
    done
done
eval "$command"

echo "Default authorizations have been successfully set."