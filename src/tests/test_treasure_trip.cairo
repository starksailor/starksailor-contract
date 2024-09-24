// Core imports
use core::fmt::{Display, Formatter, Error};

// Starknet imports
use starknet::{
    get_block_timestamp, ContractAddress, contract_address_const, testing::set_contract_address
};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use stark_sailor::{
    constants::{GAME_ID, ACTION_CODE, RESOURCE_CODE},
    systems::{actions::{IActionsDispatcher, IActionsDispatcherTrait}},
    models::{
        move::{MoveInfo}, combat::{CombatResult, CombatInfo},
        treasure_trip::{TreasureTripRewardInfo, RewardItem},
        ship::{Ship, ShipInfo, ShipUpgradeInfo, ShipType, ShipCategory, ShipGroup}, chest::{Chest, ChestLevel},
    },
    tests::{setup::{setup, setup::{Systems, Context}}, store::{Store, StoreTrait},}
};

impl ChestDisplay of Display<Chest> {
    fn fmt(self: @Chest, ref f: Formatter) -> Result<(), Error> {
        let owner: felt252 = (*self.owner).into();
        let mut level: u8 = 1;
        if(*self.level == ChestLevel::Free) {
            level = 1;
        } else if(*self.level == ChestLevel::Beginner) {
            level = 2;
        } else if(*self.level == ChestLevel::Pro) {
            level = 3;
        } else if(*self.level == ChestLevel::Expert) {
            level = 4;
        }
        let mut str: ByteArray = format!(
            "ID: {}, onwer: {}, level: {}\n", *self.id, owner, level
        );
        let mut i = 0;
        let len = self.items.len();
        loop {
            if (i == len) {
                break;
            }
            let item = *self.items.at(i);
            let bytes: ByteArray = format!(
                "Type: {}, ID: {}, Amount: {}\n", item.item_type, item.item_id, item.item_amount
            );
            str.append(@bytes);
            i += 1;
        };

        f.buffer.append(@str);
        Result::Ok(())
    }
}

#[test]
fn test_move() {
    // [Setup]
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // Prepare data
    let TARGET_X: u32 = 1;
    let TARGET_Y: u32 = 2;

    // [Test]
    set_contract_address(context.player_address);
    systems
        .actions
        .move(
            world,
            MoveInfo {
                player_address: context.player_address.into(),
                x: TARGET_X.into(),
                y: TARGET_Y.into(),
                timestamp: 1726641432,
                nonce: 3
            },
            2826816094476334228768835361572533759616263267197445030051712842352472437457,
            2797315108477163723207638883412067272350081218485129191573878939999118445381
        );

    // [Get]
    let game = store.get_game(GAME_ID);
    let treasure_trip = store.get_treasure_trip(context.player_address);
    let move = store.get_move(1);

    // [Check] - Game Data
    assert_eq!(game.total_move, 1);
    assert_eq!(game.total_combat, 0);

    // [Check] - Move Data
    assert_eq!(move.new_position.x, TARGET_X);
    assert_eq!(move.new_position.y, TARGET_Y);
    assert_eq!(move.old_position.x, 0);
    assert_eq!(move.old_position.y, 0);

    // [Check] - Treasure Trip Data
    assert_eq!(treasure_trip.position.x, TARGET_X);
    assert_eq!(treasure_trip.position.y, TARGET_Y);
}

#[test]
fn test_open_chest() {
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // Prepare data
    let RANDOM_SEED: felt252 = (get_block_timestamp()).into();
    let CHEST_ID: u128 = 1;

    // [Test]
    set_contract_address(context.another_player_address);
    systems
        .actions
        .receive_random_words(
            context.player_address,
            1,
            array![RANDOM_SEED,].span(),
            array![
                context.another_player_address.into(),
                ACTION_CODE::OPEN_CHEST,
                2, // chest level
                CHEST_ID.into(),
            ]
        );

    // [Get]
    let last_random_seed = systems.actions.get_last_random_seed();
    let chest = store.get_chest(CHEST_ID);

    // [Check] - Chest Data
    println!("Chest: {}", chest);

    // [Check] - Random Seed
    assert_eq!(last_random_seed, RANDOM_SEED);
}

