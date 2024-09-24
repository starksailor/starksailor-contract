// Core imports
use core::option::OptionTrait;
use core::hash::{LegacyHash, HashStateTrait, HashStateExTrait, Hash};
use pedersen::PedersenTrait;
use ecdsa::check_ecdsa_signature;

// Starknet imports
use starknet::{ContractAddress, get_caller_address, get_block_number, get_block_timestamp,};

// Internal imports
use stark_sailor::{constants::{ADDRESS_SIGN}, utils::UtilTrait, messages::Errors,};

// Constants
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");
const SHIP_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!(
        "ShipInfo(id:felt,skin:felt*,owner:felt,category:felt,group:felt,max_stamina:felt,current_stamina:felt,max_capacity:felt,current_capacity:felt,max_hp:felt,current_hp:felt,hp_regen:felt,speed:felt,slot_weapon:felt,level:felt,description:felt*,skill:felt,nonce:felt)"
    );
const SHIP_UPDATE_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!(
        "ShipUpgradeInfo(player_address:felt,id:felt,require_coin:felt,require_bottle_ship:felt,nonce:felt)"
    );
const DEACTIVATE_SHIP_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!("DeactivateShipInfo(player_address:felt,ship_id:felt,nonce:felt)");


// Model
#[derive(Drop, Serde)]
#[dojo::model]
struct Ship {
    #[key]
    id: u128,
    skin: ByteArray,
    owner: ContractAddress,
    ship_type: ShipType,
    category: ShipCategory,
    group: ShipGroup,
    current_stamina: u32,
    max_stamina: u32,
    max_capacity: u32,
    current_capacity: u32,
    speed: u32,
    current_hp: u32,
    hp_regen: u32,
    slot_weapon: u8,
    max_hp: u32,
    level: u32,
    description: ByteArray,
    skill: u32,
}

// Struct
#[derive(Copy, Drop, Serde)]
struct ShipInfo {
    id: felt252,
    skin: Span<felt252>,
    owner: felt252,
    category: felt252,
    group: felt252,
    max_stamina: felt252,
    current_stamina: felt252,
    max_capacity: felt252,
    current_capacity: felt252,
    max_hp: felt252,
    current_hp: felt252,
    hp_regen: felt252,
    speed: felt252,
    slot_weapon: felt252,
    level: felt252,
    description: Span<felt252>,
    skill: felt252,
    nonce: felt252,
}

#[derive(Copy, Drop, Serde, Hash)]
struct ShipUpgradeInfo {
    player_address: felt252,
    id: felt252,
    require_coin: felt252,
    require_bottle_ship: felt252,
    nonce: felt252,
}

#[derive(Copy, Drop, Serde, Hash)]
struct DeactivateShipInfo {
    player_address: felt252,
    ship_id: felt252,
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
enum ShipType {
    #[default]
    None,
    Default, // 1
    NFT, // 2
}

#[derive(Copy, Drop, Serde, Introspect, Debug, PartialEq)]
enum ShipCategory {
    #[default]
    None,
    Common, // 1
    Uncommon, // 2
    Rare, // 3
    Epic, // 4
    Legendary // 5
}

#[derive(Copy, Drop, Serde, Introspect, Debug, PartialEq)]
enum ShipGroup {
    #[default]
    None,
    OneSailBoat, // 1
    TwoSailBoat, // 2
    ThreeSailBoat, // 3
}

// Trait
trait ShipTrait {
    fn generate_default_ship(owner: ContractAddress, _id: u128, random_seed: felt252) -> Ship;

    fn create_ship(_ship: ShipInfo) -> Ship;
}

trait IStructHash<T> {
    fn hash_struct(self: @T) -> felt252;
}

trait IOffchainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

// Trait implementation
impl ShipImpl of ShipTrait {
    fn generate_default_ship(owner: ContractAddress, _id: u128, random_seed: felt252) -> Ship {
        let id = 3000 + _id;
        let category = ShipCategory::Common;
        let ship_type = ShipType::Default;
        let description = "Default ship. This ship is received when the player first logs in";

        // Random ship's group
        let group_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_group__',
            ]
                .span()
        )
            .into();
        let group_index = UtilTrait::get_u8_random_from_range(2, 3, group_seed);
        let mut group = ShipGroup::OneSailBoat;
        if (group_index == 1) {
            group = ShipGroup::OneSailBoat;
        } else if (group_index == 2) {
            group = ShipGroup::TwoSailBoat;
        } else if (group_index == 3) {
            group = ShipGroup::ThreeSailBoat;
        }

