-- love/main.lua (updated to load species.json viewer)
local json = require('json') or require('dkjson')
local map_renderer = require('map_renderer')
local species_viewer = require('species_viewer')

local assets = {}
local state = {}
local speciesJson = nil

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
  if love.filesystem.getInfo('build/species.json') then
    local s = love.filesystem.read('build/species.json')
    speciesJson = json.decode(s)
  end

  -- load map
  local mapfile = 'build/map.json'
  local mapf = io.open(mapfile, 'r')
  if mapf then
    local mtxt = mapf:read('*a')
    mapf:close()
    state.map = json.decode(mtxt)
  end

  if love.filesystem.getInfo('build/assets/tiles.png') then
    state.tilesImg = love.graphics.newImage('build/assets/tiles.png')
  end
end

function love.draw()
  love.graphics.clear(0.1, 0.1, 0.12)
  love.graphics.setColor(1,1,1)
  love.graphics.print('Loaded symbols: '..(#(assets.symbols or {})), 10, 10)
  species_viewer.draw(speciesJson, 300, 10)
  if state.map and state.tilesImg then
    local ok, err = pcall(function() map_renderer.draw(state, 10, 40) end)
    if not ok then love.graphics.print('Map draw error: '..tostring(err), 10, 40) end
  else
    love.graphics.print('No map/tiles found. Run make import-assets.', 10, 40)
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
    end
    -- reload species
    if love.filesystem.getInfo('build/species.json') then
      local s = love.filesystem.read('build/species.json')
      speciesJson = json.decode(s)
      print('Reloaded species.json')
    end
    -- reload tiles
    if love.filesystem.getInfo('build/assets/tiles.png') then
      state.tilesImg = love.graphics.newImage('build/assets/tiles.png')
      print('Reloaded tiles.png')
    end
    -- reload map
    local mapf = io.open('build/map.json', 'r')
    if mapf then
      local mtxt = mapf:read('*a')
      mapf:close()
      state.map = json.decode(mtxt)
      print('Reloaded map.json')
    end
  end
end
