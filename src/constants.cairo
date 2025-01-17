const GAME_ID: u128 = 1_u128;
const PUBLIC_KEY_SIGN: felt252 = 0x4b5e0b79d5e8e5d702062da90caa8543d4a3a15ee152675efbc0e7d9fe28346;
const ADDRESS_SIGN: felt252 = 0x01d32df1367AADa252314CC8ba9e809bF6cA69394A3B4BEbfc418F599092956b;
const ETH_ADDRESS: felt252 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;
const VRF_ADDRESS: felt252 = 0x60c69136b39319547a4df303b6b3a26fab8b2d78de90b6bd215ce82e9cb515c;

// ACTION CODES
pub mod ACTION_CODE {
    const CLAIM_NEW_PLAYER_REWARD: felt252 = 'NEW PLAYER REWARD';
    const OPEN_CHEST: felt252 = 'OPEN CHEST';
}

// REWARD
pub mod REWARD_SYSTEM {
    const NEW_PLAYER_SHIP_REWARD_NUMBER: u32 = 6;
    const NEW_PLAYER_WEAPON_CARD_REWARD_NUMBER: u32 = 20;
}

pub mod RESOURCE_CODE {
    const COIN: felt252 = 'COIN';
    const BOTTLE_SHIP: felt252 = 'BOTTLE_SHIP';
    const CONSUME: felt252 = 'CONSUME';
    const WEAPON_SCROLL: felt252 = 'WEAPON_SCROLL';
}
