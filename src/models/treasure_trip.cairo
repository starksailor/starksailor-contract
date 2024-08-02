use starknet::ContractAddress;
use stark_sailor_v11::models::position::Position;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct TreasureTrip {
    #[key]
    player_address: ContractAddress,
    position: Position
}