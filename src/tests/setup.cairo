mod setup {
    // Startnet imports
    use starknet::{
        ContractAddress, contract_address_const,
        testing::{
            set_account_contract_address, set_contract_address
        }
    };

    // Dojo imports
    use dojo::{
        world::{IWorldDispatcher, IWorldDispatcherTrait},
        test_utils::{spawn_test_world, deploy_contract}
    };

    // Internal imports
    use stark_sailor_v1::{
        systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait},
        models::{
            game::{Game, game},
            ship::{Ship, ship},
            move::{Movement, movement},
            treasure_trip::{TreasureTrip, treasure_trip},
            combat::{Combat, combat},
        },
    };

    // Constants
    fn OWNER() -> ContractAddress {
        contract_address_const::<'OWNER'>()
    }

    fn PLAYER() -> ContractAddress {
        contract_address_const::<'PLAYER'>()
    }

    #[derive(Drop)]
    struct Systems {
        actions: IActionsDispatcher
    }

    #[derive(Drop)]
    struct Context {
        owner_address: ContractAddress,
        player_address: ContractAddress
    }

    #[inline(always)]
    fn spawn_game() -> (IWorldDispatcher, Systems, Context) {
        // Define models
        let mut models = array![
            game::TEST_CLASS_HASH,
            ship::TEST_CLASS_HASH,
            movement::TEST_CLASS_HASH,
            treasure_trip::TEST_CLASS_HASH,
            combat::TEST_CLASS_HASH
        ];

        // [Setup] World
        set_account_contract_address(OWNER());
        let world = spawn_test_world(models);

        // [Setup] Systems
        let actions_address = world.deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let systems = Systems { actions: IActionsDispatcher { contract_address: actions_address }};

        // [Setup] Context
        let context = Context { owner_address: OWNER(), player_address: PLAYER() };

        // [Return]
        (world, systems, context)
    }
}