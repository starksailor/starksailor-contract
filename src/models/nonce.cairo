// Model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Nonce {
    #[key]
    nonce: felt252,
    is_used: bool
}
