// Component
#[starknet::component]
mod MoveActionsComponent {
    // Starknet imports
    use starknet::{get_block_timestamp, get_caller_address, ContractAddress};

    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor_v1::{
        constants::game::GAME_ID,
        components::interfaces::move::IMoveActions,
        models::{treasure_trip::{TreasureTrip}, game::{Game}, position::{Position}, move::{Movement}},
        events::MovedEvent,
        store::{Store, StoreImpl}
    };

    // Storage
    #[storage]
    struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MovedEvent: MovedEvent
    }

    #[embeddable_as(MoveImpl)]
    impl MoveTrait<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of IMoveActions<ComponentState<TContractState>> {
        fn move(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            x_position: u32,
            y_position: u32
        ) {
            // Params validation
            assert(x_position >= 0 && y_position >= 0, 'error: invalid position');

            // Get datastore
            let store: Store = StoreImpl::new(world);
            
            let player_address = get_caller_address();
            let timestamp = get_block_timestamp();

            // Get treasure trip by player address
            let mut treasure_trip = store.get_treasure_trip(player_address);

            // Get ship old position
            let old_position = treasure_trip.position;

            // Update ship position
            treasure_trip.position = Position { x: x_position, y: y_position };

            // Increase total move
            let mut game = store.get_game(GAME_ID);
            game.total_move += 1;

            // Save treasure trip
            store.set_treasure_trip(treasure_trip);

            // Save move
            let new_movement: Movement = Movement {
                move_id: game.total_move,
                timestamp,
                player_address,
                old_position,
                new_position: treasure_trip.position
            };
            store.set_move(new_movement);

            // Save game
            store.set_game(game);

            // Emit event
            emit!(
                world, 
                (Event::MovedEvent
                    (MovedEvent {
                        move_id: game.total_move,
                        player_address,
                        timestamp,
                        old_position,
                        new_position: treasure_trip.position
                    })
                )
            );
        }
    }
}
