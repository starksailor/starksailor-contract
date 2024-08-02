// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Interface
#[starknet::interface]
trait ICombatActions<TContractState> {
    // Function to save the combat result
    // # Arguments
    // * world: The world address
    // * ally_ships: The ally ships
    // * health_ships: The health ships
    // * result: The result of the combat
    fn combat(
        ref self: TContractState,
        world: IWorldDispatcher,
        ally_ships: Array<u32>,
        health_ships: Array<u32>,
        result: bool
    );
}
