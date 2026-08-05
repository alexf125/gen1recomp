-- love/species_viewer.lua (updated to use species_mapped.json when available)
local M = {}

function M.draw(speciesJson, x, y)
  if not speciesJson then
    love.graphics.print('No species.json available', x, y)
    return
  end
  local sym = speciesJson.symbol or 'mapped'
  local count = speciesJson.count or (#(speciesJson.species or {}))
  love.graphics.print(('Species: %s (count=%d)'):format(sym, count), x, y)
  local sx = x
  local sy = y + 16
  local list = speciesJson.species or {}
  local maxShow = 8
  for i = 1, math.min(#list, maxShow) do
    local entry = list[i]
    if type(entry) == 'table' and entry.base then
      local base = entry.base
      love.graphics.print(('%d: HP=%s ATK=%s DEF=%s SPD=%s'):format(i, tostring(base.hp), tostring(base.atk), tostring(base.def), tostring(base.spd)), sx, sy)
    else
      -- fallback show raw
      local preview = {}
      for j = 1, math.min(6, #entry) do
        table.insert(preview, tostring(entry[j]))
      end
      love.graphics.print(('%d: %s'):format(i, table.concat(preview, ', ')), sx, sy)
    end
    sy = sy + 14
  end
  if #list > maxShow then
    love.graphics.print(('... and %d more'):format(#list - maxShow), sx, sy)
  end
end

return M
