-- love/battle.lua
-- Minimal battle module with a true-GBA-like damage formula implementation and demo harness.
local M = {}

local function clamp(x, a, b) if x < a then return a end if x > b then return b end return x end

-- GBA Damage formula (Gen 3): floor(((((2*Level/5+2)*Power*Atk/Def)/50)+2)*Modifier)
-- We'll emulate core pieces: level, power, atk/def, STAB, type effectiveness, random 217-255/255

local function damage(level, power, Atk, Def, stab, typeEffect)
  local base = math.floor(((2*level)/5 + 2) * power * Atk / Def / 50) + 2
  local randomFactor = (math.random(217,255) / 255)
  local modifier = stab * typeEffect * randomFactor
  local dmg = math.floor(base * modifier)
  return math.max(1, dmg)
end

function M.new_demo(species)
  local self = {t = 0}
  self.pkm1 = {name = 'TREECKO', level = 5, atk = 45, def = 35}
  self.pkm2 = {name = 'ZIGZAGOON', level = 4, atk = 30, def = 30}

  function self:update(dt) self.t = self.t + dt end
  function self:draw()
    love.graphics.setColor(1,1,1)
    love.graphics.print(string.format('%s L%d ATK %d DEF %d', self.pkm1.name, self.pkm1.level, self.pkm1.atk, self.pkm1.def), 8, 160)
    love.graphics.print(string.format('%s L%d ATK %d DEF %d', self.pkm2.name, self.pkm2.level, self.pkm2.atk, self.pkm2.def), 8, 176)
    local d = damage(self.pkm1.level, 40, self.pkm1.atk, math.max(1,self.pkm2.def), 1.5, 1.0)
    love.graphics.print('Sample damage ('..self.pkm1.name..' -> '..self.pkm2.name..'): '..tostring(d), 8, 196)
  end
  return self
end

M.damage = damage
return M
