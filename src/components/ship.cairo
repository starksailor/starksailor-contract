// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Local imports
use stark_sailor::models::ship::{ShipInfo, ShipUpgradeInfo, Ship, DeactivateShipInfo};

// Interface
#[starknet::interface]
trait IShipActions<TContractState> {
    ///////////////////
    // Read Function //
    ///////////////////

    // Function to get the ship
    // # Arguments
    // * world The world address
    // * ship_id The ship id
    // # Returns
    // * The ship
    fn get_ship(self: @TContractState, world: IWorldDispatcher, ship_id: u128) -> Ship;

    ////////////////////
    // Write Function //
    ////////////////////

    // Function to activate a ship
    // # Arguments
    // * world The world address
    // * ship_info:
    //      The ship info
    //      This data is signed by the player
    //      See models/ship.cairo -> ShipInfo for more details.
    // * signature_r: signature r
    // * signature_s: signature s
    fn activate_ship(
        ref self: TContractState,
        world: IWorldDispatcher,
        ship_info: ShipInfo,
        signature_r: felt252,
        signature_s: felt252
    );

    // Function to deactivate a ship
    // # Arguments
    // * world The world address
    // * deactivate_ship_info:
    //      The deactivate ship info
    //      This data is signed by the player
    //      See models/ship.cairo -> DeactivateShipInfo for more details.
    // * signature_r: signature r
    // * signature_s: signature s
    // * nonce: The nonce
    fn deactivate_ship(
        ref self: TContractState,
        world: IWorldDispatcher,
        deactivate_ship_info: DeactivateShipInfo,
        signature_r: felt252,
        signature_s: felt252,
    );

    // Function to upgrade a ship
    // # Arguments
    // * world The world address
    // * ship_upgrade_info:
    //      The ship upgrade info
    //      This data is signed by the player
    //      See models/ship.cairo -> ShipUpgradeInfo for more details.
    // * signature_r: signature r
    // * signature_s: signature s
    fn upgrade_ship(
        ref self: TContractState,
        world: IWorldDispatcher,
        ship_upgrade_info: ShipUpgradeInfo,
        signature_r: felt252,
        signature_s: felt252
    );
}

// Component
#[starknet::component]
mod ShipActionsComponent {
    // Core imports
    use poseidon::PoseidonTrait;
    use ecdsa::check_ecdsa_signature;

    // Starknet imports
    use starknet::{ContractAddress, get_caller_address};

    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor::{
        messages::Errors, constants::{ADDRESS_SIGN, GAME_ID, RESOURCE_CODE},
        models::{
            ship::{
                Ship, ShipInfo, ShipUpgradeInfo, ShipTrait, ShipCategory, DeactivateShipInfo,
                OffchainMessageHashShipInfo, OffchainMessageHashShipUpdateInfo,
                OffchainMessageHashDeactivateShipInfo
            },
            game::{Game}, player_global::{PlayerGlobal}, inventory::{Inventory}, nonce::Nonce,
        },
        utils::UtilTrait,
    };

    // Storage
    #[storage]
    struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    // Implementations
    #[embeddable_as(ShipActionsImpl)]
    pub impl ShipActions<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of super::IShipActions<ComponentState<TContractState>> {
        // See IShipActions-get_ship
        fn get_ship(
            self: @ComponentState<TContractState>, world: IWorldDispatcher, ship_id: u128
        ) -> Ship {
            get!(world, (ship_id), Ship)
        }

        // See IShipActions-activate_ship
        fn activate_ship(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            ship_info: ShipInfo,
            signature_r: felt252,
            signature_s: felt252
        ) {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Verify signature
            UtilTrait::require_valid_message_hash(
                ship_info.get_message_hash(), signature_r, signature_s
            );

            // Check nonce
            let mut nonce: Nonce = get!(world, (ship_info.nonce), Nonce);
            assert(!nonce.is_used, Errors::NONCE_USED);
            nonce.is_used = true;
            set!(world, (nonce));

            // Check if ship is already activated
            let ship_id: u128 = ship_info.id.try_into().unwrap();
            let ship: Ship = get!(world, (ship_id), Ship);
            assert(!ship.owner.is_non_zero(), Errors::SHIP_ALREADY_ACTIVATED);

            // Create ship by ship info
            let new_ship: Ship = ShipTrait::create_ship(ship_info);

            // Get player
            let mut player_global: PlayerGlobal = get!(world, (get_caller_address()), PlayerGlobal);

            // Change player ship owned data
            player_global.num_ship_owned += 1;

            // Save player
            set!(world, (player_global));

            // Save ship
            set!(world, (new_ship));
        }

