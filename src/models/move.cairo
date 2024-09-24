// Core imports
use ecdsa::check_ecdsa_signature;
use pedersen::{PedersenTrait, HashState};
use hash::{LegacyHash, HashStateTrait, HashStateExTrait};

// Starknet imports
use starknet::ContractAddress;

// Local imports
use stark_sailor::{constants::{ADDRESS_SIGN}, messages::Errors, models::position::Position,};

// Constants
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");
const MOVE_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!("MoveInfo(player_address:felt,x:felt,y:felt,timestamp:felt,nonce:felt)");

// Model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Movement {
    #[key]
    move_id: u128,
    timestamp: u64,
    player_address: ContractAddress,
    old_position: Position,
    new_position: Position
}

// Struct
#[derive(Copy, Drop, Serde, Hash)]
struct MoveInfo {
    player_address: felt252,
    x: felt252,
    y: felt252,
    timestamp: felt252,
    nonce: felt252
}

#[derive(Copy, Drop, Serde, PartialEq, Hash)]
struct StarknetDomain {
    name: felt252,
    version: felt252,
    chain_id: felt252
}

// Trait
trait IStructHash<T> {
    fn hash_struct(self: @T) -> felt252;
}

trait IOffchainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

// Trait implementation
impl OffchainMessageHashMoveInfo of IOffchainMessageHash<MoveInfo> {
    fn get_message_hash(self: @MoveInfo) -> felt252 {
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

impl StructHashMoveInfo of IStructHash<MoveInfo> {
    fn hash_struct(self: @MoveInfo) -> felt252 {
        let mut hash_state = PedersenTrait::new(0);
        hash_state = hash_state.update_with(MOVE_INFO_STRUCT_TYPE_HASH);
        hash_state = hash_state.update_with(*self);
        hash_state = hash_state.update_with(6);
        hash_state.finalize()
    }
}
