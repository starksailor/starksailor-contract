// Struct
#[derive(Copy, Drop, Serde, Introspect, PartialEq)]
struct Position {
    x: u32,
    y: u32
}