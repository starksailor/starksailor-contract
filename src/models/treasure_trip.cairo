// Core imports
use ecdsa::check_ecdsa_signature;
use pedersen::{PedersenTrait, HashState};
use hash::{LegacyHash, HashStateTrait, HashStateExTrait};

// Starknet imports
use starknet::ContractAddress;

// Local imports
use stark_sailor::{constants::{ADDRESS_SIGN}, models::position::Position,};

// Constants
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");
const TREASURE_TRIP_REWARD_INFO_STRUCT_TYPE_HASH: felt252 =
    selector!(
        "TreasureTripRewardInfo(player_address:felt,reward_items:RewardItem*,nonce:felt)RewardItem(item_type:felt,item_id:felt,item_amount:felt)"
    );
const REWARD_ITEM_STRUCT_TYPE_HASH: felt252 =
    selector!("RewardItem(item_type:felt,item_id:felt,item_amount:felt)");

// Model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct TreasureTrip {
    #[key]
    player_address: ContractAddress,
    position: Position
}

// Struct
#[derive(Copy, Drop, Serde, Hash)]
struct RewardItem {
    item_type: felt252,
    item_id: felt252,
    item_amount: felt252,
}

#[derive(Copy, Drop, Serde)]
struct TreasureTripRewardInfo {
    player_address: felt252,
    reward_items: Span<RewardItem>,
    nonce: felt252,
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
impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
    fn hash_struct(self: @StarknetDomain) -> felt252 {
        let mut hash_state = PedersenTrait::new(0);
        hash_state = hash_state.update_with(STARKNET_DOMAIN_TYPE_HASH);
        hash_state = hash_state.update_with(*self);
        hash_state = hash_state.update_with(4);
        hash_state.finalize()
    }
}

impl OffchainMessageHashTreasureTripRewardInfo of IOffchainMessageHash<TreasureTripRewardInfo> {
    fn get_message_hash(self: @TreasureTripRewardInfo) -> felt252 {
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

impl StructHashTreasureTripRewardInfo of IStructHash<TreasureTripRewardInfo> {
    fn hash_struct(self: @TreasureTripRewardInfo) -> felt252 {
        let mut hash_state = PedersenTrait::new(0);
        hash_state = hash_state.update_with(TREASURE_TRIP_REWARD_INFO_STRUCT_TYPE_HASH);
        hash_state = hash_state.update_with(*self.player_address);
        hash_state = hash_state.update_with(self.reward_items.hash_struct());
        hash_state = hash_state.update_with(*self.nonce);
        hash_state = hash_state.update_with(4);
        hash_state.finalize()
    }
}

impl StructHashSpanRewardItem of IStructHash<Span<RewardItem>> {
    fn hash_struct(self: @Span<RewardItem>) -> felt252 {
        let mut call_data_state = LegacyHash::hash(0, *self);
        call_data_state = LegacyHash::hash(call_data_state, (*self).len());
        call_data_state
    }
}

impl LegacyHashSpanRewardItem of LegacyHash<Span<RewardItem>> {
    fn hash(mut state: felt252, mut value: Span<RewardItem>) -> felt252 {
        loop {
            match value.pop_front() {
                Option::Some(item) => { state = LegacyHash::hash(state, item.hash_struct()); },
                Option::None(_) => { break state; },
            };
        }
    }
}

impl StructHashRewardItem of IStructHash<RewardItem> {
    fn hash_struct(self: @RewardItem) -> felt252 {
        let mut hash_state = PedersenTrait::new(0);
        hash_state = hash_state.update_with(REWARD_ITEM_STRUCT_TYPE_HASH);
        hash_state = hash_state.update_with(*self);
        hash_state = hash_state.update_with(4);
        hash_state.finalize()
    }
}
