-- love/map_renderer.lua (improved)
local M = {}

-- state.map: { width, height, tile_width, tile_height, tileset, layers = { layer0, layer1, ... } }
-- tiles_meta: { tile_width, tile_height, tiles, tileset, palette }

local function ensure_quad_cache(img, tw, th)
  img._quad_cache = img._quad_cache or {}
  local key = tw..'x'..th
  if img._quad_cache[key] then return img._quad_cache[key] end
  local cols = math.floor(img:getWidth() / tw)
  local rows = math.floor(img:getHeight() / th)
  local quads = {}
  for y = 0, rows-1 do
    for x = 0, cols-1 do
      table.insert(quads, love.graphics.newQuad(x*tw, y*th, tw, th, img:getWidth(), img:getHeight()))
    end
  end
  img._quad_cache[key] = { quads = quads, cols = cols }
  return img._quad_cache[key]
end

function M.draw(state, ox, oy, tiles_meta)
  local map = state.map
  if not map then return end
  local tilesImg = state.tilesImg
  if not tilesImg then
    love.graphics.print('tiles image missing', ox, oy)
    return
  end
  local tw = map.tile_width or (tiles_meta and tiles_meta.tile_width) or 8
  local th = map.tile_height or (tiles_meta and tiles_meta.tile_height) or 8
  local cache = ensure_quad_cache(tilesImg, tw, th)
  local quads = cache.quads
  local cols = cache.cols

  -- draw layers in order
  for li, layer in ipairs(map.layers or {}) do
    for y = 1, #layer do
      local row = layer[y]
      for x = 1, #row do
        local idx = row[x]
        if idx and idx >= 0 and idx+1 <= #quads then
          love.graphics.draw(tilesImg, quads[idx+1], ox + (x-1)*tw, oy + (y-1)*th)
        end
      end
    end
  end
end

-- pick tile: returns layerIndex, tx, ty, tileIndex or nil
function M.pick(state, mx, my, ox, oy, tiles_meta)
  local map = state.map
  if not map then return nil end
  local tw = map.tile_width or (tiles_meta and tiles_meta.tile_width) or 8
  local th = map.tile_height or (tiles_meta and tiles_meta.tile_height) or 8
  local lx = math.floor((mx - ox) / tw) + 1
  local ly = math.floor((my - oy) / th) + 1
  if lx < 1 or ly < 1 or lx > map.width or ly > map.height then return nil end
  for li, layer in ipairs(map.layers or {}) do
    local row = layer[ly]
    if row then
      local idx = row[lx]
      return li, lx, ly, idx
    end
  end
  return nil
end

return M
