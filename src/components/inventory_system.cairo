// Interface
#[starknet::interface]
trait IInventorySystem<TContractState> {}

// Component
#[starknet::component]
mod InventorySystemComponent {
    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Local imports
    use stark_sailor::{models::inventory::Inventory};

    // Storage
    #[storage]
    struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    // Implementations
    #[embeddable_as(InventorySystemImpl)]
    pub impl InventorySystem<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of super::IInventorySystem<ComponentState<TContractState>> {}

    #[generate_trait]
    pub impl InventorySystemInternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of InternalTrait<TContractState> {
        // Must be call by the higher level component with security check
        fn _add_item(
            ref self: ComponentState<TContractState>, world: IWorldDispatcher, item: Inventory
        ) {
            let mut item_inventory = get!(world, (item.owner, item.item_type, item.id), Inventory);
            item_inventory.amount += item.amount;
            set!(world, (item_inventory));
        }

        // Must be call by the higher level component with security check
        fn _add_items(
            ref self: ComponentState<TContractState>,
            world: IWorldDispatcher,
            items: Array<Inventory>
        ) {
            let items_len = items.len();
            let mut i = 0;
            loop {
                if (i == items_len) {
                    break;
                }

                let item = *items.at(i);
                self._add_item(world, item);

                i += 1;
            };
        }
    }
}
