// Core imports
use ecdsa::check_ecdsa_signature;
use pedersen::{PedersenTrait, HashState};
use hash::{LegacyHash, HashStateTrait, HashStateExTrait};

// Starknet imports
use starknet::{ContractAddress, get_block_number, get_block_timestamp};

// Local imports
use stark_sailor::{
    constants::{ADDRESS_SIGN, RESOURCE_CODE},
    models::weapon_card::{WeaponCardCategory, WeaponCardTrait}, utils::UtilTrait,
};

// Constants
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");
const CHEST_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!("ChestInfo(player_address:felt,chest_level:felt,nonce:felt)");

// Model
#[derive(Drop, Serde)]
#[dojo::model]
struct Chest {
    #[key]
    id: u128,
    owner: ContractAddress,
    items: Array<ChestItem>,
    level: ChestLevel,
}

// Struct
#[derive(Copy, Drop, Serde, Introspect)]
struct ChestItem {
    item_type: felt252,
    item_id: u128,
    item_amount: u128,
}

#[derive(Copy, Drop, Serde, Hash)]
struct ChestInfo {
    player_address: felt252,
    chest_level: felt252,
    nonce: felt252,
}

#[derive(Copy, Drop, Serde, PartialEq, Hash)]
struct StarknetDomain {
    name: felt252,
    version: felt252,
    chain_id: felt252
}

// Enum
#[derive(Copy, Drop, Serde, Introspect, Debug, PartialEq, Default)]
enum ChestLevel {
    #[default]
    None,
    Free,
    Beginner,
    Pro,
    Expert,
}

// Trait
trait ChestTrait {
    fn create_chest(
        id: u128, chest_level: u8, player_address: ContractAddress, random_seed: felt252
    ) -> Chest;

    fn create_random_weapon_scrolls(
        owner: ContractAddress,
        category: WeaponCardCategory,
        min_received: u128,
        max_received: u128,
        random_number: u256
    ) -> ChestItem;

    fn create_random_coins(
        owner: ContractAddress,
        coin_id: u128,
        min_received: u128,
        max_received: u128,
        random_number: u256
    ) -> ChestItem;

    fn create_random_consumes(
        owner: ContractAddress,
        consume_id: u128,
        min_received: u128,
        max_received: u128,
        random_number: u256
    ) -> ChestItem;

    fn create_random_bottles(
        owner: ContractAddress,
        bottle_id: u128,
        min_received: u128,
        max_received: u128,
        random_number: u256
    ) -> ChestItem;
}

trait IStructHash<T> {
    fn hash_struct(self: @T) -> felt252;
}

trait IOffchainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

