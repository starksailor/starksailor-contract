// Core imports
use pedersen::PedersenTrait;

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Local imports
use stark_sailor::{
    models::{
        move::MoveInfo, combat::CombatInfo, treasure_trip::{TreasureTripRewardInfo},
        chest::{Chest, ChestInfo}, inventory::Inventory,
    },
};

// Interface
#[starknet::interface]
trait ITreasureTripActions<TContractState> {
    ///////////////////
    // Read Function //
    ///////////////////

    // Function to get the reward of the chest
    // # Arguments
    // * world The world address
    // * chest_id: The chest id
    // # Returns
    // * The chest reward
    fn get_chest(self: @TContractState, world: IWorldDispatcher, chest_id: u128) -> Chest;

    ////////////////////
    // Write Function //
    ////////////////////

    // Function save the new position of the player on map
    // # Arguments
    // * world The world address
    // * move_info:
    //      The move info.
    //      This data is singed by the player and contains the position (x, y) and nonce.
    // * signature_r: The signature r
    // * signature_s: The signature s
    fn move(
        ref self: TContractState,
        world: IWorldDispatcher,
        move_info: MoveInfo,
        signature_r: felt252,
        signature_s: felt252
    );

    // Function to save the combat result
    // # Arguments
    // * world The world address
    // * combat_info:
    //      The combat info
    //      This data is singed by the player and contains the ally ships, health ships and result.
    //      See models/combat.cairo -> CombatInfo for more details.
    // * signature_r: The signature r
    // * signature_s: The signature s
    fn combat(
        ref self: TContractState,
        world: IWorldDispatcher,
        combat_info: CombatInfo,
        signature_r: felt252,
        signature_s: felt252
    );

    // Function to open a chest
    // # Arguments
    // * world The world address
    // * chest_info:
    //      The chest info.
    //      This data is singed by the player and contains the chest level and nonce.
    //      See models/treasure_trip.cairo -> ChestInfo for more details.
    // * signature_r: The signature r
    // * signature_s: The signature s
    // # Returns
    // * The chest id
    fn open_chest(
        ref self: TContractState,
        world: IWorldDispatcher,
        chest_info: ChestInfo,
        signature_r: felt252,
        signature_s: felt252,
    ) -> u128;

    // Function to save the reward of the treasure trip
    // # Arguments
    // * world The world address
    // * reward_info:
    //      The reward info.
    //      This data is singed by the player and contains the reward items.
    //      See models/treasure_trip.cairo -> RewardInfo for more details.
    // * signature_r: The signature r
    // * signature_s: The signature s
    fn end_treasure_trip(
        ref self: TContractState,
        world: IWorldDispatcher,
        reward_info: TreasureTripRewardInfo,
        signature_r: felt252,
        signature_s: felt252
    );
}

// Component
#[starknet::component]
mod TreasureTripActionsComponent {
    // Core imports
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use poseidon::PoseidonTrait;
    use ecdsa::check_ecdsa_signature;

    // Starknet imports
    use starknet::{get_block_timestamp, get_caller_address, ContractAddress};

    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor::{
        constants::{GAME_ID, ADDRESS_SIGN, ACTION_CODE}, messages::Errors,
        models::{
            treasure_trip::TreasureTrip, ship::Ship, game::Game, position::Position,
            move::{MoveInfo, Movement, OffchainMessageHashMoveInfo},
            combat::{Combat, CombatInfo, CombatResult, OffchainMessageHashCombatInfo},
            treasure_trip::{TreasureTripRewardInfo, OffchainMessageHashTreasureTripRewardInfo,},
            nonce::Nonce, inventory::Inventory,
            chest::{ChestInfo, Chest, OffchainMessageHashChestInfo},
        },
        events::{MovedEvent, CombatFinishedEvent}, utils::UtilTrait,
        components::{
            random_system::{RandomSystemComponent, RandomSystemComponent::RandomSystemInternalImpl},
            inventory_system::{
                InventorySystemComponent, InventorySystemComponent::InventorySystemInternalImpl
            },
        },
    };

