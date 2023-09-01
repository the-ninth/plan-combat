use dojo::serde::SerdeLen;
impl BattleStatusSerdeLen of SerdeLen<BattleStatus> {
    fn len() -> u32 {
        1
    }
}