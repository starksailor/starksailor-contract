//! Store struct and component management methods

// Starknet imports
use starknet::{ContractAddress};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use stark_sailor_v11::models::{
    game::{Game}, ship::{Ship}, move::{Movement}, treasure_trip::{TreasureTrip}, combat::{Combat},
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

    #[inline(always)]
    fn get_game(self: Store, game_id: u128) -> Game {
        get!(self.world, (game_id), Game)
    }

    #[inline(always)]
    fn get_treasure_trip(self: Store, player_address: ContractAddress) -> TreasureTrip {
        get!(self.world, (player_address), TreasureTrip)
    }

    #[inline(always)]
    fn get_ship(self: Store, player_address: ContractAddress, ship_id: u32) -> Ship {
        get!(self.world, (player_address, ship_id), Ship)
    }

    #[inline(always)]
    fn get_combat(self: Store, combat_id: u32) -> Combat {
        get!(self.world, (combat_id), Combat)
    }

    #[inline(always)]
    fn get_move(self: Store, move_id: u32) -> Movement {
        get!(self.world, (move_id), Movement)
    }
}