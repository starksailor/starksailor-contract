use core::byte_array::ByteArrayTrait;
// Core imports
use core::fmt::{Display, Formatter, Error};

// Starknet imports
use starknet::{ContractAddress, contract_address_const, testing::set_contract_address};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use stark_sailor::{
    constants::{GAME_ID, RESOURCE_CODE},
    systems::{actions::{IActionsDispatcher, IActionsDispatcherTrait}},
    models::{
        ship::{
            Ship, ShipInfo, ShipUpgradeInfo, ShipType, ShipCategory, ShipGroup, DeactivateShipInfo
        },
        inventory::{Inventory}, player_global::{PlayerGlobal},
    },
    utils::{UtilTrait},
    tests::{setup::{setup, setup::{Systems, Context}}, store::{Store, StoreTrait},}
};

impl ShipDisplay of Display<Ship> {
    fn fmt(self: @Ship, ref f: Formatter) -> Result<(), Error> {
        let mut category: ByteArray = "Unknown";
        if (*self.category == ShipCategory::Common) {
            category = "Common";
        } else if (*self.category == ShipCategory::Rare) {
            category = "Rare";
        } else if (*self.category == ShipCategory::Epic) {
            category = "Epic";
        } else if (*self.category == ShipCategory::Legendary) {
            category = "Legendary";
        }

        let mut group: ByteArray = "Unknown";
        if (*self.group == ShipGroup::OneSailBoat) {
            group = "One Sail Boat";
        } else if (*self.group == ShipGroup::TwoSailBoat) {
            group = "Two Sail Boat";
        } else if (*self.group == ShipGroup::ThreeSailBoat) {
            group = "Three Sail Boat";
        }
        let mut str: ByteArray = format!(
            "ID: {} - Stats (Category: {}, Group: {}, Max HP: {}, HP Regen: {}, Max Stamina: {}, Max Capacity: {})\n",
            *self.id,
            category,
            group,
            *self.max_hp,
            *self.hp_regen,
            *self.max_stamina,
            *self.max_capacity,
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

#[test]
fn test_activate_ship() {
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // [Test]
    let ship_info = ShipInfo {
        id: 1,
        skin: array!['A_B_C_D', 4].span(),
        owner: context.player_address.try_into().unwrap(),
        category: 5,
        group: 3,
        max_stamina: 300,
        current_stamina: 300,
        max_capacity: 20,
        current_capacity: 20,
        max_hp: 1000,
        current_hp: 1000,
        hp_regen: 5,
        speed: 20,
        slot_weapon: 6,
        level: 1,
        description: array!['Default Ship', 12].span(),
        skill: 0,
        nonce: 1,
    };
    systems
        .actions
        .activate_ship(
            world,
            ship_info,
            2674152976601225431761278622516615546432099454157682666587231119258007770374,
            641858802766500606996814662558564176803263284822462696021881327869904197247
        );

    // [Get]
    let ship = store.get_ship(1);

    // [Check] - Ship Data
    println!("Ship: {}", ship);
}

#[test]
#[should_panic(expected: ('Ship already activated', 'ENTRYPOINT_FAILED',))]
fn test_activate_ship_already_activated() {
    let (world, systems, context) = setup::spawn_game();

    // [Test]
    let mut ship_info = ShipInfo {
        id: 1,
        skin: array!['A_B_C_D', 4].span(),
        owner: context.player_address.try_into().unwrap(),
        category: 5,
        group: 3,
        max_stamina: 300,
        current_stamina: 300,
        max_capacity: 20,
        current_capacity: 20,
        max_hp: 1000,
        current_hp: 1000,
        hp_regen: 5,
        speed: 20,
        slot_weapon: 6,
        level: 1,
        description: array!['Default Ship', 12].span(),
        skill: 0,
        nonce: 1,
    };
    systems
        .actions
        .activate_ship(
            world,
            ship_info,
            2674152976601225431761278622516615546432099454157682666587231119258007770374,
            641858802766500606996814662558564176803263284822462696021881327869904197247
        );

    ship_info.nonce = 2;
    systems
        .actions
        .activate_ship(
            world,
            ship_info,
            705263512414174124120935367563430807539660168306465818003486012625967118618,
            716019756655303353411308605539655050433311238392870104339097158603603120131
        );
}

#[test]
fn deactivate_ship() {
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // Prepare data

    let ship = Ship {
        id: 1,
        skin: "A_B_C_D",
        owner: context.player_address.try_into().unwrap(),
        ship_type: ShipType::NFT,
        category: ShipCategory::Legendary,
        group: ShipGroup::ThreeSailBoat,
        max_stamina: 300,
        current_stamina: 300,
        max_capacity: 20,
        current_capacity: 20,
        max_hp: 1000,
        current_hp: 1000,
        hp_regen: 5,
        speed: 20,
        slot_weapon: 6,
        level: 1,
        description: "Default Ship",
        skill: 0
    };

    let player_global = PlayerGlobal {
        player_address: context.player_address,
        num_ship_owned: 1,
        num_weapon_card_owned: 0,
        is_claimed_default_reward: false,
    };

    store.set_ship(ship);
    store.set_player_global(player_global);

    set_contract_address(context.player_address);

    // [Test]
    systems
        .actions
        .deactivate_ship(
            world,
            DeactivateShipInfo {
                player_address: context.player_address.into(), ship_id: 1, nonce: 2
            },
            2044745909347882727976012988510503179901371278764686584072818167437760533829,
            3311154650548329477656828910787721711748626282559942939517274454145516426880
        );

    // [Get]
    let ship = store.get_ship(1);

    // [Test] - Ship owner
    assert_eq!(ship.owner.is_non_zero(), false);
}

#[test]
fn test_upgrade_ship() {
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // Constants
    let LEVEL_INITIAL: u32 = 1;
    let COIN_INITIAL_AMOUNT: u128 = 200;
    let BOTTLE_SHIP_INITIAL_AMOUNT: u128 = 300;
    let COIN_UPGRADE_AMOUNT: u128 = 100;
    let BOTTLE_SHIP_UPGRADE_AMOUNT: u128 = 100;

    // Create a ship
    let ship = Ship {
        id: 1,
        skin: "A_B_C_D",
        owner: context.player_address.try_into().unwrap(),
        ship_type: ShipType::NFT,
        category: ShipCategory::Legendary,
        group: ShipGroup::ThreeSailBoat,
        max_stamina: 300,
        current_stamina: 300,
        max_capacity: 20,
        current_capacity: 20,
        max_hp: 1000,
        current_hp: 1000,
        hp_regen: 5,
        speed: 20,
        slot_weapon: 6,
        level: LEVEL_INITIAL,
        description: "Default Ship",
        skill: 0
    };

    // Create upgrade resource
    let ship_upgrade_coin_resource = Inventory {
        owner: context.player_address.try_into().unwrap(),
        item_type: RESOURCE_CODE::COIN,
        id: 0,
        amount: COIN_INITIAL_AMOUNT,
    };

    let ship_upgrade_bottle_resource = Inventory {
        owner: context.player_address.try_into().unwrap(),
        item_type: RESOURCE_CODE::BOTTLE_SHIP,
        id: 5, // ShipCategory::Legendary => BOTTL_SHIP_ID = 5
        amount: BOTTLE_SHIP_INITIAL_AMOUNT,
    };

    store.set_ship(ship);
    store.set_resource(ship_upgrade_coin_resource);
    store.set_resource(ship_upgrade_bottle_resource);

    // [Test]
    set_contract_address(context.player_address);
    systems
        .actions
        .upgrade_ship(
            world,
            ShipUpgradeInfo {
                player_address: context.player_address.into(),
                id: 1,
                require_coin: COIN_UPGRADE_AMOUNT.into(),
                require_bottle_ship: BOTTLE_SHIP_UPGRADE_AMOUNT.into(),
                nonce: 1
            },
            2161371356457477007825978177017089148380238705246040736276915073237895482020,
            1814097525590584550899919299927406123439861223213825966379547216663656436111
        );

    // [Get]
    let coin = store.get_resource(context.player_address, RESOURCE_CODE::COIN, 0);
    let bottle_ship = store.get_resource(context.player_address, RESOURCE_CODE::BOTTLE_SHIP, 5);
    let ship = store.get_ship(1);

    // [Check] - Resource Data
    assert_eq!(coin.amount, COIN_INITIAL_AMOUNT - COIN_UPGRADE_AMOUNT);
    assert_eq!(bottle_ship.amount, BOTTLE_SHIP_INITIAL_AMOUNT - BOTTLE_SHIP_UPGRADE_AMOUNT);

    // [Check] - Ship Data
    assert_eq!(ship.level, LEVEL_INITIAL + 1);
}

#[test]
#[should_panic(expected: ('Not enough coin', 'ENTRYPOINT_FAILED',))]
fn test_upgrade_ship_resource_not_enough() {
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // Constants
    let LEVEL_INITIAL: u32 = 1;
    let COIN_INITIAL_AMOUNT: u128 = 50;
    let BOTTLE_SHIP_INITIAL_AMOUNT: u128 = 50;
    let COIN_UPGRADE_AMOUNT: u128 = 100;
    let BOTTLE_SHIP_UPGRADE_AMOUNT: u128 = 100;

    // Create a ship
    let ship = Ship {
        id: 1,
        skin: "A_B_C_D",
        owner: context.player_address.try_into().unwrap(),
        ship_type: ShipType::NFT,
        category: ShipCategory::Legendary,
        group: ShipGroup::ThreeSailBoat,
        max_stamina: 300,
        current_stamina: 300,
        max_capacity: 20,
        current_capacity: 20,
        max_hp: 1000,
        current_hp: 1000,
        hp_regen: 5,
        speed: 20,
        slot_weapon: 6,
        level: LEVEL_INITIAL,
        description: "Default Ship",
        skill: 0
    };

    // Create upgrade resource
    let ship_upgrade_coin_resource = Inventory {
        owner: context.player_address.try_into().unwrap(),
        item_type: RESOURCE_CODE::COIN,
        id: 0,
        amount: COIN_INITIAL_AMOUNT,
    };

    let ship_upgrade_bottle_resource = Inventory {
        owner: context.player_address.try_into().unwrap(),
        item_type: RESOURCE_CODE::BOTTLE_SHIP,
        id: 5, // ShipCategory::Legendary => BOTTL_SHIP_ID = 5
        amount: BOTTLE_SHIP_INITIAL_AMOUNT,
    };

    store.set_ship(ship);
    store.set_resource(ship_upgrade_coin_resource);
    store.set_resource(ship_upgrade_bottle_resource);

    // [Test]
    set_contract_address(context.player_address);
    systems
        .actions
        .upgrade_ship(
            world,
            ShipUpgradeInfo {
                player_address: context.player_address.into(),
                id: 1,
                require_coin: COIN_UPGRADE_AMOUNT.into(),
                require_bottle_ship: BOTTLE_SHIP_UPGRADE_AMOUNT.into(),
                nonce: 1
            },
            2161371356457477007825978177017089148380238705246040736276915073237895482020,
            1814097525590584550899919299927406123439861223213825966379547216663656436111
        );
}
