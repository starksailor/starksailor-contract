// Component
#[starknet::component]
mod CombatActionsComponent {
    // Starknet imports
    use starknet::get_caller_address;

    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor_v1::{
        constants::game::GAME_ID,
        components::interfaces::combat::ICombatActions,
        models::{combat::{Combat, CombatResult}, game::{Game}, ship::{Ship}},
        events::CombatFinishedEvent,
        store::{Store, StoreImpl}
    };

    // Storage
    #[storage]
    struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CombatFinishedEvent: CombatFinishedEvent
    }

    #[embeddable_as(CombatImpl)]
    impl CombatTrait<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of ICombatActions<ComponentState<TContractState>> {
        fn combat(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            ally_ships: Array<u32>,
            health_ships: Array<u32>,
            result: bool
        ) {
            // Params validation
            assert(ally_ships.len() == health_ships.len(), 'error: invalid ships length');

            // Get datastore
            let store: Store = StoreImpl::new(world);

            let caller = get_caller_address();
            let ally_ships_data = @ally_ships;
            let ally_ships_num = ally_ships.len();
            let ally_ships_clone = ally_ships.clone(); // for emit event

            // Increase total combat
            let mut game = store.get_game(GAME_ID);
            game.total_combat += 1;

            // Decide result
            let mut game_result = CombatResult::Win;
            if (result == false) {
                game_result = CombatResult::Lose;
            }

            // Save ship health
            let mut i: u32 = 0;
            loop {
                if (i >= ally_ships_num) {
                    break;
                }

                // Get ship id
                let ship_id: u32 = *ally_ships_data.at(i);

                // Get ship
                let mut ship = store.get_ship(caller, ship_id);

                // Save ship health
                ship.health = *health_ships.at(i);

                // Save ship
                store.set_ship(ship);

                i = i + 1;
            };

            // Save combat
            let new_combat: Combat = Combat {
                combat_id: game.total_combat,
                ally_ships,
                result: game_result
            };
            store.set_combat(new_combat);

            // Save game
            store.set_game(game);

            // Emit event
            emit!(
                world,
                (Event::CombatFinishedEvent
                    (CombatFinishedEvent {
                        combat_id: game.total_combat,
                        ally_ships: ally_ships_clone,
                        result: game_result
                    })
                )
            );
        }
    }
}
