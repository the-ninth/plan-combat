#[system]
mod force_end {
    use array::ArrayTrait;
    use traits::{Into, TryInto};
    use starknet::{ContractAddress};
    use starknet::info::get_block_timestamp;
    use option::OptionTrait;
    use dojo::world::Context;
    use fighter::components::battle::{Battle, BattleStatus, WinPoints, LossPoints, DrawPoints};
    use fighter::components::player::Player;
    use fighter::components::player_battle::PlayerBattle;
    use fighter::components::character::Character;
    use fighter::components::event_reward::{EventEndTimestamp, EventReward, EventRewardTrait};
    use fighter::constants::event::BattleEndEvent;
    use fighter::math::safe_sub;

    fn execute(ctx: Context, battle_id: u32) -> () {
        let mut battle = get!(ctx.world, battle_id, (Battle));
        let block_timestamp = get_block_timestamp();
        assert(battle.status==BattleStatus::Ready.into(), 'invalid battle');
        assert(battle.host_player==ctx.origin || battle.guest_player==ctx.origin, 'invalid player');
        assert(battle.expire_at>0 && battle.expire_at<=block_timestamp, 'battle not expired');

        if battle.host_player==ctx.origin {
            assert(battle.host_moves!=0, 'no moves');
            battle.status = BattleStatus::HostWon.into();
        }else {
            assert(battle.guest_moves!=0, 'no moves');
            battle.status = BattleStatus::GuestWon.into();
        }
        set!(ctx.world, (PlayerBattle{player: battle.host_player, battle_id: 0}));
        set!(ctx.world, (PlayerBattle{player: battle.guest_player, battle_id: 0}));
        ctx.world.emit(array![BattleEndEvent], array![battle.battle_id.into(), battle.status].span());
        set!(ctx.world, (battle));

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
            guest_player.draw += 1;
            if block_timestamp < EventEndTimestamp {
                host_player.points += DrawPoints;
                guest_player.points += DrawPoints;
            }
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
    }

}
