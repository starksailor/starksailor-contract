use starknet::ContractAddress;
use stark_sailor::models::{combat::CombatResult, position::Position};

#[derive(Drop, Serde, starknet::Event)]
struct CombatFinishedEvent {
    #[key]
    combat_id: u128,
    ally_ships: Array<u128>,
    result: CombatResult,
}

#[derive(Drop, Serde, starknet::Event)]
struct MovedEvent {
    #[key]
    move_id: u128,
    player_address: ContractAddress,
    timestamp: u64,
    old_position: Position,
    new_position: Position,
}
