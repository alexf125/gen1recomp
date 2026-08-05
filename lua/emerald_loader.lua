-- lua/emerald_loader.lua
-- A small loader to pick up JSON files produced by tools/emerald_importer.py and
-- return them as Lua tables for gen1recomp.
-- Usage from main Love2D code: local emerald = require('emerald_loader')
-- local species = emerald.load('data/emerald/species_info.json')

local _M = {}

local json = nil
-- try common json libs
local ok
ok, json = pcall(require, 'dkjson')
if not ok then
  ok, json = pcall(require, 'json')
end

local function read_file(path)
  -- Uses love.filesystem if available, otherwise io.open
  if love and love.filesystem and love.filesystem.getInfo then
    if love.filesystem.getInfo(path) then
      return love.filesystem.read(path)
    end
    return nil
  else
    local f, err = io.open(path, 'r')
    if not f then return nil, err end
    local content = f:read('*a')
    f:close()
    return content
  end
end

function _M.load(path)
  local contents, err = read_file(path)
  if not contents then
    return nil, 'Could not read ' .. tostring(path) .. ': ' .. tostring(err)
  end
  if json then
    -- dkjson returns value, pos, err
    local ok, tbl
    if json.decode then
      tbl = json.decode(contents)
    else
      -- dkjson style
      ok, tbl = json.decode(contents, 1, nil)
      if not ok then return nil, 'JSON decode failed' end
      tbl = ok
    end
    return tbl
  else
    -- naive fallback: try load as Lua (not safe if not valid Lua)
    local loader, e = load('return ' .. contents)
    if not loader then
      return nil, 'No json library available and fallback load failed: ' .. tostring(e)
    end
    local ok, res = pcall(loader)
    if not ok then return nil, 'Lua load failed: ' .. tostring(res) end
    return res
  end
end

function _M.load_all(dir)
  -- If running inside love.filesystem, iterate files there. Otherwise we expect the
  -- caller to pass explicit paths.
  local results = {}
  if love and love.filesystem and love.filesystem.getDirectoryItems then
    local items = love.filesystem.getDirectoryItems(dir)
    for _, name in ipairs(items) do
      if name:match('%.json$') then
        local path = dir .. '/' .. name
        local t, err = _M.load(path)
        results[name] = t or { error = err }
      end
    end
  else
    return nil, 'load_all requires love.filesystem or explicit list of files'
  end
  return results
end

return _M
