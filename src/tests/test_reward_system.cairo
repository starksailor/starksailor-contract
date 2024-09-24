// Core imports
use core::fmt::{Display, Formatter, Error};

// Starknet imports
use starknet::{
    ContractAddress, contract_address_const, get_block_timestamp, testing::set_contract_address
};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use stark_sailor::{
    constants::{GAME_ID, ACTION_CODE, RESOURCE_CODE, VRF_ADDRESS},
    systems::{actions::{IActionsDispatcher, IActionsDispatcherTrait}},
    models::{ship::{Ship, ShipCategory, ShipGroup}, weapon_card::{WeaponCard, WeaponCardCategory}},
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
        let owner: felt252 = (*self.owner).into();
        let str: ByteArray = format!(
            "ID: {} - Stats (owner: {}, Category: {}, Group: {}, Max HP: {}, HP Regen: {}, Max Stamina: {}, Max Capacity: {})\n",
            *self.id,
            owner,
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

impl WeaponCardDisplay of Display<WeaponCard> {
    fn fmt(self: @WeaponCard, ref f: Formatter) -> Result<(), Error> {
        let mut category: ByteArray = "Unknown";
        if (*self.category == WeaponCardCategory::Common) {
            category = "Common";
        } else if (*self.category == WeaponCardCategory::Rare) {
            category = "Rare";
        } else if (*self.category == WeaponCardCategory::Epic) {
            category = "Epic";
        } else if (*self.category == WeaponCardCategory::Legendary) {
            category = "Legendary";
        }
        let onwer: felt252 = (*self.owner).into();
        let str: ByteArray = format!(
            "ID: {} - Stats (owner: {}, wps_id: {}, Category: {}, level: {})\n",
            *self.id,
            onwer,
            *self.wps_id,
            category,
            *self.level,
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

#[test]
fn test_claim_new_user_reward() {
    let (world, systems, context) = setup::spawn_game();
    let store = StoreTrait::new(world);

    // Prepare data
    let RANDOM_SEED: felt252 = (get_block_timestamp()).into();

    // [Test]
    set_contract_address(context.owner_address);
    systems
        .actions
        .receive_random_words(
            context.player_address,
            1,
            array![RANDOM_SEED].span(),
            array![context.player_address.into(), ACTION_CODE::CLAIM_NEW_PLAYER_REWARD]
        );

    // [Get]
    let last_random_seed = systems.actions.get_last_random_seed();
    // player get ship with id in range (1..6) + 3000
    // player get weapon card with id in range (1..20) + 3000
    let ship = store.get_ship(3001);
    let weapon_card = store.get_weapon_card(3001);

    // [Check] - Ship Data
    print!("Ship: {}", ship);

    // [Check] - Weapon Card Data
    print!("Weapon Card: {}", weapon_card);

    // [Check] - Random Seed
    assert_eq!(last_random_seed, RANDOM_SEED);
}

#[test]
#[should_panic(expected: ('Already claimed', 'ENTRYPOINT_FAILED',))]
fn test_claim_new_user_reward_already_claimed() {
    let (world, systems, context) = setup::spawn_game();

    // [Test]
    set_contract_address(context.player_address);
    systems.actions.get_new_player_reward(world);
    systems.actions.get_new_player_reward(world);
}
