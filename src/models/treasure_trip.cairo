use starknet::ContractAddress;
use stark_sailor_v1::models::position::Position;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct TreasureTrip {
    #[key]
    player_address: ContractAddress,
    position: Position
}