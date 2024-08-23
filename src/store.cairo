//! Store struct and component management methods

// Starknet imports
use starknet::{ContractAddress};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use stark_sailor_v1::models::{
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
}