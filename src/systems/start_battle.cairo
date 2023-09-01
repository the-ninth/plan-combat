#[system]
mod start_battle {
    use array::ArrayTrait;
    use traits::{Into, TryInto};
    use starknet::{ContractAddress};
    use starknet::info::get_block_timestamp;
    use option::OptionTrait;
    use hash::pedersen;
    use dojo::world::{Context, IWorld};
    use fighter::components::battle::{Battle, BattleStatus, WinPoints, LossPoints, DrawPoints};
    use fighter::components::player::Player;
    use fighter::components::player_battle::PlayerBattle;
    use fighter::components::character::Character;
    use fighter::components::event_reward::{EventEndTimestamp, EventReward, EventRewardTrait};
    use fighter::constants::event::BattleEndEvent;
    use fighter::constants::move;
    use fighter::math::{safe_sub, pow_2};

    const DefenceMove: u8 = 24;
    const ExpireDuration: u64 = 600;

    fn execute(ctx: Context, battle_id: u32, moves: felt252, nonce: felt252) -> () {
        assert(moves!=0, 'no moves');
        let mut battle = get!(ctx.world, battle_id, (Battle));
        assert(battle.status==BattleStatus::Ready.into(), 'invalid battle');
        assert(battle.host_player==ctx.origin || battle.guest_player==ctx.origin, 'invalid player');
        let moves_hash = pedersen(moves, nonce);
        if battle.host_player==ctx.origin {
            assert(battle.host_moves==0, 'moves submitted');
            assert(moves_hash==battle.host_moves_hash, 'invalid moves');
            battle.host_moves = moves;
        }else {
            assert(battle.guest_moves==0, 'moves submitted');
            assert(moves_hash==battle.guest_moves_hash, 'invalid moves');
            battle.guest_moves = moves;
        }
        
        
        if battle.host_moves != 0 && battle.guest_moves != 0 {
            battle.status = battle(battle.host_moves, battle.guest_moves).into();
            battle.expire_at = 0;
            set!(ctx.world, (battle));
            set!(ctx.world, (PlayerBattle{player: battle.host_player, battle_id: 0}));
            set!(ctx.world, (PlayerBattle{player: battle.guest_player, battle_id: 0}));
            ctx.world.emit(array![BattleEndEvent], array![battle.battle_id.into(), battle.status].span());
            
            let block_timestamp = get_block_timestamp();
            let zero_address: ContractAddress = 0.try_into().unwrap();
            let (mut win_player_address, mut loss_player_address, win_character_id, loss_character_id) = if battle.status == BattleStatus::HostWon.into() {
                (battle.host_player, battle.guest_player, battle.host_character, battle.guest_character)
            }else if battle.status == BattleStatus::GuestWon.into() {
                (battle.guest_player, battle.host_player, battle.guest_character, battle.host_character)
            }else {
                (zero_address, zero_address, 0, 0)
            };
            if win_character_id != 0 {
                let mut win_player = get!(ctx.world, win_player_address, (Player));
                let mut loss_player = get!(ctx.world, loss_player_address, (Player));
                win_player.wins += 1;
                loss_player.losses += 1;
                if block_timestamp < EventEndTimestamp {
                    win_player.points += WinPoints;
                    loss_player.points = safe_sub(loss_player.points, LossPoints);
                    let key: felt252 = win_player_address.into();
                    let mut reward = get!(ctx.world, key, (EventReward));
                    let totalReward = get!(ctx.world, 0, (EventReward));
                    let (totalRewardUpdated, rewardUpdated) = reward.get_rewarded(totalReward, win_player.wins);
                    set!(ctx.world, (totalRewardUpdated));
                    set!(ctx.world, (rewardUpdated));
                }
                set!(ctx.world, (win_player));
                set!(ctx.world, (loss_player));
                if win_character_id != loss_character_id {
                    let mut win_character = get!(ctx.world, win_character_id, (Character));
                    let mut loss_character = get!(ctx.world, loss_character_id, (Character));
                    win_character.wins += 1;
                    loss_character.losses += 1;
                    set!(ctx.world, (win_character));
                    set!(ctx.world, (loss_character));
                }
            }else {
                let mut host_player = get!(ctx.world, battle.host_player, (Player));
                let mut guest_player = get!(ctx.world, battle.guest_player, (Player));
                host_player.draw += 1;
                host_player.points += DrawPoints;
                guest_player.draw += 1;
                guest_player.points += DrawPoints;
                set!(ctx.world, (host_player));
                set!(ctx.world, (guest_player));
                if battle.host_character != battle.guest_character {
                    let mut guest_character = get!(ctx.world, battle.guest_character, (Character));
                    let mut host_character = get!(ctx.world, battle.host_character, (Character));
                    guest_character.draw += 1;
                    host_character.draw += 1;
                    set!(ctx.world, (guest_character));
                    set!(ctx.world, (host_character));
                }
            }
        }else {
            battle.expire_at = get_block_timestamp() + ExpireDuration;
            set!(
                ctx.world,
                (battle)
            );
        }

    }

