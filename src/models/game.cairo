#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Game {
    #[key]
    game_id: u128,
    total_move: u128,
    total_combat: u128,
}