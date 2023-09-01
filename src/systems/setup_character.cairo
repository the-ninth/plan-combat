#[system]
mod setup_character {

    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use starknet::ContractAddress;

    use dojo::world::{Context, IWorld};

    use fighter::components::character::Character;
    use fighter::constants::event::CharacterSetupEvent;

    #[derive(Drop, starknet::Event)]
    struct CharacterSetup {
        character_id: felt252,
        character_name: felt252,
    }

    fn execute(ctx: Context, character_id: felt252, character_name: felt252) -> () {
        assert(ctx.world.is_owner(ctx.origin, 'Character'), 'only character owner');
        let mut character = get!(ctx.world, character_id, (Character));
        character.character_name = character_name;
        set!(ctx.world, (character));
        ctx.world.emit(array![CharacterSetupEvent], array![character_id, character_name].span());
    }
}
