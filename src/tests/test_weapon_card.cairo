// Starknet imports
use starknet::{ContractAddress, contract_address_const, testing::set_contract_address};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use stark_sailor::{
    constants::{GAME_ID, ACTION_CODE, RESOURCE_CODE},
    systems::{actions::{IActionsDispatcher, IActionsDispatcherTrait}},
    models::{
        inventory::{Inventory},
        weapon_card::{WeaponCard, WeaponCardUpgradeInfo, WeaponCardCategory},
    },
    utils::{UtilTrait},
    tests::{setup::{setup, setup::{Systems, Context}}, store::{Store, StoreTrait},}
};

#[test]
fn test_upgrade_weapon_card() {
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // Prepare data

    let LEVEL_INITIAL: u32 = 1;
    let COIN_INITIAL_AMOUNT: u128 = 200;
    let WEAPON_SCROLL_INITIAL_AMOUNT: u128 = 300;
    let COIN_UPGRADE_AMOUNT: u128 = 100;
    let WEAPON_SCROLL_UPGRADE_AMOUNT: u128 = 200;

    // Create a weapon card
    let weapon_card = WeaponCard {
        id: 1,
        owner: context.player_address,
        wps_id: 0,
        category: WeaponCardCategory::Legendary,
        level: LEVEL_INITIAL,
    };

    // Create upgrade resource
    let weapon_card_upgrade_coin_resource = Inventory {
        owner: context.player_address.try_into().unwrap(),
        item_type: RESOURCE_CODE::COIN,
        id: 0,
        amount: COIN_INITIAL_AMOUNT,
    };

    let weapon_card_upgrade_weapon_scroll_resource = Inventory {
        owner: context.player_address.try_into().unwrap(),
        item_type: RESOURCE_CODE::WEAPON_SCROLL,
        id: 0, // weapon_card.wps_id = 0 -> WEAPON_SCROLL_ID = 0
        amount: WEAPON_SCROLL_INITIAL_AMOUNT,
    };

    store.set_weapon_card(weapon_card);
    store.set_resource(weapon_card_upgrade_coin_resource);
    store.set_resource(weapon_card_upgrade_weapon_scroll_resource);

    // [Test]
    set_contract_address(context.player_address);
    systems
        .actions
        .upgrade_weapon_card(
            world,
            WeaponCardUpgradeInfo {
                player_address: context.player_address.into(),
                id: 1,
                require_coin: COIN_UPGRADE_AMOUNT.into(),
                require_weapon_scroll: WEAPON_SCROLL_UPGRADE_AMOUNT.into(),
                nonce: 4
            },
            3247847653662209791122704086946967846177729661600386662324428930828531539941,
            3358687387499520760275142176132566359095834353294221809841438851541219824511
        );

    // [Get]
    let coin = store.get_resource(context.player_address, RESOURCE_CODE::COIN, 0);
    let weapon_scroll = store.get_resource(context.player_address, RESOURCE_CODE::WEAPON_SCROLL, 0);
    let weapon_card = store.get_weapon_card(1);

    // [Check] - Resource Data
    assert_eq!(coin.amount, COIN_INITIAL_AMOUNT - COIN_UPGRADE_AMOUNT);
    assert_eq!(weapon_scroll.amount, WEAPON_SCROLL_INITIAL_AMOUNT - WEAPON_SCROLL_UPGRADE_AMOUNT);

    // [Check] - Weapon Card Data
    assert_eq!(weapon_card.level, LEVEL_INITIAL + 1);
}

#[test]
#[should_panic(expected: ('Not enough coin', 'ENTRYPOINT_FAILED',))]
fn test_upgrade_weapon_card_resource_not_enough() {
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // Prepare data

    let LEVEL_INITIAL: u32 = 1;
    let COIN_INITIAL_AMOUNT: u128 = 50;
    let WEAPON_SCROLL_INITIAL_AMOUNT: u128 = 50;
    let COIN_UPGRADE_AMOUNT: u128 = 100;
    let WEAPON_SCROLL_UPGRADE_AMOUNT: u128 = 200;

    // Create a weapon card
    let weapon_card = WeaponCard {
        id: 1,
        owner: context.player_address,
        wps_id: 0,
        category: WeaponCardCategory::Legendary,
        level: LEVEL_INITIAL,
    };

    // Create upgrade resource
    let weapon_card_upgrade_coin_resource = Inventory {
        owner: context.player_address.try_into().unwrap(),
        item_type: RESOURCE_CODE::COIN,
        id: 0,
        amount: COIN_INITIAL_AMOUNT,
    };

    let weapon_card_upgrade_weapon_scroll_resource = Inventory {
        owner: context.player_address.try_into().unwrap(),
        item_type: RESOURCE_CODE::WEAPON_SCROLL,
        id: 0, // weapon_card.wps_id = 0 -> WEAPON_SCROLL_ID = 0
        amount: WEAPON_SCROLL_INITIAL_AMOUNT,
    };

    store.set_weapon_card(weapon_card);
    store.set_resource(weapon_card_upgrade_coin_resource);
    store.set_resource(weapon_card_upgrade_weapon_scroll_resource);

    // [Test]
    set_contract_address(context.player_address);
    systems
        .actions
        .upgrade_weapon_card(
            world,
            WeaponCardUpgradeInfo {
                player_address: context.player_address.into(),
                id: 1,
                require_coin: COIN_UPGRADE_AMOUNT.into(),
                require_weapon_scroll: WEAPON_SCROLL_UPGRADE_AMOUNT.into(),
                nonce: 4
            },
            3247847653662209791122704086946967846177729661600386662324428930828531539941,
            3358687387499520760275142176132566359095834353294221809841438851541219824511
        );
}
