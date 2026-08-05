-- love/battle.lua (updated: accept wild.level and attacker/defender stats)

local M = {}

local state = {
  active = false,
  player = nil,
  wild = nil,
  move = nil,
  log = {}
}

function M.start(opts)
  state.active = true
  state.player = opts.player or {hp=100, maxhp=100, name='PlayerMon'}
  state.wild = opts.wild or {id=0, hp=50, maxhp=50}
  state.move = opts.move or {id=0, name='Tackle', power=40}
  state.log = {}
  table.insert(state.log, 'Battle started (demo)')
end

function M.update(dt)
  if not state.active then return end
end

function M.draw()
  if not state.active then return end
  love.graphics.setColor(0,0,0,0.8)
  love.graphics.rectangle('fill', 60, 60, 520, 320)
  love.graphics.setColor(1,1,1)
  love.graphics.print('Battle (demo)', 70, 70)
  love.graphics.print('Player HP: '..tostring(state.player.hp)..'/'..tostring(state.player.maxhp), 70, 110)
  love.graphics.print('Wild ID: '..tostring(state.wild.id), 70, 150)
  love.graphics.print('Wild HP: '..tostring(state.wild.hp)..'/'..tostring(state.wild.maxhp), 70, 170)
  love.graphics.print('Move: '..tostring(state.move.name)..' (power '..tostring(state.move.power)..')', 70, 190)
  love.graphics.print('Press SPACE to attack (demo), ESC to end battle', 70, 220)
  for i=1, math.min(#state.log, 6) do
    love.graphics.print(state.log[#state.log - i + 1], 70, 250 + i*14)
  end
end

local function compute_damage(attacker, defender, move)
  local base_power = (move and move.power) and tonumber(move.power) or 40
  local atk = (attacker and (attacker.atk or attacker.base_atk or attacker.attack)) or 10
  local def = (defender and (defender.def or defender.base_def or defender.defense)) or 8
  atk = tonumber(atk) or 10
  def = tonumber(def) or 8
  local ratio = math.max(0.5, atk / math.max(1, def))
  local dmg = math.floor(base_power * ratio / 10) + math.random(1,3)
  if dmg < 1 then dmg = 1 end
  return dmg
end

function M.handle_key(k)
  if not state.active then return end
  if k == 'space' then
    local dmg = compute_damage(state.player, state.wild, state.move)
    state.wild.hp = math.max(0, state.wild.hp - dmg)
    table.insert(state.log, 'Player hit wild for '..dmg..' damage')
    if state.wild.hp == 0 then
      table.insert(state.log, 'Wild fainted!')
      state.active = false
    else
      local wild_move = { power = 20 }
      local wdmg = compute_damage(state.wild, state.player, wild_move)
      state.player.hp = math.max(0, state.player.hp - wdmg)
      table.insert(state.log, 'Wild hit player for '..wdmg..' damage')
      if state.player.hp == 0 then
        table.insert(state.log, 'Player fainted!')
        state.active = false
      end
    end
  elseif k == 'escape' then
    state.active = false
    table.insert(state.log, 'You ran away (demo).')
  end
end

function M.active()
  return state.active
end

return M
