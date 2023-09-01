use traits::{Into, TryInto, PartialEq};
use serde::Serde;
use array::{ArrayTrait, SpanTrait};
use dojo::serde::SerdeLen;
use starknet::ContractAddress;

const WinPoints: u32 = 3;
const LossPoints: u32 = 1;
const DrawPoints: u32 = 1;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Battle {
    #[key]
    battle_id: u32,

    guest_character: felt252,
    guest_moves: felt252,
    guest_moves_hash: felt252,
    guest_player: ContractAddress,
    host_character: felt252,
    host_moves: felt252,
    host_moves_hash: felt252,
    host_player: ContractAddress,
    status: felt252,
    expire_at: u64,
    created_at: u64,
}

#[derive(Copy, Drop, Serde, PartialEq)]
enum BattleStatus {
    None: (),
    Waiting: (),
    Ready: (),
    HostWon: (),
    GuestWon: (),
    Draw: (),
}

impl BattleStatusIntoFelt252 of Into<BattleStatus, felt252> {
    fn into(self: BattleStatus) -> felt252 {
        match self {
            BattleStatus::None(_) => 0,
            BattleStatus::Waiting(_) => 1,
            BattleStatus::Ready(_) => 2,
            BattleStatus::HostWon(_) => 3,
            BattleStatus::GuestWon(_) => 4,
            BattleStatus::Draw(_) => 5,
        }
    }
}
