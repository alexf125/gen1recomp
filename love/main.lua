-- love/main.lua (updated: choose wild from encounter_table or named starters [Mudkip,Treecko,Torchic])
local json = require('json') or require('dkjson')
local map_renderer = require('map_renderer')
local species_viewer = require('species_viewer')
local ui_map_browser = require('ui_map_browser')
local battle = require('battle')

local assets = {}
local state = {}
local speciesJson = nil
local tiles_meta = nil
local movesJson = nil

local mapList = {}
local selectedMapIndex = 1
local selectedMapName = nil

local MAP_OX = 320
local MAP_OY = 40

-- player
local player = { x = 0, y = 0 }
local playerSprite = nil

local encounter = nil
local inEncounter = false

local starters_preferred = { 'mudkip', 'treecko', 'torchic', 'treek' }

local function load_player_sprite()
  if love.filesystem.getInfo('build/assets/player.png') then
    playerSprite = love.graphics.newImage('build/assets/player.png')
  else
    playerSprite = nil
  end
end

local function is_blocked(tx, ty)
  if not state.map then return true end
  local coll = state.map.collision
  if not coll then return false end
  if ty < 1 or ty > #coll or tx < 1 or tx > #coll[1] then return true end
  return coll[ty][tx] == 1
end

local function try_move(dx, dy)
  local nx = math.floor(player.x + dx)
  local ny = math.floor(player.y + dy)
  local cx = nx + 1
  local cy = ny + 1
  if is_blocked(cx, cy) then
    return false
  end
  player.x = nx
  player.y = ny
  return true
end

local function find_species_by_name(name)
  if not speciesJson or not speciesJson.species then return nil end
  local target = name:lower()
  for _,s in ipairs(speciesJson.species) do
    for k,v in pairs(s) do
      if type(v) == 'string' and v:lower() == target then
        return s
      end
    end
  end
  return nil
end

