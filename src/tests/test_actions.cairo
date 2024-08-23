// Starknet imports
use starknet::{
    ContractAddress, contract_address_const,
    testing::set_contract_address
};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use stark_sailor_v1::{
    constants::game::GAME_ID,
    systems::{actions::{IActionsDispatcher, IActionsDispatcherTrait}},
    models::{combat::{CombatResult}},
    store::{Store, StoreTrait},
    tests::{setup::{setup, setup::{Systems, Context}}}
};

#[test]
fn test_spawn_game() {
    // [Setup]
    let (world, _, _) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // [Get]
    let game = store.get_game(GAME_ID);

    // [Check] - Game Data
    assert_eq!(game.total_move, 0);
    assert_eq!(game.total_combat, 0);
}

#[test]
fn test_move() {
    // [Setup]
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // [Test]
    set_contract_address(context.player_address);
    systems.actions.move(world, 30, 40);

    // [Get]
    let game = store.get_game(GAME_ID);
    let treasure_trip = store.get_treasure_trip(context.player_address);
    let move = store.get_move(1);

    // [Check] - Game Data
    assert_eq!(game.total_move, 1);
    assert_eq!(game.total_combat, 0);

    // [Check] - Move Data
    assert_eq!(move.new_position.x, 30);
    assert_eq!(move.new_position.y, 40);
    assert_eq!(move.old_position.x, 0);
    assert_eq!(move.old_position.y, 0);

    // [Check] - Treasure Trip Data
    assert_eq!(treasure_trip.position.x, 30);
    assert_eq!(treasure_trip.position.y, 40);
}

#[test]
fn test_combat() {
    // [Setup]
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // [Test]
    set_contract_address(context.player_address);
    systems.actions.combat(
        world,
        array![1, 2],
        array![90, 80],
        true
    );

    // [Get]
    let game = store.get_game(GAME_ID);
    let combat = store.get_combat(1);
    let ship_1 = store.get_ship(context.player_address, 1);
    let ship_2 = store.get_ship(context.player_address, 2);

    // [Check] - Game Data
    assert_eq!(game.total_move, 0);
    assert_eq!(game.total_combat, 1);

    // [Check]- Combat Data
    assert_eq!(combat.result, CombatResult::Win);

    // [Check] - Ship Data
    assert_eq!(ship_1.health, 90);
    assert_eq!(ship_2.health, 80);
}