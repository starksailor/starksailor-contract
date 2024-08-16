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
            let player_address = get_caller_address();
            let timestamp = get_block_timestamp();

            // Get treasure trip by player address
            let mut treasure_trip = get!(world, (player_address), TreasureTrip);

            // Get ship old position
            let old_position = treasure_trip.position;

            // Update ship position
            treasure_trip.position = Position { x: x_position, y: y_position };

            // Increase total move
            let mut game = get!(world, (GAME_ID), Game);
            game.total_move += 1;

            // Save treasure trip
            set!(world, (treasure_trip));

            // Save move
            set!(
                world,
                (Movement {
                    move_id: game.total_move,
                    timestamp: timestamp,
                    player_address: player_address,
                    old_position: old_position,
                    new_position: treasure_trip.position
                })
            );

            // Save game
            set!(world, (game));

            // Emit event
            emit!(world, (Event::MovedEvent(MovedEvent {
                move_id: game.total_move,
                player_address,
                timestamp,
                old_position,
                new_position: treasure_trip.position
            })));
        }
    }
}