local function choose_wild_for_map(map)
  -- try map-specific encounter_table
  if map and map.encounter_table and #map.encounter_table > 0 then
    -- build weighted list
    local pool = {}
    for _,entry in ipairs(map.encounter_table) do
      local w = tonumber(entry.weight) or 1
      local name = entry.name or entry.species
      if name then
        for i=1,w do table.insert(pool, name) end
      end
    end
    if #pool > 0 then
      local pick = pool[math.random(1, #pool)]
      -- try to find mapped species
      local spec = find_species_by_name(pick)
      if spec then return spec end
    end
  end
  -- fallback: prefer user-specified starters if present in species data
  for _,nm in ipairs(starters_preferred) do
    local s = find_species_by_name(nm)
    if s then return s end
  end
  -- final fallback: first species entry
  if speciesJson and speciesJson.species and #speciesJson.species > 0 then
    return speciesJson.species[1]
  end
  return nil
end

local function check_for_encounter()
  if not state.map then return nil end
  local enc = state.map.encounter_tiles
  if not enc then return nil end
  for _,e in ipairs(enc) do
    if e.x == player.x and e.y == player.y then
      local spec = choose_wild_for_map(state.map)
      if spec then return spec end
      return { id = 0 }
    end
  end
  return nil
end

local function start_encounter(spec)
  encounter = spec
  inEncounter = true
  print('Encounter started: species id=' .. tostring(spec.id))
end

local function end_encounter()
  encounter = nil
  inEncounter = false
  print('Encounter ended')
end

local function load_map_by_name(name)
  local path = 'build/maps/' .. name
  local f = io.open(path, 'r')
  if not f then return false end
  local txt = f:read('*a')
  f:close()
  state.map = json.decode(txt)
  -- set player start from map if present
  if state.map.player_start then
    player.x = state.map.player_start.x
    player.y = state.map.player_start.y
  else
    player.x = math.floor((state.map.width or 16)/2)
    player.y = math.floor((state.map.height or 12)/2)
  end
  return true
end

function love.load()
  love.window.setTitle('gen1recomp LÖVE MVP — Littleroot Demo')
  math.randomseed(os.time())
  -- Try to load generated symbols
  if love.filesystem.getInfo('build/symbols.json') then
    local s = love.filesystem.read('build/symbols.json')
    local obj = json.decode(s)
    assets = obj.gen1recomp or {}
  else
    assets = { symbols = {} }
  end

  -- load species
  if love.filesystem.getInfo('build/species_mapped.json') then
    local s = love.filesystem.read('build/species_mapped.json')
    speciesJson = json.decode(s)
  elseif love.filesystem.getInfo('build/species.json') then
    local s = love.filesystem.read('build/species.json')
    speciesJson = json.decode(s)
  end

  -- load moves
  if love.filesystem.getInfo('build/moves.json') then
    local s = love.filesystem.read('build/moves.json')
    movesJson = json.decode(s)
  end

  -- load tiles meta if present
  if love.filesystem.getInfo('build/assets/tiles_meta.json') then
    local s = love.filesystem.read('build/assets/tiles_meta.json')
    tiles_meta = json.decode(s)
  end

  -- load tiles image
  if love.filesystem.getInfo('build/assets/tiles.png') then
    state.tilesImg = love.graphics.newImage('build/assets/tiles.png')
  end

  -- load or generate player sprite
  load_player_sprite()

  -- ensure maps dir exists and load littleroot if present
  mapList = ui_map_browser.list_maps()
  if love.filesystem.getInfo('build/maps/littleroot_town.json') then
    selectedMapName = 'littleroot_town.json'
    load_map_by_name(selectedMapName)
  elseif #mapList > 0 then
    selectedMapIndex = 1
    selectedMapName = mapList[1]
    load_map_by_name(selectedMapName)
  end
end

function love.update(dt)
  if battle.active() then
    battle.update(dt)
  end
end

function love.draw()
  love.graphics.clear(0.1, 0.1, 0.12)
  love.graphics.setColor(1,1,1)
  love.graphics.print('Loaded symbols: '..(#(assets.symbols or {})), 10, 10)
  species_viewer.draw(speciesJson, 10, 40)

  -- draw map browser on left
  love.graphics.setColor(1,1,1)
  love.graphics.print('Maps:', 10, 240)
  ui_map_browser.draw_list(mapList, 10, 260, selectedMapIndex)

  -- draw selected map
  if state.map and state.tilesImg and not battle.active() then
    local ok, err = pcall(function() map_renderer.draw(state, MAP_OX, MAP_OY, tiles_meta) end)
    if not ok then love.graphics.print('Map draw error: '..tostring(err), MAP_OX, MAP_OY) end
    -- draw player sprite at tile coords
    local tw = state.map.tile_width or 8
    local th = state.map.tile_height or 8
    if playerSprite then
      love.graphics.draw(playerSprite, MAP_OX + player.x * tw, MAP_OY + player.y * th)
    else
      love.graphics.setColor(1,0.8,0)
      love.graphics.rectangle('fill', MAP_OX + player.x * tw, MAP_OY + player.y * th, tw, th)
    end
  elseif not battle.active() then
    love.graphics.print('No map/tiles found. Run import-assets.', MAP_OX, MAP_OY)
  end

  if inEncounter and encounter and not battle.active() then
    -- draw a simple encounter panel
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle('fill', 100, 100, 400, 160)
    love.graphics.setColor(1,1,1)
    love.graphics.printf('A wild species id='..tostring(encounter.id)..' appeared!', 110, 120, 380)
    love.graphics.printf('Press ENTER to start battle (demo) or ESC to run', 110, 160, 380)
  end

  if battle.active() then
    battle.draw()
  end

  love.graphics.setColor(1,1,1)
  love.graphics.print('Controls: Arrow keys to step, B to trigger simple encounter', 10, 520)
end

function love.mousepressed(mx, my, button)
  if button == 1 then
    local pickIdx = ui_map_browser.pick(mapList, 10, 260, mx, my)
    if pickIdx then
      selectedMapIndex = pickIdx
      selectedMapName = mapList[pickIdx]
      load_map_by_name(selectedMapName)
      load_player_sprite()
      print('Selected map:', selectedMapName)
      return
    end
    -- otherwise, pick tile on map
    local res = map_renderer.pick(state, mx, my, MAP_OX, MAP_OY, tiles_meta)
    if res then
      local li, tx, ty, idx = res[1], res[2], res[3], res[4]
      print(('Map clicked: layer=%s x=%d y=%d tile=%s'):format(tostring(li), tx, ty, tostring(idx)))
    end
  end
end

function love.keypressed(k)
  if battle.active() then
    battle.handle_key(k)
    return
  end

  if inEncounter then
    if k == 'return' or k == 'kpenter' then
      print('Starting battle (demo) with species id='..tostring(encounter.id))
      -- start the battle using species base HP if available
      local wild_hp = 40
      if encounter and encounter.base_hp then
        wild_hp = tonumber(encounter.base_hp) * 2
      elseif encounter and encounter.base_hp == nil and encounter.hp then
        wild_hp = tonumber(encounter.hp)
      end
      local ply_hp = 60
      if speciesJson and speciesJson.species and speciesJson.species[1] and speciesJson.species[1].base_hp then
        ply_hp = tonumber(speciesJson.species[1].base_hp) * 2
      end
      local wild = { id = encounter.id, hp = wild_hp, maxhp = wild_hp }
      local ply = { hp = ply_hp, maxhp = ply_hp }
      -- choose a move from movesJson if available
      local chosen_move = { id = 0, name = 'Tackle', power = 40 }
      if movesJson and movesJson.moves and #movesJson.moves > 0 then
        local m = movesJson.moves[1]
        chosen_move.id = m.id or chosen_move.id
        chosen_move.name = m.name or chosen_move.name
        chosen_move.power = m.power or m.raw and (m.raw[3] or chosen_move.power) or chosen_move.power
      end
      battle.start({ player = ply, wild = wild, move = chosen_move })
      return
    elseif k == 'escape' then
      print('You ran away (demo)')
      end_encounter()
      return
    end
  end

  if k=='r' then
    -- reload symbols
    if love.filesystem.getInfo('build/symbols.json') then
      local s = love.filesystem.read('build/symbols.json')
      local obj = json.decode(s)
      assets = obj.gen1recomp or {}
      print('Reloaded symbols.json')
      mapList = ui_map_browser.list_maps()
    end
    -- reload species
    if love.filesystem.getInfo('build/species_mapped.json') then
      local s = love.filesystem.read('build/species_mapped.json')
      speciesJson = json.decode(s)
      print('Reloaded species_mapped.json')
    elseif love.filesystem.getInfo('build/species.json') then
      local s = love.filesystem.read('build/species.json')
      speciesJson = json.decode(s)
      print('Reloaded species.json')
    end
    -- reload moves
    if love.filesystem.getInfo('build/moves.json') then
      local s = love.filesystem.read('build/moves.json')
      movesJson = json.decode(s)
      print('Reloaded moves.json')
    end
    -- reload tiles
    if love.filesystem.getInfo('build/assets/tiles.png') then
      state.tilesImg = love.graphics.newImage('build/assets/tiles.png')
      print('Reloaded tiles.png')
    end
    if love.filesystem.getInfo('build/assets/tiles_meta.json') then
      local s = love.filesystem.read('build/assets/tiles_meta.json')
      tiles_meta = json.decode(s)
      print('Reloaded tiles_meta.json')
    end
    -- reload player sprite
    load_player_sprite()
    -- reload map list and selected map
    mapList = ui_map_browser.list_maps()
    if selectedMapName and love.filesystem.getInfo('build/maps/'..selectedMapName) then
      load_map_by_name(selectedMapName)
    elseif #mapList > 0 then
      selectedMapIndex = 1
      selectedMapName = mapList[1]
      load_map_by_name(selectedMapName)
    end
  elseif k == 'b' then
    local spec = (speciesJson and speciesJson.species and speciesJson.species[1]) or { id = 0 }
    start_encounter(spec)
  elseif k == 'up' then
    if try_move(0, -1) then
      local s = check_for_encounter()
      if s then start_encounter(s) end
    end
  elseif k == 'down' then
    if try_move(0, 1) then
      local s = check_for_encounter()
      if s then start_encounter(s) end
    end
  elseif k == 'left' then
    if try_move(-1, 0) then
      local s = check_for_encounter()
      if s then start_encounter(s) end
    end
  elseif k == 'right' then
    if try_move(1, 0) then
      local s = check_for_encounter()
      if s then start_encounter(s) end
    end
  end
end
