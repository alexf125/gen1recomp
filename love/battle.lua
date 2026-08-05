-- love/battle.lua

local M = {}

local state = {
  active = false,
  player = nil,
  wild = nil
}

function M.start(opts)
  state.active = true
  state.player = opts.player or {hp=100, maxhp=100, name='PlayerMon'}
  state.wild = opts.wild or {id=0, hp=50, maxhp=50}
  state.log = {}
end

function M.update(dt)
  if not state.active then return end
  -- nothing time based for now
end

function M.draw()
  if not state.active then return end
  -- draw a simple battle box
  love.graphics.setColor(0,0,0,0.8)
  love.graphics.rectangle('fill', 60, 60, 520, 320)
  love.graphics.setColor(1,1,1)
  love.graphics.print('Battle (demo)', 70, 70)
  -- player
  love.graphics.print('Player HP: '..tostring(state.player.hp)..'/'..tostring(state.player.maxhp), 70, 110)
  -- wild
  love.graphics.print('Wild ID: '..tostring(state.wild.id), 70, 150)
  love.graphics.print('Wild HP: '..tostring(state.wild.hp)..'/'..tostring(state.wild.maxhp), 70, 170)
  love.graphics.print('Press SPACE to attack (demo), ESC to end battle', 70, 220)
  -- log
  for i=1, math.min(#state.log, 6) do
    love.graphics.print(state.log[#state.log - i + 1], 70, 250 + i*14)
  end
end

function M.handle_key(k)
  if not state.active then return end
  if k == 'space' then
    -- player attacks: simple damage 10-20
    local dmg = math.random(10,20)
    state.wild.hp = math.max(0, state.wild.hp - dmg)
    table.insert(state.log, 'Player hit wild for '..dmg..' damage')
    if state.wild.hp == 0 then
      table.insert(state.log, 'Wild fainted!')
      state.active = false
    else
      -- wild counterattack
      local wdmg = math.random(5,12)
      state.player.hp = math.max(0, state.player.hp - wdmg)
      table.insert(state.log, 'Wild hit player for '..wdmg..' damage')
      if state.player.hp == 0 then
        table.insert(state.log, 'Player fainted!')
        state.active = false
      end
    end
  elseif k == 'escape' then
    -- end battle
    state.active = false
    table.insert(state.log, 'You ran away (demo).')
  end
end

function M.active()
  return state.active
end

return M