// Trait implementation
impl ChestImpl of ChestTrait {
    fn create_chest(
        id: u128, chest_level: u8, player_address: ContractAddress, random_seed: felt252
    ) -> Chest {
        // Decide level
        let mut level = ChestLevel::Free;
        if (chest_level == 1) {
            level = ChestLevel::Free;
        } else if (chest_level == 2) {
            level = ChestLevel::Beginner;
        } else if (chest_level == 3) {
            level = ChestLevel::Pro;
        } else if (chest_level == 4) {
            level = ChestLevel::Expert;
        }

        // Create random number by random seed
        let random_number: u256 = poseidon::poseidon_hash_span(
            array![
                player_address.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                id.into(),
                chest_level.into(),
                '__random_chest__',
            ]
                .span()
        )
            .into();

        // Randomize chest items
        let mut items: Array<ChestItem> = array![];
        if (level == ChestLevel::Free) { // Reward_Free_Open
            // random_AidKit [2;3]
            // random_Barrel [1;2]
            // random_Silver [10;15]
            let aidkits: ChestItem = Self::create_random_consumes(
                player_address.try_into().unwrap(), 1, 2, 3, random_number
            );
            let barrels: ChestItem = Self::create_random_consumes(
                player_address.try_into().unwrap(), 2, 1, 2, random_number
            );
            let silvers: ChestItem = Self::create_random_coins(
                player_address.try_into().unwrap(), 0, 10, 15, random_number
            );
            items = array![aidkits, barrels, silvers];
        } else if (level == ChestLevel::Beginner) { // Reward_Kind01
            // random_AidKit [2;3]
            // random_Barrel [1;2]
            // random_Silver [10;15]
            // random_Bottle02 [2;5]
            // random_WeaponScroll_Common [1;5]
            let aidkits: ChestItem = Self::create_random_consumes(
                player_address.try_into().unwrap(), 1, 2, 3, random_number
            );
            let barrels: ChestItem = Self::create_random_consumes(
                player_address.try_into().unwrap(), 2, 1, 2, random_number
            );
            let silvers: ChestItem = Self::create_random_coins(
                player_address.try_into().unwrap(), 0, 10, 15, random_number
            );
            let bottles: ChestItem = Self::create_random_bottles(
                player_address.try_into().unwrap(), 2, 2, 5, random_number
            );
            let weapon_scrolls_common: ChestItem = Self::create_random_weapon_scrolls(
                player_address.try_into().unwrap(), WeaponCardCategory::Common, 1, 5, random_number
            );
            items = array![aidkits, barrels, silvers, bottles, weapon_scrolls_common];
        } else if (level == ChestLevel::Pro) { // Reward_Kind02
            // + random_AidKit [3;5]
            // + random_Barrel [2;4]
            // + random_Silver [10;20]
            // + random_Bottle02 [3;6]
            // + random_WeaponScroll_Common [4;5]
            // + random_WeaponScroll_Uncommon [1;3]
            let aidkits: ChestItem = Self::create_random_consumes(
                player_address.try_into().unwrap(), 1, 3, 5, random_number
            );
            let barrels: ChestItem = Self::create_random_consumes(
                player_address.try_into().unwrap(), 2, 2, 4, random_number
            );
            let silvers: ChestItem = Self::create_random_coins(
                player_address.try_into().unwrap(), 0, 10, 20, random_number
            );
            let bottles: ChestItem = Self::create_random_bottles(
                player_address.try_into().unwrap(), 2, 3, 6, random_number
            );
            let weapon_scrolls_common: ChestItem = Self::create_random_weapon_scrolls(
                player_address.try_into().unwrap(), WeaponCardCategory::Common, 4, 5, random_number
            );
            let weapon_scrolls_uncommon: ChestItem = Self::create_random_weapon_scrolls(
                player_address.try_into().unwrap(),
                WeaponCardCategory::Uncommon,
                1,
                3,
                random_number
            );
            items =
                array![
                    aidkits,
                    barrels,
                    silvers,
                    bottles,
                    weapon_scrolls_common,
                    weapon_scrolls_uncommon
                ];
        } else if (level == ChestLevel::Expert) { // Reward_Kind03
            // + random_AidKit [5;10]
            // + random_Barrel [1;5]
            // + random_Silver [10;30]
            // + random_Bottle02 [3;6]
            // + random_WeaponScroll_Common [3;10]
            // + random_WeaponScroll_Uncommon [2;4]
            // + random_WeaponScroll_Rare [1;2]
            let aidkits: ChestItem = Self::create_random_consumes(
                player_address.try_into().unwrap(), 1, 5, 10, random_number
            );
            let barrels: ChestItem = Self::create_random_consumes(
                player_address.try_into().unwrap(), 2, 1, 5, random_number
            );
            let silvers: ChestItem = Self::create_random_coins(
                player_address.try_into().unwrap(), 0, 10, 30, random_number
            );
            let bottles: ChestItem = Self::create_random_bottles(
                player_address.try_into().unwrap(), 2, 3, 6, random_number
            );
            let weapon_scrolls_common: ChestItem = Self::create_random_weapon_scrolls(
                player_address.try_into().unwrap(), WeaponCardCategory::Common, 3, 10, random_number
            );
            let weapon_scrolls_uncommon: ChestItem = Self::create_random_weapon_scrolls(
                player_address.try_into().unwrap(),
                WeaponCardCategory::Uncommon,
                2,
                4,
                random_number
            );
            let weapon_scrolls_rare: ChestItem = Self::create_random_weapon_scrolls(
                player_address.try_into().unwrap(), WeaponCardCategory::Rare, 1, 2, random_number
            );
            items =
                array![
                    aidkits,
                    barrels,
                    silvers,
                    bottles,
                    weapon_scrolls_common,
                    weapon_scrolls_uncommon,
                    weapon_scrolls_rare
                ];
        }

        Chest { id, owner: player_address, items, level }
    }

