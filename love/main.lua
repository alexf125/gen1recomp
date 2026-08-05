-- love/main.lua (updated: tile-step movement, collision checks, player sprite)
local json = require('json') or require('dkjson')
local map_renderer = require('map_renderer')
local species_viewer = require('species_viewer')
local ui_map_browser = require('ui_map_browser')

local assets = {}
local state = {}
local speciesJson = nil
local tiles_meta = nil

local mapList = {}
local selectedMapIndex = 1
local selectedMapName = nil

local MAP_OX = 320
local MAP_OY = 40

-- player
local player = { x = 0, y = 0 }
local playerSprite = nil

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
  -- coordinates in map are 0-based in this map; collision uses 0..width-1? map collision uses 0/1 arrays matching width: we stored collision as rows length==width
  -- Our collision is 0/1 with boundaries 1; convert nx,ny to 1-based indices for collision array
  local cx = nx + 1
  local cy = ny + 1
  if is_blocked(cx, cy) then
    -- blocked
    return false
  end
  player.x = nx
  player.y = ny
  return true
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
  -- nothing continuous; movement is tile-step on keypress
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
  if state.map and state.tilesImg then
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
  else
    love.graphics.print('No map/tiles found. Run import-assets.', MAP_OX, MAP_OY)
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
    -- simple encounter trigger: pick a species and print a battle start message
    local species = (speciesJson and speciesJson.species and speciesJson.species[1]) or nil
    if species then
      print('Encounter! A wild species id='..tostring(species.id)..' appeared (demo).')
    else
      print('Encounter! (no species data available)')
    end
  elseif k == 'up' then
    try_move(0, -1)
  elseif k == 'down' then
    try_move(0, 1)
  elseif k == 'left' then
    try_move(-1, 0)
  elseif k == 'right' then
    try_move(1, 0)
  end
end
