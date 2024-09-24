// Code imports
use ecdsa::check_ecdsa_signature;
use core::integer::{BoundedU128, BoundedU32, BoundedU8};

// Starknet imports
use starknet::{ContractAddress, get_block_timestamp, get_caller_address,};

// Dojo imports
use dojo::world::{world::WORLD, {IWorldDispatcher, IWorldDispatcherTrait}};

// Local imports
use stark_sailor::{messages::Errors, constants::{PUBLIC_KEY_SIGN, VRF_ADDRESS}};

trait UtilTrait {
    fn is_test_mode() -> bool;
    fn require_valid_time();
    fn require_world_owner(world: IWorldDispatcher, address: ContractAddress);
    fn require_vrf();
    fn require_playable();
    fn require_valid_message_hash(
        message_hash: felt252, signature_r: felt252, signature_s: felt252
    );
    fn get_u128_random_from_range(min: u128, max: u128, _seed: u256) -> u128;
    fn get_u32_random_from_range(min: u32, max: u32, _seed: u256) -> u32;
    fn get_u8_random_from_range(min: u8, max: u8, _seed: u256) -> u8;
    fn get_felt252_from_index(index: u32) -> felt252;
    fn build_byte_array_from_span_felt252(span_felt252: Span<felt252>) -> ByteArray;
}

impl UtilImpl of UtilTrait {
    #[inline(always)]
    fn is_test_mode() -> bool {
        false
    }

    #[inline(always)]
    fn require_vrf() {
        assert(get_caller_address() == VRF_ADDRESS.try_into().unwrap(), Errors::NOT_VRF);
    }

    #[inline(always)]
    fn require_valid_time() {
        if (!Self::is_test_mode()) {
            assert(get_block_timestamp() >= 1721890800, Errors::INVALID_TIME);
        }
    }

    #[inline(always)]
    fn require_world_owner(world: IWorldDispatcher, address: ContractAddress) {
        assert(world.is_owner(address, WORLD), Errors::NOT_WORLD_OWNER);
    }

    #[inline(always)]
    fn require_playable() {
        assert(true, Errors::GAME_NOT_PLAYABLE);
    }

    #[inline(always)]
    fn require_valid_message_hash(
        message_hash: felt252, signature_r: felt252, signature_s: felt252
    ) {
        assert(
            check_ecdsa_signature(message_hash, PUBLIC_KEY_SIGN, signature_r, signature_s),
            Errors::SIGNATURE_NOT_MATCH
        );
    }

    #[inline(always)]
    fn get_u128_random_from_range(min: u128, max: u128, _seed: u256) -> u128 {
        if (max <= min) {
            return min;
        } else {
            let u128_max = BoundedU128::max();
            let seed: u128 = (_seed % u128_max.into()).try_into().unwrap();
            let range = max - min + 1;
            let random = seed % range;
            return random + min;
        }
    }

    #[inline(always)]
    fn get_u32_random_from_range(min: u32, max: u32, _seed: u256) -> u32 {
        if (max <= min) {
            return min;
        } else {
            let u32_max = BoundedU32::max();
            let seed: u32 = (_seed % u32_max.into()).try_into().unwrap();
            let range = max - min + 1;
            let random = seed % range;
            return random + min;
        }
    }

    #[inline(always)]
    fn get_u8_random_from_range(min: u8, max: u8, _seed: u256) -> u8 {
        if (max <= min) {
            return min;
        } else {
            let u8_max = BoundedU8::max();
            let seed: u8 = (_seed % u8_max.into()).try_into().unwrap();
            let range = max - min + 1;
            let random = seed % range;
            return random + min;
        }
    }

    fn get_felt252_from_index(index: u32) -> felt252 {
        if (index <= 0 || index > 99) {
            return '00';
        }
        let array: Array<felt252> = array![
            '01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
            '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
            '21', '22', '23', '24', '25', '26', '27', '28', '29', '30',
            '31', '32', '33', '34', '35', '36', '37', '38', '39', '40',
            '41', '42', '43', '44', '45', '46', '47', '48', '49', '50',
            '51', '52', '53', '54', '55', '56', '57', '58', '59', '60',
            '61', '62', '63', '64', '65', '66', '67', '68', '69', '70',
            '71', '72', '73', '74', '75', '76', '77', '78', '79', '80',
            '81', '82', '83', '84', '85', '86', '87', '88', '89', '90',
            '91', '92', '93', '94', '95', '96', '97', '98', '99',
        ];
        *array.at(index - 1)
    }

    // This function is used to build a byte array from a string
    // since felt252 is stored max 31 characters
    // If string length is larger than 31, it will be split into multiple felt252
    // Each felt252 will be stored in a felt252 array
    // The last element of the array will store the size of the last felt252
    fn build_byte_array_from_span_felt252(span_felt252: Span<felt252>) -> ByteArray {
        let mut array_felt252: Array<felt252> = array![];
        array_felt252.append_span(span_felt252);
        let array_felt252_clone = array_felt252.clone();
        let mut byte_array: ByteArray = "";
        let sizes = array_felt252.len();
        let mut i = 0;
        loop {
            if (i == sizes - 2) {
                break;
            }
            byte_array.append_word(*array_felt252_clone.at(i), 31);
            i += 1;
        };
        let last_word = *array_felt252.at(sizes - 2);
        let last_word_size: u32 = (*array_felt252.at(sizes - 1)).try_into().unwrap();
        byte_array.append_word(last_word, last_word_size);
        byte_array
    }
}
