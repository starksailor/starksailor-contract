use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Ship {
    #[key]
    player_address: ContractAddress,
    #[key]
    ship_id: u128,
    health: u32
}