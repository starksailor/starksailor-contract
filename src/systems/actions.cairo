use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
#[starknet::interface]
trait IActions<TContractState> {
    fn move(ref self: TContractState, world: IWorldDispatcher, x_position: u32, y_position: u32);
    fn combat(ref self: TContractState, world: IWorldDispatcher, ally_ships: Array<u32>, health_ships: Array<u32>, result: bool);
}

#[dojo::contract]
mod actions {
    // Component imports
    use stark_sailor_v11::components::{combat::CombatActionsComponent, move::MoveActionsComponent};

    // Components
    component!(path: MoveActionsComponent, storage: moves, event: MoveEvent);
    component!(path: CombatActionsComponent, storage: combats, event: CombatEvent);


    // Component impl
    #[abi(embed_v0)]
    impl MoveImpl = MoveActionsComponent::MoveImpl<ContractState>;
    #[abi(embed_v0)]
    impl CombatImpl = CombatActionsComponent::CombatImpl<ContractState>;

    // Storage
    #[storage]
    struct Storage {
        #[substorage(v0)]
        moves: MoveActionsComponent::Storage,
        #[substorage(v0)]
        combats: CombatActionsComponent::Storage
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MoveEvent: MoveActionsComponent::Event,
        #[flat]
        CombatEvent: CombatActionsComponent::Event
    }
}
