use serde::Serde;
use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Character {
    #[key]
    character_id: felt252,

    character_name: felt252,
    wins: u32,
    losses: u32,
    draw: u32,
}