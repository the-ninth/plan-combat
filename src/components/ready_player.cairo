use serde::Serde;
use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct ReadyPlayer {
    #[key]
    index: u32,

    player: felt252,
    character_id: felt252,
    moves_hash: felt252,
    ready_time: u64,
}