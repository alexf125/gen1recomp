-- love/species_viewer.lua
local M = {}

function M.draw(speciesJson, x, y)
  if not speciesJson then
    love.graphics.print('No species.json available', x, y)
    return
  end
  love.graphics.print(('Species symbol: %s (count=%d)'):format(speciesJson.symbol or 'unknown', speciesJson.count or 0), x, y)
  local sx = x
  local sy = y + 16
  local list = speciesJson.species or {}
  local maxShow = 10
  for i = 1, math.min(#list, maxShow) do
    local entry = list[i]
    -- show first few fields as a preview
    local preview = {}
    for j = 1, math.min(6, #entry) do
      table.insert(preview, tostring(entry[j]))
    end
    love.graphics.print(('%d: %s'):format(i, table.concat(preview, ', ')), sx, sy)
    sy = sy + 12
  end
  if #list > maxShow then
    love.graphics.print(('... and %d more'):format(#list - maxShow), sx, sy)
  end
end

return M
