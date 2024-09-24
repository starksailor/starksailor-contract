mod components {
    mod inventory_system;
    mod random_system;
    mod reward_system;
    mod ship;
    mod treasure_trip;
    mod weapon_card;
}
mod models {
    mod chest;
    mod combat;
    mod game;
    mod inventory;
    mod move;
    mod nonce;
    mod player_global;
    mod position;
    mod ship;
    mod treasure_trip;
    mod weapon_card;
}
mod systems {
    mod actions;
}
mod constants;
mod events;
mod messages;
mod utils;

#[cfg(test)]
mod tests {
    mod store;
    mod setup;
    mod test_treasure_trip;
    mod test_weapon_card;
    mod test_reward_system;
    mod test_ship;
}
