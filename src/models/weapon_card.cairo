// Core imports
use core::option::OptionTrait;
use core::hash::{HashStateTrait, HashStateExTrait, Hash};
use pedersen::PedersenTrait;
use ecdsa::check_ecdsa_signature;

// Starknet imports
use starknet::{ContractAddress, get_block_number, get_block_timestamp};

// Internal imports
use stark_sailor::{constants::{ADDRESS_SIGN}, messages::Errors, utils::UtilTrait,};

// Constants
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");
const WEAPON_CARD_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!("WeaponCardInfo(id:felt,owner:felt,wps_id:felt,category:felt,level:felt,nonce:felt)");
const WEAPON_CARD_UPDATE_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!(
        "WeaponCardUpgradeInfo(player_address:felt,id:felt,require_coin:felt,require_weapon_scroll:felt,nonce:felt)"
    );

// Model
#[derive(Drop, Serde)]
#[dojo::model]
struct WeaponCard {
    #[key]
    id: u128,
    owner: ContractAddress,
    wps_id: u128,
    category: WeaponCardCategory,
    level: u32,
}

// Struct
#[derive(Copy, Drop, Serde, Hash)]
struct WeaponCardInfo {
    id: felt252,
    owner: felt252,
    wps_id: felt252,
    category: felt252,
    level: felt252,
    nonce: felt252,
}

#[derive(Copy, Drop, Serde, Hash)]
struct WeaponCardUpgradeInfo {
    player_address: felt252,
    id: felt252,
    require_coin: felt252,
    require_weapon_scroll: felt252,
    nonce: felt252,
}

#[derive(Copy, Drop, Serde, PartialEq, Hash)]
struct StarknetDomain {
    name: felt252,
    version: felt252,
    chain_id: felt252,
}

// Enum
#[derive(Copy, Drop, Serde, Introspect, Debug, PartialEq)]
enum WeaponCardCategory {
    #[default]
    None,
    Common, // 1
    Uncommon, // 2
    Rare, // 3
    Epic, // 4
    Legendary // 5
}

// Trait
trait WeaponCardTrait {
    fn generate_default_weapon_card(
        owner: ContractAddress, _id: u128, random_seed: felt252
    ) -> WeaponCard;

    fn create_weapon_card(_weapon_card: WeaponCardInfo) -> WeaponCard;

    fn generate_weapon_card_index(
        caller: ContractAddress, category: WeaponCardCategory, random_seed: felt252, id_seed: u128
    ) -> u128;
}

trait IStructHash<T> {
    fn hash_struct(self: @T) -> felt252;
}

trait IOffchainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

// Trait implementation
impl WeaponCardImpl of WeaponCardTrait {
    fn generate_weapon_card_index(
        caller: ContractAddress, category: WeaponCardCategory, random_seed: felt252, id_seed: u128
    ) -> u128 {
        let WEAPON_COMMOM: Array<u128> = array![1, 6, 21, 25];
        let WEAPON_UNCOMMOM: Array<u128> = array![
            2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 22, 23, 24, 27, 28
        ];
        let WEAPON_RARE: Array<u128> = array![
            17, 18, 19, 20, 26, 29, 30, 31, 32, 33, 34, 38, 39, 40, 41, 42, 43, 44, 45
        ];
        let WEAPON_EPIC: Array<u128> = array![35, 36, 37];
        let WEAPON_LEGENDARY: Array<u128> = array![0];

        let min_range: u32 = 1;
        let mut max_range: u32 = 1;
        let mut wps_category: u8 = 0;

        if (category == WeaponCardCategory::Common) {
            max_range = WEAPON_COMMOM.len();
            wps_category = 1_u8;
        } else if (category == WeaponCardCategory::Uncommon) {
            max_range = WEAPON_UNCOMMOM.len();
            wps_category = 2_u8;
        } else if (category == WeaponCardCategory::Rare) {
            max_range = WEAPON_RARE.len();
            wps_category = 3_u8;
        } else if (category == WeaponCardCategory::Epic) {
            max_range = WEAPON_EPIC.len();
            wps_category = 4_u8;
        } else if (category == WeaponCardCategory::Legendary) {
            max_range = WEAPON_LEGENDARY.len();
            wps_category = 5_u8;
        }

        let wps_id_seed: u256 = poseidon::poseidon_hash_span(
            array![
                caller.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                wps_category.into(),
                random_seed,
                id_seed.into(),
                '__random_wps_id__',
            ]
                .span()
        )
            .into();
        let mut wps_id_index: u32 = UtilTrait::get_u32_random_from_range(
            min_range, max_range, wps_id_seed
        );
        let mut wps_id: u128 = 0_u128;
        if (category == WeaponCardCategory::Common) {
            wps_id = *WEAPON_COMMOM.at(wps_id_index - 1_u32);
        } else if (category == WeaponCardCategory::Uncommon) {
            wps_id = *WEAPON_UNCOMMOM.at(wps_id_index - 1_u32);
        } else if (category == WeaponCardCategory::Rare) {
            wps_id = *WEAPON_RARE.at(wps_id_index - 1_u32);
        } else if (category == WeaponCardCategory::Epic) {
            wps_id = *WEAPON_EPIC.at(wps_id_index - 1_u32);
        } else if (category == WeaponCardCategory::Legendary) {
            wps_id = *WEAPON_LEGENDARY.at(wps_id_index - 1_u32);
        }

        wps_id
    }

