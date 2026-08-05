-- love/main.lua (updated with map browser integration)
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

function load_map_by_name(name)
  local path = 'build/maps/' .. name
  local f = io.open(path, 'r')
  if not f then return false end
  local txt = f:read('*a')
  f:close()
  state.map = json.decode(txt)
  return true
end

function love.load()
  love.window.setTitle('gen1recomp LÖVE MVP')
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

  -- load map list
  mapList = ui_map_browser.list_maps()
  if #mapList > 0 then
    selectedMapIndex = 1
    selectedMapName = mapList[1]
    load_map_by_name(selectedMapName)
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
  if state.map and state.tilesImg then
    local ok, err = pcall(function() map_renderer.draw(state, MAP_OX, MAP_OY, tiles_meta) end)
    if not ok then love.graphics.print('Map draw error: '..tostring(err), MAP_OX, MAP_OY) end
  else
    love.graphics.print('No map/tiles found. Run import-assets.', MAP_OX, MAP_OY)
  end
end

function love.mousepressed(mx, my, button)
  if button == 1 then
    local pickIdx = ui_map_browser.pick(mapList, 10, 260, mx, my)
    if pickIdx then
      selectedMapIndex = pickIdx
      selectedMapName = mapList[pickIdx]
      load_map_by_name(selectedMapName)
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
    -- reload map list and selected map
    mapList = ui_map_browser.list_maps()
    if selectedMapName and love.filesystem.getInfo('build/maps/'..selectedMapName) then
      load_map_by_name(selectedMapName)
    elseif #mapList > 0 then
      selectedMapIndex = 1
      selectedMapName = mapList[1]
      load_map_by_name(selectedMapName)
    end
  end
end
