// Starknet imports
use core::starknet::ContractAddress;

// Dojo imports
use dojo::world::IWorldDispatcher;

// Interface
#[starknet::interface]
pub trait IRandomSystem<TContractState> {
    ///////////////////
    // Read Function //
    ///////////////////

    // Function to get the last random seed
    // # Returns
    // * The last random seed
    fn get_last_random_seed(self: @TContractState) -> felt252;

    ////////////////////
    // Write Function //
    ////////////////////

    // Function called to receive the random words
    // This function is only called by VRF contract
    // # Arguments
    // * requester_address Address that submitted the randomness request
    // * request_id ID of the randomness request
    // * random_words A span of random words
    // * calldata The calldata which sent from _request_randomness_from_pragma
    fn receive_random_words(
        ref self: TContractState,
        requester_address: ContractAddress,
        request_id: u64,
        random_words: Span<felt252>,
        calldata: Array<felt252>
    );

    // Function to withdraw the extra fee fund
    // This function is only called by the world owner
    // # Arguments
    // * receiver: The receiver address
    fn withdraw_extra_fee_fund(ref self: TContractState, receiver: ContractAddress);
}

#[starknet::interface]
pub trait ERC20ABI<TState> {
    // IERC20
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;

    // IERC20Metadata
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
    fn decimals(self: @TState) -> u8;

    // IERC20CamelOnly
    fn totalSupply(self: @TState) -> u256;
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
}

// Component
#[starknet::component]
mod RandomSystemComponent {
    use core::option::OptionTrait;
    use super::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

    // Core imports
    use core::integer::BoundedU64;

    // Starknet imports
    use starknet::{
        ContractAddress, get_contract_address, get_block_number, get_caller_address,
        get_block_timestamp,
    };

    // Library imports
    use pragma_lib::abi::{IRandomnessDispatcher, IRandomnessDispatcherTrait};

    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor::{
        messages::Errors,
        constants::{GAME_ID, ETH_ADDRESS, VRF_ADDRESS, ACTION_CODE, REWARD_SYSTEM},
        components::{
            ship::{ShipActionsComponent, ShipActionsComponent::ShipActionsInternalImpl},
            weapon_card::{
                WeaponCardActionsComponent,
                WeaponCardActionsComponent::WeaponCardActionsInternalImpl
            },
        },
        models::{weapon_card::WeaponCardCategory, chest::{Chest, ChestLevel, ChestTrait},},
        utils::UtilTrait, systems::actions::{IActionsDispatcher, IActionsDispatcherTrait},
    };

    // Storage
    #[storage]
    struct Storage {
        last_random_seed: felt252,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    // Implementations
    #[embeddable_as(RandomSystemImpl)]
    pub impl RandomSystem<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ShipActions: ShipActionsComponent::HasComponent<TContractState>,
        impl WeaponCardActions: WeaponCardActionsComponent::HasComponent<TContractState>,
    > of super::IRandomSystem<ComponentState<TContractState>> {
        // See IRandomSystem-get_last_random_seed
        fn get_last_random_seed(self: @ComponentState<TContractState>) -> felt252 {
            self.last_random_seed.read()
        }

        // See IRandomSystem-receive_random_words
        fn receive_random_words(
            ref self: ComponentState<TContractState>,
            requester_address: ContractAddress,
            request_id: u64,
            random_words: Span<felt252>,
            calldata: Array<felt252>
        ) {
            // Call to get world address
            let world: IWorldDispatcher = IActionsDispatcher {
                contract_address: get_contract_address()
            }
                .world();

            if (!UtilTrait::is_test_mode()) {
                UtilTrait::require_vrf();
            }

            let random_seed = *random_words.at(0);
            let player_address: ContractAddress = (*calldata.at(0)).try_into().unwrap();
            let action_code = *calldata.at(1);

            if (action_code == ACTION_CODE::CLAIM_NEW_PLAYER_REWARD) {
                // Call from lower level component
                let mut ship_actions_component = get_dep_component_mut!(ref self, ShipActions);
                ship_actions_component
                    ._claim_ship(
                        world,
                        random_seed,
                        REWARD_SYSTEM::NEW_PLAYER_SHIP_REWARD_NUMBER,
                        player_address,
                    );

                // Call from lower level component
                let mut weapon_card_actions_component = get_dep_component_mut!(
                    ref self, WeaponCardActions
                );
                weapon_card_actions_component
                    ._claim_weapon_card(
                        world,
                        random_seed,
                        REWARD_SYSTEM::NEW_PLAYER_WEAPON_CARD_REWARD_NUMBER,
                        player_address,
                    );
            }

            if (action_code == ACTION_CODE::OPEN_CHEST) {
                let chest_level: u8 = (*calldata.at(2)).try_into().unwrap();
                let id: u128 = (*calldata.at(3)).try_into().unwrap();

                let chest = ChestTrait::create_chest(id, chest_level, player_address, random_seed);

                set!(world, (chest));
            }

            self.last_random_seed.write(random_seed);
        }

        // See IRandomSystem-withdraw_extra_fee_fund
        fn withdraw_extra_fee_fund(
            ref self: ComponentState<TContractState>, receiver: ContractAddress
        ) {
            // Call to get world address
            let world: IWorldDispatcher = IActionsDispatcher {
                contract_address: get_contract_address()
            }
                .world();

            UtilTrait::require_world_owner(world, get_caller_address());
            
            let eth_dispatcher = ERC20ABIDispatcher {
                contract_address: ETH_ADDRESS.try_into().unwrap()
            };
            let balance = eth_dispatcher.balance_of(get_contract_address());
            eth_dispatcher.transfer(receiver, balance);
        }
    }

    #[generate_trait]
    pub impl RandomSystemInternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn _request_randomness_from_pragma(
            ref self: ComponentState<TContractState>, calldata: Array<felt252>
        ) {
            // Fixed parameters
            let callback_address = get_contract_address();
            let callback_fee_limit = 5000000000000000; // 5 * 10^15 - 0.005
            let num_words = 1;
            let publish_delay = 0;

            // Auto generated seed
            let seed_hash: u256 = poseidon::poseidon_hash_span(
                array![
                    get_caller_address().into(),
                    get_block_number().into(),
                    get_block_timestamp().into(),
                    self.last_random_seed.read().into(),
                    '__random_seed__',
                ]
                    .span()
            )
                .into();

            let u64_max = BoundedU64::max();
            let seed: u64 = (seed_hash % u64_max.into()).try_into().unwrap();

            ERC20ABIDispatcher { contract_address: ETH_ADDRESS.try_into().unwrap() }
                .approve(
                    VRF_ADDRESS.try_into().unwrap(),
                    (callback_fee_limit + callback_fee_limit / 5).into()
                );

            // Request the randomness
            IRandomnessDispatcher { contract_address: VRF_ADDRESS.try_into().unwrap() }
                .request_random(
                    seed, callback_address, callback_fee_limit, publish_delay, num_words, calldata
                );
        }
    }
}
