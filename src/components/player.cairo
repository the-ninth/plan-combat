use serde::Serde;
use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Player {
    #[key]
    player: ContractAddress,

    nickname: felt252,
    wins: u32,
    losses: u32,
    draw: u32,
    points: u32,
}