// Starknet imports
use starknet::ContractAddress;

// Model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct PlayerGlobal {
    #[key]
    player_address: ContractAddress,
    num_ship_owned: u128,
    num_weapon_card_owned: u128,
    is_claimed_default_reward: bool,
}
