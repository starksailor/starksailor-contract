//! Store struct and component management methods

// Starknet imports
use starknet::{ContractAddress};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use stark_sailor::models::{
    game::{Game}, ship::{Ship}, nonce::{Nonce}, move::{Movement}, treasure_trip::{TreasureTrip},
    combat::{Combat}, player_global::{PlayerGlobal}, weapon_card::{WeaponCard},
    inventory::{Inventory}, chest::{Chest},
};

// Store struct
#[derive(Copy, Drop)]
struct Store {
    world: IWorldDispatcher,
}

// // Implementation of the `StoreTrait` trait for the `Store` struct
#[generate_trait]
impl StoreImpl of StoreTrait {
    #[inline(always)]
    fn new(world: IWorldDispatcher) -> Store {
        Store { world: world }
    }

    // Getters
    #[inline(always)]
    fn get_game(self: Store, game_id: u128) -> Game {
        get!(self.world, (game_id), Game)
    }

    #[inline(always)]
    fn get_treasure_trip(self: Store, player_address: ContractAddress) -> TreasureTrip {
        get!(self.world, (player_address), TreasureTrip)
    }

    #[inline(always)]
    fn get_ship(self: Store, ship_id: u128) -> Ship {
        get!(self.world, (ship_id), Ship)
    }

    #[inline(always)]
    fn get_combat(self: Store, combat_id: u128) -> Combat {
        get!(self.world, (combat_id), Combat)
    }

    #[inline(always)]
    fn get_move(self: Store, move_id: u128) -> Movement {
        get!(self.world, (move_id), Movement)
    }

    #[inline(always)]
    fn get_global_player(self: Store, player_address: ContractAddress) -> PlayerGlobal {
        get!(self.world, (player_address), PlayerGlobal)
    }

    #[inline(always)]
    fn get_nonce(self: Store, nonce: felt252) -> Nonce {
        get!(self.world, (nonce), Nonce)
    }

    #[inline(always)]
    fn get_weapon_card(self: Store, card_id: u128) -> WeaponCard {
        get!(self.world, (card_id), WeaponCard)
    }

    #[inline(always)]
    fn get_resource(
        self: Store, player_address: ContractAddress, resource_type: felt252, resource_id: u128
    ) -> Inventory {
        get!(self.world, (player_address, resource_type, resource_id), Inventory)
    }

    #[inline(always)]
    fn get_chest(self: Store, chest_id: u128) -> Chest {
        get!(self.world, (chest_id), Chest)
    }

    // Setters
    #[inline(always)]
    fn set_game(self: Store, game: Game) {
        set!(self.world, (game));
    }

    #[inline(always)]
    fn set_treasure_trip(self: Store, treasure_trip: TreasureTrip) {
        set!(self.world, (treasure_trip));
    }

    #[inline(always)]
    fn set_ship(self: Store, ship: Ship) {
        set!(self.world, (ship));
    }

    #[inline(always)]
    fn set_combat(self: Store, combat: Combat) {
        set!(self.world, (combat));
    }

    #[inline(always)]
    fn set_move(self: Store, movement: Movement) {
        set!(self.world, (movement));
    }

    #[inline(always)]
    fn set_player_global(self: Store, player_global: PlayerGlobal) {
        set!(self.world, (player_global));
    }

    #[inline(always)]
    fn set_nonce(self: Store, nonce: Nonce) {
        set!(self.world, (nonce));
    }

    #[inline(always)]
    fn set_weapon_card(self: Store, weapon_card: WeaponCard) {
        set!(self.world, (weapon_card));
    }

    #[inline(always)]
    fn set_resource(self: Store, inventory: Inventory) {
        set!(self.world, (inventory));
    }

    // Deleters
    fn delete_ship(self: Store, ship: Ship) {
        delete!(self.world, (ship));
    }
}
