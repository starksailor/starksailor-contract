// Starknet imports
use starknet::ContractAddress;

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Local imports
use stark_sailor::models::{
    move::MoveInfo, combat::CombatInfo, ship::{Ship, ShipInfo, ShipUpgradeInfo, DeactivateShipInfo},
    weapon_card::{WeaponCard, WeaponCardUpgradeInfo}, treasure_trip::TreasureTripRewardInfo,
    chest::{Chest, ChestInfo},
};

#[starknet::interface]
trait IActions<TContractState> {
    fn world(self: @TContractState) -> IWorldDispatcher;
    fn get_chest(self: @TContractState, world: IWorldDispatcher, chest_id: u128) -> Chest;
    fn get_weapon_card(
        self: @TContractState, world: IWorldDispatcher, weapon_card_id: u128
    ) -> WeaponCard;
    fn get_ship(self: @TContractState, world: IWorldDispatcher, ship_id: u128) -> Ship;
    fn get_last_random_seed(self: @TContractState) -> felt252;
    fn move(
        ref self: TContractState,
        world: IWorldDispatcher,
        move_info: MoveInfo,
        signature_r: felt252,
        signature_s: felt252
    );
    fn combat(
        ref self: TContractState,
        world: IWorldDispatcher,
        combat_info: CombatInfo,
        signature_r: felt252,
        signature_s: felt252
    );
    fn open_chest(
        ref self: TContractState,
        world: IWorldDispatcher,
        chest_info: ChestInfo,
        signature_r: felt252,
        signature_s: felt252,
    );
    fn end_treasure_trip(
        ref self: TContractState,
        world: IWorldDispatcher,
        reward_info: TreasureTripRewardInfo,
        signature_r: felt252,
        signature_s: felt252
    );
    fn upgrade_weapon_card(
        ref self: TContractState,
        world: IWorldDispatcher,
        weapon_card_upgrade_info: WeaponCardUpgradeInfo,
        signature_r: felt252,
        signature_s: felt252
    );
    fn activate_ship(
        ref self: TContractState,
        world: IWorldDispatcher,
        ship_info: ShipInfo,
        signature_r: felt252,
        signature_s: felt252
    );
    fn deactivate_ship(
        ref self: TContractState,
        world: IWorldDispatcher,
        deactivation_info: DeactivateShipInfo,
        signature_r: felt252,
        signature_s: felt252,
    );
    fn upgrade_ship(
        ref self: TContractState,
        world: IWorldDispatcher,
        ship_upgrade_info: ShipUpgradeInfo,
        signature_r: felt252,
        signature_s: felt252
    );
    fn get_new_player_reward(ref self: TContractState, world: IWorldDispatcher);
    fn receive_random_words(
        ref self: TContractState,
        requester_address: ContractAddress,
        request_id: u64,
        random_words: Span<felt252>,
        calldata: Array<felt252>
    );
    fn withdraw_extra_fee_fund(ref self: TContractState, receiver: ContractAddress);
}

#[dojo::contract]
mod actions {
    use super::{IActions, IActionsDispatcher, IActionsDispatcherTrait};
    use starknet::get_contract_address;

    // Component imports
    use stark_sailor::components::{
        ship::ShipActionsComponent, weapon_card::WeaponCardActionsComponent,
        reward_system::RewardSystemComponent, random_system::RandomSystemComponent,
        treasure_trip::TreasureTripActionsComponent, inventory_system::InventorySystemComponent,
    };

    // Components
    component!(path: ShipActionsComponent, storage: ShipStorage, event: ShipEvent);
    component!(
        path: WeaponCardActionsComponent, storage: WeaponCardStorage, event: WeaponCardEvent
    );
    component!(path: RewardSystemComponent, storage: RewardSystemStorage, event: RewardSystemEvent);
    component!(path: RandomSystemComponent, storage: RandomSystemStorage, event: RandomSystemEvent);
    component!(
        path: TreasureTripActionsComponent, storage: TreasureTripStorage, event: TreasureTripEvent
    );
    component!(
        path: InventorySystemComponent, storage: InventorySystemStorage, event: InventorySystemEvent
    );

    // Component impl
    #[abi(embed_v0)]
    impl ShipActionsImpl = ShipActionsComponent::ShipActionsImpl<ContractState>;
    #[abi(embed_v0)]
    impl WeaponCardActionsImpl =
        WeaponCardActionsComponent::WeaponCardActionsImpl<ContractState>;
    #[abi(embed_v0)]
    impl RewardSystemImpl = RewardSystemComponent::RewardSystemImpl<ContractState>;
    #[abi(embed_v0)]
    impl RandomSystemImpl = RandomSystemComponent::RandomSystemImpl<ContractState>;
    #[abi(embed_v0)]
    impl TreasureTripActionsImpl =
        TreasureTripActionsComponent::TreasureTripActionsImpl<ContractState>;
    #[abi(embed_v0)]
    impl InventorySystemImpl =
        InventorySystemComponent::InventorySystemImpl<ContractState>;

    // Storage
    #[storage]
    struct Storage {
        #[substorage(v0)]
        ShipStorage: ShipActionsComponent::Storage,
        #[substorage(v0)]
        WeaponCardStorage: WeaponCardActionsComponent::Storage,
        #[substorage(v0)]
        RewardSystemStorage: RewardSystemComponent::Storage,
        #[substorage(v0)]
        RandomSystemStorage: RandomSystemComponent::Storage,
        #[substorage(v0)]
        TreasureTripStorage: TreasureTripActionsComponent::Storage,
        #[substorage(v0)]
        InventorySystemStorage: InventorySystemComponent::Storage,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ShipEvent: ShipActionsComponent::Event,
        #[flat]
        WeaponCardEvent: WeaponCardActionsComponent::Event,
        #[flat]
        RewardSystemEvent: RewardSystemComponent::Event,
        #[flat]
        RandomSystemEvent: RandomSystemComponent::Event,
        #[flat]
        TreasureTripEvent: TreasureTripActionsComponent::Event,
        #[flat]
        InventorySystemEvent: InventorySystemComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}
}
