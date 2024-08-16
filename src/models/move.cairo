use starknet::ContractAddress;
use stark_sailor_v1::models::position::Position;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Movement {
    #[key]
    move_id: u128,
    timestamp: u64,
    player_address: ContractAddress,
    old_position: Position,
    new_position: Position
}