    fn battle(host_moves: felt252, guest_moves: felt252) -> BattleStatus {
        let mut i: u128 = 0;
        let host_moves_u256: u256 = host_moves.into();
        let guest_moves_u256: u256 = guest_moves.into();
        let mut host_stamina: u8 = 40;
        let mut host_hp: u8 = 100;
        let mut guest_stamina: u8 = 40;
        let mut guest_hp: u8 = 100;
        loop {
            if i == 10 {
                break;
            }
            let factor = pow_2((i%16)*8_u128);
            let mut host_arg = host_moves_u256.low;
            if i>15 {
                host_arg = host_moves_u256.high;
            }
            let mut host_move: u8 = ((host_arg / factor) & 0xff).try_into().unwrap();
            let (mut host_stamina_cost, mut host_priority, mut host_atk, mut host_def) = move::get_move_attrs(host_move);
            if host_stamina_cost > host_stamina {
                host_move = 0;
                host_stamina_cost = 0;
                host_atk = 0;
                host_def = 0;
            }

            let mut guest_arg = guest_moves_u256.low;
            if i>15 {
                guest_arg = guest_moves_u256.high;
            }
            let mut guest_move: u8 = ((guest_arg / factor) & 0xff).try_into().unwrap();
            let (mut guest_stamina_cost, mut guest_priority, mut guest_atk, mut guest_def) = move::get_move_attrs(guest_move);
            if guest_stamina_cost > guest_stamina {
                guest_move = 0;
                guest_stamina_cost = 0;
                guest_atk = 0;
                guest_def = 0;
            }

            if host_priority > guest_priority && host_move != DefenceMove {
                guest_atk = 0;
                guest_def = 0;
            }else if host_priority < guest_priority && guest_move != DefenceMove {
                host_atk = 0;
                host_atk = 0;
            }
            let host_dmg = safe_sub(host_atk, guest_def);
            let guest_dmg = safe_sub(guest_atk, host_def);

            host_hp = safe_sub(host_hp, guest_dmg);
            guest_hp = safe_sub(guest_hp, host_dmg);
            if host_hp==0 || guest_hp==0 {
                break;
            }
            host_stamina -= host_stamina_cost;
            guest_stamina -= guest_stamina_cost;

            i += 1;
        };
        if host_hp > guest_hp {
            return BattleStatus::HostWon;
        }else if host_hp == guest_hp {
            return BattleStatus::Draw;
        }else {
            return BattleStatus::GuestWon;
        }
    }

}

#[cfg(test)]
mod start_battle_tests {
    use super::start_battle::battle;
    use fighter::components::battle::BattleStatus;
    use traits::Into;

    #[test]
    #[available_gas(20000000)]
    fn test_battle() {
        assert(battle(0x0102030405, 0x0102030406)==BattleStatus::HostWon, 'should host win');
        assert(battle(0x10, 0x18)==BattleStatus::Draw, 'should draw 1');
        assert(battle(0x10010203040506070809, 0x18010203040506070809)==BattleStatus::Draw, 'should draw');
        assert(battle(0x171813140e0d0b01, 0x70908070605040302)==BattleStatus::HostWon, 'should host win 2')
    }

}