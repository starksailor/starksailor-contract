// Component
#[starknet::component]
mod CombatActionsComponent {
    // Starknet imports
    use starknet::get_caller_address;

    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor_v11::{
        constants::game::GAME_ID,
        components::interfaces::combat::ICombatActions,
        models::{combat::{Combat, CombatResult}, game::{Game}, ship::{Ship}}
    };

    // Storage
    #[storage]
    struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

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
            let caller = get_caller_address();
            let ally_ships_data = @ally_ships;
            let ally_ships_num = ally_ships.len();

            // Increase total combat
            let mut game = get!(world, (GAME_ID), Game);
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
                let mut ship = get!(world, (caller, ship_id), Ship);

                // Save ship health
                ship.health = *health_ships.at(i);

                // Save ship
                set!(world, (ship));

                i = i + 1;
            };

            // Save combat
            set!(
                world,
                (Combat {
                    combat_id: game.total_combat,
                    ally_ships,
                    result: game_result
                })
            );

            // Save game
            set!(world, (game));
        }
    }
}
