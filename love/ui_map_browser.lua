-- love/ui_map_browser.lua
local M = {}

function M.list_maps()
  local items = {}
  if love.filesystem.getInfo('build/maps') then
    local list = love.filesystem.getDirectoryItems('build/maps')
    for _, name in ipairs(list) do
      if name:match('%.json$') then table.insert(items, name) end
    end
  end
  table.sort(items)
  return items
end

function M.draw_list(items, x, y, selectedIndex)
  local sy = y
  for i, name in ipairs(items) do
    if i == selectedIndex then
      love.graphics.setColor(0.2,0.5,0.2)
      love.graphics.rectangle('fill', x-2, sy-2, 300, 18)
      love.graphics.setColor(1,1,1)
    else
      love.graphics.setColor(0.8,0.8,0.8)
    end
    love.graphics.print(name, x, sy)
    sy = sy + 18
  end
end

-- returns index of clicked item or nil
function M.pick(items, ox, oy, mx, my)
  local x = ox
  local y = oy
  for i, name in ipairs(items) do
    local item_y = y + (i-1)*18
    if mx >= x and mx <= x+300 and my >= item_y and my <= item_y+16 then
      return i
    end
  end
  return nil
end

return M