    // Storage
    #[storage]
    struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MovedEvent: MovedEvent,
        CombatFinishedEvent: CombatFinishedEvent
    }

    // Implementations
    #[embeddable_as(TreasureTripActionsImpl)]
    pub impl TreasureTripActions<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl RandomSystem: RandomSystemComponent::HasComponent<TContractState>,
        impl InventorySystem: InventorySystemComponent::HasComponent<TContractState>,
    > of super::ITreasureTripActions<ComponentState<TContractState>> {
        // See ITreasureTripActions-get_chest
        fn get_chest(
            self: @ComponentState<TContractState>, world: IWorldDispatcher, chest_id: u128
        ) -> Chest {
            get!(world, (chest_id), Chest)
        }

        // See ITreasureTripActions-move
        fn move(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            move_info: MoveInfo,
            signature_r: felt252,
            signature_s: felt252
        ) {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Verify signature
            UtilTrait::require_valid_message_hash(
                move_info.get_message_hash(), signature_r, signature_s
            );

            // Check player address
            let player_address = get_caller_address();
            assert(
                player_address == move_info.player_address.try_into().unwrap(),
                Errors::NOT_MOVE_PLAYER
            );

            // Check nonce
            let mut nonce = get!(world, (move_info.nonce), Nonce);
            assert(!nonce.is_used, Errors::NONCE_USED);
            nonce.is_used = true;
            set!(world, (nonce));

            // Check timestamp
            let timestamp: u64 = move_info.timestamp.try_into().unwrap();
            if (!UtilTrait::is_test_mode()) {
                assert(
                    get_block_timestamp() >= timestamp && get_block_timestamp() - timestamp <= 60,
                    Errors::TIME_EXPIRED
                );
            }

            let x_positon: u32 = move_info.x.try_into().unwrap();
            let y_positon: u32 = move_info.y.try_into().unwrap();

            // Validate params
            assert(x_positon >= 0 && y_positon >= 0, Errors::INVALID_POSITION);

            // Get treasure trip by player address
            let mut treasure_trip: TreasureTrip = get!(world, (player_address), TreasureTrip);

            // Get ship old position
            let old_position = treasure_trip.position;

            // Update ship position
            treasure_trip.position = Position { x: x_positon, y: y_positon };

            // Increase total move
            let mut game: Game = get!(world, (GAME_ID), Game);
            game.total_move += 1;

            // Save treasure trip
            set!(world, (treasure_trip));

            // Save move
            set!(
                world,
                (Movement {
                    move_id: game.total_move,
                    timestamp,
                    player_address,
                    old_position,
                    new_position: treasure_trip.position
                })
            );

            // Save game
            set!(world, (game));

            // Emit event
            emit!(
                world,
                (Event::MovedEvent(
                    MovedEvent {
                        move_id: game.total_move,
                        player_address,
                        timestamp,
                        old_position,
                        new_position: treasure_trip.position
                    }
                ))
            );
        }

        // See ITreasureTripActions-combat
        fn combat(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            combat_info: CombatInfo,
            signature_r: felt252,
            signature_s: felt252
        ) {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Verify signature
            UtilTrait::require_valid_message_hash(
                combat_info.get_message_hash(), signature_r, signature_s
            );

            // Check player address
            let player_address = get_caller_address();
            assert(
                player_address == combat_info.player_address.try_into().unwrap(),
                Errors::SIGNATURE_NOT_MATCH
            );

            let combat_id: u128 = combat_info.combat_id.try_into().unwrap();
            let mut ally_ships_felt252: Array<felt252> = array![];
            let mut health_ships: Array<felt252> = array![];
            ally_ships_felt252.append_span(combat_info.ally_ships);
            health_ships.append_span(combat_info.health_ships);

            // Validate params
            let ally_ships_num = ally_ships_felt252.len();
            assert(ally_ships_num == health_ships.len(), Errors::INVALID_SHIPS_LENGTH);

            // Verify combat id
            let combat: Combat = get!(world, (combat_id), Combat);
            assert(
                combat.ally_ships.is_empty() && combat.result == CombatResult::None,
                Errors::INVALID_COMBAT_ID
            );

            // Increase total combat
            let mut game = get!(world, (GAME_ID), Game);
            game.total_combat += 1;

            // Decide result
            let mut game_result = CombatResult::Win;
            if (combat_info.result == 0) {
                game_result = CombatResult::Lose;
            } else {
                assert(combat_info.result == 1, Errors::INVALID_COMBAT_INFO_RESULT);
            }

            // Save ship current_hp
            let mut i: u32 = 0;
            let mut ally_ships: Array<u128> = array![];
            loop {
                if (i == ally_ships_num) {
                    break;
                }

                // Get ship id
                let ship_id: u128 = (*ally_ships_felt252.at(i)).try_into().unwrap();

                // Get ship
                let mut ship: Ship = get!(world, (ship_id), Ship);

                // Save ship current_hp
                ship.current_hp = (*health_ships.at(i)).try_into().unwrap();

                // Save ship
                set!(world, (ship));

                // Append ship id
                ally_ships.append(ship_id);

                i = i + 1;
            };
            let ally_ships_event = ally_ships.clone();

            // Save combat
            set!(world, (Combat { combat_id, player_address, ally_ships, result: game_result }));

            // Save game
            set!(world, (game));

            // Emit event
            emit!(
                world,
                (Event::CombatFinishedEvent(
                    CombatFinishedEvent {
                        combat_id, ally_ships: ally_ships_event, result: game_result
                    }
                ))
            );
        }

        // See ITreasureTripActions-open_chest
        fn open_chest(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            chest_info: ChestInfo,
            signature_r: felt252,
            signature_s: felt252,
        ) -> u128 {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Verify signature
            UtilTrait::require_valid_message_hash(
                chest_info.get_message_hash(), signature_r, signature_s
            );

            // Check nonce
            let mut nonce = get!(world, (chest_info.nonce), Nonce);
            assert(!nonce.is_used, Errors::NONCE_USED);
            nonce.is_used = true;
            set!(world, (nonce));

            // Increase total chest opened
            let mut game: Game = get!(world, (GAME_ID), Game);
            game.total_chest_opened += 1;

            // Call Random System to get random number
            let mut random_system_component = get_dep_component_mut!(ref self, RandomSystem);
            let calldata: Array<felt252> = array![
                get_caller_address().into(),
                ACTION_CODE::OPEN_CHEST,
                chest_info.chest_level.into(),
                game.total_chest_opened.into()
            ];
            random_system_component._request_randomness_from_pragma(calldata);

            // Save game
            set!(world, (game));

            game.total_chest_opened
        }

        // See ITreasureTripActions-end_treasure_trip
        fn end_treasure_trip(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            reward_info: TreasureTripRewardInfo,
            signature_r: felt252,
            signature_s: felt252
        ) {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Verify signature and save nonce
            UtilTrait::require_valid_message_hash(
                reward_info.get_message_hash(), signature_r, signature_s
            );

            // Check player address
            let player_address = get_caller_address();
            assert(
                player_address == reward_info.player_address.try_into().unwrap(),
                Errors::NOT_END_TREASURE_TRIP_PLAYER
            );

            // Check nonce
            let mut nonce = get!(world, (reward_info.nonce), Nonce);
            assert(!nonce.is_used, Errors::NONCE_USED);
            nonce.is_used = true;
            set!(world, (nonce));

            // Create inventory list
            let mut inventory_list: Array<Inventory> = array![];
            let reward_num = reward_info.reward_items.len();
            let mut i = 0;
            loop {
                if (i == reward_num) {
                    break;
                }

                let reward_item = *reward_info.reward_items.at(i);
                let inventory_item: Inventory = Inventory {
                    owner: player_address,
                    item_type: reward_item.item_type,
                    id: reward_item.item_id.try_into().unwrap(),
                    amount: reward_item.item_amount.try_into().unwrap()
                };
                inventory_list.append(inventory_item);
                
                i += 1;
            };
            let mut inventory_system_component = get_dep_component_mut!(ref self, InventorySystem);
            inventory_system_component._add_items(world, inventory_list);
        }
    }
}