        // See IShipActions-deactivate_ship
        fn deactivate_ship(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            deactivate_ship_info: DeactivateShipInfo,
            signature_r: felt252,
            signature_s: felt252,
        ) {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Verify signature
            UtilTrait::require_valid_message_hash(
                deactivate_ship_info.get_message_hash(), signature_r, signature_s
            );

            // Check player address
            let player_address = deactivate_ship_info.player_address.try_into().unwrap();
            assert(get_caller_address() == player_address, Errors::NOT_SHIP_OWNER);

            // Check nonce
            let mut _nonce: Nonce = get!(world, (deactivate_ship_info.nonce), Nonce);
            assert(!_nonce.is_used, Errors::NONCE_USED);
            _nonce.is_used = true;
            set!(world, (_nonce));

            // Get ship
            let id: u128 = deactivate_ship_info.ship_id.try_into().unwrap();
            let ship: Ship = get!(world, (id), Ship);

            // Get player
            let mut player_global: PlayerGlobal = get!(world, (get_caller_address()), PlayerGlobal);

            // Change player ship owned data
            player_global.num_ship_owned -= 1;

            // Deactivate ship
            delete!(world, (ship));

            // Save player
            set!(world, (player_global));
        }

        // See IShipActions-upgrade_ship
        fn upgrade_ship(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            ship_upgrade_info: ShipUpgradeInfo,
            signature_r: felt252,
            signature_s: felt252
        ) {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Verify signature
            UtilTrait::require_valid_message_hash(
                ship_upgrade_info.get_message_hash(), signature_r, signature_s
            );

            // Check player address
            let player_address = ship_upgrade_info.player_address.try_into().unwrap();
            assert(get_caller_address() == player_address, Errors::NOT_SHIP_OWNER);

            // Check nonce
            let mut nonce: Nonce = get!(world, (ship_upgrade_info.nonce), Nonce);
            assert(!nonce.is_used, Errors::NONCE_USED);
            nonce.is_used = true;
            set!(world, (nonce));

            // Get ship
            let ship_id: u128 = ship_upgrade_info.id.try_into().unwrap();
            let mut ship: Ship = get!(world, (ship_id), Ship);

            // Check ship ownership
            assert(ship.owner == player_address, Errors::NOT_RESOURCE_OWNER);

            // Check player resources: bottle ship
            let mut bottle_ship_id = 1;
            if (ship.category == ShipCategory::Common) {
                bottle_ship_id = 1;
            } else if (ship.category == ShipCategory::Uncommon) {
                bottle_ship_id = 2;
            } else if (ship.category == ShipCategory::Rare) {
                bottle_ship_id = 3;
            } else if (ship.category == ShipCategory::Epic) {
                bottle_ship_id = 4;
            } else if (ship.category == ShipCategory::Legendary) {
                bottle_ship_id = 5;
            }

            // Check the player has enough resources
            let mut player_silvers: Inventory = get!(
                world, (player_address, RESOURCE_CODE::COIN, 0), Inventory
            );
            let mut player_bottle_ship: Inventory = get!(
                world, (player_address, RESOURCE_CODE::BOTTLE_SHIP, bottle_ship_id), Inventory
            );
            let coin_required: u128 = ship_upgrade_info.require_coin.try_into().unwrap();
            let bottle_ship_required: u128 = ship_upgrade_info
                .require_bottle_ship
                .try_into()
                .unwrap();

            assert(player_silvers.amount >= coin_required, Errors::NOT_ENOUGH_COIN);
            assert(
                player_bottle_ship.amount >= bottle_ship_required, Errors::NOT_ENOUGH_BOTTLE_SHIP
            );

            // Update ship level
            ship.level += 1;

            // Update resources
            player_silvers.amount -= coin_required;
            player_bottle_ship.amount -= bottle_ship_required;

            // Save resources
            set!(world, (player_silvers));
            set!(world, (player_bottle_ship));

            // Save ship
            set!(world, (ship));
        }
    }

    #[generate_trait]
    pub impl ShipActionsInternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of InternalTrait<TContractState> {
        // Must be call by the higher level contract with security check
        fn _claim_ship(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            random_seed: felt252,
            ship_reward_number: u32,
            player_address: ContractAddress
        ) {
            // Get player
            let mut player_global: PlayerGlobal = get!(world, (player_address), PlayerGlobal);

            // Get game
            let mut game: Game = get!(world, (GAME_ID), Game);

            let mut i = 0;
            loop {
                if (i == ship_reward_number) {
                    break;
                }

                // Create ship id
                game.total_default_ship += 1;

                // Create and claim the default ship
                let default_ship: Ship = ShipTrait::generate_default_ship(
                    player_address, game.total_default_ship, random_seed
                );
                player_global.num_ship_owned += 1;

                // Save ship
                set!(world, (default_ship));

                i += 1;
            };

            // Save player
            set!(world, (player_global));

            // Save game
            set!(world, (game));
        }
    }
}
