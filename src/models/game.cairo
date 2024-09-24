// Model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Game {
    #[key]
    game_id: u128,
    total_default_ship: u128,
    total_default_weapon_card: u128,
    total_chest_opened: u128,
    total_move: u128,
    total_combat: u128,
}
