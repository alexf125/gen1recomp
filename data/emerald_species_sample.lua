-- data/emerald_species_sample.lua
-- Small sample: the three Hoenn starters with minimal stat sets and sprite names
return {
  TREECKO = {
    id = 252,
    base = {hp=40, atk=45, def=35, spd=70, spatk=65, spdef=55},
    sprite = 'assets/starters/treecko.png',
    cry = 'audio/cries/treecko.ogg'
  },
  TORCHIC = {
    id = 255,
    base = {hp=45, atk=60, def=40, spd=45, spatk=70, spdef=50},
    sprite = 'assets/starters/torchic.png',
    cry = 'audio/cries/torchic.ogg'
  },
  MUDKIP = {
    id = 258,
    base = {hp=50, atk=70, def=50, spd=40, spatk=50, spdef=50},
    sprite = 'assets/starters/mudkip.png',
    cry = 'audio/cries/mudkip.ogg'
  }
}
