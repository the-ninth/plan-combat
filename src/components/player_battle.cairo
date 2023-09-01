use serde::Serde;
use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct PlayerBattle {
    #[key]
    player: ContractAddress,

    battle_id: u32,
}