        // Create random seed for skin part
        let body_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_body_skin__',
            ]
                .span()
        )
            .into();

        let head_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_head_skin__',
            ]
                .span()
        )
            .into();

        let bow_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_bow_skin__',
            ]
                .span()
        )
            .into();

        let mizzen_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_mizzen_skin__',
            ]
                .span()
        )
            .into();

        // Build skin part
        let mut body_skin_id: u32 = 0;
        let mut head_skin_id: u32 = 0;
        let mut bow_skin_id: u32 = 0;
        let mut mizzen_skin_id: u32 = 0;
        let mut body_skin: ByteArray = "";
        let mut head_skin: ByteArray = "";
        let mut bow_skin: ByteArray = "";
        let mut mizzen_skin: ByteArray = "";
        if (group == ShipGroup::OneSailBoat) {
            body_skin_id = UtilTrait::get_u32_random_from_range(1, 2, body_seed);
            head_skin_id = UtilTrait::get_u32_random_from_range(1, 2, head_seed);
            bow_skin_id = UtilTrait::get_u32_random_from_range(1, 4, bow_seed);
            mizzen_skin_id = UtilTrait::get_u32_random_from_range(1, 1, mizzen_seed);

            body_skin = "BodyGalleon1b";
            head_skin = "HeadBodyFor1m";
            bow_skin = "BowFor1m";
            mizzen_skin = "MizzenGalleon1b";
        } else if (group == ShipGroup::TwoSailBoat) {
            body_skin_id = UtilTrait::get_u32_random_from_range(1, 2, body_seed);
            head_skin_id = UtilTrait::get_u32_random_from_range(1, 2, head_seed);
            bow_skin_id = UtilTrait::get_u32_random_from_range(1, 2, bow_seed);
            mizzen_skin_id = UtilTrait::get_u32_random_from_range(1, 2, mizzen_seed);

            body_skin = "BodyGalleon2b";
            head_skin = "HeadBodyFor2m";
            bow_skin = "BowFor2m";
            mizzen_skin = "MizzenGalleon2b";
        } else if (group == ShipGroup::ThreeSailBoat) {
            body_skin_id = UtilTrait::get_u32_random_from_range(1, 1, body_seed);
            head_skin_id = UtilTrait::get_u32_random_from_range(1, 2, head_seed);
            bow_skin_id = UtilTrait::get_u32_random_from_range(1, 4, bow_seed);
            mizzen_skin_id = UtilTrait::get_u32_random_from_range(1, 1, mizzen_seed);

            body_skin = "BodyGalleon3b";
            head_skin = "HeadBodyFor3m";
            bow_skin = "BowFor3m";
            mizzen_skin = "MizzenGalleon3b";
        }
        body_skin.append_word(UtilTrait::get_felt252_from_index(body_skin_id), 2);
        head_skin.append_word(UtilTrait::get_felt252_from_index(head_skin_id), 2);
        bow_skin.append_word(UtilTrait::get_felt252_from_index(bow_skin_id), 2);
        mizzen_skin.append_word(UtilTrait::get_felt252_from_index(mizzen_skin_id), 2);
        let skin: ByteArray = format!("{}_{}_{}_{}", body_skin, head_skin, bow_skin, mizzen_skin);

        // Create random seed for stats
        let stamina_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_stamina__',
            ]
                .span()
        )
            .into();

        let capacity_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_capacity__',
            ]
                .span()
        )
            .into();

        let speed_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_speed__',
            ]
                .span()
        )
            .into();

        let hp_regen_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_hp_regen__',
            ]
                .span()
        )
            .into();

        let hp_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_hp__',
            ]
                .span()
        )
            .into();

        let slot_weapon_seed: u256 = poseidon::poseidon_hash_span(
            array![
                id.into(),
                get_block_number().into(),
                get_block_timestamp().into(),
                random_seed,
                '__ship_slot_weapon__',
            ]
                .span()
        )
            .into();

        let mut max_stamina = 0;
        let mut max_capacity = 0;
        let mut speed = 0;
        let mut hp_regen = 0;
        let mut max_hp = 0;
        let mut slot_weapon = 0;

        // Random ship stats based on group
        if (group == ShipGroup::OneSailBoat) {
            max_stamina = UtilTrait::get_u32_random_from_range(1, 2, stamina_seed) * 10;
            max_capacity = UtilTrait::get_u32_random_from_range(2, 3, capacity_seed);
            speed = UtilTrait::get_u32_random_from_range(20, 25, speed_seed);
            max_hp = UtilTrait::get_u32_random_from_range(35, 40, hp_seed) * 10;
            hp_regen = UtilTrait::get_u32_random_from_range(3, 5, hp_regen_seed);
            slot_weapon = UtilTrait::get_u8_random_from_range(1, 2, slot_weapon_seed);
        } else if (group == ShipGroup::TwoSailBoat) {
            max_stamina = UtilTrait::get_u32_random_from_range(1, 2, stamina_seed) * 10;
            max_capacity = UtilTrait::get_u32_random_from_range(2, 3, capacity_seed);
            speed = UtilTrait::get_u32_random_from_range(20, 25, speed_seed);
            max_hp = UtilTrait::get_u32_random_from_range(35, 40, hp_seed) * 10;
            hp_regen = UtilTrait::get_u32_random_from_range(3, 5, hp_regen_seed);
            slot_weapon = UtilTrait::get_u8_random_from_range(1, 2, slot_weapon_seed);
        } else if (group == ShipGroup::ThreeSailBoat) {
            max_stamina = UtilTrait::get_u32_random_from_range(3, 5, stamina_seed) * 10;
            max_capacity = UtilTrait::get_u32_random_from_range(3, 6, capacity_seed);
            speed = UtilTrait::get_u32_random_from_range(15, 20, speed_seed);
            max_hp = UtilTrait::get_u32_random_from_range(50, 65, hp_seed);
            hp_regen = UtilTrait::get_u32_random_from_range(5, 10, hp_regen_seed);
            slot_weapon = UtilTrait::get_u8_random_from_range(2, 4, slot_weapon_seed);
        }

        let current_stamina = max_stamina;
        let current_hp = max_hp;
        let current_capacity = 0;
        let level = 1;
        let skill = 0;

        Ship {
            id,
            skin,
            owner,
            ship_type,
            category,
            group,
            current_stamina,
            max_stamina,
            current_capacity,
            max_capacity,
            speed,
            current_hp,
            hp_regen,
            slot_weapon,
            max_hp,
            level,
            description,
            skill,
        }
    }

    fn create_ship(_ship: ShipInfo) -> Ship {
        let mut category = ShipCategory::Common;
        if (_ship.category == 1) {
            category = ShipCategory::Common;
        } else if (_ship.category == 2) {
            category = ShipCategory::Uncommon;
        } else if (_ship.category == 3) {
            category = ShipCategory::Rare;
        } else if (_ship.category == 4) {
            category = ShipCategory::Epic;
        } else if (_ship.category == 5) {
            category = ShipCategory::Legendary;
        }

        let mut group = ShipGroup::OneSailBoat;
        if (_ship.group == 1) {
            group = ShipGroup::OneSailBoat;
        } else if (_ship.group == 2) {
            group = ShipGroup::TwoSailBoat;
        } else if (_ship.group == 3) {
            group = ShipGroup::ThreeSailBoat;
        }

        Ship {
            id: _ship.id.try_into().unwrap(),
            skin: UtilTrait::build_byte_array_from_span_felt252(_ship.skin),
            owner: _ship.owner.try_into().unwrap(),
            ship_type: ShipType::NFT,
            category,
            group,
            current_stamina: _ship.current_stamina.try_into().unwrap(),
            max_stamina: _ship.max_stamina.try_into().unwrap(),
            max_capacity: _ship.max_capacity.try_into().unwrap(),
            current_capacity: _ship.current_capacity.try_into().unwrap(),
            speed: _ship.speed.try_into().unwrap(),
            current_hp: _ship.current_hp.try_into().unwrap(),
            hp_regen: _ship.hp_regen.try_into().unwrap(),
            slot_weapon: _ship.slot_weapon.try_into().unwrap(),
            max_hp: _ship.max_hp.try_into().unwrap(),
            level: _ship.level.try_into().unwrap(),
            description: UtilTrait::build_byte_array_from_span_felt252(_ship.description),
            skill: _ship.skill.try_into().unwrap(),
        }
    }
}