    fn create_random_weapon_scrolls(
        owner: ContractAddress,
        category: WeaponCardCategory,
        min_received: u128,
        max_received: u128,
        random_number: u256
    ) -> ChestItem {
        let mut wps_category: u8 = 0;
        if (category == WeaponCardCategory::Common) {
            wps_category = 1_u8;
        } else if (category == WeaponCardCategory::Uncommon) {
            wps_category = 2_u8;
        } else if (category == WeaponCardCategory::Rare) {
            wps_category = 3_u8;
        } else if (category == WeaponCardCategory::Epic) {
            wps_category = 4_u8;
        } else if (category == WeaponCardCategory::Legendary) {
            wps_category = 5_u8;
        }

        let mut wps_id: u128 = WeaponCardTrait::generate_weapon_card_index(
            owner, category, random_number.try_into().unwrap(), 0
        );

        let amount_seed: u256 = poseidon::poseidon_hash_span(
            array![
                owner.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_number.try_into().unwrap(),
                wps_category.into(),
                wps_id.into(),
                '__random_wps_amount__',
            ]
                .span()
        )
            .into();

        let item_amount = UtilTrait::get_u128_random_from_range(
            min_received, max_received, amount_seed
        );

        ChestItem { item_type: RESOURCE_CODE::WEAPON_SCROLL, item_id: wps_id, item_amount }
    }

    fn create_random_coins(
        owner: ContractAddress,
        coin_id: u128,
        min_received: u128,
        max_received: u128,
        random_number: u256
    ) -> ChestItem {
        let seed: u256 = poseidon::poseidon_hash_span(
            array![
                owner.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_number.try_into().unwrap(),
                RESOURCE_CODE::COIN,
                coin_id.into(),
                '__random_coin__',
            ]
                .span()
        )
            .into();
        let item_amount = UtilTrait::get_u128_random_from_range(min_received, max_received, seed);

        ChestItem { item_type: RESOURCE_CODE::COIN, item_id: coin_id, item_amount }
    }

    fn create_random_consumes(
        owner: ContractAddress,
        consume_id: u128,
        min_received: u128,
        max_received: u128,
        random_number: u256
    ) -> ChestItem {
        let seed: u256 = poseidon::poseidon_hash_span(
            array![
                owner.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_number.try_into().unwrap(),
                RESOURCE_CODE::CONSUME,
                consume_id.into(),
                '__random_consume__',
            ]
                .span()
        )
            .into();

        let item_amount = UtilTrait::get_u128_random_from_range(min_received, max_received, seed);

        ChestItem { item_type: RESOURCE_CODE::CONSUME, item_id: consume_id, item_amount }
    }

    fn create_random_bottles(
        owner: ContractAddress,
        bottle_id: u128,
        min_received: u128,
        max_received: u128,
        random_number: u256
    ) -> ChestItem {
        let seed: u256 = poseidon::poseidon_hash_span(
            array![
                owner.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_number.try_into().unwrap(),
                RESOURCE_CODE::BOTTLE_SHIP,
                bottle_id.into(),
                '__random_bottle__',
            ]
                .span()
        )
            .into();

        let item_amount = UtilTrait::get_u128_random_from_range(min_received, max_received, seed);

        ChestItem { item_type: RESOURCE_CODE::BOTTLE_SHIP, item_id: bottle_id, item_amount }
    }
}

impl OffchainMessageHashChestInfo of IOffchainMessageHash<ChestInfo> {
    fn get_message_hash(self: @ChestInfo) -> felt252 {
        let domain = StarknetDomain { name: 'StarkSailor', version: 1, chain_id: 'SN_MAIN' };
        let address_sign: ContractAddress = ADDRESS_SIGN.try_into().unwrap();
        let mut hash_state = PedersenTrait::new(0);
        hash_state = hash_state.update_with('StarkNet Message');
        hash_state = hash_state.update_with(domain.hash_struct());
        hash_state = hash_state.update_with(address_sign);
        hash_state = hash_state.update_with(self.hash_struct());
        hash_state = hash_state.update_with(4);
        hash_state.finalize()
    }
}

impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
    fn hash_struct(self: @StarknetDomain) -> felt252 {
        let mut hash_state = PedersenTrait::new(0);
        hash_state = hash_state.update_with(STARKNET_DOMAIN_TYPE_HASH);
        hash_state = hash_state.update_with(*self);
        hash_state = hash_state.update_with(4);
        hash_state.finalize()
    }
}

impl StructHashChestInfo of IStructHash<ChestInfo> {
    fn hash_struct(self: @ChestInfo) -> felt252 {
        let mut hash_state = PedersenTrait::new(0);
        hash_state = hash_state.update_with(CHEST_INFO_STRUCT_TYPE_HASH);
        hash_state = hash_state.update_with(*self);
        hash_state = hash_state.update_with(4);
        hash_state.finalize()
    }
}
