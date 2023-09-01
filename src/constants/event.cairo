use starknet::ContractAddress;

const BattleCreatedEvent: felt252 = 0x305cdd304d210f3051f92485b7a044e27c649fbeb81891590d2e72c6b4f6524;
const BattleEndEvent: felt252 = 0x126dab2f7940ee367160a1757059221d923a2af73207dcc0d8a8e479442a0d6;
const CharacterSetupEvent: felt252 = 0x3aa75289407807769c3c22c5f03e45de550076292966f22d3fdf3ecf6092c89;

#[derive(Drop)]
struct BattleCreated {
    #[key]
    battle_id: u32,
    host_player: ContractAddress,
    guest_player: ContractAddress,
}

#[derive(Drop)]
struct BattleEnd {
    battle_id: u32,
    status: felt252,
}

#[derive(Drop)]
struct CharacterSetup {
    character_id: felt252,
    character_name: felt252,
}
