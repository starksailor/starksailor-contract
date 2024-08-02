use stark_sailor_v11::models::ship::Ship;

#[derive(Drop, Serde)]
#[dojo::model]
struct Combat {
    #[key]
    combat_id: u128,
    ally_ships: Array<u32>,
    result: CombatResult,
}

#[derive(Copy, Drop, Serde, Introspect, Debug, PartialEq)]
enum CombatResult {
    Win,
    Lose
}