    fn generate_default_weapon_card(
        owner: ContractAddress, _id: u128, random_seed: felt252
    ) -> WeaponCard {
        let id = 3000 + _id;

        // Random category
        let category_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__weapon_card_category__',
            ]
                .span()
        )
            .into();
        let mut category_random_index = UtilTrait::get_u128_random_from_range(1, 4, category_seed);
        let mut category = WeaponCardCategory::Common;
        if (category_random_index == 1) {
            category = WeaponCardCategory::Common;
        } else if (category_random_index == 2) {
            category = WeaponCardCategory::Uncommon;
        } else if (category_random_index == 3) {
            category = WeaponCardCategory::Rare;
        } else if (category_random_index == 4) {
            category = WeaponCardCategory::Epic;
        } else if (category_random_index == 5) {
            category = WeaponCardCategory::Legendary;
        }

        // Generate weapon card skin
        let wps_id = Self::generate_weapon_card_index(owner, category, random_seed, id);

        let level = 0;

        WeaponCard { id, owner, wps_id, category, level }
    }

    fn create_weapon_card(_weapon_card: WeaponCardInfo) -> WeaponCard {
        let mut category = WeaponCardCategory::Common;
        if (_weapon_card.category == 1) {
            category = WeaponCardCategory::Common;
        } else if (_weapon_card.category == 2) {
            category = WeaponCardCategory::Uncommon;
        } else if (_weapon_card.category == 3) {
            category = WeaponCardCategory::Rare;
        } else if (_weapon_card.category == 4) {
            category = WeaponCardCategory::Epic;
        } else if (_weapon_card.category == 5) {
            category = WeaponCardCategory::Legendary;
        }

        // Create weapon card by WeaponCardInfo
        WeaponCard {
            id: _weapon_card.id.try_into().unwrap(),
            owner: _weapon_card.owner.try_into().unwrap(),
            wps_id: _weapon_card.wps_id.try_into().unwrap(),
            category: category,
            level: _weapon_card.level.try_into().unwrap(),
        }
    }
}

impl OffchainMessageHashWeaponCardInfo of IOffchainMessageHash<WeaponCardInfo> {
    fn get_message_hash(self: @WeaponCardInfo) -> felt252 {
        let domain = StarknetDomain { name: 'StarkSailor', version: 1, chain_id: 'SN_MAIN' };
        let address_sign: ContractAddress = ADDRESS_SIGN.try_into().unwrap();
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with('StarkNet Message');
        hashState = hashState.update_with(domain.hash_struct());
        hashState = hashState.update_with(address_sign);
        hashState = hashState.update_with(self.hash_struct());
        hashState = hashState.update_with(4);
        hashState.finalize()
    }
}

impl OffchainMessageHashWeaponCardUpdateInfo of IOffchainMessageHash<WeaponCardUpgradeInfo> {
    fn get_message_hash(self: @WeaponCardUpgradeInfo) -> felt252 {
        let domain = StarknetDomain { name: 'StarkSailor', version: 1, chain_id: 'SN_MAIN' };
        let address_sign: ContractAddress = ADDRESS_SIGN.try_into().unwrap();
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with('StarkNet Message');
        hashState = hashState.update_with(domain.hash_struct());
        hashState = hashState.update_with(address_sign);
        hashState = hashState.update_with(self.hash_struct());
        hashState = hashState.update_with(4);
        hashState.finalize()
    }
}

impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
    fn hash_struct(self: @StarknetDomain) -> felt252 {
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with(STARKNET_DOMAIN_TYPE_HASH);
        hashState = hashState.update_with(*self);
        hashState = hashState.update_with(4);
        hashState.finalize()
    }
}

impl StructHashWeaponCardInfo of IStructHash<WeaponCardInfo> {
    fn hash_struct(self: @WeaponCardInfo) -> felt252 {
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with(WEAPON_CARD_INFO_STRUCT_TYPE_HASH);
        hashState = hashState.update_with(*self);
        hashState = hashState.update_with(7);
        hashState.finalize()
    }
}

impl StructHashWeaponCardUpdateInfo of IStructHash<WeaponCardUpgradeInfo> {
    fn hash_struct(self: @WeaponCardUpgradeInfo) -> felt252 {
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with(WEAPON_CARD_UPDATE_INFO_STRUCT_TYPE_HASH);
        hashState = hashState.update_with(*self);
        hashState = hashState.update_with(6);
        hashState.finalize()
    }
}
