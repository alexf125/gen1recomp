# Minimal LÖVE app to load JSON assets and draw a tileset
-- love/main.lua
local json = require 'dkjson' -- optional; the user should install a Lua JSON library or load via love.filesystem

local assets = {}
local tilesetImg
local tilesetQuad

function love.load()
  love.window.setTitle('gen1recomp LÖVE MVP')
  -- Try to load generated JSON
  if love.filesystem.getInfo('build/symbols.json') then
    local s = love.filesystem.read('build/symbols.json')
    local obj = json.decode(s)
    assets = obj.gen1recomp or {}
  else
    print('build/symbols.json not found; run make import-assets')
  end

  -- Try to load an example tileset image
  if love.filesystem.getInfo('build/assets/tiles.png') then
    tilesetImg = love.graphics.newImage('build/assets/tiles.png')
  end
end

function love.update(dt)
end

function love.draw()
  love.graphics.clear(0.2,0.2,0.25)
  love.graphics.setColor(1,1,1)
  love.graphics.print('Loaded symbols: '..(assets.symbols and #assets.symbols or 0), 10, 10)
  if tilesetImg then
    love.graphics.draw(tilesetImg, 10, 40)
  else
    love.graphics.print('No tileset image at build/assets/tiles.png', 10, 40)
  end
end

function love.keypressed(k)
  if k=='r' then
    love.filesystem.load('build/symbols.json')
    -- simple hot-reload: restart lua state by reloading modules / re-reading files
    if love.filesystem.getInfo('build/symbols.json') then
      local s = love.filesystem.read('build/symbols.json')
      local obj = json.decode(s)
      assets = obj.gen1recomp or {}
      print('Reloaded symbols.json')
    end
    if love.filesystem.getInfo('build/assets/tiles.png') then
      tilesetImg = love.graphics.newImage('build/assets/tiles.png')
      print('Reloaded tiles.png')
    end
  end
end
