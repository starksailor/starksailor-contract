// Core imports
use ecdsa::check_ecdsa_signature;
use pedersen::{PedersenTrait, HashState};
use hash::{LegacyHash, HashStateTrait, HashStateExTrait};

// Starknet imports
use starknet::ContractAddress;

// Local imports
use stark_sailor::{constants::{ADDRESS_SIGN}, messages::Errors, models::ship::Ship};

// Constants
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");
const COMBAT_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!(
        "CombatInfo(player_address:felt,combat_id:felt,ally_ships:felt*,health_ships:felt*,result:felt)"
    );

// Model
#[derive(Drop, Serde)]
#[dojo::model]
struct Combat {
    #[key]
    combat_id: u128,
    player_address: ContractAddress,
    ally_ships: Array<u128>,
    result: CombatResult,
}

// Struct
#[derive(Copy, Drop, Serde)]
struct CombatInfo {
    player_address: felt252,
    combat_id: felt252,
    ally_ships: Span<felt252>,
    health_ships: Span<felt252>,
    result: felt252
}

#[derive(Copy, Drop, Serde, PartialEq, Hash)]
struct StarknetDomain {
    name: felt252,
    version: felt252,
    chain_id: felt252
}

// Enum
#[derive(Copy, Drop, Serde, Introspect, Debug, PartialEq, Default)]
enum CombatResult {
    #[default]
    None,
    Win,
    Lose
}

// Trait
trait IStructHash<T> {
    fn hash_struct(self: @T) -> felt252;
}

trait IOffchainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

// Trait implementation
impl OffchainMessageHashCombatInfo of IOffchainMessageHash<CombatInfo> {
    fn get_message_hash(self: @CombatInfo) -> felt252 {
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

impl StructHashCombatInfo of IStructHash<CombatInfo> {
    fn hash_struct(self: @CombatInfo) -> felt252 {
        let mut hash_state = PedersenTrait::new(0);
        hash_state = hash_state.update_with(COMBAT_INFO_STRUCT_TYPE_HASH);
        hash_state = hash_state.update_with(*self.player_address);
        hash_state = hash_state.update_with(*self.combat_id);
        hash_state = hash_state.update_with(self.ally_ships.hash_struct());
        hash_state = hash_state.update_with(self.health_ships.hash_struct());
        hash_state = hash_state.update_with(*self.result);
        hash_state = hash_state.update_with(6);
        hash_state.finalize()
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
