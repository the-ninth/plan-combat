use serde::Serde;
use starknet::ContractAddress;
use starknet::info::get_block_timestamp;
use dojo::world::Context;

const CarWins: u32 = 10;
const NoahLimit: u128 = 300000;
const CarLimit: u128 = 3000;
const NoahPerWin: u128 = 10;
const EventEndTimestamp: u64 = 1694779200;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct EventReward {
    #[key]
    player: felt252,

    noah: u128,
    car: u128,
}

trait EventRewardTrait {
    fn get_rewarded(ref self: EventReward, totalRewarded: EventReward, wins: u32) -> (EventReward, EventReward);
}

impl ImlpEventReward of EventRewardTrait {
    fn get_rewarded(ref self: EventReward, mut totalRewarded: EventReward, wins: u32) -> (EventReward, EventReward) {
        let block_timestamp = get_block_timestamp();
        if(block_timestamp > EventEndTimestamp) {
            return (totalRewarded, self);
        }
        let totalNoahAfter = totalRewarded.noah + NoahPerWin;
        if(totalNoahAfter <= NoahLimit) {
            self.noah += NoahPerWin;
            totalRewarded.noah = totalNoahAfter;
        }
        let totalCarAfter = totalRewarded.car + 1;
        if(wins==CarWins && totalCarAfter<=CarLimit && self.car==0) {
            self.car = 1;
            totalRewarded.car = totalCarAfter;
        }
        (totalRewarded, self)
    }
}