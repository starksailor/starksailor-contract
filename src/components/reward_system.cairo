// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Interface
#[starknet::interface]
trait IRewardSystem<TContractState> {
    ////////////////////
    // Write Function //
    ////////////////////
    
    // Function to get new player reward
    // Each player can claim this reward only once
    // # Arguments
    // * world: The world address
    fn get_new_player_reward(ref self: TContractState, world: IWorldDispatcher);
}

// Component
#[starknet::component]
mod RewardSystemComponent {
    // Starknet imports
    use starknet::{ContractAddress, get_caller_address};

    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor::{
        messages::Errors, constants::{GAME_ID, ACTION_CODE},
        models::{ship::{Ship, ShipInfo, ShipTrait}, player_global::{PlayerGlobal}},
        utils::UtilTrait,
        components::{
            random_system::{RandomSystemComponent, RandomSystemComponent::RandomSystemInternalImpl}
        },
    };

    // Storage
    #[storage]
    struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    // Implementations
    #[embeddable_as(RewardSystemImpl)]
    pub impl RewardSystem<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl RandomSystem: RandomSystemComponent::HasComponent<TContractState>,
    > of super::IRewardSystem<ComponentState<TContractState>> {
        // See IRewardSystem-get_new_player_reward
        fn get_new_player_reward(
            ref self: ComponentState<TContractState>, world: IWorldDispatcher
        ) {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Get player address
            let player_address = get_caller_address();

            // Check whether the player has already claimed the default reward
            let mut player_global: PlayerGlobal = get!(world, (player_address), PlayerGlobal);
            assert(!player_global.is_claimed_default_reward, Errors::ALREADY_CLAIMED);

            // Update & save data
            player_global.is_claimed_default_reward = true;
            set!(world, (player_global));

            // Get random number
            let mut random_system_component = get_dep_component_mut!(ref self, RandomSystem);
            let calldata: Array<felt252> = array![
                get_caller_address().into(), ACTION_CODE::CLAIM_NEW_PLAYER_REWARD
            ];
            if (!UtilTrait::is_test_mode()) {
                random_system_component._request_randomness_from_pragma(calldata);   
            }
        }
    }
}
