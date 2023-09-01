#[system]
mod get_ready {
    use array::ArrayTrait;
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::ContractAddress;
    use starknet::info::get_block_timestamp;
    use dojo::world::Context;
    
    use fighter::components::battle::{Battle, BattleStatus};
    use fighter::components::character::Character;
    use fighter::components::ready_player::ReadyPlayer;
    use fighter::components::player_battle::PlayerBattle;
    use fighter::constants::event::BattleCreatedEvent;

    fn execute(ctx: Context, character_id: felt252, moves_hash: felt252) -> () {
        assert(moves_hash!=0, 'no moves');
        let character = get!(ctx.world, character_id, (Character));
        assert(character.character_name!=0, 'invalid character');
        let player_battle = get!(ctx.world, ctx.origin, (PlayerBattle));
        assert(player_battle.battle_id==0, 'already in battle');
        let origin: felt252 = ctx.origin.into();
        let mut ready_player = get!(ctx.world, 0, (ReadyPlayer));
        assert(ready_player.player!=origin, 'already ready');

        if(ready_player.player==0) {
            ready_player.player = origin;
            ready_player.character_id = character_id;
            ready_player.moves_hash = moves_hash;
            ready_player.ready_time = get_block_timestamp();
            set!(ctx.world, (ready_player));
        }else {
            let ready_player_contract_address = ready_player.player.try_into().unwrap();
            ready_player.player = 0;
            let battle_id = ctx.world.uuid()+1;
            set!(
                ctx.world,
                (Battle {
                    battle_id: battle_id,
                    guest_character: character_id,
                    guest_moves: 0,
                    guest_moves_hash: moves_hash,
                    guest_player: ctx.origin,
                    host_character: ready_player.character_id,
                    host_moves: 0,
                    host_moves_hash: ready_player.moves_hash,
                    host_player: ready_player_contract_address,
                    status: BattleStatus::Ready.into(),
                    expire_at: 0,
                    created_at: get_block_timestamp(),
                })
            );
            set!(ctx.world, (PlayerBattle{player: ready_player_contract_address, battle_id: battle_id}));
            set!(ctx.world, (PlayerBattle{player: ctx.origin, battle_id: battle_id}));
            set!(ctx.world, (ready_player));
            ctx.world.emit(array![BattleCreatedEvent], array![battle_id.into(), ready_player.player, ctx.origin.into()].span());
        }
        
    }
}
