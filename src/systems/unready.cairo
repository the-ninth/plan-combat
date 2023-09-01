#[system]
mod unready {
    use traits::Into;
    use dojo::world::Context;
    
    use fighter::components::ready_player::ReadyPlayer;

    fn execute(ctx: Context) -> () {
        let origin: felt252 = ctx.origin.into();
        let mut ready_player = get!(ctx.world, 0, (ReadyPlayer));
        assert(ready_player.player==origin, 'you are not ready');

        ready_player.player = 0;
        set!(ctx.world, (ready_player));
    }
}
