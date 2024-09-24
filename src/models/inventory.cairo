// Starknet imports
use starknet::{ContractAddress, get_block_number, get_block_timestamp};

// Model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Inventory {
    #[key]
    owner: ContractAddress,
    #[key]
    item_type: felt252,
    #[key]
    id: u128,
    amount: u128,
}