impl OffchainMessageHashShipInfo of IOffchainMessageHash<ShipInfo> {
    fn get_message_hash(self: @ShipInfo) -> felt252 {
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

impl OffchainMessageHashShipUpdateInfo of IOffchainMessageHash<ShipUpgradeInfo> {
    fn get_message_hash(self: @ShipUpgradeInfo) -> felt252 {
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

impl OffchainMessageHashDeactivateShipInfo of IOffchainMessageHash<DeactivateShipInfo> {
    fn get_message_hash(self: @DeactivateShipInfo) -> felt252 {
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

impl StructHashShipInfo of IStructHash<ShipInfo> {
    fn hash_struct(self: @ShipInfo) -> felt252 {
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with(SHIP_INFO_STRUCT_TYPE_HASH);
        hashState = hashState.update_with(*self.id);
        hashState = hashState.update_with(self.skin.hash_struct());
        hashState = hashState.update_with(*self.owner);
        hashState = hashState.update_with(*self.category);
        hashState = hashState.update_with(*self.group);
        hashState = hashState.update_with(*self.max_stamina);
        hashState = hashState.update_with(*self.current_stamina);
        hashState = hashState.update_with(*self.max_capacity);
        hashState = hashState.update_with(*self.current_capacity);
        hashState = hashState.update_with(*self.max_hp);
        hashState = hashState.update_with(*self.current_hp);
        hashState = hashState.update_with(*self.hp_regen);
        hashState = hashState.update_with(*self.speed);
        hashState = hashState.update_with(*self.slot_weapon);
        hashState = hashState.update_with(*self.level);
        hashState = hashState.update_with(self.description.hash_struct());
        hashState = hashState.update_with(*self.skill);
        hashState = hashState.update_with(*self.nonce);
        hashState = hashState.update_with(19);
        hashState.finalize()
    }
}

impl StructHashShipUpdateInfo of IStructHash<ShipUpgradeInfo> {
    fn hash_struct(self: @ShipUpgradeInfo) -> felt252 {
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with(SHIP_UPDATE_INFO_STRUCT_TYPE_HASH);
        hashState = hashState.update_with(*self);
        hashState = hashState.update_with(6);
        hashState.finalize()
    }
}

impl StructHashDeactivateShipInfo of IStructHash<DeactivateShipInfo> {
    fn hash_struct(self: @DeactivateShipInfo) -> felt252 {
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with(DEACTIVATE_SHIP_INFO_STRUCT_TYPE_HASH);
        hashState = hashState.update_with(*self);
        hashState = hashState.update_with(4);
        hashState.finalize()
    }
}

impl StructHashSpanFelt252 of IStructHash<Span<felt252>> {
    fn hash_struct(self: @Span<felt252>) -> felt252 {
        let mut call_data_state = LegacyHash::hash(0, *self);
        call_data_state = LegacyHash::hash(call_data_state, (*self).len());
        call_data_state
    }
}

impl LegacyHashSpanFelt252 of LegacyHash<Span<felt252>> {
    fn hash(mut state: felt252, mut value: Span<felt252>) -> felt252 {
        loop {
            match value.pop_front() {
                Option::Some(item) => { state = LegacyHash::hash(state, *item); },
                Option::None(_) => { break state; },
            };
        }
    }
}
