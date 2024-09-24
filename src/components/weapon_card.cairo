// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Local imports
use stark_sailor::models::weapon_card::{WeaponCardUpgradeInfo, WeaponCard};

// Interface
#[starknet::interface]
trait IWeaponCardActions<TContractState> {
    ///////////////////
    // Read Function //
    ///////////////////

    // Function to get weapon card
    // # Arguments
    // * world The world address
    // * weapon_card_id The weapon card id
    // # Returns
    // * The weapon card
    fn get_weapon_card(
        self: @TContractState, world: IWorldDispatcher, weapon_card_id: u128
    ) -> WeaponCard;


    ////////////////////
    // Write Function //
    ////////////////////

    // Function to update weapon card
    // # Arguments
    // * world The world address
    // * weapon_card_upgrade_info:
    //      The weapon card update info
    //      This data is signed by the player
    //      See models/weapon_card.cairo -> WeaponCardUpgradeInfo for more details.
    // * signature_r: signature r
    // * signature_s: signature s
    fn upgrade_weapon_card(
        ref self: TContractState,
        world: IWorldDispatcher,
        weapon_card_upgrade_info: WeaponCardUpgradeInfo,
        signature_r: felt252,
        signature_s: felt252
    );
}

#[starknet::component]
mod WeaponCardActionsComponent {
    // Starknet imports
    use starknet::{get_caller_address, ContractAddress,};

    // Dojo imoprts
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor::{
        messages::Errors, constants::{GAME_ID, RESOURCE_CODE},
        models::{
            weapon_card::{
                WeaponCard, WeaponCardUpgradeInfo, WeaponCardTrait,
                OffchainMessageHashWeaponCardInfo, OffchainMessageHashWeaponCardUpdateInfo,
            },
            player_global::{PlayerGlobal}, game::{Game}, inventory::{Inventory}, nonce::Nonce,
        },
        utils::UtilTrait,
    };

    // Storage
    #[storage]
    struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[embeddable_as(WeaponCardActionsImpl)]
    pub impl WeaponCardActions<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of super::IWeaponCardActions<ComponentState<TContractState>> {
        // See IWeaponCardActions-get_weapon_card
        fn get_weapon_card(
            self: @ComponentState<TContractState>, world: IWorldDispatcher, weapon_card_id: u128
        ) -> WeaponCard {
            get!(world, (weapon_card_id), WeaponCard)
        }


        // See IWeaponCardActions-upgrade_weapon_card
        fn upgrade_weapon_card(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            weapon_card_upgrade_info: WeaponCardUpgradeInfo,
            signature_r: felt252,
            signature_s: felt252
        ) {
            // Check is the game playable
            UtilTrait::require_playable();

            // Check time
            UtilTrait::require_valid_time();

            // Verify signature
            UtilTrait::require_valid_message_hash(
                weapon_card_upgrade_info.get_message_hash(), signature_r, signature_s
            );

            // Check player address
            let player_address = weapon_card_upgrade_info.player_address.try_into().unwrap();
            assert(get_caller_address() == player_address, Errors::SIGNATURE_NOT_MATCH);

            // Check nonce
            let mut nonce = get!(world, (weapon_card_upgrade_info.nonce), Nonce);
            assert(!nonce.is_used, Errors::NONCE_USED);
            nonce.is_used = true;
            set!(world, (nonce));

            // Get weapon card
            let wpc_id: u128 = weapon_card_upgrade_info.id.try_into().unwrap();
            let mut weapon_card: WeaponCard = get!(world, (wpc_id), WeaponCard);

            // Check the player has enough resources
            let mut player_silvers: Inventory = get!(
                world, (player_address, RESOURCE_CODE::COIN, 0), Inventory
            );
            let mut player_weapon_scroll: Inventory = get!(
                world, (player_address, RESOURCE_CODE::WEAPON_SCROLL, weapon_card.wps_id), Inventory
            );
            let coin_required: u128 = weapon_card_upgrade_info.require_coin.try_into().unwrap();
            let weapon_scroll_required: u128 = weapon_card_upgrade_info
                .require_weapon_scroll
                .try_into()
                .unwrap();
            assert(player_silvers.amount >= coin_required, Errors::NOT_ENOUGH_COIN);
            assert(
                player_weapon_scroll.amount >= weapon_scroll_required,
                Errors::NOT_ENOUGH_WEAPON_SCROLL
            );

            // Update weapon card level
            weapon_card.level += 1;

            // Update resources
            player_silvers.amount -= coin_required;
            player_weapon_scroll.amount -= weapon_scroll_required;

            // Save resources
            set!(world, (player_silvers));
            set!(world, (player_weapon_scroll));

            // Save weapon card
            set!(world, (weapon_card));
        }
    }

    #[generate_trait]
    pub impl WeaponCardActionsInternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of InternalTrait<TContractState> {
        // Must be call by the higher level contract with security check
        fn _claim_weapon_card(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            random_seed: felt252,
            cards_reward_number: u32,
            player_address: ContractAddress
        ) {
            // Get player
            let mut player_global: PlayerGlobal = get!(world, (player_address), PlayerGlobal);

            // Get game
            let mut game: Game = get!(world, (GAME_ID), Game);

            let mut i = 0;
            loop {
                if (i == cards_reward_number) {
                    break;
                }

                // Create card id
                game.total_default_weapon_card += 1;

                // Create and claim the card
                let weapon_card = WeaponCardTrait::generate_default_weapon_card(
                    player_address, game.total_default_weapon_card, random_seed
                );
                player_global.num_weapon_card_owned += 1;

                // Save weapon card
                set!(world, (weapon_card));

                i += 1;
            };

            // Save player
            set!(world, (player_global));

            // Save game
            set!(world, (game));
        }
    }
}
