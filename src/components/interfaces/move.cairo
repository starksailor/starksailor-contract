// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Interface
#[starknet::interface]
trait IMoveActions<TContractState> {
    // Function save the new position of the player on map
    // # Arguments
    // * world: The world address
    // * x_position: The x position
    // * y_position: The y position
    fn move(ref self: TContractState, world: IWorldDispatcher, x_position: u32, y_position: u32);
}
