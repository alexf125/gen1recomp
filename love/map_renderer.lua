-- love/map_renderer.lua
-- Simple map renderer that loads build/map.json and build/assets/tiles.png
local M = {}

function M.load(mapPath, tilesMetaPath)
  local mapData
  if love.filesystem.getInfo(mapPath) then
    local s = love.filesystem.read(mapPath)
    mapData = love.filesystem.getIdentity and love._tserial and love._tserial(s) or love.filesystem.read(mapPath)
  else
    local f = io.open(mapPath, 'r')
    if not f then return nil, 'map not found' end
    mapData = f:read('*a')
    f:close()
    mapData = require('json').decode(mapData)
  end
  local tilesImg
  if love.filesystem.getInfo('build/assets/tiles.png') then
    tilesImg = love.graphics.newImage('build/assets/tiles.png')
  end
  return { map = mapData, tilesImg = tilesImg }
end

function M.draw(state, ox, oy)
  local map = state.map
  local tilesImg = state.tilesImg
  if not map or not tilesImg then
    love.graphics.print('Map or tiles missing', 10, 10)
    return
  end
  local tw = map.tile_width or 16
  local th = map.tile_height or 16
  local cols = math.floor(tilesImg:getWidth() / tw)
  for y = 1, map.height do
    for x = 1, map.width do
      local idx = map.layers[1][y][x]
      local tx = (idx % cols) * tw
      local ty = math.floor(idx / cols) * th
      love.graphics.draw(tilesImg, love.graphics.newQuad(tx, ty, tw, th, tilesImg:getWidth(), tilesImg:getHeight()), (x-1)*tw + ox, (y-1)*th + oy)
    end
  end
end

return M
