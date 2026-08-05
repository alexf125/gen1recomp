-- love/main.lua
-- Minimal LÖVE entry that loads converted Emerald data, plays audio, and supports simple animated sprites.
local battle = require('love.battle')

local species = {}
local assets = {images = {}, sounds = {}}

function love.load()
  love.window.setTitle('gen1recomp - Emerald prototype')
  love.graphics.setDefaultFilter('nearest', 'nearest')

  -- try to load converted data (fall back to built-in sample)
  local ok, emerald = pcall(require, 'data.emerald_species')
  if ok and emerald then
    species = emerald
  else
    species = require('data.emerald_species_sample')
  end

  -- load asset placeholders
  if love.filesystem.getInfo('assets/starters/treecko.png') then
    assets.images.treecko = love.graphics.newImage('assets/starters/treecko.png')
  end
  if love.filesystem.getInfo('assets/starters/torchic.png') then
    assets.images.torchic = love.graphics.newImage('assets/starters/torchic.png')
  end
  if love.filesystem.getInfo('assets/starters/mudkip.png') then
    assets.images.mudkip = love.graphics.newImage('assets/starters/mudkip.png')
  end

  -- audio: look for cries/ music
  if love.filesystem.getInfo('audio/cries/treecko.ogg') then
    assets.sounds.treecko_cry = love.audio.newSource('audio/cries/treecko.ogg', 'static')
  end

  -- simple animation state
  anim = {x = 160, y = 120, t = 0, frame = 1}

  -- spawn a demo battle
  demo = battle.new_demo(species)
end

function love.update(dt)
  anim.t = anim.t + dt
  if anim.t > 0.12 then
    anim.t = anim.t - 0.12
    anim.frame = anim.frame % 4 + 1
  end
  if demo and demo.update then demo:update(dt) end
end

function love.draw()
  love.graphics.clear(0.1,0.1,0.12)
  love.graphics.setColor(1,1,1)
  love.graphics.print('gen1recomp - Emerald prototype (sample)', 8, 8)

  -- draw starter images if present
  if assets.images.treecko then
    love.graphics.draw(assets.images.treecko, 64, 64, 0, 2, 2)
  else
    love.graphics.rectangle('line', 64, 64, 64, 64)
    love.graphics.print('treecko.png missing', 64, 130)
  end

  if demo and demo.draw then demo:draw() end
end

function love.keypressed(k)
  if k == 'space' and assets.sounds.treecko_cry then
    assets.sounds.treecko_cry:play()
  end
end
