mod constants {
    mod game;
}
mod components {
    mod interfaces {
        mod combat;
        mod move;
    }
    mod combat;
    mod move;
}
mod models {
    mod combat;
    mod ship;
    mod move;
    mod position;
    mod game;
    mod treasure_trip;
}
mod systems {
    mod actions;
}

#[cfg(test)]
mod tests {
    mod setup;
    mod store;
    mod test_actions;
}